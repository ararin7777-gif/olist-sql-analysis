-- 05 注文金額帯ごとの注文数
-- 問い: 1回の注文でいくら使われているか(平均だけでは見えない分布)
-- 使った技: CTE(WITH)/ CASE

WITH order_totals AS (
  SELECT order_id, SUM(price) AS order_total
  FROM order_items
  GROUP BY order_id
)
SELECT CASE
         WHEN order_total < 50  THEN '1: under 50'
         WHEN order_total < 100 THEN '2: 50-99'
         WHEN order_total < 200 THEN '3: 100-199'
         ELSE '4: 200+'
       END AS value_band,
       COUNT(*) AS orders,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS share_pct
FROM order_totals
GROUP BY value_band
ORDER BY value_band;
