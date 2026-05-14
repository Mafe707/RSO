import json, math, argparse, requests, time
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import LabelEncoder
from sklearn.model_selection import cross_val_score

SEED = 42
np.random.seed(SEED)

BARRIOS_BUSCAR = [
    ("Centro — Calle 17",            "Calle 17, Pasto, Nariño"),
    ("Centro — Carrera 23",          "Carrera 23, Pasto, Nariño"),
    ("Plaza El Potrerillo",          "Plaza El Potrerillo, Pasto, Nariño"),
    ("Sector La Panadería",          "La Panadería, Pasto, Nariño"),
    ("Av. Julián Bucheli",           "Avenida Julián Bucheli, Pasto, Nariño"),
    ("Barrio Las Lunas",             "Las Lunas, Pasto, Nariño"),
    ("Bomboná",                      "Bomboná, Pasto, Nariño"),
    ("San Andrés",                   "San Andrés, Pasto, Nariño"),
    ("El Ejido",                     "El Ejido, Pasto, Nariño"),
    ("Rumipamba",                    "Rumipamba, Pasto, Nariño"),
    ("La Rosa",                      "La Rosa, Pasto, Nariño"),
    ("Tamasagra",                    "Tamasagra, Pasto, Nariño"),
    ("Torobajo",                     "Torobajo, Pasto, Nariño"),
    ("Las Cuadras — Parque Infantil","Las Cuadras, Pasto, Nariño"),
    ("Mijitayo",                     "Mijitayo, Pasto, Nariño"),
    ("Aranda",                       "Aranda, Pasto, Nariño"),
]

COORDS_FALLBACK = {
    "Centro — Calle 17":             (1.2136, -77.2811),
    "Centro — Carrera 23":           (1.2120, -77.2790),
    "Plaza El Potrerillo":           (1.2050, -77.2750),
    "Sector La Panadería":           (1.2090, -77.2830),
    "Av. Julián Bucheli":            (1.2160, -77.2850),
    "Barrio Las Lunas":              (1.2200, -77.2920),
    "Bomboná":                       (1.2250, -77.2780),
    "San Andrés":                    (1.2070, -77.2760),
    "El Ejido":                      (1.2180, -77.2700),
    "Rumipamba":                     (1.2300, -77.2850),
    "La Rosa":                       (1.2350, -77.2900),
    "Tamasagra":                     (1.2220, -77.2650),
    "Torobajo":                      (1.2400, -77.2950),
    "Las Cuadras — Parque Infantil": (1.2280, -77.2820),
    "Mijitayo":                      (1.2240, -77.2760),
    "Aranda":                        (1.2450, -77.2700),
}

PESOS = {
    "Centro — Calle 17":             0.25,
    "Centro — Carrera 23":           0.15,
    "Plaza El Potrerillo":           0.12,
    "Sector La Panadería":           0.08,
    "Av. Julián Bucheli":            0.06,
    "Barrio Las Lunas":              0.05,
    "Bomboná":                       0.04,
    "San Andrés":                    0.04,
    "El Ejido":                      0.04,
    "Rumipamba":                     0.03,
    "La Rosa":                       0.03,
    "Tamasagra":                     0.03,
    "Torobajo":                      0.02,
    "Las Cuadras — Parque Infantil": 0.03,
    "Mijitayo":                      0.02,
    "Aranda":                        0.01,
}

CATEGORIAS = [
    "Venta informal",
    "Invasión vehicular",
    "Ocupación comercial",
    "Publicidad no autorizada",
    "Materiales de construcción",
    "Otro",
]

ESTADOS = [
    "pendiente", "en_revision", "resuelto_pendiente_validacion",
    "devuelto", "resuelto_publicado",
]

