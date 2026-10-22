class_name SkillDB
extends RefCounted
## Baza skilli przypisywanych do slotów w ekwipunku (3x3).
## Skile kosztują energię (żółty pasek) i mają cooldown.

const LIST := {
	"furia": {
		"name": "Furia", "type": "special",
		"desc": "Wściekły atak obszarowy. Ładuje się trafieniami (nie podczas trwania furii).",
		"cost": 60.0, "cd": 2.0, "col": Color(1.0, 0.65, 0.15),
	},
	"cios_mocy": {
		"name": "Cios Mocy", "type": "aoe",
		"desc": "Rozwala wrogów wokół ciosm o dużym odrzucie.",
		"cost": 28.0, "cd": 5.0, "dmg": 46.0, "radius": 140.0, "kb": 320.0,
		"col": Color(0.95, 0.45, 0.4),
	},
	"eklipsa": {
		"name": "Eklipsa", "type": "aoe",
		"desc": "Potężna fala uderzeniowa na dużym obszarze.",
		"cost": 55.0, "cd": 18.0, "dmg": 72.0, "radius": 210.0, "kb": 420.0,
		"col": Color(0.6, 0.35, 0.9),
	},
	"pocisk": {
		"name": "Pocisk", "type": "projectile",
		"desc": "Wystrzukuje szybki pocisk przed siebie.",
		"cost": 14.0, "cd": 2.5, "dmg": 20.0,
		"col": Color(0.5, 0.8, 0.95),
	},
	"kopniak": {
		"name": "Kopniak", "type": "dash_strike",
		"desc": "Pędzi do przodu z ciosem w biegu.",
		"cost": 22.0, "cd": 4.0, "dmg": 30.0,
		"col": Color(0.75, 0.9, 0.4),
	},
	"uzdrowienie": {
		"name": "Uzdrowienie", "type": "heal",
		"desc": "Natychmiast leczy część życia.",
		"cost": 45.0, "cd": 14.0, "heal": 36.0,
		"col": Color(0.4, 0.9, 0.5),
	},
	"tarcza": {
		"name": "Tarcza", "type": "shield",
		"desc": "Kilka sekund nietykalności.",
		"cost": 34.0, "cd": 16.0, "duration": 2.6,
		"col": Color(0.85, 0.9, 1.0),
	},
	"warcry": {
		"name": "Wojenny Krzyk", "type": "buff",
		"desc": "Chwilowo zwiększa siłę i szybkość.",
		"cost": 30.0, "cd": 20.0, "duration": 8.0, "strength": 0.35, "speed": 0.25,
		"col": Color(1.0, 0.8, 0.3),
	},
	# --- Wojownik ---
	"szal_bojowy": {
		"name": "Szał Bojowy", "type": "berserk",
		"desc": "Tracisz panowanie nad postacią. Wzmocniony atak i życie, atakuje wszystko po kolei — także graczy.",
		"cost": 50.0, "cd": 26.0, "duration": 8.0, "hp_mult": 1.6, "atk_mult": 1.7,
		"col": Color(0.95, 0.25, 0.2),
	},
	"potezny_zamach": {
		"name": "Potężny Zamach", "type": "power_swing",
		"desc": "Potężny, szeroki zamach odrzucający wszystko przed tobą.",
		"cost": 30.0, "cd": 6.0, "dmg": 60.0, "kb": 520.0, "range": 96.0,
		"col": Color(0.95, 0.55, 0.25),
	},
	# --- Łucznik ---
	"headshot": {
		"name": "Headshot", "type": "headshot",
		"desc": "Precyzyjny strzał w głowę — zawsze krytyczny.",
		"cost": 22.0, "cd": 6.0, "dmg": 44.0,
		"col": Color(0.85, 0.95, 0.4),
	},
	"trojszot": {
		"name": "Trójszot", "type": "triple_shot",
		"desc": "Wypuszcza trzy strzały w wachlarzu.",
		"cost": 30.0, "cd": 7.0, "dmg": 18.0, "spread": 22.0,
		"col": Color(0.6, 0.9, 0.5),
	},
	# --- Fechmistrz ---
	"piruet": {
		"name": "Piruet", "type": "pirouette",
		"desc": "Obraca się z mieczem, raniąc wszystko dookoła.",
		"cost": 26.0, "cd": 5.0, "dmg": 34.0, "radius": 120.0,
		"col": Color(0.7, 0.85, 1.0),
	},
	"krag_antypotworowy": {
		"name": "Krąg Antypotworowy", "type": "barrier",
		"desc": "Przez 30 s potwory nie mogą wejść do kręgu. Gracze mogą.",
		"cost": 45.0, "cd": 40.0, "duration": 30.0, "radius": 130.0,
		"col": Color(0.5, 0.95, 0.95),
	},
	# --- Złodziej ---
	"kradziez": {
		"name": "Kradzież", "type": "steal",
		"desc": "Otwiera ekwipunek innych i rozbraja najbliższego potwora.",
		"cost": 0.0, "cd": 10.0,
		"col": Color(0.55, 0.5, 0.65),
	},
	"cien": {
		"name": "Cień", "type": "shadow",
		"desc": "Ukrywa się w cieniach — nietykalny i niewidzialny dla wrogów.",
		"cost": 25.0, "cd": 16.0, "duration": 4.5,
		"col": Color(0.25, 0.25, 0.4),
	},
	# --- Mag (zaklęcia z księgi) ---
	"kula_ognia": {
		"name": "Kula Ognia", "type": "projectile",
		"desc": "Zaklęcie: ognisty pocisk zadający duże obrażenia.",
		"cost": 18.0, "cd": 2.5, "dmg": 30.0,
		"col": Color(1.0, 0.55, 0.2),
	},
	"lodowa_lanca": {
		"name": "Lodowa Lanca", "type": "projectile",
		"desc": "Zaklęcie: lodowy pocisk, który ogłusza trafionych.",
		"cost": 20.0, "cd": 4.0, "dmg": 22.0, "stun": 1.0,
		"col": Color(0.55, 0.8, 1.0),
	},
	"iskra": {
		"name": "Iskra", "type": "aoe",
		"desc": "Zaklęcie: błyskawica rażąca wszystko dookoła.",
		"cost": 25.0, "cd": 6.0, "dmg": 40.0, "radius": 150.0, "kb": 260.0,
		"col": Color(0.9, 0.85, 0.4),
	},
	# --- Lady ---
	"oszolomienie": {
		"name": "Oszołomienie", "type": "stun_all",
		"desc": "Wszyscy wokół nie mogą się ruszać ani atakować. Działa też na graczy.",
		"cost": 45.0, "cd": 20.0, "duration": 3.0, "radius": 170.0,
		"col": Color(0.85, 0.6, 1.0),
	},
}

static func default_slots() -> Array:
	return ["furia", "", "", "", "", ""]

static func has(id: String) -> bool:
	return LIST.has(id)

static func get_data(id: String) -> Dictionary:
	return LIST.get(id, {})

static func all() -> Array:
	return LIST.keys()
