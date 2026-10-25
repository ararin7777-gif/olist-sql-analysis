-- おまけ2 BigQuery(sandbox)で同じ集計を動かす
-- 準備: olist_orders_dataset.csv を、データセット olist のテーブル orders としてアップロード(スキーマは自動検出)
--
-- PostgreSQL との違い
--   ・表の名前は `プロジェクト.データセット.テーブル` とバッククォートで囲む
--   ・DATE_TRUNC('month', 列) → TIMESTAMP_TRUNC(列, MONTH)
--   ・料金は「読んだデータ量」で決まる。列指向なので、使う列だけが読まれる
--     (このクエリ: 表全体 11.25 MB のうち 776.88 KB だけを処理)

SELECT TIMESTAMP_TRUNC(order_purchase_timestamp, MONTH) AS month,
       COUNT(*) AS order_count
FROM `olist-practice.olist.orders`
WHERE order_purchase_timestamp >= '2018-01-01'
  AND order_purchase_timestamp <  '2018-09-01'
GROUP BY month
ORDER BY month;
