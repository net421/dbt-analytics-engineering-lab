"""Export compact, deterministic evidence from a completed dbt verification."""

from __future__ import annotations

import csv
import json
import re
from collections import Counter
from pathlib import Path
from typing import Any

import duckdb

ROOT = Path(__file__).resolve().parents[1]
TARGET = ROOT / "target"
VALIDATION = ROOT / "validation"
LINEAGE_PATH = ROOT / "docs" / "generated_lineage.md"
DB_PATH = ROOT / "analytics.duckdb"
ISSUE_URL = "https://github.com/net421/dbt-analytics-engineering-lab/issues/3"


def load_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        raise FileNotFoundError(f"{path.relative_to(ROOT)} is missing; run make verify")
    return json.loads(path.read_text(encoding="utf-8"))


def project_nodes(manifest: dict[str, Any], resource_type: str) -> dict[str, Any]:
    return {
        unique_id: node
        for unique_id, node in manifest["nodes"].items()
        if node["resource_type"] == resource_type
    }


def validate_test_results(
    manifest: dict[str, Any], run_results: dict[str, Any]
) -> tuple[Counter[str], int, int]:
    tests = project_nodes(manifest, "test")
    expected_ids = set(tests)
    actual_ids = {result["unique_id"] for result in run_results["results"]}
    if actual_ids != expected_ids:
        missing = sorted(expected_ids - actual_ids)
        unexpected = sorted(actual_ids - expected_ids)
        raise RuntimeError(
            "target/run_results.json must come from the final `dbt test`; "
            f"missing={missing[:3]}, unexpected={unexpected[:3]}"
        )

    statuses: Counter[str] = Counter(
        result.get("status", "unknown") for result in run_results["results"]
    )
    if statuses != Counter({"pass": len(expected_ids)}):
        raise RuntimeError(
            f"Not all dbt tests passed: {dict(sorted(statuses.items()))}"
        )

    generic_count = sum(bool(node.get("test_metadata")) for node in tests.values())
    singular_count = len(tests) - generic_count
    return statuses, generic_count, singular_count


def query_model_evidence(
    model_nodes: dict[str, Any],
) -> tuple[dict[str, int], dict[str, Any], dict[str, Any]]:
    if not DB_PATH.exists():
        raise FileNotFoundError("analytics.duckdb is missing; run make verify")
    connection = duckdb.connect(str(DB_PATH), read_only=True)
    try:
        row_counts: dict[str, int] = {}
        for node in sorted(model_nodes.values(), key=lambda item: item["name"]):
            relation_name = node.get("relation_name")
            if not relation_name:
                raise RuntimeError(
                    f"Model {node['name']} has no relation_name in manifest"
                )
            row_counts[node["name"]] = connection.execute(
                f"select count(*) from {relation_name}"
            ).fetchone()[0]

        result = connection.execute(
            """
            select
                count(*) as order_count,
                sum(units_ordered) as units_ordered,
                sum(units_shipped) as units_shipped,
                round(avg(unit_fill_rate) * 100, 2) as average_order_fill_rate_pct,
                round(avg(cast(is_in_full as integer)) * 100, 2) as complete_order_pct,
                round(avg(cast(is_on_time as integer)) * 100, 2) as on_time_pct,
                round(avg(cast(is_otif as integer)) * 100, 2) as otif_pct,
                round(sum(order_revenue), 2) as modeled_revenue,
                round(sum(total_logistics_cost), 2) as logistics_cost
            from main.fct_orders
            """
        ).fetchone()
        order_count = int(result[0])
        units_ordered = int(result[1])
        units_shipped = int(result[2])
        if units_ordered <= 0:
            raise RuntimeError(
                "Cannot calculate unit fill rate: fct_orders has no ordered units"
            )
        unit_fill_rate_pct = round(100 * units_shipped / units_ordered, 2)

        mart_result = connection.execute(
            """
            select
                sum(order_count) as order_count,
                sum(units_ordered) as units_ordered,
                sum(units_shipped) as units_shipped
            from main.mart_supply_chain_kpis
            """
        ).fetchone()
        mart_totals = {
            "order_count": int(mart_result[0]),
            "units_ordered": int(mart_result[1]),
            "units_shipped": int(mart_result[2]),
        }
        fact_totals = {
            "order_count": order_count,
            "units_ordered": units_ordered,
            "units_shipped": units_shipped,
        }
        if mart_totals != fact_totals:
            raise RuntimeError(
                "Unit fill rate reconciliation failed between fct_orders and "
                f"mart_supply_chain_kpis: fact={fact_totals}, mart={mart_totals}"
            )

        kpis = {
            "order_count": order_count,
            "units_ordered": units_ordered,
            "units_shipped": units_shipped,
            "unit_fill_rate_pct": unit_fill_rate_pct,
            "average_order_fill_rate_pct": float(result[3]),
            "complete_order_pct": float(result[4]),
            "on_time_pct": float(result[5]),
            "otif_pct": float(result[6]),
            "modeled_revenue": float(result[7]),
            "logistics_cost": float(result[8]),
        }
        reconciliations = {
            "unit_fill_rate": {
                "formula": "sum(units_shipped) / sum(units_ordered)",
                "fct_orders": fact_totals,
                "mart_supply_chain_kpis": mart_totals,
                "unit_fill_rate_pct": unit_fill_rate_pct,
                "status": "pass",
            }
        }
        return row_counts, kpis, reconciliations
    finally:
        connection.close()


