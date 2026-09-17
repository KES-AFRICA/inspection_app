import json

with open('scratch/missions/mission_m_1788898451472923_110.json', 'r', encoding='utf-8') as f:
    m = json.load(f)

audit = m.get('audit', {})

pv_list = []

def scan_points(points, equip_info):
    for p in points:
        pv_list.append({
            'equip': equip_info,
            'point': p
        })

# MT Zones & Locaux
for z in audit.get('moyenneTensionZones', []):
    z_nom = z.get('nom', '')
    for c in z.get('coffretsDirects', []):
        scan_points(c.get('pointsVerification', []), {'zone': z_nom, 'local': None, 'type': 'COFFRET_DIRECT_MT', 'nom': c.get('nom'), 'id': c.get('id')})
    for loc in z.get('locaux', []):
        loc_nom = loc.get('nom', '')
        for cel in loc.get('cellules', []):
            scan_points(cel.get('pointsVerification', []), {'zone': z_nom, 'local': loc_nom, 'type': 'CELLULE_MT', 'nom': cel.get('nom'), 'id': cel.get('id')})
        for tr in loc.get('transformateurs', []):
            scan_points(tr.get('pointsVerification', []), {'zone': z_nom, 'local': loc_nom, 'type': 'TRANSFO_MT', 'nom': tr.get('nom'), 'id': tr.get('id')})
        for cof in loc.get('coffrets', []):
            scan_points(cof.get('pointsVerification', []), {'zone': z_nom, 'local': loc_nom, 'type': 'COFFRET_LOCAL_MT', 'nom': cof.get('nom'), 'id': cof.get('id')})

# BT Zones & Locaux
for z in audit.get('basseTensionZones', []):
    z_nom = z.get('nom', '')
    for c in z.get('coffretsDirects', []):
        scan_points(c.get('pointsVerification', []), {'zone': z_nom, 'local': None, 'type': 'COFFRET_DIRECT_BT', 'nom': c.get('nom'), 'id': c.get('id')})
    for loc in z.get('locaux', []):
        loc_nom = loc.get('nom', '')
        for cof in loc.get('coffrets', []):
            scan_points(cof.get('pointsVerification', []), {'zone': z_nom, 'local': loc_nom, 'type': 'COFFRET_LOCAL_BT', 'nom': cof.get('nom'), 'id': cof.get('id')})

print(f"Total Points de Vérification dans le backup: {len(pv_list)}")

# Analyse des statuts
statuts = {}
criticités = {}
observations_non_vides = 0
nc_points = []
non_conformes_strict = 0

for item in pv_list:
    p = item['point']
    st = p.get('statut', 'SANS_STATUT')
    statuts[st] = statuts.get(st, 0) + 1
    
    crit = p.get('degreCriticite') or p.get('criticite') or 'NON_DEFINIE'
    criticités[crit] = criticités.get(crit, 0) + 1
    
    obs = p.get('observations') or p.get('observation') or ''
    if obs.strip():
        observations_non_vides += 1
        
    if st == 'NON_CONFORME' or 'NON_CONFORME' in str(st):
        non_conformes_strict += 1
        nc_points.append(item)

print(f"Statuts répartition: {statuts}")
print(f"Criticités répartition: {criticités}")
print(f"Points avec texte d'observation non vide: {observations_non_vides}")
print(f"Points avec statut NON_CONFORME: {non_conformes_strict}")

# Groupement des NC par équipement
nc_by_equip = {}
for item in nc_points:
    eq_id = item['equip']['id'] or item['equip']['nom']
    eq_type = item['equip']['type']
    if eq_id not in nc_by_equip:
        nc_by_equip[eq_id] = {'info': item['equip'], 'nc_count': 0, 'crit': {}}
    nc_by_equip[eq_id]['nc_count'] += 1
    c = item['point'].get('degreCriticite') or item['point'].get('criticite') or 'NON_DEFINIE'
    nc_by_equip[eq_id]['crit'][c] = nc_by_equip[eq_id]['crit'].get(c, 0) + 1

print(f"Nombre d'équipements impactés par au moins 1 NC: {len(nc_by_equip)}")
