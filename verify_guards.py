"""
Quick verification that the guards in main.py work as intended.
Run from the project root: python verify_guards.py
"""
import json, joblib, pandas as pd, numpy as np, sys, os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'backend-ai'))

# Inline the two helper functions as they exist in main.py after the fix
VITALS_RANGES = {
    "Dog":    {"temp": (37.5, 39.5), "hr": (60, 180)},
    "Cat":    {"temp": (38.0, 39.5), "hr": (120, 240)},
    "Rabbit": {"temp": (38.5, 40.0), "hr": (120, 325)},
    "Horse":  {"temp": (37.0, 38.5), "hr": (28, 44)},
    "Cow":    {"temp": (38.0, 39.5), "hr": (40, 80)},
    "Sheep":  {"temp": (38.5, 40.0), "hr": (60, 120)},
    "Goat":   {"temp": (38.5, 40.0), "hr": (60, 120)},
    "Pig":    {"temp": (38.0, 40.0), "hr": (55, 100)},
    "Ferret": {"temp": (37.8, 40.0), "hr": (180, 250)},
}

_SPECIES_PREFIXES = {
    "Dog":    ["canine"],
    "Cat":    ["feline"],
    "Cow":    ["bovine"],
    "Horse":  ["equine"],
    "Pig":    ["porcine", "swine", "african swine"],
    "Goat":   ["caprine", "goat"],
    "Sheep":  ["ovine", "sheep", "scrapie", "maedi", "caseous"],
    "Rabbit": ["rabbit", "myxomatosis", "snuffles"],
    "Ferret": [],
}

_DISEASE_SPECIES_OVERRIDES = {
    "Mastitis":                      {"Cow", "Goat", "Sheep"},
    "Laminitis":                     {"Horse", "Goat", "Cow"},
    "Equine Laminitis":              {"Horse"},
    "Gastrointestinal Stasis":       {"Rabbit"},
    "Bluetongue":                    {"Sheep", "Goat", "Cow"},
    "Kennel Cough":                  {"Dog"},
    "Bordetella Infection":          {"Dog", "Cat", "Rabbit"},
    "Heartworm Disease":             {"Dog"},
    "Distemper":                     {"Dog"},
    "Foot and Mouth Disease":        {"Cow", "Sheep", "Goat", "Pig"},
    "Footrot":                       {"Sheep", "Goat", "Cow"},
    "Chlamydia in Sheep":            {"Sheep"},
    "Contagious Ecthyma":            {"Sheep", "Goat"},
    "Contagious Abortion":           {"Goat", "Sheep", "Cow"},
    "Actinobacillus Pleuropneumonia":{"Pig"},
    "Actinobacillus Suis":           {"Pig"},
    "African Swine Fever":           {"Pig"},
    "Hyperthyroidism":               {"Cat", "Dog"},
    "Snuffles":                      {"Rabbit"},
    "Rabbit Syphilis":               {"Rabbit"},
    "Rabbit Hemorrhagic Disease":    {"Rabbit"},
    "Myxomatosis":                   {"Rabbit"},
    "Cryptosporidiosis":             {"Cow", "Sheep", "Goat"},
}

def _is_disease_allowed_for_species(disease_name, species):
    if disease_name in _DISEASE_SPECIES_OVERRIDES:
        return species in _DISEASE_SPECIES_OVERRIDES[disease_name]
    d_lower = disease_name.lower()
    for sp, prefixes in _SPECIES_PREFIXES.items():
        for prefix in prefixes:
            if d_lower.startswith(prefix):
                return sp == species
    return True

def _vitals_are_abnormal(species, temperature, heart_rate):
    v = VITALS_RANGES.get(species, {})
    if temperature is not None and "temp" in v:
        lo, hi = v["temp"]
        if temperature < lo or temperature > hi:
            return True
    if heart_rate is not None and "hr" in v:
        lo, hi = v["hr"]
        if heart_rate < lo or heart_rate > hi:
            return True
    return False


assets_dir = r"C:\Users\MD. SHAFIUL BARI\Desktop\a\backend-ai\assets"
model = joblib.load(os.path.join(assets_dir, "model.joblib"))
with open(os.path.join(assets_dir, "encoders.json")) as f:
    encoders = json.load(f)

disease_list = encoders["disease"]
symptoms     = encoders["symptoms"]
species_list = encoders["species"]
feature_names = encoders["feature_names"]
vitals_ref    = encoders.get("healthy_vitals", {})


