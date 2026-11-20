-- verify.sql
-- Row-count checkpoints for blinkit_sla.db (built by generate_data.py, seed random.Random(1010)).
-- Results below were produced by running each query against the generated database.

-- Check 1: dark_stores row count
-- Expected 13
SELECT COUNT(*) AS dark_stores_rows FROM dark_stores;
-- Result (1 row):
-- dark_stores_rows
-- 13

-- Check 2: hour_bands row count
-- Expected 17 (hours 06-22)
SELECT COUNT(*) AS hour_bands_rows FROM hour_bands;
-- Result (1 row):
-- hour_bands_rows
-- 17

-- Check 3: orders row count
-- Expected 6000
SELECT COUNT(*) AS orders_rows FROM orders;
-- Result (1 row):
-- orders_rows
-- 6000

-- Check 4: orders by status
-- Expected Delivered 5616, Cancelled 384
SELECT status, COUNT(*) AS n FROM orders GROUP BY status ORDER BY n DESC;
-- Result (2 rows):
-- status | n
-- Delivered | 5616
-- Cancelled | 384
