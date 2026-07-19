# Validation Evidence

The small files in this directory are committed so a reviewer can inspect executed results without downloading a CI artifact:

- `dbt_validation_summary.md`: human-readable build, test, row-count, and KPI evidence
- `manager_evidence.json`: machine-readable project counts, per-model row counts, and KPI reconciliation evidence
- `portfolio_kpi_summary.csv`: compact business metrics with unit-weighted and average-order fill rates named separately

Run `make verify` to regenerate them and `docs/generated_lineage.md`. The exporter rejects incomplete or non-passing `dbt test` results and fails if unit totals do not reconcile between `fct_orders` and `mart_supply_chain_kpis`. GitHub Actions also uploads the full `manifest.json`, `catalog.json`, and `run_results.json` as the `dbt-validation-evidence` artifact; those larger generated files are intentionally not committed.
