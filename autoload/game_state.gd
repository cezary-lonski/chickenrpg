extends Node
## GameState — zapis gry, profil postaci, stan bieżącej „rundy" (run) i mapa klawiszy.

signal gold_changed(value: int)
signal cod_changed(value: int)
signal xp_changed(current: int, needed: int, level: int)
signal level_up(new_level: int)
signal profile_changed
signal character_changed(id: String)
signal toast(text: String, color: Color)
signal stats_changed(stats: Dictionary)

const SAVE_PATH := "user://chicken_brawl_save.json"
const SAVE_VERSION := 9
const SLOT_COUNT := 3
const ATTR_POINTS_PER_LEVEL := 5
const MAX_LEVEL := 100
const ATTR_ORDER := ["strength", "health", "energy", "defense", "speed", "luck"]
const ATTRS := {
	"strength": {"name": "Siła", "per": 0.01, "desc": "+1% obrażeń za punkt"},
	"health": {"name": "Życie", "per": 3.0, "desc": "+3 maks. HP za punkt"},
	"energy": {"name": "Energia", "per": 3.0, "desc": "+3 maks. energii za punkt"},
	"defense": {"name": "Obrona", "per": 0.01, "desc": "+1% obrony za punkt"},
	"speed": {"name": "Szybkość", "per": 0.003, "desc": "+0,3% szybkości za punkt"},
	"luck": {"name": "Szczęście", "per": 0.01, "desc": "+1% szans / lepsze dropy za punkt"},
}

var profile: Dictionary = {}
var run: Dictionary = {}
var active_slot: int = 1
var game_paused: bool = false
var run_committed: bool = false
var skill_points_total: int = 0
var skill_points_spent: int = 0
var rpg: Dictionary = {}
var _last_char := "kurczak"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if profile.is_empty():
		profile = _blank_profile()
	_ensure_all()
	_register_default_actions()
	_apply_binds()

func _blank_profile() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"gold": 120,
		"cod": 0,
		"zlot": 0,
		"unlocks": {"cod": 0, "zlot": 0},
		"stage_unlocked": 1,
		"characters": {},
		"settings": {"music": true, "sfx": true, "shake": true, "binds": {}, "mouse_binds": {}, "volume": 1.0, "fullscreen": false},
		"stats": {"kills": 0, "deaths": 0, "runs": 0, "bosses": 0, "time": 0.0},
		"seen_intro": false,
		"story": {"chapter": 0, "quest": "", "step": 0, "flags": {}, "done": []},
		"appearance": CosmeticDB.blank_appearance(),
		"seen_creator": false,
		"customization": {"layers": {}, "colors": {}},
		"skill_tree": {"unlocked": [], "spent": 0, "points": 0},
		"inventory": {"slots": [], "hotbar": [], "equip": {"weapon": "", "armor": "", "helmet": "", "boots": "", "gloves": "", "ring1": "", "ring2": "", "amulet": "", "cape": ""}, "amulets": []},
		"pets": {"unlocked": ["kurczaczek"], "equipped": "kurczaczek", "gear": {}, "xp": {}},
		"craft": {"materials": {"kurczal": 0, "kurczalium": 0}, "recipes": [], "known": []},
		"paint_anims": {},
		"secrets": {"found": [], "chests": []},
		"bosses": {"killed": []},
		"act": 1,
		"forging": {"progress": 0},
		"legendary_found": [],
		"quests": {"active": [], "done": [], "claimed": []},
		"campaign": {"chapter": 1, "completed": []},
	}

func _ensure_all() -> void:
	var blank := _blank_profile()
	_merge_into(profile, blank)

func _merge_into(dst: Dictionary, src: Dictionary) -> void:
	for k in src.keys():
		if not dst.has(k):
			dst[k] = src[k].duplicate(true) if (src[k] is Dictionary or src[k] is Array) else src[k]
		elif dst[k] is Dictionary and src[k] is Dictionary:
			_merge_into(dst[k], src[k])

func blank_attrs() -> Dictionary:
	var d := {}
	for k in ATTR_ORDER: d[k] = 0
	return d

func char_profile(id: String) -> Dictionary:
	if not profile.has("characters"): profile["characters"] = {}
	if not profile["characters"].has(id):
		profile["characters"][id] = {
			"unlocked": String(CharacterDB.get_data(id).get("unlock", "")) == "",
			"level": 1, "xp": 0, "class": "", "equip": ItemDB.defaults(), "gear": [],
			"skills": SkillDB.default_slots(), "backpack": {}, "best": {}, "attr_points": 0, "attrs": blank_attrs(),
			"skill_points": 0
		}
	var cp := profile["characters"][id] as Dictionary
	if not cp.has("attrs"): cp["attrs"] = blank_attrs()
	if not cp.has("skill_points"): cp["skill_points"] = 0
	if not (cp.get("equip") is Dictionary): cp["equip"] = ItemDB.defaults()
	if not (cp.get("gear") is Array): cp["gear"] = []
	if not (cp.get("skills") is Array): cp["skills"] = SkillDB.default_slots()
	if not (cp.get("backpack") is Dictionary): cp["backpack"] = {}
	if not (cp.get("inv") is Array):
		# stary zapis / nowa postać: zbuduj 40 slotów z plecaka i listy sprzętu
		_migrate_inventory(cp)
	return cp

func gold() -> int: return int(profile.get("gold", 0))
func cod() -> int: return int(profile.get("cod", 0))
func zlot() -> int: return int(profile.get("zlot", 0))

func add_gold(v: int) -> void:
	profile["gold"] = gold() + v
	gold_changed.emit(gold())
	save_game()

func add_cod(v: int) -> void:
	profile["cod"] = cod() + v
	cod_changed.emit(cod())
	save_game()

func slot_path(slot: int) -> String:
	return "user://chicken_brawl_save_%d.json" % slot

func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))

func slot_exists_any() -> bool:
	for i in range(1, SLOT_COUNT+1):
		if slot_exists(i): return true
	return false

func set_slot(slot: int) -> void:
	active_slot = clampi(slot, 1, SLOT_COUNT)
	load_game()

func load_game() -> void:
	var path := slot_path(active_slot)
	if not FileAccess.file_exists(path):
		profile = _blank_profile()
		profile_changed.emit()
		return
	var f := FileAccess.open(path, FileAccess.READ)
	var parsed = null
	if f:
		parsed = JSON.parse_string(f.get_as_text())
		f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		# uszkodzony zapis: nie przenoś profilu poprzedniego slotu
		push_warning("Uszkodzony zapis: %s" % path)
		profile = _blank_profile()
		profile_changed.emit()
		return
	profile = parsed as Dictionary
	_ensure_all()
	if int(profile.get("version", 0)) < SAVE_VERSION:
		_migrate()
	_apply_binds()
	profile_changed.emit()
	gold_changed.emit(gold())
	cod_changed.emit(cod())

func save_game() -> void:
	if profile.is_empty(): return
	profile["version"] = SAVE_VERSION
	var path := slot_path(active_slot)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if not f: return
	f.store_string(JSON.stringify(profile))
	f.close()
	var lf := FileAccess.open("user://chicken_brawl_last.json", FileAccess.WRITE)
	if lf: lf.store_string(str(active_slot)); lf.close()

