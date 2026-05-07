# NYC 311 dbt Project

This folder contains the dbt implementation of the NYC 311 transformation layer.

The dbt project assumes raw NYC 311 data has already been loaded into PostgreSQL by the manual ingestion pipeline in `nyc311_manual/ingest/`.

It does not duplicate ingestion. Instead, it rebuilds the transformation layers using dbt models, tests, and documentation conventions.

## Model flow

```text
raw_311_requests
  ↓
models/staging/stg_311_requests.sql
  ↓
models/core/dim_*.sql + models/core/fct_*.sql
  ↓
models/intermediate/int_complaints_flagged.sql
  ↓
models/marts/fct_daily_metrics.sql
  ↓
models/marts/fct_borough_complaint_mix.sql
```

## Layer meanings

```text
staging      = cleaned source-shaped models
core         = dimensional warehouse layer: dim_* and atomic fct_* models
intermediate = reusable logic and data quality flags
marts        = aggregate analytical outputs
```

## Run

From this folder:

```bash
dbt debug
dbt build
```

Run only models:

```bash
dbt run
```

Run tests:

```bash
dbt test
```

Run one model:

```bash
dbt run --select stg_311_requests
```

Run one model and downstream dependencies:

```bash
dbt run --select stg_311_requests+
```

Run one model and upstream dependencies:

```bash
dbt run --select +fct_borough_complaint_mix
```

Generate documentation:

```bash
dbt docs generate
dbt docs serve
```

## Tests

The dbt project includes or is designed to include tests for:

- unique request keys
- non-null critical fields
- valid timestamp order
- relationship integrity between facts and dimensions
- mart grain checks
- metric sanity checks
- manual-vs-dbt row count comparisons during migration

## Credentials

Database credentials live in `~/.dbt/profiles.yml`, not in this repository.

Do not commit credentials.