-- tests/migration/assert_fct_borough_complaint_mix_row_count_matches_public.sql

SELECT
    'fct_borough_complaint_mix' AS model_name,
    public_count,
    dbt_count
FROM (
    SELECT
        (SELECT COUNT(*) FROM public.fct_borough_complaint_mix) AS public_count,
        (SELECT COUNT(*) FROM {{ ref('fct_borough_complaint_mix') }}) AS dbt_count
) counts
WHERE public_count <> dbt_count
