class_name Village
extends Node2D
## Strefa RPG w widoku z góry (top-down). Działa dla każdego rozdziału fabuły —
## teren, fale i NPC pochodzą z ZoneDB (na podstawie aktywnego rozdziału).
## Kamera podąża za graczem w obu osiach, przeszkody blokują ruch.

signal stage_cleared
signal player_died

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")

const VILLAGE := Vector2(2200.0, 1500.0)
const MARGIN := 80.0

@export var stage_index := 0

var player: Player = null
var hud: UiHud = null
var camera: Camera2D = null
var entities: Node2D = null
var waves: Array = []
var wave_i := 0
var wave_active := false
var finished := false
var rng := RandomNumberGenerator.new()
var npcs: Array = []
var _talk_target := ""
var _dialog_open := false
var _waves_started := false
var _reward_given := false

# konfiguracja bieżącej strefy / rozdziału
var quest_id := "obrona_wioski"
var zone: Dictionary = {}
var terrain := "village"
var giver := "starosta"
var spawn := Vector2(1100, 1080)
var villain: Dictionary = {}

func _ready() -> void:
	rng.seed = 424242
	quest_id = _active_quest_id()
	zone = ZoneDB.get_data(quest_id) if ZoneDB.has(quest_id) else ZoneDB.for_chapter(GameState.story_chapter())
	terrain = String(zone.get("terrain", "village"))
	giver = String(zone.get("giver", "starosta"))
	spawn = zone.get("spawn", Vector2(1100, 1080))
	villain = zone.get("villain", {})
	waves = zone.get("waves", [])

	_build_ground()
	entities = Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	add_child(entities)
	_build_walls()
	_build_scenery()
	_build_npcs()
	_setup_camera()
	_spawn_player()
	hud = UiHud.new()
	hud.stage = self
	add_child(hud)
	Fx.set_world(entities, camera)
	Fx.fade_to(0.0, 1.6)
	_begin_story()

## Identyfikator questa aktywnego rozdziału; jeśli brak, bierze pierwszy gotowy.
func _active_quest_id() -> String:
	var q := GameState.story_quest()
	if q != "" and ZoneDB.has(q):
		return q
	var c := QuestDB.chapter(GameState.story_chapter())
	var id := String(c.get("id", ""))
	if ZoneDB.has(id):
		return id
	return "obrona_wioski"

func _begin_story() -> void:
	await get_tree().create_timer(0.9).timeout
	if not is_instance_valid(self) or finished:
		return
	var banner: Array = zone.get("intro_banner", ["", ""])
	_banner(String(banner[0]), String(banner[1]))
	await get_tree().create_timer(1.7).timeout
	if not is_instance_valid(self) or finished:
		return
	var title := _hero_title()
	var lines := _with_title(zone.get("intro", []), title)
	_open_dialog(lines, UiKit.ACCENT2, func():
		var giver_name := String(NpcDB.get_data(giver).get("name", "sojusznik"))
		GameState.toast.emit("Zadanie: porozmawiaj z %s" % giver_name, UiKit.ACCENT))

func _with_title(lines: Array, title: String) -> Array:
	var out: Array = []
	for ln in lines:
		var pair: Array = ln.duplicate()
		if pair.size() >= 2:
			var txt := String(pair[1])
			if txt.contains("%s"):
				txt = txt % title
			pair[1] = txt
		out.append(pair)
	return out

func _hero_title() -> String:
	return NpcDB.hero_title(String(GameState.run.get("character", "kurczak")))

func _begin_defense() -> void:
	if _waves_started or finished:
		return
	_waves_started = true
	GameState.set_story_step(1)
	Audio.play("gate", 1.0, -6.0)
	_spawn_wave()

# ------------------------------------------------------------------ świat ---

func _ground_palette() -> Dictionary:
	match terrain:
		"road":
			return {"base": Color(0.42, 0.5, 0.3), "path": Color(0.58, 0.5, 0.34), "decor": Color(0.22, 0.34, 0.2, 0.35)}
		"city":
			return {"base": Color(0.34, 0.32, 0.3), "path": Color(0.46, 0.44, 0.42), "decor": Color(0.28, 0.24, 0.22, 0.35)}
		"tower":
			return {"base": Color(0.3, 0.3, 0.36), "path": Color(0.42, 0.42, 0.5), "decor": Color(0.2, 0.2, 0.28, 0.4)}
		"forest":
			return {"base": Color(0.2, 0.34, 0.22), "path": Color(0.4, 0.34, 0.22), "decor": Color(0.15, 0.28, 0.16, 0.4)}
		"fortress":
			return {"base": Color(0.2, 0.19, 0.22), "path": Color(0.32, 0.29, 0.3), "decor": Color(0.14, 0.12, 0.16, 0.45)}
		_:
			return {"base": Color(0.32, 0.46, 0.27), "path": Color(0.52, 0.42, 0.28), "decor": Color(0.24, 0.36, 0.2, 0.35)}

