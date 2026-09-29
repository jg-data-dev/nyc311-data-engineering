/*
Brooklyn resolution investigation

Goal:
Explain why Brooklyn has much higher average resolution time, 1279.16 (more than 2x next highest, 3x manhattan)


Current Conlusion:
Brooklyn’s high average resolution time is heavily influenced by GRAFFITI complaints,
-- whose timestamps exhibit non-representative temporal clustering.

*/

-- Hypothesis: Higher volume → slower resolution
SELECT
    COALESCE(NULLIF(TRIM(l.borough), ''), 'UNSPECIFIED') AS borough,
    COUNT(*)
FROM fact_311_complaint f
JOIN dim_location l
    ON f.location_id = l.location_id
GROUP BY
    1
ORDER BY
    2 DESC;

-- Result: Not sufficient (Brooklyn 883 vs Manhattan 628)
/*       borough    | count 
---------------+-------
 BROOKLYN      |   887
 QUEENS        |   723
 MANHATTAN     |   637
 BRONX         |   608
 STATEN ISLAND |   136
 UNSPECIFIED   |     9
 */

-- Hypothesis: Brooklyn has fewer resources (precincts)
SELECT
    COALESCE(NULLIF(TRIM(l.borough), ''), 'UNKNOWN') AS borough,
    COUNT(DISTINCT f.police_precinct) AS num_precincts
FROM fact_311_complaint f
JOIN dim_location l
  ON f.location_id = l.location_id
GROUP BY COALESCE(NULLIF(TRIM(l.borough), ''), 'UNKNOWN')
ORDER BY num_precincts DESC, borough;
-- Result: Rejected (Brooklyn = Manhattan = 24 precincts)
/*     borough    | num_precincts 
---------------+---------------
 BROOKLYN      |            24
 MANHATTAN     |            24
 QUEENS        |            17
 BRONX         |            14
 STATEN ISLAND |             5
 UNKNOWN       |             1
 UNSPECIFIED   |             1
(7 rows)
 */

-- Hypothesis: Outliers skewing mean, check the median
WITH complaint_times AS (
    SELECT
        COALESCE(NULLIF(TRIM(l.borough), ''), 'UNSPECIFIED') AS borough,
        EXTRACT(EPOCH FROM (f.closed_at - f.created_at)) / 3600.0 AS resolution_hours
    FROM fact_311_complaint f
    JOIN dim_location l
      ON f.location_id = l.location_id
    WHERE f.created_at IS NOT NULL
      AND f.closed_at IS NOT NULL
      AND f.closed_at >= f.created_at
)
SELECT
    borough,
    COUNT(*) AS num_requests,
    ROUND(AVG(resolution_hours)::numeric, 2) AS avg_resolution_hours,
    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY resolution_hours)::numeric,
        2
    ) AS median_resolution_hours,
    ROUND(
        PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY resolution_hours)::numeric,
        2
    ) AS ninety_perc_resolution_hours,
    ROUND(MIN(resolution_hours)::numeric, 2) AS min_resolution_hours,
    ROUND(MAX(resolution_hours)::numeric, 2) AS max_resolution_hours
FROM complaint_times
GROUP BY borough
ORDER BY avg_resolution_hours DESC;

-- Result: Median is only 7.90, while 90th percentile is 311.12
/* borough    | num_requests | avg_resolution_hours | median_resolution_hours | ninety_perc_resolution_hours | min_resolution_hours | max_resolution_hours 
---------------+--------------+----------------------+-------------------------+------------------------------+----------------------+----------------------
 BROOKLYN      |          883 |              1279.16 |                    7.90 |                       311.12 |                 0.00 |             42650.24
 STATEN ISLAND |          135 |               676.37 |                   27.83 |                       137.64 |                 0.00 |             38776.81
 MANHATTAN     |          628 |               430.55 |                    2.47 |                       118.87 |                 0.00 |             46519.35
 QUEENS        |          720 |               277.47 |                    8.61 |                       153.67 |                 0.00 |             38765.02
 BRONX         |          607 |               158.96 |                    9.30 |                        60.20 |                 0.00 |             38765.28
 UNSPECIFIED   |            9 |                35.09 |                   29.64 |                        52.78 |                19.68
  */

-- Hypothesis: a specific complaint skews average resolution time
WITH complaint_times AS (
    SELECT
        c.complaint_type,
        EXTRACT(EPOCH FROM (f.closed_at - f.created_at)) / 3600.0 AS resolution_hours
    FROM fact_311_complaint f
    JOIN dim_complaint_type c
      ON f.complaint_type_id = c.complaint_type_id
    WHERE f.created_at IS NOT NULL
      AND f.closed_at IS NOT NULL
      AND f.closed_at >= f.created_at
)
SELECT
    complaint_type,
    COUNT(*) AS num_requests,
    ROUND(AVG(resolution_hours)::numeric, 2) AS avg_resolution_hours,
    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY resolution_hours)::numeric,
        2
    ) AS median_resolution_hours
FROM complaint_times
GROUP BY complaint_type
HAVING COUNT(*) >= 10
ORDER BY avg_resolution_hours DESC;

-- Result: Graffiti complaints lead in resolution time
/* complaint_type            | num_requests | avg_resolution_hours | median_resolution_hours 
-------------------------------------+--------------+----------------------+-------------------------
 GRAFFITI                            |           34 |             24591.56 |                30384.96
 MAINTENANCE OR FACILITY             |           13 |              6893.21 |                  796.76
 TAXI COMPLAINT                      |           15 |              1790.34 |                 1396.45
 BUILDING/USE                        |           12 |              1790.11 |                  972.92
 GENERAL CONSTRUCTION/PLUMBING       |           13 |              1488.94 |                  136.71
 ELEVATOR                            |           11 |               850.85 |                  972.99
  */


