select distinct
    to_char(d::date, 'YYYYMMDD')::integer as date_id,
    d::date as full_date,
    extract(day from d)::integer as day_of_month,
    extract(month from d)::integer as month,
    trim(to_char(d, 'Month')) as month_name,
    extract(quarter from d)::integer as quarter,
    extract(year from d)::integer as year,
    extract(isodow from d)::integer as day_of_week,
    trim(to_char(d, 'Day')) as day_name,
    (extract(isodow from d) in (6, 7)) as is_weekend
from (
    select created_date::date as d
    from {{ ref('stg_311_requests') }}
    where created_date is not null

    union

    select closed_date::date as d
    from {{ ref('stg_311_requests') }}
    where closed_date is not null

    union

    select resolution_action_updated_date::date as d
    from {{ ref('stg_311_requests') }}
    where resolution_action_updated_date is not null
) dates
