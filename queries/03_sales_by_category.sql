-- 03 商品カテゴリ別の売上 上位10カテゴリ
-- 問い: 何が売れているか
-- 使った技: 3つの表の JOIN(order_items → products → category_translation)

SELECT t.product_category_name_english AS category,
       SUM(oi.price) AS sales
FROM order_items AS oi
INNER JOIN products AS p ON p.product_id = oi.product_id
INNER JOIN category_translation AS t ON t.product_category_name = p.product_category_name
GROUP BY t.product_category_name_english
ORDER BY sales DESC
LIMIT 10;
