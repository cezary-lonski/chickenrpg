class_name MmoWorld
extends Node2D
## Klient świata ChickenSerwera: renderuje strefę (Pustkowie albo rozdział kampanii), graczy, moby i NPC ze snapshotów
## serwera (duchy Player/Enemy), wysyła wejście i obsługuje dialogi, sklep, czat (T), ekwipunek (I), interakcję (E).
## Cała symulacja i fabuła dzieją się na serwerze.

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const PLAYER_SCENE := preload("res://scenes/player.tscn")
const PALETTES := {
	"road": [Color(0.42, 0.5, 0.3), Color(0.58, 0.5, 0.34), Color(0.22, 0.34, 0.2, 0.35)],
	"city": [Color(0.34, 0.32, 0.3), Color(0.46, 0.44, 0.42), Color(0.28, 0.24, 0.22, 0.35)],
	"tower": [Color(0.3, 0.3, 0.36), Color(0.42, 0.42, 0.5), Color(0.2, 0.2, 0.28, 0.4)],
	"forest": [Color(0.2, 0.34, 0.22), Color(0.4, 0.34, 0.22), Color(0.15, 0.28, 0.16, 0.4)],
	"fortress": [Color(0.2, 0.19, 0.22), Color(0.32, 0.29, 0.3), Color(0.14, 0.12, 0.16, 0.45)],
	"ash": [Color(0.17, 0.16, 0.18), Color(0.28, 0.25, 0.26), Color(0.42, 0.18, 0.14, 0.28)],
	"desert": [Color(0.72, 0.59, 0.36), Color(0.83, 0.72, 0.48), Color(0.58, 0.45, 0.26, 0.32)],
	"storm": [Color(0.16, 0.25, 0.21), Color(0.35, 0.3, 0.24), Color(0.1, 0.17, 0.19, 0.5)],
	"dawn": [Color(0.29, 0.22, 0.27), Color(0.44, 0.35, 0.32), Color(0.72, 0.4, 0.24, 0.3)],
	"cave": [Color(0.11, 0.1, 0.14), Color(0.18, 0.16, 0.21), Color(0.35, 0.22, 0.5, 0.3)],
	"palace": [Color(0.62, 0.6, 0.67), Color(0.62, 0.14, 0.2), Color(0.5, 0.48, 0.58, 0.3)],
	"village": [Color(0.32, 0.46, 0.27), Color(0.52, 0.42, 0.28), Color(0.24, 0.36, 0.2, 0.35)],
}

var entities: Node2D
var camera: Camera2D
var hud: UiMmoHud
var zone: Dictionary = {}
var _scenery: Node2D
var _ground: Node
var _ghosts: Dictionary = {}      # peer id -> Player
var _targets: Dictionary = {}     # node -> Vector2
var _mobs: Dictionary = {}        # net_id -> Enemy
var _npcs: Dictionary = {}        # npc id -> {node, marker, prompt, pos}
var _roster_sig: Dictionary = {}
var _acc := 0.0
var _pending: Array = []
var _left := false
var _marks: Dictionary = {}
var _prog: Dictionary = {}
var _objs: Dictionary = {}        # uid -> {node, data}
var _side: Dictionary = {}        # uid -> Interactable (zlecenia poboczne)
var _guards: Array = []           # strażnicy skradanki (tylko rysowani; wykrycie liczy serwer)
var _z: Dictionary = {}
var _my_cd: Array = []
var _sup: Dictionary = {}         # id towarzysza -> duch Ally/Pet

func _ready() -> void:
	GameState.rpg = {"active": true, "mode": "mmo"}
	camera = Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.zoom = Vector2.ONE * GameState.view_zoom()
	add_child(camera)
	hud = UiMmoHud.new()
	hud.exit_requested.connect(_leave)
	hud.dialog_closed.connect(func(token: int): Mmo.send_act("dialog_done", {"token": token}))
	hud.loot_taken.connect(func(token: int, i: int): Mmo.send_act("loot_take", {"token": token, "i": i}))
	hud.enc_picked.connect(func(token: int, i: int): Mmo.send_act("enc_pick", {"token": token, "i": i}))
	hud.puzzle_hint.connect(func(token: int): Mmo.send_act("puzzle_hint", {"token": token}))
	hud.puzzle_done.connect(func(token: int, ok: bool): Mmo.send_act("puzzle_done", {"token": token, "ok": ok}))
	hud.choice_picked.connect(func(token: int, i: int): Mmo.send_act("choice_pick", {"token": token, "i": i}))
	add_child(hud)
	Mmo.snapshot_received.connect(_on_snapshot)
	Mmo.roster_received.connect(_on_roster)
	Mmo.disconnected.connect(_on_disconnected)
	Mmo.zone_received.connect(_on_zone)
	Mmo.event_received.connect(_on_event)
	_on_zone(Mmo.zone_info)
	_on_roster(Mmo.roster)
	Fx.fade_to(0.0, 1.6)
	Audio.play_music("village")
	Mmo.flush_events.call_deferred()

