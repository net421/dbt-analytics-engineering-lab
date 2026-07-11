with expected as (
    select customer_id, count(distinct order_id) as expected_order_count
    from {{ ref('fct_orders') }}
    group by customer_id
),
actual as (
    select customer_id, order_count
    from {{ ref('mart_customer_value') }}
)
select
    expected.customer_id,
    expected.expected_order_count,
    actual.order_count as actual_order_count
from expected
left join actual using (customer_id)
where actual.customer_id is null
   or expected.expected_order_count <> actual.order_count
