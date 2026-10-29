class_name UiLoot
extends Control
## Okno łupu: zwłoki (przeszukiwanie) albo kradzież (kieszenie ofiary). Pokazuje złoto i przedmioty, każdy do zabrania
## jednym kliknięciem. `take(i)`: i >= 0 — przedmiot o tym indeksie, TAKE_GOLD — złoto, TAKE_ALL — wszystko (zwłoki).
## Okno zamyka Esc albo przycisk; host odświeża zawartość przez `refresh(box)`.

signal take(index: int)
signal on_close

const TAKE_GOLD := -1
const TAKE_ALL := -3

var _box: Dictionary = {}
var _list: VBoxContainer
var _title: Label
var _sub: Label
var _done := false

func setup(box: Dictionary) -> void:
	_box = box

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	add_child(UiKit.dim(Color(0.02, 0.02, 0.05, 0.6)))
	var center := CenterContainer.new()
	UiKit.full(center)
	add_child(center)
	var panel := UiKit.panel(Color(0.06, 0.07, 0.11, 0.97), 12)
	panel.custom_minimum_size = Vector2(640, 0)
	center.add_child(panel)
	var v := UiKit.vbox(8)
	panel.add_child(v)
	_title = UiKit.label("", 24, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_title)
	_sub = UiKit.label("", 15, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER)
	_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sub.custom_minimum_size = Vector2(600, 0)
	v.add_child(_sub)
	_list = UiKit.vbox(6)
	v.add_child(_list)
	var close := UiKit.button("Zamknij", 18)
	close.pressed.connect(_close)
	v.add_child(close)
	refresh(_box)

func refresh(box: Dictionary) -> void:
	_box = box
	if _list == null:
		return
	for c in _list.get_children():
		c.queue_free()
	var steal := String(box.get("mode", "corpse")) == "steal"
	_title.text = String(box.get("title", "Łup"))
	_sub.text = String(box.get("sub", "Wybierz, co zabrać." if not steal else "Każda rzecz to ryzyko: ofiara może zauważyć, że ją okradasz."))
	var items: Array = box.get("items", [])
	var gold := int(box.get("gold", 0))
	if gold > 0:
		var gb := UiKit.button("Weź złoto: %d zł" % gold, 18, UiKit.GOOD)
		gb.pressed.connect(func(): take.emit(TAKE_GOLD))
		_list.add_child(gb)
	for i in items.size():
		var e: Dictionary = items[i]
		var row := UiKit.panel(UiKit.BG2, 8)
		_list.add_child(row)
		var h := UiKit.hbox(10)
		row.add_child(h)
		h.add_child(UiKit.icon(Art.item_icon(String(e["id"]), 40), 40))
		var name := UiKit.label("%s ×%d" % [String(ItemDB.get_data(String(e["id"])).get("name", e["id"])), int(e.get("n", 1))], 17, ItemDB.rarity_color(String(e["id"])))
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(name)
		var b := UiKit.button("Weź", 16)
		var idx := i
		b.pressed.connect(func(): take.emit(idx))
		h.add_child(b)
	if gold <= 0 and items.is_empty():
		_list.add_child(UiKit.label("Pusto.", 18, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	elif not steal and (items.size() + (1 if gold > 0 else 0)) > 1:
		var all := UiKit.button("Weź wszystko", 18, UiKit.ACCENT)
		all.pressed.connect(func(): take.emit(TAKE_ALL))
		_list.add_child(all)

func _close() -> void:
	if _done:
		return
	_done = true
	Audio.play("back")
	on_close.emit()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _done:
		get_viewport().set_input_as_handled()
		_close()
