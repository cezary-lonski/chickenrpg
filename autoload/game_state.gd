extends Node
## GameState — zapis gry, profil postaci, stan bieżącej „rundy" (run) i mapa klawiszy.
## Ten autoload jest pierwszy w kolejności, więc reszta może się do niego odwoływać w _ready().

signal gold_changed(value: int)
signal cod_changed(value: int)
signal xp_changed(current: int, needed: int, level: int)
signal level_up(new_level: int)
signal profile_changed
signal character_changed(id: String)
signal toast(text: String, color: Color)
signal stats_changed(stats: Dictionary)

const SAVE_PATH := "user://chicken_brawl_save.json"
const SAVE_VERSION := 1
const SLOT_COUNT := 3

var profile: Dictionary = {}
var run: Dictionary = {}

# aktywny slot zapisu (1..SLOT_COUNT); 0 = jeszcze nie wybrano
var active_slot: int = 0

func slot_path(slot: int) -> String:
	return "user://chicken_brawl_save_%d.json" % slot

func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))

func slot_exists_any() -> bool:
	for i in range(1, SLOT_COUNT + 1):
		if slot_exists(i):
			return true
	return false

var game_paused: bool = false
var run_committed := false

# ---------------------------------------------------------------- wejście ---

func _ready() -> void:
	_migrate_legacy_save()
	profile = _blank_profile()
	# wczytaj ostatnio używany slot (albo pierwszy istniejący, albo slot 1)
	var last := _read_last_slot()
	if last > 0 and slot_exists(last):
		active_slot = last
	elif slot_exists(1):
		active_slot = 1
	else:
		active_slot = 1
	load_game()
	_setup_input()
	apply_binds()

func _migrate_legacy_save() -> void:
	# stary pojedynczy zapis przenieś do slotu 1 (raz)
	if FileAccess.file_exists(SAVE_PATH) and not slot_exists(1):
		var src := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if src:
			var txt := src.get_as_text()
			src.close()
			var dst := FileAccess.open(slot_path(1), FileAccess.WRITE)
			if dst:
				dst.store_string(txt)
				dst.close()
		if FileAccess.file_exists(SAVE_PATH):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

func _last_slot_file() -> String:
	return "user://chicken_brawl_last.json"

func _read_last_slot() -> int:
	if not FileAccess.file_exists(_last_slot_file()):
		return 0
	var f := FileAccess.open(_last_slot_file(), FileAccess.READ)
	if f == null:
		return 0
	var txt := f.get_as_text()
	f.close()
	return int(txt.strip_edges())

func _write_last_slot(slot: int) -> void:
	var f := FileAccess.open(_last_slot_file(), FileAccess.WRITE)
	if f:
		f.store_string(str(slot))
		f.close()

const BIND_ACTIONS := [
	"move_left", "move_right", "move_up", "move_down", "jump",
	"light_attack", "heavy_attack", "dash", "block", "throw_item",
	"special", "sprint", "pause", "equipment", "quest_log",
	"skill_1", "skill_2", "skill_3", "skill_4", "skill_5", "skill_6",
]

func default_binds() -> Dictionary:
	return {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"jump": [KEY_SPACE],
		"light_attack": [KEY_J],
		"heavy_attack": [KEY_K],
		"dash": [KEY_L],
		"block": [KEY_U],
		"throw_item": [KEY_I],
		"special": [KEY_O],
		"sprint": [KEY_SHIFT],
		"pause": [KEY_ESCAPE, KEY_P],
		"equipment": [KEY_E],
		"quest_log": [KEY_Q],
		"skill_1": [KEY_1],
		"skill_2": [KEY_2],
		"skill_3": [KEY_3],
		"skill_4": [KEY_4],
		"skill_5": [KEY_5],
		"skill_6": [KEY_6],
	}

