select order_id, total_logistics_cost
from {{ ref('fct_orders') }}
where total_logistics_cost < 0