def lineage_graph(
    manifest: dict[str, Any], model_nodes: dict[str, Any]
) -> tuple[dict[str, Any], list[tuple[str, str]]]:
    nodes: dict[str, Any] = {}
    nodes.update(manifest["sources"])
    nodes.update(model_nodes)
    nodes.update(manifest["exposures"])

    edges: list[tuple[str, str]] = []
    for child_id, node in nodes.items():
        for parent_id in node.get("depends_on", {}).get("nodes", []):
            if parent_id in nodes:
                edges.append((parent_id, child_id))
    return nodes, sorted(edges)


def display_name(unique_id: str, node: dict[str, Any]) -> str:
    if node["resource_type"] == "source":
        return f"{node['source_name']}.{node['name']}"
    return node["name"]


def mermaid_id(unique_id: str) -> str:
    return "n_" + re.sub(r"[^a-zA-Z0-9_]", "_", unique_id)


def build_lineage_markdown(nodes: dict[str, Any], edges: list[tuple[str, str]]) -> str:
    resource_order = ("source", "model", "exposure")
    group_labels = {
        "source": "Declared sources",
        "model": "dbt models",
        "exposure": "Declared exposures",
    }
    lines = [
        "# Generated dbt Lineage Evidence",
        "",
        "This file is generated from `target/manifest.json` by "
        "`scripts/export_validation_evidence.py`. It contains direct dbt dependencies "
        "for declared sources, models, and exposures; tests, seeds, snapshots, and macros "
        "are intentionally omitted from the diagram.",
        "",
        "```mermaid",
        "flowchart TB",
    ]
    for resource_type in resource_order:
        members = sorted(
            (
                (unique_id, node)
                for unique_id, node in nodes.items()
                if node["resource_type"] == resource_type
            ),
            key=lambda item: display_name(*item),
        )
        lines.append(
            f'  subgraph {resource_type}_group["{group_labels[resource_type]} ({len(members)})"]'
        )
        for unique_id, node in members:
            label = display_name(unique_id, node)
            if resource_type == "exposure":
                label = f"exposure: {label}"
            lines.append(f'    {mermaid_id(unique_id)}["{label}"]')
        lines.append("  end")
    for parent_id, child_id in edges:
        lines.append(f"  {mermaid_id(parent_id)} --> {mermaid_id(child_id)}")
    lines.extend(
        [
            "```",
            "",
            "## Direct dependency table",
            "",
            "| Node | Direct parents |",
            "|---|---|",
        ]
    )

    for unique_id, node in sorted(
        (
            (unique_id, node)
            for unique_id, node in nodes.items()
            if node["resource_type"] in {"model", "exposure"}
        ),
        key=lambda item: (item[1]["resource_type"], display_name(*item)),
    ):
        parents = [
            display_name(parent_id, nodes[parent_id])
            for parent_id in node.get("depends_on", {}).get("nodes", [])
            if parent_id in nodes
        ]
        parent_text = ", ".join(sorted(parents)) if parents else "None in graph scope"
        node_name = display_name(unique_id, node)
        if node["resource_type"] == "exposure":
            node_name = f"exposure: {node_name}"
        lines.append(f"| `{node_name}` | {parent_text} |")

    lines.extend(
        [
            "",
            "The exposure nodes are dbt metadata declarations. They do not claim that a "
            "dashboard is deployed or running.",
            "",
        ]
    )
    return "\n".join(lines)


