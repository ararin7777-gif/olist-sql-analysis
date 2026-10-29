-- おまけ3 Snowflake(無料トライアル)に移して、同じ結果になるかを確かめる
-- 準備: orders・order_items・customers の CSV を、Snowsight の画面から OLIST.PUBLIC に取り込む
--       郵便番号(customer_zip_code_prefix)は先頭の0が消えないよう VARCHAR にする
--
-- PostgreSQL との違い
--   ・日時の列が文字(VARCHAR)として入ったので、型を直した表 orders_clean を作ってから使う
--   ・JOIN、DATE_TRUNC、::date、SUM() OVER、LAG() は同じ書き方で動いた
--   ・料金は「ウェアハウス(計算の担当)が動いた時間」で決まる。BigQuery は「読んだデータ量」

-- 1. 日時の列を、文字から日時の型に直した表を作る
--    TRY_TO_TIMESTAMP は、読めない値をエラーにせず NULL にする
CREATE OR REPLACE TABLE orders_clean AS
SELECT order_id,
       customer_id,
       order_status,
       TRY_TO_TIMESTAMP(order_purchase_timestamp,      'YYYY/MM/DD HH24:MI') AS order_purchase_timestamp,
       TRY_TO_TIMESTAMP(order_approved_at,             'YYYY/MM/DD HH24:MI') AS order_approved_at,
       TRY_TO_TIMESTAMP(order_delivered_carrier_date,  'YYYY/MM/DD HH24:MI') AS order_delivered_carrier_date,
       TRY_TO_TIMESTAMP(order_delivered_customer_date, 'YYYY/MM/DD HH24:MI') AS order_delivered_customer_date,
       TRY_TO_TIMESTAMP(order_estimated_delivery_date, 'YYYY/MM/DD HH24:MI') AS order_estimated_delivery_date
FROM orders;

-- 2. 検算: 件数・合計・NULL の数が PostgreSQL と一致するか
SELECT COUNT(*), SUM(price), SUM(freight_value) FROM order_items;
-- → 112,650 / 13,591,643.70 / 2,251,909.54

SELECT COUNT(*) AS total,
       COUNT(*) - COUNT(order_purchase_timestamp)      AS purchase_null,
       COUNT(*) - COUNT(order_approved_at)             AS approved_null,
       COUNT(*) - COUNT(order_delivered_carrier_date)  AS carrier_null,
       COUNT(*) - COUNT(order_delivered_customer_date) AS delivered_null,
       COUNT(*) - COUNT(order_estimated_delivery_date) AS estimated_null
FROM orders_clean;
-- → 99,441 / 0 / 160 / 1,783 / 2,965 / 0(変換で値が消えていない)

SELECT COUNT(*) AS total,
       COUNT(DISTINCT customer_unique_id) AS people,
       MIN(customer_zip_code_prefix) AS min_zip
FROM customers;
-- → 99,441 / 96,096 / 01003(先頭の0が残っている)

-- 3. 公開した分析を動かす
--    日時の列を使う 01・09 は FROM orders を orders_clean に変えるだけ
--    02 は order_id・customer_id しか使わないので orders のままで動く
--    → 01: 24行、02: SP 5,202,955.05 ほか上位5州、09: 20行(2018-08 の累計 13,541,712.78)で一致

-- 4. Snowflake らしい機能: CLONE と Time Travel
--    CLONE は中身を複製せずに表のコピーを作る。練習はコピーで行う
CREATE OR REPLACE TABLE customers_test CLONE customers;

DELETE FROM customers_test WHERE customer_state = 'SP';   -- 41,746行を消す

-- 直前の SQL(DELETE)を実行する前の状態を読む
SELECT COUNT(*) FROM customers_test BEFORE(STATEMENT => LAST_QUERY_ID());
-- → 99,441(消す前の件数が見える)

-- 表ごと消しても、消した瞬間の状態で取り戻せる
DROP TABLE customers_test;
UNDROP TABLE customers_test;
SELECT COUNT(*) FROM customers_test;
-- → 57,695(SP を消したあとの状態で戻る)
