class_name BossBig
extends Enemy
## Prawdziwy boss kampanii top-down: wejście na arenę, fazy, zapowiedzi ataków,
## okna podatności, przywoływanie sług, sekwencja śmierci i nagrody.
## Dane w BossDB. Ataki: swipe_combo, feather_fan, dive, ring_wave, summon,
## beam_storm, lightning, charge, ground_pound.

signal phase_changed(index: int, label: String)
signal intro_finished
signal death_finished

var boss_id := ""
var bdata: Dictionary = {}
var phase := 1                      # odczytywane przez HUD ("FAZA n")
var mode := "intro"                 # intro | idle | attack | recover | transition | dying | dead
var arena_center := BossDB.ARENA_CENTER
var arena_radius := BossDB.ARENA_RADIUS
var tele: BossTelegraph

var _phase_i := 0
var _cd := 1.2
var _busy := false
var _abort := false
var _invuln := true
var _vuln_t := 0.0
var _last_attack := ""
var _beam_angle := 0.0
var _beam_active := false
var _beam_rot := 1.0
var _beam_tick := 0.0
var _beam_dmg := 20.0
var _dashing := false
var _ready_done := false

func setup_boss(id: String) -> void:
	boss_id = id
	bdata = BossDB.get_data(id)
	species = String(bdata["species"])
	data = {
		"name": String(bdata["name"]), "scale": float(bdata["scale"]), "pal": bdata["pal"],
		"aggro": 6000.0, "tier": 7, "boss": true, "ai": "boss", "attacks": [],
	}
	is_boss = true
	flying = false
	var dd := GameState.diff_data()
	max_health = float(bdata["hp"]) * clampf(GameState.enemy_hp_mult() / float(dd["hp"]) / 1.8, 1.0, 3.5) * float(dd["hp"])
	health = max_health
	defense = float(bdata.get("defense", 0.1))
	speed = float(bdata.get("speed", 130.0))
	poise = 999.0
	poise_left = 999.0
	xp_value = int(float(bdata.get("xp", 500)) * float(dd["xp"]))
	gold_value = int(float(bdata.get("gold", 200)) * float(dd["gold"]))
	tier = 7
	aggro = 6000.0

func _ready() -> void:
	super._ready()
	tele = BossTelegraph.new()
	add_child(tele)
	$Label.visible = false
	set_physics_process(true)
	_ready_done = true

# ------------------------------------------------------------------- pomocnicze ---

func _alive() -> bool:
	return is_inside_tree() and not dead and mode != "dying" and mode != "dead" and not _abort

func _wait(t: float) -> bool:
	await get_tree().create_timer(t, false).timeout
	return _alive()

func _phases() -> Array:
	return bdata.get("phases", [])

func _phase_data() -> Dictionary:
	return _phases()[_phase_i]

func _players() -> Array:
	var out: Array = []
	for p in get_tree().get_nodes_in_group("player"):
		if not is_instance_valid(p) or not (p is Node2D):
			continue
		if "state" in p and int(p.get("state")) == Player.S.DEAD:
			continue
		if "net_ghost" in p and bool(p.get("net_ghost")):
			continue
		out.append(p)
	return out

func _target() -> Node2D:
	var best: Node2D = null
	var bd := 1.0e9
	for p in _players():
		var d: float = (p as Node2D).global_position.distance_to(global_position)
		if d < bd:
			bd = d
			best = p
	return best

## Obrażenia skalowane do poziomu bohatera (walka ma być wykonalna na każdym poziomie).
func _dmg(factor: float = 1.0) -> float:
	var lv := 10
	if GameState.has_run():
		lv = int(GameState.char_profile(String(GameState.run.get("character", "lord"))).get("level", 10))
	var scale := clampf(float(lv) / 12.0, 0.7, 1.8)
	return float(bdata.get("dmg", 20.0)) * factor * scale * clampf(GameState.enemy_dmg_mult() / float(GameState.diff_data()["dmg"]) / 1.3, 1.0, 2.2) * float(GameState.diff_data()["dmg"]) * mod_dmg

