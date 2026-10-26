class_name ServerCtx
extends RefCounted
## Kontekst gry dla postaci serwerowej: na czas jednego wywołania podmienia GameState.profile/run na profil zbudowany
## z rekordu postaci, żeby oryginalna logika (SecretDB.grant, SideDB, ForgeDB, ChapterExtras…) działała bez zmian.
## Po wywołaniu zmiany (złoto, plecak, poziom, flagi, sekrety, zlecenia, kuźnia) wracają do rekordu.
## Wywołania są synchroniczne (bez await), więc podmiana jest bezpieczna.

const SKIP_KEYS := ["version", "gold", "cod", "zlot", "unlocks", "stage_unlocked", "characters", "settings", "story", "appearance",
		"customization", "skill_tree", "inventory", "paint_anims", "quests", "campaign", "seen_intro", "seen_creator", "act"]
const INV_SIZE := 40

## Uruchamia `fn` w kontekście postaci `rec`. Zwraca {"result": wartość, "toasts": [tekst], "levels": zdobyte poziomy}.
static func run(rec: Dictionary, fn: Callable, step: int = 0) -> Dictionary:
	var gs := GameState
	var old_profile: Dictionary = gs.profile
	var old_run: Dictionary = gs.run
	var old_last: String = gs._last_char
	var cid := String(rec["char"])
	var inv40: Array = []
	for e in rec["inv"]:
		if inv40.size() < INV_SIZE:
			var ent := {"id": String(e["id"]), "n": int(e["n"]), "q": float(e.get("q", 1.0))}
			if e.has("m"):
				ent["m"] = (e["m"] as Dictionary).duplicate(true)
			inv40.append(ent)
	while inv40.size() < INV_SIZE:
		inv40.append(null)
	var cp := {
		"unlocked": true, "level": int(rec["level"]), "xp": int(rec["xp"]), "class": String(rec["class"]),
		"equip": (rec["equip"] as Dictionary).duplicate(), "gear": [], "skills": (rec["skills"] as Array).duplicate(),
		"backpack": {}, "best": {}, "attr_points": int(rec.get("attr_points", 0)), "attrs": (rec["attrs"] as Dictionary).duplicate(),
		"skill_points": 0, "inv": inv40, "equip_q": (rec.get("equip_q", {}) as Dictionary).duplicate(), "equip_m": (rec.get("equip_m", {}) as Dictionary).duplicate(true), "bag_init": true, "tree_init": true, "tree": {}, "overflow": [],
	}
	var prof: Dictionary = gs._blank_profile()
	var gsx: Dictionary = rec.get("gsx", {})
	for k in gsx:
		prof[k] = gsx[k].duplicate(true) if (gsx[k] is Dictionary or gsx[k] is Array) else gsx[k]
	prof["gold"] = int(rec["gold"])
	prof["characters"] = {cid: cp}
	var st: Dictionary = rec["story"]
	prof["story"] = {"chapter": int(st.get("chapter", 0)), "quest": String(st.get("quest", "")), "step": step,
		"flags": (st.get("flags", {}) as Dictionary).duplicate(true), "done": (st.get("done", []) as Array).duplicate()}
	gs.profile = prof
	gs.run = {"character": cid, "stats": ServerChars.compute_stats(rec), "buffs": {}, "health": 100.0, "energy": 100.0, "kills": 0}
	gs._last_char = cid
	var toasts: Array = []
	var collector := func(text: String, _c: Color): toasts.append(text)
	gs.toast.connect(collector)
	var level_before := int(rec["level"])
	var result = fn.call()
	gs.toast.disconnect(collector)
	# zapis zmian do rekordu
	var cp2: Dictionary = (prof["characters"] as Dictionary)[cid]
	rec["gold"] = int(prof.get("gold", 0))
	rec["level"] = int(cp2.get("level", 1))
	rec["xp"] = int(cp2.get("xp", 0))
	rec["attr_points"] = int(cp2.get("attr_points", 0))
	var inv: Array = []
	for e in cp2.get("inv", []):
		if e is Dictionary:
			inv.append(_to_entry(e))
	for e in cp2.get("overflow", []):
		if e is Dictionary and inv.size() < INV_SIZE:
			inv.append(_to_entry(e))
	rec["inv"] = inv
	rec["equip"] = (cp2.get("equip", {}) as Dictionary).duplicate()
	rec["equip_q"] = (cp2.get("equip_q", {}) as Dictionary).duplicate()
	rec["equip_m"] = (cp2.get("equip_m", {}) as Dictionary).duplicate(true)
	var st2: Dictionary = prof["story"]
	st["flags"] = (st2.get("flags", {}) as Dictionary).duplicate(true)
	st["done"] = (st2.get("done", []) as Array).duplicate()
	var out := {}
	for k in prof:
		if k not in SKIP_KEYS:
			out[k] = prof[k]
	rec["gsx"] = out
	gs.profile = old_profile
	gs.run = old_run
	gs._last_char = old_last
	return {"result": result, "toasts": toasts, "levels": int(rec["level"]) - level_before}

static func _to_entry(e: Dictionary) -> Dictionary:
	var out := {"id": String(e["id"]), "n": int(e["n"])}
	if e.has("q") and not is_equal_approx(float(e["q"]), 1.0):
		out["q"] = float(e["q"])
	var m = e.get("m", {})
	if m is Dictionary and not (m as Dictionary).is_empty():
		out["m"] = (m as Dictionary).duplicate(true)
	return out
