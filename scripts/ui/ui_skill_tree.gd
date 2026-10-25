class_name UiSkillTree
extends Control
## Drzewko umiejętności: gałęzie, wymagania (poziom i poprzednie węzły), rangi i koszt.

signal on_close

var _points_label: Label
var _cols: HBoxContainer
var _info: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	add_child(UiKit.bg_texture(Color(0.05, 0.06, 0.1)))
	add_child(UiKit.dim(Color(0.02, 0.02, 0.04, 0.6)))
	var root := UiKit.vbox(6)
	UiKit.full(root)
	root.offset_left = 16.0
	root.offset_right = -16.0
	root.offset_top = 8.0
	root.offset_bottom = -8.0
	add_child(root)
	root.add_child(UiKit.title("DRZEWKO UMIEJĘTNOŚCI", 34))
	_points_label = UiKit.label("", 18, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(_points_label)
	root.add_child(UiKit.label("Za każdy poziom (do 100) dostajesz 1 punkt. Kolejne rangi wymagają wyższego poziomu.", 13, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	_cols = UiKit.hbox(8)
	scroll.add_child(_cols)
	_info = UiKit.label("", 14, UiKit.GOOD, HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(_info)
	var row := UiKit.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(row)
	var back := UiKit.button("Wróć", 20)
	back.pressed.connect(func(): Audio.play("back"); on_close.emit())
	row.add_child(back)
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed() and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause") or event.is_action_pressed("skill_tree")):
		get_viewport().set_input_as_handled()
		Audio.play("back")
		on_close.emit()

func _refresh() -> void:
	var cls := GameState.class_id()
	var lv := int(GameState._cp().get("level", 1))
	_points_label.text = "Poziom %d / %d  ·  Punkty umiejętności: %d  ·  Klasa: %s" % [lv, GameState.MAX_LEVEL, GameState.skill_points(), String(ClassDatabase.get_data(cls).get("title", "—"))]
	for c in _cols.get_children():
		c.queue_free()
	var by_branch := {}
	var branches := SkillTreeDB.branches(cls)
	for id in SkillTreeDB.for_class(cls):
		var b := String(SkillTreeDB.node(String(id), cls)["branch"])
		if not by_branch.has(b):
			by_branch[b] = []
		by_branch[b].append(String(id))
	for br in branches:
		if not by_branch.has(br):
			continue
		var bd: Dictionary = branches[br]
		var col := UiKit.panel(UiKit.BG, 8)
		col.custom_minimum_size = Vector2(228, 0)
		_cols.add_child(col)
		var v := UiKit.vbox(6)
		col.add_child(v)
		v.add_child(UiKit.label(String(bd["name"]), 16, bd["col"]))
		for id in by_branch[br]:
			v.add_child(_node_card(String(id), bd["col"]))

func _wl(text: String, size: int, col: Color) -> Label:
	var l := UiKit.label(text, size, col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(10, 0)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

func _node_card(id: String, col: Color) -> Control:
	var cls := GameState.class_id()
	var n := SkillTreeDB.node(id, cls)
	var d := SkillDB.get_data(id)
	var rank := int(GameState._tree().get(id, 0))
	var maxr := int(n["max_rank"])
	var card := UiKit.panel(UiKit.BG3 if rank > 0 else UiKit.BG2, 8)
	card.tooltip_text = "%s\nKoszt: %d energii · cd %.1fs" % [String(d.get("desc", "")), int(d.get("cost", 0.0)), float(d.get("cd", 0.0))]
	var v := UiKit.vbox(2)
	card.add_child(v)
	var dots := ""
	for i in maxr:
		dots += "●" if i < rank else "○"
	var head := UiKit.hbox(6)
	v.add_child(head)
	var chip := UiKit.panel(d.get("col", col), 4)
	chip.custom_minimum_size = Vector2(12, 12)
	head.add_child(chip)
	head.add_child(UiKit.label(String(d.get("name", id)), 15, UiKit.ACCENT if rank > 0 else UiKit.TEXT))
	v.add_child(UiKit.label(dots + "   wym. poz. %d" % SkillTreeDB.rank_level(id, rank + 1, cls), 12, UiKit.DIM))
	v.add_child(_wl(String(d.get("desc", "")), 12, UiKit.DIM))
	for r in n.get("req", []):
		var ok := int(GameState._tree().get(String(r), 0)) >= 1
		v.add_child(_wl("↳ wymaga: %s" % String(SkillDB.get_data(String(r)).get("name", r)), 12, UiKit.GOOD if ok else UiKit.BAD))
	var chk := GameState.can_learn(id)
	var btn := UiKit.button("Odblokuj (1 pkt)" if rank == 0 else "Ulepsz (1 pkt)", 13)
	if rank >= maxr:
		btn.text = "Maks. ranga"
		btn.disabled = true
	elif not bool(chk["ok"]):
		btn.disabled = true
		btn.tooltip_text = String(chk["reason"])
		v.add_child(_wl(String(chk["reason"]), 12, UiKit.BAD))
	btn.pressed.connect(func():
		if GameState.learn_skill(id):
			Audio.play("levelup", 1.2, -6.0)
			_info.text = "Nauczono: %s (ranga %d)" % [String(d.get("name", id)), GameState.skill_rank(id)]
			_refresh()
		else:
			Audio.play("deny"))
	v.add_child(btn)
	return card
