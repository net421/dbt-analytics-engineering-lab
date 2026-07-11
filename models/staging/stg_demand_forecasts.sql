select
    cast(month as date) as forecast_month,
    cast(warehouse as varchar) as warehouse,
    cast(sku as varchar) as sku,
    cast(forecast_units as integer) as forecast_units,
    cast(actual_units as integer) as actual_units,
    abs(forecast_units - actual_units) as absolute_error_units
from {{ source('planning', 'raw_demand_forecasts') }}
