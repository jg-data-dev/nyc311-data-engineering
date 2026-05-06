select
    row_number() over (order by agency nulls last, agency_name nulls last) as agency_id,
    agency,
    agency_name
from (
    select distinct
        agency,
        agency_name
    from {{ ref('stg_311_requests') }}
) agencies
