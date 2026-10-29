class_name Enemy
extends CharacterBody2D
## Ptak przeciwnik. Jeden skrypt obsługuje kilka typów zachowania
## (charger, sprinter, ranged, dasher, grappler) — różni je tablica ataków
## i sposób doboru ruchu.

signal died(enemy: Enemy)
signal noticed   # potwór zauważył gracza (dymek „!”; serwer rozsyła go klientom)

enum S { SPAWN, IDLE, APPROACH, BACKOFF, WINDUP, STRIKE, RECOVER, HURT, STAGGER, DEAD, AIR_WAIT, SUMMON }

const GRAVITY := 1700.0
const MAX_FALL := 900.0

const PROJ_SCENE := preload("res://scenes/enemy_projectile.tscn")
const PICKUP_SCENE := preload("res://scenes/pickup.tscn")

@onready var visual: CreatureVisual = $Visual
@onready var hitbox: Hitbox = $Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox

var species := "wrzos"
var data: Dictionary = {}
var state: int = S.SPAWN
var state_t := 0.0
var facing := -1.0

var health := 30.0
var max_health := 30.0
var defense := 0.0
var speed := 120.0
var poise := 0.0
var poise_left := 0.0
var xp_value := 10
var gold_value := 3
var tier := 1
## Modyfikatory własnych fal (życie / atak / XP względem normalnych wartości).
var skin := ""
var is_duel := false
var _parry_cd := 0.0
var mod_hp := 1.0
var mod_dmg := 1.0
var mod_xp := 1.0

func apply_mods(hp: float, dmg: float, xp: float) -> void:
	mod_hp = hp
	mod_dmg = dmg
	mod_xp = xp
	max_health *= hp
	health = max_health
	xp_value = int(round(float(xp_value) * xp))

var player: Node2D = null
var bounds_min := -100000.0
var bounds_max := 100000.0
var bounds_top := -100000.0
var bounds_bottom := 100000.0
var ground_y := 100000.0
var flying := false
var hover_y := 0.0
var is_boss := false
var elite := false

var attack: Dictionary = {}
var atk_t := 0.0
var atk_fired := false
var cooldown := 1.0
var strafe_dir := 1.0
var aggro := 500.0
## Śpiący wróg (zasadzka w jaskini): stoi w miejscu, aż gracz wejdzie w jego zasięg lub go zaatakuje.
var dormant := false
var keep_distance := 0.0
var attack_range := 50.0
var hit_count := 0
var stagger_time := 0.0
var dead := false
var weapon_taken := false
var drop_roll := 0.0
var _burst_done := false
var _grabbed := false
var leap_dir := 0.0
var net_id := ""
var net_ghost := false
## Serwer dedykowany: bez lokalnych nagród, zabójcę obsługuje serwer.
var server_mode := false
var last_killer: Node = null

func setup(id: String, p_flying: bool = false, p_elite: bool = false) -> void:
	species = id
	data = EnemyDB.get_data(id)
	if skin == "":
		skin = String(data.get("skin", ""))
	if skin == "" and not bool(data.get("boss", false)):
		skin = EnemySkins.default_for(id, int(data.get("tier", 1)))
	flying = p_flying
	elite = p_elite
	is_boss = bool(data.get("boss", false))
	max_health = float(data["health"]) * (1.7 if elite else 1.0) * GameState.enemy_hp_mult()
	health = max_health
	defense = float(data.get("defense", 0.0))
	speed = float(data.get("speed", 120.0)) * (1.08 if elite else 1.0)
	poise = float(data.get("poise", 0.0)) * (1.0 + (0.5 if elite else 0.0))
	xp_value = int(round(float(data["xp"]) * (1.6 if elite else 1.0) * float(GameState.diff_data()["xp"])))
	gold_value = int(round(float(data["gold"]) * (1.6 if elite else 1.0) * float(GameState.diff_data()["gold"])))
	tier = int(data.get("tier", 1))
	aggro = float(data.get("aggro", 500.0))
	keep_distance = float(data.get("keep_distance", 0.0))
	attack_range = float(data.get("attack_range", 50.0))
	cooldown = randf_range(0.4, 1.2)

