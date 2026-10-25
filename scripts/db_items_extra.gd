class_name ItemsExtra
extends RefCounted
## Dodatkowe przedmioty: kuźnia, materiały, legendarne nagrody, wyposażenie petów,
## hełmy i buty. Scalane z ItemDB.LIST przy starcie.
## Pola: slot, tier, rarity, stats, fx (efekty specjalne), vis (wygląd na postaci).
## fx: regen (HP/s), lifesteal (ułamek zadanych obr.), dmg_reduction, xp_mult, gold_mult.

const KURCZAL := Color(0.95, 0.62, 0.2)
const KURCZALIUM := Color(0.7, 0.3, 1.0)
const IRON := Color(0.68, 0.7, 0.76)

const LIST := {
	# --- MATERIAŁY ---------------------------------------------------------
	"sztabka_zelaza": {
		"name": "Sztabka żelaza", "slot": "material", "tier": 2, "price": 30, "icon": "sztabka", "stack": 99,
		"desc": "Zwykły, solidny metal. Podstawa każdego kowalskiego rzemiosła.", "stats": {}, "tint": Color(0.75, 0.78, 0.85),
	},
	"sztabka_kurczalu": {
		"name": "Sztabka kurczalu", "slot": "material", "tier": 4, "price": 120, "icon": "sztabka", "stack": 99, "rarity": "rzadki",
		"desc": "Złocistopomarańczowy metal wydobywany w kurzych kopalniach. Lekki i wytrzymały.", "stats": {}, "tint": Color(1.0, 0.7, 0.25),
	},
	"sztabka_kurczalium": {
		"name": "Sztabka kurczalium", "slot": "material", "tier": 6, "price": 0, "icon": "sztabka", "stack": 99, "rarity": "legendarny",
		"desc": "Fioletowy metal o własnej woli. Pulsuje, gdy ktoś znajduje się w pobliżu.", "stats": {}, "tint": Color(0.75, 0.35, 1.0),
	},
	"krysztal_cienia": {
		"name": "Diament", "slot": "material", "tier": 3, "price": 300, "icon": "diament", "stack": 99, "rarity": "rzadki",
		"desc": "Szlifowany diament. Do kupienia u kupca; składnik amuletów, run i kurczalium.", "stats": {}, "tint": Color(0.7, 0.95, 1.0),
	},
	"wegiel": {
		"name": "Węgiel", "slot": "material", "tier": 1, "price": 25, "icon": "krysztal", "stack": 99,
		"desc": "Czarny, brudny i niezastąpiony w laboratorium. Paliwo reakcji i składnik kurczalium.", "stats": {}, "tint": Color(0.28, 0.28, 0.33),
	},
	"pierwiastek_bu": {
		"name": "Pierwiastek BU", "slot": "material", "tier": 5, "price": 0, "icon": "krysztal", "stack": 99, "rarity": "epicki",
		"desc": "Niestabilny, jasnoniebieski pierwiastek wytwarzany w laboratorium. Bez niego nie powstanie kurczalium.", "stats": {}, "tint": Color(0.4, 0.95, 1.0),
	},
	"klucz_jaskini": {
		"name": "Klucz kruczej jaskini", "slot": "key", "tier": 2, "price": 0, "icon": "klucz", "stack": 5, "rarity": "niezwykly",
		"desc": "Otwiera ukryte przejścia w sekretnych jaskiniach.", "stats": {},
	},

	# --- BROŃ Z KUŹNI ------------------------------------------------------
	"miecz_zelazny": {
		"name": "Miecz żelazny", "slot": "weapon", "tier": 2, "price": 0, "icon": "miecz", "tint": Color(0.78, 0.8, 0.88), "rarity": "niezwykly",
		"desc": "Prosty, wyważony miecz. Ktoś go przecież musi mieć.",
		"stats": {"strength": 0.30, "crit": 0.03},
		"atk": {"dmg": 1.12, "light": [
			{"wind": 0.07, "active": 0.09, "rec": 0.15, "dmg": 10.0, "range": 50.0},
			{"wind": 0.08, "active": 0.09, "rec": 0.16, "dmg": 12.0, "range": 52.0},
			{"wind": 0.11, "active": 0.12, "rec": 0.24, "dmg": 17.0, "range": 56.0, "launch": true, "kb": 300.0},
		]},
		"vis": {"col": Color(0.78, 0.8, 0.88), "style": "sword", "len": 24.0},
	},
	"miecz_kurczalowy": {
		"name": "Miecz z kurczalu", "slot": "weapon", "tier": 4, "price": 0, "icon": "miecz", "tint": Color(1.0, 0.7, 0.25), "rarity": "rzadki",
		"desc": "Ostrze o ciepłym blasku. Tnie piórami i kośćmi z równą łatwością.",
		"stats": {"strength": 0.60, "crit": 0.07, "fury": 0.10},
		"atk": {"dmg": 1.25, "light": [
			{"wind": 0.065, "active": 0.09, "rec": 0.14, "dmg": 12.0, "range": 52.0},
			{"wind": 0.075, "active": 0.09, "rec": 0.15, "dmg": 14.0, "range": 54.0},
			{"wind": 0.10, "active": 0.12, "rec": 0.22, "dmg": 20.0, "range": 58.0, "launch": true, "kb": 330.0},
		], "on_hit": {"bleed": 1.0, "desc": "krwawi: +1.0"}},
		"vis": {"col": Color(1.0, 0.72, 0.28), "style": "sword", "len": 26.0, "glow": true},
	},
	"miecz_kurczaliowy": {
		"name": "Miecz z kurczalium", "slot": "weapon", "tier": 6, "price": 0, "icon": "miecz", "tint": Color(0.75, 0.35, 1.0), "rarity": "legendarny",
		"desc": "Fioletowa klinga szepcze imiona pokonanych wrogów. Tnie szybciej, niż myślisz.",
		"stats": {"strength": 0.95, "crit": 0.12, "fury": 0.30},
		"atk": {"dmg": 1.4, "light": [
			{"wind": 0.055, "active": 0.09, "rec": 0.13, "dmg": 14.0, "range": 56.0},
			{"wind": 0.065, "active": 0.09, "rec": 0.14, "dmg": 16.0, "range": 58.0},
			{"wind": 0.09, "active": 0.12, "rec": 0.2, "dmg": 24.0, "range": 62.0, "launch": true, "kb": 360.0},
		], "on_hit": {"heal": 2.5, "bleed": 1.2, "desc": "leczy i krwawi"}},
		"vis": {"col": Color(0.78, 0.4, 1.0), "style": "sword", "len": 28.0, "glow": true},
	},

	# --- ZBROJE Z KUŹNI ----------------------------------------------------
	"zbroja_zelazna": {
		"name": "Zbroja żelazna", "slot": "armor", "tier": 2, "price": 0, "icon": "pancerz", "tint": Color(0.78, 0.8, 0.88), "rarity": "niezwykly",
		"desc": "Ciężka, ale pewna. Stuka przy każdym kroku.",
		"stats": {"defense": 0.30, "health": 25.0},
		"vis": {"col": Color(0.66, 0.68, 0.74), "trim": Color(0.9, 0.9, 0.95)},
	},
	"zbroja_kurczalowa": {
		"name": "Zbroja z kurczalu", "slot": "armor", "tier": 4, "price": 0, "icon": "pancerz", "tint": Color(1.0, 0.7, 0.25), "rarity": "rzadki",
		"desc": "Złociste płyty, lekkie jak puch. Krucze pióra odbijają się od niej bez echa.",
		"stats": {"defense": 0.58, "health": 45.0, "poise": 0.2},
		"vis": {"col": Color(0.95, 0.62, 0.2), "trim": Color(1.0, 0.9, 0.55)},
	},
	"zbroja_kurczaliowa": {
		"name": "Zbroja z kurczalium", "slot": "armor", "tier": 6, "price": 0, "icon": "pancerz", "tint": Color(0.75, 0.35, 1.0), "rarity": "legendarny",
		"desc": "Fioletowy metal pulsuje własnym życiem. Zapisz na niej runy CZARKA lub KURCZAK, a obudzisz jej płomienie.",
		"stats": {"defense": 0.95, "health": 90.0, "poise": 0.5, "strength": 0.10, "fury": 0.20, "speed": 0.05},
		"fx": {"dmg_reduction": 0.06},
		"vis": {"col": Color(0.5, 0.18, 0.78), "trim": Color(0.95, 0.7, 1.0)},
	},

	# --- AMULETY ------------------------------------------------------------
	"amulet_zelazny": {
		"name": "Amulet żelazny", "slot": "amulet", "tier": 2, "price": 0, "icon": "amulet", "tint": Color(0.75, 0.8, 0.9), "rarity": "niezwykly",
		"desc": "Prosty talizman z żelaznym oczkiem. Chroni zdrowie i dodaje energii.",
		"stats": {"health": 20.0, "energy": 15.0},
		"vis": {"col": Color(0.7, 0.78, 0.9)},
	},
	"amulet_szczescia": {
		"name": "Amulet Szczęścia", "slot": "amulet", "tier": 2, "price": 90, "icon": "amulet", "tint": Color(0.5, 0.9, 0.5), "rarity": "niezwykly",
		"desc": "Czterolistna koniczyna w mosiężnej oprawie. Zwiększa szanse na łupy.",
		"stats": {"luck": 0.12, "health": 10.0},
		"vis": {"col": Color(0.5, 0.9, 0.5)},
	},
	"amulet_kurczalowy": {
		"name": "Amulet z kurczalu", "slot": "amulet", "tier": 4, "price": 0, "icon": "amulet", "tint": Color(1.0, 0.7, 0.25), "rarity": "rzadki",
		"desc": "Złoty amulet z diamentem. Wzmacnia cios i przynosi szczęście.",
		"stats": {"strength": 0.20, "crit": 0.06, "luck": 0.10},
		"vis": {"col": Color(1.0, 0.75, 0.3)},
	},
	"amulet_kurczaliowy": {
		"name": "Amulet z kurczalium", "slot": "amulet", "tier": 6, "price": 0, "icon": "amulet", "tint": Color(0.75, 0.35, 1.0), "rarity": "legendarny",
		"desc": "Pulsuje w rytmie serca właściciela. Rany goją się same.",
		"stats": {"strength": 0.30, "defense": 0.20},
		"fx": {"regen": 1.5},
		"vis": {"col": Color(0.8, 0.45, 1.0)},
	},

	# --- HEŁMY I BUTY -------------------------------------------------------
	"helm_skorzany": {
		"name": "Hełm skórzany", "slot": "helmet", "tier": 1, "price": 40, "icon": "helm", "tint": Color(0.7, 0.5, 0.3), "rarity": "zwykly",
		"desc": "Skóra i nadzieja. Lepsze niż gołe czoło.", "stats": {"defense": 0.08, "health": 6.0},
		"vis": {"col": Color(0.62, 0.45, 0.28)},
	},
	"helm_zelazny": {
		"name": "Hełm żelazny", "slot": "helmet", "tier": 3, "price": 110, "icon": "helm", "tint": Color(0.78, 0.8, 0.88), "rarity": "rzadki",
		"desc": "Rogaty? Nie. Za to solidny.", "stats": {"defense": 0.2, "health": 14.0, "poise": 0.1},
		"vis": {"col": Color(0.7, 0.72, 0.78)},
	},
	"buty_skorzane": {
		"name": "Buty skórzane", "slot": "boots", "tier": 1, "price": 35, "icon": "buty", "tint": Color(0.7, 0.5, 0.3), "rarity": "zwykly",
		"desc": "Dobre na długie trakty.", "stats": {"speed": 0.05, "energy": 6.0},
		"vis": {"col": Color(0.5, 0.34, 0.2)},
	},
	"buty_okute": {
		"name": "Buty okute", "slot": "boots", "tier": 3, "price": 100, "icon": "buty", "tint": Color(0.78, 0.8, 0.88), "rarity": "rzadki",
		"desc": "Tupot słychać z daleka. Przeciwnicy też.", "stats": {"speed": 0.08, "defense": 0.14, "poise": 0.1},
		"vis": {"col": Color(0.62, 0.64, 0.7)},
	},

	"pazur_czarnego_kruka": {
		"name": "Pazur Czarnego Kruka", "slot": "weapon", "tier": 7, "price": 0, "icon": "szabla", "tint": Color(0.7, 0.3, 1.0), "rarity": "legendarny",
		"desc": "Wyrwany z łapy władcy czarnych skrzydeł. Każdy cios szepcze mroczną pieśń.",
		"stats": {"strength": 1.05, "crit": 0.16, "fury": 0.25},
		"fx": {"lifesteal": 0.05},
		"atk": {"dmg": 1.45, "on_hit": {"heal": 2.0, "bleed": 1.4, "desc": "krwawi i leczy"}},
		"vis": {"col": Color(0.72, 0.35, 1.0), "style": "sword", "len": 29.0, "glow": true},
	},

	# --- LEGENDARNE NAGRODY Z JASKIŃ ---------------------------------------
	"szpon_burzy": {
		"name": "Szpon Burzy", "slot": "weapon", "tier": 6, "price": 0, "icon": "szabla", "tint": Color(0.5, 0.85, 1.0), "rarity": "legendarny",
		"desc": "Wyrwany z gniazda burzy. Każde trafienie leczy właściciela.",
		"stats": {"strength": 0.82, "crit": 0.14, "speed": 0.08},
		"fx": {"lifesteal": 0.06},
		"atk": {"dmg": 1.3, "on_hit": {"heal": 1.5, "desc": "kradnie życie"}},
		"vis": {"col": Color(0.55, 0.88, 1.0), "style": "sword", "len": 27.0, "glow": true},
	},
	"zbroja_switu": {
		"name": "Pancerz Świtu", "slot": "armor", "tier": 6, "price": 0, "icon": "pancerz", "tint": Color(1.0, 0.9, 0.55), "rarity": "legendarny",
		"desc": "Połyskuje, jakby noc nigdy się nie zaczęła. Zmniejsza każdy otrzymany cios.",
		"stats": {"defense": 0.75, "health": 70.0, "poise": 0.35},
		"fx": {"dmg_reduction": 0.08},
		"vis": {"col": Color(0.98, 0.88, 0.5), "trim": Color(1.0, 1.0, 0.85)},
	},
	"helm_krola": {
		"name": "Hełm Króla Kur", "slot": "helmet", "tier": 6, "price": 0, "icon": "helm", "tint": Color(1.0, 0.85, 0.35), "rarity": "legendarny",
		"desc": "Nosił go ktoś, kto wiedział, ile warte jest doświadczenie.",
		"stats": {"defense": 0.30, "health": 30.0, "luck": 0.20},
		"fx": {"xp_mult": 0.15},
		"vis": {"col": Color(0.98, 0.82, 0.3)},
	},
	"buty_wichru": {
		"name": "Buty Wichru", "slot": "boots", "tier": 6, "price": 0, "icon": "buty", "tint": Color(0.6, 0.9, 1.0), "rarity": "legendarny",
		"desc": "Sznurówki same się wiążą. Nogi same biegną.",
		"stats": {"speed": 0.25, "energy": 20.0, "poise": 0.15},
		"vis": {"col": Color(0.55, 0.85, 0.95)},
	},
	"amulet_feniksa": {
		"name": "Amulet Feniksa", "slot": "amulet", "tier": 6, "price": 0, "icon": "amulet", "tint": Color(1.0, 0.45, 0.2), "rarity": "legendarny",
		"desc": "Ciepły jak ognisko. Leczy powoli, ale bez końca.",
		"stats": {"health": 40.0, "strength": 0.15},
		"fx": {"regen": 2.5},
		"vis": {"col": Color(1.0, 0.5, 0.2)},
	},
	"amulet_zlotej_kury": {
		"name": "Amulet Złotej Kury", "slot": "amulet", "tier": 5, "price": 0, "icon": "amulet", "tint": Color(1.0, 0.9, 0.3), "rarity": "epicki",
		"desc": "Złoto samo przyciąga złoto.",
		"stats": {"luck": 0.25},
		"fx": {"gold_mult": 0.35},
		"vis": {"col": Color(1.0, 0.9, 0.3)},
	},

	"helm_krukobojcy": {
		"name": "Hełm Krukobójcy", "slot": "helmet", "tier": 6, "price": 0, "icon": "helm", "tint": Color(0.9, 0.5, 0.35), "rarity": "legendarny",
		"desc": "Zdobyty w ukrytej piwnicy Zielonki. Ostrzega przed każdym ciosem z góry.",
		"stats": {"defense": 0.34, "health": 40.0, "crit": 0.05}, "fx": {"dmg_reduction": 0.05},
		"vis": {"col": Color(0.92, 0.52, 0.36)},
	},
	"buty_cienia": {
		"name": "Buty Cienia", "slot": "boots", "tier": 6, "price": 0, "icon": "buty", "tint": Color(0.55, 0.4, 0.8), "rarity": "legendarny",
		"desc": "Cicho jak cień na bagnie. Dodają szybkości i pewności kroku.",
		"stats": {"speed": 0.22, "poise": 0.2, "crit": 0.04}, "vis": {"col": Color(0.5, 0.38, 0.75)},
	},
	"amulet_zemsty": {
		"name": "Amulet Zemsty", "slot": "amulet", "tier": 7, "price": 0, "icon": "amulet", "tint": Color(1.0, 0.3, 0.35), "rarity": "legendarny",
		"desc": "Pulsuje gniewem wyzwolonych wiosek. Każde trafienie odnawia siły.",
		"stats": {"strength": 0.4, "crit": 0.08}, "fx": {"lifesteal": 0.04, "xp_mult": 0.1}, "vis": {"col": Color(1.0, 0.3, 0.35)},
	},

	# --- WYPOSAŻENIE PETÓW (tylko dla towarzyszy) -------------------------------
	"luk_przepiorczy": {
		"name": "Łuk przepiórczy", "slot": "pet_gear", "pet_only": true, "tier": 3, "price": 140, "icon": "luk", "rarity": "rzadki",
		"desc": "Mini-łuk dla pupila. Jaja lecą szybciej i mocniej. (Tylko dla petów.)",
		"stats": {"pet_dmg": 0.35, "pet_speed": 0.15},
	},
	"kolczuga_pupila": {
		"name": "Kolczuga pupila", "slot": "pet_gear", "pet_only": true, "tier": 3, "price": 120, "icon": "pancerz", "tint": Color(0.7, 0.75, 0.85), "rarity": "rzadki",
		"desc": "Maleńka kolczuga. Pet jest dzięki niej wytrzymalszy. (Tylko dla petów.)",
		"stats": {"pet_hp": 0.5},
	},
	"obroza_polowania": {
		"name": "Obroża łowcy", "slot": "pet_gear", "pet_only": true, "tier": 4, "price": 0, "icon": "obroza", "tint": Color(0.95, 0.5, 0.3), "rarity": "epicki",
		"desc": "Skraca czas między atakami pupila i zwiększa zasięg. (Tylko dla petów.)",
		"stats": {"pet_speed": 0.3, "pet_range": 0.25},
	},
}
