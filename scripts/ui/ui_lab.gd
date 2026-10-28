class_name UiLab
extends Control
## Laboratorium:
## (1) Pierwiastek BU powstaje z ofiary: poświęcasz BROŃ (rzadką lub lepszą) — 1 broń daje 1 BU,
##     zmniejszasz się do rozmiaru atomu i zjadasz wszystkie jądra atomowe przedmiotu.
##     Na końcu następuje wybuch — na ekranie sypią się okna błędów — a przedmiot zamienia się w BU.
## (2) Z węgla, diamentu, kurczalu i 3 BU powstaje sztabka kurczalium.

signal on_close

const KURCZALIUM_COST := {"wegiel": 1, "krysztal_cienia": 1, "sztabka_kurczalu": 2, "pierwiastek_bu": 3}
const TIME_LIMIT := 30.0
const ERROR_COUNT := 5000
const ARENA := Vector2(1000, 400)
const ERRORS := [
	"ERROR 0x%X: jądro atomowe niestabilne",
	"FATAL: BU_OVERFLOW w sektorze %d",
	"Segmentation fault (core dumped)",
	"KERNEL PANIC — reaktor przeciążony",
	"Nie można odnaleźć pliku: legenda.exe",
	"WARNING: masa krytyczna przekroczona",
	"Unhandled exception: Item == null",
	"Błąd krytyczny: rzeczywistość nie odpowiada",
	"ERROR: stack overflow (poziom %d)",
	"Zasilanie BU na poziomie 9000%",
]

const LAB := Color(0.18, 0.71, 0.67)
const LAB_BG := Color(0.02, 0.13, 0.15, 0.62)
const LAB_BTN := Color(0.11, 0.27, 0.31, 0.94)
const LAB_TXT := Color(0.89, 0.98, 0.97)
## Historyjka warzenia sztabki kurczalium w kotle: składniki wpadają po kolei, a ty mieszasz.
const STORY := [
	{"id": "wegiel", "text": "Rozpalasz ogień pod kotłem i wrzucasz kawałek węgla. Kocioł syczy i puszcza czarny dym — mieszaj, żeby się nie przypalił!", "col": Color(0.25, 0.22, 0.24)},
	{"id": "krysztal_cienia", "text": "Diament rozpuszcza się w gęstniejącej mazi i cała zawartość zaczyna lśnić fioletem. Mieszaj dalej!", "col": Color(0.5, 0.3, 0.8)},
	{"id": "sztabka_kurczalu", "text": "Dwie sztabki kurczalu topią się w srebrną ciecz. Kury w całej wsi gdaczą ze strachu. Mieszaj mocniej!", "col": Color(0.7, 0.75, 0.85)},
	{"id": "pierwiastek_bu", "text": "Na koniec wpuszczasz trzy pierwiastki BU. Kocioł huczy, bąble pękają tęczą… Mieszaj, aż wszystko zastygnie w kurczalium!", "col": Color(1.0, 0.7, 0.2)},
]
const STIR_TURNS := 1.6
var _stage := 0
var _stir := 0.0
var _spoon := 0.0
var _last_ma := 0.0
var _have_ma := false
var _drop := 0.0
var _bubbles: Array = []
var _story: Label
var _liq := Color(0.2, 0.2, 0.25)
var _phase := "menu"
var _box: VBoxContainer
var _msg: Label
var _root: VBoxContainer
var _arena: Control
var _timer_label: Label

