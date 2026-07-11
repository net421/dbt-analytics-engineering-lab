select
    o.order_line_id,
    o.order_id,
    o.customer_id,
    c.customer_segment,
    c.region,
    o.warehouse,
    o.order_date,
    o.promised_date,
    o.sku,
    p.product_category,
    o.supplier_id,
    s.supplier_name,
    s.supplier_risk_tier,
    o.units_ordered,
    o.units_shipped,
    o.unit_price,
    o.unit_weight_kg,
    o.revenue,
    o.line_fill_rate,
    o.units_shipped < o.units_ordered as is_backordered_line
from {{ ref('stg_orders') }} o
left join {{ ref('stg_customers') }} c using (customer_id)
left join {{ ref('stg_products') }} p on o.sku = p.sku
left join {{ ref('stg_suppliers') }} s on o.supplier_id = s.supplier_id
