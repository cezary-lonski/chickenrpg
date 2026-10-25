class_name UiChoice
extends Control
## Okno wyboru w dialogu: pytanie i kilka odpowiedzi. Emituje `chosen(index)`.

signal chosen(index: int)
signal on_close

var prompt := ""
var options: Array = []     # [{text, disabled?, hint?}]
var accent := Color(1.0, 0.72, 0.25)
var _done := false

func setup(p_prompt: String, p_options: Array, p_accent: Color = Color(1.0, 0.72, 0.25)) -> void:
	prompt = p_prompt
	options = p_options
	accent = p_accent

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	add_child(UiKit.dim(Color(0.02, 0.02, 0.05, 0.6)))
	var outer := UiKit.vbox(0)
	UiKit.full(outer)
	outer.alignment = BoxContainer.ALIGNMENT_END
	add_child(outer)
	var pad := UiKit.hbox(0)
	pad.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_child(pad)
	var panel := UiKit.panel(Color(0.06, 0.07, 0.11, 0.97), 12)
	panel.custom_minimum_size = Vector2(900, 0)
	pad.add_child(panel)
	var v := UiKit.vbox(8)
	panel.add_child(v)
	var q := UiKit.label(prompt, 20, accent)
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	q.custom_minimum_size = Vector2(860, 0)
	v.add_child(q)
	for i in options.size():
		var o: Dictionary = options[i]
		var b := UiKit.button("%d. %s" % [i + 1, String(o["text"])], 18)
		b.custom_minimum_size = Vector2(860, 42)
		b.disabled = bool(o.get("disabled", false))
		b.tooltip_text = String(o.get("hint", ""))
		var idx := i
		b.pressed.connect(func(): _pick(idx))
		v.add_child(b)
		if i == 0 and not b.disabled:
			b.grab_focus()
	outer.add_child(UiKit.sep(18))

func _pick(i: int) -> void:
	if _done:
		return
	_done = true
	Audio.play("confirm")
	chosen.emit(i)
	on_close.emit()

func _input(event: InputEvent) -> void:
	if _done:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k := (event as InputEventKey).keycode
		if k >= KEY_1 and k <= KEY_9:
			var i := k - KEY_1
			if i < options.size() and not bool(options[i].get("disabled", false)):
				get_viewport().set_input_as_handled()
				_pick(i)
