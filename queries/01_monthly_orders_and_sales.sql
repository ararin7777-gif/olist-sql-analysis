-- 01 月別の注文数と売上
-- 問い: 売上はどのように推移しているか
-- 使った技: INNER JOIN / DATE_TRUNC / COUNT(DISTINCT) / GROUP BY

SELECT DATE_TRUNC('month', o.order_purchase_timestamp)::date AS month,
       COUNT(DISTINCT o.order_id) AS orders,   -- 1注文に明細が複数あるので DISTINCT で数える
       SUM(oi.price) AS sales
FROM orders AS o
INNER JOIN order_items AS oi ON oi.order_id = o.order_id
GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
ORDER BY month;