func _setup_input() -> void:
	var binds := default_binds()
	var pad := {
		"move_left": JOY_BUTTON_DPAD_LEFT,
		"move_right": JOY_BUTTON_DPAD_RIGHT,
		"move_up": JOY_BUTTON_DPAD_UP,
		"move_down": JOY_BUTTON_DPAD_DOWN,
		"jump": JOY_BUTTON_A,
		"light_attack": JOY_BUTTON_X,
		"heavy_attack": JOY_BUTTON_Y,
		"dash": JOY_BUTTON_B,
		"block": JOY_BUTTON_LEFT_SHOULDER,
		"throw_item": JOY_BUTTON_RIGHT_SHOULDER,
		"special": JOY_BUTTON_LEFT_STICK,
		"pause": JOY_BUTTON_START,
	}
	for action in binds:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.2)
		for k in binds[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
		if pad.has(action):
			var jb := InputEventJoypadButton.new()
			jb.button_index = pad[action]
			InputMap.action_add_event(action, jb)
	var axis_map := {
		"move_left": [JOY_AXIS_LEFT_X, -1.0],
		"move_right": [JOY_AXIS_LEFT_X, 1.0],
		"move_up": [JOY_AXIS_LEFT_Y, -1.0],
		"move_down": [JOY_AXIS_LEFT_Y, 1.0],
	}
	for action in axis_map:
		var a: Array = axis_map[action]
		var ev2 := InputEventJoypadMotion.new()
		ev2.axis = a[0]
		ev2.axis_value = a[1]
		InputMap.action_add_event(action, ev2)

# ----------------------------------------------------------------- bindy ----

func _action_keys(action: String) -> Array:
	var out := []
	if InputMap.has_action(action):
		for ev in InputMap.action_get_events(action):
			if ev is InputEventKey and not ev.physical_keycode == KEY_NONE:
				out.append(ev.physical_keycode)
	return out

func apply_binds() -> void:
	var saved: Dictionary = profile.get("settings", {}).get("binds", {})
	var defs := default_binds()
	for action in BIND_ACTIONS:
		var keys: Array = Array(saved.get(action, defs.get(action, [])))
		_set_action_keys(action, keys)

func _set_action_keys(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			InputMap.action_erase_event(action, ev)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = int(k)
		InputMap.action_add_event(action, ev)

func rebind(action: String, key: int) -> void:
	_set_action_keys(action, [key])
	profile["settings"]["binds"][action] = [key]
	save_game()

func reset_binds() -> void:
	profile["settings"]["binds"] = {}
	apply_binds()
	save_game()

func key_label(action: String) -> String:
	var keys := _action_keys(action)
	if keys.is_empty():
		return "—"
	var names := []
	for k in keys:
		names.append(OS.get_keycode_string(int(k)))
	return "  ·  ".join(names)

# --------------------------------------------------------------- RPG run ---

func start_rpg_run(mode: String, p1: String, p2: String = "", fresh: bool = true) -> void:
	if mode != "lan":
		mode = "solo"
	run_committed = false
	var cp := char_profile(p1)
	if cp["backpack"].is_empty():
		cp["backpack"] = ItemDB.starter_backpack()
	run = {
		"character": p1,
		"rpg_mode": true,
		"mode": mode,
		"players": [],
		"stage_index": 0,
		"health": 0.0,
		"energy": 0.0,
		"backpack": cp["backpack"].duplicate(true),
		"buffs": {},
		"kills": 0,
		"score": 0,
		"time": 0.0,
		"gold_earned": 0,
		"damage_dealt": 0.0,
		"damage_taken": 0.0,
		"blocks": 0,
		"parries": 0,
		"max_combo": 0,
		"stages_cleared": 0,
	}
	var players: Array = []
	players.append({"id": p1, "index": 0})
	if mode == "lan" and p2 != "" and p2 != p1:
		players.append({"id": p2, "index": 1})
	run["players"] = players
	if fresh:
		start_story()
	else:
		# kontynuacja: rozdział z zapisanej fabuły; jeśli brak, zacznij od nowa
		var s := story()
		if String(s.get("quest", "")) == "":
			start_story()
		run["stage_index"] = story_chapter()
	refresh_stats()
	run["health"] = stat("max_health")
	run["energy"] = stat("max_energy")
	run["backpack"] = cp["backpack"]
	character_changed.emit(p1)
	stats_changed.emit(run["stats"])
	xp_changed.emit(int(cp["xp"]), CharacterDB.xp_for_level(int(cp["level"])), int(cp["level"]))
	save_game()

func rpg_mode() -> bool:
	return bool(run.get("rpg_mode", false))

func is_topdown() -> bool:
	return has_run() and bool(run.get("rpg_mode", false))

func rpg_mode_str() -> String:
	return String(run.get("mode", "solo"))

func rpg_players() -> Array:
	return run.get("players", [])

func skill_slots() -> Array:
	var cp := char_profile(String(run.get("character", "kurczak")))
	if not cp.has("skills") or (cp["skills"] as Array).size() != 6:
		var cls := String(cp.get("class", ""))
		cp["skills"] = ClassDatabase.default_slots(cls) if ClassDatabase.has(cls) else SkillDB.default_slots()
	return cp["skills"]

func set_class(class_id: String) -> void:
	var cp := char_profile(String(run.get("character", "kurczak")))
	cp["class"] = class_id
	cp["skills"] = ClassDatabase.default_slots(class_id) if ClassDatabase.has(class_id) else SkillDB.default_slots()
	save_game()

func char_class(id: String = "") -> String:
	var cid := id if id != "" else String(run.get("character", "kurczak"))
	return String(char_profile(cid).get("class", ""))

func set_skill_slot(i: int, id: String) -> void:
	var slots := skill_slots()
	if i < 0 or i >= slots.size():
		return
	slots[i] = id
	save_game()

# ------------------------------------------------------------------- fabuła ---

func story() -> Dictionary:
	if not profile.has("story") or typeof(profile["story"]) != TYPE_DICTIONARY:
		profile["story"] = {"chapter": 0, "quest": "", "step": 0, "flags": {}, "done": []}
	return profile["story"]

func start_story() -> void:
	profile["story"] = {"chapter": 0, "quest": "obrona_wioski", "step": 0, "flags": {}, "done": []}

func story_chapter() -> int:
	return int(story().get("chapter", 0))

func story_quest() -> String:
	return String(story().get("quest", ""))

func story_step() -> int:
	return int(story().get("step", 0))

func set_story(chapter: int, quest: String, step: int = 0) -> void:
	var s := story()
	s["chapter"] = chapter
	s["quest"] = quest
	s["step"] = step
	save_game()

func set_story_step(step: int) -> void:
	story()["step"] = step
	save_game()

func set_story_flag(key: String, value: bool = true) -> void:
	story()["flags"][key] = value
	save_game()

func story_flag(key: String) -> bool:
	return bool(story().get("flags", {}).get(key, false))

func story_done(id: String) -> bool:
	return (story().get("done", []) as Array).has(id)

func complete_quest(id: String) -> void:
	var s := story()
	var done: Array = s.get("done", [])
	if not done.has(id):
		done.append(id)
	s["done"] = done
	s["quest"] = ""
	s["step"] = 0
	save_game()

func story_active() -> bool:
	return is_topdown() and (story_quest() != "" or story_chapter() >= 0)

func active_objective() -> String:
	var q := story_quest()
	if q == "":
		return ""
	return QuestDB.objective(q, story_step())

func story_tracker() -> Dictionary:
	if not is_topdown():
		return {"visible": false, "title": "", "objective": ""}
	var q := story_quest()
	if q != "":
		var d := QuestDB.get_data(q)
		return {"visible": true, "title": "%s — %s" % [String(d.get("label", "")), String(d.get("title", ""))], "objective": QuestDB.objective(q, story_step())}
	var c := QuestDB.chapter(story_chapter())
	var obj := "W przygotowaniu" if not bool(c.get("ready", false)) else String(c.get("intro", ""))
	return {"visible": true, "title": "%s — %s" % [String(c.get("label", "")), String(c.get("title", ""))], "objective": obj}

# ----------------------------------------------------------------- profil ---

func _blank_profile() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"gold": 120,
		"cod": 0,
		"stage_unlocked": 1,
		"characters": {},
		"settings": {"music": true, "sfx": true, "shake": true, "binds": {}},
		"stats": {"kills": 0, "deaths": 0, "runs": 0, "bosses": 0, "time": 0.0},
		"seen_intro": false,
		"story": {"chapter": 0, "quest": "", "step": 0, "flags": {}, "done": []},
	}

func char_profile(id: String) -> Dictionary:
	if not profile["characters"].has(id):
		profile["characters"][id] = {
			"unlocked": String(CharacterDB.get_data(id).get("unlock", "")) == "",
			"level": 1,
			"xp": 0,
			"class": "",
			"equip": ItemDB.defaults(),
			"gear": ItemDB.defaults().values(),
			"skills": SkillDB.default_slots(),
			"backpack": {},
			"best": {},
		}
	var cp2: Dictionary = profile["characters"][id]
	# starsze zapisy nie znają ekwipunku — dosyp domyślny sprzęt i wyposażone przedmioty
	if not cp2.has("gear"):
		var g: Array = ItemDB.defaults().values()
		for it in cp2.get("equip", {}).values():
			if not g.has(it):
				g.append(it)
		cp2["gear"] = g
	return cp2

func all_characters() -> Array:
	return CharacterDB.ordered_ids()

func is_unlocked(id: String) -> bool:
	return bool(char_profile(id).get("unlocked", false))

func unlock_cost(id: String) -> int:
	return int(CharacterDB.get_data(id).get("price", 0))

func unlock_currency(id: String) -> String:
	return String(CharacterDB.get_data(id).get("unlock", ""))

func try_unlock(id: String) -> bool:
	if is_unlocked(id):
		return true
	var cp := char_profile(id)
	var cost := unlock_cost(id)
	var cur := unlock_currency(id)
	match cur:
		"cod":
			if int(profile["cod"]) < cost:
				toast.emit("Za mało piór (potrzeba %d)" % cost, Color(0.9, 0.6, 0.2))
				return false
			profile["cod"] = int(profile["cod"]) - cost
		"zlot":
			if int(profile["gold"]) < cost:
				toast.emit("Za mało złota (potrzeba %d)" % cost, Color(0.95, 0.8, 0.3))
				return false
			profile["gold"] = int(profile["gold"]) - cost
		_:
			cp["unlocked"] = true
	cp["unlocked"] = true
	save_game()
	profile_changed.emit()
	cod_changed.emit(int(profile["cod"]))
	gold_changed.emit(int(profile["gold"]))
	toast.emit("Odblokowano: %s" % CharacterDB.get_data(id)["title"], Color(0.6, 0.95, 0.5))
	return true

# --------------------------------------------------------------- ekonomia ---

func gold() -> int:
	return int(profile.get("gold", 0))

func cod() -> int:
	return int(profile.get("cod", 0))

func add_gold(v: int) -> void:
	profile["gold"] = maxi(0, gold() + v)
	gold_changed.emit(gold())
	if v > 0:
		Audio.play("coin")
	save_game()

func add_cod(v: int) -> void:
	profile["cod"] = maxi(0, cod() + v)
	cod_changed.emit(cod())
	save_game()

func can_afford(g: int, c: int = 0) -> bool:
	return gold() >= g and cod() >= c

func spend(g: int, c: int = 0) -> bool:
	if not can_afford(g, c):
		return false
	profile["gold"] = gold() - g
	profile["cod"] = cod() - c
	gold_changed.emit(gold())
	cod_changed.emit(cod())
	save_game()
	return true

# ------------------------------------------------------------- przedmioty ---

func item_count(id: String) -> int:
	if id == "":
		return 0
	if run.has("backpack") and run["backpack"].has(id):
		return int(run["backpack"][id])
	var cp := char_profile(String(run.get("character", "kurczak")))
	var bp: Dictionary = cp.get("backpack", {})
	return int(bp.get(id, 0))

func _backpack() -> Dictionary:
	if run.has("backpack"):
		return run["backpack"]
	var cp := char_profile(String(run.get("character", "kurczak")))
	if not cp.has("backpack"):
		cp["backpack"] = ItemDB.starter_backpack()
	return cp["backpack"]

func add_item(id: String, count: int = 1) -> void:
	if not ItemDB.has(id):
		return
	var bp := _backpack()
	bp[id] = int(bp.get(id, 0)) + count

func remove_item(id: String, count: int = 1) -> bool:
	if item_count(id) < count:
		return false
	var bp := _backpack()
	var left := int(bp.get(id, 0)) - count
	if left <= 0:
		bp.erase(id)
	else:
		bp[id] = left
	return true

func consumed_ids() -> Array:
	var out := []
	for id in _backpack():
		if ItemDB.is_consumable(id) or ItemDB.is_throwable(id):
			out.append(id)
	out.sort()
	return out

func equip_item(id: String) -> bool:
	var d := ItemDB.get_data(id)
	var slot := String(d.get("slot", ""))
	if slot == "" or not SLOT_ORDER_SLOTS.has(slot):
		toast.emit("Tego nie da się włożyć na siebie.", Color(0.8, 0.8, 0.8))
		return false
	if not owns_gear(id):
		toast.emit("Nie masz tego w ekwipunku.", Color(0.9, 0.6, 0.3))
		return false
	var cp := char_profile(String(run.get("character", "kurczak")))
	var old := String(cp["equip"].get(slot, ""))
	var gained := _sum_stats(ItemDB.stats_of(old))
	var cost := _sum_stats(ItemDB.stats_of(id))
	var after_hp := float(run.get("health", 100.0)) - float(gained.get("health", 0.0)) + float(cost.get("health", 0.0))
	cp["equip"][slot] = id
	refresh_stats()
	run_set("health", clampf(after_hp, 1.0, stat("max_health")))
	toast.emit("Założono: %s" % d["name"], Color(0.8, 0.9, 1.0))
	Audio.play("equip")
	save_game()
	return true

const SLOT_ORDER_SLOTS := ["weapon", "armor", "accessory"]

func equipped() -> Dictionary:
	var cp := char_profile(String(run.get("character", "kurczak")))
	var e: Dictionary = cp.get("equip", {})
	for s in SLOT_ORDER_SLOTS:
		if not e.has(s) or not ItemDB.has(String(e[s])):
			e[s] = ItemDB.defaults()[s]
	return e

## Sprzęt (broń/pancerz/akcesoria) należący do postaci. Tylko ten można założyć.
func owned_gear() -> Array:
	var cp := char_profile(String(run.get("character", "kurczak")))
	if not cp.has("gear"):
		cp["gear"] = ItemDB.defaults().values()
	return cp["gear"]

func owns_gear(id: String) -> bool:
	return owned_gear().has(id)

## Dodaje sprzęt do ekwipunku postaci. Zwraca false, jeśli już go miała.
func add_gear(id: String) -> bool:
	if not ItemDB.has(id) or String(ItemDB.get_data(id).get("slot", "")) in ["consumable", "throwable"]:
		return false
	var g := owned_gear()
	if g.has(id):
		return false
	g.append(id)
	profile_changed.emit()
	save_game()
	return true

func owned_gear_of_slot(slot: String) -> Array:
	var out: Array = []
	for id in owned_gear():
		if String(ItemDB.get_data(id).get("slot", "")) == slot:
			out.append(id)
	out.sort_custom(func(a, b): return int(ItemDB.get_data(a).get("tier", 0)) < int(ItemDB.get_data(b).get("tier", 0)))
	return out

# ------------------------------------------------------------------ staty ---

func _sum_stats(d: Dictionary) -> Dictionary:
	var out := {
		"health": 0.0, "energy": 0.0, "strength": 0.0, "defense": 0.0,
		"speed": 0.0, "crit": 0.0, "fury": 0.0, "luck": 0.0, "poise": 0.0, "throw_power": 0.0,
	}
	for k in out:
		if d.has(k):
			out[k] = float(d[k])
	return out

func compute_stats() -> Dictionary:
	var id := String(run.get("character", "kurczak"))
	var cdata := CharacterDB.get_data(id)
	var cp := char_profile(id)
	var lvl := int(cp.get("level", 1))
	var base: Dictionary = cdata["base"]
	var gains: Dictionary = cdata["gains"]
	var s := {
		"max_health": float(base["health"]) + float(gains["health"]) * float(lvl - 1),
		"max_energy": (float(base["energy"]) + float(gains["energy"]) * float(lvl - 1)) * 1.7,
		"strength": 1.0 + float(gains["strength"]) * float(lvl - 1),
		"defense": 1.0 + float(gains["defense"]) * float(lvl - 1),
		"speed": float(base["speed"]) + float(gains["speed"]) * float(lvl - 1),
		"crit": float(base["crit"]),
		"fury_rate": float(base["fury"]),
		"luck": 1.0,
		"poise": 0.0,
		"throw_power": 1.0,
	}
	var eq := equipped()
	for slot in eq:
		_add_into(s, ItemDB.stats_of(String(eq[slot])))
	for k in run.get("buffs", {}):
		var b: Dictionary = run["buffs"][k]
		if float(b.get("time", 0.0)) > 0.0 and s.has(k):
			s[k] = float(s[k]) + float(b.get("value", 0.0))
	return s

func _add_into(s: Dictionary, d: Dictionary) -> void:
	for k in d:
		if s.has(k):
			s[k] = float(s[k]) + float(d[k])
		else:
			s[k] = float(d[k])

func refresh_stats() -> void:
	var new_stats := compute_stats()
	if not has_run():
		return
	var old_max := float(run.get("stats", {}).get("max_health", 100.0))
	run["stats"] = new_stats
	if run.has("health"):
		run["health"] = clampf(float(run["health"]), 0.0, float(new_stats["max_health"]))
	run["max_health_prev"] = old_max
	stats_changed.emit(new_stats)

func stat(key: String) -> float:
	if not has_run() or not run.has("stats"):
		return 0.0
	return float(run["stats"].get(key, 0.0))

# -------------------------------------------------------------------- run ---

func start_run(char_id: String, stage_index: int = 0) -> void:
	run_committed = false
	var cp := char_profile(char_id)
	if cp["backpack"].is_empty():
		cp["backpack"] = ItemDB.starter_backpack()
	run = {
		"character": char_id,
		"stage_index": stage_index,
		"health": 0.0,
		"energy": 0.0,
		"backpack": cp["backpack"].duplicate(true),
		"buffs": {},
		"kills": 0,
		"score": 0,
		"time": 0.0,
		"gold_earned": 0,
		"damage_dealt": 0.0,
		"damage_taken": 0.0,
		"blocks": 0,
		"parries": 0,
		"max_combo": 0,
		"stages_cleared": 0,
	}
	refresh_stats()
	run["health"] = stat("max_health")
	run["energy"] = stat("max_energy")
	# plecak należy do profilu, więc po każdej zmianie przepisujemy referencję
	run["backpack"] = cp["backpack"]
	character_changed.emit(char_id)
	stats_changed.emit(run["stats"])
	xp_changed.emit(int(cp["xp"]), CharacterDB.xp_for_level(int(cp["level"])), int(cp["level"]))
	save_game()

func has_run() -> bool:
	return run.has("character")

## zapis do run tylko wtedy, gdy trwa runda (zabezpieczenie przed zapisem w menu)
func run_set(key: String, value: Variant) -> void:
	if not has_run():
		return
	run[key] = value

func run_add(key: String, amount: Variant) -> void:
	if not has_run():
		return
	var cur: Variant = run.get(key, 0)
	if cur is float or cur is int:
		run[key] = cur + amount
	else:
		run[key] = amount

func commit_backpack() -> void:
	if not has_run():
		return
	char_profile(String(run["character"]))["backpack"] = run.get("backpack", {})

func advance_stage() -> void:
	if not has_run():
		return
	run["stage_index"] = int(run["stage_index"]) + 1
	run["kills"] = 0
	run["score"] = 0
	var st := StageDB.get_stage(int(run["stage_index"]))
	var reward: Dictionary = st.get("reward", {})
	var g := int(reward.get("gold", 0))
	if g > 0:
		run["gold_earned"] = int(run.get("gold_earned", 0)) + g
		add_gold(g)
	# odpoczynek między etapami
	run["health"] = clampf(float(run["health"]) + stat("max_health") * 0.35, 1.0, stat("max_health"))
	run["energy"] = stat("max_energy")
	run["buffs"] = {}
	refresh_stats()
	save_game()

func add_xp(amount: int) -> void:
	if not has_run():
		return
	run["score"] = int(run.get("score", 0)) + amount
	var cp := char_profile(String(run["character"]))
	var xp := int(cp.get("xp", 0)) + amount
	var lvl := int(cp.get("level", 1))
	var leveled := false
	while xp >= CharacterDB.xp_for_level(lvl) and lvl < 60:
		xp -= CharacterDB.xp_for_level(lvl)
		lvl += 1
		leveled = true
	cp["xp"] = xp
	cp["level"] = lvl
	if leveled:
		refresh_stats()
		run["health"] = stat("max_health")
		run["energy"] = stat("max_energy")
		level_up.emit(lvl)
		Audio.play("levelup")
		toast.emit("POZIOM %d!" % lvl, Color(1.0, 0.85, 0.3))
	xp_changed.emit(xp, CharacterDB.xp_for_level(lvl), lvl)
	save_game()

func finish_run(victory: bool) -> void:
	if not has_run() or run_committed:
		return
	var cp := char_profile(String(run["character"]))
	commit_backpack()
	profile["stats"]["runs"] = int(profile["stats"]["runs"]) + 1
	profile["stats"]["kills"] = int(profile["stats"]["kills"]) + int(run.get("kills", 0))
	profile["stats"]["time"] = float(profile["stats"]["time"]) + float(run.get("time", 0.0))
	if not victory:
		profile["stats"]["deaths"] = int(profile["stats"]["deaths"]) + 1
		# śmierć zabiera połowę zdobytego w tym runie złota
		var earned := int(run.get("gold_earned", 0))
		var keep := int(floor(float(earned) * 0.5))
		add_gold(-int(earned - keep))
		run["gold_earned"] = keep
	var si := int(run.get("stage_index", 0))
	var best: Dictionary = cp.get("best", {})
	var score := int(run.get("score", 0))
	if score > int(best.get(str(si), 0)):
		best[str(si)] = score
	cp["best"] = best
	run_committed = true
	save_game()

func last_results() -> Dictionary:
	return {
		"score": int(run.get("score", 0)),
		"kills": int(run.get("kills", 0)),
		"time": float(run.get("time", 0.0)),
		"gold": int(run.get("gold_earned", 0)),
		"damage_dealt": float(run.get("damage_dealt", 0.0)),
		"damage_taken": float(run.get("damage_taken", 0.0)),
		"blocks": int(run.get("blocks", 0)),
		"parries": int(run.get("parries", 0)),
		"max_combo": int(run.get("max_combo", 0)),
		"victory": false,
	}

# ------------------------------------------------------------- zapis/odczyt ---

func has_save() -> bool:
	return active_slot > 0 and slot_exists(active_slot)

func save_game() -> void:
	if active_slot <= 0:
		active_slot = 1
	var f := FileAccess.open(slot_path(active_slot), FileAccess.WRITE)
	if f == null:
		push_warning("Nie udało się zapisać gry: %s" % error_string(FileAccess.get_open_error()))
		return
	commit_backpack()
	profile["version"] = SAVE_VERSION
	f.store_string(JSON.stringify(profile, "\t"))
	f.close()
	_write_last_slot(active_slot)

func load_game() -> void:
	if not (active_slot > 0 and slot_exists(active_slot)):
		profile = _blank_profile()
		profile_changed.emit()
		return
	var f := FileAccess.open(slot_path(active_slot), FileAccess.READ)
	if f == null:
		profile = _blank_profile()
		return
	var txt := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Uszkodzony zapis — zaczynam od nowa.")
		profile = _blank_profile()
		return
	profile = _merge_defaults(parsed as Dictionary, _blank_profile())
	profile_changed.emit()
	gold_changed.emit(gold())
	cod_changed.emit(cod())

## Przełącz na slot: wczytuje jego zawartość (albo tworzy nowy, czysty profil).
func select_slot(slot: int, create_new: bool = false) -> void:
	slot = clampi(slot, 1, SLOT_COUNT)
	active_slot = slot
	run = {}
	run_committed = false
	if create_new:
		profile = _blank_profile()
		profile_changed.emit()
		save_game()
		return
	load_game()

## Kasuje zawartość slotu (jeśli istnieje).
func delete_slot(slot: int) -> void:
	if slot_exists(slot):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path(slot)))
	if active_slot == slot:
		profile = _blank_profile()
		run = {}
		profile_changed.emit()

