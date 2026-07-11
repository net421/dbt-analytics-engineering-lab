with source_revenue as (
    select round(sum(revenue), 2) as revenue from {{ ref('stg_orders') }}
),
mart_revenue as (
    select round(sum(order_revenue), 2) as revenue from {{ ref('fct_orders') }}
)
select source_revenue.revenue as source_revenue, mart_revenue.revenue as mart_revenue
from source_revenue cross join mart_revenue
where source_revenue.revenue <> mart_revenue.revenue
