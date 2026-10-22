class_name Hurtbox
extends Area2D
## Punkt trafienia aktora. Przekazuje trafienia do właściciela.

@export var team: String = "player"
var actor: Node = null
var vulnerable := true

func _ready() -> void:
	actor = get_parent()
	add_to_group("hurtbox")

func set_vulnerable(v: bool) -> void:
	vulnerable = v
	set_deferred("monitorable", v)

func take_hit(info: Dictionary) -> bool:
	if not vulnerable or actor == null or not is_instance_valid(actor):
		return false
	if not actor.has_method("apply_hit"):
		return false
	if String(info.get("team", "enemy")) == team:
		return false
	return bool(actor.apply_hit(info))
