#!/usr/bin/env bash

set -e  # stop on error

DB_NAME="nyc311"
PSQL="psql -d $DB_NAME"

# echo "== Step 1: Create raw table =="
# $PSQL -f raw/raw.sql

# echo "== Step 2: Ingest raw data ($(date)) =="
# python -m ingest.ingest --target-date 2026-05-06

echo "== Step 3: Validate raw =="
$PSQL -f raw/validate_raw.sql

# echo "== Step 4: Build staging =="
# $PSQL -f staging/staging.sql

echo "== Step 5: Validate staging =="
$PSQL -f staging/validate_staging.sql

# echo "== Step 6: Build warehouse =="
# $PSQL -f warehouse/warehouse.sql

echo "== Step 7: Validate warehouse =="
$PSQL -f warehouse/validate_warehouse.sql

echo "== Step 8: Compile analytics and export CSVs =="
python -m analytics.analyze --export-csv

echo "== Step 9: Validate analytics =="
$PSQL -f analytics/standard/validate/validate_analytics.sql

echo "== Pipeline complete =="