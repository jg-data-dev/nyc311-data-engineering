-- tests/migration/assert_dim_agency_row_count_matches_public.sql

SELECT
    'dim_agency' AS model_name,
    public_count,
    dbt_count
FROM (
    SELECT
        (SELECT COUNT(*) FROM public.dim_agency) AS public_count,
        (SELECT COUNT(*) FROM {{ ref('dim_agency') }}) AS dbt_count
) counts
WHERE public_count <> dbt_count
