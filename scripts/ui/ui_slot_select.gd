class_name UiSlotSelect
extends Control
## Ekran wyboru slotu zapisu: 3 sloty — nowy (nadpisz), kontynuuj lub usuń.

signal on_start(slot: int, create_new: bool)

const SLOTS := 3

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	add_child(UiKit.bg_texture(Color(0.05, 0.06, 0.1)))
	add_child(UiKit.dim(Color(0.02, 0.02, 0.04, 0.6)))
	var root := UiKit.vbox(10)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	UiKit.full_margin(root)
	add_child(root)
	root.add_child(UiKit.title("WYBIERZ ZAPIS", 42))
	root.add_child(UiKit.label("Wybierz slot, aby kontynuować, albo zacznij nową grę", 16, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))

	var grid := UiKit.hbox(14)
	grid.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(grid)
	for i in range(1, SLOTS + 1):
		grid.add_child(_slot_card(i))

	var row := UiKit.hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(UiKit.sep(10))
	root.add_child(row)
	var back := UiKit.button("Wstecz", 22)
	back.pressed.connect(func(): Audio.play("back"); Flow.goto("menu"))
	row.add_child(back)
	_confirm_btns.clear()
	_confirm_delete.clear()
	_dialog = FileDialog.new()
	_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_dialog.use_native_dialog = true
	_dialog.title = "Importuj zapis gry"
	_dialog.filters = PackedStringArray(["*.json ; Zapis gry (.json)"])
	_dialog.file_selected.connect(_on_import_file)
	add_child(_dialog)
	_status = UiKit.label("", 16, UiKit.GOOD, HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(_status)

var _dialog: FileDialog
var _status: Label
var _import_slot := 1
var _confirm_import: Dictionary = {}

func _start_import(slot: int) -> void:
	_import_slot = slot
	_dialog.popup_centered_ratio(0.7)

func _on_import_file(path: String) -> void:
	var err := GameState.import_save(path, _import_slot)
	if err != "":
		Audio.play("deny")
		_status.text = err
		_status.add_theme_color_override("font_color", UiKit.BAD)
		return
	Audio.play("confirm")
	_status.text = "Zaimportowano zapis do slotu %d." % _import_slot
	_status.add_theme_color_override("font_color", UiKit.GOOD)
	await get_tree().create_timer(0.7).timeout
	Flow.goto("slots")

var _confirm_btns: Dictionary = {}
var _confirm_delete: Dictionary = {}

func _slot_card(slot: int) -> PanelContainer:
	var info := GameState.slot_info(slot)
	var card := UiKit.panel(UiKit.BG, 12)
	card.custom_minimum_size = Vector2(300, 260)
	var v := UiKit.vbox(6)
	card.add_child(v)
	v.add_child(UiKit.label("SLOT %d" % slot, 22, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER))

	var exists := bool(info.get("exists", false))
	if exists and bool(info.get("broken", false)):
		v.add_child(UiKit.label("Uszkodzony zapis", 15, UiKit.BAD, HORIZONTAL_ALIGNMENT_CENTER))
	elif exists:
		v.add_child(UiKit.label("Rozdział: %d / %d" % [maxi(int(info.get("chapter", 0)), 1), QuestDB.count()], 16, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
		v.add_child(UiKit.label("Ukończone: %d" % int(info.get("done", 0)), 15, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
		v.add_child(UiKit.label("Poziom: %d   ·   Złoto: %d" % [int(info.get("level", 1)), int(info.get("gold", 0))], 15, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	else:
		v.add_child(UiKit.label("Pusty slot", 16, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))

	v.add_child(UiKit.sep(8))

	# import zapisu z pliku (przy istniejącym slocie najpierw potwierdzenie nadpisania)
	var imp := UiKit.button("Importuj zapis…", 15, UiKit.GOOD)
	imp.custom_minimum_size = Vector2(260, 36)
	_confirm_import[slot] = false
	imp.pressed.connect(func():
		if exists and not bool(_confirm_import.get(slot, false)):
			_confirm_import[slot] = true
			imp.text = "Nadpisze zapis. Kliknij ponownie"
			Audio.play("deny")
			return
		_start_import(slot))
	v.add_child(imp)

	# przycisk główny: Kontynuuj / Nowa gra
	var main := UiKit.button("", 20)
	main.custom_minimum_size = Vector2(260, 44)
	main.text = "Kontynuuj" if exists else "Nowa gra"
	main.pressed.connect(func():
		Audio.play("confirm")
		on_start.emit(slot, not exists))
	v.add_child(main)

	# nadpisz (nowa gra) — tylko gdy slot istnieje
	if exists:
		_confirm_btns[slot] = false
		var over := UiKit.button("Nowa gra (nadpisz)", 15, UiKit.ACCENT2)
		over.custom_minimum_size = Vector2(260, 36)
		over.pressed.connect(func():
			if bool(_confirm_btns.get(slot, false)):
				Audio.play("confirm")
				on_start.emit(slot, true)
			else:
				_confirm_btns[slot] = true
				over.text = "Na pewno? Kliknij ponownie"
				Audio.play("deny"))
		v.add_child(over)

		# usuń
		_confirm_delete[slot] = false
		var del := UiKit.button("Usuń zapis", 15, UiKit.BAD)
		del.custom_minimum_size = Vector2(260, 36)
		del.pressed.connect(func():
			if bool(_confirm_delete.get(slot, false)):
				GameState.delete_slot(slot)
				Audio.play("die")
				Flow.goto("slots")
			else:
				_confirm_delete[slot] = true
				del.text = "Na pewno usunąć?"
				Audio.play("deny"))
		v.add_child(del)

	return card
