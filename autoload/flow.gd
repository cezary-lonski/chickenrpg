extends Node
## Flow — menedżer ekranów. Przełącza menu, wybór postaci, ekwipunek, sklep
## i scenę gry. Pauza jest nakładką, która nie niszczy sceny etapu.

signal screen_changed(name: String)

const VILLAGE_SCENE := "res://scenes/village.tscn"

var current: Node = null
var current_screen := ""
var stage: Node = null
var hud: CanvasLayer = null
var pause_ui: UiPause = null
var overlay: CanvasLayer = null
var _busy := false
var _booted := false
var _pending_results: Dictionary = {}
var _overlay_from_gameplay := false
var _shop_then_menu := false
var _net_game_built := false
var _net_loaded_key := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Net.start_received.connect(_on_net_start)
	Net.game_started_received.connect(_on_net_game_started)
	Net.flow_received.connect(_on_net_flow)
	Net.join_failed.connect(_on_net_join_failed)
	GameState.level_up.connect(_on_level_up)
	await get_tree().process_frame
	if not _booted:
		_booted = true
		goto("menu")

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if _level_overlay_open():
		return
	if event.is_action_pressed("pause"):
		if stage != null and is_instance_valid(stage) and overlay == null:
			toggle_pause()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and (event as InputEventKey).keycode == KEY_M and overlay == null and not _busy:
		open_travel_map()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("equipment"):
		if overlay != null and is_instance_valid(overlay):
			if _overlay_from_gameplay:
				_close_overlay()
				get_viewport().set_input_as_handled()
			return
		var blocked: bool = stage == null or not is_instance_valid(stage) or _busy
		if not blocked and pause_ui and is_instance_valid(pause_ui) and pause_ui.visible:
			blocked = true
		if not blocked and stage.has_method("try_interact"):
			if bool(stage.call("try_interact")):
				get_viewport().set_input_as_handled()
				return
		if not blocked:
			_open_loadout_overlay(true)
			get_viewport().set_input_as_handled()
	if event.is_action_pressed("skill_tree"):
		if overlay != null and is_instance_valid(overlay):
			if _overlay_from_gameplay:
				_close_overlay()
				get_viewport().set_input_as_handled()
			return
		var blocked3: bool = stage == null or not is_instance_valid(stage) or _busy
		if not blocked3 and pause_ui and is_instance_valid(pause_ui) and pause_ui.visible:
			blocked3 = true
		if not blocked3:
			_open_skill_tree(true)
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
	if screen == "game" and GameState.act2_needs_choice() and (not Net.has_peer() or Net.is_host):
		screen = "worldmap"
	_busy = true
	if screen == "menu" and Net.has_peer():
		Net.reset()
	Fx.fade_to(1.0, 3.2)
	await get_tree().create_timer(0.32, true, false, true).timeout
	clear()
	_build(screen, args)
	current_screen = screen
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
		"waves":
			var we := UiWaveEditor.new()
			current = we
			we.on_close.connect(func(): goto("menu"))
			we.on_start.connect(_on_waves_start)
		"achievements":
			current = UiAchievements.new()
		"slots":
			current = UiSlotSelect.new()
			(current as UiSlotSelect).on_start.connect(_on_slot_start)
		"lan":
			current = UiLanLobby.new()
			(current as UiLanLobby).arena = bool(args.get("arena", false))
			_arena_next = bool(args.get("arena", false))
			(current as UiLanLobby).on_close.connect(func(): goto("menu"))
			(current as UiLanLobby).on_start.connect(_on_lan_start)
		"online":
			var lobby := UiLanLobby.new()
			lobby.online = true
			current = lobby
			lobby.on_close.connect(func(): goto("menu"))
			lobby.on_start.connect(_on_lan_start)
		"creator":
			current = UiCharacterCreator.new()
			(current as UiCharacterCreator).setup(String(args.get("then", "menu")))
		"paint":
			current = UiPaintEditor.new()
			(current as UiPaintEditor).setup(args)
		"worldmap":
			var wm := UiWorldMap.new()
			current = wm
			wm.on_start.connect(func(id: String):
				GameState.begin_act2_mission(id)
				goto("game", {"stage": 0}))
			wm.on_menu.connect(func():
				GameState.finish_run(false)
				goto("menu"))
		"settings":
			current = UiSettings.new()
			(current as UiSettings).setup("menu")
			(current as UiSettings).on_close.connect(func(): goto("menu"))
		"results":
			current = UiResults.new()
			(current as UiResults).set_guest(bool(args.get("guest", false)))
			(current as UiResults).set_results(args.get("results", {}))
			(current as UiResults).victory_changed.connect(_on_victory)
			(current as UiResults).continue_pressed.connect(_on_results_continue)
			(current as UiResults).menu_pressed.connect(func():
				if not Net.is_host:
					Net.reset()
				elif bool(_pending_results.get("last_stage", false)):
					GameState.finish_run(true)
				goto("menu"))
		"gameover":
			current = UiGameOver.new()
			(current as UiGameOver).set_guest(bool(args.get("guest", false)))
			(current as UiGameOver).retry_pressed.connect(_retry)
			(current as UiGameOver).menu_pressed.connect(func():
				if not Net.is_host:
					Net.reset()
				GameState.finish_run(false)
				goto("menu"))
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
			goto("menu")

