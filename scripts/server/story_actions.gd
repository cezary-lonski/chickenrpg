class_name StoryActions
extends RefCounted
## Obiekty i zdarzenia kampanii na serwerze (cele rozdziałów, skrzynie, dźwignie, jaskinie, tablica zleceń).
## Logika odpowiada village.gd; nagrody i stan (sekrety, zlecenia) liczy oryginalny kod baz danych w ServerCtx.

const BIG_RADIUS_KINDS := ["board", "door", "stairs", "stash", "lab", "hospital"]
const NPC_RADIUS := 110.0

static func flags_of(rec: Dictionary) -> Dictionary:
	return MmoServer.story_of(rec)["flags"]

static func secrets_of(rec: Dictionary) -> Dictionary:
	var gsx: Dictionary = rec.get("gsx", {})
	var s = gsx.get("secrets", {})
	return s if s is Dictionary else {}

static func prog_of(rec: Dictionary) -> Dictionary:
	var gsx: Dictionary = rec.get("gsx", {})
	return {"flags": flags_of(rec).duplicate(), "secrets": secrets_of(rec).duplicate(true), "side": gsx.get("side", {}).duplicate(true) if gsx.get("side") is Dictionary else {}}

static func radius_of(o: Dictionary) -> float:
	return 120.0 if String(o.get("kind", "")) in BIG_RADIUS_KINDS else 78.0

static func levers_pulled(rec: Dictionary, quest: String, total: int) -> int:
	var flags := flags_of(rec)
	var arr: Array = (secrets_of(rec).get("levers", {}) as Dictionary).get(quest, []) if secrets_of(rec).get("levers") is Dictionary else []
	var n := 0
	for i in total:
		if bool(flags.get("lv:%s:%d" % [quest, i], false)) or i in arr:
			n += 1
	return n

## Czy obiekt jest teraz użyteczny dla tego gracza (nie zrobiony, faza celu, dźwignie…).
static func usable(rec: Dictionary, inst: ZoneInstance, peer: int, o: Dictionary) -> bool:
	var flags := flags_of(rec)
	match String(o.get("type", "")):
		"obj":
			if String(o.get("phase", "pre")) == "post" and inst.step <= inst.waves.size():
				return false
			return not bool(flags.get(String(o["uid"]), false))
		"heist":
			return not heist_off(rec, inst.quest_id, inst.heist)
		"chest":
			return String(o["uid"]) not in (secrets_of(rec).get("chests", []) as Array)
		"lever":
			var q := inst.quest_id
			var cv := SecretDB.cave_for(q)
			var arr: Array = (secrets_of(rec).get("levers", {}) as Dictionary).get(q, []) if secrets_of(rec).get("levers") is Dictionary else []
			return not (bool(flags.get(String(o["uid"]), false)) or int(o["idx"]) in arr) and not cv.is_empty()
		"entrance":
			return levers_pulled(rec, inst.quest_id, int(o.get("levers", 3))) >= int(o.get("levers", 3))
		"cavechest":
			return not inst.opened.has(peer)
		_:
			return true

## Najbliższy użyteczny obiekt (w tym zlecenia poboczne gracza) w zasięgu; puste, gdy brak.
static func nearest_object(srv: MmoServer, peer: int, inst: ZoneInstance, pos: Vector2) -> Dictionary:
	var rec: Dictionary = srv.peers[peer]["rec"]
	var best := {}
	var best_d := 1.0e9
	var all: Array = inst.objs + inst.extra_objs + (srv.peers[peer].get("side_objs", []) as Array)
	for o in all:
		if not usable(rec, inst, peer, o):
			continue
		var d := (o["pos"] as Vector2).distance_to(pos)
		if d <= radius_of(o) and d < best_d:
			best_d = d
			best = o
	return best

