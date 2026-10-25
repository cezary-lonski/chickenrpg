class_name UiArenaBar
extends Control
## Paski życia dwóch graczy w arenie (u góry ekranu).

var _p1: Player
var _p2: Player
var _n1 := "Gracz 1"
var _n2 := "Gracz 2"

func setup(p1: Player, p2: Player, n1: String, n2: String) -> void:
	_p1 = p1
	_p2 = p2
	_n1 = n1
	_n2 = n2

func _ready() -> void:
	UiKit.full(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_dt: float) -> void:
	queue_redraw()

func _bar(x: float, w: float, p: Player, name_txt: String, col: Color, right: bool) -> void:
	var f := ThemeDB.fallback_font
	draw_rect(Rect2(x - 4, 10, w + 8, 44), Color(0.04, 0.05, 0.08, 0.85))
	var k := 0.0
	var hp := 0.0
	var mh := 1.0
	if p != null and is_instance_valid(p):
		hp = maxf(0.0, p.hp)
		mh = maxf(1.0, p.max_hp)
		k = clampf(hp / mh, 0.0, 1.0)
	draw_rect(Rect2(x, 32, w, 16), Color(0.15, 0.1, 0.1))
	var fw := w * k
	draw_rect(Rect2(x + (w - fw if right else 0.0), 32, fw, 16), col)
	var tw := f.get_string_size(name_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	draw_string(f, Vector2(x + (w - tw if right else 0.0), 27), name_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1))
	var hs := "%d / %d" % [int(hp), int(mh)]
	var hw := f.get_string_size(hs, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	draw_string(f, Vector2(x + w * 0.5 - hw * 0.5, 45), hs, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1))

func _draw() -> void:
	var vw := size.x if size.x > 10.0 else 1280.0
	var w := minf(400.0, vw * 0.29)
	_bar(vw * 0.5 - 40.0 - w, w, _p1, _n1, Color(0.35, 0.8, 0.45), false)
	_bar(vw * 0.5 + 40.0, w, _p2, _n2, Color(0.9, 0.35, 0.3), true)
	var f := ThemeDB.fallback_font
	draw_string(f, Vector2(vw * 0.5 - 14.0, 40.0), "VS", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1.0, 0.85, 0.4))
