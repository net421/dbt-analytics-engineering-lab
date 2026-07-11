select
    order_id,
    order_revenue,
    freight_cost,
    handling_cost,
    exception_cost,
    total_logistics_cost
from {{ ref('fct_orders') }}
where order_revenue < 0
   or freight_cost < 0
   or handling_cost < 0
   or exception_cost < 0
   or total_logistics_cost < 0
   or abs(total_logistics_cost - (freight_cost + handling_cost + exception_cost)) > 0.01