func _exit_tree() -> void:
	Mmo.events_ready = false
	for pair in [[Mmo.snapshot_received, _on_snapshot], [Mmo.roster_received, _on_roster], [Mmo.disconnected, _on_disconnected],
			[Mmo.zone_received, _on_zone], [Mmo.event_received, _on_event]]:
		if (pair[0] as Signal).is_connected(pair[1]):
			(pair[0] as Signal).disconnect(pair[1])
	GameState.rpg = {}

func _leave() -> void:
	if _left:
		return
	_left = true
	Mmo.stop()
	Flow.goto("menu")

func _on_disconnected(reason: String) -> void:
	if _left:
		return
	_left = true
	GameState.toast.emit(reason, UiKit.BAD)
	Flow.goto("menu")

# -------------------------------------------------------------------- strefa ---

func _on_zone(info: Dictionary) -> void:
	if info.is_empty():
		return
	zone = info
	if hud != null and hud.has_overlay():
		hud.close_overlay()
	for g in _ghosts.values():
		if is_instance_valid(g):
			g.queue_free()
	_ghosts.clear()
	_roster_sig.clear()
	_targets.clear()
	_mobs.clear()
	_npcs.clear()
	_objs.clear()
	_side.clear()
	_guards.clear()
	_sup.clear()
	_prog = {}
	_z = {}
	if _ground != null and is_instance_valid(_ground):
		_ground.queue_free()
	if entities != null and is_instance_valid(entities):
		entities.queue_free()
	if _scenery != null and is_instance_valid(_scenery):
		_scenery.queue_free()
	var size: Vector2 = info.get("size", Vector2(2200, 1500))
	var pal: Array = PALETTES.get(String(info.get("terrain", "village")), PALETTES["village"])
	_ground = PixelGround.sprite(String(info.get("terrain", "village")), size, pal[0], pal[1], pal[2])
	add_child(_ground)
	move_child(_ground, 0)
	_scenery = Node2D.new()
	_scenery.z_index = -3
	add_child(_scenery)
	_build_scenery(String(info.get("terrain", "village")), size, String(info.get("kind", "story")) == "swiat")
	entities = Node2D.new()
	entities.y_sort_enabled = true
	add_child(entities)
	camera.limit_right = int(size.x)
	camera.limit_bottom = int(size.y)
	camera.position = info.get("spawn", Vector2.ZERO)
	camera.reset_smoothing()
	Fx.set_world(entities, camera)
	if String(info.get("kind", "")) == "swiat":
		var mark := Node2D.new()
		mark.position = info.get("spawn", Vector2.ZERO)
		mark.z_index = -2
		mark.set_script(preload("res://scripts/mmo_spawn_mark.gd"))
		add_child(mark)
	for n in info.get("npcs", []):
		_make_npc(String(n["id"]), n["pos"])
	for o in info.get("objs", []):
		_make_object(o)
	for b in info.get("buildings", []):
		_make_building(String(b["kind"]), b["pos"])
	var hz: Dictionary = info.get("heist", {})
	for g in hz.get("guards", []):
		var sg := StealthGuard.new()
		sg.detect = false
		sg.clock = float(hz.get("t", 0.0))
		sg.setup(g["path"], float(g.get("range", 250.0)))
		entities.add_child(sg)
		_guards.append(sg)
	_refresh_guards()
	if String(info.get("mine_id", "")) != "":
		var deco := MineDecor.new()
		deco.setup(String(info["mine_id"]))
		deco.z_index = -3
		entities.add_child(deco)
	hud.set_zone_title(String(info.get("title", "")))
	_on_roster(Mmo.roster)

