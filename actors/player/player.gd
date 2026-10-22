class_name Player
extends CharacterBody2D
## Kurczak. Ruch, skok, combo trójpuderne, atak ciężki, unik, blok z parry,
## rzut przedmiotem i furia (atak specjalny). Wszystko w jednym automacie stanów.

signal health_changed(hp: float, max_hp: float)
signal energy_changed(en: float, max_en: float)
signal stamina_changed(st: float, max_st: float)
signal skills_changed
signal fury_changed(v: float)
signal combo_changed(n: int)
signal died
signal state_changed(name: String)

enum S { IDLE, RUN, JUMP, FALL, ATTACK, AIR_ATTACK, DASH, BLOCK, HURT, THROW, SPECIAL, VICTORY, DEAD, DOWNED, INTRO }

const GRAVITY := 1900.0
const FALL_GRAVITY := 2500.0
const MAX_FALL := 980.0
const JUMP_V := -700.0
const RUN_BASE := 252.0
const AIR_ACCEL := 1500.0
const GROUND_ACCEL := 2600.0
const GROUND_FRICTION := 3000.0
const COYOTE := 0.10
const JUMP_BUFFER := 0.14
const DASH_SPEED := 600.0
const DASH_TIME := 0.19
const DASH_IFRAMES := 0.26
const DASH_CD := 0.65
const COMBO_WINDOW := 0.34
const HURT_IFRAMES := 0.55
const BLOCK_REDUCTION := 0.72
const PARRY_WINDOW := 0.2
const INVULN_AFTER_HIT := 0.45
const COMBO_DECAY := 1.7

const SPRINT_MULT := 1.55
const SPRINT_DRAIN := 26.0
const STAMINA_REGEN := 24.0
const JUMP_STAM := 10.0
const DJUMP_STAM := 24.0

const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")

const LIGHT := [
	{"name": "Dziób", "wind": 0.075, "active": 0.085, "rec": 0.15, "dmg": 9.0, "kb": 150.0, "stun": 0.24, "range": 46.0, "lunge": 120.0, "launch": false, "s": 1.0},
	{"name": "Kolano", "wind": 0.085, "active": 0.095, "rec": 0.17, "dmg": 11.0, "kb": 185.0, "stun": 0.28, "range": 50.0, "lunge": 140.0, "launch": false, "s": 1.05},
	{"name": "Wir", "wind": 0.12, "active": 0.13, "rec": 0.29, "dmg": 16.0, "kb": 330.0, "stun": 0.4, "range": 58.0, "lunge": 190.0, "launch": true, "s": 1.15},
]
const HEAVY := {"name": "Rozszczyp", "wind": 0.26, "active": 0.13, "rec": 0.34, "dmg": 26.0, "kb": 300.0, "stun": 0.5, "range": 62.0, "lunge": 90.0, "launch": true, "s": 1.25}
const AIR := {"name": "Atak w powietrzu", "wind": 0.055, "active": 0.16, "rec": 0.2, "dmg": 13.0, "kb": 200.0, "stun": 0.3, "range": 52.0, "lunge": 60.0, "launch": false, "s": 1.0}

@onready var visual: CreatureVisual = $Visual
@onready var hitbox: Hitbox = $Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox

var state: int = S.IDLE
var state_t := 0.0
var facing := 1.0
var bounds_min := -100000.0
var bounds_max := 100000.0
var bounds_top := -100000.0
var bounds_bottom := 100000.0
var floor_y := 100000.0
var is_boss_intro := false
var _dash_dir := Vector2.ZERO
var _td_speed := 0.0

var hp := 100.0
var max_hp := 100.0
var energy := 100.0
var max_energy := 100.0
var stamina := 100.0
var max_stamina := 100.0
var stamina_delay := 0.0
var fury := 0.0
var fury_ready_off := 0.0
var skill_slots: Array = []
var skill_cd: Array = []

var invuln := 0.0
var dash_cd := 0.0
var sprinting := false
var coyote := 0.0
var air_jumps := 0
var combo := 0
var combo_timer := 0.0
var attack_phase := 0
var attack_t := 0.0
var attack_fired := false
var attack_data: Dictionary = {}
var buffered := ""
var block_hold := false
var parry_t := 0.0
var energy_delay := 0.0
var charge_t := 0.0
var special_data: Dictionary = {}
var special_tick := 0.0
var drop_timer := 0.0
var hit_count_in_attack := 0
var spawn_invuln := 1.0
var can_act := true
var grab_lock := 0.0
var berserk_t := 0.0
var shadow_t := 0.0
var stun_t := 0.0
var barrier: Node2D = null
var _berserk_on := false
var _shadow_on := false
var _berserk_atk_cd := 0.0
var _base_atk_mult := 1.0

# bufor wejścia: Dictionary akcja -> czas do wykonania
var _input_buf: Dictionary = {}

func _ready() -> void:
	add_to_group("player")
	hurtbox.team = "player"
	hitbox.area_entered.connect(_on_hitbox_area)
	hitbox.hit_landed.connect(_on_weapon_hit)
	character_id = String(GameState.run.get("character", "kurczak"))
	_apply_character()
	GameState.stats_changed.connect(_on_stats_changed)
	GameState.xp_changed.connect(func(_a, _b, _c): pass)
	max_hp = GameState.stat("max_health")
	max_energy = GameState.stat("max_energy")
	if max_hp <= 0.0:
		max_hp = CharacterDB.get_data(character_id)["base"]["health"]
		max_energy = CharacterDB.get_data(character_id)["base"]["energy"]
	if GameState.has_run():
		hp = clampf(float(GameState.run.get("health", max_hp)), 1.0, max_hp)
		energy = clampf(float(GameState.run.get("energy", max_energy)), 0.0, max_energy)
	else:
		hp = max_hp
		energy = max_energy
	health_changed.emit(hp, max_hp)
	energy_changed.emit(energy, max_energy)
	stamina_changed.emit(stamina, max_stamina)
	skills_changed.emit()
	fury_changed.emit(fury)
	set_state(S.INTRO)

var character_id := "kurczak"

func _apply_character() -> void:
	var data := CharacterDB.get_data(character_id)
	visual.configure(character_id, data["pal"], 1.0)
	special_data = CharacterDB.SPECIALS.get(String(data.get("special", "")), CharacterDB.SPECIALS["kurzacyjny_pogrom"])
	skill_slots = GameState.skill_slots().duplicate()
	skill_cd = []
	for i in skill_slots.size():
		skill_cd.append(0.0)
	var shape := $Body.shape as RectangleShape2D
	if shape:
		shape.size = Vector2(32, 50)

func _on_stats_changed(_s: Dictionary) -> void:
	var prev_max := max_hp
	max_hp = GameState.stat("max_health")
	max_energy = GameState.stat("max_energy")
	if max_hp > prev_max:
		hp += max_hp - prev_max
	hp = clampf(hp, 0.0, max_hp)
	energy = clampf(energy, 0.0, max_energy)
	stamina = clampf(stamina, 0.0, max_stamina)
	health_changed.emit(hp, max_hp)
	energy_changed.emit(energy, max_energy)
	stamina_changed.emit(stamina, max_stamina)

# ------------------------------------------------------------------- bufor ---

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if not can_act:
		return
	var map := {
		"light_attack": "light", "heavy_attack": "heavy", "dash": "dash",
		"jump": "jump", "special": "special", "throw_item": "throw", "block": "block",
	}
	for a in map:
		if event.is_action_pressed(a):
			_input_buf[map[a]] = 0.16
	for i in range(6):
		if event.is_action_pressed("skill_%d" % (i + 1)):
			_try_skill(i)
			return

