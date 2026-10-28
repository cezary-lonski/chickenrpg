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
		"wander", "shaft":
			return true
		"mine":
			return not bool(flags.get(String(o["uid"]), false))
		"entrance":
			if bool(o.get("mine", false)):
				return not bool(flags.get("mine_done:" + String(o["cave"]), false))
			if bool(o.get("camp", false)):
				return not bool(flags.get("camp_done:" + String(o["cave"]), false))
			return levers_pulled(rec, inst.quest_id, int(o.get("levers", 3))) >= int(o.get("levers", 3))
		"cavechest":
			return not inst.opened.has(peer)
		"prisoner":
			return not bool(flags.get(String(o["uid"]), false))
		_:
			return true

## Najbliższy użyteczny obiekt (w tym zlecenia poboczne gracza) w zasięgu; puste, gdy brak.
static func nearest_object(srv: MmoServer, peer: int, inst: ZoneInstance, pos: Vector2) -> Dictionary:
	var rec: Dictionary = srv.peers[peer]["rec"]
	var best := {}
	var best_d := 1.0e9
	var all: Array = inst.objs + inst.extra_objs + (srv.peers[peer].get("side_objs", []) as Array) + (srv.peers[peer].get("wander_objs", []) as Array)
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
		"entrance": _entrance(srv, peer, o)
		"board": open_board(srv, peer, inst)
		"cavechest": _cave_chest(srv, peer, inst)
		"wander": enc_start(srv, peer, String(o["enc"]))
		"shaft": _shaft(srv, peer, o)
		"prisoner": _prisoner(srv, peer, inst, o)
		"mine": srv.open_puzzle(peer, String(_mine_step(inst, o).get("puzzle", "lockpick")), String(o["uid"]), {"mine": o})
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
	var obj := _objective(inst.quest_id, String(o["obj"]))
	if obj.is_empty():
		return
	var pz := MinesDB.step_value(obj, "puzzles", "puzzle", int(o.get("idx", 0)))
	if pz != "":
		srv.open_puzzle(peer, pz, String(o["uid"]), {"o": o})
		return
	obj_apply(srv, peer, inst, o)

## Wynik zagadki: cel (obj) albo zamek skrzyni (chest, z wytrychem, który może się złamać).
static func _mine_step(inst: ZoneInstance, o: Dictionary) -> Dictionary:
	var steps: Array = (inst.zone.get("mine", {}) as Dictionary).get("steps", [])
	var i := int(o.get("idx", 0))
	return steps[i] if i >= 0 and i < steps.size() else {}

## Krok kopalni wykonany: flagi postaci i licznik celu, a po trzecim — nagroda, historyjka zalania i wyjście.
## Szyb: przenosi gracza do drugiego końca (omija strażników w kopalni/obozie).
static func _shaft(srv: MmoServer, peer: int, o: Dictionary) -> void:
	var node = srv.player_of(peer)
	if node == null:
		return
	(node as Node2D).position = (o["to"] as Vector2) + Vector2(0.0, 80.0)   # tuż obok szybu, żeby nie zjechać z powrotem
	if "velocity" in node:
		node.velocity = Vector2.ZERO
	srv.say(peer, "Zjeżdżasz szybem i wychodzisz na drugim końcu kopalni.")

static func mine_step_done(srv: MmoServer, peer: int, inst: ZoneInstance, o: Dictionary) -> void:
	var rec: Dictionary = srv.peers[peer]["rec"]
	var fl := flags_of(rec)
	var mine: Dictionary = inst.zone.get("mine", {})
	if mine.is_empty() or bool(fl.get(String(o["uid"]), false)):
		return
	var mid := String(mine["id"])
	fl[String(o["uid"])] = true
	fl[ChapterExtras.flag(String(mine["zone"]), mid, int(o["idx"]))] = true
	var steps: Array = mine["steps"]
	var done_n := 0
	for i in steps.size():
		if bool(fl.get("mine:%s:%d" % [mid, i], false)):
			done_n += 1
	srv.say(peer, "%s (%d / %d)" % [String(_mine_step(inst, o).get("msg", "Gotowe!")), done_n, steps.size()])
	srv.chars.mark_dirty()
	srv.push_prog(peer)
	if done_n < steps.size():
		return
	fl["mine_done:" + mid] = true
	var rflag := "r:mine:" + mid
	if not bool(fl.get(rflag, false)):
		fl[rflag] = true
		var rw: Dictionary = mine["reward"]
		var res := ServerCtx.run(rec, func(): return SecretDB.grant({"items": rw.get("items", {}), "gold": int(rw.get("gold", 0)), "xp": int(rw.get("xp", 0))}))
		srv.say(peer, "Kopalnia zalana! — " + ", ".join(res["result"]))
		srv.after_ctx(peer, int(res["levels"]))
	inst.camp_freed()
	srv._open_dialog(peer, [], UiKit.ACCENT, "", {"scene": String(mine["scene"])})

