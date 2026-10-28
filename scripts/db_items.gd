class_name ItemDB
extends RefCounted
## Wszystkie przedmioty: broń, pancerz, akcesoria, przedmioty rzutane i mikstury.
## stats: strength, defense, health, energy, speed, crit, fury, luck, poise, throw_power

const BASE_LIST := {
	# --- BROŃ ---------------------------------------------------------
	"kolt": {
		"name": "Kołek do płotu", "slot": "weapon", "tier": 1, "price": 0, "icon": "kol",
		"desc": "Twardy, brudny, pozbawiony sentymentów. Lepsze niż nic.",
		"stats": {"strength": 0.10, "crit": 0.01},
		"atk": {"dmg": 1.0},
	},
	"widelec": {
		"name": "Widelec ogrodowy", "slot": "weapon", "tier": 1, "price": 30, "icon": "widelec",
		"desc": "Służył do piór. Teraz służy do ważenia argumentów.",
		"stats": {"strength": 0.18, "speed": 0.05},
		"atk": {"dmg": 1.05, "light": [
			{"name": "Cios", "wind": 0.07, "active": 0.08, "rec": 0.14, "dmg": 9.0, "range": 46.0},
			{"name": "Drugi cios", "wind": 0.08, "active": 0.09, "rec": 0.15, "dmg": 11.0, "range": 48.0},
			{"name": "Trzeci cios", "wind": 0.10, "active": 0.11, "rec": 0.22, "dmg": 16.0, "kb": 280.0, "range": 52.0, "launch": true, "s": 1.12},
		], "on_hit": {"bleed": 0.8, "desc": "krwawi: +0.8"}},
	},
	"kij_bej": {
		"name": "Kij bejsowy", "slot": "weapon", "tier": 2, "price": 70, "icon": "kij",
		"desc": "Ciężki, długi i zaskakująco szybki w rękach kogoś, kto nie boi się kurczaków.",
		"stats": {"strength": 0.30, "crit": 0.03},
		"atk": {"dmg": 1.15, "heavy": {"s": 1.35, "kb": 360.0, "stun": 0.6, "lunge": 80.0, "range": 64.0}},
	},
	"kosa": {
		"name": "Kosa farmera", "slot": "weapon", "tier": 2, "price": 85, "icon": "kosa",
		"desc": "Łamie rytm wrogów. Dosłownie.",
		"stats": {"strength": 0.28, "crit": 0.09, "speed": -0.03},
		"atk": {"dmg": 1.15, "light": [
			{"range": 60.0, "kb": 200.0},
			{"range": 60.0, "kb": 220.0},
			{"range": 64.0, "kb": 360.0, "launch": true},
		], "on_hit": {"splash": true, "desc": "kosi tłumy"}},
	},
	"pioro_graf": {
		"name": "Pióro Graffiti", "slot": "weapon", "tier": 3, "price": 130, "icon": "pioro",
		"desc": "Tak wspaniałe, że aż wkurza. Trafia częściej, niż powinno.",
		"stats": {"strength": 0.26, "crit": 0.18, "speed": 0.08},
		"atk": {"dmg": 1.1, "light": [
			{"wind": 0.06, "active": 0.08, "rec": 0.12, "dmg": 9.0, "range": 44.0, "s": 1.0},
			{"wind": 0.07, "active": 0.08, "rec": 0.13, "dmg": 10.0, "range": 46.0, "s": 1.05},
			{"wind": 0.09, "active": 0.09, "rec": 0.16, "dmg": 13.0, "range": 48.0, "s": 1.15},
		], "on_hit": {"bleed": 0.6, "desc": "krwawi: +0.6"}},
	},
	"młot_dmuchawy": {
		"name": "Młot do gumy", "slot": "weapon", "tier": 3, "price": 150, "icon": "mlot",
		"desc": "Siła uderzenia zależy od głośności krzyku.",
		"stats": {"strength": 0.44, "speed": -0.06, "crit": -0.02},
		"atk": {"dmg": 1.3, "heavy": {"s": 1.4, "dmg": 32.0, "kb": 360.0, "stun": 0.6, "range": 64.0, "lunge": 70.0, "launch": true}, "on_hit": {"splash": true, "desc": "tłumowy"}},
	},
	"kolce_niedzwiedzia": {
		"name": "Kolce niedźwiedzia", "slot": "weapon", "tier": 4, "price": 220, "icon": "kolce",
		"desc": "Wbijają się głębiej, niż powinno. Krzywdzi też właściciela.",
		"stats": {"strength": 0.58, "crit": 0.06, "health": -20.0},
		"atk": {"dmg": 1.25, "light": [
			{"wind": 0.07, "active": 0.09, "rec": 0.16, "dmg": 11.0, "range": 44.0, "kb": 160.0},
			{"wind": 0.08, "active": 0.09, "rec": 0.17, "dmg": 13.0, "range": 46.0, "kb": 175.0},
			{"wind": 0.11, "active": 0.11, "rec": 0.24, "dmg": 18.0, "range": 50.0, "kb": 220.0, "launch": true},
		], "heavy": {"dmg": 30.0, "s": 1.3, "kb": 340.0}, "on_hit": {"bleed": 1.4, "desc": "krwawi: +1.4"}},
	},
	"szabla_koguta": {
		"name": "Szabla Koguta", "slot": "weapon", "tier": 5, "price": 320, "icon": "szabla",
		"desc": "Rodzinny skarb. Nikt nie wie, czemu świeci, ale nikt nie pyta.",
		"stats": {"strength": 0.72, "crit": 0.12, "fury": 0.2},
		"atk": {"dmg": 1.25, "on_hit": {"heal": 2.0, "desc": "leczy przy trafieniu"}},
	},
	"dziobak": {
		"name": "Dziobaki", "slot": "weapon", "tier": 5, "price": 300, "icon": "dziobak",
		"desc": "Sześć sztuk, wszystkie ostre, wszystkie tanie. Brutalne.",
		"stats": {"strength": 0.60, "speed": 0.14, "crit": 0.08},
		"atk": {"dmg": 1.25, "light": [
			{"wind": 0.065, "active": 0.08, "rec": 0.13, "dmg": 10.0, "range": 46.0, "s": 1.05},
			{"wind": 0.065, "active": 0.08, "rec": 0.13, "dmg": 10.0, "range": 46.0, "s": 1.05},
			{"wind": 0.08, "active": 0.09, "rec": 0.15, "dmg": 12.0, "range": 48.0, "s": 1.1},
		], "air": {"dmg": 16.0, "s": 1.05, "kb": 220.0, "stun": 0.35, "range": 54.0}},
	},
	"laska_orla": {
		"name": "Laska Orła", "slot": "weapon", "tier": 6, "price": 430, "icon": "laska",
		"desc": "Wykuta z lotki najbardziej aroganckiego kruka w okolicy.",
		"stats": {"strength": 0.95, "crit": 0.14, "fury": 0.25, "energy": 25.0},
		"atk": {"dmg": 1.6, "on_hit": {"splash": true, "heal": 1.5, "desc": "leczy przy trafieniu, kosi tłumy"}},
	},
	"widly": {
		"name": "Widły Farmera", "slot": "weapon", "tier": 2, "price": 78, "icon": "widelec",
		"desc": "Cztery zęby, zero litości. Dobre na siano i na ptaki.",
		"stats": {"strength": 0.32, "crit": 0.04, "speed": 0.03},
		"atk": {"dmg": 1.15, "light": [
			{"range": 58.0, "dmg": 12.0},
			{"range": 60.0, "dmg": 14.0},
			{"range": 64.0, "dmg": 20.0, "kb": 350.0, "launch": true},
		], "on_hit": {"chain": 1, "desc": "przebicie"}},
	},
	"sierp": {
		"name": "Sierp Kombajnu", "slot": "weapon", "tier": 3, "price": 140, "icon": "kosa",
		"desc": "Kosi zboże i wrogów bez rozróżnienia.",
		"stats": {"strength": 0.40, "crit": 0.10, "speed": 0.02},
		"atk": {"dmg": 1.2, "light": [
			{"range": 60.0, "kb": 200.0, "dmg": 12.0},
			{"range": 62.0, "kb": 220.0, "dmg": 14.0},
			{"range": 66.0, "kb": 380.0, "dmg": 20.0, "launch": true},
		], "on_hit": {"bleed": 1.0, "desc": "krwawi: +1.0"}},
	},
	"gwiazda": {
		"name": "Gwiazda Poranna", "slot": "weapon", "tier": 6, "price": 410, "icon": "kolce",
		"desc": "Kolczasta kula na łańcuchu. Nikt nie wie, skąd się wzięła w kurniku.",
		"stats": {"strength": 0.86, "crit": 0.10, "fury": 0.2},
		"atk": {"dmg": 1.4, "heavy": {"s": 1.5, "dmg": 36.0, "kb": 380.0, "stun": 0.7, "range": 68.0, "lunge": 70.0, "launch": true}, "on_hit": {"splash": true, "desc": "tłumowy"}},
	},

	# --- PANCERZ -------------------------------------------------------
	"szmata": {
		"name": "Podkoszulek", "slot": "armor", "tier": 1, "price": 0, "icon": "szmata",
		"desc": "Chroni przed wiatrem. I przed tym jednym piórem.",
		"stats": {"defense": 0.05},
	},
	"kamizelka": {
		"name": "Kamizelka farmera", "slot": "armor", "tier": 1, "price": 35, "icon": "kamizelka",
		"desc": "Pachnie, ale działa.",
		"stats": {"defense": 0.12, "health": 10.0},
	},
	"kolczuga": {
		"name": "Kolczuga z drutu", "slot": "armor", "tier": 2, "price": 90, "icon": "kolczuga",
		"desc": "Kurczak w pełnej zbroi wygląda absurdalnie. Wrogowie nie patrzą na absurdalność.",
		"stats": {"defense": 0.22, "health": 18.0, "speed": -0.04},
	},
	"skorupa_z": {
		"name": "Skorupa Żółwia", "slot": "armor", "tier": 2, "price": 75, "icon": "skorupa",
		"desc": "Ktoś tu był. Nie pyta się kto.",
		"stats": {"defense": 0.18, "health": 26.0, "poise": 0.25},
	},
	"skrzydla_bociola": {
		"name": "Skrzydła Bociola", "slot": "armor", "tier": 3, "price": 160, "icon": "skrzydla",
		"desc": "Skrzydła są w kurniku, bo nikt nie wie, że to skrzydła.",
		"stats": {"defense": 0.24, "speed": 0.12, "energy": 15.0},
	},
	"pancerz_strazacky": {
		"name": "Pancerż Strażacki", "slot": "armor", "tier": 4, "price": 250, "icon": "pancerz",
		"desc": "Ciężki, głupiutki, skuteczny.",
		"stats": {"defense": 0.34, "health": 34.0, "poise": 0.4, "speed": -0.05},
	},
	"plaszcz_jastrzabia": {
		"name": "Płaszcz Jastrzębia", "slot": "armor", "tier": 5, "price": 360, "icon": "plaszcz",
		"desc": "Ciemny, gładki, idealny do znikania.",
		"stats": {"defense": 0.40, "speed": 0.16, "crit": 0.05, "energy": 20.0},
	},
	"upior_strzygodla": {
		"name": "Upiór Strzygodła", "slot": "armor", "tier": 6, "price": 480, "icon": "upior",
		"desc": "Wciąż ciepły. Niestety.",
		"stats": {"defense": 0.55, "health": 45.0, "fury": 0.3, "speed": 0.05},
	},
	"kurtka": {
		"name": "Kurtka Puchowa", "slot": "armor", "tier": 3, "price": 145, "icon": "kamizelka",
		"desc": "Lekka jak piórko, a jednak trzyma cios. Kto by pomyślał.",
		"stats": {"defense": 0.28, "health": 22.0, "speed": 0.06},
	},
	"zbroja_kruka": {
		"name": "Zbroja Krukowa", "slot": "armor", "tier": 6, "price": 470, "icon": "pancerz",
		"desc": "Czarne pióra zlane w stal. Sam król kruków jej pozazdrościł.",
		"stats": {"defense": 0.52, "health": 40.0, "poise": 0.35, "crit": 0.06},
	},

	# --- AKCESORIA ----------------------------------------------------
	"obroza": {
		"name": "Obroża Farmer'a", "slot": "accessory", "tier": 1, "price": 20, "icon": "obroza",
		"desc": "Głupi wygląd. Niesamowicie podnosi nastrój właściciela.",
		"stats": {"health": 8.0, "luck": 0.05},
	},
	"koraliki": {
		"name": "Koraliki z Pestek", "slot": "accessory", "tier": 1, "price": 28, "icon": "koraliki",
		"desc": "Amulet z bezwartościowego naszyjnika. Działa, bo nikt nie patrzy.",
		"stats": {"energy": 14.0, "crit": 0.02},
	},
	"kiel_pior": {
		"name": "Kieł Piorowy", "slot": "accessory", "tier": 2, "price": 65, "icon": "kiel",
		"desc": "Mocno pachnie. Mocno wzmacnia.",
		"stats": {"strength": 0.14, "defense": 0.06},
	},
	"buty_bieganki": {
		"name": "Buty Biegańki", "slot": "accessory", "tier": 2, "price": 80, "icon": "buty",
		"desc": "Zrobione z gumy i nadziei.",
		"stats": {"speed": 0.18, "energy": 8.0},
	},
	"piercien_kruka": {
		"name": "Pierścień Kruka", "slot": "accessory", "tier": 3, "price": 120, "icon": "piercien",
		"desc": "Czarny metal, chłodna skóra, zimne spojrzenie.",
		"stats": {"crit": 0.09, "strength": 0.12, "defense": 0.08},
	},
	"szalik_draca": {
		"name": "Szałwik Ranny", "slot": "accessory", "tier": 3, "price": 110, "icon": "szalik",
		"desc": "Krwawy, ale prestiżowy.",
		"stats": {"strength": 0.18, "fury": 0.22},
	},
	"amulet_szczepionki": {
		"name": "Amulet Szczepionki", "slot": "accessory", "tier": 4, "price": 200, "icon": "amulet",
		"desc": "Chorzy, którzy go noszą, nie chorują. Nikt nie wie dlaczego.",
		"stats": {"health": 28.0, "defense": 0.18, "energy": 20.0},
	},
	"okulary_sokola": {
		"name": "Okulary Sokoła", "slot": "accessory", "tier": 4, "price": 210, "icon": "okulary",
		"desc": "Wszystko jest ostrzejsze, gdy tak na to patrzysz.",
		"stats": {"crit": 0.16, "speed": 0.10, "luck": 0.08},
	},
	"korona_ogonow": {
		"name": "Korona z Ogonów", "slot": "accessory", "tier": 5, "price": 300, "icon": "korona",
		"desc": "Pięć ogonów. Szacunek natychmiastowy.",
		"stats": {"fury": 0.45, "health": 22.0, "energy": 30.0},
	},
	"jaja_feniks": {
		"name": "Jajo Feniksowe", "slot": "accessory", "tier": 6, "price": 520, "icon": "feniks",
		"desc": "Podobno z niego wyrósł pierwszy kurczak.",
		"stats": {"strength": 0.35, "health": 55.0, "energy": 40.0, "fury": 0.35, "crit": 0.08},
	},
	"dzwonek": {
		"name": "Dzwonek Wabiący", "slot": "accessory", "tier": 2, "price": 60, "icon": "obroza",
		"desc": "Dzwoni tak ładnie, że łup spada częściej. Nauka nie potrafi tego wyjaśnić.",
		"stats": {"luck": 0.12, "health": 6.0},
	},
	"pioro_aniola": {
		"name": "Pióro Anioła", "slot": "accessory", "tier": 5, "price": 285, "icon": "amulet",
		"desc": "Miękkie, ciepłe i trochę święte. Trzymaj blisko.",
		"stats": {"health": 30.0, "defense": 0.2, "energy": 25.0},
	},

	# --- MIKSTURY (przedmioty do użycia) -------------------------------
	"jajko": {
		"name": "Jajko", "slot": "throwable", "tier": 1, "price": 6, "icon": "jajko", "stack": 20,
		"desc": "Kładziesz je, wybijasz rzut. Klasyka.",
		"stats": {},
		"throw": {"damage": 18.0, "radius": 46.0, "speed": 620.0, "gravity": 900.0, "count": 1},
	},
	"jajko_ogromne": {
		"name": "Jajko Olbrzymie", "slot": "throwable", "tier": 2, "price": 14, "icon": "jajko_duze", "stack": 20,
		"desc": "Zajmuje pół kieszeni i pół kurnika.",
		"stats": {},
		"throw": {"damage": 34.0, "radius": 62.0, "speed": 560.0, "gravity": 1000.0, "count": 1},
	},
	"skamielina": {
		"name": "Skamielina Ptasia", "slot": "throwable", "tier": 2, "price": 11, "icon": "skamielina", "stack": 20,
		"desc": "Trzy rzuty, trzy martwe ptaki. Reklamy kłamią.",
		"stats": {},
		"throw": {"damage": 12.0, "radius": 24.0, "speed": 700.0, "gravity": 700.0, "count": 3},
	},
	"cebula": {
		"name": "Cebula", "slot": "throwable", "tier": 1, "price": 9, "icon": "cebula", "stack": 20,
		"desc": "Zawiera gaz. Wszyscy płaczą. To w sumie atak.",
		"stats": {},
		"throw": {"damage": 8.0, "radius": 80.0, "speed": 480.0, "gravity": 500.0, "count": 1, "stun": 1.6},
	},
	"mikstura_miodu": {
		"name": "Mikstura Miodu", "slot": "consumable", "tier": 1, "price": 20, "icon": "mikstura", "stack": 10,
		"desc": "Przywraca 45 punktów życia.",
		"stats": {}, "use": {"health": 45.0},
	},
	"eliksir_pietra": {
		"name": "Eliksir Piętrowy", "slot": "consumable", "tier": 1, "price": 18, "icon": "eliksir", "stack": 10,
		"desc": "Przywraca 55 punktów energii.",
		"stats": {}, "use": {"energy": 55.0},
	},
	"rosol_z_ptaka": {
		"name": "Rosół z Ptaka", "slot": "consumable", "tier": 2, "price": 60, "icon": "rosol", "stack": 5,
		"desc": "Pełne życie i krótki zryw siły.",
		"stats": {}, "use": {"health": 999.0, "energy": 40.0, "buff_strength": 0.35, "buff_time": 12.0},
	},
	"koktajl_domowy": {
		"name": "Koktajl Domowy", "slot": "consumable", "tier": 3, "price": 130, "icon": "koktajl", "stack": 3,
		"desc": "Pełna energia, pełne życie, chwilowa niezniszczalność.",
		"stats": {}, "use": {"health": 999.0, "energy": 999.0, "buff_speed": 0.35, "buff_time": 10.0, "invuln": 4.0},
	},
	"mikstura_kruka": {
		"name": "Mikstura Krucza", "slot": "consumable", "tier": 3, "price": 95, "icon": "mikstura", "stack": 6,
		"desc": "Czarna, gęsta i ohydna. Leczy 120 życia i dodaje 60 energii.",
		"stats": {}, "use": {"health": 120.0, "energy": 60.0},
	},
	"eliksir_mocy": {
		"name": "Eliksir Mocy", "slot": "consumable", "tier": 4, "price": 125, "icon": "eliksir", "stack": 5,
		"desc": "Rozpala mięśnie na kwadrans. Na dłużej nie starcza.",
		"stats": {}, "use": {"buff_strength": 0.5, "buff_time": 15.0},
	},
	"kamyk": {
		"name": "Kamyk z Drogi", "slot": "throwable", "tier": 1, "price": 4, "icon": "skamielina", "stack": 30,
		"desc": "Leży wszędzie. Lecisz nim szybciej niż nim rzucasz.",
		"stats": {},
		"throw": {"damage": 10.0, "radius": 20.0, "speed": 760.0, "gravity": 650.0, "count": 1},
	},
	"granat_nawoz": {
		"name": "Granat z Nawozu", "slot": "throwable", "tier": 3, "price": 48, "icon": "jajko_duze", "stack": 10,
		"desc": "Śmierdzi, błyska i ogłusza. Trzy w jednym.",
		"stats": {},
		"throw": {"damage": 44.0, "radius": 92.0, "speed": 500.0, "gravity": 920.0, "count": 1, "stun": 1.0},
	},
}

