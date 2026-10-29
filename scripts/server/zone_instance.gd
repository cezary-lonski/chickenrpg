class_name ZoneInstance
extends Node2D
## Instancja strefy na serwerze: wspólny świat do polowania ("swiat") albo rozdział kampanii (id questa).
## Instancje leżą daleko od siebie we wspólnej przestrzeni fizyki (origin), a wszystkie pozycje graczy,
## wrogów i NPC są lokalne względem instancji. Logika fabuły (fale, boss, nagrody) odtwarza village.gd.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const BOSS_SCENE := preload("res://scenes/boss_big.tscn")
const STORY_SIZE := Vector2(2200.0, 1500.0)
const WORLD_SIZE := Vector2(3000.0, 2000.0)
const MARGIN := 80.0
const SPACING := 9000.0

var srv: MmoServer
var key := ""
var kind := "story"          # story | swiat
var quest_id := ""
var zone: Dictionary = {}
var size := STORY_SIZE
var spawn := Vector2(1100.0, 1080.0)
var terrain := "village"
var giver := ""
var waves: Array = []
var wave_i := 0
var wave_active := false
var waves_started := false
var finished := false
var step := 0
var slot := 0
var entities: Node2D
var peer_ids: Array = []
var npc_list: Array = []     # {id, pos}
var boss_id := ""
var _seq := 0
var _next_wave_t := -1.0
var _spawn_acc := 0.0
var _idle_t := 0.0
var _boss: BossBig = null
var _finish_t := -1.0
var _finish_info: Dictionary = {}
var objs: Array = []          # obiekty interaktywne: {uid, kind, label, pos, type, phase?, ...}
var extra_objs: Array = []    # obiekty dodane w trakcie (skarbiec i portal jaskini)
var cave_id := ""
var cave: Dictionary = {}
var cave_state := "fight"     # fight | loot | exit
var cave_t := 0.0
var cave_bonus := false
var owner_peer := 0
var _start_t := -1.0
var _cave_boss_out := false
var _elites_done := false
var buildings: Array = []     # budynki do narysowania na kliencie: {kind, pos}
var opened: Dictionary = {}     # peer -> otworzył skarbiec jaskini
var duels := 0
var custom_cfg: Dictionary = {}
var ch_round := 0               # wyzwanie: numer rundy
var _ch_t := -1.0
var _ch_act := ""
var arena_peers: Array = []     # arena PvP: dwaj gracze
var duel_knight: Enemy = null
var duel_kid := ""
var _boss_t := 150.0           # Pustkowie: czas do kolejnego bossa świata
var _raid_t := 240.0           # Pustkowie: czas do najazdu elit
var _raid_mobs: Array = []
var hunts: Dictionary = {}     # id zlecenia -> wróg łowcy nagród
var heist: Dictionary = {}     # cel skradankowy rozdziału (strażnicy ze stożkiem wzroku)
var _clock := 0.0              # zegar patroli strażników (klienci rysują ich z tego samego czasu)
var _heist_alert: Dictionary = {}   # peer -> pasek wykrycia
var camp_off := false              # obóz niewolników: strażnicy odeszli (naczelnik pokonany albo jeniec wolny)
var _heist_send := 0.0

func setup(p_srv: MmoServer, p_key: String, p_slot: int) -> void:
	srv = p_srv
	key = p_key
	slot = p_slot
	position = Vector2(float(slot % 8) * SPACING, float(slot / 8) * SPACING)
	name = "Zone_%s" % key
	if key == "swiat":
		kind = "swiat"
		size = WORLD_SIZE
		spawn = MmoServer.SPAWN
		terrain = "village"
	elif key.begins_with("custom:"):
		kind = "custom"
		owner_peer = int(key.split(":")[1])
		custom_cfg = srv.pending_custom.get(key, UiWaveEditor.default_config())
		var ws: Array = []
		for w in custom_cfg.get("waves", []):
			ws.append({"name": String(w.get("name", "")), "enemies": w.get("enemies", []), "elite": bool(w.get("elite", false)),
				"hp": float(w.get("hp", 1.0)), "dmg": float(w.get("dmg", 1.0)), "xp": float(w.get("xp", 1.0))})
		terrain = String(custom_cfg.get("terrain", "village"))
		spawn = Vector2(1100.0, 1080.0)
		waves = ws
		zone = {"terrain": terrain, "spawn": spawn, "waves": ws, "intro_banner": ["WŁASNE FALE", "%d fal do pokonania" % ws.size()],
			"outro_banner": ["ZWYCIĘSTWO", "Wszystkie fale pokonane"]}
		_start_t = 2.6
	elif key.begins_with("challenge:"):
		kind = "challenge"
		owner_peer = int(key.split(":")[1])
		terrain = "palace"
		spawn = Vector2(1100.0, 1080.0)
		zone = {"intro_banner": ["WYZWANIE", "Kolejni rycerze, coraz silniejsi"], "outro_banner": ["KONIEC WYZWANIA", ""]}
		_ch_act = "next"
		_ch_t = 2.5
	elif key.begins_with("arena:"):
		kind = "arena"
		terrain = "fortress"
		spawn = Vector2(1100.0, 780.0)
		zone = {"intro_banner": ["ARENA GRACZY", "Pojedynek dwóch graczy"], "outro_banner": ["KONIEC WALKI", ""]}
	elif key.begins_with("cave:"):
		kind = "cave"
		var parts := key.split(":")
		cave_id = parts[1]
		owner_peer = int(parts[2]) if parts.size() > 2 else 0
		cave = SecretDB.cave_by_id(cave_id)
		zone = SecretDB.cave_zone(cave_id)
		terrain = String(zone.get("terrain", "cave"))
		spawn = zone.get("spawn", Vector2(1100.0, 1280.0))
		waves = zone.get("waves", [])
		_start_t = 2.6
		if zone.has("camp"):
			var cp: Dictionary = zone["camp"]
			heist = {"id": "camp:" + cave_id, "guards": cp["guards"], "start": cp["start"], "camp": true}
			# wyjście z obozu jest od początku: uciec można bez zabijania strażników
			extra_objs.append({"uid": "campportal", "kind": "portal", "label": "Opuść obóz", "pos": (cp["start"] as Vector2) + Vector2(0.0, -90.0), "type": "portal"})
		for pr in zone.get("shafts", []):
			var sa: Vector2 = pr[0]
			var sb: Vector2 = pr[1]
			extra_objs.append({"uid": "shaft:%d:a" % extra_objs.size(), "kind": "shaft", "label": "Zejdź szybem", "pos": sa, "type": "shaft", "to": sb})
			extra_objs.append({"uid": "shaft:%d:b" % extra_objs.size(), "kind": "shaft", "label": "Zejdź szybem", "pos": sb, "type": "shaft", "to": sa})
		if zone.has("mine"):
			var mn: Dictionary = zone["mine"]
			var steps: Array = mn["steps"]
			for i in steps.size():
				var st: Dictionary = steps[i]
				extra_objs.append({"uid": "mine:%s:%d" % [String(mn["id"]), i], "kind": String(st["kind"]), "label": String(st["label"]),
					"pos": st["pos"], "type": "mine", "mine": String(mn["id"]), "idx": i})
	else:
		quest_id = key
		zone = ZoneDB.get_data(key)
		terrain = String(zone.get("terrain", "village"))
		giver = String(zone.get("giver", ""))
		spawn = zone.get("spawn", Vector2(1100.0, 1080.0))
		waves = zone.get("waves", [])
		for id in zone.get("npcs", []):
			var d := NpcDB.get_data(String(id))
			if not d.is_empty():
				npc_list.append({"id": String(id), "pos": d.get("pos", spawn + Vector2(120.0, 0.0))})
		if ChapterExtras.has(quest_id):
			for id in ChapterExtras.npc_ids(quest_id):
				var dx := NpcDB.get_data(String(id))
				if not dx.is_empty():
					npc_list.append({"id": String(id), "pos": dx.get("pos", spawn + Vector2(160.0, 0.0))})
		_build_objects()
	entities = Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	add_child(entities)
	var walls := StaticBody2D.new()
	walls.collision_layer = 1
	walls.collision_mask = 0
	add_child(walls)
	var t := 200.0
	for spec in [
		[Vector2(size.x * 0.5, -t * 0.5), Vector2(size.x + t * 2.0, t)],
		[Vector2(size.x * 0.5, size.y + t * 0.5), Vector2(size.x + t * 2.0, t)],
		[Vector2(-t * 0.5, size.y * 0.5), Vector2(t, size.y + t * 2.0)],
		[Vector2(size.x + t * 0.5, size.y * 0.5), Vector2(t, size.y + t * 2.0)],
	]:
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = spec[1]
		cs.shape = rs
		cs.position = spec[0]
		walls.add_child(cs)

