with sequenced as (
    select
        order_id,
        customer_id,
        customer_order_number,
        row_number() over (
            partition by customer_id
            order by order_date, order_id
        ) as expected_customer_order_number
    from {{ ref('fct_orders') }}
)

select *
from sequenced
where customer_order_number <> expected_customer_order_number
