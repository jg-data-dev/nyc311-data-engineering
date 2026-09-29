#!/usr/bin/env bash

set -euo pipefail

# Always run from the version root
cd "$(dirname "$0")"

# Load version-level config
set -a
source .env
set +a

DB_NAME="${PROJECT_DB:-nyc311_v3}"
PSQL="psql -d $DB_NAME"

echo "== Using database: $DB_NAME =="

echo "== Step 1: Create raw table =="
$PSQL -f raw/raw.sql

echo "== Step 2: Ingest raw data ($(date)) =="
python -m ingest.ingest "$@"

echo "== Step 3: Validate raw =="
$PSQL -f raw/validate_raw.sql

echo "== Step 4: dbt debug =="
dbt debug

echo "== Step 5: dbt models =="
dbt run

echo "== Step 6: dbt tests =="
dbt test

echo "== Pipeline complete =="