func _ready() -> void:
	if data.is_empty():
		setup(species)
	add_to_group("enemies")
	hurtbox.team = "enemy"
	visual.configure(species, data["pal"], float(data.get("scale", 1.0)) * (1.12 if elite else 1.0))
	visual.idle_seed = randf() * TAU
	if skin != "":
		EnemySkins.apply(visual, skin)
	if elite:
		visual.modulate = Color(1.15, 0.9, 0.9)
	$Body.shape = _body_shape()
	$Label.visible = is_boss
	$Tell.texture = Art.soft_blob(104, Color(1, 1, 1, 1.0), 0.5, 26)
	$Tell.visible = false
	cooldown = randf_range(0.5, 1.4)
	set_state(S.SPAWN)
	queue_redraw()
	if net_ghost:
		set_physics_process(false)
		collision_layer = 0
		collision_mask = 0
		hitbox.monitoring = false
		hitbox.monitorable = false
		hurtbox.monitoring = false
		hurtbox.monitorable = false
		$Tell.visible = false

func apply_net_state(info: Dictionary) -> void:
	if not net_ghost:
		return
	var target := Vector2(float(info.get("x", global_position.x)), float(info.get("y", global_position.y)))
	global_position = global_position.lerp(target, 0.6)
	max_health = maxf(1.0, float(info.get("max_health", max_health)))
	health = clampf(float(info.get("health", health)), 0.0, max_health)
	var f := float(info.get("facing", facing))
	if f != 0.0:
		facing = signf(f)
		visual.set_facing(facing)
	state = int(info.get("state", state))
	visual.moving = bool(info.get("moving", false))
	visual.dead = health <= 0.0
	queue_redraw()

func _body_shape() -> RectangleShape2D:
	var s := RectangleShape2D.new()
	var sc := float(data.get("scale", 1.0)) * (1.12 if elite else 1.0)
	s.size = Vector2(30.0 * sc, 42.0 * sc)
	return s

func _draw() -> void:
	if dead or health >= max_health or is_boss:
		return
	var w := 34.0 * float(data.get("scale", 1.0))
	var y := -52.0 * float(data.get("scale", 1.0))
	var k := clampf(health / max_health, 0.0, 1.0)
	draw_rect(Rect2(-w * 0.5 - 1.0, y - 1.0, w + 2.0, 6.0), Color(0, 0, 0, 0.55))
	draw_rect(Rect2(-w * 0.5, y, w * k, 4.0), Color(0.85, 0.25, 0.22) if k < 0.35 else Color(0.95, 0.7, 0.2))
	if elite:
		draw_arc(Vector2(0, -26), 30.0 * float(data.get("scale", 1.0)), 0, TAU, 24, Color(1.0, 0.85, 0.3, 0.35), 1.5, true)

func set_state(s: int) -> void:
	state = s
	state_t = 0.0
	match s:
		S.WINDUP:
			atk_t = 0.0
			atk_fired = false
			_burst_done = false
			_grabbed = false
			hit_count = 0
			_place_hitbox(float(attack.get("range", 50.0)) * 0.4)
		S.DEAD:
			hitbox.stop()
			hurtbox.set_vulnerable(false)
			visual.die()

func is_dead() -> bool:
	return dead

func set_bounds(a: float, b: float, gy: float) -> void:
	bounds_min = a
	bounds_max = b
	ground_y = gy

func set_bounds_rect(a: float, b: float, top: float, bottom: float) -> void:
	bounds_min = a
	bounds_max = b
	bounds_top = top
	bounds_bottom = bottom

# -------------------------------------------------------------- pętla --------

func _physics_process(delta: float) -> void:
	_parry_cd = maxf(0.0, _parry_cd - delta)
	if player and (not is_instance_valid(player) or player.state == Player.S.DEAD):
		player = null
	_find_player()
	state_t += delta
	poise_left = minf(poise, poise_left + poise * 0.55 * delta)
	var td := GameState.is_topdown()
	if not flying and not td and not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
	elif flying and not td:
		velocity.y = 0.0

	match state:
		S.SPAWN: _st_spawn(delta)
		S.IDLE: _st_idle(delta)
		S.APPROACH: _st_approach(delta)
		S.BACKOFF: _st_backoff(delta)
		S.AIR_WAIT: _st_air_wait(delta)
		S.WINDUP: _st_windup(delta)
		S.STRIKE: _st_strike(delta)
		S.RECOVER: _st_recover(delta)
		S.HURT: _st_hurt(delta)
		S.STAGGER: _st_stagger(delta)
		S.DEAD: _st_dead(delta)

	_clamp()
	move_and_slide()
	_update_visual()
	if not dead:
		queue_redraw()

