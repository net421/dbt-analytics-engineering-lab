with orders as (
    select * from {{ ref('stg_orders') }}
)
select
    customer_id,
    count(distinct order_id) as orders_count,
    sum(total_amount) as customer_revenue,
    max(order_date) as last_order_date
from orders
group by 1