func _build_scenery(terrain: String, size: Vector2, open_world: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(zone.get("key", "")))
	var leaf := Color(0.2, 0.46, 0.22) if terrain == "forest" else Color(0.25, 0.5, 0.24)
	var n := 70 if open_world else 34
	for i in n:
		var p := Vector2(rng.randf_range(60.0, size.x - 60.0), rng.randf_range(60.0, size.y - 60.0))
		# drzewa tylko przy brzegach mapy, żeby nie wchodzić graczom pod nogi
		if p.x > 200.0 and p.x < size.x - 200.0 and p.y > 200.0 and p.y < size.y - 200.0 and terrain != "forest":
			continue
		var holder := Node2D.new()
		holder.position = p
		var s := rng.randf_range(0.9, 1.4)
		holder.scale = Vector2(s, s)
		match terrain:
			"city", "tower", "fortress", "palace":
				holder.add_child(PixelProps.pillar())
			"desert", "ash", "cave":
				holder.add_child(PixelProps.rock(i, Color(0.5, 0.42, 0.35)))
			_:
				holder.add_child(PixelProps.tree(i, leaf))
		_scenery.add_child(holder)

func _make_npc(id: String, pos: Vector2) -> void:
	var data := NpcDB.get_data(id)
	var accent: Color = data.get("accent", UiKit.ACCENT)
	var n := Node2D.new()
	n.position = pos
	entities.add_child(n)
	if String(data.get("role", "")) == "shop":
		var stall := MerchantStall.new()
		stall.setup(accent, 17)
		stall.position = Vector2(-104, -26)
		n.add_child(stall)
	if String(data.get("role", "")) == "smith":
		var prop := ForgeProp.new()
		prop.position = Vector2(60, 22)
		n.add_child(prop)
	var cv := CreatureVisual.new()
	cv.configure(String(data.get("species", "kurczak")), NpcDB.pal_for(id), float(data.get("scale", 1.4)))
	cv.set_facing(-1.0)
	cv.idle_seed = float(id.hash() % 100) * 0.13
	n.add_child(cv)
	var name_l := _label(String(data.get("name", "?")), 14, Color(0.95, 0.96, 1.0), Vector2(-70, -96))
	n.add_child(name_l)
	var marker := _label("", 24, accent, Vector2(-70, -132))
	n.add_child(marker)
	var prompt := _label("[E] porozmawiaj", 13, accent, Vector2(-70, -78))
	prompt.visible = false
	n.add_child(prompt)
	_npcs[id] = {"node": n, "marker": marker, "prompt": prompt, "pos": pos, "cv": cv}

func _label(text: String, size: int, col: Color, pos: Vector2) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.custom_minimum_size = Vector2(140, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 5)
	return l

# ---------------------------------------------------------------- obiekty ---

func _make_building(kind: String, pos: Vector2) -> void:
	var bld := Node2D.new()
	bld.position = pos
	entities.add_child(bld)
	bld.add_child(PixelProps.lab_building() if kind == "lab" else PixelProps.hospital_building())

func _make_object(o: Dictionary) -> void:
	var uid := String(o["uid"])
	if _objs.has(uid) and is_instance_valid(_objs[uid]["node"]):
		return
	var it := Interactable.new()
	it.setup(String(o.get("kind", "chest")), String(o.get("label", "Użyj")), uid, bool(o.get("hidden", false)))
	it.position = o["pos"]
	entities.add_child(it)
	_objs[uid] = {"node": it, "data": o}
	_refresh_objects()

func _flags() -> Dictionary:
	return _prog.get("flags", {}) if _prog.get("flags") is Dictionary else {}

func _secrets() -> Dictionary:
	return _prog.get("secrets", {}) if _prog.get("secrets") is Dictionary else {}

func _levers_done(total: int) -> int:
	var q := String(zone.get("quest", ""))
	var lv: Dictionary = _secrets().get("levers", {}) if _secrets().get("levers") is Dictionary else {}
	var arr: Array = lv.get(q, [])
	var n := 0
	for i in total:
		if bool(_flags().get("lv:%s:%d" % [q, i], false)) or i in arr:
			n += 1
	return n

