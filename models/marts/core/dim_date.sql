with bounds as (
    select min(order_date) as min_date, max(promised_date) as max_date
    from {{ ref('stg_orders') }}
),
date_spine as (
    select cast(date_day as date) as date_day
    from bounds,
    generate_series(min_date, max_date, interval 1 day) as dates(date_day)
)
select
    date_day,
    extract(year from date_day) as calendar_year,
    extract(quarter from date_day) as calendar_quarter,
    extract(month from date_day) as calendar_month,
    monthname(date_day) as month_name,
    extract(week from date_day) as calendar_week,
    dayname(date_day) as day_name,
    date_trunc('month', date_day)::date as month_start_date,
    date_trunc('week', date_day)::date as week_start_date
from date_spine