func zone_title() -> String:
	if kind == "story":
		return String(QuestDB.get_data(quest_id).get("title", "Świat"))
	if kind == "cave":
		return "Sekretna jaskinia — %s" % String(cave.get("name", ""))
	if kind == "custom":
		return "Własne fale"
	if kind == "challenge":
		return "Wyzwanie — runda %d" % maxi(1, ch_round)
	if kind == "arena":
		return "Arena graczy"
	return "Pustkowie"

func zone_info() -> Dictionary:
	var banner: Array = zone.get("intro_banner", ["", ""])
	return {"key": key, "kind": kind, "terrain": terrain, "size": size, "spawn": spawn, "npcs": npc_list,
		"quest": quest_id, "title": zone_title(), "waves_n": waves.size(),
		"mine_id": String((zone.get("mine", {}) as Dictionary).get("id", (zone.get("camp", {}) as Dictionary).get("id", ""))), "banner": banner, "boss_pos": BossDB.ARENA_CENTER, "boss_radius": BossDB.ARENA_RADIUS, "objs": objs + extra_objs, "buildings": buildings,
		"heist": {} if heist.is_empty() else {"guards": heist["guards"], "t": _clock, "id": String(heist["id"]), "disarm": String(heist.get("disarm", "")), "camp": bool(heist.get("camp", false))}}

# ---------------------------------------------------------------- obiekty ---

func _free_pos(p: Vector2) -> Vector2:
	return Vector2(clampf(p.x, 120.0, size.x - 120.0), clampf(p.y, 120.0, size.y - 120.0))

func _build_objects() -> void:
	for obj in ChapterExtras.objectives(quest_id):
		var o: Dictionary = obj
		match String(o.get("type", "")):
			"collect", "free", "sabotage":
				var positions: Array = o.get("positions", [])
				for i in positions.size():
					objs.append({"uid": ChapterExtras.flag(quest_id, String(o["id"]), i), "kind": MinesDB.step_value(o, "kinds", "kind", i, "document"),
						"label": MinesDB.step_value(o, "labels", "label", i, "Użyj"), "pos": positions[i], "type": "obj", "obj": String(o["id"]), "idx": i,
						"phase": String(o.get("phase", "pre"))})
	for obj2 in ChapterExtras.objectives(quest_id):
		if String(obj2.get("type", "")) == "heist":
			heist = obj2
			objs.append({"uid": "heist:" + quest_id, "kind": "document", "label": String(obj2.get("label", "Zwędź")), "pos": obj2["pos"], "type": "heist"})
	for c in SecretDB.chests_for(quest_id):
		objs.append({"uid": "%s:%s" % [quest_id, String(c["id"])], "kind": "chest", "label": "Otwórz skrzynię", "pos": c["pos"],
			"type": "chest", "hidden": bool(c.get("hidden", false)), "chest": String(c["id"])})
	for camp_id in SpecialDB.camps_in(quest_id):
		var cvc := SecretDB.cave_by_id(String(camp_id))
		objs.append({"uid": "cave:" + String(camp_id), "kind": "entrance", "label": "Ścieżka do obozu niewolników", "pos": cvc["entrance"], "type": "entrance",
			"cave": String(camp_id), "levers": 0, "camp": true})
	for mine_id in MinesDB.mines_in(quest_id):
		var cvm := SecretDB.cave_by_id(String(mine_id))
		objs.append({"uid": "cave:" + String(mine_id), "kind": "entrance", "label": "Wejdź: " + String(cvm["name"]), "pos": cvm["entrance"], "type": "entrance",
			"cave": String(mine_id), "levers": 0, "camp": false, "mine": true})
	var cv := SecretDB.cave_for(quest_id)
	if not cv.is_empty():
		objs.append({"uid": "sign:" + quest_id, "kind": "sign", "label": "Przeczytaj", "pos": _free_pos(spawn + Vector2(150.0, -90.0)), "type": "sign"})
		var lev: Array = cv["levers"]
		for i in lev.size():
			objs.append({"uid": "lv:%s:%d" % [quest_id, i], "kind": "lever", "label": "Pociągnij dźwignię", "pos": lev[i], "type": "lever", "idx": i})
		objs.append({"uid": "cave:" + String(cv["id"]), "kind": "entrance", "label": "Zejdź do jaskini", "pos": cv["entrance"], "type": "entrance",
			"cave": String(cv["id"]), "levers": lev.size()})
	var board_pos := _free_pos(spawn + Vector2(300.0, -100.0))
	objs.append({"uid": "board:" + quest_id, "kind": "board", "label": "Tablica zleceń", "pos": board_pos, "type": "board"})
	var lab_pos = SecretDB.lab_for(quest_id)
	if lab_pos != null:
		buildings.append({"kind": "lab", "pos": lab_pos})
		objs.append({"uid": "lab:" + quest_id, "kind": "lab", "label": "Wejdź do laboratorium", "pos": (lab_pos as Vector2) + Vector2(0.0, 38.0), "type": "lab"})
	var stash_pos := _free_spot([Vector2(-300, -100), Vector2(300, -100), Vector2(-440, -60), Vector2(440, -60), Vector2(-260, -240), Vector2(260, -240), Vector2(0, -300), Vector2(-560, -180), Vector2(560, -180)], [board_pos])
	objs.append({"uid": "stash:" + quest_id, "kind": "stash", "label": "Otwórz skrytkę", "pos": stash_pos, "type": "stash"})
	var taken: Array = []
	for o in objs:
		taken.append(o["pos"])
	var hosp_pos := _free_spot([Vector2(-560, -80), Vector2(560, -80), Vector2(-700, 120), Vector2(700, 120), Vector2(-420, -300), Vector2(420, -300), Vector2(0, -420)], taken)
	buildings.append({"kind": "hospital", "pos": hosp_pos})
	objs.append({"uid": "hospital:" + quest_id, "kind": "hospital", "label": "Wejdź do szpitala", "pos": hosp_pos + Vector2(0.0, 38.0), "type": "hospital"})

