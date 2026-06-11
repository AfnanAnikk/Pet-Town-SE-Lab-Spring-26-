import os
import json
import joblib
import pandas as pd
import numpy as np
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional

app = FastAPI(title="Pet Vet AI API", version="2.0.0")

# ── CORS — allow_credentials MUST be False when allow_origins=["*"] ──────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Absolute paths (works regardless of cwd on Render) ───────────────────────
_HERE         = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH    = os.path.join(_HERE, "model.joblib")
ENCODERS_PATH = os.path.join(_HERE, "encoders.json")
INFO_PATH     = os.path.join(_HERE, "data", "disease_info.json")

# Auto-train on first deploy if model files are missing
if not os.path.exists(MODEL_PATH):
    print("Model not found — running train.py …")
    from train import train
    train()

model = joblib.load(MODEL_PATH)
with open(ENCODERS_PATH) as f:
    encoders = json.load(f)
with open(INFO_PATH) as f:
    disease_info = json.load(f)

# ── Urgency classification ────────────────────────────────────────────────────
EMERGENCY_KW = [
    'parvovirus', 'distemper', 'bloat', 'tuberculosis',
    'rabies', 'septicemia', 'pneumonia', 'hemorrhagic',
]
MONITOR_KW = ['healthy', 'pregnancy']


def get_urgency(name: str) -> str:
    n = name.lower()
    if any(k in n for k in EMERGENCY_KW):
        return "Emergency"
    if any(k in n for k in MONITOR_KW):
        return "Monitor"
    return "Schedule Vet Visit"


# ── Request / Response schemas ────────────────────────────────────────────────
class PredictRequest(BaseModel):
    animal_type: str
    symptoms: List[str]
    temperature: Optional[float] = None
    heart_rate: Optional[float] = None


class PredictResult(BaseModel):
    disease: str
    confidence: float
    urgency: str
    description: str
    treatment: str
    prevention: str


# ── Endpoints ─────────────────────────────────────────────────────────────────
@app.get("/health")
def health():
    return {"status": "ok", "version": "2.0.0"}


@app.post("/predict", response_model=List[PredictResult])
def predict(req: PredictRequest):
    try:
        species_list = encoders["species"]
        sp_enc = (
            species_list.index(req.animal_type)
            if req.animal_type in species_list
            else 0
        )

        temp = req.temperature or 38.5
        hr   = req.heart_rate  or 85.0

        sym_list = encoders["symptoms"]
        sym_vec  = [1 if s in req.symptoms else 0 for s in sym_list]

        features = pd.DataFrame(
            [[sp_enc, temp, hr] + sym_vec],
            columns=encoders["feature_names"],
        )

        probs = model.predict_proba(features)[0]
        top3  = np.argsort(probs)[::-1][:3]

        results = []
        for idx in top3:
            conf = round(float(probs[idx]) * 100, 1)
            if conf < 5.0:
                continue
            name = encoders["disease"][idx]
            info = disease_info.get(name, {})
            results.append(
                PredictResult(
                    disease=name,
                    confidence=conf,
                    urgency=get_urgency(name),
                    description=info.get("description", "No details available."),
                    treatment=info.get("treatment", "Consult a vet."),
                    prevention=info.get("prevention", "Regular checkups recommended."),
                )
            )
        return results

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
