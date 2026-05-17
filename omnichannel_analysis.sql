/*              Omnichannel Sales Analysis
          Tool: PostgreSQL / DBeaver
   Description: Analysis of online and offline retail sales data
                combining 6 tables across two channels */

-- 1. Top customers by total online spend
-- Joins orders, items, and products to rank customers by revenue

SELECT o.user_id, 
	   SUM(oi.quantity * pr.product_price) AS total_sum
FROM orders_sql_project o
LEFT JOIN order_items_sql_project oi USING(order_id)
LEFT JOIN products_sql_project    pr USING(product_id)
WHERE o.user_id IS NOT NULL 
GROUP BY o.user_id
ORDER BY 2 DESC; 

-- 2. Customer order count by channel
-- Counts total, online, and offline orders per customer 
-- to identify omnichannel buyers vs single-channel customers

SELECT user_id,
       COUNT(DISTINCT order_id)                                        AS total_orders,
       COUNT(DISTINCT CASE WHEN channel = 'online'  THEN order_id END) AS online_orders,
       COUNT(DISTINCT CASE WHEN channel = 'offline' THEN order_id END) AS offline_orders
FROM (
    SELECT user_id, store_order_id AS order_id, 'offline' AS channel
    FROM store_orders
    WHERE user_id IS NOT NULL
    UNION ALL
    SELECT user_id, order_id, 'online' AS channel
    FROM orders_sql_project
    WHERE user_id IS NOT NULL
) combined
GROUP BY user_id
ORDER BY total_orders DESC;

-- 3. Products available in both channels
-- Uses INTERSECT to find cross-channel assortment with product details

SELECT DISTINCT oi.product_id,
                pr.product_name,
                pr.product_brand,
                pr.product_price
FROM order_items_sql_project oi
JOIN products_sql_project pr USING (product_id)
WHERE oi.product_id IN (
    SELECT product_id FROM order_items_sql_project
    INTERSECT
    SELECT product_id FROM store_order_items
)
ORDER BY pr.product_price DESC;

-- 4. True omnichannel bulk buyers
-- Customers who purchased 2+ units per item in BOTH channels

SELECT user_id
FROM orders_sql_project
WHERE user_id IS NOT NULL AND order_id IN (SELECT order_id FROM order_items_sql_project WHERE quantity > 2)
INTERSECT
SELECT user_id
FROM store_orders
WHERE user_id IS NOT NULL AND store_order_id IN (SELECT store_order_id FROM store_order_items WHERE quantity > 2)
ORDER BY 1;

-- 5. Average order value for paid online orders
-- Filters by payment status = 'Paid' across three joined tables

SELECT ROUND(SUM(quantity * product_price)
       /COUNT(DISTINCT order_id), 2) AS average_check
FROM order_items_sql_project
JOIN products_sql_project USING (product_id)
JOIN payments_sql_project USING (order_id)
WHERE payment_status = 'Оплачено';

-- 6. Channel volume comparison (items and orders)
-- Compares total items sold and unique orders online vs offline

WITH purchase_info_combined AS
(
	SELECT item_id, 
	       order_id, 
	       product_id, 
	       quantity, 
	       'online' AS purchase_type
	FROM order_items_sql_project osp
    UNION ALL
	SELECT store_item_id, 
	       store_order_id,
	       product_id,
	       quantity,
	       'offline' AS purchase_type
	FROM store_order_items
)
SELECT purchase_type, 
       SUM(quantity) AS total_items, 
       COUNT(DISTINCT order_id) AS unique_orders
FROM purchase_info_combined
GROUP BY purchase_type
ORDER BY 1 DESC; 

-- 7. Top 3 products by unique buyers across both channels
-- Combines online and offline data to find most popular products

WITH combined_order_items AS
(
	SELECT item_id,
	       order_id,
	       product_id, 
		   quantity
	FROM order_items_sql_project s
	WHERE order_id IN (SELECT order_id FROM orders_sql_project WHERE user_id IS NOT NULL)
	UNION ALL
	SELECT store_item_id,
	       store_order_id,
	       product_id, 
	       quantity
	FROM store_order_items s
	WHERE store_order_id IN (SELECT store_order_id 
	                         FROM store_orders 
	                         WHERE user_id IS NOT NULL)
),
combined_orders AS 
(
	SELECT order_id, order_date, user_id
	FROM orders_sql_project osp 
	WHERE user_id IS NOT NULL 
	UNION ALL 
	SELECT store_order_id, order_date, user_id
	FROM store_orders so
	WHERE user_id IS NOT NULL 
)
SELECT product_id, 
       COUNT(DISTINCT user_id)
FROM combined_order_items c
JOIN combined_orders USING (order_id)
GROUP BY c.product_id 
ORDER BY 2 DESC
LIMIT 3;

-- 8. Average order value by channel
-- Offline average is nearly 2x higher than online

WITH combined_orders AS (
	SELECT item_id, 
	       order_id, 
	       product_id, 
	       quantity, 
	       'online' AS order_type
	FROM order_items_sql_project
	UNION ALL 
	SELECT store_item_id,
           store_order_id,
           product_id,
           quantity, 
           'offline' AS order_type
	FROM store_order_items
)
SELECT order_type, 
       ROUND(SUM(quantity * product_price)
       /COUNT(DISTINCT order_id), 2) AS average_per_order
FROM combined_orders
LEFT JOIN products_sql_project USING (product_id)
GROUP BY order_type
ORDER BY 2;

-- 9. Online customers who bought above offline average price
-- Subquery calculates weighted average offline price for comparison

SELECT DISTINCT user_id
FROM orders_sql_project
LEFT JOIN order_items_sql_project USING (order_id)
LEFT JOIN products_sql_project USING (product_id)
WHERE product_price > (SELECT SUM(product_price * quantity)
                              /SUM(quantity)
                       FROM store_order_items
                       LEFT JOIN products_sql_project USING (product_id))
AND user_id IS NOT NULL 
ORDER BY 1 ASC; 

-- 10. Monthly distribution of high-value orders
-- Identifies which months drive above-average purchases across channels

WITH online_offline_orders AS 
(
	SELECT *
	FROM orders_sql_project
	UNION ALL 
	SELECT * 
    FROM store_orders
), 
online_offline_items AS 
(
	SELECT item_id, 
	       order_id, 
	       product_id, 
	       quantity
	FROM order_items_sql_project
	UNION ALL
	SELECT *
	FROM store_order_items
), 
full_info AS 
(
	SELECT order_id, 
		   order_date, 
		   user_id,
		   SUM(quantity * product_price) AS total_sum
	FROM online_offline_orders
	LEFT JOIN online_offline_items USING (order_id)
	LEFT JOIN products_sql_project USING (product_id)
	GROUP BY 1, 2, 3
)
SELECT EXTRACT(MONTH FROM order_date) AS order_month,
       COUNT(DISTINCT user_id) AS user_count
FROM full_info
WHERE total_sum > (SELECT SUM(total_sum)/COUNT(DISTINCT order_id)
                   FROM full_info)
AND user_id IS NOT NULL 
GROUP BY EXTRACT(MONTH FROM order_date)
ORDER BY 1;


