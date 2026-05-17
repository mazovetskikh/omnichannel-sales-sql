# Omnichannel Sales Analysis — PostgreSQL

SQL analysis of online and offline sales data for a retail company, combining multiple data sources to answer real business questions about customers, products, and channel performance.

---

## Business Context

A retail company operates both an **online store** and a network of **offline stores**. The goal of this analysis is to understand:
- Who are the highest-spending customers?
- Which customers and products appear in both channels?
- How do average order values compare between online and offline?
- Which months drive the most high-value purchases?

---

## Database Structure

| Table | Description |
|---|---|
| `orders_sql_project` | Online orders |
| `order_items_sql_project` | Online order line items |
| `store_orders` | Offline store orders |
| `store_order_items` | Offline store order line items |
| `products_sql_project` | Product catalogue with prices |
| `payments_sql_project` | Payment records with status |

---

## Queries & Key Findings

### Top Customers by Online Spend
Ranked all online customers by total spend using multi-table JOIN across orders, items, and products.

**Top result:** User #49 — $670,055 in total online purchases. Top 3 users account for a significantly disproportionate share of revenue.

---

### Customer Activity Across Channels
Identified how many orders each customer placed online vs offline using UNION ALL and conditional aggregation.

**Finding:** Users #37 and #5 are the most active overall (28 orders each). Notably, users #37 and #34 are true omnichannel buyers — purchasing heavily in both channels. Several top spenders shop exclusively online.

---

### Products Sold in Both Channels
Used INTERSECT to find products available in both online and offline channels, joined with product details.

**Finding:** Products sold in both channels are predominantly ElectroLine brand, led by "Клавіатура Prime 4" at 45,601 and "Лампа Max 25" at 44,149. These cross-channel products represent the core assortment.

---

### True Omnichannel Buyers (Bulk Purchasers)
Identified customers who bought more than 2 units per item in **both** online and offline channels using INTERSECT with subqueries.

**Finding:** Only 3 users (IDs: 5, 7, 37) qualify as true omnichannel bulk buyers — a highly valuable segment for loyalty and upsell programmes.

---

### Average Online Order Value (Paid Orders Only)
Calculated average check for paid online orders by joining orders, items, products, and payments.

**Result:** Average online order value = **$51,710.91**

---

### Channel Volume Comparison
Compared total items sold and number of unique orders across online and offline channels using CTE + UNION ALL.

| Channel | Total Items | Unique Orders |
|---|---|---|
| Online | 615 | 295 |
| Offline | 667 | 180 |

**Finding:** Offline has fewer orders but more items per order — suggesting larger basket sizes in-store. Online has more frequent but smaller purchases.

---

### Top 3 Products by Unique Buyers (Both Channels)
Found the 3 most popular products by number of unique customers who purchased them across both channels.

**Top products by unique buyers:**
- Product #20 — 20 unique buyers
- Product #17 — 19 unique buyers
- Product #23 — 18 unique buyers

---

### Average Order Value: Online vs Offline
Compared average order value between channels using CTE + LEFT JOIN with product prices.

| Channel | Average Order Value |
|---|---|
| Online | $50,061.04 |
| Offline | $92,272.94 |

**Finding:** Offline average order value is nearly **2x higher** than online. This suggests in-store customers either buy premium products or larger quantities per visit.

---

### Customers Who Bought Above Offline Average Price
Identified online customers who purchased at least one product priced higher than the weighted average price of offline items.

**Finding:** 43 out of 50 online customers made at least one purchase priced above the offline weighted average — indicating strong premium demand in the online channel and high crossover potential between channels.

---

### Monthly Distribution of High-Value Orders
Identified months with the most customers placing orders above the overall average order value (across both channels).

| Month | Customers with High-Value Orders |
|---|---|
| January | 24 |
| February | 27 |
| March | 22 |
| April | 2 |

**Finding:** Q1 (January–March) drives the majority of high-value purchases. The sharp drop in April may indicate seasonality or a data cutoff — worth investigating further.

---

## SQL Techniques Used

- `JOIN` (INNER, LEFT) across multiple tables
- `UNION ALL` for combining online and offline data sources
- `INTERSECT` for finding overlap between channels
- `CTEs` (Common Table Expressions) for query organisation
- Subqueries in `WHERE` and `FROM` clauses
- Conditional aggregation with `CASE WHEN`
- `ROUND`, `SUM`, `COUNT(DISTINCT)` for metric calculation
- `EXTRACT` for date-based grouping

---

## Tools

- **PostgreSQL** — query execution
- **DBeaver** — SQL client

---

## Files

| File | Description |
|---|---|
| `omnichannel_analysis.sql` | All 10 queries with comments |

