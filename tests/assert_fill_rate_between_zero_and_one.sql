select order_id, unit_fill_rate
from {{ ref('fct_orders') }}
where unit_fill_rate < 0 or unit_fill_rate > 1
