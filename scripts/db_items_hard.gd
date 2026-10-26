class_name ItemsHard
extends RefCounted
## Legendarki wzmacniające umiejętności. Wzór istnieje w trzech wersjach (legendarna, hiperlegendarna,
## hiperekstralegendarna), ale z potworów, bossów i skrzyń wypada wyłącznie wersja legendarna.
## Rzadkości powyżej legendarnej można zdobyć tylko przez runy.
##
## fx: skill_power (moc umiejętności), skill_cdr (krótsze odnowienie), skill_cost (tańsze umiejętności),
## skill_range (zasięg), energy_regen (energia/s) — poza zwykłymi regen/lifesteal/dmg_reduction.

const LEVELS := [
	{"suffix": "", "rarity": "legendarny", "mult": 1.0, "tier": 7},
	{"suffix": " Koszmaru", "rarity": "hiperlegendarny", "mult": 1.65, "tier": 8},
	{"suffix": " Piekła", "rarity": "hiperextralegendarny", "mult": 2.5, "tier": 9},
]

const TEMPLATES := {
	"ostrze_echa": {"name": "Ostrze Echa", "slot": "weapon", "icon": "miecz", "col": Color(0.6, 0.85, 1.0),
		"desc": "Każdy czar odbija się echem — umiejętności uderzają mocniej i wracają szybciej.",
		"stats": {"strength": 0.85, "crit": 0.12}, "fx": {"skill_power": 0.14, "skill_cdr": 0.06},
		"atk": {"dmg": 1.35, "on_hit": {"splash": true, "desc": "kosi tłumy"}}},
	"szpon_zametu": {"name": "Szpon Zamętu", "slot": "weapon", "icon": "szabla", "col": Color(0.85, 0.4, 1.0),
		"desc": "Krwawi przeciwników i wysysa z nich energię na kolejne umiejętności.",
		"stats": {"strength": 0.75, "speed": 0.10}, "fx": {"skill_cost": 0.12, "energy_regen": 2.0},
		"atk": {"dmg": 1.3, "on_hit": {"bleed": 1.2, "desc": "krwawi"}}},
	"mlot_grzmotu": {"name": "Młot Grzmotu", "slot": "weapon", "icon": "mlot", "col": Color(1.0, 0.85, 0.35),
		"desc": "Fale uderzeniowe z umiejętności sięgają znacznie dalej.",
		"stats": {"strength": 1.0, "poise": 0.2}, "fx": {"skill_range": 0.18, "skill_power": 0.10},
		"atk": {"dmg": 1.45, "heavy": {"s": 1.5, "kb": 420.0, "stun": 0.7, "lunge": 80.0, "range": 70.0}}},
	"rozdzka_piorunow": {"name": "Różdżka Piorunów", "slot": "weapon", "icon": "laska", "col": Color(0.55, 0.9, 1.0),
		"desc": "Szybka, zwinna, a umiejętności z jej użyciem biją jak pioruny.",
		"stats": {"strength": 0.7, "crit": 0.10}, "fx": {"skill_power": 0.20, "skill_range": 0.10},
		"atk": {"dmg": 1.25, "on_hit": {"heal": 1.0, "desc": "leczy"}}},
	"korona_skupienia": {"name": "Korona Skupienia", "slot": "helmet", "icon": "korona", "col": Color(1.0, 0.85, 0.4),
		"desc": "Umysł czysty jak kryształ: umiejętności są tańsze i szybciej gotowe.",
		"stats": {"defense": 0.30, "energy": 25.0}, "fx": {"skill_cdr": 0.10, "skill_cost": 0.08}},
	"kaptur_cichego_piora": {"name": "Kaptur Cichego Pióra", "slot": "helmet", "icon": "helm", "col": Color(0.55, 0.45, 0.8),
		"desc": "Cichy strzał, głośny skutek — wzmacnia moc umiejętności.",
		"stats": {"crit": 0.10, "speed": 0.08, "defense": 0.15}, "fx": {"skill_power": 0.12}},
	"pancerz_rezonansu": {"name": "Pancerz Rezonansu", "slot": "armor", "icon": "pancerz", "col": Color(0.9, 0.6, 0.3),
		"desc": "Drga w rytm walki. Chroni i zasila każdą umiejętność.",
		"stats": {"defense": 0.80, "health": 70.0}, "fx": {"dmg_reduction": 0.05, "skill_power": 0.10}},
	"szata_burzy": {"name": "Szata Burzy", "slot": "armor", "icon": "plaszcz", "col": Color(0.45, 0.7, 1.0),
		"desc": "Poszerza zasięg umiejętności i szybko odnawia energię.",
		"stats": {"defense": 0.50, "energy": 40.0}, "fx": {"skill_range": 0.15, "skill_cost": 0.12, "energy_regen": 1.5}},
	"buty_przeskoku": {"name": "Buty Przeskoku", "slot": "boots", "icon": "buty", "col": Color(0.5, 1.0, 0.7),
		"desc": "Lekkie jak pióro. Umiejętności wracają do gotowości w mgnieniu oka.",
		"stats": {"speed": 0.25, "energy": 15.0}, "fx": {"skill_cdr": 0.10}},
	"pierscien_furii": {"name": "Pierścień Furii", "slot": "accessory", "icon": "piercien", "col": Color(1.0, 0.4, 0.2),
		"desc": "Furia narasta szybciej, a umiejętności zadają większe obrażenia.",
		"stats": {"fury": 0.30, "strength": 0.20}, "fx": {"skill_power": 0.12}},
	"obroza_alfy": {"name": "Obroża Alfy", "slot": "accessory", "icon": "obroza", "col": Color(0.9, 0.75, 0.4),
		"desc": "Przywódca stada uczy się szybciej i bije mocniej umiejętnościami.",
		"stats": {"health": 40.0, "luck": 0.20}, "fx": {"skill_power": 0.10, "xp_mult": 0.08}},
	"szalik_przeciagu": {"name": "Szalik Przeciągu", "slot": "accessory", "icon": "szalik", "col": Color(0.6, 0.85, 0.95),
		"desc": "Wiatr w plecy: szybszy bieg, regeneracja i krótsze odnowienie umiejętności.",
		"stats": {"speed": 0.15, "poise": 0.20}, "fx": {"skill_cdr": 0.08, "regen": 1.0}},
	"amulet_rytmu": {"name": "Amulet Wiecznego Rytmu", "slot": "amulet", "icon": "amulet", "col": Color(0.75, 0.55, 1.0),
		"desc": "Odmierza czas inaczej niż reszta świata — umiejętności wracają błyskawicznie.",
		"stats": {"energy": 30.0}, "fx": {"skill_cdr": 0.14}},
	"amulet_kradziezy_many": {"name": "Amulet Kradzieży Many", "slot": "amulet", "icon": "amulet", "col": Color(0.4, 0.8, 1.0),
		"desc": "Każde trafienie wysysa życie, a umiejętności kosztują mniej.",
		"stats": {"health": 30.0}, "fx": {"lifesteal": 0.03, "skill_cost": 0.15, "energy_regen": 2.5}},
}

