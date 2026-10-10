"""
Column screening on application_train (run after 00_load_staging_tables.py).

For every numeric column in staging_application_train this prints:
  - the share of values that are missing
  - the correlation with the default flag (target)
sorted by the size of the correlation.

This is a plain linear check. It can't rule out a relationship that isn't
a straight line, so I read it alongside the domain-relevance filter described
in the README, not instead of it.
"""
import pandas as pd
from sqlalchemy import create_engine

engine = create_engine("postgresql+psycopg2://postgres@localhost:5432/home_credit")
df = pd.read_sql("SELECT * FROM staging_application_train", engine)

numeric_cols = df.select_dtypes(include='number').columns.drop('target')

results = []
for col in numeric_cols:
    missing_pct = df[col].isna().mean() * 100
    correlation = df[col].corr(df['target'])
    results.append({
        'column': col,
        'missing_%': round(missing_pct, 1),
        'correlation_with_target': round(correlation, 4),
    })

summary = pd.DataFrame(results).sort_values('correlation_with_target', key=abs, ascending=False)
print(summary.to_string())
