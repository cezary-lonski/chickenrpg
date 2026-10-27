class_name Stage
extends Node2D
## Scena etapu: niebo, paralaksa, teren, półki, kamera, reżyser fal i brama.
## Walka toczy się ekran po ekranie — kamera nie cofa się, a kamera pilnuje,
## żeby gracz nie wyszedł poza ekran.

signal stage_cleared
signal player_died
signal boss_registered(boss: Node)

const VIEW := Vector2(1280, 720)
const STEP_WIDTH := 640.0

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const BOSS_SCENE := preload("res://scenes/boss.tscn")

@export var stage_index := 0

var data: Dictionary = {}
var ground_y := 560.0
var stage_length := 3600.0
var cam_x := 0.0
var player: Player = null
var hud: UiHud = null
var waves: Array = []
var wave_i := 0
var wave_active := false
var wave_cleared := false
var stage_done := false
var finished := false
var boss: Node = null
var rng := RandomNumberGenerator.new()
var entities: Node2D
var banners: Array = []
var spawn_marker_x := 0.0
var intro_t := 0.0
var clear_t := -1.0
var _shake_done := false

@onready var camera: Camera2D = $Camera
@onready var sky_rect: TextureRect = $Sky/Rect
@onready var sun: Sprite2D = $Sky/Sun
@onready var p_far: ParallaxLayer = $Parallax/Far
@onready var p_mid: ParallaxLayer = $Parallax/Mid
@onready var p_near: ParallaxLayer = $Parallax/Near
@onready var ground: StaticBody2D = $World/Ground
@onready var ground_vis: GroundVisual = $World/GroundVis
@onready var platforms: Node2D = $World/Platforms
@onready var gates: Node2D = $World/Gates
@onready var ambient: Node2D = $World/Ambient
@onready var entities_node: Node2D = $World/Entities

func _ready() -> void:
	rng.seed = hash(String(StageDB.get_stage(stage_index)["id"])) + 7
	data = StageDB.get_stage(stage_index)
	ground_y = float(data["ground_y"])
	stage_length = float(data["length"])
	waves = data["waves"]
	entities = entities_node
	_setup_sky()
	_setup_parallax()
	_setup_ground()
	_setup_platforms()
	_setup_gates()
	_setup_ambient()
	camera.enabled = true
	camera.position = Vector2(VIEW.x * 0.5, VIEW.y * 0.5)
	cam_x = VIEW.x * 0.5
	Fx.set_world(entities, camera)
	_spawn_player()
	hud = UiHud.new()
	hud.stage = self
	add_child(hud)
	Fx.fade_to(0.0, 1.6)
	_banner("ETAP %d" % (stage_index + 1), String(data["name"]))
	_boot_waves()

func _boot_waves() -> void:
	await get_tree().create_timer(1.35).timeout
	if is_instance_valid(self) and not finished and is_instance_valid(player):
		_spawn_wave()

# ------------------------------------------------------------------- niebo ---

func _setup_sky() -> void:
	sky_rect.texture = Art.gradient(data["sky"], true, 16, 256)
	sun.texture = Art.radial_glow(120, data.get("sun", Color(1, 0.95, 0.7)))
	sun.position = Vector2(VIEW.x * 0.76, VIEW.y * 0.22)
	sun.modulate = Color(1, 1, 1, 0.85)
	$Vignette/Rect.texture = Art.vignette(Vector2i(160, 90), 0.5)