func _migrate() -> void:
	var old_version := int(profile.get("version", 0))
	_ensure_all()
	# v7: między rozdziałem VII a VIII wstawiono Akt II (misje wiosek). Zapisy, które
	# przeszły Akt I, zaczynają od mapy świata; ukończone rozdziały zachowują flagę "done".
	if old_version < 7:
		var st: Dictionary = story()
		if not bool(st.get("act2_shift", false)):
			st["act2_shift"] = true
			if int(st.get("chapter", 0)) >= 7:
				st["chapter"] = QuestDB.act_start(2)
				st["quest"] = ""
				st["step"] = 0
	# v8: w Akcie I dodano pałac (6 pięter), naradę, lochy, Miasto i Zamek Kruka — indeksy rozdziałów się przesunęły.
	if old_version < 8:
		var st8: Dictionary = story()
		for key in ["chapter", "best"]:
			if st8.has(key):
				st8[key] = _chapter_v8(int(st8[key]))
	# v9: dodano piętra twierdzy (2) po „Marszu na twierdzę” i piętra zamku (3) po Mieście Kruka.
	if old_version < 9:
		var st9: Dictionary = story()
		for key9 in ["chapter", "best"]:
			if st9.has(key9):
				st9[key9] = _chapter_v9(int(st9[key9]))
	profile["version"] = SAVE_VERSION
	save_game()

## Indeks rozdziału z wersji 8 → nowy (po wstawieniu pięter twierdzy i zamku).
func _chapter_v9(old: int) -> int:
	if old <= 12:
		return old
	if old == 13:
		return old + 2   # Miasto Kruka
	return old + 5

## Stary indeks rozdziału (do v7) → nowy.
func _chapter_v8(old: int) -> int:
	var map := {3: "uwolnij_krolowa", 4: "trojka_prob", 5: "marsz_na_forteca", 6: "krol_i_kruk"}
	if map.has(old):
		return maxi(0, QuestDB.index_of(String(map[old])))
	if old >= 7:
		return old + 9
	return old

func _apply_binds() -> void:
	var b: Dictionary = profile.get("settings", {}).get("binds", {})
	for action in b.keys():
		var arr: Array = b[action]
		if arr.is_empty(): continue
		_set_keys(action, arr)
	var mb: Dictionary = profile.get("settings", {}).get("mouse_binds", {})
	for action in mb.keys():
		if b.has(action) and not (b[action] as Array).is_empty():
			continue   # stary zapis z dwoma przypisaniami: zostaje klawisz
		var arr: Array = mb[action]
		if arr.is_empty(): continue
		_set_mouse(action, arr)

func _set_keys(action: String, keys: Array) -> void:
	if not InputMap.has_action(action): InputMap.add_action(action)
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey: InputMap.action_erase_event(action, ev)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = int(k)
		InputMap.action_add_event(action, ev)

func _set_mouse(action: String, buttons: Array) -> void:
	if not InputMap.has_action(action): InputMap.add_action(action)
	for ev in InputMap.action_get_events(action):
		if ev is InputEventMouseButton: InputMap.action_erase_event(action, ev)
	for b in buttons:
		var ev := InputEventMouseButton.new()
		ev.button_index = int(b)
		InputMap.action_add_event(action, ev)

func rebind(action: String, key: int) -> void:
	# jedna czynność = jeden przycisk: przypisanie klawisza zdejmuje mysz
	_set_keys(action, [key])
	_set_mouse(action, [])
	if profile.has("settings") and (profile["settings"] as Dictionary).has("mouse_binds"):
		(profile["settings"]["mouse_binds"] as Dictionary).erase(action)
	if not profile.has("settings"): profile["settings"] = {}
	if not profile["settings"].has("binds"): profile["settings"]["binds"] = {}
	profile["settings"]["binds"][action] = [key]
	save_game()

func rebind_mouse(action: String, button: int) -> void:
	# jedna czynność = jeden przycisk: przypisanie myszy zdejmuje klawisz
	_set_keys(action, [])
	_set_mouse(action, [button])
	if not profile.has("settings"): profile["settings"] = {}
	if not profile["settings"].has("mouse_binds"): profile["settings"]["mouse_binds"] = {}
	if profile["settings"].has("binds"): (profile["settings"]["binds"] as Dictionary).erase(action)
	profile["settings"]["mouse_binds"][action] = [button]
	save_game()

func reset_binds() -> void:
	if profile.has("settings"):
		profile["settings"]["binds"] = {}
		profile["settings"]["mouse_binds"] = {}
	save_game()
	for action in DEFAULT_KEYS:
		_set_mouse(action, [])
	_register_default_actions()

func is_topdown() -> bool:
	return bool(rpg.get("active", false))

func xp_for_level(lv: int) -> int:
	return CharacterDB.xp_for_level(maxi(1, lv))

func grant_xp(v: int) -> void:
	if v <= 0: return
	if run.is_empty(): return
	v = int(round(float(v) * (1.0 + stat("xp_mult"))))
	var cid := String(run.get("character", ""))
	if cid == "": return
	var cp := char_profile(cid)
	_tree()
	if int(cp.get("level", 1)) >= MAX_LEVEL:
		return
	var xp := int(cp.get("xp", 0)) + v
	var lvl := int(cp.get("level", 1))
	var start_lvl := lvl
	while xp >= xp_for_level(lvl) and lvl < MAX_LEVEL:
		xp -= xp_for_level(lvl)
		lvl += 1
		lvl = mini(lvl, MAX_LEVEL)
	if lvl >= MAX_LEVEL:
		xp = 0
	cp["xp"] = xp
	cp["level"] = lvl
	if lvl > start_lvl:
		var gained := lvl - start_lvl
		cp["attr_points"] = int(cp.get("attr_points", 0)) + gained * ATTR_POINTS_PER_LEVEL
		cp["skill_points"] = int(cp.get("skill_points", 0)) + gained
		skill_points_total += gained
		refresh_stats()
		if run.has("health"): run["health"] = stat("max_health")
		if run.has("energy"): run["energy"] = stat("max_energy")
		level_up.emit(lvl)
		Audio.play("levelup")
		toast.emit("POZIOM %d! +%d PKT UMIEJĘTNOŚCI" % [lvl, gained], Color(1.0, 0.85, 0.3))
	xp_changed.emit(xp, xp_for_level(mini(lvl, MAX_LEVEL)), lvl)
	save_game()

func refresh_stats() -> void:
	if run.is_empty(): return
	if String(run.get("character", "")) == "": return
	run["stats"] = compute_stats()
	stats_changed.emit(run["stats"])

## Statystyki bohatera: baza + poziom + ekwipunek + atrybuty (bez chwilowych buffów).
func compute_stats() -> Dictionary:
	var cid := current_character_id()
	var cd := CharacterDB.get_data(cid)
	var cp := char_profile(cid)
	var base: Dictionary = cd.get("base", {})
	var gains: Dictionary = cd.get("gains", {})
	var lv := float(int(cp.get("level", 1)) - 1)
	var s := {
		"max_health": float(base.get("health", 120.0)) + float(gains.get("health", 0.0)) * lv,
		"max_energy": float(base.get("energy", 100.0)) + float(gains.get("energy", 0.0)) * lv,
		"strength": 1.0 + float(gains.get("strength", 0.0)) * lv,
		"defense": 1.0 + float(gains.get("defense", 0.0)) * lv,
		"speed": float(base.get("speed", 1.0)) + float(gains.get("speed", 0.0)) * lv,
		"crit": float(base.get("crit", 0.06)),
		"fury_rate": float(base.get("fury", 1.0)),
		"luck": 1.0, "throw_power": 1.0, "poise": 0.0,
		"regen": 0.0, "lifesteal": 0.0, "dmg_reduction": 0.0, "xp_mult": 0.0, "gold_mult": 0.0,
	}
	var eq: Dictionary = cp.get("equip", {})
	var eqq: Dictionary = cp.get("equip_q", {})
	for slot in eq:
		var iid := String(eq[slot])
		var emeta: Dictionary = cp.get("equip_m", {}).get(slot, {})
		var qm := float(eqq.get(slot, 1.0)) * ItemDB.meta_mult(iid, emeta)
		var st := ItemDB.stats_of(iid)
		for k in st:
			var key := String(k)
			if key == "health": key = "max_health"
			elif key == "energy": key = "max_energy"
			elif key == "fury": key = "fury_rate"
			s[key] = float(s.get(key, 0.0)) + float(st[k]) * qm
		var fx := ItemDB.fx_of(iid)
		for k in fx:
			s[String(k)] = float(s.get(String(k), 0.0)) + float(fx[k])
		for k in emeta.get("fx", {}):
			s[String(k)] = float(s.get(String(k), 0.0)) + float(emeta["fx"][k])
	var attrs: Dictionary = cp.get("attrs", {})
	for k in ATTR_ORDER:
		var key2 := String(k)
		if key2 == "health": key2 = "max_health"
		elif key2 == "energy": key2 = "max_energy"
		s[key2] = float(s.get(key2, 0.0)) + attr_bonus(String(k))
	return s