func _find_player() -> void:
	var best: Node2D = null
	var best_d := 1.0e20
	var td := GameState.is_topdown()
	for p in get_tree().get_nodes_in_group("player"):
		if not is_instance_valid(p):
			continue
		if p is Player and (p as Player).state == Player.S.DEAD:
			continue
		if not (p is Node2D):
			continue
		var d: float = absf((p as Node2D).global_position.x - global_position.x)
		if td:
			d = (p as Node2D).global_position.distance_to(global_position)
		if d < best_d:
			best_d = d
			best = p as Node2D
	# w kampanii top-down wrogowie biją też żołnierzy i pety, jeśli są bliżej
	if td:
		for grp in ["allies", "pets"]:
			for a in get_tree().get_nodes_in_group(grp):
				if not is_instance_valid(a) or not (a is Node2D) or bool(a.get("dying")):
					continue
				var da: float = (a as Node2D).global_position.distance_to(global_position) * 1.25
				if da < best_d and da < 260.0:
					best_d = da
					best = a as Node2D
	if best:
		player = best

func _distance_to_player() -> float:
	if not player or not is_instance_valid(player):
		return 99999.0
	if player.has_method("is_hidden") and player.is_hidden():
		return 99999.0
	if GameState.is_topdown():
		return global_position.distance_to(player.global_position)
	return absf(player.global_position.x - global_position.x)

func _player_dir() -> float:
	if not player or not is_instance_valid(player):
		return facing
	var d := signf(player.global_position.x - global_position.x)
	return d if d != 0.0 else facing

func _face_target() -> void:
	facing = _player_dir()
	visual.set_facing(facing)

func _clamp() -> void:
	if position.x < bounds_min:
		position.x = bounds_min
		velocity.x = absf(velocity.x)
	elif position.x > bounds_max:
		position.x = bounds_max
		velocity.x = -absf(velocity.x)
	if GameState.is_topdown():
		if position.y < bounds_top:
			position.y = bounds_top
			velocity.y = absf(velocity.y)
		elif position.y > bounds_bottom:
			position.y = bounds_bottom
			velocity.y = -absf(velocity.y)
	visual.set_facing(facing)

# ------------------------------------------------------------------ stany ----

