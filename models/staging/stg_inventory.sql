select
    cast(snapshot_date as date) as snapshot_date,
    cast(warehouse as varchar) as warehouse,
    cast(sku as varchar) as sku,
    cast(on_hand_units as integer) as on_hand_units,
    cast(average_daily_demand as decimal(18, 3)) as average_daily_demand,
    cast(inventory_value as decimal(18, 2)) as inventory_value,
    case
        when average_daily_demand > 0 then on_hand_units / average_daily_demand
        else null
    end as days_of_inventory
from {{ source('wms', 'raw_inventory') }}