## Wolne miejsce przy punkcie startu: kandydat najdalszy od NPC i zajętych miejsc (jak village.gd::_free_spot).
func _free_spot(offsets: Array, taken: Array) -> Vector2:
	var best: Vector2 = spawn + (offsets[0] as Vector2)
	var best_d := -1.0
	for off in offsets:
		var p := Vector2(clampf(spawn.x + (off as Vector2).x, 150.0, size.x - 150.0), clampf(spawn.y + (off as Vector2).y, 160.0, size.y - 150.0))
		var dmin := 1.0e9
		for n in npc_list:
			dmin = minf(dmin, (n["pos"] as Vector2).distance_to(p))
		for t in taken:
			dmin = minf(dmin, (t as Vector2).distance_to(p))
		if dmin > best_d:
			best_d = dmin
			best = p
	return best

func find_obj(uid: String) -> Dictionary:
	for o in objs:
		if String(o["uid"]) == uid:
			return o
	for o in extra_objs:
		if String(o["uid"]) == uid:
			return o
	return {}

func add_extra_obj(o: Dictionary) -> void:
	extra_objs.append(o)
	srv.broadcast_zone_ev(self, "objs_add", {"objs": [o]})

func remove_extra_obj(uid: String) -> void:
	for i in extra_objs.size():
		if String(extra_objs[i]["uid"]) == uid:
			extra_objs.remove_at(i)
			return

## Elitarny wróg z celu rozdziału (przed obroną) — pojawia się raz na instancję.
func spawn_objective_elites() -> void:
	if _elites_done or kind != "story":
		return
	_elites_done = true
	for obj in ChapterExtras.objectives(quest_id):
		var o: Dictionary = obj
		if String(o.get("type", "")) != "elite":
			continue
		var e := ENEMY_SCENE.instantiate() as Enemy
		e.server_mode = true
		e.setup(String(o.get("enemy", "kruk")), false, true)
		e.set_meta("obj_elite", true)
		e.net_id = "%d_o%d" % [slot, _seq]
		_seq += 1
		e.aggro = 420.0
		entities.add_child(e)
		e.position = o.get("pos", Vector2(1100.0, 1000.0))
		e.set_bounds_rect(MARGIN, size.x - MARGIN, MARGIN, size.y - MARGIN)
		e.died.connect(srv.on_mob_died.bind(self))
		e.died.connect(func(_x): srv.on_objective_elite(self, o))

func spawn_hunt(qid: String, at: Vector2) -> void:
	if hunts.has(qid) and is_instance_valid(hunts[qid]):
		return
	var e := ENEMY_SCENE.instantiate() as Enemy
	e.server_mode = true
	e.setup("kruk", false, true)
	e.set_meta("hunt", qid)
	e.net_id = "%d_h%d" % [slot, _seq]
	_seq += 1
	e.aggro = 520.0
	entities.add_child(e)
	e.position = at
	e.set_bounds_rect(MARGIN, size.x - MARGIN, MARGIN, size.y - MARGIN)
	e.died.connect(srv.on_mob_died.bind(self))
	e.died.connect(func(_x): srv.on_hunt_died(self, qid))
	hunts[qid] = e

# ------------------------------------------------------------------ gracze ---

func add_player(peer: int, rec: Dictionary) -> Player:
	var p := PLAYER_SCENE.instantiate() as Player
	p.forced_character = String(rec["char"])
	p.net_controlled = true
	p.position = spawn + Vector2(randf_range(-80.0, 80.0), randf_range(-60.0, 60.0))
	entities.add_child(p)
	p.bounds_min = MARGIN
	p.bounds_max = size.x - MARGIN
	p.bounds_top = MARGIN
	p.bounds_bottom = size.y - MARGIN
	p.floor_y = size.y - MARGIN
	p.steal_cast.connect(func(): LootOps.start_steal(srv, peer, self))
	p.apply_server_loadout(ServerChars.compute_stats(rec), rec["equip"], rec["skills"], ServerChars.ranks_of(rec))
	p.hp = p.max_hp
	p.energy = p.max_energy
	peer_ids.append(peer)
	if srv.peers.has(peer) and (srv.peers[peer] as Dictionary).has("wander"):
		(srv.peers[peer] as Dictionary).erase("wander")
		(srv.peers[peer] as Dictionary)["wander_objs"] = []
	_idle_t = 0.0
	spawn_objective_elites()
	return p

# ------------------------------------------------------------------ zwłoki ---
# Poległy gracz zostawia zwłoki z rzeczami z plecaka (zob. ItemDB.death_losable) i 20% złota; każdy w strefie może je
# przeszukać. Zwłoki znikają po CORPSE_TTL sekundach (rzeczy przepadają).

const CORPSE_TTL := 900.0
var corpses: Dictionary = {}
var _corpse_seq := 0

## Przenosi rzeczy do utraty z plecaka gracza do zwłok w miejscu śmierci; zwraca listę opisów.
func add_corpse(peer: int, rec: Dictionary, at: Vector2) -> Array:
	var inv: Array = rec["inv"]
	var items: Array = []
	var lost: Array = []
	for i in range(inv.size() - 1, -1, -1):
		if ItemDB.death_losable(String(inv[i]["id"])):
			items.push_front((inv[i] as Dictionary).duplicate(true))
			lost.push_front("%s ×%d" % [String(ItemDB.get_data(String(inv[i]["id"])).get("name", inv[i]["id"])), int(inv[i]["n"])])
			inv.remove_at(i)
	var gold_lost := int(float(rec["gold"]) * 0.2)
	if gold_lost > 0:
		rec["gold"] = int(rec["gold"]) - gold_lost
		lost.append("%d zł" % gold_lost)
	if items.is_empty() and gold_lost <= 0:
		return lost
	_corpse_seq += 1
	var uid := "corpse:%d:%d" % [slot, _corpse_seq]
	var nm := String((srv.peers[peer] as Dictionary).get("name", "gracz")) if srv.peers.has(peer) else "gracz"
	corpses[uid] = {"name": nm, "pos": at, "items": items, "gold": gold_lost, "t": CORPSE_TTL}
	add_extra_obj({"uid": uid, "kind": "corpse", "label": "Przeszukaj zwłoki: " + nm, "pos": at, "type": "corpse"})
	return lost

