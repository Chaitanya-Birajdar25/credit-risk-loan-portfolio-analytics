-- =====================================================================
-- 03_risk_analysis/07_risk_driver_calibration.sql
-- Which things I can calculate actually separate risky customers from safe ones?
-- Overall default rate for reference: 8.07%.
-- =====================================================================


-- ---------------------------------------------------------------------
-- SANITY CHECK (not the analysis): how many customers have each ingredient?
-- Result: 307,511 customers; 289,444 (94.12%) have earlier-loan history;
--         172 have no external score at all; 12 have no DTI.
-- ---------------------------------------------------------------------
WITH has_history AS (
    SELECT DISTINCT sk_id_curr
    FROM delinquency_history
)
SELECT
    COUNT(*)                                                     AS customers,
    COUNT(h.sk_id_curr)                                          AS with_dpd_history,
    ROUND(100.0 * COUNT(h.sk_id_curr) / COUNT(*), 2)             AS pct_with_history,
    COUNT(*) FILTER (WHERE (c.ext_source_1 IS NOT NULL)::int
                         + (c.ext_source_2 IS NOT NULL)::int
                         + (c.ext_source_3 IS NOT NULL)::int = 0) AS no_ext_score,
    COUNT(*) FILTER (WHERE l.amt_annuity IS NULL
                        OR c.amt_income_total = 0)               AS no_dti
FROM customers c
JOIN loans l ON l.sk_id_curr = c.sk_id_curr
LEFT JOIN has_history h ON h.sk_id_curr = c.sk_id_curr;


-- ---------------------------------------------------------------------
-- PAST LATENESS: default rate by a customer's worst delay on earlier loans.
-- Result:
--   0 No history          18,067 customers   6.66%
--   1 Never late         234,761             7.72%
--   2 Worst 1-30 days     47,509            10.13%
--   3 Worst 31-90 days     2,532            11.41%
--   4 Worst 90+ days       4,642             8.51%
-- A modest signal. The 90+ group is small and breaks the upward pattern; I have
-- not checked why. Customers with no history are the safest group, not the riskiest.
-- ---------------------------------------------------------------------
WITH cust_dpd AS (
    SELECT sk_id_curr, MAX(sk_dpd) AS max_dpd
    FROM delinquency_history
    GROUP BY sk_id_curr
)
SELECT
    CASE WHEN d.sk_id_curr IS NULL THEN '0 No history'
         WHEN d.max_dpd = 0         THEN '1 Never late'
         WHEN d.max_dpd <= 30       THEN '2 Worst 1-30 days'
         WHEN d.max_dpd <= 90       THEN '3 Worst 31-90 days'
         ELSE                            '4 Worst 90+ days'
    END                                        AS history_band,
    COUNT(*)                                   AS customers,
    ROUND(100.0 * AVG(l.target), 2)            AS default_rate_pct
FROM loans l
LEFT JOIN cust_dpd d ON d.sk_id_curr = l.sk_id_curr
GROUP BY history_band
ORDER BY history_band;


-- ---------------------------------------------------------------------
-- EXTERNAL SCORE AND DTI in finer bands.
-- ext_avg = average of whichever of ext_source_1/2/3 a customer has.
-- Result, ext_avg:  missing 8.14% | <0.20 28.24% | 0.20-0.30 20.36% |
--   0.30-0.40 14.08% | 0.40-0.50 8.52% | 0.50-0.60 5.14% | 0.60-0.70 3.29% | 0.70+ 1.98%
-- Result, dti:      missing 0.00% (12 customers) | <0.10 7.26% | 0.10-0.20 8.01% |
--   0.20-0.30 8.76% | 0.30-0.40 8.11% | 0.40+ 8.27%
-- The external score is a strong signal. DTI is weak, and flat above 0.30.
-- ---------------------------------------------------------------------
WITH base AS (
    SELECT
        l.target,
        (COALESCE(c.ext_source_1, 0) + COALESCE(c.ext_source_2, 0) + COALESCE(c.ext_source_3, 0))
          / NULLIF((c.ext_source_1 IS NOT NULL)::int
                 + (c.ext_source_2 IS NOT NULL)::int
                 + (c.ext_source_3 IS NOT NULL)::int, 0)   AS ext_avg,
        l.amt_annuity / NULLIF(c.amt_income_total, 0)      AS dti
    FROM loans l
    JOIN customers c ON c.sk_id_curr = l.sk_id_curr
),
banded AS (
    SELECT 'ext_avg' AS feature,
           CASE WHEN ext_avg IS NULL THEN '0 missing'
                WHEN ext_avg < 0.2 THEN '1 under 0.20'
                WHEN ext_avg < 0.3 THEN '2 0.20-0.30'
                WHEN ext_avg < 0.4 THEN '3 0.30-0.40'
                WHEN ext_avg < 0.5 THEN '4 0.40-0.50'
                WHEN ext_avg < 0.6 THEN '5 0.50-0.60'
                WHEN ext_avg < 0.7 THEN '6 0.60-0.70'
                ELSE                    '7 0.70+' END  AS band,
           target
    FROM base
    UNION ALL
    SELECT 'dti',
           CASE WHEN dti IS NULL THEN '0 missing'
                WHEN dti < 0.1 THEN '1 under 0.10'
                WHEN dti < 0.2 THEN '2 0.10-0.20'
                WHEN dti < 0.3 THEN '3 0.20-0.30'
                WHEN dti < 0.4 THEN '4 0.30-0.40'
                ELSE                '5 0.40+' END,
           target
    FROM base
)
SELECT
    feature,
    band,
    COUNT(*)                          AS customers,
    ROUND(100.0 * AVG(target), 2)     AS default_rate_pct
FROM banded
GROUP BY feature, band
ORDER BY feature, band;