## Sloty widoczne w sklepie (stare) oraz wszystkie sloty wyposażenia postaci.
const SLOT_ORDER := ["weapon", "armor", "accessory"]
const EQUIP_SLOTS := ["weapon", "helmet", "armor", "boots", "accessory", "amulet", "amulet2"]
const SLOT_NAMES := {
	"weapon": "Broń", "helmet": "Hełm", "armor": "Zbroja", "boots": "Buty",
	"accessory": "Akcesorium", "amulet": "Amulet", "amulet2": "Amulet 2",
}
const RARITIES := ["zwykly", "niezwykly", "rzadki", "epicki", "legendarny", "hiperlegendarny", "hiperextralegendarny"]
const RARITY_MULT := [1.0, 1.15, 1.35, 1.65, 2.05, 2.6, 3.4]
const RARITY_NAMES := {
	"zwykly": "Zwykły", "niezwykly": "Niezwykły", "rzadki": "Rzadki", "epicki": "Epicki",
	"legendarny": "LEGENDARNY", "hiperlegendarny": "HIPERLEGENDARNY", "hiperextralegendarny": "HIPEREKSTRALEGENDARNY",
}
const RARITY_COLORS := {
	"zwykly": Color(0.85, 0.87, 0.92), "niezwykly": Color(0.45, 0.9, 0.5), "rzadki": Color(0.4, 0.7, 1.0),
	"epicki": Color(0.72, 0.5, 0.98), "legendarny": Color(1.0, 0.62, 0.15), "hiperlegendarny": Color(0.95, 0.3, 0.95), "hiperextralegendarny": Color(1.0, 0.95, 0.45),
}

