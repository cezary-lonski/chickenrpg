class_name UiMmoTravel
extends UiMmoPanel
## Mapa świata na serwerze (klawisz M — zmienisz go w Ustawieniach): klikasz osiągnięte miejsce i podróżujesz do jego
## rozdziału. Stan (rozdział, najdalszy osiągnięty) pochodzi z karty postaci; podróż robi serwer.

var _canvas: UiTravelMap._MapCanvas
var _info: Label
var _go: Button
var _sel := -1

func _init() -> void:
	super._init("MAPA ŚWIATA")

func _cur() -> int:
	return clampi(int(Mmo.my_info.get("chapter", 0)), 0, QuestDB.count() - 1)

func _best() -> int:
	return maxi(int(Mmo.my_info.get("best", 0)), _cur())

func _build() -> void:
	_box.add_child(UiKit.label("Kliknij miejsce, do którego chcesz dotrzeć. Zablokowane są jeszcze nieodkryte — odkryjesz je, pokonując wcześniejsze etapy.", 15, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var holder := CenterContainer.new()
	_box.add_child(holder)
	_canvas = UiTravelMap._MapCanvas.new()
	_canvas.custom_minimum_size = UiTravelMap.MAP_SIZE
	_canvas.best = _best()
	_canvas.current = _cur()
	_canvas.selected.connect(_select)
	holder.add_child(_canvas)
	_info = UiKit.label("", 17, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.custom_minimum_size = Vector2(1000, 54)
	_box.add_child(_info)
	_go = UiKit.button("Podróżuj", 22, UiKit.GOOD)
	_go.custom_minimum_size = Vector2(240, 48)
	_go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_go.pressed.connect(func():
		if _sel < 0 or _sel > _best():
			Audio.play("deny")
			return
		Audio.play("confirm")
		Mmo.send_act("travel", {"index": _sel})
		closed.emit())
	_box.add_child(_go)
	_select(_cur())

func _select(i: int) -> void:
	Audio.play("select")
	_sel = i
	_canvas.sel = i
	var cur := _cur()
	var reached := i <= _best()
	var nm := PlaceDB.name_of(i)
	_canvas.route = [cur] + PlaceDB.route(cur, i) + [i] if i != cur else [cur]
	if i == cur:
		_info.text = "%s — tu jesteś." % nm
	elif not reached:
		_info.text = "%s — zablokowane. Odkryjesz je, pokonując wcześniejsze etapy." % nm
	else:
		_info.text = "%s — możesz tam podróżować (powtórka rozdziału; fabuła pójdzie dalej od niego)." % nm
	_go.disabled = i == cur or not reached

func apply_state(_data: Dictionary) -> void:
	pass

func cancel_or_close() -> bool:
	return true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("world_map"):
		get_viewport().set_input_as_handled()
		closed.emit()
