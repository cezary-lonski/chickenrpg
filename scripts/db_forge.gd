class_name ForgeDB
extends RefCounted
## Receptury kowalskie. Wybór: co kuć (miecz / zbroja / amulet) i z jakiego metalu.
## Koszty: miecz 1 sztabka + 1 węgiel, zbroja 5 sztabek + 3 węgle, amulet 2 sztabki + diament + węgiel.

const KINDS := {
	"sword": {"name": "Miecz", "bars": 1, "extra": {"wegiel": 1}, "icon": "miecz"},
	"armor": {"name": "Zbroja", "bars": 5, "extra": {"wegiel": 3}, "icon": "pancerz"},
	"amulet": {"name": "Amulet", "bars": 2, "extra": {"krysztal_cienia": 1, "wegiel": 1}, "icon": "amulet"},
}

const METALS := {
	"zelazo": {"name": "Żelazo", "bar": "sztabka_zelaza", "col": Color(0.75, 0.78, 0.85), "known": true},
	"kurczal": {"name": "Kurczal", "bar": "sztabka_kurczalu", "col": Color(1.0, 0.7, 0.25), "known": true},
	"kurczalium": {"name": "Kurczalium", "bar": "sztabka_kurczalium", "col": Color(0.75, 0.35, 1.0), "known": false},
}

const RESULTS := {
	"sword": {"zelazo": "miecz_zelazny", "kurczal": "miecz_kurczalowy", "kurczalium": "miecz_kurczaliowy"},
	"armor": {"zelazo": "zbroja_zelazna", "kurczal": "zbroja_kurczalowa", "kurczalium": "zbroja_kurczaliowa"},
	"amulet": {"zelazo": "amulet_zelazny", "kurczal": "amulet_kurczalowy", "kurczalium": "amulet_kurczaliowy"},
}

## Progi jakości wyniku minigry (0–1) → nazwa i mnożnik statystyk.
const QUALITY := [
	{"min": 0.0, "name": "Nieudane", "mult": 0.0},
	{"min": 0.25, "name": "Przeciętne", "mult": 0.90},
	{"min": 0.55, "name": "Dobre", "mult": 1.0},
	{"min": 0.85, "name": "Mistrzowskie", "mult": 1.15},
	{"min": 0.97, "name": "Arcydzieło", "mult": 1.25},
]

static func result_id(kind: String, metal: String) -> String:
	return String(RESULTS.get(kind, {}).get(metal, ""))

static func quality_of(score: float) -> Dictionary:
	var out: Dictionary = QUALITY[0]
	for q in QUALITY:
		if score >= float(q["min"]):
			out = q
	return out

## Wymagane składniki: {id: ilość}
static func cost(kind: String, metal: String) -> Dictionary:
	var k: Dictionary = KINDS[kind]
	var out := {String(METALS[metal]["bar"]): int(k["bars"])}
	for id in k["extra"]:
		out[String(id)] = int(k["extra"][id])
	return out

## Przy porażce przepada połowa sztabek (zaokrąglona w dół), reszta wraca. Nigdy wszystko.
static func fail_loss(kind: String, metal: String) -> Dictionary:
	var out := {}
	var c := cost(kind, metal)
	for id in c:
		var n := int(c[id])
		var lost := n / 2
		if lost > 0:
			out[id] = lost
	return out

## Metal znany: żelazo i kurczal od początku; kurczalium po odkryciu receptury
## (zwój z sekretnej jaskini lub rozdział V i dalej).
static func metal_known(metal: String) -> bool:
	if bool(METALS[metal]["known"]):
		return true
	var known: Array = GameState.profile.get("craft", {}).get("known", [])
	return metal in known or GameState.story_chapter() >= QuestDB.index_of("marsz_na_forteca")

static func learn_metal(metal: String) -> void:
	var craft: Dictionary = GameState.profile["craft"]
	var known: Array = craft.get("known", [])
	if metal not in known:
		known.append(metal)
	craft["known"] = known
	GameState.save_game()
