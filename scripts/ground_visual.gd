class_name GroundVisual
extends Node2D
## Rysuje pas terenu: gradient, trawa z postrzępionym brzegiem, kamyki, kępki.
## Wszystko deterministyczne (seed), więc etap wygląda tak samo przy każdym wejściu.

var length := 3600.0
var top_y := 0.0
var depth := 420.0
var top_col := Color(0.36, 0.48, 0.26)
var bot_col := Color(0.25, 0.34, 0.18)
var accent := Color(0.62, 0.45, 0.24)
var seed_v := 1
var style := "field"  # field | soil

func configure(p_len: float, p_top: float, p_top_col: Color, p_bot_col: Color, p_accent: Color, p_seed: int, p_style: String) -> void:
	length = p_len
	top_y = p_top
	top_col = p_top_col
	bot_col = p_bot_col
	accent = p_accent
	seed_v = p_seed
	style = p_style
	queue_redraw()

func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var x0 := -140.0
	var x1 := length + 200.0
	# gradient w dół
	var strips := 46
	for i in strips:
		var k := float(i) / float(strips - 1)
		var c := top_col.lerp(bot_col, pow(k, 0.8))
		var y := top_y + depth * k
		var h := depth / float(strips) + 1.0
		draw_rect(Rect2(x0, y, x1 - x0, h), c)
	# trawa u góry
	var tuft_h := 14.0
	var scallop := 7.0
	var x := x0
	while x < x1:
		var w := rng.randf_range(6.0, 13.0)
		var hh := tuft_h + rng.randf_range(-4.0, 7.0)
		draw_colored_polygon(_grass(x, top_y, w, hh, scallop), top_col.lightened(0.12))
		x += w * 0.62
	# jasna linia kontaktu
	draw_rect(Rect2(x0, top_y, x1 - x0, 3.0), top_col.lightened(0.3))
	# plamki
	for i in int(length / 14.0):
		var px := rng.randf_range(x0, x1)
		var py := rng.randf_range(top_y + 16.0, top_y + depth * 0.7)
		var r := rng.randf_range(1.0, 3.2)
		var c := bot_col.darkened(rng.randf_range(0.05, 0.2))
		if rng.randf() < 0.12:
			c = accent.darkened(rng.randf_range(0.0, 0.25))
		draw_circle(Vector2(px, py), r, c)
	# kępki traw
	for i in int(length / 90.0):
		var px := rng.randf_range(x0, x1)
		var py := top_y + rng.randf_range(2.0, 6.0)
		var h := rng.randf_range(8.0, 20.0)
		var col := top_col.lightened(0.22) if style != "soil" else accent.darkened(0.1)
		for b in 3:
			var lean := rng.randf_range(-6.0, 6.0)
			draw_line(Vector2(px + b * 3.0 - 3.0, py), Vector2(px + b * 3.0 - 3.0 + lean, py - h), col, 1.6, true)

func _grass(x: float, y: float, w: float, h: float, sc: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.append(Vector2(x, y - h))
	var steps := 4
	for i in steps + 1:
		var k := float(i) / float(steps)
		pts.append(Vector2(x + w * k, y - h * (1.0 - k) + sin(k * PI) * -sc))
	pts.append(Vector2(x + w, y + 2.0))
	pts.append(Vector2(x, y + 2.0))
	return pts
