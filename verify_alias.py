import json, sys, os
sys.path.insert(0, r'backend-ai')

# Load main.py inline info and check coverage for the unaliased diseases
main_py = open(r'backend-ai/main.py', encoding='utf-8').read()

# Extract INLINE_INFO keys by checking which disease names are in the dict
disease_info = json.load(open(r'backend-ai/assets/disease_info.json'))

# These diseases now fall through alias to INLINE_INFO
now_need_inline = [
    'Rabbit Hemorrhagic Disease', 'Rabbit Calicivirus', 'Rabbit Syphilis',
    'Equine Pneumonia', 'Caprine Respiratory Disease',
    'Porcine Respiratory Disease Complex', 'Feline Coronavirus',
    'Feline Asthma', 'Chronic Bronchitis', 'Hyperthyroidism',
    'Equine Arthritis', 'Pneumonia',
]

print("Coverage check for unaliased diseases:")
for d in now_need_inline:
    in_inline = f'"{d}": {{' in main_py or f"'{d}': {{" in main_py
    in_disease_info_real = d in disease_info and not disease_info[d].get('description','').startswith('Clinical medical condition.')
    status = 'INLINE_INFO' if in_inline else ('DISEASE_INFO(real)' if in_disease_info_real else 'NEEDS_INLINE_INFO!')
    print(f'  [{status:20}] {d}')
