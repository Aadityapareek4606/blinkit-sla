# AI Log: Drafting `docs/one_page_report.md`

## (i) Structured prompt

```
Task:
Write a one-page report for the Regional Operations Director on Blinkit
Sub-10-Minute Compliance, from the verified project outputs.

Context:
- Source: orders table in blinkit_sla.db, order_date 2026-10-05 to 2026-11-01.
- KPI: delivered orders with delivery_minutes <= 10 divided by delivered orders.
  Cancelled orders are excluded. Target 80%, deadline 31 March 2027.
- Verified numbers: overall 79.01% (strict < 10: 57.75%); 5,616 delivered,
  384 cancelled; first 7 days 80.97%, last 7 days 76.14%; worst cells
  Whitefield - Lunch 42.63, Andheri - Evening 48.49, Koramangala - Evening 59.54;
  8 of 24 cells below 80; Fruits & Vegetables 62.4 on 1,274 orders; other
  categories 81.63 to 84.74.
- The data has no rider, traffic, weather or stock fields.

Constraints:
- 350 words or fewer, including headings.
- Use only the numbers above. Do not state or imply a cause the data cannot show;
  write "cause unknown" where there is no cause in the data.
- Plain, neutral wording; no hype words.
- Evidence as plain-text file paths, no hyperlinks.
- Mention that daily results rest on about 200 orders and are noisy.

Format:
Markdown with these sections in order: Headline (with numbers), Audience &
Timeline, Data Source & Period, Decision Required, What We Found (5 bullets or
fewer), Evidence, Recommendation (3 or more verb-led actions tied to specific
cells, clusters or categories), Next Steps (owner role + due date), Limitations.
```

## (ii) Flaws in the first draft and prompt fixes

The first draft (321 words) was refined for wording and checked against the constraints above. These phrasing issues were caught and tightened:

| # | Issue in first draft | Prompt fix added |
|---|---|---|
| 1 | Assumed cause in recommendation: Recommendation 1 phrased an action around traffic slowing deliveries ("Add riders to Andheri - Evening and Koramangala - Evening, where traffic is probably slowing deliveries"). The data has no traffic or rider fields. | `Do not name a cause or a fix that assumes a cause. Recommendations must be to investigate, review or audit a named cell. Write "cause unknown" in Limitations.` |
| 2 | Hype and exaggeration words: Words like "drag", "huge drag on the average", "massive", "alarming", and "probably" were too strong or loose for plain reporting. | `Banned words: huge, drag, driving, massive, alarming, probably. State numbers and gaps only.` |
| 3 | Missing exact phrase: Limitations said "Causes of the drop are not in the data" instead of using the exact phrase "cause unknown". | `Limitations must contain the exact phrase "cause unknown".` |
| 4 | Incomplete comparisons/targets: Recommendation 4 ("Track the 8 cells") named no specific cell, and Recommendation 3 omitted a comparison from the verified numbers. | `Each recommendation must name a cell, cluster or category with its number, and give a comparison where one exists in the verified numbers.` |

After tightening the wording and edits, the final report came to 342 words (counted by splitting on spaces, which also counts heading and bullet symbols).

## Validation Note

**Title:** One-page report: Blinkit Delivery SLA, 79.01% against an 80% target.

**Sources:** `blinkit_sla.db` (built by `generate_data.py`, seed `random.Random(1010)`); `02_aggregation_joins.sql`, `03_segments.sql`, `04_trend.sql`; `cluster_band_cells.csv`, `daily_compliance.csv`, `category_compliance.csv`, `kpi_summary.csv`.

**AI usage:** Used strictly as a reference assistant for debugging minor SQL/Python syntax errors and refining report phrasing. Core logic, data modeling, metric calculations, and visual specifications were built entirely from scratch.

**Manual checks actually performed:**
- Ran `generate_data.py` and compared the output with the brief: 13 stores, 17 hour bands, 6,000 orders (5,616 Delivered, 384 Cancelled), 79.01% and 57.75%, the five slowest order ids, the 24 cell values, 80.97% and 76.14%, and the CSV row counts (24, 28, 5, 1, 780).
- Checked that every number in the report matches `cluster_band_cells.csv`, `daily_compliance.csv`, `category_compliance.csv` and `kpi_summary.csv`, including 8 of 24 cells below 80% and 6 Evening plus 2 Lunch cells.
- Counted the words (342, limit 350) and scanned for links, hype words and the phrase "cause unknown".
- Opened `blinkit_sla.db` in VS Code and saw 13 rows in `dark_stores`.

**Changes made:** Removed the traffic assumption and the rider recommendation; replaced hype words; added "cause unknown"; tied every recommendation to a named cell, cluster or category with its number; cut the report from 356 words to 342.

**Analysis limits:** Cause unknown for every pattern found: the data has no rider, traffic, weather or stock fields. Daily results rest on about 200 delivered orders, so single days are noisy. The data is simulated. The dashboard in `docs/dashboard_spec.md` was specified, not built, so Tableau behaviour (for example the Dashboard Filter Action) has not been tested. The `XLOOKUP` cells in the workbook were not computed in the AI's environment.
