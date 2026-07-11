select
    cast(customer_id as varchar) as customer_id,
    cast(customer_segment as varchar) as customer_segment,
    cast(region as varchar) as region
from {{ source('crm', 'raw_customers') }}