CATEGORIA_PESO = {
    "Centro — Calle 17":             [0.60, 0.10, 0.15, 0.08, 0.04, 0.03],
    "Centro — Carrera 23":           [0.55, 0.12, 0.18, 0.08, 0.04, 0.03],
    "Plaza El Potrerillo":           [0.55, 0.08, 0.20, 0.05, 0.08, 0.04],
    "Sector La Panadería":           [0.50, 0.10, 0.25, 0.06, 0.06, 0.03],
    "Av. Julián Bucheli":            [0.30, 0.25, 0.20, 0.12, 0.08, 0.05],
    "Barrio Las Lunas":              [0.10, 0.65, 0.10, 0.05, 0.05, 0.05],
    "Bomboná":                       [0.20, 0.25, 0.20, 0.15, 0.12, 0.08],
    "San Andrés":                    [0.20, 0.20, 0.20, 0.15, 0.15, 0.10],
    "El Ejido":                      [0.15, 0.20, 0.25, 0.18, 0.12, 0.10],
    "Rumipamba":                     [0.15, 0.25, 0.20, 0.15, 0.15, 0.10],
    "La Rosa":                       [0.15, 0.20, 0.20, 0.18, 0.15, 0.12],
    "Tamasagra":                     [0.15, 0.20, 0.20, 0.20, 0.15, 0.10],
    "Torobajo":                      [0.15, 0.20, 0.18, 0.18, 0.18, 0.11],
    "Las Cuadras — Parque Infantil": [0.20, 0.15, 0.35, 0.15, 0.08, 0.07],
    "Mijitayo":                      [0.15, 0.20, 0.22, 0.20, 0.13, 0.10],
    "Aranda":                        [0.10, 0.15, 0.15, 0.40, 0.12, 0.08],
}

CALLES = {
    "Centro — Calle 17":             ["Calle 17 #24-", "Calle 17 #22-", "Calle 17 #20-"],
    "Centro — Carrera 23":           ["Carrera 23 #18-", "Carrera 23 #17-", "Cra 23 #16-"],
    "Plaza El Potrerillo":           ["Sector Potrerillo #", "Entrada Potrerillo #", "Cra 20 Potrerillo #"],
    "Sector La Panadería":           ["Sector La Panadería Cra #", "Calle La Panadería #", "Tv. Panadería #"],
    "Av. Julián Bucheli":            ["Av. Julián Bucheli #", "Av. Bucheli norte #", "Av. Bucheli sur #"],
    "Barrio Las Lunas":              ["Barrio Las Lunas Cra #", "Calle Las Lunas #", "Las Lunas diagonal #"],
    "Bomboná":                       ["Barrio Bomboná Cra #", "Calle Bomboná #", "Bomboná Tv. #"],
    "San Andrés":                    ["Barrio San Andrés Cra #", "Calle San Andrés #", "San Andrés Tv. #"],
    "El Ejido":                      ["Barrio El Ejido Cra #", "Calle El Ejido #", "El Ejido Tv. #"],
    "Rumipamba":                     ["Barrio Rumipamba Cra #", "Calle Rumipamba #", "Rumipamba Tv. #"],
    "La Rosa":                       ["Barrio La Rosa Cra #", "Calle La Rosa #", "La Rosa Tv. #"],
    "Tamasagra":                     ["Barrio Tamasagra Cra #", "Calle Tamasagra #", "Tamasagra Tv. #"],
    "Torobajo":                      ["Barrio Torobajo Cra #", "Calle Torobajo #", "Torobajo Tv. #"],
    "Las Cuadras — Parque Infantil": ["Las Cuadras Cra #", "Sector Parque Infantil #", "Calle Las Cuadras #"],
    "Mijitayo":                      ["Barrio Mijitayo Cra #", "Calle Mijitayo #", "Mijitayo Tv. #"],
    "Aranda":                        ["Barrio Aranda Cra #", "Calle Aranda #", "Aranda Tv. #"],
}

