-- tests/migration/assert_int_complaints_flagged_keys_match_public.sql

WITH public_keys AS (
    SELECT
        unique_key
    FROM public.int_complaints_flagged
),

dbt_keys AS (
    SELECT
        unique_key
    FROM {{ ref('int_complaints_flagged') }}
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
