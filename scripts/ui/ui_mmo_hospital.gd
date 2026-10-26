class_name UiMmoHospital
extends UiMmoPanel
## Szpital: leczenie rannych strażników i peta oraz wypisywanie poległych za złoto. Czas leczenia liczy serwer.

var _state: Dictionary = {}
var _acc := 0.0

func _init() -> void:
	super._init("SZPITAL")

func apply_state(data: Dictionary) -> void:
	_state = data
	if _box != null:
		_rebuild()

func _build() -> void:
	_rebuild()

func _process(delta: float) -> void:
	# odliczanie czasu poległych między odświeżeniami z serwera
	_acc += delta
	var any := false
	for r in _state.get("rows", []):
		if bool(r["fallen"]):
			r["left"] = maxf(0.0, float(r["left"]) - delta)
			any = true
	if any and _acc >= 1.0 and _box != null:
		_acc = 0.0
		_rebuild()

func _fmt(sec: float) -> String:
	var t := int(ceil(sec))
	return "%d:%02d" % [t / 60, t % 60]

func _rebuild() -> void:
	_clear()
	_box.add_child(UiKit.label("Leczysz strażników i peta za złoto: ranni wracają do pełni sił, poległych możesz wypisać od razu. Bez zabiegu poległy wraca po 5 minutach.", 15, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var secs := float(_state.get("secs", 300.0))
	var gold := int(_state.get("gold", 0))
	for r in _state.get("rows", []):
		var key := String(r["key"])
		var mx := float(r["max"])
		var fallen := bool(r["fallen"])
		var left := float(r["left"])
		var hp := mx * (1.0 - left / secs) if fallen else float(r["hp"])
		var p := UiKit.panel(UiKit.BG, 10)
		var h := UiKit.hbox(14)
		p.add_child(h)
		var name_l := UiKit.label(String(r["title"]), 18, UiKit.TEXT)
		name_l.custom_minimum_size = Vector2(270, 0)
		h.add_child(name_l)
		var bar := ProgressBar.new()
		bar.max_value = mx
		bar.value = hp
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(260, 20)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var ratio := hp / maxf(1.0, mx)
		var col := UiKit.GOOD if ratio > 0.6 else (UiKit.ACCENT if ratio > 0.3 else UiKit.BAD)
		var fcol := Color(0.45, 0.7, 1.0) if fallen else col
		var fill := StyleBoxFlat.new()
		fill.bg_color = fcol
		bar.add_theme_stylebox_override("fill", fill)
		h.add_child(bar)
		h.add_child(UiKit.label("%d / %d" % [int(round(hp)), int(round(mx))], 17, fcol))
		if fallen:
			h.add_child(UiKit.label("wraca za %s" % _fmt(left), 17, UiKit.BAD))
			var cost := int(_state.get("revive", 0))
			var b := UiKit.button("Wypisz teraz (%d zł)" % cost, 16, UiKit.GOOD)
			b.disabled = gold < cost
			b.pressed.connect(func(): Mmo.send_act("hosp_revive", {"key": key}))
			h.add_child(b)
		elif hp < mx - 0.5:
			var hc := int(r["heal"])
			var b2 := UiKit.button("Ulecz (%d zł)" % hc, 16, UiKit.GOOD)
			b2.disabled = gold < hc
			b2.pressed.connect(func(): Mmo.send_act("hosp_heal", {"key": key}))
			h.add_child(b2)
		_box.add_child(p)
	_box.add_child(UiKit.label("Złoto: %d" % gold, 16, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER))
