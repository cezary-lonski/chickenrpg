class_name EggProjectile
extends Node2D
## Rzucany przedmiot (jajko, cebula, kamyki). Leci po paraboli, wybucha przy
## kontakcie z wrogiem, ziemią albo po czasie życia.

var source: Node = null
var item_id := "jajko"
var data: Dictionary = {}
var velocity := Vector2.ZERO
var _t := 0.0
var _delay := 0.0
var _done := false
var _life := 3.0
var _td := false

func setup(from: Node, id: String, hit: Dictionary, delay: float = 0.0) -> void:
	source = from
	item_id = id
	data = hit
	_delay = delay
	var dir := float(hit.get("dir", 1.0))
	_td = GameState.is_topdown()
	if _td:
		# top-down: prosty lot w kierunku celowania, bez łuku grawitacji
		var aim: Vector2 = hit.get("aim", Vector2(dir, 0.0))
		velocity = aim.normalized() * float(hit.get("speed", 600.0))
		_life = 1.0
	else:
		velocity = Vector2(dir * float(hit.get("speed", 600.0)), -260.0)

func _ready() -> void:
	z_index = 40
	var icon: Texture2D = Art.item_icon(String(ItemDB.get_data(item_id).get("icon", "jajko")), 28)
	$Sprite.texture = icon
	$Shadow.visible = false
	$Trail.emitting = false
	if data.has("col"):
		$Sprite.modulate = data["col"]

func _physics_process(delta: float) -> void:
	if _done:
		return
	if _delay > 0.0:
		_delay -= delta
		$Sprite.visible = false
		return
	$Sprite.visible = true
	$Shadow.visible = true
	$Trail.emitting = true
	$Sprite.rotation = velocity.angle() + PI * 0.5
	$Shadow.visible = true
	$Trail.emitting = true
	_t += delta
	if not _td:
		velocity.y += float(data.get("gravity", 900.0)) * delta
	position += velocity * delta
	$Sprite.rotation = velocity.angle() + PI * 0.5
	if velocity.x != 0.0:
		$Sprite.flip_h = velocity.x < 0.0
	# kolizje
	for area in $Area.get_overlapping_areas():
		if area is Hurtbox and area.actor != source and area.team != "player":
			_burst(area.actor)
			return
	if _t >= _life or (not _td and position.y > 1400.0):
		_burst(null)

func _shadow_y() -> float:
	# przybliżona linia gruntu: najbliższa płaska powierzchnia w dół
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(position, position + Vector2(0, 900.0))
	q.collision_mask = 1 | 64
	q.exclude = [$Area.get_rid()]
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return position.y
	return hit["position"].y

func _burst(actor: Node) -> void:
	if _done:
		return
	_done = true
	var radius := float(data.get("radius", 46.0))
	var dmg := float(data.get("damage", 14.0))
	var stun := float(data.get("stun", 0.0))
	var dir := Vector2(signf(velocity.x), -0.35).normalized()
	for area in _all_enemy_hurtboxes():
		var d: float = area.global_position.distance_to(global_position)
		if d > radius + 30.0:
			continue
		var push: Vector2 = area.global_position - global_position
		if push.length() < 1.0:
			push = dir
		area.take_hit({
			"damage": dmg * (1.4 if d < radius * 0.5 else 0.75),
			"kb": (push.normalized() * 240.0) if _td else Vector2(push.normalized().x * 220.0, -240.0 if stun > 0.0 else -150.0),
			"hitstun": maxf(0.25, stun),
			"launch": true,
			"crit": bool(data.get("crit", false)),
			"team": (String(source.get("team_tag")) if (source != null and is_instance_valid(source) and "team_tag" in source) else "player"),
			"source": source,
			"kind": "throw",
		})
	Fx.burst(global_position, Color(1.0, 0.95, 0.75), 14, 300.0, 3.0, 0.35)
	Fx.ring(global_position, Color(1.0, 0.9, 0.6), radius, 0.28, 4.0)
	Audio.play("egg", randf_range(0.9, 1.1), -3.0)
	queue_free()

func _all_enemy_hurtboxes() -> Array:
	var out := []
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var hb: Hurtbox = e.get_node_or_null("Hurtbox")
		if hb and hb.vulnerable:
			out.append(hb)
	return out
