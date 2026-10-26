class_name SupportOps
extends RefCounted
## Towarzysze na serwerze: żołnierze (Ally) i pet (Pet) każdego gracza, szpital, skrytka, laboratorium i menu petów.
## Stan: rec["support"] = {"hp": {klucz: życie}, "fallen": {klucz: sekundy do powrotu}}; klucze: "ally:N" i "pet".
## Pety, skrytka i laboratorium korzystają z oryginalnej logiki GameState/ForgeDB w ServerCtx.

const HOSPITAL_SECS := 300.0
const LAB_BU_COST_MIN_SECS := 6.0
const LAB_KURCZ_MIN_SECS := 4.0
const KURCZALIUM_COST := {"wegiel": 1, "krysztal_cienia": 1, "sztabka_kurczalu": 2, "pierwiastek_bu": 1}

static func support_of(rec: Dictionary) -> Dictionary:
	if not (rec.get("support") is Dictionary):
		rec["support"] = {}
	var s: Dictionary = rec["support"]
	if not (s.get("hp") is Dictionary):
		s["hp"] = {}
	if not (s.get("fallen") is Dictionary):
		s["fallen"] = {}
	return s

static func pets_of(rec: Dictionary) -> Dictionary:
	var gsx: Dictionary = rec.get("gsx", {})
	var p = gsx.get("pets")
	if p is Dictionary:
		return p
	return {"unlocked": ["kurczaczek"], "equipped": "kurczaczek", "gear": {}, "xp": {}}

static func ally_count(srv: MmoServer, inst: ZoneInstance, rec: Dictionary) -> int:
	var act2 := QuestDB.act_of(maxi(0, int(MmoServer.story_of(rec).get("chapter", 0)))) == 2
	return int(inst.zone.get("allies", 4 if act2 else 3)) if inst.kind != "swiat" else 3

static func max_hp_of(rec: Dictionary, key: String) -> float:
	var lv := int(rec["level"])
	if key == "pet":
		var pid := String(pets_of(rec).get("equipped", ""))
		var pd: Dictionary = PetDB.get_data(pid) if PetDB.has(pid) else {}
		return float(pd.get("hp", 40.0)) + 8.0 * float(lv)
	return 70.0 + 16.0 * float(lv)

static func hp_of(rec: Dictionary, key: String) -> float:
	var mx := max_hp_of(rec, key)
	return minf(float((support_of(rec)["hp"] as Dictionary).get(key, mx)), mx)

static func heal_cost(rec: Dictionary, key: String) -> int:
	return maxi(1, int(ceil(maxf(0.0, max_hp_of(rec, key) - hp_of(rec, key)))))

static func revive_cost(rec: Dictionary) -> int:
	return 100 + 15 * int(rec["level"])

# -------------------------------------------------------------- towarzysze ---

static func spawn_for(srv: MmoServer, peer: int, inst: ZoneInstance) -> void:
	var pl: Dictionary = srv.peers[peer]
	var rec: Dictionary = pl["rec"]
	var node: Player = srv.player_of(peer)
	if node == null or inst.kind in ["arena", "challenge", "custom"]:
		return
	var sup := support_of(rec)
	for i in ally_count(srv, inst, rec):
		if (sup["fallen"] as Dictionary).has("ally:%d" % i):
			continue
		_make_ally(srv, peer, inst, node, rec, i, node.position)
	var pid := String(pets_of(rec).get("equipped", ""))
	if pid != "" and PetDB.has(pid) and pid in pets_of(rec).get("unlocked", []) and not (sup["fallen"] as Dictionary).has("pet"):
		_make_pet(srv, peer, inst, node, rec, pid, node.position)

static func _make_ally(srv: MmoServer, peer: int, inst: ZoneInstance, node: Player, rec: Dictionary, i: int, at: Vector2) -> void:
	var a := Ally.new()
	a.server_peer = peer
	a.s_level = int(rec["level"])
	a.s_strength = float(ServerChars.compute_stats(rec)["strength"])
	a.s_hp = hp_of(rec, "ally:%d" % i)
	a.net_id = "a%d_%d" % [peer, i]
	a.setup(node, i)
	a.hp_changed.connect(func(k: String, hp: float): (support_of(rec)["hp"] as Dictionary)[k] = hp)
	a.fell.connect(func(k: String): _on_fell(srv, peer, rec, k))
	inst.entities.add_child(a)
	a.position = at + a._formation()