def predict_with_guards(animal, syms, temp=None, hr=None):
    sp_enc = species_list.index(animal)
    sv     = vitals_ref.get(animal, {"temp": 38.5, "hr": 85.0})
    t      = temp if temp is not None else sv["temp"]
    h      = hr   if hr   is not None else sv["hr"]

    sym_vec  = [1 if s in syms else 0 for s in symptoms]
    features = pd.DataFrame([[sp_enc, t, h] + sym_vec], columns=feature_names)
    probs    = model.predict_proba(features)[0]

    # Guard 1: Pregnancy
    pregnancy_indicators = {
        "Nesting Behavior", "Clear Vaginal Discharge", "Bloody Vaginal Discharge",
        "Purulent Vaginal Discharge", "Fetal Heart Sound Detected", "Increased Appetite",
    }
    if not any(s in syms for s in pregnancy_indicators):
        try:
            probs[disease_list.index("Pregnancy")] = 0.0
        except ValueError:
            pass

    # Guard 2: Healthy
    if syms or _vitals_are_abnormal(animal, temp, hr):
        try:
            probs[disease_list.index("Healthy / No Disease")] = 0.0
        except ValueError:
            pass

    # Guard 3: Species-disease filter
    for idx, dis in enumerate(disease_list):
        if not _is_disease_allowed_for_species(dis, animal):
            probs[idx] = 0.0

    # Normalise
    if probs.sum() > 0:
        probs = probs / probs.sum()

    top = np.argsort(probs)[::-1][:5]
    return [(disease_list[i], round(float(probs[i]) * 100, 1)) for i in top if probs[i] > 0]


# ── Verification tests ──────────────────────────────────────────────────────────
tests = [
    # (label, animal, symptoms, temp, hr, assertion_fn)
    (
        "Kennel Cough: Healthy must NOT be #1",
        "Dog", ["Coughing", "Nasal Discharge", "Sneezing"], 38.8, 95.0,
        lambda r: r[0][0] != "Healthy / No Disease",
    ),
    (
        "Laminitis: Healthy must NOT be #1",
        "Horse", ["Lameness", "Restless Behavior"], 38.0, 42.0,
        lambda r: r[0][0] != "Healthy / No Disease",
    ),
    (
        "Cat flu: Bovine disease must NOT appear in top-5",
        "Cat", ["Sneezing", "Eye Discharge", "Nasal Discharge", "Fever"], 39.4, 140.0,
        lambda r: all("bovine" not in n.lower() for n, _ in r),
    ),
    (
        "Dog: Bovine Tuberculosis must NOT appear",
        "Dog", ["Coughing", "Fever", "Weight Loss"], 39.0, 100.0,
        lambda r: all(n != "Bovine Tuberculosis" for n, _ in r),
    ),
    (
        "Healthy Dog: Healthy SHOULD be present",
        "Dog", [], 38.5, 85.0,
        lambda r: any(n == "Healthy / No Disease" for n, _ in r),
    ),
    (
        "Extreme vitals (no syms): Healthy must NOT be #1",
        "Dog", [], 41.0, 220.0,
        lambda r: r[0][0] != "Healthy / No Disease",
    ),
    (
        "Cow Mastitis: Mastitis should appear in top-3",
        "Cow", ["Decreased Milk Yield", "Swelling", "Fever"], 39.6, 80.0,
        lambda r: any(n == "Mastitis" for n, _ in r[:3]),
    ),
    (
        "Cat: Kennel Cough must NOT appear (dog-only)",
        "Cat", ["Coughing", "Nasal Discharge"], 38.5, 120.0,
        lambda r: all(n != "Kennel Cough" for n, _ in r),
    ),
]

print("=== Guard Verification Tests ===\n")
all_passed = True
for label, animal, syms, temp, hr, check_fn in tests:
    results = predict_with_guards(animal, syms, temp, hr)
    passed  = check_fn(results) if results else False
    status  = "PASS OK" if passed else "FAIL !!"
    if not passed:
        all_passed = False
    print(f"  [{status}] {label}")
    for name, conf in results[:3]:
        print(f"         {conf:5.1f}%  {name}")
    print()

print("=" * 50)
print("ALL TESTS PASSED" if all_passed else "SOME TESTS FAILED -- review output above")
