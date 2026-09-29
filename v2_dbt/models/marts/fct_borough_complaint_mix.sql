with base as (
    select
        i.created_at,
        coalesce(nullif(trim(l.borough), ''), 'UNSPECIFIED') as borough,
        coalesce(c.complaint_type, 'UNSPECIFIED') as complaint_type
    from {{ ref('int_complaints_flagged') }} i
    left join {{ ref('dim_location') }} l
        on i.location_id = l.location_id
    left join {{ ref('dim_complaint_type') }} c
        on i.complaint_type_id = c.complaint_type_id
    where i.created_at is not null
)

select
    min(created_at)::date as min_created_date,
    max(created_at)::date as max_created_date,
    borough,
    complaint_type,
    count(*) as total_requests,
    round(
        count(*)::numeric
        / sum(count(*)) over (partition by borough) * 100,
        2
    ) as pct_of_borough_requests,
    round(
        count(*)::numeric
        / sum(count(*)) over () * 100,
        2
    ) as pct_of_all_requests
from base
group by
    borough,
    complaint_type
