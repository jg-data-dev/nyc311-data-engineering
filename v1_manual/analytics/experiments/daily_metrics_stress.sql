 /* Metrics Stress Test
 */

-- Sanity: number of days
SELECT COUNT(*) FROM fct_daily_metrics;
/* as expected
count 
-------
    16
(1 row)
 */

-- Stress: distribution of cases per day
SELECT metric_date, created_count
FROM fct_daily_metrics
ORDER BY created_count DESC;
SELECT metric_date, created_count,
    ROUND(
        (created_count * 100.0) / SUM(created_count) OVER (),
        2) AS percent
FROM fct_daily_metrics
ORDER BY percent DESC;

/* even distribution:
metric_date | created_count | percent 
-------------+---------------+---------
 2020-01-02  |          7509 |    7.51
 2020-01-09  |          7334 |    7.33
 2020-01-06  |          7119 |    7.12
 2020-01-13  |          6952 |    6.95
 2020-01-07  |          6781 |    6.78
 2020-01-14  |          6701 |    6.70
 2020-01-10  |          6647 |    6.65
 2020-01-08  |          6600 |    6.60
 2020-01-03  |          6547 |    6.55
 2020-01-15  |          6410 |    6.41
 2020-01-11  |          5766 |    5.77
 2020-01-12  |          5573 |    5.57
 2020-01-05  |          5511 |    5.51
 2020-01-04  |          5262 |    5.26
 2020-01-01  |          5010 |    5.01
 2020-01-16  |          4278 |    4.28
(16 rows)
 */


-- Sanity & Stress: daily net case flow
SELECT
    metric_date,
    created_count,
    closed_count,
    (closed_count * 100.0) /created_count as pct_close_rate, -- Stress
    (created_count - closed_count) as diff, -- Sanity
    daily_net_case_flow
FROM fct_daily_metrics;

-- Stress: daily net case flow
-- use the day with the highest closed cases for example

SELECT
    count(*)
FROM fact_311_complaint
WHERE created_at IS NOT NULL AND DATE(closed_at) = DATE(created_at);

-- 2033 cases closed the same day
SELECT 
    count(*)
FROM fact_311_complaint
WHERE DATE(created_at) = '2020-01-02'
and closed_at>created_at
and date(closed_at) = date(created_at);

-- WARN: 147 cases closed instantly!
SELECT 
    count(*)
FROM fact_311_complaint
WHERE DATE(created_at) = '2020-01-02'
and closed_at=created_at;

-- Inspect further, variety of complaints types, and no single reason
SELECT 
    c.complaint_type,
    f.created_at,
    f.closed_at,
    t.resolution_description
FROM fact_311_complaint f
JOIN dim_complaint_type c
ON f.complaint_type_id = c.complaint_type_id
JOIN fact_311_complaint_text t
ON f.unique_key = t.unique_key
WHERE DATE(f.created_at) = '2020-01-02'
and f.closed_at=f.created_at;

/*  metric_date | created_count | closed_count |   pct_close_rate    | diff | daily_net_case_flow 
-------------+---------------+--------------+---------------------+------+---------------------
 2020-01-01  |          5010 |         4973 | 99.2614770459081836 |   37 |                  37
 2020-01-02  |          7509 |         7163 | 95.3921960314289519 |  346 |                 346
 2020-01-03  |          6547 |         6411 | 97.9227126928364136 |  136 |                 136
 2020-01-04  |          5262 |         5220 | 99.2018244013683010 |   42 |                  42
 2020-01-05  |          5511 |         5476 | 99.3649065505352931 |   35 |                  35
 2020-01-06  |          7119 |         6968 | 97.8789155780306223 |  151 |                 151
 2020-01-07  |          6781 |         6715 | 99.0266922282849137 |   66 |                  66
 2020-01-08  |          6600 |         6510 | 98.6363636363636364 |   90 |                  90
 2020-01-09  |          7334 |         7260 | 98.9910008181074448 |   74 |                  74
 2020-01-10  |          6647 |         6482 | 97.5176771475853769 |  165 |                 165
 2020-01-11  |          5766 |         5704 | 98.9247311827956989 |   62 |                  62
 2020-01-12  |          5573 |         5519 | 99.0310425264668940 |   54 |                  54
 2020-01-13  |          6952 |         6741 | 96.9649021864211738 |  211 |                 211
 2020-01-14  |          6701 |         6480 | 96.7019847783912849 |  221 |                 221
 2020-01-15  |          6410 |         6290 | 98.1279251170046802 |  120 |                 120
 2020-01-16  |          4278 |         4217 | 98.5741000467508181 |   61 |                  61
(16 rows)
 */

