import json

json_path = r'C:\Users\TeufackAndelson\.gemini\antigravity-ide\brain\408d6ca9-a8d2-4f02-9e1a-8741d90bf860\scratch\missions\mission_m_1788898451472923_110.json'
with open(json_path, 'r', encoding='utf-8') as f:
    m = json.load(f)

audit = m.get('audit', {})

print("--- MT LOCAL INSPECTION ---")
for z in audit.get('moyenneTensionZones', []):
    for loc in z.get('locaux', []):
        print('Local MT keys:', list(loc.keys()))
        print('Local MT nom:', loc.get('nom'))
        for k, v in loc.items():
            if isinstance(v, list):
                print(f"   list key: {k}, len={len(v)}")
        break
    break

print("\n--- MT CELLULE INSPECTION ---")
for z in audit.get('moyenneTensionZones', []):
    for loc in z.get('locaux', []):
        for cel in loc.get('cellules', []):
            print('Cellule keys:', list(cel.keys()))
            for k, v in cel.items():
                if isinstance(v, list):
                    print(f"   list key: {k}, len={len(v)}")
            break
        break
    break

print("\n--- MT TRANSFO INSPECTION ---")
for z in audit.get('moyenneTensionZones', []):
    for loc in z.get('locaux', []):
        for tr in loc.get('transformateurs', []):
            print('Transfo keys:', list(tr.keys()))
            for k, v in tr.items():
                if isinstance(v, list):
                    print(f"   list key: {k}, len={len(v)}")
            break
        break
    break

print("\n--- BT LOCAL INSPECTION ---")
for z in audit.get('basseTensionZones', []):
    for loc in z.get('locaux', []):
        print('Local BT keys:', list(loc.keys()))
        print('Local BT nom:', loc.get('nom'), 'typeLocal:', loc.get('typeLocal'))
        for k, v in loc.items():
            if isinstance(v, list):
                print(f"   list key: {k}, len={len(v)}")
        break
    break
