-- 02_aggregation_joins.sql
-- Aggregation and joins. KPI: delivered orders with delivery_minutes <= 10 / delivered orders. Cancelled orders excluded.

-- (a) Overall compliance: <= 10 (KPI) vs < 10 (strict boundary)
-- Expected 79.01 and 57.75. Delivered-only denominator via COUNT(delivery_minutes).
SELECT COUNT(delivery_minutes) AS delivered_orders,
       SUM(CASE WHEN delivery_minutes <= 10 THEN 1 ELSE 0 END) AS within_sla_orders,
       ROUND(100.0 * SUM(CASE WHEN delivery_minutes <= 10 THEN 1 ELSE 0 END) / COUNT(delivery_minutes), 2) AS compliance_pct_le_10,
       ROUND(100.0 * SUM(CASE WHEN delivery_minutes < 10 THEN 1 ELSE 0 END) / COUNT(delivery_minutes), 2) AS compliance_pct_lt_10
FROM orders
WHERE status = 'Delivered';
-- Result (1 row):
-- delivered_orders | within_sla_orders | compliance_pct_le_10 | compliance_pct_lt_10
-- 5616 | 4437 | 79.01 | 57.75

-- (b1) Compliance by city
-- Expected Mumbai 79.89, Bengaluru 78.14
SELECT d.city,
       COUNT(o.delivery_minutes) AS delivered_orders,
       ROUND(100.0 * SUM(CASE WHEN o.delivery_minutes <= 10 THEN 1 ELSE 0 END) / COUNT(o.delivery_minutes), 2) AS compliance_pct
FROM orders o
JOIN dark_stores d ON o.store_id = d.store_id
WHERE o.status = 'Delivered'
GROUP BY d.city
ORDER BY compliance_pct DESC;
-- Result (2 rows):
-- city | delivered_orders | compliance_pct
-- Mumbai | 2789 | 79.89
-- Bengaluru | 2827 | 78.14

-- (b2) Compliance by cluster
-- Expected range Whitefield 72.63 to Thane 85.03
SELECT d.cluster,
       COUNT(o.delivery_minutes) AS delivered_orders,
       ROUND(100.0 * SUM(CASE WHEN o.delivery_minutes <= 10 THEN 1 ELSE 0 END) / COUNT(o.delivery_minutes), 2) AS compliance_pct
FROM orders o
JOIN dark_stores d ON o.store_id = d.store_id
WHERE o.status = 'Delivered'
GROUP BY d.cluster
ORDER BY compliance_pct ASC;
-- Result (6 rows):
-- cluster | delivered_orders | compliance_pct
-- Whitefield | 950 | 72.63
-- Andheri | 982 | 73.93
-- Koramangala | 938 | 78.36
-- Powai | 925 | 81.3
-- Indiranagar | 939 | 83.49
-- Thane | 882 | 85.03

-- (c) Compliance by hour band
-- Expected Evening 69.17 (lowest), Morning 89.92 (highest). Join key: hour text from order_ts.
SELECT h.band,
       COUNT(o.delivery_minutes) AS delivered_orders,
       ROUND(100.0 * SUM(CASE WHEN o.delivery_minutes <= 10 THEN 1 ELSE 0 END) / COUNT(o.delivery_minutes), 2) AS compliance_pct
FROM orders o
JOIN hour_bands h ON STRFTIME('%H', o.order_ts) = h.hour_text
WHERE o.status = 'Delivered'
GROUP BY h.band
ORDER BY compliance_pct ASC;
-- Result (4 rows):
-- band | delivered_orders | compliance_pct
-- Evening | 1849 | 69.17
-- Lunch | 1457 | 75.09
-- Afternoon | 1119 | 88.74
-- Morning | 1191 | 89.92

-- (d) Compliance by category with more than 1000 delivered orders
-- Expected F&V 62.4, Snacks & Beverages 83.56, Dairy & Bread 84.74
SELECT category,
       COUNT(delivery_minutes) AS delivered_orders,
       ROUND(100.0 * SUM(CASE WHEN delivery_minutes <= 10 THEN 1 ELSE 0 END) / COUNT(delivery_minutes), 2) AS compliance_pct
FROM orders
WHERE status = 'Delivered'
GROUP BY category
HAVING COUNT(delivery_minutes) > 1000
ORDER BY compliance_pct ASC;
-- Result (3 rows):
-- category | delivered_orders | compliance_pct
-- Fruits & Vegetables | 1274 | 62.4
-- Snacks & Beverages | 1320 | 83.56
-- Dairy & Bread | 1658 | 84.74

-- (e) Every store with its order count (LEFT JOIN keeps the not-yet-live store)
-- Expected Powai Annex (not yet live) first with 0
SELECT d.store_name,
       COUNT(o.order_id) AS total_orders
FROM dark_stores d
LEFT JOIN orders o ON d.store_id = o.store_id
GROUP BY d.store_id, d.store_name
ORDER BY total_orders ASC, d.store_name ASC;
-- Result (13 rows):
-- store_name | total_orders
-- Powai Annex (not yet live) | 0
-- Powai Hiranandani 2 | 467
-- Thane Ghodbunder 1 | 467
-- Thane Naupada 2 | 480
-- Koramangala 8th Block | 486
-- Whitefield Main | 499
-- Indiranagar 100ft | 506
-- Andheri East 2 | 511
-- Koramangala 5th Block | 511
-- Whitefield ITPL | 511
-- Indiranagar CMH | 512
-- Powai Lake 1 | 519
-- Andheri West 1 | 531