-- Stress: resolution hour
SELECT
    avg_resolution_hours,
    median_resolution_hours,
    p90_resolution_hours,
    p95_resolution_hours
FROM fct_daily_metrics;
   avg_resolution_hours    | median_resolution_hours | p90_resolution_hours 
/* WARN: extreme tail skew average
avg_resolution_hours | median_resolution_hours | p90_resolution_hours | p95_resolution_hours 
----------------------+-------------------------+----------------------+----------------------
               828.85 |                   10.38 |               173.36 |              1038.03
               947.37 |                   30.97 |               505.01 |              1536.35
               627.53 |                   27.97 |               427.38 |              1162.79
               580.89 |                   25.86 |               262.18 |               874.98
               470.99 |                   22.49 |               200.95 |               612.12
              1646.08 |                   29.54 |              1023.93 |             16667.89
               612.55 |                   23.15 |               359.98 |              1075.87
              1042.33 |                   24.22 |               501.55 |              2341.33
              1246.77 |                   26.24 |               548.73 |              3313.65
               685.89 |                   24.00 |               427.86 |              1286.71
               565.92 |                    8.34 |               267.08 |               812.73
               606.60 |                   10.61 |               237.51 |               798.46
               747.41 |                   23.95 |               483.67 |              1395.60
               801.27 |                   24.00 |               492.13 |              1325.19
               712.00 |                   20.94 |               481.56 |              1347.10
               735.63 |                   24.93 |               610.93 |              1326.99
(16 rows)
 */

/* Sanity: time bucketing works */
SELECT
    metric_date,
    created_count,
    SUM(created_morning_count + created_afternoon_count + created_evening_count + created_overnight_count) AS total
FROM fct_daily_metrics
GROUP BY metric_date, created_count
ORDER BY metric_date;
/* as expected
metric_date | created_count | total 
-------------+---------------+-------
 2020-01-01  |          5010 |  5010
 2020-01-02  |          7509 |  7509
 2020-01-03  |          6547 |  6547
 2020-01-04  |          5262 |  5262
 2020-01-05  |          5511 |  5511
 2020-01-06  |          7119 |  7119
 2020-01-07  |          6781 |  6781
 2020-01-08  |          6600 |  6600
 2020-01-09  |          7334 |  7334
 2020-01-10  |          6647 |  6647
 2020-01-11  |          5766 |  5766
 2020-01-12  |          5573 |  5573
 2020-01-13  |          6952 |  6952
 2020-01-14  |          6701 |  6701
 2020-01-15  |          6410 |  6410
 2020-01-16  |          4278 |  4278
(16 rows)
*/

/* Stress: distribution of time bucketing */
SELECT
    metric_date,
    ROUND(
        (created_morning_count * 100.0) / created_count,
        2) AS percent_morn,
    ROUND(
        (created_afternoon_count * 100.0) / created_count,
        2) AS percent_aft,
    ROUND(
        (created_evening_count * 100.0) / created_count,
        2) AS percent_eve,
    ROUND(
        (created_overnight_count * 100.0) / created_count,
        2) AS percent_night