func remove_corpse(uid: String) -> void:
	corpses.erase(uid)
	remove_extra_obj(uid)
	srv.broadcast_zone_ev(self, "objs_del", {"uid": uid})

func _tick_corpses(delta: float) -> void:
	for uid in corpses.keys():
		corpses[uid]["t"] = float(corpses[uid]["t"]) - delta
		if float(corpses[uid]["t"]) <= 0.0:
			remove_corpse(String(uid))

func remove_player(peer: int) -> void:
	peer_ids.erase(peer)
	_heist_alert.erase(peer)

func is_empty() -> bool:
	return peer_ids.is_empty()

func local_pos(node: Node2D) -> Vector2:
	return node.global_position - global_position

# -------------------------------------------------------------------- wrogowie ---

func alive_enemies() -> Array:
	var out: Array = []
	for c in entities.get_children():
		if c is Enemy and not (c as Enemy).dead and String((c as Enemy).net_id) != "" and not c.has_meta("obj_elite") and not c.has_meta("hunt"):
			out.append(c)
	return out

## Zabija wszystkich wrogów (zdarzenia śmierci, bez nagród) — komenda admina /killall.
func kill_all() -> int:
	var n := 0
	for c in entities.get_children():
		if c is Enemy and not (c as Enemy).dead:
			(c as Enemy)._die({})
			n += 1
	return n

func clear_enemies() -> int:
	var n := 0
	for c in entities.get_children():
		if c is Enemy:
			c.queue_free()
			n += 1
	return n

func spawn_mob(species: String, at: Vector2, elite: bool = false, mods: Dictionary = {}, skin: String = "") -> Enemy:
	if not EnemyDB.LIST.has(species) or bool(EnemyDB.LIST[species].get("boss", false)):
		return null
	var e := ENEMY_SCENE.instantiate() as Enemy
	e.server_mode = true
	if skin != "":
		e.skin = skin
	e.setup(species, false, elite)
	if not mods.is_empty():
		e.apply_mods(float(mods["hp"]), float(mods.get("dmg", 1.0)), float(mods.get("xp", 1.0)))
	e.net_id = "%d_e%d" % [slot, _seq]
	_seq += 1
	e.aggro = 700.0 if kind == "swiat" else 2600.0
	entities.add_child(e)
	e.position = at
	e.set_bounds_rect(MARGIN, size.x - MARGIN, MARGIN, size.y - MARGIN)
	e.died.connect(srv.on_mob_died.bind(self))
	return e

func _edge_spawn() -> Vector2:
	var side := randi() % 4
	var p := Vector2.ZERO
	match side:
		0: p = Vector2(randf_range(MARGIN, size.x - MARGIN), MARGIN + 20.0)
		1: p = Vector2(randf_range(MARGIN, size.x - MARGIN), size.y - MARGIN - 20.0)
		2: p = Vector2(MARGIN + 20.0, randf_range(MARGIN, size.y - MARGIN))
		_: p = Vector2(size.x - MARGIN - 20.0, randf_range(MARGIN, size.y - MARGIN))
	return p

# ----------------------------------------------------------------- pętla ---

## Skradanka: serwer liczy wykrycie każdego gracza. Zauważony wraca na start, a pasek wykrycia
## trafia do jego klienta (rysuje czerwienienie stożka).
func _tick_heist(delta: float) -> void:
	_clock += delta
	if heist.is_empty():
		return
	_heist_send -= delta
	for peer in peer_ids:
		var pl = srv.peers.get(peer)
		if pl == null:
			continue
		var node = pl.get("node")
		if node == null or not is_instance_valid(node) or (camp_off if bool(heist.get("camp", false)) else StoryActions.guards_off(pl["rec"], quest_id, heist)):
			if _heist_alert.erase(peer):
				srv.send_ev(peer, "heist_alert", {"a": 0.0, "hit": false})
			continue
		var best := 0.0
		for g in heist["guards"]:
			var s := StealthGuard.state_at(g["path"], _clock)
			best = maxf(best, StealthGuard.sees(s["pos"], s["dir"], float(g.get("range", 250.0)), (node as Node2D).position))
		var a := float(_heist_alert.get(peer, 0.0))
		a = a + delta * (0.9 + 1.6 * best) if best > 0.0 else maxf(0.0, a - delta * 0.7)
		if a >= 1.0 and bool(heist.get("camp", false)):
			_heist_alert.erase(peer)
			srv.send_ev(peer, "heist_alert", {"a": 0.0, "hit": false})
			camp_alarm()
			continue
		if a >= 1.0:
			_heist_alert.erase(peer)
			(node as Node2D).position = heist.get("start", spawn)
			if "velocity" in node:
				node.velocity = Vector2.ZERO
			srv.say(peer, "Zauważono cię! Strażnicy odprowadzili cię na start.")
			srv.send_ev(peer, "heist_alert", {"a": 0.0, "hit": true})
			continue
		_heist_alert[peer] = a
		if _heist_send <= 0.0 and (a > 0.0 or best > 0.0):
			srv.send_ev(peer, "heist_alert", {"a": a, "hit": false})
	if _heist_send <= 0.0:
		_heist_send = 0.2

func tick(delta: float) -> void:
	_tick_heist(delta)
	_tick_corpses(delta)
	if kind == "swiat":
		_tick_world(delta)
		return
	if kind == "cave" or kind == "custom":
		_tick_cave(delta)
	if kind == "challenge":
		_tick_challenge(delta)
	if finished:
		_finish_t -= delta
		if _finish_t <= 0.0 and _finish_t > -50.0:
			_finish_t = -100.0
			srv.advance_after_finish(self, _finish_info)
		return
	if _next_wave_t >= 0.0:
		_next_wave_t -= delta
		if _next_wave_t < 0.0:
			_next_wave_t = -1.0
			spawn_wave()
	if wave_active and alive_enemies().is_empty() and (_boss == null or not is_instance_valid(_boss) or _boss.dead) and not _cave_boss_out:
		wave_active = false
		_on_wave_cleared()

# ------------------------------------------------------------------ wyzwanie ---

func _tick_challenge(delta: float) -> void:
	if finished or _ch_t < 0.0:
		return
	_ch_t -= delta
	if _ch_t > 0.0:
		return
	_ch_t = -1.0
	if _ch_act == "next":
		_challenge_next()
	elif _ch_act == "spawn":
		_challenge_spawn()

func _challenge_kid() -> String:
	if ch_round >= 7:
		return "rycerz_hiper"
	if ch_round >= 3:
		return "rycerz_legenda"
	return "rycerz_pojedynku"

func _challenge_next() -> void:
	ch_round += 1
	var kd: Dictionary = EnemyDB.get_data(_challenge_kid())
	srv.broadcast_zone_ev(self, "banner", {"title": "RUNDA %d" % ch_round, "sub": String(kd["name"])})
	_ch_act = "spawn"
	_ch_t = 1.6

