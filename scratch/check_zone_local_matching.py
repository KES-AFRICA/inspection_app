import json

json_path = r'C:\Users\TeufackAndelson\.gemini\antigravity-ide\brain\408d6ca9-a8d2-4f02-9e1a-8741d90bf860\scratch\missions\mission_m_1788898451472923_110.json'
with open(json_path, 'r', encoding='utf-8') as f:
    m = json.load(f)

audit = m.get('audit', {})
mt_locaux = audit.get('moyenneTensionLocaux', [])
mt_zones = audit.get('moyenneTensionZones', [])
bt_zones = audit.get('basseTensionZones', [])

cz = m.get('classements_zones', [])
cl = m.get('classements_locaux', [])

cz_by_name = { (z.get('nomZone') or '').strip().lower(): z for z in cz }

audit_zones = []
for z in mt_zones:
    audit_zones.append({'name': z.get('nom'), 'domain': 'MT', 'id': z.get('id')})
for z in bt_zones:
    audit_zones.append({'name': z.get('nom'), 'domain': 'BT', 'id': z.get('id')})

print('=== ZONES AUDIT ===')
classified_zones_count = 0
for z in audit_zones:
    name_clean = (z['name'] or '').strip().lower()
    match = cz_by_name.get(name_clean)
    has_class = match is not None and any([match.get('af'), match.get('be'), match.get('ip'), match.get('ik')])
    if has_class:
        classified_zones_count += 1
    match_name = match.get('nomZone') if match else 'None'
    print(f"Zone: {z['name']} ({z['domain']}) -> Classified: {has_class} (match: {match_name})")

print(f"\nTotal Zones: {len(audit_zones)}, Classified Zones: {classified_zones_count}/{len(audit_zones)}")

cl_by_name = { (l.get('localisation') or '').strip().lower(): l for l in cl if l.get('typeEmplacement') == 'local' }
audit_locaux = []
for l in mt_locaux:
    audit_locaux.append({'name': l.get('nom'), 'domain': 'MT', 'id': l.get('id')})
for z in mt_zones:
    for l in z.get('locaux', []):
        audit_locaux.append({'name': l.get('nom'), 'domain': 'MT', 'id': l.get('id')})
for z in bt_zones:
    for l in z.get('locaux', []):
        audit_locaux.append({'name': l.get('nom'), 'domain': 'BT', 'id': l.get('id')})

print('\n=== LOCAUX AUDIT ===')
classified_locaux_count = 0
for l in audit_locaux:
    name_clean = (l['name'] or '').strip().lower()
    match = cl_by_name.get(name_clean)
    has_class = match is not None and any([match.get('af'), match.get('be'), match.get('ip'), match.get('ik')])
    if has_class:
        classified_locaux_count += 1
    match_name = match.get('localisation') if match else 'None'
    print(f"Local: {l['name']} ({l['domain']}) -> Classified: {has_class} (match: {match_name})")

print(f"\nTotal Locaux: {len(audit_locaux)}, Classified Locaux: {classified_locaux_count}/{len(audit_locaux)}")