def build_summary_markdown(evidence: dict[str, Any]) -> str:
    project = evidence["project"]
    tests = evidence["tests"]
    kpis = evidence["kpis"]
    unit_fill_reconciliation = evidence["reconciliations"]["unit_fill_rate"]
    rows = evidence["model_row_counts"]
    return f"""# Executed dbt Validation Summary

This compact file is regenerated by `make verify` from dbt artifacts and the local DuckDB database. It contains no invocation timestamp, so identical inputs produce an identical committed result.

| Verification | Executed result |
|---|---:|
| dbt data tests | {tests["passed"]}/{tests["total"]} passed |
| Generic / singular tests | {tests["generic"]} / {tests["singular"]} |
| Models | {project["models"]} ({project["view_models"]} views, {project["table_models"]} tables) |
| Sources / seeds / snapshots | {project["sources"]} / {project["seeds"]} / {project["snapshots"]} |
| Declared exposures | {project["exposures"]} |
| Lineage graph | {project["lineage_nodes"]} nodes, {project["lineage_edges"]} direct edges |
| Unit fill reconciliation | {unit_fill_reconciliation["status"].upper()}: `fct_orders` = `mart_supply_chain_kpis` |

## Materialized row evidence

| Relation | Rows |
|---|---:|
| `fct_orders` | {rows["fct_orders"]:,} |
| `fct_order_lines` | {rows["fct_order_lines"]:,} |
| `mart_supply_chain_kpis` | {rows["mart_supply_chain_kpis"]:,} |
| `mart_inventory_risk` | {rows["mart_inventory_risk"]:,} |
| `mart_forecast_accuracy` | {rows["mart_forecast_accuracy"]:,} |
| `mart_customer_value` | {rows["mart_customer_value"]:,} |

## Synthetic scenario KPI evidence

| KPI | Result |
|---|---:|
| Orders | {kpis["order_count"]:,} |
| Units shipped / ordered | {kpis["units_shipped"]:,} / {kpis["units_ordered"]:,} |
| Unit fill rate (unit-weighted) | {kpis["unit_fill_rate_pct"]:.2f}% |
| Average order fill rate (unweighted) | {kpis["average_order_fill_rate_pct"]:.2f}% |
| Complete-order rate | {kpis["complete_order_pct"]:.2f}% |
| On-time delivery | {kpis["on_time_pct"]:.2f}% |
| OTIF | {kpis["otif_pct"]:.2f}% |
| Modeled revenue (synthetic currency) | {kpis["modeled_revenue"]:,.2f} |
| Logistics cost (synthetic currency) | {kpis["logistics_cost"]:,.2f} |

The contractual unit fill rate uses `sum(units_shipped) / sum(units_ordered)`: {kpis["units_shipped"]:,} / {kpis["units_ordered"]:,} = {kpis["unit_fill_rate_pct"]:.2f}%. The unweighted {kpis["average_order_fill_rate_pct"]:.2f}% figure is the average of order-level fill rates and is reported separately. The exporter fails if the unit totals in `fct_orders` and `mart_supply_chain_kpis` differ.

All {project["models"]} model relations were queried successfully during evidence export. Full per-model row counts are in `manager_evidence.json`. The inputs are deterministic synthetic data, the warehouse is local DuckDB, and the exposures are metadata declarations rather than deployed dashboards.
"""


