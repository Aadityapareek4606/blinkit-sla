-- 03_segments.sql
-- Segments: cluster x hour-band cells with ranks (CTE + window functions).

-- Cluster x hour-band cells (>= 150 delivered orders), worst first
-- Expected 24 cells. Worst 3: Whitefield - Lunch 42.63, Andheri - Evening 48.49, Koramangala - Evening 59.54
WITH cell_metrics AS (
    SELECT d.city,
           d.cluster,
           h.band,
           d.cluster || ' - ' || h.band AS cell_label,
           COUNT(o.delivery_minutes) AS delivered_orders,
           SUM(CASE WHEN o.delivery_minutes <= 10 THEN 1 ELSE 0 END) AS within_sla_orders,
           ROUND(100.0 * SUM(CASE WHEN o.delivery_minutes <= 10 THEN 1 ELSE 0 END) / COUNT(o.delivery_minutes), 2) AS compliance_pct,
           ROUND(AVG(o.delivery_minutes), 2) AS avg_minutes
    FROM orders o
    JOIN dark_stores d ON o.store_id = d.store_id
    JOIN hour_bands h ON STRFTIME('%H', o.order_ts) = h.hour_text
    WHERE o.status = 'Delivered'
    GROUP BY d.city, d.cluster, h.band
    HAVING COUNT(o.delivery_minutes) >= 150
)
SELECT city, cluster, band, cell_label, delivered_orders, within_sla_orders, compliance_pct, avg_minutes,
       RANK() OVER (PARTITION BY city ORDER BY compliance_pct ASC) AS rank_in_city,
       RANK() OVER (ORDER BY compliance_pct ASC) AS rank_overall
FROM cell_metrics
ORDER BY rank_overall, cell_label;
-- Result (24 rows):
-- city | cluster | band | cell_label | delivered_orders | within_sla_orders | compliance_pct | avg_minutes | rank_in_city | rank_overall
-- Bengaluru | Whitefield | Lunch | Whitefield - Lunch | 251 | 107 | 42.63 | 11.07 | 1 | 1
-- Mumbai | Andheri | Evening | Andheri - Evening | 332 | 161 | 48.49 | 11.95 | 1 | 2
-- Bengaluru | Koramangala | Evening | Koramangala - Evening | 304 | 181 | 59.54 | 10.7 | 2 | 3
-- Mumbai | Powai | Evening | Powai - Evening | 303 | 225 | 74.26 | 9.4 | 2 | 4
-- Mumbai | Powai | Lunch | Powai - Lunch | 235 | 183 | 77.87 | 9.33 | 3 | 5
-- Bengaluru | Whitefield | Evening | Whitefield - Evening | 314 | 245 | 78.03 | 9.48 | 3 | 6
-- Bengaluru | Indiranagar | Evening | Indiranagar - Evening | 313 | 245 | 78.27 | 9.43 | 4 | 7
-- Mumbai | Thane | Evening | Thane - Evening | 283 | 222 | 78.45 | 9.46 | 4 | 8
-- Mumbai | Andheri | Lunch | Andheri - Lunch | 269 | 220 | 81.78 | 9.09 | 5 | 9
-- Bengaluru | Koramangala | Lunch | Koramangala - Lunch | 236 | 194 | 82.2 | 9.25 | 5 | 10
-- Bengaluru | Indiranagar | Lunch | Indiranagar - Lunch | 242 | 199 | 82.23 | 9.14 | 6 | 11
-- Bengaluru | Whitefield | Afternoon | Whitefield - Afternoon | 180 | 153 | 85.0 | 8.58 | 7 | 12
-- Mumbai | Thane | Lunch | Thane - Lunch | 224 | 191 | 85.27 | 9.1 | 6 | 13
-- Mumbai | Thane | Afternoon | Thane - Afternoon | 178 | 153 | 85.96 | 8.61 | 7 | 14
-- Bengaluru | Koramangala | Morning | Koramangala - Morning | 204 | 179 | 87.75 | 8.38 | 8 | 15
-- Bengaluru | Indiranagar | Afternoon | Indiranagar - Afternoon | 192 | 169 | 88.02 | 8.56 | 9 | 16
-- Mumbai | Powai | Afternoon | Powai - Afternoon | 187 | 165 | 88.24 | 8.49 | 8 | 17
-- Bengaluru | Indiranagar | Morning | Indiranagar - Morning | 192 | 171 | 89.06 | 8.34 | 10 | 18
-- Mumbai | Powai | Morning | Powai - Morning | 200 | 179 | 89.5 | 8.34 | 9 | 19
-- Mumbai | Andheri | Morning | Andheri - Morning | 193 | 173 | 89.64 | 8.44 | 10 | 20
-- Bengaluru | Whitefield | Morning | Whitefield - Morning | 205 | 185 | 90.24 | 8.34 | 11 | 21
-- Mumbai | Andheri | Afternoon | Andheri - Afternoon | 188 | 172 | 91.49 | 8.47 | 11 | 22
-- Bengaluru | Koramangala | Afternoon | Koramangala - Afternoon | 194 | 181 | 93.3 | 8.39 | 12 | 23
-- Mumbai | Thane | Morning | Thane - Morning | 197 | 184 | 93.4 | 8.17 | 12 | 24