func _refresh_objects() -> void:
	var flags := _flags()
	var chests: Array = _secrets().get("chests", []) if _secrets().get("chests") is Array else []
	var q := String(zone.get("quest", ""))
	var waves_n := int(zone.get("waves_n", 0))
	var step := int(_z.get("step", 0))
	var lv: Dictionary = _secrets().get("levers", {}) if _secrets().get("levers") is Dictionary else {}
	for uid in _objs:
		var e: Dictionary = _objs[uid]
		var it: Interactable = e["node"]
		if not is_instance_valid(it):
			continue
		var o: Dictionary = e["data"]
		match String(o.get("type", "")):
			"obj":
				it.done = bool(flags.get(String(uid), false))
				it.visible = String(o.get("phase", "pre")) != "post" or step > waves_n
			"chest":
				it.done = String(uid) in chests
			"lever":
				it.done = bool(flags.get(String(uid), false)) or int(o["idx"]) in (lv.get(q, []) as Array)
			"heist":
				it.done = _heist_off()
			"prisoner":
				it.done = bool(flags.get(String(uid), false))
			"entrance":
				it.visible = _levers_done(int(o.get("levers", 3))) >= int(o.get("levers", 3))

## Skradanka nie dotyczy gracza, który zwędził lutnię albo już ją oddał (strażnicy znikają z mapy).
func _heist_off() -> bool:
	var hz: Dictionary = zone.get("heist", {})
	if hz.is_empty():
		return true
	var q := String(zone.get("quest", ""))
	var fl := _flags()
	return bool(fl.get("heist_taken:" + q, false)) or bool(fl.get(ChapterExtras.flag(q, String(hz.get("id", "")), 0), false))

var _camp_off := false

## Strażnicy znikają też po pokonaniu naczelnika obozu (cel z pola `disarm`).
func _guards_off() -> bool:
	var hz: Dictionary = zone.get("heist", {})
	if bool(hz.get("camp", false)):
		return _camp_off
	if _heist_off():
		return true
	var did := String(hz.get("disarm", ""))
	return did != "" and bool(_flags().get(ChapterExtras.flag(String(zone.get("quest", "")), did, 0), false))

func _refresh_guards() -> void:
	var off := _guards_off()
	for g in _guards:
		if is_instance_valid(g):
			g.active = not off
			g.visible = not off

## Pasek wykrycia gracza z serwera: zaczerwienia stożek strażnika, który patrzy na niego najmocniej.
func _heist_alert(a: float) -> void:
	var me: Player = _ghosts.get(Mmo.my_peer)
	var best: StealthGuard = null
	var best_s := -1.0
	for g in _guards:
		if not is_instance_valid(g):
			continue
		g.alert = 0.0
		if me != null:
			var s := StealthGuard.sees(g.position, g.facing, g.view_range, me.position)
			if s > best_s:
				best_s = s
				best = g
	if best != null:
		best.alert = a

func _set_side(list: Array) -> void:
	for uid in _side.keys():
		if is_instance_valid(_side[uid]):
			_side[uid].queue_free()
	_side.clear()
	for o in list:
		var it := Interactable.new()
		it.setup(String(o.get("kind", "herb")), String(o.get("label", "Użyj")), String(o["uid"]))
		it.position = o["pos"]
		entities.add_child(it)
		_side[String(o["uid"])] = it

# ------------------------------------------------------------------ zdarzenia ---

