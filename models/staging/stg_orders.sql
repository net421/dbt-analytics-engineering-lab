with source as (
    select * from {{ ref('raw_orders') }}
),
renamed as (
    select
        order_id,
        customer_id,
        cast(order_date as date) as order_date,
        status,
        cast(total_amount as numeric) as total_amount
    from source
)
select * from renamed
