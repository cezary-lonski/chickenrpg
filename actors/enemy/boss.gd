class_name Boss
extends Enemy
## Indyk Królewski. Trzy fazy, własne wzorce ataków, wzywa posiłki
## i wchodzi w szał, gdy zejdzie mu poniżej 20% życia.

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")

var phase := 1
var enraged := false
var intro_done := false
var pattern_cooldown := 0.0
var current_pattern := ""
var pattern_step := 0
var _phase_lock := 0.0
var _enrage_done := false

func _ready() -> void:
	if data.is_empty():
		species = "indyk_krolewski"
	super._ready()
	intro_done = false
	health = max_health * 0.5
	$Label.visible = true
	$Label.text = String(data.get("name", "BOSS")).to_upper()

func start_intro() -> void:
	if intro_done:
		return
	intro_done = true
	set_state(S.SPAWN)
	velocity = Vector2.ZERO
	Audio.play("roar", 0.75, 2.0)
	Audio.stop_music()
	await get_tree().create_timer(0.5).timeout
	Audio.play_music("boss")
	Fx.flash(Color(1.0, 0.4, 0.25), 0.35, 0.5)
	Fx.shake(10.0, 0.8)
	Audio.play("roar", 0.9, 4.0)
	set_ph(1)
	await get_tree().create_timer(1.4).timeout

func _physics_process(delta: float) -> void:
	if not intro_done:
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		if not is_on_floor():
			velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
		visual.flap = 0.2 + 0.1 * sin(state_t * 3.0)
		move_and_slide()
		queue_redraw()
		return
	super._physics_process(delta)
	_check_phase()

func _check_phase() -> void:
	if dead or _phase_lock > 0.0:
		_phase_lock = maxf(0.0, _phase_lock - get_physics_process_delta_time())
		return
	var k := health / max_health
	if not enraged and k < 0.2:
		enraged = true
		set_ph(3)
		return
	if phase == 1 and k < 0.66:
		set_ph(2)
	elif phase == 2 and k < 0.33:
		set_ph(3)

func set_ph(p: int) -> void:
	phase = p
	_phase_lock = 1.6
	velocity = Vector2.ZERO
	set_state(S.STAGGER)
	stagger_time = 0.9
	poise_left = poise
	Audio.play("roar", 0.8, 2.0)
	Fx.flash(Color(1.0, 0.55, 0.3), 0.3, 0.45)
	Fx.shake(12.0, 0.7)
	Fx.popup(global_position + Vector2(0, -120.0), "FAZA %d!" % p, Color(1.0, 0.5, 0.3))
	hitbox.stop()
	# wzmocnienie
	max_health = max(max_health, float(data["health"]))
	speed = float(data.get("speed", 92.0)) * (1.0 + 0.12 * float(p - 1))
	if p >= 2:
		_summon_adds(2 if p == 2 else 3)

func _summon_adds(n: int) -> void:
	for i in n:
		var e := (ENEMY_SCENE as PackedScene).instantiate() as Enemy
		e.setup("wronszek" if randf() < 0.5 else "sroka", true, false)
		get_parent().add_child(e)
		e.global_position = global_position + Vector2(randf_range(-320, 320), -260.0 - randf() * 80.0)
		e.set_bounds(bounds_min, bounds_max, ground_y)
		Fx.ring(e.global_position, Color(0.9, 0.6, 0.3), 40.0, 0.4, 3.0)

# ------------------------------------------------------------------ wzorce --

func _choose_attack(d: float) -> void:
	var attacks: Array = data.get("attacks", [])
	if attacks.is_empty():
		return
	var pool: Array = []
	for a in attacks:
		var w := float(a.get("w", 1.0))
		var reach := float(a.get("range", 60.0))
		if d < reach * 1.25:
			w *= 1.8
		pool.append({"name": String(a["name"]), "w": w})
	var total := 0.0
	for p in pool:
		total += float(p["w"])
	var r := randf() * total
	var chosen: String = String(pool[0]["name"])
	for p in pool:
		r -= float(p["w"])
		if r <= 0.0:
			chosen = String(p["name"])
			break
	for a in attacks:
		if String(a["name"]) == chosen:
			attack = a
			break
	_face_target()
	leap_dir = facing
	if chosen == "pijar" and randf() < 0.5:
		# podskok z wierzchu — zaskakuje
		velocity.y = -520.0
		position.y -= 40.0
	set_state(S.WINDUP)

func _st_windup(delta: float) -> void:
	var windup := float(attack.get("windup", 0.5))
	_face_target()
	velocity.x = move_toward(velocity.x, 0.0, 2600.0 * delta)
	visual.arm_back = clampf(state_t / maxf(0.01, windup), 0.0, 1.0)
	visual.charge_t = clampf(state_t / maxf(0.01, windup), 0.0, 1.0)
	if state_t >= windup:
		_begin_strike()
		if String(attack.get("name", "")) == "pijar":
			Audio.play("roar", 1.3, -2.0)

func _st_strike(delta: float) -> void:
	super._st_strike(delta)
	if String(attack.get("name", "")) == "pijar" and state_t < 0.02:
		velocity.y = 900.0
		Fx.shake(8.0, 0.4)

func _die(info: Dictionary = {}) -> void:
	if dead:
		return
	super._die(info)
	if is_boss:
		Audio.stop_music()
		Fx.flash(Color(1, 1, 1), 0.6, 0.7)
		Fx.shake(16.0, 1.2)
		Audio.play("roar", 0.6, 4.0)
		for i in 3:
			var tw := create_tween()
			tw.tween_interval(i * 0.18)
			tw.tween_callback(func(): Fx.burst(global_position + Vector2(randf_range(-40, 40), -randf_range(10, 70)), Color(1.0, 0.7, 0.3), 18, 320.0, 4.0, 0.6))
		GameState.profile["stats"]["bosses"] = int(GameState.profile["stats"].get("bosses", 0)) + 1
