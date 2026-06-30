with orders as (
    select * from {{ ref('stg_orders') }}
),

customer_order_windows as (
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
        net_order_amount,
        is_revenue_order,
        is_exception_order,
        is_open_order,
        row_number() over (
            partition by customer_id
            order by order_date, order_id
        ) as customer_order_number,
        lag(order_date) over (
            partition by customer_id
            order by order_date, order_id
        ) as previous_order_date,
        min(order_date) over (
            partition by customer_id
        ) as first_order_date,
        max(order_date) over (
            partition by customer_id
        ) as latest_order_date,
        sum(case when is_revenue_order then net_order_amount else 0 end) over (
            partition by customer_id
            order by order_date, order_id
            rows between unbounded preceding and current row
        ) as customer_lifetime_revenue_to_date,
        count(case when is_revenue_order then 1 end) over (
            partition by customer_id
            order by order_date, order_id
            rows between unbounded preceding and current row
        ) as customer_revenue_order_count_to_date
    from orders
),

classified as (
    select
        *,
        {{ dbt.datediff("previous_order_date", "order_date", "day") }} as days_since_previous_order,
        case
            when previous_order_date is null then 'new'
            when {{ dbt.datediff("previous_order_date", "order_date", "day") }} > 60 then 'reactivated'
            else 'returning'
        end as customer_order_stage
    from customer_order_windows
)

select * from classified