static func activate(srv: MmoServer, peer: int, inst: ZoneInstance, o: Dictionary) -> void:
	match String(o.get("type", "")):
		"obj": _obj(srv, peer, inst, o)
		"chest": _chest(srv, peer, inst, o)
		"sign": _sign(srv, peer, inst)
		"lever": _lever(srv, peer, inst, o)
		"entrance": srv.enter_cave(peer, String(o["cave"]))
		"board": open_board(srv, peer, inst)
		"cavechest": _cave_chest(srv, peer, inst)
		"portal": srv.enter_zone(peer, srv.zone_key_for(srv.peers[peer]["rec"]))
		"side": _side(srv, peer, inst, o)
		"heist": _heist_take(srv, peer, inst)
		"hospital": SupportOps.open_hospital(srv, peer)
		"stash": SupportOps.open_stash(srv, peer)
		"lab": SupportOps.open_lab(srv, peer)

# ----------------------------------------------------------- cele rozdziału ---

static func _objective(quest: String, id: String) -> Dictionary:
	for o in ChapterExtras.objectives(quest):
		if String(o["id"]) == id:
			return o
	return {}

static func _obj(srv: MmoServer, peer: int, inst: ZoneInstance, o: Dictionary) -> void:
	var rec: Dictionary = srv.peers[peer]["rec"]
	var obj := _objective(inst.quest_id, String(o["obj"]))
	if obj.is_empty():
		return
	flags_of(rec)[String(o["uid"])] = true
	srv.chars.mark_dirty()
	match String(obj.get("type", "")):
		"collect":
			var clues: Array = obj.get("clues", [])
			var idx := int(o["idx"])
			srv._open_dialog(peer, [["", String(clues[idx]) if idx < clues.size() else "Znaleziono wskazówkę."]], UiKit.ACCENT2, "")
		"free":
			srv.say(peer, "Uwolniono! (%d / %d)" % [ChapterExtras.count_done(inst.quest_id, obj, flags_of(rec)), int(obj.get("count", 1))])
		"sabotage":
			srv.say(peer, "Zniszczono! (%d / %d)" % [ChapterExtras.count_done(inst.quest_id, obj, flags_of(rec)), int(obj.get("count", 1))])
	check_obj_reward(srv, peer, inst.quest_id, obj)
	srv.push_prog(peer)

static func check_obj_reward(srv: MmoServer, peer: int, quest: String, obj: Dictionary) -> void:
	var rec: Dictionary = srv.peers[peer]["rec"]
	if not ChapterExtras.is_done(quest, obj, flags_of(rec)):
		return
	var rflag := "r:" + ChapterExtras.flag(quest, String(obj["id"]), 0)
	if bool(flags_of(rec).get(rflag, false)):
		return
	flags_of(rec)[rflag] = true
	var rw: Dictionary = obj.get("reward", {})
	var res := ServerCtx.run(rec, func(): return SecretDB.grant({"items": rw.get("items", {}), "gold": int(rw.get("gold", 0)), "xp": int(rw.get("xp", 0))}))
	var lines: Array = res["result"]
	srv.say(peer, "Cel ukończony: %s%s" % [String(obj["text"]), (" — " + ", ".join(lines)) if not lines.is_empty() else ""])
	srv.after_ctx(peer, int(res["levels"]))

# ------------------------------------------------------------ skradanka (lutnia) ---

static func _item_count(rec: Dictionary, id: String) -> int:
	var n := 0
	for e in rec["inv"]:
		if String(e["id"]) == id:
			n += int(e["n"])
	return n

## Skradanka nie dotyczy gracza, który już zwędził lutnię (ma ją albo oddał barda).
static func heist_off(rec: Dictionary, quest: String, o: Dictionary) -> bool:
	if o.is_empty():
		return true
	var fl := flags_of(rec)
	return bool(fl.get("heist_taken:" + quest, false)) or _item_count(rec, "lutnia_kukuryka") > 0 or ChapterExtras.is_done(quest, o, fl)

static func _heist_take(srv: MmoServer, peer: int, inst: ZoneInstance) -> void:
	var rec: Dictionary = srv.peers[peer]["rec"]
	flags_of(rec)["heist_taken:" + inst.quest_id] = true
	ServerChars.inv_add(rec, "lutnia_kukuryka", 1)
	srv.say(peer, "Zwędzono lutnię! Wymknij się i zanieś ją bardowi.")
	srv.chars.mark_dirty()
	srv.push_prog(peer)
	srv._push_me(peer)