func _clamp_arena(p: Vector2, margin: float = 70.0) -> Vector2:
	var d := p - arena_center
	var lim := arena_radius - margin
	if d.length() > lim:
		return arena_center + d.normalized() * lim
	return p

func _hurt(p: Node2D, dmg: float, kb: Vector2, launch: bool = false) -> void:
	var hb: Hurtbox = p.get_node_or_null("Hurtbox")
	if hb == null:
		return
	hb.take_hit({
		"damage": dmg, "kb": kb, "hitstun": 0.4, "launch": launch, "crit": false,
		"team": "enemy", "source": self, "kind": "boss", "unblockable": false,
	})

func _hurt_circle(c: Vector2, r: float, dmg: float, push: float = 320.0, launch: bool = false) -> void:
	for p in _players():
		var d: float = (p as Node2D).global_position.distance_to(c)
		if d <= r:
			_hurt(p, dmg, ((p as Node2D).global_position - c).normalized() * push, launch)

func _hurt_ring(c: Vector2, r_in: float, r_out: float, dmg: float) -> void:
	for p in _players():
		var d: float = (p as Node2D).global_position.distance_to(c)
		if d >= r_in and d <= r_out:
			_hurt(p, dmg, ((p as Node2D).global_position - c).normalized() * 280.0, true)

static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
	return p.distance_to(a + ab * t)

func _face_to(p: Node2D) -> void:
	if p == null:
		return
	var d := signf(p.global_position.x - global_position.x)
	if d != 0.0:
		facing = d
		visual.set_facing(facing)

# ---------------------------------------------------------------------- wejście ---

