# “What is this system and how does it work?”
A small data pipeline that ingests NYC 311 data, models it into structured tables, and supports both SQL and semantic querying.

# Workflow
1. Ingest NYC 311 data from the Socrata API
2. Store raw data in Postgres
3. Clean / standardize data into staging tables
4. Model data into fact/dimension tables 
5. Analytics: run SQL analytics 
6. (optional) Run semantic analysis using an LLM

            ┌──────────────────────┐
            │   NYC 311 API        │
            └─────────┬────────────┘
                      ↓
            ┌──────────────────────┐
            │   ingest.py          │
            │ (API → Postgres)     │
            └─────────┬────────────┘
                      ↓
            ┌──────────────────────┐
            │ raw_311_requests     │
            │ (source of truth)    │
            └─────────┬────────────┘
                      ↓
            ┌──────────────────────┐
            │ stage.sql / stage.py │
            │ (clean + standardize│
            └─────────┬────────────┘
                      ↓
            ┌──────────────────────┐
            │ stg_311_requests     │
            └─────────┬────────────┘
                      ↓
            ┌──────────────────────┐
            │ fact_complaints      │
            │ dim_* tables         │
            └─────────┬────────────┘
                      ↓
            ┌──────────────────────┐
            │ analytics queries    │   ← YOU ARE HERE
            │ (metrics, patterns)  │
            └─────────┬────────────┘
                      ↓
            ┌──────────────────────┐
            │ output layer         │
            │ (script / report)    │
            └─────────┬────────────┘
                      ↓
            ┌──────────────────────┐
            │ orchestration        │   ← FINAL STEP
            │ (Airflow / cron)     │
            └──────────────────────┘
            
# Automation/Orchestration
create_tables.sql
ingest.py
validate_raw.sql
stage.sql
validate_stage.sql
star_schema.sql
validate_star_schema.sql
-> NEXT: analytics

# Design goals
- Keep the pipeline manually runnable end-to-end
- Make reruns safe (idempotent where possible)
- Keep each stage conceptually separate

# Next Steps
- modelling: build tables
- performance: experiment 1M row, incl/excl raw_json in staging
- data quality tracking / documentation, e.g. null dates in original
# Future extension
- Automate daily ingestion and analytics after the manual workflow is stable