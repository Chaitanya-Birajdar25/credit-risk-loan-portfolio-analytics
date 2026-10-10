-- =====================================================================
-- 05_performance/01_indexing_and_explain_analyze.sql
-- Do indexes help? Depends on the kind of query.
--
-- My first before/after comparison was not a fair test: it compared timings of
-- two different queries, which says nothing about the index. This version is
-- controlled: same query, with the index, without it, then with it again.
--
-- Run top to bottom. The first block clears any old indexes so the baseline
-- really has none (safe to rerun).
-- =====================================================================

DROP INDEX IF EXISTS idx_loans_sk_id_curr;
DROP INDEX IF EXISTS idx_loans_target;
DROP INDEX IF EXISTS idx_delinquency_sk_id_prev;
DROP INDEX IF EXISTS idx_delinquency_months_balance;


-- ---------------------------------------------------------------------
-- TEST 1: full-table aggregate (reads most of the table)
-- Before indexes: about 299 ms
-- ---------------------------------------------------------------------
EXPLAIN ANALYZE
SELECT c.name_income_type, COUNT(*), SUM(l.target)
FROM customers c
JOIN loans l ON c.sk_id_curr = l.sk_id_curr
GROUP BY c.name_income_type;

CREATE INDEX idx_loans_sk_id_curr ON loans(sk_id_curr);
CREATE INDEX idx_loans_target ON loans(target);
CREATE INDEX idx_delinquency_sk_id_prev ON delinquency_history(sk_id_prev);
CREATE INDEX idx_delinquency_months_balance ON delinquency_history(months_balance);

-- After indexes: about 284 ms. Barely any change, because Postgres still has to
-- read almost every row.
EXPLAIN ANALYZE
SELECT c.name_income_type, COUNT(*), SUM(l.target)
FROM customers c
JOIN loans l ON c.sk_id_curr = l.sk_id_curr
GROUP BY c.name_income_type;


-- ---------------------------------------------------------------------
-- TEST 2: lookup of one customer (selective query), controlled
-- ---------------------------------------------------------------------

-- With the index: about 0.09 ms (index scan)
EXPLAIN ANALYZE
SELECT * FROM loans WHERE sk_id_curr = 100002;

DROP INDEX idx_loans_sk_id_curr;

-- Without the index: about 63.11 ms (sequential scan), roughly 700x slower
EXPLAIN ANALYZE
SELECT * FROM loans WHERE sk_id_curr = 100002;

-- Put the index back
CREATE INDEX idx_loans_sk_id_curr ON loans(sk_id_curr);
