# NYC 311 dbt Setup

This project uses dbt Core with PostgreSQL.

## Project shape

```text
raw_311_requests
  ↓
models/staging/stg_311_requests.sql
  ↓
models/core/dim_*.sql + models/core/fct_*.sql
  ↓
models/intermediate/int_complaints_flagged.sql
  ↓
models/marts/fct_daily_metrics.sql + models/marts/fct_borough_complaint_mix.sql
```

Layer meanings:

```text
staging = cleaned source-shaped views
core = dimensional warehouse layer: dim_* and atomic fct_* models
intermediate = reusable logic / flags built from core
marts = derived aggregate analytics outputs
```

## Enter project

```bash
cd nyc311_dbt
```

## Confirm connection

```bash
dbt debug
```

## Build models

```bash
dbt run
```

## Run tests

```bash
dbt test
```

## Run one model

```bash
dbt run --select stg_311_requests
```

## Run one model and downstream models

```bash
dbt run --select stg_311_requests+
```

## Run one model and upstream dependencies

```bash
dbt run --select +fct_borough_complaint_mix
```

## Generate local docs

```bash
dbt docs generate
dbt docs serve
```

## Credentials

Database connection settings live in `~/.dbt/profiles.yml`, not in this repository.

Do not commit credentials. Prefer an environment variable for the password:

```yaml
password: "{{ env_var('DBT_POSTGRES_PASSWORD') }}"
```

Then set it locally before running dbt:

```bash
export DBT_POSTGRES_PASSWORD='your_password_here'
dbt debug
```