func _st_spawn(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
	if not flying and position.y < ground_y - 4.0:
		pass
	if state_t > (0.45 if flying else 0.25):
		if flying and not GameState.is_topdown():
			hover_y = clampf(global_position.y, 200.0, ground_y - 90.0)
			set_state(S.AIR_WAIT)
		else:
			set_state(S.APPROACH)
	Fx.burst(global_position, Color(0.9, 0.9, 0.95, 0.7), 8, 160.0, 2.0, 0.3)

func _st_idle(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	if state_t > 0.2:
		set_state(S.APPROACH)

func _st_approach(delta: float) -> void:
	_face_target()
	var d := _distance_to_player()
	var ai := String(data.get("ai", "charger"))
	if GameState.is_topdown():
		_td_approach(delta, d, ai)
		_separate(delta)
		return
	if d > aggro:
		# nie widzi gracza — krąży wokół wejścia
		velocity.x = move_toward(velocity.x, facing * speed * 0.4, 800.0 * delta)
		if state_t > 1.6:
			facing = -facing
			state_t = 0.0
		return
	cooldown -= delta
	if keep_distance > 0.0 and ai == "ranged":
		if d < keep_distance * 0.75:
			velocity.x = move_toward(velocity.x, -facing * speed, 1200.0 * delta)
		elif d > keep_distance * 1.25:
			velocity.x = move_toward(velocity.x, facing * speed, 1200.0 * delta)
		else:
			velocity.x = move_toward(velocity.x, strafe_dir * speed * 0.55, 1000.0 * delta)
			if randf() < 0.01:
				strafe_dir = -strafe_dir
	else:
		if d > attack_range * 0.85:
			velocity.x = move_toward(velocity.x, facing * speed, 1400.0 * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, 1600.0 * delta)
	if cooldown <= 0.0 and d <= aggro:
		_choose_attack(d)
	elif d < attack_range * 0.6 and cooldown <= 0.0:
		_choose_attack(d)
	# separacja od innych ptaków
	_separate(delta)

## Budzi wroga i resztę watahy stojącą w pobliżu.
func wake() -> void:
	if not dormant:
		return
	dormant = false
	_notice_bubble()
	for o in get_tree().get_nodes_in_group("enemies"):
		if o != self and is_instance_valid(o) and o.get("dormant") == true and global_position.distance_to(o.global_position) < 280.0:
			o.dormant = false
			o._notice_bubble()

func _notice_bubble() -> void:
	noticed.emit()
	Fx.popup(global_position + Vector2(0, -78), "!", Color(1.0, 0.3, 0.2))

func _td_approach(delta: float, d: float, ai: String) -> void:
	if not player or not is_instance_valid(player):
		velocity = velocity.move_toward(Vector2.ZERO, 800.0 * delta)
		return
	if dormant:
		if d > aggro:
			velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
			return
		wake()
	var to: Vector2 = player.global_position - global_position
	var dir := to.normalized() if to.length() > 0.01 else Vector2(facing, 0.0)
	if d > aggro:
		velocity = velocity.move_toward(dir * speed * 0.4, 700.0 * delta)
		return
	cooldown -= delta
	if keep_distance > 0.0 and ai == "ranged":
		if d < keep_distance * 0.75:
			velocity = velocity.move_toward(-dir * speed, 1100.0 * delta)
		elif d > keep_distance * 1.25:
			velocity = velocity.move_toward(dir * speed, 1100.0 * delta)
		else:
			velocity = velocity.move_toward(dir.orthogonal() * strafe_dir * speed * 0.6, 900.0 * delta)
			if randf() < 0.01:
				strafe_dir = -strafe_dir
	else:
		if d > attack_range * 0.85:
			velocity = velocity.move_toward(dir * speed, 1300.0 * delta)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, 1500.0 * delta)
	if cooldown <= 0.0 and d <= aggro:
		_choose_attack(d)
	elif d < attack_range * 0.6 and cooldown <= 0.0:
		_choose_attack(d)

func _separate(delta: float) -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == self or not is_instance_valid(e) or not (e is Node2D):
			continue
		if e is Enemy and (e as Enemy).flying != flying:
			continue
		if GameState.is_topdown():
			var dv: Vector2 = global_position - e.global_position
			var dist := dv.length()
			if dist > 0.01 and dist < 42.0:
				velocity += dv.normalized() * 240.0 * delta
			continue
		var d: Vector2 = e.global_position - global_position
		if absf(d.x) < 34.0 and absf(d.y) < 44.0:
			var push := signf(d.x)
			if push == 0.0:
				push = 1.0
			velocity.x += push * 260.0 * delta

func _st_backoff(delta: float) -> void:
	if GameState.is_topdown():
		var to: Vector2 = (player.global_position - global_position) if (player and is_instance_valid(player)) else Vector2(facing, 0.0)
		var away := -to.normalized()
		velocity = velocity.move_toward(away * speed * 0.8, 1000.0 * delta)
	elif flying:
		velocity.x = move_toward(velocity.x, -facing * speed * 0.8, 1000.0 * delta)
		velocity.y = move_toward(velocity.y, (hover_y - global_position.y) * 2.0, 900.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, -facing * speed * 0.8, 1000.0 * delta)
	if state_t > 0.5:
		cooldown = randf_range(float(data["cooldown"][0]), float(data["cooldown"][1]))
		set_state(S.APPROACH)

func _st_air_wait(delta: float) -> void:
	_face_target()
	var d := _distance_to_player()
	if GameState.is_topdown():
		_td_approach(delta, d, String(data.get("ai", "charger")))
		_separate(delta)
		return
	cooldown -= delta
	var target_y := ground_y - 90.0 - randf() * 30.0
	hover_y = lerpf(hover_y, target_y, 0.02)
	velocity.y = clampf((hover_y - global_position.y) * 1.6, -260.0, 260.0)
	if d > aggro:
		velocity.x = move_toward(velocity.x, facing * speed * 0.4, 700.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	if cooldown <= 0.0 and d <= aggro:
		_choose_attack(d)
	_separate(delta)

func _choose_attack(d: float) -> void:
	var list: Array = data["attacks"]
	var best: Dictionary = {}
	for a in list:
		var rng_range := float(a["range"])
		if d <= rng_range and (best.is_empty() or rng_range < float(best["range"])):
			best = a
	if best.is_empty():
		# za daleko: podejście
		cooldown = 0.35
		return
	attack = best
	_face_target()
	leap_dir = facing
	set_state(S.WINDUP)
	Audio.play("swing", 1.3, -14.0)

func _st_windup(delta: float) -> void:
	var windup := float(attack.get("windup", 0.3))
	_face_target()
	velocity.x = move_toward(velocity.x, 0.0, 2200.0 * delta)
	if GameState.is_topdown():
		velocity.y = move_toward(velocity.y, 0.0, 2200.0 * delta)
	visual.arm_back = clampf(state_t / maxf(0.01, windup), 0.0, 1.0)
	visual.charge_t = clampf(state_t / maxf(0.01, windup), 0.0, 1.0) if float(attack.get("dmg", 0.0)) > 15.0 else 0.0
	if flying and not GameState.is_topdown():
		velocity.y = move_toward(velocity.y, (hover_y - global_position.y) * 2.0, 900.0 * delta)
	if state_t >= windup:
		_begin_strike()

func _begin_strike() -> void:
	atk_fired = true
	set_state(S.STRIKE)
	var active := float(attack.get("active", 0.15))
	_face_target()
	var dmg := float(attack.get("dmg", 8.0)) * (1.25 if elite else 1.0) * GameState.enemy_dmg_mult() * mod_dmg
	if weapon_taken:
		dmg *= 0.45
	var rng_range := float(attack.get("range", 50.0))
	_place_hitbox(rng_range * 0.4)
	var strike_aim := _aim_vec()
	hitbox.fire(active + 0.08, {
		"damage": dmg,
		"kb": (strike_aim * float(attack.get("kb", 150.0))) if GameState.is_topdown() else Vector2(facing * float(attack.get("kb", 150.0)), -200.0 if bool(attack.get("launch", false)) else -60.0),
		"hitstun": float(attack.get("stun", 0.3)),
		"launch": bool(attack.get("launch", false)),
		"unblockable": bool(attack.get("unblockable", false)),
		"crit": false,
		"team": "enemy",
		"source": self,
		"kind": "enemy",
		"grab": bool(attack.get("grab", false)),
	}, 1)
	# ruch ataku
	if bool(attack.get("dash", false)) or bool(attack.get("leap", false)):
		if GameState.is_topdown():
			velocity = strike_aim * maxf(320.0, rng_range * 1.7)
		else:
			velocity.x = facing * maxf(320.0, rng_range * 1.7)
			if not is_on_floor():
				velocity.y = -180.0
		_place_hitbox(rng_range * 0.5)
	if bool(attack.get("push", false)):
		velocity.x = facing * 260.0
	# pociski
	if attack.has("projectile"):
		var n := int(attack.get("volley", 1))
		for i in n:
			var ang := deg_to_rad(randf_range(-26.0, 26.0))
			var p := (PROJ_SCENE as PackedScene).instantiate() as EnemyProjectile
			p.setup(self, {
				"damage": dmg * (0.9 if n > 1 else 1.0),
				"speed": 380.0,
				"gravity": 120.0 if bool(attack.get("slow", false)) else 220.0,
				"radius": 12.0,
				"dir": facing,
				"aim": strike_aim,
				"angle": ang,
				"kind": String(attack["projectile"]),
				"slow": bool(attack.get("slow", false)),
				"delay": i * 0.11,
			})
			get_parent().add_child(p)
			p.global_position = global_position + (strike_aim * 22.0 + Vector2(0.0, -26.0) if GameState.is_topdown() else Vector2(facing * 18.0, -30.0))
	# fala uderzeniowa
	if attack.has("shock"):
		_shock(float(attack["shock"]), dmg)
	# ogon po akcji
	Audio.play("punch", randf_range(0.9, 1.15), -8.0)
	if is_boss or float(attack.get("dmg", 0.0)) > 14.0:
		Audio.play("swing_heavy", 0.8, -10.0)
	Fx.slash(global_position + Vector2(facing * rng_range * 0.5, -30.0), facing, Color(1.0, 0.7, 0.6, 0.75), 0.9)

## Kierunek ataku: w top-down w stronę gracza (2D), w platformówce poziomo.
func _aim_vec() -> Vector2:
	if GameState.is_topdown() and player and is_instance_valid(player):
		var d: Vector2 = player.global_position - global_position
		if d.length() > 1.0:
			return d.normalized()
	return Vector2(facing, 0.0)

func _place_hitbox(dist: float) -> void:
	if GameState.is_topdown():
		hitbox.aim_offset(_aim_vec(), dist, -26.0)
	else:
		hitbox.move_offset(facing * dist, -26.0)

func _shock(radius: float, dmg: float) -> void:
	var fx_pos := global_position if GameState.is_topdown() else Vector2(global_position.x, ground_y - 6.0)
	Fx.ring(fx_pos, Color(1.0, 0.6, 0.35), radius, 0.3, 5.0)
	Fx.burst(fx_pos, Color(0.8, 0.7, 0.5), 12, 260.0, 3.0, 0.4)
	if player and is_instance_valid(player):
		var topdown := GameState.is_topdown()
		var to_player: Vector2 = player.global_position - global_position
		var in_range := to_player.length() < radius if topdown else absf(to_player.x) < radius
		if in_range:
			var hb: Hurtbox = player.get_node_or_null("Hurtbox")
			if hb:
				var kb_dir := to_player.normalized() if topdown else Vector2(_player_dir(), 0.0)
				hb.take_hit({
					"damage": dmg * 0.8,
					"kb": (kb_dir * 260.0) if topdown else Vector2(_player_dir() * 260.0, -280.0),
					"hitstun": 0.4,
					"launch": not topdown,
					"crit": false,
					"team": "enemy",
					"source": self,
					"kind": "shock",
				})

func _st_strike(delta: float) -> void:
	var active := float(attack.get("active", 0.15))
	visual.arm = 1.0 if state_t < active * 0.7 else 0.0
	visual.charge_t = 0.0
	if bool(attack.get("dash", false)) or bool(attack.get("leap", false)):
		velocity.x = move_toward(velocity.x, facing * 120.0, 1400.0 * delta)
	if GameState.is_topdown():
		velocity.y = move_toward(velocity.y, 0.0, 1400.0 * delta)
	elif flying:
		velocity.y = move_toward(velocity.y, (hover_y - global_position.y) * 1.5, 800.0 * delta)
	if state_t >= active:
		set_state(S.RECOVER)

func _st_recover(delta: float) -> void:
	var rec := float(attack.get("recover", 0.4))
	velocity.x = move_toward(velocity.x, 0.0, 1200.0 * delta)
	visual.arm = maxf(0.0, visual.arm - delta * 6.0)
	if GameState.is_topdown():
		velocity.y = move_toward(velocity.y, 0.0, 1200.0 * delta)
	elif flying:
		velocity.y = move_toward(velocity.y, (hover_y - global_position.y) * 1.6, 900.0 * delta)
	if state_t >= rec:
		hitbox.stop()
		var ai := String(data.get("ai", "charger"))
		if ai in ["ranged", "sprinter", "grappler"] and randf() < 0.55:
			strafe_dir = -strafe_dir
			set_state(S.BACKOFF)
		else:
			cooldown = randf_range(float(data["cooldown"][0]), float(data["cooldown"][1]))
			set_state(S.AIR_WAIT if flying else S.APPROACH)

# --------------------------------------------------------------- obrażenia ---

## Rycerz pojedynku paruje każdy cios z przodu, dopóki nie atakuje (wtedy jest odsłonięty).
func _try_parry(info: Dictionary) -> bool:
	if _parry_cd > 0.0 or bool(info.get("unblockable", false)):
		return false
	if String(info.get("kind", "")) in ["bleed", "zone"]:
		return false
	if not (state in [S.IDLE, S.APPROACH, S.BACKOFF, S.AIR_WAIT]):
		return false
	var src = info.get("source")
	if src == null or not is_instance_valid(src) or not (src is Node2D):
		return false
	var to_src: Vector2 = (src as Node2D).global_position - global_position
	if to_src.length() > 1.0 and to_src.normalized().dot(_aim_vec()) < -0.15:
		return false   # cios w plecy
	_parry_cd = 0.45
	visual.flash(0.4)
	Fx.ring(global_position + Vector2(0, -34), Color(1.0, 0.95, 0.7), 62.0, 0.28, 5.0)
	Fx.burst(global_position + Vector2(0, -34) + _aim_vec() * 22.0, Color(1.0, 0.95, 0.6), 10, 240.0, 2.5, 0.25)
	Fx.popup(global_position + Vector2(0, -90), "PARUJE!", Color(1.0, 0.9, 0.5))
	Audio.play("parry", randf_range(0.95, 1.1), -2.0)
	if src is Player:
		(src as Player).apply_hit({"damage": 3.0, "kb": _aim_vec() * 260.0, "hitstun": 0.4, "launch": false, "crit": false, "team": "enemy", "source": self, "kind": "riposta"})
	# riposta: szybki kontratak — po nim rycerz jest odsłonięty
	var atks: Array = data.get("attacks", [])
	if not atks.is_empty():
		attack = atks[0]
		_face_target()
		set_state(S.WINDUP)
		state_t = float(attack.get("windup", 0.3)) * 0.5
	return true

func apply_hit(info: Dictionary) -> bool:
	wake()
	if dead:
		return false
	if bool(data.get("duelist", false)) and _try_parry(info):
		return true
	var dmg := float(info.get("damage", 0.0))
	dmg = maxf(1.0, dmg * (1.0 - defense))
	health -= dmg
	hit_count += 1
	visual.flash(1.0)
	var crit := bool(info.get("crit", false))
	Fx.damage_number(global_position + Vector2(randf_range(-10, 10), -56.0 * float(data.get("scale", 1.0))), dmg, Color(1.0, 0.85, 0.35) if crit else Color(1.0, 0.97, 0.9), "crit" if crit else "normal")
	Fx.burst(global_position + Vector2(0, -26), Color(1.0, 0.6, 0.4), 6, 190.0, 2.5, 0.25)
	Audio.play("hit_crit" if crit else ("hit_heavy" if dmg > 18.0 else "hit"), randf_range(0.9, 1.15), -5.0)
	if not bool(info.get("no_hitstop", false)):
		Fx.hitstop(0.05 if not crit else 0.1)
	# nagroda za trafienie
	var src = info.get("source")
	if src and is_instance_valid(src) and src is Player:
		(src as Player).add_fury(0.007 * dmg)
		(src as Player).add_combo()
	# furia / odrzut
	var kb: Vector2 = info.get("kb", Vector2.ZERO)
	if health <= 0.0:
		_die(info)
		return true
	poise_left -= float(info.get("hitstun", 0.3))
	if poise_left <= 0.0 or bool(info.get("launch", false)):
		_stagger(float(info.get("hitstun", 0.3)) + (0.25 if poise_left <= 0.0 else 0.0), kb)
	else:
		velocity += kb * 0.25
		hitbox.stop()
	return true

func stagger(time: float, kb: Vector2 = Vector2.ZERO) -> void:
	if dead:
		return
	_stagger(time, kb)

func _stagger(time: float, kb: Vector2) -> void:
	stagger_time = time
	velocity = kb
	hitbox.stop()
	visual.arm = 0.0
	visual.charge_t = 0.0
	set_state(S.STAGGER)

func _st_hurt(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
	visual.arm = 0.0

func _st_stagger(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
	visual.crouch = 0.3
	if GameState.is_topdown():
		velocity.y = move_toward(velocity.y, 0.0, 600.0 * delta)
	elif not flying and is_on_floor():
		velocity.y = 0.0
	if state_t >= stagger_time:
		visual.crouch = 0.0
		cooldown = randf_range(0.25, 0.7)
		set_state(S.AIR_WAIT if flying else S.APPROACH)

func _die(info: Dictionary = {}) -> void:
	if dead:
		return
	dead = true
	health = 0.0
	visual.die()
	hitbox.stop()
	hurtbox.set_vulnerable(false)
	Audio.play("die", randf_range(0.9, 1.15), -6.0)
	Fx.hitstop(0.08)
	Fx.burst(global_position + Vector2(0, -26), Color(0.9, 0.4, 0.35), 16, 280.0, 3.0, 0.5)
	drop_roll = randf()
	var src = info.get("source")
	if server_mode:
		last_killer = src if (src and is_instance_valid(src) and src is Player) else null
		set_state(S.DEAD)
		died.emit(self)
		return
	if src and is_instance_valid(src) and src is Player:
		var luck := GameState.stat("luck")
		var streak_m := GameState.streak_kill()
		GameState.add_xp(int(round(float(xp_value) * luck * streak_m)))
		GameState.run_add("kills", 1)
		if randf() < 0.55 + 0.15 * luck:
			_spawn_drop()
		if randf() < 0.7 or (streak_m >= 1.4 and randf() < 0.5):
			_spawn_gold()
		_maybe_pattern_drop()
		_maybe_gear_drop()
	set_state(S.DEAD)
	died.emit(self)

func _maybe_gear_drop() -> void:
	return   # legendarki wypadają wyłącznie z bossów sekretnych jaskiń
	var lv := int(GameState.diff_data()["loot"])
	var chance := (0.004 + 0.002 * float(tier)) * (1.0 + 2.5 * float(lv))
	if elite:
		chance = chance * 5.0 + 0.02
	if is_boss:
		chance = 1.0
	if randf() > chance:
		return
	var gid := ItemsHard.roll(lv)
	if gid == "":
		return
	var p := (PICKUP_SCENE as PackedScene).instantiate() as Pickup
	p.setup(gid, 1)
	get_parent().add_child(p)
	p.global_position = global_position + Vector2(randf_range(-26, 26), -40)
	GameState.toast.emit("Wypadł: %s!" % String(ItemDB.get_data(gid).get("name", gid)), ItemDB.rarity_color(gid))

func _maybe_pattern_drop() -> void:
	var chance := 0.03 + 0.02 * float(tier) + (0.1 if elite else 0.0)
	if randf() > chance:
		return
	var pid := RuneDB.random_pattern(tier)
	if pid == "":
		return
	var p := (PICKUP_SCENE as PackedScene).instantiate() as Pickup
	p.setup(pid, 1)
	get_parent().add_child(p)
	p.global_position = global_position + Vector2(randf_range(-20, 20), -34)
	GameState.toast.emit("Wypadł wzorzec run!", Color(1.0, 0.85, 0.4))

func _spawn_drop() -> void:
	var pool := ["mikstura_miodu", "jajko", "eliksir_pietra"]
	if tier >= 2:
		pool.append("jajko_ogromne")
	if tier >= 3:
		pool.append("skamielina")
		if randf() < 0.4:
			pool.append("rosol_z_ptaka")
	var id: String = pool[randi() % pool.size()]
	var p := (PICKUP_SCENE as PackedScene).instantiate() as Pickup
	p.setup(id, 1)
	get_parent().add_child(p)
	p.global_position = global_position + Vector2(0, -30)

func _spawn_gold() -> void:
	var n := 1 + (1 if randf() < 0.35 * GameState.stat("luck") else 0)
	if elite:
		n += 2
	var p := (PICKUP_SCENE as PackedScene).instantiate() as Pickup
	p.setup("gold", n)
	get_parent().add_child(p)
	p.global_position = global_position + Vector2(randf_range(-14, 14), -26)

func _st_dead(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
	if GameState.is_topdown():
		velocity.y = move_toward(velocity.y, 0.0, 300.0 * delta)
	elif not is_on_floor() and not flying:
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
	if flying and not GameState.is_topdown():
		velocity.y = move_toward(velocity.y, 260.0, 700.0 * delta)
		visual.flap = 0.9
	if state_t > 1.4:
		queue_free()

func _update_visual() -> void:
	var td := GameState.is_topdown()
	visual.moving = (absf(velocity.x) > 20.0 or (td and absf(velocity.y) > 20.0)) and (td or is_on_floor()) and not dead
	visual.grounded = td or is_on_floor() or flying
	visual.flap = clampf(1.0 - velocity.y / 500.0, 0.0, 1.0) * (1.0 if flying and not td else 0.0)
	if not dead:
		visual.arm = lerpf(visual.arm, 0.0, 0.2) if state != S.STRIKE and state != S.WINDUP else visual.arm
		visual.charge_t = 0.0 if state != S.WINDUP else visual.charge_t
	visual.dead = dead
	# ostrzeżenie przed ciosem
	if state == S.WINDUP:
		$Tell.visible = true
		var k := clampf(state_t / maxf(0.01, float(attack.get("windup", 0.3))), 0.0, 1.0)
		$Tell.scale = Vector2.ONE * (0.6 + 0.6 * k)
		$Tell.modulate = Color(1.0, 0.4, 0.3, 0.25 + 0.35 * k)
	else:
		$Tell.visible = false
