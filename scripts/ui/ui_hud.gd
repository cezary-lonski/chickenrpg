class_name UiHud
extends CanvasLayer
## Paski życia, energii i furii, pasek bossa, licznik combo, ekwipunek
## szybkiego użycia i komunikaty.

var stage: Node = null
var player: Player = null

var hp_bar            # UiChickenGauge
var en_bar             # UiChickenGauge
var stamina_bar: UiBar
var fury_bar: UiBar
var xp_bar: UiBar
var skill_slots_ui: Array = []
var _effects_label: Label
var boss_panel: PanelContainer
var boss_bar: UiBar
var boss_name: Label
var combo_label: Label
var gold_label: Label
var cod_label: Label
var wave_label: Label
var party_panel: PanelContainer
var partner_name: Label
var partner_hp: UiBar
var partner_en: UiBar
var _partner: Player = null
var quest_panel: PanelContainer
var quest_title: Label
var quest_obj: Label
var item_row: HBoxContainer
var _skill_fan: UiSkillFan
var toast_box: VBoxContainer
var _boss: Node = null
var _toasts: Array = []
var _xp_value
var streak_box: VBoxContainer
var streak_label: Label
var streak_bar: UiBar
var _streak_shown := 0

func _ready() -> void:
	layer = 10
	_build()
	player = stage.get("player")
	if player:
		_connect_player()
		_skill_fan.player = player
	_setup_party()
	GameState.gold_changed.connect(func(v): gold_label.text = str(v))
	GameState.cod_changed.connect(func(v): cod_label.text = str(v))
	GameState.xp_changed.connect(_on_xp)
	GameState.toast.connect(add_toast)
	GameState.level_up.connect(func(_l): add_toast("POZIOM %d!" % _l, UiKit.ACCENT))
	gold_label.text = str(GameState.gold())
	cod_label.text = str(GameState.cod())
	_on_xp(int(GameState.char_profile(String(GameState.run.get("character", "kurczak"))).get("xp", 0)),
		CharacterDB.xp_for_level(int(GameState.char_profile(String(GameState.run.get("character", "kurczak"))).get("level", 1))),
		int(GameState.char_profile(String(GameState.run.get("character", "kurczak"))).get("level", 1)))
	_update_wave()
	_rebuild_items()

func _connect_player() -> void:
	player.health_changed.connect(func(h, m): hp_bar.set_value(h / maxf(1.0, m)); hp_bar.text = "%d" % int(h))
	player.energy_changed.connect(func(e, m): en_bar.set_value(e / maxf(1.0, m)); en_bar.text = "%d" % int(e))
	player.stamina_changed.connect(func(s, m): stamina_bar.set_value(s / maxf(1.0, m)))
	player.fury_changed.connect(func(v): fury_bar.set_value(v); fury_bar.text = "FURIA" if v >= 1.0 else "")
	player.combo_changed.connect(_on_combo)
	hp_bar.set_value(player.hp / maxf(1.0, player.max_hp))
	hp_bar.text = "%d" % int(player.hp)
	en_bar.set_value(player.energy / maxf(1.0, player.max_energy))
	en_bar.text = "%d" % int(player.energy)
	stamina_bar.set_value(player.stamina / maxf(1.0, player.max_stamina))
	_refresh_char_name()

func _setup_party() -> void:
	var players = stage.get("_net_players")
	if typeof(players) != TYPE_DICTIONARY or players.size() < 2:
		return
	for key in players:
		var p: Player = players[key]
		if p != null and is_instance_valid(p) and p != player:
			_partner = p
			break
	if _partner == null:
		return
	party_panel.visible = true
	partner_name.text = "P2 · %s" % String(CharacterDB.get_data(_partner.character_id).get("title", _partner.character_id))
	partner_hp.set_value(_partner.hp / maxf(1.0, _partner.max_hp))
	partner_en.set_value(_partner.energy / maxf(1.0, _partner.max_energy))
	_partner.health_changed.connect(func(h, m):
		partner_hp.set_value(h / maxf(1.0, m))
		partner_hp.text = "%d" % int(h))
	_partner.energy_changed.connect(func(e, m):
		partner_en.set_value(e / maxf(1.0, m)))
	partner_hp.text = "%d" % int(_partner.hp)

