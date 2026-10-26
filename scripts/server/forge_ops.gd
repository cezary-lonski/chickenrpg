class_name ForgeOps
extends RefCounted
## Kuźnia na serwerze: kucie przedmiotów (jakość z minigry klienta, sprawdzana czasowo), zakup materiałów i zapis run.
## Koszty, receptury, runy i metale pochodzą z ForgeDB/RuneDB i działają w ServerCtx na postaci gracza.

const MIN_FORGE_SECS := 9.0
const BUYS := {
	"iron": {"id": "sztabka_zelaza", "n": 1, "price": 30},
	"coal": {"id": "wegiel", "n": 1, "price": 25},
	"coal5": {"id": "wegiel", "n": 5, "price": 110},
}

static func _state(srv: MmoServer, id: int) -> Dictionary:
	var rec: Dictionary = srv.peers[id]["rec"]
	var res := ServerCtx.run(rec, func():
		GameState.absorb_patterns()
		var metals: Array = []
		for m in ForgeDB.METALS:
			if ForgeDB.metal_known(String(m)):
				metals.append(String(m))
		return {"metals": metals, "runes": GameState.known_runes().duplicate()})
	srv.chars.mark_dirty()
	var st: Dictionary = res["result"]
	st["gold"] = int(rec["gold"])
	return st

static func open(srv: MmoServer, id: int) -> void:
	srv.peers[id]["forge"] = {"open": true}
	srv.send_ev(id, "forge", _state(srv, id))
	srv._push_me(id)

static func close(srv: MmoServer, id: int) -> void:
	if srv.peers.has(id):
		srv.peers[id]["forge"] = {}

static func _is_open(srv: MmoServer, id: int) -> bool:
	return srv.peers.has(id) and not (srv.peers[id].get("forge", {}) as Dictionary).is_empty()

static func buy(srv: MmoServer, id: int, what: String) -> void:
	if not _is_open(srv, id) or not BUYS.has(what):
		return
	var rec: Dictionary = srv.peers[id]["rec"]
	var b: Dictionary = BUYS[what]
	if int(rec["gold"]) < int(b["price"]):
		srv.say(id, "Za mało złota.")
		return
	if ServerChars.inv_add(rec, String(b["id"]), int(b["n"])) < int(b["n"]):
		srv.say(id, "Plecak pełny.")
		return
	rec["gold"] = int(rec["gold"]) - int(b["price"])
	srv.chars.mark_dirty()
	srv._push_me(id)
	srv.send_ev(id, "forge", _state(srv, id))

static func start(srv: MmoServer, id: int, kind: String, metal: String) -> void:
	if not _is_open(srv, id) or not ForgeDB.KINDS.has(kind) or not ForgeDB.METALS.has(metal):
		return
	var rec: Dictionary = srv.peers[id]["rec"]
	var res := ServerCtx.run(rec, func():
		if not ForgeDB.metal_known(metal):
			return "Receptura nieznana."
		var cost := ForgeDB.cost(kind, metal)
		for iid in cost:
			if GameState.item_count(String(iid)) < int(cost[iid]):
				return "Brakuje składników."
		return "")
	var err: String = res["result"]
	if err != "":
		srv.say(id, err)
		return
	srv.peers[id]["forge"] = {"open": true, "job": {"kind": kind, "metal": metal, "t0": Time.get_ticks_msec() * 0.001}}

static func finish(srv: MmoServer, id: int, score: float) -> void:
	if not _is_open(srv, id):
		return
	var forge: Dictionary = srv.peers[id]["forge"]
	var job: Dictionary = forge.get("job", {})
	if job.is_empty():
		return
	forge["job"] = {}
	var rec: Dictionary = srv.peers[id]["rec"]
	var kind := String(job["kind"])
	var metal := String(job["metal"])
	var elapsed := Time.get_ticks_msec() * 0.001 - float(job["t0"])
	score = clampf(score, 0.0, 1.0)
	if elapsed < MIN_FORGE_SECS:
		score = minf(score, 0.4)   # za szybko jak na trzy etapy minigry
	var q := ForgeDB.quality_of(score)
	var rid := ForgeDB.result_id(kind, metal)
	var failed: bool = float(q["mult"]) <= 0.0
	var res := ServerCtx.run(rec, func():
		var cost := ForgeDB.cost(kind, metal)
		for iid in cost:
			if GameState.item_count(String(iid)) < int(cost[iid]):
				return false
		if failed:
			var loss := ForgeDB.fail_loss(kind, metal)
			for lid in loss:
				GameState.remove_item(String(lid), int(loss[lid]))
		else:
			for cid in cost:
				GameState.remove_item(String(cid), int(cost[cid]))
			GameState.add_item(rid, 1, float(q["mult"]))
		return true)
	var ok: bool = res["result"]
	srv.chars.mark_dirty()
	srv._push_me(id)
	srv.send_ev(id, "forge_result", {"ok": ok, "failed": failed, "item": rid, "quality": String(q["name"]), "mult": float(q["mult"]), "score": score,
		"loss": ForgeDB.fail_loss(kind, metal) if failed else {}})
	srv.send_ev(id, "forge", _state(srv, id))

## Zapis słowa runami na przedmiocie z plecaka (kind "inv", key = indeks) albo założonym (kind "eq", key = slot).
static func rune(srv: MmoServer, id: int, src_kind: String, key: String, word: String) -> void:
	if not _is_open(srv, id) or not RuneDB.has(word) or src_kind not in ["inv", "eq"]:
		return
	var rec: Dictionary = srv.peers[id]["rec"]
	var res := ServerCtx.run(rec, func():
		GameState.absorb_patterns()
		if not RuneDB.is_known(word):
			return "Kowal nie zna tego wzoru."
		var item_id := ""
		var meta: Dictionary = {}
		if src_kind == "inv":
			var inv := GameState.inv()
			var i := int(key)
			if i < 0 or i >= inv.size() or not (inv[i] is Dictionary):
				return "Nie ma takiego przedmiotu."
			item_id = String(inv[i]["id"])
			meta = inv[i].get("m", {})
		else:
			item_id = String(GameState.equipped().get(key, ""))
			meta = GameState.equipped_meta(key)
		if item_id == "" or not ItemDB.is_gear(item_id):
			return "Runy można zapisać tylko na wyposażeniu."
		var chk := RuneDB.check(item_id, meta, word)
		if not bool(chk["ok"]):
			return String(chk["msg"])
		if not RuneDB.pay(word):
			return "Brakuje składników."
		var nm := RuneDB.apply(item_id, meta, word)
		if src_kind == "inv":
			GameState.inv()[int(key)]["m"] = nm
		else:
			GameState.equipped_meta()[key] = nm
		return "OK:" + String(ItemDB.get_data(item_id).get("name", item_id)))
	var msg: String = res["result"]
	srv.chars.mark_dirty()
	if msg.begins_with("OK:"):
		srv.say(id, "Runy %s zapisane na: %s" % [word, msg.substr(3)])
		srv.refresh_loadout(id)
	else:
		srv.say(id, msg)
	srv.send_ev(id, "forge", _state(srv, id))