func _build_ground() -> void:
	var pal := _ground_palette()
	var grass := Polygon2D.new()
	grass.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(VILLAGE.x, 0),
		Vector2(VILLAGE.x, VILLAGE.y), Vector2(0, VILLAGE.y),
	])
	grass.color = pal["base"]
	add_child(grass)
	var dirt: Color = pal["path"]
	if terrain == "road":
		var path := Polygon2D.new()
		path.polygon = PackedVector2Array([
			Vector2(0, VILLAGE.y * 0.42), Vector2(VILLAGE.x, VILLAGE.y * 0.42),
			Vector2(VILLAGE.x, VILLAGE.y * 0.62), Vector2(0, VILLAGE.y * 0.62),
		])
		path.color = dirt
		add_child(path)
	else:
		var path_h := Polygon2D.new()
		path_h.polygon = PackedVector2Array([
			Vector2(0, VILLAGE.y * 0.52), Vector2(VILLAGE.x, VILLAGE.y * 0.52),
			Vector2(VILLAGE.x, VILLAGE.y * 0.62), Vector2(0, VILLAGE.y * 0.62),
		])
		path_h.color = dirt
		add_child(path_h)
		var path_v := Polygon2D.new()
		path_v.polygon = PackedVector2Array([
			Vector2(VILLAGE.x * 0.47, 0), Vector2(VILLAGE.x * 0.55, 0),
			Vector2(VILLAGE.x * 0.55, VILLAGE.y), Vector2(VILLAGE.x * 0.47, VILLAGE.y),
		])
		path_v.color = dirt
		add_child(path_v)
	for i in 90:
		var s := Sprite2D.new()
		s.texture = Art.soft_blob(int(rng.randf_range(40, 120)), pal["decor"], 0.5, i)
		s.position = Vector2(rng.randf_range(0, VILLAGE.x), rng.randf_range(0, VILLAGE.y))
		s.scale = Vector2(rng.randf_range(0.6, 1.6), rng.randf_range(0.5, 1.2))
		add_child(s)

func _build_walls() -> void:
	var walls := StaticBody2D.new()
	walls.collision_layer = 1
	walls.collision_mask = 0
	add_child(walls)
	var t := 200.0
	var specs := [
		[Vector2(VILLAGE.x * 0.5, -t * 0.5), Vector2(VILLAGE.x + t * 2.0, t)],
		[Vector2(VILLAGE.x * 0.5, VILLAGE.y + t * 0.5), Vector2(VILLAGE.x + t * 2.0, t)],
		[Vector2(-t * 0.5, VILLAGE.y * 0.5), Vector2(t, VILLAGE.y + t * 2.0)],
		[Vector2(VILLAGE.x + t * 0.5, VILLAGE.y * 0.5), Vector2(t, VILLAGE.y + t * 2.0)],
	]
	for spec in specs:
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = spec[1]
		cs.shape = sh
		cs.position = spec[0]
		walls.add_child(cs)

func _house(pos: Vector2, w: float, h: float, body_col: Color, roof_col: Color) -> Node2D:
	var n := Node2D.new()
	n.position = pos
	entities.add_child(n)
	var ob := StaticBody2D.new()
	ob.collision_layer = 1
	ob.collision_mask = 0
	n.add_child(ob)
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(w, h)
	cs.shape = sh
	cs.position = Vector2(0, -h * 0.5)
	ob.add_child(cs)
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-w * 0.5, 0), Vector2(w * 0.5, 0),
		Vector2(w * 0.5, -h), Vector2(-w * 0.5, -h),
	])
	body.color = body_col
	n.add_child(body)
	var roof := Polygon2D.new()
	roof.polygon = PackedVector2Array([
		Vector2(-w * 0.6, -h), Vector2(w * 0.6, -h),
		Vector2(w * 0.45, -h - 70.0), Vector2(-w * 0.45, -h - 70.0),
	])
	roof.color = roof_col
	n.add_child(roof)
	var door := Polygon2D.new()
	door.polygon = PackedVector2Array([
		Vector2(-26, 0), Vector2(26, 0), Vector2(26, -64), Vector2(-26, -64),
	])
	door.color = Color(0.2, 0.14, 0.1)
	n.add_child(door)
	return n

