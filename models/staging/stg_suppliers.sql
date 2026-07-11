select
    cast(supplier_id as varchar) as supplier_id,
    cast(supplier_name as varchar) as supplier_name,
    cast(base_lead_time_days as integer) as base_lead_time_days,
    cast(supplier_risk_tier as varchar) as supplier_risk_tier
from {{ source('product_master', 'raw_suppliers') }}