static func puzzle_result(srv: MmoServer, peer: int, inst: ZoneInstance, extra: Dictionary, ok: bool) -> void:
	if extra.has("mine"):
		if ok:
			mine_step_done(srv, peer, inst, extra["mine"])
		else:
			srv.say(peer, "Nie udało się — spróbuj jeszcze raz.")
		return
	if extra.has("chest"):
		var rec: Dictionary = srv.peers[peer]["rec"]
		var pick := String(extra.get("pick", ""))
		if pick == "" or _item_count(rec, pick) <= 0:
			return
		if SecretDB.pick_breaks(pick, ok):
			ServerChars.inv_remove(rec, pick, 1)
			srv.say(peer, "%s się złamał." % String(ItemDB.get_data(pick).get("name", "Wytrych")))
			srv.chars.mark_dirty()
			srv._push_me(peer)
		if ok:
			_chest_open(srv, peer, inst, extra["chest"])
		return
	if not ok:
		srv.say(peer, "Nie udało się — spróbuj jeszcze raz.")
		return
	obj_apply(srv, peer, inst, extra["o"])

## Cel zaliczony (po zagadce, jeśli była): flaga, komunikat i nagroda.
static func obj_apply(srv: MmoServer, peer: int, inst: ZoneInstance, o: Dictionary) -> void:
	var rec: Dictionary = srv.peers[peer]["rec"]
	var obj := _objective(inst.quest_id, String(o["obj"]))
	if obj.is_empty() or bool(flags_of(rec).get(String(o["uid"]), false)):
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
			srv.say(peer, "%s (%d / %d)" % [MinesDB.step_value(obj, "msgs", "msg", int(o["idx"]), "Zniszczono!"), ChapterExtras.count_done(inst.quest_id, obj, flags_of(rec)), int(obj.get("count", 1))])
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
	if String(obj.get("scene", "")) != "":
		srv._open_dialog(peer, [], UiKit.ACCENT, "", {"scene": String(obj["scene"])})

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
	return bool(fl.get("heist_taken:" + quest, false)) or _item_count(rec, ChapterExtras.heist_item(o)) > 0 or ChapterExtras.is_done(quest, o, fl)

## Strażnicy nie widzą gracza, który ma łup, oddał go albo pokonał naczelnika obozu.
static func guards_off(rec: Dictionary, quest: String, o: Dictionary) -> bool:
	return heist_off(rec, quest, o) or ChapterExtras.heist_disarmed(quest, o, flags_of(rec))

static func _heist_take(srv: MmoServer, peer: int, inst: ZoneInstance) -> void:
	var rec: Dictionary = srv.peers[peer]["rec"]
	flags_of(rec)["heist_taken:" + inst.quest_id] = true
	ServerChars.inv_add(rec, ChapterExtras.heist_item(inst.heist), 1)
	srv.say(peer, String(inst.heist.get("take_msg", "Zwędzono lutnię! Wymknij się i zanieś ją bardowi.")))
	srv.chars.mark_dirty()
	srv.push_prog(peer)
	srv._push_me(peer)