func _build() -> void:
	var root := Control.new()
	UiKit.full(root)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# --- lewy górny panel
	var left := UiKit.wood()
	left.position = Vector2(14, 12)
	left.custom_minimum_size = Vector2(340, 0)
	root.add_child(left)
	var lv := UiKit.vbox(4)
	left.add_child(lv)
	var top := UiKit.hbox(8)
	lv.add_child(top)
	var portrait := UiKit.icon(Art.hud_icon("chicken", 34, UiKit.ACCENT), 34)
	top.add_child(portrait)
	var names := UiKit.vbox(0)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(names)
	char_name = UiKit.label("Kurczak", 17, UiKit.TEXT)
	names.add_child(char_name)
	names.add_child(UiKit.label("Poziom 1", 12, UiKit.DIM))
	level_label = names.get_child(1)
	var frow := UiKit.hbox(6)
	lv.add_child(frow)
	var fl := UiKit.icon(Art.hud_icon("fury", 14, UiKit.FURY), 14)
	frow.add_child(fl)
	fury_bar = _bar(120, 12, UiKit.FURY)
	fury_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frow.add_child(fury_bar)
	stamina_bar = _bar(250, 10, Color(0.93, 0.78, 0.3))
	lv.add_child(stamina_bar)
	xp_bar = _bar(250, 8, UiKit.XP)
	lv.add_child(xp_bar)
	_effects_label = UiKit.label("", 12, UiKit.ACCENT2)
	lv.add_child(_effects_label)
	party_panel = UiKit.wood(4)
	party_panel.custom_minimum_size = Vector2(316, 0)
	party_panel.visible = false
	lv.add_child(party_panel)
	var pv := UiKit.vbox(2)
	party_panel.add_child(pv)
	partner_name = UiKit.label("", 12, UiKit.DIM)
	pv.add_child(partner_name)
	partner_hp = _bar(300, 10, UiKit.HP)
	pv.add_child(partner_hp)
	partner_en = _bar(300, 6, UiKit.EN)
	pv.add_child(partner_en)

	# --- prawy górny panel
	var right := UiKit.wood()
	right.position = Vector2(1126, 12)
	right.custom_minimum_size = Vector2(140, 0)
	root.add_child(right)
	var rv := UiKit.vbox(4)
	right.add_child(rv)
	var g := UiKit.hbox(6)
	rv.add_child(g)
	g.add_child(UiKit.icon(Art.hud_icon("gold", 18, Color(1, 0.82, 0.3)), 18))
	gold_label = UiKit.label("0", 16, Color(1, 0.85, 0.4))
	g.add_child(gold_label)
	var c := UiKit.hbox(6)
	rv.add_child(c)
	c.add_child(UiKit.icon(Art.hud_icon("cod", 18, Color(0.8, 0.85, 0.95)), 18))
	cod_label = UiKit.label("0", 16, Color(0.85, 0.9, 1.0))
	c.add_child(cod_label)
	wave_label = UiKit.label("", 14, UiKit.DIM)
	rv.add_child(wave_label)

	# --- pasek bossa
	boss_panel = UiKit.panel(Color(0.1, 0.05, 0.06, 0.8), 10)
	boss_panel.position = Vector2(330, 20)
	boss_panel.custom_minimum_size = Vector2(620, 0)
	boss_panel.visible = false
	root.add_child(boss_panel)
	var bv := UiKit.vbox(3)
	boss_panel.add_child(bv)
	boss_name = UiKit.label("BOSS", 16, Color(1, 0.6, 0.4), HORIZONTAL_ALIGNMENT_CENTER)
	bv.add_child(boss_name)
	boss_bar = _bar(596, 16, Color(0.85, 0.25, 0.2))
	bv.add_child(boss_bar)

	# --- combo
	combo_label = UiKit.label("", 34, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_LEFT)
	combo_label.position = Vector2(40, 250)
	combo_label.modulate.a = 0.0
	root.add_child(combo_label)

	# --- seria zabójstw: licznik i pasek czasu do jej utraty
	streak_box = UiKit.vbox(2)
	streak_box.position = Vector2(40, 318)
	streak_box.modulate.a = 0.0
	root.add_child(streak_box)
	streak_label = UiKit.label("", 22, Color(1.0, 0.8, 0.3), HORIZONTAL_ALIGNMENT_LEFT)
	streak_box.add_child(streak_label)
	streak_bar = _bar(130, 6, Color(1.0, 0.8, 0.3))
	streak_box.add_child(streak_bar)

	# --- umiejętności: wachlarz jajek na dole
	_skill_fan = UiSkillFan.new()
	_skill_fan.position = Vector2(640.0 - _skill_fan.size.x * 0.5, 612)
	root.add_child(_skill_fan)
	# kurczaki-mierniki życia i energii tuż przy rzędzie jajek, puste w środku
	hp_bar = UiChickenGauge.new()
	hp_bar.set_fill(Color(0.85, 0.28, 0.25))
	hp_bar.hi_col = Color(0.95, 0.5, 0.45)
	hp_bar.position = Vector2(_skill_fan.position.x - 224.0, 492)
	root.add_child(hp_bar)
	en_bar = UiChickenGauge.new()
	en_bar.flipped = true
	en_bar.set_fill(Color(0.29, 0.56, 0.88))
	en_bar.hi_col = Color(0.56, 0.76, 0.94)
	en_bar.position = Vector2(_skill_fan.position.x + _skill_fan.size.x, 492)
	root.add_child(en_bar)

	# --- przedmioty
	item_row = UiKit.hbox(6)
	item_row.visible = false   # szybkie przedmioty znikają z ekranu (rzut klawiszem I nadal działa)
	root.add_child(item_row)

	# --- tracker zadania
	quest_panel = UiKit.wood()
	quest_panel.position = Vector2(1000, 100)
	quest_panel.custom_minimum_size = Vector2(266, 0)
	quest_panel.visible = false
	root.add_child(quest_panel)
	var qv := UiKit.vbox(2)
	quest_panel.add_child(qv)
	quest_title = UiKit.label("", 15, UiKit.ACCENT2)
	quest_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	qv.add_child(quest_title)
	quest_obj = UiKit.label("", 14, UiKit.TEXT)
	quest_obj.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	qv.add_child(quest_obj)
	qv.add_child(UiKit.label("[Q] dziennik zadań", 12, UiKit.DIM))

	# --- toasty
	toast_box = UiKit.vbox(4)
	toast_box.position = Vector2(400, 360)
	toast_box.custom_minimum_size = Vector2(480, 130)
	toast_box.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(toast_box)

	# --- podpowiedź o sterowaniu (na starcie etapu)
	var hint_text := "WSAD ruch · Shift sprint · J/K atak · L unik · U blok · I rzut · O furia · 1-9 skile · E rozmowa · Q dziennik" if GameState.is_topdown() else "A/D ruch · Shift sprint · spacja skok (2x = stamina) · J/K atak · L unik · U blok · I rzut · O furia · 1-9 skile"
	var hint := UiKit.label(hint_text, 14, Color(0.85, 0.87, 0.92, 0.8), HORIZONTAL_ALIGNMENT_CENTER)
	hint.position = Vector2(190, 456)
	hint.custom_minimum_size = Vector2(900, 0)
	root.add_child(hint)
	var ht := create_tween()
	ht.tween_interval(6.0)
	ht.tween_property(hint, "modulate:a", 0.0, 1.5)

