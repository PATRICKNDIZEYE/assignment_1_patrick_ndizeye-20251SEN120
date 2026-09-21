# Sunrise Supermarket — SQL Assignment 1

**Name:** Patrick Ndizeye
**Student ID:** 20251SEN120

## DBMS used

**PostgreSQL 16** (via `psql`), run against a local server.

> Note: the assignment's provided `CREATE TABLE` statements use Oracle types (`NUMBER`, `VARCHAR2`). I don't have Oracle installed locally, so rather than submit SQL I couldn't actually run, I ported the schema to standard/PostgreSQL types (`INTEGER`, `NUMERIC`, `VARCHAR`) and executed everything for real. The table names, columns, relationships, and query logic are unchanged — only the type keywords differ. See **Challenges & Resolutions** below.

## Summary

Implements the Sunrise Supermarket schema (`customers`, `products`, `orders`, `order_items`), populates it with sample data (6 customers, 8 products across 4 categories, 15 orders, 25 order items across Jan–Mar 2026), and answers the required JOIN, CTE, and window-function questions about customers, purchases, and sales trends.

## How to run

Requires PostgreSQL (`createdb`, `psql`) available on the path.

```bash
createdb sunrise_supermarket
psql -d sunrise_supermarket -f sql/schema.sql
psql -d sunrise_supermarket -f sql/data.sql
psql -d sunrise_supermarket -f sql/queries.sql
```

Or run each query individually, e.g.:

```bash
psql -d sunrise_supermarket -c "SELECT ... "
```

Files:
- `sql/schema.sql` — table definitions
- `sql/data.sql` — sample data (customers, products, orders, order_items)
- `sql/queries.sql` — all JOIN / CTE / window-function queries

## Business scenario

Sunrise Supermarket sells products to customers who place orders containing one or more line items. Management wants three things out of the data:

1. **Who their customers are** — where they live, how many orders they place, how much they spend relative to each other.
2. **What they buy** — which products/categories appear on orders, at what price and quantity.
3. **How sales trend over time** — order cadence per customer and cumulative revenue growth.

