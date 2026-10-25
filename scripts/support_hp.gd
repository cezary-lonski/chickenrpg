class_name SupportHp
extends RefCounted
## Wspólne dla żołnierzy i petów: obszar trafień (wrogowie mogą ich bić) i pasek życia.

static func attach(node: Node2D, radius: float) -> void:
	var hb := Hurtbox.new()
	hb.name = "Hurtbox"
	hb.team = "player"
	hb.collision_layer = 16
	hb.collision_mask = 8
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = radius
	cs.shape = sh
	cs.position = Vector2(0, -radius * 1.1)
	hb.add_child(cs)
	node.add_child(hb)

static func draw_bar(node: Node2D, hp: float, max_hp: float, at: Vector2) -> void:
	if hp >= max_hp or max_hp <= 0.0:
		return
	var k := clampf(hp / max_hp, 0.0, 1.0)
	node.draw_rect(Rect2(at + Vector2(-17, -1), Vector2(34, 7)), Color(0.05, 0.04, 0.07))
	node.draw_rect(Rect2(at + Vector2(-15, 1), Vector2(30, 3)), Color(0.3, 0.1, 0.1))
	node.draw_rect(Rect2(at + Vector2(-15, 1), Vector2(30.0 * k, 3)), Color(0.4, 0.9, 0.4) if k > 0.4 else Color(0.95, 0.4, 0.3))

static func can_start_dying(node: Node) -> bool:
	return node != null and is_instance_valid(node)