var pending_replay := -1

## Bohater zapisanej gry: ta z postaci (Lord/Lady), która ma klasę i wyższy poziom.
func pick_hero() -> Array:
	var hero := "lord"
	var best := -1
	for cid in ["lord", "lady"]:
		var cp := GameState.char_profile(cid)
		var score := int(cp.get("level", 1)) + (1000 if String(cp.get("class", "")) != "" else 0)
		if score > best:
			best = score
			hero = cid
	var cls := String(GameState.char_profile(hero).get("class", ""))
	var avail := ClassDatabase.for_character(hero)
	if cls == "" or not avail.has(cls):
		cls = String(avail[0]) if avail.size() > 0 else "wojownik"
	return [hero, cls]

## Tryb wyzwań: kolejne pojedynki z coraz silniejszymi rycerzami, wynik trafia do rankingu.
func start_challenge() -> void:
	var last := GameState.last_slot()
	if last >= 1 and GameState.slot_exists(last):
		GameState.set_slot(last)
	else:
		GameState.select_slot(1, true)
	_slot_is_new = false
	var hc := pick_hero()
	GameState.start_rpg_run("solo", String(hc[0]), "", false)
	GameState.set_class(String(hc[1]))
	GameState.rpg["challenge"] = true
	goto("game", {"stage": 0})

func _on_waves_start(config: Dictionary, hero: String) -> void:
	GameState.start_rpg_run("solo", hero, "", false)
	GameState.rpg["custom"] = config
	_slot_is_new = true
	goto("game", {"stage": 0})

func _on_rpg_start(mode: String, p1: String, p2: String, cls: String) -> void:
	GameState.start_rpg_run(mode, p1, p2, _slot_is_new)
	GameState.set_class(cls)
	if pending_replay >= 0:
		GameState.replay_chapter(pending_replay)
		pending_replay = -1
	_slot_is_new = true
	goto("loadout", {"from": "select"})

var _slot_is_new := true

## Start z ekranu wyboru slotu: wybierz slot, potem ekran trybu/klasy (rpg_select).
func _on_slot_start(slot: int, create_new: bool) -> void:
	GameState.select_slot(slot, create_new)
	_slot_is_new = create_new
	if create_new:
		goto("creator", {"then": "rpg_select"})
	else:
		goto("rpg_select")

var _arena_next := false

func _on_lan_start(p1: String, p2: String, cls: String) -> void:
	var info := Net.first_client_info()
	var cls2 := String(info.get("class", cls))
	GameState.start_rpg_run("lan", p1, p2, not _arena_next)
	if _arena_next:
		GameState.rpg["arena"] = true
	GameState.set_class_for(p1, cls)
	GameState.set_class_for(p2, cls2)
	_net_game_built = false
	goto("game", {"stage": 0})

func _on_net_start(config: Dictionary) -> void:
	if Net.is_host:
		return
	var p1 := String(config.get("p1", "lord"))
	var p2 := String(config.get("p2", "lady"))
	var cls1 := String(config.get("cls1", "wojownik"))
	var cls2 := String(config.get("cls2", cls1))
	Net.my_class = cls2
	GameState.start_rpg_run("lan", p1, p2, not bool(config.get("arena", false)))
	if bool(config.get("arena", false)):
		GameState.rpg["arena"] = true
	GameState.set_class_for(p1, cls1)
	GameState.set_class_for(p2, cls2)
	_net_game_built = false
	if not Net.pending_game_start.is_empty():
		var pending := Net.pending_game_start.duplicate(true)
		Net.pending_game_start.clear()
		_on_net_game_started(pending)
		return
	_net_enter_game()

