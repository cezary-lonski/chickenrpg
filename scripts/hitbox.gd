class_name Hitbox
extends Area2D
## Obszar ataku. Włączasz go na czas aktywnej klatki animacji, wtedy
## sprawdza, kogo dotyka, i przekazuje trafienia dokładnie raz.

signal hit_landed(target: Node, info: Dictionary)

var actor: Node = null
var duration := 0.1
var max_targets := 6
var hits: Array[Dictionary] = []
var _timer := 0.0
var _used: Dictionary = {}
var _active := false
var base_position := Vector2.ZERO

func _ready() -> void:
	actor = get_parent()
	monitoring = false
	add_to_group("hitbox")

func fire(dur: float, hit_info: Dictionary, targets: int = 6) -> void:
	hits = [hit_info]
	duration = maxf(0.02, dur)
	max_targets = targets
	_timer = duration
	_used.clear()
	_active = true
	monitoring = true

func stop() -> void:
	_active = false
	monitoring = false

## Kształt hitboxa leży w scenie z przesunięciem lokalnym (+x), więc node obracamy
## w kierunku ataku zamiast tylko go przesuwać.
func move_offset(x: float, y: float = 0.0) -> void:
	base_position = Vector2(x, y)
	position = base_position
	rotation = 0.0 if x >= 0.0 else PI

## Atak w dowolnym kierunku (top-down): `dist` od aktora wzdłuż `aim`.
func aim_offset(aim: Vector2, dist: float, y: float = 0.0) -> void:
	var a := aim.normalized() if aim.length() > 0.01 else Vector2.RIGHT
	base_position = a * dist + Vector2(0.0, y)
	position = base_position
	rotation = a.angle()

func _physics_process(delta: float) -> void:
	if not _active:
		return
	_timer -= delta
	if _timer <= 0.0:
		stop()
		return
	for area in get_overlapping_areas():
		if not area is Hurtbox:
			continue
		if area.actor == self:
			continue
		var id := area.get_instance_id()
		if _used.has(id):
			continue
		var applied := false
		for h in hits:
			if area.take_hit(h):
				applied = true
				break
		if applied:
			_used[id] = true
			var info: Dictionary = hits[0] if not hits.is_empty() else {}
			hit_landed.emit(area.actor, info)
			if _used.size() >= max_targets:
				stop()
				return
