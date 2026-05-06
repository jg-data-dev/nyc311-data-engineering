-- tests/migration/assert_fct_311_complaint_row_count_matches_public.sql

SELECT
    'fct_311_complaint' AS model_name,
    public_count,
    dbt_count
FROM (
    SELECT
        (SELECT COUNT(*) FROM public.fact_311_complaint) AS public_count,
        (SELECT COUNT(*) FROM {{ ref('fct_311_complaint') }}) AS dbt_count
) counts
WHERE public_count <> dbt_count