## Bard odbiera lutnię: dialog z podziękowaniem i nagroda za cel „włamanie”.
static func _bard_turn_in(srv: MmoServer, peer: int, inst: ZoneInstance) -> bool:
	var rec: Dictionary = srv.peers[peer]["rec"]
	var o := inst.heist
	if o.is_empty() or ChapterExtras.is_done(inst.quest_id, o, flags_of(rec)) or _item_count(rec, "lutnia_kukuryka") <= 0:
		return false
	ServerChars.inv_remove(rec, "lutnia_kukuryka", 1)
	flags_of(rec)[ChapterExtras.flag(inst.quest_id, String(o["id"]), 0)] = true
	srv._open_dialog(peer, o.get("thanks", []), NpcDB.get_data("bard").get("accent", UiKit.ACCENT), "")
	check_obj_reward(srv, peer, inst.quest_id, o)
	srv.chars.mark_dirty()
	srv.push_prog(peer)
	srv._push_me(peer)
	return true

static func mark_talked(srv: MmoServer, peer: int, quest: String, npc: String) -> void:
	var rec: Dictionary = srv.peers[peer]["rec"]
	for o in ChapterExtras.objectives(quest):
		if String(o.get("type", "")) != "talk":
			continue
		var i := (o.get("npcs", []) as Array).find(npc)
		if i >= 0:
			flags_of(rec)[ChapterExtras.flag(quest, String(o["id"]), i)] = true
			check_obj_reward(srv, peer, quest, o)
	srv.chars.mark_dirty()
	srv.push_prog(peer)

# ------------------------------------------------------- skrzynie i dźwignie ---

static func _chest(srv: MmoServer, peer: int, inst: ZoneInstance, o: Dictionary) -> void:
	var rec: Dictionary = srv.peers[peer]["rec"]
	var c := {}
	for ch in SecretDB.chests_for(inst.quest_id):
		if String(ch["id"]) == String(o["chest"]):
			c = ch
	if c.is_empty():
		return
	var uid := String(o["uid"])
	var res := ServerCtx.run(rec, func():
		SecretDB.mark_chest(uid)
		return SecretDB.grant({"items": c.get("loot", {}), "gold": int(c.get("gold", 0)), "xp": int(c.get("xp", 0))}))
	srv.say(peer, "Skrzynia: " + ", ".join(res["result"]))
	srv.after_ctx(peer, int(res["levels"]))
	srv.push_prog(peer)

static func _sign(srv: MmoServer, peer: int, inst: ZoneInstance) -> void:
	var cv := SecretDB.cave_for(inst.quest_id)
	if not cv.is_empty():
		srv._open_dialog(peer, [["", String(cv["hint"])]], UiKit.ACCENT2, "")

static func _lever(srv: MmoServer, peer: int, inst: ZoneInstance, o: Dictionary) -> void:
	var rec: Dictionary = srv.peers[peer]["rec"]
	var q := inst.quest_id
	var cv := SecretDB.cave_for(q)
	if cv.is_empty():
		return
	flags_of(rec)[String(o["uid"])] = true
	var idx := int(o["idx"])
	ServerCtx.run(rec, func(): SecretDB.pull_lever(q, idx))
	var total := (cv["levers"] as Array).size()
	var pulled := levers_pulled(rec, q, total)
	if pulled >= total:
		srv.send_ev(peer, "banner", {"title": "COŚ ZAZGRZYTAŁO…", "sub": "Odsłonięto wejście do: %s" % String(cv["name"])})
	else:
		srv.say(peer, "Dźwignia pociągnięta (%d / %d)" % [pulled, total])
	srv.chars.mark_dirty()
	srv.push_prog(peer)

