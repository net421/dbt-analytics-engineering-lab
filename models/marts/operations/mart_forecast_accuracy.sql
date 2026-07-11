select
    forecast_month,
    warehouse,
    sku,
    forecast_units,
    actual_units,
    absolute_error_units,
    case
        when actual_units = 0 and forecast_units = 0 then 1.0
        when actual_units = 0 then 0.0
        else greatest(0.0, 1.0 - absolute_error_units / cast(actual_units as double))
    end as forecast_accuracy
from {{ ref('stg_demand_forecasts') }}
