class_name UiEncounter
extends Control
## Okno rozmowy ze spotkania (EncounterDB): tekst, wynik rzutu k20 i ponumerowane odpowiedzi z opisem próby
## (cecha, trudność, szansa). Esc zamyka rozmowę. Wybór wysyła `picked(i)` (i = -1: przerwano).

signal picked(index: int)
signal on_close

var _view: Dictionary = {}
var _roll_text := ""
var _fx_text := ""
var _roll_ok := true
var _done := false

func setup(view: Dictionary, roll_text: String = "", roll_ok: bool = true, fx_text: String = "") -> void:
	_view = view
	_roll_text = roll_text
	_roll_ok = roll_ok
	_fx_text = fx_text

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
	panel.custom_minimum_size = Vector2(960, 0)
	pad.add_child(panel)
	var v := UiKit.vbox(8)
	panel.add_child(v)
	var accent: Color = _view.get("accent", UiKit.ACCENT)
	v.add_child(UiKit.label(String(_view.get("speaker", "")), 22, accent))
	if _roll_text != "":
		v.add_child(UiKit.label("🎲 " + _roll_text, 17, UiKit.GOOD if _roll_ok else UiKit.BAD))
	var t := UiKit.label(String(_view.get("text", "")), 19, UiKit.TEXT)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size = Vector2(920, 0)
	v.add_child(t)
	if _fx_text != "":
		v.add_child(UiKit.label("✦ " + _fx_text, 16, UiKit.ACCENT))
	var opts: Array = _view.get("options", [])
	for i in opts.size():
		var o: Dictionary = opts[i]
		var tag := String(o.get("tag", ""))
		var label := "%d. %s" % [i + 1, String(o["text"])]
		if tag != "":
			label += "   " + tag
		var b := UiKit.button(label, 17)
		b.custom_minimum_size = Vector2(920, 40)
		b.disabled = bool(o.get("disabled", false))
		b.tooltip_text = String(o.get("hint", ""))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var idx := i
		b.pressed.connect(func(): _pick(idx))
		v.add_child(b)
		if b.disabled and String(o.get("hint", "")) != "":
			v.add_child(UiKit.label("    ↳ " + String(o["hint"]), 13, UiKit.DIM))
		elif i == 0 and not b.disabled:
			b.grab_focus()
	outer.add_child(UiKit.sep(18))

func _pick(i: int) -> void:
	if _done:
		return
	_done = true
	Audio.play("confirm")
	picked.emit(i)
	on_close.emit()

func _input(event: InputEvent) -> void:
	if _done:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_done = true
		picked.emit(-1)
		on_close.emit()
	elif event is InputEventKey and event.pressed and not event.echo:
		var i: int = int(event.keycode) - KEY_1
		var opts: Array = _view.get("options", [])
		if i >= 0 and i < opts.size() and not bool((opts[i] as Dictionary).get("disabled", false)):
			get_viewport().set_input_as_handled()
			_pick(i)