static func _cave_chest(srv: MmoServer, peer: int, inst: ZoneInstance) -> void:
	var rec: Dictionary = srv.peers[peer]["rec"]
	if inst.opened.has(peer):
		return
	inst.opened[peer] = true
	var cave := inst.cave
	var reward: Dictionary = (cave["reward"] as Dictionary).duplicate(true)
	if String(cave.get("pet", "")) != "":
		reward["pet"] = String(cave["pet"])
	if inst.cave_bonus:
		var bi: Dictionary = reward.get("items", {})
		bi["krysztal_cienia"] = int(bi.get("krysztal_cienia", 0)) + 1
		reward["items"] = bi
		reward["gold"] = int(reward.get("gold", 0)) + 100
	var cid := inst.cave_id
	var res := ServerCtx.run(rec, func():
		if SecretDB.cave_done(cid):
			return []
		var lines := SecretDB.grant(reward)
		SecretDB.mark_cave(cid)
		return lines)
	var lines2: Array = res["result"]
	srv.say(peer, ("Nagroda jaskini: " + ", ".join(lines2)) if not lines2.is_empty() else "Skarbiec jest pusty.")
	if inst.cave_bonus and not lines2.is_empty():
		srv.say(peer, "Wyzwanie czasowe ukończone: bonusowa nagroda!")
	srv.after_ctx(peer, int(res["levels"]))
	if inst.cave_state == "loot":
		inst.cave_state = "exit"
		inst.add_extra_obj({"uid": "cave_portal", "kind": "portal", "label": "Wróć na powierzchnię", "pos": Vector2(1100.0, 1230.0), "type": "portal"})
	srv.push_prog(peer)

# ---------------------------------------------------------------- tablica ---

static func open_board(srv: MmoServer, peer: int, inst: ZoneInstance) -> void:
	var rec: Dictionary = srv.peers[peer]["rec"]
	var extras: Array = ChapterExtras.npc_ids(inst.quest_id) if ChapterExtras.has(inst.quest_id) else []
	var quest := inst.quest_id
	var res := ServerCtx.run(rec, func():
		var opts: Array = []
		var acts: Array = []
		for q in SideDB.active():
			if SideDB.is_complete(q):
				var r: Dictionary = q["reward"]
				opts.append({"text": "Odbierz nagrodę: %s  (%d zł, %d XP)" % [SideDB.title_of(q), int(r["gold"]), int(r["xp"])]})
				acts.append(["turn", String(q["id"])])
		for q in SideDB.offers(quest, extras):
			if not SideDB.find(String(q["id"])).is_empty():
				continue
			var r2: Dictionary = q["reward"]
			var o := {"text": "%s — %s  [%d zł]" % [SideDB.title_of(q), SideDB.desc_of(q), int(r2["gold"])]}
			if SideDB.active().size() >= 2:
				o["disabled"] = true
				o["hint"] = "Masz już 2 aktywne zlecenia."
			opts.append(o)
			acts.append(["accept", q])
		opts.append({"text": "Zamknij tablicę"})
		acts.append(["close"])
		return {"opts": opts, "acts": acts, "rep": Act2DB.rep(), "done": SideDB.done_count()})
	var d: Dictionary = res["result"]
	srv.open_choice(peer, "TABLICA ZLECEŃ  —  Reputacja: %d  ·  wykonane zlecenia: %d" % [int(d["rep"]), int(d["done"])], d["opts"],
		Color(0.95, 0.8, 0.4), {"kind": "board", "acts": d["acts"]})

