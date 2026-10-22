extends Node
## Flow — menedżer ekranów. Przełącza menu, wybór postaci, ekwipunek, sklep
## i scenę gry. Pauza jest nakładką, która nie niszczy sceny etapu.

signal screen_changed(name: String)

const STAGE_SCENE := "res://scenes/stage.tscn"
const VILLAGE_SCENE := "res://scenes/village.tscn"

var current: Node = null
var stage: Node = null
var hud: CanvasLayer = null
var pause_ui: UiPause = null
var overlay: CanvasLayer = null
var _busy := false
var _booted := false
var _pending_results: Dictionary = {}
var _overlay_from_gameplay := false
var _shop_then_menu := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	if not _booted:
		_booted = true
		goto("menu")

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed("pause"):
		if stage != null and is_instance_valid(stage) and overlay == null:
			toggle_pause()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("equipment"):
		if overlay != null and is_instance_valid(overlay):
			if _overlay_from_gameplay:
				_close_overlay()
				get_viewport().set_input_as_handled()
			return
		if stage != null and is_instance_valid(stage) and stage.has_method("try_interact"):
			if bool(stage.call("try_interact")):
				get_viewport().set_input_as_handled()
				return
		var blocked: bool = stage == null or not is_instance_valid(stage) or _busy
		if not blocked and pause_ui and is_instance_valid(pause_ui) and pause_ui.visible:
			blocked = true
		if not blocked:
			_open_loadout_overlay(true)
			get_viewport().set_input_as_handled()
	if event.is_action_pressed("quest_log"):
		if overlay != null and is_instance_valid(overlay):
			if _overlay_from_gameplay:
				_close_overlay()
				get_viewport().set_input_as_handled()
			return
		var blocked2: bool = stage == null or not is_instance_valid(stage) or _busy
		if not blocked2 and pause_ui and is_instance_valid(pause_ui) and pause_ui.visible:
			blocked2 = true
		if not blocked2:
			_open_quest_log()
			get_viewport().set_input_as_handled()

# --------------------------------------------------------------- pomocnicze ---

func add_to_tree(n: Node) -> Node:
	get_tree().current_scene.add_child(n)
	return n

func clear() -> void:
	_hide_overlay()
	_overlay_from_gameplay = false
	_hide_pause()
	stage = null
	hud = null
	if current and is_instance_valid(current):
		current.queue_free()
	current = null
	Fx.clear_world()
	get_tree().paused = false
	GameState.game_paused = false

func goto(screen: String, args: Dictionary = {}) -> void:
	if _busy:
		return
	_busy = true
	Fx.fade_to(1.0, 3.2)
	await get_tree().create_timer(0.32, true, false, true).timeout
	clear()
	_build(screen, args)
	Fx.fade_to(0.0, 3.2)
	screen_changed.emit(screen)
	_busy = false

func quit_game() -> void:
	await goto("menu")
	get_tree().quit()

# ------------------------------------------------------------------ budowa ---

func _build(screen: String, args: Dictionary) -> void:
	match screen:
		"menu":
			current = UiMainMenu.new()
			Audio.play_music("menu")
		"select":
			current = UiSelect.new()
			(current as UiSelect).on_chosen.connect(_on_character_chosen)
		"loadout":
			current = UiLoadout.new()
			(current as UiLoadout).setup(String(args.get("from", "select")))
			(current as UiLoadout).on_close.connect(func(): _back_to(String(args.get("from", "select"))))
		"shop":
			current = UiShop.new()
			(current as UiShop).on_close.connect(_shop_done)
		"rpg_select":
			current = UiRpgSelect.new()
			(current as UiRpgSelect).on_start.connect(_on_rpg_start)
		"lan":
			current = UiLanLobby.new()
			(current as UiLanLobby).on_close.connect(func(): goto("menu"))
			(current as UiLanLobby).on_start.connect(_on_lan_start)
		"settings":
			current = UiSettings.new()
			(current as UiSettings).setup("menu")
			(current as UiSettings).on_close.connect(func(): goto("menu"))
		"results":
			current = UiResults.new()
			(current as UiResults).set_results(args.get("results", {}))
			(current as UiResults).victory_changed.connect(_on_victory)
			(current as UiResults).continue_pressed.connect(_on_results_continue)
			(current as UiResults).menu_pressed.connect(func(): GameState.finish_run(true); goto("menu"))
		"gameover":
			current = UiGameOver.new()
			(current as UiGameOver).retry_pressed.connect(_retry)
			(current as UiGameOver).menu_pressed.connect(func(): GameState.finish_run(false); goto("menu"))
		"game":
			_build_stage(int(args.get("stage", 0)))
			return
		_:
			current = UiMainMenu.new()
	if current and current.get_parent() == null:
		get_tree().current_scene.add_child(current)

