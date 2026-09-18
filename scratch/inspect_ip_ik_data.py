import json

path = r'C:\Users\TeufackAndelson\.gemini\antigravity-ide\brain\408d6ca9-a8d2-4f02-9e1a-8741d90bf860\scratch\missions\mission_m_1788898451472923_110.json'
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)

audit = data.get('audit', {})
cl = data.get('classements_locaux', [])
cz = data.get('classements_zones', [])

print(f"Total classements_locaux: {len(cl)}")
print(f"Total classements_zones: {len(cz)}")

print("\n--- CLASSEMENTS ZONES ---")
for z in cz:
    print(f"  Zone: {z.get('nomZone')} - Type: {z.get('typeZone')} - IP: {z.get('ip')} - IK: {z.get('ik')}")

print("\n--- CLASSEMENTS LOCAUX (sample) ---")
for l in cl:
    print(f"  Local: {l.get('localisation')} - Zone: {l.get('zone')} - IP: {l.get('ip')} - IK: {l.get('ik')} - TypeEmp: {l.get('typeEmplacement')}")

print("\n--- COFFRETS & ARMOIRES IP/IK (sample) ---")
# Check observed IP/IK on coffrets
observed_counts = {}
for z in audit.get('basseTensionZones', []):
    z_nom = z.get('nom')
    for cof in z.get('coffretsDirects', []) or z.get('coffrets', []):
        ip_obs = cof.get('indiceIpIk')
        rep_obs = cof.get('indiceIpIkRepere')
        print(f"  Direct Coffret '{cof.get('nom')}' in Zone '{z_nom}': IP_obs={ip_obs}, Repere={rep_obs}")
    for l in z.get('locaux', []):
        l_nom = l.get('nom')
        for cof in l.get('coffrets', []):
            ip_obs = cof.get('indiceIpIk')
            rep_obs = cof.get('indiceIpIkRepere')
            print(f"  Local Coffret '{cof.get('nom')}' in Local '{l_nom}' (Zone '{z_nom}'): IP_obs={ip_obs}, Repere={rep_obs}")
