import os
import re
import json
import joblib
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import MultiLabelBinarizer, LabelEncoder
from sklearn.model_selection import cross_val_score

# ─── Paths ────────────────────────────────────────────────────────────────────
# Use absolute paths so the script works from any working directory
# (locally or when Render sets cwd to /opt/render/project/src/backend-ai/)
_HERE         = os.path.dirname(os.path.abspath(__file__))
_ROOT         = os.path.dirname(_HERE)          # one level up = project root

DATA_DIR      = os.path.join(_ROOT, "DataSet of Animals")
MODEL_PATH    = os.path.join(_HERE, "model.joblib")
ENCODERS_PATH = os.path.join(_HERE, "encoders.json")
INFO_OUT_PATH = os.path.join(_HERE, "data", "disease_info.json")

os.makedirs(os.path.join(_HERE, "data"), exist_ok=True)

# ─── Lookup maps ──────────────────────────────────────────────────────────────
SYMPTOM_MAP = {
    'loss of appetite': 'Appetite Loss',
    'reduced appetite': 'Appetite Loss',
    'appetite loss': 'Appetite Loss',
    'decreased milk yield': 'Decreased Milk Yield',
    'reduced milk production': 'Decreased Milk Yield',
    'reduced mobility': 'Lameness',
    'lameness': 'Lameness',
    'reduced wool growth': 'Reduced Wool Production',
    'reduced wool production': 'Reduced Wool Production',
    'swollen legs': 'Swollen Legs',
    'swollen joints': 'Swollen Joints',
    'skin lesions': 'Skin Lesions',
    'nasal discharge': 'Nasal Discharge',
    'eye discharge': 'Eye Discharge',
    'coughing': 'Coughing',
    'vomiting': 'Vomiting',
    'diarrhea': 'Diarrhea',
    'fever': 'Fever',
    'lethargy': 'Lethargy',
    'sneezing': 'Sneezing',
    'dehydration': 'Dehydration',
    'weight loss': 'Weight Loss',
    'labored breathing': 'Labored Breathing',
    'swelling': 'Swelling',
    'nesting': 'Nesting Behavior',
    'restless': 'Restless Behavior',
    'aggressive': 'Aggressive Behavior',
    'increased appetite': 'Increased Appetite',
    'clear': 'Clear Vaginal Discharge',
    'bloody': 'Bloody Vaginal Discharge',
    'detected': 'Fetal Heart Sound Detected',
}

DISEASE_MAP = {
    'blue tongue': 'Bluetongue',
    'blue tongue disease': 'Bluetongue',
    'blue tongue virus': 'Bluetongue',
    'bluetongue virus': 'Bluetongue',
    'bovine respiratory disease complex': 'Bovine Respiratory Disease',
    'caprine arthritis': 'Caprine Arthritis Encephalitis',
    'caprine arthritis encephalitis virus': 'Caprine Arthritis Encephalitis',
    'caprine viral arthritis': 'Caprine Arthritis Encephalitis',
    'equine influenza virus': 'Equine Influenza',
    'feline chlamydiosis': 'Feline Chlamydia',
    'feline leukemia virus': 'Feline Leukemia',
    'feline panleukopenia virus': 'Feline Panleukopenia',
    'feline viral rhinotracheitis': 'Feline Rhinotracheitis',
    'foot-and-mouth disease': 'Foot and Mouth Disease',
    'rabbit viral hemorrhagic disease': 'Rabbit Hemorrhagic Disease',
    'viral hemorrhagic disease': 'Rabbit Hemorrhagic Disease',
    'scrapie disease': 'Scrapie',
    'porcine epidemic diarrhea virus': 'Porcine Epidemic Diarrhea',
}

# Correct species-specific healthy vitals
HEALTHY_VITALS = {
    'Dog':    {'temp': 38.5, 'hr': 90},
    'Cat':    {'temp': 38.6, 'hr': 150},
    'Cow':    {'temp': 38.5, 'hr': 60},
    'Horse':  {'temp': 37.8, 'hr': 36},
    'Rabbit': {'temp': 39.0, 'hr': 200},
    'Sheep':  {'temp': 39.0, 'hr': 75},
    'Goat':   {'temp': 39.0, 'hr': 80},
    'Pig':    {'temp': 39.0, 'hr': 70},
}

