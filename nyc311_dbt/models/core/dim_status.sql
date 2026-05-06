select
    row_number() over (order by status) as status_id,
    status
from (
    select distinct status
    from {{ ref('stg_311_requests') }}
    where status is not null
) statuses
