# Package Notes — Complete Executable dbt Lab

## Changes

- Replaced the incomplete scaffold with an executable dbt-DuckDB project.
- Added eight deterministic source seeds generated from code and source contracts.
- Added staging, intermediate, fact, dimension, operations, and customer mart layers.
- Added a customer profile snapshot, dashboard exposures, a reusable macro, and a portfolio KPI analysis.
- Added generic schema tests and singular reconciliation/business-rule tests.
- Corrected the original missing `raw_orders` dependency and lineage mismatch.
- Preserved the strongest validation ideas from the superseded order-lifecycle PR.
- Added GitHub Actions CI, documentation generation, evidence export, and release-readiness guidance.

## Validation gate

The release is accepted only when `make verify` passes in GitHub Actions with zero warnings or errors.
