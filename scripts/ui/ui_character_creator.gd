class_name UiCharacterCreator
extends Control
## Kreator postaci: wygląd bazowy, kolory części, ubrania, nazwa. Zapisuje do profilu.
## `then` = ekran po zatwierdzeniu ("menu" albo "rpg_select" przy nowej grze).

signal on_done

var then := "menu"

const SWATCHES := [
	"#f9f5e6", "#e8d9b0", "#c9a66b", "#8a5a2b", "#4a3020", "#202028",
	"#b02f2f", "#e8572b", "#f4a62a", "#e8d23a", "#7cc24a", "#2f8f4e",
	"#3fb5b0", "#3a6ea5", "#2c3e8f", "#7a4fc2", "#c254b3", "#f28fb3",
	"#ffffff", "#bfc5cc", "#808890", "#40464e", "#6b3a1f", "#101014",
]

var _app: Dictionary = {}
var _visual: CreatureVisual
var _tab_box: VBoxContainer
var _tab := "look"
var _part := "body"
var _slot := "head"
var _name_edit: LineEdit
var _status: Label
var _undo: Array = []

func setup(next_screen: String) -> void:
	then = next_screen

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_app = GameState.appearance()
	UiKit.full(self)
	add_child(UiKit.bg_texture(Color(0.06, 0.08, 0.12)))
	var root := UiKit.vbox(8)
	UiKit.full(root)
	root.offset_left = 24.0
	root.offset_right = -24.0
	root.offset_top = 12.0
	root.offset_bottom = -12.0
	add_child(root)
	root.add_child(UiKit.title("KREATOR POSTACI", 40))
	root.add_child(UiKit.label("Zmiany są tylko kosmetyczne — nie wpływają na statystyki.", 14, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))

	var body := UiKit.hbox(14)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	# --- podgląd
	var left := UiKit.panel(UiKit.BG, 12)
	left.custom_minimum_size = Vector2(340, 0)
	body.add_child(left)
	var lv := UiKit.vbox(8)
	left.add_child(lv)
	lv.add_child(UiKit.label("PODGLĄD", 15, UiKit.DIM))
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(300, 290)
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lv.add_child(holder)
	_visual = CreatureVisual.new()
	_visual.position = Vector2(150, 250)
	_visual.body_scale = 2.7
	holder.add_child(_visual)
	var rot := UiKit.hbox(6)
	rot.alignment = BoxContainer.ALIGNMENT_CENTER
	lv.add_child(rot)
	var b_rot := UiKit.button("↻ Obróć postać", 15, UiKit.ACCENT2)
	b_rot.pressed.connect(func(): _visual.set_facing(-_visual.facing); Audio.play("select"))
	rot.add_child(b_rot)
	var pose := UiKit.hbox(6)
	pose.alignment = BoxContainer.ALIGNMENT_CENTER
	lv.add_child(pose)
	for entry in [["idle", "Stoi"], ["walk", "Idzie"], ["attack", "Atak"]]:
		var key := String(entry[0])
		var pb := UiKit.button(String(entry[1]), 14)
		pb.pressed.connect(func(): _set_pose(key))
		pose.add_child(pb)

	# --- opcje
	var right := UiKit.panel(UiKit.BG, 12)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	var rv := UiKit.vbox(8)
	right.add_child(rv)
	var tabs := UiKit.hbox(6)
	rv.add_child(tabs)
	for entry in [["look", "Wygląd"], ["colors", "Kolory"], ["clothes", "Ubrania"], ["name", "Nick"]]:
		var key2 := String(entry[0])
		var tb := UiKit.button(String(entry[1]), 17)
		tb.pressed.connect(func(): _tab = key2; Audio.play("select"); _rebuild())
		tabs.add_child(tb)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rv.add_child(scroll)
	_tab_box = UiKit.vbox(8)
	_tab_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_tab_box)

	# --- dół
	_status = UiKit.label("", 14, UiKit.GOOD, HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(_status)
	var row := UiKit.hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(row)
	var back := UiKit.button("Wstecz", 20)
	back.pressed.connect(func(): Audio.play("back"); Flow.goto(_back_screen()))
	row.add_child(back)
	var undo := UiKit.button("Cofnij", 20, UiKit.ACCENT2)
	undo.pressed.connect(_undo_last)
	row.add_child(undo)
	var paint := UiKit.button("Kreator animacji…", 20, UiKit.ACCENT2)
	paint.pressed.connect(_open_paint)
	row.add_child(paint)
	var ok := UiKit.button("Zatwierdź" if then == "menu" else "Zatwierdź i rozpocznij grę", 22)
	ok.custom_minimum_size = Vector2(300, 48)
	ok.pressed.connect(_confirm)
	row.add_child(ok)
	_rebuild()
	_refresh_preview()

func _set_pose(key: String) -> void:
	Audio.play("select")
	_visual.moving = key == "walk"
	_visual.arm = 0.0
	if key == "attack":
		_visual.arm = 1.0
		var tw := create_tween()
		tw.tween_property(_visual, "arm", 0.0, 0.5)
	_visual.set_anim(key)

func _snapshot() -> void:
	_undo.append(_app.duplicate(true))
	if _undo.size() > 40:
		_undo.pop_front()

func _undo_last() -> void:
	if _undo.is_empty():
		_status.text = "Nie ma czego cofać."
		return
	Audio.play("back")
	_app = _undo.pop_back()
	_status.text = "Cofnięto ostatnią zmianę."
	_rebuild()
	_refresh_preview()

func _refresh_preview() -> void:
	var id := String(_app.get("look", ""))
	if not CharacterDB.LIST.has(id):
		id = String(GameState.run.get("character", "kurczak")) if GameState.has_run() else "kurczak"
		if not CharacterDB.LIST.has(id):
			id = "kurczak"
	_visual.configure(id, CharacterDB.get_data(id)["pal"], 2.7)
	_visual.apply_appearance(_app)
	_visual.custom_anims = GameState.anims()
	_visual.set_gear(CosmeticDB.gear_visual(GameState.equipped(), GameState.equipped_meta()) if GameState.has_run() else {})

func _rebuild() -> void:
	for c in _tab_box.get_children():
		c.queue_free()
	match _tab:
		"look": _build_look()
		"colors": _build_colors()
		"clothes": _build_clothes()
		"name": _build_name()

# -------------------------------------------------------------------- wygląd ---

func _build_look() -> void:
	_tab_box.add_child(UiKit.label("Wybierz bazowy wygląd (tylko odblokowane):", 16, UiKit.TEXT))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_tab_box.add_child(grid)
	var cur := String(_app.get("look", ""))
	for id in GameState.all_characters():
		var cid := String(id)
		var data := CharacterDB.get_data(cid)
		var unlocked := GameState.is_unlocked(cid) or cid == "lord" or cid == "lady"
		var price_txt := ""
		if not unlocked:
			price_txt = "  [%d %s]" % [GameState.unlock_cost(cid), "piór" if GameState.unlock_currency(cid) == "cod" else "zł"]
		var b := UiKit.button(String(data.get("title", cid)) + ("  ✔" if cur == cid else "") + price_txt, 17)
		b.custom_minimum_size = Vector2(190, 44)
		b.tooltip_text = String(data.get("subtitle", "")) if unlocked else "Kliknij, aby odblokować (złoto ze wszystkich zapisów razem)"
		b.pressed.connect(func():
			if not (GameState.is_unlocked(cid) or cid == "lord" or cid == "lady"):
				if not GameState.try_unlock(cid):
					Audio.play("deny")
					GameState.toast.emit("Za mało: potrzeba %d, masz razem %d." % [GameState.unlock_cost(cid), GameState.total_gold() if GameState.unlock_currency(cid) != "cod" else GameState.cod()], UiKit.BAD)
					return
				GameState.toast.emit("Odblokowano: %s!" % String(data.get("title", cid)), UiKit.GOOD)
			_snapshot()
			_app["look"] = cid
			Audio.play("confirm")
			_rebuild()
			_refresh_preview())
		grid.add_child(b)
	var auto := UiKit.button("Wg postaci kampanii" + ("  ✔" if cur == "" else ""), 16, UiKit.ACCENT2)
	auto.pressed.connect(func():
		_snapshot()
		_app["look"] = ""
		Audio.play("select")
		_rebuild()
		_refresh_preview())
	_tab_box.add_child(auto)

# -------------------------------------------------------------------- kolory ---

func _swatch_grid(on_pick: Callable) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 12
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	for hex in SWATCHES:
		var sw := Button.new()
		sw.custom_minimum_size = Vector2(30, 30)
		sw.add_theme_stylebox_override("normal", UiKit.sb(Color.html(String(hex)), 6, 2.0, Color(0, 0, 0, 0.6)))
		sw.add_theme_stylebox_override("hover", UiKit.sb(Color.html(String(hex)).lightened(0.15), 6, 2.0, Color(1, 1, 1, 0.8)))
		sw.add_theme_stylebox_override("pressed", UiKit.sb(Color.html(String(hex)), 6, 2.0, Color(1, 1, 1, 1)))
		var h: String = hex
		sw.pressed.connect(func(): on_pick.call(h))
		grid.add_child(sw)
	return grid

func _picker_button(initial: Color, on_pick: Callable) -> ColorPickerButton:
	var cp := ColorPickerButton.new()
	cp.custom_minimum_size = Vector2(120, 32)
	cp.color = initial
	cp.edit_alpha = false
	cp.text = "Własny kolor"
	cp.color_changed.connect(func(c: Color): on_pick.call("#" + c.to_html(false)))
	return cp

func _part_color(part: String) -> Color:
	var over: Dictionary = _app.get("colors", {})
	if over.has(part) and String(over[part]) != "":
		return Color.html(String(over[part]))
	return _visual.pal.get(part, Color.WHITE) if _visual and not _visual.pal.is_empty() else Color.WHITE

func _build_colors() -> void:
	_tab_box.add_child(UiKit.label("Wybierz część i jej kolor:", 16, UiKit.TEXT))
	var parts := UiKit.hbox(6)
	_tab_box.add_child(parts)
	for key in CosmeticDB.PARTS:
		var pk := String(key)
		var b := UiKit.button(String(CosmeticDB.PARTS[key]) + ("  ●" if pk == _part else ""), 15)
		b.pressed.connect(func(): _part = pk; Audio.play("select"); _rebuild())
		parts.add_child(b)
	_tab_box.add_child(_swatch_grid(func(hex: String):
		_snapshot()
		if not (_app.get("colors") is Dictionary):
			_app["colors"] = {}
		_app["colors"][_part] = hex
		_refresh_preview()))
	_tab_box.add_child(_picker_button(_part_color(_part), func(hex: String):
		if not (_app.get("colors") is Dictionary):
			_app["colors"] = {}
		_app["colors"][_part] = hex
		_refresh_preview()))
	var reset := UiKit.button("Przywróć kolor tej części", 16, UiKit.ACCENT2)
	reset.pressed.connect(func():
		_snapshot()
		(_app["colors"] as Dictionary).erase(_part)
		Audio.play("back")
		_refresh_preview()
		_rebuild())
	_tab_box.add_child(reset)

# -------------------------------------------------------------------- ubrania ---

func _build_clothes() -> void:
	var slots := UiKit.hbox(6)
	_tab_box.add_child(slots)
	for key in CosmeticDB.CLOTH_SLOTS:
		var sk := String(key)
		var b := UiKit.button(String(CosmeticDB.CLOTH_SLOTS[key]) + ("  ●" if sk == _slot else ""), 16)
		b.pressed.connect(func(): _slot = sk; Audio.play("select"); _rebuild())
		slots.add_child(b)
	var clothes: Dictionary = _app.get("clothes", {})
	var worn: Dictionary = clothes.get(_slot, {})
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_tab_box.add_child(grid)
	var none := UiKit.button("Brak" + ("  ✔" if worn.is_empty() else ""), 16)
	none.custom_minimum_size = Vector2(190, 40)
	none.pressed.connect(func():
		_snapshot()
		(_app["clothes"] as Dictionary).erase(_slot)
		Audio.play("select")
		_refresh_preview()
		_rebuild())
	grid.add_child(none)
	for id in CosmeticDB.CLOTHES[_slot]:
		var cid := String(id)
		var d: Dictionary = CosmeticDB.CLOTHES[_slot][id]
		var b2 := UiKit.button(String(d["name"]) + ("  ✔" if String(worn.get("id", "")) == cid else ""), 16)
		b2.custom_minimum_size = Vector2(190, 40)
		b2.pressed.connect(func():
			_snapshot()
			if not (_app.get("clothes") is Dictionary):
				_app["clothes"] = {}
			_app["clothes"][_slot] = CosmeticDB.cloth_default(_slot, cid)
			Audio.play("confirm")
			_refresh_preview()
			_rebuild())
		grid.add_child(b2)
	if worn.is_empty():
		return
	for which in ["main", "trim"]:
		var wk: String = which
		_tab_box.add_child(UiKit.label("Kolor główny:" if wk == "main" else "Kolor wykończenia:", 15, UiKit.DIM))
		_tab_box.add_child(_swatch_grid(func(hex: String):
			_snapshot()
			(_app["clothes"][_slot] as Dictionary)[wk] = hex
			_refresh_preview()))
		_tab_box.add_child(_picker_button(Color.html(String(worn.get(wk, "#ffffff"))), func(hex: String):
			(_app["clothes"][_slot] as Dictionary)[wk] = hex
			_refresh_preview()))

# ---------------------------------------------------------------------- nazwa ---

func _build_name() -> void:
	_tab_box.add_child(UiKit.label("Nick (3–16 znaków: litery, cyfry, _):", 16, UiKit.TEXT))
	_tab_box.add_child(UiKit.label("Widzą go inni gracze na czacie i w komendach, np. /msg nick.", 13, UiKit.DIM))
	_name_edit = LineEdit.new()
	_name_edit.max_length = 16
	_name_edit.text = String(_app.get("name", ""))
	_name_edit.placeholder_text = "np. KogutZawadiaka"
	_name_edit.custom_minimum_size = Vector2(360, 40)
	_name_edit.text_changed.connect(func(t: String):
		var clean := GameState.clean_nick(t)
		if clean != t:
			var c := _name_edit.caret_column
			_name_edit.text = clean
			_name_edit.caret_column = mini(c, clean.length())
		_app["name"] = clean)
	_tab_box.add_child(_name_edit)

# --------------------------------------------------------------------- zapis ---

func _back_screen() -> String:
	if then == "menu" or then == "mmo_connect":
		return then
	return "slots"

func _open_paint() -> void:
	Audio.play("confirm")
	GameState.set_appearance(_app)
	Flow.goto("paint", {"back": "creator", "then": then})

func _confirm() -> void:
	if _name_edit and is_instance_valid(_name_edit):
		_app["name"] = GameState.clean_nick(_name_edit.text)
	if String(_app.get("name", "")).length() < 3:
		_tab = "name"
		_rebuild()
		_status.text = "Wpisz nick (min. 3 znaki: litery, cyfry, _)."
		_status.add_theme_color_override("font_color", UiKit.BAD)
		Audio.play("deny")
		return
	GameState.set_appearance(_app)
	Audio.play("confirm")
	GameState.toast.emit("Wygląd zapisany.", UiKit.GOOD)
	on_done.emit()
	Flow.goto(then)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed() and event.is_action_pressed("ui_cancel") and not (_name_edit and _name_edit.has_focus()):
		Audio.play("back")
		Flow.goto(_back_screen())
