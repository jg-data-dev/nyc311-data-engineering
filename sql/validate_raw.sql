SELECT COUNT(*) FROM raw_311_requests;

SELECT COUNT(*) 
FROM raw_311_requests
WHERE unique_key IS NULL;

SELECT COUNT(*) 
FROM raw_311_requests
WHERE created_date IS NULL;

SELECT COUNT(*) 
FROM raw_311_requests
WHERE closed_date < created_date;