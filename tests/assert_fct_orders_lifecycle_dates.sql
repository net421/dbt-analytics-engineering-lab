select
    order_id,
    order_date,
    shipped_date,
    delivered_date,
    days_to_ship,
    days_to_deliver
from {{ ref('fct_orders') }}
where (
        shipped_date is not null
        and shipped_date < order_date
    )
    or (
        delivered_date is not null
        and shipped_date is not null
        and delivered_date < shipped_date
    )
    or days_to_ship < 0
    or days_to_deliver < 0