-- Hypothesis: GRAFFITI complaints mostly in Brooklyn
SELECT
COALESCE(NULLIF(TRIM(l.borough), ''), 'UNSPECIFIED') AS borough,
count(*)
FROM fact_311_complaint f
    JOIN dim_location l
      ON f.location_id = l.location_id
    JOIN dim_complaint_type c
      ON f.complaint_type_id = c.complaint_type_id
      where c.complaint_type = 'GRAFFITI'
    GROUP BY 1;

-- Result: 31/34 in Brooklyn
/* borough  | count 
-----------+-------
 BROOKLYN  |    31
 MANHATTAN |     2
 QUEENS    |     1
  */

-- Hypothesis: remove graffiti complaints, Brooklyn resolution time is comparable to Manhattan
WITH complaint_times AS (
    SELECT
        COALESCE(NULLIF(TRIM(l.borough), ''), 'UNSPECIFIED') AS borough,
        EXTRACT(EPOCH FROM (f.closed_at - f.created_at)) / 3600.0 AS resolution_hours
    FROM fact_311_complaint f
    JOIN dim_location l
      ON f.location_id = l.location_id
    JOIN dim_complaint_type c
      ON f.complaint_type_id = c.complaint_type_id
    
    WHERE f.created_at IS NOT NULL
      AND f.closed_at IS NOT NULL
      AND f.closed_at >= f.created_at
      and c.complaint_type != 'GRAFFITI'
)
SELECT
    borough,
    COUNT(*) AS num_requests,
    ROUND(AVG(resolution_hours)::numeric, 2) AS avg_resolution_hours,
    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY resolution_hours)::numeric,
        2
    ) AS median_resolution_hours
FROM complaint_times
GROUP BY borough
HAVING COUNT(*) >= 10
ORDER BY avg_resolution_hours DESC;

/* Result: BROOKLYN average lowered to 422.54, comparable to Manhattan
    borough    | num_requests | avg_resolution_hours | median_resolution_hours 
---------------+--------------+----------------------+-------------------------
 STATEN ISLAND |          135 |               676.37 |                   27.83
 BROOKLYN      |          852 |               422.54 |                    6.67
 MANHATTAN     |          626 |               356.57 |                    2.46
 QUEENS        |          719 |               250.81 |                    8.56
 BRONX         |          607 |               158.96 |                    9.30
 */


 -- Data Quality Check: inspect details about graffiti complaints
SELECT
l.borough as borough,
ROUND(EXTRACT(EPOCH FROM (f.closed_at - f.created_at)) / 3600.0, 2) as resolution_time,
t.resolution_description as description
FROM fact_311_complaint f
    JOIN dim_location l
      ON f.location_id = l.location_id
    JOIN fact_311_complaint_text t
      ON f.unique_key = t.unique_key
    JOIN dim_complaint_type c
      ON f.complaint_type_id = c.complaint_type_id
      where c.complaint_type = 'GRAFFITI';
-- Result: some missing, the result normal messages

-- Data Quality Check: graffiti complaints closing time
SELECT
  DATE_TRUNC('month', f.closed_at) AS closed_month,
  COUNT(*) AS cnt
FROM fact_311_complaint f
JOIN dim_complaint_type c
      ON f.complaint_type_id = c.complaint_type_id
WHERE complaint_type = 'GRAFFITI'
GROUP BY 1
ORDER BY 1;
-- Result: 20 out of 34 graffiti complaints were closed in June 2023 */

SELECT
  d.year as closed_year,
  d.month AS closed_month,
  COUNT(*) AS cnt
FROM fact_311_complaint f
JOIN dim_date d
      ON f.closed_date_id = d.date_id
JOIN dim_complaint_type c
      ON f.complaint_type_id = c.complaint_type_id
WHERE complaint_type = 'GRAFFITI'
GROUP BY 1, 2
ORDER BY 1;


/* 
 closed_year | closed_month | cnt 
-------------+--------------+-----
        2021 |            8 |   7
        2021 |            9 |   1
        2021 |           12 |   4
        2022 |            3 |   1
        2022 |           10 |   1
        2023 |            6 |  20
(6 rows)
*/

-- Data Quality Check: graffiti complaints creation time

SELECT
  d.year as created_year,
  d.month AS created_month,
  COUNT(*) AS cnt
FROM fact_311_complaint f
JOIN dim_date d
      ON f.created_date_id = d.date_id
JOIN dim_complaint_type c
      ON f.complaint_type_id = c.complaint_type_id
WHERE complaint_type = 'GRAFFITI'
GROUP BY 1, 2
ORDER BY 1;

/* created_year | created_month | cnt 
--------------+---------------+-----
         2020 |             1 |  34

data anomaly possible explanations:
- bulk data import
- backfilled records
- test or legacy data
- subset of historical cleanup cases
- data pipeline artifact
 */

-- Check creation time for clustring 
SELECT DISTINCT f.created_at
FROM fact_311_complaint f
JOIN dim_complaint_type c
  ON f.complaint_type_id = c.complaint_type_id
WHERE c.complaint_type = 'GRAFFITI'
ORDER BY f.created_at;

/* All 34 graffiti complaints were created on:
2020-01-01 between ~09:08 and ~12:43 */