## Rozmieszczenie dekoracji zależne od typu terenu.
func _build_scenery() -> void:
	match terrain:
		"road":
			for i in 26:
				_tree(Vector2(rng.randf_range(120, VILLAGE.x - 120), rng.randf_range(120, 420)), rng.randf_range(0.8, 1.3), i)
				_tree(Vector2(rng.randf_range(120, VILLAGE.x - 120), rng.randf_range(1080, VILLAGE.y - 120)), rng.randf_range(0.8, 1.3), i + 40)
		"forest":
			for i in 40:
				_tree(Vector2(rng.randf_range(120, VILLAGE.x - 120), rng.randf_range(120, VILLAGE.y - 120)), rng.randf_range(0.9, 1.5), i)
		"city":
			_house(Vector2(430, 620), 220, 140, Color(0.6, 0.56, 0.5), Color(0.45, 0.3, 0.25))
			_house(Vector2(1760, 620), 220, 140, Color(0.58, 0.54, 0.5), Color(0.4, 0.34, 0.3))
			_house(Vector2(430, 1220), 220, 140, Color(0.62, 0.58, 0.52), Color(0.5, 0.34, 0.28))
			_house(Vector2(1760, 1220), 220, 140, Color(0.58, 0.55, 0.5), Color(0.44, 0.3, 0.26))
			for i in 8:
				_fence(Vector2(240 + i * 70.0, 380.0))
		"tower", "fortress":
			for i in 10:
				var x := 240.0 + i * 180.0
				_pillar(Vector2(x, 360.0))
				_pillar(Vector2(x, VILLAGE.y - 200.0))
		_:
			_house(Vector2(430, 620), 240, 150, Color(0.72, 0.62, 0.46), Color(0.55, 0.28, 0.2))
			_house(Vector2(1720, 600), 240, 150, Color(0.68, 0.6, 0.44), Color(0.32, 0.36, 0.5))
			_house(Vector2(430, 1250), 220, 140, Color(0.7, 0.6, 0.45), Color(0.5, 0.3, 0.24))
			_house(Vector2(1760, 1240), 220, 140, Color(0.66, 0.58, 0.42), Color(0.4, 0.3, 0.24))
			_well(Vector2(VILLAGE.x * 0.5, VILLAGE.y * 0.57))
			var tree_spots := [
				Vector2(150, 300), Vector2(2050, 320), Vector2(160, 1100), Vector2(2040, 1120),
				Vector2(820, 240), Vector2(1360, 260), Vector2(700, 1420), Vector2(1500, 1430),
			]
			for i in tree_spots.size():
				_tree(tree_spots[i], rng.randf_range(0.9, 1.4), i)
			for i in 8:
				_fence(Vector2(240 + i * 70.0, 320.0))
				_fence(Vector2(240 + i * 70.0, 1420.0))

func _well(pos: Vector2) -> void:
	var well := Node2D.new()
	well.position = pos
	entities.add_child(well)
	var wb := StaticBody2D.new()
	wb.collision_layer = 1
	well.add_child(wb)
	var wcs := CollisionShape2D.new()
	var wsh := CircleShape2D.new()
	wsh.radius = 38.0
	wcs.shape = wsh
	wb.add_child(wcs)
	var ring := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * float(i) / 20.0
		pts.append(Vector2(cos(a), sin(a) * 0.6) * 40.0)
	ring.polygon = pts
	ring.color = Color(0.5, 0.5, 0.52)
	well.add_child(ring)
	var water := Polygon2D.new()
	var wp := PackedVector2Array()
	for i in 20:
		var a2 := TAU * float(i) / 20.0
		wp.append(Vector2(cos(a2), sin(a2) * 0.6) * 28.0)
	water.polygon = wp
	water.color = Color(0.2, 0.35, 0.45)
	water.position = Vector2(0, -4)
	well.add_child(water)

func _pillar(pos: Vector2) -> void:
	var n := Node2D.new()
	n.position = pos
	entities.add_child(n)
	var ob := StaticBody2D.new()
	ob.collision_layer = 1
	ob.collision_mask = 0
	n.add_child(ob)
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 22.0
	cs.shape = sh
	cs.position = Vector2(0, -30)
	ob.add_child(cs)
	var col := Polygon2D.new()
	col.polygon = PackedVector2Array([
		Vector2(-20, 0), Vector2(20, 0), Vector2(16, -110), Vector2(-16, -110),
	])
	col.color = Color(0.5, 0.48, 0.52)
	n.add_child(col)
	var cap := Polygon2D.new()
	cap.polygon = PackedVector2Array([
		Vector2(-26, -110), Vector2(26, -110), Vector2(22, -128), Vector2(-22, -128),
	])
	cap.color = Color(0.42, 0.4, 0.46)
	n.add_child(cap)

