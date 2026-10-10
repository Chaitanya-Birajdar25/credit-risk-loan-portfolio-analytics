-- =====================================================================
-- 02_data_load/03_load_delinquency_history.sql
-- Fills delinquency_history from staging_pos_cash_balance (10,001,358 monthly
-- status records from customers' earlier loans).
-- Same EXISTS check as the repayments load.
-- =====================================================================

-- Sanity check: rows in the staging table before filtering
SELECT COUNT(*) FROM staging_pos_cash_balance;

INSERT INTO delinquency_history (
    sk_id_prev, sk_id_curr, months_balance, cnt_instalment,
    cnt_instalment_future, name_contract_status, sk_dpd, sk_dpd_def
)
SELECT
    s.sk_id_prev, s.sk_id_curr, s.months_balance, s.cnt_instalment,
    s.cnt_instalment_future, s.name_contract_status, s.sk_dpd, s.sk_dpd_def
FROM staging_pos_cash_balance s
WHERE EXISTS (
    SELECT 1 FROM customers c WHERE c.sk_id_curr = s.sk_id_curr
);

-- Sanity check: rows after filtering
SELECT COUNT(*) FROM delinquency_history;