DESCRIPCIONES = {
    "Venta informal": [
        "Vendedores ambulantes bloquean el paso peatonal con puestos de comida.",
        "Comerciantes sin permiso ocupan la acera con mercancía variada.",
        "Puestos de venta informal impiden el libre tránsito peatonal.",
        "Vendedor de frutas invade zona peatonal frente a establecimiento.",
    ],
    "Invasión vehicular": [
        "Vehículo abandonado obstruye la acera hace más de 24 horas.",
        "Motos parqueadas en zona peatonal restringida.",
        "Camión descarga mercancía bloqueando el andén.",
        "Vehículo estacionado sobre el andén impide el paso.",
    ],
    "Ocupación comercial": [
        "Establecimiento ocupa la vía pública con mesas y sillas sin permiso.",
        "Local comercial instala vitrinas invadiendo el espacio público.",
        "Negocio coloca exhibidores en zona peatonal sin autorización.",
        "Bar instala sillas en el andén obstruyendo el paso.",
    ],
    "Publicidad no autorizada": [
        "Valla publicitaria instalada en espacio público sin permiso.",
        "Carteles pegados en postes del alumbrado público.",
        "Pendones publicitarios obstruyen la visibilidad peatonal.",
        "Pintada publicitaria sobre fachada de bien público.",
    ],
    "Materiales de construcción": [
        "Materiales de construcción obstruyen la vía peatonal sin señalización.",
        "Escombros depositados en el andén sin permiso.",
        "Arena y gravilla en espacio público sin autorización.",
        "Andamios invaden la acera sin señalización de seguridad.",
    ],
    "Otro": [
        "Invasión del espacio público no categorizada.",
        "Obstáculo en zona peatonal de tipo no identificado.",
        "Ocupación irregular del espacio público.",
    ],
}

def obtener_coords(query):
    try:
        r = requests.get(
            "https://nominatim.openstreetmap.org/search",
            params={"q": query, "format": "json", "limit": 1, "accept-language": "es"},
            headers={"User-Agent": "rso-pasto/1.0"},
            timeout=5,
        )
        data = r.json()
        if data:
            return float(data[0]["lat"]), float(data[0]["lon"])
    except Exception as e:
        print(f"    Error Nominatim: {e}")
    return None

def construir_hotspots():
    hotspots = []
    print("Consultando coordenadas reales desde OpenStreetMap...")
    for nombre, query in BARRIOS_BUSCAR:
        coords = obtener_coords(query)
        if coords:
            lat, lng = coords
            print(f"  ✓ {nombre}: {lat:.5f}, {lng:.5f}")
        else:
            lat, lng = COORDS_FALLBACK[nombre]
            print(f"  ⚠ {nombre}: fallback {lat:.5f}, {lng:.5f}")
        hotspots.append((lat, lng, nombre, PESOS[nombre]))
        time.sleep(1)
    return hotspots

def dist_m(lat1, lng1, lat2, lng2):
    R = 6371000.0
    dLat = (lat2-lat1)*math.pi/180
    dLng = (lng2-lng1)*math.pi/180
    a = math.sin(dLat/2)**2 + math.cos(lat1*math.pi/180)*math.cos(lat2*math.pi/180)*math.sin(dLng/2)**2
    return R*2*math.atan2(math.sqrt(a), math.sqrt(1-a))

def nombre_cercano(lat, lng, hotspots):
    return min(hotspots, key=lambda h: dist_m(lat, lng, h[0], h[1]))[2]

def generar(n, hotspots):
    rows = []
    pesos = [h[3] for h in hotspots]
    idx = np.random.choice(len(hotspots), size=n, p=pesos)
    fecha_base = pd.Timestamp("2025-01-01")
    fecha_fin  = pd.Timestamp("2025-05-13")
    rango = (fecha_fin - fecha_base).days
    for i in range(n):
        hs = hotspots[idx[i]]
        lat = hs[0] + np.random.normal(0, 0.0008)
        lng = hs[1] + np.random.normal(0, 0.0008)
        cat = np.random.choice(CATEGORIAS, p=CATEGORIA_PESO[hs[2]])
        dias = int(np.random.triangular(0, rango*0.75, rango))
        fecha = (fecha_base + pd.Timedelta(days=dias)).replace(
            hour=np.random.choice([8,9,10,12,13,14,17,18,19],
                p=[0.12,0.12,0.10,0.12,0.12,0.10,0.12,0.12,0.08]),
            minute=np.random.randint(0,60))
        calles = CALLES[hs[2]]
        calle = calles[np.random.randint(len(calles))]
        numero = np.random.randint(10, 90)
        rows.append({
            "latitud": round(lat, 6),
            "longitud": round(lng, 6),
            "categoria": cat,
            "estado": np.random.choice(ESTADOS, p=[0.35,0.30,0.15,0.10,0.10]),
            "creado_en": fecha,
            "zona_nombre": hs[2],
            "ubicacion": f"{calle}{numero}, {hs[2]}, Pasto, Nariño",
            "descripcion": DESCRIPCIONES[cat][np.random.randint(len(DESCRIPCIONES[cat]))],
        })
    return pd.DataFrame(rows)