## Scalona baza: przedmioty bazowe + dodatki (kuźnia, legendarne, pety).
static var LIST: Dictionary = _armorize(BASE_LIST.merged(ItemsExtra.LIST).merged(RuneDB.pattern_items()).merged(ItemsHard.LIST).merged(SideDB.ITEMS).merged(PalaceDB.ITEMS).merged(BowDB.LIST).merged(ItemsGen.LIST))

## Zbroja nie dodaje życia — zmniejsza obrażenia: obrona zbroi zamienia się na procent
## mniejszych obrażeń (30% wartości obrony), a bonus do życia zbroi znika.
static func _armorize(l: Dictionary) -> Dictionary:
	var out := l.duplicate()
	for id in out:
		var d: Dictionary = out[id]
		if String(d.get("slot", "")) != "armor":
			continue
		d = d.duplicate(true)
		var st: Dictionary = d.get("stats", {})
		st.erase("health")
		var fx: Dictionary = d.get("fx", {})
		fx["dmg_reduction"] = float(fx.get("dmg_reduction", 0.0)) + float(st.get("defense", 0.0)) * 0.3
		d["stats"] = st
		d["fx"] = fx
		out[id] = d
	return out

## Ofiara do pierwiastka BU: dowolna broń o rzadkości rzadkiej lub wyższej. 1 broń = 1 BU, a sztabka kurczalium kosztuje 3 BU.
const BU_PER_SACRIFICE := 1
static func bu_sacrifice_ok(id: String) -> bool:
	if String(get_data(id).get("slot", "")) != "weapon":
		return false
	return RARITIES.find(rarity_of(id)) >= RARITIES.find("rzadki")

