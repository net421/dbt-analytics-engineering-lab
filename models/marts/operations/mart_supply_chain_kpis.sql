select
    order_date,
    warehouse,
    count(*) as order_count,
    sum(units_ordered) as units_ordered,
    sum(units_shipped) as units_shipped,
    sum(units_shipped) / nullif(cast(sum(units_ordered) as double), 0) as unit_fill_rate,
    avg(cast(is_in_full as integer)) as complete_order_rate,
    avg(cast(calculated_on_time as integer)) as on_time_delivery_rate,
    avg(cast(is_otif as integer)) as otif_rate,
    avg(order_cycle_time_days) as average_order_cycle_time_days,
    sum(order_revenue) as revenue,
    sum(total_logistics_cost) as total_logistics_cost,
    sum(total_logistics_cost) / nullif(sum(order_revenue), 0) as cost_to_serve_pct,
    avg(freight_cost_per_kg) as average_freight_cost_per_kg
from {{ ref('int_order_fulfillment') }}
group by order_date, warehouse