func _on_net_game_started(config: Dictionary) -> void:
	if Net.is_host:
		return
	if not GameState.has_run() or GameState.rpg_mode_str() != "lan":
		return
	GameState.rpg["cave"] = String(config.get("cave", ""))
	if bool(config.get("arena", false)):
		GameState.rpg["arena"] = true
	var key := "%d:%s:%s:%s" % [int(config.get("chapter", 0)), String(config.get("quest", "")), String(config.get("cave", "")), str(config.get("arena", false))]
	GameState.apply_net_story(
		int(config.get("chapter", 0)),
		String(config.get("quest", "")),
		int(config.get("step", 0)),
		config.get("flags", {})
	)
	GameState.run["stage_index"] = int(config.get("stage_index", GameState.run.get("stage_index", 0)))
	if _net_game_built and current_screen == "game" and key == _net_loaded_key:
		return
	_net_game_built = false
	_net_enter_game()

func _on_net_flow(event: String, data: Dictionary) -> void:
	if Net.is_host:
		return
	while _busy:
		await get_tree().process_frame
	match event:
		"results":
			if current_screen == "results":
				return
			_pending_results = data
			goto("results", {"results": data, "guest": true})
		"gameover":
			if current_screen == "gameover":
				return
			_pending_results = data
			goto("gameover", {"guest": true})
		"menu":
			goto("menu")

func _on_net_join_failed(reason: String) -> void:
	if Net.is_host:
		return
	if current_screen not in ["game", "results", "gameover"]:
		return
	GameState.toast.emit(reason, UiKit.BAD)
	_net_lost_to_menu()

func _net_lost_to_menu() -> void:
	while _busy:
		await get_tree().process_frame
	if current_screen in ["game", "results", "gameover"]:
		goto("menu")

func _net_enter_game() -> void:
	while _busy:
		await get_tree().process_frame
	if _net_game_built and current_screen == "game":
		return
	_net_game_built = false
	Net.latest_snapshot.clear()
	await goto("game", {"stage": int(GameState.run.get("stage_index", 0))})
	_net_loaded_key = "%d:%s:%s:%s" % [GameState.story_chapter(), GameState.story_quest(), String(GameState.rpg.get("cave", "")), str(bool(GameState.rpg.get("arena", false)))]
	_net_game_built = true

func _shop_done() -> void:
	if _shop_then_menu:
		_shop_then_menu = false
		if Net.is_host:
			Net.broadcast_flow("menu")
		goto("menu")
		return
	goto("game", {"stage": int(GameState.run.get("stage_index", 0))})

# ------------------------------------------------------------------- scena ---

func _build_stage(index: int) -> void:
	var packed: PackedScene = load(VILLAGE_SCENE)
	if packed == null:
		push_error("Flow: nie znaleziono %s" % VILLAGE_SCENE)
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
	# tryb RPG (pałac, twierdze i pozostałe mapy) traktujemy jako jeden etap
	if GameState.is_topdown():
		return "krolestwo"
	var id := String(StageDB.get_stage(index)["id"])
	if Audio.THEMES.has(id):
		return id
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
		var lq := String(GameState.story().get("last_quest", ""))
		if lq != "" and not QuestDB.get_data(lq).is_empty():
			c = QuestDB.get_data(lq)
		res["stage_name"] = "%s — %s" % [String(c.get("label", "Rozdział")), String(c.get("title", "Wioska"))]
		res["story"] = true
		res["last_stage"] = GameState.story_chapter() >= QuestDB.count()
	else:
		res["stage_name"] = String(StageDB.get_stage(idx)["name"])
		res["last_stage"] = idx >= StageDB.count() - 1
		GameState.unlock_stage(idx)
		GameState.advance_stage()
	_pending_results = res
	if Net.is_host:
		Net.broadcast_flow("results", res)
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
	if Net.is_host:
		Net.broadcast_flow("gameover", res)
	await get_tree().create_timer(1.6, false).timeout
	goto("gameover")

func _on_victory(v: bool) -> void:
	if bool(_pending_results.get("last_stage", false)):
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
		var quest := GameState.story_quest() if GameState.story_quest() != "" else String(QuestDB.chapter(chap).get("id", "obrona_wioski"))
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

func _on_level_up(level: int) -> void:
	if stage == null or not is_instance_valid(stage):
		return
	if overlay != null and is_instance_valid(overlay):
		return
	var ui := UiLevelUp.new()
	ui.setup(level)
	_open_overlay(ui, true)