static func _make_pet(srv: MmoServer, peer: int, inst: ZoneInstance, node: Player, rec: Dictionary, pid: String, at: Vector2) -> void:
	var p := Pet.new()
	p.server_peer = peer
	p.s_level = int(rec["level"])
	p.s_strength = float(ServerChars.compute_stats(rec)["strength"])
	p.s_gear = String((pets_of(rec).get("gear", {}) as Dictionary).get(pid, ""))
	p.s_hp = hp_of(rec, "pet")
	p.net_id = "p%d" % peer
	p.setup(node, pid)
	p.hp_changed.connect(func(k: String, hp: float): (support_of(rec)["hp"] as Dictionary)[k] = hp)
	p.fell.connect(func(k: String): _on_fell(srv, peer, rec, k))
	inst.entities.add_child(p)
	p.position = at + Vector2(-40.0, 10.0)

static func _on_fell(srv: MmoServer, peer: int, rec: Dictionary, key: String) -> void:
	var sup := support_of(rec)
	(sup["fallen"] as Dictionary)[key] = HOSPITAL_SECS
	(sup["hp"] as Dictionary).erase(key)
	var nm := "Towarzysz"
	if key == "pet":
		nm = String(PetDB.get_data(String(pets_of(rec).get("equipped", ""))).get("name", "Pupil"))
	else:
		nm = String(Ally.NAMES[int(key.substr(5)) % Ally.NAMES.size()])
	srv.say(peer, "%s poległ — leży w szpitalu, wróci za 5 minut (albo wypisz go w szpitalu za złoto)." % nm)
	srv.chars.mark_dirty()

## Co klatkę: czas leczenia poległych towarzyszy.
static func tick(srv: MmoServer, peer: int, delta: float) -> void:
	var rec: Dictionary = srv.peers[peer]["rec"]
	var fallen: Dictionary = support_of(rec)["fallen"]
	if fallen.is_empty() or srv.player_of(peer) == null:
		return
	for key in fallen.keys():
		fallen[key] = float(fallen[key]) - delta
		if float(fallen[key]) <= 0.0:
			fallen.erase(key)
			return_support(srv, peer, String(key))

static func return_support(srv: MmoServer, peer: int, key: String) -> void:
	var pl: Dictionary = srv.peers.get(peer, {})
	var inst: ZoneInstance = pl.get("inst")
	var node: Player = srv.player_of(peer)
	if pl.is_empty() or inst == null or node == null:
		return
	var rec: Dictionary = pl["rec"]
	var sup := support_of(rec)
	(sup["hp"] as Dictionary).erase(key)
	if key == "pet":
		var pid := String(pets_of(rec).get("equipped", ""))
		if PetDB.has(pid):
			_make_pet(srv, peer, inst, node, rec, pid, node.position)
	elif key.begins_with("ally:"):
		_make_ally(srv, peer, inst, node, rec, int(key.substr(5)), node.position)
	srv.say(peer, "Towarzysz wrócił do walki!")

## Przeładowuje towarzyszy (zmiana peta, poziomu, wyposażenia): usuwa starych i tworzy od nowa.
static func respawn(srv: MmoServer, peer: int) -> void:
	var pl: Dictionary = srv.peers.get(peer, {})
	var inst: ZoneInstance = pl.get("inst")
	if pl.is_empty() or inst == null:
		return
	for c in inst.entities.get_children():
		if (c is Ally or c is Pet) and int(c.server_peer) == peer:
			c.queue_free()
	spawn_for(srv, peer, inst)

static func snapshot(inst: ZoneInstance) -> Array:
	var out: Array = []
	for c in inst.entities.get_children():
		if c is Ally:
			var a := c as Ally
			if a.dying:
				continue
			out.append({"id": a.net_id, "k": "ally", "slot": a.slot, "x": a.position.x, "y": a.position.y, "f": a.visual.facing, "hp": a.hp, "mx": a.max_hp, "mv": a.visual.moving})
		elif c is Pet:
			var p := c as Pet
			if p.dying:
				continue
			out.append({"id": p.net_id, "k": "pet", "pet": p.pet_id, "gear": p.s_gear, "x": p.position.x, "y": p.position.y, "f": p.visual.facing, "hp": p.hp, "mx": p.max_hp, "mv": p.visual.moving})
	return out

# ------------------------------------------------------------------ szpital ---