func _take(action: String) -> bool:
	if _input_buf.has(action) and float(_input_buf[action]) > 0.0:
		_input_buf[action] = 0.0
		return true
	return false

func _clear_buf() -> void:
	_input_buf.clear()

# ------------------------------------------------------------------ stany ----

func set_state(s: int) -> void:
	state = s
	state_t = 0.0
	match s:
		S.ATTACK, S.AIR_ATTACK:
			attack_t = 0.0
			attack_fired = false
			hit_count_in_attack = 0
		S.DASH:
			dash_cd = DASH_CD
			invuln = maxf(invuln, DASH_IFRAMES)
		S.BLOCK:
			parry_t = PARRY_WINDOW
	visual.arm = 0.0
	visual.arm_back = 0.0
	visual.crouch = 0.0
	visual.charge_t = 0.0
	state_changed.emit(_state_name(s))

func _state_name(s: int) -> String:
	match s:
		S.IDLE: return "idle"
		S.RUN: return "run"
		S.JUMP: return "jump"
		S.FALL: return "fall"
		S.ATTACK: return "attack"
		S.AIR_ATTACK: return "air_attack"
		S.DASH: return "dash"
		S.BLOCK: return "block"
		S.HURT: return "hurt"
		S.THROW: return "throw"
		S.SPECIAL: return "special"
		S.VICTORY: return "victory"
		S.DEAD: return "dead"
		S.DOWNED: return "downed"
		S.INTRO: return "intro"
	return "?"

# -------------------------------------------------------------- pętla główna ---

func _physics_process(delta: float) -> void:
	state_t += delta
	for k in _input_buf.keys():
		_input_buf[k] = float(_input_buf[k]) - delta
	invuln = maxf(0.0, invuln - delta)
	dash_cd = maxf(0.0, dash_cd - delta)
	for i in range(skill_cd.size()):
		skill_cd[i] = maxf(0.0, float(skill_cd[i]) - delta)
	spawn_invuln = maxf(0.0, spawn_invuln - delta)
	grab_lock = maxf(0.0, grab_lock - delta)
	berserk_t = maxf(0.0, berserk_t - delta)
	if berserk_t <= 0.0 and _berserk_on:
		_end_berserk()
	stun_t = maxf(0.0, stun_t - delta)
	shadow_t = maxf(0.0, shadow_t - delta)
	if shadow_t <= 0.0 and _shadow_on:
		_set_shadow(false)
	_tick_buffs(delta)
	combo_timer = maxf(0.0, combo_timer - delta)
	if combo_timer <= 0.0 and combo > 0:
		combo = 0
		combo_changed.emit(0)
	if Input.is_action_just_pressed("pause"):
		Flow.toggle_pause()
		return
	if combo_timer > 0.0:
		combo_timer = maxf(0.0, combo_timer - COMBO_DECAY * delta)

	if not GameState.is_topdown():
		_apply_gravity(delta)

	match state:
		S.INTRO: _st_intro(delta)
		S.IDLE: _st_ground(delta, false)
		S.RUN: _st_ground(delta, true)
		S.JUMP: _st_air(delta)
		S.FALL: _st_air(delta)
		S.ATTACK: _st_attack(delta)
		S.AIR_ATTACK: _st_air_attack(delta)
		S.DASH: _st_dash(delta)
		S.BLOCK: _st_block(delta)
		S.HURT: _st_hurt(delta)
		S.DOWNED: _st_downed(delta)
		S.THROW: _st_throw(delta)
		S.SPECIAL: _st_special(delta)
		S.VICTORY: _st_victory(delta)
		S.DEAD: _st_dead(delta)

	_enforce_bounds()
	_update_regen(delta)
	_update_stamina(delta)
	move_and_slide()
	_update_visual(delta)

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		var g := GRAVITY
		if velocity.y > 0.0 or Input.is_action_pressed("move_down"):
			g = FALL_GRAVITY
		velocity.y = minf(velocity.y + g * delta, MAX_FALL)
	else:
		if velocity.y > 0.0:
			_on_land()
		velocity.y = 0.0
		coyote = COYOTE
	if is_on_floor():
		coyote = COYOTE
	else:
		coyote = maxf(0.0, coyote - delta)

func _grounded() -> bool:
	if GameState.is_topdown():
		return true
	return is_on_floor()

func _enforce_bounds() -> void:
	if position.x < bounds_min:
		position.x = bounds_min
		velocity.x = maxf(velocity.x, 0.0)
	elif position.x > bounds_max:
		position.x = bounds_max
		velocity.x = minf(velocity.x, 0.0)
	if GameState.is_topdown():
		if position.y < bounds_top:
			position.y = bounds_top
			velocity.y = maxf(velocity.y, 0.0)
		elif position.y > bounds_bottom:
			position.y = bounds_bottom
			velocity.y = minf(velocity.y, 0.0)
	visual.set_facing(facing)

func _on_land() -> void:
	Fx.burst(Vector2(position.x, position.y), Color(0.85, 0.8, 0.7, 0.8), 5, 110.0, 2.0, 0.25)
	Audio.play("land", randf_range(0.95, 1.08), -8.0)
	air_jumps = 0
	if state == S.JUMP or state == S.FALL or state == S.AIR_ATTACK:
		if state == S.AIR_ATTACK:
			set_state(S.IDLE)
		else:
			set_state(S.IDLE)

# ---------------------------------------------------------------- wejście ---

func _input_x() -> float:
	if stun_t > 0.0:
		return 0.0
	if berserk_t > 0.0:
		return _berserk_dir_x()
	return Input.get_axis("move_left", "move_right")

func _input_y() -> float:
	return Input.get_axis("move_up", "move_down")

func _try_common_actions() -> bool:
	if stun_t > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, GROUND_FRICTION * get_physics_process_delta_time())
		return false
	if berserk_t > 0.0:
		_berserk_tick()
		return false
	# specjalny (furia)
	if _take("special") and fury >= 1.0 and can_act:
		_start_special()
		return true
	if _take("special"):
		Audio.play("deny", 1.3, -16.0)
	# ciężki atak
	if _take("heavy") and can_act:
		_start_attack(_weap_attacks()["heavy"], 3, _grounded())
		return true
	# lekki atak
	if _take("light") and can_act:
		if _grounded():
			_start_attack(_weap_attacks()["light"][0], 0, true)
		else:
			_start_attack(_weap_attacks()["air"], 3, false)
		return true
	# unik
	if _take("dash") and dash_cd <= 0.0 and can_act:
		_start_dash()
		return true
	# rzut
	if _take("throw") and can_act:
		_start_throw()
		return true
	# skok (podwójny w powietrzu) — wyłączony w widoku z góry
	if _take("jump") and not GameState.is_topdown():
		if is_on_floor() or coyote > 0.0:
			_do_jump(false)
			return true
		if air_jumps < max_air_jumps() and stamina >= DJUMP_STAM:
			air_jumps += 1
			_spend_stamina(DJUMP_STAM)
			_do_jump(true)
			return true
	return false

func max_air_jumps() -> int:
	return 1

# ------------------------------------------------------------- stany ruchu ---

func _st_intro(_delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 2000.0 * get_physics_process_delta_time())
	if state_t > 0.35:
		set_state(S.IDLE)

