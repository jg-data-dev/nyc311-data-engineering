-- tests/migration/assert_fct_borough_complaint_mix_keys_match_public.sql

WITH public_keys AS (
    SELECT
        borough,
        complaint_type
    FROM public.fct_borough_complaint_mix
),

dbt_keys AS (
    SELECT
        borough,
        complaint_type
    FROM {{ ref('fct_borough_complaint_mix') }}
),

missing_from_dbt AS (
    SELECT
        'missing_from_dbt' AS issue,
        borough,
        complaint_type
    FROM public_keys

    EXCEPT

    SELECT
        'missing_from_dbt' AS issue,
        borough,
        complaint_type
    FROM dbt_keys
),

extra_in_dbt AS (
    SELECT
        'extra_in_dbt' AS issue,
        borough,
        complaint_type
    FROM dbt_keys

    EXCEPT

    SELECT
        'extra_in_dbt' AS issue,
        borough,
        complaint_type
    FROM public_keys
)

SELECT * FROM missing_from_dbt
UNION ALL
SELECT * FROM extra_in_dbt