static func hospital_state(srv: MmoServer, peer: int) -> Dictionary:
	var pl: Dictionary = srv.peers[peer]
	var rec: Dictionary = pl["rec"]
	var inst: ZoneInstance = pl["inst"]
	var sup := support_of(rec)
	var rows: Array = []
	var keys: Array = []
	for i in ally_count(srv, inst, rec):
		keys.append("ally:%d" % i)
	var pid := String(pets_of(rec).get("equipped", ""))
	if pid != "" and PetDB.has(pid) and pid in pets_of(rec).get("unlocked", []):
		keys.append("pet")
	for key in keys:
		var fallen := (sup["fallen"] as Dictionary).has(key)
		var title := String(Ally.NAMES[int(String(key).substr(5)) % Ally.NAMES.size()]) if key != "pet" else "Towarzysz: %s" % String(PetDB.get_data(pid).get("name", pid))
		rows.append({"key": key, "title": title, "hp": hp_of(rec, key), "max": max_hp_of(rec, key), "fallen": fallen,
			"left": float((sup["fallen"] as Dictionary).get(key, 0.0)), "heal": heal_cost(rec, key)})
	return {"rows": rows, "gold": int(rec["gold"]), "revive": revive_cost(rec), "secs": HOSPITAL_SECS}

static func open_hospital(srv: MmoServer, peer: int) -> void:
	srv.peers[peer]["panel"] = "hospital"
	srv.send_ev(peer, "hospital", hospital_state(srv, peer))

static func hospital_act(srv: MmoServer, peer: int, kind: String, key: String) -> void:
	if srv.peers[peer].get("panel", "") != "hospital":
		return
	var rec: Dictionary = srv.peers[peer]["rec"]
	var inst: ZoneInstance = srv.peers[peer]["inst"]
	var sup := support_of(rec)
	if kind == "heal":
		if (sup["fallen"] as Dictionary).has(key) or not (key == "pet" or key.begins_with("ally:")):
			return
		var cost := heal_cost(rec, key)
		if int(rec["gold"]) < cost:
			return
		rec["gold"] = int(rec["gold"]) - cost
		var mx := max_hp_of(rec, key)
		(sup["hp"] as Dictionary)[key] = mx
		for c in inst.entities.get_children():
			if (c is Ally and key.begins_with("ally:") and int((c as Ally).slot) == int(key.substr(5)) and (c as Ally).server_peer == peer):
				(c as Ally).hp = mx
			elif c is Pet and key == "pet" and (c as Pet).server_peer == peer:
				(c as Pet).hp = mx
		srv.say(peer, "Wyleczono za %d zł." % cost)
	elif kind == "revive":
		var rc := revive_cost(rec)
		if int(rec["gold"]) < rc or not (sup["fallen"] as Dictionary).has(key):
			return
		rec["gold"] = int(rec["gold"]) - rc
		(sup["fallen"] as Dictionary).erase(key)
		(sup["hp"] as Dictionary).erase(key)
		return_support(srv, peer, key)
		srv.say(peer, "Wypisano ze szpitala za %d zł." % rc)
	srv.chars.mark_dirty()
	srv._push_me(peer)
	srv.send_ev(peer, "hospital", hospital_state(srv, peer))

# ------------------------------------------------------------------ skrytka ---

static func stash_state(srv: MmoServer, peer: int) -> Dictionary:
	var rec: Dictionary = srv.peers[peer]["rec"]
	var res := ServerCtx.run(rec, func():
		var tabs: Array = []
		var st := GameState.stash()
		for t in st.size():
			var tab: Array = []
			for i in (st[t] as Array).size():
				var e = st[t][i]
				if e is Dictionary:
					var ent := ServerCtx._to_entry(e)
					ent["slot"] = i
					tab.append(ent)
			tabs.append(tab)
		return tabs)
	return {"tabs": res["result"], "slots": GameState.STASH_SLOTS}

static func open_stash(srv: MmoServer, peer: int) -> void:
	srv.peers[peer]["panel"] = "stash"
	srv.send_ev(peer, "stash", stash_state(srv, peer))

