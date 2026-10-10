-- =====================================================================
-- 03_risk_analysis/03_roll_rate_analysis.sql
-- How does a loan's delinquency status change over its recorded life?
-- =====================================================================

-- PREVIEW ONLY (sanity check, not the analysis).
-- My first attempt was to count every month-to-month change in DPD. This
-- preview showed why that is misleading: a loan that bounces between late and
-- on time gets counted again and again, which overstates deterioration.
SELECT
    sk_id_prev,
    months_balance,
    sk_dpd,
    LAG(sk_dpd) OVER (PARTITION BY sk_id_prev ORDER BY months_balance) AS prev_month_dpd,
    sk_dpd - LAG(sk_dpd) OVER (PARTITION BY sk_id_prev ORDER BY months_balance) AS dpd_change
FROM delinquency_history
LIMIT 50;


-- THE ANALYSIS: one outcome per loan, comparing its first and last recorded DPD.
WITH loan_dpd_range AS (
    SELECT
        sk_id_prev,
        FIRST_VALUE(sk_dpd) OVER (PARTITION BY sk_id_prev ORDER BY months_balance
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS first_dpd,
        LAST_VALUE(sk_dpd) OVER (PARTITION BY sk_id_prev ORDER BY months_balance
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_dpd
    FROM delinquency_history
),
loan_summary AS (
    SELECT DISTINCT sk_id_prev, first_dpd, last_dpd
    FROM loan_dpd_range
)
SELECT
    CASE
        WHEN last_dpd > first_dpd THEN 'Ended Worse'
        WHEN last_dpd < first_dpd THEN 'Ended Better'
        ELSE 'No Net Change'
    END AS net_outcome,
    COUNT(*) AS loan_count
FROM loan_summary
GROUP BY 1
ORDER BY loan_count DESC;
