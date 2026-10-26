class_name Pet
extends Node2D
## Towarzysz gracza: podąża za właścicielem (bez kolizji), atakuje wrogów zależnie od roli.
## Nie atakuje sojuszników; nie blokuje ruchu (brak ciała fizycznego).

var owner_player: Node2D = null
var pet_id := "kurczaczek"
var data: Dictionary = {}
var visual: CreatureVisual
var _cd := 0.5
var _target: Node2D = null
var _bob := 0.0
var _attack_t := 0.0
var _heal_cd := 2.0
var _dash_t := 0.0
var _dash_vec := Vector2.ZERO
var hp := 60.0
var max_hp := 60.0
var state := 0
var dying := false
## Serwer dedykowany: dane gracza zamiast globalnego GameState; duch (ghost) tylko rysuje się według migawek.
signal hp_changed(key: String, hp: float)
signal fell(key: String)
var server_peer := 0
var s_level := 1
var s_strength := 1.0
var s_gear := ""
var s_hp := -1.0
var ghost := false
var net_id := ""

func _level() -> int:
	return s_level if (server_peer != 0 or ghost) else GameState.player_level()

func _gear() -> String:
	return s_gear if (server_peer != 0 or ghost) else GameState.pet_gear(pet_id)

func setup(owner_node: Node2D, id: String) -> void:
	owner_player = owner_node
	pet_id = id
	data = PetDB.get_data(id)

func _ready() -> void:
	add_to_group("pets")
	z_index = 3
	visual = CreatureVisual.new()
	visual.configure(String(data.get("species", "kwoka")), data.get("pal", {}), float(data.get("scale", 0.5)))
	visual.idle_seed = randf() * 3.0
	add_child(visual)
	_refresh_aura()
	if server_peer == 0 and not ghost:
		GameState.pets_changed.connect(_refresh_aura)
	max_hp = (float(data.get("hp", 40.0)) + 8.0 * float(_level())) * (1.0 + _bonus("pet_hp"))
	if server_peer != 0 or ghost:
		hp = maxf(1.0, minf(s_hp if s_hp >= 0.0 else max_hp, max_hp))
	else:
		hp = maxf(1.0, GameState.support_hp("pet", max_hp))
	if not ghost:
		SupportHp.attach(self, 14.0)
	if owner_player and is_instance_valid(owner_player):
		global_position = owner_player.global_position + Vector2(-40, 10)
	if ghost:
		set_physics_process(false)

## Wyposażenie peta o wysokiej rzadkości daje aurę: hiperekstralegendarne — ogromne złote słońce.
func _refresh_aura() -> void:
	if visual == null:
		return
	var gid := _gear()
	var rar := ItemDB.rarity_of(gid) if gid != "" else ""
	var g := {}
	if rar == "hiperextralegendarny":
		g = {"aura": "gold_flame", "aura_radius": 120.0}
	elif rar == "hiperlegendarny":
		g = {"aura": "purple_flame", "aura_radius": 70.0}
	visual.set_gear(g)

func _draw() -> void:
	if not dying:
		SupportHp.draw_bar(self, hp, max_hp, Vector2(0, -52.0 * float(data.get("scale", 0.5)) - 10.0))

func apply_hit(info: Dictionary) -> bool:
	if dying:
		return false
	var dmg := maxf(1.0, float(info.get("damage", 0.0)) * 0.7)
	hp -= dmg
	if server_peer != 0:
		hp_changed.emit("pet", maxf(hp, 0.0))
	else:
		GameState.set_support_hp("pet", maxf(hp, 0.0))
	visual.flash(1.0)
	Fx.damage_number(global_position + Vector2(0, -40), dmg, Color(1.0, 0.55, 0.45))
	Audio.play("hit", randf_range(1.1, 1.3), -9.0)
	queue_redraw()
	if hp <= 0.0:
		_die()
	return true

