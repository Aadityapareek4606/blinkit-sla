# Requirements: Blinkit Delivery SLA Diagnostic

## Situation

The Regional Operations Director asked: *"Build me a real-time dashboard of every late order across all stores."*

| Item | Agreed detail |
|---|---|
| Review rhythm | Weekly review is sufficient |
| Target | At least 80% of delivered orders delivered in 10 minutes or less, in every cluster and every hour band |
| Deadline | End of next quarter (31 March 2027) |
| Owner | Regional Operations Director |
| Date used | `order_date` |
| Source | `orders` table in `blinkit_sla.db` |
| Exclusions | Cancelled orders are excluded |

---

## Task 1: Stakeholder Grid

| Stakeholder | Interest | Influence | Quadrant | Action | Official Number Owner |
|---|---|---|---|---|---|
| Regional Operations Director | Cares a lot | Can change, approve or block it | Manage Closely | Agree the KPI, target and scope; review the weekly numbers | Owns the official compliance number: signs off the 80% target and the reported compliance figure |
| Data Engineering / Analytics Team | Cares a lot | Can change, approve or block it | Manage Closely | Confirm the data source and KPI formula; keep the pipeline stable | Owns the official delivery timestamps (`order_ts`, `delivery_minutes` in `orders`) |
| Finance Team | Cares less | Can change, approve or block it | Keep Satisfied | Share the cost of any extra riders or staffing before it is proposed | No ownership; consumes the official compliance number |
| Dark-Store Managers | Cares a lot | Cannot change the work | Keep Informed | Send the weekly cell-level results for their cluster | No ownership; consume the official compliance number |
| Rider-Fleet Lead | Cares a lot | Cannot change the work | Keep Informed | Share the worst cells (cluster and hour band) so rider supply can be checked | No ownership; consumes the official compliance number |
| Category / Growth Team | Cares less | Cannot change the work | Monitor | Share the category view once; no regular updates | No ownership; consumes the official compliance number |

**Official number owners.** The Data Engineering / Analytics Team owns the official delivery timestamps. The Regional Operations Director owns the official compliance numbers. Any figure in this project must trace back to those two owners.

---

## Task 2: Questions and Playback

### Better questions

| Original question | Open-ended rewrite | Why the original was poor |
|---|---|---|
| "Do you want a bar chart or a line chart?" | "What decision will you make from this each week, and what would you need to see to make it?" | It asks about a chart type before the decision is known, and offers only two answers. |
| "Should it be real-time?" | "How soon after an order is delivered do you need to act on a slow-delivery pattern, and what would you do differently if you knew sooner?" | A yes/no question invites "yes" by default and hides the real need for speed. |
| "Do you need every late order listed?" | "When you look at late deliveries, what do you want to understand: which places, which times, or which orders, and what will you do with that?" | It assumes the answer is a list, and a list of every late order does not point to a cause or an action. |

### Playback

You asked for a real-time dashboard of every late order across all stores. From our discussion, what you actually need is a weekly view of where and when we miss the 10-minute promise, so you can direct fixes to the clusters and hour bands that are furthest below the 80% target. We will build a weekly Sub-10-Minute Compliance view, cut by cluster, hour band, category and day, using delivered orders from `orders` in `blinkit_sla.db` (cancelled orders excluded). It will not stream live data or list every late order.

---

## Task 3: Ask, Need, Build

| Ask | Need | Build |
|---|---|---|
| "Real-time dashboard" | A weekly check on whether delivery speed is on target | Weekly-refresh dashboard of Sub-10-Minute Compliance (trend and big numbers) |
| "Every late order across all stores" | To find which clusters and hour bands miss the target, and by how much | Cluster-by-hour-band view with a ranked "worst N" list |
| "All stores" | To know where to send riders and attention first | Compliance by city and cluster, plus a category view, each compared with the 80% target |

**Need Statement:**

"Regional Operations Director needs to review Sub-10-Minute Compliance by cluster and hour band every week so that the cells below 80% are fixed before the end of next quarter."

---

## Task 4: KPI Definition

### Sub-10-Minute Compliance

| Field | Definition |
|---|---|
| **Name** | Sub-10-Minute Compliance |
| **Definition** | The share of delivered orders that reached the customer in 10 minutes or less |
| **Question answered** | Are we keeping the 10-minute delivery promise, and where and when are we not? |
| **Formula** | `COUNT(delivery_minutes <= 10) / COUNT(delivery_minutes)`. In SQL: `SUM(CASE WHEN delivery_minutes <= 10 THEN 1 ELSE 0 END) / COUNT(delivery_minutes)`, so the denominator is delivered orders only (`COUNT(delivery_minutes)`) |
| **Counted on** | Delivered orders (`status = 'Delivered'`; cancelled orders have no `delivery_minutes` and are excluded) |
| **Date used** | `order_date` |
| **Cut by** | City, cluster, hour band, category, and day |
| **Target** | 80% |
| **Deadline** | End of next quarter (31 March 2027) |
| **Starting point** | 79.01% (4,437 of 5,616 delivered orders, 5 Oct to 1 Nov 2026) |
| **Owner** | Regional Operations Director |
| **Source** | `orders` table in `blinkit_sla.db`, joined to `dark_stores` and `hour_bands` for cuts |

### Boundary Note

The promise is "10 minutes or less", so an order delivered in exactly 10 minutes counts as on time (`delivery_minutes <= 10`). That gives 79.01%. If the boundary were exclusive (`delivery_minutes < 10`), the same orders would score 57.75%, which is 21.26 percentage points lower. Reporting the wrong boundary would turn a result 0.99 points below target into one that looks 22.25 points below target, and would send the team to fix a problem that mostly does not exist. The inclusive boundary is fixed in the definition and used in every query, so every report uses the same number.

---

## Task 5: Decision Log and Scope

### Decision Log

| Date | Decision | Agreed roles | Why it matters |
|---|---|---|---|
| 2026-11-02 | Replace the "real-time, every late order" request with a weekly compliance view by cluster and hour band | Regional Operations Director approves; Data Engineering / Analytics Team builds | A weekly review matches how fixes are made, and a cell-level view points to where action is needed |
| 2026-11-03 | The KPI is delivered orders with `delivery_minutes <= 10` divided by all delivered orders; cancelled orders are excluded | Regional Operations Director owns the number; Data Engineering / Analytics Team owns the timestamps | Fixes the boundary (79.01% vs 57.75%) and the denominator, so every report gives the same answer |

### Out of Scope

| Item | Reason |
|---|---|
| Real-time streaming refresh | The review is weekly, and a streaming pipeline would add cost without changing any decision |
| Order-level live tracking or a list of every late order | A list does not show patterns by cluster or hour band, which is where fixes are directed |
| Root-cause analysis (traffic, weather, rider supply) | The data has no fields for these, so any cause would be a guess; the analysis reports where and when, and labels causes as unknown |
| Powai Annex (not yet live) | The store has no orders yet, so it has no compliance figure |
