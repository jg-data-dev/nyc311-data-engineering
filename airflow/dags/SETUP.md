<!-- Activate the Airflow virtual environment --> -->
source airflow-venv/bin/activate

<!-- Confirm Airflow is available: -->
airflow version

<!-- Confirm Airflow metadata DB location -->
airflow config get-value database sql_alchemy_conn

<!-- Start Airflow locally -->
airflow standalone

<!-- Airflow login -->
cat /Users/janeguo/airflow/simple_auth_manager_passwords.json.generated
http://localhost:8080


<!-- Trigger a production run -->
DAG name: nyc311_daily_pipeline

<!-- Trigger a test run -->
{
  "test": true,
  "reset_probe": true
}

<!-- Trigger with an explicit target date -->

{
  "test": true,
  "reset_probe": true,
  "target_date": "2026-01-01"
}

<!-- Trigger from CLI -->

airflow dags trigger nyc311_daily_pipeline --conf '{}'

airflow dags trigger nyc311_daily_pipeline \
  --conf '{"test": true}'

airflow dags trigger nyc311_daily_pipeline \
  --conf '{"test": true, "reset_probe": true}'

airflow dags trigger nyc311_daily_pipeline \
  --conf '{"test": true, "reset_probe": true, "target_date": "2026-05-10"}'

<!-- Check DAG runs from CLI -->
airflow dags list-runs -d nyc311_daily_pipeline

<!-- Check task logs -->
airflow tasks logs nyc311_daily_pipeline dbt_run <run_id>
Replace <run_id> with the run ID shown by airflow dags list-runs.