func _on_event(kind: String, data: Dictionary) -> void:
	match kind:
		"banner":
			var b := UiBanner.new()
			b.setup(String(data.get("title", "")), String(data.get("sub", "")))
			add_child(b)
			Audio.play("gate", 1.0, -8.0)
		"dialog":
			hud.open_dialog(int(data.get("token", 0)), data.get("lines", []), data.get("accent", UiKit.ACCENT), String(data.get("scene", "")))
		"loot":
			hud.open_loot(int(data.get("token", 0)), data.get("box", {}))
		"loot_close":
			hud.close_loot()
		"objs_del":
			var duid := String(data.get("uid", ""))
			if _objs.has(duid):
				if is_instance_valid(_objs[duid]["node"]):
					(_objs[duid]["node"] as Node).queue_free()
				_objs.erase(duid)
		"wander":
			_make_object(data["obj"])
		"wander_off":
			var wuid := String(data.get("uid", ""))
			if _objs.has(wuid):
				if is_instance_valid(_objs[wuid]["node"]):
					(_objs[wuid]["node"] as Node).queue_free()
				_objs.erase(wuid)
		"enc":
			hud.open_encounter(int(data.get("token", 0)), data.get("view", {}), String(data.get("roll", "")), bool(data.get("ok", true)), String(data.get("fx", "")))
		"puzzle_hint":
			hud.puzzle_hint_ok()
		"puzzle":
			hud.open_puzzle(int(data.get("token", 0)), String(data.get("kind", "")), String(data.get("uid", "")), String(data.get("pick", "")))
		"shop":
			hud.open_shop(data.get("stock", []), int(data.get("gold", 0)))
		"hospital", "stash", "lab", "worldmap":
			hud.open_overlay(kind, data)
		"forge":
			hud.open_forge(data)
		"forge_result":
			hud.forge_result(data)
		"choice":
			hud.open_choice(int(data.get("token", 0)), String(data.get("prompt", "")), data.get("options", []), data.get("accent", UiKit.ACCENT))
		"prog":
			_prog = data
			_refresh_objects()
			_refresh_guards()
			_refresh_tracker()
		"heist_alert":
			_heist_alert(float(data.get("a", 0.0)))
			if bool(data.get("hit", false)):
				Audio.play("hit_heavy", 0.7, -4.0)
				Fx.shake(6.0, 0.3)
		"camp_off":
			_camp_off = true
			_refresh_guards()
		"notice":
			var ne: Enemy = _mobs.get(String(data.get("id", "")))
			if ne != null and is_instance_valid(ne):
				Fx.popup(ne.global_position + Vector2(0, -78), "!", Color(1.0, 0.3, 0.2))
		"objs_add":
			for o in data.get("objs", []):
				_make_object(o)
		"side_objs":
			_set_side(data.get("objs", []))

# ------------------------------------------------------------------ wejście ---

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.is_pressed() or event.is_echo():
		return
	var key := (event as InputEventKey).keycode
	if key == KEY_ESCAPE:
		hud.handle_escape()
		get_viewport().set_input_as_handled()
	elif hud.is_typing() or hud.is_dialog_open():
		return
	elif key == KEY_T or key == KEY_ENTER:
		hud.open_chat()
		get_viewport().set_input_as_handled()
	elif key == KEY_SLASH:
		hud.open_chat("/")
		get_viewport().set_input_as_handled()
	elif key == KEY_I:
		hud.toggle_inventory()
		get_viewport().set_input_as_handled()
	elif key == KEY_O and (not hud.is_blocking() or hud.inv_panel.visible):
		hud.open_skills()
		get_viewport().set_input_as_handled()
	elif key == KEY_K and not hud.is_blocking():
		hud.open_overlay("tree", {})
		get_viewport().set_input_as_handled()
	elif key == KEY_B and not hud.is_blocking():
		hud.open_overlay("waves", {})
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("world_map") and not hud.is_blocking():
		hud.open_world_map()
		get_viewport().set_input_as_handled()
	elif key == KEY_P and not hud.is_blocking():
		hud.open_overlay("pets", {})
		get_viewport().set_input_as_handled()
	elif key == KEY_E and not hud.is_blocking():
		Mmo.send_act("interact")
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	for node in _targets.keys():
		if not is_instance_valid(node):
			_targets.erase(node)
			continue
		var t: Vector2 = _targets[node]
		var d := (node as Node2D).position.distance_to(t)
		if d > 500.0:
			(node as Node2D).position = t
		else:
			(node as Node2D).position = (node as Node2D).position.lerp(t, 1.0 - exp(-20.0 * delta))
	var me: Player = _ghosts.get(Mmo.my_peer)
	if me != null and is_instance_valid(me):
		camera.position = me.position
		me.skill_slots = Mmo.my_info.get("skills", [])
		me.skill_cd = _my_cd
		hud.bind_player(me)
		hud.set_vitals(me.hp, me.max_hp, me.energy, me.max_energy, me.hp <= 0.0, _ghosts.size())
		_update_npc_prompts(me)
	_send_input(delta)