const _STAT_DEFAULTS := {"strength": 1.0, "defense": 1.0, "speed": 1.0, "crit": 0.06, "fury_rate": 1.0, "luck": 1.0, "throw_power": 1.0}

func stat(key: String) -> float:
	var s: Dictionary = run.get("stats", {})
	var v := float(s.get(key, _STAT_DEFAULTS.get(key, 0.0)))
	var buffs: Dictionary = run.get("buffs", {})
	if buffs.has(key):
		v += float((buffs[key] as Dictionary).get("value", 0.0))
	return v

func select_char(id: String, stage_index: int = 0) -> void:
	if not profile.has("characters"): profile["characters"] = {}
	var cp := char_profile(id)
	cp["unlocked"] = true
	run_committed = false
	if not bool(cp.get("bag_init", false)):
		if inv_free_slots_of(cp) == INV_SIZE:
			var sb := ItemDB.starter_backpack()
			for sid in sb:
				_insert(cp, String(sid), int(sb[sid]), 1.0)
		cp["bag_init"] = true
	run = {
		"character": id, "stage_index": stage_index, "health": 0.0, "energy": 0.0,
		"buffs": {}, "kills": 0, "score": 0, "time": 0.0,
		"gold_earned": 0, "damage_dealt": 0.0, "damage_taken": 0.0, "blocks": 0, "parries": 0, "max_combo": 0, "stages_cleared": 0
	}
	refresh_stats()
	run["health"] = stat("max_health")
	run["energy"] = stat("max_energy")
	character_changed.emit(id)
	stats_changed.emit(run["stats"])
	var cpl := char_profile(id)
	xp_changed.emit(int(cpl.get("xp",0)), xp_for_level(int(cpl.get("level",1))), int(cpl.get("level",1)))
	save_game()

func has_run() -> bool: return run.has("character")
func run_set(key: String, val) -> void: if has_run(): run[key] = val
func run_get(key: String, def = null): return run.get(key, def)
func get_profile() -> Dictionary: return profile
func get_run() -> Dictionary: return run
func mark_run_committed() -> void: run_committed = true
func is_run_committed() -> bool: return run_committed
func spend_attr(key: String) -> bool:
	if not has_run(): return false
	var cid := String(run["character"])
	var cp := char_profile(cid)
	var pts := int(cp.get("attr_points", 0))
	if pts <= 0: return false
	if key not in ATTR_ORDER: return false
	var a: Dictionary = cp.get("attrs", blank_attrs())
	a[key] = int(a.get(key,0)) + 1
	cp["attrs"] = a
	cp["attr_points"] = pts - 1
	refresh_stats()
	save_game()
	return true

func has_class(cid: String) -> bool:
	var cp := char_profile(cid)
	return bool(cp.get("unlocked", false))

func unlock_class(cid: String) -> void:
	var cp := char_profile(cid)
	cp["unlocked"] = true
	save_game()

func can_buy_class(cid: String) -> bool:
	var d := CharacterDB.get_data(cid)
	var unlock := String(d.get("unlock",""))
	var price := int(d.get("price",0))
	if unlock == "": return true
	if unlock == "gold": return gold() >= price
	if unlock == "cod": return cod() >= price
	return true

func buy_class(cid: String) -> bool:
	if has_class(cid): return true
	var d := CharacterDB.get_data(cid)
	var unlock := String(d.get("unlock",""))
	var price := int(d.get("price",0))
	if unlock == "gold":
		if gold() < price: return false
		profile["gold"] = gold() - price
		gold_changed.emit(gold())
	elif unlock == "cod":
		if cod() < price: return false
		profile["cod"] = cod() - price
		cod_changed.emit(cod())
	unlock_class(cid)
	save_game()
	return true

func is_music() -> bool: return bool(profile.get("settings",{}).get("music", true))
func is_sfx() -> bool: return bool(profile.get("settings",{}).get("sfx", true))
func is_shake() -> bool: return bool(profile.get("settings",{}).get("shake", true))
func toggle_music() -> void: profile["settings"]["music"] = not is_music(); save_game()
func toggle_sfx() -> void: profile["settings"]["sfx"] = not is_sfx(); save_game()
func toggle_shake() -> void: profile["settings"]["shake"] = not is_shake(); save_game()
func volume() -> float: return float(profile.get("settings",{}).get("volume",1.0))
func set_volume(v: float) -> void: profile["settings"]["volume"] = clampf(v,0.0,1.0); save_game()

# --------------------------------------------------------------------- run ---

func inv_free_slots_of(cp: Dictionary) -> int:
	var n := 0
	for e in cp.get("inv", []):
		if e == null: n += 1
	return n

func current_character_id() -> String:
	return String(run.get("character", _last_char))

func run_add(key: String, amount) -> void:
	if has_run():
		run[key] = run.get(key, 0) + amount

func add_xp(v: int) -> void:
	grant_xp(v)

func start_run(id: String, stage_index: int = 0) -> void:
	rpg = {}
	select_char(id, stage_index)

## Start kampanii RPG. `new_game` zeruje fabułę (nowy zapis); kontynuacja ją zachowuje.
func start_rpg_run(mode: String, p1: String, p2: String = "", new_game: bool = true) -> void:
	var players: Array = [{"id": p1}]
	if p2 != "":
		players.append({"id": p2})
	rpg = {"active": true, "mode": mode, "players": players}
	if mode == "lan":
		# fabuła wspólnej gry jest tymczasowa — własny postęp wraca po wyjściu
		rpg["own_story"] = story().duplicate(true)
	if new_game:
		profile["story"] = _blank_profile()["story"]
	select_char(p1, 0)
	if p2 != "":
		char_profile(p2)["unlocked"] = true
	save_game()

func rpg_mode_str() -> String:
	return String(rpg.get("mode", "solo"))

func rpg_players() -> Array:
	return rpg.get("players", [])

func set_class(cls: String) -> void:
	set_class_for(current_character_id(), cls)

func set_class_for(char_id: String, cls: String) -> void:
	if cls == "" or not ClassDatabase.has(cls): return
	var cp := char_profile(char_id)
	# klasa zapisanej postaci jest na stałe — nie da się jej zmienić przy kontynuowaniu gry
	if String(cp.get("class", "")) != "" and String(cp.get("class", "")) != cls:
		return
	if String(cp.get("class", "")) != cls:
		cp["class"] = cls
		cp["skills"] = ClassDatabase.default_slots(cls)
	save_game()

func skill_slots_for(char_id: String) -> Array:
	var cp := char_profile(char_id)
	var sl: Array = cp.get("skills", [])
	while sl.size() < 6: sl.append("")
	cp["skills"] = sl
	return sl

func skill_slots() -> Array:
	return skill_slots_for(current_character_id())

func set_skill_slot(idx: int, id: String) -> void:
	var sl := skill_slots()
	if idx < 0 or idx >= sl.size(): return
	sl[idx] = id
	save_game()

func finish_run(victory: bool) -> void:
	if has_run():
		var st: Dictionary = profile["stats"]
		st["runs"] = int(st.get("runs", 0)) + 1
		st["kills"] = int(st.get("kills", 0)) + int(run.get("kills", 0))
		st["time"] = float(st.get("time", 0.0)) + float(run.get("time", 0.0))
		if not victory:
			st["deaths"] = int(st.get("deaths", 0)) + 1
		commit_backpack()
		_last_char = String(run["character"])
	if rpg.get("own_story") is Dictionary:
		profile["story"] = (rpg["own_story"] as Dictionary).duplicate(true)
	run = {}
	rpg = {}
	run_committed = false
	save_game()
	profile_changed.emit()

