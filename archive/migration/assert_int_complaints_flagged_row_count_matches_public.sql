-- tests/migration/assert_int_complaints_flagged_row_count_matches_public.sql

SELECT
    'int_complaints_flagged' AS model_name,
    public_count,
    dbt_count
FROM (
    SELECT
        (SELECT COUNT(*) FROM public.int_complaints_flagged) AS public_count,
        (SELECT COUNT(*) FROM {{ ref('int_complaints_flagged') }}) AS dbt_count
) counts
WHERE public_count <> dbt_count
