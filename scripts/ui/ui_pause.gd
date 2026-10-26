class_name UiPause
extends CanvasLayer
## Nakładka pauzy. Nie usuwa sceny etapu — tylko ją przyciemnia.

signal resume_pressed
signal loadout_pressed
signal attributes_pressed
signal skills_pressed
signal pets_pressed
signal settings_pressed
signal restart_pressed
signal menu_pressed
signal host_pressed(online: bool)
signal waves_pressed
signal arena_pressed
signal map_pressed
signal stash_pressed
signal achievements_pressed

var _panel: PanelContainer
var _root: Control

func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	UiKit.full(_root)
	add_child(_root)
	var dim := UiKit.dim(Color(0.02, 0.02, 0.05, 0.72))
	_root.add_child(dim)
	_panel = UiKit.panel(Color(0.07, 0.08, 0.12, 0.98), 14)
	_panel.custom_minimum_size = Vector2(400, 0)
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_root.add_child(_panel)
	var v := UiKit.vbox(3)
	_panel.add_child(v)
	v.add_child(UiKit.title("PAUZA", 40))
	v.add_child(UiKit.sep(6))
	var first := UiKit.button("Wracaj do walki", 20)
	first.custom_minimum_size = Vector2(606, 36)
	first.pressed.connect(func():
		Audio.play("confirm")
		resume_pressed.emit())
	v.add_child(first)
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 4)
	v.add_child(g)
	_btn(g, "Ekwipunek", func(): loadout_pressed.emit())
	_attr_button = _btn(g, "Atrybuty", func(): attributes_pressed.emit(), UiKit.ACCENT2)
	_skills_button = _btn(g, "Umiejętności", func(): skills_pressed.emit(), UiKit.ACCENT2)
	_btn(g, "Towarzysze", func(): pets_pressed.emit(), UiKit.ACCENT2)
	_btn(g, "Skrytka", func(): stash_pressed.emit(), UiKit.ACCENT)
	_btn(g, "Mapa świata (M)", func(): map_pressed.emit(), UiKit.ACCENT2)
	_btn(g, "Osiągnięcia", func(): achievements_pressed.emit(), UiKit.ACCENT)
	_btn(g, "Własne fale", func(): waves_pressed.emit(), Color(0.9, 0.5, 1.0))
	_btn(g, "Arena graczy (LAN / online)", func(): arena_pressed.emit(), Color(1.0, 0.45, 0.4))
	_btn(g, "Hostuj grę LAN", func(): host_pressed.emit(false), UiKit.GOOD)
	_btn(g, "Hostuj grę online", func(): host_pressed.emit(true), UiKit.GOOD)
	_btn(g, "Od nowa", func(): restart_pressed.emit())
	_btn(g, "Ustawienia", func(): settings_pressed.emit())
	_btn(g, "Wyjdź do menu", func(): menu_pressed.emit(), UiKit.BAD)
	v.add_child(UiKit.sep(6))
	var t := UiKit.label("WASD ruch · Shift sprint · J lekki · K ciężki · L unik · U blok · I rzut · O furia\n1-6 skile · E rozmowa/użycie · Q dziennik · T umiejętności", 13, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(t)
	_opts = UiKit.vbox(4)
	_opts.visible = false
	v.add_child(_opts)
	for entry in [["music", "Muzyka"], ["sfx", "Dźwięki"], ["shake", "Trzęsienie"]]:
		var key := String(entry[0])
		var b := UiKit.button("", 16)
		b.text = "%s: %s" % [String(entry[1]), "TAK" if GameState.setting(key) else "NIE"]
		b.pressed.connect(func():
			var on := GameState.toggle_setting(key)
			b.text = "%s: %s" % [String(entry[1]), "TAK" if on else "NIE"]
			Audio.play("select")
			if key == "music":
				Audio.set_music_enabled(on)
			elif key == "sfx":
				Audio.play("confirm"))
		_opts.add_child(b)
	v.add_child(UiKit.sep(4))
	_btn(v, "Usuń zapis", _do_reset)
	_refresh_attr_button()
	first.grab_focus()
	Audio.play("pause")

var _opts: VBoxContainer
var _attr_button: Button
var _skills_button: Button
var _confirm_reset := false

func refresh_attributes_button() -> void:
	_refresh_attr_button()

func _refresh_attr_button() -> void:
	if _attr_button == null or not is_instance_valid(_attr_button):
		return
	if _skills_button and is_instance_valid(_skills_button):
		var sp := GameState.skill_points()
		_skills_button.text = ("Umiejętności (%d)" % sp) if sp > 0 else "Umiejętności"
	var points := GameState.attr_points()
	_attr_button.text = ("Atrybuty (%d)" % points) if points > 0 else "Atrybuty"
	_attr_button.disabled = points <= 0

func _btn(parent: Control, text: String, cb: Callable, col: Color = UiKit.ACCENT) -> Button:
	var b := UiKit.button(text, 17, col)
	b.custom_minimum_size = Vector2(300, 34)
	b.pressed.connect(func():
		Audio.play("confirm")
		cb.call())
	parent.add_child(b)
	return b

func _toggle_opts() -> void:
	Audio.play("select")
	_opts.visible = not _opts.visible

func _do_reset() -> void:
	if _confirm_reset:
		GameState.reset_save()
		_confirm_reset = false
		GameState.toast.emit("Zapis usunięty.", UiKit.BAD)
	else:
		_confirm_reset = true
		GameState.toast.emit("Kliknij ponownie, aby usunąć zapis.", UiKit.BAD)

func open() -> void:
	visible = true

func close() -> void:
	visible = false
	queue_free()
