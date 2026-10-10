"""
One-time bulk load of the three Kaggle CSVs into staging tables in PostgreSQL.

Each file is read with pandas, column names are lower-cased (Kaggle headers are
upper case), and the result is written to a staging table, replacing it if it
already exists. The SQL files in this folder then copy the staging data into
the real tables.

Staging tables created here, with the row counts I got:
    staging_application_train       307,511
    staging_installments_payments   13,605,401
    staging_pos_cash_balance        10,001,358

Edit CSV_DIR below, then run:   python 00_load_staging_tables.py
Needs: pandas, sqlalchemy, psycopg2-binary
"""
import os
import pandas as pd
from sqlalchemy import create_engine

CSV_DIR = r"C:\path\to\home-credit-default-risk"   # <-- edit this

# Local PostgreSQL with trust authentication (no password in the connection string)
db_user = "postgres"
db_host = "localhost"
db_port = "5432"
db_name = "home_credit"

engine = create_engine(f"postgresql+psycopg2://{db_user}@{db_host}:{db_port}/{db_name}")


def load_csv(file_name, table_name, chunksize):
    df = pd.read_csv(os.path.join(CSV_DIR, file_name))
    df.columns = df.columns.str.lower()
    df.to_sql(table_name, engine, if_exists="replace", index=False, chunksize=chunksize)
    print(f"{table_name}: rows loaded: {len(df)}")


load_csv("application_train.csv",     "staging_application_train",     chunksize=5000)
load_csv("installments_payments.csv", "staging_installments_payments", chunksize=10000)
load_csv("POS_CASH_balance.csv",      "staging_pos_cash_balance",      chunksize=10000)
