# Synthetic Data Quality

The project generates all eight dbt seeds deterministically with `scripts/generate_synthetic_seeds.py`.

The generator enforces:

```text
order_date <= ship_date <= delivery_date
```

It also guarantees unique source keys, valid customer and region values, valid product-to-supplier relationships, non-negative units and costs, and one shipment per order.

Delivery promises, partial fills, late deliveries, stockouts, forecast error, and cost exceptions remain represented so the dbt tests exercise meaningful edge cases.
