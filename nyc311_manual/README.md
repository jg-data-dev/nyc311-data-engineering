# Manual NYC 311 Pipeline

This folder contains the from-scratch implementation of the NYC 311 pipeline using Python, PostgreSQL, shell scripts, and SQL validation.

The goal of this version is to make each pipeline layer explicit and manually runnable.

## Flow

```text
NYC 311 Socrata API
  ↓
ingest/ingest.py
  ↓
raw/raw.sql
  ↓
staging/staging.sql
  ↓
warehouse/warehouse.sql
  ↓
analytics/analyze.py
  ↓
validation checks
```

## Folder structure

```text
nyc311_manual/
  config.py
  run_pipeline.sh

  raw/
    raw.sql
    validate/
      validate_raw.sql

  ingest/
    ingest.py

  staging/
    staging.sql
    validate/
      validate_staging.sql

  warehouse/
    warehouse.sql
    validate/
      validate_warehouse.sql

  analytics/
    analyze.py
    intermediate/
    marts/
    standard_queries/
    validate/
      validate_analytics.sql

  common/
    validate_common.sql
```

## Layer meanings

```text
raw        = create and validate the raw source table
ingest     = extract/load records from the NYC 311 API
staging    = clean and standardize source-shaped data
warehouse  = build reusable facts and dimensions
analytics  = build marts, metrics, and standard analytical outputs
common     = shared validation SQL
```

## Run

From this folder:

```bash
bash run_pipeline.sh
```

The script assumes a local PostgreSQL database named `nyc311`.

Depending on local state, raw table creation and ingestion may be commented out in `run_pipeline.sh` to avoid unnecessary reloads.

## Validation

Validation exists at multiple layers:

- raw source checks
- staging row count and timestamp checks
- warehouse foreign key checks
- analytics mart sanity checks

The intent is to make each transformation layer reviewable and rerunnable.