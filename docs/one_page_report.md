# Blinkit Delivery SLA: 79.01% Against an 80% Target, Falling to 76.14%

## Headline
Sub-10-Minute Compliance is 79.01% against the 80% target. It fell from 80.97% to 76.14% over four weeks. Three cluster-hour cells sit below 60%.

## Audience & Timeline
Regional Operations Director. Weekly review. Target must be met by 31 March 2027.

## Data Source & Period
`orders` table in `blinkit_sla.db`, 5 Oct to 1 Nov 2026 (`order_date`). 5,616 delivered orders; 384 cancelled orders excluded.

## Decision Required
Approve store-level reviews of the three cells below 60% before the next weekly review.

## What We Found
- Overall: 79.01% delivered within 10 minutes (target 80%). Counting only "under 10" gives 57.75%.
- Trend: 80.97% (5 to 11 Oct) down to 76.14% (26 Oct to 1 Nov), a fall of 4.83 points.
- Worst cells: Whitefield - Lunch 42.63%, Andheri - Evening 48.49%, Koramangala - Evening 59.54%.
- 8 of 24 cluster-hour cells are below 80%: all 6 Evening cells and 2 Lunch cells.
- Fruits & Vegetables is 62.4% on 1,274 delivered orders; the other four categories are 81.63% to 84.74%.

## Evidence
02_aggregation_joins.sql, 03_segments.sql, 04_trend.sql, cluster_band_cells.csv, daily_compliance.csv, category_compliance.csv, kpi_summary.csv, blinkit_sla_analysis.xlsx, docs/dashboard_spec.md

## Recommendation
1. Investigate Whitefield - Lunch (42.63%) first: compare order-to-delivery steps with Whitefield - Afternoon (85.00%).
2. Review Andheri - Evening (48.49%) and Koramangala - Evening (59.54%) with store managers and the Rider-Fleet Lead.
3. Audit Fruits & Vegetables (62.4%) handling times against Dairy & Bread (84.74%).
4. Track the 8 cells below 80% every week until each reaches 80%.

## Next Steps
- Rider-Fleet Lead: share rider counts for the three worst cells by 2026-12-04.
- Dark-Store Managers (Whitefield, Andheri, Koramangala): report order-to-delivery steps by 2026-12-11.
- Data Engineering / Analytics Team: publish the weekly dashboard from 2026-12-07.

## Limitations
Root cause: cause unknown. The data has no rider, traffic, weather or stock fields, so this shows where and when orders are slow, not why. Daily results rest on about 200 orders, so one day can move by several points through noise alone. Data is simulated.
