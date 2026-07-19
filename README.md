# dbt Analytics Engineering Lab

An executable dbt project that transforms synthetic ERP, TMS, WMS, CRM, product, and planning data into documented, tested, BI-ready analytics marts.

## Evidence in 60 seconds

The evidence below is committed and regenerated from dbt artifacts plus DuckDB; a reviewer does not need to trust manually typed counts.

| Manager question | Verifiable evidence |
|---|---|
| Did the data tests execute? | [Validation summary](validation/dbt_validation_summary.md): 71/71 passed, including 63 generic and 8 singular business-rule tests. |
| Is the modeling layered? | 20 models: 8 staging, 3 intermediate, and 9 marts; 11 views and 9 tables. See the [manifest-derived lineage](docs/generated_lineage.md). |
| Did the models materialize? | The exporter queried all 20 model relations. Selected outputs contain 120 orders, 240 order lines, 324 inventory-risk rows, 324 forecast rows, and 30 customer-value rows. |
| Are business outputs inspectable? | [KPI CSV](validation/portfolio_kpi_summary.csv): 98.35% unit-weighted fill rate (2,860 / 2,908 units), 98.13% average order fill rate, 80.00% complete-order rate, 36.67% on-time delivery, and 29.17% OTIF. |
| Can the evidence be audited mechanically? | [Machine-readable evidence](validation/manager_evidence.json) records project counts, every model row count, test results, KPI outputs, scope boundaries, and a passing `fct_orders`-to-mart unit reconciliation. |

Fast review path: open the validation summary, inspect the lineage, then read the reconciliation tests [`assert_order_revenue_reconciles.sql`](tests/assert_order_revenue_reconciles.sql), [`assert_order_units_reconcile.sql`](tests/assert_order_units_reconcile.sql), and [`assert_otif_requires_on_time_and_in_full.sql`](tests/assert_otif_requires_on_time_and_in_full.sql).

All numbers describe a deterministic synthetic scenario running locally on DuckDB. The two dbt exposures are metadata declarations, not proof of deployed dashboards.

## What this project demonstrates

- dbt sources and deterministically generated reproducible seeds
- staging, intermediate, fact, dimension, and domain mart layers
- explicit model grain and lineage
- generic tests and business-rule singular tests
- source-to-mart revenue and unit reconciliation
- customer profile snapshot using a Type 2 history pattern
- declarative dashboard exposure metadata
- DuckDB local execution and CI-ready commands

## Exact lineage

[`docs/generated_lineage.md`](docs/generated_lineage.md) is generated from dbt's `manifest.json`. It includes 30 source/model/exposure nodes and 29 direct dependency edges plus a direct-parent table. This replaces a manually maintained architecture claim with regenerable evidence.

## Change case: manager-verifiable evidence

[Issue #3](https://github.com/net421/dbt-analytics-engineering-lab/issues/3) asks for evidence that can be checked quickly without running the full project.

| Requirement | Implemented change | Acceptance proof |
|---|---|---|
| Verify results without a local dbt run | Commit a concise Markdown summary, CSV, and JSON evidence file | The files above expose executed tests, model counts, row counts, and KPIs |
| Avoid a hand-maintained lineage claim | Generate Mermaid and the direct-parent table from `manifest.json` | CI regenerates `docs/generated_lineage.md` and fails on committed drift |
| Keep claims tied to execution | Require final `dbt test` results, query every model relation, and reconcile unit totals between `fct_orders` and `mart_supply_chain_kpis` | The exporter fails on missing tests, non-passing tests, unavailable models, or mismatched unit totals |
| Preserve honest scope | State synthetic/local/declarative boundaries in README and generated outputs | No production, cloud, real-data, or deployed-dashboard claim |

## Repository structure

```text
scripts/generate_synthetic_seeds.py  deterministic source generator
seeds/              generated source datasets (ignored by Git)
models/sources.yml  source contracts
models/staging/     typed and normalized views
models/intermediate reusable business logic
models/marts/       facts, dimensions, and BI-ready marts
snapshots/          customer history example
tests/              business-rule and reconciliation tests
macros/             reusable SQL helpers
analyses/           portfolio KPI query
docs/               lineage, metrics, and AI workflow
```

## Run locally

```bash
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r requirements.txt
make verify
```

`make verify` generates the eight deterministic seed files, runs connection checks, full seed refresh, snapshot, build, documentation generation, all 71 data tests, and evidence export.

## Models

### Core

- `dim_customers`
- `dim_products`
- `dim_date`
- `fct_order_lines`
- `fct_orders`

### Operations

- `mart_supply_chain_kpis`
- `mart_inventory_risk`
- `mart_forecast_accuracy`

### Customer analytics

- `mart_customer_value`

## Quality gates

The build checks source and model uniqueness, required values, relationships, accepted values, fill-rate bounds, OTIF consistency, revenue and unit reconciliation, lifecycle chronology, additive logistics costs, and customer order-count reconciliation.

## Honest scope

This is a dbt analytics-engineering portfolio lab running locally on DuckDB. It demonstrates modeling, testing, documentation, lineage, and CI patterns without claiming production enterprise deployment.

## Reproducibility contract

`requirements.txt` pins dbt Core, the DuckDB adapter, and DuckDB itself. GitHub Actions runs `make verify`, checks that the committed evidence has no drift, and uploads the full dbt artifacts for deeper inspection. Run `make clean && make verify` for a clean local rebuild.