DEFAULT_TEMP = {k: v['temp'] for k, v in HEALTHY_VITALS.items()}


# ─── Helpers ──────────────────────────────────────────────────────────────────
def clean_temp(val):
    if pd.isna(val):
        return None
    val_str = str(val).upper()
    match = re.search(r'([0-9\.]+)', val_str)
    if not match:
        return None
    num = float(match.group(1))
    if 'F' in val_str or num > 50:
        num = (num - 32) * 5 / 9
    return round(num, 2)


# ─── Data loading ─────────────────────────────────────────────────────────────
def load_data():
    records = []

    # 1. Main disease dataset (cleaned_animal_disease_prediction.csv)
    df_dis = pd.read_csv(
        os.path.join(DATA_DIR, "cleaned_animal_disease_prediction.csv")
    )
    for _, row in df_dis.iterrows():
        species = row['Animal_Type'].strip()
        active = []

        binary_cols = {
            'Appetite_Loss': 'Appetite Loss',
            'Vomiting': 'Vomiting',
            'Diarrhea': 'Diarrhea',
            'Coughing': 'Coughing',
            'Labored_Breathing': 'Labored Breathing',
            'Lameness': 'Lameness',
            'Skin_Lesions': 'Skin Lesions',
            'Nasal_Discharge': 'Nasal Discharge',
            'Eye_Discharge': 'Eye Discharge',
        }
        for col, sym in binary_cols.items():
            if str(row[col]).strip().lower() == 'yes':
                active.append(sym)

        for col in ['Symptom_1', 'Symptom_2', 'Symptom_3', 'Symptom_4']:
            s = str(row[col]).strip().lower() if not pd.isna(row[col]) else ''
            if s in SYMPTOM_MAP:
                active.append(SYMPTOM_MAP[s])

        temp = clean_temp(row['Body_Temperature'])
        records.append({
            'species': species,
            'disease': DISEASE_MAP.get(
                str(row['Disease_Prediction']).strip().lower(),
                str(row['Disease_Prediction']).strip().title(),
            ),
            'temp': temp if temp else DEFAULT_TEMP.get(species, 38.5),
            'hr': float(row['Heart_Rate']) if not pd.isna(row['Heart_Rate'])
                  else HEALTHY_VITALS.get(species, {}).get('hr', 90),
            'symptoms': list(set(active)),
        })

    # 2. Pregnancy dataset (Animal_Vet_Pregnancy.xlsx)
    df_preg = pd.read_excel(
        os.path.join(DATA_DIR, "Animal_Vet_Pregnancy.xlsx")
    )
    preg_count = 0
    for _, row in df_preg.iterrows():
        if str(row['Pregnancy_Status']).strip().lower() != 'yes':
            continue
        species = row['Species'].strip()
        active = []

        if str(row['Vomiting']).strip().lower() == 'yes':
            active.append('Vomiting')

        app = str(row['Appetite_Change']).strip().lower()
        if app == 'increased':
            active.append('Increased Appetite')
        elif app == 'decreased':
            active.append('Appetite Loss')

        beh = str(row['Behavior_Change']).strip().lower()
        if beh == 'nesting':
            active.append('Nesting Behavior')
        elif beh == 'restless':
            active.append('Restless Behavior')
        elif beh == 'aggressive':
            active.append('Aggressive Behavior')
        elif beh == 'lethargic':
            active.append('Lethargy')

        disc = str(row['Discharge_Type']).strip().lower()
        if disc == 'clear':
            active.append('Clear Vaginal Discharge')
        elif disc == 'bloody':
            active.append('Bloody Vaginal Discharge')

        if str(row['Fetal_Heart_Sound']).strip().lower() == 'detected':
            active.append('Fetal Heart Sound Detected')

        temp = clean_temp(row['Body_Temperature_F'])
        records.append({
            'species': species,
            'disease': 'Pregnancy',
            'temp': temp if temp else DEFAULT_TEMP.get(species, 38.5),
            'hr': HEALTHY_VITALS.get(species, {}).get('hr', 100),
            'symptoms': list(set(active)),
        })
        preg_count += 1

    print(f"Loaded {preg_count} positive pregnancy records.")

    # 3. Healthy baselines — species-specific correct vitals
    for species, vitals in HEALTHY_VITALS.items():
        for _ in range(15):
            records.append({
                'species': species,
                'disease': 'Healthy / No Disease',
                'temp': vitals['temp'],
                'hr': vitals['hr'],
                'symptoms': [],
            })

    return pd.DataFrame(records)


