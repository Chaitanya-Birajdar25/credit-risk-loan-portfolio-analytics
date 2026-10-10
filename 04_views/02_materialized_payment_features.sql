-- =====================================================================
-- 04_views/02_materialized_payment_features.sql
-- Per-customer payment-history features for the ML phase.
-- Materialized because it scans repayments (11.6M rows) and
-- delinquency_history (~10M rows); computed once, read many times.
-- Customers with no history keep NULLs and get a "no history" flag.
-- =====================================================================

-- SANITY CHECK (preview): how many customers have payment history?
-- Result: 291,643 in repayments, 289,444 in delinquency_history, 307,511 total.
SELECT
  (SELECT COUNT(DISTINCT sk_id_curr) FROM repayments)            AS customers_in_repayments,
  (SELECT COUNT(DISTINCT sk_id_curr) FROM delinquency_history)   AS customers_in_delinquency,
  (SELECT COUNT(*) FROM customers)                               AS total_customers;

-- REAL BUILD
CREATE MATERIALIZED VIEW mv_customer_payment_features AS
WITH rep AS (
    SELECT
        sk_id_curr,
        COUNT(*) AS n_installments,
        AVG(GREATEST(days_entry_payment - days_instalment, 0)) AS avg_days_late,
        MAX(GREATEST(days_entry_payment - days_instalment, 0)) AS max_days_late,
        AVG(CASE WHEN days_entry_payment > days_instalment THEN 1.0 ELSE 0 END) AS share_late,
        AVG(CASE WHEN amt_payment < amt_instalment THEN 1.0 ELSE 0 END) AS share_underpaid
    FROM repayments
    WHERE days_entry_payment IS NOT NULL
    GROUP BY sk_id_curr
),
dq AS (
    SELECT
        sk_id_curr,
        COUNT(*) AS n_months,
        MAX(sk_dpd) AS max_dpd,
        AVG(CASE WHEN sk_dpd > 0 THEN 1.0 ELSE 0 END) AS share_months_dpd
    FROM delinquency_history
    GROUP BY sk_id_curr
)
SELECT
    c.sk_id_curr,
    rep.n_installments, rep.avg_days_late, rep.max_days_late,
    rep.share_late, rep.share_underpaid,
    dq.n_months, dq.max_dpd, dq.share_months_dpd,
    (rep.sk_id_curr IS NULL)::int AS no_repayment_history,
    (dq.sk_id_curr IS NULL)::int  AS no_delinquency_history
FROM customers c
LEFT JOIN rep ON rep.sk_id_curr = c.sk_id_curr
LEFT JOIN dq  ON dq.sk_id_curr  = c.sk_id_curr;

-- SANITY CHECK (preview).
-- Result: 307,511 rows; 291,635 with repayment features (8 customers had only
-- unpaid installments, dropped by the WHERE filter); 289,444 with DPD features;
-- average share_late 0.076.
SELECT COUNT(*) AS total_rows,
       COUNT(avg_days_late) AS with_repayment_features,
       COUNT(max_dpd) AS with_dpd_features,
       ROUND(AVG(share_late)::numeric, 3) AS avg_share_late
FROM mv_customer_payment_features;
