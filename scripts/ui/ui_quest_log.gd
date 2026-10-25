class_name UiQuestLog
extends Control

signal on_close

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	add_child(UiKit.bg_texture(Color(0.05, 0.06, 0.1)))
	add_child(UiKit.dim(Color(0.02, 0.02, 0.04, 0.6)))
	var outer := UiKit.vbox(8)
	UiKit.full(outer)
	outer.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(outer)
	outer.add_child(UiKit.title("DZIENNIK ZADAŃ", 40))
	var panel := UiKit.panel(UiKit.BG, 12)
	panel.custom_minimum_size = Vector2(780, 500)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	outer.add_child(panel)
	var v := UiKit.vbox(6)
	panel.add_child(v)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var list := UiKit.vbox(8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	_build(list)
	var close := UiKit.button("Zamknij  [Q]", 20)
	close.custom_minimum_size = Vector2(240, 44)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(func(): Audio.play("back"); on_close.emit())
	v.add_child(close)
	close.grab_focus()

func _build(list: Control) -> void:
	var chapter := GameState.story_chapter()
	var quest := GameState.story_quest()
	var step := GameState.story_step()
	var done: Array = GameState.story().get("done", [])
	for i in QuestDB.count():
		var c := QuestDB.chapter(i)
		var cid := String(c.get("id", ""))
		var is_done := done.has(cid)
		var is_current := i == chapter and quest != ""
		var card := UiKit.panel(UiKit.BG2, 10)
		list.add_child(card)
		var v := UiKit.vbox(4)
		card.add_child(v)
		var head := UiKit.hbox(8)
		v.add_child(head)
		var mark := "✓" if is_done else ("▶" if is_current else "•")
		var mark_col := UiKit.GOOD if is_done else (UiKit.ACCENT if is_current else UiKit.DIM)
		head.add_child(UiKit.label(mark, 22, mark_col))
		var name_text := "%s — %s" % [String(c.get("label", "")), String(c.get("title", ""))]
		var name_l := UiKit.label(name_text, 20, UiKit.TEXT if (is_done or is_current) else UiKit.DIM)
		name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(name_l)
		if not is_done and not is_current:
			head.add_child(UiKit.label("W przygotowaniu", 14, UiKit.DIM))
		v.add_child(UiKit.label(String(c.get("intro", "")), 15, UiKit.DIM))
		var objs: Array = c.get("objs", [])
		for j in objs.size():
			var line := String(objs[j])
			var col := UiKit.DIM
			var prefix := "· "
			if is_done:
				col = UiKit.GOOD
				prefix = "✓ "
			elif is_current:
				if j < step:
					col = UiKit.GOOD
					prefix = "✓ "
				elif j == step:
					col = UiKit.ACCENT
					prefix = "▶ "
				else:
					col = UiKit.DIM
			v.add_child(UiKit.label(prefix + line, 16, col))
		if is_current and ChapterExtras.has(cid):
			v.add_child(UiKit.label("Cele rozdziału:", 15, UiKit.ACCENT2))
			for p in ChapterExtras.progress(cid):
				var mk := "✓ " if bool(p["done"]) else ("▶ " if bool(p["required"]) else "· ")
				var cnt := "" if int(p["total"]) <= 1 else " (%d/%d)" % [int(p["count"]), int(p["total"])]
				v.add_child(UiKit.label(mk + String(p["text"]) + cnt + ("" if bool(p["required"]) else "  [opcjonalnie]"), 14, UiKit.GOOD if bool(p["done"]) else UiKit.TEXT))
		if is_current or is_done:
			v.add_child(UiKit.label("Nagroda: %s" % QuestDB.reward_text(cid), 14, Color(1, 0.85, 0.4)))