# stan minigry
var _item_id := ""
var _item_idx := -1
var _tier_bonus := 3
var _atoms: Array = []
var _total := 0
var _eaten := 0
var _t := 0.0
var _pp := Vector2.ZERO
var _pr := 70.0
var _err_layer: Control
var _shake := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	add_child(UiKit.bg_texture(Color(0.04, 0.08, 0.09)))
	add_child(UiKit.dim(Color(0.0, 0.2, 0.22, 0.22)))
	add_child(_scan())
	_root = UiKit.vbox(8)
	UiKit.full_margin(_root)
	add_child(_root)
	_root.add_child(UiKit.title("LABORATORIUM", 38, Color(0.56, 0.89, 0.85)))
	var p := UiKit.panel(LAB_BG, 12)
	_lab_panel(p)
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root.add_child(p)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p.add_child(sc)
	_box = UiKit.vbox(8)
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_box)
	_msg = UiKit.label("", 15, UiKit.ACCENT2, HORIZONTAL_ALIGNMENT_CENTER)
	_root.add_child(_msg)
	var row := UiKit.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_root.add_child(row)
	var back := UiKit.button("Wyjdź z laboratorium", 20)
	back.pressed.connect(func(): Audio.play("back"); if _phase == "menu": on_close.emit())
	row.add_child(back)
	_skin(row)
	_err_layer = Control.new()
	UiKit.full(_err_layer)
	_err_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_err_layer.z_index = 50
	add_child(_err_layer)
	_enter("menu")

## Siatka i linie skanowania w motywie laboratoryjnym.
func _scan() -> Control:
	var c := Control.new()
	UiKit.full(c)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var r := c.size
		for x in range(0, int(r.x), 40):
			c.draw_line(Vector2(x, 0), Vector2(x, r.y), Color(0.56, 0.89, 0.85, 0.05), 1.0)
		for y in range(0, int(r.y), 4):
			c.draw_line(Vector2(0, y), Vector2(r.x, y), Color(0.56, 0.89, 0.85, 0.04), 1.0))
	return c

