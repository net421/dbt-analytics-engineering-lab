select
    snapshot_date,
    warehouse,
    sku,
    on_hand_units,
    average_daily_demand,
    inventory_value,
    days_of_inventory,
    on_hand_units = 0 and average_daily_demand > 0 as is_stockout,
    case
        when average_daily_demand = 0 then 'No demand'
        when on_hand_units = 0 then 'Stockout'
        when days_of_inventory < 7 then 'Critical'
        when days_of_inventory < 14 then 'Watch'
        else 'Healthy'
    end as inventory_risk_status
from {{ ref('stg_inventory') }}