## NPC-odbiorca (bard z lutnią, ojciec z uwolnionym dzieckiem): dialog z podziękowaniem i nagroda za cel.
static func _heist_turn_in(srv: MmoServer, peer: int, inst: ZoneInstance, npc: String) -> bool:
	var rec: Dictionary = srv.peers[peer]["rec"]
	var o := inst.heist
	if o.is_empty() or ChapterExtras.heist_npc(o) != npc or ChapterExtras.is_done(inst.quest_id, o, flags_of(rec)) or _item_count(rec, ChapterExtras.heist_item(o)) <= 0:
		return false
	ServerChars.inv_remove(rec, ChapterExtras.heist_item(o), 1)
	flags_of(rec)[ChapterExtras.flag(inst.quest_id, String(o["id"]), 0)] = true
	srv._open_dialog(peer, o.get("thanks", []), NpcDB.get_data(npc).get("accent", UiKit.ACCENT), "", {"scene": String(o.get("scene", ""))})
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
	for ch in SecretDB.chests_for(inst.quest_id):
		if String(ch["id"]) == String(o["chest"]) and SecretDB.chest_locked(ch):
			var pick := SecretDB.best_pick(func(id): return _item_count(rec, String(id)))
			if pick == "":
				srv.say(peer, "Skrzynia jest zamknięta na zamek. Potrzebny wytrych — kupisz go w sklepie.")
				return
			srv.open_puzzle(peer, "lockpick", String(o["uid"]), {"chest": o, "pick": pick})
			return
	_chest_open(srv, peer, inst, o)

static func _chest_open(srv: MmoServer, peer: int, inst: ZoneInstance, o: Dictionary) -> void:
	var rec: Dictionary = srv.peers[peer]["rec"]
	var c := {}
	for ch in SecretDB.chests_for(inst.quest_id):
		if String(ch["id"]) == String(o["chest"]):
			c = ch
	if c.is_empty() or String(o["uid"]) in (secrets_of(rec).get("chests", []) as Array):
		return
	var uid := String(o["uid"])
	var res := ServerCtx.run(rec, func():
		SecretDB.mark_chest(uid)
		return SecretDB.grant({"items": c.get("loot", {}), "gold": int(c.get("gold", 0)), "xp": int(c.get("xp", 0))}))
	srv.say(peer, "Skrzynia: " + ", ".join(res["result"]))
	srv.after_ctx(peer, int(res["levels"]))
	srv.push_prog(peer)

## Wejście do jaskini; ścieżka do obozu niewolników wpuszcza dopiero po rozmowie ze zleceniodawcą.
static func _entrance(srv: MmoServer, peer: int, o: Dictionary) -> void:
	var cid := String(o["cave"])
	if bool(o.get("camp", false)) and not bool(flags_of(srv.peers[peer]["rec"]).get(SpecialDB.accept_flag(cid), false)):
		srv._open_dialog(peer, [["", String(SecretDB.cave_by_id(cid).get("hint", ""))], ["", "Nie wiesz jeszcze, kogo tam szukać. Porozmawiaj najpierw z: %s." % SpecialDB.giver_name(cid)]], UiKit.ACCENT2, "")
		return
	srv.enter_cave(peer, cid)

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

## Więzień w celi (lochy zamku Kruka): nagroda i podziękowanie; Tosia zna cię z prośby młynarza Mariana.
static func _prisoner(srv: MmoServer, peer: int, inst: ZoneInstance, o: Dictionary) -> void:
	var rec: Dictionary = srv.peers[peer]["rec"]
	var fl := flags_of(rec)
	var uid := String(o["uid"])
	if bool(fl.get(uid, false)):
		return
	var pr := {}
	for p in inst.zone.get("prisoners", []):
		if String(p["id"]) == String(o.get("pid", "")):
			pr = p
	if pr.is_empty():
		return
	fl[uid] = true
	if inst.zone.has("camp") and not inst.zone.has("mine"):
		fl["camp_done:" + inst.cave_id] = true
		inst.camp_freed()
	var knows := not bool(pr.get("tosia", false)) or bool(fl.get(SpecialDB.TOSIA_FLAG, false))
	var rw: Dictionary = pr["reward"] if knows else pr.get("reward_plain", pr["reward"])
	var thanks: Array = pr["thanks"] if knows else pr.get("thanks_plain", pr["thanks"])
	srv._open_dialog(peer, thanks, UiKit.ACCENT2, "")
	var res := ServerCtx.run(rec, func(): return SecretDB.grant({"items": rw.get("items", {}), "gold": int(rw.get("gold", 0)), "xp": int(rw.get("xp", 0))}))
	var lines: Array = res["result"]
	srv.say(peer, "Uwolniono: %s — %s" % [String(pr.get("name", "więzień")), ", ".join(lines)])
	srv.after_ctx(peer, int(res["levels"]))
	srv.chars.mark_dirty()
	srv.push_prog(peer)
	srv._push_me(peer)

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
		"revive":
			srv.revive_choice(peer, i == 0)
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
			var eff := DecisionDB.describe(String(opt["flag"]))
			if eff != "":
				srv.say(peer, "Decyzja ma skutki: %s" % eff)
				srv.refresh_loadout(peer)
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