func last_results() -> Dictionary:
	var kills := int(run.get("kills", 0))
	var dealt := float(run.get("damage_dealt", 0.0))
	var score := int(run.get("score", 0))
	if score <= 0:
		score = kills * 100 + int(dealt) + int(run.get("max_combo", 0)) * 20
	return {
		"score": score, "time": float(run.get("time", 0.0)), "kills": kills,
		"damage_dealt": dealt, "damage_taken": float(run.get("damage_taken", 0.0)),
		"max_combo": int(run.get("max_combo", 0)), "blocks": int(run.get("blocks", 0)),
		"parries": int(run.get("parries", 0)), "gold": int(run.get("gold_earned", 0)),
	}

func unlock_stage(idx: int) -> void:
	profile["stage_unlocked"] = maxi(int(profile.get("stage_unlocked", 1)), idx + 2)
	save_game()

func advance_stage() -> void:
	if not has_run(): return
	run["stage_index"] = mini(int(run.get("stage_index", 0)) + 1, StageDB.count() - 1)
	run["stages_cleared"] = int(run.get("stages_cleared", 0)) + 1

# ---------------------------------------------------------------- ekwipunek ---
## Ekwipunek: 40 slotów podstawowych (cp["inv"]) + sloty wyposażenia (cp["equip"]).
## Wpis slotu: {"id": String, "n": int, "q": float}; q = jakość (kuźnia), domyślnie 1.0.
## Skrytka (cp["overflow"]) zbiera przedmioty, które nie zmieściły się w ekwipunku.
## Zasada amuletów: działają WYŁĄCZNIE w slotach amuletów (amulet, amulet2); w plecaku
## nie dają nic. Ten sam amulet nie może być założony dwa razy. Bonusy liczone są
## z aktualnego wyposażenia, więc zdjęcie amuletu natychmiast je odbiera.

const INV_SIZE := 40

func _cp() -> Dictionary:
	return char_profile(current_character_id())

func inv() -> Array:
	var cp := _cp()
	if not (cp.get("equip_q") is Dictionary): cp["equip_q"] = {}
	if not (cp.get("equip_m") is Dictionary): cp["equip_m"] = {}
	if not (cp.get("inv") is Array) or (cp["inv"] as Array).size() != INV_SIZE:
		_migrate_inventory(cp)
	return cp["inv"]

func _migrate_inventory(cp: Dictionary) -> void:
	var inv_a: Array = []
	for i in INV_SIZE:
		inv_a.append(null)
	var old: Array = cp["inv"] if cp.get("inv") is Array else []
	cp["inv"] = inv_a
	if not (cp.get("overflow") is Array): cp["overflow"] = []
	if not (cp.get("equip_q") is Dictionary): cp["equip_q"] = {}
	if not (cp.get("equip_m") is Dictionary): cp["equip_m"] = {}
	for i in mini(old.size(), INV_SIZE):
		if old[i] is Dictionary:
			inv_a[i] = old[i]
	var bp: Dictionary = cp.get("backpack", {}) if cp.get("backpack") is Dictionary else {}
	for id in bp:
		if ItemDB.has(String(id)) and int(bp[id]) > 0:
			_insert(cp, String(id), int(bp[id]), 1.0)
	cp["backpack"] = {}
	var eq: Dictionary = cp.get("equip", {})
	var worn: Array = eq.values()
	for id in cp.get("gear", []):
		if String(id) in worn or not ItemDB.has(String(id)):
			continue
		_insert(cp, String(id), 1, 1.0)
	cp["gear"] = []

## Wkłada przedmiot do slotów inwentarza; zwraca liczbę sztuk, które się NIE zmieściły.
func _insert(cp: Dictionary, id: String, n: int, q: float, meta: Dictionary = {}) -> int:
	var inv_a: Array = cp["inv"]
	var cap := ItemDB.stack_of(id)
	if cap > 1:
		for i in INV_SIZE:
			var e = inv_a[i]
			if e is Dictionary and String(e["id"]) == id and int(e["n"]) < cap:
				var take := mini(n, cap - int(e["n"]))
				e["n"] = int(e["n"]) + take
				n -= take
				if n <= 0: return 0
	while n > 0:
		var free := -1
		for i in INV_SIZE:
			if inv_a[i] == null:
				free = i
				break
		if free < 0: return n
		var put := mini(n, cap)
		inv_a[free] = {"id": id, "n": put, "q": q}
		if not meta.is_empty():
			inv_a[free]["m"] = meta.duplicate(true)
		n -= put
	return 0

func add_item(id: String, amount: int = 1, q: float = 1.0) -> int:
	if not ItemDB.has(id) or amount <= 0: return amount
	inv()
	var left := _insert(_cp(), id, amount, q)
	if left > 0:
		(_cp()["overflow"] as Array).append({"id": id, "n": left, "q": q})
		toast.emit("Brak miejsca! „%s” trafia do skrytki." % String(ItemDB.get_data(id).get("name", id)), Color(1.0, 0.6, 0.3))
	return left

func add_gear(id: String, q: float = 1.0) -> void:
	add_item(id, 1, q)
	save_game()

func item_count(id: String) -> int:
	var total := 0
	for e in inv():
		if e is Dictionary and String(e["id"]) == id:
			total += int(e["n"])
	return total

func remove_item(id: String, amount: int = 1) -> bool:
	if item_count(id) < amount: return false
	var inv_a := inv()
	for i in INV_SIZE:
		var e = inv_a[i]
		if e is Dictionary and String(e["id"]) == id:
			var take := mini(amount, int(e["n"]))
			e["n"] = int(e["n"]) - take
			amount -= take
			if int(e["n"]) <= 0:
				inv_a[i] = null
			if amount <= 0: break
	return true

## Identyfikatory zużywalnych i rzucanych przedmiotów (w kolejności slotów).
func consumed_ids() -> Array:
	var out: Array = []
	for e in inv():
		if e is Dictionary:
			var id := String(e["id"])
			if (ItemDB.is_consumable(id) or ItemDB.is_throwable(id)) and id not in out:
				out.append(id)
	return out

func commit_backpack() -> void:
	save_game()

func inv_swap(a: int, b: int) -> void:
	var inv_a := inv()
	if a == b or a < 0 or b < 0 or a >= INV_SIZE or b >= INV_SIZE: return
	var ea = inv_a[a]
	var eb = inv_a[b]
	if ea is Dictionary and eb is Dictionary and String(ea["id"]) == String(eb["id"]) and is_equal_approx(float(ea.get("q", 1.0)), float(eb.get("q", 1.0))):
		var cap := ItemDB.stack_of(String(ea["id"]))
		var take := mini(int(ea["n"]), cap - int(eb["n"]))
		if take > 0:
			eb["n"] = int(eb["n"]) + take
			ea["n"] = int(ea["n"]) - take
			if int(ea["n"]) <= 0: inv_a[a] = null
			return
	inv_a[a] = eb
	inv_a[b] = ea

func inv_sort() -> void:
	var items: Array = []
	for e in inv():
		if e is Dictionary: items.append(e)
	items.sort_custom(func(x, y):
		var sx := String(ItemDB.get_data(String(x["id"])).get("slot", ""))
		var sy := String(ItemDB.get_data(String(y["id"])).get("slot", ""))
		if sx != sy: return sx < sy
		var rx := ItemDB.RARITIES.find(ItemDB.rarity_of(String(x["id"])))
		var ry := ItemDB.RARITIES.find(ItemDB.rarity_of(String(y["id"])))
		if rx != ry: return rx > ry
		return String(x["id"]) < String(y["id"]))
	var inv_a := inv()
	for i in INV_SIZE:
		inv_a[i] = items[i] if i < items.size() else null
	save_game()

