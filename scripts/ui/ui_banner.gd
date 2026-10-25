class_name UiBanner
extends CanvasLayer
## Duży napis na środku ekranu (tytuł etapu, liczba fali, zwycięstwo).

var title_text := ""
var sub_text := ""

func setup(t: String, s: String) -> void:
	title_text = t
	sub_text = s

func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	UiKit.full(root)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	# rozbłysk (tło pod tekstem)
	var glow := ColorRect.new()
	glow.color = Color(0, 0, 0, 0.35)
	glow.position = Vector2(190, 280)
	glow.size = Vector2(900, 160)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(glow)
	var box := UiKit.vbox(4)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	UiKit.full(box)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(box)
	var t := UiKit.title(title_text, 56, UiKit.ACCENT)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(t)
	var s := UiKit.label(sub_text, 26, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(s)
	root.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(root, "modulate:a", 1.0, 0.28)
	tw.tween_interval(1.5)
	tw.tween_property(root, "modulate:a", 0.0, 0.5)
	tw.tween_callback(queue_free)