func _setup_parallax() -> void:
	for l in [p_far, p_mid, p_near]:
		l.motion_mirroring = Vector2(VIEW.x, 0)
		for c in l.get_children():
			c.queue_free()
	p_far.motion_scale = Vector2(0.12, 0.05)
	p_mid.motion_scale = Vector2(0.3, 0.1)
	p_near.motion_scale = Vector2(0.6, 0.2)
	var props: Dictionary = data.get("props", {})
	var far_col: Color = Color(data["sky"][0]).darkened(0.25)
	var mid_col: Color = Color(data["ground"][0]).darkened(0.12)
	# dalekie wzgórza
	for i in 7:
		var w := rng.randf_range(420, 780)
		var h := rng.randf_range(70, 170)
		var x := float(i) * 420.0 - 200.0
		p_far.add_child(_hill(x, VIEW.y * 0.62, w, h, far_col))
	# chmury
	for i in 6:
		var c := _blob(Vector2(rng.randf_range(0, VIEW.x * 2.0), rng.randf_range(60, 240)), rng.randf_range(60, 140), Color(1, 1, 1, 0.16), 1)
		p_far.add_child(c)
	# drzewa i budynki
	var tree_n := int(props.get("trees", 0))
	for i in tree_n:
		p_mid.add_child(_tree(Vector2(rng.randf_range(-200, VIEW.x * 2.2), ground_y + 10.0), rng.randf_range(0.7, 1.5), mid_col))
	if bool(props.get("barn", false)):
		p_mid.add_child(_barn(Vector2(VIEW.x * 0.62, ground_y + 8.0), 1.5, mid_col))
	# płot
	if bool(props.get("fence", false)):
		for i in 6:
			p_near.add_child(_fence(Vector2(float(i) * 420.0 - 100.0, ground_y + 12.0), Color(0.5, 0.36, 0.22)))
	# kępy i krzaczki
	for i in 10:
		p_near.add_child(_bush(Vector2(rng.randf_range(-100, VIEW.x * 2.0), ground_y + 6.0), rng.randf_range(24, 60)))

func _hill(x: float, base_y: float, w: float, h: float, col: Color) -> Node2D:
	var n := Node2D.new()
	n.position = Vector2(x, base_y)
	var poly := Polygon2D.new()
	var pts := PackedVector2Array()
	pts.append(Vector2(-w * 0.5, 260))
	for i in 14:
		var k := float(i) / 13.0
		pts.append(Vector2(-w * 0.5 + w * k, -h * sin(k * PI) - h * 0.15))
	pts.append(Vector2(w * 0.5, 260))
	poly.polygon = pts
	poly.color = col
	n.add_child(poly)
	return n

func _blob(pos: Vector2, r: float, col: Color, sd: int) -> Node2D:
	var n := Node2D.new()
	n.position = pos
	var s := Sprite2D.new()
	s.texture = Art.soft_blob(int(r * 2), col, 0.35, sd)
	s.scale = Vector2(1, 0.6)
	n.add_child(s)
	return n

func _tree(pos: Vector2, s: float, col: Color) -> Node2D:
	var n := Node2D.new()
	n.position = pos
	n.scale = Vector2(s, s)
	var trunk := Line2D.new()
	trunk.points = PackedVector2Array([Vector2(0, 0), Vector2(-4, -60), Vector2(2, -110)])
	trunk.width = 9.0
	trunk.default_color = col.darkened(0.3)
	n.add_child(trunk)
	for i in 3:
		var b := Sprite2D.new()
		b.texture = Art.soft_blob(120, col, 0.4, 3 + i)
		b.position = Vector2(rng.randf_range(-34, 34), -120 - rng.randf_range(0, 40))
		b.scale = Vector2(rng.randf_range(0.5, 0.9), rng.randf_range(0.45, 0.8))
		n.add_child(b)
	return n

func _bush(pos: Vector2, r: float) -> Node2D:
	var n := Node2D.new()
	n.position = pos
	var col := Color(data["ground"][0]).lightened(0.1)
	for i in 3:
		var b := Sprite2D.new()
		b.texture = Art.soft_blob(int(r * 2.0), col, 0.45, 5 + i)
		b.position = Vector2(rng.randf_range(-r * 0.5, r * 0.5), -r * 0.35)
		b.scale = Vector2(rng.randf_range(0.4, 0.7), rng.randf_range(0.35, 0.6))
		n.add_child(b)
	return n

func _fence(pos: Vector2, col: Color) -> Node2D:
	var n := Node2D.new()
	n.position = pos
	var l := Line2D.new()
	l.points = PackedVector2Array([Vector2(0, -70), Vector2(0, 8)])
	l.width = 8.0
	l.default_color = col
	n.add_child(l)
	for i in 2:
		var r := Line2D.new()
		r.points = PackedVector2Array([Vector2(-10, -58 + i * 30.0), Vector2(230, -58 + i * 30.0)])
		r.width = 5.0
		r.default_color = col.lightened(0.08)
		n.add_child(r)
	return n

