select
    cast(activity_date as date) as activity_date,
    cast(warehouse as varchar) as warehouse,
    cast(units_processed as integer) as units_processed,
    cast(labor_hours as decimal(18, 2)) as labor_hours,
    units_processed / nullif(cast(labor_hours as double), 0) as units_per_labor_hour
from {{ source('wms', 'raw_warehouse_activity') }}
