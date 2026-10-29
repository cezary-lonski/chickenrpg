class_name Village
extends Node2D
## Strefa RPG w widoku z góry (top-down). Działa dla każdego rozdziału fabuły —
## teren, fale i NPC pochodzą z ZoneDB (na podstawie aktywnego rozdziału).
## Kamera podąża za graczem w obu osiach, przeszkody blokują ruch.

signal stage_cleared
signal player_died

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")

const VILLAGE := Vector2(2200.0, 1500.0)
const MARGIN := 80.0

@export var stage_index := 0

var player: Player = null
var hud: UiHud = null
var camera: Camera2D = null
var entities: Node2D = null
var waves: Array = []
var wave_i := 0
var wave_active := false
var finished := false
var rng := RandomNumberGenerator.new()
var npcs: Array = []
var _talk_target := ""
var _dialog_open := false
var _waves_started := false
var _reward_given := false

var _net_host := false
var _net_client := false
var _net_players: Dictionary = {}
var _net_enemies: Dictionary = {}
var _net_enemy_seq := 0
var _net_snapshot_acc := 0.0
var _net_input_acc := 0.0
var _boss_pool: Array = []
var _boss_hud_t := 0.0
var _net_pending_actions: Array = []

# konfiguracja bieżącej strefy / rozdziału
var quest_id := "obrona_wioski"
var zone: Dictionary = {}
var terrain := "village"
var giver := "starosta"
var spawn := Vector2(1100, 1080)
var villain: Dictionary = {}

func _ready() -> void:
	rng.seed = 424242
	cave_id = String(GameState.rpg.get("cave", ""))
	custom_cfg = GameState.rpg.get("custom", {}) if GameState.rpg.get("custom") is Dictionary else {}
	custom_mode = not custom_cfg.is_empty() and not Net.has_peer()
	_net_host = GameState.rpg_mode_str() == "lan" and Net.is_host and Net.has_peer()
	_net_client = GameState.rpg_mode_str() == "lan" and not Net.is_host and Net.has_peer()
	arena_mode = bool(GameState.rpg.get("arena", false)) and (_net_host or _net_client)
	challenge_mode = bool(GameState.rpg.get("challenge", false)) and not Net.has_peer()
	var mr = GameState.rpg.get("march")
	march_mode = mr is Dictionary and not (mr as Dictionary).is_empty() and not Net.has_peer() and int((mr["route"] as Array)[clampi(int(mr["i"]), 0, (mr["route"] as Array).size() - 1)]) == GameState.story_chapter()
	cave_mode = (cave_id != "" and not SecretDB.cave_zone(cave_id).is_empty()) or custom_mode or arena_mode or challenge_mode
	quest_id = _active_quest_id()
	zone = ZoneDB.get_data(quest_id) if ZoneDB.has(quest_id) else ZoneDB.for_chapter(GameState.story_chapter())
	if arena_mode:
		zone = _arena_zone()
	elif challenge_mode:
		zone = _challenge_zone()
	elif custom_mode:
		zone = _custom_zone()
	elif cave_mode:
		zone = SecretDB.cave_zone(cave_id)
	terrain = String(zone.get("terrain", "village"))
	giver = String(zone.get("giver", "starosta"))
	spawn = zone.get("spawn", Vector2(1100, 1080))
	villain = zone.get("villain", {})
	waves = zone.get("waves", [])
	stairs_mode = bool(zone.get("stairs", false)) and not march_mode and not cave_mode
	if march_mode:
		waves = waves.filter(func(w): return not bool(w.get("boss", false)))
	# po śmierci: ta sama fala i ci sami potwory (zapamiętane przy porażce, zob. _record_death)
	var st := GameState.story()
	if not _net_client and not cave_mode and not custom_mode and not march_mode and String(st.get("retry_quest", "")) == quest_id and int(st.get("retry_wave", -1)) >= 0 and not waves.is_empty():
		_retry_wave = mini(int(st["retry_wave"]), waves.size() - 1)
	st.erase("retry_wave")
	st.erase("retry_quest")
	# wznowienie zapisu w trakcie bitwy: zacznij rozdział od rozmowy
	if not _net_client and not cave_mode and GameState.story_step() >= 1 and GameState.story_step() <= waves.size():
		GameState.set_story_step(0)

	_build_ground()
	var tint := CanvasModulate.new()
	tint.color = _terrain_tint()
	add_child(tint)
	entities = Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	add_child(entities)
	var ambient := AmbientField.new()
	ambient.setup(_ambient_mode(), VILLAGE, 23)
	add_child(ambient)
	_build_walls()
	_build_scenery()
	_build_npcs()
	_build_extras()
	_build_corpse()
	_build_side()
	_build_decor()
	_build_rooms()
	_build_stash()
	_build_secrets()
	_build_lab()
	_build_hospital()
	var ach_timer := Timer.new()
	ach_timer.wait_time = 4.0
	ach_timer.autostart = true
	ach_timer.timeout.connect(func():
		for nm in AchievementDB.check():
			GameState.toast.emit("OSIĄGNIĘCIE: %s" % nm, UiKit.ACCENT)
			Audio.play("levelup", 1.2, -6.0))
	add_child(ach_timer)
	_setup_camera()
	_spawn_players()
	_spawn_allies()
	hud = UiHud.new()
	hud.stage = self
	add_child(hud)
	Fx.set_world(entities, camera)
	Fx.fade_to(0.0, 1.6)
	if _net_client:
		Net.snapshot_received.connect(_on_net_snapshot)
		if not Net.latest_snapshot.is_empty():
			_on_net_snapshot(Net.latest_snapshot)
	else:
		_begin_story()
	if arena_mode:
		_build_arena_bar()
		if _net_client:
			_begin_arena()
	if _net_host or _net_client:
		Net.world_event_received.connect(_on_world_event)
	if _net_host:
		Net.peer_left.connect(_on_net_peer_left)
		Net.broadcast_game_started({
			"chapter": GameState.story_chapter(),
			"quest": GameState.story_quest(),
			"step": GameState.story_step(),
			"flags": GameState.story().get("flags", {}).duplicate(true),
			"stage_index": int(GameState.run.get("stage_index", 0)),
			"p1": _player_id(0),
			"p2": _player_id(1),
			"cave": cave_id,
			"arena": arena_mode,
		})

func _on_net_peer_left(_id: int) -> void:
	if finished:
		return
	GameState.toast.emit("Drugi gracz rozłączył się. Kontynuujesz sam.", UiKit.BAD)

## Identyfikator questa aktywnego rozdziału; jeśli brak, bierze pierwszy gotowy.
func _active_quest_id() -> String:
	var q := GameState.story_quest()
	if q != "" and ZoneDB.has(q):
		return q
	var c := QuestDB.chapter(GameState.story_chapter())
	var id := String(c.get("id", ""))
	if ZoneDB.has(id):
		return id
	return "obrona_wioski"

func _player_id(index: int) -> String:
	var players: Array = GameState.rpg_players()
	if index >= 0 and index < players.size():
		return String(players[index].get("id", "lord" if index == 0 else "lady"))
	return "lord" if index == 0 else "lady"

func _begin_story() -> void:
	if _net_client:
		return
	if march_mode:
		_begin_march_stage()
		return
	if stairs_mode:
		_begin_stairs_floor()
		return
	if arena_mode:
		_begin_arena()
		return
	if challenge_mode:
		_begin_challenge()
		return
	if cave_mode:
		_begin_cave()
		return
	if _retry_wave >= 0:
		_resume_from_wave()
		return
	if zone.get("council", false):
		_begin_council()
		return
	await get_tree().create_timer(0.9).timeout
	if not is_instance_valid(self) or finished:
		return
	var banner: Array = zone.get("intro_banner", ["", ""])
	_banner(String(banner[0]), String(banner[1]))
	await get_tree().create_timer(1.7).timeout
	if not is_instance_valid(self) or finished:
		return
	var title := _hero_title()
	var lines := _with_title(zone.get("intro", []), title)
	_open_dialog(lines, UiKit.ACCENT2, func():
		var giver_name := String(NpcDB.get_data(giver).get("name", "sojusznik"))
		GameState.toast.emit("Zadanie: %s czeka na rozmowę" % giver_name, UiKit.ACCENT))

func _with_title(lines: Array, title: String) -> Array:
	var out: Array = []
	for ln in lines:
		var pair: Array = ln.duplicate()
		if pair.size() >= 2:
			var txt := String(pair[1])
			if txt.contains("%s"):
				txt = txt % title
			pair[1] = txt
		out.append(pair)
	return out

func _vignette_then(kind: String, done: Callable) -> void:
	await _vignette_async(kind)
	if is_instance_valid(self):
		await get_tree().process_frame   # Flow najpierw domyka nakładkę historyjki
		done.call()

func _vignette_async(kind: String) -> void:
	_dialog_open = true
	var ui := UiVignette.new()
	ui.setup(kind)
	Flow.open_dialog(ui)
	await ui.on_close
	_dialog_open = false

## Narada wojenna to animowana historyjka (zamiast rozmów z NPC), a po niej wybór strategii i zamach.
func _begin_council() -> void:
	await get_tree().create_timer(0.9).timeout
	if not is_instance_valid(self) or finished:
		return
	var banner: Array = zone.get("intro_banner", ["", ""])
	_banner(String(banner[0]), String(banner[1]))
	await get_tree().create_timer(1.7).timeout
	if not is_instance_valid(self) or finished:
		return
	_dialog_open = true
	var ui := UiVignette.new()
	ui.setup("council")
	ui.on_close.connect(func():
		_dialog_open = false
		await get_tree().process_frame   # Flow najpierw domyka nakładkę historyjki
		var qd: Dictionary = ChapterExtras.EXTRAS.get(quest_id, {}).get("dialogs", {}).get("krolowa", {})
		_open_choice(qd.get("choice", {}), UiKit.ACCENT2, func():
			_banner("ZAMACH!", "Zamachowcy wpadają do sali narad")
			Audio.play("gate", 0.8, -4.0)
			await get_tree().create_timer(1.6).timeout
			_begin_defense()))
	Flow.open_dialog(ui)

func _hero_title() -> String:
	return NpcDB.hero_title(String(GameState.run.get("character", "kurczak")))

var _retry_wave := -1

## Powtórka po śmierci: bez rozmów i narady, od razu ta sama fala z tymi samymi potworami.
func _resume_from_wave() -> void:
	await get_tree().create_timer(1.2).timeout
	if not is_instance_valid(self) or finished:
		return
	_banner("PONOWNIE", "Fala %d / %d" % [_retry_wave + 1, waves.size()])
	await get_tree().create_timer(1.2).timeout
	if not is_instance_valid(self) or finished:
		return
	wave_i = _retry_wave
	_begin_defense()

## Porażka: zapamiętaj falę (powtórka zacznie od niej) i zabierz część przedmiotów z plecaka.
func _record_death() -> void:
	if _waves_started and not cave_mode and not custom_mode and not march_mode and not _net_client:
		GameState.story()["retry_wave"] = maxi(0, wave_i - 1)
		GameState.story()["retry_quest"] = quest_id
	var at := player.global_position if (player != null and is_instance_valid(player)) else spawn
	GameState.drop_corpse(_corpse_zone(), at)

# ------------------------------------------------------ zwłoki i kradzież ---

var _angry_npcs: Dictionary = {}
var _corpse_node: Interactable

func _corpse_zone() -> String:
	return cave_id if cave_mode else quest_id

## Zwłoki gracza z poprzedniej śmierci w tej strefie: można je przeszukać i odzyskać rzeczy.
func _build_corpse() -> void:
	var c := GameState.corpse()
	if c.is_empty() or String(c.get("zone", "")) != _corpse_zone() or custom_mode or arena_mode or challenge_mode:
		return
	var p: Array = c["pos"]
	_corpse_node = Interactable.new()
	_corpse_node.setup("corpse", "Przeszukaj swoje zwłoki")
	_spot(_corpse_node, Vector2(float(p[0]), float(p[1])))
	_corpse_node.activated.connect(func(_w): _open_corpse())

func _corpse_box() -> Dictionary:
	var c := GameState.corpse()
	var items: Array = []
	for e in c.get("items", []):
		items.append({"id": String(e["id"]), "n": int(e["n"])})
	return Pickpocket.make_box("Twoje zwłoki", "corpse", int(c.get("gold", 0)), items)

func _open_corpse() -> void:
	if _dialog_open or GameState.corpse().is_empty():
		return
	var ui := UiLoot.new()
	ui.setup(_corpse_box())
	_dialog_open = true
	ui.take.connect(func(i: int): _corpse_take(ui, i))
	ui.on_close.connect(func(): _dialog_open = false)
	Flow.open_dialog(ui)

func _corpse_take(ui: UiLoot, i: int) -> void:
	var c := GameState.corpse()
	if c.is_empty():
		ui.on_close.emit()
		return
	if i == UiLoot.TAKE_GOLD or i == UiLoot.TAKE_ALL:
		GameState.add_gold(int(c["gold"]))
		c["gold"] = 0
	var items: Array = c["items"]
	if i == UiLoot.TAKE_ALL:
		while not items.is_empty():
			if not GameState.give_entry(items[0]):
				GameState.toast.emit("Plecak pełny.", UiKit.BAD)
				break
			items.remove_at(0)
	elif i >= 0 and i < items.size():
		if GameState.give_entry(items[i]):
			items.remove_at(i)
		else:
			GameState.toast.emit("Plecak pełny.", UiKit.BAD)
	GameState.save_game()
	if int(c["gold"]) <= 0 and items.is_empty():
		GameState.clear_corpse()
		if _corpse_node != null and is_instance_valid(_corpse_node):
			_corpse_node.queue_free()
		ui.on_close.emit()
		return
	ui.refresh(_corpse_box())

## Umiejętność „Kradzież”: najbliższy potwór albo NPC (bez zleceniodawcy, handlarzy i kowala); otwiera się jego ekwipunek.
func _steal_target() -> Dictionary:
	if player == null or not is_instance_valid(player):
		return {}
	var best := {}
	var best_d := 200.0
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or not (e is Node2D) or e.has_meta("robbed"):
			continue
		if e.has_method("is_dead") and e.is_dead():
			continue
		var d := player.global_position.distance_to((e as Node2D).global_position)
		if d < best_d:
			best_d = d
			best = {"kind": "enemy", "node": e}
	for entry in npcs:
		var nid := String(entry["id"])
		if nid == giver or String(entry["role"]) in Pickpocket.SAFE_ROLES or not is_instance_valid(entry["node"]):
			continue
		var d2 := player.global_position.distance_to((entry["node"] as Node2D).global_position)
		if d2 < best_d:
			best_d = d2
			best = {"kind": "npc", "id": nid}
	return best

func _on_steal() -> void:
	if _dialog_open or finished:
		return
	var t := _steal_target()
	if t.is_empty():
		Fx.popup(player.global_position + Vector2(0, -80), "BRAK CELU", Color(0.7, 0.7, 0.9))
		return
	var box := {}
	if String(t["kind"]) == "enemy":
		var e: Enemy = t["node"]
		var b := Pickpocket.enemy_box(e.gold_value)
		box = Pickpocket.make_box("Kieszenie: " + String(EnemyDB.get_data(e.species).get("name", "potwór")), "steal", int(b["gold"]), b["items"])
		e.set_meta("robbed", true)
	else:
		var nid := String(t["id"])
		var b2 := Pickpocket.npc_box(nid)
		var items: Array = []
		for i in (b2["items"] as Array).size():
			if not GameState.story_flag("pp:%s:%d" % [nid, i]):
				items.append((b2["items"] as Array)[i].merged({"pp": i}))
		var gold := 0 if GameState.story_flag("pp:%s:g" % nid) else int(b2["gold"])
		box = Pickpocket.make_box("Kieszenie: " + String(NpcDB.get_data(nid).get("name", "?")), "steal", gold, items)
	if (box["items"] as Array).is_empty() and int(box["gold"]) <= 0:
		GameState.toast.emit("Kieszenie są puste.", UiKit.DIM)
		return
	var ui := UiLoot.new()
	ui.setup(box)
	_dialog_open = true
	var state := {"taken": 0}
	ui.take.connect(func(i: int): _steal_take(ui, t, box, state, i))
	ui.on_close.connect(func(): _dialog_open = false)
	Flow.open_dialog(ui)

func _steal_take(ui: UiLoot, t: Dictionary, box: Dictionary, state: Dictionary, i: int) -> void:
	if i < UiLoot.TAKE_GOLD or (i >= 0 and i >= (box["items"] as Array).size()):
		return
	var mod := EncounterDB.modifier("zrecznosc", EncounterDB.ctx_game())
	if randf() < Pickpocket.notice_chance(int(state["taken"]), i == UiLoot.TAKE_GOLD, mod):
		_steal_noticed(t)
		ui.on_close.emit()
		return
	if i == UiLoot.TAKE_GOLD:
		GameState.add_gold(int(box["gold"]))
		box["gold"] = 0
		if String(t["kind"]) == "npc":
			GameState.set_story_flag("pp:%s:g" % String(t["id"]))
	else:
		var e: Dictionary = (box["items"] as Array)[i]
		GameState.add_item(String(e["id"]), int(e["n"]))
		if String(t["kind"]) == "npc" and e.has("pp"):
			GameState.set_story_flag("pp:%s:%d" % [String(t["id"]), int(e["pp"])])
		(box["items"] as Array).remove_at(i)
	state["taken"] = int(state["taken"]) + 1
	GameState.save_game()
	Audio.play("coin", 1.2, -4.0)
	if int(box["gold"]) <= 0 and (box["items"] as Array).is_empty():
		ui.on_close.emit()
		return
	ui.refresh(box)

