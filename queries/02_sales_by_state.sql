-- 02 州別の売上 上位5州
-- 問い: どの地域の売上が大きいか
-- 使った技: 3つの表の JOIN(customers → orders → order_items)

SELECT c.customer_state AS state,
       SUM(oi.price) AS sales
FROM customers AS c
INNER JOIN orders AS o       ON o.customer_id = c.customer_id
INNER JOIN order_items AS oi ON oi.order_id = o.order_id
GROUP BY c.customer_state
ORDER BY sales DESC
LIMIT 5;
