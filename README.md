# Olist EC データの SQL 分析

ブラジルの EC サイト「Olist」の公開データ(注文 約10万件)を PostgreSQL で分析した、SQL 10本の作品集です。
「ビジネス上の問い → SQL → わかったこと」の形でまとめています。

## 使った技術

| 分類 | 内容 |
|---|---|
| データベース | PostgreSQL 16(Docker で起動)、BigQuery(sandbox)、Snowflake(無料トライアル) |
| SQL | JOIN(最大5表)、GROUP BY / HAVING、サブクエリ、CTE(WITH)、CASE、COALESCE |
| ウィンドウ関数 | RANK / SUM() OVER(累計)/ LAG(前月比)/ PARTITION BY |
| 性能 | インデックス、EXPLAIN ANALYZE による実行計画の確認 |

## データ

- 出典: [Brazilian E-Commerce Public Dataset by Olist(Kaggle)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
- 期間: 2016年9月〜2018年9月
- 使った表(5つ)

```
customers ──(customer_id)── orders ──(order_id)── order_items ──(product_id)── products ──(product_category_name)── category_translation
  99,441行                   99,441行               112,650行                   32,951行                              71行
```

CSV はライセンスの都合でリポジトリに含めていません。上のリンクからダウンロードしてください。

## 分析の一覧

| # | 問い | 主な技 | わかったこと |
|---|---|---|---|
| [01](queries/01_monthly_orders_and_sales.sql) | 売上はどう推移しているか | JOIN / DATE_TRUNC / COUNT(DISTINCT) | 2017年に急成長し、2018年は月84〜100万レアルで横ばい |
| [02](queries/02_sales_by_state.sql) | どの地域の売上が大きいか | 3表 JOIN | サンパウロ州(SP)が約520万レアルで全体の約38%。2位 RJ の約2.9倍 |
| [03](queries/03_sales_by_category.sql) | 何が売れているか | 3表 JOIN | 1位は健康・美容、2位は時計・ギフト、3位は寝具・バス用品 |
| [04](queries/04_repeat_customers.sql) | リピーターはどれくらいいるか | CTE / FILTER | 2回以上買った客は約3,000人で、リピート率は **3.1%**。ほぼ一見客のサービス |
| [05](queries/05_order_value_bands.sql) | 1回の注文でいくら使われるか | CTE / CASE | 約6割の注文が100レアル未満。平均(約138)は、15%の高額注文に引き上げられている |
| [06](queries/06_delivery_status.sql) | お届け予定日を守れているか | CASE / IS NULL | 予定日までに届いたのは89.1%、遅延7.9%、未配達3.0% |
| [07](queries/07_top_category_by_state.sql) | 地域によって売れるものは違うか | 5表 JOIN / 複数 CTE / RANK | SP・RS は寝具、RJ・PR は時計・ギフト、MG・BA・PE は健康・美容が1位 |
| [08](queries/08_top_cities_by_state.sql) | 注文は州のどこに集中しているか | RANK / PARTITION BY | SP州ではサンパウロ市が15,540件で、2位の約10倍。注文は州都に集中 |
| [09](queries/09_cumulative_and_mom_growth.sql) | 事業は伸び続けているか | SUM() OVER / LAG | 2017年11月は前月比 **+52%**(ブラックフライデーの影響と考えられる)。2018年2月以降は前月比 -13%〜+17% を行き来し、成長が頭打ち |
| [10](queries/10_category_sales_with_unknown.sql) | INNER JOIN で消えた売上はないか | LEFT JOIN / COALESCE | カテゴリ不明の売上が約18.5万レアルあった。LEFT JOIN で残すと全体の売上と一致 |

## おまけ

- [インデックスと実行計画](extras/index_and_explain.sql): `product_id` にインデックスを付けると、Seq Scan(約16ms)から Index Only Scan(約0.1〜0.4ms)に変わり、約40〜100倍速くなった。値が偏った列(顧客の42%が SP 州)には効きにくいことも確認した
- [BigQuery 版](extras/bigquery_monthly_orders.sql): 同じ集計を BigQuery で実行した。列指向のため、11.25MB の表から使う1列(776.88KB)だけが読まれる
- [Snowflake 版](extras/snowflake_migration.sql): 3つの表を Snowflake に移し、件数・合計・NULL の数で検算した。文字で入った日時の列を型に直した表を作るだけで、分析 01・02・09 が PostgreSQL と同じ結果になった。CLONE と Time Travel(消したデータの取り戻し)も試した

## 気をつけたこと

- **重複して数えない**: 1注文に明細が複数あるため、JOIN 後の注文数は `COUNT(DISTINCT order_id)` で数えた
- **同じ人を正しく数える**: `customer_id` は注文ごとに変わるため、人数は `customer_unique_id` で数えた
- **NULL の扱い**: 未配達は届いた日時が NULL になる。比較の前に `IS NULL` で先に分けた
- **期間の終わり**: 「8月末まで」は `< '2018-09-01'` と書き、8月31日の途中の時刻も漏らさないようにした
- **合計の検算**: カテゴリ別の合計が全体の売上と一致するかを確かめ、INNER JOIN で消えた行に気づいた

## 動かし方

```bash
# 1. Kaggle から CSV をダウンロードし、data/ フォルダに置く

# 2. PostgreSQL を Docker で起動する(このフォルダを /work として見せる)
docker run -d --name pg -e POSTGRES_PASSWORD=<任意のパスワード> \
  -p 127.0.0.1:5432:5432 -v "$(pwd):/work:ro" postgres:16

# 3. データベースを作り、CSV を取り込む
docker exec pg psql -U postgres -c "CREATE DATABASE olist;"
docker exec pg psql -U postgres -d olist -f /work/setup/setup_olist.sql

# 4. 分析を実行する
docker exec pg psql -U postgres -d olist -f /work/queries/01_monthly_orders_and_sales.sql
```

## フォルダ構成

```
├── README.md
├── setup/setup_olist.sql   表の作成と CSV の取り込み
├── queries/                分析 SQL 10本
└── extras/                 インデックスの実験、BigQuery 版、Snowflake 版
```
