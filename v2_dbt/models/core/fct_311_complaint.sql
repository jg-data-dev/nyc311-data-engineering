select
    s.unique_key as complaint_key,
    s.unique_key,

    s.created_date as created_at,
    s.closed_date as closed_at,
    s.resolution_action_updated_date as resolution_action_updated_at,

    case
        when s.created_date is not null
        then to_char(s.created_date::date, 'YYYYMMDD')::integer
    end as created_date_id,

    case
        when s.closed_date is not null
        then to_char(s.closed_date::date, 'YYYYMMDD')::integer
    end as closed_date_id,

    case
        when s.resolution_action_updated_date is not null
        then to_char(s.resolution_action_updated_date::date, 'YYYYMMDD')::integer
    end as resolution_action_date_id,

    s.location_key as location_id,
    s.agency_key as agency_id,
    s.complaint_type_key as complaint_type_id,
    s.status_key as status_id,
    s.channel_key as channel_id,

    s.police_precinct

from {{ ref('stg_311_requests') }} s
where s.unique_key is not null