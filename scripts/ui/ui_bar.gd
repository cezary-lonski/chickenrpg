class_name UiBar
extends Control
## Pasek wartości z „duchem" (opóźnionym wskaźnikiem) i etykietą.

var value := 1.0
var ghost := 1.0
var fill_col := Color(0.9, 0.3, 0.3)
var bg_col := Color(0.1, 0.1, 0.13, 0.9)
var text := ""
var font_size := 14
var text_col := Color(1, 1, 1)
var ghost_speed := 1.6
var show_numbers := false
var _sb_fill: StyleBoxFlat
var _sb_bg: StyleBoxFlat

func _ready() -> void:
	_sb_fill = UiKit.sb(fill_col, 5)
	_sb_fill.content_margin_left = 0
	_sb_fill.content_margin_right = 0
	_sb_fill.content_margin_top = 0
	_sb_fill.content_margin_bottom = 0
	_sb_bg = UiKit.sb(bg_col, 5)
	_sb_bg.content_margin_left = 0
	_sb_bg.content_margin_right = 0
	_sb_bg.content_margin_top = 0
	_sb_bg.content_margin_bottom = 0
	_sb_bg.border_width_left = 1
	_sb_bg.border_width_right = 1
	_sb_bg.border_width_top = 1
	_sb_bg.border_width_bottom = 1
	_sb_bg.border_color = Color(0, 0, 0, 0.7)

func set_fill(c: Color) -> void:
	fill_col = c
	if _sb_fill:
		_sb_fill.bg_color = c

func set_value(v: float) -> void:
	value = clampf(v, 0.0, 1.0)

func _process(delta: float) -> void:
	if ghost > value:
		ghost = maxf(value, ghost - ghost_speed * delta)
	else:
		ghost = value
	queue_redraw()

func _draw() -> void:
	if _sb_bg == null:
		return
	var r := Rect2(Vector2.ZERO, size)
	draw_style_box(_sb_bg, r)
	if ghost > value + 0.001:
		draw_style_box(_sb_fill, Rect2(Vector2.ZERO, Vector2(size.x * ghost, size.y)))
	var fg := _sb_fill.duplicate() as StyleBoxFlat
	fg.bg_color = fill_col
	draw_style_box(fg, Rect2(Vector2(1, 1), Vector2(maxf(0.0, (size.x - 2) * value), size.y - 2)))
	# połyski
	var shine := Rect2(Vector2(1, 1), Vector2(maxf(0.0, (size.x - 2) * value), (size.y - 2) * 0.4))
	draw_rect(shine, Color(1, 1, 1, 0.10))
	if text != "":
		var font := ThemeDB.fallback_font
		if font:
			var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			var pos := Vector2((size.x - w) * 0.5, size.y * 0.5 + float(font_size) * 0.36)
			draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, Color(0, 0, 0, 0.75))
			draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_col)
