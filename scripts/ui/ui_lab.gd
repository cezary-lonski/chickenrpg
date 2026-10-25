class_name UiLab
extends Control
## Laboratorium:
## (1) Pierwiastek BU powstaje z ofiary: poświęcasz przedmiot LEGENDARNY (lub hiperlegendarny),
##     zmniejszasz się do rozmiaru atomu i zjadasz wszystkie jądra atomowe przedmiotu.
##     Na końcu następuje wybuch — na ekranie sypią się okna błędów — a przedmiot zamienia się w BU.
## (2) Z węgla, diamentu, kurczalu i BU powstaje sztabka kurczalium.

signal on_close

const KURCZALIUM_COST := {"wegiel": 1, "krysztal_cienia": 1, "sztabka_kurczalu": 2, "pierwiastek_bu": 1}
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
	add_child(UiKit.dim(Color(0.02, 0.04, 0.05, 0.5)))
	_root = UiKit.vbox(8)
	UiKit.full_margin(_root)
	add_child(_root)
	_root.add_child(UiKit.title("LABORATORIUM", 38))
	var p := UiKit.panel(UiKit.BG, 12)
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
	_err_layer = Control.new()
	UiKit.full(_err_layer)
	_err_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_err_layer.z_index = 50
	add_child(_err_layer)
	_enter("menu")

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

func _count_line(id: String, need: int) -> Control:
	var have := GameState.item_count(id)
	var h := UiKit.hbox(6)
	h.add_child(UiKit.icon(Art.item_icon(id, 24), 24))
	h.add_child(UiKit.label("%s: %d / %d" % [String(ItemDB.get_data(id).get("name", id)), have, need], 15, UiKit.GOOD if have >= need else UiKit.BAD))
	return h

## Przedmioty z plecaka o rzadkości legendarnej lub wyższej: [{idx, id, rar}]
func _sacrifices() -> Array:
	var out: Array = []
	var inv := GameState.inv()
	for i in inv.size():
		var e = inv[i]
		if e is Dictionary:
			var rar := ItemDB.rarity_of(String(e["id"]))
			if rar == "legendarny" or rar == "hiperlegendarny":
				out.append({"idx": i, "id": String(e["id"]), "rar": rar})
	return out

func _build_menu() -> void:
	_box.add_child(UiKit.label("SYNTEZA PIERWIASTKA BU", 20, UiKit.ACCENT))
	_box.add_child(_wl("Aby wytworzyć BU, musisz POŚWIĘCIĆ przedmiot o rzadkości legendarnej (lub hiperlegendarnej) z plecaka. Zmniejszysz się do rozmiaru atomu i zjesz wszystkie jądra atomowe przedmiotu. Gdy skończysz — wybuch zamieni go w BU. Legendarny daje 3 BU, hiperlegendarny 6 (zjedz wszystko, by dostać całość).", 14, UiKit.DIM))
	var list := _sacrifices()
	if list.is_empty():
		_box.add_child(_wl("Nie masz w plecaku żadnego legendarnego przedmiotu (założone nie liczą się — zdejmij je najpierw).", 14, UiKit.BAD))
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
		v.add_child(UiKit.label(String(ItemDB.RARITY_NAMES.get(s["rar"], "")) + " → %d BU" % (6 if s["rar"] == "hiperlegendarny" else 3), 12, UiKit.DIM))
		var b := UiKit.button("Poświęć", 16, UiKit.BAD)
		var idx: int = int(s["idx"])
		b.pressed.connect(func(): Audio.play("deny"); _start_eat(idx))
		h.add_child(b)
	_box.add_child(UiKit.sep(10))
	_box.add_child(UiKit.label("WYTWARZANIE KURCZALIUM", 20, UiKit.ACCENT))
	_box.add_child(_wl("Receptura: węgiel + diament + 2 sztabki kurczalu + pierwiastek BU (zdobyty z poświęcenia legendarnego przedmiotu) = sztabka kurczalium.", 14, UiKit.DIM))
	var can := true
	for id in KURCZALIUM_COST:
		_box.add_child(_count_line(String(id), int(KURCZALIUM_COST[id])))
		if GameState.item_count(String(id)) < int(KURCZALIUM_COST[id]):
			can = false
	var mk := UiKit.button("Stwórz sztabkę kurczalium", 20, Color(0.8, 0.45, 1.0))
	mk.disabled = not can
	mk.pressed.connect(_make_kurczalium)
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
	_msg.text = "Powstała sztabka kurczalium!" + (" (ekwipunek pełny — czeka w skrytce)" if left > 0 else "")
	GameState.toast.emit("Wytworzono: Sztabka kurczalium", UiKit.GOOD)
	_enter("menu")

# ------------------------------------------------------------- minigra: jądra ---

func _start_eat(idx: int) -> void:
	var e = GameState.inv()[idx]
	if not (e is Dictionary):
		return
	_item_idx = idx
	_item_id = String(e["id"])
	_tier_bonus = 6 if ItemDB.rarity_of(_item_id) == "hiperlegendarny" else 3
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
	var yield_n := maxi(1, int(round(float(_tier_bonus) * ratio)))
	if _eaten >= _total and _t < TIME_LIMIT - 10.0:
		yield_n += 1
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
		if _phase == "eat":
			_msg.text = "Przerwałeś syntezę — przedmiot nie został poświęcony."
			_enter("menu")
		elif _phase == "menu":
			on_close.emit()
