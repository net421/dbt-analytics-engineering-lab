select
    cast(sku as varchar) as sku,
    cast(product_category as varchar) as product_category,
    cast(supplier_id as varchar) as supplier_id,
    cast(unit_price as decimal(18, 2)) as standard_unit_price,
    cast(unit_weight_kg as decimal(18, 3)) as standard_unit_weight_kg
from {{ source('product_master', 'raw_products') }}
