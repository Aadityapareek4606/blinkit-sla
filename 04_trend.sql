-- 04_trend.sql
-- Trend: daily compliance and first-7 vs last-7 day comparison.

-- (a) Daily compliance, 28 days
-- Expected 28 rows
SELECT order_date,
       COUNT(delivery_minutes) AS delivered_orders,
       SUM(CASE WHEN delivery_minutes <= 10 THEN 1 ELSE 0 END) AS within_sla_orders,
       ROUND(100.0 * SUM(CASE WHEN delivery_minutes <= 10 THEN 1 ELSE 0 END) / COUNT(delivery_minutes), 2) AS compliance_pct
FROM orders
WHERE status = 'Delivered'
GROUP BY order_date
ORDER BY order_date;
-- Result (28 rows):
-- order_date | delivered_orders | within_sla_orders | compliance_pct
-- 2026-10-05 | 200 | 153 | 76.5
-- 2026-10-06 | 215 | 169 | 78.6
-- 2026-10-07 | 209 | 179 | 85.65
-- 2026-10-08 | 174 | 138 | 79.31
-- 2026-10-09 | 212 | 174 | 82.08
-- 2026-10-10 | 210 | 167 | 79.52
-- 2026-10-11 | 199 | 169 | 84.92
-- 2026-10-12 | 223 | 191 | 85.65
-- 2026-10-13 | 211 | 159 | 75.36
-- 2026-10-14 | 198 | 159 | 80.3
-- 2026-10-15 | 200 | 168 | 84.0
-- 2026-10-16 | 180 | 148 | 82.22
-- 2026-10-17 | 195 | 149 | 76.41
-- 2026-10-18 | 197 | 157 | 79.7
-- 2026-10-19 | 184 | 148 | 80.43
-- 2026-10-20 | 206 | 161 | 78.16
-- 2026-10-21 | 185 | 141 | 76.22
-- 2026-10-22 | 220 | 172 | 78.18
-- 2026-10-23 | 199 | 156 | 78.39
-- 2026-10-24 | 196 | 155 | 79.08
-- 2026-10-25 | 178 | 139 | 78.09
-- 2026-10-26 | 212 | 164 | 77.36
-- 2026-10-27 | 223 | 170 | 76.23
-- 2026-10-28 | 190 | 145 | 76.32
-- 2026-10-29 | 221 | 169 | 76.47
-- 2026-10-30 | 196 | 156 | 79.59
-- 2026-10-31 | 199 | 145 | 72.86
-- 2026-11-01 | 184 | 136 | 73.91

-- (b) First 7 days vs last 7 days
-- Expected 80.97 (first) and 76.14 (last)
SELECT CASE WHEN order_date BETWEEN '2026-10-05' AND '2026-10-11' THEN 'First 7 days (2026-10-05 to 2026-10-11)'
            ELSE 'Last 7 days (2026-10-26 to 2026-11-01)' END AS period,
       COUNT(delivery_minutes) AS delivered_orders,
       ROUND(100.0 * SUM(CASE WHEN delivery_minutes <= 10 THEN 1 ELSE 0 END) / COUNT(delivery_minutes), 2) AS compliance_pct
FROM orders
WHERE status = 'Delivered'
  AND (order_date BETWEEN '2026-10-05' AND '2026-10-11'
    OR order_date BETWEEN '2026-10-26' AND '2026-11-01')
GROUP BY period
ORDER BY period DESC;
-- Result (2 rows):
-- period | delivered_orders | compliance_pct
-- Last 7 days (2026-10-26 to 2026-11-01) | 1425 | 76.14
-- First 7 days (2026-10-05 to 2026-10-11) | 1419 | 80.97
