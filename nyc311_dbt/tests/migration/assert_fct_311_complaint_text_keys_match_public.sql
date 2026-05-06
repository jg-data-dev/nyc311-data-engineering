-- tests/migration/assert_fct_311_complaint_text_keys_match_public.sql

WITH public_keys AS (
    SELECT
        unique_key
    FROM public.fact_311_complaint_text
),

dbt_keys AS (
    SELECT
        unique_key
    FROM {{ ref('fct_311_complaint_text') }}
),

missing_from_dbt AS (
    SELECT
        'missing_from_dbt' AS issue,
        unique_key
    FROM public_keys

    EXCEPT

    SELECT
        'missing_from_dbt' AS issue,
        unique_key
    FROM dbt_keys
),

extra_in_dbt AS (
    SELECT
        'extra_in_dbt' AS issue,
        unique_key
    FROM dbt_keys

    EXCEPT

    SELECT
        'extra_in_dbt' AS issue,
        unique_key
    FROM public_keys
)

SELECT * FROM missing_from_dbt
UNION ALL
SELECT * FROM extra_in_dbt