func _die() -> void:
	dying = true
	state = Player.S.DEAD
	visual.die()
	var hb: Node = get_node_or_null("Hurtbox")
	if hb:
		hb.set_deferred("monitorable", false)
	if server_peer != 0:
		fell.emit("pet")
		get_tree().create_timer(0.8).timeout.connect(queue_free)
		return
	GameState.mark_fallen("pet")
	GameState.clear_support_hp("pet")
	GameState.toast.emit("%s poległ — karetka już jedzie. Leży w szpitalu — wróci za 5 minut." % String(data.get("name", "Pupil")), Color(1.0, 0.6, 0.5))
	Ambulance.dispatch(get_parent(), global_position, func():
		Fx.burst(global_position + Vector2(0, -16), Color(1, 1, 1), 10, 180.0, 3.0, 0.4)
		queue_free())

# ----------------------------------------------------------- statystyki z wyposażenia ---

func _bonus(key: String) -> float:
	var gear := _gear()
	if gear == "":
		return 0.0
	return float(ItemDB.stats_of(gear).get(key, 0.0))

func _dmg() -> float:
	var st := s_strength if (server_peer != 0 or ghost) else GameState.stat("strength")
	return float(data.get("dmg", 5.0)) * (1.0 + _bonus("pet_dmg")) * maxf(1.0, st * 0.8)

func _cooldown() -> float:
	var base := float(data.get("cd", 1.2)) / (1.0 + _bonus("pet_speed"))
	if GameState.has_run() and float(GameState.run.get("pet_frenzy", 0.0)) > 0.0:
		base *= 0.5
	return base

func _range() -> float:
	return float(data.get("range", 300.0)) * (1.0 + _bonus("pet_range"))

# ------------------------------------------------------------------ pętla ---

func _physics_process(delta: float) -> void:
	if dying:
		return
	if owner_player == null or not is_instance_valid(owner_player):
		queue_free()
		return
	_bob += delta
	_cd -= delta
	_attack_t = maxf(0.0, _attack_t - delta)
	var topdown := GameState.is_topdown()
	var facing := 1.0
	if "facing" in owner_player:
		facing = float(owner_player.get("facing"))
	var home := owner_player.global_position + Vector2(-46.0 * facing, 14.0 if topdown else 0.0)
	if not topdown:
		home.y = owner_player.global_position.y
	var speed := float(data.get("speed", 220.0))
	var moving := false
	if _dash_t > 0.0:
		_dash_t -= delta
		global_position += _dash_vec * delta
		moving = true
	else:
		_target = _find_target()
		var goal := home
		if _target != null and String(data.get("role", "")) == "hunter":
			goal = _target.global_position + Vector2(-30.0 * signf(_target.global_position.x - global_position.x), 0.0)
		var to_goal := goal - global_position
		if to_goal.length() > 900.0:
			global_position = home
		elif to_goal.length() > 14.0:
			var step := to_goal.normalized() * minf(speed * (1.4 if to_goal.length() > 220.0 else 1.0), to_goal.length() / maxf(delta, 0.001)) * delta
			global_position += step
			moving = true
		if not topdown:
			global_position.y = owner_player.global_position.y
	_role_tick(delta)
	# wizualizacja
	visual.moving = moving
	visual.grounded = true
	var face_dir := facing
	if _target != null and is_instance_valid(_target):
		face_dir = signf(_target.global_position.x - global_position.x)
	elif absf(owner_player.global_position.x - global_position.x) > 8.0:
		face_dir = signf(owner_player.global_position.x - global_position.x)
	visual.set_facing(face_dir if face_dir != 0.0 else 1.0)
	visual.arm = clampf(_attack_t / 0.25, 0.0, 1.0)
	visual.lean = 0.25 if moving else 0.0
	if GameState.has_run():
		for k in ["pet_frenzy", "pet_guard"]:
			if GameState.run.has(k):
				GameState.run[k] = maxf(0.0, float(GameState.run[k]) - delta)

func _find_target() -> Node2D:
	var best: Node2D = null
	var bd := _range()
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or not (e is Node2D):
			continue
		if e.has_method("is_dead") and e.is_dead():
			continue
		if "is_duel" in e and bool(e.get("is_duel")):
			continue   # pojedynek: towarzysze nie wtrącają się
		var d: float = e.global_position.distance_to(global_position) if GameState.is_topdown() else absf(e.global_position.x - global_position.x)
		if d < bd:
			bd = d
			best = e
	return best

