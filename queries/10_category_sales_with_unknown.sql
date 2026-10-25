-- 10 カテゴリ不明の明細も残したカテゴリ別売上
-- 問い: 03 の集計で消えていた売上はどれくらいあるか
-- 使った技: LEFT JOIN / COALESCE
-- 注意: INNER JOIN だと、カテゴリが登録されていない商品の売上が黙って消える

WITH category_sales AS (
  SELECT COALESCE(t.product_category_name_english, 'unknown') AS category,
         SUM(oi.price) AS sales
  FROM order_items AS oi
  INNER JOIN products AS p ON p.product_id = oi.product_id
  LEFT JOIN category_translation AS t ON t.product_category_name = p.product_category_name
  GROUP BY COALESCE(t.product_category_name_english, 'unknown')
)
-- カテゴリ別の合計が、全体の売上と一致するかを確かめる
SELECT (SELECT SUM(sales) FROM category_sales) AS total_by_category,
       (SELECT SUM(price) FROM order_items)     AS total_sales,
       (SELECT sales FROM category_sales WHERE category = 'unknown') AS unknown_sales;
