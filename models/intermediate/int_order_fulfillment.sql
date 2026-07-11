with order_lines as (
    select
        order_id,
        any_value(customer_id) as customer_id,
        any_value(customer_segment) as customer_segment,
        any_value(region) as region,
        any_value(warehouse) as warehouse,
        min(order_date) as order_date,
        max(promised_date) as promised_date,
        count(*) as order_line_count,
        sum(units_ordered) as units_ordered,
        sum(units_shipped) as units_shipped,
        sum(revenue) as order_revenue,
        sum(units_ordered * unit_weight_kg) as ordered_weight_kg,
        count(distinct sku) as distinct_sku_count
    from {{ ref('int_order_lines_enriched') }}
    group by order_id
),
joined as (
    select
        o.*,
        s.shipment_id,
        s.carrier,
        s.ship_date,
        s.delivery_date,
        coalesce(s.promised_date, o.promised_date) as shipment_promised_date,
        s.shipment_weight_kg,
        s.freight_cost,
        s.handling_cost,
        s.exception_cost,
        s.total_logistics_cost,
        s.calculated_on_time,
        o.units_shipped >= o.units_ordered as is_in_full,
        least(o.units_shipped / nullif(cast(o.units_ordered as double), 0), 1.0) as unit_fill_rate,
        s.calculated_on_time and o.units_shipped >= o.units_ordered as is_otif,
        date_diff('day', o.order_date, s.delivery_date) as order_cycle_time_days,
        s.total_logistics_cost / nullif(o.order_revenue, 0) as cost_to_serve_pct,
        s.freight_cost / nullif(s.shipment_weight_kg, 0) as freight_cost_per_kg
    from order_lines o
    left join {{ ref('stg_shipments') }} s using (order_id)
)
select * from joined
