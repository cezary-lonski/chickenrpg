class_name UiMmoTree
extends UiMmoPanel
## Drzewko umiejętności na serwerze (jak w normalnej grze): punkty za poziomy, rangi, wymagania. Zakup wykonuje serwer.

func _init() -> void:
	super._init("DRZEWKO UMIEJĘTNOŚCI")

func apply_state(_data: Dictionary) -> void:
	if _box != null:
		_rebuild()

func _build() -> void:
	Mmo.me_received.connect(func(_i): _rebuild())
	_rebuild()

func _rebuild() -> void:
	_clear()
	var info: Dictionary = Mmo.my_info
	var cls := String(info.get("class", ""))
	var lv := int(info.get("level", 1))
	var tree: Dictionary = info.get("tree", {}) if info.get("tree") is Dictionary else {}
	_box.add_child(UiKit.label("Poziom %d  ·  Punkty umiejętności: %d  ·  Klasa: %s" % [lv, int(info.get("skill_points", 0)), String(ClassDatabase.get_data(cls).get("title", "—"))], 18, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER))
	_box.add_child(_wl("Za każdy poziom dostajesz 1 punkt. Kolejne rangi wymagają wyższego poziomu. Kupione umiejętności przypiszesz do slotów w ekwipunku (I).", 13, UiKit.DIM))
	var branches := SkillTreeDB.branches(cls)
	if branches.is_empty():
		_box.add_child(_wl("Ta klasa nie ma drzewka umiejętności.", 16, UiKit.DIM))
		return
	var by_branch := {}
	for id in SkillTreeDB.for_class(cls):
		var b := String(SkillTreeDB.node(String(id), cls)["branch"])
		if not by_branch.has(b):
			by_branch[b] = []
		by_branch[b].append(String(id))
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 8)
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_box.add_child(cols)
	for br in branches:
		if not by_branch.has(br):
			continue
		var bd: Dictionary = branches[br]
		var col := UiKit.panel(UiKit.BG, 8)
		col.custom_minimum_size = Vector2(228, 0)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cols.add_child(col)
		var v := UiKit.vbox(6)
		col.add_child(v)
		v.add_child(UiKit.label(String(bd["name"]), 16, bd["col"]))
		for id in by_branch[br]:
			v.add_child(_card(String(id), cls, lv, tree, bd["col"]))

func _card(id: String, cls: String, lv: int, tree: Dictionary, col: Color) -> Control:
	var n := SkillTreeDB.node(id, cls)
	var d := SkillDB.get_data(id)
	var rank := int(tree.get(id, 0))
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
		var ok := int(tree.get(String(r), 0)) >= 1 or ServerChars.free_skill(cls, String(r))
		v.add_child(_wl("↳ wymaga: %s" % String(SkillDB.get_data(String(r)).get("name", r)), 12, UiKit.GOOD if ok else UiKit.BAD))
	var chk := ServerChars.can_learn(cls, lv, tree, id)
	var btn := UiKit.button("Odblokuj (1 pkt)" if rank == 0 else "Ulepsz (1 pkt)", 13)
	if rank >= maxr:
		btn.text = "Maks. ranga"
		btn.disabled = true
	elif not bool(chk["ok"]):
		btn.disabled = true
		v.add_child(_wl(String(chk["reason"]), 12, UiKit.BAD))
	btn.pressed.connect(func():
		Audio.play("levelup", 1.2, -6.0)
		Mmo.send_inv("tree", id, ""))
	v.add_child(btn)
	return card
