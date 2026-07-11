select
    order_line_id,
    order_id,
    customer_id,
    warehouse,
    order_date,
    promised_date,
    sku,
    supplier_id,
    units_ordered,
    units_shipped,
    unit_price,
    unit_weight_kg,
    revenue,
    line_fill_rate,
    is_backordered_line
from {{ ref('int_order_lines_enriched') }}