func _challenge_spawn() -> void:
	if finished or peer_ids.is_empty():
		return
	var p := srv.player_of(int(peer_ids[0]))
	if p == null:
		return
	var kid := _challenge_kid()
	var k := ENEMY_SCENE.instantiate() as Enemy
	k.server_mode = true
	k.setup(kid, false, false)
	k.apply_mods(1.0 + 0.12 * float(ch_round - 1), 1.0 + 0.06 * float(ch_round - 1), 1.0)
	k.is_duel = true
	k.aggro = 2000.0
	k.net_id = "%d_c%d" % [slot, _seq]
	_seq += 1
	entities.add_child(k)
	var side := 1.0 if p.position.x < size.x * 0.5 else -1.0
	k.position = (p.position + Vector2(260.0 * side, 0.0)).clamp(Vector2(MARGIN + 40.0, MARGIN + 40.0), Vector2(size.x - MARGIN - 40.0, size.y - MARGIN - 40.0))
	k.set_bounds_rect(MARGIN, size.x - MARGIN, MARGIN, size.y - MARGIN)
	duel_knight = k
	k.died.connect(srv.on_mob_died.bind(self))
	k.died.connect(func(_e): _challenge_won())

func _challenge_won() -> void:
	if finished:
		return
	var p := srv.player_of(int(peer_ids[0])) if not peer_ids.is_empty() else null
	if p != null:
		p.heal(p.max_hp * 0.3)
	srv.broadcast_zone_ev(self, "banner", {"title": "RUNDA %d UKOŃCZONA" % ch_round, "sub": "Łapiesz oddech…"})
	_ch_act = "next"
	_ch_t = 2.4

## Koniec wyzwania (śmierć albo wyjście): ranking i powrót do swojej strefy.
func challenge_over() -> void:
	if finished or kind != "challenge":
		return
	finished = true
	_finish_t = 5.0
	srv.on_challenge_over(self, maxi(0, ch_round - 1))

# --------------------------------------------------------------------- arena ---

func arena_ko(loser: int) -> void:
	if finished or kind != "arena" or loser not in arena_peers:
		return
	finished = true
	_finish_t = 4.0
	var winner := -1
	for p in arena_peers:
		if int(p) != loser:
			winner = int(p)
	srv.on_arena_over(self, winner, loser)

## Gracz wyszedł z serwera/strefy w trakcie walki.
func on_peer_left(peer: int) -> void:
	if kind == "arena" and not finished:
		arena_ko(peer)
	elif kind == "custom" and not finished:
		finished = true
		_finish_t = 0.5
	elif kind == "challenge" and not finished:
		challenge_over()

func _tick_world(delta: float) -> void:
	if peer_ids.is_empty():
		_idle_t += delta
		if _idle_t > 20.0:
			clear_enemies()
		return
	_idle_t = 0.0
	_tick_events(delta)
	_spawn_acc -= delta
	if _spawn_acc > 0.0:
		return
	_spawn_acc = 1.4
	if alive_enemies().size() >= clampi(8 + 5 * peer_ids.size(), 8, 60):
		return
	var pool := srv.species_pool(self)
	spawn_mob(pool[randi() % pool.size()], _random_spawn_point(), randf() < 0.06)

# ------------------------------------------------------- wydarzenia na Pustkowiu ---

const WORLD_BOSS_EVERY := 600.0
const RAID_EVERY := 420.0
const BOSS_SPOTS := [Vector2(760, 720), Vector2(2240, 720), Vector2(760, 1280), Vector2(2240, 1280)]

func world_boss_alive() -> bool:
	for c in entities.get_children():
		if c is BossBig and not (c as BossBig).dead:
			return true
	return false

# ------------------------------------------------ wędrowni podróżnicy ---
# Na Pustkowiu co kilka minut koło gracza pojawia się wędrowiec (spotkanie z EncounterDB): rozmowa z próbami umiejętności,
# znika po kilku minutach. Widzi go tylko ten gracz; po każdej rozmowie ten podróżnik nie wraca do tego samego gracza.

const WANDER_MIN := 300.0
const WANDER_MAX := 540.0
const WANDER_LIFE := 180.0
var _wander_t: Dictionary = {}

func _tick_wander(delta: float) -> void:
	for peer in peer_ids:
		var pl = srv.peers.get(peer)
		if pl == null:
			continue
		if pl.has("wander"):
			pl["wander"]["t"] = float(pl["wander"]["t"]) - delta
			if float(pl["wander"]["t"]) <= 0.0:
				clear_wander(peer)
			continue
		_wander_t[peer] = float(_wander_t.get(peer, randf_range(90.0, 200.0))) - delta
		if float(_wander_t[peer]) <= 0.0:
			_wander_t[peer] = randf_range(WANDER_MIN, WANDER_MAX)
			spawn_wander(int(peer))

## Pojawia wędrowca przy graczu (enc = "" losuje); false, gdy już rozmawiał ze wszystkimi albo coś mu przeszkadza.
func spawn_wander(peer: int, enc: String = "") -> bool:
	var pl = srv.peers.get(peer)
	if pl == null or pl.has("wander") or float(pl["frozen"]) > 0.0:
		return false
	var node = pl.get("node")
	if node == null or not is_instance_valid(node):
		return false
	var fl: Dictionary = StoryActions.flags_of(pl["rec"])
	var pool: Array = []
	for e in EncounterDB.roaming():
		if enc != "" and String(e) != enc:
			continue
		if enc != "" or not bool(fl.get(EncounterDB.flag_done(String(e)), false)):
			pool.append(String(e))
	if pool.is_empty():
		return false
	var pick: String = pool[randi() % pool.size()]
	var p := ((node as Node2D).position + Vector2.from_angle(randf() * TAU) * randf_range(180.0, 260.0)).clamp(Vector2(MARGIN, MARGIN), size - Vector2(MARGIN, MARGIN))
	var nm := String(((EncounterDB.LIST[pick] as Dictionary)["npc"] as Dictionary)["name"])
	var obj := {"uid": "wander:" + pick, "kind": "wanderer", "label": "Porozmawiaj: " + nm, "pos": p, "type": "wander", "enc": pick}
	pl["wander"] = {"obj": obj, "t": WANDER_LIFE}
	pl["wander_objs"] = [obj]
	srv.send_ev(peer, "wander", {"obj": obj})
	srv.say(peer, "Na drodze pojawił się wędrowiec: %s." % nm)
	return true

func clear_wander(peer: int) -> void:
	var pl = srv.peers.get(peer)
	if pl == null or not pl.has("wander"):
		return
	var uid := String((pl["wander"]["obj"] as Dictionary)["uid"])
	pl.erase("wander")
	pl["wander_objs"] = []
	srv.send_ev(peer, "wander_off", {"uid": uid})