def features(df):
    df = df.copy()
    df["creado_en"] = pd.to_datetime(df["creado_en"])
    df["dia_semana"] = df["creado_en"].dt.dayofweek
    df["mes"] = df["creado_en"].dt.month
    df["franja_hora"] = df["creado_en"].dt.hour.apply(
        lambda h: 0 if h<7 else 1 if h<12 else 2 if h<17 else 3 if h<21 else 4)
    df["es_finde"] = (df["dia_semana"]>=4).astype(int)
    le = LabelEncoder()
    df["categoria_cod"] = le.fit_transform(df["categoria"])
    df["grid_lat"] = ((df["latitud"]-1.20)/0.003).astype(int)
    df["grid_lng"] = ((df["longitud"]+77.31)/0.003).astype(int)
    df["grid_id"] = df["grid_lat"].astype(str)+"_"+df["grid_lng"].astype(str)
    dens = df.groupby("grid_id").size().rename("densidad_grid")
    df = df.join(dens, on="grid_id")
    df["ventana_48h"] = 0
    for gid, g in df.groupby("grid_id"):
        gs = g.sort_values("creado_en")
        counts = []
        for _, row in gs.iterrows():
            t0 = row["creado_en"]
            counts.append(len(gs[
                (gs["creado_en"]>=t0-pd.Timedelta(hours=48)) &
                (gs["creado_en"]<=t0+pd.Timedelta(hours=48))
            ])-1)
        df.loc[gs.index,"ventana_48h"] = counts
    fmax = df["creado_en"].max()
    rec = df[df["creado_en"]>=fmax-pd.Timedelta(days=14)]
    hot = set(rec.groupby("grid_id").filter(lambda x: len(x)>=5)["grid_id"])
    df["zona_reincidente"] = df["grid_id"].isin(hot).astype(int)
    return df, le

def etiquetar(df):
    def nivel(row):
        score = 0
        score += min(row["densidad_grid"]/40, 1.0)*3
        score += min(row["ventana_48h"]/8, 1.0)*2
        score += row["zona_reincidente"]*1.5
        score += row["es_finde"]*0.5
        if score < 1.5: return 0
        if score < 3.0: return 1
        return 2
    return df.apply(nivel, axis=1)

