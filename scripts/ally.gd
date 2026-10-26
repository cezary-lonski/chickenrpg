class_name Ally
extends Node2D
## Żołnierz Korony: towarzyszy bohaterowi w kampanii i walczy z wrogami w zwarciu.
## Idzie w szyku za graczem, doskakuje do najbliższego wroga i tnie. Nie blokuje ruchu
## (brak ciała fizycznego) i nie atakuje sojuszników.

var owner_player: Node2D = null
var slot := 0
var rank := "Żołnierz"
var visual: CreatureVisual
var _cd := 0.6
var _attack_t := 0.0
var _target: Node2D = null
var _name_label: Label
var hp := 100.0
var max_hp := 100.0
var state := 0          # Player.S.DEAD po poległym (wrogowie przestają go celować)
var dying := false

const SPECIES := ["kogut", "gasior", "kogut", "gasior"]
const PALS := [
	{"body": Color(0.86, 0.8, 0.7), "shade": Color(0.62, 0.56, 0.5), "comb": Color(0.2, 0.35, 0.8), "beak": Color(0.95, 0.7, 0.2), "leg": Color(0.95, 0.7, 0.2)},
	{"body": Color(0.9, 0.9, 0.92), "shade": Color(0.65, 0.66, 0.72), "comb": Color(0.2, 0.35, 0.8), "beak": Color(0.95, 0.7, 0.2), "leg": Color(0.95, 0.65, 0.2)},
]
const NAMES := ["Szeregowy Antek", "Kapral Bolek", "Sierżant Cezary", "Szeregowy Dominik"]

func setup(owner_node: Node2D, index: int) -> void:
	owner_player = owner_node
	slot = index

func _ready() -> void:
	add_to_group("allies")
	z_index = 3
	visual = CreatureVisual.new()
	visual.configure(String(SPECIES[slot % SPECIES.size()]), PALS[slot % PALS.size()], 1.05)
	visual.set_gear({
		"weapon": {"col": Color(0.82, 0.85, 0.92), "style": "sword", "len": 22.0},
		"armor": {"col": Color(0.3, 0.42, 0.75), "trim": Color(0.9, 0.9, 1.0)},
		"helmet": {"col": Color(0.65, 0.68, 0.75)},
	})
	visual.idle_seed = randf() * 3.0
	add_child(visual)
	_name_label = Label.new()
	_name_label.text = String(NAMES[slot % NAMES.size()])
	_name_label.add_theme_font_size_override("font_size", 12)
	_name_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	_name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_name_label.add_theme_constant_override("outline_size", 4)
	_name_label.position = Vector2(-50, -92)
	_name_label.custom_minimum_size = Vector2(100, 0)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_name_label)
	max_hp = 70.0 + 16.0 * float(GameState.player_level())
	hp = maxf(1.0, GameState.support_hp("ally:%d" % slot, max_hp))
	SupportHp.attach(self, 20.0)
	if owner_player and is_instance_valid(owner_player):
		global_position = owner_player.global_position + _formation()

func _draw() -> void:
	if not dying:
		SupportHp.draw_bar(self, hp, max_hp, Vector2(0, -82))

## Wrogowie biją żołnierza tak jak gracza; po śmierci przyjeżdża karetka.
func apply_hit(info: Dictionary) -> bool:
	if dying:
		return false
	var dmg := maxf(1.0, float(info.get("damage", 0.0)) * 0.8)
	hp -= dmg
	GameState.set_support_hp("ally:%d" % slot, maxf(hp, 0.0))
	visual.flash(1.0)
	Fx.damage_number(global_position + Vector2(0, -64), dmg, Color(1.0, 0.55, 0.45))
	Audio.play("hit", randf_range(0.9, 1.1), -8.0)
	queue_redraw()
	if hp <= 0.0:
		_die()
	return true

