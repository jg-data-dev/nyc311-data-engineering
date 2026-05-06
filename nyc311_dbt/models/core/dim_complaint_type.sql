select
    row_number() over (
        order by complaint_type nulls last, descriptor nulls last, descriptor_2 nulls last
    ) as complaint_type_id,
    complaint_type,
    descriptor,
    descriptor_2
from (
    select distinct
        complaint_type,
        descriptor,
        descriptor_2
    from {{ ref('stg_311_requests') }}
) complaint_types
