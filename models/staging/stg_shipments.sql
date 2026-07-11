with source as (
    select * from {{ source('tms', 'raw_shipments') }}
)
select
    cast(shipment_id as varchar) as shipment_id,
    cast(order_id as varchar) as order_id,
    cast(carrier as varchar) as carrier,
    cast(warehouse as varchar) as warehouse,
    cast(ship_date as date) as ship_date,
    cast(delivery_date as date) as delivery_date,
    cast(promised_date as date) as promised_date,
    cast(shipment_weight_kg as decimal(18, 3)) as shipment_weight_kg,
    cast(freight_cost as decimal(18, 2)) as freight_cost,
    cast(handling_cost as decimal(18, 2)) as handling_cost,
    cast(exception_cost as decimal(18, 2)) as exception_cost,
    cast(on_time as boolean) as source_on_time,
    delivery_date <= promised_date as calculated_on_time,
    freight_cost + handling_cost + exception_cost as total_logistics_cost
from source