const PET_GEAR := {
	"pet_slonce_obroza": {
		"name": "Słoneczna Obroża", "slot": "pet_gear", "pet_only": true, "tier": 9, "price": 0, "icon": "obroza", "tint": Color(1.0, 0.85, 0.3), "rarity": "hiperextralegendarny",
		"desc": "Obroża utkana z promieni słońca. Pupil płonie złotym blaskiem, a jego ciosy palą jak słoneczne płomienie. (Tylko dla petów.)",
		"stats": {"pet_dmg": 1.2, "pet_speed": 0.5, "pet_hp": 1.0, "pet_range": 0.4},
	},
	"pet_slonce_napiersnik": {
		"name": "Słoneczny Napierśnik pupila", "slot": "pet_gear", "pet_only": true, "tier": 9, "price": 0, "icon": "pancerz", "tint": Color(1.0, 0.8, 0.25), "rarity": "hiperextralegendarny",
		"desc": "Złoty pancerz, od którego bije żar. Pupil ma ogromne życie i otacza się płonącym słońcem. (Tylko dla petów.)",
		"stats": {"pet_dmg": 0.8, "pet_speed": 0.3, "pet_hp": 2.5, "pet_range": 0.2},
	},
	"pet_slonce_luk": {
		"name": "Słoneczny Łuk pupila", "slot": "pet_gear", "pet_only": true, "tier": 9, "price": 0, "icon": "luk", "tint": Color(1.0, 0.9, 0.4), "rarity": "hiperextralegendarny",
		"desc": "Strzały z czystego światła. Pupil razi wrogów z daleka i płonie jak słońce. (Tylko dla petów.)",
		"stats": {"pet_dmg": 1.6, "pet_speed": 0.8, "pet_hp": 0.6, "pet_range": 0.9},
	},
}

static var LIST: Dictionary = _build().merged(PET_GEAR)

static func id_of(base: String, level: int) -> String:
	return "%s_%d" % [base, level]

static func _build() -> Dictionary:
	var out := {}
	for base in TEMPLATES:
		var t: Dictionary = TEMPLATES[base]
		for lv in LEVELS.size():
			var L: Dictionary = LEVELS[lv]
			var m := float(L["mult"])
			var stats := {}
			for k in t["stats"]:
				stats[k] = float(t["stats"][k]) * m
			var fx := {}
			for k in t["fx"]:
				fx[k] = float(t["fx"][k]) * (1.0 + (m - 1.0) * 0.8)
			var col: Color = t["col"]
			var d := {
				"name": String(t["name"]) + String(L["suffix"]), "slot": t["slot"], "tier": int(L["tier"]), "price": 0,
				"icon": t["icon"], "tint": col, "rarity": L["rarity"], "desc": t["desc"], "stats": stats, "fx": fx,
				"vis": {"col": col, "style": "sword", "len": 24.0 + 2.0 * lv, "glow": lv > 0, "trim": col.lightened(0.4)},
				"hard_lv": lv,
			}
			if t.has("atk"):
				var a: Dictionary = (t["atk"] as Dictionary).duplicate(true)
				a["dmg"] = float(a["dmg"]) * (1.0 + 0.25 * lv)
				d["atk"] = a
			out[id_of(String(base), lv)] = d
	return out

## Losuje legendarkę: poziom trudności 0..2 decyduje o jakości (na wyższych trudnościach
## częściej wypadają lepsze wersje). Zwraca id przedmiotu.
## Losuje legendarkę. Przedmioty powyżej legendarnych (hiperlegendarne i hiperekstralegendarne) nie wypadają
## już nigdzie — da się je zdobyć wyłącznie przez runy, więc poziom trudności nie podnosi tu rzadkości.
static func roll(_difficulty_level: int) -> String:
	var keys: Array = TEMPLATES.keys()
	return id_of(String(keys[randi() % keys.size()]), 0)
