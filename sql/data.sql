-- Sunrise Supermarket - Sample Data
-- 6 customers (one with zero orders, to demonstrate LEFT JOIN),
-- 8 products across 4 categories, 15 orders, 25 order items.

-- Customers
INSERT INTO customers (customer_id, customer_name, email, city) VALUES
  (1, 'Alice Uwase',        'alice.uwase@example.com',   'Kigali'),
  (2, 'Brian Mugisha',      'brian.mugisha@example.com', 'Musanze'),
  (3, 'Claudine Iradukunda','claudine.irad@example.com', 'Huye'),
  (4, 'David Niyonzima',    'david.niyo@example.com',    'Kigali'),
  (5, 'Esther Mukamana',    'esther.muka@example.com',   'Rubavu'),
  (6, 'Faustin Bizimana',   'faustin.bizi@example.com',  'Kigali'); -- no orders (tests LEFT JOIN)

-- Products (4 categories)
INSERT INTO products (product_id, product_name, category, price) VALUES
  (1, 'Bottled Water 500ml',   'Beverages', 0.80),
  (2, 'Orange Juice 1L',       'Beverages', 2.50),
  (3, 'White Bread',           'Bakery',    1.20),
  (4, 'Croissant',              'Bakery',    1.00),
  (5, 'Milk 1L',                'Dairy',     1.50),
  (6, 'Cheddar Cheese 200g',   'Dairy',     3.20),
  (7, 'Bananas 1kg',           'Produce',   1.10),
  (8, 'Tomatoes 1kg',          'Produce',   1.40);

-- Orders (15), spread across Jan-Mar 2026
INSERT INTO orders (order_id, customer_id, order_date) VALUES
  (1,  1, DATE '2026-01-05'),
  (2,  2, DATE '2026-01-06'),
  (3,  3, DATE '2026-01-08'),
  (4,  1, DATE '2026-01-12'),
  (5,  4, DATE '2026-01-15'),
  (6,  2, DATE '2026-01-18'),
  (7,  5, DATE '2026-01-20'),
  (8,  3, DATE '2026-01-25'),
  (9,  1, DATE '2026-02-02'),
  (10, 4, DATE '2026-02-05'),
  (11, 2, DATE '2026-02-10'),
  (12, 3, DATE '2026-02-14'),
  (13, 5, DATE '2026-02-18'),
  (14, 1, DATE '2026-02-25'),
  (15, 4, DATE '2026-03-01');

-- Order items (25)
INSERT INTO order_items (order_item_id, order_id, product_id, quantity) VALUES
  (1,  1, 1, 2),
  (2,  1, 3, 1),
  (3,  2, 2, 3),
  (4,  3, 5, 2),
  (5,  3, 6, 1),
  (6,  4, 1, 4),
  (7,  4, 7, 2),
  (8,  5, 4, 3),
  (9,  5, 8, 1),
  (10, 6, 2, 2),
  (11, 6, 3, 2),
  (12, 7, 5, 1),
  (13, 8, 7, 3),
  (14, 8, 8, 2),
  (15, 9, 1, 1),
  (16, 9, 2, 1),
  (17, 10, 3, 3),
  (18, 11, 6, 2),
  (19, 11, 7, 1),
  (20, 12, 8, 3),
  (21, 13, 1, 2),
  (22, 13, 5, 1),
  (23, 14, 2, 1),
  (24, 15, 6, 1),
  (25, 15, 7, 2);
