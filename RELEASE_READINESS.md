# Release Readiness

## Executable scope

- DuckDB-backed dbt project using pinned `dbt-core` and `dbt-duckdb` versions.
- Eight deterministic sources, one snapshot, 20 models, generic and singular data tests, two exposures, documentation generation, and evidence export.
- `make verify` is the canonical local and CI validation command.

## Claim boundary

This repository demonstrates dbt analytics-engineering practice on deterministic synthetic data and DuckDB. It does not claim a production enterprise warehouse deployment or live BI publication.

## Release gate

The repository is ready to merge only when GitHub Actions regenerates the seeds, build, documentation, and validation evidence successfully from a clean runner.
