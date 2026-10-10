-- =====================================================================
-- 04_views/01_create_views.sql
-- Reusable views for the headline metrics.
-- =====================================================================

CREATE OR REPLACE VIEW vw_npl_ratio AS
SELECT
    COUNT(*) AS total_records,
    SUM(CASE WHEN sk_dpd > 90 THEN 1 ELSE 0 END) AS npl_records,
    ROUND(100.0 * SUM(CASE WHEN sk_dpd > 90 THEN 1 ELSE 0 END) / COUNT(*), 2) AS npl_ratio_pct
FROM delinquency_history;

CREATE OR REPLACE VIEW vw_default_rate_by_income_type AS
SELECT
    c.name_income_type,
    COUNT(*) AS total_loans,
    SUM(l.target) AS defaults,
    ROUND(100.0 * SUM(l.target) / COUNT(*), 2) AS default_rate_pct
FROM customers c
JOIN loans l ON c.sk_id_curr = l.sk_id_curr
GROUP BY c.name_income_type
ORDER BY default_rate_pct DESC;

CREATE OR REPLACE VIEW vw_default_rate_by_dti_band AS
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

-- Quick checks
SELECT * FROM vw_npl_ratio;
SELECT * FROM vw_default_rate_by_income_type;
SELECT * FROM vw_default_rate_by_dti_band;