func _tick_events(delta: float) -> void:
	_tick_wander(delta)
	_boss_t -= delta
	if _boss_t <= 0.0:
		_boss_t = WORLD_BOSS_EVERY
		if not world_boss_alive():
			spawn_world_boss(srv.world_boss_for(self), Vector2.ZERO)
	_raid_t -= delta
	if _raid_t <= 0.0:
		_raid_t = RAID_EVERY
		if _raid_mobs.is_empty():
			start_raid()
	if not _raid_mobs.is_empty():
		var alive := false
		for m in _raid_mobs:
			if is_instance_valid(m) and not (m as Enemy).dead:
				alive = true
		if not alive:
			_raid_mobs.clear()
			srv.on_raid_won(self)

## Boss świata: pojawia się w jednym z rogów mapy (albo w podanym miejscu), serwer ogłasza to wszystkim w strefie.
func spawn_world_boss(bid: String, at: Vector2) -> void:
	if not BossDB.has(bid):
		return
	var center := at if at != Vector2.ZERO else (BOSS_SPOTS[randi() % BOSS_SPOTS.size()] as Vector2)
	var lv := srv.average_level(self)
	_spawn_boss(bid, {"hp": 1.0 + 0.04 * lv, "dmg": 1.0 + 0.03 * lv, "xp": 1.0}, center, false)
	var bd := BossDB.get_data(bid)
	srv.broadcast_zone_chat(self, "server", "ŚWIAT", "Na Pustkowiu pojawił się boss: %s! Szukaj go na mapie (pasek życia u góry)." % String(bd.get("name", bid)))

## Najazd: kilku elitarnych wrogów naraz; po ich pokonaniu wszyscy w strefie dostają nagrodę.
func start_raid() -> void:
	var pool := srv.species_pool(self)
	var at := _random_spawn_point()
	_raid_mobs.clear()
	for i in 6:
		var e := spawn_mob(pool[randi() % pool.size()], at + Vector2(randf_range(-120.0, 120.0), randf_range(-120.0, 120.0)), true)
		if e != null:
			e.aggro = 900.0
			_raid_mobs.append(e)
	srv.broadcast_zone_ev(self, "banner", {"title": "NAJAZD", "sub": "Elitarni wrogowie na Pustkowiu"})
	srv.broadcast_zone_chat(self, "server", "ŚWIAT", "Najazd! Sześciu elitarnych wrogów wyszło z cienia — pokonajcie ich razem, a dostaniecie nagrodę.")

func _random_spawn_point() -> Vector2:
	var pos := Vector2.ZERO
	for i in 12:
		pos = Vector2(randf_range(MARGIN + 40.0, size.x - MARGIN - 40.0), randf_range(MARGIN + 40.0, size.y - MARGIN - 40.0))
		if pos.distance_to(spawn) < MmoServer.SAFE_RADIUS + 300.0:
			continue
		var ok := true
		for id in peer_ids:
			var p := srv.player_of(int(id))
			if p != null and local_pos(p).distance_to(pos) < 500.0:
				ok = false
				break
		if ok:
			return pos
	return pos

# --------------------------------------------------------------- fabuła ---

func marks() -> Dictionary:
	var m := {}
	for n in npc_list:
		var id := String(n["id"])
		if id == giver:
			if step > waves.size() and not finished:
				m[id] = "?"
			elif not waves_started and step == 0:
				m[id] = "!"
		elif String(NpcDB.get_data(id).get("role", "")) == "shop":
			m[id] = "$"
	return m

func objective() -> String:
	if kind == "custom":
		return "Wróć portalem na serwer" if cave_state != "fight" else "Pokonaj wszystkie fale (%d)" % waves.size()
	if kind == "cave":
		match cave_state:
			"loot": return "Otwórz skarbiec jaskini"
			"exit": return "Wróć na powierzchnię (portal)"
		return "Pokonaj elitarnych strażników jaskini"
	if kind != "story":
		return "Poluj na potwory, zdobywaj poziomy i złoto."
	return QuestDB.objective(quest_id, step)

func set_step(n: int) -> void:
	step = n

func begin_defense() -> void:
	if waves_started or finished or kind != "story":
		return
	waves_started = true
	set_step(1)
	srv.broadcast_zone_ev(self, "banner", {"title": "WALKA!", "sub": String(QuestDB.get_data(quest_id).get("title", ""))})
	spawn_wave()

func spawn_wave() -> void:
	if wave_i >= waves.size() or finished:
		return
	var wave: Dictionary = waves[wave_i]
	if not bool(wave.get("boss", false)):
		srv.broadcast_zone_ev(self, "banner", {"title": "FALA %d / %d" % [wave_i + 1, waves.size()], "sub": String(wave.get("name", ""))})
	wave_active = true
	wave_i += 1
	set_step(wave_i)
	for entry in wave["enemies"]:
		var id := String(entry[0])
		if id.begins_with("BOSS:"):
			_spawn_boss(id.substr(5), wave)
			continue
		var mods := {}
		if wave.has("hp"):
			mods = {"hp": float(wave["hp"]), "dmg": float(wave.get("dmg", 1.0)), "xp": float(wave.get("xp", 1.0))}
		for i in int(entry[1]):
			spawn_mob(id, _edge_spawn(), bool(wave.get("elite", false)) or (entry.size() > 2 and bool(entry[2])), mods, String(entry[3]) if entry.size() > 3 else "")

## Sekretna jaskinia bez fal: potwory śpią w zasadzkach i budzą się, gdy ktoś podejdzie lub je zaatakuje.
func _spawn_ambush() -> void:
	var packs: Array = []
	for w in waves:
		for entry in w["enemies"]:
			if not String(entry[0]).begins_with("BOSS:"):
				packs.append([entry, w])
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var centers := SecretDB.ambush_centers(packs.size(), size, MARGIN, spawn, rng)
	for n in packs.size():
		var entry: Array = packs[n][0]
		var wave: Dictionary = packs[n][1]
		var mods := {}
		if wave.has("hp"):
			mods = {"hp": float(wave["hp"]), "dmg": float(wave.get("dmg", 1.0)), "xp": float(wave.get("xp", 1.0))}
		for i in int(entry[1]):
			var at: Vector2 = (centers[n] as Vector2) + Vector2(rng.randf_range(-110.0, 110.0), rng.randf_range(-90.0, 90.0))
			var e := spawn_mob(String(entry[0]), at, bool(wave.get("elite", false)) or (entry.size() > 2 and bool(entry[2])), mods, String(entry[3]) if entry.size() > 3 else "")
			if e != null:
				e.dormant = true
				e.aggro = 460.0
				if bool(wave.get("elite", false)) and zone.has("camp"):
					e.died.connect(func(_x): camp_disarm())
	wave_i = waves.size()
	set_step(wave_i)
	wave_active = true
	for p in zone.get("prisoners", []):
		add_extra_obj({"uid": "pris:" + String(p["id"]), "kind": "cage", "label": String(p.get("label", "Uwolnij więźnia")), "pos": p["pos"], "type": "prisoner", "pid": String(p["id"])})
	srv.broadcast_zone_chat(self, "system", "", "Potwory czekają w mroku — atakują, gdy podejdziesz zbyt blisko.")

