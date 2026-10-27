class_name UiTravelMap
extends Control
## Mapa świata w pixel arcie: osada, trakty, stolica, pałac, twierdze i wioski rozmieszczone jak na
## prawdziwej mapie. Klikasz miejsce, mapa wytycza drogę przez kolejne etapy, a „Maszeruj" prowadzi
## cię przez nie (po pokonaniu potworów w każdym pytam, czy iść dalej). Dostępne są miejsca
## odblokowane; pozostałe otwiera tylko zwój teleportacji.

signal on_close
signal on_march(index: int)
signal on_teleport(index: int)

const MAP_SIZE := Vector2(1200, 380)

var _sel := -1
var _info: Label
var _march_btn: Button
var _scroll_btn: Button
var _canvas: _MapCanvas

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	add_child(UiKit.bg_texture(Color(0.04, 0.06, 0.1)))
	var outer := UiKit.vbox(6)
	UiKit.full_margin(outer, 24.0)
	add_child(outer)
	outer.add_child(UiKit.title("MAPA ŚWIATA", 36))
	var best := GameState.best_chapter()
	var scrolls := GameState.item_count("zwoj_teleportacji")
	outer.add_child(UiKit.label("Kliknij miejsce, do którego chcesz dotrzeć. Zablokowane są jeszcze nieodkryte. Zwój teleportacji przenosi natychmiast, ale tylko do zbadanych miejsc (masz: %d)." % scrolls, 15, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var holder := CenterContainer.new()
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(holder)
	_canvas = _MapCanvas.new()
	_canvas.custom_minimum_size = MAP_SIZE
	_canvas.best = best
	_canvas.current = GameState.story_chapter()
	_canvas.selected.connect(_select)
	holder.add_child(_canvas)
	_info = UiKit.label("", 17, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.custom_minimum_size = Vector2(1000, 54)
	outer.add_child(_info)
	var row := UiKit.hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_child(row)
	var back := UiKit.button("Zamknij", 18)
	back.pressed.connect(func(): Audio.play("back"); on_close.emit())
	row.add_child(back)
	_march_btn = UiKit.button("Maszeruj", 22, UiKit.GOOD)
	_march_btn.custom_minimum_size = Vector2(240, 48)
	_march_btn.pressed.connect(_march)
	row.add_child(_march_btn)
	_scroll_btn = UiKit.button("Teleportuj (zwój)", 18, Color(0.75, 0.55, 1.0))
	_scroll_btn.custom_minimum_size = Vector2(240, 48)
	_scroll_btn.pressed.connect(_teleport)
	row.add_child(_scroll_btn)
	var cur := clampi(GameState.story_chapter(), 0, QuestDB.count() - 1)
	_select(cur)

func _select(i: int) -> void:
	Audio.play("select")
	_sel = i
	_canvas.sel = i
	var cur := clampi(GameState.story_chapter(), 0, QuestDB.count() - 1)
	var reached := i <= GameState.best_chapter()
	var scrolls := GameState.item_count("zwoj_teleportacji")
	var nm := PlaceDB.name_of(i)
	var route := PlaceDB.route(cur, i)
	_canvas.route = [cur] + route + [i] if i != cur else [cur]
	var txt := ""
	if i == cur:
		txt = "%s — tu jesteś." % nm
	elif not reached:
		txt = "%s — zablokowane. Odkryjesz je, pokonując wcześniejsze etapy; teleportacja działa tylko do zbadanych miejsc." % nm
	else:
		var names: Array = []
		for r in route:
			names.append(PlaceDB.name_of(int(r)))
		if route.is_empty():
			txt = "%s — droga prosta, bez przeszkód." % nm
		else:
			txt = "%s — droga: %s → %s (%d etap%s do pokonania po drodze)." % [nm, PlaceDB.name_of(cur), " → ".join(names) + " → " + nm, route.size(), "" if route.size() == 1 else "y"]
	_info.text = txt
	_march_btn.disabled = i == cur or not reached
	_scroll_btn.visible = reached and i != cur
	_scroll_btn.disabled = scrolls <= 0

func _march() -> void:
	if _sel < 0 or _sel == GameState.story_chapter() or _sel > GameState.best_chapter():
		Audio.play("deny")
		return
	Audio.play("confirm")
	on_march.emit(_sel)

func _teleport() -> void:
	if _sel < 0 or _sel > GameState.best_chapter() or _sel == GameState.story_chapter() or GameState.item_count("zwoj_teleportacji") <= 0:
		Audio.play("deny")
		return
	GameState.remove_item("zwoj_teleportacji", 1)
	Audio.play("confirm")
	on_teleport.emit(_sel)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed() and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("world_map")):
		get_viewport().set_input_as_handled()
		on_close.emit()

# ------------------------------------------------------------------- płótno mapy ---

class _MapCanvas extends Control:
	signal selected(index: int)

	const ICON_CELL := 3.0
	const MS := Vector2(1200, 380)
	var best := 0
	var current := 0
	var sel := -1
	var route: Array = []
	var _hover := -1
	var _t := 0.0
	var _bg: ImageTexture
	var _icons: Dictionary = {}

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		_build_background()
		for kind in ["village", "city", "tower", "castle", "cave", "forest", "road"]:
			_icons[kind] = _make_icon(kind)

	func _pos_of(i: int) -> Vector2:
		var p: Vector2 = PlaceDB.of(String(QuestDB.chapter(i).get("id", "")))["pos"]
		return Vector2(p.x * size.x, p.y * size.y)

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _build_background() -> void:
		var cell := 6.0
		var cv := PixelCanvas.new(int(MS.x / cell), int(MS.y / cell), Vector2.ZERO, cell)
		# morze
		cv.rect(Rect2(Vector2.ZERO, MS), Color(0.1, 0.22, 0.38), false)
		var r := RandomNumberGenerator.new()
		r.seed = 77
		for i in 90:
			var p := Vector2(r.randf() * MS.x, r.randf() * MS.y)
			cv.line(p, p + Vector2(12, 0), Color(0.16, 0.3, 0.48), 3.0)
		# kontynent
		var land := [Vector2(0.01, 0.92), Vector2(0.015, 0.62), Vector2(0.07, 0.5), Vector2(0.14, 0.4), Vector2(0.22, 0.22), Vector2(0.36, 0.14), Vector2(0.52, 0.08),
			Vector2(0.68, 0.05), Vector2(0.84, 0.03), Vector2(0.975, 0.05), Vector2(0.995, 0.34), Vector2(0.985, 0.72), Vector2(0.92, 0.86), Vector2(0.82, 0.97),
			Vector2(0.62, 0.985), Vector2(0.42, 0.95), Vector2(0.26, 0.985), Vector2(0.1, 0.985)]
		var pts := PackedVector2Array()
		for p in land:
			pts.append(Vector2(p.x * MS.x, p.y * MS.y))
		cv.poly(pts, Color(0.38, 0.56, 0.3), true)
		# góry, lasy, jeziora
		for i in 26:
			var p := Vector2(r.randf_range(0.1, 0.95) * MS.x, r.randf_range(0.12, 0.9) * MS.y)
			if _near_place(p, 56.0):
				continue
			var s := r.randf_range(14.0, 26.0)
			cv.poly(PackedVector2Array([p + Vector2(-s, 0), p + Vector2(0, -s * 1.2), p + Vector2(s, 0)]), Color(0.52, 0.5, 0.52), true)
			cv.poly(PackedVector2Array([p + Vector2(-s * 0.25, -s * 0.85), p + Vector2(0, -s * 1.2), p + Vector2(s * 0.25, -s * 0.85)]), Color(0.95, 0.95, 0.98), false)
		for i in 40:
			var p := Vector2(r.randf_range(0.08, 0.96) * MS.x, r.randf_range(0.14, 0.92) * MS.y)
			if _near_place(p, 40.0):
				continue
			cv.circle(p, r.randf_range(7.0, 11.0), Color(0.22, 0.45, 0.24), true)
		for i in 4:
			var p := Vector2(r.randf_range(0.2, 0.9) * MS.x, r.randf_range(0.2, 0.85) * MS.y)
			if _near_place(p, 60.0):
				continue
			cv.ellipse(p, 26.0, 14.0, Color(0.2, 0.4, 0.62), true)
		cv.finish()
		_bg = cv.texture

	func _near_place(p: Vector2, d: float) -> bool:
		for i in QuestDB.count():
			var q: Vector2 = PlaceDB.of(String(QuestDB.chapter(i).get("id", "")))["pos"]
			if Vector2(q.x * MS.x, q.y * MS.y).distance_to(p) < d:
				return true
		return false

	func _make_icon(kind: String) -> ImageTexture:
		var cv := PixelCanvas.new(16, 16, Vector2(-24, -30), ICON_CELL)
		var wall := Color(0.82, 0.78, 0.7)
		var roof := Color(0.75, 0.3, 0.25)
		match kind:
			"village":
				for o in [Vector2(-12, 0), Vector2(6, 2), Vector2(-3, -9)]:
					cv.rect(Rect2(o + Vector2(-5, -8), Vector2(10, 8)), wall, true)
					cv.poly(PackedVector2Array([o + Vector2(-7, -8), o + Vector2(0, -15), o + Vector2(7, -8)]), roof, true)
			"city":
				cv.rect(Rect2(-14, -14, 28, 14), wall, true)
				for x in [-14.0, -2.0, 8.0]:
					cv.rect(Rect2(x, -22, 6, 10), wall.darkened(0.1), true)
					cv.rect(Rect2(x, -25, 6, 3), roof, false)
			"tower":
				cv.rect(Rect2(-6, -24, 12, 24), wall, true)
				cv.poly(PackedVector2Array([Vector2(-9, -24), Vector2(0, -34), Vector2(9, -24)]), roof, true)
				cv.rect(Rect2(-1, -40, 2, 8), Color(0.3, 0.2, 0.15), false)
				cv.rect(Rect2(1, -40, 7, 4), Color(0.9, 0.2, 0.2), false)
			"castle":
				cv.rect(Rect2(-16, -14, 32, 14), wall, true)
				for x in [-18.0, 10.0]:
					cv.rect(Rect2(x, -26, 8, 26), wall.darkened(0.08), true)
					cv.rect(Rect2(x - 1, -29, 10, 4), roof, false)
				cv.rect(Rect2(-4, -9, 8, 9), Color(0.2, 0.14, 0.1), false)
				cv.rect(Rect2(-1, -38, 2, 9), Color(0.3, 0.2, 0.15), false)
				cv.rect(Rect2(1, -38, 8, 4), Color(0.2, 0.2, 0.25), false)
			"cave":
				cv.poly(PackedVector2Array([Vector2(-16, 0), Vector2(-10, -16), Vector2(0, -22), Vector2(10, -16), Vector2(16, 0)]), Color(0.45, 0.43, 0.46), true)
				cv.poly(PackedVector2Array([Vector2(-7, 0), Vector2(-5, -10), Vector2(0, -13), Vector2(5, -10), Vector2(7, 0)]), Color(0.05, 0.05, 0.08), false)
			"forest":
				for o in [Vector2(-10, 0), Vector2(8, 2), Vector2(-1, -6)]:
					cv.rect(Rect2(o + Vector2(-1, -6), Vector2(3, 7)), Color(0.4, 0.27, 0.15), false)
					cv.circle(o + Vector2(0, -12), 8.0, Color(0.22, 0.5, 0.25), true)
			"road":
				cv.rect(Rect2(-1, -22, 3, 22), Color(0.5, 0.34, 0.2), false)
				cv.poly(PackedVector2Array([Vector2(-14, -20), Vector2(8, -20), Vector2(12, -16), Vector2(8, -12), Vector2(-14, -12)]), Color(0.62, 0.45, 0.25), true)
				cv.poly(PackedVector2Array([Vector2(14, -10), Vector2(-6, -10), Vector2(-10, -6), Vector2(-6, -2), Vector2(14, -2)]), Color(0.58, 0.42, 0.22), true)
		cv.finish()
		return cv.texture

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseMotion:
			_hover = _pick((event as InputEventMouseMotion).position)
		elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			var i := _pick((event as InputEventMouseButton).position)
			if i >= 0:
				selected.emit(i)
				accept_event()

	func _pick(p: Vector2) -> int:
		var bi := -1
		var bd := 28.0
		for i in QuestDB.count():
			var d := _pos_of(i).distance_to(p)
			if d < bd:
				bd = d
				bi = i
		return bi

	func _draw() -> void:
		if _bg != null:
			draw_texture_rect(_bg, Rect2(Vector2.ZERO, MS), false)
		# drogi między kolejnymi etapami
		for i in range(1, QuestDB.count()):
			if int(QuestDB.chapter(i).get("act", 1)) == 2 and int(QuestDB.chapter(i - 1).get("act", 1)) != 2:
				continue
			_dotted(_pos_of(i - 1), _pos_of(i), Color(0.78, 0.65, 0.4) if i <= best else Color(0.45, 0.4, 0.35), 4.0)
		# wyznaczona droga
		for k in range(1, route.size()):
			_dotted(_pos_of(int(route[k - 1])), _pos_of(int(route[k])), Color(1.0, 0.85, 0.3), 6.0, true)
		var font := ThemeDB.fallback_font
		for i in QuestDB.count():
			var c := QuestDB.chapter(i)
			var pl := PlaceDB.of(String(c.get("id", "")))
			var p := _pos_of(i)
			var reached := i <= best
			var tex: ImageTexture = _icons.get(String(pl["kind"]))
			if tex != null:
				var mod := Color(1, 1, 1) if reached else Color(0.45, 0.45, 0.5)
				draw_texture_rect(tex, Rect2(p + Vector2(-24, -30), Vector2(16, 16) * ICON_CELL), false, mod)
			if i == current:
				var pulse := 1.0 + 0.1 * sin(_t * 5.0)
				_ring(p + Vector2(0, -12), 26.0 * pulse, Color(1.0, 0.85, 0.3))
				_flag(p + Vector2(0, -52 + 3.0 * sin(_t * 4.0)))
			if i == sel:
				_ring(p + Vector2(0, -12), 22.0, Color(1, 1, 1))
			if not reached:
				_lock(p + Vector2(0, 4))
			if bool(pl.get("label", true)) or i == _hover or i == sel:
				var txt := String(pl["name"])
				var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
				draw_rect(Rect2(p + Vector2(-w * 0.5 - 4, 8), Vector2(w + 8, 17)), Color(0.04, 0.05, 0.08, 0.78))
				draw_string(font, p + Vector2(-w * 0.5, 21), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1) if reached else Color(0.65, 0.65, 0.7))

	func _dotted(a: Vector2, b: Vector2, col: Color, sz: float, anim: bool = false) -> void:
		var d := b - a
		var n := maxi(1, int(d.length() / 11.0))
		for k in n:
			var f := (float(k) + (fmod(_t * 3.0, 1.0) if anim else 0.0)) / float(n)
			if f > 1.0:
				continue
			var q := a + d * f
			draw_rect(Rect2(q - Vector2(sz, sz) * 0.5 - Vector2(1, 1), Vector2(sz + 2, sz + 2)), Color(0.05, 0.04, 0.07))
			draw_rect(Rect2(q - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), col)

	func _ring(c: Vector2, r: float, col: Color) -> void:
		for k in 20:
			var a := TAU * float(k) / 20.0
			draw_rect(Rect2(c + Vector2(cos(a), sin(a)) * r - Vector2(2, 2), Vector2(4, 4)), col)

	func _flag(p: Vector2) -> void:
		draw_rect(Rect2(p + Vector2(-1, -12), Vector2(3, 22)), Color(0.3, 0.2, 0.15))
		draw_rect(Rect2(p + Vector2(2, -12), Vector2(16, 9)), Color(1.0, 0.8, 0.2))
		draw_rect(Rect2(p + Vector2(-1, -12), Vector2(19, 11)), Color(0.05, 0.04, 0.07), false, 2.0)

	func _lock(p: Vector2) -> void:
		draw_rect(Rect2(p + Vector2(-8, -4), Vector2(16, 12)), Color(0.85, 0.7, 0.2))
		draw_rect(Rect2(p + Vector2(-8, -4), Vector2(16, 12)), Color(0.05, 0.04, 0.07), false, 2.0)
		draw_arc(p + Vector2(0, -5), 5.0, PI, TAU, 8, Color(0.85, 0.85, 0.9), 3.0)
