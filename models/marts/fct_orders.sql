with customer_orders as (
    select * from {{ ref('int_customer_orders') }}
)

select
    order_id,
    customer_id,
    order_date,
    shipped_date,
    delivered_date,
    status,
    channel,
    region,
    payment_method,
    total_amount,
    discount_amount,
    freight_amount,
    net_order_amount,
    case when is_revenue_order then net_order_amount else 0 end as recognized_revenue_amount,
    case when is_exception_order then 1 else 0 end as exception_order_count,
    case when is_open_order then 1 else 0 end as open_order_count,
    case when customer_order_number = 1 then true else false end as is_first_order,
    is_revenue_order,
    is_exception_order,
    customer_order_number,
    previous_order_date,
    days_since_previous_order,
    customer_order_stage,
    first_order_date,
    latest_order_date,
    customer_lifetime_revenue_to_date,
    customer_revenue_order_count_to_date,
    {{ dbt.datediff("order_date", "shipped_date", "day") }} as days_to_ship,
    {{ dbt.datediff("order_date", "delivered_date", "day") }} as days_to_deliver
from customer_orders
