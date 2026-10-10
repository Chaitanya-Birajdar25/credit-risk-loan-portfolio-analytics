-- =====================================================================
-- 03_risk_analysis/02_segmentation_analysis.sql
-- Default rate by customer segment.
-- =====================================================================

-- By income type
SELECT
    c.name_income_type,
    COUNT(*) AS total_loans,
    SUM(l.target) AS defaults,
    ROUND(100.0 * SUM(l.target) / COUNT(*), 2) AS default_rate_pct
FROM customers c
JOIN loans l ON c.sk_id_curr = l.sk_id_curr
GROUP BY c.name_income_type
ORDER BY default_rate_pct DESC;


-- By age group (age worked out from days_birth, which is negative days)
SELECT
    CASE
        WHEN -c.days_birth/365 < 25 THEN 'Under 25'
        WHEN -c.days_birth/365 BETWEEN 25 AND 34 THEN '25-34'
        WHEN -c.days_birth/365 BETWEEN 35 AND 44 THEN '35-44'
        WHEN -c.days_birth/365 BETWEEN 45 AND 54 THEN '45-54'
        ELSE '55+'
    END AS age_group,
    COUNT(*) AS total_loans,
    SUM(l.target) AS defaults,
    ROUND(100.0 * SUM(l.target) / COUNT(*), 2) AS default_rate_pct
FROM customers c
JOIN loans l ON c.sk_id_curr = l.sk_id_curr
GROUP BY 1
ORDER BY default_rate_pct DESC;


-- By education level
SELECT
    c.name_education_type,
    COUNT(*) AS total_loans,
    SUM(l.target) AS defaults,
    ROUND(100.0 * SUM(l.target) / COUNT(*), 2) AS default_rate_pct
FROM customers c
JOIN loans l ON c.sk_id_curr = l.sk_id_curr
GROUP BY c.name_education_type
ORDER BY default_rate_pct DESC;


-- Income type x education, ranked by default rate.
-- Segments with 100 loans or fewer are dropped so small groups don't dominate the ranking.
SELECT
    c.name_income_type,
    c.name_education_type,
    COUNT(*) AS total_loans,
    SUM(l.target) AS defaults,
    ROUND(100.0 * SUM(l.target) / COUNT(*), 2) AS default_rate_pct,
    RANK() OVER (ORDER BY ROUND(100.0 * SUM(l.target) / COUNT(*), 2) DESC) AS risk_rank
FROM customers c
JOIN loans l ON c.sk_id_curr = l.sk_id_curr
GROUP BY c.name_income_type, c.name_education_type
HAVING COUNT(*) > 100
ORDER BY risk_rank;