func _barn(pos: Vector2, s: float, col: Color) -> Node2D:
	var n := Node2D.new()
	n.position = pos
	n.scale = Vector2(s, s)
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([Vector2(-140, 0), Vector2(140, 0), Vector2(140, -180), Vector2(-140, -180)])
	body.color = col.darkened(0.15)
	n.add_child(body)
	var roof := Polygon2D.new()
	roof.polygon = PackedVector2Array([Vector2(-165, -180), Vector2(0, -300), Vector2(165, -180)])
	roof.color = col.darkened(0.35)
	n.add_child(roof)
	var door := Polygon2D.new()
	door.polygon = PackedVector2Array([Vector2(-45, 0), Vector2(45, 0), Vector2(45, -110), Vector2(0, -140), Vector2(-45, -110)])
	door.color = Color(0.15, 0.12, 0.1)
	n.add_child(door)
	return n

# ------------------------------------------------------------------ teren ---

func _setup_ground() -> void:
	ground_vis.configure(stage_length, ground_y, data["ground"][0], data["ground"][1], data.get("accent", Color(0.5, 0.36, 0.2)), rng.randi(), String(data.get("props", {}).get("style", "field")))
	var shape := RectangleShape2D.new()
	shape.size = Vector2(stage_length + 600.0, 300.0)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = Vector2(stage_length * 0.5, ground_y + 150.0)
	ground.add_child(cs)

func _setup_platforms() -> void:
	for c in platforms.get_children():
		c.queue_free()
	for p in data.get("platforms", []):
		var w := float(p[2])
		var x := float(p[0])
		var y := float(p[1])
		var body := StaticBody2D.new()
		body.collision_layer = 64
		body.collision_mask = 0
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(w, 22.0)
		cs.shape = sh
		cs.one_way_collision = true
		cs.one_way_collision_margin = 6.0
		body.add_child(cs)
		body.position = Vector2(x + w * 0.5, y)
		platforms.add_child(body)
		var vis := Line2D.new()
		vis.points = PackedVector2Array([Vector2(x, y + 11.0), Vector2(x + w, y + 11.0)])
		vis.width = 14.0
		vis.default_color = Color(data.get("accent", Color(0.5, 0.36, 0.2)))
		platforms.add_child(vis)
		var under := Line2D.new()
		under.points = PackedVector2Array([Vector2(x + 6, y + 20.0), Vector2(x + w - 6, y + 20.0)])
		under.width = 5.0
		under.default_color = Color(0, 0, 0, 0.2)
		platforms.add_child(under)

func _setup_gates() -> void:
	for c in gates.get_children():
		c.queue_free()
	_gate = _build_gate()
	gates.add_child(_gate)
	_gate.visible = false

var _gate: Node2D = null

func _build_gate() -> Node2D:
	var n := Node2D.new()
	var wood := Color(0.48, 0.33, 0.2)
	for sgn in [-1.0, 1.0]:
		var post := Polygon2D.new()
		post.polygon = PackedVector2Array([Vector2(-9, 0), Vector2(9, 0), Vector2(9, -150), Vector2(-9, -150)])
		post.color = wood
		post.position = Vector2(sgn * 46.0, 0)
		n.add_child(post)
	for i in 3:
		var bar := Polygon2D.new()
		bar.polygon = PackedVector2Array([Vector2(-46, 0), Vector2(46, 0), Vector2(46, -14), Vector2(-46, -14)])
		bar.color = Color(0.62, 0.24, 0.2) if i % 2 == 0 else Color(0.9, 0.88, 0.82)
		bar.position = Vector2(0, -30.0 - i * 38.0)
		n.add_child(bar)
	var glow := Sprite2D.new()
	glow.texture = Art.radial_glow(90, Color(1.0, 0.5, 0.35))
	glow.position = Vector2(0, -70)
	glow.modulate = Color(1, 1, 1, 0.35)
	n.add_child(glow)
	return n

func _update_gate(closed: bool) -> void:
	if _gate and is_instance_valid(_gate):
		_gate.position = Vector2(cam_x + VIEW.x * 0.5 + 34.0, ground_y)
		_gate.visible = closed

