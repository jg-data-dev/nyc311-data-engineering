                    Git repository
        ┌─────────────────────────────────┐
        │ Python code │ DAGs │ dbt models │
        └─────────────────────────────────┘
                         │ deployed to
                         ▼
                  Airflow environment
             scheduler + task workers
                  │               │
          runs Python          runs dbt
                  │               │
                  ▼               ▼
            NYC 311 API       dbt-bigquery
                  │               │
                  └──────┬────────┘
                         ▼
                      BigQuery
        raw tables → staging tables → marts

# Run
1. source venv/bin/activate
2. Install requirements.
      python -m pip install google-cloud-bigquery requests
3. Install gcloud CLI system-wide.
      gcloud auth application-default login
4. Authenticate with Application Default Credentials.
5. Set the default Google Cloud project.
6. Create the BigQuery dataset.
7. Run ingestion.
8. Run dbt models and tests.
9. Start Airflow
      source ~/airflow-venv/bin/activate
      airflow standalone
      login: cat /Users/janeguo/airflow/simple_auth_manager_passwords.json.generated
{"admin": "p7gTQUazndknN3Pq"}
      <!-- export AIRFLOW__CORE__DAGS_FOLDER="$HOME/airflow/dags"
      airflow config get-value core dags_folder
      or ~/airflow/run_airflow.sh -->
10. run bigquery integrated DAG


# Work log
- installed gcloud CLI
- ran `gcloud auth application-default login`
- enabled billing use to merge query function
- deleted manually created malformed raw tables
- ingestion script recreated schema correctly
- installed `dbt-bigquery`
- ran `rehash` because shell cached old dbt
- created local `profiles.yml`
      export DBT_PROFILES_DIR="$PWD"
      dbt debug
- fixed Postgres SQL for BigQuery

- `dbt run` passes
      gcloud config set project nyc311-502315
      gcloud config get-value project
- `dbt test` passes
- added airflow DAG
- simlinked dags from each project folder so all dags show up
      ln -sf \
  /Users/janeguo/Desktop/nyc311_project/v4_cloud/dags/nyc311_bigquery.py \
  /Users/janeguo/airflow/dags/nyc311_project_dags/nyc311_v4.py
  ln -sf \
  /Users/janeguo/Desktop/nyc311_project/v3_airflow/dags/nyc311_postgres.py \
  /Users/janeguo/airflow/dags/nyc311_project_dags/nyc311_v3.py
      