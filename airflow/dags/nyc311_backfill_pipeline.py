"""
Example trigger config:

Probe backfill, reset probe:
{
  "test": true,
  "reset_probe": true,
  "start_date": "2024-01-01",
  "end_date": "2024-01-31"
}

Probe backfill, do not reset probe:
{
  "test": true,
  "reset_probe": false,
  "start_date": "2024-01-01",
  "end_date": "2024-01-31"
}

Production backfill:
{
  "test": false,
  "start_date": "2024-01-01",
  "end_date": "2024-01-31"
}
"""

from __future__ import annotations

from datetime import timedelta

import pendulum

from airflow import DAG
from airflow.operators.bash import BashOperator


PROJECT_DIR = "/Users/janeguo/batch_python/4_nyc311"
DBT_DIR = f"{PROJECT_DIR}/nyc311_dbt"
DBT_BIN = "/Users/janeguo/miniforge3/bin/dbt"
PYTHON_BIN = f"{PROJECT_DIR}/venv/bin/python"

POOL_NAME = "nyc311_main_warehouse_pool"


RAW_TABLE_BASH = """
TEST_MODE="{{ dag_run.conf.get('test', false) if dag_run else false }}"

case "$TEST_MODE" in
    True|true|"true"|1|"1")
        RAW_TABLE="raw_311_requests_probe"
        ;;
    False|false|"false"|0|"0"|"")
        RAW_TABLE="raw_311_requests"
        ;;
    *)
        echo "Invalid test value: $TEST_MODE"
        echo "Use true or false."
        exit 1
        ;;
esac

echo "TEST_MODE=$TEST_MODE"
echo "Using RAW_TABLE=$RAW_TABLE"
"""


RESET_PROBE_BASH = """
RESET_PROBE="{{ dag_run.conf.get('reset_probe', false) if dag_run else false }}"

case "$RESET_PROBE" in
    True|true|"true"|1|"1")
        RESET_PROBE="true"
        ;;
    False|false|"false"|0|"0"|"")
        RESET_PROBE="false"
        ;;
    *)
        echo "Invalid reset_probe value: $RESET_PROBE"
        echo "Use true or false."
        exit 1
        ;;
esac

echo "RESET_PROBE=$RESET_PROBE"
"""


DATE_RANGE_BASH = """
START_DATE="{{ dag_run.conf.get('start_date') if dag_run and dag_run.conf.get('start_date') else '' }}"
END_DATE="{{ dag_run.conf.get('end_date') if dag_run and dag_run.conf.get('end_date') else '' }}"

if [ -z "$START_DATE" ] || [ -z "$END_DATE" ]; then
    echo "Missing required backfill date range."
    echo "Provide both start_date and end_date in dag_run.conf, e.g.:"
    echo '{"start_date": "2024-01-01", "end_date": "2024-01-31"}'
    exit 1
fi

echo "START_DATE=$START_DATE"
echo "END_DATE=$END_DATE"
"""


with DAG(
    dag_id="nyc311_backfill_pipeline",
    description="Manual NYC 311 historical backfill pipeline for a supplied date range.",
    start_date=pendulum.datetime(2026, 5, 1, tz="America/New_York"),
    schedule=None,
    catchup=False,
    max_active_runs=1,
    tags=["nyc311", "dbt", "analytics-engineering", "backfill"],
) as dag:

    ensure_raw_tables = BashOperator(
        task_id="ensure_raw_tables",
        bash_command=f"""
        set -euo pipefail
        cd {PROJECT_DIR}

        psql -v ON_ERROR_STOP=1 \
             -d nyc311 \
             -f nyc311_manual/raw/raw.sql
        """,
        pool=POOL_NAME,
        execution_timeout=timedelta(minutes=10),
    )

    reset_probe_raw = BashOperator(
        task_id="reset_probe_raw",
        bash_command=f"""
        set -euo pipefail
        cd {PROJECT_DIR}

        {RAW_TABLE_BASH}
        {RESET_PROBE_BASH}

        if [ "$RAW_TABLE" = "raw_311_requests_probe" ] && [ "$RESET_PROBE" = "true" ]; then
            echo "Resetting probe raw table"
            psql -v ON_ERROR_STOP=1 \
                 -d nyc311 \
                 -f nyc311_manual/raw/reset_raw_probe.sql
        else
            echo "Not resetting probe raw table"
        fi
        """,
        pool=POOL_NAME,
        execution_timeout=timedelta(minutes=10),
    )

    ingest_backfill = BashOperator(
        task_id="ingest_backfill",
        bash_command=f"""
        set -euo pipefail
        cd {PROJECT_DIR}

        {RAW_TABLE_BASH}
        {DATE_RANGE_BASH}

        {PYTHON_BIN} -m nyc311_manual.ingest.ingest \
            --start-date "$START_DATE" \
            --end-date "$END_DATE" \
            --target-table "$RAW_TABLE"
        """,
        pool=POOL_NAME,
        execution_timeout=timedelta(hours=23),
        retries=0,
    )

    validate_raw = BashOperator(
        task_id="validate_raw",
        bash_command=f"""
        set -euo pipefail
        cd {PROJECT_DIR}

        {RAW_TABLE_BASH}

        psql -v ON_ERROR_STOP=1 \
             -v raw_table="$RAW_TABLE" \
             -d nyc311 \
             -f nyc311_manual/raw/validate_raw.sql
        """,
        pool=POOL_NAME,
        execution_timeout=timedelta(minutes=30),
    )

    dbt_run = BashOperator(
        task_id="dbt_run",
        bash_command=f"""
        set -euo pipefail
        cd {DBT_DIR}

        {RAW_TABLE_BASH}

        NYC311_RAW_TABLE="$RAW_TABLE" {DBT_BIN} run
        """,
        pool=POOL_NAME,
        execution_timeout=timedelta(hours=2),
    )

    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command=f"""
        set -euo pipefail
        cd {DBT_DIR}

        {RAW_TABLE_BASH}

        NYC311_RAW_TABLE="$RAW_TABLE" {DBT_BIN} test --exclude tests/migration
        """,
        pool=POOL_NAME,
        execution_timeout=timedelta(hours=1),
    )

    ensure_raw_tables >> reset_probe_raw >> ingest_backfill >> validate_raw >> dbt_run >> dbt_test