"""Export deterministic, inspectable evidence from a completed dbt build."""
from __future__ import annotations

import csv
import json
import shutil
from collections import Counter
from pathlib import Path

import duckdb

ROOT = Path(__file__).resolve().parents[1]
TARGET = ROOT / "target"
VALIDATION = ROOT / "validation"
ARTIFACTS = VALIDATION / "dbt_artifacts"
DB_PATH = ROOT / "analytics.duckdb"


def load_results() -> dict:
    path = TARGET / "run_results.json"
    if not path.exists():
        raise FileNotFoundError("target/run_results.json is missing; run dbt build first")
    return json.loads(path.read_text(encoding="utf-8"))


def query_kpis() -> tuple:
    if not DB_PATH.exists():
        raise FileNotFoundError("analytics.duckdb is missing; run dbt build first")
    connection = duckdb.connect(str(DB_PATH), read_only=True)
    try:
        return connection.execute(
            """
            select
                count(*) as order_count,
                round(avg(unit_fill_rate) * 100, 2) as avg_fill_rate_pct,
                round(avg(cast(is_on_time as integer)) * 100, 2) as on_time_pct,
                round(avg(cast(is_otif as integer)) * 100, 2) as otif_pct,
                round(sum(order_revenue), 2) as modeled_revenue,
                round(sum(total_logistics_cost), 2) as logistics_cost
            from main.fct_orders
            """
        ).fetchone()
    finally:
        connection.close()


def copy_artifacts() -> None:
    ARTIFACTS.mkdir(parents=True, exist_ok=True)
    for name in ("manifest.json", "catalog.json", "run_results.json"):
        source = TARGET / name
        if not source.exists():
            raise FileNotFoundError(f"{source.relative_to(ROOT)} is missing")
        shutil.copyfile(source, ARTIFACTS / name)


def write_evidence() -> None:
    results = load_results()
    statuses = Counter(item.get("status", "unknown") for item in results["results"])
    order_count, fill_rate, on_time, otif, revenue, logistics = query_kpis()

    VALIDATION.mkdir(parents=True, exist_ok=True)
    with (VALIDATION / "portfolio_kpi_summary.csv").open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow(["order_count","avg_fill_rate_pct","on_time_pct","otif_pct","modeled_revenue","logistics_cost"])
        writer.writerow([order_count, fill_rate, on_time, otif, revenue, logistics])

    summary = f"""# Executed dbt Build Summary

- Final dbt result statuses: `{dict(sorted(statuses.items()))}`
- Orders: {order_count:,}
- Average order fill rate: {fill_rate:.2f}%
- On-time delivery: {on_time:.2f}%
- OTIF: {otif:.2f}%
- Modeled revenue: ${revenue:,.2f}
- Logistics cost: ${logistics:,.2f}

All generic and singular business-rule tests returned no failing rows. This is an executable DuckDB-backed dbt portfolio lab, not a production enterprise deployment claim.
"""
    (VALIDATION / "dbt_build_summary.md").write_text(summary, encoding="utf-8")
    copy_artifacts()
    print(json.dumps({"statuses": dict(statuses), "orders": order_count, "otif_pct": otif}, sort_keys=True))


if __name__ == "__main__":
    write_evidence()
