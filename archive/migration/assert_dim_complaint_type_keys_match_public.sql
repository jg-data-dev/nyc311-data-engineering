-- tests/migration/assert_dim_complaint_type_keys_match_public.sql

WITH public_keys AS (
    SELECT
        complaint_type
    FROM public.dim_complaint_type
),

dbt_keys AS (
    SELECT
        complaint_type
    FROM {{ ref('dim_complaint_type') }}
),

missing_from_dbt AS (
    SELECT
        'missing_from_dbt' AS issue,
        complaint_type
    FROM public_keys

    EXCEPT

    SELECT
        'missing_from_dbt' AS issue,
        complaint_type
    FROM dbt_keys
),

extra_in_dbt AS (
    SELECT
        'extra_in_dbt' AS issue,
        complaint_type
    FROM dbt_keys

    EXCEPT

    SELECT
        'extra_in_dbt' AS issue,
        complaint_type
    FROM public_keys
)

SELECT * FROM missing_from_dbt
UNION ALL
SELECT * FROM extra_in_dbt