func _spawn_boss(bid: String, wave: Dictionary, center: Vector2 = BossDB.ARENA_CENTER, pull_players: bool = true) -> void:
	if not BossDB.has(bid):
		return
	var b := BOSS_SCENE.instantiate() as BossBig
	b.server_mode = true
	b.setup_boss(bid)
	if wave.has("hp"):
		b.apply_mods(float(wave["hp"]), float(wave.get("dmg", 1.0)), float(wave.get("xp", 1.0)))
	# boss skaluje się z liczbą graczy
	if peer_ids.size() > 1:
		b.max_health *= 1.0 + 0.6 * float(peer_ids.size() - 1)
		b.health = b.max_health
	if bid == "czarny_kruk_odrodzony" and srv.max_rep(self) >= 3:
		b.max_health *= 0.9
		b.health = b.max_health
		srv.broadcast_zone_chat(self, "system", "", "Wioski wspierają cię w walce: Czarny Kruk jest osłabiony (−10% zdrowia).")
	b.net_id = "%d_b%d" % [slot, _seq]
	_seq += 1
	entities.add_child(b)
	b.position = center + Vector2(0.0, -60.0)
	b.arena_center = global_position + center
	b.arena_radius = BossDB.ARENA_RADIUS
	b.set_bounds_rect(MARGIN, size.x - MARGIN, MARGIN, size.y - MARGIN)
	_boss = b
	boss_id = bid
	var inside := center + Vector2(0.0, BossDB.ARENA_RADIUS * 0.62)
	for id in peer_ids:
		var p := srv.player_of(int(id))
		if pull_players and p != null and local_pos(p).distance_to(center) > BossDB.ARENA_RADIUS - 100.0:
			p.position = inside + Vector2(randf_range(-60.0, 60.0), 0.0)
	var bd := BossDB.get_data(bid)
	srv.broadcast_zone_ev(self, "banner", {"title": String(bd.get("name", "BOSS")).to_upper(), "sub": String(bd.get("title", ""))})
	b.phase_changed.connect(func(_i: int, label: String): srv.broadcast_zone_ev(self, "banner", {"title": label, "sub": String(bd.get("name", ""))}))
	b.died.connect(srv.on_mob_died.bind(self))
	b.start_intro()

## Obóz niewolników: naczelnik padł — strażnicy ze stożkami odchodzą.
func camp_disarm() -> void:
	if camp_off:
		return
	camp_off = true
	srv.broadcast_zone_ev(self, "camp_off", {})
	srv.broadcast_zone_chat(self, "system", "", "Naczelnik padł — reszta strażników rozbiega się w popłochu.")

## Obóz niewolników: strażnik zauważył intruza — stożki znikają, a cała straż obozu rusza do ataku.
func camp_alarm() -> void:
	if camp_off:
		return
	camp_off = true
	srv.broadcast_zone_ev(self, "camp_off", {})
	for c in entities.get_children():
		if c is Enemy and (c as Enemy).dormant:
			(c as Enemy).dormant = false
	srv.broadcast_zone_chat(self, "system", "", "Alarm! Strażnicy zauważyli intruza i ruszają do ataku!")

## Jeniec uwolniony: strażnicy odchodzą, a na starcie pojawia się wyjście.
func camp_freed() -> void:
	if not camp_off:
		camp_off = true
		srv.broadcast_zone_ev(self, "camp_off", {})
	for o in extra_objs:
		if String(o.get("uid", "")) == "campportal":
			return
	add_extra_obj({"uid": "campportal", "kind": "portal", "label": "Wróć na pustkowie", "pos": (zone["camp"] as Dictionary).get("start", spawn) + Vector2(0.0, -90.0), "type": "portal"})

func _tick_cave(delta: float) -> void:
	if _start_t >= 0.0:
		_start_t -= delta
		if _start_t < 0.0:
			_start_t = -1.0
			var banner: Array = zone.get("intro_banner", ["", ""])
			srv.broadcast_zone_ev(self, "banner", {"title": String(banner[0]), "sub": String(banner[1])})
			if kind == "cave" and zone.has("camp"):
				for pid in peer_ids:
					srv._open_dialog(int(pid), (zone["camp"] as Dictionary).get("intro", []), UiKit.ACCENT2, "")
			elif kind == "cave":
				srv.broadcast_zone_chat(self, "system", "", "Wyzwanie: oczyść jaskinię w 120 s, by dostać dodatkową nagrodę.")
			waves_started = true
			if kind == "cave":
				_spawn_ambush()
			else:
				spawn_wave()
		return
	if kind == "cave" and cave_state == "fight":
		cave_t += delta

func _spawn_cave_boss() -> void:
	var bid := CaveBossDB.id_for(cave_id)
	if not BossDB.has(bid):
		_cave_cleared()
		return
	_cave_boss_out = true
	srv.broadcast_zone_ev(self, "banner", {"title": "STRAŻNIK JASKINI", "sub": String(BossDB.get_data(bid).get("title", ""))})
	_spawn_boss(bid, {})
	if _boss != null and is_instance_valid(_boss):
		_boss.died.connect(func(_e): _cave_cleared())
	else:
		_cave_cleared()

func _cave_cleared() -> void:
	if cave_state != "fight":
		return
	cave_state = "loot"
	cave_bonus = cave_t <= 120.0
	var ob: Array = zone.get("outro_banner", ["JASKINIA OCZYSZCZONA", ""])
	srv.broadcast_zone_ev(self, "banner", {"title": String(ob[0]), "sub": String(ob[1])})
	add_extra_obj({"uid": "cavechest", "kind": "chest", "label": "Skarbiec jaskini", "pos": Vector2(1100.0, 760.0), "type": "cavechest"})

func _custom_cleared() -> void:
	if cave_state != "fight":
		return
	cave_state = "loot"
	var ob: Array = zone.get("outro_banner", ["ZWYCIĘSTWO", ""])
	srv.broadcast_zone_ev(self, "banner", {"title": String(ob[0]), "sub": String(ob[1])})
	srv.on_custom_cleared(self)
	add_extra_obj({"uid": "custom_portal", "kind": "portal", "label": "Wróć na serwer", "pos": Vector2(1100.0, 900.0), "type": "portal"})

## Własne fale: porażka gracza kończy walkę (jak w oryginale).
func custom_fail() -> void:
	if finished or kind != "custom" or cave_state != "fight":
		return
	finished = true
	_finish_t = 4.0
	srv.broadcast_zone_ev(self, "banner", {"title": "PORAŻKA", "sub": "Fale cię pokonały"})