func _st_ground(delta: float, running: bool) -> void:
	var ix := _input_x()
	if GameState.is_topdown():
		_td_move(delta, ix)
		visual.moving = velocity.length() > 24.0
		if _try_common_actions():
			return
		if Input.is_action_pressed("block") and can_act:
			set_state(S.BLOCK)
			return
		set_state(S.RUN if absf(ix) > 0.15 or absf(_input_y()) > 0.15 else S.IDLE)
		return
	sprinting = is_on_floor() and absf(ix) > 0.15 and Input.is_action_pressed("sprint") and stamina > 0.0
	var spd := RUN_BASE * GameState.stat("speed") * (SPRINT_MULT if sprinting else 1.0)
	if absf(ix) > 0.15:
		facing = signf(ix)
		velocity.x = move_toward(velocity.x, ix * spd, GROUND_ACCEL * delta)
		running = true
	else:
		velocity.x = move_toward(velocity.x, 0.0, GROUND_FRICTION * delta)
		running = false
	visual.moving = absf(velocity.x) > 24.0
	if _try_common_actions():
		return
	# blok
	if Input.is_action_pressed("block") and can_act:
		set_state(S.BLOCK)
		return
	if not is_on_floor():
		set_state(S.FALL)
		return
	set_state(S.RUN if running else S.IDLE)

func _td_move(delta: float, ix: float) -> void:
	var iy := _input_y()
	sprinting = (absf(ix) > 0.15 or absf(iy) > 0.15) and Input.is_action_pressed("sprint") and stamina > 0.0
	var spd := RUN_BASE * GameState.stat("speed") * (SPRINT_MULT if sprinting else 1.0)
	var dir := Vector2(ix, iy)
	if dir.length() > 1.0:
		dir = dir.normalized()
	var target := dir * spd
	velocity.x = move_toward(velocity.x, target.x, GROUND_ACCEL * delta)
	velocity.y = move_toward(velocity.y, target.y, GROUND_ACCEL * delta)
	if absf(ix) > 0.15:
		facing = signf(ix)

func _do_jump(double: bool) -> void:
	coyote = 0.0
	velocity.y = JUMP_V * (0.88 if double else 1.0)
	if double:
		Fx.ring(Vector2(position.x, position.y - 10.0), Color(0.9, 0.95, 1.0), 30.0, 0.25, 3.0)
	set_state(S.JUMP)
	Audio.play("jump", randf_range(0.97, 1.05) * (1.15 if double else 1.0), -6.0)
	Fx.burst(Vector2(position.x, position.y), Color(0.9, 0.85, 0.75, 0.7), 6, 130.0, 2.0, 0.25)

func _st_air(delta: float) -> void:
	sprinting = false
	var ix := _input_x()
	velocity.x = move_toward(velocity.x, ix * RUN_BASE * GameState.stat("speed") * 1.05, AIR_ACCEL * delta)
	if absf(ix) > 0.15:
		facing = signf(ix)
	visual.moving = false
	if _try_common_actions():
		return
	if velocity.y > 0.0 and state == S.JUMP:
		set_state(S.FALL)
	if is_on_floor():
		set_state(S.IDLE)

# ---------------------------------------------------------------- ataki -----

func _weap_attacks() -> Dictionary:
	return ItemDB.weapon_attacks(String(GameState.equipped().get("weapon", "kolt")))

func _start_attack(data: Dictionary, combo_index: int, grounded: bool) -> void:
	attack_data = data
	attack_phase = combo_index
	_clear_buf()
	if grounded:
		# przyciągnij twarz do najbliższego wroga
		_snap_to_enemy(150.0)
		velocity.x = facing * float(data["lunge"])
		set_state(S.ATTACK)
		var weapon := String(GameState.equipped().get("weapon", "kolt"))
		var tier := int(ItemDB.get_data(weapon).get("tier", 1))
		var lightish := float(data["dmg"]) < 20.0
		var snd := "swing" if lightish else "swing_heavy"
		if tier >= 3 and lightish:
			snd = "swing_weapon"
		elif tier >= 4:
			snd = "swing_heavy_weapon"
		Audio.play(snd, randf_range(0.95, 1.1), -6.0)
	else:
		velocity.y = minf(velocity.y, 30.0)
		set_state(S.AIR_ATTACK)
		Audio.play("swing", randf_range(1.05, 1.2), -8.0)

func _attack_timings() -> Vector3:
	return Vector3(float(attack_data["wind"]), float(attack_data["active"]), float(attack_data["rec"]))

func _st_attack(delta: float) -> void:
	var t := _attack_timings()
	_snap_to_enemy(210.0, true)
	velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	if GameState.is_topdown():
		velocity.y = move_toward(velocity.y, 0.0, 900.0 * delta)
	else:
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
	if state_t < t.x:
		visual.arm_back = clampf(state_t / t.x, 0.0, 1.0)
		if attack_data.has("s") and float(attack_data["s"]) > 1.2:
			visual.charge_t = clampf(state_t / t.x, 0.0, 1.0)
	elif not attack_fired:
		_fire_attack()
		attack_fired = true
	else:
		visual.arm_back = 0.0
		visual.arm = maxf(0.0, 1.0 - (state_t - t.x - t.y) / maxf(0.01, t.z))
	# łańcuchowanie
	if state_t > t.x * 0.6 and not attack_fired:
		if _take("light"):
			var wa := _weap_attacks()
			var li: int = mini(attack_phase + 1, wa["light"].size() - 1)
			_start_attack(wa["light"][li], li, true)
			return
		if _take("heavy"):
			_start_attack(_weap_attacks()["heavy"], 3, true)
			return
	if attack_fired and state_t >= t.x + t.y + t.z * 0.35:
		if _take("light"):
			var wa2 := _weap_attacks()
			var idx := 0 if attack_phase >= wa2["light"].size() - 1 else attack_phase + 1
			_start_attack(wa2["light"][idx], idx, true)
			return
		if _take("heavy"):
			_start_attack(_weap_attacks()["heavy"], 3, true)
			return
		if _take("dash") and dash_cd <= 0.0:
			_start_dash()
			return
	if state_t >= t.x + t.y + t.z:
		_clear_buf()
		set_state(S.IDLE)

func _st_air_attack(delta: float) -> void:
	var t := _attack_timings()
	velocity.x = move_toward(velocity.x, facing * 60.0, 500.0 * delta)
	velocity.y = minf(velocity.y + GRAVITY * 0.4 * delta, MAX_FALL)
	visual.arm_back = state_t < t.x
	visual.arm = state_t >= t.x and state_t < t.x + t.y + t.z
	if not attack_fired and state_t >= t.x:
		_fire_attack()
		attack_fired = true
	if state_t >= t.x + t.y + t.z:
		set_state(S.FALL if not is_on_floor() else S.IDLE)
	if is_on_floor() and state_t > t.x + t.y:
		set_state(S.IDLE)

