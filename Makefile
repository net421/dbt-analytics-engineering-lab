.PHONY: setup data debug seed snapshot build test docs evidence verify clean

setup:
	python -m pip install -r requirements.txt

data:
	python scripts/generate_synthetic_seeds.py

debug:
	dbt debug --profiles-dir .

seed:
	dbt seed --profiles-dir . --full-refresh

snapshot:
	dbt snapshot --profiles-dir .

build:
	dbt build --profiles-dir .

test:
	dbt test --profiles-dir .

docs:
	dbt docs generate --profiles-dir .

evidence:
	python scripts/export_validation_evidence.py

verify: data debug seed snapshot build docs evidence

clean:
	dbt clean --profiles-dir .
	rm -f analytics.duckdb seeds/*.csv