## Kara za śmierć: do DEATH_LOSS_MAX losowych przedmiotów z plecaka (założone są bezpieczne). Rzeczy wyposażenia znikają
## w całości, mikstury i rzutki — połowa stosu. Materiały, klucze, wzorce i sprzęt pupili nie giną.
const DEATH_LOSS_MAX := 3
static func death_losable(id: String) -> bool:
	return String(get_data(id).get("slot", "")) in ["weapon", "armor", "helmet", "boots", "accessory", "amulet", "consumable", "throwable"]

## Ile sztuk z danego stosu przepada (n = wielkość stosu).
static func death_loss_amount(id: String, n: int) -> int:
	if String(get_data(id).get("slot", "")) in ["consumable", "throwable"]:
		return maxi(1, int(ceil(float(n) / 2.0)))
	return n

static func rarity_of(id: String) -> String:
	var d: Dictionary = LIST.get(id, {})
	if d.has("rarity"):
		return String(d["rarity"])
	var tier := int(d.get("tier", 1))
	if tier <= 1: return "zwykly"
	if tier == 2: return "niezwykly"
	if tier <= 4: return "rzadki"
	return "epicki"

static func rarity_index(r: String) -> int:
	return maxi(0, RARITIES.find(r))

## Rzadkość przedmiotu z uwzględnieniem run (meta["r"]).
static func meta_rarity(id: String, meta: Dictionary) -> String:
	var base := rarity_of(id)
	var r := String(meta.get("r", ""))
	if r != "" and rarity_index(r) > rarity_index(base):
		return r
	return base

