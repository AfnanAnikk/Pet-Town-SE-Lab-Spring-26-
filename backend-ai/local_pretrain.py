import os
import re
import json
import joblib
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.preprocessing import MultiLabelBinarizer, LabelEncoder

# Set paths based on your workspace setup
DATA_DIR = "./DataSet of Animals" 
OUTPUT_DIR = "./assets"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Standardized Master Symptom Vocabulary mapping keys
SYMPTOM_MAP = {
    'loss of appetite': 'Appetite Loss', 'reduced appetite': 'Appetite Loss', 'appetite loss': 'Appetite Loss',
    'decreased milk yield': 'Decreased Milk Yield', 'reduced milk production': 'Decreased Milk Yield',
    'reduced mobility': 'Lameness', 'lameness': 'Lameness', 'limping': 'Lameness', 'swollen legs': 'Swollen Legs',
    'fever': 'Fever', 'lethargy': 'Lethargy', 'vomiting': 'Vomiting', 'diarrhea': 'Diarrhea', 'coughing': 'Coughing',
    'sneezing': 'Sneezing', 'eye discharge': 'Eye Discharge', 'nasal discharge': 'Nasal Discharge',
    'labored breathing': 'Labored Breathing', 'skin lesions': 'Skin Irritations', 'skin irritations': 'Skin Irritations',
    'parasites': 'Parasites', 'ear infections': 'Ear Infections', 'mobility problems': 'Lameness', 'digestive issues': 'Digestive Issues'
}

HEALTHY_VITALS = {
    'Dog': {'temp': 38.5, 'hr': 85}, 'Cat': {'temp': 38.6, 'hr': 120}, 'Cow': {'temp': 38.5, 'hr': 60},
    'Horse': {'temp': 38.0, 'hr': 36}, 'Rabbit': {'temp': 39.2, 'hr': 200}, 'Sheep': {'temp': 39.0, 'hr': 75},
    'Goat': {'temp': 39.1, 'hr': 80}, 'Pig': {'temp': 39.2, 'hr': 70}, 'Ferret': {'temp': 38.8, 'hr': 220}
}

def clean_temp(val):
    if pd.isna(val): return None
    val_str = str(val).upper()
    match = re.search(r'([0-9\.]+)', val_str)
    if not match: return None
    num = float(match.group(1))
    if 'F' in val_str or num > 50:  # If explicitly Fahrenheit or an un-stripped F value
        num = (num - 32) * 5 / 9
    return round(num, 2)

