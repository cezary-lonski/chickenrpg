class_name UiHospital
extends Control
## Szpital: zdrowie strażników i peta. Życie nie wraca samo. Poległy leży w szpitalu, jego życie rośnie,
## a po 5 minutach gry wraca karetką. W budynku szpitala w wiosce można za złoto leczyć rannych
## i od razu wypisywać poległych.

signal on_close
signal act(kind: String, key: String)   # "heal" albo "revive"

var building := false
var _list: VBoxContainer

func setup(in_building: bool) -> void:
	building = in_building

static func max_hp_of(key: String) -> float:
	var lv := GameState.player_level()
	if key == "pet":
		var pid := String(GameState.pets().get("equipped", ""))
		var pd: Dictionary = PetDB.get_data(pid) if PetDB.has(pid) else {}
		return float(pd.get("hp", 40.0)) + 8.0 * float(lv)
	return 70.0 + 16.0 * float(lv)

static func heal_cost(key: String) -> int:
	var missing := maxf(0.0, max_hp_of(key) - GameState.support_hp(key, max_hp_of(key)))
	return maxi(1, int(ceil(missing)))

static func revive_cost() -> int:
	return 100 + 15 * GameState.player_level()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	add_child(UiKit.dim(Color(0.02, 0.02, 0.04, 0.9)))
	var root := UiKit.vbox(10)
	UiKit.full_margin(root, 60.0)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(root)
	root.add_child(UiKit.title("SZPITAL", 40))
	var sub := "Leczysz strażników i peta za złoto: ranni wracają do pełni sił, poległych możesz wypisać od razu. Bez zabiegu poległy wraca po 5 minutach." if building else "Życie nie wraca samo, a poległych leczy szpital: wracają po 5 minutach. Leczyć za złoto można w budynku szpitala w wiosce."
	root.add_child(UiKit.label(sub, 15, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	_list = UiKit.vbox(8)
	root.add_child(_list)
	var back := UiKit.button("Wróć", 22)
	back.custom_minimum_size = Vector2(240, 40)
	back.pressed.connect(func(): Audio.play("back"); on_close.emit())
	var wrap := UiKit.hbox(0)
	wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	wrap.add_child(back)
	root.add_child(UiKit.sep(8))
	root.add_child(wrap)
	back.grab_focus()
	refresh()

func refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	var n := 4 if QuestDB.act_of(maxi(0, GameState.story_chapter())) == 2 else 3
	for i in n:
		_list.add_child(_row(String(Ally.NAMES[i % Ally.NAMES.size()]), "ally:%d" % i))
	var pid := String(GameState.pets().get("equipped", ""))
	if pid != "" and PetDB.has(pid) and GameState.has_pet(pid):
		_list.add_child(_row("Towarzysz: %s" % String(PetDB.get_data(pid).get("name", pid)), "pet"))
	if building:
		_list.add_child(UiKit.label("Złoto: %d" % GameState.gold(), 16, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER))

func _fmt(sec: float) -> String:
	var t := int(ceil(sec))
	return "%d:%02d" % [t / 60, t % 60]

func _row(title: String, key: String) -> Control:
	var max_hp := max_hp_of(key)
	var p := UiKit.panel(UiKit.BG, 10)
	var h := UiKit.hbox(14)
	p.add_child(h)
	var name_l := UiKit.label(title, 18, UiKit.TEXT)
	name_l.custom_minimum_size = Vector2(270, 0)
	h.add_child(name_l)
	var fallen := GameState.is_fallen(key)
	var hp := GameState.support_hp(key, max_hp)
	var left := 0.0
	if fallen:
		# w szpitalu życie rośnie od zera do pełni w ciągu 5 minut
		left = GameState.hospital_left(key)
		hp = max_hp * (1.0 - left / GameState.HOSPITAL_SECS)
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = max_hp
	bar.value = hp
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(260, 20)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ratio := hp / maxf(1.0, max_hp)
	var col := UiKit.GOOD if ratio > 0.6 else (UiKit.ACCENT if ratio > 0.3 else UiKit.BAD)
	var fcol := Color(0.45, 0.7, 1.0) if fallen else col
	var fill := StyleBoxFlat.new()
	fill.bg_color = fcol
	bar.add_theme_stylebox_override("fill", fill)
	h.add_child(bar)
	h.add_child(UiKit.label("%d / %d" % [int(round(hp)), int(round(max_hp))], 17, fcol))
	if fallen:
		h.add_child(UiKit.label("wraca za %s" % _fmt(left), 17, UiKit.BAD))
		if building:
			var cost := revive_cost()
			var b := UiKit.button("Wypisz teraz (%d zł)" % cost, 16, UiKit.GOOD)
			b.disabled = GameState.gold() < cost
			b.pressed.connect(func(): act.emit("revive", key))
			h.add_child(b)
	elif building and hp < max_hp - 0.5:
		var hc := heal_cost(key)
		var b2 := UiKit.button("Ulecz (%d zł)" % hc, 16, UiKit.GOOD)
		b2.disabled = GameState.gold() < hc
		b2.pressed.connect(func(): act.emit("heal", key))
		h.add_child(b2)
	return p
