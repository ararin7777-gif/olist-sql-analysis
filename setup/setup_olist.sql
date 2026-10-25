-- Olist(ブラジルのECサイト)のデータを取り込むSQL
-- 実行: docker exec pg psql -U postgres -d olist -f /work/setup/setup_olist.sql
-- 何度実行しても同じ状態に戻る(作り直す)

DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS category_translation;

-- ステップ1: 入れ物(表)を作る ------------------------------

-- 顧客。customer_id は注文ごとに振られる番号で、同じ人でも注文が違えば別の値になる
-- 同じ人を表すのは customer_unique_id
CREATE TABLE customers (
  customer_id              TEXT PRIMARY KEY,
  customer_unique_id       TEXT NOT NULL,
  customer_zip_code_prefix TEXT,   -- 郵便番号は先頭の0を消さないよう文字で持つ
  customer_city            TEXT,
  customer_state           TEXT    -- 州(SP = サンパウロ など)
);

-- 注文。1行 = 1回の注文
CREATE TABLE orders (
  order_id                      TEXT PRIMARY KEY,
  customer_id                   TEXT NOT NULL REFERENCES customers(customer_id),
  order_status                  TEXT,       -- delivered(配達済み)、canceled(キャンセル)など
  order_purchase_timestamp      TIMESTAMP,  -- 購入日時
  order_approved_at             TIMESTAMP,  -- 支払い承認日時
  order_delivered_carrier_date  TIMESTAMP,  -- 配送業者に渡した日時
  order_delivered_customer_date TIMESTAMP,  -- 顧客に届いた日時(未配達は NULL)
  order_estimated_delivery_date TIMESTAMP   -- お届け予定日
);

-- 商品。列名の "lenght" は元データのつづり間違いだが、CSVに合わせてそのまま使う
CREATE TABLE products (
  product_id                 TEXT PRIMARY KEY,
  product_category_name      TEXT,   -- ポルトガル語のカテゴリ名
  product_name_lenght        INTEGER,
  product_description_lenght INTEGER,
  product_photos_qty         INTEGER,
  product_weight_g           INTEGER,
  product_length_cm          INTEGER,
  product_height_cm          INTEGER,
  product_width_cm           INTEGER
);

-- 注文明細。1行 = 注文の中の商品1個
-- 同じ注文で同じ商品を2個買うと、order_item_id が 1, 2 の2行になる
CREATE TABLE order_items (
  order_id            TEXT NOT NULL REFERENCES orders(order_id),
  order_item_id       INTEGER NOT NULL,
  product_id          TEXT NOT NULL REFERENCES products(product_id),
  seller_id           TEXT NOT NULL,
  shipping_limit_date TIMESTAMP,
  price               NUMERIC(10,2),  -- 商品の価格(ブラジルレアル)
  freight_value       NUMERIC(10,2),  -- 送料
  PRIMARY KEY (order_id, order_item_id)
);

-- カテゴリ名の英訳
CREATE TABLE category_translation (
  product_category_name         TEXT PRIMARY KEY,
  product_category_name_english TEXT
);

-- ステップ2: CSVの中身を流し込む ----------------------------
-- HEADER: 1行目は列名なので読み飛ばす
-- 親の表(customers, products)から先に入れる。注文明細は注文と商品を参照しているため

COPY customers   FROM '/work/data/olist_customers_dataset.csv'   WITH (FORMAT csv, HEADER true);
COPY orders      FROM '/work/data/olist_orders_dataset.csv'      WITH (FORMAT csv, HEADER true);
COPY products    FROM '/work/data/olist_products_dataset.csv'    WITH (FORMAT csv, HEADER true);
COPY order_items FROM '/work/data/olist_order_items_dataset.csv' WITH (FORMAT csv, HEADER true);
COPY category_translation FROM '/work/data/product_category_name_translation.csv' WITH (FORMAT csv, HEADER true);
