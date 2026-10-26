class_name UiMmoShop
extends PanelContainer
## Sklep kupca na serwerze: lista towarów (kup) i plecak (sprzedaj za 40% ceny). Zakupy sprawdza serwer.

signal closed

var _gold: Label
var _list: ItemList
var _ids: Array = []
var _stock: Array = []
var _mode := "buy"
var _tab_buy: Button
var _tab_sell: Button
var _detail: Label

func _ready() -> void:
	add_theme_stylebox_override("panel", UiKit.sb(Color(0.05, 0.04, 0.08, 0.96), 12, 3, Color(0.17, 0.11, 0.06)))
	custom_minimum_size = Vector2(620, 520)
	var v := UiKit.vbox(6)
	add_child(v)
	var head := UiKit.hbox(10)
	v.add_child(head)
	var t := UiKit.label("SKLEP KUPCA", 22, UiKit.ACCENT)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	_gold = UiKit.label("", 18, UiKit.EN)
	head.add_child(_gold)
	var tabs := UiKit.hbox(8)
	v.add_child(tabs)
	_tab_buy = UiKit.button("Kup", 16)
	_tab_buy.pressed.connect(func(): _set_mode("buy"))
	tabs.add_child(_tab_buy)
	_tab_sell = UiKit.button("Sprzedaj", 16)
	_tab_sell.pressed.connect(func(): _set_mode("sell"))
	tabs.add_child(_tab_sell)
	_list = ItemList.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.item_activated.connect(_on_activated)
	_list.item_selected.connect(_on_selected)
	v.add_child(_list)
	_detail = UiKit.label("Dwuklik: kup / sprzedaj 1 sztukę.", 13, UiKit.DIM)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size = Vector2(0, 40)
	v.add_child(_detail)
	var close := UiKit.button("Zamknij", 18)
	close.pressed.connect(func(): closed.emit())
	v.add_child(close)

func setup(stock: Array, gold: int) -> void:
	_stock = stock
	_gold.text = "Złoto: %d" % gold
	_refill()

func _set_mode(m: String) -> void:
	_mode = m
	_refill()

func _refill() -> void:
	_list.clear()
	_ids.clear()
	if _mode == "buy":
		for id in _stock:
			var d := ItemDB.get_data(String(id))
			_list.add_item("%s — %d zł" % [String(d.get("name", id)), ItemDB.price_of(String(id))], Art.item_icon(String(id), 24))
			_list.set_item_custom_fg_color(_list.item_count - 1, ItemDB.rarity_color(String(id)))
			_ids.append(String(id))
	else:
		for e in Mmo.my_info.get("inv", []):
			var id2 := String(e["id"])
			var price := int(round(float(ItemDB.price_of(id2)) * 0.4))
			_list.add_item("%s x%d — %d zł/szt." % [String(ItemDB.get_data(id2).get("name", id2)), int(e["n"]), price], Art.item_icon(id2, 24))
			_list.set_item_custom_fg_color(_list.item_count - 1, ItemDB.rarity_color(id2))
			_ids.append(id2)

func _on_selected(i: int) -> void:
	if i >= 0 and i < _ids.size():
		var d := ItemDB.get_data(String(_ids[i]))
		_detail.text = "%s  %s" % [String(d.get("desc", "")), str(d.get("stats", {})) if d.get("stats", {}).size() > 0 else ""]

func _on_activated(i: int) -> void:
	if i < 0 or i >= _ids.size():
		return
	Audio.play("select")
	Mmo.send_act("buy" if _mode == "buy" else "sell", {"id": _ids[i], "n": 1})
