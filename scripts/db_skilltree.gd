class_name SkillTreeDB
extends RefCounted
## Drzewka umiejętności — każda klasa ma własne, osobne drzewko (gałęzie, kolejność i wymagania).
## Węzeł = umiejętność z SkillDB. Wymagania: poziom postaci, poprzednie węzły i punkty
## (1 punkt za każdy poziom, maks. poziom 100). Każdy kolejny rank wymaga wyższego poziomu:
## req_level + (rank-1) * RANK_LEVEL_STEP i zwiększa skuteczność o RANK_BONUS.
## Umiejętności sygnaturowe klasy (SkillDB / ClassDatabase) są dostępne od początku.

const RANK_LEVEL_STEP := 8
const RANK_BONUS := 0.2

## Drzewka klas są zdefiniowane w ClassSkillDB (każda klasa ma własne umiejętności).
static var TREES: Dictionary = ClassSkillDB.trees()

static func _cls(class_id: String) -> String:
	return class_id if class_id != "" else GameState.class_id()

static func tree(class_id: String = "") -> Dictionary:
	return TREES.get(_cls(class_id), {"branches": {}, "nodes": {}})

static func branches(class_id: String = "") -> Dictionary:
	return tree(class_id)["branches"]

static func has(id: String, class_id: String = "") -> bool:
	return (tree(class_id)["nodes"] as Dictionary).has(id)

static func node(id: String, class_id: String = "") -> Dictionary:
	return (tree(class_id)["nodes"] as Dictionary).get(id, {})

## Węzły drzewka klasy (kolejność: gałąź, poziom).
static func for_class(class_id: String) -> Array:
	var nodes: Dictionary = tree(class_id)["nodes"]
	var out: Array = nodes.keys()
	out.sort_custom(func(a, b):
		var na: Dictionary = nodes[a]
		var nb: Dictionary = nodes[b]
		if String(na["branch"]) != String(nb["branch"]):
			return String(na["branch"]) < String(nb["branch"])
		return int(na["req_level"]) < int(nb["req_level"]))
	return out

static func rank_level(id: String, rank: int, class_id: String = "") -> int:
	return int(node(id, class_id).get("req_level", 1)) + maxi(0, rank - 1) * RANK_LEVEL_STEP

static func scale(rank: int) -> float:
	return 1.0 + RANK_BONUS * float(maxi(0, rank - 1))