func _back_to(from: String) -> void:
	match from:
		"pause":
			_show_pause()
		_:
			goto("select")

func _on_character_chosen(id: String) -> void:
	GameState.start_run(id, 0)
	goto("loadout", {"from": "select"})

func _on_rpg_start(mode: String, p1: String, p2: String, cls: String) -> void:
	GameState.start_rpg_run(mode, p1, p2)
	GameState.set_class(cls)
	goto("loadout", {"from": "select"})

func _on_lan_start(p1: String, p2: String, cls: String) -> void:
	GameState.start_rpg_run("lan", p1, p2)
	GameState.set_class(cls)
	goto("loadout", {"from": "select"})

func _shop_done() -> void:
	if _shop_then_menu:
		_shop_then_menu = false
		goto("menu")
		return
	goto("game", {"stage": int(GameState.run.get("stage_index", 0))})

# ------------------------------------------------------------------- scena ---

func _build_stage(index: int) -> void:
	var scene_path := VILLAGE_SCENE if GameState.is_topdown() else STAGE_SCENE
	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_error("Flow: nie znaleziono %s" % scene_path)
		current = UiMainMenu.new()
		add_to_tree(current)
		return
	var s: Node = packed.instantiate()
	s.set("stage_index", index)
	if s.has_signal("stage_cleared"):
		s.connect("stage_cleared", _on_stage_cleared)
	if s.has_signal("player_died"):
		s.connect("player_died", _on_player_died)
	stage = s
	current = s
	add_to_tree(s)
	Audio.play_music(_stage_track(index))

func _stage_track(index: int) -> String:
	match String(StageDB.get_stage(index)["id"]):
		"podworko":
			return "podworko"
		"sad":
			return "sad"
		"las":
			return "las"
		"stodola":
			return "boss"
		"bagno":
			return "bagno"
		"gniazdo":
			return "gniazdo"
	return "menu"

func _on_stage_cleared() -> void:
	var res := GameState.last_results()
	res["victory"] = true
	var idx := int(GameState.run.get("stage_index", 0))
	if GameState.is_topdown():
		var chapter_i := GameState.story_chapter() - 1
		if chapter_i < 0:
			chapter_i = 0
		var c := QuestDB.chapter(chapter_i)
		res["stage_name"] = "%s — %s" % [String(c.get("label", "Rozdział")), String(c.get("title", "Wioska"))]
		res["story"] = true
		res["last_stage"] = GameState.story_chapter() >= QuestDB.count()
	else:
		res["stage_name"] = String(StageDB.get_stage(idx)["name"])
		res["last_stage"] = idx >= StageDB.count() - 1
	GameState.unlock_stage(idx)
	GameState.advance_stage()
	_pending_results = res
	Audio.play_music("victory")
	await get_tree().create_timer(1.1, false).timeout
	goto("results", {"results": res})

func _on_player_died() -> void:
	var res := GameState.last_results()
	res["victory"] = false
	if GameState.is_topdown():
		res["stage_name"] = "Wioska"
	else:
		res["stage_name"] = String(StageDB.get_stage(int(GameState.run.get("stage_index", 0)))["name"])
	_pending_results = res
	await get_tree().create_timer(1.6, false).timeout
	goto("gameover")

func _on_victory(v: bool) -> void:
	if bool(_pending_results.get("last_stage", false)) or bool(_pending_results.get("story", false)):
		GameState.finish_run(v)
	Audio.play_music("victory" if v else "menu")

func _on_results_continue() -> void:
	GameState.commit_backpack()
	if bool(_pending_results.get("story", false)):
		if bool(_pending_results.get("last_stage", false)):
			# ostatni rozdział — zakończ kampanię
			_shop_then_menu = true
			goto("shop")
			return
		# kolejny rozdział tej samej kampanii (bez kończenia runu)
		goto("game", {"stage": int(GameState.run.get("stage_index", 0))})
		return
	if bool(_pending_results.get("last_stage", false)):
		goto("select")
		return
	goto("shop")