func _on_wave_cleared() -> void:
	if kind == "custom":
		if wave_i >= waves.size():
			_custom_cleared()
		else:
			set_step(wave_i + 1)
			_next_wave_t = 3.0
		return
	if kind == "cave":
		if wave_i >= waves.size():
			if not _cave_boss_out:
				_spawn_cave_boss()
		else:
			set_step(wave_i + 1)
			_next_wave_t = 3.0
		return
	if wave_i >= waves.size():
		_post_battle()
		return
	var villain: Dictionary = zone.get("villain", {})
	if not villain.is_empty() and int(villain.get("after_wave", -1)) == wave_i:
		_villain_cutscene(villain)
		return
	if _roll_duel():
		_start_duel()
		return
	_next_wave_after_clear()

func _next_wave_after_clear() -> void:
	set_step(wave_i + 1)
	srv.broadcast_zone_ev(self, "banner", {"title": "FALA OCZYSZCZONA", "sub": "Nadchodzą kolejne…"})
	_next_wave_t = 3.0

# ---------------------------------------------------- pojedynek z rycerzem ---

## Czasem między falami rycerz w zbroi wyzywa gracza na pojedynek (tylko gdy w strefie jest jeden gracz).
func _roll_duel() -> bool:
	if kind != "story" or peer_ids.size() != 1 or duels >= 1:
		return false
	if wave_i >= waves.size() or bool(waves[wave_i].get("boss", false)):
		return false
	if quest_id == "zamek_kruka":
		return true
	return randf() < 0.16

func _start_duel() -> void:
	duels += 1
	wave_active = false
	var peer := int(peer_ids[0])
	var kid := srv.roll_knight(peer)
	if quest_id == "zamek_kruka":
		kid = "rycerz_hiper" if randf() < 0.5 else "rycerz_legenda"
	var kd: Dictionary = EnemyDB.get_data(kid)
	var nm := String(kd["name"])
	srv.broadcast_zone_ev(self, "banner", {"title": "POJEDYNEK", "sub": nm})
	var lines: Array = [
		[nm, "Stój, wędrowcze! Moja tarcza jeszcze nie znalazła godnego przeciwnika."],
		[nm, "Walczymy jeden na jednego. Uważaj — każdy cios z przodu odbiję. Chyba że sam zaatakuję."],
	]
	if int(kd.get("knight_tier", 0)) == 2:
		lines.append([nm, "Ta zbroja nie ma sobie równych. Spróbuj ją zarysować."])
	duel_kid = kid
	srv._open_dialog(peer, lines, Color(0.85, 0.85, 0.95), "duel", {"kid": kid})

## Po zamknięciu dialogu rycerz staje do walki obok gracza.
func begin_duel(kid: String) -> void:
	if finished or peer_ids.is_empty() or not EnemyDB.LIST.has(kid):
		return
	var p := srv.player_of(int(peer_ids[0]))
	if p == null:
		return
	var k := ENEMY_SCENE.instantiate() as Enemy
	k.server_mode = true
	k.setup(kid, false, false)
	k.is_duel = true
	k.aggro = 2000.0
	k.net_id = "%d_d%d" % [slot, _seq]
	_seq += 1
	entities.add_child(k)
	var side := 1.0 if p.position.x < size.x * 0.5 else -1.0
	k.position = (p.position + Vector2(260.0 * side, 0.0)).clamp(Vector2(MARGIN + 40.0, MARGIN + 40.0), Vector2(size.x - MARGIN - 40.0, size.y - MARGIN - 40.0))
	k.set_bounds_rect(MARGIN, size.x - MARGIN, MARGIN, size.y - MARGIN)
	k.set_meta("hunt", "duel")   # nie liczy się do fali
	duel_knight = k
	k.died.connect(srv.on_mob_died.bind(self))
	k.died.connect(func(_e): _on_duel_won(kid))

func _on_duel_won(kid: String) -> void:
	srv.on_duel_won(self, kid)
	srv.broadcast_zone_ev(self, "banner", {"title": "ZWYCIĘSTWO", "sub": "Pojedynek wygrany"})
	await get_tree().create_timer(2.2).timeout
	if is_instance_valid(self) and not finished:
		_next_wave_after_clear()

func _villain_cutscene(villain: Dictionary) -> void:
	var who := String(villain.get("who", "Wróg"))
	srv.broadcast_zone_ev(self, "banner", {"title": "HOLD", "sub": "Niebo ciemnieje…"})
	var last := ""
	for ln in villain.get("lines", []):
		var txt := String(ln)
		if txt.contains("%s"):
			txt = txt % "kurczaku"
		srv.broadcast_zone_chat(self, "server", who, txt)
		last = txt
	if last != "Ostatnia fala! Zmiażdżcie ich!":
		srv.broadcast_zone_chat(self, "server", who, "Ostatnia fala! Zmiażdżcie ich!")
	_next_wave_t = 6.0

func _post_battle() -> void:
	set_step(waves.size() + 1)
	var ob: Array = zone.get("outro_banner", ["ŚWIT", "Udało się"])
	srv.broadcast_zone_ev(self, "banner", {"title": String(ob[0]), "sub": String(ob[1])})
	srv.broadcast_zone_chat(self, "system", "", "Porozmawiaj z: %s" % String(NpcDB.get_data(giver).get("name", "sojusznik")))

func finish_story(first_peer: int) -> void:
	if finished or kind != "story":
		return
	finished = true
	_finish_t = 3.0
	_finish_info = {"by": first_peer}
	srv.on_story_finished(self)

# ------------------------------------------------------------- snapshot ---

func build_snapshot() -> Dictionary:
	var ps: Array = []
	for id in peer_ids:
		var p := srv.player_of(int(id))
		if p == null:
			continue
		var pl: Dictionary = srv.peers[id]
		ps.append({
			"id": int(id), "x": p.position.x, "y": p.position.y, "facing": p.facing,
			"hp": p.hp, "max_hp": p.max_hp, "energy": p.energy, "max_energy": p.max_energy, "state": p.state,
			"moving": p.visual.moving, "spin": p.visual.spin_angle, "spin_speed": p.visual.spin_speed,
			"berserk": p.berserk_t > 0.0, "lv": int(pl["rec"]["level"]), "name": String(pl["name"]), "cd": p.skill_cd.duplicate(),
		})
	var es: Array = []
	for c in entities.get_children():
		if not (c is Enemy) or String((c as Enemy).net_id) == "":
			continue
		var e := c as Enemy
		var entry := {"id": String(e.net_id), "species": String(e.species), "x": e.position.x, "y": e.position.y,
			"facing": e.facing, "health": e.health, "max_health": e.max_health, "state": e.state, "moving": e.visual.moving}
		if e is BossBig:
			entry["boss_id"] = (e as BossBig).boss_id
		es.append(entry)
	return {"players": ps, "enemies": es, "sup": SupportOps.snapshot(self), "z": {"step": step, "waves": waves.size(), "wave_i": wave_i, "active": wave_active,
		"marks": marks(), "obj": objective(), "title": (String(QuestDB.get_data(quest_id).get("label", "")) + " — " + String(QuestDB.get_data(quest_id).get("title", ""))) if kind == "story" else zone_title()}}
