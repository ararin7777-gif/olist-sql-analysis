-- 08 SP州・RJ州で注文の多い都市 上位3都市
-- 問い: 注文は州の中のどこに集中しているか
-- 使った技: 複数の CTE / RANK() OVER (PARTITION BY)

WITH city_orders AS (
  SELECT c.customer_state AS state,
         c.customer_city AS city,
         COUNT(*) AS orders
  FROM customers AS c
  INNER JOIN orders AS o ON o.customer_id = c.customer_id
  WHERE c.customer_state IN ('SP', 'RJ')
  GROUP BY c.customer_state, c.customer_city
),
ranked AS (
  SELECT state, city, orders,
         RANK() OVER (PARTITION BY state ORDER BY orders DESC) AS rnk
  FROM city_orders
)
SELECT state, city, orders, rnk
FROM ranked
WHERE rnk <= 3
ORDER BY state, rnk;
