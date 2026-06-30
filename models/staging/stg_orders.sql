with source as (
    select * from {{ ref('raw_orders') }}
),

typed as (
    select
        nullif(trim(cast(order_id as {{ dbt.type_string() }})), '') as order_id,
        nullif(trim(cast(customer_id as {{ dbt.type_string() }})), '') as customer_id,
        cast(nullif(trim(cast(order_date as {{ dbt.type_string() }})), '') as date) as order_date,
        cast(nullif(trim(cast(shipped_at as {{ dbt.type_string() }})), '') as date) as shipped_date,
        cast(nullif(trim(cast(delivered_at as {{ dbt.type_string() }})), '') as date) as delivered_date,
        lower(nullif(trim(cast(status as {{ dbt.type_string() }})), '')) as order_status_raw,
        lower(nullif(trim(cast(channel as {{ dbt.type_string() }})), '')) as channel,
        lower(nullif(trim(cast(region as {{ dbt.type_string() }})), '')) as region,
        lower(nullif(trim(cast(payment_method as {{ dbt.type_string() }})), '')) as payment_method,
        cast(total_amount as {{ dbt.type_numeric() }}) as total_amount,
        cast(discount_amount as {{ dbt.type_numeric() }}) as discount_amount,
        cast(freight_amount as {{ dbt.type_numeric() }}) as freight_amount,
        cast(nullif(trim(cast(source_loaded_at as {{ dbt.type_string() }})), '') as date) as source_loaded_date
    from source
),

standardized as (
    select
        order_id,
        customer_id,
        order_date,
        shipped_date,
        delivered_date,
        case
            when order_status_raw in ('placed', 'pending') then 'placed'
            when order_status_raw in ('shipped', 'in_transit') then 'shipped'
            when order_status_raw in ('delivered', 'complete', 'completed') then 'delivered'
            when order_status_raw in ('cancelled', 'canceled') then 'cancelled'
            when order_status_raw in ('returned', 'refunded') then 'returned'
            else 'unknown'
        end as status,
        channel,
        region,
        payment_method,
        total_amount,
        coalesce(discount_amount, 0) as discount_amount,
        coalesce(freight_amount, 0) as freight_amount,
        source_loaded_date
    from typed
)

select
    order_id,
    customer_id,
    order_date,
    shipped_date,
    delivered_date,
    status,
    channel,
    region,
    payment_method,
    total_amount,
    discount_amount,
    freight_amount,
    total_amount - discount_amount as net_order_amount,
    case when status in ('shipped', 'delivered') then true else false end as is_revenue_order,
    case when status in ('cancelled', 'returned') then true else false end as is_exception_order,
    case when status in ('placed', 'shipped') then true else false end as is_open_order,
    source_loaded_date
from standardized