func _die() -> void:
	dying = true
	state = Player.S.DEAD
	visual.die()
	if _name_label:
		_name_label.visible = false
	var hb: Node = get_node_or_null("Hurtbox")
	if hb:
		hb.set_deferred("monitorable", false)
	GameState.mark_fallen("ally:%d" % slot)
	GameState.clear_support_hp("ally:%d" % slot)
	GameState.toast.emit("%s poległ — karetka już jedzie. Wróci po 5 poziomach." % String(NAMES[slot % NAMES.size()]), Color(1.0, 0.6, 0.5))
	Ambulance.dispatch(get_parent(), global_position, func():
		Fx.burst(global_position + Vector2(0, -20), Color(1, 1, 1), 12, 200.0, 3.0, 0.4)
		queue_free())

func _formation() -> Vector2:
	var side := -1.0 if slot % 2 == 0 else 1.0
	var row := float(slot / 2 + 1)
	return Vector2(side * 70.0 * row, 40.0 + 24.0 * float(slot % 2))

func _damage() -> float:
	var lv := 1
	if GameState.has_run():
		lv = int(GameState.char_profile(String(GameState.run.get("character", "lord"))).get("level", 1))
	# strażnicy wspierają, nie grają za gracza: słabe, wolne uderzenia (poziom liczy się tylko w małym stopniu)
	return (6.0 + 0.7 * float(lv)) * (0.8 + 0.2 * GameState.stat("strength")) * 0.5

func _physics_process(delta: float) -> void:
	if dying:
		return
	if owner_player == null or not is_instance_valid(owner_player):
		queue_free()
		return
	_cd -= delta
	_attack_t = maxf(0.0, _attack_t - delta)
	_target = _find_target()
	var goal := owner_player.global_position + _formation()
	var close := false
	if _target != null:
		var to := _target.global_position - global_position
		if to.length() > 64.0:
			goal = _target.global_position - to.normalized() * 48.0
		else:
			goal = global_position
			close = true
	var d := goal - global_position
	var moving := false
	if d.length() > 900.0:
		global_position = goal
	elif d.length() > 10.0:
		global_position += d.normalized() * minf(250.0 if _target != null else 230.0, d.length() / maxf(delta, 0.001)) * delta
		moving = true
	if _cd <= 0.0 and close and _target != null:
		_swing(_target)
	var face := signf(((_target.global_position if _target != null else owner_player.global_position).x - global_position.x))
	visual.moving = moving
	visual.grounded = true
	visual.set_facing(face if face != 0.0 else 1.0)
	visual.arm = clampf(_attack_t / 0.25, 0.0, 1.0)

func _find_target() -> Node2D:
	var best: Node2D = null
	var bd := 300.0
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or not (e is Node2D):
			continue
		if e.has_method("is_dead") and e.is_dead():
			continue
		if "net_ghost" in e and bool(e.get("net_ghost")):
			continue
		if "is_duel" in e and bool(e.get("is_duel")):
			continue   # pojedynek: towarzysze nie wtrącają się
		var dist: float = e.global_position.distance_to(global_position)
		if dist < bd:
			bd = dist
			best = e
	return best

func _swing(t: Node2D) -> void:
	_cd = 2.2
	_attack_t = 0.25
	var hb: Hurtbox = t.get_node_or_null("Hurtbox")
	if hb == null:
		return
	var dmg := _damage()
	if "is_boss" in t and bool(t.get("is_boss")):
		dmg *= 0.25   # bossów ma bić gracz, nie straż
	elif "elite" in t and bool(t.get("elite")):
		dmg *= 0.5
	hb.take_hit({
		"damage": dmg, "kb": (t.global_position - global_position).normalized() * 160.0,
		"hitstun": 0.18, "launch": false, "crit": false, "team": "player", "source": owner_player, "kind": "ally",
	})
	Fx.slash(t.global_position + Vector2(0, -30), signf(t.global_position.x - global_position.x), Color(0.8, 0.9, 1.0, 0.8), 0.9)
	Audio.play("punch", 1.1, -12.0)
