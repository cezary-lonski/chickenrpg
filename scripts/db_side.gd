class_name SideDB
extends RefCounted
## Zlecenia poboczne z tablicy ogłoszeń — zadania, w których nie chodzi o samą walkę:
## zbieranie ziół, tropienie śladów, doręczanie przesyłek i polowanie na łowcę nagród.
## Stan zapisuje się w profilu ("side": active / done). Tablica oferuje 3 zlecenia na strefę.

const ITEMS := {
	"paczka_listow": {
		"name": "Paczka listów", "slot": "material", "tier": 1, "price": 0, "icon": "list", "stack": 5,
		"desc": "Zapieczętowana przesyłka z tablicy ogłoszeń. Doręcz ją adresatowi.", "stats": {}, "tint": Color(0.95, 0.9, 0.7),
	},
	"lutnia_kukuryka": {
		"name": "Lutnia Kukuryka", "slot": "material", "tier": 1, "price": 0, "icon": "list", "stack": 1,
		"desc": "Ulubiona lutnia barda, skonfiskowana przez ludzi kanclerza. Zanieś ją bardowi.", "stats": {}, "tint": Color(0.9, 0.6, 0.3),
	},
}

const TITLES := {
	"herbs": ["Zielarka potrzebuje ziół", "Zbierz %d pęków ziół rozsianych po okolicy i zanieś je na tablicę."],
	"tracks": ["Zaginiony kupiec", "Podążaj za %d śladami, aż znajdziesz skrzynię zaginionego kupca."],
	"package": ["Pilna przesyłka", "Doręcz paczkę listów: %s."],
	"hunt": ["List gończy", "W okolicy grasuje łowca nagród. Pokonaj go i zgłoś się po nagrodę."],
}

static func state() -> Dictionary:
	var s = GameState.profile.get("side")
	if not (s is Dictionary):
		s = {"active": [], "done": 0}
		GameState.profile["side"] = s
	if not (s.get("active") is Array):
		s["active"] = []
	return s

static func active() -> Array:
	return state()["active"]

static func done_count() -> int:
	return int(state().get("done", 0))

static func _rng(key: String) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = key.hash()
	return r

## Wolne miejsce w strefie, deterministyczne dla danego klucza.
static func spot(key: String, index: int) -> Vector2:
	var r := _rng("%s#%d" % [key, index])
	return Vector2(r.randf_range(260.0, 1940.0), r.randf_range(320.0, 1250.0))

static func offers(zone_id: String, npc_ids: Array) -> Array:
	var out: Array = []
	var lv := GameState.player_level()
	var types: Array = ["herbs", "tracks", "hunt"]
	if not npc_ids.is_empty():
		types.append("package")
	var r := _rng("%s|%d" % [zone_id, done_count()])
	var picked: Array = []
	while picked.size() < mini(3, types.size()):
		var t: String = String(types[r.randi() % types.size()])
		if t not in picked:
			picked.append(t)
	for i in picked.size():
		var t: String = picked[i]
		var id := "%s:%d:%s" % [zone_id, done_count(), t]
		var count := 4 if t == "herbs" else (4 if t == "tracks" else 1)
		var npc := ""
		if t == "package":
			npc = String(npc_ids[r.randi() % npc_ids.size()])
		out.append({
			"id": id, "type": t, "zone": zone_id, "count": count, "prog": 0, "found": [], "npc": npc,
			"reward": _reward(t, lv, r),
		})
	return out

static func _reward(t: String, lv: int, r: RandomNumberGenerator) -> Dictionary:
	var mult := float(GameState.diff_data()["gold"])
	var gold := int((50.0 + 9.0 * float(lv)) * (1.4 if t == "hunt" else 1.0) * mult)
	var items := {}
	var pool := ["mikstura_miodu", "eliksir_mocy", "sztabka_zelaza", "wegiel", "krysztal_cienia"]
	items[pool[r.randi() % pool.size()]] = 1 + r.randi() % 2
	if r.randf() < 0.2:
		items["zwoj_teleportacji"] = 1
	return {"gold": gold, "xp": int((30.0 + 8.0 * float(lv)) * mult), "items": items, "diff_loot": 0.0}

static func title_of(q: Dictionary) -> String:
	return String((TITLES[String(q["type"])] as Array)[0])

static func desc_of(q: Dictionary) -> String:
	var t := String(q["type"])
	var fmt := String((TITLES[t] as Array)[1])
	if t == "package":
		var nm := String(ChapterExtras.NPCS.get(String(q["npc"]), NpcDB.get_data(String(q["npc"]))).get("name", String(q["npc"])))
		return fmt % nm
	if fmt.contains("%d"):
		return fmt % (int(q["count"]) - (1 if t == "tracks" else 0))
	return fmt

static func is_complete(q: Dictionary) -> bool:
	return int(q.get("prog", 0)) >= int(q.get("count", 1))

static func accept(q: Dictionary) -> bool:
	if active().size() >= 2:
		return false
	for a in active():
		if String(a["id"]) == String(q["id"]):
			return false
	active().append(q.duplicate(true))
	if String(q["type"]) == "package":
		GameState.add_item("paczka_listow", 1)
	GameState.save_game()
	return true

static func find(id: String) -> Dictionary:
	for a in active():
		if String(a["id"]) == id:
			return a
	return {}

static func progress(id: String, idx: int = -1) -> void:
	var q := find(id)
	if q.is_empty():
		return
	if idx >= 0:
		if idx in (q["found"] as Array):
			return
		(q["found"] as Array).append(idx)
	q["prog"] = int(q.get("prog", 0)) + 1
	GameState.save_game()

## Wydaje nagrodę i zamyka zlecenie.
static func turn_in(id: String) -> Array:
	var q := find(id)
	if q.is_empty() or not is_complete(q):
		return []
	var lines: Array = SecretDB.grant(q["reward"])
	active().erase(q)
	state()["done"] = done_count() + 1
	Act2DB.add_rep(1)
	GameState.save_game()
	return lines

static func tracker_lines() -> Array:
	var out: Array = []
	for q in active():
		var left := int(q["count"]) - int(q.get("prog", 0))
		var txt := "◆ %s" % title_of(q)
		if is_complete(q):
			txt += " — wróć na tablicę"
		elif int(q["count"]) > 1:
			txt += " (%d/%d)" % [int(q["prog"]), int(q["count"])]
		out.append(txt)
	return out