def write_evidence() -> None:
    manifest = load_json(TARGET / "manifest.json")
    run_results = load_json(TARGET / "run_results.json")
    if not (TARGET / "catalog.json").exists():
        raise FileNotFoundError("target/catalog.json is missing; run make verify")

    model_nodes = project_nodes(manifest, "model")
    seed_nodes = project_nodes(manifest, "seed")
    snapshot_nodes = project_nodes(manifest, "snapshot")
    statuses, generic_count, singular_count = validate_test_results(
        manifest, run_results
    )
    row_counts, kpis, reconciliations = query_model_evidence(model_nodes)
    lineage_nodes, lineage_edges = lineage_graph(manifest, model_nodes)
    materializations = Counter(
        node["config"]["materialized"] for node in model_nodes.values()
    )
    layers = Counter(
        tag for node in model_nodes.values() for tag in node.get("tags", [])
    )

    evidence = {
        "change_request": ISSUE_URL,
        "evidence_sources": [
            "target/manifest.json",
            "target/run_results.json from the final dbt test",
            "analytics.duckdb",
        ],
        "project": {
            "dbt_version": manifest["metadata"]["dbt_version"],
            "adapter": manifest["metadata"]["adapter_type"],
            "models": len(model_nodes),
            "view_models": materializations["view"],
            "table_models": materializations["table"],
            "staging_models": layers["staging"],
            "intermediate_models": layers["intermediate"],
            "mart_models": layers["marts"],
            "sources": len(manifest["sources"]),
            "seeds": len(seed_nodes),
            "snapshots": len(snapshot_nodes),
            "exposures": len(manifest["exposures"]),
            "lineage_nodes": len(lineage_nodes),
            "lineage_edges": len(lineage_edges),
        },
        "tests": {
            "total": sum(statuses.values()),
            "passed": statuses["pass"],
            "generic": generic_count,
            "singular": singular_count,
            "failed": 0,
            "warned": 0,
            "skipped": 0,
        },
        "model_row_counts": row_counts,
        "kpis": kpis,
        "reconciliations": reconciliations,
        "scope": {
            "data": "deterministic synthetic scenario",
            "warehouse": "local DuckDB",
            "production_deployment": False,
            "deployed_dashboards": False,
        },
    }

    VALIDATION.mkdir(parents=True, exist_ok=True)
    with (VALIDATION / "portfolio_kpi_summary.csv").open(
        "w", encoding="utf-8", newline=""
    ) as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow(
            [
                "order_count",
                "units_shipped",
                "units_ordered",
                "unit_fill_rate_pct",
                "average_order_fill_rate_pct",
                "complete_order_pct",
                "on_time_pct",
                "otif_pct",
                "modeled_revenue",
                "logistics_cost",
            ]
        )
        writer.writerow(
            [
                kpis["order_count"],
                kpis["units_shipped"],
                kpis["units_ordered"],
                f"{kpis['unit_fill_rate_pct']:.2f}",
                f"{kpis['average_order_fill_rate_pct']:.2f}",
                f"{kpis['complete_order_pct']:.2f}",
                f"{kpis['on_time_pct']:.2f}",
                f"{kpis['otif_pct']:.2f}",
                f"{kpis['modeled_revenue']:.2f}",
                f"{kpis['logistics_cost']:.2f}",
            ]
        )

    (VALIDATION / "manager_evidence.json").write_text(
        json.dumps(evidence, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    (VALIDATION / "dbt_validation_summary.md").write_text(
        build_summary_markdown(evidence), encoding="utf-8"
    )
    LINEAGE_PATH.write_text(
        build_lineage_markdown(lineage_nodes, lineage_edges), encoding="utf-8"
    )
    print(
        json.dumps(
            {
                "models_queried": len(row_counts),
                "orders": kpis["order_count"],
                "otif_pct": kpis["otif_pct"],
                "tests_passed": statuses["pass"],
                "unit_fill_rate_pct": kpis["unit_fill_rate_pct"],
                "unit_fill_reconciliation": reconciliations["unit_fill_rate"]["status"],
            },
            sort_keys=True,
        )
    )


if __name__ == "__main__":
    write_evidence()