def build_and_train():
    records = []
    text_corpus = []
    text_labels = []
    
    # ── 1. PRIMARY CLEANED DISEASE PREDICTION CSV ───────────────────────────
    p1 = os.path.join(DATA_DIR, "cleaned_animal_disease_prediction.csv")
    if os.path.exists(p1):
        df = pd.read_csv(p1)
        for _, row in df.iterrows():
            species = str(row.get('Animal_Type', 'Dog')).strip()
            disease = str(row.get('Disease_Prediction', 'Healthy / No Disease')).strip()
            temp = clean_temp(row.get('Body_Temperature')) or HEALTHY_VITALS.get(species, {'temp':38.5})['temp']
            hr = pd.to_numeric(row.get('Heart_Rate'), errors='coerce') or HEALTHY_VITALS.get(species, {'hr':85})['hr']
            
            active = []
            for col in ['Appetite_Loss','Vomiting','Diarrhea','Coughing','Labored_Breathing','Lameness','Skin_Lesions','Nasal_Discharge','Eye_Discharge']:
                if str(row.get(col, '')).strip().lower() == 'yes' and col.lower() in SYMPTOM_MAP:
                    active.append(SYMPTOM_MAP[col.lower()])
            for s_col in ['Symptom_1','Symptom_2','Symptom_3','Symptom_4']:
                s_val = str(row.get(s_col, '')).strip().lower()
                if s_val in SYMPTOM_MAP:
                    active.append(SYMPTOM_MAP[s_val])
            records.append({'species': species, 'disease': disease, 'temp': float(temp), 'hr': float(hr), 'symptoms': list(set(active))})

    # ── 2. PREGNANCY EXCEL SOURCE ───────────────────────────────────────────
    p2 = os.path.join(DATA_DIR, "Animal_Vet_Pregnancy.xlsx - animal_vet_data3.csv")
    if os.path.exists(p2):
        df_preg = pd.read_csv(p2)
        for _, row in df_preg.iterrows():
            if str(row.get('Pregnancy_Status', '')).strip().lower() != 'yes': continue
            species = str(row.get('Species', 'Dog')).strip()
            temp_f = pd.to_numeric(row.get('Body_Temperature_F'), errors='coerce')
            temp = round((temp_f - 32) * 5 / 9, 2) if not pd.isna(temp_f) else HEALTHY_VITALS.get(species, {'temp':38.5})['temp']
            hr = HEALTHY_VITALS.get(species, {'hr':85})['hr']
            
            active = []
            if str(row.get('Vomiting','')).strip().lower() == 'yes': active.append('Vomiting')
            b_change = str(row.get('Behavior_Change','')).strip().lower()
            if 'nesting' in b_change: active.append('Nesting Behavior')
            elif 'restless' in b_change: active.append('Restless Behavior')
            
            records.append({'species': species, 'disease': 'Pregnancy', 'temp': float(temp), 'hr': float(hr), 'symptoms': list(set(active))})

    # ── 3. VET TEXT DATASET (NLP TRANSLATION BRIDGE) ────────────────────────
    p3 = os.path.join(DATA_DIR, "pet-health-symptoms-dataset.csv")
    if os.path.exists(p3):
        df_ph = pd.read_csv(p3)
        for _, row in df_ph.iterrows():
            text_str = str(row.get('text', '')).strip().lower()
            condition_tag = str(row.get('condition', '')).strip()
            record_type = str(row.get('record_type', '')).strip()
            mapped_symptom = SYMPTOM_MAP.get(condition_tag.lower(), condition_tag)
            
            # Populate text corpus vocabulary with BOTH owner and vet phrasing strings
            text_corpus.append(text_str)
            text_labels.append(mapped_symptom)
            
            # STRICT GUARDRAIL: Only allow verified clinical veterinary notes to train the Random Forest
            if record_type != "Clinical Notes": continue
            
            species = 'Dog'
            if 'cat' in text_str or 'feline' in text_str: species = 'Cat'
            elif 'horse' in text_str or 'equine' in text_str: species = 'Horse'
            
            active = [mapped_symptom]
            if 'vomit' in text_str or 'emesis' in text_str: active.append('Vomiting')
            if 'diarrhea' in text_str: active.append('Diarrhea')
            records.append({
                'species': species, 'disease': mapped_symptom,
                'temp': HEALTHY_VITALS.get(species, {'temp':38.5})['temp'],
                'hr': HEALTHY_VITALS.get(species, {'hr':85})['hr'],
                'symptoms': list(set(active))
            })

    # ── 4. CONTROL BASELINES FOR HEALTHY ANIMALS ────────────────────────────
    for sp, vitals in HEALTHY_VITALS.items():
        for _ in range(30):
            records.append({'species': sp, 'disease': 'Healthy / No Disease', 'temp': vitals['temp'], 'hr': vitals['hr'], 'symptoms': []})

    # --- TF-IDF REPLACEMENT VECTORIZER ---
    print("Fitting text extraction vectorizer matrix...")
    vectorizer = TfidfVectorizer(ngram_range=(1, 2), stop_words='english', max_features=2000)
    tfidf_matrix = vectorizer.fit_transform(text_corpus)
    
    joblib.dump(vectorizer, os.path.join(OUTPUT_DIR, "tfidf_vectorizer.joblib"))
    joblib.dump(tfidf_matrix, os.path.join(OUTPUT_DIR, "tfidf_matrix.joblib"))
    with open(os.path.join(OUTPUT_DIR, "text_labels.json"), "w") as f:
        json.dump(text_labels, f)

    # --- MODEL CORE MACHINE LEARNING BRAIN ---
    df_master = pd.DataFrame(records)
    le_sp = LabelEncoder()
    df_master['species_enc'] = le_sp.fit_transform(df_master['species'])
    
    mlb = MultiLabelBinarizer()
    sym_enc = mlb.fit_transform(df_master['symptoms'])
    sym_cols = [f"sym_{s}" for s in mlb.classes_]
    df_sym = pd.DataFrame(sym_enc, columns=sym_cols, index=df_master.index)
    
    X = pd.concat([df_master[['species_enc', 'temp', 'hr']], df_sym], axis=1)
    le_dis = LabelEncoder()
    y = le_dis.fit_transform(df_master['disease'])
    
    # 300 Trees for max predictive capability. Split restrictions prevent memorization.
    print("Training optimized Random Forest Core...")
    rf = RandomForestClassifier(
        n_estimators=300, 
        max_depth=30, 
        min_samples_split=5, 
        min_samples_leaf=2, 
        random_state=42, 
        n_jobs=-1
    )
    rf.fit(X, y)
    
    from sklearn.model_selection import cross_val_score
    print(f"Verified Model Generalization Score: {round(cross_val_score(rf, X, y, cv=3).mean() * 100, 2)}%")
    joblib.dump(rf, os.path.join(OUTPUT_DIR, "model.joblib"))
    
    encoders_json = {
        "species": le_sp.classes_.tolist(), "disease": le_dis.classes_.tolist(),
        "symptoms": mlb.classes_.tolist(), "feature_names": X.columns.tolist()
    }
    with open(os.path.join(OUTPUT_DIR, "encoders.json"), "w") as f:
        json.dump(encoders_json, f, indent=2)

    # --- PULL THE ENCYCLOPEDIA METRICS ---
    info_map = {}
    p4 = os.path.join(DATA_DIR, "Animal disease spreadsheet - Sheet1.csv")
    if os.path.exists(p4):
        df_info = pd.read_csv(p4)
        for _, row in df_info.iterrows():
            name = row.get('Unnamed: 0')
            if pd.isna(name): continue
            info_map[str(name).strip().title()] = {
                'description': str(row.get('Description', '')).strip(),
                'treatment': str(row.get('Treatment', '')).strip(),
                'prevention': str(row.get('Advice/ Prevention', '')).strip(),
            }
            
    # Add target safety fallbacks
    for d in encoders_json["disease"]:
        if d not in info_map:
            info_map[d] = {'description': 'Clinical medical condition.', 'treatment': 'Consult a veterinarian for detailed systemic tracking.', 'prevention': 'Maintain diagnostic tracking and clear habitat management protocols.'}
            
    with open(os.path.join(OUTPUT_DIR, "disease_info.json"), "w") as f:
        json.dump(info_map, f, indent=2)
    print("Pre-training successfully complete. Commit the 'assets' folder to GitHub for Render deployment.")

if __name__ == "__main__":
    build_and_train()