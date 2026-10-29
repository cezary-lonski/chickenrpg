class_name LootOps
extends RefCounted
## Okno łupu na serwerze: zwłoki poległych graczy (można je przeszukać i zabrać rzeczy) oraz kradzież (umiejętność
## „Kradzież”: ekwipunek potwora, NPC albo innego gracza). Sesja: pl["loot"] = {n, mode, ...}; klient wysyła act "loot_take"
## (index przedmiotu, UiLoot.TAKE_GOLD, UiLoot.TAKE_ALL albo TAKE_CLOSE), serwer odpowiada eventem "loot" / "loot_close".

const TAKE_CLOSE := -2
const RANGE := 200.0
const VICTIM_CD_MS := 120000

static func _send(srv: MmoServer, peer: int, box: Dictionary) -> void:
	var l: Dictionary = srv.peers[peer]["loot"]
	srv.send_ev(peer, "loot", {"token": int(l["n"]), "box": box})

static func _open(srv: MmoServer, peer: int, session: Dictionary, box: Dictionary) -> void:
	srv._token_seq += 1
	session["n"] = srv._token_seq
	srv.peers[peer]["loot"] = session
	srv.peers[peer]["frozen"] = MmoServer.DIALOG_FREEZE
	_send(srv, peer, box)

static func close(srv: MmoServer, peer: int) -> void:
	var pl: Dictionary = srv.peers[peer]
	if pl.has("loot"):
		pl.erase("loot")
		pl["frozen"] = 0.0
		srv.send_ev(peer, "loot_close", {})

# ------------------------------------------------------------------ zwłoki ---

static func _corpse_box(c: Dictionary) -> Dictionary:
	var items: Array = []
	for e in c["items"]:
		items.append({"id": String(e["id"]), "n": int(e["n"])})
	return Pickpocket.make_box("Zwłoki: " + String(c["name"]), "corpse", int(c["gold"]), items)

static func open_corpse(srv: MmoServer, peer: int, inst: ZoneInstance, uid: String) -> void:
	var c: Dictionary = inst.corpses.get(uid, {})
	if c.is_empty():
		return
	_open(srv, peer, {"mode": "corpse", "uid": uid}, _corpse_box(c))

static func _take_entry(srv: MmoServer, peer: int, rec: Dictionary, c: Dictionary, idx: int) -> void:
	var items: Array = c["items"]
	if idx < 0 or idx >= items.size():
		return
	var e: Dictionary = items[idx]
	var added := ServerChars.inv_add(rec, String(e["id"]), int(e["n"]), float(e.get("q", 1.0)), e.get("m", {}))
	if added >= int(e["n"]):
		items.remove_at(idx)
	else:
		e["n"] = int(e["n"]) - added
		srv.say(peer, "Plecak pełny.")

static func _take_corpse(srv: MmoServer, peer: int, inst: ZoneInstance, l: Dictionary, i: int) -> void:
	var rec: Dictionary = srv.peers[peer]["rec"]
	var c: Dictionary = inst.corpses.get(String(l["uid"]), {})
	if c.is_empty():
		close(srv, peer)
		return
	if i == UiLoot.TAKE_GOLD or i == UiLoot.TAKE_ALL:
		rec["gold"] = int(rec["gold"]) + int(c["gold"])
		c["gold"] = 0
	if i == UiLoot.TAKE_ALL:
		while not (c["items"] as Array).is_empty():
			var before := (c["items"] as Array).size()
			var n0 := int(((c["items"] as Array)[0] as Dictionary)["n"])
			_take_entry(srv, peer, rec, c, 0)
			if (c["items"] as Array).size() == before and int(((c["items"] as Array)[0] as Dictionary)["n"]) == n0:
				break   # plecak pełny
	elif i >= 0:
		_take_entry(srv, peer, rec, c, i)
	srv.chars.mark_dirty()
	srv._push_me(peer)
	if int(c["gold"]) <= 0 and (c["items"] as Array).is_empty():
		inst.remove_corpse(String(l["uid"]))
		close(srv, peer)
		return
	_send(srv, peer, _corpse_box(c))

# ---------------------------------------------------------------- kradzież ---

static func _victim_items(rec: Dictionary) -> Array:
	var out: Array = []
	for i in (rec["inv"] as Array).size():
		var e: Dictionary = rec["inv"][i]
		if String(ItemDB.get_data(String(e["id"])).get("slot", "")) == "key":
			continue
		out.append({"id": String(e["id"]), "n": int(e["n"]), "inv": i})
	return out