func _update_npc_prompts(me: Player) -> void:
	var best := ""
	var best_d := 110.0
	for id in _npcs:
		var d: float = (_npcs[id]["pos"] as Vector2).distance_to(me.position)
		if d < best_d:
			best_d = d
			best = String(id)
	for id in _npcs:
		var e: Dictionary = _npcs[id]
		(e["prompt"] as Label).visible = id == best and not hud.is_blocking()
		var cv: CreatureVisual = e["cv"]
		var near := (e["pos"] as Vector2).distance_to(me.position) < 180.0
		if near:
			cv.set_facing(signf(me.position.x - (e["pos"] as Vector2).x) if absf(me.position.x - (e["pos"] as Vector2).x) > 12.0 else cv.facing)

func _send_input(delta: float) -> void:
	var blocked := hud.is_blocking()
	if not blocked:
		for a in Mmo.ALLOWED_ACTIONS:
			if a == "throw_item" and Input.is_key_pressed(KEY_I):
				continue   # I otwiera ekwipunek, nie rzuca przedmiotu
			if Input.is_action_just_pressed(a):
				_pending.append(a)
	_acc += delta
	if _acc < 0.05:
		return
	_acc = 0.0
	var move := Vector2.ZERO if blocked else Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var held := {"block": not blocked and Input.is_action_pressed("block"), "sprint": not blocked and Input.is_action_pressed("sprint")}
	Mmo.send_input(move, held, _pending)
	_pending.clear()

# ----------------------------------------------------------------- snapshoty ---

func _on_roster(roster: Dictionary) -> void:
	for id in roster:
		var pid := int(id)
		var info: Dictionary = roster[id]
		var sig := str(info)
		if _roster_sig.get(pid, "") == sig:
			continue
		_roster_sig[pid] = sig
		if _ghosts.has(pid):
			_dress(_ghosts[pid], info)
	for pid in _ghosts.keys():
		if not roster.has(pid):
			var g: Player = _ghosts[pid]
			_targets.erase(g)
			if is_instance_valid(g):
				g.queue_free()
			_ghosts.erase(pid)
			_roster_sig.erase(pid)

func _dress(g: Player, info: Dictionary) -> void:
	var look := String(info.get("look", ""))
	var cid := String(info.get("char", "kurczak"))
	var base_id := look if CharacterDB.LIST.has(look) else cid
	g.visual.configure(base_id, CharacterDB.get_data(base_id)["pal"], 1.0)
	g.visual.apply_appearance(info.get("appearance", {}))
	g.visual.set_gear(CosmeticDB.gear_visual(info.get("equip", {}), {}))
	var tag: Label = g.get_node_or_null("Nameplate")
	if tag:
		tag.text = "%s  [%d]" % [info.get("name", ""), int(info.get("level", 1))]
		tag.add_theme_color_override("font_color", Color(1.0, 0.5, 0.95) if bool(info.get("admin", false)) else Color(1.0, 0.92, 0.6))

func _make_ghost(pid: int, info: Dictionary) -> Player:
	var g := PLAYER_SCENE.instantiate() as Player
	g.forced_character = String(info.get("char", "kurczak"))
	g.net_ghost = true
	g.local_view = pid == Mmo.my_peer
	g.position = zone.get("spawn", Vector2.ZERO)
	entities.add_child(g)
	var tag := Label.new()
	tag.name = "Nameplate"
	tag.position = Vector2(-70, -96)
	tag.custom_minimum_size = Vector2(140, 0)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_size_override("font_size", 13)
	tag.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	tag.add_theme_constant_override("outline_size", 4)
	g.add_child(tag)
	_ghosts[pid] = g
	_dress(g, info)
	return g

func _on_snapshot(snap: Dictionary) -> void:
	if entities == null or not is_instance_valid(entities):
		return
	for info in snap.get("players", []):
		var pid := int(info.get("id", 0))
		var g: Player = _ghosts.get(pid)
		if g == null or not is_instance_valid(g):
			var r: Dictionary = Mmo.roster.get(pid, {})
			if r.is_empty():
				continue
			g = _make_ghost(pid, r)
			g.position = Vector2(float(info.get("x", 0.0)), float(info.get("y", 0.0)))
		var target := Vector2(float(info.get("x", g.position.x)), float(info.get("y", g.position.y)))
		var i2: Dictionary = info.duplicate()
		i2["x"] = g.global_position.x
		i2["y"] = g.global_position.y
		g.apply_net_state(i2)
		_targets[g] = target
		if pid == Mmo.my_peer:
			_my_cd = info.get("cd", [])
	_apply_enemies(snap.get("enemies", []))
	_apply_support(snap.get("sup", []))
	_apply_zone_state(snap.get("z", {}))
	var boss_found := false
	for info in snap.get("enemies", []):
		if info.has("boss_id"):
			var bd := BossDB.get_data(String(info["boss_id"]))
			hud.set_boss(String(bd.get("name", "BOSS")), float(info.get("health", 0.0)), float(info.get("max_health", 1.0)))
			boss_found = true
	if not boss_found:
		hud.set_boss("", 0.0, 1.0)

