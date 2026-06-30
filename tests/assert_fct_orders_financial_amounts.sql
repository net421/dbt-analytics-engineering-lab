select
    order_id,
    total_amount,
    discount_amount,
    freight_amount,
    net_order_amount,
    recognized_revenue_amount
from {{ ref('fct_orders') }}
where total_amount < 0
    or discount_amount < 0
    or freight_amount < 0
    or net_order_amount < 0
    or recognized_revenue_amount < 0
    or recognized_revenue_amount > net_order_amount