## Mnożnik statystyk po zmianie rzadkości i wzmocnieniach runami.
static func meta_mult(id: String, meta: Dictionary) -> float:
	if meta.is_empty():
		return 1.0
	var from_i := rarity_index(rarity_of(id))
	var to_i := rarity_index(meta_rarity(id, meta))
	return RARITY_MULT[to_i] / RARITY_MULT[from_i] * (1.0 + 0.2 * float(int(meta.get("b", 0))))

static func rarity_of_entry(e: Dictionary) -> String:
	return meta_rarity(String(e["id"]), e.get("m", {}))

static func rarity_color_of(r: String) -> Color:
	return RARITY_COLORS.get(r, Color.WHITE)

static func rarity_color(id: String) -> Color:
	return RARITY_COLORS.get(rarity_of(id), Color.WHITE)

static func is_gear_slot(slot: String) -> bool:
	return slot in ["weapon", "helmet", "armor", "boots", "accessory", "amulet"]

static func is_gear(id: String) -> bool:
	var slot := String(LIST.get(id, {}).get("slot", ""))
	return slot in ["weapon", "helmet", "armor", "boots", "accessory", "amulet"]

## Rozmiar stosu: wyposażenie = 1, reszta wg pola "stack" (domyślnie 99).
static func stack_of(id: String) -> int:
	if is_gear(id) or String(LIST.get(id, {}).get("slot", "")) == "pet_gear":
		return 1
	return int(LIST.get(id, {}).get("stack", 99))

