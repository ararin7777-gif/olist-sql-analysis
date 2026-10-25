-- 04 リピーターの人数とリピート率
-- 問い: 2回以上買ってくれた客はどれくらいいるか
-- 使った技: CTE(WITH)/ COUNT(*) FILTER
-- 注意: customer_id は注文ごとに振られる番号。同じ人を数えるには customer_unique_id を使う

WITH orders_per_person AS (
  SELECT customer_unique_id, COUNT(*) AS order_count
  FROM customers
  GROUP BY customer_unique_id
)
SELECT COUNT(*) AS customers,
       COUNT(*) FILTER (WHERE order_count >= 2) AS repeat_customers,
       ROUND(COUNT(*) FILTER (WHERE order_count >= 2) * 100.0 / COUNT(*), 1) AS repeat_rate_pct
FROM orders_per_person;