func inv_discard(idx: int) -> void:
	var inv_a := inv()
	if idx >= 0 and idx < INV_SIZE:
		inv_a[idx] = null
		save_game()

func inv_free_slots() -> int:
	var n := 0
	for e in inv():
		if e == null: n += 1
	return n

func overflow_items() -> Array:
	inv()
	return _cp()["overflow"]

## Przenosi przedmioty ze skrytki do ekwipunku, o ile jest miejsce. Zwraca liczbę przeniesionych wpisów.
func claim_overflow() -> int:
	inv()
	var cp := _cp()
	var rest: Array = []
	var moved := 0
	for e in cp["overflow"]:
		var left := _insert(cp, String(e["id"]), int(e["n"]), float(e.get("q", 1.0)))
		if left > 0:
			rest.append({"id": e["id"], "n": left, "q": e.get("q", 1.0)})
		if left < int(e["n"]):
			moved += 1
	cp["overflow"] = rest
	save_game()
	return moved

func equipped() -> Dictionary:
	var cp := _cp()
	if not (cp.get("equip") is Dictionary): cp["equip"] = ItemDB.defaults()
	return cp["equip"]

func equipped_meta(slot: String = "") -> Dictionary:
	var m: Dictionary = _cp().get("equip_m", {})
	if slot == "":
		return m
	return m.get(slot, {})

func equipped_q(slot: String) -> float:
	return float(_cp().get("equip_q", {}).get(slot, 1.0))

func owns_gear(id: String) -> bool:
	if id in equipped().values(): return true
	return item_count(id) > 0

func owned_gear_of_slot(slot: String) -> Array:
	var out: Array = []
	for e in inv():
		if e is Dictionary and ItemDB.fits_slot(String(e["id"]), slot) and e["id"] not in out:
			out.append(String(e["id"]))
	return out

## Zakłada przedmiot z ekwipunku. `slot` pusty = wg typu (amulety: pierwszy wolny slot amuletu).
func equip_item(id: String, slot: String = "") -> bool:
	if not ItemDB.has(id): return false
	var kind := String(ItemDB.get_data(id).get("slot", ""))
	var eq := equipped()
	if slot == "":
		slot = kind
		if kind == "amulet":
			if String(eq.get("amulet", "")) == "": slot = "amulet"
			elif String(eq.get("amulet2", "")) == "": slot = "amulet2"
	if not ItemDB.fits_slot(id, slot):
		toast.emit("Ten przedmiot nie pasuje do tego slotu.", Color(0.95, 0.4, 0.35))
		return false
	if kind == "amulet":
		var other := "amulet2" if slot == "amulet" else "amulet"
		if String(eq.get(other, "")) == id:
			toast.emit("Ten amulet jest już założony.", Color(0.95, 0.4, 0.35))
			return false
	# znajdź w ekwipunku
	var inv_a := inv()
	var from := -1
	for i in INV_SIZE:
		var e = inv_a[i]
		if e is Dictionary and String(e["id"]) == id:
			from = i
			break
	var q := 1.0
	var new_meta: Dictionary = {}
	if from >= 0:
		q = float(inv_a[from].get("q", 1.0))
		new_meta = (inv_a[from].get("m", {}) as Dictionary).duplicate(true)
		var old := String(eq.get(slot, ""))
		if old != "":
			inv_a[from] = {"id": old, "n": 1, "q": equipped_q(slot)}
			var om := equipped_meta(slot)
			if not om.is_empty():
				inv_a[from]["m"] = om.duplicate(true)
		else:
			inv_a[from] = null
	else:
		toast.emit("Nie masz tego przedmiotu w ekwipunku.", Color(0.95, 0.4, 0.35))
		return false
	eq[slot] = id
	_cp()["equip_q"][slot] = q
	if new_meta.is_empty():
		_cp()["equip_m"].erase(slot)
	else:
		_cp()["equip_m"][slot] = new_meta
	refresh_stats()
	save_game()
	return true

func unequip_item(slot: String) -> bool:
	var eq := equipped()
	var id := String(eq.get(slot, ""))
	if id == "": return false
	inv()
	var left := _insert(_cp(), id, 1, equipped_q(slot), equipped_meta(slot))
	if left > 0:
		toast.emit("Brak miejsca w ekwipunku.", Color(0.95, 0.4, 0.35))
		return false
	eq.erase(slot)
	_cp()["equip_q"].erase(slot)
	_cp()["equip_m"].erase(slot)
	refresh_stats()
	save_game()
	return true

func spend(price: int) -> bool:
	if gold() < price: return false
	profile["gold"] = gold() - price
	gold_changed.emit(gold())
	save_game()
	return true

# ----------------------------------------------------------------- postać ---

func all_characters() -> Array:
	return CharacterDB.ordered_ids()

func is_unlocked(id: String) -> bool:
	return has_class(id)

func unlock_currency(id: String) -> String:
	return String(CharacterDB.get_data(id).get("unlock", ""))

func unlock_cost(id: String) -> int:
	return int(CharacterDB.get_data(id).get("price", 0))

func try_unlock(id: String) -> bool:
	if has_class(id): return true
	if unlock_currency(id) == "zlot":
		var price := unlock_cost(id)
		if zlot() < price: return false
		profile["zlot"] = zlot() - price
		unlock_class(id)
		return true
	return buy_class(id)

func attr_order() -> Array:
	return ATTR_ORDER

func attr_defs() -> Dictionary:
	return ATTRS

func attr_points() -> int:
	return int(char_profile(current_character_id()).get("attr_points", 0))

func attr_value(key: String) -> int:
	return int(char_profile(current_character_id()).get("attrs", {}).get(key, 0))

func attr_bonus(key: String) -> float:
	return float(attr_value(key)) * float(ATTRS.get(key, {}).get("per", 0.0))

func spend_attr_points(key: String, count: int = 1) -> bool:
	if key not in ATTR_ORDER or count <= 0: return false
	var cp := char_profile(current_character_id())
	var pts := int(cp.get("attr_points", 0))
	if pts < count: return false
	var a: Dictionary = cp.get("attrs", blank_attrs())
	a[key] = int(a.get(key, 0)) + count
	cp["attrs"] = a
	cp["attr_points"] = pts - count
	refresh_stats()
	save_game()
	return true

# ----------------------------------------------------------------- fabuła ---

func story() -> Dictionary:
	if not (profile.get("story") is Dictionary):
		profile["story"] = _blank_profile()["story"]
	return profile["story"]

func story_chapter() -> int: return int(story().get("chapter", 0))
func story_quest() -> String: return String(story().get("quest", ""))
func story_step() -> int: return int(story().get("step", 0))

func story_done(quest_id: String) -> bool:
	return quest_id in story().get("done", [])

func story_flag(flag: String) -> bool:
	return bool(story().get("flags", {}).get(flag, false))

func set_story_flag(flag: String, value: bool = true, sync: bool = true) -> void:
	var s := story()
	if not (s.get("flags") is Dictionary): s["flags"] = {}
	s["flags"][flag] = value
	# LAN: flagi fabuły należą do hosta — gość zgłasza zmianę, host rozsyła w migawkach
	if sync and rpg_mode_str() == "lan" and Net.has_peer() and not Net.is_host:
		Net.send_world_event("flag", {"name": flag, "value": value})

func set_story_step(step: int) -> void:
	story()["step"] = step

func set_story(chapter: int, quest: String, step: int = 0) -> void:
	var s := story()
	s["best"] = maxi(int(s.get("best", 0)), maxi(int(s.get("chapter", 0)), chapter))
	s["chapter"] = chapter
	s["quest"] = quest
	s["step"] = step

func apply_net_story(chapter: int, quest: String, step: int, flags: Dictionary) -> void:
	set_story(chapter, quest, step)
	story()["flags"] = flags.duplicate(true)

