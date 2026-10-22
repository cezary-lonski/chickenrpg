class_name EnemyProjectile
extends Node2D
## Pocisk wroga: pióro, kamień itp. Leci i rozbija się o gracza albo o ziemię.

var source: Node = null
var data: Dictionary = {}
var velocity := Vector2.ZERO
var delay := 0.0
var _t := 0.0
var _delay := 0.0
var _done := false

func setup(from: Node, d: Dictionary) -> void:
	source = from
	data = d
	var ang := float(d.get("angle", 0.0))
	var dir := float(d.get("dir", -1.0))
	var spd := float(d.get("speed", 380.0))
	velocity = Vector2(dir * cos(ang), sin(ang)) * spd
	_delay = float(d.get("delay", 0.0))

func _ready() -> void:
	z_index = 30
	delay = _delay
	if data.get("kind", "feather") == "rock":
		$Sprite.texture = Art.hud_icon("skull", 16, Color(0.45, 0.42, 0.4))
	else:
		$Sprite.texture = Art.item_icon("feather", 22)

func _physics_process(delta: float) -> void:
	if _done:
		return
	if delay > 0.0:
		delay -= delta
		$Sprite.visible = false
		return
	$Sprite.visible = true
	_t += delta
	velocity.y += float(data.get("gravity", 200.0)) * delta
	position += velocity * delta
	$Sprite.rotation = velocity.angle() + PI * 0.5
	if velocity.x < 0.0:
		$Sprite.flip_h = true
	for area in $Area.get_overlapping_areas():
		if area is Hurtbox and area.actor != source:
			_burst(area.actor)
			return
	if _t > 4.0 or position.y > 1500.0:
		_burst(null)

func _burst(actor: Node) -> void:
	if _done:
		return
	_done = true
	var dmg := float(data.get("damage", 10.0))
	if actor and is_instance_valid(actor):
		var hb: Hurtbox = actor.get_node_or_null("Hurtbox")
		if hb:
			var slow := bool(data.get("slow", false))
			hb.take_hit({
				"damage": dmg,
				"kb": Vector2(signf(velocity.x) * 200.0, -180.0 if not slow else -60.0),
				"hitstun": 0.45 if slow else 0.25,
				"launch": not slow,
				"crit": false,
				"team": "enemy",
				"source": source,
				"kind": "projectile",
			})
		Fx.burst(position, Color(0.95, 0.85, 0.7), 8, 180.0, 2.5, 0.3)
		Audio.play("hit", 1.3, -10.0)
	else:
		Fx.burst(position, Color(0.7, 0.7, 0.75), 5, 120.0, 2.0, 0.25)
	queue_free()
