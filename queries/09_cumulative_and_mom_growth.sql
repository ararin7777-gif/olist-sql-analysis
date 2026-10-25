-- 09 月別売上の累計と前月比(2017年1月〜2018年8月)
-- 問い: 事業は伸び続けているか
-- 使った技: CTE / SUM() OVER(累計)/ LAG() OVER(前月の値)

WITH monthly_sales AS (
  SELECT DATE_TRUNC('month', o.order_purchase_timestamp)::date AS month,
         SUM(oi.price) AS sales
  FROM orders AS o
  INNER JOIN order_items AS oi ON oi.order_id = o.order_id
  WHERE o.order_purchase_timestamp >= '2017-01-01'
    AND o.order_purchase_timestamp <  '2018-09-01'   -- 8月末までを含めるため「9月1日より前」
  GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
)
SELECT month,
       sales,
       SUM(sales) OVER (ORDER BY month) AS cumulative_sales,
       ROUND((sales - LAG(sales) OVER (ORDER BY month))
             / LAG(sales) OVER (ORDER BY month) * 100, 1) AS mom_growth_pct
FROM monthly_sales
ORDER BY month;
