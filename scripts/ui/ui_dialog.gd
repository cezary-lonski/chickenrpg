class_name UiDialog
extends Control

signal on_close

var _lines: Array = []
var _index := 0
var _accent := Color(1.0, 0.72, 0.25)
var _who: Label
var _text: Label
var _hint: Label
var _progress: Label
var _closed := false

func setup(lines: Array, accent: Color = Color(1.0, 0.72, 0.25)) -> void:
	_lines = lines
	_accent = accent

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	add_child(UiKit.dim(Color(0.02, 0.02, 0.05, 0.55)))
	var outer := UiKit.vbox(0)
	UiKit.full(outer)
	outer.alignment = BoxContainer.ALIGNMENT_END
	add_child(outer)
	var pad := UiKit.hbox(0)
	pad.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_child(pad)
	var panel := UiKit.panel(Color(0.06, 0.07, 0.11, 0.97), 12)
	panel.custom_minimum_size = Vector2(1040, 176)
	pad.add_child(panel)
	var v := UiKit.vbox(6)
	v.custom_minimum_size = Vector2(1000, 0)
	panel.add_child(v)
	var head := UiKit.hbox(10)
	v.add_child(head)
	_who = UiKit.label("", 22, _accent)
	_who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_who)
	_progress = UiKit.label("", 14, UiKit.DIM, HORIZONTAL_ALIGNMENT_RIGHT)
	head.add_child(_progress)
	_text = UiKit.label("", 20, UiKit.TEXT)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(1000, 92)
	_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	v.add_child(_text)
	_hint = UiKit.label("[E] / kliknij — dalej", 14, UiKit.DIM, HORIZONTAL_ALIGNMENT_RIGHT)
	v.add_child(_hint)
	_show()
	Audio.play("select", 1.0, -6.0)

func _show() -> void:
	if _lines.is_empty():
		_finish()
		return
	var line = _lines[_index]
	var who := ""
	var text := ""
	if line is Array:
		who = String(line[0]) if line.size() > 0 else ""
		text = String(line[1]) if line.size() > 1 else ""
	else:
		text = String(line)
	_who.text = who
	_who.visible = who != ""
	_text.text = text
	_text.modulate = UiKit.TEXT if who != "" else UiKit.DIM
	_progress.text = "%d / %d" % [_index + 1, _lines.size()]

func _advance() -> void:
	if _closed:
		return
	_index += 1
	if _index >= _lines.size():
		_finish()
	else:
		Audio.play("select", 1.0, -10.0)
		_show()

func _finish() -> void:
	if _closed:
		return
	_closed = true
	on_close.emit()

func _input(event: InputEvent) -> void:
	if _closed:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("equipment") or event.is_action_pressed("jump"):
			_advance()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("quest_log") or event.is_action_pressed("pause"):
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()
		get_viewport().set_input_as_handled()
