class_name UiMmoPanel
extends Control
## Wspólna baza pełnoekranowych paneli serwera (szpital, skrytka, laboratorium, pety): ciemne tło, tytuł, przycisk zamknięcia.
## Dane panelu przychodzą z serwera (apply_state); akcje wracają przez Mmo.send_act.

signal closed

var _box: VBoxContainer
var _msg: Label
var _title_text := ""

func _init(title: String = "") -> void:
	_title_text = title

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	var solid := ColorRect.new()
	solid.color = Color(0.05, 0.05, 0.08, 1.0)
	UiKit.full(solid)
	add_child(solid)
	var root := UiKit.vbox(8)
	UiKit.full_margin(root, 24.0)
	add_child(root)
	root.add_child(UiKit.title(_title_text, 36))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(sc)
	_box = UiKit.vbox(8)
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_box)
	_msg = UiKit.label("", 15, UiKit.ACCENT2, HORIZONTAL_ALIGNMENT_CENTER)
	_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_msg)
	var back := UiKit.button("Zamknij", 20)
	back.pressed.connect(func(): Audio.play("back"); closed.emit())
	root.add_child(back)
	_build()

## Nadpisywane: tworzy zawartość panelu.
func _build() -> void:
	pass

func apply_state(_data: Dictionary) -> void:
	pass

## Esc: true = zamknij okno; false = panel sam obsłużył anulowanie (np. przerwał minigrę).
func cancel_or_close() -> bool:
	return true

func _clear() -> void:
	for c in _box.get_children():
		c.queue_free()

func _wl(text: String, size: int, col: Color) -> Label:
	var l := UiKit.label(text, size, col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(10, 0)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

func _count(id: String) -> int:
	var n := 0
	for e in Mmo.my_info.get("inv", []):
		if String(e["id"]) == id:
			n += int(e["n"])
	return n
