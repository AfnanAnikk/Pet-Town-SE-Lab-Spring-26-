import os
import json
import joblib
import pandas as pd
import numpy as np
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
from sklearn.metrics.pairwise import cosine_similarity

app = FastAPI(title="Ultra-Lightweight Pet Vet AI Gateway", version="3.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

_HERE = os.path.dirname(os.path.abspath(__file__))
ASSETS_DIR = os.path.join(_HERE, "assets")

# Instantaneous asset registration
model = joblib.load(os.path.join(ASSETS_DIR, "model.joblib"))
vectorizer = joblib.load(os.path.join(ASSETS_DIR, "tfidf_vectorizer.joblib"))
tfidf_matrix = joblib.load(os.path.join(ASSETS_DIR, "tfidf_matrix.joblib"))

with open(os.path.join(ASSETS_DIR, "encoders.json")) as f: encoders = json.load(f)
with open(os.path.join(ASSETS_DIR, "disease_info.json")) as f: disease_info = json.load(f)
with open(os.path.join(ASSETS_DIR, "text_labels.json")) as f: text_labels = json.load(f)

master_symptoms = encoders["symptoms"]

class TextRequest(BaseModel):
    text: str

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

def get_urgency(disease_name: str) -> str:
    name_lower = disease_name.lower()
    if any(c in name_lower for c in ["parvovirus", "rabies", "bloat", "anthrax", "foot and mouth"]): return "Emergency"
    if any(m in name_lower for m in ["healthy", "pregnancy"]): return "Monitor"
    return "Schedule Vet Visit"

@app.post("/extract-symptoms")
def extract_symptoms(req: TextRequest):
    """Translates free text into matching checkboxes instantly using zero deep learning frameworks."""
    if not req.text.strip(): return {"matched_symptoms": []}
    
    user_query = req.text.lower()
    detected = []
    
    # Layer 1: Check for explicit substring inclusions
    for sym in master_symptoms:
        if sym.lower() in user_query and sym not in detected:
            detected.append(sym)
            
    # Layer 2: Sparse Vector Math Cosine Matching
    query_vector = vectorizer.transform([user_query])
    similarities = cosine_similarity(query_vector, tfidf_matrix)[0]
    
    # Isolate top vocab matches
    top_indices = np.argsort(similarities)[::-1][:5]
    for idx in top_indices:
        if similarities[idx] > 0.28:  # Optimized relevance baseline matching threshold
            matched_label = text_labels[idx]
            if matched_label in master_symptoms and matched_label not in detected:
                detected.append(matched_label)
                
    return {"matched_symptoms": detected}

@app.post("/predict", response_model=List[PredictResult])
def predict(req: PredictRequest):
    try:
        species_list = encoders["species"]
        sp_enc = species_list.index(req.animal_type) if req.animal_type in species_list else 0

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
            if conf < 5.0: continue
            name = encoders["disease"][idx]
            info = disease_info.get(name, {})
            results.append(
                PredictResult(
                    disease=name, confidence=conf, urgency=get_urgency(name),
                    description=info.get("description", "No details available."),
                    treatment=info.get("treatment", "Consult a vet."),
                    prevention=info.get("prevention", "Maintain general hygiene care.")
                )
            )
        return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))