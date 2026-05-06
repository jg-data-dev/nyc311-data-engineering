-- tests/migration_assert_fct_monthly_metrics_keys_match_public.sql

WITH public_keys AS (
    SELECT month_start
    FROM public.fct_monthly_metrics
),

dbt_keys AS (
    SELECT month_start
    FROM {{ ref('fct_monthly_metrics') }}
),

missing_from_dbt AS (
    SELECT
        'missing_from_dbt' AS issue,
        month_start
    FROM public_keys
    EXCEPT
    SELECT
        'missing_from_dbt' AS issue,
        month_start
    FROM dbt_keys
),

extra_in_dbt AS (
    SELECT
        'extra_in_dbt' AS issue,
        month_start
    FROM dbt_keys
    EXCEPT
    SELECT
        'extra_in_dbt' AS issue,
        month_start
    FROM public_keys
)

SELECT * FROM missing_from_dbt
UNION ALL
SELECT * FROM extra_in_dbt