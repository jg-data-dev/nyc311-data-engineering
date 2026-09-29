{{ config(
    indexes=[
      {'columns': ['unique_key'], 'unique': True},
      {'columns': ['location_key']},
      {'columns': ['agency_key']},
      {'columns': ['complaint_type_key']},
      {'columns': ['status_key']},
      {'columns': ['channel_key']}
    ]
) }}

with cleaned as (
    select
        unique_key,
        created_date,
        closed_date,
        resolution_action_updated_date,

        nullif(btrim(upper(agency)), '') as agency,
        nullif(btrim(upper(agency_name)), '') as agency_name,
        nullif(btrim(upper(complaint_type)), '') as complaint_type,
        nullif(btrim(upper(descriptor)), '') as descriptor,
        nullif(btrim(upper(descriptor_2)), '') as descriptor_2,
        nullif(btrim(upper(status)), '') as status,
        nullif(btrim(resolution_description), '') as resolution_description,
        nullif(btrim(upper(open_data_channel_type)), '') as open_data_channel_type,

        nullif(btrim(upper(incident_address)), '') as incident_address,
        nullif(btrim(upper(street_name)), '') as street_name,
        nullif(btrim(upper(cross_street_1)), '') as cross_street_1,
        nullif(btrim(upper(cross_street_2)), '') as cross_street_2,
        nullif(btrim(upper(intersection_street_1)), '') as intersection_street_1,
        nullif(btrim(upper(intersection_street_2)), '') as intersection_street_2,
        nullif(btrim(upper(landmark)), '') as landmark,
        nullif(btrim(upper(city)), '') as city,
        nullif(btrim(upper(borough)), '') as borough,
        nullif(btrim(incident_zip), '') as incident_zip,

        nullif(btrim(upper(community_board)), '') as community_board,
        nullif(btrim(council_district), '') as council_district,
        nullif(btrim(upper(police_precinct)), '') as police_precinct,

        nullif(btrim(upper(park_borough)), '') as park_borough,
        nullif(btrim(upper(park_facility_name)), '') as park_facility_name,
        nullif(btrim(taxi_pick_up_location), '') as taxi_pick_up_location,

        nullif(btrim(bbl), '') as bbl,
        nullif(btrim(x_coordinate_state_plane), '') as x_coordinate_state_plane,
        nullif(btrim(y_coordinate_state_plane), '') as y_coordinate_state_plane,

        cast(latitude as numeric) as latitude,
        cast(longitude as numeric) as longitude,
        location,
        raw_json
    from {{ source('nyc311', 'raw_311_requests') }}
)

select
    *,
    md5(
        coalesce(city, '') || '|' ||
        coalesce(borough, '') || '|' ||
        coalesce(landmark, '') || '|' ||
        coalesce(street_name, '') || '|' ||
        coalesce(incident_zip, '') || '|' ||
        coalesce(park_borough, '') || '|' ||
        coalesce(cross_street_1, '') || '|' ||
        coalesce(cross_street_2, '') || '|' ||
        coalesce(intersection_street_1, '') || '|' ||
        coalesce(intersection_street_2, '') || '|' ||
        coalesce(incident_address, '') || '|' ||
        coalesce(park_facility_name, '') || '|' ||
        coalesce(latitude::text, '') || '|' ||
        coalesce(longitude::text, '') || '|' ||
        coalesce(x_coordinate_state_plane, '') || '|' ||
        coalesce(y_coordinate_state_plane, '') || '|' ||
        coalesce(community_board, '') || '|' ||
        coalesce(council_district, '')
    ) as location_key,

    md5(
        coalesce(agency, '<NULL>') || '|' ||
        coalesce(agency_name, '<NULL>')
    ) as agency_key,

    md5(
        coalesce(complaint_type, '<NULL>') || '|' ||
        coalesce(descriptor, '<NULL>') || '|' ||
        coalesce(descriptor_2, '<NULL>')
    ) as complaint_type_key,

    md5(
        coalesce(status, '<NULL>')
    ) as status_key,

    md5(
        coalesce(open_data_channel_type, '<NULL>')
    ) as channel_key,

    created_date::date as created_day,
    closed_date::date as closed_day,

    case
        when closed_date is not null and closed_date < created_date then true
        else false
    end as invalid_close_before_create,

    case
        when latitude is not null
         and longitude is not null
         and latitude between -90 and 90
         and longitude between -180 and 180
        then true
        else false
    end as valid_lat_long
from cleaned
