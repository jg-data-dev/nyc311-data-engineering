#!/usr/bin/env bash

set -e  # stop on error

DB_NAME="nyc311"
PSQL="psql -d $DB_NAME"

echo "== Step 1: Create tables =="
$PSQL -f sql/create_tables.sql

echo "== Step 2: Ingest raw data ($(date)) =="
python ingest.py

echo "== Step 3: Validate raw =="
$PSQL -f sql/validate_raw.sql

echo "== Step 4: Stage data =="
$PSQL -f sql/stage.sql

echo "== Step 5: Validate stage =="
$PSQL -f sql/validate_stage.sql

echo "== Step 6: Build star schema =="
$PSQL -f sql/star_schema.sql

echo "== Step 7: Validate star schema =="
$PSQL -f sql/validate_star_schema.sql

echo "== Step 8: Compile analytics and export CSVs =="
python -m analyze.analyze --export-csv

echo "== Step 9: Validate analytics =="
$PSQL -f analyze/validate/validate_data.sql

echo "== Pipeline complete =="