func _steal_noticed(t: Dictionary) -> void:
	Audio.play("hit_heavy", 0.8, -4.0)
	if String(t["kind"]) == "npc":
		_angry_npcs[String(t["id"])] = true
		GameState.toast.emit("%s zauważył, że go okradasz! Jest wściekły." % String(NpcDB.get_data(String(t["id"])).get("name", "NPC")), UiKit.BAD)
		if Act2DB.rep() > 0:
			Act2DB.add_rep(-1)
	else:
		var e = t.get("node")
		if e != null and is_instance_valid(e):
			e.dormant = false
			e.aggro = 2600.0
		GameState.toast.emit("Potwór zauważył kradzież i rzuca się na ciebie!", UiKit.BAD)

func _begin_defense() -> void:
	if _waves_started or finished:
		return
	_waves_started = true
	_set_step(1)
	Audio.play("gate", 1.0, -6.0)
	_spawn_wave()

# ------------------------------------------------------------------ świat ---

func _ground_palette() -> Dictionary:
	match terrain:
		"road":
			return {"base": Color(0.42, 0.5, 0.3), "path": Color(0.58, 0.5, 0.34), "decor": Color(0.22, 0.34, 0.2, 0.35)}
		"city":
			return {"base": Color(0.34, 0.32, 0.3), "path": Color(0.46, 0.44, 0.42), "decor": Color(0.28, 0.24, 0.22, 0.35)}
		"tower":
			return {"base": Color(0.3, 0.3, 0.36), "path": Color(0.42, 0.42, 0.5), "decor": Color(0.2, 0.2, 0.28, 0.4)}
		"forest":
			return {"base": Color(0.2, 0.34, 0.22), "path": Color(0.4, 0.34, 0.22), "decor": Color(0.15, 0.28, 0.16, 0.4)}
		"fortress":
			return {"base": Color(0.2, 0.19, 0.22), "path": Color(0.32, 0.29, 0.3), "decor": Color(0.14, 0.12, 0.16, 0.45)}
		"ash":
			return {"base": Color(0.17, 0.16, 0.18), "path": Color(0.28, 0.25, 0.26), "decor": Color(0.42, 0.18, 0.14, 0.28)}
		"desert":
			return {"base": Color(0.72, 0.59, 0.36), "path": Color(0.83, 0.72, 0.48), "decor": Color(0.58, 0.45, 0.26, 0.32)}
		"storm":
			return {"base": Color(0.16, 0.25, 0.21), "path": Color(0.35, 0.3, 0.24), "decor": Color(0.1, 0.17, 0.19, 0.5)}
		"dawn":
			return {"base": Color(0.29, 0.22, 0.27), "path": Color(0.44, 0.35, 0.32), "decor": Color(0.72, 0.4, 0.24, 0.3)}
		"cave":
			return {"base": Color(0.11, 0.1, 0.14), "path": Color(0.18, 0.16, 0.21), "decor": Color(0.35, 0.22, 0.5, 0.3)}
		"palace":
			return {"base": Color(0.62, 0.6, 0.67), "path": Color(0.62, 0.14, 0.2), "decor": Color(0.5, 0.48, 0.58, 0.3)}
		_:
			return {"base": Color(0.32, 0.46, 0.27), "path": Color(0.52, 0.42, 0.28), "decor": Color(0.24, 0.36, 0.2, 0.35)}

func _terrain_tint() -> Color:
	match terrain:
		"desert":
			return Color(1.06, 0.98, 0.86)
		"storm":
			return Color(0.7, 0.79, 0.94)
		"ash":
			return Color(0.72, 0.69, 0.77)
		"dawn":
			return Color(1.02, 0.86, 0.76)
		"fortress", "tower":
			return Color(0.8, 0.78, 0.87)
		"cave":
			return Color(0.66, 0.62, 0.82)
		"city":
			return Color(0.92, 0.89, 0.91)
		"palace":
			return Color(1.0, 0.96, 0.94)
		"forest":
			return Color(0.88, 0.99, 0.86)
	return Color.WHITE

func _ambient_mode() -> String:
	match terrain:
		"desert":
			return "sand"
		"storm":
			return "rain"
		"ash":
			return "ash"
		"dawn", "fortress", "tower", "cave":
			return "embers"
		"road", "city":
			return "dust"
		"forest":
			return "leaves"
	return "leaves"

func _build_ground() -> void:
	var pal := _ground_palette()
	add_child(PixelGround.sprite(terrain, VILLAGE, pal["base"], pal["path"], pal["decor"]))

func _build_walls() -> void:
	var walls := StaticBody2D.new()
	walls.collision_layer = 1
	walls.collision_mask = 0
	add_child(walls)
	var t := 200.0
	var specs := [
		[Vector2(VILLAGE.x * 0.5, -t * 0.5), Vector2(VILLAGE.x + t * 2.0, t)],
		[Vector2(VILLAGE.x * 0.5, VILLAGE.y + t * 0.5), Vector2(VILLAGE.x + t * 2.0, t)],
		[Vector2(-t * 0.5, VILLAGE.y * 0.5), Vector2(t, VILLAGE.y + t * 2.0)],
		[Vector2(VILLAGE.x + t * 0.5, VILLAGE.y * 0.5), Vector2(t, VILLAGE.y + t * 2.0)],
	]
	for spec in specs:
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = spec[1]
		cs.shape = sh
		cs.position = spec[0]
		walls.add_child(cs)

func _house(pos: Vector2, w: float, h: float, body_col: Color, roof_col: Color) -> Node2D:
	var n := Node2D.new()
	n.position = pos
	entities.add_child(n)
	var ob := StaticBody2D.new()
	ob.collision_layer = 1
	ob.collision_mask = 0
	n.add_child(ob)
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(w, h)
	cs.shape = sh
	cs.position = Vector2(0, -h * 0.5)
	ob.add_child(cs)
	n.add_child(PixelProps.house(w, h, body_col, roof_col))
	return n

func _build_scenery() -> void:
	match terrain:
		"road":
			for i in 26:
				_tree(Vector2(rng.randf_range(120, VILLAGE.x - 120), rng.randf_range(120, 420)), rng.randf_range(0.8, 1.3), i)
				_tree(Vector2(rng.randf_range(120, VILLAGE.x - 120), rng.randf_range(1080, VILLAGE.y - 120)), rng.randf_range(0.8, 1.3), i + 40)
		"forest":
			for i in 40:
				_tree(Vector2(rng.randf_range(120, VILLAGE.x - 120), rng.randf_range(120, VILLAGE.y - 120)), rng.randf_range(0.9, 1.5), i)
		"city":
			_house(Vector2(430, 620), 220, 140, Color(0.6, 0.56, 0.5), Color(0.45, 0.3, 0.25))
			_house(Vector2(1760, 620), 220, 140, Color(0.58, 0.54, 0.5), Color(0.4, 0.34, 0.3))
			_house(Vector2(430, 1220), 220, 140, Color(0.62, 0.58, 0.52), Color(0.5, 0.34, 0.28))
			_house(Vector2(1760, 1220), 220, 140, Color(0.58, 0.55, 0.5), Color(0.44, 0.3, 0.26))
			for i in 8:
				_fence(Vector2(240 + i * 70.0, 380.0))
		"palace":
			for i in 10:
				var px := 240.0 + i * 180.0
				_pillar(Vector2(px, 330.0))
				_pillar(Vector2(px, VILLAGE.y - 190.0))
			for i in 6:
				_torch(Vector2(210.0 + i * 356.0, 430.0), Color(1.0, 0.82, 0.4), float(i))
				_torch(Vector2(210.0 + i * 356.0, 1120.0), Color(1.0, 0.82, 0.4), float(i) + 0.7)
		"tower", "fortress":
			for i in 10:
				var x := 240.0 + i * 180.0
				_pillar(Vector2(x, 360.0))
				_pillar(Vector2(x, VILLAGE.y - 200.0))
			for i in 6:
				_torch(Vector2(210.0 + i * 356.0, 420.0), Color(1.0, 0.58, 0.2), float(i))
				_torch(Vector2(210.0 + i * 356.0, 1120.0), Color(1.0, 0.58, 0.2), float(i) + 0.7)
		"ash":
			for i in 9:
				_pillar(Vector2(250.0 + i * 216.0, 350.0))
				_pillar(Vector2(250.0 + i * 216.0, VILLAGE.y - 170.0))
			for i in 26:
				_rock(Vector2(rng.randf_range(120, VILLAGE.x - 120), rng.randf_range(160, VILLAGE.y - 160)), rng.randf_range(0.5, 1.25), Color(0.24, 0.22, 0.24), i)
			for i in 7:
				_dead_tree(Vector2(rng.randf_range(200, VILLAGE.x - 200), rng.randf_range(260, VILLAGE.y - 220)), rng.randf_range(0.8, 1.3), i)
			for i in 4:
				_torch(Vector2(300.0 + i * 520.0, 450.0), Color(1.0, 0.45, 0.2), float(i))
		"desert":
			for i in 14:
				_dune(Vector2(rng.randf_range(-80, VILLAGE.x + 80), rng.randf_range(80, VILLAGE.y - 60)), rng.randf_range(140, 320), Color(0.82, 0.68, 0.42, 0.32), i)
			for i in 18:
				_rock(Vector2(rng.randf_range(120, VILLAGE.x - 120), rng.randf_range(150, VILLAGE.y - 150)), rng.randf_range(0.45, 1.15), Color(0.58, 0.47, 0.32), i)
			for i in 8:
				_dead_tree(Vector2(rng.randf_range(200, VILLAGE.x - 200), rng.randf_range(220, VILLAGE.y - 180)), rng.randf_range(0.55, 0.95), i + 20)
			for i in 5:
				_bones(Vector2(rng.randf_range(220, VILLAGE.x - 220), rng.randf_range(260, VILLAGE.y - 200)), rng.randf_range(0.8, 1.3), i)
		"storm":
			for i in 30:
				_tree(Vector2(rng.randf_range(100, VILLAGE.x - 100), rng.randf_range(100, VILLAGE.y - 100)), rng.randf_range(0.9, 1.6), i)
			for i in 14:
				_rock(Vector2(rng.randf_range(140, VILLAGE.x - 140), rng.randf_range(140, VILLAGE.y - 140)), rng.randf_range(0.7, 1.5), Color(0.24, 0.27, 0.29), i + 30)
			for i in 12:
				_twig(Vector2(rng.randf_range(0, VILLAGE.x), rng.randf_range(0, VILLAGE.y)), rng.randf_range(-0.9, 0.9), rng.randf_range(70, 210), i)
		"cave":
			for i in 34:
				_rock(Vector2(rng.randf_range(120, VILLAGE.x - 120), rng.randf_range(160, VILLAGE.y - 160)), rng.randf_range(0.6, 1.5), Color(0.2, 0.18, 0.24), i)
			for i in 8:
				_torch(Vector2(200.0 + i * 260.0, 320.0), Color(0.7, 0.4, 1.0), float(i))
				_torch(Vector2(200.0 + i * 260.0, VILLAGE.y - 260.0), Color(0.7, 0.4, 1.0), float(i) + 0.5)
		"dawn":
			for i in 10:
				var dx := 240.0 + i * 180.0
				_pillar(Vector2(dx, 360.0))
				_pillar(Vector2(dx, VILLAGE.y - 200.0))
			for i in 8:
				_torch(Vector2(220.0 + i * 250.0, 430.0), Color(1.0, 0.78, 0.38), float(i))
			for i in 16:
				_rock(Vector2(rng.randf_range(150, VILLAGE.x - 150), rng.randf_range(200, VILLAGE.y - 150)), rng.randf_range(0.4, 0.9), Color(0.3, 0.25, 0.28), i + 40)
		_:
			_house(Vector2(430, 620), 240, 150, Color(0.72, 0.62, 0.46), Color(0.55, 0.28, 0.2))
			_house(Vector2(1720, 600), 240, 150, Color(0.68, 0.6, 0.44), Color(0.32, 0.36, 0.5))
			_house(Vector2(430, 1250), 220, 140, Color(0.7, 0.6, 0.45), Color(0.5, 0.3, 0.24))
			_house(Vector2(1760, 1240), 220, 140, Color(0.66, 0.58, 0.42), Color(0.4, 0.3, 0.24))
			_well(Vector2(VILLAGE.x * 0.5, VILLAGE.y * 0.57))
			var tree_spots := [
				Vector2(150, 300), Vector2(2050, 320), Vector2(160, 1100), Vector2(2040, 1120),
				Vector2(820, 240), Vector2(1360, 260), Vector2(700, 1420), Vector2(1500, 1430),
			]
			for i in tree_spots.size():
				_tree(tree_spots[i], rng.randf_range(0.9, 1.4), i)
			for i in 8:
				_fence(Vector2(240 + i * 70.0, 320.0))
				_fence(Vector2(240 + i * 70.0, 1420.0))

func _well(pos: Vector2) -> void:
	var well := Node2D.new()
	well.position = pos
	entities.add_child(well)
	var wb := StaticBody2D.new()
	wb.collision_layer = 1
	well.add_child(wb)
	var wcs := CollisionShape2D.new()
	var wsh := CircleShape2D.new()
	wsh.radius = 38.0
	wcs.shape = wsh
	wb.add_child(wcs)
	well.add_child(PixelProps.well())

func _pillar(pos: Vector2) -> void:
	var n := Node2D.new()
	n.position = pos
	entities.add_child(n)
	var ob := StaticBody2D.new()
	ob.collision_layer = 1
	ob.collision_mask = 0
	n.add_child(ob)
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 22.0
	cs.shape = sh
	cs.position = Vector2(0, -30)
	ob.add_child(cs)
	n.add_child(PixelProps.pillar())

func _tree(pos: Vector2, s: float, seed_i: int) -> void:
	var n := Node2D.new()
	n.position = pos
	n.scale = Vector2(s, s)
	entities.add_child(n)
	var ob := StaticBody2D.new()
	ob.collision_layer = 1
	n.add_child(ob)
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 16.0
	cs.shape = sh
	cs.position = Vector2(0, -18)
	ob.add_child(cs)
	var leaf := Color(0.25, 0.5, 0.24)
	if terrain == "storm":
		leaf = Color(0.2, 0.36, 0.3)
	elif terrain == "forest":
		leaf = Color(0.2, 0.46, 0.22)
	n.add_child(PixelProps.tree(seed_i, leaf))

func _fence(pos: Vector2) -> void:
	var n := Node2D.new()
	n.position = pos
	entities.add_child(n)
	n.add_child(PixelProps.fence())

func _torch(pos: Vector2, color: Color, phase: float) -> void:
	var t := Torch.new()
	t.setup(color, phase)
	t.position = pos
	entities.add_child(t)

func _rock(pos: Vector2, s: float, col: Color, seed_i: int) -> void:
	var n := Node2D.new()
	n.position = pos
	n.scale = Vector2(s, s)
	entities.add_child(n)
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 23.0
	cs.shape = sh
	cs.position = Vector2(0, -10)
	body.add_child(cs)
	n.add_child(body)
	n.add_child(PixelProps.rock(seed_i, col.lightened(0.12)))

func _dune(pos: Vector2, w: float, col: Color, seed_i: int) -> void:
	var sp := PixelProps.dune(w, Color(col.r, col.g, col.b, 0.5))
	sp.position += pos
	sp.z_index = -6
	add_child(sp)

func _dead_tree(pos: Vector2, s: float, seed_i: int) -> void:
	var n := Node2D.new()
	n.position = pos
	n.scale = Vector2(s, s)
	entities.add_child(n)
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 14.0
	cs.shape = sh
	cs.position = Vector2(0, -18)
	body.add_child(cs)
	n.add_child(body)
	n.add_child(PixelProps.dead_tree(seed_i))

func _bones(pos: Vector2, s: float, seed_i: int) -> void:
	var n := Node2D.new()
	n.position = pos
	n.scale = Vector2(s, s)
	n.z_index = -2
	add_child(n)
	n.add_child(PixelProps.bones(seed_i))

func _twig(pos: Vector2, ang: float, length: float, seed_i: int) -> void:
	var n := Node2D.new()
	n.position = pos
	n.rotation = ang
	n.z_index = -1
	add_child(n)
	n.add_child(PixelProps.twig(length, seed_i))

# ------------------------------------------------------------------- NPC ----

func _build_npcs() -> void:
	var ids: Array = zone.get("npcs", NpcDB.LIST.keys())
	for id in ids:
		_npc(String(id))

