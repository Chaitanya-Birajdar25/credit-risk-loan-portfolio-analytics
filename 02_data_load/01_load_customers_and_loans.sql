-- =====================================================================
-- 02_data_load/01_load_customers_and_loans.sql
-- Fills customers and loans from staging_application_train.
-- Only 30 of the 122 source columns are kept (see README, "Column selection").
-- Expected: 307,511 rows in each table.
-- =====================================================================

INSERT INTO customers (
    sk_id_curr, code_gender, days_birth, cnt_children, cnt_fam_members,
    name_family_status, name_education_type, name_housing_type,
    flag_own_car, flag_own_realty, amt_income_total, name_income_type,
    occupation_type, organization_type, days_employed,
    ext_source_1, ext_source_2, ext_source_3,
    def_30_cnt_social_circle, def_60_cnt_social_circle,
    obs_30_cnt_social_circle, obs_60_cnt_social_circle,
    amt_req_credit_bureau_day, amt_req_credit_bureau_week,
    amt_req_credit_bureau_mon, amt_req_credit_bureau_qrt, amt_req_credit_bureau_year,
    region_population_relative, days_last_phone_change,
    reg_city_not_live_city, reg_city_not_work_city
)
SELECT
    sk_id_curr, code_gender, days_birth, cnt_children, cnt_fam_members,
    name_family_status, name_education_type, name_housing_type,
    flag_own_car, flag_own_realty, amt_income_total, name_income_type,
    occupation_type, organization_type, days_employed,
    ext_source_1, ext_source_2, ext_source_3,
    def_30_cnt_social_circle, def_60_cnt_social_circle,
    obs_30_cnt_social_circle, obs_60_cnt_social_circle,
    amt_req_credit_bureau_day, amt_req_credit_bureau_week,
    amt_req_credit_bureau_mon, amt_req_credit_bureau_qrt, amt_req_credit_bureau_year,
    region_population_relative, days_last_phone_change,
    reg_city_not_live_city, reg_city_not_work_city
FROM staging_application_train;

INSERT INTO loans (
    sk_id_curr, name_contract_type, amt_credit, amt_annuity,
    amt_goods_price, region_rating_client, target
)
SELECT
    sk_id_curr, name_contract_type, amt_credit, amt_annuity,
    amt_goods_price, region_rating_client, target
FROM staging_application_train;

-- Sanity check: row counts
SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM loans;
