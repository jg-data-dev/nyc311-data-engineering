-- tests/migration/assert_dim_status_keys_match_public.sql

WITH public_keys AS (
    SELECT
        status
    FROM public.dim_status
),

dbt_keys AS (
    SELECT
        status
    FROM {{ ref('dim_status') }}
),

missing_from_dbt AS (
    SELECT
        'missing_from_dbt' AS issue,
        status
    FROM public_keys

    EXCEPT

    SELECT
        'missing_from_dbt' AS issue,
        status
    FROM dbt_keys
),

extra_in_dbt AS (
    SELECT
        'extra_in_dbt' AS issue,
        status
    FROM dbt_keys

    EXCEPT

    SELECT
        'extra_in_dbt' AS issue,
        status
    FROM public_keys
)

SELECT * FROM missing_from_dbt
UNION ALL
SELECT * FROM extra_in_dbt