## Czy przedmiot można założyć w danym slocie wyposażenia (amulet2 przyjmuje amulety).
## Dlaczego klasa nie może nosić tej broni (pusty tekst = może). Mag nie nosi broni wcale,
## łucznik tylko łuków, reszta klas wszystkiego poza łukami.
static func class_block(id: String, cls: String) -> String:
	var d: Dictionary = LIST.get(id, {})
	if String(d.get("slot", "")) != "weapon":
		return ""
	var bow := bool(d.get("bow", false))
	if cls == "mag":
		return "Mag nie nosi broni — walczy zaklęciami (klawisze 1-9)."
	if cls == "lucznik" and not bow:
		return "Łucznik walczy tylko łukiem."
	if cls != "lucznik" and bow:
		return "Łuki są tylko dla łucznika."
	return ""

static func fits_slot(id: String, slot: String) -> bool:
	var s := String(LIST.get(id, {}).get("slot", ""))
	if slot == "amulet2":
		return s == "amulet"
	return s == slot

static func fx_of(id: String) -> Dictionary:
	return LIST.get(id, {}).get("fx", {})

static func get_data(id: String) -> Dictionary:
	return LIST.get(id, {})

static func has(id: String) -> bool:
	return LIST.has(id)

static func by_slot(slot: String) -> Array:
	var out := []
	for id in LIST:
		if String(LIST[id]["slot"]) == slot:
			if ItemsExtra.LIST.has(id) and int(LIST[id].get("price", 0)) <= 0:
				continue  # tylko z kuźni / nagrody — nie na sprzedaż
			out.append(id)
	out.sort_custom(func(a, b): return int(LIST[a]["tier"]) < int(LIST[b]["tier"]))
	return out

