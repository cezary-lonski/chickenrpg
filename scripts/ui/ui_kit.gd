class_name UiKit
extends RefCounted
## Wspólne kawałki interfejsu: kolory, panele, przyciski, ikony.
## Cały wygląd gry trzyma się tej paleta i tych helperów.

const BG := Color(0.08, 0.09, 0.13, 0.95)
const BG2 := Color(0.14, 0.16, 0.22, 0.97)
const BG3 := Color(0.19, 0.22, 0.29, 0.98)
const ACCENT := Color(1.0, 0.72, 0.25)
const ACCENT2 := Color(0.45, 0.78, 0.95)
const TEXT := Color(0.93, 0.94, 0.97)
const DIM := Color(0.6, 0.63, 0.7)
const GOOD := Color(0.42, 0.9, 0.5)
const BAD := Color(0.95, 0.4, 0.35)
const HP := Color(0.88, 0.24, 0.24)
const EN := Color(0.96, 0.86, 0.24)
const STAM := Color(0.36, 0.66, 0.98)
const FURY := Color(1.0, 0.65, 0.15)
const XP := Color(0.72, 0.5, 0.95)

static func sb(bg: Color, _radius: int = 8, border: float = 0.0, border_col: Color = Color(0, 0, 0, 0.5)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.anti_aliasing = false
	if border <= 0.0 and bg.a > 0.1:
		border = 2.0
		border_col = Color(bg.r * 0.45, bg.g * 0.45, bg.b * 0.5, 1.0)
	if border > 0.0:
		s.border_width_left = int(border)
		s.border_width_right = int(border)
		s.border_width_top = int(border)
		s.border_width_bottom = int(border)
		s.border_color = border_col
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

static func panel(bg: Color = BG, radius: int = 12) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", sb(bg, radius))
	return p

## Drewniany panel kurnika (ramka z desek) dla HUD.
static func wood(radius: int = 6) -> PanelContainer:
	var p := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.42, 0.29, 0.17, 0.94)
	s.border_color = Color(0.23, 0.15, 0.08)
	s.set_border_width_all(3)
	s.set_corner_radius_all(radius)
	s.anti_aliasing = false
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 7
	s.content_margin_bottom = 7
	p.add_theme_stylebox_override("panel", s)
	return p

static func label(text: String, size: int = 18, color: Color = TEXT, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 4)
	l.horizontal_alignment = align
	return l

static func title(text: String, size: int = 54, color: Color = ACCENT) -> Label:
	var l := label(text, size, color, HORIZONTAL_ALIGNMENT_CENTER)
	l.add_theme_constant_override("outline_size", 8)
	return l

static func button(text: String, size: int = 22, accent: Color = ACCENT) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 44)
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_hover_color", accent)
	b.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	b.add_theme_color_override("font_focus_color", accent)
	b.add_theme_stylebox_override("normal", sb(BG2, 8))
	b.add_theme_stylebox_override("hover", sb(BG3, 8, 2, accent))
	b.add_theme_stylebox_override("pressed", sb(Color(accent.r, accent.g, accent.b, 0.25), 8))
	b.add_theme_stylebox_override("focus", sb(Color(0, 0, 0, 0), 8, 2, Color(accent.r, accent.g, accent.b, 0.5)))
	b.add_theme_stylebox_override("disabled", sb(Color(0.1, 0.1, 0.12, 0.8), 8))
	return b

static func icon(tex: Texture2D, px: int = 32) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex
	t.custom_minimum_size = Vector2(px, px)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return t

static func sep(h: int = 8) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c

static func spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c

static func vbox(sep_v: int = 8) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep_v)
	return v

static func hbox(sep_h: int = 8) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep_h)
	return h

static func full(c: Control) -> Control:
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.offset_left = 0
	c.offset_top = 0
	c.offset_right = 0
	c.offset_bottom = 0
	return c

## Pełny ekran z marginesem (żeby panele nie dotykały krawędzi okna).
static func full_margin(c: Control, m: float = 18.0) -> Control:
	full(c)
	c.offset_left = m
	c.offset_top = m * 0.6
	c.offset_right = -m
	c.offset_bottom = -m * 0.6
	return c

static func bg_texture(tint: Color = Color(0.05, 0.06, 0.09, 1.0)) -> TextureRect:
	var t := TextureRect.new()
	t.texture = Art.gradient([Color(tint.r + 0.05, tint.g + 0.05, tint.b + 0.07), tint], true, 8, 256)
	full(t)
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t

static func stat_line(name_text: String, value: float, suffix: String = "", col: Color = TEXT) -> HBoxContainer:
	var h := hbox(6)
	var n := label(name_text, 15, DIM)
	n.custom_minimum_size = Vector2(110, 0)
	h.add_child(n)
	var v := label(_fmt(value) + suffix, 15, col)
	h.add_child(v)
	return h

static func _fmt(v: float) -> String:
	if absf(v - roundf(v)) < 0.01:
		return str(int(roundf(v)))
	return "%.2f" % v

static func dim(c: Color = Color(0.02, 0.02, 0.04, 0.72)) -> ColorRect:
	var r := ColorRect.new()
	r.color = c
	full(r)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

static func stars(n: int) -> String:
	return "★".repeat(n) + "☆".repeat(maxi(0, 5 - n))
