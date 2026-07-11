select
    p.sku,
    p.product_category,
    p.supplier_id,
    s.supplier_name,
    s.supplier_risk_tier,
    p.standard_unit_price,
    p.standard_unit_weight_kg
from {{ ref('stg_products') }} p
left join {{ ref('stg_suppliers') }} s on p.supplier_id = s.supplier_id
