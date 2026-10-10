-- =====================================================================
-- 01_schema/01_create_tables.sql
-- Creates the four tables: customers, loans, repayments, delinquency_history.
-- Run this first, on an empty database (e.g. home_credit).
-- =====================================================================

CREATE TABLE customers (
    sk_id_curr      INTEGER PRIMARY KEY,
    code_gender     VARCHAR(5),
    days_birth      INTEGER,
    cnt_children    INTEGER,
    cnt_fam_members NUMERIC(3,1),
    name_family_status  VARCHAR(30),
    name_education_type VARCHAR(50),
    name_housing_type   VARCHAR(30),
    flag_own_car    VARCHAR(1),
    flag_own_realty VARCHAR(1),
    amt_income_total NUMERIC(14,2),
    name_income_type VARCHAR(30),
    occupation_type   VARCHAR(50),
    organization_type VARCHAR(50),
    days_employed     INTEGER,
    ext_source_1      NUMERIC(10,8),
    ext_source_2      NUMERIC(10,8),
    ext_source_3      NUMERIC(10,8),
    def_30_cnt_social_circle NUMERIC(5,0),
    def_60_cnt_social_circle NUMERIC(5,0),
    obs_30_cnt_social_circle NUMERIC(5,0),
    obs_60_cnt_social_circle NUMERIC(5,0),
    amt_req_credit_bureau_day  NUMERIC(5,0),
    amt_req_credit_bureau_week NUMERIC(5,0),
    amt_req_credit_bureau_mon  NUMERIC(5,0),
    amt_req_credit_bureau_qrt  NUMERIC(5,0),
    amt_req_credit_bureau_year NUMERIC(5,0),
    region_population_relative NUMERIC(10,6),
    days_last_phone_change     INTEGER,
    reg_city_not_live_city     SMALLINT,
    reg_city_not_work_city     SMALLINT
);

CREATE TABLE loans (
    loan_id       SERIAL PRIMARY KEY,
    sk_id_curr    INTEGER REFERENCES customers(sk_id_curr),
    name_contract_type VARCHAR(30),
    amt_credit      NUMERIC(14,2),
    amt_annuity     NUMERIC(14,2),
    amt_goods_price NUMERIC(14,2),
    region_rating_client SMALLINT,
    target          SMALLINT      -- 1 = defaulted, 0 = repaid
);

CREATE TABLE repayments (
    repayment_id            SERIAL PRIMARY KEY,
    sk_id_prev               INTEGER,
    sk_id_curr                INTEGER REFERENCES customers(sk_id_curr),
    num_instalment_version    NUMERIC(5,1),
    num_instalment_number     INTEGER,
    days_instalment            INTEGER,
    days_entry_payment         INTEGER,
    amt_instalment              NUMERIC(14,2),
    amt_payment                  NUMERIC(14,2)
);

CREATE TABLE delinquency_history (
    delinquency_id      SERIAL PRIMARY KEY,
    sk_id_prev            INTEGER,
    sk_id_curr              INTEGER REFERENCES customers(sk_id_curr),
    months_balance           INTEGER,
    cnt_instalment             NUMERIC(5,0),
    cnt_instalment_future       NUMERIC(5,0),
    name_contract_status         VARCHAR(30),
    sk_dpd                        INTEGER,
    sk_dpd_def                     INTEGER
);