func _npc(id: String) -> void:
	var data := NpcDB.get_data(id)
	var role := String(data.get("role", "lore"))
	var accent: Color = data.get("accent", UiKit.ACCENT)
	var n := Node2D.new()
	n.name = "Npc_" + id
	n.position = data.get("pos", Vector2.ZERO)
	entities.add_child(n)
	if role == "shop":
		var stall := MerchantStall.new()
		stall.setup(accent, 17)
		stall.position = Vector2(-104, -26)
		n.add_child(stall)
		var sb := StaticBody2D.new()
		sb.collision_layer = 1
		sb.collision_mask = 0
		var scs := CollisionShape2D.new()
		var ssh := RectangleShape2D.new()
		ssh.size = Vector2(196, 34)
		scs.shape = ssh
		scs.position = Vector2(-104, -12)
		sb.add_child(scs)
		n.add_child(sb)
	if role == "smith":
		var prop := ForgeProp.new()
		prop.position = Vector2(60, 22)
		n.add_child(prop)
	var cv := CreatureVisual.new()
	cv.configure(String(data.get("species", "kurczak")), NpcDB.pal_for(id), float(data.get("scale", 1.4)))
	cv.set_facing(-1.0)
	cv.idle_seed = float(id.hash() % 100) * 0.13
	n.add_child(cv)
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 18.0
	cs.shape = sh
	cs.position = Vector2(0, -12)
	body.add_child(cs)
	n.add_child(body)
	var settings := LabelSettings.new()
	settings.font_size = 14
	settings.font_color = Color(0.95, 0.96, 1.0)
	settings.outline_size = 5
	settings.outline_color = Color(0, 0, 0, 0.85)
	var name_l := Label.new()
	name_l.text = String(data.get("name", "?"))
	name_l.label_settings = settings
	name_l.position = Vector2(-70, -96)
	name_l.custom_minimum_size = Vector2(140, 0)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.add_child(name_l)
	var marker_settings := LabelSettings.new()
	marker_settings.font_size = 24
	marker_settings.font_color = accent
	marker_settings.outline_size = 6
	marker_settings.outline_color = Color(0, 0, 0, 0.9)
	var marker := Label.new()
	marker.text = ""
	marker.label_settings = marker_settings
	marker.position = Vector2(-70, -132)
	marker.custom_minimum_size = Vector2(140, 0)
	marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marker.visible = false
	n.add_child(marker)
	var prompt := Label.new()
	prompt.text = "[E] sklep" if role == "shop" else "[E] porozmawiaj"
	prompt.label_settings = settings
	prompt.position = Vector2(-70, -78)
	prompt.custom_minimum_size = Vector2(140, 0)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.modulate = accent
	prompt.visible = false
	n.add_child(prompt)
	npcs.append({"id": id, "node": n, "prompt": prompt, "marker": marker, "cv": cv, "role": role, "accent": accent, "greet": 0.0, "marker_text": ""})

func _nearest_npc() -> Dictionary:
	if player == null or not is_instance_valid(player):
		return {}
	var best := {}
	var best_d := 96.0
	for entry in npcs:
		var node: Node2D = entry["node"]
		if not is_instance_valid(node):
			continue
		var d := node.global_position.distance_to(player.global_position)
		if d < best_d:
			best_d = d
			best = entry
	return best

func _nearest_interactable() -> Interactable:
	if player == null or not is_instance_valid(player):
		return null
	var best: Interactable = null
	var best_d := 1.0e9
	for n in get_tree().get_nodes_in_group("interactables"):
		var it := n as Interactable
		if it == null or not is_instance_valid(it) or not it.visible or not it.can_use():
			continue
		var d := it.global_position.distance_to(player.global_position)
		if d <= it.radius and d < best_d:
			best_d = d
			best = it
	return best

## Gdy trwa rozmowa/historyjka lub rozdział się kończy, klawisz E nie może otwierać ekwipunku.
func blocks_loadout() -> bool:
	return _dialog_open or finished

func try_interact() -> bool:
	if _dialog_open or finished:
		return false
	var it := _nearest_interactable()
	var target := _nearest_npc()
	# wygrywa to, co bliżej: obiekt (tablica, drzwi, schody) albo rozmówca
	if it != null and (target.is_empty() or it.global_position.distance_to(player.global_position) <= (target["node"] as Node2D).global_position.distance_to(player.global_position) + 30.0):
		it.interact(player)
		return true
	if target.is_empty():
		return false
	_talk_to(String(target["id"]))
	return true

func _talk_to(id: String) -> void:
	if bool(_angry_npcs.get(id, false)):
		_open_dialog([[String(NpcDB.get_data(id).get("name", "?")), "Złodziej! Nie mam z tobą o czym rozmawiać!"]], NpcDB.get_data(id).get("accent", UiKit.ACCENT))
		return
	if _try_deliver_package(id):
		return
	var step := GameState.story_step()
	var flags: Dictionary = GameState.story().get("flags", {})
	var char_id := String(GameState.run.get("character", "kurczak"))
	var accent: Color = NpcDB.get_data(id).get("accent", UiKit.ACCENT)
	if id == giver:
		var waves_n := waves.size()
		if step > waves_n and not GameState.story_done(quest_id):
			var gate_post := _giver_gate("post")
			if gate_post != "":
				_open_dialog([[String(NpcDB.get_data(id).get("name", "?")), "Jeszcze nie koniec. Najpierw: %s." % gate_post]], accent)
			else:
				_open_dialog(NpcDB.lines_for(id, step, flags, char_id, quest_id), accent, _req_finish_story)
		elif not _waves_started and step == 0:
			var gate_pre := _giver_gate("pre")
			if gate_pre != "":
				_open_dialog([[String(NpcDB.get_data(id).get("name", "?")), "Zanim ruszymy do walki, musimy się przygotować: %s." % gate_pre]], accent)
			else:
				_open_dialog(NpcDB.lines_for(id, step, flags, char_id, quest_id), accent, _req_begin_defense)
		else:
			_open_dialog(NpcDB.lines_for(id, step, flags, char_id, quest_id), accent)
	elif ChapterExtras.NPCS.has(id):
		_talk_extra(id)
	elif id == "kupiec":
		_open_dialog(NpcDB.lines_for("kupiec", step, flags, char_id, quest_id), accent, _open_shop)
	elif id == "kowal":
		_open_dialog(NpcDB.lines_for("kowal", step, flags, char_id, quest_id), accent, func():
			if not GameState.story_flag("kowal_gift"):
				GameState.set_story_flag("kowal_gift")
				GameState.add_item("mikstura_miodu", 1)
				GameState.add_item("sztabka_zelaza", 2)
				GameState.save_game()
				GameState.toast.emit("Otrzymano: Mikstura miodu i 2 sztabki żelaza", UiKit.GOOD)
			_open_forge())
	else:
		_open_dialog(NpcDB.lines_for(id, step, flags, char_id, quest_id), accent)

func _open_forge() -> void:
	await get_tree().process_frame
	Flow.open_forge_overlay()

func _open_shop() -> void:
	await get_tree().process_frame
	Flow.open_shop_overlay()

## Dialog z oczekiwaniem na zamknięcie (do sekwencji fabularnych).
func _dialog_async(lines: Array, accent: Color) -> void:
	_dialog_open = true
	var d := UiDialog.new()
	d.setup(lines, accent)
	d.on_close.connect(func(): _dialog_open = false)
	await get_tree().process_frame
	Flow.open_dialog(d)
	await d.on_close

func _act_cinematic(qid: String) -> Array:
	if qid == "krol_i_kruk":
		return [
			["", "Czarne pióra opadają na posadzkę sali tronowej jak śnieg. Czarny Kruk, ranny, rozpościera skrzydła i ucieka w kłębach dymu."],
			["Czarny Kruk", "Jeszcze wrócę, kurczaku. Moje gniazda są liczniejsze niż twoje wioski. Nie zaznasz spokoju."],
			["Królowa Aurelia", "Fortecę mamy z powrotem, ale wojna się nie skończyła. Kruk obsadził wioski swoimi wronami."],
			["Królowa Aurelia", "Czas, byśmy to my uderzyli pierwsi. Wyzwól ich wioski jedna po drugiej — i dosięgnij go w jego gnieździe."],
			["", "AKT I UKOŃCZONY. Odblokowano AKT II: ZEMSTA NA CZARNYM KRUKU."],
		]
	if qid == Act2DB.FINAL:
		return [
			["", "Czarny Kruk Odrodzony rozsypuje się w czarny pył. Ostatnie pióro opada do twoich stóp i gaśnie."],
			["Kapitan Odwetu Hanna", "Zrobiłeś to. Wszystkie wioski są wolne. Nikt już nie zapomni twojego imienia."],
			["", "AKT II UKOŃCZONY. Przed tobą ostatnie rozdziały kampanii."],
		]
	return []

func _open_dialog(lines: Array, accent: Color, after: Callable = Callable()) -> void:
	if _dialog_open:
		return
	if lines.is_empty():
		if after.is_valid():
			after.call()
		return
	_dialog_open = true
	var d := UiDialog.new()
	d.setup(lines, accent)
	d.on_close.connect(func():
		_dialog_open = false
		if after.is_valid():
			after.call())
	Flow.open_dialog(d)

func _npc_marker_text(entry: Dictionary) -> String:
	if role_is_quest_giver(String(entry["id"])):
		var step := GameState.story_step()
		var waves_n := waves.size()
		if step > waves_n and not GameState.story_done(quest_id):
			return "?"
		if not _waves_started and step == 0:
			return "!"
		return ""
	if String(entry["role"]) == "shop":
		return "$"
	return ""

func role_is_quest_giver(id: String) -> bool:
	return id == giver

func _on_dialog_update() -> void:
	for entry in npcs:
		var prompt: Label = entry["prompt"]
		if is_instance_valid(prompt):
			prompt.visible = false
		var marker: Label = entry["marker"]
		if is_instance_valid(marker):
			var text := "" if _dialog_open or finished else _npc_marker_text(entry)
			if text != String(entry.get("marker_text", "")):
				entry["marker_text"] = text
				marker.text = text
			marker.visible = text != ""
	if _dialog_open or finished:
		return
	var t := _nearest_npc()
	if not t.is_empty():
		var prompt2: Label = t["prompt"]
		if is_instance_valid(prompt2):
			prompt2.visible = true

