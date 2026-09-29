-- tests/migration/assert_fct_monthly_metrics_columns_match_public.sql

WITH public_columns AS (
    SELECT
        column_name,
        data_type
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'fct_monthly_metrics'
),

dbt_columns AS (
    SELECT
        column_name,
        data_type
    FROM information_schema.columns
    WHERE table_schema = '{{ target.schema }}'
      AND table_name = 'fct_monthly_metrics'
),

missing_or_different_in_dbt AS (
    SELECT
        'missing_or_different_in_dbt' AS issue,
        column_name,
        data_type
    FROM public_columns

    EXCEPT

    SELECT
        'missing_or_different_in_dbt' AS issue,
        column_name,
        data_type
    FROM dbt_columns
),

extra_or_different_in_dbt AS (
    SELECT
        'extra_or_different_in_dbt' AS issue,
        column_name,
        data_type
    FROM dbt_columns

    EXCEPT

    SELECT
        'extra_or_different_in_dbt' AS issue,
        column_name,
        data_type
    FROM public_columns
)

SELECT * FROM missing_or_different_in_dbt
UNION ALL
SELECT * FROM extra_or_different_in_dbt
