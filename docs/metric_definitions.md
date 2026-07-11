# Metric Definitions

| Metric | Definition | Grain |
|---|---|---|
| Unit Fill Rate | Units shipped / units ordered | Order or aggregate |
| Complete Order Rate | Orders with all requested units shipped / orders | Aggregate |
| On-Time Delivery | Orders delivered on or before promised date / orders | Aggregate |
| OTIF | Orders both on time and in full / orders | Aggregate |
| Cost-to-Serve % | Logistics cost / order revenue | Order or aggregate |
| Freight Cost per kg | Freight cost / shipment weight | Order or aggregate |
| Forecast Accuracy | max(0, 1 - absolute error / actual units) | Month, warehouse, SKU |

Unit fill rate and complete-order rate are intentionally separate.
