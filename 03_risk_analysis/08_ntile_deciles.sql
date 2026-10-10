-- =====================================================================
-- 03_risk_analysis/08_ntile_deciles.sql
-- Default rate by EXT_SOURCE_2 decile (equal-sized groups, decile 1 = lowest score).
-- Result: default rate falls at every step, 18.35% (decile 1) to 2.97% (decile 10),
-- about a 6x spread from one feature. ~30,685 customers per decile (306,851 with a score).
-- Customers with no ext_source_2 (0.21%) are excluded.
-- =====================================================================
WITH scored AS (
    SELECT c.sk_id_curr, c.ext_source_2, l.target,
           NTILE(10) OVER (ORDER BY c.ext_source_2) AS decile
    FROM customers c
    JOIN loans l ON l.sk_id_curr = c.sk_id_curr
    WHERE c.ext_source_2 IS NOT NULL
)
SELECT decile,
       COUNT(*)                                  AS borrowers,
       ROUND(MIN(ext_source_2)::numeric, 3)      AS min_score,
       ROUND(MAX(ext_source_2)::numeric, 3)      AS max_score,
       SUM(target)                               AS defaults,
       ROUND(100.0 * AVG(target), 2)             AS default_rate_pct
FROM scored
GROUP BY decile
ORDER BY decile;