The four tables model this directly: `customers` (who), `products` (what's for sale), `orders` (a purchase event tied to a customer and a date), `order_items` (the line items — product + quantity — that make up an order).

---

## JOIN queries

### 1. Every order with customer name, city, and order date (INNER JOIN)

```sql
SELECT o.order_id, c.customer_name, c.city, o.order_date
FROM orders o
INNER JOIN customers c ON c.customer_id = o.customer_id
ORDER BY o.order_date;
```

**Explanation:** joins `orders` to `customers` on `customer_id` so each order row carries the placing customer's name and city. INNER JOIN is correct here because every order must have a valid customer (FK constraint) — there's nothing to preserve on either side.

**Result (15 rows):**

```
 order_id |    customer_name    |  city   | order_date
----------+---------------------+---------+------------
        1 | Alice Uwase         | Kigali  | 2026-01-05
        2 | Brian Mugisha       | Musanze | 2026-01-06
        3 | Claudine Iradukunda | Huye    | 2026-01-08
        4 | Alice Uwase         | Kigali  | 2026-01-12
        5 | David Niyonzima     | Kigali  | 2026-01-15
        6 | Brian Mugisha       | Musanze | 2026-01-18
        7 | Esther Mukamana     | Rubavu  | 2026-01-20
        8 | Claudine Iradukunda | Huye    | 2026-01-25
        9 | Alice Uwase         | Kigali  | 2026-02-02
       10 | David Niyonzima     | Kigali  | 2026-02-05
       11 | Brian Mugisha       | Musanze | 2026-02-10
       12 | Claudine Iradukunda | Huye    | 2026-02-14
       13 | Esther Mukamana     | Rubavu  | 2026-02-18
       14 | Alice Uwase         | Kigali  | 2026-02-25
       15 | David Niyonzima     | Kigali  | 2026-03-01
```

**Business interpretation:** gives a clean, readable order log for customer service and reporting — no need to look up customer IDs manually. Kigali customers (Alice, David) place orders most frequently in this dataset.

---

### 2. Every order item with product name, category, price, and quantity (JOIN)

```sql
SELECT oi.order_item_id, oi.order_id, p.product_name, p.category, p.price, oi.quantity,
       (p.price * oi.quantity) AS line_total
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
ORDER BY oi.order_id, oi.order_item_id;
```

**Explanation:** joins `order_items` to `products` on `product_id` to turn a bare product-ID/quantity row into a readable line item, and computes a `line_total` (price × quantity) inline.

**Result (25 rows, abridged — see `sql/queries.sql` output for full run):**

```
 order_item_id | order_id |    product_name     | category  | price | quantity | line_total
---------------+----------+---------------------+-----------+-------+----------+------------
             1 |        1 | Bottled Water 500ml | Beverages |  0.80 |        2 |       1.60
             2 |        1 | White Bread         | Bakery    |  1.20 |        1 |       1.20
             3 |        2 | Orange Juice 1L     | Beverages |  2.50 |        3 |       7.50
             4 |        3 | Milk 1L             | Dairy     |  1.50 |        2 |       3.00
             5 |        3 | Cheddar Cheese 200g | Dairy     |  3.20 |        1 |       3.20
           ... |      ... | ...                 | ...       |   ... |      ... |        ...
            24 |       15 | Cheddar Cheese 200g | Dairy     |  3.20 |        1 |       3.20
            25 |       15 | Bananas 1kg         | Produce   |  1.10 |        2 |       2.20
(25 rows)
```

**Business interpretation:** this is the transaction-level view management needs to see which specific products drive revenue on each order — e.g. Beverages and Dairy items tend to be the highest-value line items due to price, even when quantities are modest.

---

### 3. All customers and their orders, including customers with none (LEFT JOIN)

```sql
SELECT c.customer_id, c.customer_name, o.order_id, o.order_date
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
ORDER BY c.customer_id, o.order_date;
```

**Explanation:** LEFT JOIN keeps every customer row even when there's no matching order, so customers who have never ordered show up with NULL order fields instead of disappearing.

**Result (16 rows):**

```
 customer_id |    customer_name    | order_id | order_date
-------------+---------------------+----------+------------
           1 | Alice Uwase         |        1 | 2026-01-05
           1 | Alice Uwase         |        4 | 2026-01-12
           1 | Alice Uwase         |        9 | 2026-02-02
           1 | Alice Uwase         |       14 | 2026-02-25
           2 | Brian Mugisha       |        2 | 2026-01-06
           2 | Brian Mugisha       |        6 | 2026-01-18
           2 | Brian Mugisha       |       11 | 2026-02-10
           3 | Claudine Iradukunda |        3 | 2026-01-08
           3 | Claudine Iradukunda |        8 | 2026-01-25
           3 | Claudine Iradukunda |       12 | 2026-02-14
           4 | David Niyonzima     |        5 | 2026-01-15
           4 | David Niyonzima     |       10 | 2026-02-05
           4 | David Niyonzima     |       15 | 2026-03-01
           5 | Esther Mukamana     |        7 | 2026-01-20
           5 | Esther Mukamana     |       13 | 2026-02-18
           6 | Faustin Bizimana    |          |
```

**Business interpretation:** surfaces customers who signed up but never bought anything (here, Faustin Bizimana) — a list marketing can target for re-engagement. An INNER JOIN would have silently hidden this customer.

---

## CTE query

### Customers whose total spend is above the average

```sql
WITH customer_totals AS (
  SELECT c.customer_id, c.customer_name, SUM(oi.quantity * p.price) AS total_spent
  FROM customers c
  JOIN orders o       ON o.customer_id = c.customer_id
  JOIN order_items oi ON oi.order_id = o.order_id
  JOIN products p     ON p.product_id = oi.product_id
  GROUP BY c.customer_id, c.customer_name
)
SELECT customer_id, customer_name, total_spent
FROM customer_totals
WHERE total_spent > (SELECT AVG(total_spent) FROM customer_totals)
ORDER BY total_spent DESC;
```

**Explanation:** the CTE `customer_totals` first computes each customer's lifetime spend (quantity × price, summed across all their order items). The outer query then filters to customers above the average of those totals. Using a CTE avoids repeating the 3-way join and lets the average be computed cleanly against pre-aggregated rows rather than raw line items.

**Result — all customer totals for reference:**

```
 customer_id |    customer_name    | total_spent
-------------+---------------------+-------------
           2 | Brian Mugisha       |       22.40
           3 | Claudine Iradukunda |       16.50
           1 | Alice Uwase         |       14.00
           4 | David Niyonzima     |       13.40
           5 | Esther Mukamana     |        4.60
```

Average spend = (22.40 + 16.50 + 14.00 + 13.40 + 4.60) / 5 = **14.18**

**Above-average customers:**

```
 customer_id |    customer_name    | total_spent
-------------+---------------------+-------------
           2 | Brian Mugisha       |       22.40
           3 | Claudine Iradukunda |       16.50
```

**Business interpretation:** Brian and Claudine are the supermarket's highest-value customers — good candidates for loyalty perks. Esther's spend (4.60) is far below average, which flags her as a low-engagement customer worth a targeted promotion.

---

## Window-function queries

### 1. Rank customers by total amount spent, highest first

```sql
WITH customer_totals AS ( ... same as above ... )
SELECT customer_id, customer_name, total_spent,
       RANK() OVER (ORDER BY total_spent DESC) AS spend_rank
FROM customer_totals
ORDER BY spend_rank;
```

**Explanation:** `RANK()` orders customers by `total_spent` descending and assigns a rank, with ties sharing a rank (none occur here).

**Result:**

```
 customer_id |    customer_name    | total_spent | spend_rank
-------------+---------------------+-------------+------------
           2 | Brian Mugisha       |       22.40 |          1
           3 | Claudine Iradukunda |       16.50 |          2
           1 | Alice Uwase         |       14.00 |          3
           4 | David Niyonzima     |       13.40 |          4
           5 | Esther Mukamana     |        4.60 |          5
```

**Business interpretation:** gives management an instant top-customer leaderboard for a VIP/loyalty program without manually sorting spend totals.

---

### 2. Number each customer's orders in the order placed

```sql
SELECT customer_id, order_id, order_date,
       ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) AS order_sequence
FROM orders
ORDER BY customer_id, order_sequence;
```

**Explanation:** `PARTITION BY customer_id` restarts the numbering for each customer; `ORDER BY order_date` numbers their orders chronologically (1st order, 2nd order, etc.).

**Result:**

```
 customer_id | order_id | order_date | order_sequence
-------------+----------+------------+----------------
           1 |        1 | 2026-01-05 |              1
           1 |        4 | 2026-01-12 |              2
           1 |        9 | 2026-02-02 |              3
           1 |       14 | 2026-02-25 |              4
           2 |        2 | 2026-01-06 |              1
           2 |        6 | 2026-01-18 |              2
           2 |       11 | 2026-02-10 |              3
           3 |        3 | 2026-01-08 |              1
           3 |        8 | 2026-01-25 |              2
           3 |       12 | 2026-02-14 |              3
           4 |        5 | 2026-01-15 |              1
           4 |       10 | 2026-02-05 |              2
           4 |       15 | 2026-03-01 |              3
           5 |        7 | 2026-01-20 |              1
           5 |       13 | 2026-02-18 |              2
```

**Business interpretation:** lets you spot each customer's 1st, 2nd, 3rd... order — useful for measuring repeat-purchase behavior, e.g. checking whether a customer's basket size grows between their 1st and later orders.

---

### 3. Running total of revenue over time, ordered by order date

```sql
WITH order_revenue AS (
  SELECT o.order_id, o.order_date, SUM(oi.quantity * p.price) AS order_total
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  JOIN products p     ON p.product_id = oi.product_id
  GROUP BY o.order_id, o.order_date
)
SELECT order_id, order_date, order_total,
       SUM(order_total) OVER (ORDER BY order_date, order_id) AS running_revenue
FROM order_revenue
ORDER BY order_date, order_id;
```

**Explanation:** the CTE computes each order's total revenue; the window function then sums `order_total` cumulatively over all preceding rows (ordered by date) to produce a running total.

**Result:**

```
 order_id | order_date | order_total | running_revenue
----------+------------+-------------+-----------------
        1 | 2026-01-05 |        2.80 |            2.80
        2 | 2026-01-06 |        7.50 |           10.30
        3 | 2026-01-08 |        6.20 |           16.50
        4 | 2026-01-12 |        5.40 |           21.90
        5 | 2026-01-15 |        4.40 |           26.30
        6 | 2026-01-18 |        7.40 |           33.70
        7 | 2026-01-20 |        1.50 |           35.20
        8 | 2026-01-25 |        6.10 |           41.30
        9 | 2026-02-02 |        3.30 |           44.60
       10 | 2026-02-05 |        3.60 |           48.20
       11 | 2026-02-10 |        7.50 |           55.70
       12 | 2026-02-14 |        4.20 |           59.90
       13 | 2026-02-18 |        3.10 |           63.00
       14 | 2026-02-25 |        2.50 |           65.50
       15 | 2026-03-01 |        5.40 |           70.90
```

**Business interpretation:** shows cumulative revenue growth (total revenue reaches **70.90** by March 1), which is exactly the shape of chart management wants for a sales-trend dashboard — no need to pre-aggregate in a reporting tool.

---

### 4. Days between current and previous order, for customers with more than one order

```sql
WITH customer_order_gaps AS (
  SELECT customer_id, order_id, order_date,
         LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS previous_order_date,
         COUNT(*) OVER (PARTITION BY customer_id) AS total_orders
  FROM orders
)
SELECT customer_id, order_id, order_date, previous_order_date,
       (order_date - previous_order_date) AS days_since_previous_order
FROM customer_order_gaps
WHERE total_orders > 1
ORDER BY customer_id, order_date;
```

**Explanation:** `LAG(order_date)` (partitioned per customer, ordered by date) pulls in each customer's previous order date alongside the current one, and the difference is the gap in days. `COUNT(*) OVER (PARTITION BY customer_id)` filters out any customer with only a single order — every customer in this dataset happens to have more than one, except none were excluded here since all 5 ordering customers have 2+ orders. A customer's very first order naturally has no "previous" order, so it shows `NULL`.

**Result:**

```
 customer_id | order_id | order_date | previous_order_date | days_since_previous_order
-------------+----------+------------+----------------------+---------------------------
           1 |        1 | 2026-01-05 |                      |
           1 |        4 | 2026-01-12 | 2026-01-05           |                         7
           1 |        9 | 2026-02-02 | 2026-01-12           |                        21
           1 |       14 | 2026-02-25 | 2026-02-02           |                        23
           2 |        2 | 2026-01-06 |                      |
           2 |        6 | 2026-01-18 | 2026-01-06           |                        12
           2 |       11 | 2026-02-10 | 2026-01-18           |                        23
           3 |        3 | 2026-01-08 |                      |
           3 |        8 | 2026-01-25 | 2026-01-08           |                        17
           3 |       12 | 2026-02-14 | 2026-01-25           |                        20
           4 |        5 | 2026-01-15 |                      |
           4 |       10 | 2026-02-05 | 2026-01-15           |                        21
           4 |       15 | 2026-03-01 | 2026-02-05           |                        24
           5 |        7 | 2026-01-20 |                      |
           5 |       13 | 2026-02-18 | 2026-01-20           |                        29
```

**Business interpretation:** customers reorder roughly every 2–4 weeks (7–29 days apart). Esther Mukamana's 29-day gap is the widest — combined with her low total spend from the CTE query, she's the clearest churn-risk customer in this dataset.

---

## Challenges & resolutions

- **No local Oracle installation.** The assignment's DDL is written in Oracle syntax (`NUMBER`, `VARCHAR2`). Rather than submit SQL that was never actually executed, I adapted the same schema/relationships to PostgreSQL (already installed locally) and ran every query for real against live data, so all results above are genuine query output, not hand-computed.
- **Demonstrating the LEFT JOIN meaningfully.** With only 5 required customers all having orders, the LEFT JOIN query would look identical to an INNER JOIN. I added a 6th customer (Faustin Bizimana) with zero orders so the NULL-preserving behavior of LEFT JOIN is actually visible in the results.
- **Avoiding ties/ambiguity in the CTE's average-spend filter.** Computing the average inside a scalar subquery against the same CTE (rather than a second aggregation pass) kept the query readable and guaranteed the average is calculated over customer-level totals, not raw order-item rows (which would have skewed it toward customers with many small line items).
