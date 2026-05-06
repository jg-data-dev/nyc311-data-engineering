-- tests/migration/assert_dim_date_row_count_matches_public.sql

SELECT
    'dim_date' AS model_name,
    public_count,
    dbt_count
FROM (
    SELECT
        (SELECT COUNT(*) FROM public.dim_date) AS public_count,
        (SELECT COUNT(*) FROM {{ ref('dim_date') }}) AS dbt_count
) counts
WHERE public_count <> dbt_count