func start_intro() -> void:
	mode = "intro"
	_invuln = true
	visual.position.y = -900.0
	visual.modulate.a = 0.0
	Audio.stop_music()
	await get_tree().create_timer(0.4, false).timeout
	Audio.play("roar", 0.6, 4.0)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(visual, "position:y", 0.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(visual, "modulate:a", 1.0, 0.5)
	await tw.finished
	Fx.shake(16.0, 0.9)
	Fx.flash(Color(0.8, 0.4, 1.0), 0.35, 0.5)
	Fx.ring(global_position, Color(0.8, 0.4, 1.0), 380.0, 0.6, 8.0)
	Fx.burst(global_position + Vector2(0, -20), Color(0.6, 0.3, 0.9), 40, 520.0, 4.0, 0.7)
	Audio.play("hit_heavy", 0.5, 2.0)
	_hurt_circle(global_position, 200.0, _dmg(0.6), 520.0, true)
	await get_tree().create_timer(0.8, false).timeout
	var lines: Array = bdata.get("intro", [])
	if not lines.is_empty():
		var d := UiDialog.new()
		d.setup(lines, Color(0.85, 0.35, 0.9))
		Flow.open_dialog(d)
		await d.on_close
	Audio.play_music("boss")
	_invuln = false
	mode = "idle"
	_cd = 1.0
	intro_finished.emit()

# ---------------------------------------------------------------------- pętla ---

func _physics_process(delta: float) -> void:
	if net_ghost:
		return
	if mode == "dead":
		return
	_find_player()
	_vuln_t = maxf(0.0, _vuln_t - delta)
	if _beam_active:
		_beam_angle += _beam_rot * delta
		_beam_tick -= delta
		var angles := _beam_angles()
		tele.beams["angles"] = angles
		if _beam_tick <= 0.0:
			_beam_tick = 0.3
			for p in _players():
				for ang in angles:
					var tip := global_position + Vector2.RIGHT.rotated(float(ang)) * 900.0
					if _seg_dist((p as Node2D).global_position, global_position, tip) < 24.0:
						_hurt(p, _beam_dmg, Vector2.RIGHT.rotated(float(ang) + PI * 0.5) * 220.0, false)
						break
	match mode:
		"idle":
			_chase(delta)
		"recover":
			velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
		"attack":
			if not _dashing:
				velocity = velocity.move_toward(Vector2.ZERO, 1200.0 * delta)
		_:
			velocity = velocity.move_toward(Vector2.ZERO, 1400.0 * delta)
	global_position = _clamp_arena(global_position, 60.0)
	move_and_slide()
	visual.moving = velocity.length() > 20.0 and mode != "dying"
	visual.grounded = true
	visual.berserk = 1.0 if (_phase_i >= _phases().size() - 1 and _phases().size() > 2 and mode != "dying") else 0.0
	visual.arm = lerpf(visual.arm, 0.0, 0.1)
	if mode in ["idle", "recover"]:
		visual.set_facing(facing)
	queue_redraw()

func _chase(delta: float) -> void:
	var t := _target()
	if t == null:
		velocity = velocity.move_toward(Vector2.ZERO, 800.0 * delta)
		return
	_face_to(t)
	var to := t.global_position - global_position
	var sp := speed * float(_phase_data().get("speed", 1.0))
	if to.length() > 110.0:
		velocity = velocity.move_toward(to.normalized() * sp, 1400.0 * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 1400.0 * delta)
	_cd -= delta
	if _cd <= 0.0 and not _busy:
		_start_attack()

func _start_attack() -> void:
	var pool: Array = (_phase_data().get("attacks", ["swipe_combo"]) as Array).duplicate()
	if pool.size() > 1 and _last_attack in pool:
		pool.erase(_last_attack)
	var name := String(pool[randi() % pool.size()])
	_last_attack = name
	_busy = true
	mode = "attack"
	await _run_attack(name)
	_busy = false
	if mode == "attack":
		mode = "idle"
	var cd: Array = _phase_data().get("cd", [1.0, 1.5])
	_cd = randf_range(float(cd[0]), float(cd[1]))

func _run_attack(name: String) -> void:
	match name:
		"swipe_combo": await _atk_swipe_combo()
		"feather_fan": await _atk_feather_fan()
		"dive": await _atk_dive()
		"ring_wave": await _atk_ring_wave()
		"summon": await _atk_summon()
		"beam_storm": await _atk_beam_storm()
		"lightning": await _atk_lightning()
		"charge": await _atk_charge()
		"ground_pound": await _atk_ground_pound()
	_beam_active = false
	_dashing = false
	if _alive():
		Audio.play("land", 0.7, -6.0)

func _recover(t: float) -> void:
	if not _alive():
		return
	mode = "recover"
	_vuln_t = t
	visual.charge_t = 0.0
	Fx.popup(global_position + Vector2(0, -150.0 * float(data.get("scale", 1.0)) * 0.5), "ODSŁONIĘTY!", Color(1.0, 0.9, 0.4))
	await get_tree().create_timer(t, false).timeout
	if mode == "recover":
		mode = "attack"

func _dash(vec: Vector2, dur: float, hit_r: float = 0.0, dmg: float = 0.0) -> void:
	_dashing = true
	var hit := {}
	var t := 0.0
	while t < dur and _alive():
		velocity = vec
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		if hit_r > 0.0:
			for p in _players():
				if not hit.has(p) and (p as Node2D).global_position.distance_to(global_position) < hit_r:
					hit[p] = true
					_hurt(p, dmg, vec.normalized() * 380.0, true)
	_dashing = false
	velocity = Vector2.ZERO

# ------------------------------------------------------------------------- ataki ---

func _atk_swipe_combo() -> void:
	var col := Color(1.0, 0.3, 0.2)
	for i in 3:
		var t := _target()
		if t == null or not _alive():
			return
		_face_to(t)
		var to := t.global_position - global_position
		if to.length() > 150.0:
			await _dash(to.normalized() * 760.0, minf(0.3, (to.length() - 110.0) / 760.0))
			if not _alive():
				return
		t = _target()
		if t == null:
			return
		var dirv := (t.global_position - global_position).normalized()
		var c := global_position + dirv * 85.0
		var r := 100.0 + (28.0 if i == 2 else 0.0)
		tele.add_circle(c, r, 0.52, col)
		visual.arm_back = 1.0
		visual.charge_t = 1.0
		if not await _wait(0.52):
			return
		visual.arm = 1.0
		visual.charge_t = 0.0
		_hurt_circle(c, r, _dmg(1.0 + 0.25 * float(i)), 360.0, i == 2)
		Fx.slash(c, facing, Color(1.0, 0.5, 0.45, 0.85), 1.6)
		Fx.burst(c, Color(1.0, 0.5, 0.4), 12, 260.0, 3.0, 0.3)
		Audio.play("hit_heavy", 0.8 + 0.1 * float(i), -4.0)
		if not await _wait(0.22):
			return
	await _recover(0.5)

func _atk_feather_fan() -> void:
	var t := _target()
	if t == null:
		return
	_face_to(t)
	var n := mini(9 + 2 * _phase_i, 15)
	var spread := deg_to_rad(110.0 + 14.0 * float(_phase_i))
	var aim := (t.global_position - global_position).normalized()
	var col := Color(0.8, 0.4, 1.0)
	for i in n:
		var a := -spread * 0.5 + spread * float(i) / float(maxi(1, n - 1))
		tele.add_line(global_position, global_position + aim.rotated(a) * 760.0, 10.0, 0.75, col)
	visual.charge_t = 1.0
	if not await _wait(0.75):
		return
	visual.charge_t = 0.0
	visual.arm = 1.0
	Audio.play("roar", 1.3, -6.0)
	_fire_fan(aim, n, spread, 0.0)
	if _phase_i >= 1:
		if not await _wait(0.55):
			return
		_fire_fan(aim, n, spread, spread / float(maxi(1, n - 1)) * 0.5)
	await _recover(0.9)

func _fire_fan(aim: Vector2, n: int, spread: float, offset: float) -> void:
	for i in n:
		var a := -spread * 0.5 + spread * float(i) / float(maxi(1, n - 1)) + offset
		var p := (preload("res://scenes/enemy_projectile.tscn") as PackedScene).instantiate() as EnemyProjectile
		p.setup(self, {
			"damage": _dmg(0.55), "speed": 460.0, "gravity": 0.0, "radius": 12.0,
			"dir": facing, "aim": aim, "angle": a, "kind": "feather", "slow": false,
		})
		get_parent().add_child(p)
		p.global_position = global_position + aim.rotated(a) * 70.0 + Vector2(0, -30)

func _atk_dive() -> void:
	var count := 1 + mini(_phase_i, 2)
	_invuln = true
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(visual, "position:y", -900.0, 0.35).set_ease(Tween.EASE_IN)
	tw.tween_property(visual, "modulate:a", 0.0, 0.3)
	Audio.play("dash", 0.6, 0.0)
	if not await _wait(0.4):
		_invuln = false
		visual.position.y = 0.0
		visual.modulate.a = 1.0
		return
	for k in count:
		var t := _target()
		if t == null or not _alive():
			break
		var target := _clamp_arena(t.global_position, 120.0)
		tele.add_circle(target, 150.0, 1.0, Color(1.0, 0.25, 0.2))
		if not await _wait(1.0):
			break
		global_position = target
		velocity = Vector2.ZERO
		visual.modulate.a = 1.0
		var tw2 := create_tween()
		tw2.tween_property(visual, "position:y", 0.0, 0.12).set_ease(Tween.EASE_IN)
		await tw2.finished
		_hurt_circle(target, 150.0, _dmg(1.6), 480.0, true)
		Fx.shake(12.0, 0.4)
		Fx.ring(target, Color(1.0, 0.5, 0.3), 190.0, 0.4, 7.0)
		Fx.burst(target + Vector2(0, -10), Color(0.9, 0.5, 0.3), 24, 380.0, 3.5, 0.5)
		Audio.play("hit_heavy", 0.6, 0.0)
		if k < count - 1:
			if not await _wait(0.35):
				break
			var tw3 := create_tween()
			tw3.set_parallel(true)
			tw3.tween_property(visual, "position:y", -900.0, 0.3)
			tw3.tween_property(visual, "modulate:a", 0.0, 0.25)
			if not await _wait(0.35):
				break
	visual.position.y = 0.0
	visual.modulate.a = 1.0
	_invuln = false
	await _recover(1.6)

func _atk_ring_wave() -> void:
	var c := global_position
	var cycles := 1 + (1 if _phase_i >= 2 else 0)
	var col := Color(0.9, 0.3, 0.9)
	for cyc in cycles:
		for wave in 2:
			var rings: Array = [[70.0, 190.0], [350.0, 470.0]] if wave == 0 else [[210.0, 330.0], [490.0, 610.0]]
			for r in rings:
				tele.add_ring(c, float(r[0]), float(r[1]), 1.05, col)
			if not await _wait(1.05):
				return
			for r in rings:
				_hurt_ring(c, float(r[0]), float(r[1]), _dmg(1.1))
				Fx.ring(c, col, float(r[1]), 0.35, 6.0)
			Fx.shake(7.0, 0.25)
			Audio.play("hit_heavy", 0.9, -4.0)
			if not await _wait(0.3):
				return
	await _recover(0.8)

func _atk_summon() -> void:
	var n := int(_phase_data().get("adds", 3))
	Audio.play("roar", 0.9, -2.0)
	Fx.flash(Color(0.6, 0.3, 0.9), 0.2, 0.4)
	visual.charge_t = 1.0
	for i in n:
		var ang := TAU * float(i) / float(n) + randf() * 0.5
		var pos := _clamp_arena(global_position + Vector2.RIGHT.rotated(ang) * 260.0, 100.0)
		tele.add_circle(pos, 46.0, 0.9, Color(0.7, 0.3, 1.0))
	if not await _wait(0.9):
		return
	visual.charge_t = 0.0
	for i in n:
		var ang2 := TAU * float(i) / float(n) + randf() * 0.5
		var pos2 := _clamp_arena(global_position + Vector2.RIGHT.rotated(ang2) * 260.0, 100.0)
		var e := (preload("res://scenes/enemy.tscn") as PackedScene).instantiate() as Enemy
		e.setup("kruk", false, false)
		e.aggro = 3000.0
		get_parent().add_child(e)
		e.global_position = pos2
		e.set_bounds_rect(arena_center.x - arena_radius, arena_center.x + arena_radius, arena_center.y - arena_radius, arena_center.y + arena_radius)
		Fx.burst(pos2 + Vector2(0, -20), Color(0.7, 0.3, 1.0), 14, 220.0, 3.0, 0.4)
	await _wait(0.6)
	await _recover(0.6)

func _atk_beam_storm() -> void:
	var n := 4 if _phase_i < 3 else 5
	_beam_rot = (1.0 + 0.15 * float(_phase_i)) * (1.0 if randf() < 0.5 else -1.0)
	_beam_angle = randf() * TAU
	_beam_dmg = _dmg(0.6)
	tele.beams = {"center": global_position, "angles": _beam_angles_n(n), "length": 900.0, "width": 44.0, "active": false}
	_beam_n = n
	Audio.play("roar", 0.7, -2.0)
	visual.charge_t = 1.0
	visual.remote_spin = true
	visual.spin_speed = 0.0
	# zapowiedź: cienkie linie
	var t := 0.0
	while t < 1.1 and _alive():
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		tele.beams["angles"] = _beam_angles_n(n)
	if not _alive():
		visual.remote_spin = false
		tele.beams = {}
		return
	tele.beams["active"] = true
	_beam_active = true
	_beam_tick = 0.0
	visual.charge_t = 0.0
	visual.spin_speed = 6.0 * signf(_beam_rot)
	Audio.play("hit_heavy", 1.2, -2.0)
	var dur := 3.8
	t = 0.0
	while t < dur and _alive():
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	_beam_active = false
	tele.beams = {}
	visual.remote_spin = false
	visual.spin_speed = 0.0
	visual.spin_angle = 0.0
	await _recover(1.3)

var _beam_n := 4

func _beam_angles_n(n: int) -> Array:
	var out: Array = []
	for i in n:
		out.append(_beam_angle + TAU * float(i) / float(n))
	return out

func _beam_angles() -> Array:
	return _beam_angles_n(_beam_n)

func _atk_lightning() -> void:
	var n := 5 + _phase_i * 2
	visual.arm = 1.0
	Audio.play("roar", 1.4, -8.0)
	for i in n:
		if not _alive():
			return
		var t := _target()
		if t == null:
			return
		var pos := _clamp_arena(t.global_position + Vector2(randf_range(-70, 70), randf_range(-70, 70)), 60.0)
		tele.add_circle(pos, 78.0, 0.85, Color(0.6, 0.8, 1.0))
		_strike_later(pos, 78.0, 0.85, _dmg(1.0))
		if not await _wait(0.34):
			return
	await _wait(0.7)
	await _recover(0.9)

func _strike_later(pos: Vector2, r: float, delay: float, dmg: float) -> void:
	await get_tree().create_timer(delay, false).timeout
	if not is_inside_tree() or dead:
		return
	_hurt_circle(pos, r, dmg, 300.0, true)
	Fx.ring(pos, Color(0.7, 0.85, 1.0), r * 1.2, 0.3, 6.0)
	Fx.burst(pos + Vector2(0, -20), Color(0.75, 0.9, 1.0), 16, 300.0, 3.0, 0.35)
	Fx.flash(Color(0.8, 0.9, 1.0), 0.06, 0.12)
	Audio.play("hit_crit", 1.0, -6.0)

func _atk_charge() -> void:
	var t := _target()
	if t == null:
		return
	_face_to(t)
	var dirv := (t.global_position - global_position).normalized()
	var end := _clamp_arena(global_position + dirv * 950.0, 50.0)
	tele.add_line(global_position, end, 120.0, 1.0, Color(1.0, 0.3, 0.2))
	visual.charge_t = 1.0
	if not await _wait(1.0):
		return
	visual.charge_t = 0.0
	Audio.play("dash", 0.7, 0.0)
	var vec := dirv * 1050.0
	await _dash(vec, 0.9, 85.0, _dmg(1.4))
	Fx.shake(8.0, 0.3)
	await _recover(1.6)

func _atk_ground_pound() -> void:
	var c := global_position
	tele.add_circle(c, 240.0, 0.95, Color(1.0, 0.3, 0.2))
	visual.charge_t = 1.0
	if not await _wait(0.95):
		return
	visual.charge_t = 0.0
	_hurt_circle(c, 240.0, _dmg(1.3), 420.0, true)
	Fx.shake(11.0, 0.4)
	Fx.ring(c, Color(1.0, 0.5, 0.3), 260.0, 0.4, 8.0)
	Fx.burst(c, Color(0.9, 0.5, 0.3), 26, 400.0, 3.5, 0.5)
	Audio.play("hit_heavy", 0.6, 0.0)
	await _recover(1.0)

# ------------------------------------------------------------- obrażenia i fazy ---

func apply_hit(info: Dictionary) -> bool:
	if dead or _invuln or mode == "dying" or mode == "intro":
		return false
	var inf := info
	if _vuln_t > 0.0:
		inf = info.duplicate()
		inf["damage"] = float(info.get("damage", 0.0)) * (1.0 + float(bdata.get("vuln_bonus", 0.25)))
	inf = inf.duplicate()
	inf["kb"] = Vector2.ZERO  # boss się nie przesuwa
	var ok := super.apply_hit(inf)
	if not dead and mode != "dying":
		_check_phase()
	return ok

func _stagger(_time: float, _kb: Vector2) -> void:
	pass

func _check_phase() -> void:
	var k := health / maxf(1.0, max_health)
	var next := _phase_i
	var phs := _phases()
	for i in phs.size():
		if k <= float(phs[i]["at"]):
			next = i
	if next > _phase_i and mode != "transition":
		_transition(next)

func _transition(next: int) -> void:
	var prev_mode := mode
	mode = "transition"
	_abort = true
	_invuln = true
	tele.clear()
	_beam_active = false
	while _busy:
		await get_tree().process_frame
	_abort = false
	visual.position.y = 0.0
	visual.modulate.a = 1.0
	_phase_i = next
	phase = next + 1
	var pd := _phase_data()
	var label := String(pd.get("name", "FAZA %d" % phase))
	Audio.play("roar", 0.55, 3.0)
	Fx.shake(14.0, 0.9)
	Fx.flash(Color(1.0, 0.4, 0.6), 0.3, 0.5)
	Fx.ring(global_position, Color(1.0, 0.4, 0.6), 420.0, 0.7, 9.0)
	Fx.burst(global_position + Vector2(0, -30), Color(1.0, 0.4, 0.6), 36, 480.0, 4.0, 0.7)
	_hurt_circle(global_position, 260.0, _dmg(0.5), 520.0, true)
	phase_changed.emit(next, label)
	health = minf(max_health, health + max_health * 0.01)
	await get_tree().create_timer(1.6, false).timeout
	if not is_inside_tree() or dead:
		return
	var adds := int(pd.get("adds", 0))
	if adds > 0:
		_busy = true
		mode = "attack"
		await _atk_summon()
		_busy = false
	_invuln = false
	mode = "idle"
	_cd = 0.8

# ----------------------------------------------------------------------- śmierć ---

func _die(info: Dictionary = {}) -> void:
	if dead or mode == "dying":
		return
	mode = "dying"
	_invuln = true
	_abort = true
	tele.clear()
	_beam_active = false
	health = 1.0
	hitbox.stop()
	_run_death(info)

func _run_death(info: Dictionary) -> void:
	while _busy:
		await get_tree().process_frame
	visual.position.y = 0.0
	visual.modulate.a = 1.0
	visual.charge_t = 0.0
	visual.remote_spin = false
	velocity = Vector2.ZERO
	Audio.stop_music()
	Fx.hitstop(0.3)
	Fx.shake(14.0, 2.0)
	Audio.play("roar", 0.5, 2.0)
	for i in 10:
		Fx.burst(global_position + Vector2(randf_range(-60, 60), randf_range(-100, -10)), Color(1.0, 0.5, 0.8), 18, 360.0, 3.5, 0.6)
		Fx.flash(Color(1, 0.8, 1), 0.08, 0.15)
		Audio.play("hit_heavy", randf_range(0.5, 0.9), -4.0)
		await get_tree().create_timer(0.18, false).timeout
	dead = true
	health = 0.0
	visual.die()
	hurtbox.set_vulnerable(false)
	mode = "dead"
	Fx.shake(18.0, 0.8)
	Fx.burst(global_position + Vector2(0, -30), Color(1.0, 0.8, 0.9), 50, 600.0, 4.0, 0.9)
	await get_tree().create_timer(1.0, false).timeout
	var lines: Array = bdata.get("death", [])
	if not lines.is_empty():
		var d := UiDialog.new()
		d.setup(lines, Color(0.85, 0.35, 0.9))
		Flow.open_dialog(d)
		await d.on_close
	_grant_rewards(info)
	died.emit(self)
	death_finished.emit()
	await get_tree().create_timer(1.5, false).timeout
	queue_free()

func _grant_rewards(info: Dictionary) -> void:
	var src = info.get("source")
	GameState.add_xp(xp_value)
	GameState.run_add("kills", 1)
	var reward: Dictionary = bdata.get("reward", {})
	var lines := SecretDB.grant({"items": reward.get("items", {}), "gold": int(reward.get("gold", 0)) + gold_value, "diff_loot": (1.0 + float(GameState.diff_data()["loot"])) if boss_id.begins_with("cavebos_") else 0.0})
	GameState.toast.emit("Nagroda za bossa: " + ", ".join(lines), Color(1.0, 0.85, 0.35))
	GameState.profile["bosses"]["killed"] = GameState.profile["bosses"].get("killed", [])
	if boss_id not in GameState.profile["bosses"]["killed"]:
		GameState.profile["bosses"]["killed"].append(boss_id)
	GameState.profile["stats"]["bosses"] = int(GameState.profile["stats"].get("bosses", 0)) + 1
	GameState.save_game()
	Audio.play("levelup", 0.8, -2.0)

func _st_dead(_delta: float) -> void:
	pass
