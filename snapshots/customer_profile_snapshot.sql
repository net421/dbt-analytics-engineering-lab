{% snapshot customer_profile_snapshot %}
{{
  config(
    target_schema='snapshots',
    unique_key='customer_id',
    strategy='check',
    check_cols=['customer_segment', 'region']
  )
}}
select customer_id, customer_segment, region
from {{ source('crm', 'raw_customers') }}
{% endsnapshot %}