func _fire_attack() -> void:
	var rng_range := float(attack_data["range"])
	var crit := randf() < clampf(GameState.stat("crit"), 0.0, 0.9)
	var dmg := float(attack_data["dmg"]) * GameState.stat("strength")
	if crit:
		dmg *= 1.75
	GameState.run_add("damage_dealt", dmg)
	var aim := _aim_dir()
	if GameState.is_topdown():
		hitbox.move_offset(aim.x * (rng_range * 0.42), aim.y * (rng_range * 0.42) - 2.0)
	else:
		hitbox.move_offset(facing * (rng_range * 0.42))
	hitbox.fire(float(attack_data["active"]) + 0.06, {
		"damage": dmg,
		"kb": (aim * float(attack_data["kb"])) if GameState.is_topdown() else Vector2(facing * float(attack_data["kb"]), -260.0 if bool(attack_data["launch"]) else -70.0),
		"hitstun": float(attack_data["stun"]),
		"launch": bool(attack_data["launch"]),
		"crit": crit,
		"team": "player",
		"source": self,
		"kind": "light" if float(attack_data["dmg"]) < 20.0 else "heavy",
		"air": state == S.AIR_ATTACK,
		"on_hit": ItemDB.weapon_on_hit(String(GameState.equipped().get("weapon", "kolt"))).duplicate(true),
	}, 8)
	visual.arm = 1.0
	var tip := global_position + ((aim * float(attack_data["range"]) * 0.85) if GameState.is_topdown() else Vector2(facing * float(attack_data["range"]) * 0.85, -34.0))
	Fx.slash(tip, facing, Color(1, 1, 1, 0.9) if not crit else Color(1.0, 0.85, 0.4, 0.95), 1.0 if float(attack_data["dmg"]) < 20.0 else 1.35)

func _on_hitbox_area(_a: Area2D) -> void:
	pass

func _on_weapon_hit(target: Node, info: Dictionary) -> void:
	var oh: Dictionary = info.get("on_hit", {})
	var t: Variant = target
	if oh.is_empty() or not is_instance_valid(t) or not t.has_method("apply_hit"):
		return
	var dmg := float(info.get("damage", 0.0))
	if float(oh.get("heal", 0.0)) > 0.0:
		hp = minf(max_hp, hp + float(oh["heal"]))
		GameState.run_set("health", hp)
		health_changed.emit(hp, max_hp)
		Fx.popup(global_position + Vector2(0, -84), "+%.0f" % float(oh["heal"]), Color(0.4, 1.0, 0.6))
	var tpos: Vector2 = t.global_position
	if bool(oh.get("splash", false)):
		_aoe_hit(tpos, 110.0, dmg * 0.5, 220.0, 0.3)
	if int(oh.get("chain", 0)) > 0:
		_chain_hit(t, dmg * float(oh["chain"]))
	if float(oh.get("bleed", 0.0)) > 0.0:
		var bleed := float(oh["bleed"])
		t.apply_hit({ "damage": bleed, "kb": Vector2.ZERO, "hitstun": 0.2, "launch": false, "crit": false, "team": "player", "source": self, "kind": "bleed", "no_hitstop": true })
		Fx.popup(tpos + Vector2(0, -34), "KRWAWI", Color(0.9, 0.3, 0.25))

func _aoe_hit(pos: Vector2, radius: float, dmg: float, kb: float, stun: float) -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or not (e is Node2D):
			continue
		if e == self:
			continue
		if e.has_method("is_dead") and e.is_dead():
			continue
		if not e.has_method("apply_hit"):
			continue
		if e.global_position.distance_to(pos) > radius:
			continue
		var dir: Vector2 = (e.global_position - pos).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2(facing, 0.0)
		e.apply_hit({
			"damage": dmg,
			"kb": Vector2(dir.x * kb, -kb * 0.6),
			"hitstun": stun,
			"launch": false,
			"crit": false,
			"team": "player",
			"source": self,
			"kind": "splash",
		})

func _chain_hit(target: Node, dmg: float, seen: Array = []) -> void:
	if seen.size() >= 2 or not is_instance_valid(target):
		return
	var tgt: Variant = target
	var best = null
	var best_d := 220.0
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or not (e is Node2D):
			continue
		if e == target or e == self or seen.has(e):
			continue
		if e.has_method("is_dead") and e.is_dead():
			continue
		if not e.has_method("apply_hit"):
			continue
		var d: float = e.global_position.distance_to(tgt.global_position)
		if d < best_d:
			best_d = d
			best = e
	if best == null:
		return
	var on_hit: Dictionary = ItemDB.weapon_on_hit(String(GameState.equipped().get("weapon", "kolt"))).duplicate(true)
	var dir := signf(best.global_position.x - tgt.global_position.x)
	if dir == 0.0:
		dir = facing
	best.apply_hit({
		"damage": dmg,
		"kb": Vector2(dir * 160.0, -120.0),
		"hitstun": 0.25,
		"launch": false,
		"crit": false,
		"team": "player",
		"source": self,
		"kind": "chain",
		"on_hit": on_hit,
	})
	seen.append(best)
	_chain_hit(best, dmg * 0.85, seen)

# ------------------------------------------------------------------ dash ----

func _start_dash() -> void:
	_clear_buf()
	var ix := _input_x()
	if absf(ix) > 0.15:
		facing = signf(ix)
	if GameState.is_topdown():
		var dir := Vector2(_input_x(), _input_y())
		if dir.length() < 0.2:
			dir = Vector2(facing, 0.0)
		_dash_dir = dir.normalized()
		velocity = _dash_dir * DASH_SPEED
	else:
		_dash_dir = Vector2(facing, 0.0)
		velocity.x = facing * DASH_SPEED
	set_state(S.DASH)
	Audio.play("dash", randf_range(0.95, 1.1), -8.0)
	Fx.burst(Vector2(position.x, position.y - 20), Color(0.9, 0.9, 0.95, 0.8), 8, 200.0, 2.5, 0.28)

func _st_dash(delta: float) -> void:
	if GameState.is_topdown():
		velocity = _dash_dir * DASH_SPEED * (1.0 - 0.35 * clampf(state_t / DASH_TIME, 0.0, 1.0))
	else:
		velocity.x = facing * DASH_SPEED * (1.0 - 0.35 * clampf(state_t / DASH_TIME, 0.0, 1.0))
	if randf() < 0.4:
		Fx.burst(Vector2(position.x - facing * 12.0, position.y - 22.0), Color(0.85, 0.85, 0.9, 0.5), 2, 60.0, 2.0, 0.2)
	if state_t >= DASH_TIME:
		_clear_buf()
		set_state(S.IDLE if _grounded() else S.FALL)

# ------------------------------------------------------------------ blok ----

func _st_block(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 2400.0 * delta)
	parry_t = maxf(0.0, parry_t - delta)
	visual.crouch = 0.85
	_snap_to_enemy(170.0, true)
	# wyjście z bloku
	if _take("light"):
		_start_attack(_weap_attacks()["light"][0], 0, true)
		return
	if _take("heavy"):
		_start_attack(_weap_attacks()["heavy"], 3, true)
		return
	if _take("dash") and dash_cd <= 0.0:
		_start_dash()
		return
	if _take("special") and fury >= 1.0:
		_start_special()
		return
	if not Input.is_action_pressed("block"):
		set_state(S.IDLE)
		return
	if _take("jump") and not GameState.is_topdown():
		if is_on_floor() or coyote > 0.0:
			_do_jump(false)
		elif air_jumps < max_air_jumps() and stamina >= DJUMP_STAM:
			air_jumps += 1
			_spend_stamina(DJUMP_STAM)
			_do_jump(true)

# ------------------------------------------------------------------ rzut ---

