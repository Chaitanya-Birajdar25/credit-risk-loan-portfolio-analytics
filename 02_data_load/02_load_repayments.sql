-- =====================================================================
-- 02_data_load/02_load_repayments.sql
-- Fills repayments from staging_installments_payments (13,605,401 rows, so
-- this one takes a while). The EXISTS check keeps the foreign key safe: only
-- rows whose customer exists in the customers table are loaded. 11,591,592
-- rows were kept in my load.
-- =====================================================================

INSERT INTO repayments (
    sk_id_prev, sk_id_curr, num_instalment_version, num_instalment_number,
    days_instalment, days_entry_payment, amt_instalment, amt_payment
)
SELECT
    s.sk_id_prev, s.sk_id_curr, s.num_instalment_version, s.num_instalment_number,
    s.days_instalment, s.days_entry_payment, s.amt_instalment, s.amt_payment
FROM staging_installments_payments s
WHERE EXISTS (
    SELECT 1 FROM customers c WHERE c.sk_id_curr = s.sk_id_curr
);

-- Sanity check: row count
SELECT COUNT(*) FROM repayments;
