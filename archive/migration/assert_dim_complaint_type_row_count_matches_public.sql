-- tests/migration/assert_dim_complaint_type_row_count_matches_public.sql

SELECT
    'dim_complaint_type' AS model_name,
    public_count,
    dbt_count
FROM (
    SELECT
        (SELECT COUNT(*) FROM public.dim_complaint_type) AS public_count,
        (SELECT COUNT(*) FROM {{ ref('dim_complaint_type') }}) AS dbt_count
) counts
WHERE public_count <> dbt_count
