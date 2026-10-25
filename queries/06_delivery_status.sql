-- 06 配送状況(間に合った/遅れた/未配達)
-- 問い: お届け予定日をどれくらい守れているか
-- 使った技: CASE / IS NULL
-- 注意: NULL は比較が成り立たないので、未配達の判定を最初の WHEN に書く

SELECT CASE
         WHEN order_delivered_customer_date IS NULL THEN '3: not delivered'
         WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN '1: on time'
         ELSE '2: late'
       END AS delivery_status,
       COUNT(*) AS orders,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS share_pct
FROM orders
GROUP BY delivery_status
ORDER BY delivery_status;