func _setup_ambient() -> void:
	for c in ambient.get_children():
		c.queue_free()
	var props: Dictionary = data.get("props", {})
	if float(props.get("fog", 0.0)) > 0.0:
		var f := float(props["fog"])
		for i in 7:
			var b := Sprite2D.new()
			b.texture = Art.soft_blob(300, Color(1, 1, 1, 0.06 + f * 0.1), 0.4, 20 + i)
			b.position = Vector2(rng.randf_range(-200, stage_length + 200), ground_y - rng.randf_range(-20, 90))
			b.scale = Vector2(rng.randf_range(1.4, 2.6), 0.5)
			b.modulate = Color(0.9, 0.95, 1.0, 1.0)
			ambient.add_child(b)
	if bool(props.get("hay", 0)) or bool(props.get("embers", false)):
		var n := int(props.get("hay", 0))
		for i in n:
			ambient.add_child(_hay(Vector2(rng.randf_range(100, stage_length - 100), ground_y)))
	if bool(props.get("embers", false)):
		ambient.add_child(_ambient_particles(true))
	elif bool(props.get("mushrooms", false)):
		ambient.add_child(_ambient_particles(false))
	if bool(props.get("apples", false)):
		for i in 6:
			var a := Node2D.new()
			a.position = Vector2(rng.randf_range(200, stage_length - 200), ground_y - rng.randf_range(0, 10))
			var s := Sprite2D.new()
			s.texture = Art.hud_icon("cod", 14, Color(0.9, 0.25, 0.25))
			s.position = Vector2(rng.randf_range(-30, 30), -20)
			a.add_child(s)
			ambient.add_child(a)

func _hay(pos: Vector2) -> Node2D:
	var n := Node2D.new()
	n.position = pos
	var col := Color(0.85, 0.7, 0.32)
	for i in 3:
		var w := 78.0 - i * 14.0
		var r := Polygon2D.new()
		r.polygon = PackedVector2Array([Vector2(-w * 0.5, 0), Vector2(w * 0.5, 0), Vector2(w * 0.42, -26.0), Vector2(-w * 0.42, -26.0)])
		r.color = col.darkened(0.12 * i)
		r.position = Vector2(0, -26.0 * i)
		n.add_child(r)
	return n

func _ambient_particles(embers: bool) -> Node2D:
	var n := Node2D.new()
	if Fx.particle_mul <= 0.0:
		return n
	var p := CPUParticles2D.new()
	p.amount = 40
	p.lifetime = 6.0
	p.preprocess = 4.0
	p.position = Vector2(stage_length * 0.5, ground_y - 20.0)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(stage_length * 0.5, 260.0)
	p.gravity = Vector2(10, -26) if embers else Vector2(-14, 8)
	p.initial_velocity_min = 6.0
	p.initial_velocity_max = 24.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.6
	p.color = Color(1.0, 0.6, 0.25, 0.75) if embers else Color(0.7, 0.95, 0.7, 0.35)
	p.texture = Art.soft_blob(12, Color(1, 1, 1, 1.0), 0.1, 1)
	n.add_child(p)
	return n

# ----------------------------------------------------------------- gracz ----

func _spawn_player() -> void:
	player = (PLAYER_SCENE as PackedScene).instantiate() as Player
	player.position = Vector2(160.0, ground_y)
	entities.add_child(player)
	player.died.connect(_on_player_died)
	player.bounds_min = 60.0
	player.bounds_max = cam_x + VIEW.x * 0.5 - 60.0
	player.floor_y = ground_y
	GameState.run_set("time", float(GameState.run.get("time", 0.0)))

func _on_player_died() -> void:
	if finished:
		return
	await get_tree().create_timer(1.9).timeout
	if not finished:
		if GameState.try_scroll_revive(player):
			return
		finished = true
		player_died.emit()

# ---------------------------------------------------------------- kamera ----

func _process(delta: float) -> void:
	if player and is_instance_valid(player):
		GameState.run_add("time", delta)
		_update_camera(delta)
		_update_flow(delta)
	camera.position = Vector2(cam_x, VIEW.y * 0.5)