## Wybór z okna wyboru (tablica zleceń albo wybór w rozmowie z NPC).
static func choice_pick(srv: MmoServer, peer: int, data: Dictionary, i: int) -> void:
	var rec: Dictionary = srv.peers[peer]["rec"]
	var inst: ZoneInstance = srv.peers[peer]["inst"]
	match String(data.get("kind", "")):
		"arena_invite":
			srv.answer_arena(peer, int(data.get("from", -1)), i == 0)
		"board":
			var acts: Array = data["acts"]
			if i < 0 or i >= acts.size():
				return
			var a: Array = acts[i]
			match String(a[0]):
				"turn":
					var qid := String(a[1])
					var res := ServerCtx.run(rec, func(): return SideDB.turn_in(qid))
					srv.say(peer, "Nagroda: " + ", ".join(res["result"]))
					srv.after_ctx(peer, int(res["levels"]))
				"accept":
					var q: Dictionary = a[1]
					var res2 := ServerCtx.run(rec, func(): return SideDB.accept(q))
					if bool(res2["result"]):
						srv.say(peer, "Przyjęto zlecenie: %s" % SideDB.title_of(q))
						push_side(srv, peer, inst, true)
					else:
						srv.say(peer, "Nie można przyjąć zlecenia.")
			srv.chars.mark_dirty()
			srv.push_prog(peer)
		"talk":
			var choice: Dictionary = data["choice"]
			var opts: Array = choice["options"]
			if i < 0 or i >= opts.size():
				return
			var opt: Dictionary = opts[i]
			if int(opt.get("cost", 0)) > int(rec["gold"]):
				return
			for tk in opt.get("take", {}):
				if srv.count_of(rec, String(tk)) < int(opt["take"][tk]):
					return
			flags_of(rec)[String(opt["flag"])] = true
			if int(opt.get("rep", 0)) > 0:
				var rp := int(opt["rep"])
				ServerCtx.run(rec, func(): Act2DB.add_rep(rp))
			if int(opt.get("cost", 0)) > 0:
				rec["gold"] = int(rec["gold"]) - int(opt["cost"])
			for tk2 in opt.get("take", {}):
				ServerChars.inv_remove(rec, String(tk2), int(opt["take"][tk2]))
			srv.chars.mark_dirty()
			srv.push_prog(peer)
			srv._push_me(peer)
			if String(opt.get("reply", "")) != "":
				srv._open_dialog(peer, [["", String(opt["reply"])]], data.get("accent", UiKit.ACCENT), "")

# ------------------------------------------------------------ rozmowy z NPC ---

static func talk_extra(srv: MmoServer, peer: int, inst: ZoneInstance, npc: String) -> void:
	var rec: Dictionary = srv.peers[peer]["rec"]
	if npc == "bard" and _bard_turn_in(srv, peer, inst):
		return
	var d := ChapterExtras.dialog(inst.quest_id, npc)
	var accent: Color = NpcDB.get_data(npc).get("accent", UiKit.ACCENT)
	var post: bool = inst.step > inst.waves.size()
	var lines: Array = d.get("post" if post else "pre", [["", "…"]])
	var choice: Dictionary = d.get("choice", {})
	var made := false
	for opt in choice.get("options", []):
		if bool(flags_of(rec).get(String(opt["flag"]), false)):
			made = true
	srv._open_dialog(peer, lines, accent, "extra", {"npc": npc, "choice": choice if (not choice.is_empty() and not made and not post) else {}, "accent": accent})

static func after_extra_dialog(srv: MmoServer, peer: int, inst: ZoneInstance, extra: Dictionary) -> void:
	mark_talked(srv, peer, inst.quest_id, String(extra.get("npc", "")))
	var choice: Dictionary = extra.get("choice", {})
	if choice.is_empty():
		return
	var rec: Dictionary = srv.peers[peer]["rec"]
	var opts: Array = []
	for o in choice["options"]:
		var item := {"text": String(o["text"])}
		if int(o.get("cost", 0)) > int(rec["gold"]):
			item["disabled"] = true
			item["hint"] = "Za mało złota (%d)" % int(o["cost"])
		for tk in o.get("take", {}):
			if srv.count_of(rec, String(tk)) < int(o["take"][tk]):
				item["disabled"] = true
				item["hint"] = "Brakuje przedmiotu"
		opts.append(item)
	srv.open_choice(peer, String(choice["prompt"]), opts, extra.get("accent", UiKit.ACCENT), {"kind": "talk", "choice": choice, "accent": extra.get("accent", UiKit.ACCENT)})

# ---------------------------------------------------------- zlecenia poboczne ---