func _restart_current() -> void:
	if GameState.is_topdown():
		var players: Array = GameState.rpg_players()
		var p1 := "lord"
		var p2 := ""
		if players.size() > 0:
			p1 = String(players[0].get("id", "lord"))
		if players.size() > 1:
			p2 = String(players[1].get("id", ""))
		var mode := GameState.rpg_mode_str()
		# wznowienie bieżącego rozdziału fabuły
		var chap := GameState.story_chapter()
		var quest := String(QuestDB.chapter(chap).get("id", "obrona_wioski"))
		var flags: Dictionary = GameState.story().get("flags", {}).duplicate()
		var done: Array = (GameState.story().get("done", []) as Array).duplicate()
		GameState.finish_run(false)
		GameState.start_rpg_run(mode, p1, p2)
		var s := GameState.story()
		s["chapter"] = chap
		s["quest"] = quest
		s["step"] = 0
		s["flags"] = flags
		s["done"] = done
		GameState.save_game()
		goto("game", {"stage": 0})
		return
	var idx := int(GameState.run.get("stage_index", 0))
	var id := String(GameState.run.get("character", "kurczak"))
	GameState.finish_run(false)
	GameState.start_run(id, idx)
	goto("game", {"stage": idx})

func _retry() -> void:
	_restart_current()

# ------------------------------------------------------------------- pauza ---

func pause() -> void:
	get_tree().paused = true
	GameState.game_paused = true

func resume() -> void:
	_hide_pause()

func toggle_pause() -> void:
	if _busy:
		return
	if stage == null or not is_instance_valid(stage):
		return
	if pause_ui and is_instance_valid(pause_ui):
		_hide_pause()
	else:
		_show_pause()

func _show_pause() -> void:
	if pause_ui and is_instance_valid(pause_ui):
		pause_ui.visible = true
		pause()
		return
	pause_ui = UiPause.new()
	pause_ui.resume_pressed.connect(resume)
	pause_ui.loadout_pressed.connect(_open_loadout_overlay)
	pause_ui.settings_pressed.connect(_open_settings_overlay)
	pause_ui.restart_pressed.connect(_restart_current)
	pause_ui.menu_pressed.connect(func():
		GameState.finish_run(false)
		goto("menu"))
	add_to_tree(pause_ui)
	pause()

func _hide_pause() -> void:
	if pause_ui and is_instance_valid(pause_ui):
		pause_ui.queue_free()
	pause_ui = null
	get_tree().paused = false
	GameState.game_paused = false

func _open_loadout_overlay(from_gameplay := false) -> void:
	var l := UiLoadout.new()
	l.setup("pause")
	_open_overlay(l, from_gameplay)

func _open_settings_overlay(from_gameplay := false) -> void:
	var s := UiSettings.new()
	s.setup("pause")
	_open_overlay(s, from_gameplay)

func open_dialog(dialog: Control) -> void:
	_open_overlay(dialog, true)

func open_shop_overlay() -> void:
	var s := UiShop.new()
	_open_overlay(s, true)

func _open_quest_log() -> void:
	var q := UiQuestLog.new()
	_open_overlay(q, true)

func _open_overlay(node: Control, from_gameplay: bool) -> void:
	if _busy:
		return
	_overlay_from_gameplay = from_gameplay
	if from_gameplay:
		pause()
	elif pause_ui and is_instance_valid(pause_ui):
		pause_ui.visible = false
	# warstwa wyższa niż HUD (10), żeby nakładka nie ginęła pod paskami
	var wrap := CanvasLayer.new()
	wrap.layer = 50
	wrap.process_mode = Node.PROCESS_MODE_ALWAYS
	wrap.add_child(node)
	if node.has_signal("on_close"):
		node.connect("on_close", _close_overlay)
	overlay = wrap
	add_to_tree(wrap)

func _close_overlay() -> void:
	_hide_overlay()
	if _overlay_from_gameplay:
		_overlay_from_gameplay = false
		get_tree().paused = false
		GameState.game_paused = false
	elif pause_ui and is_instance_valid(pause_ui):
		pause_ui.visible = true

func _hide_overlay() -> void:
	if overlay and is_instance_valid(overlay):
		overlay.queue_free()
	overlay = null