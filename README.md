# Sunrise Supermarket — SQL Assignment 1

**Name:** Patrick Ndizeye
**Student ID:** 20251SEN120
**DBMS:** PostgreSQL 16 (Oracle wasn't installed on my machine, so I adapted the given `NUMBER`/`VARCHAR2` schema to Postgres types and ran everything for real instead of submitting untested SQL)

## What this is

The `customers` / `products` / `orders` / `order_items` schema from the assignment, filled with sample data, plus the required JOIN, CTE, and window-function queries answering questions about customers, what they buy, and how sales move over time.

## How to run it

```bash
createdb sunrise_supermarket
psql -d sunrise_supermarket -f sql/schema.sql
psql -d sunrise_supermarket -f sql/data.sql
psql -d sunrise_supermarket -f sql/queries.sql
```

- `sql/schema.sql` — the four tables
- `sql/data.sql` — 6 customers, 8 products (4 categories), 15 orders, 25 order items, spread Jan–Mar 2026
- `sql/queries.sql` — all the queries below, runnable as one file or individually

## The scenario

Sunrise Supermarket wants to know three things from this data: who its customers are, what they're buying, and whether sales are growing. Customers place orders, each order has one or more line items (a product + a quantity), and that's basically the whole model.

I added a sixth customer, **Fofo Ndengeyimana**, who has never placed an order — the assignment only requires 5 customers, but with everyone having orders the LEFT JOIN query would look no different from an inner join, so this way it actually proves something.

---

## JOIN queries

### 1. Every order with customer name, city, order date

```sql
SELECT o.order_id, c.customer_name, c.city, o.order_date
FROM orders o
INNER JOIN customers c ON c.customer_id = o.customer_id
ORDER BY o.order_date;
```

Straightforward inner join — every order has a customer (it's a FK), so nothing gets lost here.

```
 order_id |  customer_name  |  city   | order_date
----------+-----------------+---------+------------
        1 | Patrick Ndizeye | Kigali  | 2026-01-05
        2 | Jean Morris     | Musanze | 2026-01-06
        3 | Iyaraa Umwe     | Huye    | 2026-01-08
        4 | Patrick Ndizeye | Kigali  | 2026-01-12
        5 | David Niyo      | Kigali  | 2026-01-15
        6 | Jean Morris     | Musanze | 2026-01-18
        7 | Eric Hana       | Rubavu  | 2026-01-20
        8 | Iyaraa Umwe     | Huye    | 2026-01-25
        9 | Patrick Ndizeye | Kigali  | 2026-02-02
       10 | David Niyo      | Kigali  | 2026-02-05
       11 | Jean Morris     | Musanze | 2026-02-10
       12 | Iyaraa Umwe     | Huye    | 2026-02-14
       13 | Eric Hana       | Rubavu  | 2026-02-18
       14 | Patrick Ndizeye | Kigali  | 2026-02-25
       15 | David Niyo      | Kigali  | 2026-03-01
```

This is basically the order log a support agent would want — customer name and city right there instead of chasing an ID. Kigali customers (me and David) show up the most in this batch.

### 2. Every order item with product, category, price, quantity

```sql
SELECT oi.order_item_id, oi.order_id, p.product_name, p.category, p.price, oi.quantity,
       (p.price * oi.quantity) AS line_total
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
ORDER BY oi.order_id, oi.order_item_id;
```

Joins the line items to the product catalog and throws in a `line_total` since it's a one-line calculation.

```
 order_item_id | order_id |    product_name     | category  | price | quantity | line_total
---------------+----------+---------------------+-----------+-------+----------+------------
             1 |        1 | Bottled Water 500ml | Beverages |  0.80 |        2 |       1.60
             2 |        1 | White Bread         | Bakery    |  1.20 |        1 |       1.20
             3 |        2 | Orange Juice 1L     | Beverages |  2.50 |        3 |       7.50
             4 |        3 | Milk 1L             | Dairy     |  1.50 |        2 |       3.00
             5 |        3 | Cheddar Cheese 200g | Dairy     |  3.20 |        1 |       3.20
             6 |        4 | Bottled Water 500ml | Beverages |  0.80 |        4 |       3.20
             7 |        4 | Bananas 1kg         | Produce   |  1.10 |        2 |       2.20
             8 |        5 | Croissant           | Bakery    |  1.00 |        3 |       3.00
             9 |        5 | Tomatoes 1kg        | Produce   |  1.40 |        1 |       1.40
            10 |        6 | Orange Juice 1L     | Beverages |  2.50 |        2 |       5.00
            11 |        6 | White Bread         | Bakery    |  1.20 |        2 |       2.40
            12 |        7 | Milk 1L             | Dairy     |  1.50 |        1 |       1.50
            13 |        8 | Bananas 1kg         | Produce   |  1.10 |        3 |       3.30
            14 |        8 | Tomatoes 1kg        | Produce   |  1.40 |        2 |       2.80
            15 |        9 | Bottled Water 500ml | Beverages |  0.80 |        1 |       0.80
            16 |        9 | Orange Juice 1L     | Beverages |  2.50 |        1 |       2.50
            17 |       10 | White Bread         | Bakery    |  1.20 |        3 |       3.60
            18 |       11 | Cheddar Cheese 200g | Dairy     |  3.20 |        2 |       6.40
            19 |       11 | Bananas 1kg         | Produce   |  1.10 |        1 |       1.10
            20 |       12 | Tomatoes 1kg        | Produce   |  1.40 |        3 |       4.20
            21 |       13 | Bottled Water 500ml | Beverages |  0.80 |        2 |       1.60
            22 |       13 | Milk 1L             | Dairy     |  1.50 |        1 |       1.50
            23 |       14 | Orange Juice 1L     | Beverages |  2.50 |        1 |       2.50
            24 |       15 | Cheddar Cheese 200g | Dairy     |  3.20 |        1 |       3.20
            25 |       15 | Bananas 1kg         | Produce   |  1.10 |        2 |       2.20
(25 rows)
```

This is the level of detail you'd actually pull for a "what's selling" report. Beverages and Dairy items carry the highest line totals even in small quantities, since they're priced higher than the Bakery/Produce items.

### 3. All customers and their orders, including customers with none

```sql
SELECT c.customer_id, c.customer_name, o.order_id, o.order_date
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
ORDER BY c.customer_id, o.order_date;
```

Same idea but LEFT JOIN, so customers with zero orders still show up (with nulls on the order side) instead of vanishing.

```
 customer_id |   customer_name   | order_id | order_date
-------------+--------------------+----------+------------
           1 | Patrick Ndizeye   |        1 | 2026-01-05
           1 | Patrick Ndizeye   |        4 | 2026-01-12
           1 | Patrick Ndizeye   |        9 | 2026-02-02
           1 | Patrick Ndizeye   |       14 | 2026-02-25
           2 | Jean Morris       |        2 | 2026-01-06
           2 | Jean Morris       |        6 | 2026-01-18
           2 | Jean Morris       |       11 | 2026-02-10
           3 | Iyaraa Umwe       |        3 | 2026-01-08
           3 | Iyaraa Umwe       |        8 | 2026-01-25
           3 | Iyaraa Umwe       |       12 | 2026-02-14
           4 | David Niyo        |        5 | 2026-01-15
           4 | David Niyo        |       10 | 2026-02-05
           4 | David Niyo        |       15 | 2026-03-01
           5 | Eric Hana         |        7 | 2026-01-20
           5 | Eric Hana         |       13 | 2026-02-18
           6 | FOFO Ndengeyimana |          |
(16 rows)
```

Fofo Ndengeyimana shows up with nothing on the order side — that's the whole point of using LEFT JOIN here. An inner join would have just dropped him, and marketing wouldn't know he exists to re-engage him.

---

## CTE query

### Customers spending above the average

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

The CTE does the hard part first — one row per customer with their total spend (quantity × price, summed across every item they've bought). Then the outer query just filters against the average of that. Doing it this way means the average is computed over customer totals, not raw line items, which would skew it toward whoever happens to have more items on their orders.

Totals for all 5 ordering customers:

```
 customer_id |  customer_name  | total_spent
-------------+-----------------+-------------
           2 | Jean Morris     |       22.40
           3 | Iyaraa Umwe     |       16.50
           1 | Patrick Ndizeye |       14.00
           4 | David Niyo      |       13.40
           5 | Eric Hana       |        4.60
```

Average is 14.18, so two customers clear it:

```
 customer_id | customer_name | total_spent
-------------+---------------+-------------
           2 | Jean Morris   |       22.40
           3 | Iyaraa Umwe   |       16.50
```

Jean and Iyaraa are the two customers worth prioritizing for a loyalty program. Eric's total (4.60) is way under — he's the one I'd flag as low-engagement.

---

## Window-function queries

### 1. Rank customers by total spend

```sql
WITH customer_totals AS ( ... )
SELECT customer_id, customer_name, total_spent,
       RANK() OVER (ORDER BY total_spent DESC) AS spend_rank
FROM customer_totals
ORDER BY spend_rank;
```

Same CTE as above, `RANK()` just turns it into a leaderboard.

```
 customer_id |  customer_name  | total_spent | spend_rank
-------------+-----------------+-------------+------------
           2 | Jean Morris     |       22.40 |          1
           3 | Iyaraa Umwe     |       16.50 |          2
           1 | Patrick Ndizeye |       14.00 |          3
           4 | David Niyo      |       13.40 |          4
           5 | Eric Hana       |        4.60 |          5
```

Gives you the top-spender list without doing the sorting by hand — handy for a VIP list.

### 2. Number each customer's orders in the order placed

```sql
SELECT customer_id, order_id, order_date,
       ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) AS order_sequence
FROM orders
ORDER BY customer_id, order_sequence;
```

`PARTITION BY customer_id` resets the count for each customer, so everyone gets their own 1st, 2nd, 3rd order instead of one continuous count across the whole table.

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

Useful if you want to compare, say, a customer's first order to their later ones — does the basket grow, shrink, stay the same.

### 3. Running total of revenue over time

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

Compute each order's total first, then let a running `SUM() OVER (ORDER BY order_date)` accumulate it.

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

Total revenue across the sample data comes out to 70.90 by March 1 — this is basically the shape of a "revenue over time" chart without having to build one.

### 4. Days between a customer's orders

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

`LAG()` grabs each customer's previous order date so I can subtract it from the current one. The `COUNT(*) OVER (...)` bit is there to drop anyone with only one order — doesn't matter for this dataset since all 5 ordering customers have 2+, but it's needed for the query to hold up in general. First order for each customer naturally has no "previous" to compare to, hence the null.

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

Gaps sit mostly between 1–4 weeks. Eric's 29-day gap is the widest one in the data — paired with him also having the lowest total spend from the CTE query, he's the customer I'd worry about losing.

---

## Challenges

- **No Oracle locally.** I only had PostgreSQL set up, so I converted the given Oracle DDL (`NUMBER`, `VARCHAR2`) to Postgres equivalents (`INTEGER`, `NUMERIC`, `VARCHAR`). Table structure and query logic are identical — just the type keywords changed — and I ran everything against a real database rather than typing out SQL I couldn't test.
- **Making the LEFT JOIN mean something.** With the minimum 5 customers, everyone would have had orders and the LEFT JOIN result would look exactly like an INNER JOIN. Added a 6th customer with zero orders specifically so the null-preserving behavior actually shows up.
- **Getting the average right in the CTE query.** Filtering against `AVG(total_spent)` from the same CTE (instead of averaging raw order-item rows) keeps it correct — averaging unaggregated rows would have weighted customers with more line items too heavily.
