class_name AchievementDB
extends RefCounted
## Osiągnięcia i dziennik odkryć. Postęp liczony jest z zapisu gry (statystyki, flagi fabuły, sekrety).

const DEFS := [
	{"id": "pierwszy_krok", "name": "Pierwszy krok", "desc": "Ukończ pierwszy rozdział.", "stat": "quests", "need": 1},
	{"id": "weteran", "name": "Weteran kurnika", "desc": "Ukończ 10 rozdziałów.", "stat": "quests", "need": 10},
	{"id": "legenda_kampanii", "name": "Legenda kampanii", "desc": "Ukończ wszystkie rozdziały.", "stat": "quests", "need": 27},
	{"id": "poziom_10", "name": "Rozgrzany kurczak", "desc": "Osiągnij 10. poziom.", "stat": "level", "need": 10},
	{"id": "poziom_30", "name": "Doświadczony wojownik", "desc": "Osiągnij 30. poziom.", "stat": "level", "need": 30},
	{"id": "poziom_100", "name": "Kurczak absolutny", "desc": "Osiągnij maksymalny, 100. poziom.", "stat": "level", "need": 100},
	{"id": "ciekawski", "name": "Ciekawski", "desc": "Odkryj 3 sekretne komnaty pałacu.", "stat": "rooms", "need": 3},
	{"id": "lowca_sekretow", "name": "Łowca sekretów", "desc": "Odkryj 10 sekretnych komnat.", "stat": "rooms", "need": 10},
	{"id": "jaskiniowiec", "name": "Jaskiniowiec", "desc": "Pokonaj bossa sekretnej jaskini.", "stat": "caves", "need": 1},
	{"id": "zdobywca_jaskin", "name": "Zdobywca jaskiń", "desc": "Pokonaj 5 bossów jaskiń.", "stat": "caves", "need": 5},
	{"id": "legendarny", "name": "Błysk legendy", "desc": "Zdobądź legendarny przedmiot.", "stat": "legend", "need": 1},
	{"id": "kolekcjoner", "name": "Kolekcjoner legend", "desc": "Zdobądź 5 legendarnych przedmiotów.", "stat": "legend", "need": 5},
	{"id": "szermierz", "name": "Szermierz", "desc": "Wygraj pojedynek z rycerzem.", "stat": "duels", "need": 1},
	{"id": "mistrz_areny", "name": "Mistrz areny", "desc": "Wygraj 10 pojedynków.", "stat": "duels", "need": 10},
	{"id": "gladiator", "name": "Gladiator", "desc": "Przetrwaj 5 rund w trybie wyzwań.", "stat": "challenge_best", "need": 5},
	{"id": "niezwyciezony", "name": "Niezwyciężony", "desc": "Przetrwaj 10 rund w trybie wyzwań.", "stat": "challenge_best", "need": 10},
	{"id": "zwyciezca_wiosek", "name": "Wyzwoliciel wiosek", "desc": "Wyzwól wszystkie 6 wiosek Aktu II.", "stat": "villages", "need": 6},
	{"id": "bogacz", "name": "Bogacz", "desc": "Miej jednocześnie 5000 złota.", "stat": "gold", "need": 5000},
	{"id": "stadko", "name": "Stadko", "desc": "Odblokuj 3 towarzyszy.", "stat": "pets", "need": 3},
	{"id": "pogromca", "name": "Pogromca", "desc": "Pokonaj 500 wrogów.", "stat": "kills", "need": 500},
]

static func value(stat: String) -> int:
	var p: Dictionary = GameState.profile
	match stat:
		"quests":
			return (GameState.story().get("done", []) as Array).size()
		"level":
			var lv := 1
			for cp in (p.get("characters", {}) as Dictionary).values():
				lv = maxi(lv, int(cp.get("level", 1)))
			return lv
		"rooms":
			var n := 0
			for k in (GameState.story().get("flags", {}) as Dictionary):
				if String(k).begins_with("room:"):
					n += 1
			return n
		"caves":
			var n2 := 0
			for k in ((p.get("secrets", {}) as Dictionary).get("found", []) as Array):
				if String(k).begins_with("cave:"):
					n2 += 1
			return n2
		"legend":
			return (p.get("legendary_found", []) as Array).size()
		"duels":
			return int((p.get("stats", {}) as Dictionary).get("duels", 0))
		"challenge_best":
			return int((p.get("stats", {}) as Dictionary).get("challenge_best", 0))
		"villages":
			return Act2DB.liberated().size()
		"gold":
			return GameState.gold()
		"pets":
			return ((p.get("pets", {}) as Dictionary).get("unlocked", []) as Array).size()
		"kills":
			return int((p.get("stats", {}) as Dictionary).get("kills", 0))
	return 0

static func unlocked() -> Dictionary:
	if not (GameState.profile.get("ach") is Dictionary):
		GameState.profile["ach"] = {}
	return GameState.profile["ach"]

static func is_done(d: Dictionary) -> bool:
	return unlocked().has(String(d["id"]))

## Odblokowuje spełnione osiągnięcia; zwraca ich nazwy.
static func check() -> Array:
	var out: Array = []
	var u := unlocked()
	for d in DEFS:
		var id := String(d["id"])
		if u.has(id):
			continue
		if value(String(d["stat"])) >= int(d["need"]):
			u[id] = true
			out.append(String(d["name"]))
	if not out.is_empty():
		GameState.save_game()
	return out

## Zlicza wygraną (np. pojedynek) w statystykach profilu.
static func bump(stat: String, by: int = 1) -> void:
	var st: Dictionary = GameState.profile.get("stats", {})
	st[stat] = int(st.get(stat, 0)) + by
	GameState.profile["stats"] = st

static func set_max(stat: String, v: int) -> void:
	var st: Dictionary = GameState.profile.get("stats", {})
	if v > int(st.get(stat, 0)):
		st[stat] = v
		GameState.profile["stats"] = st

static func count_done() -> int:
	var n := 0
	for d in DEFS:
		if is_done(d):
			n += 1
	return n