func _start_throw() -> void:
	_clear_buf()
	var id := _best_throwable()
	if id == "":
		Audio.play("deny", 1.0, -14.0)
		Fx.popup(global_position + Vector2(0, -70), "Brak przedmiotów!", Color(1, 0.5, 0.4))
		return
	GameState.remove_item(id, 1)
	GameState.commit_backpack()
	_snap_to_enemy(190.0, true)
	set_state(S.THROW)
	Audio.play("throw", randf_range(0.95, 1.05), -6.0)
	var data := ItemDB.get_data(id)
	var th: Dictionary = data.get("throw", {"damage": 14.0, "radius": 44.0, "speed": 600.0, "gravity": 900.0, "count": 1})
	_snap_to_enemy(190.0, true)
	for i in int(th.get("count", 1)):
		var proj := (PROJECTILE_SCENE as PackedScene).instantiate() as EggProjectile
		proj.setup(self, id, {
			"damage": float(th["damage"]) * GameState.stat("throw_power") * GameState.stat("strength"),
			"radius": float(th["radius"]),
			"speed": float(th["speed"]),
			"gravity": float(th["gravity"]),
			"stun": float(th.get("stun", 0.0)),
			"dir": facing,
		}, float(i * 0.09))
		get_parent().add_child(proj)
		proj.global_position = global_position + Vector2(facing * 18.0, -38.0)

func _best_throwable() -> String:
	for id in GameState.consumed_ids():
		if ItemDB.is_throwable(id):
			return id
	return ""

func _st_throw(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 1600.0 * delta)
	visual.arm = 1.0 if state_t < 0.18 else 0.0
	if state_t > 0.32:
		set_state(S.IDLE)

# ---------------------------------------------------------------- furia -----

func _start_special() -> void:
	_clear_buf()
	fury = 0.0
	fury_changed.emit(0.0)
	invuln = maxf(invuln, float(special_data.get("duration", 1.4)) + 0.1)
	energy = maxf(0.0, energy - float(special_data.get("cost", 100.0)))
	energy_changed.emit(energy, max_energy)
	set_state(S.SPECIAL)
	special_tick = 0.0
	velocity = Vector2.ZERO
	Audio.play("roar", 1.2, -4.0)
	Fx.flash(Color(1.0, 0.75, 0.4), 0.2, 0.35)
	Fx.shake(8.0, 0.4)

func _st_special(delta: float) -> void:
	var dur := float(special_data.get("duration", 1.4))
	var radius := float(special_data.get("radius", 120.0))
	var tick := float(special_data.get("tick", 0.0))
	velocity.x = move_toward(velocity.x, 0.0, 2000.0 * delta)
	if GameState.is_topdown():
		velocity.y = move_toward(velocity.y, 0.0, 2000.0 * delta)
	elif not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
	visual.arm = 1.0
	visual.flap = 0.6
	if tick <= 0.0:
		# atak jednorazowy pośrodku
		if state_t >= dur * 0.35 and special_tick == 0.0:
			special_tick = 1.0
			_special_hit(radius, float(special_data.get("dmg", 15.0)))
			Fx.ring(Vector2(position.x, position.y - 30), Color(1.0, 0.8, 0.4), radius, 0.35, 6.0)
			Fx.burst(Vector2(position.x, position.y - 30), Color(1.0, 0.8, 0.4), 20, 380.0, 3.5, 0.5)
	else:
		special_tick -= delta
		if special_tick <= 0.0:
			special_tick = tick
			_special_hit(radius, float(special_data.get("dmg", 15.0)))
			Fx.ring(Vector2(position.x, position.y - 30), Color(1.0, 0.8, 0.4), radius * 0.7, 0.25, 4.0)
	if state_t >= dur:
		set_state(S.IDLE if _grounded() else S.FALL)

func _special_hit(radius: float, dmg: float) -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or not (e is Node2D):
			continue
		if e.has_method("is_dead") and e.is_dead():
			continue
		var hb: Hurtbox = e.get_node_or_null("Hurtbox")
		if hb == null:
			continue
		var dir: Vector2 = (e.global_position - global_position).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2(facing, 0)
		hb.take_hit({
			"damage": dmg * GameState.stat("strength"),
			"kb": Vector2(dir.x * 240.0, -300.0),
			"hitstun": 0.35,
			"launch": true,
			"crit": false,
			"team": "player",
			"source": self,
			"kind": "special",
			"no_hitstop": true,
		})
	Audio.play("hit_heavy", randf_range(0.9, 1.05), -4.0)
	Fx.shake(6.0, 0.25)

# ------------------------------------------------------------- obrażenia ----

func apply_hit(info: Dictionary) -> bool:
	if state == S.DEAD or state == S.VICTORY:
		return false
	if invuln > 0.0 or spawn_invuln > 0.0:
		return false
	var dmg := float(info.get("damage", 0.0))
	var def_red := minf(0.6, GameState.stat("defense") * 0.15)
	dmg *= 1.0 - def_red
	var unblockable := bool(info.get("unblockable", false))
	var is_parry := false
	# --- blok
	if state == S.BLOCK and not unblockable and _facing_attacker(info):
		if parry_t > 0.0:
			is_parry = true
		else:
			dmg *= (1.0 - BLOCK_REDUCTION)
			energy = maxf(0.0, energy - dmg * 0.35)
			energy_delay = 1.0
			energy_changed.emit(energy, max_energy)
			Fx.ring(global_position + Vector2(facing * 26.0, -34.0), Color(0.6, 0.85, 1.0), 34.0, 0.22, 3.0)
			Fx.burst(global_position + Vector2(facing * 26.0, -34.0), Color(0.7, 0.9, 1.0), 8, 180.0, 2.5, 0.3)
			Fx.hitstop(0.06)
			Audio.play("block", randf_range(0.95, 1.05), -3.0)
			GameState.run_add("blocks", 1)
			if energy <= 0.0:
				_stagger(0.6, Vector2(-facing * 90.0, -40.0))
			return true
	if is_parry:
		GameState.run_add("parries", 1)
		add_energy(18.0)
		add_fury(0.12)
		Fx.hitstop(0.16)
		Fx.shake(9.0, 0.3)
		Fx.flash(Color(1.0, 1.0, 1.0), 0.2, 0.4)
		Audio.play("parry", 1.0, 0.0)
		Fx.popup(global_position + Vector2(0, -78), "PARRY!", Color(0.7, 0.95, 1.0))
		Fx.ring(global_position + Vector2(0, -34.0), Color(1.0, 1.0, 1.0), 80.0, 0.35, 5.0)
		# odrzut atakującego
		var src = info.get("source")
		if src and is_instance_valid(src) and src.has_method("stagger"):
			var d := signf(global_position.x - src.global_position.x)
			if d == 0.0:
				d = -facing
			src.stagger(1.1, Vector2(d * 180.0, -120.0))
		invuln = maxf(invuln, 0.5)
		return true

	# --- trafienie
	hp -= dmg
	GameState.run_add("damage_taken", dmg)
	GameState.run_set("health", hp)
	health_changed.emit(hp, max_hp)
	add_fury(0.02 * dmg)
	energy_delay = 1.2
	visual.flash(1.0)
	visual.hurt_t = 0.3
	Fx.damage_number(global_position + Vector2(0, -66), dmg, Color(1.0, 0.35, 0.32), "player")
	Fx.hitstop(0.07)
	Fx.shake(5.0 + dmg * 0.12, 0.26)
	Fx.burst(global_position + Vector2(0, -30), Color(0.9, 0.25, 0.2), 12, 240.0, 3.0, 0.4)
	Audio.play("hurt", randf_range(0.95, 1.08), -3.0)
	combo = 0
	combo_changed.emit(0)
	if hp <= 0.0:
		_die(info)
		return true
	invuln = maxf(invuln, INVULN_AFTER_HIT)
	var kb: Vector2 = info.get("kb", Vector2(-facing * 200.0, -200.0))
	_stagger(float(info.get("hitstun", 0.35)), kb)
	return true

