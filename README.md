# NYC 311 Data Engineering Project

This repository contains a data engineering / analytics engineering project built around NYC 311 service request data.

The project demonstrates an ELT-style pipeline for ingesting public-sector data, modeling it into analytical tables, and validating data quality across pipeline layers.

## Project structure

```text
nyc311-data-engineering/
  README.md
  SETUP.md
  requirements.txt

  nyc311_manual/
    raw/
    ingest/
    staging/
    warehouse/
    analytics/
    common/

  nyc311_dbt/
    models/
    tests/
    macros/
    seeds/
    snapshots/
```

## Two implementations

This repository contains two related implementations of the same pipeline.

### 1. `nyc311_manual/`

A from-scratch implementation using Python, PostgreSQL, shell scripts, and SQL validation.

This version includes:

- NYC 311 API ingestion
- raw PostgreSQL table creation
- staging transformations
- warehouse facts and dimensions
- analytics marts
- validation checks at each layer

The manual version is useful for showing the underlying pipeline mechanics without relying on a transformation framework.

### 2. `nyc311_dbt/`

A dbt implementation of the transformation layer.

The dbt project assumes raw NYC 311 data has already been loaded into PostgreSQL. It does not duplicate the Python ingestion layer. Instead, it rebuilds the staging, warehouse, intermediate, and mart layers using dbt models, tests, and documentation conventions.

## Pipeline architecture

```text
NYC 311 Socrata API
  ↓
Python ingestion
  ↓
raw PostgreSQL table
  ↓
staging models
  ↓
warehouse facts and dimensions
  ↓
analytics marts
  ↓
validation / tests
```

## Layer meanings

```text
raw        = source-shaped landing layer
staging    = cleaned and standardized source-shaped data
warehouse  = reusable dimensional model: facts and dimensions
analytics  = derived metrics, marts, and standard analytical outputs
dbt        = production-style transformation implementation
```

## Data quality focus

The project includes validation checks for issues such as:

- duplicate request keys
- missing critical fields
- invalid timestamp order
- missing foreign keys
- row count mismatches across layers
- inconsistent closed status / closed timestamp behavior
- aggregate metric sanity checks

## Skills demonstrated

- Python API ingestion
- PostgreSQL data modeling
- ELT pipeline design
- dbt transformations and tests
- dimensional modeling
- data quality validation
- analytical mart design
- Git-based project organization

See `SETUP.md` for local setup and run instructions.


## Airflow Orchestration
Daily Ingestion DAG
→ ensure_raw_tables
→ reset_probe_raw
→ ingest_daily
→ validate_raw
→ dbt_run
→ dbt_test

- ingest is daily ingestion, default to 2 days prior to current date, using ds (Airflow logical date), because the current day and previous day of NYC 311 source data may still be incomplete, or explicitly selected using config:
  {
    "target_date": "2026-05-10"
  }
- support testing raw table raw_311_requests_probe, but using
  {
      "test": true
  }

- dbt models runs on the entire selected raw table

- dbt test exclude migration tests againt older manual public.* outputs


### Airflow scheduling, backfill, and concurrency

The project includes two Airflow DAGs:

- `nyc311_daily_pipeline`: scheduled daily ingestion and transformation pipeline.
- `nyc311_backfill_pipeline`: manually triggered historical date-range backfill pipeline.

The daily DAG is scheduled to run at 9:30 AM local time:

```python
schedule="30 9 * * *"

# Future Production Improvements

incremental dbt models
backfill DAG/date range support
cloud warehouse version
CI for dbt tests
dashboard or simple metrics output