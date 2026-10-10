-- =====================================================================
-- 03_risk_analysis/01_portfolio_overview_and_npl.sql
-- Headline numbers: default rate, DPD buckets, NPL ratio.
-- =====================================================================

-- Portfolio overview
-- Result: 307,511 loans, 24,825 defaults, 8.07% default rate
SELECT
    COUNT(*) AS total_loans,
    SUM(target) AS total_defaults,
    ROUND(100.0 * SUM(target) / COUNT(*), 2) AS default_rate_pct
FROM loans;


-- Days-past-due (DPD) buckets across all monthly records
SELECT
    CASE
        WHEN sk_dpd = 0 THEN '0 - Current'
        WHEN sk_dpd BETWEEN 1 AND 30 THEN '1-30 DPD'
        WHEN sk_dpd BETWEEN 31 AND 60 THEN '31-60 DPD'
        WHEN sk_dpd BETWEEN 61 AND 90 THEN '61-90 DPD'
        WHEN sk_dpd > 90 THEN '90+ DPD (NPL)'
    END AS dpd_bucket,
    COUNT(*) AS record_count
FROM delinquency_history
GROUP BY 1
ORDER BY MIN(sk_dpd);


-- NPL ratio: share of monthly records more than 90 days past due
-- Result: 1.23%
-- (See 06_vintage_analysis.sql: almost all of this sits in loans that run
--  past their scheduled term.)
SELECT
    COUNT(*) AS total_records,
    SUM(CASE WHEN sk_dpd > 90 THEN 1 ELSE 0 END) AS npl_records,
    ROUND(100.0 * SUM(CASE WHEN sk_dpd > 90 THEN 1 ELSE 0 END) / COUNT(*), 2) AS npl_ratio_pct
FROM delinquency_history;
