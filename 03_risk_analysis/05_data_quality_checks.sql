-- =====================================================================
-- 03_risk_analysis/05_data_quality_checks.sql
-- Can the data be trusted?
-- =====================================================================

-- DAYS_EMPLOYED has a placeholder value (365243) instead of a real number.
-- Result: 18.01% of customers are affected. Flagged, not silently used.
SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN days_employed = 365243 THEN 1 ELSE 0 END) AS anomalous_employment_flag,
    ROUND(100.0 * SUM(CASE WHEN days_employed = 365243 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_affected
FROM customers;


-- Duplicate IDs and invalid income
-- Result: 0 duplicate customer IDs, 0 non-positive or missing income values
SELECT
    (SELECT COUNT(*) - COUNT(DISTINCT sk_id_curr) FROM customers) AS duplicate_customer_ids,
    (SELECT COUNT(*) FROM customers WHERE amt_income_total <= 0) AS non_positive_income_count,
    (SELECT COUNT(*) FROM customers WHERE amt_income_total IS NULL) AS null_income_count;


-- Missing rates for the three external scores
-- Result: ext_source_1 56.38% missing, ext_source_2 0.21%, ext_source_3 19.83%
SELECT
    ROUND(100.0 * SUM(CASE WHEN ext_source_1 IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS ext_source_1_missing_pct,
    ROUND(100.0 * SUM(CASE WHEN ext_source_2 IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS ext_source_2_missing_pct,
    ROUND(100.0 * SUM(CASE WHEN ext_source_3 IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS ext_source_3_missing_pct
FROM customers;
