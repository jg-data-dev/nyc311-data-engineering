-- find hotspot
SELECT borough, street_name, COUNT(*) AS cnt
FROM stg_311_requests
WHERE street_name IS NOT NULL
  AND borough IS NOT NULL
GROUP BY borough, street_name
ORDER BY cnt DESC
LIMIT 20;