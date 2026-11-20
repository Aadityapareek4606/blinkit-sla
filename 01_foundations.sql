-- 01_foundations.sql
-- Foundations: SELECT, WHERE, DISTINCT, LIKE, ORDER BY, BETWEEN, IS NULL, computed columns.

-- (a) Stores in Mumbai
SELECT store_id, store_name, city, cluster
FROM dark_stores
WHERE city = 'Mumbai'
ORDER BY store_id;
-- Result (7 rows):
-- store_id | store_name | city | cluster
-- 1 | Andheri West 1 | Mumbai | Andheri
-- 2 | Andheri East 2 | Mumbai | Andheri
-- 3 | Powai Lake 1 | Mumbai | Powai
-- 4 | Powai Hiranandani 2 | Mumbai | Powai
-- 5 | Thane Ghodbunder 1 | Mumbai | Thane
-- 6 | Thane Naupada 2 | Mumbai | Thane
-- 13 | Powai Annex (not yet live) | Mumbai | Powai

-- (b) Distinct clusters
SELECT DISTINCT cluster
FROM dark_stores
ORDER BY cluster;
-- Result (6 rows):
-- cluster
-- Andheri
-- Indiranagar
-- Koramangala
-- Powai
-- Thane
-- Whitefield

-- (c) Stores whose name starts with 'Powai'
-- Expected 3 stores (includes the not-yet-live Annex)
SELECT store_id, store_name
FROM dark_stores
WHERE store_name LIKE 'Powai%'
ORDER BY store_id;
-- Result (3 rows):
-- store_id | store_name
-- 3 | Powai Lake 1
-- 4 | Powai Hiranandani 2
-- 13 | Powai Annex (not yet live)

-- (d) Top 5 slowest orders
-- Tie-break on order_id ASC. Expected 616, 762, 2565, 3337, 602
SELECT order_id, store_id, order_date, delivery_minutes
FROM orders
WHERE status = 'Delivered'
ORDER BY delivery_minutes DESC, order_id ASC
LIMIT 5;
-- Result (5 rows):
-- order_id | store_id | order_date | delivery_minutes
-- 616 | 2 | 2026-10-27 | 20
-- 762 | 2 | 2026-10-21 | 20
-- 2565 | 1 | 2026-11-01 | 20
-- 3337 | 2 | 2026-10-19 | 20
-- 602 | 1 | 2026-10-06 | 19

-- (e) Delivered orders taking 11 to 15 minutes
-- Expected 1079
SELECT COUNT(*) AS orders_11_to_15
FROM orders
WHERE delivery_minutes BETWEEN 11 AND 15;
-- Result (1 row):
-- orders_11_to_15
-- 1079

-- (f) Orders with no delivery time (cancelled)
-- Expected 384
SELECT COUNT(*) AS null_delivery_orders
FROM orders
WHERE delivery_minutes IS NULL;
-- Result (1 row):
-- null_delivery_orders
-- 384

-- (g) Minutes over the 10-minute SLA, delivered orders
-- Negative = faster than SLA. First 10 rows shown in the comment.
SELECT order_id, delivery_minutes,
       delivery_minutes - 10 AS minutes_over_sla
FROM orders
WHERE status = 'Delivered'
ORDER BY order_id;
-- Result (5616 rows):
-- order_id | delivery_minutes | minutes_over_sla
-- 1 | 10 | 0
-- 2 | 10 | 0
-- 3 | 9 | -1
-- 4 | 9 | -1
-- 5 | 11 | 1
-- 6 | 10 | 0
-- 7 | 8 | -2
-- 8 | 7 | -3
-- 9 | 8 | -2
-- 10 | 9 | -1
-- ... (5606 more rows not shown)
