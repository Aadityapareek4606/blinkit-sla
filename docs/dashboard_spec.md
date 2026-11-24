# Dashboard Specification: Blinkit Sub-10-Minute Compliance (Tableau Public)

Audience: Regional Operations Director. Refresh: weekly (manual re-export of the CSVs, then re-publish). Period shown: 2026-10-05 to 2026-11-01. Cancelled orders are excluded in every number.

## 1. Data sources

Tableau Public cannot read SQLite, so every view reads one of the CSVs exported from `blinkit_sla.db`. Connect each as a separate Text File source.

| Source file | Rows | Used by |
|---|---|---|
| `daily_compliance.csv` | 28 | W1 |
| `cluster_band_cells.csv` | 24 | W2, W3 |
| `category_compliance.csv` | 5 | W4 |
| `kpi_summary.csv` | 1 | W5 |

**Calculated field `Compliance %`** (create in each of the first three sources):
`SUM([within_sla_orders]) / SUM([delivered_orders]) * 100`
Always use this field, never `AVERAGE` of `compliance_pct`, so that totals are weighted by orders.

**Colour rule used everywhere** (calculated field `Status Band`):
`IF [Compliance %] < 60 THEN "Below 60" ELSEIF [Compliance %] < 80 THEN "60 to under 80" ELSE "80 or above" END`
Manual colours: Below 60 = `#F8696B` (red), 60 to under 80 = `#FFD966` (amber), 80 or above = `#63BE7B` (green). Target lines are dashed `#404040`.

## 2. Worksheets

### W1 Daily Trend
- **Question:** Is compliance rising or falling day to day?
- **Source:** `daily_compliance.csv`
- **Columns:** `order_date` as Day, continuous (exact date), format `d mmm`.
- **Rows:** `Compliance %`.
- **Marks:** Line, with circle markers. Colour is a single blue, `#1F77B4` (not Status Band, because it is a trend).
- **Axis:** fixed from 70 to 90. Title `Compliance % (<= 10 minutes)`.
- **Reference line:** constant 80, dashed, label `Target 80%`.
- **Sort:** chronological (date axis).
- **Annotations (typed text, copied from `04_trend.sql`; Tableau does not compute them):**
  - Area annotation over 5 to 11 Oct: `First 7 days: 80.97%`
  - Area annotation over 26 Oct to 1 Nov: `Last 7 days: 76.14% (down 4.83 pts)`
  - Point annotation on 31 Oct: `Lowest day: 72.86%`
  - Caption text: `Each day has about 200 delivered orders, so single days are noisy.`
- **Checkpoints:** 28 points; first day (5 Oct) 76.5; last day (1 Nov) 73.91; lowest 72.86 (31 Oct); highest 85.65 (7 Oct and 12 Oct).

### W2 Cluster-Band Cells
- **Question:** Which cluster and hour band combinations miss 80%?
- **Source:** `cluster_band_cells.csv`
- **Rows:** `cluster`. **Columns:** `band`, with manual sort Morning, Lunch, Afternoon, Evening.
- **Marks:** Square (heat table). **Colour:** `Status Band` with the manual colours above. **Label:** `Compliance %`, number format 0.00.
- **Tooltip:** `<cell_label>: <Compliance %>% (<within_sla_orders> of <delivered_orders> delivered)`.
- **Sort (rows):** by `Compliance %` ascending, computed across the whole view.
- **Filter:** `city` (Mumbai, Bengaluru), multiple values, dropdown, default All (see section 4).
- **Annotation:** caption `8 of 24 cells are below 80%; 3 are below 60%.`
- **Checkpoints:** 24 cells. Red: Whitefield - Lunch 42.63, Andheri - Evening 48.49, Koramangala - Evening 59.54. Amber (5): Powai - Evening 74.26, Powai - Lunch 77.87, Whitefield - Evening 78.03, Indiranagar - Evening 78.27, Thane - Evening 78.45. Best cell: Thane - Morning 93.4.

### W3 Worst N
- **Question:** What are the N weakest cells?
- **Source:** `cluster_band_cells.csv`
- **Parameter `N`:** Integer, range 3 to 7, step 1, default 3. Show the parameter control above the sheet (slider).
- **Calculated field `Cell Label`:** `[cluster] + " - " + [band]`
- **Calculated field `Rank`:** `RANK_UNIQUE([Compliance %], 'asc')`, computed along `Cell Label`.
- **Filters:** `Rank <= [N]` (table calculation filter).
- **Rows:** `Cell Label`. **Columns:** `Compliance %`. **Marks:** Bar. **Colour:** `Status Band`. **Label:** `Compliance %`, 0.00.
- **Sort:** `Cell Label` by `Compliance %`, ascending (weakest at the top).
- **Reference line:** constant 80, dashed, label `Target 80%`.
- **Checkpoints:** N = 3 shows Whitefield - Lunch 42.63, Andheri - Evening 48.49, Koramangala - Evening 59.54. N = 7 adds Powai - Evening 74.26, Powai - Lunch 77.87, Whitefield - Evening 78.03, Indiranagar - Evening 78.27.