func _facing_attacker(info: Dictionary) -> bool:
	var src = info.get("source")
	if src and is_instance_valid(src):
		return signf(src.global_position.x - global_position.x) == signf(facing)
	return false

func _stagger(time: float, kb: Vector2) -> void:
	velocity = kb
	can_act = false
	set_state(S.HURT)
	_stagger_time = time

var _stagger_time := 0.0

func _st_hurt(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	if GameState.is_topdown():
		velocity.y = move_toward(velocity.y, 0.0, 900.0 * delta)
	elif not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
	visual.crouch = 0.4
	if state_t >= _stagger_time:
		can_act = true
		_clear_buf()
		set_state(S.IDLE if _grounded() else S.FALL)

func _st_downed(delta: float) -> void:
	# powalony po ciężkim ciosie: leży chwilę, zanim wstanie
	velocity.x = move_toward(velocity.x, 0.0, 1400.0 * delta)
	if GameState.is_topdown():
		velocity.y = move_toward(velocity.y, 0.0, 1400.0 * delta)
	elif not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
	visual.crouch = 1.0
	if state_t >= _stagger_time:
		can_act = true
		invuln = maxf(invuln, 0.6)
		_clear_buf()
		set_state(S.IDLE if _grounded() else S.FALL)

func _die(info: Dictionary = {}) -> void:
	hp = 0.0
	health_changed.emit(hp, max_hp)
	GameState.run_set("health", 0.0)
	visual.die()
	Audio.play("die", 1.0, -2.0)
	Fx.hitstop(0.3)
	Fx.shake(12.0, 0.6)
	set_state(S.DEAD)
	died.emit()

func _st_dead(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
	if GameState.is_topdown():
		velocity.y = move_toward(velocity.y, 0.0, 400.0 * delta)
	else:
		velocity.y = minf(velocity.y + GRAVITY * 0.6 * delta, MAX_FALL)
	if state_t > 1.0:
		position.y += 60.0 * delta

func victory() -> void:
	if state == S.DEAD:
		return
	can_act = false
	set_state(S.VICTORY)
	Audio.play("levelup", 1.0, -4.0)

func _st_victory(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 1200.0 * delta)
	visual.arm = 0.3 + 0.2 * sin(state_t * 6.0)

func celebrate() -> void:
	can_act = true
	visual.revive()
	invuln = 1.0
	hp = max_hp
	health_changed.emit(hp, max_hp)
	set_state(S.IDLE)

# --------------------------------------------------------- zasoby i pasek ---

func _update_regen(delta: float) -> void:
	if energy_delay > 0.0:
		energy_delay = maxf(0.0, energy_delay - delta)
	elif energy < max_energy and state != S.SPECIAL:
		energy = minf(max_energy, energy + 9.0 * delta)
		energy_changed.emit(energy, max_energy)

func add_energy(v: float) -> void:
	energy = clampf(energy + v, 0.0, max_energy)
	energy_changed.emit(energy, max_energy)

func add_fury(v: float) -> void:
	if fury >= 1.0 or state == S.SPECIAL:
		return
	fury = clampf(fury + v * GameState.stat("fury_rate"), 0.0, 1.0)
	fury_changed.emit(fury)
	if fury >= 1.0:
		Fx.popup(global_position + Vector2(0, -86), "FURIA!", Color(1.0, 0.75, 0.25))
		Audio.play("confirm", 1.4, -6.0)

func heal(v: float) -> void:
	hp = clampf(hp + v, 0.0, max_hp)
	GameState.run_set("health", hp)
	health_changed.emit(hp, max_hp)

func full_restore() -> void:
	hp = max_hp
	energy = max_energy
	stamina = max_stamina
	GameState.run_set("health", hp)
	GameState.run_set("energy", energy)
	health_changed.emit(hp, max_hp)
	energy_changed.emit(energy, max_energy)
	stamina_changed.emit(stamina, max_stamina)

func _update_stamina(delta: float) -> void:
	if sprinting:
		stamina = maxf(0.0, stamina - SPRINT_DRAIN * delta)
		stamina_delay = 0.55
		stamina_changed.emit(stamina, max_stamina)
	elif stamina_delay > 0.0:
		stamina_delay = maxf(0.0, stamina_delay - delta)
	elif stamina < max_stamina:
		stamina = minf(max_stamina, stamina + STAMINA_REGEN * delta)
		stamina_changed.emit(stamina, max_stamina)

func _spend_stamina(v: float) -> void:
	stamina = maxf(0.0, stamina - v)
	stamina_delay = 0.55
	stamina_changed.emit(stamina, max_stamina)

# ------------------------------------------------------------------ skile ---

func _try_skill(i: int) -> void:
	if not can_act or state == S.DEAD or state == S.SPECIAL:
		return
	if i < 0 or i >= skill_slots.size():
		return
	var id := String(skill_slots[i])
	if id == "" or not SkillDB.has(id):
		return
	if float(skill_cd[i]) > 0.0:
		Audio.play("deny", 1.4, -14.0)
		return
	var d: Dictionary = SkillDB.get_data(id)
	if String(d.get("type", "")) == "special":
		if fury < 1.0:
			Audio.play("deny", 1.4, -14.0)
			Fx.popup(global_position + Vector2(0, -86), "FURIA NIE GOTOWA", Color(1.0, 0.75, 0.25))
			return
		skill_cd[i] = float(d.get("cd", 2.0))
		skills_changed.emit()
		_start_special()
		return
	var cost := float(d.get("cost", 0.0))
	if energy < cost:
		Audio.play("deny", 1.4, -14.0)
		Fx.popup(global_position + Vector2(0, -86), "BRAK ENERGII", Color(0.6, 0.85, 1.0))
		return
	energy = maxf(0.0, energy - cost)
	energy_delay = 1.0
	energy_changed.emit(energy, max_energy)
	skill_cd[i] = float(d.get("cd", 3.0))
	skills_changed.emit()
	_cast_skill(id, d)

func _cast_skill(id: String, d: Dictionary) -> void:
	var t := String(d.get("type", ""))
	var st := GameState.stat("strength")
	match t:
		"aoe":
			var r := float(d.get("radius", 140.0))
			_aoe_hit(Vector2(position.x, position.y - 20.0), r, float(d.get("dmg", 40.0)) * st, float(d.get("kb", 300.0)), 0.35)
			Fx.ring(Vector2(position.x, position.y - 30), d.get("col", Color(1, 1, 1)), r, 0.3, 6.0)
			Fx.shake(7.0, 0.25)
			Audio.play("hit_heavy", 1.0, -4.0)
		"projectile":
			_spawn_skill_projectile(float(d.get("dmg", 20.0)))
		"dash_strike":
			_skill_dash_strike(float(d.get("dmg", 30.0)))
		"heal":
			heal(float(d.get("heal", 30.0)))
			Fx.popup(global_position + Vector2(0, -84), "+%d" % int(d.get("heal", 30.0)), Color(0.4, 1.0, 0.6))
			Audio.play("drink", 1.1, -6.0)
		"shield":
			invuln = maxf(invuln, float(d.get("duration", 2.5)))
			Fx.ring(global_position + Vector2(0, -30), Color(0.85, 0.9, 1.0), 46.0, 0.4, 4.0)
			Audio.play("confirm", 1.2, -6.0)
		"buff":
			if GameState.has_run():
				GameState.run["buffs"]["strength"] = {"value": float(d.get("strength", 0.3)), "time": float(d.get("duration", 8.0))}
				GameState.run["buffs"]["speed"] = {"value": float(d.get("speed", 0.2)), "time": float(d.get("duration", 8.0))}
				GameState.refresh_stats()
			Fx.popup(global_position + Vector2(0, -84), String(d.get("name", "BUFF")), d.get("col", UiKit.ACCENT))
			Audio.play("roar", 1.3, -6.0)
		"berserk":
			_skill_berserk(d)
		"power_swing":
			_skill_power_swing(d)
		"headshot":
			_skill_headshot(d)
		"triple_shot":
			_skill_triple_shot(d)
		"pirouette":
			_skill_pirouette(d)
		"barrier":
			_skill_barrier(d)
		"shadow":
			_skill_shadow(d)
		"stun_all":
			_skill_stun_all(d)
		"steal":
			_skill_steal(d)

func _spawn_skill_projectile(dmg: float) -> void:
	_snap_to_enemy(240.0, true)
	Audio.play("throw", 1.1, -6.0)
	var proj := (PROJECTILE_SCENE as PackedScene).instantiate() as EggProjectile
	proj.setup(self, "jajko", {
		"damage": dmg * GameState.stat("strength"),
		"radius": 30.0,
		"speed": 780.0,
		"gravity": 0.0,
		"stun": 0.2,
		"dir": facing,
	}, 0.0)
	get_parent().add_child(proj)
	proj.global_position = global_position + Vector2(facing * 18.0, -38.0)

func _skill_dash_strike(dmg: float) -> void:
	_snap_to_enemy(260.0, true)
	invuln = maxf(invuln, 0.25)
	_start_attack({
		"name": "Kopniak", "wind": 0.06, "active": 0.14, "rec": 0.2,
		"dmg": dmg, "kb": 380.0, "stun": 0.4, "range": 66.0, "lunge": 240.0, "launch": true, "s": 1.2,
	}, 3, _grounded())

# --------------------------------------------------- nowe umięjętności klas ---

func _nearest_target(max_range: float = 400.0) -> Node2D:
	var best: Node2D = null
	var bd := max_range
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var d := global_position.distance_to(e.global_position)
		if d < bd:
			bd = d
			best = e
	# w szału / oszołomieniu gracze też są celem
	for p in get_tree().get_nodes_in_group("player"):
		if p == self or not is_instance_valid(p):
			continue
		var d2 := global_position.distance_to(p.global_position)
		if d2 < bd:
			bd = d2
			best = p
	return best

func _berserk_dir_x() -> float:
	var t := _nearest_target(1600.0)
	if t == null:
		return Input.get_axis("move_left", "move_right")
	return signf(t.global_position.x - global_position.x)

func _berserk_tick() -> void:
	_berserk_atk_cd = maxf(0.0, _berserk_atk_cd - get_physics_process_delta_time())
	var t := _nearest_target(220.0)
	if t != null:
		facing = signf(t.global_position.x - global_position.x)
		if _berserk_atk_cd <= 0.0 and (state == S.IDLE or state == S.RUN):
			var atk: Array = _weap_attacks()["light"]
			_start_attack(atk[randi() % atk.size()], 0, true)
			_berserk_atk_cd = 0.38

func _skill_berserk(d: Dictionary) -> void:
	if _berserk_on:
		return
	_berserk_on = true
	berserk_t = float(d.get("duration", 8.0))
	# najpierw buffy (refresh_stats nadpisuje max_hp), potem bonus HP
	if GameState.has_run():
		GameState.run["buffs"]["strength"] = {"value": float(d.get("atk_mult", 1.7)) - 1.0, "time": berserk_t}
		GameState.refresh_stats()
	var hp_mult := float(d.get("hp_mult", 1.6))
	var bonus := max_hp * (hp_mult - 1.0)
	max_hp += bonus
	hp = minf(max_hp, hp + bonus)
	energy_changed.emit(energy, max_energy)
	Fx.popup(global_position + Vector2(0, -90), "SZAŁ BOJOWY", Color(1.0, 0.3, 0.2))
	Audio.play("roar", 1.2, -4.0)

func _end_berserk() -> void:
	_berserk_on = false
	if GameState.has_run() and GameState.run["buffs"].has("strength"):
		GameState.run["buffs"].erase("strength")
		GameState.refresh_stats()
	hp = minf(hp, max_hp)

func _skill_power_swing(d: Dictionary) -> void:
	_snap_to_enemy(180.0, true)
	_start_attack({
		"name": "Potężny Zamach", "wind": 0.16, "active": 0.16, "rec": 0.3,
		"dmg": float(d.get("dmg", 60.0)), "kb": float(d.get("kb", 520.0)), "stun": 0.6,
		"range": float(d.get("range", 96.0)), "lunge": 140.0, "launch": true, "s": 1.5,
	}, 3, _grounded())
	Audio.play("hit_heavy", 1.1, -6.0)

func _skill_headshot(d: Dictionary) -> void:
	_snap_to_enemy(280.0, true)
	_spawn_projectile(float(d.get("dmg", 44.0)), d.get("col", UiKit.TEXT), true, 0.0)
	Audio.play("throw", 1.3, -4.0)

func _skill_triple_shot(d: Dictionary) -> void:
	_snap_to_enemy(280.0, true)
	var spread := float(d.get("spread", 22.0))
	var dmg := float(d.get("dmg", 18.0))
	for off in [-spread, 0.0, spread]:
		_spawn_projectile_angle(dmg, d.get("col", UiKit.GOOD), off, 0.0)
	Audio.play("throw", 1.2, -4.0)

func _skill_pirouette(d: Dictionary) -> void:
	var r := float(d.get("radius", 120.0))
	var dmg := float(d.get("dmg", 34.0)) * GameState.stat("strength")
	_aoe_hit(Vector2(position.x, position.y - 20.0), r, dmg, 200.0, 0.45)
	Fx.ring(Vector2(position.x, position.y - 30), d.get("col", UiKit.ACCENT2), r, 0.4, 6.0)
	Fx.shake(5.0, 0.2)
	Audio.play("swing_weapon", 1.1, -4.0)

func _skill_barrier(d: Dictionary) -> void:
	if barrier and is_instance_valid(barrier):
		barrier.queue_free()
	barrier = Node2D.new()
	barrier.set_script(load("res://scripts/barrier.gd"))
	barrier.global_position = Vector2(position.x, position.y - 20.0)
	barrier.set("radius", float(d.get("radius", 130.0)))
	barrier.set("duration", float(d.get("duration", 30.0)))
	barrier.set("col", d.get("col", Color(0.5, 0.95, 0.95)))
	get_parent().add_child(barrier)
	Audio.play("confirm", 1.2, -4.0)

func _skill_shadow(d: Dictionary) -> void:
	shadow_t = float(d.get("duration", 4.5))
	_set_shadow(true)
	Fx.popup(global_position + Vector2(0, -80), "W CIEŃ", Color(0.4, 0.4, 0.7))
	Audio.play("dash", 1.0, -6.0)

func _set_shadow(on: bool) -> void:
	_shadow_on = on
	modulate.a = 0.35 if on else 1.0
	invuln = maxf(invuln, 0.05) if on else invuln

func is_hidden() -> bool:
	return _shadow_on

func _skill_stun_all(d: Dictionary) -> void:
	var r := float(d.get("radius", 170.0))
	var dur := float(d.get("duration", 3.0))
	Fx.ring(Vector2(position.x, position.y - 30), d.get("col", Color(0.85, 0.6, 1.0)), r, 0.5, 6.0)
	Audio.play("roar", 1.1, -6.0)
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.global_position.distance_to(global_position) <= r:
			if e.has_method("stagger"):
				e.stagger(dur, Vector2.ZERO)
	for p in get_tree().get_nodes_in_group("player"):
		if p == self or not is_instance_valid(p):
			continue
		if p.global_position.distance_to(global_position) <= r:
			if "stun_t" in p:
				p.set("stun_t", dur)

func _skill_steal(d: Dictionary) -> void:
	var t := _nearest_target(220.0)
	if t == null:
		Fx.popup(global_position + Vector2(0, -80), "BRAK CELU", Color(0.7, 0.7, 0.9))
		Audio.play("deny", 1.2, -10.0)
		return
	Audio.play("confirm", 1.2, -8.0)
	# rozbrój
	if "weapon_taken" in t:
		t.set("weapon_taken", true)
		Fx.popup(t.global_position + Vector2(0, -70), "ROZBROJONY!", Color(0.7, 0.7, 0.9))
	# kradzież złota zależna od wroga i szczęścia
	var luck := GameState.stat("luck")
	var base := 6
	if "gold_value" in t:
		base = int(t.get("gold_value"))
	var stolen := maxi(1, int(round(float(base) * (0.6 + 0.4 * luck))))
	GameState.add_gold(stolen)
	if GameState.has_run():
		GameState.run["gold_earned"] = int(GameState.run.get("gold_earned", 0)) + stolen
	# szansa na miksturę z kieszeni wroga
	if randf() < clampf(0.25 * luck, 0.0, 0.8):
		GameState.add_item("mikstura_miodu", 1)
		if GameState.has_run():
			GameState.run["backpack"] = GameState.char_profile(String(GameState.run.get("character", ""))).get("backpack", {})
		Fx.popup(t.global_position + Vector2(0, -100), "+ MIÓD", Color(1.0, 0.85, 0.4))
	Fx.popup(t.global_position + Vector2(0, -40), "+%d zł" % stolen, Color(1.0, 0.85, 0.3))
	if t.has_method("stagger"):
		t.stagger(0.4, Vector2.ZERO)

func _spawn_projectile(dmg: float, col: Color, crit: bool = false, stun: float = 0.0) -> void:
	_spawn_projectile_angle(dmg, col, 0.0, stun, crit)

func _spawn_projectile_angle(dmg: float, col: Color, angle_off: float, stun: float = 0.0, crit: bool = false) -> void:
	var dir := facing
	var vel := Vector2(dir, 0.0).rotated(deg_to_rad(angle_off))
	var proj := (PROJECTILE_SCENE as PackedScene).instantiate() as EggProjectile
	proj.setup(self, "jajko", {
		"damage": dmg * GameState.stat("strength"),
		"radius": 30.0,
		"speed": 780.0,
		"gravity": 0.0,
		"stun": stun,
		"crit": crit,
		"dir": vel.x,
		"col": col,
	}, 0.0)
	get_parent().add_child(proj)
	proj.global_position = global_position + Vector2(vel.x * 18.0, -38.0)
	proj.velocity = vel * 780.0

func add_combo() -> void:
	combo += 1
	combo_timer = 1.0 + COMBO_DECAY
	combo_changed.emit(combo)
	if GameState.has_run() and combo > int(GameState.run.get("max_combo", 0)):
		GameState.run_set("max_combo", combo)

func use_consumable(id: String) -> bool:
	var d := ItemDB.get_data(id)
	var use: Dictionary = d.get("use", {})
	if use.is_empty():
		return false
	if not GameState.remove_item(id, 1):
		return false
	GameState.commit_backpack()
	heal(float(use.get("health", 0.0)))
	add_energy(float(use.get("energy", 0.0)))
	var t := float(use.get("buff_time", 0.0))
	if t > 0.0:
		for k in ["strength", "speed", "defense", "crit"]:
			if use.has("buff_" + k) and GameState.has_run():
				GameState.run["buffs"][k] = {"value": float(use["buff_" + k]), "time": t}
	if use.has("invuln"):
		invuln = maxf(invuln, float(use["invuln"]))
	GameState.refresh_stats()
	Audio.play("drink", 1.0, -4.0)
	Fx.burst(global_position + Vector2(0, -34), Color(0.5, 0.95, 0.6), 14, 200.0, 3.0, 0.5)
	GameState.toast.emit("Użyto: %s" % d["name"], Color(0.6, 0.95, 0.6))
	return true

func _tick_buffs(delta: float) -> void:
	if not GameState.has_run() or not GameState.run.has("buffs"):
		return
	var buffs: Dictionary = GameState.run["buffs"]
	var expired: Array = []
	for k in buffs.keys():
		var b: Dictionary = buffs[k]
		var t := float(b.get("time", 0.0))
		if t <= 0.0:
			continue
		b["time"] = t - delta
		if b["time"] <= 0.0:
			expired.append(k)
	for k in expired:
		buffs.erase(k)
		GameState.toast.emit("Mija efekt: %s" % String(k).capitalize(), Color(0.8, 0.8, 0.85))
	if not expired.is_empty():
		GameState.refresh_stats()

# ------------------------------------------------------------- pomocnicze ---

func _aim_dir() -> Vector2:
	if not GameState.is_topdown():
		return Vector2(facing, 0.0)
	var t := _nearest_target(320.0)
	if t != null and is_instance_valid(t):
		var d: Vector2 = t.global_position - global_position
		if d.length() > 0.01:
			return d.normalized()
	return Vector2(facing, 0.0)

func _snap_to_enemy(range_px: float, soft: bool = false) -> void:
	var best: Node2D = null
	var best_d := range_px
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or not (e is Node2D):
			continue
		if e.has_method("is_dead") and e.is_dead():
			continue
		var d: float = absf(e.global_position.x - global_position.x)
		if d < best_d:
			best_d = d
			best = e
	if best:
		facing = signf(best.global_position.x - global_position.x)
		if facing == 0.0:
			facing = 1.0
	elif not soft:
		var ix := _input_x()
		if absf(ix) > 0.15:
			facing = signf(ix)

func _update_visual(delta: float) -> void:
	visual.moving = absf(velocity.x) > 24.0 and _grounded() and state in [S.RUN, S.IDLE]
	visual.grounded = _grounded()
	visual.flap = clampf(velocity.y / 600.0, 0.0, 1.0) if not _grounded() else 0.0
	visual.dead = state == S.DEAD
	if state != S.BLOCK and state != S.HURT:
		visual.crouch = lerpf(visual.crouch, 0.0, 0.25)
	visual.arm = lerpf(visual.arm, 0.0, 0.2)
	visual.arm_back = lerpf(visual.arm_back, 0.0, 0.25)
	if state != S.ATTACK and state != S.AIR_ATTACK:
		visual.charge_t = 0.0
	visual.charge_t = lerpf(visual.charge_t, 0.0, 0.1)
	# odporność na trafienia: migotanie
	if invuln > 0.0:
		visual.modulate.a = 0.55 + 0.45 * absf(sin(invuln * 30.0))
	else:
		visual.modulate.a = 1.0

func stagger(time: float, kb: Vector2 = Vector2.ZERO) -> void:
	_stagger(time, kb)
