class_name UiShop
extends Control
## Sklep między etapami: broń, pancerz, akcesoria, mikstury. Kupno od razu
## wkłada przedmiot, jeśli slot jest pusty albo nowy jest lepszy.

signal on_close

var _gold_l: Label
var _cod_l: Label
var _tabs: Array = []
var _tab := 0
var _list: VBoxContainer
var _stats: VBoxContainer
var _hint: Label
var _equipped: Dictionary = {}

const TABS := [
	{"id": "weapon", "name": "BROŃ"},
	{"id": "armor", "name": "PANCERZ"},
	{"id": "helmet", "name": "HEŁMY"},
	{"id": "boots", "name": "BUTY"},
	{"id": "accessory", "name": "AKCESORIA"},
	{"id": "amulet", "name": "AMULETY"},
	{"id": "material", "name": "MATERIAŁY"},
	{"id": "pet_gear", "name": "PETY"},
	{"id": "pattern", "name": "WZORCE"},
	{"id": "consumable", "name": "MIKSTURY"},
	{"id": "throwable", "name": "DO RZUCANIA"},
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	add_child(UiKit.bg_texture(Color(0.07, 0.06, 0.05)))
	var root := UiKit.vbox(8)
	UiKit.full_margin(root)
	add_child(root)

	var head := UiKit.hbox(10)
	root.add_child(head)
	head.add_child(UiKit.title("SKLAR", 42))
	head.add_child(UiKit.spacer())
	var g := UiKit.hbox(4)
	g.add_child(UiKit.icon(Art.hud_icon("gold", 20, Color(1, 0.82, 0.3)), 20))
	_gold_l = UiKit.label(str(GameState.gold()), 22, Color(1, 0.85, 0.4))
	g.add_child(_gold_l)
	head.add_child(g)
	var c := UiKit.hbox(4)
	c.add_child(UiKit.icon(Art.hud_icon("cod", 20, Color(0.85, 0.9, 1)), 20))
	_cod_l = UiKit.label(str(GameState.cod()), 22, Color(0.88, 0.92, 1))
	c.add_child(_cod_l)
	head.add_child(c)

	# --- zakładki
	var tabs := UiKit.hbox(6)
	root.add_child(tabs)
	for i in TABS.size():
		var b := UiKit.button(String(TABS[i]["name"]), 17)
		b.pressed.connect(func(): _set_tab(i))
		tabs.add_child(b)
		_tabs.append(b)

	var body := UiKit.hbox(12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	var left := UiKit.panel(UiKit.BG, 12)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(left)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(sc)
	_list = UiKit.vbox(4)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_list)

	var right := UiKit.panel(UiKit.BG, 12)
	right.custom_minimum_size = Vector2(320, 0)
	body.add_child(right)
	var rv := UiKit.vbox(6)
	right.add_child(rv)
	rv.add_child(UiKit.label("TWÓJ KURCZAK", 18, UiKit.ACCENT))
	var sc2 := UiKit.panel(UiKit.BG2, 8)
	rv.add_child(sc2)
	_stats = UiKit.vbox(2)
	sc2.add_child(_stats)
	_hint = UiKit.label("Kupujesz w trakcie wyprawy. Ekwipunek zostaje z postacią na stałe.", 13, UiKit.DIM)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rv.add_child(_hint)

	var row := UiKit.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(row)
	var next_stage := StageDB.get_stage(int(GameState.run.get("stage_index", 0)))
	var go := UiKit.button("Do etapu %d: %s →" % [int(GameState.run.get("stage_index", 0)) + 1, String(next_stage["name"])], 22)
	go.custom_minimum_size = Vector2(460, 50)
	go.pressed.connect(func(): Audio.play("confirm"); on_close.emit())
	row.add_child(go)

	_set_tab(0)
	_refresh_stats()

func _set_tab(i: int) -> void:
	_tab = i
	Audio.play("select")
	for j in _tabs.size():
		_tabs[j].add_theme_stylebox_override("normal", UiKit.sb(UiKit.BG3 if j == i else UiKit.BG2, 8, 2 if j == i else 0, UiKit.ACCENT))
	_rebuild()

func _rebuild() -> void:
	for c in _list.get_children():
		c.queue_free()
	var slot := String(TABS[_tab]["id"])
	for id in ItemDB.by_slot(slot):
		# sklep sprzedaje tylko rzeczy za złoto i poniżej legendarnych (bez „gratisowych” legendarek)
		var sd := ItemDB.get_data(id)
		if int(sd.get("price", 0)) <= 0:
			continue
		if ItemDB.RARITIES.find(ItemDB.rarity_of(id)) >= ItemDB.RARITIES.find("legendarny"):
			continue
		_list.add_child(_make_row(id, slot))

func _make_row(id: String, slot: String) -> Control:
	var d := ItemDB.get_data(id)
	var price := int(d.get("price", 0))
	var owned := GameState.item_count(id) if slot in ["consumable", "throwable", "material", "pet_gear", "pattern"] else 0
	var row := UiKit.panel(UiKit.BG2, 8)
	var h := UiKit.hbox(8)
	row.add_child(h)
	h.add_child(UiKit.icon(Art.item_icon(id, 40), 40))
	var v := UiKit.vbox(1)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var is_equipped: bool = String(GameState.equipped().get(slot, "")) == id
	var is_owned: bool = GameState.owns_gear(id) if ItemDB.is_gear_slot(slot) else false
	var title := String(d["name"])
	if is_equipped:
		title += "  ✔"
	elif ItemDB.is_gear_slot(slot) and is_owned:
		title += "  (w ekwipunku)"
	elif owned > 0:
		title += "  (masz %d)" % owned
	v.add_child(UiKit.label(title, 17, UiKit.ACCENT if is_equipped else UiKit.TEXT))
	v.add_child(UiKit.label(String(d["desc"]), 13, UiKit.DIM))
	v.add_child(UiKit.label(_stats_text(d), 13, UiKit.GOOD))
	var b := UiKit.button("%d zł" % price if price > 0 else "gratis", 16)
	b.custom_minimum_size = Vector2(110, 36)
	if is_equipped or is_owned:
		b.disabled = true
	else:
		b.disabled = GameState.gold() < price
	b.pressed.connect(func(): _buy(id, slot, price, d))
	h.add_child(b)
	return row

func _stats_text(d: Dictionary) -> String:
	var names := {
		"strength": "Siła", "defense": "Obrona", "health": "Życie", "energy": "Energia",
		"speed": "Szybkość", "crit": "Krytyk", "fury": "Furia", "luck": "Łupy", "poise": "Pewność",
	}
	var out: Array = []
	for k in d.get("stats", {}):
		var v := float(d["stats"][k])
		var txt := "%+.0f%%" % (v * 100.0)
		if k == "health" or k == "energy":
			txt = "%+.0f" % v
		elif k == "crit" or k == "luck":
			txt = "%+.0f%%" % (v * 100.0)
		out.append("%s %s" % [String(names.get(k, k)), txt])
	if d.has("use"):
		var u: Dictionary = d["use"]
		var parts: Array = []
		if float(u.get("health", 0.0)) > 900.0:
			parts.append("pełne życie")
		elif float(u.get("health", 0.0)) > 0.0:
			parts.append("+%d życia" % int(u["health"]))
		if float(u.get("energy", 0.0)) > 0.0:
			parts.append("+%d energii" % int(minf(u["energy"], 999.0)))
		if u.has("buff_time"):
			parts.append("wzmocnienie na %ds" % int(u["buff_time"]))
		if not parts.is_empty():
			out.append("· ".join(parts))
	if d.has("throw"):
		var t: Dictionary = d["throw"]
		out.append("obrażenia %d, zasięg %d" % [int(t["damage"]), int(t["radius"])])
	return "  ".join(out)

func _buy(id: String, slot: String, price: int, d: Dictionary) -> void:
	if not GameState.spend(price):
		Audio.play("deny")
		GameState.toast.emit("Za mało złota.", UiKit.BAD)
		return
	Audio.play("coin")
	if slot in ["consumable", "throwable", "material", "pet_gear", "pattern"]:
		GameState.add_item(id, 1)
		GameState.commit_backpack()
		GameState.toast.emit("Kupiono: %s" % String(d["name"]), UiKit.GOOD)
	else:
		# trafia do ekwipunku postaci; jeśli to ulepszenie, od razu się zakłada
		GameState.add_gear(id)
		var old: String = String(GameState.equipped().get(slot, ""))
		if old == "" or _score(d) > _score(ItemDB.get_data(String(old))):
			GameState.equip_item(id)
			GameState.toast.emit("Kupiono i założono: %s" % String(d["name"]), UiKit.GOOD)
		else:
			GameState.toast.emit("Kupiono: %s (załóż w ekwipunku)" % String(d["name"]), UiKit.ACCENT2)
	_gold_l.text = str(GameState.gold())
	_cod_l.text = str(GameState.cod())
	_rebuild()
	_refresh_stats()

func _score(d: Dictionary) -> float:
	var s := 0.0
	for k in d.get("stats", {}):
		var v := float(d["stats"][k])
		if k == "crit" or k == "luck":
			s += v * 60.0
		else:
			s += v
	return s

func _refresh_stats() -> void:
	for c in _stats.get_children():
		c.queue_free()
	var s := GameState.compute_stats()
	var rows := [
		["Życie", "%.0f" % s["max_health"], UiKit.HP],
		["Energia", "%.0f" % s["max_energy"], UiKit.EN],
		["Siła", "%.2f" % s["strength"], UiKit.TEXT],
		["Obrona", "%.2f" % s["defense"], UiKit.TEXT],
		["Szybkość", "%.2f" % s["speed"], UiKit.ACCENT2],
		["Krytyk", "%.0f%%" % (s["crit"] * 100.0), UiKit.XP],
	]
	for r in rows:
		var h := UiKit.hbox(4)
		var a := UiKit.label(String(r[0]), 14, UiKit.DIM)
		a.custom_minimum_size = Vector2(100, 0)
		h.add_child(a)
		h.add_child(UiKit.label(String(r[1]), 14, r[2]))
		_stats.add_child(h)
	_stats.add_child(UiKit.sep(4))
	_stats.add_child(UiKit.label("WYPOSAŻONE", 13, UiKit.DIM))
	var eq := GameState.equipped()
	for slot in ItemDB.SLOT_ORDER:
		var it := String(eq.get(slot, ""))
		var h2 := UiKit.hbox(4)
		h2.add_child(UiKit.icon(Art.item_icon(it, 22), 22))
		h2.add_child(UiKit.label(String(ItemDB.get_data(it).get("name", "?")), 13, UiKit.TEXT))
		_stats.add_child(h2)
