class_name CaveBossDB
extends RefCounted
## Bossowie na końcu sekretnych jaskiń: każdy dzierży legendarną broń, którą jaskinia nagradza
## (albo inny najcenniejszy przedmiot z nagrody) i oddaje ją dopiero po pokonaniu.

const SPECIES := ["kruk", "orzel_szarak", "bocian_gruby", "krol_krukow", "sep", "sowa_wieszczka", "kruk", "sep_cesarski"]
const PALS := [
	{"body": Color(0.14, 0.14, 0.2), "shade": Color(0.06, 0.06, 0.1), "beak": Color(0.75, 0.75, 0.8), "eye": Color(1.0, 0.4, 0.15)},
	{"body": Color(0.3, 0.2, 0.14), "shade": Color(0.14, 0.09, 0.06), "beak": Color(0.95, 0.75, 0.25), "eye": Color(1.0, 0.55, 0.15)},
	{"body": Color(0.22, 0.28, 0.4), "shade": Color(0.1, 0.13, 0.22), "beak": Color(0.9, 0.85, 0.5), "eye": Color(0.5, 0.9, 1.0)},
	{"body": Color(0.3, 0.14, 0.34), "shade": Color(0.14, 0.06, 0.18), "beak": Color(0.9, 0.7, 0.9), "eye": Color(1.0, 0.3, 0.9)},
]
const PREFIX := ["Strażnik", "Kasztelan", "Łowca", "Skarbnik", "Pogromca", "Wartownik", "Cieniobójca", "Namiestnik"]

static var LIST: Dictionary = _build()

static func id_for(cave_id: String) -> String:
	return "cavebos_" + cave_id

## Najcenniejszy przedmiot z nagrody jaskini: broń, a w razie jej braku — pierwszy sprzęt.
static func trophy_of(cave: Dictionary) -> String:
	var items: Dictionary = (cave.get("reward", {}) as Dictionary).get("items", {})
	var best := ""
	for id in items:
		var d: Dictionary = ItemsExtra.LIST.get(String(id), {})
		if String(d.get("slot", "")) == "weapon":
			return String(id)
		if best == "" and String(d.get("slot", "")) in ["armor", "helmet", "boots", "amulet", "accessory"]:
			best = String(id)
	return best

static func _build() -> Dictionary:
	var out := {}
	var i := 0
	for zone_id in SecretDB.CAVES:
		var cave: Dictionary = SecretDB.CAVES[zone_id]
		var trophy := trophy_of(cave)
		var tname := String(ItemsExtra.LIST.get(trophy, {}).get("name", "legendarną broń")) if trophy != "" else "skarb jaskini"
		var sp := String(SPECIES[i % SPECIES.size()])
		var base_hp := 700.0 + 170.0 * float(i)
		out[id_for(String(cave["id"]))] = {
			"name": "%s — %s" % [String(PREFIX[i % PREFIX.size()]), String(cave["name"])],
			"title": "Dzierżyciel: %s" % tname, "species": sp, "scale": 2.0 + 0.03 * float(i), "hp": base_hp, "dmg": 16.0 + 1.8 * float(i), "speed": 125.0,
			"xp": 300 + 40 * i, "gold": 150 + 30 * i, "defense": 0.05 + 0.01 * float(i),
			"phases": [
				{"at": 1.0, "attacks": ["swipe_combo", "charge", "feather_fan"], "cd": [1.1, 1.7], "speed": 1.0},
				{"at": 0.5, "attacks": ["charge", "feather_fan", "ground_pound", "lightning"], "cd": [0.8, 1.3], "speed": 1.2, "name": "STRAŻNIK WZYWA MOC BRONI"},
			],
			"intro": [[String(cave["name"]), "Kto śmie zakłócać spokój tej jaskini? Nie oddam ci: %s!" % tname]],
			"death": [[String(cave["name"]), "Zabierz ją... Ta broń wybrała ciebie."]],
			"reward": {"gold": 80 + 20 * i, "items": {}},
			"pal": PALS[i % PALS.size()],
			"trophy": trophy,
		}
		i += 1
	return out
