select order_id, is_on_time, is_in_full, is_otif
from {{ ref('fct_orders') }}
where is_otif and not (is_on_time and is_in_full)