func _tree(pos: Vector2, s: float, seed_i: int) -> void:
	var n := Node2D.new()
	n.position = pos
	n.scale = Vector2(s, s)
	entities.add_child(n)
	var ob := StaticBody2D.new()
	ob.collision_layer = 1
	n.add_child(ob)
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 16.0
	cs.shape = sh
	cs.position = Vector2(0, -18)
	ob.add_child(cs)
	var trunk := Polygon2D.new()
	trunk.polygon = PackedVector2Array([
		Vector2(-7, 0), Vector2(7, 0), Vector2(5, -70), Vector2(-5, -70),
	])
	trunk.color = Color(0.35, 0.24, 0.15)
	n.add_child(trunk)
	for i in 3:
		var b := Sprite2D.new()
		b.texture = Art.soft_blob(150, Color(0.22, 0.38, 0.2), 0.4, seed_i * 3 + i)
		b.position = Vector2(rng.randf_range(-26, 26), -90 - rng.randf_range(0, 30))
		b.scale = Vector2(rng.randf_range(0.6, 1.0), rng.randf_range(0.5, 0.9))
		n.add_child(b)

func _fence(pos: Vector2) -> void:
	var n := Node2D.new()
	n.position = pos
	entities.add_child(n)
	var col := Color(0.5, 0.36, 0.22)
	var l1 := Line2D.new()
	l1.points = PackedVector2Array([Vector2(0, 0), Vector2(0, -46)])
	l1.width = 7.0
	l1.default_color = col
	n.add_child(l1)
	for i in 2:
		var r := Line2D.new()
		r.points = PackedVector2Array([Vector2(-30, -22 - i * 16.0), Vector2(30, -22 - i * 16.0)])
		r.width = 5.0
		r.default_color = col.lightened(0.08)
		n.add_child(r)

# ------------------------------------------------------------------- NPC ----

func _build_npcs() -> void:
	var ids: Array = zone.get("npcs", NpcDB.LIST.keys())
	for id in ids:
		_npc(String(id))

func _npc(id: String) -> void:
	var data := NpcDB.get_data(id)
	var n := Node2D.new()
	n.name = "Npc_" + id
	n.position = data.get("pos", Vector2.ZERO)
	entities.add_child(n)
	var cv := CreatureVisual.new()
	cv.configure(String(data.get("species", "kurczak")), NpcDB.pal_for(id), float(data.get("scale", 1.4)))
	cv.set_facing(-1.0)
	n.add_child(cv)
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 18.0
	cs.shape = sh
	cs.position = Vector2(0, -12)
	body.add_child(cs)
	n.add_child(body)
	var settings := LabelSettings.new()
	settings.font_size = 14
	settings.font_color = Color(0.95, 0.96, 1.0)
	settings.outline_size = 5
	settings.outline_color = Color(0, 0, 0, 0.85)
	var name_l := Label.new()
	name_l.text = String(data.get("name", "?"))
	name_l.label_settings = settings
	name_l.position = Vector2(-70, -96)
	name_l.custom_minimum_size = Vector2(140, 0)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.add_child(name_l)
	var prompt := Label.new()
	prompt.text = "[E] porozmawiaj"
	prompt.label_settings = settings
	prompt.position = Vector2(-70, -78)
	prompt.custom_minimum_size = Vector2(140, 0)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.modulate = data.get("accent", UiKit.ACCENT)
	prompt.visible = false
	n.add_child(prompt)
	npcs.append({"id": id, "node": n, "prompt": prompt, "accent": data.get("accent", UiKit.ACCENT)})

func _nearest_npc() -> Dictionary:
	if player == null or not is_instance_valid(player):
		return {}
	var best := {}
	var best_d := 96.0
	for entry in npcs:
		var node: Node2D = entry["node"]
		if not is_instance_valid(node):
			continue
		var d := node.global_position.distance_to(player.global_position)
		if d < best_d:
			best_d = d
			best = entry
	return best

func try_interact() -> bool:
	if _dialog_open or finished:
		return false
	var target := _nearest_npc()
	if target.is_empty():
		return false
	_talk_to(String(target["id"]))
	return true

