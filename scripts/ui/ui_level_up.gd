class_name UiLevelUp
extends Control

signal on_close

var _level := 1
var _points: Label
var _rows: VBoxContainer
var _close: Button

func setup(level: int) -> void:
	_level = level

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	add_child(UiKit.dim(Color(0.02, 0.02, 0.05, 0.78)))
	var center := UiKit.vbox(8)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	UiKit.full(center)
	add_child(center)
	center.add_child(UiKit.title("POZIOM %d" % _level, 52))
	center.add_child(UiKit.label("Rozdaj punkty atrybutów", 19, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	_points = UiKit.label("", 22, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	center.add_child(_points)
	var panel := UiKit.panel(UiKit.BG, 14)
	panel.custom_minimum_size = Vector2(650, 0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center.add_child(panel)
	_rows = UiKit.vbox(8)
	panel.add_child(_rows)
	center.add_child(UiKit.sep(10))
	var row := UiKit.hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(row)
	_close = UiKit.button("Gotowe", 22)
	_close.custom_minimum_size = Vector2(280, 48)
	_close.pressed.connect(_close_pressed)
	row.add_child(_close)
	_refresh()

func _refresh() -> void:
	var points := GameState.attr_points()
	_points.text = "Punkty do rozdania: %d" % points
	for c in _rows.get_children():
		_rows.remove_child(c)
		c.queue_free()
	var first: Button = null
	for key in GameState.attr_order():
		var row := _attr_row(String(key), points)
		_rows.add_child(row)
		if first == null:
			first = row.get_meta("plus")
	if points > 0 and first:
		first.grab_focus()
	else:
		_close.grab_focus()

func _attr_row(key: String, points: int) -> HBoxContainer:
	var defs := GameState.attr_defs()
	var d: Dictionary = defs.get(key, {})
	var h := UiKit.hbox(8)
	h.custom_minimum_size = Vector2(620, 0)
	var name_label := UiKit.label(String(d.get("name", key)), 19, UiKit.TEXT)
	name_label.custom_minimum_size = Vector2(140, 0)
	h.add_child(name_label)
	var bonus := UiKit.label(_bonus_text(key), 17, UiKit.ACCENT2)
	bonus.custom_minimum_size = Vector2(190, 0)
	h.add_child(bonus)
	var spent := UiKit.label("rozdane: %d" % GameState.attr_value(key), 13, UiKit.DIM)
	spent.custom_minimum_size = Vector2(105, 0)
	h.add_child(spent)
	h.add_child(UiKit.spacer())
	var one := UiKit.button("+1", 16)
	one.custom_minimum_size = Vector2(58, 38)
	one.tooltip_text = String(d.get("desc", ""))
	one.disabled = points < 1
	one.pressed.connect(func(): _spend(key, 1))
	h.add_child(one)
	h.set_meta("plus", one)
	var five := UiKit.button("+5", 16)
	five.custom_minimum_size = Vector2(58, 38)
	five.tooltip_text = String(d.get("desc", ""))
	five.disabled = points < 5
	five.pressed.connect(func(): _spend(key, 5))
	h.add_child(five)
	return h

func _bonus_text(key: String) -> String:
	var bonus := GameState.attr_bonus(key)
	match key:
		"health":
			return "+%.0f maks. HP" % bonus
		"energy":
			return "+%.0f maks. energii" % bonus
		"speed":
			return "+%.1f%% szybkości" % (bonus * 100.0)
		"strength":
			return "+%.0f%% obrażeń" % (bonus * 100.0)
		"defense":
			return "+%.0f%% obrony" % (bonus * 100.0)
		"luck":
			return "+%.0f%% szczęścia" % (bonus * 100.0)
	return "+%.2f" % bonus

func _spend(key: String, count: int) -> void:
	if GameState.spend_attr_points(key, count):
		Audio.play("select")
		_refresh()

func _close_pressed() -> void:
	Audio.play("confirm")
	on_close.emit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close_pressed()