### W4 Category
- **Question:** Does any product category stand out?
- **Source:** `category_compliance.csv` (all 5 categories; the SQL `HAVING COUNT(delivery_minutes) > 1000` filter is not applied here).
- **Rows:** `category`. **Columns:** `Compliance %`. **Marks:** Bar. **Colour:** `Status Band`. **Label:** `Compliance %`, 0.00.
- **Sort:** `category` by `Compliance %`, ascending.
- **Reference line:** constant 80, dashed, label `Target 80%`.
- **Annotation:** on Fruits & Vegetables: `62.4% on 1,274 delivered orders`.
- **Checkpoints:** Fruits & Vegetables 62.4, Household 81.63, Snacks & Beverages 83.56, Personal Care 84.57, Dairy & Bread 84.74.

### W5 Big Numbers
- **Question:** Where do we stand overall?
- **Source:** `kpi_summary.csv`. Four text tiles (Marks: Text, one measure per tile, font size 28 bold for the number, 10 for the label).

| Tile | Field | Displayed value |
|---|---|---|
| Compliance (<= 10 min) | `compliance_pct_le_10`, format 0.00"%" | 79.01% |
| Gap to 80% target | calculated `80 - SUM([compliance_pct_le_10])`, format 0.00" pts below" | 0.99 pts below |
| Delivered orders | `delivered_orders`, format #,##0 | 5,616 |
| Strict reading (< 10 min) | `compliance_pct_lt_10`, format 0.00"%" | 57.75% |

Tile 1 uses amber `#FFD966` (79.01 is under 80). Tile 4 has the label `For reference only: not the KPI`.

## 3. Dashboard layout

- **Size:** Fixed size, 1200 x 768 pixels (Dashboard > Size > Fixed size > Custom).
- **Layout order (top to bottom, left to right), tiled containers, 4 px padding:**

| Position | Content | Size (w x h) |
|---|---|---|
| Row 0 | Title `Blinkit Sub-10-Minute Compliance, 5 Oct to 1 Nov 2026` | 1200 x 48 |
| Row 1 | W5 Big Numbers (four tiles of 300 px) | 1200 x 96 |
| Row 2 left | W1 Daily Trend | 600 x 312 |
| Row 2 right | W2 Cluster-Band Cells with the City filter above it | 600 x 312 |
| Row 3 left | W3 Worst N with the N control above it | 600 x 312 |
| Row 3 right | W4 Category | 600 x 312 |

- Hide all other legends. Keep only the colour legend `Status Band` once, inside W2.
- Footer text (inside the title row): `Source: orders in blinkit_sla.db. Cancelled orders excluded.`

## 4. Filter scope and actions

**City filter applies to W2 only.** In the filter menu choose Apply to Worksheets > Selected Worksheets and tick only W2. It is explicitly **not** applied to W1, W3, W4 or W5.
- W1, W4 and W5 read files with no `city` column, so they cannot be filtered by city, and they must keep showing the network-wide numbers (79.01, 62.4 and so on).
- W3 is excluded so that the Worst N ranking stays network-wide. If it were filtered to Mumbai, the "worst 3" would change and the checkpoint values (42.63, 48.49, 59.54) would no longer appear.

**Dashboard Filter Action:** Dashboard > Actions > Add Action > Filter.
- Source sheet: W2. Run action on: Select. Target sheet: W3.
- Field mapping: `cluster` to `cluster` and `band` to `band`. Clearing the selection: Show all values.
- Expected result: clicking the Whitefield - Lunch square in W2 filters W3 to that one cell, which shows **42.63**. The action filter runs before the Rank filter, so the single cell has rank 1 and stays visible for any N.

## 5. Story (5 points)

Create with Story > New Story, fixed size 1200 x 768. Every caption has a number.

| # | Sheet shown | Caption |
|---|---|---|
| 1 | Dashboard | `79.01% of 5,616 delivered orders arrived in 10 minutes or less, 0.99 points under the 80% target.` |
| 2 | W1 Daily Trend | `Compliance fell from 80.97% in the first 7 days to 76.14% in the last 7 days, down 4.83 points.` |
| 3 | W2 Cluster-Band Cells | `8 of 24 cells are below 80%: all 6 Evening cells and 2 Lunch cells.` |
| 4 | W3 Worst N (N = 3) | `Whitefield - Lunch is at 42.63%, Andheri - Evening 48.49% and Koramangala - Evening 59.54%.` |
| 5 | W4 Category | `Fruits & Vegetables is at 62.4% on 1,274 orders; the other four categories are between 81.63% and 84.74%.` |

## 6. Pre-publish checks

1. W5 shows 79.01, 0.99, 5,616 and 57.75.
2. W3 at N = 3 shows 42.63, 48.49 and 59.54; at N = 7 it shows 7 bars.
3. Clicking Whitefield - Lunch in W2 shows 42.63 in W3.
4. Setting City to Mumbai changes W2 only.
5. W4 shows five bars with Fruits & Vegetables at 62.4.
6. Dashboard size is fixed at 1200 x 768 and the story has 5 points.