## Przelicza obiekty zleceń pobocznych gracza w tej strefie i wysyła mu je (oraz spawnuje łowców nagród).
static func push_side(srv: MmoServer, peer: int, inst: ZoneInstance, announce: bool = false) -> void:
	var pl: Dictionary = srv.peers[peer]
	var rec: Dictionary = pl["rec"]
	if inst.kind != "story":
		pl["side_objs"] = []
		srv.send_ev(peer, "side_objs", {"objs": []})
		return
	var res := ServerCtx.run(rec, func(): return SideDB.active().duplicate(true))
	var list: Array = []
	for q in res["result"]:
		if String(q["zone"]) != inst.quest_id or SideDB.is_complete(q):
			continue
		var id := String(q["id"])
		match String(q["type"]):
			"herbs":
				for i in int(q["count"]):
					if i in (q["found"] as Array):
						continue
					list.append({"uid": "side:%s:h%d" % [id, i], "kind": "herb", "label": "Zerwij zioło", "pos": SideDB.spot(id, i), "type": "side", "q": id, "sk": "herb", "idx": i})
			"tracks":
				var n := int(q.get("prog", 0))
				var last := n >= int(q["count"]) - 1
				list.append({"uid": "side:%s:t%d" % [id, n], "kind": "chest" if last else "tracks", "label": "Otwórz skrzynię kupca" if last else "Zbadaj ślady",
					"pos": SideDB.spot(id, n), "type": "side", "q": id, "sk": "track"})
			"hunt":
				if not inst.hunts.has(id) or not is_instance_valid(inst.hunts[id]):
					inst.spawn_hunt(id, SideDB.spot(id, 0))
					if announce:
						srv.say(peer, "Łowca nagród kręci się gdzieś w okolicy…")
	pl["side_objs"] = list
	srv.send_ev(peer, "side_objs", {"objs": list})

static func _side(srv: MmoServer, peer: int, inst: ZoneInstance, o: Dictionary) -> void:
	var rec: Dictionary = srv.peers[peer]["rec"]
	var qid := String(o["q"])
	var idx := int(o.get("idx", -1))
	var res := ServerCtx.run(rec, func():
		SideDB.progress(qid, idx)
		return SideDB.find(qid).duplicate(true))
	_side_msg(srv, peer, res["result"])
	push_side(srv, peer, inst)
	srv.chars.mark_dirty()
	srv.push_prog(peer)

static func _side_msg(srv: MmoServer, peer: int, q: Dictionary) -> void:
	if q.is_empty():
		return
	if SideDB.is_complete(q):
		srv.say(peer, "Zlecenie wykonane: %s — wróć na tablicę po nagrodę." % SideDB.title_of(q))
	else:
		srv.say(peer, "%s (%d/%d)" % [SideDB.title_of(q), int(q["prog"]), int(q["count"])])

static func hunt_died(srv: MmoServer, inst: ZoneInstance, qid: String) -> void:
	for peer in inst.peer_ids.duplicate():
		if not srv.peers.has(peer):
			continue
		var rec: Dictionary = srv.peers[peer]["rec"]
		var res := ServerCtx.run(rec, func():
			if SideDB.find(qid).is_empty():
				return {}
			SideDB.progress(qid)
			return SideDB.find(qid).duplicate(true))
		_side_msg(srv, peer, res["result"])
		srv.chars.mark_dirty()
		srv.push_prog(peer)
		push_side(srv, peer, inst)

## Dostarczenie paczki listów do adresata (zlecenie "package"); true, gdy rozmowa została przejęta.
static func try_package(srv: MmoServer, peer: int, inst: ZoneInstance, npc: String) -> bool:
	var rec: Dictionary = srv.peers[peer]["rec"]
	var res := ServerCtx.run(rec, func():
		for q in SideDB.active():
			if String(q["type"]) == "package" and String(q["zone"]) == inst.quest_id and String(q["npc"]) == npc and not SideDB.is_complete(q) and GameState.item_count("paczka_listow") > 0:
				GameState.remove_item("paczka_listow", 1)
				SideDB.progress(String(q["id"]))
				return String(q["id"])
		return "")
	var qid: String = res["result"]
	if qid == "":
		return false
	var nm := String(NpcDB.get_data(npc).get("name", ChapterExtras.NPCS.get(npc, {}).get("name", "Adresat")))
	srv._open_dialog(peer, [[nm, "Paczka listów! Od dawna na nią czekałem. Przekaż na tablicy, że dotarła."]], UiKit.ACCENT, "")
	srv.chars.mark_dirty()
	srv.push_prog(peer)
	return true
