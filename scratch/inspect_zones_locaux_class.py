import json

json_path = r'C:\Users\TeufackAndelson\.gemini\antigravity-ide\brain\408d6ca9-a8d2-4f02-9e1a-8741d90bf860\scratch\missions\mission_m_1788898451472923_110.json'
with open(json_path, 'r', encoding='utf-8') as f:
    m = json.load(f)

audit = m.get('audit', {})
mt_locaux = audit.get('moyenneTensionLocaux', [])
mt_zones = audit.get('moyenneTensionZones', [])
bt_zones = audit.get('basseTensionZones', [])

# All audit zones
all_audit_zones = []
for z in mt_zones:
    all_audit_zones.append({'domain': 'MT', 'nom': z.get('nom'), 'id': z.get('id')})
for z in bt_zones:
    all_audit_zones.append({'domain': 'BT', 'nom': z.get('nom'), 'id': z.get('id')})

print(f"Total Audit Zones: {len(all_audit_zones)} (MT: {len(mt_zones)}, BT: {len(bt_zones)})")

# All audit locaux
all_audit_locaux = []
for l in mt_locaux:
    all_audit_locaux.append({'domain': 'MT', 'nom': l.get('nom'), 'id': l.get('id'), 'parent': 'Direct MT'})
for z in mt_zones:
    for l in z.get('locaux', []):
        all_audit_locaux.append({'domain': 'MT', 'nom': l.get('nom'), 'id': l.get('id'), 'parent': z.get('nom')})
for z in bt_zones:
    for l in z.get('locaux', []):
        all_audit_locaux.append({'domain': 'BT', 'nom': l.get('nom'), 'id': l.get('id'), 'parent': z.get('nom'), 'type': l.get('type')})

print(f"Total Audit Locaux: {len(all_audit_locaux)} (MT: {len(mt_locaux) + sum(len(z.get('locaux', [])) for z in mt_zones)}, BT: {sum(len(z.get('locaux', [])) for z in bt_zones)})")

# Classement zones
cz = m.get('classements_zones', [])
print(f"\nTotal Classements Zones in DB: {len(cz)}")
cz_with_class = [z for z in cz if z.get('af') or z.get('be') or z.get('ip') or z.get('ik')]
print(f"Classements Zones with valid classification: {len(cz_with_class)}/{len(cz)}")

# Classement locaux
cl = m.get('classements_locaux', [])
print(f"\nTotal Classements Locaux in DB: {len(cl)}")
cl_locaux = [l for l in cl if l.get('typeEmplacement') == 'local']
cl_zones = [l for l in cl if l.get('typeEmplacement') == 'zone']
print(f"In classements_locaux: {len(cl_locaux)} marked typeEmplacement==local, {len(cl_zones)} marked typeEmplacement==zone")
cl_loc_with_class = [l for l in cl_locaux if l.get('af') or l.get('be') or l.get('ip') or l.get('ik')]
print(f"Classements Locaux with valid classification: {len(cl_loc_with_class)}/{len(cl_locaux)}")

# Check matching with audit entities
audit_zone_names = {z['nom'].strip().lower() for z in all_audit_zones if z['nom']}
audit_local_names = {l['nom'].strip().lower() for l in all_audit_locaux if l['nom']}

cz_matched = [z for z in cz if (z.get('nomZone') or '').strip().lower() in audit_zone_names]
print(f"\nCZ matching audit zone names: {len(cz_matched)}/{len(cz)}")

cl_matched = [l for l in cl_locaux if (l.get('localisation') or '').strip().lower() in audit_local_names]
print(f"CL matching audit local names: {len(cl_matched)}/{len(cl_locaux)}")
