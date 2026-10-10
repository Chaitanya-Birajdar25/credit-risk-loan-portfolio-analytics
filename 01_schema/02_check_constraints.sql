-- =====================================================================
-- 01_schema/02_check_constraints.sql
-- Schema-level validation. Run the sanity check first: every number must be 0
-- (all were 0 when run), otherwise an ALTER below will fail on existing rows.
-- NULLs pass CHECK constraints, so missing ext_source values are unaffected.
-- =====================================================================

-- SANITY CHECK (preview)
SELECT
  (SELECT COUNT(*) FROM loans WHERE target NOT IN (0,1))                     AS bad_target,
  (SELECT COUNT(*) FROM loans WHERE amt_credit <= 0)                         AS bad_credit,
  (SELECT COUNT(*) FROM customers WHERE amt_income_total <= 0)               AS bad_income,
  (SELECT COUNT(*) FROM customers WHERE days_birth >= 0)                     AS bad_birth,
  (SELECT COUNT(*) FROM customers WHERE ext_source_1 NOT BETWEEN 0 AND 1
                                      OR ext_source_2 NOT BETWEEN 0 AND 1
                                      OR ext_source_3 NOT BETWEEN 0 AND 1)   AS bad_ext,
  (SELECT COUNT(*) FROM delinquency_history WHERE sk_dpd < 0)                AS bad_dpd;

-- REAL CHANGE (the last one scans ~10M rows)
ALTER TABLE loans ADD CONSTRAINT chk_loans_target CHECK (target IN (0,1));
ALTER TABLE loans ADD CONSTRAINT chk_loans_credit CHECK (amt_credit > 0);
ALTER TABLE customers ADD CONSTRAINT chk_cust_income CHECK (amt_income_total > 0);
ALTER TABLE customers ADD CONSTRAINT chk_cust_birth CHECK (days_birth < 0);
ALTER TABLE customers ADD CONSTRAINT chk_cust_ext
  CHECK (ext_source_1 BETWEEN 0 AND 1 AND ext_source_2 BETWEEN 0 AND 1 AND ext_source_3 BETWEEN 0 AND 1);
ALTER TABLE delinquency_history ADD CONSTRAINT chk_dq_dpd CHECK (sk_dpd >= 0);
