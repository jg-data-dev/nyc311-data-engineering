-- =========================================================
-- STAR SCHEMA FOR NYC 311
-- Grain: 1 row in fact_311_complaint = 1 complaint record
-- =========================================================

-- -------------------------
-- Drop existing tables
-- -------------------------
DROP TABLE IF EXISTS fact_311_complaint_text CASCADE;
DROP TABLE IF EXISTS fact_311_complaint CASCADE;
DROP TABLE IF EXISTS dim_channel CASCADE;
DROP TABLE IF EXISTS dim_status CASCADE;
DROP TABLE IF EXISTS dim_complaint_type CASCADE;
DROP TABLE IF EXISTS dim_agency CASCADE;
DROP TABLE IF EXISTS dim_location CASCADE;
DROP TABLE IF EXISTS dim_date CASCADE;

-- =========================================================
-- DIMENSIONS
-- =========================================================

CREATE TABLE dim_date (
    date_id         INTEGER PRIMARY KEY,   -- YYYYMMDD
    full_date       DATE NOT NULL UNIQUE,
    day_of_month    INTEGER NOT NULL,
    month           INTEGER NOT NULL,
    month_name      TEXT NOT NULL,
    quarter         INTEGER NOT NULL,
    year            INTEGER NOT NULL,
    day_of_week     INTEGER NOT NULL,      -- ISO: Mon=1 ... Sun=7
    day_name        TEXT NOT NULL,
    is_weekend      BOOLEAN NOT NULL
);

CREATE TABLE dim_location (
    location_id                 BIGSERIAL PRIMARY KEY,
    city                        TEXT,
    borough                     TEXT,
    landmark                    TEXT,
    street_name                 TEXT,
    incident_zip                TEXT,
    park_borough                TEXT,
    cross_street_1              TEXT,
    cross_street_2              TEXT,
    intersection_street_1       TEXT,
    intersection_street_2       TEXT,
    incident_address            TEXT,
    park_facility_name          TEXT,
    latitude                    NUMERIC,
    longitude                   NUMERIC,
    x_coordinate_state_plane    TEXT,
    y_coordinate_state_plane    TEXT,
    community_board             TEXT,
    council_district            TEXT,
    UNIQUE (
        city, borough, landmark, street_name, incident_zip, park_borough,
        cross_street_1, cross_street_2, intersection_street_1, intersection_street_2,
        incident_address, park_facility_name, latitude, longitude,
        x_coordinate_state_plane, y_coordinate_state_plane,
        community_board, council_district
    )
);

CREATE TABLE dim_agency (
    agency_id       BIGSERIAL PRIMARY KEY,
    agency          TEXT,
    agency_name     TEXT,
    UNIQUE (agency, agency_name)
);

CREATE TABLE dim_complaint_type (
    complaint_type_id    BIGSERIAL PRIMARY KEY,
    complaint_type       TEXT,
    descriptor           TEXT,
    descriptor_2         TEXT,
    UNIQUE (complaint_type, descriptor, descriptor_2)
);

CREATE TABLE dim_status (
    status_id        BIGSERIAL PRIMARY KEY,
    status           TEXT UNIQUE
);

CREATE TABLE dim_channel (
    channel_id               BIGSERIAL PRIMARY KEY,
    open_data_channel_type   TEXT UNIQUE
);

-- =========================================================
-- FACT TABLES
-- =========================================================

CREATE TABLE fact_311_complaint (
    complaint_key                BIGSERIAL PRIMARY KEY,
    unique_key                   TEXT NOT NULL UNIQUE,

    created_at                   TIMESTAMP,
    closed_at                    TIMESTAMP,
    resolution_action_updated_at TIMESTAMP,

    created_date_id              INTEGER REFERENCES dim_date(date_id),
    closed_date_id               INTEGER REFERENCES dim_date(date_id),
    resolution_action_date_id    INTEGER REFERENCES dim_date(date_id),

    location_id                  BIGINT REFERENCES dim_location(location_id),
    agency_id                    BIGINT REFERENCES dim_agency(agency_id),
    complaint_type_id            BIGINT REFERENCES dim_complaint_type(complaint_type_id),
    status_id                    BIGINT REFERENCES dim_status(status_id),
    channel_id                   BIGINT REFERENCES dim_channel(channel_id),

    police_precinct              TEXT
);

