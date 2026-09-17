import json

json_path = r'C:\Users\TeufackAndelson\.gemini\antigravity-ide\brain\408d6ca9-a8d2-4f02-9e1a-8741d90bf860\scratch\missions\mission_m_1788898451472923_110.json'
with open(json_path, 'r', encoding='utf-8') as f:
    m = json.load(f)

audit = m.get('audit', {})

def is_nc(conf):
    if conf is None: return False
    if isinstance(conf, bool): return not conf
    s = str(conf).strip().lower()
    return s in ['non', 'non conforme', 'non_conforme', 'false']

all_nc = []

# 1. Locaux MT
for z in audit.get('moyenneTensionZones', []):
    z_nom = z.get('nom')
    for loc in z.get('locaux', []):
        loc_nom = loc.get('nom')
        for item in loc.get('dispositionsConstructives', []):
            if is_nc(item.get('conforme')) or item.get('conforme') is False:
                all_nc.append({
                    'scope': 'MT_LOCAL_DISPO_CONSTRUCTIVE',
                    'zone': z_nom, 'local': loc_nom, 'equip': loc_nom,
                    'point': item.get('elementControle'),
                    'obs': item.get('observation'),
                    'crit': item.get('criticite') or 'Non spécifiée'
                })
        for item in loc.get('conditionsExploitation', []):
            if is_nc(item.get('conforme')) or item.get('conforme') is False:
                all_nc.append({
                    'scope': 'MT_LOCAL_COND_EXPLOITATION',
                    'zone': z_nom, 'local': loc_nom, 'equip': loc_nom,
                    'point': item.get('elementControle'),
                    'obs': item.get('observation'),
                    'crit': item.get('criticite') or 'Non spécifiée'
                })
        for cel in loc.get('cellules', []):
            for item in cel.get('elementsVerifies', []):
                if is_nc(item.get('conforme')) or item.get('conforme') is False:
                    all_nc.append({
                        'scope': 'MT_CELLULE',
                        'zone': z_nom, 'local': loc_nom, 'equip': cel.get('nom'),
                        'point': item.get('elementControle'),
                        'obs': item.get('observation'),
                        'crit': item.get('criticite') or 'Non spécifiée'
                    })
        for tr in loc.get('transformateurs', []):
            for item in tr.get('elementsVerifies', []):
                if is_nc(item.get('conforme')) or item.get('conforme') is False:
                    all_nc.append({
                        'scope': 'MT_TRANSFO',
                        'zone': z_nom, 'local': loc_nom, 'equip': tr.get('nom'),
                        'point': item.get('elementControle'),
                        'obs': item.get('observation'),
                        'crit': item.get('criticite') or 'Non spécifiée'
                    })
        for cof in loc.get('coffrets', []):
            for item in cof.get('pointsVerification', []):
                if is_nc(item.get('conformite')):
                    all_nc.append({
                        'scope': 'MT_COFFRET',
                        'zone': z_nom, 'local': loc_nom, 'equip': cof.get('nom'),
                        'point': item.get('pointVerification'),
                        'obs': item.get('observation'),
                        'crit': item.get('criticite') or 'Non spécifiée'
                    })
    for cof in z.get('coffretsDirects', []):
        for item in cof.get('pointsVerification', []):
            if is_nc(item.get('conformite')):
                all_nc.append({
                    'scope': 'MT_COFFRET_DIRECT',
                    'zone': z_nom, 'local': None, 'equip': cof.get('nom'),
                    'point': item.get('pointVerification'),
                    'obs': item.get('observation'),
                    'crit': item.get('criticite') or 'Non spécifiée'
                })

# 2. Locaux BT
for z in audit.get('basseTensionZones', []):
    z_nom = z.get('nom')
    for loc in z.get('locaux', []):
        loc_nom = loc.get('nom')
        is_ge = 'groupe' in loc_nom.lower() or loc.get('type') == 'LOCAL_GROUPE_ELECTROGENE'
        prefix = 'BT_GE_' if is_ge else 'BT_LOCAL_'
        for item in loc.get('dispositionsConstructives', []):
            if is_nc(item.get('conforme')) or item.get('conforme') is False:
                all_nc.append({
                    'scope': prefix + 'DISPO_CONSTRUCTIVE',
                    'zone': z_nom, 'local': loc_nom, 'equip': loc_nom,
                    'point': item.get('elementControle'),
                    'obs': item.get('observation'),
                    'crit': item.get('criticite') or 'Non spécifiée'
                })
        for item in loc.get('conditionsExploitation', []):
            if is_nc(item.get('conforme')) or item.get('conforme') is False:
                all_nc.append({
                    'scope': prefix + 'COND_EXPLOITATION',
                    'zone': z_nom, 'local': loc_nom, 'equip': loc_nom,
                    'point': item.get('elementControle'),
                    'obs': item.get('observation'),
                    'crit': item.get('criticite') or 'Non spécifiée'
                })
        for cof in loc.get('coffrets', []):
            c_type = cof.get('type', 'ARMOIRE')
            for item in cof.get('pointsVerification', []):
                if is_nc(item.get('conformite')):
                    all_nc.append({
                        'scope': f'BT_{c_type}',
                        'zone': z_nom, 'local': loc_nom, 'equip': cof.get('nom'),
                        'point': item.get('pointVerification'),
                        'obs': item.get('observation'),
                        'crit': item.get('criticite') or 'Non spécifiée'
                    })
    for cof in z.get('coffretsDirects', []):
        c_type = cof.get('type', 'ARMOIRE')
        for item in cof.get('pointsVerification', []):
            if is_nc(item.get('conformite')):
                all_nc.append({
                    'scope': f'BT_{c_type}_DIRECT',
                    'zone': z_nom, 'local': None, 'equip': cof.get('nom'),
                    'point': item.get('pointVerification'),
                    'obs': item.get('observation'),
                    'crit': item.get('criticite') or 'Non spécifiée'
                })

print(f"TOTAL NON-CONFORMITES REELLES: {len(all_nc)}")

by_scope = {}
by_crit = {}
for nc in all_nc:
    s = nc['scope']
    by_scope[s] = by_scope.get(s, 0) + 1
    c = nc['crit']
    by_crit[c] = by_crit.get(c, 0) + 1

print("\nRépartition par scope:")
for s, count in sorted(by_scope.items()):
    print(f"  {s}: {count}")

print("\nRépartition par criticité:")
for c, count in sorted(by_crit.items()):
    print(f"  {c}: {count}")