FROM fct_daily_metrics;
/* night time generally have fewer cases, 2020-01-16 has no case in the evening
metric_date | percent_morn | percent_aft | percent_eve | percent_night 
-------------+--------------+-------------+-------------+---------------
 2020-01-01  |        18.18 |       30.70 |       24.61 |         26.51
 2020-01-02  |        32.60 |       38.90 |       21.92 |          6.58
 2020-01-03  |        30.32 |       37.51 |       23.86 |          8.31
 2020-01-04  |        23.79 |       35.56 |       27.52 |         13.13
 2020-01-05  |        22.68 |       34.97 |       27.65 |         14.70
 2020-01-06  |        31.61 |       38.15 |       24.03 |          6.21
 2020-01-07  |        32.64 |       35.53 |       24.13 |          7.71
 2020-01-08  |        30.36 |       35.50 |       26.67 |          7.47
 2020-01-09  |        34.52 |       34.99 |       23.59 |          6.90
 2020-01-10  |        31.28 |       36.02 |       24.96 |          7.75
 2020-01-11  |        22.94 |       34.98 |       29.33 |         12.75
 2020-01-12  |        20.62 |       32.24 |       29.48 |         17.66
 2020-01-13  |        32.45 |       36.92 |       23.85 |          6.78
 2020-01-14  |        32.31 |       36.96 |       23.41 |          7.31
 2020-01-15  |        31.40 |       36.05 |       25.99 |          6.55
 2020-01-16  |        47.24 |       42.08 |        0.00 |         10.68
  */

-- Stress: bad data percentage
SELECT
    metric_date,
    ROUND(
        (invalid_time_order_count * 100.0) / created_count,
        2) AS pct_invalid_time,
    ROUND(
        (missing_critical_fields_count * 100.0) / created_count,
        2) AS pct_miss_total,
    ROUND(
        (missing_location_id_count * 100.0) / created_count,
        2) AS pct_miss_location,
    ROUND(
        (missing_complaint_type_id_count * 100.0) / created_count,
        2) AS pct_miss_complaint_type,
    ROUND(
        (missing_agency_id_count * 100.0) / created_count,
        2) AS pct_miss_agency
FROM fct_daily_metrics;

/* invalid time is the most siginificant, e.g. 2020-01-02 has ~4%

metric_date | pct_invalid_time | pct_miss_total | pct_miss_location | pct_miss_complaint_type | pct_miss_agency 
-------------+------------------+----------------+-------------------+-------------------------+-----------------
 2020-01-01  |             0.02 |           0.00 |              0.00 |                    0.00 |            0.00
 2020-01-02  |             3.76 |           0.00 |              0.00 |                    0.00 |            0.00
 2020-01-03  |             1.36 |           0.00 |              0.00 |                    0.00 |            0.00
 2020-01-04  |             0.00 |           0.00 |              0.00 |                    0.00 |            0.00
 2020-01-05  |             0.00 |           0.00 |              0.00 |                    0.00 |            0.00
 2020-01-06  |             1.45 |           0.00 |              0.00 |                    0.00 |            0.00
 2020-01-07  |             0.01 |           0.00 |              0.00 |                    0.00 |            0.00
 2020-01-08  |             0.06 |           0.00 |              0.00 |                    0.00 |            0.00
 2020-01-09  |             0.00 |           0.00 |              0.00 |                    0.00 |            0.00
 2020-01-10  |             1.26 |           0.00 |              0.00 |                    0.00 |            0.00
 2020-01-11  |             0.00 |           0.00 |              0.00 |                    0.00 |            0.00
 2020-01-12  |             0.00 |           0.00 |              0.00 |                    0.00 |            0.00
 2020-01-13  |             1.80 |           0.00 |              0.00 |                    0.00 |            0.00
 2020-01-14  |             2.00 |           0.00 |              0.00 |                    0.00 |            0.00
 2020-01-15  |             0.62 |           0.00 |              0.00 |                    0.00 |            0.00
 2020-01-16  |             0.33 |           0.00 |              0.00 |                    0.00 |            0.00
 */