## Spotkania w stylu BG (EncounterDB): serwer rzuca kośćmi i księguje skutki; rozgrywane raz na postać.
static func enc_start(srv: MmoServer, peer: int, enc: String) -> void:
	var rec: Dictionary = srv.peers[peer]["rec"]
	var e: Dictionary = EncounterDB.LIST[enc]
	if bool(flags_of(rec).get(EncounterDB.flag_done(enc), false)):
		srv._open_dialog(peer, [[String((e["npc"] as Dictionary)["name"]), "Wszystko już sobie powiedzieliśmy. Powodzenia."]], (e["npc"] as Dictionary).get("accent", UiKit.ACCENT), "")
		return
	_enc_send(srv, peer, enc, String(e["start"]), "", true, "")

static func _enc_send(srv: MmoServer, peer: int, enc: String, node: String, roll_text: String, roll_ok: bool, fx_text: String) -> void:
	var rec: Dictionary = srv.peers[peer]["rec"]
	var ctx: Dictionary = ServerCtx.run(rec, func(): return EncounterDB.ctx_game())["result"]
	var v := EncounterDB.view(enc, node, ctx)
	srv._token_seq += 1
	srv.peers[peer]["enc"] = {"n": srv._token_seq, "enc": enc, "node": node, "terminal": bool(v["terminal"])}
	srv.peers[peer]["frozen"] = MmoServer.DIALOG_FREEZE
	srv.send_ev(peer, "enc", {"token": srv._token_seq, "view": v, "roll": roll_text, "ok": roll_ok, "fx": fx_text})

static func enc_pick(srv: MmoServer, peer: int, token: int, i: int) -> void:
	var pl: Dictionary = srv.peers[peer]
	var en: Dictionary = pl.get("enc", {})
	if en.is_empty() or int(en.get("n", -1)) != token:
		return
	pl["enc"] = {}
	pl["frozen"] = 0.0
	if i < 0 or bool(en["terminal"]):
		return
	var rec: Dictionary = pl["rec"]
	var enc := String(en["enc"])
	var node := String(en["node"])
	var ctx: Dictionary = ServerCtx.run(rec, func(): return EncounterDB.ctx_game())["result"]
	var res := EncounterDB.choose(enc, node, i, ctx)
	if not bool(res.get("ok", false)):
		_enc_send(srv, peer, enc, node, "", true, "")
		return
	if String(res.get("set", "")) != "":
		flags_of(rec)["enc:" + String(res["set"])] = true
	var next := String(res["next"])
	var fx := EncounterDB.node_effects(enc, next)
	var out := ServerCtx.run(rec, func(): return EncounterDB.apply(res, fx))
	srv.after_ctx(peer, int(out["levels"]))
	var nctx: Dictionary = ServerCtx.run(rec, func(): return EncounterDB.ctx_game())["result"]
	if bool(EncounterDB.view(enc, next, nctx)["terminal"]):
		flags_of(rec)[EncounterDB.flag_done(enc)] = true
		var winst = pl.get("inst")
		if pl.has("wander") and String(pl["wander"]["obj"]["enc"]) == enc and winst != null:
			(winst as ZoneInstance).clear_wander(peer)
	srv.chars.mark_dirty()
	srv.push_prog(peer)
	srv._push_me(peer)
	_enc_send(srv, peer, enc, next, EncounterDB.roll_text(res["roll"]), bool((res["roll"] as Dictionary).get("success", true)), ", ".join(out["result"]))

static func talk_extra(srv: MmoServer, peer: int, inst: ZoneInstance, npc: String) -> void:
	var rec: Dictionary = srv.peers[peer]["rec"]
	if _heist_turn_in(srv, peer, inst, npc):
		return
	var enc := EncounterDB.enc_of_npc(npc)
	if enc != "":
		enc_start(srv, peer, enc)
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