func complete_quest(quest_id: String) -> void:
	var s := story()
	var done: Array = s.get("done", [])
	if quest_id not in done: done.append(quest_id)
	s["done"] = done

func story_tracker() -> Dictionary:
	if not is_topdown(): return {"visible": false}
	if bool(rpg.get("arena", false)):
		return {"visible": false}
	if rpg.get("custom") is Dictionary and not (rpg["custom"] as Dictionary).is_empty():
		return {"visible": true, "title": "Własne fale", "objective": "Pokonaj wszystkie fale (%d)" % (rpg["custom"].get("waves", []) as Array).size()}
	var cave_i := String(rpg.get("cave", ""))
	if cave_i != "":
		var cv := SecretDB.cave_by_id(cave_i)
		var st := String(rpg.get("cave_state", "fight"))
		var obj := "Pokonaj elitarnych strażników jaskini"
		if st == "loot": obj = "Otwórz skarbiec jaskini"
		elif st == "exit": obj = "Wróć na powierzchnię (portal)"
		return {"visible": true, "title": "Sekretna jaskinia — %s" % String(cv.get("name", "")), "objective": obj}
	var c := QuestDB.chapter(story_chapter())
	var id := story_quest() if story_quest() != "" else String(c.get("id", ""))
	if story_chapter() >= QuestDB.count() or id == "":
		return {"visible": false}
	var q := QuestDB.get_data(id)
	var objective := QuestDB.objective(id, story_step())
	if ChapterExtras.has(id):
		var wn: int = ZoneDB.get_data(id).get("waves", []).size()
		var phase := "pre" if story_step() == 0 else ("post" if story_step() > wn else "")
		if phase != "":
			for p in ChapterExtras.progress(id, phase):
				objective += "\n%s %s%s" % ["✓" if bool(p["done"]) else ("▶" if bool(p["required"]) else "·"), String(p["text"]), "" if int(p["total"]) <= 1 else " (%d/%d)" % [int(p["count"]), int(p["total"])]]
	for ln in SideDB.tracker_lines():
		objective += "\n" + String(ln)
	return {"visible": true, "title": "%s — %s" % [String(q.get("label", "")), String(q.get("title", ""))], "objective": objective}

# ------------------------------------------------------------------ sloty ---

func select_slot(slot: int, create_new: bool) -> void:
	active_slot = clampi(slot, 1, SLOT_COUNT)
	run = {}
	rpg = {}
	if create_new or not slot_exists(active_slot):
		profile = _blank_profile()
		save_game()
		profile_changed.emit()
	else:
		load_game()

func slot_info(slot: int) -> Dictionary:
	if not slot_exists(slot): return {"exists": false}
	var f := FileAccess.open(slot_path(slot), FileAccess.READ)
	if not f: return {"exists": true, "broken": true}
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY: return {"exists": true, "broken": true}
	var st: Dictionary = data.get("story", {})
	var lvl := 1
	for cp in (data.get("characters", {}) as Dictionary).values():
		lvl = maxi(lvl, int(cp.get("level", 1)))
	return {
		"exists": true, "chapter": mini(int(st.get("chapter", 0)) + 1, QuestDB.count()),
		"done": (st.get("done", []) as Array).size(), "level": lvl, "gold": int(data.get("gold", 0)),
	}

func delete_slot(slot: int) -> void:
	if slot_exists(slot):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path(slot)))
	if slot == active_slot:
		profile = _blank_profile()
		run = {}
		rpg = {}
		profile_changed.emit()

func reset_save() -> void:
	delete_slot(active_slot)
	save_game()

# ------------------------------------------------------- ustawienia i klawisze ---

const BIND_ACTIONS := [
	"move_left", "move_right", "move_up", "move_down", "jump", "light_attack", "heavy_attack",
	"dash", "block", "throw_item", "special", "sprint", "pause", "equipment", "quest_log", "skill_tree",
	"skill_1", "skill_2", "skill_3", "skill_4", "skill_5", "skill_6",
]

const DEFAULT_KEYS := {
	"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
	"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN], "jump": [KEY_SPACE],
	"light_attack": [KEY_J], "heavy_attack": [KEY_K], "dash": [KEY_L], "block": [KEY_U],
	"throw_item": [KEY_I], "special": [KEY_O], "sprint": [KEY_SHIFT], "pause": [KEY_ESCAPE],
	"equipment": [KEY_E], "quest_log": [KEY_Q], "skill_tree": [KEY_T],
	"skill_1": [KEY_1], "skill_2": [KEY_2], "skill_3": [KEY_3],
	"skill_4": [KEY_4], "skill_5": [KEY_5], "skill_6": [KEY_6],
}

func _register_default_actions() -> void:
	for action in DEFAULT_KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		_set_keys(action, DEFAULT_KEYS[action])

func setting(key: String) -> bool:
	return bool(profile.get("settings", {}).get(key, true))

func toggle_setting(key: String) -> bool:
	if not profile.has("settings"): profile["settings"] = {}
	var v := not setting(key)
	profile["settings"][key] = v
	save_game()
	return v

func key_label(action: String) -> String:
	if not InputMap.has_action(action): return "—"
	var parts: Array = []
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			var kc := (ev as InputEventKey).physical_keycode
			parts.append(OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(kc)))
		elif ev is InputEventMouseButton:
			match (ev as InputEventMouseButton).button_index:
				MOUSE_BUTTON_LEFT: parts.append("LPM")
				MOUSE_BUTTON_RIGHT: parts.append("PPM")
				MOUSE_BUTTON_MIDDLE: parts.append("ŚPM")
				MOUSE_BUTTON_XBUTTON1: parts.append("Mysz boczny 1 (wstecz)")
				MOUSE_BUTTON_XBUTTON2: parts.append("Mysz boczny 2 (naprzód)")
				MOUSE_BUTTON_WHEEL_UP: parts.append("Kółko w górę")
				MOUSE_BUTTON_WHEEL_DOWN: parts.append("Kółko w dół")
				MOUSE_BUTTON_WHEEL_LEFT: parts.append("Kółko w lewo")
				MOUSE_BUTTON_WHEEL_RIGHT: parts.append("Kółko w prawo")
				_: parts.append("Mysz %d" % (ev as InputEventMouseButton).button_index)
	return " / ".join(parts) if not parts.is_empty() else "—"

# ------------------------------------------------------------ wygląd i animacje ---

const ANIMS_RES_PATH := "res://data/paint_anims.json"
const ANIMS_USER_PATH := "user://paint_anims.json"

func last_slot() -> int:
	var lf := "user://chicken_brawl_last.json"
	var last := 0
	if FileAccess.file_exists(lf):
		var f := FileAccess.open(lf, FileAccess.READ)
		if f:
			last = int(f.get_as_text().strip_edges())
			f.close()
	if last < 1 or last > SLOT_COUNT:
		last = 0
		for i in range(1, SLOT_COUNT + 1):
			if slot_exists(i):
				last = i
				break
	return maxi(last, 1)

## Wygląd kosmetyczny (kolory, ubrania, emblemat) — zawsze pełny słownik.
func appearance() -> Dictionary:
	var ap: Dictionary = profile.get("appearance", {})
	var out := CosmeticDB.blank_appearance()
	for k in out.keys():
		if ap.has(k) and typeof(ap[k]) == typeof(out[k]):
			out[k] = ap[k].duplicate(true) if (ap[k] is Dictionary or ap[k] is Array) else ap[k]
	return out

func set_appearance(ap: Dictionary) -> void:
	profile["appearance"] = ap.duplicate(true)
	profile["seen_creator"] = true
	save_game()
	profile_changed.emit()

func has_created_character() -> bool:
	return bool(profile.get("seen_creator", false))