## Najbliższy cel kradzieży w zasięgu: potwór, NPC (bez fabularnych) albo inny gracz. Zwraca {} gdy brak.
static func find_target(srv: MmoServer, peer: int, inst: ZoneInstance) -> Dictionary:
	var node = srv.player_of(peer)
	if node == null:
		return {}
	var pos: Vector2 = (node as Node2D).position
	var best := {}
	var best_d := RANGE
	for c in inst.entities.get_children():
		if c is Enemy and is_instance_valid(c) and not (c as Enemy).dead and not (c as Enemy).has_meta("robbed"):
			var d := (c as Node2D).position.distance_to(pos)
			if d < best_d:
				best_d = d
				best = {"kind": "enemy", "node": c}
	for n in inst.npc_list:
		var nid := String(n["id"])
		var role := String(NpcDB.get_data(nid).get("role", "lore"))
		if nid == inst.giver or role in Pickpocket.SAFE_ROLES:
			continue
		var d2 := (n["pos"] as Vector2).distance_to(pos)
		if d2 < best_d:
			best_d = d2
			best = {"kind": "npc", "id": nid}
	if inst.kind != "arena" and inst.kind != "challenge":
		for other in inst.peer_ids:
			if int(other) == peer:
				continue
			var on = srv.player_of(int(other))
			if on == null or (on as Player).state == Player.S.DEAD:
				continue
			var safe: bool = inst.kind == "swiat" and (on as Node2D).position.distance_to(inst.spawn) < MmoServer.SAFE_RADIUS
			var d3 := (on as Node2D).position.distance_to(pos)
			if d3 < best_d and not safe:
				best_d = d3
				best = {"kind": "player", "peer": int(other)}
	return best

static func start_steal(srv: MmoServer, peer: int, inst: ZoneInstance) -> void:
	var pl: Dictionary = srv.peers.get(peer, {})
	if pl.is_empty() or pl.has("loot") or float(pl["frozen"]) > 0.0:
		return
	var t := find_target(srv, peer, inst)
	if t.is_empty():
		srv._say_to(peer, "Brak celu w zasięgu kradzieży.", "error")
		return
	var rec: Dictionary = pl["rec"]
	var fl := StoryActions.flags_of(rec)
	var box := {}
	var kind := String(t["kind"])
	if kind == "enemy":
		var e: Enemy = t["node"]
		var b := Pickpocket.enemy_box(e.gold_value)
		box = Pickpocket.make_box("Kieszenie: " + String(EnemyDB.get_data(e.species).get("name", "potwór")), "steal", int(b["gold"]), b["items"])
		e.set_meta("robbed", true)
	elif kind == "npc":
		var nid := String(t["id"])
		var b2 := Pickpocket.npc_box(nid)
		var items: Array = []
		for i in (b2["items"] as Array).size():
			if not bool(fl.get("pp:%s:%d" % [nid, i], false)):
				items.append((b2["items"] as Array)[i].merged({"pp": i}))
		var gold := 0 if bool(fl.get("pp:%s:g" % nid, false)) else int(b2["gold"])
		box = Pickpocket.make_box("Kieszenie: " + String(NpcDB.get_data(nid).get("name", "?")), "steal", gold, items)
	else:
		var vid := int(t["peer"])
		var vp: Dictionary = srv.peers[vid]
		var steals: Dictionary = pl.get("steal_victims", {})
		if Time.get_ticks_msec() - int(steals.get(vid, -VICTIM_CD_MS)) < VICTIM_CD_MS:
			srv._say_to(peer, "Ten gracz został niedawno okradziony — spróbuj później.", "error")
			return
		steals[vid] = Time.get_ticks_msec()
		pl["steal_victims"] = steals
		var vrec: Dictionary = vp["rec"]
		var vgold := mini(200, maxi(0, int(vrec["gold"]) / 4))
		box = Pickpocket.make_box("Kieszenie: " + String(vp["name"]), "steal", vgold, _victim_items(vrec))
	if (box["items"] as Array).is_empty() and int(box["gold"]) <= 0:
		srv.say(peer, "Kieszenie są puste.")
		return
	_open(srv, peer, {"mode": "steal", "target": t, "taken": 0, "box": box}, box)

static func _mod(srv: MmoServer, peer: int) -> int:
	var rec: Dictionary = srv.peers[peer]["rec"]
	var res: Dictionary = ServerCtx.run(rec, func(): return EncounterDB.modifier("zrecznosc", EncounterDB.ctx_game()))
	return int(res["result"])

