-- おまけ1 インデックスの効果を実行計画で確かめる
-- 使った技: EXPLAIN ANALYZE / CREATE INDEX
-- 対象: いちばん売れた商品(明細 527件)を、order_items(約11万行)から探す

-- ① インデックスなし → Seq Scan(全行を調べる)
EXPLAIN ANALYZE
SELECT COUNT(*) FROM order_items
WHERE product_id = 'aca2eb7d00ea1a7b8ebd4e68314663af';
-- 結果の例: Seq Scan on order_items / Rows Removed by Filter: 112123 / Execution Time: 約16 ms

-- ② product_id にインデックスを作る
CREATE INDEX idx_order_items_product_id ON order_items (product_id);

-- ③ もう一度同じ EXPLAIN ANALYZE → Index Only Scan(索引だけで答えが出る)
EXPLAIN ANALYZE
SELECT COUNT(*) FROM order_items
WHERE product_id = 'aca2eb7d00ea1a7b8ebd4e68314663af';
-- 結果の例: Index Only Scan using idx_order_items_product_id / Execution Time: 約0.1〜0.4 ms

-- すべての列にインデックスを付けない理由
--   ・追加・更新・削除のたびにインデックスも更新されるので、書き込みが遅くなる
--   ・インデックス自体が保存領域を使う
--   ・値の種類が少ない列には効きにくい
--     (例: customer_state = 'SP' は顧客の42%なので、索引を使っても全件を読むのと大差ない)
