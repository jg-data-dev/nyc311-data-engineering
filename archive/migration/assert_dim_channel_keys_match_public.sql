-- tests/migration/assert_dim_channel_keys_match_public.sql

WITH public_keys AS (
    SELECT
        open_data_channel_type
    FROM public.dim_channel
),

dbt_keys AS (
    SELECT
        open_data_channel_type
    FROM {{ ref('dim_channel') }}
),

missing_from_dbt AS (
    SELECT
        'missing_from_dbt' AS issue,
        open_data_channel_type
    FROM public_keys

    EXCEPT

    SELECT
        'missing_from_dbt' AS issue,
        open_data_channel_type
    FROM dbt_keys
),

extra_in_dbt AS (
    SELECT
        'extra_in_dbt' AS issue,
        open_data_channel_type
    FROM dbt_keys

    EXCEPT

    SELECT
        'extra_in_dbt' AS issue,
        open_data_channel_type
    FROM public_keys
)

SELECT * FROM missing_from_dbt
UNION ALL
SELECT * FROM extra_in_dbt