static func stash_act(srv: MmoServer, peer: int, kind: String, a: int, b: int) -> void:
	if srv.peers[peer].get("panel", "") != "stash":
		return
	var rec: Dictionary = srv.peers[peer]["rec"]
	var res := ServerCtx.run(rec, func():
		if kind == "put":
			return GameState.stash_put(a, clampi(b, 0, GameState.STASH_TABS - 1))
		return GameState.stash_take(clampi(a, 0, GameState.STASH_TABS - 1), b))
	if not bool(res["result"]):
		srv.say(peer, "Nie da się przenieść (zakładka albo plecak pełny).")
	srv.chars.mark_dirty()
	srv._push_me(peer)
	srv.send_ev(peer, "stash", stash_state(srv, peer))

# ------------------------------------------------------------ laboratorium ---

static func open_lab(srv: MmoServer, peer: int) -> void:
	srv.peers[peer]["panel"] = "lab"
	srv.peers[peer]["lab_t0"] = Time.get_ticks_msec() * 0.001
	srv.send_ev(peer, "lab", {"gold": int(srv.peers[peer]["rec"]["gold"])})

static func lab_act(srv: MmoServer, peer: int, kind: String, data: Dictionary) -> void:
	var pl: Dictionary = srv.peers[peer]
	if pl.get("panel", "") != "lab":
		return
	var rec: Dictionary = pl["rec"]
	var now := Time.get_ticks_msec() * 0.001
	var elapsed := now - float(pl.get("lab_t0", now))
	match kind:
		"buy":
			if int(rec["gold"]) >= 25 and ServerChars.inv_add(rec, "wegiel", 1) > 0:
				rec["gold"] = int(rec["gold"]) - 25
		"start":
			pl["lab_t0"] = now
			return
		"bu":
			var idx := int(data.get("idx", -1))
			var ratio := clampf(float(data.get("ratio", 0.0)), 0.0, 1.0)
			var secs := float(data.get("secs", 0.0))
			var inv: Array = rec["inv"]
			if idx < 0 or idx >= inv.size():
				return
			var id := String(inv[idx]["id"])
			var rar := ItemDB.rarity_of(id)
			if rar != "legendarny" and rar != "hiperlegendarny":
				srv.say(peer, "Tylko legendarne przedmioty można poświęcić.")
				return
			if elapsed < LAB_BU_COST_MIN_SECS:
				ratio = minf(ratio, 0.3)
			var tier_bonus := 6 if rar == "hiperlegendarny" else 3
			var yield_n := maxi(1, int(round(float(tier_bonus) * ratio)))
			if ratio >= 1.0 and secs < 20.0 and elapsed >= LAB_BU_COST_MIN_SECS + 4.0:
				yield_n += 1
			inv[idx]["n"] = int(inv[idx]["n"]) - 1
			if int(inv[idx]["n"]) <= 0:
				inv.remove_at(idx)
			ServerChars.inv_add(rec, "pierwiastek_bu", yield_n)
			srv.say(peer, "Przedmiot zamienił się w %d × pierwiastek BU." % yield_n)
		"kurcz":
			if elapsed < LAB_KURCZ_MIN_SECS:
				srv.say(peer, "Za szybko — kocioł jeszcze nie ugotował.")
				return
			var res := ServerCtx.run(rec, func():
				for cid in KURCZALIUM_COST:
					if GameState.item_count(String(cid)) < int(KURCZALIUM_COST[cid]):
						return false
				for rid in KURCZALIUM_COST:
					GameState.remove_item(String(rid), int(KURCZALIUM_COST[rid]))
				ForgeDB.learn_metal("kurczalium")
				GameState.add_item("sztabka_kurczalium", 1)
				return true)
			if bool(res["result"]):
				srv.say(peer, "Kocioł ucichł. Na dnie zastygła sztabka kurczalium!")
			else:
				srv.say(peer, "Brakuje składników.")
	srv.chars.mark_dirty()
	srv._push_me(peer)
	srv.send_ev(peer, "lab", {"gold": int(rec["gold"])})

# -------------------------------------------------------------------- pety ---

static func pet_act(srv: MmoServer, peer: int, kind: String, pet: String, item: String) -> void:
	var rec: Dictionary = srv.peers[peer]["rec"]
	var res := ServerCtx.run(rec, func():
		match kind:
			"equip":
				GameState.equip_pet(pet)
				return true
			"gear":
				return GameState.set_pet_gear(pet, item)
			"ungear":
				return GameState.unequip_pet_gear(pet)
		return false)
	if not bool(res["result"]) and kind != "equip":
		srv.say(peer, "Nie udało się (brak przedmiotu albo miejsca w plecaku).")
	srv.chars.mark_dirty()
	srv._push_me(peer)
	respawn(srv, peer)