# ─── Training ─────────────────────────────────────────────────────────────────
def train():
    df = load_data()
    print(f"Total training records : {len(df)}")
    print(f"Unique disease classes  : {df['disease'].nunique()}")

    le_species = LabelEncoder()
    df['species_enc'] = le_species.fit_transform(df['species'])

    mlb = MultiLabelBinarizer()
    sym_enc = mlb.fit_transform(df['symptoms'])
    sym_cols = [f"sym_{s}" for s in mlb.classes_]
    df_sym = pd.DataFrame(sym_enc, columns=sym_cols, index=df.index)

    X = pd.concat([df[['species_enc', 'temp', 'hr']], df_sym], axis=1)

    le_disease = LabelEncoder()
    y = le_disease.fit_transform(df['disease'])

    rf = RandomForestClassifier(
        n_estimators=200,
        max_depth=20,
        min_samples_split=2,
        random_state=42,
        n_jobs=-1,
    )
    rf.fit(X, y)

    scores = cross_val_score(rf, X, y, cv=5)
    print(f"5-Fold CV Accuracy: {scores.mean()*100:.2f}% ± {scores.std()*100:.2f}%")

    joblib.dump(rf, MODEL_PATH)
    encoders = {
        'species':       le_species.classes_.tolist(),
        'disease':       le_disease.classes_.tolist(),
        'symptoms':      mlb.classes_.tolist(),
        'feature_names': X.columns.tolist(),
    }
    with open(ENCODERS_PATH, 'w') as f:
        json.dump(encoders, f, indent=2)

    _build_disease_info()
    print("Training complete — model.joblib + encoders.json + data/disease_info.json saved.")


# ─── Disease info card builder ────────────────────────────────────────────────
def _build_disease_info():
    """Reads Animal disease spreadsheet and writes data/disease_info.json."""
    df_info = pd.read_csv(
        os.path.join(DATA_DIR, "Animal disease spreadsheet - Sheet1.csv")
    )
    info_map = {}
    for _, row in df_info.iterrows():
        name = row.get('Unnamed: 0')
        if pd.isna(name):
            continue
        info_map[str(name).strip().title()] = {
            'description': str(row.get('Description', '')).strip(),
            'treatment':   str(row.get('Treatment', '')).strip(),
            'prevention':  str(row.get('Advice/ Prevention', '')).strip(),
        }

    # Manual entries for special classes
    info_map['Pregnancy'] = {
        'description': (
            'Your pet may be pregnant. Gestation is ~63 days for dogs/cats. '
            'Watch for mammary gland enlargement and nesting behavior.'
        ),
        'treatment': (
            'Provide high-quality nutrition, a quiet whelping area, and schedule '
            'a vet ultrasound for confirmation.'
        ),
        'prevention': (
            'Spaying prevents unwanted pregnancies and reduces the risk of uterine cancer.'
        ),
    }
    info_map['Healthy / No Disease'] = {
        'description': 'Your pet appears healthy with no significant symptoms detected.',
        'treatment':   'Continue regular vet checkups, vaccinations, and a balanced diet.',
        'prevention':  'Annual health checkups, flea/tick control, and proper nutrition.',
    }

    with open(INFO_OUT_PATH, 'w') as f:
        json.dump(info_map, f, indent=2)
    print(f"Disease info saved to {INFO_OUT_PATH} ({len(info_map)} entries).")


if __name__ == "__main__":
    train()
