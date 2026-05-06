-- tests/migration/assert_dim_agency_keys_match_public.sql

WITH public_keys AS (
    SELECT
        agency,
        agency_name
    FROM public.dim_agency
),

dbt_keys AS (
    SELECT
        agency,
        agency_name
    FROM {{ ref('dim_agency') }}
),

missing_from_dbt AS (
    SELECT
        'missing_from_dbt' AS issue,
        agency,
        agency_name
    FROM public_keys

    EXCEPT

    SELECT
        'missing_from_dbt' AS issue,
        agency,
        agency_name
    FROM dbt_keys
),

extra_in_dbt AS (
    SELECT
        'extra_in_dbt' AS issue,
        agency,
        agency_name
    FROM dbt_keys

    EXCEPT

    SELECT
        'extra_in_dbt' AS issue,
        agency,
        agency_name
    FROM public_keys
)

SELECT * FROM missing_from_dbt
UNION ALL
SELECT * FROM extra_in_dbt