func _update_npc_animation(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var t := Time.get_ticks_msec() * 0.001
	for entry in npcs:
		var node: Node2D = entry["node"]
		if not is_instance_valid(node):
			continue
		var cv: CreatureVisual = entry["cv"]
		if not is_instance_valid(cv):
			continue
		var to_p := player.global_position - node.global_position
		if absf(to_p.x) > 12.0:
			cv.set_facing(sign(to_p.x))
		var near := to_p.length() < 180.0
		var want := 1.0 if near else 0.0
		entry["greet"] = move_toward(float(entry["greet"]), want, delta * 2.4)
		var g := float(entry["greet"])
		if String(entry["role"]) == "shop":
			cv.arm = g * (0.28 + 0.22 * sin(t * 6.0))
			cv.flap = g * (0.25 + 0.12 * sin(t * 6.0 + 0.7))
			cv.lean = sin(t * 1.7) * 0.03
		elif role_is_quest_giver(String(entry["id"])):
			cv.arm = g * (0.18 + 0.12 * sin(t * 4.0))
			cv.lean = g * sin(t * 2.2) * 0.04
		else:
			cv.arm = g * 0.12
			cv.lean = sin(t * 1.3 + cv.idle_seed) * 0.02


# ------------------------------------------------------------------ gracz ---

func _spawn_players() -> void:
	var p1 := _player_id(0)
	var p2 := _player_id(1)
	var at1 := ARENA_P1 if arena_mode else spawn
	var at2 := ARENA_P2 if arena_mode else spawn + Vector2(74.0, 0.0)
	if _net_client:
		var ghost1 := _make_player(p1, at1, true, false)
		var ghost2 := _make_player(p2, at2, true, false)
		ghost2.local_view = true   # to postać gościa: obiekty reagują na jej bliskość (podpowiedź [E], ukryte skrzynie)
		_net_players = {"p1": ghost1, "p2": ghost2}
		player = ghost2
		return
	if _net_host:
		player = _make_player(p1, at1, false, false)
		var remote := _make_player(p2, at2, false, true)
		remote.net_controlled = true
		_apply_remote_loadout(remote)
		if arena_mode:
			remote.team_tag = "player2"
			remote.hurtbox.team = "player2"
			remote.facing = -1.0
			remote.visual.set_facing(-1.0)
			remote.died.connect(_arena_ko.bind(remote))
			player.died.connect(_arena_ko.bind(player))
			player.add_to_group("enemies")
			remote.add_to_group("enemies")
		else:
			remote.died.connect(_on_remote_player_died.bind(remote))
		_net_players = {"p1": player, "p2": remote}
		return
	player = _make_player(p1, spawn, false, false)
	player.steal_cast.connect(_on_steal)
	_net_players = {"p1": player}
	GameState.run_set("time", float(GameState.run.get("time", 0.0)))

## Zdalny gracz walczy swoimi statystykami i wyglądem z własnego zapisu (przysłanymi przy dołączaniu).
func _apply_remote_loadout(remote: Player) -> void:
	var info := Net.first_client_info()
	if info.get("stats") is Dictionary:
		remote.stats_override = (info["stats"] as Dictionary).duplicate()
		remote._on_stats_changed({})
		remote.hp = remote.max_hp
		remote.health_changed.emit(remote.hp, remote.max_hp)
	if info.get("gear") is Dictionary:
		remote.visual.set_gear(CosmeticDB.gear_visual(info["gear"], {}))

func _make_player(character: String, at: Vector2, ghost: bool, controlled: bool) -> Player:
	var p := (PLAYER_SCENE as PackedScene).instantiate() as Player
	p.forced_character = character
	p.net_ghost = ghost
	p.net_controlled = controlled
	p.position = at
	entities.add_child(p)
	p.bounds_min = MARGIN
	p.bounds_max = VILLAGE.x - MARGIN
	p.bounds_top = MARGIN
	p.bounds_bottom = VILLAGE.y - MARGIN
	p.floor_y = VILLAGE.y - MARGIN
	if not ghost and not controlled and not arena_mode:
		p.died.connect(_on_player_died)
	return p

func _on_remote_player_died(remote: Player) -> void:
	if finished or remote == null or not is_instance_valid(remote):
		return
	await get_tree().create_timer(3.0).timeout
	if finished or not is_instance_valid(remote):
		return
	var at := player.global_position if player and is_instance_valid(player) else spawn
	remote.global_position = at + Vector2(40.0, 0.0)
	remote.celebrate()
	GameState.toast.emit("%s wraca do walki!" % NpcDB.hero_title(remote.character_id), UiKit.GOOD)

func _on_player_died() -> void:
	if finished:
		return
	await get_tree().create_timer(1.9).timeout
	if finished:
		return
	if challenge_mode:
		_challenge_over()
		return
	if GameState.item_count("zwoj_wskrzeszenia") > 0 and player != null and is_instance_valid(player):
		Flow.offer_revive(player, func():
			_record_death()
			finished = true
			player_died.emit())
		return
	_record_death()
	finished = true
	player_died.emit()

# ---------------------------------------------------------------- kamera ----

func _setup_camera() -> void:
	camera = Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(VILLAGE.x)
	camera.limit_bottom = int(VILLAGE.y)
	camera.position = spawn
	camera.zoom = Vector2.ONE * GameState.view_zoom()
	add_child(camera)

func _physics_process(_delta: float) -> void:
	if _net_host:
		var remote: Player = _net_players.get("p2")
		if remote and is_instance_valid(remote):
			remote.net_apply_input(Net.remote_move(), Net.remote_held(), Net.take_remote_actions())

func _track_boss(e: Enemy) -> void:
	if e == null or not is_instance_valid(e) or hud == null:
		return
	if not _boss_pool.has(e):
		_boss_pool.append(e)
	_refresh_boss_hud()

func _refresh_boss_hud() -> void:
	if hud == null:
		return
	var alive: Array = []
	for b in _boss_pool:
		if is_instance_valid(b) and float(b.health) > 0.0:
			alive.append(b)
	_boss_pool = alive
	if alive.is_empty():
		return
	var best: Enemy = alive[0]
	for b in alive:
		if float(b.max_health) > float(best.max_health):
			best = b
	hud.set_boss(best)

func _process(delta: float) -> void:
	_tick_hospital(delta)
	_sync_acc -= delta
	if _sync_acc <= 0.0:
		_sync_acc = 0.4
		_sync_world_state()
	if _cave_clock:
		_cave_t += delta
	_boss_hud_t -= delta
	if _boss_hud_t <= 0.0:
		_boss_hud_t = 0.25
		_refresh_boss_hud()
	if player and is_instance_valid(player):
		if not _net_client:
			GameState.run_add("time", delta)
		camera.position = player.position
		_on_dialog_update()
		_update_npc_animation(delta)
		if _net_host:
			_net_snapshot_acc += delta
			if _net_snapshot_acc >= 0.066:
				_net_snapshot_acc = 0.0
				_net_send_snapshot()
		elif _net_client:
			_net_client_input(delta)
		if wave_active and _alive_enemies().is_empty() and not _net_client:
			wave_active = false
			_on_wave_cleared()

# ---------------------------------------------------------------- sieć LAN ---

func _net_send_snapshot() -> void:
	var ps: Array = []
	for key in _net_players:
		var p: Player = _net_players[key]
		if p == null or not is_instance_valid(p):
			continue
		ps.append({
			"id": key,
			"character": p.character_id,
			"x": p.global_position.x,
			"y": p.global_position.y,
			"facing": p.facing,
			"hp": p.hp,
			"max_hp": p.max_hp,
			"energy": p.energy,
			"max_energy": p.max_energy,
			"state": p.state,
			"moving": p.visual.moving,
			"spin": p.visual.spin_angle,
			"spin_speed": p.visual.spin_speed,
			"berserk": p.berserk_t > 0.0,
		})
	var es: Array = []
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or e is Player or String(e.net_id) == "":
			continue
		es.append({
			"id": String(e.net_id),
			"species": String(e.species),
			"x": e.global_position.x,
			"y": e.global_position.y,
			"facing": e.facing,
			"health": e.health,
			"max_health": e.max_health,
			"state": e.state,
			"moving": e.visual.moving,
		})
	Net.broadcast_snapshot({
		"players": ps,
		"enemies": es,
		"wave_i": wave_i,
		"waves": waves.size(),
		"wave_active": wave_active,
		"chapter": GameState.story_chapter(),
		"quest": GameState.story_quest(),
		"step": GameState.story_step(),
		"flags": GameState.story().get("flags", {}).duplicate(true),
		"finished": finished,
	})

func _net_client_input(delta: float) -> void:
	for a in ["light_attack", "heavy_attack", "dash", "jump", "special", "throw_item", "block", "skill_1", "skill_2", "skill_3", "skill_4", "skill_5", "skill_6", "skill_7", "skill_8", "skill_9"]:
		if Input.is_action_just_pressed(a):
			_net_pending_actions.append(a)
	_net_input_acc += delta
	if _net_input_acc < 0.05:
		return
	_net_input_acc = 0.0
	var held := {
		"block": Input.is_action_pressed("block"),
		"sprint": Input.is_action_pressed("sprint"),
	}
	var move := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	Net.send_input(move, held, _net_pending_actions)
	_net_pending_actions.clear()

func _on_net_snapshot(snap: Dictionary) -> void:
	if not _net_client:
		return
	wave_i = int(snap.get("wave_i", wave_i))
	wave_active = bool(snap.get("wave_active", wave_active))
	finished = bool(snap.get("finished", finished))
	var s := GameState.story()
	s["chapter"] = int(snap.get("chapter", GameState.story_chapter()))
	s["quest"] = String(snap.get("quest", GameState.story_quest()))
	s["step"] = int(snap.get("step", GameState.story_step()))
	s["flags"] = snap.get("flags", {})
	for info in snap.get("players", []):
		var key := String(info.get("id", ""))
		var p: Player = _net_players.get(key)
		if p and is_instance_valid(p):
			p.apply_net_state(info)
	_apply_net_enemies(snap.get("enemies", []))

func _apply_net_enemies(list: Array) -> void:
	var seen := {}
	for info in list:
		var id := String(info.get("id", ""))
		if id == "":
			continue
		seen[id] = true
		var e: Enemy = _net_enemies.get(id)
		if e == null or not is_instance_valid(e):
			e = (ENEMY_SCENE as PackedScene).instantiate() as Enemy
			e.net_id = id
			e.net_ghost = true
			e.setup(String(info.get("species", "wrzos")), false, false)
			entities.add_child(e)
			e.global_position = Vector2(float(info.get("x", 0.0)), float(info.get("y", 0.0)))
			_net_enemies[id] = e
		if e.is_boss:
			_track_boss(e)
		e.apply_net_state(info)
	for id in _net_enemies.keys():
		if not seen.has(id):
			var old: Enemy = _net_enemies[id]
			if old and is_instance_valid(old):
				old.queue_free()
			_net_enemies.erase(id)

# ------------------------------------------------------------------ fale ---

func _alive_enemies() -> Array:
	var out := []
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		if e.has_method("is_dead") and e.is_dead():
			continue
		if e.has_meta("obj_elite"):
			continue
		out.append(e)
	return out

func _spawn_wave() -> void:
	if wave_i >= waves.size() or finished:
		return
	var wave: Dictionary = waves[wave_i]
	if not bool(wave.get("boss", false)):
		_banner("FALA %d / %d" % [wave_i + 1, waves.size()], String(wave.get("name", "")))
	wave_active = true
	wave_i += 1
	_set_step(wave_i)
	for entry in wave["enemies"]:
		var id := String(entry[0])
		if id.begins_with("BOSS:"):
			_spawn_boss(id.substr(5), wave)
			continue
		for i in int(entry[1]):
			var e: Enemy = (ENEMY_SCENE as PackedScene).instantiate() as Enemy
			if entry.size() > 3:
				e.skin = String(entry[3])
			e.setup(id, false, bool(wave.get("elite", false)) or (entry.size() > 2 and bool(entry[2])))
			if wave.has("hp"):
				e.apply_mods(float(wave["hp"]), float(wave.get("dmg", 1.0)), float(wave.get("xp", 1.0)))
			e.net_id = "e%d" % _net_enemy_seq
			_net_enemy_seq += 1
			e.aggro = 2600.0
			entities.add_child(e)
			e.global_position = _edge_spawn()
			e.set_bounds_rect(MARGIN, VILLAGE.x - MARGIN, MARGIN, VILLAGE.y - MARGIN)
			if e.is_boss:
				_track_boss(e)

func _edge_spawn() -> Vector2:
	var side := rng.randi() % 4
	var p := Vector2.ZERO
	match side:
		0: p = Vector2(rng.randf_range(MARGIN, VILLAGE.x - MARGIN), MARGIN + 20.0)
		1: p = Vector2(rng.randf_range(MARGIN, VILLAGE.x - MARGIN), VILLAGE.y - MARGIN - 20.0)
		2: p = Vector2(MARGIN + 20.0, rng.randf_range(MARGIN, VILLAGE.y - MARGIN))
		_: p = Vector2(VILLAGE.x - MARGIN - 20.0, rng.randf_range(MARGIN, VILLAGE.y - MARGIN))
	if player and p.distance_to(player.global_position) < 380.0:
		p = Vector2(VILLAGE.x - p.x, VILLAGE.y - p.y)
	return p

# ---------------------------------------------------------- arena graczy ---

const ARENA_P1 := Vector2(700.0, 780.0)
const ARENA_P2 := Vector2(1500.0, 780.0)
var _arena_started := false

func _arena_zone() -> Dictionary:
	return {
		"terrain": "fortress", "spawn": Vector2(1100, 780), "npcs": [], "giver": "", "waves": [],
		"intro_banner": ["ARENA GRACZY", "Pojedynek na zapisanych postaciach"],
		"outro_banner": ["KO", ""],
	}

func _player_name(p: Player) -> String:
	if p == null or not is_instance_valid(p):
		return "Gracz"
	var t := String(CharacterDB.get_data(p.character_id).get("title", "Gracz"))
	return t + (" (host)" if p == _net_players.get("p1") else " (gość)")

## Odliczanie, a potem walka do pierwszego KO.
func _begin_arena() -> void:
	await get_tree().create_timer(0.6).timeout
	if not is_instance_valid(self) or finished:
		return
	for p in _net_players.values():
		if is_instance_valid(p):
			p.can_act = false
	for n in ["3", "2", "1"]:
		_banner(n, "Przygotuj się")
		Audio.play("select", 1.0, -4.0)
		await get_tree().create_timer(0.9).timeout
		if not is_instance_valid(self) or finished:
			return
	_banner("WALKA!", "Pojedynek graczy")
	Audio.play("roar", 1.2, -4.0)
	for p in _net_players.values():
		if is_instance_valid(p):
			p.can_act = true
	_arena_started = true

func _arena_ko(loser: Player) -> void:
	if finished:
		return
	finished = true
	var winner: Player = null
	for p in _net_players.values():
		if is_instance_valid(p) and p != loser:
			winner = p
	var wname := _player_name(winner)
	var cause := String(loser.last_hit_desc) if loser != null and is_instance_valid(loser) else ""
	if _net_host:
		Net.broadcast_world_event("arena_ko", {"winner": wname, "cause": cause})
	_arena_ko_show(wname, cause)
	await get_tree().create_timer(4.0).timeout
	if _net_host:
		Net.broadcast_flow("menu")
		GameState.finish_run(false)
		Flow.goto("menu")

func _arena_ko_show(wname: String, cause: String = "") -> void:
	finished = true
	Audio.stop_music()
	_banner("KO!", "Wygrywa: %s%s" % [wname, ("  (ostatnie trafienie: %s)" % cause) if cause != "" else ""])
	Fx.flash(Color(1, 1, 0.9), 0.4, 0.5)

func _arena_ghost_ko() -> void:
	pass

func _build_arena_bar() -> void:
	var bar := UiArenaBar.new()
	bar.setup(_net_players.get("p1"), _net_players.get("p2"), _player_name(_net_players.get("p1")), _player_name(_net_players.get("p2")))
	hud.add_child(bar)

## Strefa zbudowana z konfiguracji „Własnych fal”.
func _custom_zone() -> Dictionary:
	var ws: Array = []
	for w in custom_cfg.get("waves", []):
		ws.append({"name": String(w.get("name", "")), "enemies": w.get("enemies", []), "elite": bool(w.get("elite", false)),
			"hp": float(w.get("hp", 1.0)), "dmg": float(w.get("dmg", 1.0)), "xp": float(w.get("xp", 1.0))})
	return {
		"terrain": String(custom_cfg.get("terrain", "village")), "spawn": Vector2(1100, 1080), "npcs": [], "giver": "",
		"waves": ws,
		"intro_banner": ["WŁASNE FALE", "%d fal do pokonania" % ws.size()],
		"outro_banner": ["ZWYCIĘSTWO", "Wszystkie fale pokonane"],
	}

func _custom_cleared() -> void:
	_cave_clock = false
	Audio.stop_music()
	var ob: Array = zone.get("outro_banner", ["ZWYCIĘSTWO", ""])
	_banner(String(ob[0]), String(ob[1]))
	Fx.flash(Color(1, 1, 0.9), 0.4, 0.5)
	var bonus := waves.size() * 40
	if bonus > 0:
		GameState.add_gold(bonus)
	GameState.toast.emit("Wszystkie fale pokonane! Premia: %d zł." % bonus, UiKit.GOOD)
	var portal := Interactable.new()
	portal.setup("portal", "Wróć do menu")
	_spot(portal, Vector2(1100, 900))
	portal.activated.connect(func(_w):
		GameState.rpg["custom"] = {}
		GameState.finish_run(true)
		Flow.goto("menu"))

func _on_wave_cleared() -> void:
	Audio.play("gate", 1.0, -6.0)
	if wave_i >= waves.size():
		if custom_mode:
			_custom_cleared()
		elif cave_mode:
			_spawn_cave_boss()
		else:
			_post_battle()
		return
	if not villain.is_empty() and int(villain.get("after_wave", -1)) == wave_i:
		_villain_cutscene()
		return
	if _roll_duel():
		_start_duel()
		return
	_next_wave_after_clear()

func _next_wave_after_clear() -> void:
	_set_step(wave_i + 1)
	_banner("FALA OCZYSZCZONA", "Nadchodzą kolejne…")
	await get_tree().create_timer(1.4).timeout
	if not finished:
		_spawn_wave()

func _villain_cutscene() -> void:
	_banner("HOLD", "Niebo ciemnieje…")
	var title := _hero_title()
	var who := String(villain.get("who", "Wróg"))
	var raw: Array = villain.get("lines", [])
	var lines: Array = []
	for ln in raw:
		var txt := String(ln)
		if txt.contains("%s"):
			txt = txt % title
		lines.append([who, txt])
	if lines.is_empty() or String(lines[lines.size() - 1][1]) != "Ostatnia fala! Zmiażdżcie ich!":
		lines.append([who, "Ostatnia fala! Zmiażdżcie ich!"])
	_open_dialog(lines, Color(0.85, 0.35, 0.3), func():
		if not finished:
			_spawn_wave())

func _post_battle() -> void:
	if march_mode:
		_march_prompt()
		return
	_post_battle_normal()

func _begin_march_stage() -> void:
	await get_tree().create_timer(0.9).timeout
	if not is_instance_valid(self) or finished:
		return
	var mr: Dictionary = GameState.rpg["march"]
	_banner("MARSZ", "%s — w drodze do: %s" % [PlaceDB.name_of(GameState.story_chapter()), PlaceDB.name_of(int(mr["target"]))])
	await get_tree().create_timer(1.7).timeout
	if not is_instance_valid(self) or finished:
		return
	_begin_defense()

## Po pokonaniu potworów na etapie marszu: iść dalej, zmienić cel czy anulować.
func _march_prompt() -> void:
	_set_step(waves.size() + 1)
	Audio.stop_music()
	var mr: Dictionary = GameState.rpg["march"]
	var route: Array = mr["route"]
	var i := int(mr["i"])
	var next_idx := int(route[i + 1]) if i + 1 < route.size() else int(mr["target"])
	var arriving := i + 1 >= route.size()
	_banner("DROGA WOLNA", PlaceDB.name_of(GameState.story_chapter()))
	Fx.flash(Color(1, 1, 0.9), 0.3, 0.4)
	await get_tree().create_timer(1.6).timeout
	if not is_instance_valid(self) or finished:
		return
	var opts: Array = [
		{"text": ("Dotrzyj do celu: %s" if arriving else "Maszeruj dalej: %s") % PlaceDB.name_of(next_idx)},
		{"text": "Zmień cel (mapa świata)"},
		{"text": "Anuluj marsz i zostań tutaj"},
	]
	_dialog_open = true
	var ui := UiChoice.new()
	ui.setup("Potwory pokonane. Co dalej?", opts, Color(1.0, 0.85, 0.3))
	ui.chosen.connect(func(k: int): _march_choice.call_deferred(k, next_idx, arriving))
	ui.on_close.connect(func(): _dialog_open = false)
	Flow.open_dialog(ui)

func _march_choice(k: int, next_idx: int, arriving: bool) -> void:
	match k:
		0:
			var mr: Dictionary = GameState.rpg["march"]
			if arriving:
				GameState.rpg.erase("march")
			else:
				mr["i"] = int(mr["i"]) + 1
			GameState.replay_chapter(next_idx)
			Flow.goto("game", {"stage": 0})
		1:
			GameState.rpg.erase("march")
			await get_tree().process_frame
			Flow.open_travel_map()
		2:
			GameState.rpg.erase("march")
			GameState.toast.emit("Marsz anulowany.", UiKit.ACCENT2)
			march_mode = false
			_post_battle_normal()

func _post_battle_normal() -> void:
	if stairs_mode:
		_set_step(waves.size() + 1)
		Audio.stop_music()
		var ob2: Array = zone.get("outro_banner", ["SCHODY WOLNE", ""])
		_banner(String(ob2[0]), String(ob2[1]))
		Fx.flash(Color(1, 1, 0.9), 0.4, 0.5)
		await get_tree().create_timer(1.4).timeout
		if is_instance_valid(self) and not finished:
			_spawn_stairs()
		return
	_set_step(waves.size() + 1)
	_reveal_post_objectives()
	Audio.stop_music()
	var ob: Array = zone.get("outro_banner", ["ŚWIT", "Udało się"])
	_banner(String(ob[0]), String(ob[1]))
	Fx.flash(Color(1, 1, 0.9), 0.4, 0.5)
	await get_tree().create_timer(1.6).timeout
	if is_instance_valid(self) and not finished:
		var giver_name := String(NpcDB.get_data(giver).get("name", "sojusznik"))
		GameState.toast.emit("Zadanie: %s czeka na rozmowę" % giver_name, UiKit.ACCENT)

func _finish_story() -> void:
	if _reward_given or finished:
		return
	_reward_given = true
	if _net_host:
		Net.broadcast_world_event("rewards", {"quest": quest_id})
	var quest := QuestDB.get_data(quest_id)
	var is_act2 := int(quest.get("act", 1)) == 2
	var reward: Dictionary = quest.get("reward", {})
	var first_clear := not GameState.story_done(quest_id)
	if not first_clear:
		reward = {}
	GameState.add_gold(int(reward.get("gold", 0)))
	GameState.add_xp(int(reward.get("xp", 0)))
	var items: Dictionary = reward.get("items", {})
	for it in items:
		GameState.add_item(String(it), int(items[it]))
	if is_act2 and quest_id == Act2DB.FINAL and Act2DB.rep() >= 3 and first_clear:
		GameState.add_gold(500)
		GameState.add_item("sztabka_kurczalium", 1)
		GameState.toast.emit("Wdzięczność wiosek: dodatkowa nagroda — 500 złota i 2 sztabki kurczalium!", UiKit.ACCENT)
	if first_clear and ChapterExtras.has(quest_id):
		var fb := ChapterExtras.final_bonus(quest_id)
		if int(fb["gold"]) > 0:
			GameState.add_gold(int(fb["gold"]))
		for fit in fb["items"]:
			GameState.add_item(String(fit), int(fb["items"][fit]))
		if int(fb["gold"]) > 0 or not (fb["items"] as Dictionary).is_empty():
			GameState.toast.emit("Wdzięczność za twoje wybory: +%d złota%s" % [int(fb["gold"]), "" if (fb["items"] as Dictionary).is_empty() else " i przedmioty"], UiKit.ACCENT)
	GameState.set_story_flag(quest_id + "_done")
	GameState.complete_quest(quest_id)
	GameState.story()["last_quest"] = quest_id
	var next_chapter := 0
	var next_quest := ""
	if is_act2:
		Act2DB.liberate(quest_id)
		next_chapter = mini(QuestDB.act_start(2) + Act2DB.liberated().size(), QuestDB.count())
		if Act2DB.all_done():
			# pomiń rozdziały, które gracz już ukończył (zapisy sprzed Aktu II)
			var done_ids: Array = GameState.story().get("done", [])
			while next_chapter < QuestDB.count() and String(QuestDB.chapter(next_chapter).get("id", "")) in done_ids:
				next_chapter += 1
			if next_chapter < QuestDB.count():
				next_quest = String(QuestDB.chapter(next_chapter).get("id", ""))
	else:
		next_chapter = mini(GameState.story_chapter() + 1, QuestDB.count())
		if next_chapter < QuestDB.count() and QuestDB.act_of(next_chapter) != 2:
			next_quest = String(QuestDB.chapter(next_chapter).get("id", ""))
	GameState.set_story(next_chapter, next_quest, 0)
	GameState.save_game()
	var label := String(quest.get("label", "Rozdział"))
	GameState.toast.emit("%s ukończony! +%d złota, +%d XP" % [label, int(reward.get("gold", 0)), int(reward.get("xp", 0))], UiKit.GOOD)
	if stairs_mode:
		# schody prowadzą od razu na kolejne piętro — bez ekranu statystyk
		finished = true
		Audio.play("gate", 0.9, -4.0)
		Fx.flash(Color(1, 0.95, 0.8), 0.4, 0.5)
		await get_tree().create_timer(0.6).timeout
		GameState.commit_backpack()
		Flow.goto("game", {"stage": int(GameState.run.get("stage_index", 0))})
		return
	var ob: Array = zone.get("outro_banner", ["ROZDZIAŁ UKOŃCZONY", ""])
	_banner(String(ob[0]), String(ob[1]))
	Fx.flash(Color(1, 0.95, 0.8), 0.5, 0.6)
	Audio.play("levelup", 1.0, -2.0)
	await get_tree().create_timer(2.2).timeout
	if is_instance_valid(self) and UiVignette.EPILOGUE.has(quest_id) and not _net_client:
		var seq = UiVignette.EPILOGUE[quest_id]
		for sid in (seq if seq is Array else [seq]):
			if not is_instance_valid(self):
				return
			await _vignette_async(String(sid))
	if is_instance_valid(self):
		var cine := _act_cinematic(quest_id)
		if not cine.is_empty():
			await _dialog_async(cine, Color(0.85, 0.4, 0.9))
		finished = true
		if player and is_instance_valid(player):
			player.victory()
		stage_cleared.emit()

# ---------------------------------------------------------------- pomocne ---

func enemies_left() -> int:
	return _alive_enemies().size()

func waves_left() -> int:
	return maxi(0, waves.size() - wave_i)

func _banner(title: String, sub: String) -> void:
	var v := UiBanner.new()
	v.setup(title, sub)
	add_child(v)

# ------------------------------------------------- skrzynie, dźwignie, jaskinie ---

var cave_mode := false
var stairs_mode := false
var march_mode := false
var arena_mode := false
var challenge_mode := false
var _ch_round := 0
var custom_mode := false
var custom_cfg: Dictionary = {}
var cave_id := ""
var _entrance: Interactable = null
var _levers: Array = []
var _cave_t := 0.0
var _cave_clock := false

func _set_step(n: int) -> void:
	if not cave_mode:
		GameState.set_story_step(n)

func _spot(i: Interactable, pos: Vector2) -> Interactable:
	i.position = pos
	entities.add_child(i)
	return i

func _build_secrets() -> void:
	if cave_mode:
		return
	for c in SecretDB.chests_for(quest_id):
		var uid := "%s:%s" % [quest_id, String(c["id"])]
		var ch := Interactable.new()
		ch.setup("chest", "Otwórz skrzynię", uid, bool(c.get("hidden", false)))
		ch.done = SecretDB.chest_opened(uid)
		_spot(ch, c["pos"])
		var cd: Dictionary = c
		ch.activated.connect(func(_w): _open_chest(ch, cd))
	for camp_id in SpecialDB.camps_in(quest_id):
		_build_camp_entrance(String(camp_id))
	for mine_id in MinesDB.mines_in(quest_id):
		_build_mine_entrance(String(mine_id))
	var cave := SecretDB.cave_for(quest_id)
	if cave.is_empty() or (SecretDB.cave_done(String(cave["id"])) and not bool(cave.get("repeatable", false))):
		return
	var sgn := Interactable.new()
	sgn.setup("sign", "Przeczytaj")
	_spot(sgn, Vector2(clampf(spawn.x + 150.0, 120.0, VILLAGE.x - 120.0), clampf(spawn.y - 90.0, 120.0, VILLAGE.y - 120.0)))
	sgn.activated.connect(func(_w):
		_open_dialog([["", String(cave["hint"])]], UiKit.ACCENT2))
	var pulled: Array = SecretDB.levers_pulled(quest_id)
	var lev_pos: Array = cave["levers"]
	for i in lev_pos.size():
		var lv := Interactable.new()
		lv.setup("lever", "Pociągnij dźwignię")
		lv.uid = "lv:%s:%d" % [quest_id, i]
		lv.done = i in pulled or GameState.story_flag(lv.uid)
		_spot(lv, lev_pos[i])
		_levers.append(lv)
		var idx := i
		lv.activated.connect(func(_w): _pull_lever(lv, idx, cave))
	_entrance = Interactable.new()
	_entrance.setup("entrance", "Zejdź do jaskini")
	_spot(_entrance, cave["entrance"])
	_entrance.visible = _levers_pulled_count(cave) >= lev_pos.size()
	_entrance.activated.connect(func(_w): _enter_cave(cave))

## Ścieżka do obozu niewolników (zadanie poboczne): wejście jest zawsze, ale wpuszcza dopiero po rozmowie ze zleceniodawcą.
func _build_camp_entrance(camp_id: String) -> void:
	if SecretDB.cave_done(camp_id) or Net.has_peer():
		return
	var cv := SecretDB.cave_by_id(camp_id)
	var en := Interactable.new()
	en.setup("entrance", "Ścieżka do obozu niewolników")
	_spot(en, cv["entrance"])
	en.activated.connect(func(_w):
		if not GameState.story_flag(SpecialDB.accept_flag(camp_id)):
			_open_dialog([["", String(cv["hint"])], ["", "Nie wiesz jeszcze, kogo tam szukać. Porozmawiaj najpierw z: %s." % SpecialDB.giver_name(camp_id)]], UiKit.ACCENT2)
			return
		_enter_cave(cv))

func _open_chest(ch: Interactable, c: Dictionary) -> void:
	if ch.done:
		return
	if SecretDB.chest_locked(c) and not ch.has_meta("unlocked"):
		var pick := SecretDB.best_pick(GameState.item_count)
		if pick == "":
			GameState.toast.emit("Skrzynia jest zamknięta na zamek. Potrzebny wytrych — kupisz go w sklepie.", UiKit.BAD)
			return
		var ui := UiPuzzle.new()
		ui.setup("lockpick", hash(ch.uid), SecretDB.PICKS[pick])
		_dialog_open = true
		ui.finished.connect(func(ok: bool):
			if ok:
				ch.set_meta("unlocked", true)
			if SecretDB.pick_breaks(pick, ok):
				GameState.remove_item(pick, 1)
				GameState.toast.emit("%s się złamał." % String(ItemDB.get_data(pick).get("name", "Wytrych")), UiKit.BAD))
		ui.on_close.connect(func():
			_dialog_open = false
			await get_tree().process_frame   # Flow najpierw domyka nakładkę zagadki
			if ch.has_meta("unlocked"):
				_open_chest(ch, c))
		Flow.open_dialog(ui)
		return
	ch.done = true
	SecretDB.mark_chest(ch.uid)
	var lines := SecretDB.grant({"items": c.get("loot", {}), "gold": int(c.get("gold", 0)), "xp": int(c.get("xp", 0))})
	Audio.play("coin", 1.0, -2.0)
	Fx.burst(ch.global_position + Vector2(0, -30), Color(1.0, 0.9, 0.5), 18, 260.0, 3.0, 0.5)
	GameState.toast.emit("Skrzynia: " + ", ".join(lines), UiKit.GOOD)

func _pull_lever(lv: Interactable, idx: int, cave: Dictionary) -> void:
	if lv.done:
		return
	lv.done = true
	GameState.set_story_flag("lv:%s:%d" % [quest_id, idx])
	SecretDB.pull_lever(quest_id, idx)
	Audio.play("gate", 0.9, -2.0)
	Fx.shake(4.0, 0.2)
	var pulled := _levers_pulled_count(cave)
	var total := (cave["levers"] as Array).size()
	if pulled >= total:
		_entrance.visible = true
		_banner("COŚ ZAZGRZYTAŁO…", "Odsłonięto wejście do: %s" % String(cave["name"]))
		Fx.flash(Color(0.7, 0.5, 1.0), 0.3, 0.5)
		Fx.shake(9.0, 0.6)
		Audio.play("roar", 0.6, -4.0)
	else:
		GameState.toast.emit("Dźwignia pociągnięta (%d / %d)" % [pulled, total], UiKit.ACCENT2)

func _enter_cave(cave: Dictionary) -> void:
	if _dialog_open or finished:
		return
	if _net_client:
		Net.send_world_event("enter_cave")
		return
	GameState.rpg["cave"] = String(cave["id"])
	GameState.rpg["cave_state"] = "fight"
	GameState.save_game()
	Audio.play("gate", 0.8, -2.0)
	Flow.goto("game", {"stage": int(GameState.run.get("stage_index", 0))})

func _leave_cave() -> void:
	if _net_client:
		Net.send_world_event("leave_cave")
		return
	GameState.rpg["cave"] = ""
	GameState.rpg["cave_state"] = ""
	Flow.goto("game", {"stage": int(GameState.run.get("stage_index", 0))})

func _begin_cave() -> void:
	await get_tree().create_timer(0.9).timeout
	if not is_instance_valid(self) or finished:
		return
	var banner: Array = zone.get("intro_banner", ["", ""])
	_banner(String(banner[0]), String(banner[1]))
	if not custom_mode and not zone.has("camp"):
		GameState.toast.emit("Wyzwanie: oczyść jaskinię w 120 s, by dostać dodatkową nagrodę.", UiKit.ACCENT)
	await get_tree().create_timer(1.7).timeout
	if not is_instance_valid(self) or finished:
		return
	_cave_clock = true
	_waves_started = true
	if custom_mode:
		_spawn_wave()
	else:
		_spawn_cave_ambush()
		_build_prisoners()
		_build_camp()
		_build_mine()
		_build_shafts()

## Więźniowie w celach (lochy zamku Kruka): klatki do otwarcia, z nagrodą i podziękowaniem.
func _build_prisoners() -> void:
	for p in zone.get("prisoners", []):
		var pr: Dictionary = p
		var uid := "pris:" + String(pr["id"])
		var it := Interactable.new()
		it.setup("cage", String(pr.get("label", "Uwolnij więźnia")), uid)
		it.done = GameState.story_flag(uid)
		it.accent = Color(0.7, 0.9, 1.0)
		_spot(it, pr["pos"])
		it.activated.connect(func(_w): _free_prisoner(pr, it))

## Wejście do kopalni wroga (zob. MinesDB): wnętrze z patrolami, górnikami w klatkach i trzema urządzeniami do zalania.
func _build_mine_entrance(mid: String) -> void:
	if SecretDB.cave_done(mid) or Net.has_peer():
		return
	var cv := SecretDB.cave_by_id(mid)
	var en := Interactable.new()
	en.setup("entrance", "Wejdź: " + String(cv["name"]))
	_spot(en, cv["entrance"])
	en.activated.connect(func(_w): _enter_cave(cv))

## Wnętrze kopalni: wystrój, trzy urządzenia z zagadkami; po trzecim zalewa kopalnię (historyjka) i odpala wyjście.
## Szyby (pary): wejście do jednego wyprowadza z drugiego; omijają strażników i skracają drogę.
func _build_shafts() -> void:
	for pr in zone.get("shafts", []):
		var a: Vector2 = pr[0]
		var b: Vector2 = pr[1]
		for pair in [[a, b], [b, a]]:
			var from: Vector2 = pair[0]
			var to: Vector2 = pair[1]
			var sh := Interactable.new()
			sh.setup("shaft", "Zejdź szybem")
			_spot(sh, from)
			sh.activated.connect(func(_w):
				if player == null or not is_instance_valid(player):
					return
				Audio.play("gate", 1.2, -6.0)
				Fx.burst(from + Vector2(0, -24), Color(0.4, 0.35, 0.3), 14, 160.0, 3.0, 0.4)
				player.global_position = to + Vector2(0, 80)   # tuż obok szybu, żeby nie zjechać z powrotem
				GameState.toast.emit("Zjeżdżasz szybem i wychodzisz na drugim końcu kopalni.", UiKit.ACCENT))

func _build_mine() -> void:
	var mine: Dictionary = zone.get("mine", {})
	if mine.is_empty():
		var camp: Dictionary = zone.get("camp", {})
		if not camp.is_empty():
			var cd := MineDecor.new()
			cd.setup(String(camp["id"]))
			cd.z_index = -3
			entities.add_child(cd)
		return
	var deco := MineDecor.new()
	deco.setup(String(mine["id"]))
	deco.z_index = -3
	entities.add_child(deco)
	var steps: Array = mine["steps"]
	for i in steps.size():
		var st: Dictionary = steps[i]
		var uid := "mine:%s:%d" % [String(mine["id"]), i]
		var it := Interactable.new()
		it.setup(String(st["kind"]), String(st["label"]), uid)
		it.done = GameState.story_flag(uid)
		it.accent = Color(0.7, 0.9, 1.0)
		_spot(it, st["pos"])
		var idx := i
		it.activated.connect(func(_w): _mine_step(mine, idx, it))

func _mine_step(mine: Dictionary, idx: int, it: Interactable) -> void:
	if it.done or _dialog_open:
		return
	var st: Dictionary = (mine["steps"] as Array)[idx]
	var ui := UiPuzzle.new()
	ui.setup(String(st["puzzle"]), hash(it.uid))
	ui.pay = _pay_puzzle_hint
	_dialog_open = true
	var solved := [false]
	ui.finished.connect(func(ok: bool): solved[0] = ok)
	ui.on_close.connect(func():
		_dialog_open = false
		await get_tree().process_frame   # Flow najpierw domyka nakładkę zagadki
		if bool(solved[0]):
			_mine_step_done(mine, idx, it)
		else:
			GameState.toast.emit("Nie udało się — spróbuj jeszcze raz.", UiKit.BAD))
	Flow.open_dialog(ui)

func _mine_step_done(mine: Dictionary, idx: int, it: Interactable) -> void:
	it.done = true
	GameState.set_story_flag(it.uid)
	GameState.set_story_flag(ChapterExtras.flag(String(mine["zone"]), String(mine["id"]), idx))
	Audio.play("hit_heavy", 0.8, -4.0)
	Fx.shake(5.0, 0.2)
	var steps: Array = mine["steps"]
	var done_n := 0
	for i in steps.size():
		if GameState.story_flag("mine:%s:%d" % [String(mine["id"]), i]):
			done_n += 1
	GameState.toast.emit("%s (%d / %d)" % [String((steps[idx] as Dictionary)["msg"]), done_n, steps.size()], UiKit.GOOD)
	if done_n < steps.size():
		GameState.save_game()
		return
	var rflag := "r:mine:" + String(mine["id"])
	if not GameState.story_flag(rflag):
		GameState.set_story_flag(rflag)
		var rw: Dictionary = mine["reward"]
		var lines := SecretDB.grant({"items": rw.get("items", {}), "gold": int(rw.get("gold", 0)), "xp": int(rw.get("xp", 0))})
		GameState.toast.emit("Kopalnia zalana! — " + ", ".join(lines), UiKit.ACCENT)
		Audio.play("levelup", 1.3, -6.0)
	SecretDB.mark_cave(String(mine["id"]))
	_camp_off = true
	_refresh_camp_guards()
	_spawn_camp_exit()
	if _camp_exit != null and is_instance_valid(_camp_exit):
		_camp_exit.label_text = "Wróć na powierzchnię"
	GameState.save_game()
	_scene_later(String(mine["scene"]))

func _free_prisoner(pr: Dictionary, it: Interactable) -> void:
	if it.done or _dialog_open:
		return
	it.done = true
	GameState.set_story_flag(it.uid)
	if zone.has("camp") and not zone.has("mine"):
		_camp_freed()
	var knows := not bool(pr.get("tosia", false)) or GameState.story_flag(SpecialDB.TOSIA_FLAG)
	var rw: Dictionary = pr["reward"] if knows else pr.get("reward_plain", pr["reward"])
	var thanks: Array = pr["thanks"] if knows else pr.get("thanks_plain", pr["thanks"])
	Audio.play("confirm", 1.2, -2.0)
	Fx.burst(it.global_position + Vector2(0, -24), Color(0.8, 0.95, 1.0), 14, 220.0, 3.0, 0.4)
	_open_dialog(thanks, UiKit.ACCENT2, func():
		var lines := SecretDB.grant({"items": rw.get("items", {}), "gold": int(rw.get("gold", 0)), "xp": int(rw.get("xp", 0))})
		GameState.toast.emit("Uwolniono: %s — %s" % [String(pr.get("name", "więzień")), ", ".join(lines)], UiKit.GOOD)
		Audio.play("levelup", 1.3, -6.0)
		GameState.save_game())

## Obóz niewolników: strażnicy ze stożkami wzroku (zauważenie cofa na start); znikają po pokonaniu naczelnika albo uwolnieniu jeńca.
var _camp_guards: Array = []
var _camp_off := false

func _build_camp() -> void:
	var camp: Dictionary = zone.get("camp", {})
	if camp.is_empty():
		return
	for g in camp["guards"]:
		var sg := StealthGuard.new()
		sg.setup(g["path"], float(g.get("range", 250.0)))
		entities.add_child(sg)
		sg.spotted.connect(_camp_spotted)
		_camp_guards.append(sg)
	_open_dialog(camp.get("intro", []), UiKit.ACCENT2)
	_spawn_camp_exit()

## Wyjście z obozu na starcie jest od początku: uciec można bez zabijania strażników.
var _camp_exit: Interactable

func _spawn_camp_exit() -> void:
	if _camp_exit != null and is_instance_valid(_camp_exit):
		return
	_camp_exit = Interactable.new()
	_camp_exit.setup("portal", "Opuść obóz")
	_spot(_camp_exit, (zone["camp"] as Dictionary).get("start", spawn) + Vector2(0, -90))
	_camp_exit.activated.connect(func(_w): _leave_cave())

func _refresh_camp_guards() -> void:
	for sg in _camp_guards:
		if is_instance_valid(sg):
			sg.active = not _camp_off
			sg.visible = not _camp_off

func _camp_spotted() -> void:
	if _camp_off or player == null or not is_instance_valid(player):
		return
	# alarm: strażnicy zrzucają stożki wzroku i ruszają do ataku (cała straż obozu się budzi)
	Audio.play("hit_heavy", 0.7, -4.0)
	Fx.shake(6.0, 0.3)
	_camp_off = true
	_refresh_camp_guards()
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.get("dormant") == true:
			e.dormant = false
	GameState.toast.emit("Alarm! Strażnicy cię zauważyli i ruszają do ataku!", UiKit.BAD)

func _camp_disarm() -> void:
	if _camp_off:
		return
	_camp_off = true
	_refresh_camp_guards()
	GameState.toast.emit("Naczelnik padł — reszta strażników rozbiega się w popłochu.", UiKit.GOOD)

## Jeniec uwolniony: strażnicy znikają, obóz uznany za rozbity, a na starcie pojawia się wyjście.
func _camp_freed() -> void:
	_camp_off = true
	_refresh_camp_guards()
	SecretDB.mark_cave(cave_id)
	_spawn_camp_exit()
	if _camp_exit != null and is_instance_valid(_camp_exit):
		_camp_exit.label_text = "Wróć na pustkowie"

## Sekretna jaskinia nie ma fal: wszystkie potwory czekają w mroku i atakują dopiero, gdy podejdziesz.
func _spawn_cave_ambush() -> void:
	var packs: Array = []
	for w in waves:
		for entry in w["enemies"]:
			if not String(entry[0]).begins_with("BOSS:"):
				packs.append([entry, w])
	var centers := SecretDB.ambush_centers(packs.size(), VILLAGE, MARGIN, zone.get("spawn", Vector2(1100, 1280)), rng)
	for n in packs.size():
		var entry: Array = packs[n][0]
		var wave: Dictionary = packs[n][1]
		for i in int(entry[1]):
			var e: Enemy = (ENEMY_SCENE as PackedScene).instantiate() as Enemy
			if entry.size() > 3:
				e.skin = String(entry[3])
			e.setup(String(entry[0]), false, bool(wave.get("elite", false)) or (entry.size() > 2 and bool(entry[2])))
			if wave.has("hp"):
				e.apply_mods(float(wave["hp"]), float(wave.get("dmg", 1.0)), float(wave.get("xp", 1.0)))
			e.net_id = "e%d" % _net_enemy_seq
			_net_enemy_seq += 1
			e.dormant = true
			e.aggro = minf(e.aggro, 460.0)
			if bool(wave.get("elite", false)) and zone.has("camp"):
				e.died.connect(func(_x): _camp_disarm())
			entities.add_child(e)
			e.global_position = (centers[n] as Vector2) + Vector2(rng.randf_range(-110.0, 110.0), rng.randf_range(-90.0, 90.0))
			e.set_bounds_rect(MARGIN, VILLAGE.x - MARGIN, MARGIN, VILLAGE.y - MARGIN)
	wave_i = waves.size()
	_set_step(wave_i)
	wave_active = true
	GameState.toast.emit("Potwory czekają w mroku — atakują, gdy podejdziesz zbyt blisko.", UiKit.ACCENT)

## Na końcu jaskini czeka boss, który dzierży legendarną broń z nagrody.
func _spawn_cave_boss() -> void:
	var cave := SecretDB.cave_by_id(cave_id)
	var bid := CaveBossDB.id_for(cave_id)
	if cave.is_empty() or not BossDB.has(bid):
		_cave_cleared()
		return
	wave_active = false
	Audio.play("roar", 0.7, -2.0)
	_banner("STRAŻNIK JASKINI", String(BossDB.get_data(bid).get("title", "")))
	await get_tree().create_timer(1.6).timeout
	if finished:
		return
	_spawn_boss(bid)
	var b := _boss_node
	if b == null or not is_instance_valid(b):
		_cave_cleared()
		return
	var trophy := String(BossDB.get_data(bid).get("trophy", ""))
	if trophy != "":
		b.visual.set_gear(CosmeticDB.gear_visual({"weapon": trophy}, {}))
	b.died.connect(func(_e): _cave_cleared())

func _cave_cleared() -> void:
	_cave_clock = false
	GameState.rpg["cave_state"] = "loot"
	Audio.stop_music()
	var ob: Array = zone.get("outro_banner", ["JASKINIA OCZYSZCZONA", ""])
	_banner(String(ob[0]), String(ob[1]))
	Fx.flash(Color(1, 1, 0.9), 0.4, 0.5)
	var bonus := _cave_t <= 120.0
	if _net_host:
		Net.broadcast_world_event("cave_cleared", {"bonus": bonus})
	_spawn_cave_chest(bonus)

func _spawn_cave_chest(bonus: bool) -> void:
	var cave := SecretDB.cave_by_id(cave_id)
	var chest := Interactable.new()
	chest.setup("chest", "Skarbiec jaskini")
	_spot(chest, Vector2(1100, 760))
	chest.activated.connect(func(_w):
		if chest.done:
			return
		chest.done = true
		var reward: Dictionary = (cave["reward"] as Dictionary).duplicate(true)
		if String(cave.get("pet", "")) != "":
			reward["pet"] = String(cave["pet"])
		if bonus:
			var bi: Dictionary = reward.get("items", {})
			bi["krysztal_cienia"] = int(bi.get("krysztal_cienia", 0)) + 1
			reward["items"] = bi
			reward["gold"] = int(reward.get("gold", 0)) + 100
		var already := SecretDB.cave_done(cave_id)
		var lines: Array = []
		if not already:
			lines = SecretDB.grant(reward)
			SecretDB.mark_cave(cave_id)
		Audio.play("levelup", 1.0, -2.0)
		Fx.burst(chest.global_position + Vector2(0, -30), Color(1.0, 0.9, 0.5), 28, 340.0, 3.5, 0.6)
		GameState.toast.emit(("Nagroda jaskini: " + ", ".join(lines)) if not lines.is_empty() else "Skarbiec jest pusty.", UiKit.GOOD)
		if bonus and not already:
			GameState.toast.emit("Wyzwanie czasowe ukończone: bonusowa nagroda!", UiKit.ACCENT)
		GameState.rpg["cave_state"] = "exit"
		var portal := Interactable.new()
		portal.setup("portal", "Wróć na powierzchnię")
		_spot(portal, Vector2(1100, 1230))
		portal.activated.connect(func(_w2): _leave_cave()))

# ----------------------------------------------------------------------- bossowie ---

const BOSS_SCENE := preload("res://scenes/boss_big.tscn")
var _arena: BossArena = null
var _boss_node: BossBig = null

func _spawn_boss(bid: String, wave: Dictionary = {}) -> void:
	if not BossDB.has(bid):
		return
	var b := (BOSS_SCENE as PackedScene).instantiate() as BossBig
	b.setup_boss(bid)
	if wave.has("hp"):
		b.apply_mods(float(wave["hp"]), float(wave.get("dmg", 1.0)), float(wave.get("xp", 1.0)))
	b.net_id = "e%d" % _net_enemy_seq
	_net_enemy_seq += 1
	entities.add_child(b)
	b.global_position = BossDB.ARENA_CENTER + Vector2(0.0, -60.0)
	b.arena_center = BossDB.ARENA_CENTER
	b.arena_radius = BossDB.ARENA_RADIUS
	b.set_bounds_rect(MARGIN, VILLAGE.x - MARGIN, MARGIN, VILLAGE.y - MARGIN)
	_boss_node = b
	_arena = BossArena.new()
	_arena.center = BossDB.ARENA_CENTER
	_arena.radius = BossDB.ARENA_RADIUS
	add_child(_arena)
	_track_boss(b)
	# gracze wchodzą na arenę
	var inside := BossDB.ARENA_CENTER + Vector2(0.0, BossDB.ARENA_RADIUS * 0.62)
	for p in get_tree().get_nodes_in_group("player"):
		if p is Node2D and (p as Node2D).global_position.distance_to(BossDB.ARENA_CENTER) > BossDB.ARENA_RADIUS - 100.0:
			var tw := create_tween()
			tw.tween_property(p, "global_position", inside + Vector2(randf_range(-60.0, 60.0), 0.0), 0.5)
	if camera:
		var tz := create_tween()
		tz.tween_property(camera, "zoom", Vector2(0.78, 0.78) * GameState.view_zoom(), 1.2)
	var bd := BossDB.get_data(bid)
	if bid == "czarny_kruk_odrodzony" and Act2DB.rep() >= 3:
		b.max_health *= 0.9
		b.health = b.max_health
		GameState.toast.emit("Wioski wspierają cię w walce: Czarny Kruk jest osłabiony (−10%% zdrowia).", UiKit.ACCENT)
	_banner(String(bd.get("name", "BOSS")).to_upper(), String(bd.get("title", "")))
	b.phase_changed.connect(func(_i: int, label: String): _banner(label, String(bd.get("name", ""))))
	b.died.connect(_on_boss_died)
	b.start_intro()

func _on_boss_died(_e: Enemy) -> void:
	if _arena and is_instance_valid(_arena):
		_arena.lower()
	_arena = null
	if camera:
		var tz := create_tween()
		tz.tween_property(camera, "zoom", Vector2.ONE * GameState.view_zoom(), 1.0)
	Audio.play_music("victory")

# ------------------------------------------------ rozbudowa rozdziałów (cele) ---

var _post_nodes: Array = []

func _build_extras() -> void:
	if cave_mode or march_mode or not ChapterExtras.has(quest_id):
		return
	for id in ChapterExtras.npc_ids(quest_id):
		_npc(String(id))
	for obj in ChapterExtras.objectives(quest_id):
		var o: Dictionary = obj
		var post := String(o.get("phase", "pre")) == "post"
		match String(o.get("type", "")):
			"collect", "free", "sabotage":
				var positions: Array = o.get("positions", [])
				for i in positions.size():
					var it := Interactable.new()
					it.setup(MinesDB.step_value(o, "kinds", "kind", i, "document"), MinesDB.step_value(o, "labels", "label", i, "Użyj"), ChapterExtras.flag(quest_id, String(o["id"]), i))
					it.done = GameState.story_flag(it.uid)
					it.accent = Color(0.7, 0.9, 1.0)
					_spot(it, positions[i])
					if post:
						it.visible = false
						_post_nodes.append(it)
					var idx := i
					it.activated.connect(func(_w): _obj_activate(o, idx, it))
			"elite":
				if not ChapterExtras.is_done(quest_id, o) and not _net_client:
					var e := (ENEMY_SCENE as PackedScene).instantiate() as Enemy
					e.setup(String(o.get("enemy", "kruk")), false, true)
					e.aggro = 420.0
					e.set_meta("obj_elite", true)
					entities.add_child(e)
					e.global_position = o.get("pos", Vector2(1100, 1000))
					e.set_bounds_rect(MARGIN, VILLAGE.x - MARGIN, MARGIN, VILLAGE.y - MARGIN)
					e.died.connect(func(_x): _obj_complete_flag(o, 0))
			"heist":
				_build_heist(o)
	_reveal_post_objectives()

## Włamanie (skradanka): strażnicy ze stożkiem wzroku, lutnia do zwędzenia; zauważenie cofa na start.
var _heist_guards: Array = []

func _build_heist(o: Dictionary) -> void:
	if _net_client or ChapterExtras.is_done(quest_id, o):
		return
	var item := ChapterExtras.heist_item(o)
	var taken := GameState.story_flag("heist_taken:" + quest_id) or GameState.item_count(item) > 0
	_heist_obj = o
	for g in o.get("guards", []):
		var sg := StealthGuard.new()
		sg.setup(g["path"], float(g.get("range", 250.0)))
		entities.add_child(sg)
		sg.spotted.connect(func(): _heist_spotted(o))
		_heist_guards.append(sg)
	_refresh_heist_guards()
	var it := Interactable.new()
	it.setup("document", String(o.get("label", "Zwędź")), "heist:" + quest_id)
	it.done = taken
	it.accent = Color(1.0, 0.7, 0.35)
	_spot(it, o["pos"])
	it.activated.connect(func(_w):
		it.done = true
		GameState.set_story_flag("heist_taken:" + quest_id)
		GameState.add_item(item, 1)
		Audio.play("confirm", 1.2, -2.0)
		_refresh_heist_guards()
		GameState.toast.emit(String(o.get("take_msg", "Zwędzono lutnię! Wymknij się i zanieś ją bardowi.")), UiKit.GOOD)
		GameState.save_game())
	if not taken and not GameState.story_flag("heist_intro:" + quest_id):
		GameState.set_story_flag("heist_intro:" + quest_id)
		_open_dialog(o.get("intro", []), UiKit.ACCENT2)

var _heist_obj: Dictionary = {}

## Strażnicy znikają, gdy gracz ma już łup albo pokonał wroga-naczelnika z pola `disarm`.
func _refresh_heist_guards() -> void:
	if _heist_obj.is_empty():
		return
	var off := GameState.story_flag("heist_taken:" + quest_id) or GameState.item_count(ChapterExtras.heist_item(_heist_obj)) > 0 \
		or ChapterExtras.heist_disarmed(quest_id, _heist_obj)
	for sg in _heist_guards:
		if is_instance_valid(sg):
			sg.active = not off
			sg.visible = not off

func _heist_spotted(o: Dictionary) -> void:
	if player == null or not is_instance_valid(player) or GameState.item_count(ChapterExtras.heist_item(o)) > 0:
		return
	Audio.play("hit_heavy", 0.7, -4.0)
	Fx.shake(6.0, 0.3)
	player.global_position = o.get("start", spawn)
	for sg in _heist_guards:
		if is_instance_valid(sg):
			sg.reset()
	GameState.toast.emit("Zauważono cię! Strażnicy odprowadzili cię na start.", UiKit.BAD)

## NPC-odbiorca (bard z lutnią, ojciec z uwolnionym dzieckiem): dialog z podziękowaniem i nagroda za cel.
func _heist_turn_in(npc: String) -> bool:
	for obj in ChapterExtras.objectives(quest_id):
		if String(obj.get("type", "")) != "heist" or ChapterExtras.is_done(quest_id, obj) or ChapterExtras.heist_npc(obj) != npc:
			continue
		var item := ChapterExtras.heist_item(obj)
		if GameState.item_count(item) <= 0:
			return false
		GameState.remove_item(item, 1)
		var accent: Color = NpcDB.get_data(npc).get("accent", UiKit.ACCENT)
		if UiVignette.ALL.has(String(obj.get("scene", ""))):
			_vignette_then(String(obj["scene"]), func(): _obj_complete_flag(obj, 0))
		else:
			_open_dialog(obj.get("thanks", []), accent, func(): _obj_complete_flag(obj, 0))
		return true
	return false

func _reveal_post_objectives() -> void:
	if GameState.story_step() > waves.size():
		for n in _post_nodes:
			if is_instance_valid(n):
				n.visible = true

## Podpowiedź do zagadki za złoto (UiPuzzle.HINT_COST).
func _pay_puzzle_hint() -> bool:
	if GameState.gold() < UiPuzzle.HINT_COST:
		GameState.toast.emit("Za mało złota na podpowiedź (%d zł)." % UiPuzzle.HINT_COST, UiKit.BAD)
		return false
	GameState.add_gold(-UiPuzzle.HINT_COST)
	return true

func _obj_activate(o: Dictionary, idx: int, it: Interactable) -> void:
	if it.done:
		return
	var pz := MinesDB.step_value(o, "puzzles", "puzzle", idx)
	if pz != "" and not it.has_meta("solved"):
		var ui := UiPuzzle.new()
		ui.setup(pz, hash(it.uid))
		ui.pay = _pay_puzzle_hint
		_dialog_open = true
		ui.finished.connect(func(ok: bool):
			if ok:
				it.set_meta("solved", true))
		ui.on_close.connect(func():
			_dialog_open = false
			await get_tree().process_frame   # Flow najpierw domyka nakładkę zagadki
			if it.has_meta("solved"):
				_obj_activate(o, idx, it)
			else:
				GameState.toast.emit("Nie udało się — spróbuj jeszcze raz.", UiKit.BAD))
		Flow.open_dialog(ui)
		return
	it.done = true
	GameState.set_story_flag(it.uid)
	Fx.burst(it.global_position + Vector2(0, -24), Color(0.8, 0.95, 1.0), 14, 220.0, 3.0, 0.4)
	match String(o.get("type", "")):
		"collect":
			Audio.play("select", 1.1, -2.0)
			var clues: Array = o.get("clues", [])
			var txt := String(clues[idx]) if idx < clues.size() else "Znaleziono wskazówkę."
			_open_dialog([["", txt]], UiKit.ACCENT2)
		"free":
			Audio.play("confirm", 1.2, -2.0)
			GameState.toast.emit("Uwolniono! (%d / %d)" % [ChapterExtras.count_done(quest_id, o), int(o.get("count", 1))], UiKit.GOOD)
		"sabotage":
			Audio.play("hit_heavy", 0.8, -4.0)
			Fx.shake(5.0, 0.2)
			var msg := MinesDB.step_value(o, "msgs", "msg", idx, "Zniszczono!")
			GameState.toast.emit("%s (%d / %d)" % [msg, ChapterExtras.count_done(quest_id, o), int(o.get("count", 1))], UiKit.GOOD)
	_check_obj_reward(o)

func _obj_complete_flag(o: Dictionary, i: int) -> void:
	GameState.set_story_flag(ChapterExtras.flag(quest_id, String(o["id"]), i))
	_refresh_heist_guards()
	_check_obj_reward(o)

func _check_obj_reward(o: Dictionary) -> void:
	if not ChapterExtras.is_done(quest_id, o):
		return
	var rflag := "r:" + ChapterExtras.flag(quest_id, String(o["id"]), 0)
	if GameState.story_flag(rflag):
		return
	GameState.set_story_flag(rflag)
	var rw: Dictionary = o.get("reward", {})
	var lines := SecretDB.grant({"items": rw.get("items", {}), "gold": int(rw.get("gold", 0)), "xp": int(rw.get("xp", 0))})
	GameState.toast.emit("Cel ukończony: %s%s" % [String(o["text"]), (" — " + ", ".join(lines)) if not lines.is_empty() else ""], UiKit.ACCENT)
	Audio.play("levelup", 1.3, -6.0)
	GameState.save_game()
	if String(o.get("scene", "")) != "":
		_scene_later(String(o["scene"]))

## Historyjka po ukończeniu celu (np. zalanie kopalni) — z chwilą oddechu po zamknięciu zagadki.
func _scene_later(kind: String) -> void:
	await get_tree().create_timer(1.4).timeout
	if is_instance_valid(self) and not finished and not _dialog_open:
		await _vignette_async(kind)

func _talk_extra(id: String) -> void:
	if _heist_turn_in(id):
		return
	var enc := EncounterDB.enc_of_npc(id)
	if enc != "":
		_start_encounter(enc)
		return
	var d := ChapterExtras.dialog(quest_id, id)
	var accent: Color = NpcDB.get_data(id).get("accent", UiKit.ACCENT)
	var step := GameState.story_step()
	var post: bool = step > waves.size()
	var lines: Array = d.get("post" if post else "pre", [["", "…"]])
	var choice: Dictionary = d.get("choice", {})
	var made := false
	for opt in choice.get("options", []):
		if GameState.story_flag(String(opt["flag"])):
			made = true
	_open_dialog(lines, accent, func():
		_mark_talked(id)
		if not choice.is_empty() and not made and not post:
			_open_choice_deferred(choice, accent))

## Spotkanie w stylu BG (zob. EncounterDB): rozmowa z próbami umiejętności, rozgrywana raz.
func _start_encounter(enc: String) -> void:
	if _dialog_open:
		return
	var e: Dictionary = EncounterDB.LIST[enc]
	if GameState.story_flag(EncounterDB.flag_done(enc)):
		_open_dialog([[String((e["npc"] as Dictionary)["name"]), "Wszystko już sobie powiedzieliśmy. Powodzenia."]], (e["npc"] as Dictionary).get("accent", UiKit.ACCENT))
		return
	_enc_step(enc, String(e["start"]), "", true, "")

func _enc_step(enc: String, node: String, roll_text: String, roll_ok: bool, fx_text: String) -> void:
	var v := EncounterDB.view(enc, node, EncounterDB.ctx_game())
	var ui := UiEncounter.new()
	ui.setup(v, roll_text, roll_ok, fx_text)
	_dialog_open = true
	var picked := [-2]
	ui.picked.connect(func(i: int): picked[0] = i)
	ui.on_close.connect(func():
		_dialog_open = false
		await get_tree().process_frame   # Flow najpierw domyka nakładkę
		if int(picked[0]) < 0 or bool(v["terminal"]):
			return
		var res := EncounterDB.choose(enc, node, int(picked[0]), EncounterDB.ctx_game())
		if not bool(res.get("ok", false)):
			return
		if String(res.get("set", "")) != "":
			GameState.set_story_flag("enc:" + String(res["set"]))
		var next := String(res["next"])
		var fx := EncounterDB.node_effects(enc, next)
		var lines := EncounterDB.apply(res, fx)
		var nv := EncounterDB.view(enc, next, EncounterDB.ctx_game())
		if bool(nv["terminal"]):
			GameState.set_story_flag(EncounterDB.flag_done(enc))
		GameState.save_game()
		_enc_step(enc, next, EncounterDB.roll_text(res["roll"]), bool((res["roll"] as Dictionary).get("success", true)), ", ".join(lines)))
	Flow.open_dialog(ui)

func _mark_talked(id: String) -> void:
	for o in ChapterExtras.objectives(quest_id):
		if String(o.get("type", "")) != "talk":
			continue
		var npcs: Array = o.get("npcs", [])
		var i := npcs.find(id)
		if i >= 0:
			GameState.set_story_flag(ChapterExtras.flag(quest_id, String(o["id"]), i))
			_check_obj_reward(o)

## Nakładka musi otworzyć się dopiero po zamknięciu poprzedniej (Flow zamyka ją po sygnale).
func _open_choice_deferred(choice: Dictionary, accent: Color) -> void:
	await get_tree().process_frame
	_open_choice(choice, accent)

func _open_choice(choice: Dictionary, accent: Color, after: Callable = Callable()) -> void:
	if _dialog_open:
		return
	var opts: Array = []
	for o in choice["options"]:
		var item := {"text": String(o["text"])}
		if int(o.get("cost", 0)) > GameState.gold():
			item["disabled"] = true
			item["hint"] = "Za mało złota (%d)" % int(o["cost"])
		for tk in o.get("take", {}):
			if GameState.item_count(String(tk)) < int(o["take"][tk]):
				item["disabled"] = true
				item["hint"] = "Brakuje przedmiotu"
		opts.append(item)
	_dialog_open = true
	var ui := UiChoice.new()
	ui.setup(String(choice["prompt"]), opts, accent)
	ui.chosen.connect(func(i: int):
		var opt: Dictionary = (choice["options"] as Array)[i]
		GameState.set_story_flag(String(opt["flag"]))
		GameState.refresh_stats()
		var eff := DecisionDB.describe(String(opt["flag"]))
		if eff != "":
			GameState.toast.emit("Decyzja ma skutki: %s" % eff, UiKit.ACCENT)
		if int(opt.get("rep", 0)) > 0:
			Act2DB.add_rep(int(opt["rep"]))
		if int(opt.get("cost", 0)) > 0:
			GameState.spend(int(opt["cost"]))
		for tk in opt.get("take", {}):
			GameState.remove_item(String(tk), int(opt["take"][tk]))
		GameState.save_game()
		_pending_reply = String(opt.get("reply", "")))
	ui.on_close.connect(func():
		_dialog_open = false
		if _pending_reply != "":
			var r := _pending_reply
			_pending_reply = ""
			await get_tree().process_frame
			_open_dialog([["", r]], accent, after)
		elif after.is_valid():
			after.call())
	Flow.open_dialog(ui)

var _pending_reply := ""

func _giver_gate(phase: String) -> String:
	if not ChapterExtras.has(quest_id):
		return ""
	return ChapterExtras.remaining_text(quest_id, phase)

# ------------------------------------------------------------ żołnierze i laboratoria ---

func _spawn_allies() -> void:
	if arena_mode or challenge_mode or player == null or not is_instance_valid(player):
		return
	var n := int(zone.get("allies", 4 if QuestDB.act_of(maxi(0, GameState.story_chapter())) == 2 else 3))
	for i in n:
		if GameState.is_fallen("ally:%d" % i):
			continue
		var a := Ally.new()
		a.setup(player, i)
		entities.add_child(a)

## Polegli towarzysze wracają karetką po 5 minutach w szpitalu.
## Szpital: czas leczenia upływa podczas gry; po 5 minutach towarzysz wraca karetką z pełnym życiem.
func _tick_hospital(delta: float) -> void:
	if arena_mode or challenge_mode or finished or player == null or not is_instance_valid(player):
		return
	var fallen: Dictionary = GameState.rpg.get("fallen", {})
	if fallen.is_empty():
		return
	for key in fallen.keys():
		fallen[key] = float(fallen[key]) - delta
		if float(fallen[key]) <= 0.0:
			fallen.erase(key)
			_return_support(String(key))

func _return_support(key: String) -> void:
	var pos := player.global_position + Vector2(-90.0, 30.0)
	Ambulance.dispatch(entities, pos, func():
		if player == null or not is_instance_valid(player):
			return
		if key == "pet":
			player._respawn_pet()
		elif key.begins_with("ally:"):
			var a := Ally.new()
			a.setup(player, int(key.substr(5)))
			entities.add_child(a)
			a.global_position = pos
		Fx.burst(pos + Vector2(0, -24), Color(0.6, 1.0, 0.7), 14, 220.0, 3.0, 0.5)
		GameState.toast.emit("Towarzysz wrócił do walki!", UiKit.GOOD))

func _build_lab() -> void:
	if cave_mode:
		return
	var pos: Variant = SecretDB.lab_for(quest_id)
	if pos == null:
		return
	var bld := Node2D.new()
	bld.position = pos
	entities.add_child(bld)
	bld.add_child(PixelProps.lab_building())
	var sbody := StaticBody2D.new()
	sbody.collision_layer = 1
	sbody.collision_mask = 0
	var scs := CollisionShape2D.new()
	var ssh := RectangleShape2D.new()
	ssh.size = Vector2(210, 80)
	scs.shape = ssh
	scs.position = Vector2(0, -50)
	sbody.add_child(scs)
	bld.add_child(sbody)
	var lab := Interactable.new()
	lab.setup("lab", "Wejdź do laboratorium")
	lab.radius = 90.0
	_spot(lab, pos + Vector2(0, 38))
	lab.activated.connect(func(_w): Flow.open_lab_overlay())

## Budynek szpitala: za złoto leczy rannych strażników i peta oraz wypisuje poległych.
func _build_hospital() -> void:
	if cave_mode or march_mode or arena_mode or challenge_mode:
		return
	var taken: Array = []
	if _board != null:
		taken.append(_board.position)
	for n in get_tree().get_nodes_in_group("interactables"):
		taken.append((n as Node2D).position)
	var pos := _free_spot([Vector2(-560, -80), Vector2(560, -80), Vector2(-700, 120), Vector2(700, 120), Vector2(-420, -300), Vector2(420, -300), Vector2(0, -420)], taken)
	var bld := Node2D.new()
	bld.position = pos
	entities.add_child(bld)
	bld.add_child(PixelProps.hospital_building())
	var sbody := StaticBody2D.new()
	sbody.collision_layer = 1
	sbody.collision_mask = 0
	var scs := CollisionShape2D.new()
	var ssh := RectangleShape2D.new()
	ssh.size = Vector2(210, 80)
	scs.shape = ssh
	scs.position = Vector2(0, -50)
	sbody.add_child(scs)
	bld.add_child(sbody)
	var door := Interactable.new()
	door.setup("hospital", "Wejdź do szpitala")
	_spot(door, pos + Vector2(0, 38))
	door.activated.connect(func(_w): _open_hospital())

func _open_hospital() -> void:
	if _dialog_open or finished:
		return
	var ui := UiHospital.new()
	ui.setup(true)
	ui.act.connect(func(kind: String, key: String):
		if kind == "heal":
			var cost := UiHospital.heal_cost(key)
			if GameState.gold() < cost:
				return
			GameState.spend(cost)
			var mx := UiHospital.max_hp_of(key)
			GameState.set_support_hp(key, mx)
			for a in get_tree().get_nodes_in_group("allies"):
				if key.begins_with("ally:") and is_instance_valid(a) and int(a.get("slot")) == int(key.substr(5)):
					a.set("hp", mx)
			if key == "pet" and player != null and is_instance_valid(player) and player.get("_pet") != null and is_instance_valid(player.get("_pet")):
				(player.get("_pet")).set("hp", mx)
			GameState.toast.emit("Wyleczono za %d zł." % cost, UiKit.GOOD)
		elif kind == "revive":
			var rc := UiHospital.revive_cost()
			if GameState.gold() < rc or not GameState.is_fallen(key):
				return
			GameState.spend(rc)
			(GameState.rpg["fallen"] as Dictionary).erase(key)
			GameState.clear_support_hp(key)
			_return_support(key)
			GameState.toast.emit("Wypisano ze szpitala za %d zł." % rc, UiKit.GOOD)
		GameState.save_game()
		ui.refresh())
	Flow.open_dialog(ui)

# ------------------------------------------------------------- LAN: świat wspólny ---

var _sync_acc := 0.0

func _levers_pulled_count(cave: Dictionary) -> int:
	var n := 0
	for i in (cave["levers"] as Array).size():
		if GameState.story_flag("lv:%s:%d" % [quest_id, i]) or i in SecretDB.levers_pulled(quest_id):
			n += 1
	return n

## Stan obiektów celów i dźwigni wynika ze wspólnych flag fabuły (host jest autorytetem).
func _sync_world_state() -> void:
	for n in get_tree().get_nodes_in_group("interactables"):
		var it := n as Interactable
		if it == null or it.uid == "":
			continue
		if (it.uid.begins_with("o:") or it.uid.begins_with("lv:")) and not it.done and GameState.story_flag(it.uid):
			it.done = true
	if _entrance != null and is_instance_valid(_entrance) and not _entrance.visible:
		var cave := SecretDB.cave_for(quest_id)
		if not cave.is_empty() and _levers_pulled_count(cave) >= (cave["levers"] as Array).size():
			_entrance.visible = true
			_banner("COŚ ZAZGRZYTAŁO…", "Odsłonięto wejście do: %s" % String(cave["name"]))

func _req_begin_defense() -> void:
	if _net_client:
		Net.send_world_event("begin_defense")
	else:
		_begin_defense()

func _req_finish_story() -> void:
	if _net_client:
		Net.send_world_event("finish_story")
	else:
		_finish_story()

func _on_world_event(event_name: String, data: Dictionary) -> void:
	if _net_host:
		match event_name:
			"flag":
				GameState.set_story_flag(String(data.get("name", "")), bool(data.get("value", true)), false)
			"begin_defense":
				_begin_defense()
			"finish_story":
				_finish_story()
			"enter_cave":
				var cave := SecretDB.cave_for(quest_id)
				if not cave.is_empty() and _entrance != null and _entrance.visible:
					_enter_cave(cave)
			"leave_cave":
				if cave_mode:
					_leave_cave()
	elif _net_client:
		match event_name:
			"arena_ko":
				_arena_ko_show(String(data.get("winner", "")), String(data.get("cause", "")))
			"rewards":
				_grant_rewards_local(String(data.get("quest", "")))
			"cave_cleared":
				if cave_mode:
					_spawn_cave_chest(bool(data.get("bonus", false)))

## Gość otrzymuje nagrody za rozdział na własne konto (host przyznaje je sobie w _finish_story).
func _grant_rewards_local(qid: String) -> void:
	var quest := QuestDB.get_data(qid)
	if quest.is_empty() or GameState.story_done(qid):
		return
	var reward: Dictionary = quest.get("reward", {})
	GameState.add_gold(int(reward.get("gold", 0)))
	GameState.add_xp(int(reward.get("xp", 0)))
	for it in reward.get("items", {}):
		GameState.add_item(String(it), int(reward["items"][it]))
	if ChapterExtras.has(qid):
		var fb := ChapterExtras.final_bonus(qid)
		if int(fb["gold"]) > 0:
			GameState.add_gold(int(fb["gold"]))
		for fit in fb["items"]:
			GameState.add_item(String(fit), int(fb["items"][fit]))
	GameState.complete_quest(qid)
	GameState.save_game()
	GameState.toast.emit("%s ukończony! Nagrody otrzymane." % String(quest.get("label", "Rozdział")), UiKit.GOOD)

# ------------------------------------------------------- zlecenia poboczne ---

var _board: Interactable = null

func _build_side() -> void:
	# gość LAN też dostaje tablicę (żeby układ budynków był taki sam jak u hosta), ale bez obiektów zleceń
	if cave_mode or march_mode:
		return
	_board = Interactable.new()
	_board.setup("board", "Tablica zleceń")
	_spot(_board, _free_spot([Vector2(300, -100), Vector2(-300, -100), Vector2(440, -60), Vector2(-440, -60), Vector2(260, -240), Vector2(-260, -240), Vector2(0, -300), Vector2(560, -180), Vector2(-560, -180)], []))
	_board.activated.connect(func(_w): _open_board())
	if _net_client:
		return
	for q in SideDB.active():
		if String(q["zone"]) == quest_id and not SideDB.is_complete(q):
			_spawn_side_objects(q)

func _spawn_side_objects(q: Dictionary) -> void:
	var id := String(q["id"])
	match String(q["type"]):
		"herbs":
			for i in int(q["count"]):
				if i in (q["found"] as Array):
					continue
				var it := Interactable.new()
				it.setup("herb", "Zerwij zioło")
				_spot(it, SideDB.spot(id, i))
				var idx := i
				it.activated.connect(func(_w):
					if it.done:
						return
					it.done = true
					Audio.play("select", 1.2, -2.0)
					Fx.burst(it.global_position + Vector2(0, -20), Color(0.5, 1.0, 0.5), 10, 160.0, 3.0, 0.4)
					SideDB.progress(id, idx)
					_side_toast(id)
					it.queue_free())
		"tracks":
			_spawn_next_track(id)
		"hunt":
			var e := (ENEMY_SCENE as PackedScene).instantiate() as Enemy
			e.setup("kruk", false, true)
			e.aggro = 520.0
			entities.add_child(e)
			e.global_position = SideDB.spot(id, 0)
			e.set_bounds_rect(MARGIN, VILLAGE.x - MARGIN, MARGIN, VILLAGE.y - MARGIN)
			e.died.connect(func(_x):
				SideDB.progress(id)
				_side_toast(id))
			GameState.toast.emit("Łowca nagród kręci się gdzieś w okolicy…", UiKit.ACCENT)

func _spawn_next_track(id: String) -> void:
	var q := SideDB.find(id)
	if q.is_empty():
		return
	var n := int(q.get("prog", 0))
	var last := n >= int(q["count"]) - 1
	var it := Interactable.new()
	it.setup("chest" if last else "tracks", "Otwórz skrzynię kupca" if last else "Zbadaj ślady")
	_spot(it, SideDB.spot(id, n))
	it.activated.connect(func(_w):
		if it.done:
			return
		it.done = true
		Audio.play("select", 1.0, -2.0)
		Fx.burst(it.global_position + Vector2(0, -20), Color(1.0, 0.9, 0.5), 10, 160.0, 3.0, 0.4)
		SideDB.progress(id)
		_side_toast(id)
		if not last:
			it.queue_free()
			_spawn_next_track(id))

func _side_toast(id: String) -> void:
	var q := SideDB.find(id)
	if q.is_empty():
		return
	if SideDB.is_complete(q):
		GameState.toast.emit("Zlecenie wykonane: %s — wróć na tablicę po nagrodę." % SideDB.title_of(q), UiKit.GOOD)
	else:
		GameState.toast.emit("%s (%d/%d)" % [SideDB.title_of(q), int(q["prog"]), int(q["count"])], UiKit.ACCENT2)

func _try_deliver_package(npc_id: String) -> bool:
	for q in SideDB.active():
		if String(q["type"]) == "package" and String(q["zone"]) == quest_id and String(q["npc"]) == npc_id and not SideDB.is_complete(q) and GameState.item_count("paczka_listow") > 0:
			GameState.remove_item("paczka_listow", 1)
			SideDB.progress(String(q["id"]))
			var nm := String(NpcDB.get_data(npc_id).get("name", ChapterExtras.NPCS.get(npc_id, {}).get("name", "Adresat")))
			_open_dialog([[nm, "Paczka listów! Od dawna na nią czekałem. Przekaż na tablicy, że dotarła."]], UiKit.ACCENT, func(): _side_toast(String(q["id"])))
			return true
	return false

func _open_board() -> void:
	if _dialog_open or finished:
		return
	if _net_client:
		GameState.toast.emit("Zlecenia poboczne przyjmuje host.", UiKit.ACCENT2)
		return
	var opts: Array = []
	var acts: Array = []
	for q in SideDB.active():
		if SideDB.is_complete(q):
			var r: Dictionary = q["reward"]
			opts.append({"text": "Odbierz nagrodę: %s  (%d zł, %d XP)" % [SideDB.title_of(q), int(r["gold"]), int(r["xp"])]})
			acts.append(["turn", String(q["id"])])
	for q in SideDB.offers(quest_id, ChapterExtras.npc_ids(quest_id) if ChapterExtras.has(quest_id) else []):
		var taken := not SideDB.find(String(q["id"])).is_empty()
		if taken:
			continue
		var r2: Dictionary = q["reward"]
		var o := {"text": "%s — %s  [%d zł]" % [SideDB.title_of(q), SideDB.desc_of(q), int(r2["gold"])]}
		if SideDB.active().size() >= 2:
			o["disabled"] = true
			o["hint"] = "Masz już 2 aktywne zlecenia."
		opts.append(o)
		acts.append(["accept", q])
	opts.append({"text": "Zamknij tablicę"})
	acts.append(["close", null])
	_dialog_open = true
	var ui := UiChoice.new()
	var rep_txt := "Reputacja: %d  ·  wykonane zlecenia: %d" % [Act2DB.rep(), SideDB.done_count()]
	ui.setup("TABLICA ZLECEŃ  —  %s" % rep_txt, opts, Color(0.95, 0.8, 0.4))
	ui.chosen.connect(func(i: int): _board_pick(acts[i]))
	ui.on_close.connect(func(): _dialog_open = false)
	Flow.open_dialog(ui)

func _board_pick(a: Array) -> void:
	match String(a[0]):
		"turn":
			var lines := SideDB.turn_in(String(a[1]))
			Audio.play("levelup", 1.0, -2.0)
			GameState.toast.emit("Nagroda: " + ", ".join(lines), UiKit.GOOD)
		"accept":
			var q: Dictionary = a[1]
			if SideDB.accept(q):
				Audio.play("confirm")
				_spawn_side_objects(SideDB.find(String(q["id"])))
				GameState.toast.emit("Przyjęto zlecenie: %s" % SideDB.title_of(q), UiKit.ACCENT)

# ---------------------------------------------- wnętrza: wystrój, komnaty, schody, skrytka ---

## Meble i dekoracje zgodne z opisem etapu (regały w bibliotece, stoły na bankiecie, portrety w galerii…).
func _build_decor() -> void:
	if cave_mode or march_mode:
		return
	var list: Array = PalaceDB.DECOR.get(quest_id, FortressDB.DECOR.get(quest_id, []))
	for i in list.size():
		var d: Array = list[i]
		var kind := String(d[0])
		var n := Node2D.new()
		n.position = d[1]
		entities.add_child(n)
		n.add_child(PixelProps.decor(kind, i))
		if PixelProps.DECOR_BODY.has(kind):
			var sb := StaticBody2D.new()
			sb.collision_layer = 1
			sb.collision_mask = 0
			var cs := CollisionShape2D.new()
			var sh := RectangleShape2D.new()
			sh.size = PixelProps.DECOR_BODY[kind]
			cs.shape = sh
			cs.position = Vector2(0, -sh.size.y * 0.5)
			sb.add_child(cs)
			n.add_child(sb)

## Sekretne komnaty arystokratów: wejście jest dobrowolne, w środku czeka scenka.
func _build_rooms() -> void:
	if cave_mode or march_mode:
		return
	for r in PalaceDB.ROOMS.get(quest_id, []):
		var rd: Dictionary = r
		var door := Interactable.new()
		door.setup("door", "Sekretna komnata", "", true)
		door.reveal_radius = 360.0
		door.accent = Color(0.8, 0.7, 1.0)
		_spot(door, rd["pos"])
		door.activated.connect(func(_w): _enter_room(rd))

func _enter_room(rd: Dictionary) -> void:
	if _dialog_open or finished:
		return
	_dialog_open = true
	Audio.play("gate", 1.3, -8.0)
	var ui := UiVignette.new()
	ui.setup(String(rd["kind"]))
	ui.on_close.connect(func():
		_dialog_open = false
		var flag := "room:" + String(rd["id"])
		if not GameState.story_flag(flag):
			GameState.set_story_flag(flag)
			GameState.add_gold(60)
			GameState.toast.emit("Sekretna komnata odkryta: %s  (+60 zł)" % String(rd["name"]), UiKit.ACCENT))
	Flow.open_dialog(ui)

## Schody na kolejne piętro pojawiają się po pokonaniu wszystkich fal.
func _spawn_stairs() -> void:
	var st := Interactable.new()
	st.setup("stairs", "Wejdź schodami w górę")
	st.accent = Color(1.0, 0.9, 0.5)
	_spot(st, Vector2(1100, 360))
	st.activated.connect(func(_w):
		if st.done:
			return
		st.done = true
		_req_finish_story())
	GameState.toast.emit("Schody w górę są wolne!", UiKit.GOOD)
	Audio.play("gate", 1.0, -6.0)

func _begin_stairs_floor() -> void:
	await get_tree().create_timer(0.9).timeout
	if not is_instance_valid(self) or finished:
		return
	var banner: Array = zone.get("intro_banner", ["", ""])
	_banner(String(banner[0]), String(banner[1]))
	await get_tree().create_timer(1.7).timeout
	if not is_instance_valid(self) or finished:
		return
	_open_dialog(_with_title(zone.get("intro", []), _hero_title()), UiKit.ACCENT2, func():
		GameState.toast.emit("Przejdź przez komnaty i pokonaj straż — potem schody w górę.", UiKit.ACCENT)
		_begin_defense())

## Skrytka jak w Diablo 2 Resurrected: wspólna dla wszystkich postaci, stoi obok miejsca startu.
func _build_stash() -> void:
	if cave_mode or march_mode or arena_mode:
		return
	var it := Interactable.new()
	it.setup("stash", "Otwórz skrytkę")
	it.accent = Color(1.0, 0.85, 0.4)
	var taken: Array = [_board.position] if _board != null else []
	_spot(it, _free_spot([Vector2(-300, -100), Vector2(300, -100), Vector2(-440, -60), Vector2(440, -60), Vector2(-260, -240), Vector2(260, -240), Vector2(0, -300), Vector2(-560, -180), Vector2(560, -180)], taken))
	it.activated.connect(func(_w): Flow.open_stash())

# ------------------------------------------------------------ pojedynek z rycerzem ---

var _duels := 0

## Czasem między falami pojawia się rycerz w zbroi i wyzywa na pojedynek.
func _roll_duel() -> bool:
	if challenge_mode or cave_mode or custom_mode or arena_mode or march_mode or _net_host or _net_client or _duels >= 1:
		return false
	if wave_i >= waves.size() or bool(waves[wave_i].get("boss", false)):
		return false
	if quest_id == "zamek_kruka":
		return true   # w Zamku Kruka rycerz wyzywa na pojedynek zawsze (po pierwszej fali)
	return randf() < 0.16

func _start_duel() -> void:
	_duels += 1
	wave_active = false
	var kid := KnightDB.roll()
	if quest_id == "zamek_kruka":
		kid = "rycerz_hiper" if randf() < 0.5 else "rycerz_legenda"
	var kd: Dictionary = EnemyDB.get_data(kid)
	_banner("POJEDYNEK", String(kd["name"]))
	Audio.play("roar", 0.8, -4.0)
	await get_tree().create_timer(1.6).timeout
	if finished or not is_instance_valid(self):
		return
	var lines: Array = [
		[String(kd["name"]), "Stój, wędrowcze! Moja tarcza jeszcze nie znalazła godnego przeciwnika."],
		[String(kd["name"]), "Walczymy jeden na jednego. Uważaj — każdy cios z przodu odbiję. Chyba że sam zaatakuję."],
	]
	if int(kd.get("knight_tier", 0)) == 2:
		lines.append([String(kd["name"]), "Ta zbroja nie ma sobie równych. Spróbuj ją zarysować."])
	_open_dialog(lines, Color(0.85, 0.85, 0.95), func():
		var k: Enemy = (ENEMY_SCENE as PackedScene).instantiate() as Enemy
		k.setup(kid, false, false)
		k.is_duel = true
		k.aggro = 2000.0
		entities.add_child(k)
		var side := 1.0 if player.global_position.x < VILLAGE.x * 0.5 else -1.0
		k.global_position = (player.global_position + Vector2(260.0 * side, 0.0)).clamp(Vector2(MARGIN + 40, MARGIN + 40), Vector2(VILLAGE.x - MARGIN - 40, VILLAGE.y - MARGIN - 40))
		k.set_bounds_rect(MARGIN, VILLAGE.x - MARGIN, MARGIN, VILLAGE.y - MARGIN)
		_arena = BossArena.new()
		_arena.center = (player.global_position + k.global_position) * 0.5
		_arena.radius = 380.0
		add_child(_arena)
		_track_boss(k)
		k.died.connect(func(_e): _end_duel(kd)))

func _end_duel(kd: Dictionary) -> void:
	if _arena and is_instance_valid(_arena):
		_arena.lower()
	_arena = null
	var lv := GameState.player_level()
	var gold := int(float(kd.get("gold", 90)) * (1.0 + 0.04 * float(lv)))
	GameState.add_gold(gold)
	var lines: Array = ["%d zł" % gold]
	if randf() < 0.25:
		GameState.add_item("zwoj_teleportacji", 1)
		lines.append("Zwój teleportacji")
	AchievementDB.bump("duels")
	GameState.toast.emit("Wygrany pojedynek! Łup: " + ", ".join(lines), UiKit.GOOD)
	_banner("ZWYCIĘSTWO", "Pojedynek wygrany")
	Fx.flash(Color(1, 1, 0.9), 0.3, 0.5)
	await get_tree().create_timer(2.2).timeout
	if not finished and is_instance_valid(self):
		_next_wave_after_clear()

## Wybiera miejsce wokół startu najdalej od NPC i innych obiektów (żeby nie zasłaniały rozmów).
func _free_spot(offsets: Array, taken: Array) -> Vector2:
	var best: Vector2 = spawn + (offsets[0] as Vector2)
	var best_d := -1.0
	for o in offsets:
		var p := Vector2(clampf(spawn.x + (o as Vector2).x, 150.0, VILLAGE.x - 150.0), clampf(spawn.y + o.y, 160.0, VILLAGE.y - 150.0))
		var dmin := 1.0e9
		for e in npcs:
			var nd: Node2D = e["node"]
			if is_instance_valid(nd):
				dmin = minf(dmin, nd.global_position.distance_to(p))
		for t in taken:
			dmin = minf(dmin, (t as Vector2).distance_to(p))
		if dmin > best_d:
			best_d = dmin
			best = p
	return best

# ------------------------------------------------------------ tryb wyzwań ---

func _challenge_zone() -> Dictionary:
	return {
		"terrain": "palace", "spawn": Vector2(1100, 1080), "npcs": [], "giver": "", "waves": [],
		"intro_banner": ["WYZWANIE", "Kolejni rycerze, coraz silniejsi"],
		"outro_banner": ["KONIEC WYZWANIA", ""],
	}

func _begin_challenge() -> void:
	await get_tree().create_timer(0.9).timeout
	if not is_instance_valid(self) or finished:
		return
	var banner: Array = zone.get("intro_banner", ["", ""])
	_banner(String(banner[0]), String(banner[1]))
	await get_tree().create_timer(2.0).timeout
	_challenge_next()

func _challenge_next() -> void:
	if finished or not is_instance_valid(self):
		return
	_ch_round += 1
	var kid := "rycerz_pojedynku"
	if _ch_round >= 7:
		kid = "rycerz_hiper"
	elif _ch_round >= 3:
		kid = "rycerz_legenda"
	var kd: Dictionary = EnemyDB.get_data(kid)
	_banner("RUNDA %d" % _ch_round, String(kd["name"]))
	Audio.play("roar", 0.8 + 0.02 * float(_ch_round), -4.0)
	await get_tree().create_timer(1.6).timeout
	if finished or not is_instance_valid(self):
		return
	var k: Enemy = (ENEMY_SCENE as PackedScene).instantiate() as Enemy
	k.setup(kid, false, false)
	k.apply_mods(1.0 + 0.12 * float(_ch_round - 1), 1.0 + 0.06 * float(_ch_round - 1), 1.0)
	k.is_duel = true
	k.aggro = 2000.0
	entities.add_child(k)
	var side := 1.0 if player.global_position.x < VILLAGE.x * 0.5 else -1.0
	k.global_position = (player.global_position + Vector2(260.0 * side, 0.0)).clamp(Vector2(MARGIN + 40, MARGIN + 40), Vector2(VILLAGE.x - MARGIN - 40, VILLAGE.y - MARGIN - 40))
	k.set_bounds_rect(MARGIN, VILLAGE.x - MARGIN, MARGIN, VILLAGE.y - MARGIN)
	_arena = BossArena.new()
	_arena.center = (player.global_position + k.global_position) * 0.5
	_arena.radius = 380.0
	add_child(_arena)
	_track_boss(k)
	k.died.connect(func(_e): _challenge_won(kd))

func _challenge_won(kd: Dictionary) -> void:
	if _arena and is_instance_valid(_arena):
		_arena.lower()
	_arena = null
	AchievementDB.bump("duels")
	AchievementDB.set_max("challenge_best", _ch_round)
	GameState.add_gold(int(kd.get("gold", 90)))
	if player and is_instance_valid(player):
		player.heal(player.max_hp * 0.3)
	_banner("RUNDA %d UKOŃCZONA" % _ch_round, "Łapiesz oddech…")
	Audio.play("levelup", 1.0, -4.0)
	await get_tree().create_timer(2.4).timeout
	_challenge_next()

func _challenge_over() -> void:
	finished = true
	var rounds := _ch_round - 1
	var rank: Array = GameState.profile.get("challenge_rank", [])
	rank.append({"rounds": rounds, "lv": GameState.player_level(), "cls": String(GameState.char_profile(GameState.current_character_id()).get("class", ""))})
	rank.sort_custom(func(a, b): return int(a["rounds"]) > int(b["rounds"]))
	rank = rank.slice(0, 5)
	GameState.profile["challenge_rank"] = rank
	AchievementDB.set_max("challenge_best", rounds)
	GameState.save_game()
	var txt := "RANKING (najlepsze 5):"
	var i := 1
	for e in rank:
		txt += "
%d.  %d rund  ·  poz. %d  ·  %s" % [i, int(e["rounds"]), int(e["lv"]), String(e["cls"])]
		i += 1
	var lines: Array = [["", "Padłeś w rundzie %d. Pokonanych rycerzy: %d." % [_ch_round, rounds]], ["", txt]]
	_open_dialog(lines, Color(1.0, 0.75, 0.3), func():
		GameState.finish_run(false)
		Flow.goto("menu"))
