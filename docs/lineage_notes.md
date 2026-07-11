# Lineage and Modeling Decisions

```mermaid
flowchart LR
  Generator[Deterministic source generator] --> Seeds[ERP / TMS / WMS / CRM seeds]
  Seeds --> Sources[dbt sources]
  Sources --> Staging[stg_* typed views]
  Staging --> Intermediate[int_order_lines_enriched]
  Intermediate --> Fulfillment[int_order_fulfillment]
  Fulfillment --> Facts[fct_orders / fct_order_lines]
  Fulfillment --> OpsMart[mart_supply_chain_kpis]
  Staging --> Inventory[mart_inventory_risk]
  Staging --> Forecast[mart_forecast_accuracy]
  Fulfillment --> Customer[int_customer_orders]
  Customer --> CustomerMart[mart_customer_value]
  OpsMart --> Exposure[Supply Chain Control Tower exposure]
```

## Grain

- `stg_orders`: one row per order line.
- `int_order_fulfillment`: one row per order.
- `fct_order_lines`: one row per order line.
- `fct_orders`: one row per order.
- `mart_supply_chain_kpis`: one row per order date and warehouse.
- `mart_inventory_risk`: one row per snapshot date, warehouse, and SKU.
- `mart_customer_value`: one row per customer.

The complete project corrects the earlier scaffold mismatch: `fct_orders` depends on `int_order_fulfillment`, which depends on enriched line-level staging data.
