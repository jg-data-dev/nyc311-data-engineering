\echo '== Resetting probe raw table from production raw schema =='

DROP TABLE IF EXISTS raw_311_requests_probe;

CREATE TABLE raw_311_requests_probe (
    LIKE raw_311_requests INCLUDING ALL
);