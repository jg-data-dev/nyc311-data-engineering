--1. Daily/monthly row counts are nonzero

SELECT 'daily_metrics_nonzero' AS check_name, COUNT(*) AS row_count
FROM fct_daily_metrics;

SELECT 'monthly_metrics_nonzero' AS check_name, COUNT(*) AS row_count
FROM fct_monthly_metrics;

SELECT 'borough_complaint_mix_nonzero' AS check_name, COUNT(*) AS row_count
FROM fct_borough_complaint_mix;


--2. Daily totals reconcile to intermediate table
SELECT
  'daily_created_count_matches_int' AS check_name,
  (SELECT SUM(created_count) FROM fct_daily_metrics)
  -
  (SELECT COUNT(*) FROM int_complaints_flagged WHERE created_at IS NOT NULL)
AS diff;

-- 3. Monthly totals reconcile to intermediate table
SELECT
  'monthly_created_count_matches_int' AS check_name,
  (SELECT SUM(created_count) FROM fct_monthly_metrics)
  -
  (SELECT COUNT(*) FROM int_complaints_flagged WHERE created_at IS NOT NULL)
AS diff;


-- 4. Complaint mix totals reconcile
SELECT
  'borough_complaint_mix_total_matches_int' AS check_name,
  (SELECT SUM(total_requests) FROM fct_borough_complaint_mix)
  -
  (SELECT COUNT(*) FROM int_complaints_flagged WHERE created_at IS NOT NULL)
AS diff;


-- 5. Percent sanity for complaint mix
SELECT
  'borough_complaint_mix_exact_pct_sum' AS check_name,
  ROUND(
    SUM(total_requests)::numeric
    / (SELECT SUM(total_requests) FROM fct_borough_complaint_mix)
    * 100,
    2
  ) AS pct_sum
FROM fct_borough_complaint_mix;

-- 6.Check no null dates in metric tables:

SELECT
  'daily_null_metric_date' AS check_name,
  COUNT(*) AS issue_count
FROM fct_daily_metrics
WHERE metric_date IS NULL;

SELECT
  'monthly_null_month_start' AS check_name,
  COUNT(*) AS issue_count
FROM fct_monthly_metrics
WHERE month_start IS NULL;