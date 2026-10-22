class_name UiSelect
extends Control
## Wybór kurczaka: podgląd, statystyki, odblokowania.

signal on_chosen(id: String)

var _cards: Array = []
var _sel := 0
var _ids: Array = []
var _desc: Label
var _info: VBoxContainer
var _go: Button
var _unlock_btn: Button
var _card_root: HBoxContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	add_child(UiKit.bg_texture(Color(0.06, 0.08, 0.12)))
	_ids = GameState.all_characters()

	var root := UiKit.vbox(0)
	UiKit.full(root)
	add_child(root)
	root.add_child(UiKit.title("WYBIERZ KURCZAKA", 46))
	root.add_child(UiKit.label("Strzałki / A D — zmiana, Enter — wybór, Esc — wstecz", 16, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	root.add_child(UiKit.sep(12))

	# --- karty
	_card_root = UiKit.hbox(14)
	_card_root.alignment = BoxContainer.ALIGNMENT_CENTER
	_card_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_card_root)
	var card_w := 210 if _ids.size() <= 4 else 176
	for i in _ids.size():
		var card := _make_card(String(_ids[i]), i, card_w)
		_card_root.add_child(card)
		_cards.append(card)

	# --- opis
	var bottom := UiKit.panel(UiKit.BG, 12)
	bottom.custom_minimum_size = Vector2(760, 150)
	bottom.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_child(bottom)
	var bv := UiKit.vbox(6)
	bottom.add_child(bv)
	_desc = UiKit.label("", 17, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	bv.add_child(_desc)
	_info = UiKit.vbox(2)
	bv.add_child(_info)
	_unlock_btn = UiKit.button("", 20)
	_unlock_btn.pressed.connect(_on_unlock)
	bv.add_child(_unlock_btn)

	# --- przyciski
	var row := UiKit.hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(UiKit.sep(10))
	root.add_child(row)
	var back := UiKit.button("Wstecz", 20)
	back.pressed.connect(func(): Audio.play("back"); Flow.goto("menu"))
	row.add_child(back)
	_go = UiKit.button("Wyrusz!", 24)
	_go.custom_minimum_size = Vector2(260, 50)
	_go.pressed.connect(_on_choose)
	row.add_child(_go)

	_select(0)
	_go.grab_focus()

func _make_card(id: String, index: int, card_w: float = 210.0) -> Control:
	var data := CharacterDB.get_data(id)
	var card := UiKit.panel(UiKit.BG2, 12)
	card.custom_minimum_size = Vector2(card_w, 250)
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var v := UiKit.vbox(4)
	card.add_child(v)
	var holder_w := card_w - 24.0
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(holder_w, 130)
	v.add_child(holder)
	var vis := CreatureVisual.new()
	vis.configure(id, data["pal"], 1.5)
	vis.position = Vector2(holder_w * 0.5, 124)
	vis.idle_seed = float(index) * 1.7
	holder.add_child(vis)
	v.add_child(UiKit.label(String(data["title"]), 22, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UiKit.label(String(data["subtitle"]), 14, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var base: Dictionary = data["base"]
	var bars := UiKit.vbox(2)
	v.add_child(bars)
	var bw := card_w - 106.0
	_stat(bars, "Życie", float(base["health"]), 200.0, UiKit.HP, bw)
	_stat(bars, "Energia", float(base["energy"]), 130.0, UiKit.EN, bw)
	_stat(bars, "Szybkość", float(base["speed"]), 1.3, UiKit.ACCENT2, bw)
	_stat(bars, "Krytyk", float(base["crit"]) * 100.0, 20.0, UiKit.XP, bw)
	card.set_meta("id", id)
	return card

func _stat(parent: Control, name_text: String, value: float, maxv: float, col: Color, bar_w: float = 104.0) -> void:
	var h := UiKit.hbox(4)
	parent.add_child(h)
	var l := UiKit.label(name_text, 12, UiKit.DIM)
	l.custom_minimum_size = Vector2(66, 0)
	h.add_child(l)
	var b := UiBar.new()
	b.custom_minimum_size = Vector2(bar_w, 9)
	b.set_fill(col)
	b.set_value(value / maxv)
	h.add_child(b)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed():
		return
	if event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		_select(_sel + 1)
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		_select(_sel - 1)
	elif event.is_action_pressed("ui_accept"):
		_on_choose()
	elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		Audio.play("back")
		Flow.goto("menu")

func _select(i: int) -> void:
	_sel = wrapi(i, 0, _ids.size())
	Audio.play("select")
	var id := String(_ids[_sel])
	for c in _cards:
		var sel: bool = String(c.get_meta("id")) == id
		c.modulate = Color(1, 1, 1) if sel else Color(0.55, 0.58, 0.64)
		(c as PanelContainer).add_theme_stylebox_override("panel", UiKit.sb(UiKit.BG3 if sel else UiKit.BG2, 12, 2 if sel else 0, UiKit.ACCENT))
	# opis
	var data := CharacterDB.get_data(id)
	var cp := GameState.char_profile(id)
	_desc.text = String(data["desc"]) + "\n%s  ·  Poziom %d  ·  Zdobyte XP: %d / %d" % [
		String(data["subtitle"]), int(cp.get("level", 1)), int(cp.get("xp", 0)),
		CharacterDB.xp_for_level(int(cp.get("level", 1))),
	]
	for c in _info.get_children():
		c.queue_free()
	var sp: Dictionary = CharacterDB.SPECIALS.get(String(data.get("special", "")), {})
	if not sp.is_empty():
		_info.add_child(UiKit.label("Specjalny: %s — %s" % [String(sp["name"]), String(sp["desc"])], 15, UiKit.ACCENT2, HORIZONTAL_ALIGNMENT_CENTER))
	# przyciski
	var unlocked := GameState.is_unlocked(id)
	_go.disabled = not unlocked
	if unlocked:
		_unlock_btn.visible = false
		_go.text = "Wyrusz jako %s" % String(data["title"])
		if int(cp.get("level", 1)) > 1:
			_info.add_child(UiKit.label("Warto wziąć: rośnie z każdym poziomem.", 13, UiKit.GOOD, HORIZONTAL_ALIGNMENT_CENTER))
	else:
		_unlock_btn.visible = true
		var cur := GameState.unlock_currency(id)
		var cost := GameState.unlock_cost(id)
		_unlock_btn.text = "Odblokuj za %d %s" % [cost, "piór" if cur == "cod" else "złota"]
		var can := (GameState.cod() >= cost) if cur == "cod" else (GameState.gold() >= cost)
		_unlock_btn.add_theme_color_override("font_hover_color", UiKit.GOOD if can else UiKit.BAD)

func _on_unlock() -> void:
	if GameState.try_unlock(String(_ids[_sel])):
		_select(_sel)
	else:
		Audio.play("deny")

func _on_choose() -> void:
	var id := String(_ids[_sel])
	if not GameState.is_unlocked(id):
		Audio.play("deny")
		return
	Audio.play("confirm")
	on_chosen.emit(id)
