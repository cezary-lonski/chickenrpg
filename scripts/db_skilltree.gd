class_name SkillTreeDB
extends RefCounted
## Drzewka umiejętności — każda klasa ma własne, osobne drzewko (gałęzie, kolejność i wymagania).
## Węzeł = umiejętność z SkillDB. Wymagania: poziom postaci, poprzednie węzły i punkty
## (1 punkt za każdy poziom, maks. poziom 100). Każdy kolejny rank wymaga wyższego poziomu:
## req_level + (rank-1) * RANK_LEVEL_STEP i zwiększa skuteczność o RANK_BONUS.
## Umiejętności sygnaturowe klasy (SkillDB / ClassDatabase) są dostępne od początku.

const RANK_LEVEL_STEP := 8
const RANK_BONUS := 0.2

static func _n(branch: String, lv: int, req: Array, rank: int) -> Dictionary:
	return {"branch": branch, "req_level": lv, "req": req, "max_rank": rank}

static func _br(name: String, col: Color) -> Dictionary:
	return {"name": name, "col": col}

static var TREES: Dictionary = _build()

static func _build() -> Dictionary:
	var t := {}
	t["wojownik"] = {
		"branches": {"a": _br("Furia i siła", Color(0.95, 0.45, 0.35)), "b": _br("Pancerz i szarża", Color(0.6, 0.75, 1.0)), "c": _br("Dowodzenie", Color(1.0, 0.85, 0.4))},
		"nodes": {
			"cios_mocy": _n("a", 4, [], 3), "wstrzas": _n("a", 6, ["cios_mocy"], 3), "krag_ognia": _n("a", 14, ["wstrzas"], 3),
			"burza_pior": _n("a", 20, ["krag_ognia"], 3), "eklipsa": _n("a", 26, ["burza_pior"], 2),
			"wicher_ostrzy": _n("a", 30, ["eklipsa", "bastion"], 3), "furia_tytana": _n("a", 40, ["wicher_ostrzy"], 1),
			"zelazna_skora": _n("b", 5, [], 3), "bastion": _n("b", 18, ["zelazna_skora"], 2), "szarza": _n("b", 8, [], 3), "kopniak": _n("b", 7, [], 2),
			"warcry": _n("c", 6, [], 3), "krzyk_ogluszajacy": _n("c", 12, ["wstrzas"], 2), "komenda_ataku": _n("c", 7, [], 3), "ochrona_pupila": _n("c", 15, ["komenda_ataku"], 2),
		},
	}
	t["lucznik"] = {
		"branches": {"a": _br("Strzelectwo", Color(0.6, 0.9, 0.5)), "b": _br("Zwinność", Color(0.45, 0.85, 0.95)), "c": _br("Pułapki i kontrola", Color(0.8, 0.6, 1.0))},
		"nodes": {
			"pocisk": _n("a", 3, [], 3), "burza_pior": _n("a", 20, ["pocisk"], 3), "eklipsa": _n("a", 26, ["burza_pior"], 2),
			"wicher_ostrzy": _n("a", 30, ["burza_pior", "chmurowy_wzlot"], 3), "furia_tytana": _n("a", 40, ["wicher_ostrzy"], 1),
			"unik_mgla": _n("b", 4, [], 2), "szarza": _n("b", 8, ["unik_mgla"], 3), "chmurowy_wzlot": _n("b", 10, ["unik_mgla"], 3), "cien": _n("b", 15, ["unik_mgla"], 2),
			"okowy_lodu": _n("c", 9, [], 3), "wstrzas": _n("c", 6, [], 3), "krzyk_ogluszajacy": _n("c", 12, ["wstrzas"], 2),
			"komenda_ataku": _n("c", 7, [], 3), "ochrona_pupila": _n("c", 15, ["komenda_ataku"], 2), "odnowa": _n("c", 3, [], 3),
		},
	}
	t["fechmistrz"] = {
		"branches": {"a": _br("Szermierka", Color(1.0, 0.65, 0.35)), "b": _br("Zwinność", Color(0.45, 0.85, 0.95)), "c": _br("Obrona", Color(0.6, 0.75, 1.0))},
		"nodes": {
			"kopniak": _n("a", 4, [], 3), "cios_mocy": _n("a", 6, ["kopniak"], 3), "potezny_zamach": _n("a", 10, ["kopniak"], 3), "krag_ognia": _n("a", 14, ["cios_mocy"], 3),
			"wicher_ostrzy": _n("a", 30, ["krag_ognia", "bastion"], 3), "furia_tytana": _n("a", 40, ["wicher_ostrzy"], 1),
			"unik_mgla": _n("b", 4, [], 2), "szarza": _n("b", 8, ["unik_mgla"], 3), "chmurowy_wzlot": _n("b", 10, ["unik_mgla"], 3), "okowy_lodu": _n("b", 9, [], 3),
			"zelazna_skora": _n("c", 5, [], 3), "bastion": _n("c", 18, ["zelazna_skora"], 2), "tarcza": _n("c", 9, [], 2), "odnowa": _n("c", 3, [], 3),
		},
	}
	t["zlodziej"] = {
		"branches": {"a": _br("Cień", Color(0.7, 0.6, 0.9)), "b": _br("Podstęp", Color(0.95, 0.8, 0.4)), "c": _br("Łupy i zamieszanie", Color(0.5, 0.95, 0.6))},
		"nodes": {
			"unik_mgla": _n("a", 4, [], 2), "chmurowy_wzlot": _n("a", 10, ["unik_mgla"], 3), "szarza": _n("a", 8, ["unik_mgla"], 3), "okowy_lodu": _n("a", 9, [], 3),
			"kopniak": _n("b", 4, [], 3), "pocisk": _n("b", 3, [], 3), "headshot": _n("b", 12, ["pocisk"], 3), "trojszot": _n("b", 18, ["headshot"], 2),
			"wicher_ostrzy": _n("b", 30, ["trojszot", "chmurowy_wzlot"], 3), "furia_tytana": _n("b", 40, ["wicher_ostrzy"], 1),
			"wstrzas": _n("c", 6, [], 3), "krzyk_ogluszajacy": _n("c", 12, ["wstrzas"], 2), "oszolomienie": _n("c", 10, [], 3), "odnowa": _n("c", 3, [], 3),
		},
	}
	t["mag"] = {
		"branches": {"a": _br("Żywioły", Color(1.0, 0.55, 0.3)), "b": _br("Arkana", Color(0.8, 0.6, 1.0)), "c": _br("Ochrona many", Color(0.6, 0.85, 1.0))},
		"nodes": {
			"okowy_lodu": _n("a", 6, [], 3), "krag_ognia": _n("a", 10, [], 3), "burza_pior": _n("a", 18, ["krag_ognia"], 3), "eklipsa": _n("a", 26, ["burza_pior"], 2),
			"wstrzas": _n("b", 6, [], 3), "krzyk_ogluszajacy": _n("b", 12, ["wstrzas"], 2), "oszolomienie": _n("b", 14, [], 3), "chmurowy_wzlot": _n("b", 10, [], 3),
			"wicher_ostrzy": _n("b", 30, ["eklipsa", "bastion"], 3), "furia_tytana": _n("b", 40, ["wicher_ostrzy"], 1),
			"zelazna_skora": _n("c", 5, [], 3), "bastion": _n("c", 18, ["zelazna_skora"], 2), "tarcza": _n("c", 9, [], 2), "odnowa": _n("c", 3, [], 3), "unik_mgla": _n("c", 4, [], 2),
		},
	}
	t["lady"] = {
		"branches": {"a": _br("Uzdrawianie", Color(0.5, 0.95, 0.6)), "b": _br("Opieka", Color(1.0, 0.85, 0.4)), "c": _br("Czary", Color(0.8, 0.6, 1.0))},
		"nodes": {
			"odnowa": _n("a", 3, [], 3), "zew_wsparcia": _n("a", 11, ["odnowa"], 3), "blogoslawienstwo": _n("a", 22, ["zew_wsparcia"], 2),
			"zelazna_skora": _n("b", 5, [], 3), "bastion": _n("b", 18, ["zelazna_skora"], 2), "komenda_ataku": _n("b", 7, [], 3), "ochrona_pupila": _n("b", 15, ["komenda_ataku"], 2), "unik_mgla": _n("b", 4, [], 2),
			"okowy_lodu": _n("c", 9, [], 3), "krag_ognia": _n("c", 14, [], 3), "wstrzas": _n("c", 6, [], 3), "krzyk_ogluszajacy": _n("c", 12, ["wstrzas"], 2),
			"wicher_ostrzy": _n("c", 30, ["blogoslawienstwo", "bastion"], 3), "furia_tytana": _n("c", 40, ["wicher_ostrzy"], 1),
		},
	}
	return t

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