static func _noticed(srv: MmoServer, peer: int, l: Dictionary) -> void:
	var t: Dictionary = l["target"]
	var pl: Dictionary = srv.peers[peer]
	var thief := String(pl["name"])
	match String(t["kind"]):
		"npc":
			var angry: Dictionary = pl.get("angry", {})
			angry[String(t["id"])] = true
			pl["angry"] = angry
			srv._say_to(peer, "%s zauważył, że go okradasz! Jest wściekły." % String(NpcDB.get_data(String(t["id"])).get("name", "NPC")), "error")
			var rec: Dictionary = pl["rec"]
			ServerCtx.run(rec, func():
				if Act2DB.rep() > 0:
					Act2DB.add_rep(-1))
		"enemy":
			var e = t.get("node")
			if e != null and is_instance_valid(e):
				e.dormant = false
				e.aggro = 2600.0
			srv._say_to(peer, "Potwór zauważył kradzież i rzuca się na ciebie!", "error")
		"player":
			var vid := int(t["peer"])
			srv._say_to(peer, "Ofiara cię zauważyła!", "error")
			if srv.peers.has(vid):
				srv._say_to(vid, "Przyłapałeś %s na próbie kradzieży!" % thief, "error")
	close(srv, peer)

static func _take_steal(srv: MmoServer, peer: int, l: Dictionary, i: int) -> void:
	var pl: Dictionary = srv.peers[peer]
	var rec: Dictionary = pl["rec"]
	var box: Dictionary = l["box"]
	var gold_take := i == UiLoot.TAKE_GOLD
	if i < UiLoot.TAKE_GOLD or (i >= 0 and i >= (box["items"] as Array).size()):
		return
	if randf() < Pickpocket.notice_chance(int(l["taken"]), gold_take, _mod(srv, peer)):
		_noticed(srv, peer, l)
		return
	var t: Dictionary = l["target"]
	var fl := StoryActions.flags_of(rec)
	var victim = srv.peers.get(int(t.get("peer", -1)))
	if gold_take:
		var g := int(box["gold"])
		if String(t["kind"]) == "player" and victim != null:
			g = mini(g, int(victim["rec"]["gold"]))
			victim["rec"]["gold"] = int(victim["rec"]["gold"]) - g
			srv._say_to(int(t["peer"]), "Zginęło %d zł z twojej sakiewki!" % g, "error")
			srv.chars.mark_dirty()
			srv._push_me(int(t["peer"]))
		rec["gold"] = int(rec["gold"]) + g
		box["gold"] = 0
		if String(t["kind"]) == "npc":
			fl["pp:%s:g" % String(t["id"])] = true
	else:
		var e: Dictionary = (box["items"] as Array)[i]
		if String(t["kind"]) == "player" and victim != null:
			var vinv: Array = victim["rec"]["inv"]
			var vi := int(e.get("inv", -1))
			if vi < 0 or vi >= vinv.size() or String(vinv[vi]["id"]) != String(e["id"]):
				close(srv, peer)
				return
			var take_n := mini(int(e["n"]), int(vinv[vi]["n"]))
			ServerChars.inv_add(rec, String(e["id"]), take_n, float(vinv[vi].get("q", 1.0)), vinv[vi].get("m", {}))
			vinv[vi]["n"] = int(vinv[vi]["n"]) - take_n
			if int(vinv[vi]["n"]) <= 0:
				vinv.remove_at(vi)
			srv._say_to(int(t["peer"]), "Coś zniknęło z twojego plecaka!", "error")
			srv.chars.mark_dirty()
			srv._push_me(int(t["peer"]))
			close(srv, peer)   # indeksy plecaka ofiary się przesunęły
			srv.say(peer, "Zabrano: %s ×%d" % [String(ItemDB.get_data(String(e["id"])).get("name", e["id"])), take_n])
			srv.chars.mark_dirty()
			srv._push_me(peer)
			return
		ServerChars.inv_add(rec, String(e["id"]), int(e["n"]))
		if String(t["kind"]) == "npc" and e.has("pp"):
			fl["pp:%s:%d" % [String(t["id"]), int(e["pp"])]] = true
		(box["items"] as Array).remove_at(i)
	l["taken"] = int(l["taken"]) + 1
	srv.chars.mark_dirty()
	srv._push_me(peer)
	if int(box["gold"]) <= 0 and (box["items"] as Array).is_empty():
		close(srv, peer)
		return
	_send(srv, peer, box)

## Wybór w oknie łupu (act "loot_take").
static func take(srv: MmoServer, peer: int, token: int, i: int) -> void:
	var pl: Dictionary = srv.peers.get(peer, {})
	var l: Dictionary = pl.get("loot", {})
	if l.is_empty() or int(l["n"]) != token:
		return
	if i == TAKE_CLOSE:
		close(srv, peer)
		return
	var inst: ZoneInstance = pl["inst"]
	if inst == null:
		close(srv, peer)
		return
	if String(l["mode"]) == "corpse":
		_take_corpse(srv, peer, inst, l, i)
	else:
		_take_steal(srv, peer, l, i)
