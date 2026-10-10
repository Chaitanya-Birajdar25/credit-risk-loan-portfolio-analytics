-- =====================================================================
-- 03_risk_analysis/04_risk_signal_validation.sql
-- First checks that the ratios and scores I use actually line up with default.
-- (Finer-grained versions of both checks are in 07_risk_driver_calibration.sql.)
-- =====================================================================

-- Debt-to-income (annuity / income), calculated live, in four broad bands.
-- The same query is saved as the view vw_default_rate_by_dti_band.
SELECT
    CASE
        WHEN l.amt_annuity / c.amt_income_total < 0.20 THEN 'Low DTI (<20%)'
        WHEN l.amt_annuity / c.amt_income_total BETWEEN 0.20 AND 0.40 THEN 'Moderate DTI (20-40%)'
        WHEN l.amt_annuity / c.amt_income_total BETWEEN 0.40 AND 0.60 THEN 'High DTI (40-60%)'
        ELSE 'Very High DTI (60%+)'
    END AS dti_band,
    COUNT(*) AS total_loans,
    SUM(l.target) AS defaults,
    ROUND(100.0 * SUM(l.target) / COUNT(*), 2) AS default_rate_pct
FROM customers c
JOIN loans l ON c.sk_id_curr = l.sk_id_curr
WHERE c.amt_income_total > 0
GROUP BY 1
ORDER BY default_rate_pct DESC;


-- EXT_SOURCE_2 by score band.
-- Result: default rate falls as the score rises, so it behaves like a real
-- risk score and I don't have to take that on faith.
SELECT
    CASE
        WHEN ext_source_2 < 0.2 THEN 'Very Low Score (<0.2)'
        WHEN ext_source_2 BETWEEN 0.2 AND 0.4 THEN 'Low Score (0.2-0.4)'
        WHEN ext_source_2 BETWEEN 0.4 AND 0.6 THEN 'Medium Score (0.4-0.6)'
        WHEN ext_source_2 BETWEEN 0.6 AND 0.8 THEN 'High Score (0.6-0.8)'
        WHEN ext_source_2 >= 0.8 THEN 'Very High Score (0.8+)'
    END AS score_band,
    COUNT(*) AS total_loans,
    SUM(l.target) AS defaults,
    ROUND(100.0 * SUM(l.target) / COUNT(*), 2) AS default_rate_pct
FROM customers c
JOIN loans l ON c.sk_id_curr = l.sk_id_curr
WHERE c.ext_source_2 IS NOT NULL
GROUP BY 1
ORDER BY MIN(c.ext_source_2);
