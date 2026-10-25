-- 07 州ごとの売れ筋1位カテゴリ(売上の大きい8州)
-- 問い: 地域によって売れるものは違うか
-- 使った技: 5つの表の JOIN / 複数の CTE / RANK() OVER (PARTITION BY)

WITH state_category_sales AS (
  SELECT c.customer_state AS state,
         t.product_category_name_english AS category,
         SUM(oi.price) AS sales
  FROM customers AS c
  INNER JOIN orders AS o       ON o.customer_id = c.customer_id
  INNER JOIN order_items AS oi ON oi.order_id = o.order_id
  INNER JOIN products AS p     ON p.product_id = oi.product_id
  INNER JOIN category_translation AS t ON t.product_category_name = p.product_category_name
  GROUP BY c.customer_state, t.product_category_name_english
),
ranked AS (
  SELECT state, category, sales,
         RANK() OVER (PARTITION BY state ORDER BY sales DESC) AS rnk
  FROM state_category_sales
)
-- 順位は同じ SELECT の WHERE では使えないので、外側で絞る
SELECT state, category, sales
FROM ranked
WHERE rnk = 1
ORDER BY sales DESC
LIMIT 8;