func _lab_box(bg: Color, bw: int, bc: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_border_width_all(bw)
	sb.border_color = bc
	sb.set_corner_radius_all(2)
	sb.shadow_color = Color(LAB.r, LAB.g, LAB.b, 0.3)
	sb.shadow_size = 6
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

func _lab_panel(p: PanelContainer) -> void:
	p.add_theme_stylebox_override("panel", _lab_box(LAB_BG, 2, LAB))

## Przemalowuje przyciski i panele w drzewie na styl laboratorium.
func _skin(n: Node) -> void:
	if n is Button:
		var b := n as Button
		b.add_theme_stylebox_override("normal", _lab_box(LAB_BTN, 2, LAB))
		b.add_theme_stylebox_override("hover", _lab_box(LAB_BTN.lightened(0.15), 2, Color(0.56, 0.89, 0.85)))
		b.add_theme_stylebox_override("focus", _lab_box(LAB_BTN.lightened(0.1), 2, Color(0.56, 0.89, 0.85)))
		b.add_theme_stylebox_override("pressed", _lab_box(LAB_BTN.darkened(0.2), 2, LAB))
		b.add_theme_stylebox_override("disabled", _lab_box(Color(0.1, 0.2, 0.22, 0.5), 2, Color(LAB.r, LAB.g, LAB.b, 0.35)))
		b.add_theme_color_override("font_color", LAB_TXT)
	elif n is PanelContainer:
		(n as PanelContainer).add_theme_stylebox_override("panel", _lab_box(Color(0.06, 0.25, 0.28, 0.5), 2, Color(LAB.r, LAB.g, LAB.b, 0.7)))
	for c in n.get_children():
		_skin(c)

func _wl(text: String, size: int, col: Color) -> Label:
	var l := UiKit.label(text, size, col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(10, 0)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

func _enter(phase: String) -> void:
	_phase = phase
	for c in _box.get_children():
		c.queue_free()
	_arena = null
	match phase:
		"menu": _build_menu()
		"eat": _build_eat()
		"kociol": _build_kociol()
	_skin(_box)

func _count_line(id: String, need: int) -> Control:
	var have := GameState.item_count(id)
	var h := UiKit.hbox(6)
	h.add_child(UiKit.icon(Art.item_icon(id, 24), 24))
	h.add_child(UiKit.label("%s: %d / %d" % [String(ItemDB.get_data(id).get("name", id)), have, need], 15, UiKit.GOOD if have >= need else UiKit.BAD))
	return h

## Bronie z plecaka o rzadkości rzadkiej lub wyższej: [{idx, id, rar}]
func _sacrifices() -> Array:
	var out: Array = []
	var inv := GameState.inv()
	for i in inv.size():
		var e = inv[i]
		if e is Dictionary:
			var rar := ItemDB.rarity_of(String(e["id"]))
			if ItemDB.bu_sacrifice_ok(String(e["id"])):
				out.append({"idx": i, "id": String(e["id"]), "rar": rar})
	return out

func _build_menu() -> void:
	_box.add_child(UiKit.label("SYNTEZA PIERWIASTKA BU", 20, UiKit.ACCENT))
	_box.add_child(_wl("Aby wytworzyć BU, musisz POŚWIĘCIĆ BROŃ (rzadką lub lepszą) z plecaka — 1 broń to 1 BU. Zmniejszysz się do rozmiaru atomu i zjesz wszystkie jądra atomowe przedmiotu. Gdy skończysz — wybuch zamieni go w BU. Zjedz wszystkie jądra, nim minie czas. Sztabka kurczalium kosztuje 3 BU.", 14, UiKit.DIM))
	var list := _sacrifices()
	if list.is_empty():
		_box.add_child(_wl("Nie masz w plecaku żadnej broni rzadkiej lub lepszej (założone nie liczą się — zdejmij je najpierw).", 14, UiKit.BAD))
	for s in list:
		var d := ItemDB.get_data(String(s["id"]))
		var row := UiKit.panel(UiKit.BG2, 8)
		_box.add_child(row)
		var h := UiKit.hbox(8)
		row.add_child(h)
		h.add_child(UiKit.icon(Art.item_icon(String(s["id"]), 40), 40))
		var v := UiKit.vbox(0)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		v.add_child(UiKit.label(String(d.get("name", "?")), 16, ItemDB.rarity_color(String(s["id"]))))
		v.add_child(UiKit.label(String(ItemDB.RARITY_NAMES.get(s["rar"], "")) + " → 1 BU", 12, UiKit.DIM))
		var b := UiKit.button("Poświęć", 16, UiKit.BAD)
		var idx: int = int(s["idx"])
		b.pressed.connect(func(): Audio.play("deny"); _start_eat(idx))
		h.add_child(b)
	_box.add_child(UiKit.sep(10))
	_box.add_child(UiKit.label("WYTWARZANIE KURCZALIUM", 20, UiKit.ACCENT))
	_box.add_child(_wl("Receptura: węgiel + diament + 2 sztabki kurczalu + 3 pierwiastki BU (każdy z poświęcenia broni) = sztabka kurczalium.", 14, UiKit.DIM))
	var can := true
	for id in KURCZALIUM_COST:
		_box.add_child(_count_line(String(id), int(KURCZALIUM_COST[id])))
		if GameState.item_count(String(id)) < int(KURCZALIUM_COST[id]):
			can = false
	var mk := UiKit.button("Stwórz sztabkę kurczalium", 20, Color(0.8, 0.45, 1.0))
	mk.disabled = not can
	mk.pressed.connect(_start_kociol)
	_box.add_child(mk)
	var buy := UiKit.button("Kup węgiel (25 zł)", 15, UiKit.ACCENT2)
	buy.disabled = GameState.gold() < 25
	buy.pressed.connect(func():
		if GameState.spend(25):
			GameState.add_item("wegiel", 1)
			Audio.play("coin")
			_enter("menu"))
	_box.add_child(buy)
	_box.add_child(UiKit.label("Złoto: %d" % GameState.gold(), 14, Color(1, 0.85, 0.4)))

func _has_all() -> bool:
	for id in KURCZALIUM_COST:
		if GameState.item_count(String(id)) < int(KURCZALIUM_COST[id]):
			return false
	return true

func _start_kociol() -> void:
	if not _has_all():
		return
	_stage = 0
	_stir = 0.0
	_spoon = 0.0
	_have_ma = false
	_drop = 1.0
	_bubbles.clear()
	_liq = Color(0.2, 0.2, 0.25)
	_t = 0.0
	Audio.play("select")
	_enter("kociol")

func _build_kociol() -> void:
	_box.add_child(UiKit.label("KOCIOŁ KURCZALIUM", 20, UiKit.ACCENT))
	_story = _wl(String(STORY[0]["text"]), 15, UiKit.TEXT)
	_box.add_child(_story)
	_timer_label = UiKit.label("", 16, UiKit.ACCENT2, HORIZONTAL_ALIGNMENT_CENTER)
	_box.add_child(_timer_label)
	_arena = Control.new()
	_arena.custom_minimum_size = ARENA
	_arena.draw.connect(_draw_kociol)
	_box.add_child(_arena)

func _kociol_center() -> Vector2:
	return Vector2(ARENA.x * 0.5, ARENA.y * 0.5)

func _draw_kociol() -> void:
	if _arena == null:
		return
	var a := _arena
	var c := _kociol_center()
	a.draw_rect(Rect2(Vector2.ZERO, ARENA), Color(0.03, 0.05, 0.08, 0.7))
	for i in 7:
		var fx := c.x - 120.0 + float(i) * 40.0
		var fh := 40.0 + 22.0 * sin(_t * 9.0 + float(i) * 1.7)
		a.draw_colored_polygon(PackedVector2Array([Vector2(fx - 18, ARENA.y - 20), Vector2(fx, ARENA.y - 20 - fh), Vector2(fx + 18, ARENA.y - 20)]), Color(1.0, 0.45 + 0.1 * float(i % 3), 0.1, 0.85))
	var rx := 190.0
	var ry := 50.0
	var top := c.y - 70.0
	a.draw_circle(Vector2(c.x, top + 100.0), 150.0, Color(0.1, 0.1, 0.12))
	a.draw_rect(Rect2(c.x - rx, top, rx * 2.0, 100.0), Color(0.1, 0.1, 0.12))
	_ellipse(a, Vector2(c.x, top), rx, ry, Color(0.2, 0.2, 0.24))
	_ellipse(a, Vector2(c.x, top + 4.0), rx - 14.0, ry - 10.0, _liq)
	for bb in _bubbles:
		var bp: Vector2 = bb["p"]
		a.draw_arc(bp, float(bb["r"]), 0.0, TAU, 12, Color(1, 1, 1, 0.6 * float(bb["t"])), 2.0)
	var tip := Vector2(c.x, top + 4.0) + Vector2(cos(_spoon) * (rx - 60.0), sin(_spoon) * (ry - 18.0))
	a.draw_line(tip + Vector2(40, -150), tip, Color(0.55, 0.38, 0.2), 8.0)
	a.draw_circle(tip, 11.0, Color(0.55, 0.38, 0.2))
	if _drop > 0.0 and _stage < STORY.size():
		var tex := Art.item_icon(String(STORY[_stage]["id"]), 32)
		var k := clampf(_drop, 0.0, 1.0)
		var pos := Vector2(c.x, 10.0).lerp(Vector2(c.x, top), 1.0 - k)
		a.draw_texture_rect(tex, Rect2(pos - Vector2(28, 28), Vector2(56, 56)), false)
	var bw := 360.0
	a.draw_rect(Rect2(Vector2(c.x - bw * 0.5, ARENA.y - 14.0), Vector2(bw, 10.0)), Color(0.1, 0.1, 0.12))
	a.draw_rect(Rect2(Vector2(c.x - bw * 0.5, ARENA.y - 14.0), Vector2(bw * clampf(_stir, 0.0, 1.0), 10.0)), Color(LAB.r, LAB.g, LAB.b))
	a.draw_rect(Rect2(Vector2.ZERO, ARENA), Color(0, 0, 0, 0), false, 2.0)

func _ellipse(a: Control, c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 32:
		var an := TAU * float(i) / 32.0
		pts.append(c + Vector2(cos(an) * rx, sin(an) * ry))
	a.draw_colored_polygon(pts, col)

func _process_kociol(delta: float) -> void:
	_t += delta
	var c := _kociol_center()
	if _drop > 0.0:
		_drop = maxf(0.0, _drop - delta * 1.1)
	else:
		var d := 0.0
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): d -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): d += 1.0
		var moved := 0.0
		if d != 0.0:
			moved = d * 5.0 * delta
		else:
			var m := _arena.get_local_mouse_position() - c
			if m.length() > 20.0:
				var ma := m.angle()
				if _have_ma:
					moved = wrapf(ma - _last_ma, -PI, PI)
				_last_ma = ma
				_have_ma = true
			else:
				_have_ma = false
		_spoon += moved
		_stir += absf(moved) / (TAU * STIR_TURNS)
		if absf(moved) > 0.01 and randf() < 0.5:
			_bubbles.append({"p": Vector2(c.x + randf_range(-110, 110), c.y - 66.0 + randf_range(-10, 10)), "r": randf_range(3, 9), "t": 1.0})
	for bb in _bubbles:
		bb["t"] = float(bb["t"]) - delta * 1.4
		bb["p"] = Vector2(bb["p"]) + Vector2(0, -22.0 * delta)
	_bubbles = _bubbles.filter(func(x): return float(x["t"]) > 0.0)
	var target: Color = STORY[mini(_stage, STORY.size() - 1)]["col"]
	_liq = _liq.lerp(target, minf(1.0, delta * 2.0))
	if _stir >= 1.0:
		_stage += 1
		_stir = 0.0
		Audio.play("coin", 0.8 + 0.12 * float(_stage), -4.0)
		if _stage >= STORY.size():
			_phase = "menu_wait"
			_make_kurczalium()
			return
		_drop = 1.0
		_story.text = String(STORY[_stage]["text"])
	_arena.queue_redraw()
	_timer_label.text = "Etap %d / %d  ·  mieszaj: kręć myszą wokół kotła albo A / D" % [mini(_stage + 1, STORY.size()), STORY.size()]

func _make_kurczalium() -> void:
	for id in KURCZALIUM_COST:
		if GameState.item_count(String(id)) < int(KURCZALIUM_COST[id]):
			return
	for id in KURCZALIUM_COST:
		GameState.remove_item(String(id), int(KURCZALIUM_COST[id]))
	ForgeDB.learn_metal("kurczalium")
	var left := GameState.add_item("sztabka_kurczalium", 1)
	GameState.save_game()
	Audio.play("levelup", 0.9, -2.0)
	_msg.text = "Kocioł ucichł. Na dnie zastygła sztabka kurczalium!" + (" (ekwipunek pełny — czeka w skrytce)" if left > 0 else "")
	GameState.toast.emit("Wytworzono: Sztabka kurczalium", UiKit.GOOD)
	_enter("menu")

# ------------------------------------------------------------- minigra: jądra ---

func _start_eat(idx: int) -> void:
	var e = GameState.inv()[idx]
	if not (e is Dictionary):
		return
	_item_idx = idx
	_item_id = String(e["id"])
	_tier_bonus = 3
	_total = 10 + _tier_bonus * 2
	_eaten = 0
	_t = 0.0
	_pr = 70.0
	_pp = ARENA * 0.5
	_atoms.clear()
	for i in _total:
		_atoms.append({
			"p": Vector2(randf_range(60, ARENA.x - 60), randf_range(60, ARENA.y - 60)),
			"v": Vector2.from_angle(randf() * TAU) * randf_range(10, 35),
			"ph": randf() * TAU,
		})
	_enter("eat")

func _build_eat() -> void:
	_box.add_child(UiKit.label("ZJEDZ WSZYSTKIE JĄDRA", 20, UiKit.ACCENT))
	_box.add_child(_wl("Zmniejszyłeś się do rozmiaru atomu. Steruj WASD / strzałkami (lub przytrzymaj lewy przycisk myszy) i pochłoń wszystkie jądra przedmiotu „%s”. Jądra uciekają, gdy się zbliżysz!" % String(ItemDB.get_data(_item_id).get("name", "?")), 14, UiKit.TEXT))
	_timer_label = UiKit.label("", 16, UiKit.ACCENT2, HORIZONTAL_ALIGNMENT_CENTER)
	_box.add_child(_timer_label)
	_arena = Control.new()
	_arena.custom_minimum_size = ARENA
	_arena.draw.connect(_draw_arena)
	_box.add_child(_arena)

func _draw_arena() -> void:
	if _arena == null:
		return
	_arena.draw_rect(Rect2(Vector2.ZERO, ARENA), Color(0.03, 0.05, 0.08))
	var tex := Art.item_icon(_item_id, 32)
	var big := 300.0
	_arena.draw_texture_rect(tex, Rect2(ARENA * 0.5 - Vector2(big, big) * 0.5, Vector2(big, big)), false, Color(1, 1, 1, 0.12))
	for x in range(0, int(ARENA.x), 50):
		_arena.draw_line(Vector2(x, 0), Vector2(x, ARENA.y), Color(0.15, 0.25, 0.3, 0.25), 1.0)
	for y in range(0, int(ARENA.y), 50):
		_arena.draw_line(Vector2(0, y), Vector2(ARENA.x, y), Color(0.15, 0.25, 0.3, 0.25), 1.0)
	var tt := Time.get_ticks_msec() * 0.001
	for a in _atoms:
		var p: Vector2 = a["p"]
		var ph := float(a["ph"])
		_arena.draw_circle(p, 16.0, Color(0.4, 0.95, 1.0, 0.18))
		_arena.draw_circle(p, 8.0, Color(0.5, 1.0, 1.0))
		for k in 2:
			var ang := tt * (2.0 + k) + ph + k * PI
			_arena.draw_arc(p, 18.0 + 4.0 * k, 0.0, TAU, 24, Color(0.4, 0.8, 1.0, 0.25), 1.0)
			_arena.draw_circle(p + Vector2.from_angle(ang) * (18.0 + 4.0 * k), 2.4, Color(1, 1, 1, 0.9))
	# gracz (zmniejszony)
	_arena.draw_circle(_pp, _pr + 6.0, Color(1.0, 0.85, 0.3, 0.2))
	_arena.draw_circle(_pp, _pr, Color(1.0, 0.85, 0.3))
	_arena.draw_circle(_pp + Vector2(_pr * 0.3, -_pr * 0.15), maxf(1.5, _pr * 0.16), Color(0.1, 0.1, 0.12))
	_arena.draw_rect(Rect2(Vector2.ZERO, ARENA), Color(0, 0, 0, 0), false, 2.0)

func _process(delta: float) -> void:
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta)
		_root.position = Vector2(randf_range(-10, 10), randf_range(-8, 8)) * (_shake / 1.2)
	elif _root.position != Vector2.ZERO:
		_root.position = Vector2.ZERO
	if _phase == "kociol" and _arena != null:
		_process_kociol(delta)
		return
	if _phase != "eat" or _arena == null:
		return
	_t += delta
	_pr = move_toward(_pr, 9.0, 52.0 * delta)   # animacja zmniejszania
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): dir.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): dir.y += 1.0
	if dir == Vector2.ZERO and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var m := _arena.get_local_mouse_position()
		if m.distance_to(_pp) > 6.0:
			dir = (m - _pp).normalized()
	_pp += dir.normalized() * 270.0 * delta
	_pp = _pp.clamp(Vector2(10, 10), ARENA - Vector2(10, 10))
	for a in _atoms.duplicate():
		var p: Vector2 = a["p"]
		var v: Vector2 = a["v"]
		var d: Vector2 = p - _pp
		if d.length() < 150.0:
			v = v.lerp(d.normalized() * 95.0, 0.08)
		else:
			v = v.lerp(v.normalized() * 22.0, 0.02)
		p += v * delta
		if p.x < 20.0 or p.x > ARENA.x - 20.0: v.x = -v.x
		if p.y < 20.0 or p.y > ARENA.y - 20.0: v.y = -v.y
		p = p.clamp(Vector2(20, 20), ARENA - Vector2(20, 20))
		a["p"] = p
		a["v"] = v
		if p.distance_to(_pp) < _pr + 12.0:
			_atoms.erase(a)
			_eaten += 1
			Audio.play("coin", 1.0 + 0.04 * float(_eaten), -8.0)
	_arena.queue_redraw()
	_timer_label.text = "Czas: %.0f s   ·   Zjedzone jądra: %d / %d" % [maxf(0.0, TIME_LIMIT - _t), _eaten, _total]
	if _eaten >= _total or _t >= TIME_LIMIT:
		_explode()

