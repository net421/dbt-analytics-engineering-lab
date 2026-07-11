select
    customer_id,
    any_value(customer_segment) as customer_segment,
    any_value(region) as region,
    count(distinct order_id) as order_count,
    sum(order_revenue) as lifetime_revenue,
    avg(unit_fill_rate) as average_order_fill_rate,
    avg(cast(is_otif as integer)) as otif_rate,
    min(order_date) as first_order_date,
    max(order_date) as latest_order_date,
    date_diff('day', min(order_date), max(order_date)) as customer_tenure_days
from {{ ref('int_order_fulfillment') }}
group by customer_id
