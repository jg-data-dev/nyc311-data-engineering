-- tests/migration/assert_dim_date_keys_match_public.sql

WITH public_keys AS (
    SELECT
        full_date
    FROM public.dim_date
),

dbt_keys AS (
    SELECT
        full_date
    FROM {{ ref('dim_date') }}
),

missing_from_dbt AS (
    SELECT
        'missing_from_dbt' AS issue,
        full_date
    FROM public_keys

    EXCEPT

    SELECT
        'missing_from_dbt' AS issue,
        full_date
    FROM dbt_keys
),

extra_in_dbt AS (
    SELECT
        'extra_in_dbt' AS issue,
        full_date
    FROM dbt_keys

    EXCEPT

    SELECT
        'extra_in_dbt' AS issue,
        full_date
    FROM public_keys
)

SELECT * FROM missing_from_dbt
UNION ALL
SELECT * FROM extra_in_dbt
