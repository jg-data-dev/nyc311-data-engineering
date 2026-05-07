# Setup

This project uses Python, PostgreSQL, and dbt Core.

## 1. Create virtual environment

From the repository root:

```bash
python3 -m venv venv
source venv/bin/activate
```

## 2. Install dependencies

```bash
pip install -r requirements.txt
```

If installing manually:

```bash
pip install requests "psycopg[binary]" dbt-core dbt-postgres
```

## 3. Start PostgreSQL

```bash
brew services start postgresql
```

## 4. Create database

```bash
createdb nyc311
```

Or from `psql`:

```sql
CREATE DATABASE nyc311;
```

## 5. Configure database connection

The Python pipeline expects a local PostgreSQL database named `nyc311`.

If using an environment variable:

```bash
export DATABASE_URL="postgresql://localhost/nyc311"
```

Do not commit credentials or local secrets.

## 6. Run the manual pipeline

From the repository root:

```bash
cd nyc311_manual
bash run_pipeline.sh
```

The manual pipeline runs the following layers:

```text
raw → ingest → staging → warehouse → analytics → validation
```

Some ingestion and raw table creation steps may be commented out in `run_pipeline.sh` depending on whether the raw table and source data already exist locally.

## 7. Run dbt models

The dbt project assumes the raw NYC 311 table already exists in PostgreSQL.

From the repository root:

```bash
cd nyc311_dbt
dbt debug
dbt build
```

To run only tests:

```bash
dbt test
```

To generate dbt docs:

```bash
dbt docs generate
dbt docs serve
```

## 8. dbt credentials

dbt database credentials should live in:

```text
~/.dbt/profiles.yml
```

Do not commit `profiles.yml`.

A password can be provided through an environment variable:

```yaml
password: "{{ env_var('DBT_POSTGRES_PASSWORD') }}"
```

Then locally:

```bash
export DBT_POSTGRES_PASSWORD='your_password_here'
dbt debug
```

## Optional: pgvector / semantic enrichment

Earlier experiments explored semantic enrichment using embeddings. That extension is optional and is not required for the core pipeline.

If used later, it may require:

```sql
CREATE EXTENSION IF NOT EXISTS vector;
```