"""Credit-risk scoring API: serves the tuned LightGBM from 06_ml_phase.

Run locally:  uvicorn main:app --reload
Docs page:    http://127.0.0.1:8000/docs
"""
import json
from pathlib import Path
from typing import Any, Dict

import joblib
import numpy as np
import pandas as pd
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

MODEL_DIR = Path(__file__).resolve().parent / "model"
model = joblib.load(MODEL_DIR / "lgbm.joblib")
schema = json.loads((MODEL_DIR / "schema.json").read_text())

FEATURES = schema["features"]              # exact training column order (130)
CATEGORICAL = schema["categorical"]        # column -> allowed levels
PAYMENT_FEATURES = schema["payment_features"]
DECILE_CUTS = schema["decile_cuts"]        # 9 probability cut points from the test set
PLACEHOLDER_DAYS_EMPLOYED = 365243         # same cleanup as the notebook

# Not accepted as input (fair-lending concern, see README "Limits of the ML Phase").
BLOCKED = {"code_gender"}

app = FastAPI(
    title="Credit Risk Scoring API",
    description=(
        "Demo only. Trained on the public Home Credit dataset with anonymised "
        "external scores. Not for real lending decisions."
    ),
    version="1.0.0",
)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])


class PredictRequest(BaseModel):
    features: Dict[str, Any] = Field(
        ...,
        description="Any subset of the model's input columns. Omitted ones are treated as missing.",
        examples=[{"ext_source_2": 0.35, "ext_source_3": 0.4, "amt_credit": 500000,
                   "amt_income_total": 150000, "days_birth": -12000}],
    )
    explain: bool = Field(True, description="Include the top 3 drivers of this score.")


def build_frame(inputs: Dict[str, Any]) -> pd.DataFrame:
    unknown = sorted(set(inputs) - set(FEATURES))
    if unknown:
        raise HTTPException(422, f"Unknown feature(s): {unknown}. See GET /schema.")
    blocked = sorted(set(inputs) & BLOCKED)
    if blocked:
        raise HTTPException(422, f"Feature(s) not accepted by this API: {blocked}.")

    row = {c: np.nan for c in FEATURES}
    for name, value in inputs.items():
        if value is None:
            continue
        if name in CATEGORICAL:
            if value not in CATEGORICAL[name]:
                raise HTTPException(422, f"'{value}' is not a valid level for {name}. "
                                         f"Allowed: {CATEGORICAL[name]}")
            row[name] = value
        else:
            try:
                row[name] = float(value)
            except (TypeError, ValueError):
                raise HTTPException(422, f"{name} must be a number, got {value!r}.")

    if row["days_employed"] == PLACEHOLDER_DAYS_EMPLOYED:
        row["days_employed"] = np.nan

    df = pd.DataFrame([row], columns=FEATURES)
    for col, levels in CATEGORICAL.items():
        df[col] = pd.Categorical(df[col], categories=levels)
    return df


@app.get("/health")
def health():
    return {"status": "ok", "model_test_auc": schema.get("test_auc")}


@app.get("/schema")
def get_schema():
    return {
        "features": FEATURES,
        "categorical_levels": CATEGORICAL,
        "payment_features": PAYMENT_FEATURES,
        "not_accepted": sorted(BLOCKED),
    }


@app.post("/predict")
def predict(req: PredictRequest):
    df = build_frame(req.features)
    p = float(model.predict_proba(df)[:, 1][0])
    decile = 10 - int(np.searchsorted(DECILE_CUTS, p))   # 1 = riskiest 10%, 10 = safest

    out = {
        "default_probability": round(p, 4),
        "risk_decile": decile,
        "inputs_provided": len([v for v in req.features.values() if v is not None]),
        "inputs_expected": len(FEATURES) - len(BLOCKED),
    }
    if out["inputs_provided"] < 5:
        out["warning"] = "Very few inputs provided; the score is less reliable."

    if req.explain:
        contrib = model.booster_.predict(df, pred_contrib=True)[0][:-1]  # last value = baseline
        order = [i for i in np.argsort(-np.abs(contrib)) if FEATURES[i] not in BLOCKED][:3]
        out["top_drivers"] = [
            {
                "feature": FEATURES[i],
                "value": None if pd.isna(df.iloc[0, i]) else (
                    df.iloc[0, i] if FEATURES[i] in CATEGORICAL else float(df.iloc[0, i])),
                "effect": "raises risk" if contrib[i] > 0 else "lowers risk",
                "impact_log_odds": round(float(contrib[i]), 3),
            }
            for i in order
        ]
    return out
