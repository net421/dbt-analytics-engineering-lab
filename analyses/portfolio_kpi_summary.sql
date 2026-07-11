select
    count(*) as order_count,
    round(100 * avg(unit_fill_rate), 2) as average_order_fill_rate_pct,
    round(100 * avg(cast(is_on_time as integer)), 2) as on_time_delivery_pct,
    round(100 * avg(cast(is_otif as integer)), 2) as otif_pct,
    round(sum(order_revenue), 2) as modeled_revenue,
    round(sum(total_logistics_cost), 2) as logistics_cost
from {{ ref('fct_orders') }}