## Animacje użytkownika: domyślne ← plik w zasobach ← zapis profilu.
func anims() -> Dictionary:
	var out := CosmeticDB.default_anims()
	for path in [ANIMS_RES_PATH, ANIMS_USER_PATH]:
		if FileAccess.file_exists(path):
			var f := FileAccess.open(path, FileAccess.READ)
			if f:
				var parsed = JSON.parse_string(f.get_as_text())
				f.close()
				if typeof(parsed) == TYPE_DICTIONARY:
					for k in parsed:
						out[k] = parsed[k]
	var saved: Dictionary = profile.get("paint_anims", {})
	for k in saved:
		out[k] = saved[k]
	return out

func save_anim(anim_name: String, data: Dictionary) -> void:
	if not (profile.get("paint_anims") is Dictionary):
		profile["paint_anims"] = {}
	profile["paint_anims"][anim_name] = data.duplicate(true)
	save_game()
	# kopia w zasobach projektu (działa w edytorze/dev), a poza tym w katalogu użytkownika
	var all := {}
	for k in profile["paint_anims"]:
		all[k] = profile["paint_anims"][k]
	var txt := JSON.stringify(all, "\t")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://data"))
	for path in [ANIMS_RES_PATH, ANIMS_USER_PATH]:
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f:
			f.store_string(txt)
			f.close()

func reset_anim(anim_name: String) -> void:
	if profile.get("paint_anims") is Dictionary:
		profile["paint_anims"].erase(anim_name)
		save_game()

## Nakłada wygląd gracza, animacje i widoczne wyposażenie na postać.
func dress(visual: CreatureVisual, with_look: bool = true) -> void:
	if with_look:
		var ap := appearance()
		visual.apply_appearance(ap)
	visual.custom_anims = anims()
	visual.set_gear(CosmeticDB.gear_visual(equipped(), equipped_meta()))

## Id wyglądu bazowego wybranego w kreatorze lub "" (wtedy wg postaci).
func look_id() -> String:
	var l := String(appearance().get("look", ""))
	return l if CharacterDB.LIST.has(l) else ""

# ------------------------------------------------------- drzewko umiejętności ---
## Punkty: 1 za każdy poziom (cp["skill_points"] = nieprzydzielone). Rank węzła: cp["tree"][id].
## Umiejętności klasowe (sygnaturowe) i Furia są dostępne od początku (rank 1).

func _tree() -> Dictionary:
	var cp := _cp()
	if not bool(cp.get("tree_init", false)):
		# stare zapisy: przyznaj punkty wstecz (poziom - 1)
		cp["tree_init"] = true
		cp["tree"] = {}
		cp["skill_points"] = maxi(int(cp.get("skill_points", 0)), int(cp.get("level", 1)) - 1)
	if not (cp.get("tree") is Dictionary):
		cp["tree"] = {}
	return cp["tree"]

func skill_points() -> int:
	_tree()
	return int(_cp().get("skill_points", 0))

func class_id() -> String:
	return String(_cp().get("class", ""))

func _free_skill(id: String) -> bool:
	if id == "furia":
		return true
	return id in ClassDatabase.get_data(class_id()).get("skills", [])

func skill_rank(id: String) -> int:
	var tree := _tree()
	var r := int(tree.get(id, 0))
	if _free_skill(id):
		r = maxi(r, 1)
	return r

func skill_scale(id: String) -> float:
	return SkillTreeDB.scale(skill_rank(id))

## Czy można kupić (następny rank) węzła; zwraca {ok, reason}.
func can_learn(id: String) -> Dictionary:
	if not SkillTreeDB.has(id):
		return {"ok": false, "reason": "Brak w drzewku"}
	var n := SkillTreeDB.node(id)
	var rank := skill_rank(id)
	var tree_rank := int(_tree().get(id, 0))
	if tree_rank >= int(n["max_rank"]):
		return {"ok": false, "reason": "Maksymalny poziom"}
	var next_rank := tree_rank + 1
	var need_lv := SkillTreeDB.rank_level(id, next_rank)
	var lv := int(_cp().get("level", 1))
	if lv < need_lv:
		return {"ok": false, "reason": "Wymaga poziomu %d" % need_lv}
	for r in n.get("req", []):
		if int(_tree().get(String(r), 0)) < 1 and not _free_skill(String(r)):
			return {"ok": false, "reason": "Wymaga: %s" % String(SkillDB.get_data(String(r)).get("name", r))}
	if skill_points() < 1:
		return {"ok": false, "reason": "Brak punktów umiejętności"}
	return {"ok": true, "reason": "", "rank": rank}

func learn_skill(id: String) -> bool:
	var chk := can_learn(id)
	if not bool(chk["ok"]):
		return false
	var tree := _tree()
	tree[id] = int(tree.get(id, 0)) + 1
	var cp := _cp()
	cp["skill_points"] = int(cp.get("skill_points", 0)) - 1
	skill_points_spent += 1
	save_game()
	profile_changed.emit()
	return true

## Umiejętności możliwe do przypisania do slotów: sygnaturowe + kupione.
func available_skills() -> Array:
	var out: Array = []
	var tree := _tree()
	for id in SkillDB.all():
		var sid := String(id)
		if _free_skill(sid) or int(tree.get(sid, 0)) >= 1:
			out.append(sid)
	return out

# ------------------------------------------------------------------ towarzysze ---

signal pets_changed

func pets() -> Dictionary:
	if not (profile.get("pets") is Dictionary):
		profile["pets"] = {"unlocked": ["kurczaczek"], "equipped": "kurczaczek", "gear": {}, "xp": {}}
	var p: Dictionary = profile["pets"]
	if not (p.get("unlocked") is Array): p["unlocked"] = ["kurczaczek"]
	if not (p.get("gear") is Dictionary): p["gear"] = {}
	if not p.has("equipped"): p["equipped"] = ""
	return p

func has_pet(id: String) -> bool:
	return id in pets()["unlocked"]

func unlock_pet(id: String) -> bool:
	if not PetDB.has(id) or has_pet(id):
		return false
	pets()["unlocked"].append(id)
	if String(pets().get("equipped", "")) == "":
		pets()["equipped"] = id
	save_game()
	toast.emit("Nowy towarzysz: %s!" % String(PetDB.get_data(id).get("name", id)), Color(1.0, 0.85, 0.4))
	pets_changed.emit()
	return true

func equip_pet(id: String) -> void:
	if not has_pet(id): return
	pets()["equipped"] = id
	save_game()
	pets_changed.emit()

func pet_gear(pet_id: String) -> String:
	return String(pets()["gear"].get(pet_id, ""))

## Zakłada wyposażenie peta z ekwipunku (stare wraca do ekwipunku).
func set_pet_gear(pet_id: String, item_id: String) -> bool:
	if not has_pet(pet_id) or String(ItemDB.get_data(item_id).get("slot", "")) != "pet_gear":
		return false
	if not remove_item(item_id, 1):
		return false
	var old := pet_gear(pet_id)
	pets()["gear"][pet_id] = item_id
	if old != "":
		add_item(old, 1)
	save_game()
	pets_changed.emit()
	return true

func unequip_pet_gear(pet_id: String) -> bool:
	var old := pet_gear(pet_id)
	if old == "":
		return false
	inv()
	if _insert(_cp(), old, 1, 1.0) > 0:
		return false
	pets()["gear"].erase(pet_id)
	save_game()
	pets_changed.emit()
	return true

# --------------------------------------------------------------------- Akt II ---

## Czy gracz musi wybrać misję na mapie świata (Akt II bez wybranego zadania).
func act2_needs_choice() -> bool:
	if not is_topdown():
		return false
	var start := QuestDB.act_start(2)
	if start < 0:
		return false
	var ch := story_chapter()
	return ch >= start and ch < start + QuestDB.act_count(2) and story_quest() == ""

func begin_act2_mission(id: String) -> void:
	var start := QuestDB.act_start(2)
	set_story(start + Act2DB.liberated().size(), id, 0)
	save_game()

# ------------------------------------------------------- poziom trudności ---