func _role_tick(delta: float) -> void:
	match String(data.get("role", "")):
		"shooter":
			if _target != null and _cd <= 0.0:
				_shoot(_target)
		"looter":
			_magnet()
			if _target != null and _cd <= 0.0:
				_peck(_target)
		"hunter":
			if _target != null and _cd <= 0.0:
				_pounce(_target)
		"healer":
			_heal_cd -= delta
			if _heal_cd <= 0.0:
				_heal_cd = _cooldown()
				_heal_owner()
		"tank":
			if GameState.has_run():
				var near := owner_player.global_position.distance_to(global_position) < 140.0
				GameState.run["pet_dr"] = float(data.get("dr", 0.08)) if near else 0.0
			if _target != null and _cd <= 0.0:
				_peck(_target)

func _shoot(t: Node2D) -> void:
	_cd = _cooldown()
	_attack_t = 0.25
	var aim := (t.global_position - global_position).normalized()
	var proj := (preload("res://scenes/projectile.tscn") as PackedScene).instantiate() as EggProjectile
	proj.setup(owner_player, "jajko", {
		"damage": _dmg(), "radius": 20.0, "speed": 640.0, "gravity": 0.0, "stun": 0.0,
		"dir": signf(aim.x) if aim.x != 0.0 else 1.0, "aim": aim, "col": Color(0.95, 0.9, 0.7), "team": "player",
	}, 0.0)
	get_parent().add_child(proj)
	proj.global_position = global_position + aim * 18.0 + Vector2(0.0, -14.0)
	proj.velocity = aim * 640.0
	if not GameState.is_topdown():
		proj.velocity.y = aim.y * 640.0
	Audio.play("throw", 1.6, -14.0)

func _peck(t: Node2D) -> void:
	_cd = _cooldown()
	_attack_t = 0.25
	if t.global_position.distance_to(global_position) > 90.0:
		return
	_hit(t, _dmg())

func _pounce(t: Node2D) -> void:
	_cd = _cooldown()
	_attack_t = 0.25
	var d := t.global_position - global_position
	if d.length() > 70.0:
		_dash_vec = d.normalized() * 520.0
		_dash_t = minf(0.22, (d.length() - 40.0) / 520.0)
	_hit(t, _dmg())
	Audio.play("punch", 1.4, -12.0)

func _hit(t: Node2D, dmg: float) -> void:
	var hb: Hurtbox = t.get_node_or_null("Hurtbox")
	if hb == null:
		return
	var kb := (t.global_position - global_position).normalized() * 120.0
	hb.take_hit({
		"damage": dmg, "kb": kb, "hitstun": 0.12, "launch": false, "crit": false,
		"team": "player", "source": owner_player, "kind": "pet",
	})
	Fx.burst(t.global_position + Vector2(0, -26), Color(1, 0.9, 0.6), 5, 140.0, 2.0, 0.2)

func _heal_owner() -> void:
	if owner_player == null or not owner_player.has_method("heal"):
		return
	var hp_now := float(owner_player.get("hp"))
	var hp_max := float(owner_player.get("max_hp"))
	if hp_now >= hp_max or hp_now <= 0.0:
		return
	var amount := float(data.get("heal", 12.0)) * (1.0 + _bonus("pet_dmg"))
	if GameState.has_run() and float(GameState.run.get("pet_guard", 0.0)) > 0.0:
		amount *= 1.8
	owner_player.heal(amount)
	_attack_t = 0.25
	Fx.popup(owner_player.global_position + Vector2(0, -70), "+%d" % int(amount), Color(0.7, 1.0, 0.85))
	Fx.burst(owner_player.global_position + Vector2(0, -30), Color(0.7, 1.0, 0.9), 8, 120.0, 2.0, 0.4)

func _magnet() -> void:
	var r := float(data.get("magnet", 400.0))
	for p in get_tree().get_nodes_in_group("pickup"):
		if not is_instance_valid(p) or not (p is Node2D):
			continue
		var d: Vector2 = owner_player.global_position - (p as Node2D).global_position
		if d.length() < r and d.length() > 20.0:
			(p as Node2D).global_position += d.normalized() * 260.0 * get_physics_process_delta_time()
