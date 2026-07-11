with source as (
    select * from {{ source('erp', 'raw_orders') }}
),
renamed as (
    select
        cast(order_line_id as varchar) as order_line_id,
        cast(order_id as varchar) as order_id,
        cast(customer_id as varchar) as customer_id,
        cast(warehouse as varchar) as warehouse,
        cast(order_date as date) as order_date,
        cast(promised_date as date) as promised_date,
        cast(sku as varchar) as sku,
        cast(supplier_id as varchar) as supplier_id,
        cast(units_ordered as integer) as units_ordered,
        cast(units_shipped as integer) as units_shipped,
        cast(unit_price as decimal(18, 2)) as unit_price,
        cast(unit_weight_kg as decimal(18, 3)) as unit_weight_kg,
        cast(revenue as decimal(18, 2)) as revenue,
        cast(units_shipped as double) / nullif(cast(units_ordered as double), 0) as line_fill_rate,
        current_timestamp as dbt_loaded_at
    from source
)
select * from renamed
