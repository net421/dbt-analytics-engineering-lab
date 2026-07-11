select
    order_id,
    order_date,
    ship_date,
    delivery_date,
    order_cycle_time_days
from {{ ref('fct_orders') }}
where (ship_date is not null and ship_date < order_date)
   or (delivery_date is not null and ship_date is not null and delivery_date < ship_date)
   or order_cycle_time_days < 0