var char_name: Label
var level_label: Label

func _bar(w: float, h: float, col: Color) -> UiBar:
	var b := UiBar.new()
	b.custom_minimum_size = Vector2(w, h)
	b.set_fill(col)
	return b

func _build_skills(parent: VBoxContainer) -> void:
	parent.add_child(UiKit.label("SKILE (1-6)", 12, UiKit.DIM))
	var row := UiKit.hbox(4)
	parent.add_child(row)
	for i in range(6):
		var p := UiKit.panel(UiKit.BG3, 6)
		p.custom_minimum_size = Vector2(38, 46)
		var v := UiKit.vbox(0)
		p.add_child(v)
		var nl := UiKit.label("", 11, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(nl)
		var cl := UiKit.label("", 10, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER)
		v.add_child(cl)
		row.add_child(p)
		skill_slots_ui.append({"panel": p, "name": nl, "cost": cl})
	_update_skills()

func _update_skills() -> void:
	if player == null or not is_instance_valid(player) or skill_slots_ui.is_empty():
		return
	var slots: Array = player.skill_slots
	var cds: Array = player.skill_cd
	for i in range(skill_slots_ui.size()):
		var ui: Dictionary = skill_slots_ui[i]
		var id := String(slots[i]) if i < slots.size() else ""
		if id == "":
			(ui["name"] as Label).text = "—"
			(ui["cost"] as Label).text = ""
			(ui["panel"] as PanelContainer).modulate.a = 0.35
			continue
		var d := SkillDB.get_data(id)
		var cd := float(cds[i]) if i < cds.size() else 0.0
		(ui["name"] as Label).text = String(d.get("name", "?")).substr(0, 4)
		(ui["panel"] as PanelContainer).tooltip_text = "%s\n%s\nKoszt: %d energii · cd %.1fs" % [d.get("name", ""), d.get("desc", ""), int(d.get("cost", 0.0)), float(d.get("cd", 0.0))]
		if cd > 0.0:
			(ui["cost"] as Label).text = "%.0f" % cd
			(ui["panel"] as PanelContainer).modulate.a = 0.4
		else:
			(ui["cost"] as Label).text = "%d" % int(d.get("cost", 0.0))
			(ui["panel"] as PanelContainer).modulate.a = 1.0 if player.energy >= float(d.get("cost", 0.0)) else 0.55

func _update_effects() -> void:
	if _effects_label == null or player == null or not is_instance_valid(player):
		return
	var parts: Array = []
	for e in player.active_effects():
		parts.append("%s %.0fs" % [String(e["name"]), float(e["t"])])
	_effects_label.text = "  ·  ".join(parts)
	_effects_label.visible = not parts.is_empty()

func _refresh_char_name() -> void:
	var id := String(GameState.run.get("character", "kurczak"))
	var cp := GameState.char_profile(id)
	var custom_name := String(GameState.appearance().get("name", ""))
	char_name.text = custom_name if custom_name != "" else String(CharacterDB.get_data(id)["title"])
	level_label.text = "Poziom %d" % int(cp.get("level", 1))

func _on_xp(cur: int, need: int, _lvl: int) -> void:
	xp_bar.set_value(float(cur) / maxf(1.0, float(need)))
	xp_bar.text = "%d / %d XP" % [cur, need]
	_refresh_char_name()

func _on_combo(n: int) -> void:
	if n < 2:
		combo_label.modulate.a = 0.0
		return
	combo_label.text = "%d\nKOMBO" % n
	combo_label.modulate.a = 1.0
	combo_label.scale = Vector2(1.35, 1.35)
	var tw := create_tween()
	tw.tween_property(combo_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _update_streak() -> void:
	var left := GameState.streak_left()
	var n := GameState.streak if left > 0.0 else 0
	if n < 2:
		streak_box.modulate.a = move_toward(streak_box.modulate.a, 0.0, 0.1)
		_streak_shown = 0
		return
	streak_box.modulate.a = 1.0
	streak_bar.set_value(left / GameState.STREAK_WINDOW)
	if n != _streak_shown:
		_streak_shown = n
		streak_label.text = "SERIA ×%d  (x%.2f)" % [n, GameState.streak_mult(n)]
		streak_box.pivot_offset = Vector2.ZERO
		streak_box.scale = Vector2(1.25, 1.25)
		create_tween().tween_property(streak_box, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _update_wave() -> void:
	if stage == null:
		return
	wave_label.text = "Fala %d / %d" % [int(stage.wave_i), int(stage.waves.size())]

func _update_quest() -> void:
	if quest_panel == null:
		return
	var t: Variant = GameState.story_tracker()
	quest_panel.visible = bool(t.get("visible", false))
	if quest_panel.visible:
		quest_title.text = String(t.get("title", ""))
		quest_obj.text = String(t.get("objective", ""))

func _process(delta: float) -> void:
	if player and is_instance_valid(player):
		hp_bar.set_value(player.hp / maxf(1.0, player.max_hp))
		hp_bar.text = "%d" % int(player.hp)
		stamina_bar.set_value(player.stamina / maxf(1.0, player.max_stamina))
	_update_skills()
	_update_effects()
	_update_wave()
	_update_quest()
	_update_streak()
	_process_boss(delta)
	for t in _toasts.duplicate():
		t["t"] = float(t["t"]) - delta
		var nd: Control = t["node"]
		if is_instance_valid(nd) and float(t["t"]) < 0.6:
			nd.modulate.a = clampf(float(t["t"]) / 0.6, 0.0, 1.0)   # powolne gaśnięcie
		if float(t["t"]) <= 0.0:
			if is_instance_valid(nd):
				nd.queue_free()
			_toasts.erase(t)
	# komunikaty wchodzą po kolei, w odstępach, a nie wszystkie naraz
	_toast_gap -= delta
	if _toast_gap <= 0.0 and not _toast_queue.is_empty() and _toasts.size() < 5:
		var q: Array = _toast_queue.pop_front()
		_show_toast(String(q[0]), q[1])
		_toast_gap = 0.9 if _toast_queue.size() < 4 else 0.6

var _toast_queue: Array = []
var _toast_gap := 0.0

func add_toast(text: String, color: Color = UiKit.TEXT) -> void:
	if not GameState.setting("toasts"):
		return
	if _toast_queue.size() >= 12:
		_toast_queue.pop_front()
	_toast_queue.append([text, color])

func _show_toast(text: String, color: Color) -> void:
	var p := UiKit.wood()
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var l := UiKit.label(text, 17, color, HORIZONTAL_ALIGNMENT_CENTER)
	p.add_child(l)
	toast_box.add_child(p)
	_toasts.append({"node": p, "t": 5.0})
	p.modulate.a = 0.0
	p.position.x = -30.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(p, "modulate:a", 1.0, 0.4)

func _rebuild_items() -> void:
	for c in item_row.get_children():
		c.queue_free()
	var ids: Variant = GameState.consumed_ids()
	if ids.is_empty():
		return
	var shown := 0
	for id in ids:
		if shown >= 6:
			break
		var count: int = int(GameState.item_count(id))
		if count <= 0:
			continue
		var d := ItemDB.get_data(id)
		var p := UiKit.panel(Color(0.06, 0.07, 0.1, 0.8), 8)
		var h := UiKit.hbox(4)
		p.add_child(h)
		h.add_child(UiKit.icon(Art.item_icon(id, 24), 24))
		var v := UiKit.vbox(0)
		h.add_child(v)
		v.add_child(UiKit.label(String(d["name"]), 12, UiKit.TEXT))
		v.add_child(UiKit.label("x%d" % count, 12, UiKit.ACCENT))
		item_row.add_child(p)
		shown += 1
	var hint := UiKit.label("(I = rzuć pierwszym)", 12, UiKit.DIM)
	item_row.add_child(hint)

func set_boss(b: Node) -> void:
	if b == _boss:
		return
	_boss = b
	if b == null or not is_instance_valid(b):
		boss_panel.visible = false
		return
	boss_panel.visible = true
	boss_name.text = String(b.data.get("name", "BOSS")).to_upper()
	boss_bar.ghost = 1.0
	Audio.play("roar", 1.0, -2.0)

func _process_boss(delta: float) -> void:
	if _boss != null and (not is_instance_valid(_boss) or bool(_boss.get("dead")) or float(_boss.get("health")) <= 0.0):
		# boss padł — chowamy pasek
		boss_panel.visible = false
		_boss = null
		return
	if boss_panel.visible and _boss and is_instance_valid(_boss):
		var hp := float(_boss.health)
		var mx := float(_boss.max_health)
		boss_bar.set_value(hp / maxf(1.0, mx))
		boss_bar.text = "%d / %d" % [int(hp), int(mx)]
		var ph_val = _boss.get("phase")
		if ph_val != null:
			boss_name.text = "%s — FAZA %d" % [String(_boss.data.get("name", "BOSS")).to_upper(), int(ph_val)]
		else:
			boss_name.text = String(_boss.data.get("name", "BOSS")).to_upper()