func _open_attributes_overlay() -> void:
	if GameState.attr_points() <= 0:
		return
	var ui := UiLevelUp.new()
	ui.setup(int(GameState.char_profile(GameState.current_character_id()).get("level", 1)))
	_open_overlay(ui, false)

func _level_overlay_open() -> bool:
	if overlay == null or not is_instance_valid(overlay) or overlay.get_child_count() == 0:
		return false
	return overlay.get_child(0) is UiLevelUp

func _show_pause() -> void:
	if pause_ui and is_instance_valid(pause_ui):
		pause_ui.refresh_attributes_button()
		pause_ui.visible = true
		pause()
		return
	pause_ui = UiPause.new()
	pause_ui.resume_pressed.connect(resume)
	pause_ui.loadout_pressed.connect(_open_loadout_overlay)
	pause_ui.attributes_pressed.connect(_open_attributes_overlay)
	pause_ui.skills_pressed.connect(func(): _open_skill_tree(false))
	pause_ui.pets_pressed.connect(func(): _open_overlay(UiPets.new(), false))
	pause_ui.settings_pressed.connect(_open_settings_overlay)
	pause_ui.restart_pressed.connect(_restart_current)
	pause_ui.map_pressed.connect(open_travel_map)
	pause_ui.stash_pressed.connect(open_stash)
	pause_ui.arena_pressed.connect(func():
		_hide_pause()
		GameState.finish_run(false)
		goto("lan", {"arena": true}))
	pause_ui.waves_pressed.connect(func():
		_hide_pause()
		GameState.finish_run(false)
		goto("waves"))
	pause_ui.host_pressed.connect(func(online: bool):
		_hide_pause()
		GameState.finish_run(false)
		goto("online" if online else "lan"))
	pause_ui.menu_pressed.connect(func():
		if Net.is_host:
			Net.broadcast_flow("menu")
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

## Mapa świata: szybka podróż do osiągniętych etapów (albo dowolnych — za zwój teleportacji).
func open_travel_map() -> void:
	if stage == null or not is_instance_valid(stage) or not GameState.is_topdown():
		return
	if Net.has_peer() or bool(GameState.rpg.get("arena", false)) or not (GameState.rpg.get("custom", {}) as Dictionary).is_empty():
		GameState.toast.emit("Mapa świata nie działa we wspólnej grze ani w trybie własnych fal.", UiKit.BAD)
		return
	var m := UiTravelMap.new()
	m.on_march.connect(start_march)
	m.on_teleport.connect(_travel_to_chapter)
	_open_overlay(m, true)

## Marsz: idziesz przez wszystkie etapy po drodze (w każdym trzeba pokonać potwory) aż do celu.
func start_march(target: int) -> void:
	_close_overlay()
	_hide_pause()
	GameState.rpg["cave"] = ""
	GameState.rpg["cave_state"] = ""
	var cur := clampi(GameState.story_chapter(), 0, QuestDB.count() - 1)
	var route := PlaceDB.route(cur, target)
	if route.is_empty():
		GameState.rpg.erase("march")
		GameState.replay_chapter(target)
	else:
		GameState.rpg["march"] = {"target": target, "route": route, "i": 0}
		GameState.replay_chapter(int(route[0]))
	goto("game", {"stage": 0})

func _travel_to_chapter(index: int) -> void:
	_close_overlay()
	_hide_pause()
	GameState.rpg.erase("march")
	GameState.rpg["cave"] = ""
	GameState.rpg["cave_state"] = ""
	GameState.replay_chapter(index)
	goto("game", {"stage": 0})

func open_stash() -> void:
	if stage == null or not is_instance_valid(stage):
		return
	_open_overlay(UiStash.new(), true)

func open_forge_overlay() -> void:
	var f := UiForge.new()
	_open_overlay(f, true)

func open_lab_overlay() -> void:
	_open_overlay(UiLab.new(), true)

func open_shop_overlay() -> void:
	var s := UiShop.new()
	_open_overlay(s, true)

func _open_skill_tree(from_gameplay := false) -> void:
	var t := UiSkillTree.new()
	_open_overlay(t, from_gameplay)

func _open_quest_log() -> void:
	var q := UiQuestLog.new()
	_open_overlay(q, true)

func _open_overlay(node: Control, from_gameplay: bool) -> void:
	if _busy:
		node.queue_free()
		return
	_hide_overlay()
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
		pause_ui.refresh_attributes_button()
		pause_ui.visible = true

func _hide_overlay() -> void:
	if overlay and is_instance_valid(overlay):
		overlay.queue_free()
	overlay = null