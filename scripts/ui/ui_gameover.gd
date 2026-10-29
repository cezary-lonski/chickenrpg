class_name UiGameOver
extends Control
## Ekran po śmierci kurczaka: powtórka etapu albo powrót do sklepu/menu.

signal retry_pressed
signal menu_pressed

var _guest := false

func set_guest(guest: bool) -> void:
	_guest = guest

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	add_child(UiKit.dim(Color(0.08, 0.02, 0.02, 0.92)))
	var center := UiKit.vbox(6)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	UiKit.full(center)
	add_child(center)
	var t := UiKit.title("KONIEC WALKI", 60, UiKit.BAD)
	center.add_child(t)
	center.add_child(UiKit.label("Twoje pióra spadły na ziemię…", 22, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	if not GameState.last_death_loss.is_empty():
		center.add_child(UiKit.label("Utracone przedmioty (leżą przy twoich zwłokach — wróć po nie): " + ", ".join(GameState.last_death_loss), 18, UiKit.BAD, HORIZONTAL_ALIGNMENT_CENTER))
	center.add_child(UiKit.sep(26))
	center.add_child(UiKit.label("Wskrzesić może cię tylko Zwój Wskrzeszenia — nagroda za duże zadania poboczne (np. lutnia barda).", 16, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER))
	center.add_child(UiKit.sep(14))
	var row := UiKit.hbox(14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(row)
	var again := UiKit.button("Jeszcze raz", 24)
	again.custom_minimum_size = Vector2(300, 52)
	again.pressed.connect(func(): Audio.play("confirm"); retry_pressed.emit())
	row.add_child(again)
	var back := UiKit.button("Menu", 20)
	back.pressed.connect(func(): Audio.play("back"); menu_pressed.emit())
	row.add_child(back)
	center.add_child(UiKit.sep(20))
	if _guest:
		again.visible = false
		center.add_child(UiKit.label("Host zdecyduje o powtórce.", 15, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
		back.grab_focus()
	else:
		center.add_child(UiKit.label("Naciśnij Enter, aby spróbować ponownie", 15, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
		again.grab_focus()
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.5)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed() and event.is_action_pressed("ui_accept") and not _guest:
		retry_pressed.emit()
	elif event.is_pressed() and event.is_action_pressed("ui_cancel"):
		menu_pressed.emit()
