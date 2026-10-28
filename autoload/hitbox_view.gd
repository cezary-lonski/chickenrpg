extends Node2D
## Ustawienie „Pokaż hitboxy”: rysuje nad światem WSZYSTKIE kształty kolizji — ataki (czerwone, pełne gdy
## aktywne), hurtboxy (niebieskie), inne obszary jak strefy obrażeń i pociski (żółte), ciała (zielone) i ściany (szare).

const C_HIT_ON := Color(1.0, 0.2, 0.2)
const C_HIT_OFF := Color(1.0, 0.4, 0.4, 0.28)
const C_HURT := Color(0.3, 0.6, 1.0, 0.9)
const C_BODY := Color(0.4, 1.0, 0.5, 0.8)
const C_AREA := Color(1.0, 0.85, 0.2, 0.9)
const C_WALL := Color(0.7, 0.7, 0.75, 0.55)

func _ready() -> void:
	z_index = 4000
	process_mode = Node.PROCESS_MODE_ALWAYS
	if DisplayServer.get_name() == "headless":
		set_process(false)

func _process(_delta: float) -> void:
	var on := GameState.setting("hitboxes")
	if on or visible:
		visible = on
		queue_redraw()

func _draw() -> void:
	if not GameState.setting("hitboxes"):
		return
	_walk(get_tree().root)
	draw_set_transform_matrix(Transform2D.IDENTITY)

## Przechodzi po całym świecie gry i rysuje każdy kształt kolizji (z pominięciem interfejsu).
func _walk(n: Node) -> void:
	for c in n.get_children():
		if c == self or c is Control or c is CanvasLayer or c is Window:
			continue
		if c is CollisionShape2D:
			var cs := c as CollisionShape2D
			if not cs.disabled and cs.is_visible_in_tree():
				_draw_collider(cs, n)
		elif c is CollisionPolygon2D:
			var cp := c as CollisionPolygon2D
			if not cp.disabled and cp.is_visible_in_tree():
				_draw_collider(cp, n)
		if c.get_child_count() > 0:
			_walk(c)

func _draw_collider(c: Node2D, parent: Node) -> void:
	var col := C_BODY
	var fill := false
	if parent is Area2D:
		var a := parent as Area2D
		if a.is_in_group("hitbox"):
			fill = a.monitoring
			col = C_HIT_ON if fill else C_HIT_OFF
		elif a is Hurtbox:
			col = C_HURT
		else:
			col = C_AREA
			fill = a.monitoring
	elif parent is StaticBody2D:
		col = C_WALL
	if c is CollisionShape2D:
		_shape(c as CollisionShape2D, col, fill)
	else:
		draw_set_transform_matrix(c.global_transform)
		var pts := (c as CollisionPolygon2D).polygon
		if pts.size() >= 2:
			var loop := PackedVector2Array(pts)
			loop.append(pts[0])
			draw_polyline(loop, col, 2.0)

func _shape(cs: CollisionShape2D, col: Color, fill: bool) -> void:
	var s: Shape2D = cs.shape
	if s == null:
		return
	draw_set_transform_matrix(cs.global_transform)
	if s is RectangleShape2D:
		var r := Rect2(-(s as RectangleShape2D).size * 0.5, (s as RectangleShape2D).size)
		if fill:
			draw_rect(r, Color(col.r, col.g, col.b, 0.3), true)
		draw_rect(r, col, false, 2.0)
	elif s is CircleShape2D:
		var rad := (s as CircleShape2D).radius
		if fill:
			draw_circle(Vector2.ZERO, rad, Color(col.r, col.g, col.b, 0.3))
		draw_arc(Vector2.ZERO, rad, 0.0, TAU, 32, col, 2.0)
	elif s is CapsuleShape2D:
		var cap := s as CapsuleShape2D
		var half := maxf(0.0, cap.height * 0.5 - cap.radius)
		draw_arc(Vector2(0, -half), cap.radius, PI, TAU, 16, col, 2.0)
		draw_arc(Vector2(0, half), cap.radius, 0.0, PI, 16, col, 2.0)
		draw_line(Vector2(-cap.radius, -half), Vector2(-cap.radius, half), col, 2.0)
		draw_line(Vector2(cap.radius, -half), Vector2(cap.radius, half), col, 2.0)
	elif s is SegmentShape2D:
		draw_line((s as SegmentShape2D).a, (s as SegmentShape2D).b, col, 2.0)
	draw_set_transform_matrix(Transform2D.IDENTITY)