func _refresh_tracker() -> void:
	if _z.is_empty():
		return
	var obj := String(_z.get("obj", ""))
	var q := String(zone.get("quest", ""))
	if q != "" and ChapterExtras.has(q):
		var step := int(_z.get("step", 0))
		var phase := "pre" if step == 0 else ("post" if step > int(zone.get("waves_n", 0)) else "")
		if phase != "":
			for p in ChapterExtras.progress(q, phase, _flags()):
				obj += "\n%s %s%s" % ["✓" if bool(p["done"]) else ("▶" if bool(p["required"]) else "·"), String(p["text"]), "" if int(p["total"]) <= 1 else " (%d/%d)" % [int(p["count"]), int(p["total"])]]
	hud.set_objective(String(_z.get("title", "")), obj, int(_z.get("wave_i", 0)), int(_z.get("waves", 0)), bool(_z.get("active", false)))

func _apply_support(list: Array) -> void:
	var seen := {}
	for info in list:
		var id := String(info["id"])
		seen[id] = true
		var n: Node2D = _sup.get(id)
		var target := Vector2(float(info["x"]), float(info["y"]))
		if n == null or not is_instance_valid(n):
			if String(info["k"]) == "ally":
				var a := Ally.new()
				a.ghost = true
				a.setup(null, int(info["slot"]))
				n = a
			else:
				var p := Pet.new()
				p.ghost = true
				p.s_gear = String(info.get("gear", ""))
				p.setup(null, String(info["pet"]))
				n = p
			entities.add_child(n)
			n.position = target
			_sup[id] = n
		_targets[n] = target
		n.hp = float(info["hp"])
		n.max_hp = float(info["mx"])
		n.visual.set_facing(float(info["f"]))
		n.visual.moving = bool(info["mv"])
		n.visual.grounded = true
		n.queue_redraw()
	for id in _sup.keys():
		if not seen.has(id):
			var old: Node2D = _sup[id]
			_targets.erase(old)
			if is_instance_valid(old):
				old.queue_free()
			_sup.erase(id)

func _apply_zone_state(z: Dictionary) -> void:
	if z.is_empty():
		return
	var changed := int(z.get("step", 0)) != int(_z.get("step", -1))
	_z = z
	_refresh_tracker()
	if changed:
		_refresh_objects()
	var marks: Dictionary = z.get("marks", {})
	for id in _npcs:
		var text := String(marks.get(id, ""))
		var m: Label = _npcs[id]["marker"]
		if m.text != text:
			m.text = text
		m.visible = text != ""

func _apply_enemies(list: Array) -> void:
	var seen := {}
	for info in list:
		var id := String(info.get("id", ""))
		if id == "":
			continue
		seen[id] = true
		var e: Enemy = _mobs.get(id)
		var target := Vector2(float(info.get("x", 0.0)), float(info.get("y", 0.0)))
		if e == null or not is_instance_valid(e):
			e = ENEMY_SCENE.instantiate() as Enemy
			e.net_id = id
			e.net_ghost = true
			e.setup(String(info.get("species", "wrzos")), false, false)
			entities.add_child(e)
			e.position = target
			if info.has("boss_id"):
				var bd := BossDB.get_data(String(info["boss_id"]))
				e.is_boss = true
				e.visual.configure(String(bd["species"]), bd["pal"], float(bd["scale"]))
			_mobs[id] = e
		var i2: Dictionary = info.duplicate()
		i2["x"] = e.global_position.x
		i2["y"] = e.global_position.y
		e.apply_net_state(i2)
		_targets[e] = target
	for id in _mobs.keys():
		if not seen.has(id):
			var old: Enemy = _mobs[id]
			_targets.erase(old)
			if is_instance_valid(old):
				old.queue_free()
			_mobs.erase(id)
