select
    customer_id,
    customer_segment,
    region
from {{ ref('stg_customers') }}
