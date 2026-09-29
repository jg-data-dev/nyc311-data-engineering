-- tests/migration/assert_fct_daily_metrics_keys_match_public.sql

WITH public_keys AS (
    SELECT
        metric_date
    FROM public.fct_daily_metrics
),

dbt_keys AS (
    SELECT
        metric_date
    FROM {{ ref('fct_daily_metrics') }}
),

missing_from_dbt AS (
    SELECT
        'missing_from_dbt' AS issue,
        metric_date
    FROM public_keys

    EXCEPT

    SELECT
        'missing_from_dbt' AS issue,
        metric_date
    FROM dbt_keys
),

extra_in_dbt AS (
    SELECT
        'extra_in_dbt' AS issue,
        metric_date
    FROM dbt_keys

    EXCEPT

    SELECT
        'extra_in_dbt' AS issue,
        metric_date
    FROM public_keys
)

SELECT * FROM missing_from_dbt
UNION ALL
SELECT * FROM extra_in_dbt
