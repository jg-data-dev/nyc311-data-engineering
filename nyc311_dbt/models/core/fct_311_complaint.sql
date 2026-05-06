select
    row_number() over (order by s.unique_key) as complaint_key,
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

    l.location_id,
    a.agency_id,
    ct.complaint_type_id,
    st.status_id,
    ch.channel_id,
    s.police_precinct
from {{ ref('stg_311_requests') }} s
left join {{ ref('dim_location') }} l
    on l.location_key = s.location_key
left join {{ ref('dim_agency') }} a
    on a.agency is not distinct from s.agency
   and a.agency_name is not distinct from s.agency_name
left join {{ ref('dim_complaint_type') }} ct
    on ct.complaint_type is not distinct from s.complaint_type
   and ct.descriptor is not distinct from s.descriptor
   and ct.descriptor_2 is not distinct from s.descriptor_2
left join {{ ref('dim_status') }} st
    on st.status is not distinct from s.status
left join {{ ref('dim_channel') }} ch
    on ch.open_data_channel_type is not distinct from s.open_data_channel_type
where s.unique_key is not null
