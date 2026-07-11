with source_units as (
    select sum(units_ordered) as units_ordered, sum(units_shipped) as units_shipped
    from {{ ref('stg_orders') }}
),
mart_units as (
    select sum(units_ordered) as units_ordered, sum(units_shipped) as units_shipped
    from {{ ref('fct_orders') }}
)
select *
from source_units cross join mart_units
where source_units.units_ordered <> mart_units.units_ordered
   or source_units.units_shipped <> mart_units.units_shipped
