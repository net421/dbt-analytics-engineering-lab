select
    customer_id,
    customer_segment,
    region,
    order_count,
    lifetime_revenue,
    average_order_fill_rate,
    otif_rate,
    first_order_date,
    latest_order_date,
    customer_tenure_days,
    ntile(4) over (order by lifetime_revenue) as revenue_quartile,
    dense_rank() over (partition by region order by lifetime_revenue desc) as regional_revenue_rank
from {{ ref('int_customer_orders') }}