## Trudność rośnie z postępem w grze (jak daleko zaszedł gracz), a nie z tym, ile obrażeń zadaje.
func progress_index() -> int:
	if is_topdown():
		return story_chapter() + (1 if story_quest() != "" and story_step() > 0 else 0)
	return int(run.get("stage_index", 0)) * 2

func enemy_hp_mult() -> float:
	return (1.8 + 0.24 * float(progress_index())) * float(diff_data()["hp"])

func enemy_dmg_mult() -> float:
	return (1.3 + 0.07 * float(progress_index())) * float(diff_data()["dmg"])

# ------------------------------------------------------- poziomy trudności ---
## Normalny = dotychczasowa trudność. Koszmarny / Piekielny mnożą życie i obrażenia potworów,
## ale dają więcej XP i złota oraz lepsze przedmioty (legendarki, które wzmacniają umiejętności).

const DIFFICULTIES := {
	"normal": {"name": "Normalny", "hp": 1.0, "dmg": 1.0, "xp": 1.0, "gold": 1.0, "loot": 0, "col": Color(0.55, 0.9, 0.55),
		"desc": "Standardowa trudność kampanii."},
	"nightmare": {"name": "Koszmarny", "hp": 5.0, "dmg": 3.0, "xp": 3.0, "gold": 2.5, "loot": 1, "col": Color(1.0, 0.6, 0.2),
		"desc": "Potwory 5× wytrzymalsze i 3× groźniejsze. XP ×3, złoto ×2,5, lepsze przedmioty."},
	"hell": {"name": "Piekielny", "hp": 10.0, "dmg": 5.0, "xp": 6.0, "gold": 5.0, "loot": 2, "col": Color(1.0, 0.25, 0.25),
		"desc": "Potwory 10× wytrzymalsze i 5× groźniejsze. XP ×6, złoto ×5, najlepsze przedmioty."},
}
const DIFF_ORDER := ["normal", "nightmare", "hell"]

func difficulty() -> String:
	var d := String(profile.get("difficulty", "normal"))
	return d if DIFFICULTIES.has(d) else "normal"

func diff_data() -> Dictionary:
	return DIFFICULTIES[difficulty()]

func set_difficulty(id: String) -> void:
	if DIFFICULTIES.has(id):
		profile["difficulty"] = id
		save_game()

# --------------------------------------------------- powtarzanie rozdziałów ---

func best_chapter() -> int:
	return maxi(int(story().get("best", 0)), story_chapter())

## Rozdziały, które można zagrać (od początku do najdalszego osiągniętego).
func replayable_chapters() -> Array:
	var out: Array = []
	for i in mini(QuestDB.count(), best_chapter() + 1):
		var c := QuestDB.chapter(i)
		var id := String(c.get("id", ""))
		if ZoneDB.has(id) and QuestDB.ready(id):
			out.append(i)
	return out

## Zaczyna wybrany rozdział od nowa (ekwipunek, postać i poziomy zostają).
func replay_chapter(index: int) -> void:
	var s := story()
	s["best"] = best_chapter()
	var c := QuestDB.chapter(index)
	var id := String(c.get("id", ""))
	var done: Array = []
	for d in s.get("done", []):
		var di := -1
		for i in QuestDB.count():
			if String(QuestDB.chapter(i).get("id", "")) == String(d):
				di = i
		if di >= 0 and di < index:
			done.append(d)
	s["done"] = done
	s["flags"] = {}
	set_story(index, id, 0)
	save_game()

# --------------------------------------------------- skrytka (wspólna dla wszystkich postaci) ---
## Jak „wspólna skrytka” w Diablo 2 Resurrected: 3 zakładki po 60 miejsc, dostępne dla każdej postaci.

const STASH_TABS := 3
const STASH_SLOTS := 60

func stash() -> Array:
	var st = profile.get("stash")
	if not (st is Array):
		st = []
		profile["stash"] = st
	while st.size() < STASH_TABS:
		st.append([])
	for t in STASH_TABS:
		var tab: Array = st[t]
		while tab.size() < STASH_SLOTS:
			tab.append(null)
	return st

## Przenosi przedmiot z ekwipunku do zakładki skrytki; zwraca true, jeśli się udało.
func stash_put(inv_idx: int, tab: int) -> bool:
	var inv_a := inv()
	if inv_idx < 0 or inv_idx >= inv_a.size() or not (inv_a[inv_idx] is Dictionary):
		return false
	var t: Array = stash()[clampi(tab, 0, STASH_TABS - 1)]
	for i in STASH_SLOTS:
		if t[i] == null:
			t[i] = inv_a[inv_idx]
			inv_a[inv_idx] = null
			save_game()
			return true
	return false

## Przenosi przedmiot ze skrytki do ekwipunku (resztka wraca na miejsce).
func stash_take(tab: int, slot: int) -> bool:
	var t: Array = stash()[clampi(tab, 0, STASH_TABS - 1)]
	if slot < 0 or slot >= STASH_SLOTS or not (t[slot] is Dictionary):
		return false
	var e: Dictionary = t[slot]
	var left := _insert(_cp(), String(e["id"]), int(e["n"]), float(e.get("q", 1.0)), e.get("m", {}))
	if left >= int(e["n"]):
		return false
	if left > 0:
		e["n"] = left
	else:
		t[slot] = null
	save_game()
	return true

## Poziom aktualnego bohatera.
func player_level() -> int:
	return int(char_profile(current_character_id()).get("level", 1))

## Poległy towarzysz (żołnierz „ally:N” albo „pet”) wraca po zdobyciu 5 poziomów.
func mark_fallen(key: String) -> void:
	if not (rpg.get("fallen") is Dictionary):
		rpg["fallen"] = {}
	rpg["fallen"][key] = player_level() + 5

## Życie żołnierzy i petów nie regeneruje się: zapamiętujemy je między etapami (do poległego powrotu).
func support_hp(key: String, max_hp: float) -> float:
	var d: Dictionary = rpg.get("support_hp", {})
	return minf(float(d.get(key, max_hp)), max_hp)

func set_support_hp(key: String, hp: float) -> void:
	if not (rpg.get("support_hp") is Dictionary):
		rpg["support_hp"] = {}
	rpg["support_hp"][key] = hp

func clear_support_hp(key: String) -> void:
	if rpg.get("support_hp") is Dictionary:
		(rpg["support_hp"] as Dictionary).erase(key)

func is_fallen(key: String) -> bool:
	return (rpg.get("fallen") is Dictionary) and (rpg["fallen"] as Dictionary).has(key)

## Statystyki i wygląd zapisanej postaci (arena / współpraca): wysyłane hostowi przy dołączaniu.
func arena_loadout(cid: String) -> Dictionary:
	var prev := _last_char
	_last_char = cid
	var st := compute_stats()
	var eq: Dictionary = equipped().duplicate(true)
	var meta: Dictionary = _cp().get("equip_m", {}).duplicate(true)
	_last_char = prev
	return {"stats": st, "gear": eq, "meta": meta}

# ------------------------------------------------------------- wzorce run ---

func known_runes() -> Array:
	var craft: Dictionary = profile.get("craft", {})
	if not (craft.get("runes") is Array):
		craft["runes"] = []
		profile["craft"] = craft
	return craft["runes"]

func learn_rune(word: String) -> bool:
	if word in known_runes():
		return false
	known_runes().append(word)
	save_game()
	return true

## Kowal przejmuje wzorce z plecaka: uczy się słów, a wzorce zużywa.
func absorb_patterns() -> Array:
	var learned: Array = []
	for e in inv().duplicate():
		if e is Dictionary:
			var w := RuneDB.word_of_pattern(String(e["id"]))
			if w != "":
				if learn_rune(w):
					learned.append(w)
				remove_item(String(e["id"]), int(e["n"]))
	if not learned.is_empty():
		save_game()
		toast.emit("Kowal poznał wzór: %s" % ", ".join(learned), Color(1.0, 0.85, 0.4))
	return learned
