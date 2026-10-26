class_name UiHospital
extends Control
## Szpital: licznik zdrowia strażników i peta. Poległy towarzysz leży w szpitalu i wraca karetką,
## gdy bohater zdobędzie 5 poziomów od jego śmierci. Życie nie regeneruje się samo.

signal on_close

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	add_child(UiKit.dim(Color(0.02, 0.02, 0.04, 0.8)))
	var root := UiKit.vbox(10)
	UiKit.full_margin(root, 80.0)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(root)
	root.add_child(UiKit.title("SZPITAL", 40))
	root.add_child(UiKit.label("Stan zdrowia strażników i towarzysza. Życie nie wraca samo — poległych przywozi karetka po 5 poziomach.", 15, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var lv := GameState.player_level()
	var n := 4 if QuestDB.act_of(maxi(0, GameState.story_chapter())) == 2 else 3
	for i in n:
		root.add_child(_row(String(Ally.NAMES[i % Ally.NAMES.size()]), "ally:%d" % i, 70.0 + 16.0 * float(lv)))
	var pid := String(GameState.pets().get("equipped", ""))
	if pid != "" and PetDB.has(pid) and GameState.has_pet(pid):
		var pd: Dictionary = PetDB.get_data(pid)
		var pmax := (float(pd.get("hp", 40.0)) + 8.0 * float(lv))
		root.add_child(_row("Towarzysz: %s" % String(pd.get("name", pid)), "pet", pmax))
	var back := UiKit.button("Wróć", 22)
	back.custom_minimum_size = Vector2(240, 40)
	back.pressed.connect(func(): Audio.play("back"); on_close.emit())
	var wrap := UiKit.hbox(0)
	wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	wrap.add_child(back)
	root.add_child(UiKit.sep(8))
	root.add_child(wrap)
	back.grab_focus()

func _row(title: String, key: String, max_hp: float) -> Control:
	var p := UiKit.panel(UiKit.BG, 10)
	var h := UiKit.hbox(16)
	p.add_child(h)
	var name_l := UiKit.label(title, 18, UiKit.TEXT)
	name_l.custom_minimum_size = Vector2(300, 0)
	h.add_child(name_l)
	if GameState.is_fallen(key):
		var left := maxi(0, int((GameState.rpg.get("fallen", {}) as Dictionary)[key]) - GameState.player_level())
		h.add_child(UiKit.label("W szpitalu — wraca za %d poziom%s" % [left, "" if left == 1 else ("y" if left in [2, 3, 4] else "ów")], 17, UiKit.BAD))
		return p
	var hp := GameState.support_hp(key, max_hp)
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = max_hp
	bar.value = hp
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(320, 20)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ratio := hp / maxf(1.0, max_hp)
	var col := UiKit.GOOD if ratio > 0.6 else (UiKit.ACCENT if ratio > 0.3 else UiKit.BAD)
	var fill := StyleBoxFlat.new()
	fill.bg_color = col
	bar.add_theme_stylebox_override("fill", fill)
	h.add_child(bar)
	h.add_child(UiKit.label("%d / %d" % [int(round(hp)), int(round(max_hp))], 17, col))
	return p