# ------------------------------------------------------------- wybuch i błędy ---

func _explode() -> void:
	_phase = "boom"
	var ratio := float(_eaten) / float(_total)
	var yield_n := ItemDB.BU_PER_SACRIFICE
	# przedmiot przepada (zawsze znajdź go ponownie po id)
	var inv := GameState.inv()
	if _item_idx >= 0 and _item_idx < inv.size() and inv[_item_idx] is Dictionary and String(inv[_item_idx]["id"]) == _item_id:
		inv[_item_idx] = null
	else:
		GameState.remove_item(_item_id, 1)
	Audio.play("roar", 0.5, 4.0)
	Audio.play("hit_heavy", 0.4, 2.0)
	_shake = 1.2
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.95)
	UiKit.full(flash)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_err_layer.add_child(flash)
	var tw := create_tween()
	tw.tween_property(flash, "color:a", 0.0, 0.5)
	_spawn_errors(yield_n)

## Na ekranie (a nie w dymku) sypią się tysiące okien błędów. Rysowane partiami: każda partia to
## jeden węzeł, który rysuje się raz, więc nawet 5000 okien nie zwalnia gry.
class ErrorBatch extends Control:
	var items: Array = []     # {p: Vector2, s: Vector2, t: String}

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var f := ThemeDB.fallback_font
		for it in items:
			var p: Vector2 = it["p"]
			var s: Vector2 = it["s"]
			draw_rect(Rect2(p, s), Color(0.92, 0.92, 0.94))
			draw_rect(Rect2(p, Vector2(s.x, 13)), Color(0.78, 0.1, 0.1))
			draw_rect(Rect2(p, s), Color(0.1, 0.1, 0.42), false, 2.0)
			draw_string(f, p + Vector2(4, 11), "ERROR", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
			draw_string(f, p + Vector2(7, 28), "✖ " + String(it["t"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.1, 0.1, 0.12))
			draw_string(f, p + Vector2(s.x - 36, s.y - 4), "[ OK ]", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.1, 0.1, 0.5))

func _spawn_errors(yield_n: int) -> void:
	var vp := get_viewport_rect().size
	var f := ThemeDB.fallback_font
	var texts: Array = []
	for e in ERRORS:
		var txt := String(e)
		if txt.contains("%X"):
			txt = txt % 0xA13F77
		elif txt.contains("%d"):
			txt = txt % 4096
		texts.append(txt)
	var widths: Array = []
	for t in texts:
		widths.append(f.get_string_size("✖ " + String(t), HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 20.0)
	var made := 0
	var step := 0
	while made < ERROR_COUNT:
		# najpierw pojedyncze okna, co chwilę, potem coraz szybciej aż do lawiny
		var delay := maxf(0.04, 0.55 * pow(0.78, float(step)))
		await get_tree().create_timer(delay).timeout
		if not is_inside_tree():
			return
		var n := clampi(1 + int(float(step * step) * 0.55), 1, 260)
		n = mini(n, ERROR_COUNT - made)
		var b := ErrorBatch.new()
		for i in n:
			var k := randi() % texts.size()
			var sz := Vector2(maxf(float(widths[k]), 90.0), 46.0)
			b.items.append({"p": Vector2(randf_range(-30.0, vp.x - 60.0), randf_range(-10.0, vp.y - 30.0)), "s": sz, "t": texts[k]})
		_err_layer.add_child(b)
		made += n
		step += 1
		Audio.play("deny", randf_range(0.7, 1.4), -10.0 if step > 12 else -6.0)
	await get_tree().create_timer(1.4).timeout
	if not is_inside_tree():
		return
	for c in _err_layer.get_children():
		c.queue_free()
	GameState.add_item("pierwiastek_bu", yield_n)
	GameState.save_game()
	Audio.play("levelup", 1.2, -2.0)
	var ratio := float(_eaten) / float(_total)
	_msg.text = "Przedmiot zamienił się w %d × pierwiastek BU (zjedzone jądra: %d%%)." % [yield_n, int(ratio * 100.0)]
	GameState.toast.emit("Wytworzono: pierwiastek BU ×%d" % yield_n, UiKit.GOOD)
	_enter("menu")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed() and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		if _phase == "kociol":
			_msg.text = "Przerwałeś warzenie — składniki wróciły do plecaka."
			_enter("menu")
		elif _phase == "eat":
			_msg.text = "Przerwałeś syntezę — przedmiot nie został poświęcony."
			_enter("menu")
		elif _phase == "menu":
			on_close.emit()
