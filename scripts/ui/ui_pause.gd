class_name UiPause
extends CanvasLayer
## Nakładka pauzy. Nie usuwa sceny etapu — tylko ją przyciemnia.

signal resume_pressed
signal loadout_pressed
signal settings_pressed
signal restart_pressed
signal menu_pressed

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
	_panel.position = Vector2(-200, -230)
	_root.add_child(_panel)
	var v := UiKit.vbox(8)
	_panel.add_child(v)
	v.add_child(UiKit.title("PAUZA", 44))
	v.add_child(UiKit.sep(6))
	var first := UiKit.button("Wracaj do walki", 20)
	first.custom_minimum_size = Vector2(360, 44)
	first.pressed.connect(func():
		Audio.play("confirm")
		resume_pressed.emit())
	v.add_child(first)
	_btn(v, "Ekwipunek", func(): loadout_pressed.emit())
	_btn(v, "Od nowa", func(): restart_pressed.emit())
	_btn(v, "Ustawienia", func(): settings_pressed.emit())
	_btn(v, "Wyjdź do menu", func(): menu_pressed.emit(), UiKit.BAD)
	v.add_child(UiKit.sep(6))
	var t := UiKit.label("A/D ruch · Shift sprint · spacja skok (2x stamina) · J lekki · K ciężki\nL unik · U blok · I rzut · O furia · 1-6 skile", 13, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER)
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
	first.grab_focus()
	Audio.play("pause")

var _opts: VBoxContainer
var _confirm_reset := false

func _btn(parent: Control, text: String, cb: Callable, col: Color = UiKit.ACCENT) -> void:
	var b := UiKit.button(text, 20, col)
	b.custom_minimum_size = Vector2(360, 44)
	b.pressed.connect(func():
		Audio.play("confirm")
		cb.call())
	parent.add_child(b)

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
