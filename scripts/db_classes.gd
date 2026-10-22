class_name ClassDatabase
extends RefCounted
## Klasy postaci RPG. Każda klasa daje zestaw sygnaturowych umiejętności,
## które trafiają do slotów w ekwipunku (3x3). Reszta slotów do wypełnienia.

const LIST := {
	"wojownik": {
		"title": "Wojownik",
		"desc": "Brutalna siła. Szał bojowy i potężne zamachy.",
		"col": Color(0.95, 0.35, 0.25),
		"skills": ["szal_bojowy", "potezny_zamach"],
	},
	"lucznik": {
		"title": "Łucznik",
		"desc": "Precyzja z dystansu. Headshot i trójszot.",
		"col": Color(0.6, 0.9, 0.5),
		"skills": ["headshot", "trojszot"],
	},
	"fechmistrz": {
		"title": "Fechmistrz",
		"desc": "Taniec ostrza. Piruet i krąg antypotworowy.",
		"col": Color(0.7, 0.85, 1.0),
		"skills": ["piruet", "krag_antypotworowy"],
	},
	"zlodziej": {
		"title": "Złodziej",
		"desc": "Cień i kradzież. Otwiera cudzy ekwipunek, rozbraja wrogów.",
		"col": Color(0.55, 0.5, 0.65),
		"skills": ["kradziez", "cien"],
	},
	"mag": {
		"title": "Mag",
		"desc": "Księga zaklęć zamiast umiejętności. Kula ognia, lodowa lanca, iskra.",
		"col": Color(0.6, 0.45, 0.95),
		"skills": ["kula_ognia", "lodowa_lanca", "iskra"],
	},
	"lady": {
		"title": "Lady",
		"desc": "Opanowanie i wsparcie. Zaklęcie oszołomienia ogłusza wszystkich wokół.",
		"col": Color(0.98, 0.65, 0.8),
		"skills": ["oszolomienie", "uzdrowienie", "tarcza"],
		"female_only": true,
	},
}

static func has(id: String) -> bool:
	return LIST.has(id)

static func get_data(id: String) -> Dictionary:
	return LIST.get(id, {})

static func all() -> Array:
	return LIST.keys()

## Klasy dostępne dla danej postaci (roli).
static func for_character(char_id: String) -> Array:
	var role := String(CharacterDB.get_data(char_id).get("role", ""))
	var out: Array = []
	for id in LIST:
		var d: Dictionary = LIST[id]
		if bool(d.get("female_only", false)) and role != "lady":
			continue
		if id == "wojownik" and role == "lady":
			continue
		out.append(id)
	return out

## Domyślne sloty (6) z sygnaturowymi umiejętnościami klasy.
static func default_slots(class_id: String) -> Array:
	var slots := ["", "", "", "", "", ""]
	var sk: Array = get_data(class_id).get("skills", [])
	for i in range(mini(sk.size(), slots.size())):
		slots[i] = sk[i]
	return slots