static func stats_of(id: String) -> Dictionary:
	if not LIST.has(id):
		return {}
	return LIST[id].get("stats", {})

static func price_of(id: String) -> int:
	return int(LIST.get(id, {}).get("price", 0))

static func is_consumable(id: String) -> bool:
	return String(LIST.get(id, {}).get("slot", "")) == "consumable"

static func is_throwable(id: String) -> bool:
	return String(LIST.get(id, {}).get("slot", "")) == "throwable"

static func defaults() -> Dictionary:
	return {
		"weapon": "kolt", "armor": "szmata", "accessory": "obroza",
	}

static func starter_backpack() -> Dictionary:
	return {"jajko": 5, "mikstura_miodu": 2}

const WEAPON_BASE_LIGHT := [
	{"name": "Cios", "wind": 0.075, "active": 0.085, "rec": 0.15, "dmg": 9.0, "kb": 150.0, "stun": 0.24, "range": 46.0, "lunge": 120.0, "launch": false, "s": 1.0},
	{"name": "Drugi cios", "wind": 0.085, "active": 0.095, "rec": 0.17, "dmg": 11.0, "kb": 185.0, "stun": 0.28, "range": 50.0, "lunge": 140.0, "launch": false, "s": 1.05},
	{"name": "Trzeci cios", "wind": 0.12, "active": 0.13, "rec": 0.29, "dmg": 16.0, "kb": 330.0, "stun": 0.4, "range": 58.0, "lunge": 190.0, "launch": true, "s": 1.15},
]
const WEAPON_BASE_HEAVY := {"name": "Ciężki cios", "wind": 0.26, "active": 0.13, "rec": 0.34, "dmg": 26.0, "kb": 300.0, "stun": 0.5, "range": 62.0, "lunge": 90.0, "launch": true, "s": 1.25}
const WEAPON_BASE_AIR := {"name": "Cios w powietrzu", "wind": 0.055, "active": 0.16, "rec": 0.2, "dmg": 13.0, "kb": 200.0, "stun": 0.3, "range": 52.0, "lunge": 60.0, "launch": false, "s": 1.0}