func _talk_to(id: String) -> void:
	var step := GameState.story_step()
	var flags: Dictionary = GameState.story().get("flags", {})
	var char_id := String(GameState.run.get("character", "kurczak"))
	var accent: Color = NpcDB.get_data(id).get("accent", UiKit.ACCENT)
	if id == giver:
		var waves_n := waves.size()
		if step > waves_n and not GameState.story_done(quest_id):
			_open_dialog(NpcDB.lines_for(id, step, flags, char_id, quest_id), accent, _finish_story)
		elif not _waves_started and step == 0:
			_open_dialog(NpcDB.lines_for(id, step, flags, char_id, quest_id), accent, _begin_defense)
		else:
			_open_dialog(NpcDB.lines_for(id, step, flags, char_id, quest_id), accent)
	elif id == "kupiec":
		_open_dialog(NpcDB.lines_for("kupiec", step, flags, char_id, quest_id), accent, _open_shop)
	elif id == "kowal":
		_open_dialog(NpcDB.lines_for("kowal", step, flags, char_id, quest_id), accent, func():
			if not GameState.story_flag("kowal_gift"):
				GameState.set_story_flag("kowal_gift")
				GameState.add_item("mikstura_miodu", 1)
				GameState.save_game()
				GameState.toast.emit("Otrzymano: Mikstura miodu", UiKit.GOOD))
	else:
		_open_dialog(NpcDB.lines_for(id, step, flags, char_id, quest_id), accent)

func _open_shop() -> void:
	await get_tree().process_frame
	Flow.open_shop_overlay()

func _open_dialog(lines: Array, accent: Color, after: Callable = Callable()) -> void:
	if _dialog_open:
		return
	if lines.is_empty():
		if after.is_valid():
			after.call()
		return
	_dialog_open = true
	var d := UiDialog.new()
	d.setup(lines, accent)
	d.on_close.connect(func():
		_dialog_open = false
		if after.is_valid():
			after.call())
	Flow.open_dialog(d)

func _on_dialog_update() -> void:
	for entry in npcs:
		var prompt: Label = entry["prompt"]
		if is_instance_valid(prompt):
			prompt.visible = false
	if _dialog_open or finished:
		return
	var t := _nearest_npc()
	if not t.is_empty():
		var prompt2: Label = t["prompt"]
		if is_instance_valid(prompt2):
			prompt2.visible = true


# ------------------------------------------------------------------ gracz ---

func _spawn_player() -> void:
	player = (PLAYER_SCENE as PackedScene).instantiate() as Player
	player.position = spawn
	entities.add_child(player)
	player.died.connect(_on_player_died)
	player.bounds_min = MARGIN
	player.bounds_max = VILLAGE.x - MARGIN
	player.bounds_top = MARGIN
	player.bounds_bottom = VILLAGE.y - MARGIN
	player.floor_y = VILLAGE.y - MARGIN
	GameState.run_set("time", float(GameState.run.get("time", 0.0)))

func _on_player_died() -> void:
	if finished:
		return
	await get_tree().create_timer(1.9).timeout
	if not finished:
		finished = true
		player_died.emit()

# ---------------------------------------------------------------- kamera ----

func _setup_camera() -> void:
	camera = Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(VILLAGE.x)
	camera.limit_bottom = int(VILLAGE.y)
	camera.position = spawn
	add_child(camera)

func _process(delta: float) -> void:
	if player and is_instance_valid(player):
		GameState.run_add("time", delta)
		camera.position = player.position
		_on_dialog_update()
		if wave_active and _alive_enemies().is_empty():
			wave_active = false
			_on_wave_cleared()

# ------------------------------------------------------------------ fale ---

func _alive_enemies() -> Array:
	var out := []
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		if e.has_method("is_dead") and e.is_dead():
			continue
		out.append(e)
	return out

func _spawn_wave() -> void:
	if wave_i >= waves.size() or finished:
		return
	var wave: Dictionary = waves[wave_i]
	_banner("FALA %d / %d" % [wave_i + 1, waves.size()], String(wave.get("name", "")))
	wave_active = true
	wave_i += 1
	GameState.set_story_step(wave_i)
	for entry in wave["enemies"]:
		var id := String(entry[0])
		for i in int(entry[1]):
			var e: Enemy = (ENEMY_SCENE as PackedScene).instantiate() as Enemy
			e.setup(id, false, false)
			e.aggro = 2600.0
			entities.add_child(e)
			e.global_position = _edge_spawn()
			e.set_bounds_rect(MARGIN, VILLAGE.x - MARGIN, MARGIN, VILLAGE.y - MARGIN)

