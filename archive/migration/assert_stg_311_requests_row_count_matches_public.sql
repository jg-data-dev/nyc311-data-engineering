-- tests/migration/assert_stg_311_requests_row_count_matches_public.sql

SELECT
    'stg_311_requests' AS model_name,
    public_count,
    dbt_count
FROM (
    SELECT
        (SELECT COUNT(*) FROM public.stg_311_requests) AS public_count,
        (SELECT COUNT(*) FROM {{ ref('stg_311_requests') }}) AS dbt_count
) counts
WHERE public_count <> dbt_count
