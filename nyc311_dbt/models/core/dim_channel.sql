select
    row_number() over (order by open_data_channel_type) as channel_id,
    open_data_channel_type
from (
    select distinct open_data_channel_type
    from {{ ref('stg_311_requests') }}
    where open_data_channel_type is not null
) channels
