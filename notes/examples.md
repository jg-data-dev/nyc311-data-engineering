 ## json example
 {"bbl": "4142600001", "city": "JAMAICA", "agency": "TLC", "status": "Closed", "borough": "QUEENS", "landmark": "JFK AIRPORT", "latitude": "40.64832048620134", "location": {"type": "Point", "coordinates": [-73.788281251302, 40.648320486201]}, "longitude": "-73.78828125130184", "descriptor": "Other", "unique_key": "45337893", "agency_name": "Taxi and Limousine Commission", "closed_date": "2020-01-09T09:43:31.000", "street_name": "JFK", "created_date": "2020-01-08T19:24:54.000", "descriptor_2": "Passport", "incident_zip": "11430", "park_borough": "QUEENS", "complaint_type": "Lost Property", "cross_street_1": "BEND", "cross_street_2": "BEND", "community_board": "83 QUEENS", "police_precinct": "Precinct 113", "council_district": "28", "incident_address": "JFK", "park_facility_name": "Unspecified", "intersection_street_1": "BEND", "intersection_street_2": "BEND", "taxi_pick_up_location": "JFK AIRPORT, QUEENS (JAMAICA) ,NY, 11430", "open_data_channel_type": "PHONE", "resolution_description": "See notes for information.", "x_coordinate_state_plane": "1043001", "y_coordinate_state_plane": "175548", "resolution_action_updated_date": "2020-01-09T09:43:34.000"}
(1 row)


## fact table
fact_311_complaint
- complaint_key              -- surrogate PK for warehouse use, optional
- unique_key                 -- business key from source
- created_at
- closed_at
- created_date_id
- closed_date_id
- resolution_action_date_id
- location_id
- agency_id
- complaint_type_id
- status_id
- channel_id
- police_precinct
- complaint_count


## dimension table

dim_date
- date_id                    -- e.g. 20260131
- full_date
- day_of_month
- month
- month_name
- quarter
- year
- day_of_week
- day_name
- is_weekend

dim_location
- location_id
- incident_address
- street_name
- cross_street_1
- cross_street_2
- intersection_street_1
- intersection_street_2
- city
- borough
- incident_zip
- park_borough
- park_facility_name
- landmark
- latitude
- longitude
- x_coordinate_state_plane
- y_coordinate_state_plane
- community_board
- council_district

dim_agency
- agency_id
- agency
- agency_name

dim_complaint_type
- complaint_type_id
- complaint_type
- descriptor
- descriptor_2

dim_status
- status_id
- status

dim_channel
- channel_id
- open_data_channel_type

later:
fact_311_resolution_nlp
- unique_key
- sentiment_label
- sentiment_score
- resolution_theme
- resolution_category