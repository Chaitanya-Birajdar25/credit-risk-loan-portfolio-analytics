-- =====================================================================
-- 03_risk_analysis/06_vintage_analysis.sql
-- How does risk change as a loan ages?
--
-- The data (delinquency_history, built from POS_CASH_balance) has no start
-- date, only months_balance: a month number counted back from the application
-- date (0 is now, -1 is last month, and so on, back to -96).
-- So a loan's age = its months_balance minus its own first recorded month.
-- These are customers' EARLIER loans (sk_id_prev), not the loan behind `target`.
-- =====================================================================


-- ---------------------------------------------------------------------
-- STEP 1a. SANITY CHECK (not the analysis): what do loan histories look like?
-- Result: 800,337 loans; first months run from -96 to -1; history length 1 to 96
-- months (average 10.7); 1,634 loans have gaps (missing months).
-- ---------------------------------------------------------------------
WITH loan_span AS (
    SELECT
        sk_id_prev,
        MIN(months_balance) AS first_month,
        MAX(months_balance) AS last_month,
        COUNT(*)            AS months_recorded
    FROM delinquency_history
    GROUP BY sk_id_prev
)
SELECT
    COUNT(*)                        AS total_loans,
    MIN(first_month)                AS earliest_start,
    MAX(first_month)                AS latest_start,
    MIN(months_recorded)            AS shortest_history,
    MAX(months_recorded)            AS longest_history,
    ROUND(AVG(months_recorded), 1)  AS avg_history,
    SUM(CASE WHEN months_recorded <> last_month - first_month + 1
             THEN 1 ELSE 0 END)    AS loans_with_gaps
FROM loan_span;


-- ---------------------------------------------------------------------
-- STEP 1b. SANITY CHECK (not the analysis): how many loans can I trust the age of?
-- Result: 29,896 cut off at the start of the window (real start unknown),
--         81,608 still running at the end, 687,476 clean start to finish.
-- Cohort rule used below: drop the cut-off loans and the loans with gaps,
-- KEEP the still-running loans (each loan age has its own denominator).
-- ---------------------------------------------------------------------
WITH loan_span AS (
    SELECT
        sk_id_prev,
        MIN(months_balance) AS first_month,
        MAX(months_balance) AS last_month,
        COUNT(*)            AS months_recorded
    FROM delinquency_history
    GROUP BY sk_id_prev
)
SELECT
    COUNT(*)                                                      AS total_loans,
    COUNT(*) FILTER (WHERE first_month = -96)                     AS cut_off_at_start,
    COUNT(*) FILTER (WHERE last_month = -1)                       AS still_running_at_end,
    COUNT(*) FILTER (WHERE first_month > -96
                       AND last_month < -1
                       AND months_recorded = last_month - first_month + 1)
                                                                  AS fully_observed_clean
FROM loan_span;


-- ---------------------------------------------------------------------
-- STEP 2. THE VINTAGE CURVE: share of loans that are late, by loan age.
--
-- IMPORTANT: this is the CORRECTED version. My first version counted every
-- record, including records after a loan's scheduled end (term). The share of
-- late loans jumped at ages 13, 25 and 37 (multiples of 12) because healthy
-- 12/24/36-month loans finish and leave the data, while the loans still being
-- recorded past their term are mostly the unpaid ones. The denominator shrank
-- and the late share shot up without any loan actually changing.
-- Fix: only count records up to each loan's scheduled term (max cnt_instalment).
--
-- Result: late share rises from 0.04% at age 0 to about 3% by month 10, then
-- stays roughly flat (about 2 to 2.9%) to age 35. 30+ days late stays at
-- 0.05% to 0.1%. Ages past about 35 have thin data (under 3,000 records);
-- raise the HAVING cutoff (e.g. to 5000) to hide them.
--
-- Boundary note: age <= term counts the last scheduled month as in term. Whether
-- the last instalment falls at age term-1 or term depends on how the source
-- numbers its months, so this can shift one month per loan. It does not change
-- the finding.
-- ---------------------------------------------------------------------
WITH loan_span AS (
    SELECT
        sk_id_prev,
        MIN(months_balance)  AS first_month,
        MAX(months_balance)  AS last_month,
        COUNT(*)             AS months_recorded,
        MAX(cnt_instalment)  AS term
    FROM delinquency_history
    GROUP BY sk_id_prev
),
clean_loans AS (
    SELECT sk_id_prev, first_month, term
    FROM loan_span
    WHERE first_month > -96
      AND months_recorded = last_month - first_month + 1
      AND term IS NOT NULL
)
SELECT
    d.months_balance - c.first_month                                    AS loan_age_months,
    COUNT(*)                                                            AS loans_observed,
    ROUND(100.0 * COUNT(*) FILTER (WHERE d.sk_dpd > 0)  / COUNT(*), 2)  AS pct_any_dpd,
    ROUND(100.0 * COUNT(*) FILTER (WHERE d.sk_dpd > 30) / COUNT(*), 2)  AS pct_dpd_30plus
FROM delinquency_history d
JOIN clean_loans c ON c.sk_id_prev = d.sk_id_prev
WHERE d.months_balance - c.first_month <= c.term
GROUP BY loan_age_months
HAVING COUNT(*) >= 1000
ORDER BY loan_age_months;


-- ---------------------------------------------------------------------
-- STEP 3. IN TERM vs PAST TERM: where does the serious delinquency sit?
-- in_term   = record at or before the loan's scheduled end
-- past_term = record after the scheduled end (the loan is still open)
--
-- Result:
--   in_term    8,048,269 records, 768,053 loans, 1.71% any DPD,  0.00% NPL
--   past_term    198,411 records,  60,596 loans, 31.64% any DPD, 27.85% NPL
-- About 2.4% of records and about 7.9% of loans are past term, and they carry
-- nearly all of the 90+ days overdue records.
-- ---------------------------------------------------------------------
WITH loan_span AS (
    SELECT
        sk_id_prev,
        MIN(months_balance)  AS first_month,
        MAX(months_balance)  AS last_month,
        COUNT(*)             AS months_recorded,
        MAX(cnt_instalment)  AS term
    FROM delinquency_history
    GROUP BY sk_id_prev
),
clean_loans AS (
    SELECT sk_id_prev, first_month, term
    FROM loan_span
    WHERE first_month > -96
      AND months_recorded = last_month - first_month + 1
      AND term IS NOT NULL
)
SELECT
    CASE WHEN d.months_balance - c.first_month <= c.term
         THEN 'in_term' ELSE 'past_term' END                            AS phase,
    COUNT(*)                                                            AS records,
    COUNT(DISTINCT d.sk_id_prev)                                        AS loans,
    ROUND(100.0 * COUNT(*) FILTER (WHERE d.sk_dpd > 0)  / COUNT(*), 2)  AS pct_any_dpd,
    ROUND(100.0 * COUNT(*) FILTER (WHERE d.sk_dpd > 90) / COUNT(*), 2)  AS pct_npl
FROM delinquency_history d
JOIN clean_loans c ON c.sk_id_prev = d.sk_id_prev
GROUP BY phase
ORDER BY phase;