## Krótki opis slotu do ekranu wyboru.
func slot_info(slot: int) -> Dictionary:
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		return {"exists": false}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {"exists": false}
	var txt := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"exists": true, "broken": true}
	var p := parsed as Dictionary
	var chars: Dictionary = p.get("characters", {})
	var story: Dictionary = p.get("story", {})
	var cp: Dictionary = chars.get("lord", {})
	var chap := int(story.get("chapter", 0))
	return {
		"exists": true,
		"gold": int(p.get("gold", 0)),
		"level": int(cp.get("level", 1)),
		"chapter": chap,
		"done": (story.get("done", []) as Array).size(),
	}

func _merge_defaults(src: Dictionary, def: Dictionary) -> Dictionary:
	var out := def.duplicate(true)
	for k in src:
		if typeof(src[k]) == TYPE_NIL:
			continue
		if typeof(out.get(k)) == TYPE_DICTIONARY and typeof(src[k]) == TYPE_DICTIONARY:
			out[k] = _merge_defaults(src[k], out[k])
		else:
			out[k] = src[k]
	return out

func reset_save() -> void:
	profile = _blank_profile()
	run = {}
	if active_slot > 0 and FileAccess.file_exists(slot_path(active_slot)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path(active_slot)))
	save_game()
	profile_changed.emit()
	gold_changed.emit(0)
	cod_changed.emit(0)

func stage_unlocked() -> int:
	return int(profile.get("stage_unlocked", 1))

func unlock_stage(i: int) -> void:
	if i + 1 > stage_unlocked():
		profile["stage_unlocked"] = mini(i + 1, StageDB.count())
		save_game()

func setting(key: String) -> bool:
	return bool(profile.get("settings", {}).get(key, true))

func toggle_setting(key: String) -> bool:
	profile["settings"][key] = not setting(key)
	save_game()
	return bool(profile["settings"][key])
