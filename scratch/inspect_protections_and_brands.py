import json

json_path = r'C:\Users\TeufackAndelson\.gemini\antigravity-ide\brain\408d6ca9-a8d2-4f02-9e1a-8741d90bf860\scratch\missions\mission_m_1788898451472923_110.json'
with open(json_path, 'r', encoding='utf-8') as f:
    m = json.load(f)

audit = m.get('audit', {})

# Collect all coffrets/armoires
all_coffrets = []
# Direct in MT locaux
for loc in audit.get('moyenneTensionLocaux', []):
    all_coffrets.extend(loc.get('coffrets', []))
# In MT zones
for z in audit.get('moyenneTensionZones', []):
    for loc in z.get('locaux', []):
        all_coffrets.extend(loc.get('coffrets', []))
    all_coffrets.extend(z.get('coffrets', []))
# In BT zones
for z in audit.get('basseTensionZones', []):
    for loc in z.get('locaux', []):
        all_coffrets.extend(loc.get('coffrets', []))
    all_coffrets.extend(z.get('coffretsDirects', []))

print(f"Total Coffrets/Armoires gathered: {len(all_coffrets)}")

# Inspect structure of first coffret with departures or terminalCircuits
with_departs = [c for c in all_coffrets if c.get('departures')]
with_circuits = [c for c in all_coffrets if c.get('terminalCircuits')]
print(f"Equipments with departures: {len(with_departs)}, with circuits: {len(with_circuits)}")

# Total departures and circuits
all_departs = []
for c in all_coffrets:
    for d in c.get('departures', []):
        all_departs.append({'parent': c.get('nom'), 'data': d})

all_circuits = []
for c in all_coffrets:
    for ct in c.get('terminalCircuits', []):
        all_circuits.append({'parent': c.get('nom'), 'data': ct})

print(f"\nTotal Départs in mission: {len(all_departs)}")
if all_departs:
    print("Sample départ keys:", list(all_departs[0]['data'].keys()))
    print("Sample départ:", all_departs[0]['data'])

print(f"\nTotal Circuits Terminaux in mission: {len(all_circuits)}")
if all_circuits:
    print("Sample circuit keys:", list(all_circuits[0]['data'].keys()))
    print("Sample circuit:", all_circuits[0]['data'])

# Check protection de tete
with_prot_tete = 0
for c in all_coffrets:
    prot = c.get('protectionTete')
    # Check how dart code checks protection de tete
    has_prot = prot is not None and (isinstance(prot, dict) and (prot.get('type') or prot.get('calibre') or prot.get('marque')))
    if has_prot:
        with_prot_tete += 1

print(f"\nEquipments with protection de tete: {with_prot_tete}/{len(all_coffrets)}")
