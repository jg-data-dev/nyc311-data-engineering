-- tests/migration/assert_fct_monthly_metrics_row_count_matches_public.sql

SELECT
    'fct_monthly_metrics' AS model_name,
    public_count,
    dbt_count
FROM (
    SELECT
        (SELECT COUNT(*) FROM public.fct_monthly_metrics) AS public_count,
        (SELECT COUNT(*) FROM {{ ref('fct_monthly_metrics') }}) AS dbt_count
) counts
WHERE public_count <> dbt_count