CREATE TABLE fact_311_complaint_text (
    unique_key               TEXT PRIMARY KEY REFERENCES fact_311_complaint(unique_key),
    resolution_description   TEXT
);

-- =========================================================
-- INDEXES
-- =========================================================

CREATE INDEX idx_fact_311_created_date_id
    ON fact_311_complaint(created_date_id);

CREATE INDEX idx_fact_311_closed_date_id
    ON fact_311_complaint(closed_date_id);

CREATE INDEX idx_fact_311_resolution_action_date_id
    ON fact_311_complaint(resolution_action_date_id);

CREATE INDEX idx_fact_311_location_id
    ON fact_311_complaint(location_id);

CREATE INDEX idx_fact_311_agency_id
    ON fact_311_complaint(agency_id);

CREATE INDEX idx_fact_311_complaint_type_id
    ON fact_311_complaint(complaint_type_id);

CREATE INDEX idx_fact_311_status_id
    ON fact_311_complaint(status_id);

CREATE INDEX idx_fact_311_channel_id
    ON fact_311_complaint(channel_id);

-- =========================================================
-- LOAD DIMENSIONS
-- =========================================================

-- dim_date
INSERT INTO dim_date (
    date_id,
    full_date,
    day_of_month,
    month,
    month_name,
    quarter,
    year,
    day_of_week,
    day_name,
    is_weekend
)
SELECT DISTINCT
    TO_CHAR(d::date, 'YYYYMMDD')::INTEGER AS date_id,
    d::date AS full_date,
    EXTRACT(DAY FROM d)::INTEGER AS day_of_month,
    EXTRACT(MONTH FROM d)::INTEGER AS month,
    TRIM(TO_CHAR(d, 'Month')) AS month_name,
    EXTRACT(QUARTER FROM d)::INTEGER AS quarter,
    EXTRACT(YEAR FROM d)::INTEGER AS year,
    EXTRACT(ISODOW FROM d)::INTEGER AS day_of_week,
    TRIM(TO_CHAR(d, 'Day')) AS day_name,
    (EXTRACT(ISODOW FROM d) IN (6, 7)) AS is_weekend
FROM (
    SELECT created_date::date AS d
    FROM stg_311_requests
    WHERE created_date IS NOT NULL

    UNION

    SELECT closed_date::date AS d
    FROM stg_311_requests
    WHERE closed_date IS NOT NULL

    UNION

    SELECT resolution_action_updated_date::date AS d
    FROM stg_311_requests
    WHERE resolution_action_updated_date IS NOT NULL
) dates
ON CONFLICT (date_id) DO NOTHING;

-- dim_location
INSERT INTO dim_location (
    city,
    borough,
    landmark,
    street_name,
    incident_zip,
    park_borough,
    cross_street_1,
    cross_street_2,
    intersection_street_1,
    intersection_street_2,
    incident_address,
    park_facility_name,
    latitude,
    longitude,
    x_coordinate_state_plane,
    y_coordinate_state_plane,
    community_board,
    council_district
)
SELECT DISTINCT
    city,
    borough,
    landmark,
    street_name,
    incident_zip,
    park_borough,
    cross_street_1,
    cross_street_2,
    intersection_street_1,
    intersection_street_2,
    incident_address,
    park_facility_name,
    latitude,
    longitude,
    x_coordinate_state_plane,
    y_coordinate_state_plane,
    community_board,
    council_district
FROM stg_311_requests
ON CONFLICT DO NOTHING;

-- dim_agency
INSERT INTO dim_agency (
    agency,
    agency_name
)
SELECT DISTINCT
    agency,
    agency_name
FROM stg_311_requests
ON CONFLICT DO NOTHING;

-- dim_complaint_type
INSERT INTO dim_complaint_type (
    complaint_type,
    descriptor,
    descriptor_2
)
SELECT DISTINCT
    complaint_type,
    descriptor,
    descriptor_2
FROM stg_311_requests
ON CONFLICT DO NOTHING;

-- dim_status
INSERT INTO dim_status (status)
SELECT DISTINCT status
FROM stg_311_requests
WHERE status IS NOT NULL
ON CONFLICT DO NOTHING;