func _edge_spawn() -> Vector2:
	var side := rng.randi() % 4
	var p := Vector2.ZERO
	match side:
		0: p = Vector2(rng.randf_range(MARGIN, VILLAGE.x - MARGIN), MARGIN + 20.0)
		1: p = Vector2(rng.randf_range(MARGIN, VILLAGE.x - MARGIN), VILLAGE.y - MARGIN - 20.0)
		2: p = Vector2(MARGIN + 20.0, rng.randf_range(MARGIN, VILLAGE.y - MARGIN))
		_: p = Vector2(VILLAGE.x - MARGIN - 20.0, rng.randf_range(MARGIN, VILLAGE.y - MARGIN))
	if player and p.distance_to(player.global_position) < 380.0:
		p = Vector2(VILLAGE.x - p.x, VILLAGE.y - p.y)
	return p

func _on_wave_cleared() -> void:
	Audio.play("gate", 1.0, -6.0)
	if wave_i >= waves.size():
		_post_battle()
		return
	if not villain.is_empty() and int(villain.get("after_wave", -1)) == wave_i:
		_villain_cutscene()
		return
	GameState.set_story_step(wave_i + 1)
	_banner("FALA OCZYSZCZONA", "Nadchodzą kolejne…")
	await get_tree().create_timer(1.4).timeout
	if not finished:
		_spawn_wave()

func _villain_cutscene() -> void:
	_banner("HOLD", "Niebo ciemnieje…")
	var title := _hero_title()
	var who := String(villain.get("who", "Wróg"))
	var raw: Array = villain.get("lines", [])
	var lines: Array = []
	for ln in raw:
		var txt := String(ln)
		if txt.contains("%s"):
			txt = txt % title
		lines.append([who, txt])
	lines.append([who, "Ostatnia fala! Zmiażdżcie ich!"])
	_open_dialog(lines, Color(0.85, 0.35, 0.3), func():
		if not finished:
			_spawn_wave())

func _post_battle() -> void:
	GameState.set_story_step(waves.size() + 1)
	Audio.stop_music()
	var ob: Array = zone.get("outro_banner", ["ŚWIT", "Udało się"])
	_banner(String(ob[0]), String(ob[1]))
	Fx.flash(Color(1, 1, 0.9), 0.4, 0.5)
	await get_tree().create_timer(1.6).timeout
	if is_instance_valid(self) and not finished:
		var giver_name := String(NpcDB.get_data(giver).get("name", "sojusznik"))
		GameState.toast.emit("Zadanie: porozmawiaj z %s" % giver_name, UiKit.ACCENT)

func _finish_story() -> void:
	if _reward_given or finished:
		return
	_reward_given = true
	var quest := QuestDB.get_data(quest_id)
	var reward: Dictionary = quest.get("reward", {})
	GameState.add_gold(int(reward.get("gold", 0)))
	GameState.add_xp(int(reward.get("xp", 0)))
	var items: Dictionary = reward.get("items", {})
	for it in items:
		GameState.add_item(String(it), int(items[it]))
	GameState.set_story_flag(quest_id + "_done")
	GameState.complete_quest(quest_id)
	var next_chapter := GameState.story_chapter() + 1
	GameState.set_story(next_chapter, "", 0)
	GameState.save_game()
	var label := String(quest.get("label", "Rozdział"))
	GameState.toast.emit("%s ukończony! +%d złota, +%d XP" % [label, int(reward.get("gold", 0)), int(reward.get("xp", 0))], UiKit.GOOD)
	var ob: Array = zone.get("outro_banner", ["ROZDZIAŁ UKOŃCZONY", ""])
	_banner(String(ob[0]), String(ob[1]))
	Fx.flash(Color(1, 0.95, 0.8), 0.5, 0.6)
	Audio.play("levelup", 1.0, -2.0)
	await get_tree().create_timer(2.2).timeout
	if is_instance_valid(self):
		finished = true
		if player and is_instance_valid(player):
			player.victory()
		stage_cleared.emit()

# ---------------------------------------------------------------- pomocne ---

func enemies_left() -> int:
	return _alive_enemies().size()

func waves_left() -> int:
	return maxi(0, waves.size() - wave_i)

func _banner(title: String, sub: String) -> void:
	var v := UiBanner.new()
	v.setup(title, sub)
	add_child(v)