func _update_camera(delta: float) -> void:
	var max_cam := maxf(VIEW.x * 0.5, stage_length - VIEW.x * 0.5)
	var target := clampf(player.position.x, cam_x, max_cam)
	cam_x = move_toward(cam_x, target, 700.0 * delta)
	player.bounds_min = cam_x - VIEW.x * 0.5 + 40.0
	player.bounds_max = cam_x + VIEW.x * 0.5 - 40.0

# ------------------------------------------------------------------ fale ----

func _alive_enemies() -> Array:
	var out := []
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		if e.has_method("is_dead") and e.is_dead():
			continue
		out.append(e)
	return out

func _update_flow(delta: float) -> void:
	if finished or player.state == Player.S.DEAD:
		return
	var alive := _alive_enemies()
	if wave_active and alive.is_empty():
		wave_active = false
		wave_cleared = true
		_on_wave_cleared()
	if not wave_cleared:
		_update_gate(true)
		return
	_update_gate(false)
	if wave_i >= waves.size():
		_finish_stage()
		return
	# gracz musi dojść do prawej krawędzi ekranu
	if player.position.x > cam_x + VIEW.x * 0.5 - 90.0:
		_advance_wave()

func _on_wave_cleared() -> void:
	Audio.play("gate", 1.0, -6.0)
	var left := waves.size() - wave_i - 1
	if left <= 0:
		_banner("ETAP OCZYSZCZONY", "")
		clear_t = 0.0
	else:
		_banner("FALA %d / %d" % [wave_i + 1, waves.size()], "Idź w prawo →")

func _advance_wave() -> void:
	var max_cam := maxf(VIEW.x * 0.5, stage_length - VIEW.x * 0.5)
	cam_x = minf(cam_x + STEP_WIDTH, max_cam)
	wave_cleared = false
	clear_t = -1.0
	_spawn_wave()

func _spawn_wave() -> void:
	if wave_i >= waves.size():
		return
	var wave: Dictionary = waves[wave_i]
	var air := bool(wave.get("air", false))
	var right := cam_x + VIEW.x * 0.5
	_banner("FALA %d" % (wave_i + 1), _wave_name(wave))
	wave_active = true
	wave_i += 1
	Audio.play("gate", 0.7, -10.0)
	for entry in wave["enemies"]:
		var id := String(entry[0])
		var n := int(entry[1])
		for i in n:
			var e: Enemy
			if bool(EnemyDB.get_data(id).get("boss", false)):
				e = (BOSS_SCENE as PackedScene).instantiate() as Enemy
			else:
				e = (ENEMY_SCENE as PackedScene).instantiate() as Enemy
			e.setup(id, air, _make_elite(wave))
			e.set_bounds(maxf(40.0, cam_x - 260.0), minf(stage_length - 40.0, right + 320.0), ground_y)
			entities.add_child(e)
			var px := right - 60.0 - float(i) * rng.randf_range(70, 120)
			var py := ground_y - rng.randf_range(180, 300) if air else ground_y - 60.0
			e.position = Vector2(px, py)
			if e is Boss:
				boss = e
				(e as Boss).start_intro()
				boss_registered.emit(e)
				hud.set_boss(e)

func _make_elite(wave: Dictionary) -> bool:
	var tag := String(wave.get("tag", ""))
	return tag == "miniboss" and randf() < 0.6

func _wave_name(wave: Dictionary) -> String:
	var names := []
	for entry in wave["enemies"]:
		names.append(String(EnemyDB.get_data(String(entry[0]))["name"]))
	return ", ".join(names)

func _finish_stage() -> void:
	if finished:
		return
	finished = true
	Audio.stop_music()
	if player and is_instance_valid(player):
		player.victory()
	_banner("ZWYCIĘSTWO!", "")
	Fx.flash(Color(1, 1, 0.9), 0.4, 0.4)
	Audio.play("levelup", 1.0, -2.0)
	await get_tree().create_timer(2.0).timeout
	stage_cleared.emit()

# ---------------------------------------------------------------- banery ----

func _banner(title: String, sub: String) -> void:
	var v := UiBanner.new()
	v.setup(title, sub)
	add_child(v)

# ---------------------------------------------------------------- pomocne ---

func enemies_left() -> int:
	return _alive_enemies().size()

func waves_left() -> int:
	return maxi(0, waves.size() - wave_i)

func kill_all_silently() -> void:
	for e in _alive_enemies():
		e.queue_free()