-- dim_channel
INSERT INTO dim_channel (open_data_channel_type)
SELECT DISTINCT open_data_channel_type
FROM stg_311_requests
WHERE open_data_channel_type IS NOT NULL
ON CONFLICT DO NOTHING;

-- =========================================================
-- LOAD FACT TABLE
-- =========================================================

INSERT INTO fact_311_complaint (
    unique_key,
    created_at,
    closed_at,
    resolution_action_updated_at,
    created_date_id,
    closed_date_id,
    resolution_action_date_id,
    location_id,
    agency_id,
    complaint_type_id,
    status_id,
    channel_id,
    police_precinct
)
SELECT
    s.unique_key,
    s.created_date AS created_at,
    s.closed_date AS closed_at,
    s.resolution_action_updated_date AS resolution_action_updated_at,

    CASE
        WHEN s.created_date IS NOT NULL
        THEN TO_CHAR(s.created_date::date, 'YYYYMMDD')::INTEGER
    END AS created_date_id,

    CASE
        WHEN s.closed_date IS NOT NULL
        THEN TO_CHAR(s.closed_date::date, 'YYYYMMDD')::INTEGER
    END AS closed_date_id,

    CASE
        WHEN s.resolution_action_updated_date IS NOT NULL
        THEN TO_CHAR(s.resolution_action_updated_date::date, 'YYYYMMDD')::INTEGER
    END AS resolution_action_date_id,

    l.location_id,
    a.agency_id,
    ct.complaint_type_id,
    st.status_id,
    ch.channel_id,
    s.police_precinct

FROM stg_311_requests s
LEFT JOIN dim_location l
    ON l.city IS NOT DISTINCT FROM s.city
   AND l.borough IS NOT DISTINCT FROM s.borough
   AND l.landmark IS NOT DISTINCT FROM s.landmark
   AND l.street_name IS NOT DISTINCT FROM s.street_name
   AND l.incident_zip IS NOT DISTINCT FROM s.incident_zip
   AND l.park_borough IS NOT DISTINCT FROM s.park_borough
   AND l.cross_street_1 IS NOT DISTINCT FROM s.cross_street_1
   AND l.cross_street_2 IS NOT DISTINCT FROM s.cross_street_2
   AND l.intersection_street_1 IS NOT DISTINCT FROM s.intersection_street_1
   AND l.intersection_street_2 IS NOT DISTINCT FROM s.intersection_street_2
   AND l.incident_address IS NOT DISTINCT FROM s.incident_address
   AND l.park_facility_name IS NOT DISTINCT FROM s.park_facility_name
   AND l.latitude IS NOT DISTINCT FROM s.latitude
   AND l.longitude IS NOT DISTINCT FROM s.longitude
   AND l.x_coordinate_state_plane IS NOT DISTINCT FROM s.x_coordinate_state_plane
   AND l.y_coordinate_state_plane IS NOT DISTINCT FROM s.y_coordinate_state_plane
   AND l.community_board IS NOT DISTINCT FROM s.community_board
   AND l.council_district IS NOT DISTINCT FROM s.council_district

LEFT JOIN dim_agency a
    ON a.agency IS NOT DISTINCT FROM s.agency
   AND a.agency_name IS NOT DISTINCT FROM s.agency_name

LEFT JOIN dim_complaint_type ct
    ON ct.complaint_type IS NOT DISTINCT FROM s.complaint_type
   AND ct.descriptor IS NOT DISTINCT FROM s.descriptor
   AND ct.descriptor_2 IS NOT DISTINCT FROM s.descriptor_2

LEFT JOIN dim_status st
    ON st.status IS NOT DISTINCT FROM s.status

LEFT JOIN dim_channel ch
    ON ch.open_data_channel_type IS NOT DISTINCT FROM s.open_data_channel_type

WHERE s.unique_key IS NOT NULL
ON CONFLICT (unique_key) DO NOTHING;

-- =========================================================
-- LOAD FACT TEXT TABLE
-- =========================================================

INSERT INTO fact_311_complaint_text (
    unique_key,
    resolution_description
)
SELECT
    unique_key,
    resolution_description
FROM stg_311_requests
WHERE unique_key IS NOT NULL
ON CONFLICT (unique_key) DO NOTHING;