class_name BowDB
extends RefCounted
## Łuki — broń wyłącznie dla łucznika. Lekki atak to szybka strzała, ciężki to naciągnięta, mocna strzała.
## "bow": true oznacza łuk; reszta pól jak w zwykłej broni (stats, fx, atk, vis).

const LIGHT := {"name": "Strzał", "wind": 0.11, "active": 0.04, "rec": 0.2, "dmg": 9.0, "kb": 90.0, "stun": 0.2, "range": 40.0, "lunge": 0.0, "launch": false, "s": 1.0}
const HEAVY := {"name": "Mocny strzał", "wind": 0.42, "active": 0.05, "rec": 0.3, "dmg": 30.0, "kb": 260.0, "stun": 0.45, "range": 40.0, "lunge": 0.0, "launch": false, "s": 1.3}

const LIST := {
	"luk_mysliwski": {
		"name": "Łuk myśliwski", "slot": "weapon", "bow": true, "tier": 1, "price": 0, "icon": "luk",
		"desc": "Prosty łuk na kurze polowanie. Cięciwa trochę skrzypi.",
		"stats": {"strength": 0.12, "crit": 0.03},
		"atk": {"dmg": 1.0, "light": [LIGHT], "heavy": HEAVY},
		"vis": {"col": Color(0.6, 0.42, 0.22), "style": "bow", "len": 22.0},
	},
	"luk_lowcy": {
		"name": "Łuk łowcy", "slot": "weapon", "bow": true, "tier": 2, "price": 90, "icon": "luk", "tint": Color(0.5, 0.62, 0.3),
		"desc": "Giętki jesion i pewna ręka. Strzały lecą szybciej.",
		"stats": {"strength": 0.26, "crit": 0.06, "speed": 0.03},
		"atk": {"dmg": 1.12, "light": [LIGHT], "heavy": HEAVY},
		"vis": {"col": Color(0.5, 0.62, 0.3), "style": "bow", "len": 23.0},
	},
	"luk_refleksyjny": {
		"name": "Łuk refleksyjny", "slot": "weapon", "bow": true, "tier": 3, "price": 170, "icon": "luk", "tint": Color(0.85, 0.7, 0.35),
		"desc": "Wygięty w drugą stronę, strzela mocniej, niż wygląda.",
		"stats": {"strength": 0.4, "crit": 0.12, "speed": 0.04},
		"atk": {"dmg": 1.22, "light": [LIGHT], "heavy": HEAVY},
		"vis": {"col": Color(0.85, 0.7, 0.35), "style": "bow", "len": 24.0},
	},
	"luk_kompozytowy": {
		"name": "Łuk kompozytowy", "slot": "weapon", "bow": true, "tier": 4, "price": 320, "icon": "luk", "tint": Color(0.75, 0.55, 0.3), "rarity": "epicki",
		"desc": "Róg, ścięgna i drewno sklejone przez mistrza. Każdy mocny strzał to mały grom.",
		"stats": {"strength": 0.58, "crit": 0.16, "speed": 0.05},
		"atk": {"dmg": 1.32, "light": [LIGHT], "heavy": HEAVY},
		"vis": {"col": Color(0.78, 0.55, 0.3), "style": "bow", "len": 25.0},
	},

	# --- LEGENDARNE ŁUKI ----------------------------------------------------
	"luk_cienia_kruka": {
		"name": "Łuk Cienia Kruka", "slot": "weapon", "bow": true, "tier": 6, "price": 0, "icon": "luk", "tint": Color(0.6, 0.3, 0.95), "rarity": "legendarny",
		"desc": "Cięciwa spleciona z czarnych piór. Strzały nie rzucają cienia, tylko go zabierają.",
		"stats": {"strength": 0.8, "crit": 0.2, "speed": 0.07},
		"fx": {"lifesteal": 0.05},
		"atk": {"dmg": 1.4, "light": [LIGHT], "heavy": HEAVY},
		"vis": {"col": Color(0.62, 0.32, 0.95), "style": "bow", "len": 27.0, "glow": true},
	},
	"luk_burzowy": {
		"name": "Łuk Burzowy", "slot": "weapon", "bow": true, "tier": 6, "price": 0, "icon": "luk", "tint": Color(0.5, 0.85, 1.0), "rarity": "legendarny",
		"desc": "Wystrzelone nim strzały trzeszczą od błyskawic. Ciężki strzał ogłusza na długo.",
		"stats": {"strength": 0.78, "crit": 0.16, "speed": 0.12},
		"atk": {"dmg": 1.36, "light": [LIGHT], "heavy": HEAVY},
		"vis": {"col": Color(0.55, 0.88, 1.0), "style": "bow", "len": 27.0, "glow": true},
	},
	"luk_zlotego_skowronka": {
		"name": "Łuk Złotego Skowronka", "slot": "weapon", "bow": true, "tier": 6, "price": 0, "icon": "luk", "tint": Color(1.0, 0.85, 0.35), "rarity": "legendarny",
		"desc": "Śpiewa przy każdym strzale. Szczęście sprzyja temu, kto go napina.",
		"stats": {"strength": 0.74, "crit": 0.24, "luck": 0.2},
		"atk": {"dmg": 1.34, "light": [LIGHT], "heavy": HEAVY},
		"vis": {"col": Color(1.0, 0.85, 0.35), "style": "bow", "len": 27.0, "glow": true},
	},
	"luk_z_kurczalium": {
		"name": "Łuk z kurczalium", "slot": "weapon", "bow": true, "tier": 6, "price": 0, "icon": "luk", "tint": Color(0.75, 0.35, 1.0), "rarity": "legendarny",
		"desc": "Wykuty z kurczalium. Mocny strzał przebija pancerz, jakby go nie było.",
		"stats": {"strength": 0.9, "crit": 0.18, "fury": 0.2},
		"atk": {"dmg": 1.45, "light": [LIGHT], "heavy": HEAVY},
		"vis": {"col": Color(0.75, 0.35, 1.0), "style": "bow", "len": 28.0, "glow": true},
	},
	"luk_wschodzacego_slonca": {
		"name": "Łuk Wschodzącego Słońca", "slot": "weapon", "bow": true, "tier": 8, "price": 0, "icon": "luk", "tint": Color(1.0, 0.7, 0.2), "rarity": "hiperlegendarny",
		"desc": "Każda strzała to promień świtu. Mówią, że kurczaki widzą go przed wschodem.",
		"stats": {"strength": 1.25, "crit": 0.3, "speed": 0.1, "fury": 0.3},
		"fx": {"lifesteal": 0.06},
		"atk": {"dmg": 1.7, "light": [LIGHT], "heavy": HEAVY},
		"vis": {"col": Color(1.0, 0.75, 0.25), "style": "bow", "len": 30.0, "glow": true},
	},
}

static func is_bow(id: String) -> bool:
	return bool(ItemDB.get_data(id).get("bow", false))