def exportar_arbol(tree, feat_names):
    from sklearn.tree._tree import TREE_LEAF
    t = tree.tree_
    L, R = t.children_left.tolist(), t.children_right.tolist()
    F, TH, V = t.feature.tolist(), t.threshold.tolist(), t.value.tolist()
    def nodo(i):
        if L[i]==TREE_LEAF:
            vals=V[i][0]; total=sum(vals)
            return {"leaf":True,"class":int(np.argmax(vals)),"probs":[round(v/total,4) for v in vals]}
        return {"leaf":False,"feature":feat_names[F[i]],"feature_idx":F[i],
                "threshold":round(TH[i],6),"left":nodo(L[i]),"right":nodo(R[i])}
    return nodo(0)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--csv", default=None)
    parser.add_argument("--n_sinteticos", type=int, default=700)
    parser.add_argument("--n_trees", type=int, default=20)
    parser.add_argument("--max_depth", type=int, default=8)
    args = parser.parse_args()

    # Obtener coordenadas reales desde Nominatim
    hotspots = construir_hotspots()

    print("\nGenerando datos...")
    if args.csv:
        dr = pd.read_csv(args.csv, parse_dates=["creado_en"])
        dr = dr[dr["latitud"].notna()&dr["longitud"].notna()]
        ds = generar(max(100, args.n_sinteticos-len(dr)), hotspots)
        df = pd.concat([dr,ds], ignore_index=True)
        print(f"  {len(dr)} reales + {len(ds)} sinteticos")
    else:
        df = generar(args.n_sinteticos, hotspots)
        print(f"  {len(df)} sinteticos")

    print("Feature engineering...")
    df, le = features(df)
    y = etiquetar(df)
    FEAT = ["latitud","longitud","categoria_cod","dia_semana","mes","franja_hora",
            "es_finde","densidad_grid","ventana_48h","zona_reincidente","grid_lat","grid_lng"]
    X = df[FEAT]
    dist_y = y.value_counts().sort_index().to_dict()
    print(f"  Bajo:{dist_y.get(0,0)}  Medio:{dist_y.get(1,0)}  Alto:{dist_y.get(2,0)}")

    print("Entrenando...")
    rf = RandomForestClassifier(n_estimators=args.n_trees, max_depth=args.max_depth,
        min_samples_leaf=4, random_state=SEED, class_weight="balanced")
    rf.fit(X, y)
    sc = cross_val_score(rf, X, y, cv=5, scoring="f1_macro")
    print(f"  F1: {sc.mean():.3f} +/- {sc.std():.3f}")

    arboles = [exportar_arbol(e, FEAT) for e in rf.estimators_]

    zonas = []
    for gid, g in df.groupby("grid_id"):
        lat_c = g["latitud"].mean()
        lng_c = g["longitud"].mean()
        n_total = len(g)
        fmax = df["creado_en"].max()
        n_48h = len(g[g["creado_en"]>=fmax-pd.Timedelta(hours=48)])
        cat = g["categoria"].mode()[0]
        nivel_p = int(rf.predict(g[FEAT].mean().values.reshape(1,-1))[0])
        probs_p = rf.predict_proba(g[FEAT].mean().values.reshape(1,-1))[0].tolist()
        nombre = g["zona_nombre"].mode()[0] if "zona_nombre" in g.columns else nombre_cercano(lat_c, lng_c, hotspots)
        zonas.append({
            "grid_id": gid,
            "zona_nombre": nombre,
            "lat_centro": round(lat_c,6),
            "lng_centro": round(lng_c,6),
            "reportes_historicos": n_total,
            "reportes_48h": n_48h,
            "categoria_predominante": cat,
            "nivel_riesgo": ["bajo","medio","alto"][nivel_p],
            "probabilidades": [round(p,4) for p in probs_p],
        })

    import os
    os.makedirs("../../assets/ml", exist_ok=True)

    # Guardar modelo
    artefacto = {
        "version":"4.0.0",
        "fecha_entrenamiento": pd.Timestamp.now().isoformat(),
        "n_reportes_usados": len(df),
        "features": FEAT,
        "clases": ["bajo","medio","alto"],
        "n_arboles": args.n_trees,
        "arboles": arboles,
        "zonas_precalculadas": zonas,
        "categoria_mapping": {c:int(le.transform([c])[0]) for c in le.classes_},
        "config": {"grid_lat_offset":1.20,"grid_lng_offset":-77.31,"grid_size":0.003,
                   "umbral_alerta_48h":5,"umbral_hotspot_densidad":15}
    }
    with open("../../assets/ml/modelo_rf.json","w",encoding="utf-8") as f:
        json.dump(artefacto, f, ensure_ascii=False, indent=2)

    # Guardar hotspots con coords reales para Dart
    hotspots_json = [
        {"nombre": h[2], "lat": round(h[0],6), "lng": round(h[1],6)}
        for h in hotspots
    ]
    with open("../../assets/ml/hotspots_pasto.json","w",encoding="utf-8") as f:
        json.dump(hotspots_json, f, ensure_ascii=False, indent=2)

    bajo  = sum(1 for z in zonas if z["nivel_riesgo"]=="bajo")
    medio = sum(1 for z in zonas if z["nivel_riesgo"]=="medio")
    alto  = sum(1 for z in zonas if z["nivel_riesgo"]=="alto")
    print(f"\nmodelo_rf.json → {len(zonas)} zonas: Bajo:{bajo} Medio:{medio} Alto:{alto}")
    print(f"hotspots_pasto.json → {len(hotspots_json)} barrios con coords reales")
    print("\nZonas ALTO riesgo:")
    for z in zonas:
        if z["nivel_riesgo"]=="alto":
            print(f"  {z['zona_nombre']} — {z['categoria_predominante']} — {z['reportes_historicos']} rep.")

if __name__=="__main__":
    main()