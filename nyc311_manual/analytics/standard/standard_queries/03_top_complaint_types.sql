SELECT
    c.complaint_type,
    COUNT(*) AS num_requests
FROM fact_311_complaint f
JOIN dim_complaint_type c
  ON f.complaint_type_id = c.complaint_type_id
GROUP BY c.complaint_type
ORDER BY num_requests DESC, c.complaint_type
LIMIT 20;