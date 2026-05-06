-- tests/migration/assert_dim_location_row_count_matches_public.sql

SELECT
    'dim_location' AS model_name,
    public_count,
    dbt_count
FROM (
    SELECT
        (SELECT COUNT(*) FROM public.dim_location) AS public_count,
        (SELECT COUNT(*) FROM {{ ref('dim_location') }}) AS dbt_count
) counts
WHERE public_count <> dbt_count
