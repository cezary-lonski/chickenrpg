class_name UiAchievements
extends Control
signal on_close
## Ekran osiągnięć i dziennika odkryć.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	add_child(UiKit.bg_texture(Color(0.05, 0.06, 0.1)))
	add_child(UiKit.dim(Color(0.02, 0.02, 0.04, 0.6)))
	var root := UiKit.vbox(8)
	UiKit.full_margin(root)
	add_child(root)
	root.add_child(UiKit.title("OSIĄGNIĘCIA", 40))
	root.add_child(UiKit.label("Odblokowano %d / %d" % [AchievementDB.count_done(), AchievementDB.DEFS.size()], 16, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var list := UiKit.vbox(6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	list.add_child(UiKit.label("Dziennik odkryć", 20, UiKit.ACCENT))
	list.add_child(UiKit.label("Sekretne komnaty: %d   ·   Jaskinie: %d   ·   Legendarne przedmioty: %d   ·   Pojedynki: %d   ·   Wyzwania (rekord): %d rund" % [
		AchievementDB.value("rooms"), AchievementDB.value("caves"), AchievementDB.value("legend"), AchievementDB.value("duels"), AchievementDB.value("challenge_best")], 15, UiKit.TEXT))
	list.add_child(UiKit.sep(6))
	list.add_child(UiKit.label("Osiągnięcia", 20, UiKit.ACCENT))
	for d in AchievementDB.DEFS:
		list.add_child(_row(d))
	var back := UiKit.button("Wstecz", 22)
	back.custom_minimum_size = Vector2(240, 40)
	back.pressed.connect(func(): Audio.play("back"); on_close.emit())
	var wrap := UiKit.hbox(0)
	wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	wrap.add_child(back)
	root.add_child(wrap)

func _row(d: Dictionary) -> Control:
	var done := AchievementDB.is_done(d)
	var cur := mini(AchievementDB.value(String(d["stat"])), AchievementDB.need_of(d))
	var p := UiKit.panel(Color(0.18, 0.22, 0.1, 0.9) if done else UiKit.BG, 8)
	var h := UiKit.hbox(14)
	p.add_child(h)
	h.add_child(UiKit.label("★" if done else "☆", 26, UiKit.ACCENT if done else UiKit.DIM))
	var v := UiKit.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UiKit.label(String(d["name"]), 18, UiKit.ACCENT if done else UiKit.TEXT))
	v.add_child(UiKit.label(String(d["desc"]), 14, UiKit.DIM))
	h.add_child(UiKit.label("Ukończone" if done else "%d / %d" % [cur, AchievementDB.need_of(d)], 15, UiKit.GOOD if done else UiKit.DIM))
	return p
