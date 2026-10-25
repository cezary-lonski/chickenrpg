class_name Pickup
extends Area2D
## Łupki: złoto, mikstury, jajka, sprzęt. Podnosi się przez wejście gracza.

var item_id := "gold"
var amount := 1
var life := 26.0
var _t := 0.0
var _v := Vector2.ZERO
var _ground_y := 100000.0
var _resting := false
var _collected := false
var _from_loot := false

func setup(id: String, count: int = 1, from_loot: bool = true) -> void:
	item_id = id
	amount = count
	_from_loot = from_loot

func _ready() -> void:
	add_to_group("pickup")
	z_index = 20
	$Sprite.texture = _texture()
	_v = Vector2(randf_range(-140, 140), -randf_range(260, 380))
	$Label.visible = amount > 1 and item_id == "gold"
	$Label.text = "x%d" % amount

func _texture() -> Texture2D:
	if item_id == "gold":
		return Art.hud_icon("gold", 20, Color(1.0, 0.82, 0.28))
	return Art.item_icon(String(ItemDB.get_data(item_id).get("icon", "jajko")), 22)

func _physics_process(delta: float) -> void:
	_t += delta
	life -= delta
	_ground_y = _floor_y()
	if _resting:
		_v = Vector2.ZERO
	else:
		_v.y = minf(_v.y + 1400.0 * delta, 900.0)
		_v.x = move_toward(_v.x, 0.0, 400.0 * delta)
		position += _v * delta
		if position.y >= _ground_y:
			position.y = _ground_y
			if absf(_v.x) < 40.0 and _v.y > 0.0:
				_resting = true
				_v = Vector2.ZERO
	# unoszenie
	var float_y := -6.0 + sin(_t * 3.4) * 3.0
	$Sprite.position.y = float_y
	$Sprite.rotation = sin(_t * 2.0) * 0.12
	# przyciąganie do gracza
	if not _collected:
		for p in get_tree().get_nodes_in_group("player"):
			if not is_instance_valid(p):
				continue
			var d: Vector2 = p.global_position - global_position
			var dist := d.length()
			if dist < 26.0:
				_collect(p)
				return
			elif dist < 62.0:
				position += d.normalized() * 460.0 * delta
	if life <= 0.0:
		queue_free()

func _floor_y() -> float:
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(Vector2(position.x, position.y - 60.0), Vector2(position.x, position.y + 160.0))
	q.collision_mask = 1 | 64
	var hit := space.intersect_ray(q)
	return position.y if hit.is_empty() else float(hit["position"].y)

func _collect(p: Node) -> void:
	if _collected:
		return
	_collected = true
	match item_id:
		"gold":
			var gold_amt := int(round(float(amount) * (1.0 + GameState.stat("gold_mult"))))
			GameState.add_gold(gold_amt)
			GameState.run_add("gold_earned", gold_amt)
			Fx.popup(global_position + Vector2(0, -26), "+%d złota" % gold_amt, Color(1.0, 0.85, 0.3))
		_:
			GameState.add_item(item_id, amount)
			GameState.commit_backpack()
			Fx.popup(global_position + Vector2(0, -26), String(ItemDB.get_data(item_id).get("name", item_id)), Color(0.7, 0.95, 1.0))
			Audio.play("coin", 1.3, -6.0)
	Fx.burst(global_position, Color(1.0, 0.95, 0.7), 10, 200.0, 2.5, 0.35)
	queue_free()