static func weapon_damage_mult(id: String) -> float:
	if not LIST.has(id):
		return 1.0
	var w = LIST[id]
	if String(w.get("slot", "")) != "weapon":
		return 1.0
	var atk = w.get("atk", {})
	if atk is Dictionary and atk.has("dmg"):
		return float(atk["dmg"])
	return 1.0

static func weapon_on_hit(id: String) -> Dictionary:
	if not LIST.has(id):
		return {}
	var w = LIST[id]
	if String(w.get("slot", "")) != "weapon":
		return {}
	var atk = w.get("atk", {})
	if atk is Dictionary and atk.has("on_hit"):
		return atk["on_hit"]
	return {}

static func weapon_desc(id: String) -> String:
	if not LIST.has(id):
		return ""
	var w = LIST[id]
	if String(w.get("slot", "")) != "weapon":
		return ""
	var atk = w.get("atk", {})
	if atk is Dictionary and atk.has("on_hit"):
		var d = atk["on_hit"]
		if d is Dictionary and d.has("desc"):
			return String(d["desc"])
	return ""

static func weapon_attacks(id: String) -> Dictionary:
	var fallback: Dictionary = {
		"light": [WEAPON_BASE_LIGHT[0].duplicate(true)],
		"heavy": WEAPON_BASE_HEAVY.duplicate(true),
		"air": WEAPON_BASE_AIR.duplicate(true),
	}
	if not LIST.has(id):
		return fallback
	var w = LIST[id]
	if String(w.get("slot", "")) != "weapon":
		return fallback
	var atk = w.get("atk", {})
	var m := weapon_damage_mult(id)
	var light_arr: Array = []
	if atk is Dictionary and atk.has("light") and atk["light"] is Array and (atk["light"] as Array).size() > 0:
		for i in range((atk["light"] as Array).size()):
			var base: Dictionary = (WEAPON_BASE_LIGHT[i] if i < WEAPON_BASE_LIGHT.size() else WEAPON_BASE_LIGHT[0]) as Dictionary
			var merged: Dictionary = base.duplicate(true)
			var ov = (atk["light"] as Array)[i]
			if ov is Dictionary:
				for k in (ov as Dictionary).keys():
					merged[k] = (ov as Dictionary)[k]
			merged["dmg"] = float(merged["dmg"]) * m
			light_arr.append(merged)
	else:
		for base_d in WEAPON_BASE_LIGHT:
			var merged: Dictionary = (base_d as Dictionary).duplicate(true)
			merged["dmg"] = float(merged["dmg"]) * m
			light_arr.append(merged)
	var heavy_res: Dictionary = WEAPON_BASE_HEAVY.duplicate(true)
	if atk is Dictionary and atk.has("heavy") and atk["heavy"] is Dictionary:
		for k in (atk["heavy"] as Dictionary).keys():
			heavy_res[k] = (atk["heavy"] as Dictionary)[k]
	heavy_res["dmg"] = float(heavy_res["dmg"]) * m
	var air_res: Dictionary = WEAPON_BASE_AIR.duplicate(true)
	if atk is Dictionary and atk.has("air") and atk["air"] is Dictionary:
		for k in (atk["air"] as Dictionary).keys():
			air_res[k] = (atk["air"] as Dictionary)[k]
	air_res["dmg"] = float(air_res["dmg"]) * m
	if light_arr.size() == 0:
		light_arr.append(WEAPON_BASE_LIGHT[0].duplicate(true))
	return {"light": light_arr, "heavy": heavy_res, "air": air_res}
