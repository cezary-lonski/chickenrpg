class_name MmoServer
extends Node
## Logika serwera ChickenSerwer: instancje stref (świat do polowania + rozdziały kampanii), gracze,
## fabuła, XP/loot, sklep, czat i komendy. Okno (UiServerApp) i tryb --headless używają tej samej klasy.

signal log_line(text: String)
signal players_changed()
signal info_changed()
signal stopped()

const SPAWN := Vector2(1500.0, 1000.0)
const SAFE_RADIUS := 380.0
const SNAP_INTERVAL := 1.0 / 15.0
const RESPAWN_SECS := 4.0
const SAVE_EVERY := 30.0
const DIALOG_FREEZE := 90.0
const SHOP_SLOTS := ["weapon", "armor", "helmet", "boots", "amulet", "accessory", "consumable", "throwable"]
const SELL_RATIO := 0.4

var cfg := {
	"name": "ChickenSerwer", "port": Mmo.DEFAULT_PORT, "max_players": 16, "motd": "Witaj na serwerze! T = czat, E = rozmowa, /help = komendy.",
	"allow_admin_class": true, "admins": [], "banned": [], "auto_update": true,
}
var chars := ServerChars.new()
var running := false
var peers: Dictionary = {}          # peer id -> dane gracza (patrz on_login)
var instances: Dictionary = {}      # klucz strefy -> ZoneInstance
var info := {"local_ip": "", "external_ip": "", "mapped": false, "upnp": "", "busy": false}
var cmds := ServerCmds.new()
var updater: ServerUpdater = null

var _snap_acc := 0.0
var _save_acc := 0.0
var _token_seq := 0
var _upnp_thread: Thread = null
var _upnp: UPNP = null
var _upnp_port := 0
var _gen := 0
var _started_at := 0.0
var _fxroot: Node2D
var pending_custom: Dictionary = {}   # klucz instancji własnych fal -> konfiguracja
var ranking: Array = []           # ranking wyzwań: [{name, rounds, lv, cls}]

# ------------------------------------------------------------------ start/stop ---

static func config_file() -> String:
	return ServerChars.dir() + "/config.json"

func load_config() -> void:
	if FileAccess.file_exists(config_file()):
		var f := FileAccess.open(config_file(), FileAccess.READ)
		if f:
			var v = JSON.parse_string(f.get_as_text())
			f.close()
			if typeof(v) == TYPE_DICTIONARY:
				for k in (v as Dictionary):
					cfg[k] = v[k]
	cfg["port"] = clampi(int(cfg["port"]), 1, 65535)
	cfg["max_players"] = clampi(int(cfg["max_players"]), 1, Mmo.MAX_PLAYERS)

func save_config() -> void:
	DirAccess.make_dir_recursive_absolute(ServerChars.dir())
	var f := FileAccess.open(config_file(), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(cfg, "\t"))
		f.close()

func start() -> int:
	if running:
		return OK
	chars.load_all()
	_load_ranking()
	var err := Mmo.start_server(int(cfg["port"]), int(cfg["max_players"]))
	if err != OK:
		log_msg("Nie udało się uruchomić serwera na porcie %d: %s" % [int(cfg["port"]), error_string(err)])
		return err
	Mmo.server = self
	running = true
	_started_at = Time.get_unix_time_from_system()
	GameState.rpg = {"active": true, "mode": "server"}   # tryb top-down (jak kampania)
	if _fxroot == null:
		_fxroot = Node2D.new()
		add_child(_fxroot)
	Fx.set_world(_fxroot, null)
	_start_upnp(int(cfg["port"]))
	save_config()
	log_msg("Serwer „%s” działa na porcie %d (UDP), limit graczy: %d, zapisanych postaci: %d." % [cfg["name"], int(cfg["port"]), int(cfg["max_players"]), chars.records.size()])
	info_changed.emit()
	return OK

## Zamknięcie okna serwera (X) nie woła stop() — zapisujemy postacie, żeby nic nie przepadło.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		if running:
			chars.save_all(true)

func stop() -> void:
	if not running:
		return
	for id in peers.keys():
		_say_to(int(id), "Serwer jest zamykany.", "system")
	for id in peers.keys():
		_drop_player(int(id), false)
	chars.save_all(true)
	_clear_upnp()
	Mmo.server = null
	Mmo.stop()
	for k in instances.keys():
		if is_instance_valid(instances[k]):
			instances[k].queue_free()
	instances.clear()
	running = false
	log_msg("Serwer zatrzymany.")
	info_changed.emit()
	stopped.emit()

func log_msg(text: String) -> void:
	var line := "[%s] %s" % [Time.get_time_string_from_system(), text]
	print(line)
	log_line.emit(line)

func uptime() -> int:
	return int(Time.get_unix_time_from_system() - _started_at) if running else 0

# ------------------------------------------------------------------- UPnP ---

func _local_ipv4() -> String:
	for addr in IP.get_local_addresses():
		if addr.contains(".") and not addr.begins_with("127.") and not addr.begins_with("169.254."):
			return addr
	return "127.0.0.1"

func _start_upnp(port: int) -> void:
	info = {"local_ip": _local_ipv4(), "external_ip": "", "mapped": false, "upnp": "Szukam routera (UPnP)…", "busy": true}
	_upnp_port = port
	_gen += 1
	_upnp_thread = Thread.new()
	_upnp_thread.start(_upnp_worker.bind(port, _gen))

func _upnp_worker(port: int, gen: int) -> void:
	var upnp := UPNP.new()
	var res := {"ok": false, "ext": "", "err": "", "port": port, "gen": gen, "upnp": upnp}
	if upnp.discover(1800, 2) != UPNP.UPNP_RESULT_SUCCESS:
		res["err"] = "Router nie odpowiedział na UPnP — przekieruj port UDP %d ręcznie." % port
	else:
		var gw := upnp.get_gateway()
		if gw == null or not gw.is_valid_gateway():
			res["err"] = "Router nie obsługuje UPnP — przekieruj port UDP %d ręcznie." % port
		else:
			var e := gw.add_port_mapping(port, port, "ChickenSerwer", "UDP", 0)
			if e == UPNP.UPNP_RESULT_SUCCESS:
				res["ok"] = true
				res["ext"] = gw.query_external_address()
			else:
				res["err"] = "UPnP: nie udało się otworzyć portu (kod %d) — przekieruj UDP %d ręcznie." % [e, port]
	call_deferred("_on_upnp_done", res)

func _on_upnp_done(res: Dictionary) -> void:
	if _upnp_thread != null:
		_upnp_thread.wait_to_finish()
		_upnp_thread = null
	var up: UPNP = res.get("upnp")
	if int(res.get("gen", -1)) != _gen or not running:
		if up != null and bool(res.get("ok", false)):
			var gw := up.get_gateway()
			if gw != null:
				gw.delete_port_mapping(int(res.get("port", 0)), "UDP")
		return
	_upnp = up
	info["busy"] = false
	info["mapped"] = bool(res.get("ok", false))
	info["external_ip"] = String(res.get("ext", ""))
	info["upnp"] = "Port %d otwarty przez UPnP." % _upnp_port if bool(res.get("ok", false)) else String(res.get("err", ""))
	log_msg(String(info["upnp"]) + ((" Adres zewnętrzny: %s" % info["external_ip"]) if info["external_ip"] != "" else ""))
	info_changed.emit()

func _clear_upnp() -> void:
	_gen += 1
	if _upnp_thread != null:
		_upnp_thread.wait_to_finish()
		_upnp_thread = null
	if _upnp != null and bool(info.get("mapped", false)):
		var gw := _upnp.get_gateway()
		if gw != null:
			gw.delete_port_mapping(_upnp_port, "UDP")
	_upnp = null

# ----------------------------------------------------------------- instancje ---

func _free_slot() -> int:
	var used := {}
	for k in instances:
		used[(instances[k] as ZoneInstance).slot] = true
	var s := 0
	while used.has(s):
		s += 1
	return s

func get_instance(key: String) -> ZoneInstance:
	if instances.has(key) and is_instance_valid(instances[key]):
		return instances[key]
	var inst := ZoneInstance.new()
	inst.setup(self, key, _free_slot())
	add_child(inst)
	instances[key] = inst
	return inst

func inst_of(id: int) -> ZoneInstance:
	var pl = peers.get(id)
	return pl["inst"] if pl != null else null

func total_mobs() -> int:
	var n := 0
	for k in instances:
		n += (instances[k] as ZoneInstance).alive_enemies().size()
	return n

func average_level(inst: ZoneInstance = null) -> float:
	var s := 0.0
	var c := 0
	for pl in peers.values():
		if inst == null or pl["inst"] == inst:
			s += float(pl["rec"]["level"])
			c += 1
	return s / float(c) if c > 0 else 1.0

func species_pool(inst: ZoneInstance) -> Array:
	var top := clampi(1 + int(average_level(inst) / 12.0), 1, 5)
	var out: Array = []
	for id in EnemyDB.LIST:
		var d: Dictionary = EnemyDB.LIST[id]
		if bool(d.get("boss", false)):
			continue
		var t := int(d.get("tier", 1))
		if t <= top and t >= maxi(1, top - 1):
			out.append(String(id))
	if out.is_empty():
		out.append("wrzos")
	return out

# --------------------------------------------------------------------- fabuła ---

static func story_of(rec: Dictionary) -> Dictionary:
	if not (rec.get("story") is Dictionary):
		rec["story"] = {}
	var s: Dictionary = rec["story"]
	var a2start := QuestDB.act_start(2)
	var in_act2 := a2start >= 0 and int(s.get("chapter", -1)) >= a2start and int(s.get("chapter", -1)) < a2start + QuestDB.act_count(2)
	var q_ok := s.has("quest") and ((String(s["quest"]) == "" and in_act2) or ZoneDB.has(String(s["quest"])))
	if not q_ok:
		var first := _first_playable(0)
		s["quest"] = String(QuestDB.chapter(first).get("id", "obrona_wioski"))
		s["chapter"] = first
	if not (s.get("done") is Array):
		s["done"] = []
	if not (s.get("flags") is Dictionary):
		s["flags"] = {}
	if not rec.has("zone"):
		rec["zone"] = "story"
	s["best"] = maxi(int(s.get("best", 0)), int(s.get("chapter", 0)))
	return s

static func _first_playable(from_index: int) -> int:
	var i := from_index
	while i < QuestDB.count():
		if ZoneDB.has(String(QuestDB.chapter(i).get("id", ""))):
			return i
		i += 1
	return 0

func zone_key_for(rec: Dictionary) -> String:
	var s := story_of(rec)
	if String(rec.get("zone", "story")) == "swiat" or act2_needs_choice(rec):
		return "swiat"
	return String(s["quest"])

# ------------------------------------------------------ Akt II: mapa świata ---

static func act2_state(rec: Dictionary) -> Dictionary:
	if not (rec.get("gsx") is Dictionary):
		rec["gsx"] = {}
	var gsx: Dictionary = rec["gsx"]
	if not (gsx.get("act2") is Dictionary):
		gsx["act2"] = {"liberated": [], "rep": 0, "started": false}
	var s: Dictionary = gsx["act2"]
	if not (s.get("liberated") is Array):
		s["liberated"] = []
	if not s.has("rep"):
		s["rep"] = 0
	return s

## Akt II bez wybranej misji: gracz musi wybrać wioskę na mapie świata.
static func act2_needs_choice(rec: Dictionary) -> bool:
	var s := story_of(rec)
	var start := QuestDB.act_start(2)
	if start < 0:
		return false
	var ch := int(s.get("chapter", 0))
	return ch >= start and ch < start + QuestDB.act_count(2) and String(s["quest"]) == ""

static func act2_available(rec: Dictionary, id: String) -> bool:
	var lib: Array = act2_state(rec)["liberated"]
	if id in lib or id not in Act2DB.ORDER:
		return false
	if id == Act2DB.FINAL:
		return lib.size() >= Act2DB.ORDER.size() - 1
	return true

func map_state(rec: Dictionary) -> Dictionary:
	var st := act2_state(rec)
	var avail := {}
	for id in Act2DB.ORDER:
		avail[id] = act2_available(rec, String(id))
	return {"liberated": (st["liberated"] as Array).duplicate(), "rep": int(st["rep"]), "started": bool(st.get("started", false)), "avail": avail}

func open_map(id: int) -> void:
	var pl = peers.get(id)
	if pl != null:
		send_ev(id, "worldmap", map_state(pl["rec"]))

## Mapa świata (M): podróż do osiągniętego już rozdziału (powtórka); dalsza fabuła idzie od niego po kolei.
func _travel(id: int, index: int) -> void:
	var pl = peers.get(id)
	if pl == null:
		return
	var rec: Dictionary = pl["rec"]
	var inst: ZoneInstance = pl["inst"]
	if inst != null and inst.kind not in ["story", "swiat"]:
		_say_to(id, "Najpierw zakończ walkę (/wyjdz).", "error")
		return
	var story := story_of(rec)
	if index < 0 or index >= QuestDB.count() or index > int(story["best"]):
		_say_to(id, "To miejsce jest jeszcze zablokowane.", "error")
		return
	var qid := String(QuestDB.chapter(index).get("id", ""))
	if not ZoneDB.has(qid):
		_say_to(id, "Do tego miejsca nie da się podróżować z mapy (użyj wyboru wioski, /mapa).", "error")
		return
	if index == int(story["chapter"]) and rec.get("zone", "story") == "story" and inst != null and inst.kind == "story":
		return
	story["chapter"] = index
	story["quest"] = qid
	rec["zone"] = "story"
	chars.mark_dirty()
	enter_zone(id, qid)

func _act2_pick(id: int, mission: String) -> void:
	var pl = peers.get(id)
	if pl == null:
		return
	var rec: Dictionary = pl["rec"]
	if not act2_needs_choice(rec):
		_say_to(id, "Mapa świata jest dostępna tylko między misjami Aktu II.", "error")
		return
	if not act2_available(rec, mission):
		_say_to(id, "Ta misja jest teraz niedostępna.", "error")
		return
	var story := story_of(rec)
	story["chapter"] = QuestDB.act_start(2) + (act2_state(rec)["liberated"] as Array).size()
	story["quest"] = mission
	rec["zone"] = "story"
	chars.mark_dirty()
	enter_zone(id, mission)

## Przejście do następnego rozdziału po ukończeniu questa (logika village.gd::_finish_story).
func _advance_story(id: int, rec: Dictionary, qid: String, first: bool) -> void:
	var story := story_of(rec)
	var is_act2 := int(QuestDB.get_data(qid).get("act", 1)) == 2
	var nxt := 0
	var nq := ""
	if is_act2:
		ServerCtx.run(rec, func(): Act2DB.liberate(qid))
		story = story_of(rec)
		var lib: Array = act2_state(rec)["liberated"]
		nxt = mini(QuestDB.act_start(2) + lib.size(), QuestDB.count())
		if lib.size() >= Act2DB.ORDER.size():
			while nxt < QuestDB.count() and String(QuestDB.chapter(nxt).get("id", "")) in story["done"]:
				nxt += 1
			if nxt < QuestDB.count():
				nq = String(QuestDB.chapter(nxt).get("id", ""))
		if first and qid == Act2DB.FINAL and int(act2_state(rec)["rep"]) >= 3:
			rec["gold"] = int(rec["gold"]) + 500
			ServerChars.inv_add(rec, "sztabka_kurczalium", 1)
			_say_to(id, "Wdzięczność wiosek: dodatkowa nagroda — 500 złota i sztabka kurczalium!", "system")
	else:
		nxt = QuestDB.index_of(qid) + 1
		if nxt < QuestDB.count() and QuestDB.act_of(nxt) != 2:
			nq = String(QuestDB.chapter(nxt).get("id", ""))
	if nxt >= QuestDB.count() or (nq != "" and not ZoneDB.has(nq)):
		rec["zone"] = "swiat"
		_say_to(id, "Kampania ukończona! Przenoszę Cię na Pustkowie.", "system")
		return
	story["chapter"] = nxt
	story["quest"] = nq
	if nq == "":
		_say_to(id, "Wybierz kolejną wioskę na mapie świata (komenda /mapa).", "system")

func _act_cinematic(qid: String) -> Array:
	if qid == "krol_i_kruk":
		return [
			"Czarny Kruk, ranny, rozpościera skrzydła i ucieka w kłębach dymu.",
			"Królowa Aurelia: Fortecę mamy z powrotem, ale wojna się nie skończyła. Kruk obsadził wioski swoimi wronami.",
			"AKT I UKOŃCZONY. Odblokowano AKT II: ZEMSTA NA CZARNYM KRUKU.",
		]
	if qid == Act2DB.FINAL:
		return [
			"Czarny Kruk Odrodzony rozsypuje się w czarny pył. Ostatnie pióro opada do twoich stóp i gaśnie.",
			"Kapitan Odwetu Hanna: Zrobiłeś to. Wszystkie wioski są wolne. Nikt już nie zapomni twojego imienia.",
			"AKT II UKOŃCZONY. Przed tobą ostatnie rozdziały kampanii.",
		]
	return []

func max_rep(inst: ZoneInstance) -> int:
	var m := 0
	for id in inst.peer_ids:
		if peers.has(id):
			m = maxi(m, int(act2_state(peers[id]["rec"])["rep"]))
	return m

## Zmienia strefę gracza: usuwa jego postać ze starej instancji i tworzy ją w nowej.
func enter_zone(id: int, key: String) -> void:
	var pl = peers.get(id)
	if pl == null:
		return
	var old: ZoneInstance = pl.get("inst")
	var old_node = pl.get("node")
	if old != null and is_instance_valid(old):
		old.remove_player(id)
	if old_node != null and is_instance_valid(old_node):
		old_node.queue_free()
	var inst := get_instance(key)
	var node := inst.add_player(id, pl["rec"])
	node.died.connect(_on_player_died.bind(id))
	pl["inst"] = inst
	pl["node"] = node
	pl["respawn"] = 0.0
	pl["frozen"] = 0.0
	pl["token"] = {}
	pl["shop"] = false
	pl["forge"] = {}
	pl["panel"] = ""
	Mmo.send_zone(id, inst.zone_info())
	if act2_needs_choice(pl["rec"]):
		open_map(id)
	SupportOps.spawn_for(self, id, inst)
	push_prog(id)
	StoryActions.push_side(self, id, inst, true)
	if old != null and is_instance_valid(old) and old != inst:
		_cleanup_instance(old)
	_push_roster()
	players_changed.emit()
	var seen_key := "intro:" + inst.quest_id
	if inst.kind == "story" and inst.step == 0 and not inst.waves_started and not bool(story_of(pl["rec"])["flags"].get(seen_key, false)):
		story_of(pl["rec"])["flags"][seen_key] = true
		var zone: Dictionary = inst.zone
		var banner: Array = zone.get("intro_banner", ["", ""])
		send_ev(id, "banner", {"title": String(banner[0]), "sub": String(banner[1])})
		var lines := _with_title(zone.get("intro", []), NpcDB.hero_title(String(pl["rec"]["char"])))
		if not lines.is_empty():
			_open_dialog(id, lines, UiKit.ACCENT2, "")

func _with_title(lines: Array, title: String) -> Array:
	var out: Array = []
	for ln in lines:
		var pair: Array = (ln as Array).duplicate()
		if pair.size() >= 2:
			var txt := String(pair[1])
			if txt.contains("%s"):
				txt = txt % title
			pair[1] = txt
		out.append(pair)
	return out

func _cleanup_instance(inst: ZoneInstance) -> void:
	if inst.key == "swiat" or not inst.is_empty():
		return
	instances.erase(inst.key)
	inst.queue_free()

func _open_dialog(id: int, lines: Array, accent: Color, action: String, extra: Dictionary = {}) -> void:
	var pl = peers.get(id)
	if pl == null:
		return
	_token_seq += 1
	pl["token"] = {"n": _token_seq, "action": action, "extra": extra}
	pl["frozen"] = DIALOG_FREEZE
	send_ev(id, "dialog", {"token": _token_seq, "lines": lines, "accent": accent})

## Interakcja (klawisz E): obiekt (skrzynia, dźwignia, cel, tablica…) albo rozmowa z najbliższym NPC.
func _interact(id: int) -> void:
	var pl = peers.get(id)
	var inst: ZoneInstance = pl["inst"] if pl != null else null
	var node := player_of(id)
	if inst == null or node == null or inst.kind == "swiat" or node.state == Player.S.DEAD or float(pl["frozen"]) > 0.0:
		return
	var obj := StoryActions.nearest_object(self, id, inst, node.position)
	var best := ""
	var best_d := StoryActions.NPC_RADIUS
	for n in inst.npc_list:
		var d: float = (n["pos"] as Vector2).distance_to(node.position)
		if d < best_d:
			best_d = d
			best = String(n["id"])
	var obj_d := (obj["pos"] as Vector2).distance_to(node.position) if not obj.is_empty() else 1.0e9
	if not obj.is_empty() and (best == "" or obj_d <= best_d + 30.0):
		StoryActions.activate(self, id, inst, obj)
		return
	if best != "":
		_talk_npc(id, inst, best)

## Rozmowa z NPC; logika odpowiada village.gd::_talk_to.
func _talk_npc(id: int, inst: ZoneInstance, npc: String) -> void:
	var pl: Dictionary = peers[id]
	if inst.kind != "story":
		return
	if StoryActions.try_package(self, id, inst, npc):
		return
	var rec: Dictionary = pl["rec"]
	var story := story_of(rec)
	var flags: Dictionary = story["flags"]
	var char_id := String(rec["char"])
	var accent: Color = NpcDB.get_data(npc).get("accent", UiKit.ACCENT)
	var step := inst.step
	var q := inst.quest_id
	var lines: Array = NpcDB.lines_for(npc, step, flags, char_id, q)
	var action := ""
	if npc == inst.giver:
		var nm := String(NpcDB.get_data(npc).get("name", "?"))
		if step > inst.waves.size() and not inst.finished:
			var gate_post := ChapterExtras.remaining_text(q, "post", flags) if ChapterExtras.has(q) else ""
			if gate_post != "":
				lines = [[nm, "Jeszcze nie koniec. Najpierw: %s." % gate_post]]
			else:
				action = "finish"
		elif not inst.waves_started and step == 0:
			var gate_pre := ChapterExtras.remaining_text(q, "pre", flags) if ChapterExtras.has(q) else ""
			if gate_pre != "":
				lines = [[nm, "Zanim ruszymy do walki, musimy się przygotować: %s." % gate_pre]]
			else:
				action = "begin"
	elif ChapterExtras.NPCS.has(npc) and ChapterExtras.has(q):
		StoryActions.talk_extra(self, id, inst, npc)
		return
	elif npc == "kupiec":
		action = "shop"
	elif npc == "kowal":
		action = "kowal"
	_open_dialog(id, lines, accent, action, {"npc": npc})

## Okno wyboru (klient: UiChoice). Wynik wraca przez act "choice_pick".
func open_choice(id: int, prompt: String, options: Array, accent: Color, data: Dictionary) -> void:
	var pl = peers.get(id)
	if pl == null:
		return
	_token_seq += 1
	pl["choice"] = {"n": _token_seq, "data": data}
	pl["frozen"] = DIALOG_FREEZE
	send_ev(id, "choice", {"token": _token_seq, "prompt": prompt, "options": options, "accent": accent})

func _choice_pick(id: int, token: int, index: int) -> void:
	var pl = peers.get(id)
	if pl == null:
		return
	var ch: Dictionary = pl.get("choice", {})
	if ch.is_empty() or int(ch.get("n", -1)) != token:
		return
	pl["choice"] = {}
	pl["frozen"] = 0.0
	StoryActions.choice_pick(self, id, ch["data"], index)

func _dialog_done(id: int, token: int) -> void:
	var pl = peers.get(id)
	if pl == null:
		return
	var tk: Dictionary = pl["token"]
	if tk.is_empty() or int(tk.get("n", -1)) != token:
		return
	pl["token"] = {}
	pl["frozen"] = 0.0
	var inst: ZoneInstance = pl["inst"]
	match String(tk.get("action", "")):
		"begin":
			inst.begin_defense()
		"finish":
			inst.finish_story(id)
		"shop":
			pl["shop"] = true
			send_ev(id, "shop", {"stock": shop_stock(), "gold": int(pl["rec"]["gold"])})
		"extra":
			StoryActions.after_extra_dialog(self, id, inst, tk.get("extra", {}))
		"duel":
			inst.begin_duel(String((tk.get("extra", {}) as Dictionary).get("kid", "")))
		"kowal":
			var rec: Dictionary = pl["rec"]
			var flags: Dictionary = story_of(rec)["flags"]
			if not bool(flags.get("kowal_gift", false)):
				flags["kowal_gift"] = true
				ServerChars.inv_add(rec, "mikstura_miodu", 1)
				ServerChars.inv_add(rec, "sztabka_zelaza", 2)
				chars.mark_dirty()
				_say_to(id, "Otrzymano: Mikstura miodu i 2 sztabki żelaza.", "system")
				_push_me(id)
			ForgeOps.open(self, id)

# --- pomocnicze dla fabuły ---

func say(id: int, text: String) -> void:
	_say_to(id, text, "system")

func count_of(rec: Dictionary, item: String) -> int:
	return _count_of(rec, item)

func push_prog(id: int) -> void:
	var pl = peers.get(id)
	if pl != null:
		send_ev(id, "prog", StoryActions.prog_of(pl["rec"]))

## Po kodzie z kontekstu gry (nagrody): odśwież kartę postaci i ogłoś awanse.
func after_ctx(id: int, levels: int) -> void:
	var pl = peers.get(id)
	if pl == null:
		return
	chars.mark_dirty()
	if levels > 0:
		broadcast_chat("system", "", "%s awansuje na poziom %d!" % [pl["name"], int(pl["rec"]["level"])])
		refresh_loadout(id)
		var node := player_of(id)
		if node != null:
			node.hp = node.max_hp
			node.energy = node.max_energy
		players_changed.emit()
	else:
		_push_me(id)

func enter_cave(id: int, cave_id: String) -> void:
	if SecretDB.cave_by_id(cave_id).is_empty():
		return
	enter_zone(id, "cave:%s:%d" % [cave_id, id])

func on_objective_elite(inst: ZoneInstance, obj: Dictionary) -> void:
	for id in inst.peer_ids.duplicate():
		if not peers.has(id):
			continue
		var rec: Dictionary = peers[id]["rec"]
		StoryActions.flags_of(rec)[ChapterExtras.flag(inst.quest_id, String(obj["id"]), 0)] = true
		StoryActions.check_obj_reward(self, int(id), inst.quest_id, obj)
		push_prog(int(id))

## Rycerz wyzywający na pojedynek: wybór zbroi zależy od postępu gracza (KnightDB.roll w kontekście jego postaci).
func roll_knight(peer: int) -> String:
	var pl = peers.get(peer)
	if pl == null:
		return "rycerz_pojedynku"
	return String(ServerCtx.run(pl["rec"], func(): return KnightDB.roll())["result"])

func on_duel_won(inst: ZoneInstance, kid: String) -> void:
	var kd: Dictionary = EnemyDB.get_data(kid)
	for id in inst.peer_ids:
		var pl = peers.get(id)
		if pl == null:
			continue
		var rec: Dictionary = pl["rec"]
		var gold := int(float(kd.get("gold", 90)) * (1.0 + 0.04 * float(int(rec["level"]))))
		rec["gold"] = int(rec["gold"]) + gold
		var lines: Array = ["%d zł" % gold]
		if randf() < 0.25:
			ServerChars.inv_add(rec, "zwoj_teleportacji", 1)
			lines.append("Zwój teleportacji")
		_say_to(int(id), "Wygrany pojedynek! Łup: " + ", ".join(lines), "system")
		chars.mark_dirty()
		_push_me(int(id))

## Boss świata odpowiedni do poziomu graczy w strefie (od najsłabszego bossa kampanii do najsilniejszego).
func world_boss_for(inst: ZoneInstance) -> String:
	var ids: Array = BossDB.BASE_LIST.keys()
	ids.sort_custom(func(a, b): return float(BossDB.BASE_LIST[a]["hp"]) < float(BossDB.BASE_LIST[b]["hp"]))
	var i := clampi(int(average_level(inst) / 8.0), 0, ids.size() - 1)
	return String(ids[maxi(0, i - randi() % 2)])

func on_raid_won(inst: ZoneInstance) -> void:
	for id in inst.peer_ids:
		var pl = peers.get(id)
		if pl == null:
			continue
		var rec: Dictionary = pl["rec"]
		var lv := int(rec["level"])
		var gold := 150 + 25 * lv
		rec["gold"] = int(rec["gold"]) + gold
		var gained := ServerChars.add_xp(rec, 120 + 40 * lv)
		ServerChars.inv_add(rec, "krysztal_cienia", 1)
		_say_to(int(id), "Najazd odparty! Nagroda: %d zł, XP i diament." % gold, "system")
		after_ctx(int(id), gained)
	broadcast_zone_ev(inst, "banner", {"title": "NAJAZD ODPARTY", "sub": "Pustkowie jest bezpieczne"})

# ------------------------------------------------- wyzwania, ranking, arena PvP ---

func _ranking_file() -> String:
	return ServerChars.dir() + "/ranking.json"

func _load_ranking() -> void:
	ranking = []
	if FileAccess.file_exists(_ranking_file()):
		var f := FileAccess.open(_ranking_file(), FileAccess.READ)
		var v = JSON.parse_string(f.get_as_text()) if f else null
		if f:
			f.close()
		if v is Array:
			ranking = v

func _save_ranking() -> void:
	DirAccess.make_dir_recursive_absolute(ServerChars.dir())
	var f := FileAccess.open(_ranking_file(), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(ranking))
		f.close()

func ranking_text() -> String:
	var lines: Array = []
	var i := 1
	for e in ranking.slice(0, 10):
		lines.append("%d. %s — %d rund (poz. %d, %s)" % [i, String(e["name"]), int(e["rounds"]), int(e["lv"]), String(e["cls"])])
		i += 1
	var arena: Array = []
	for k in chars.records:
		var r: Dictionary = chars.records[k]
		var w := int((r.get("arena", {}) as Dictionary).get("wins", 0)) if r.get("arena") is Dictionary else 0
		if w > 0:
			arena.append([String(r["name"]), w])
	arena.sort_custom(func(a, b): return int(a[1]) > int(b[1]))
	var al: Array = []
	for e in arena.slice(0, 5):
		al.append("%s (%d)" % [e[0], e[1]])
	return "RANKING WYZWAŃ:\n%s\nARENA — wygrane: %s" % ["\n".join(lines) if not lines.is_empty() else "(pusto)", ", ".join(al) if not al.is_empty() else "(brak)"]

func start_challenge(id: int) -> void:
	var pl = peers.get(id)
	if pl == null:
		return
	var inst: ZoneInstance = pl["inst"]
	if inst != null and inst.kind in ["challenge", "arena", "custom"]:
		_say_to(id, "Najpierw skończ obecną walkę (/wyjdz).", "error")
		return
	enter_zone(id, "challenge:%d" % id)

func start_custom(id: int) -> void:
	var pl = peers.get(id)
	if pl == null:
		return
	var inst: ZoneInstance = pl["inst"]
	if inst != null and inst.kind in ["challenge", "arena", "custom"]:
		_say_to(id, "Najpierw skończ obecną walkę (/wyjdz).", "error")
		return
	var key := "custom:%d" % id
	if instances.has(key):
		_cleanup_instance(instances[key])
	pending_custom[key] = ServerChars.sanitize_waves(pl["rec"].get("custom_waves", {}))
	enter_zone(id, key)

func on_custom_cleared(inst: ZoneInstance) -> void:
	var bonus := mini(inst.waves.size(), 30) * 40
	for id in inst.peer_ids:
		var pl = peers.get(id)
		if pl == null:
			continue
		pl["rec"]["gold"] = int(pl["rec"]["gold"]) + bonus
		_say_to(int(id), "Wszystkie fale pokonane! Premia: %d zł." % bonus, "system")
		chars.mark_dirty()
		_push_me(int(id))

func on_challenge_over(inst: ZoneInstance, rounds: int) -> void:
	if inst.peer_ids.is_empty():
		return
	var id := int(inst.peer_ids[0])
	var pl = peers.get(id)
	if pl == null:
		return
	var rec: Dictionary = pl["rec"]
	ranking.append({"name": String(rec["name"]), "rounds": rounds, "lv": int(rec["level"]), "cls": String(rec["class"])})
	ranking.sort_custom(func(a, b): return int(a["rounds"]) > int(b["rounds"]))
	ranking = ranking.slice(0, 20)
	_save_ranking()
	send_ev(id, "banner", {"title": "KONIEC WYZWANIA", "sub": "Pokonani rycerze: %d" % rounds})
	_say_to(id, "Wyzwanie zakończone: pokonani rycerze: %d.\n%s" % [rounds, ranking_text()], "system")
	if rounds >= 3:
		broadcast_chat("system", "", "%s ukończył %d rund wyzwania!" % [rec["name"], rounds])

func leave_fight(id: int) -> void:
	var pl = peers.get(id)
	var inst: ZoneInstance = pl["inst"] if pl != null else null
	if inst == null or inst.kind not in ["challenge", "arena", "custom"]:
		_say_to(id, "Nie jesteś w wyzwaniu, na arenie ani we własnych falach.", "error")
		return
	if inst.kind == "arena":
		inst.arena_ko(id)
	elif inst.kind == "custom":
		inst.finished = true
		inst._finish_t = 0.5
	else:
		inst.challenge_over()

func _arena_ok(id: int) -> bool:
	var pl = peers.get(id)
	if pl == null or pl["inst"] == null:
		return false
	return (pl["inst"] as ZoneInstance).kind in ["story", "swiat"] and float(pl["frozen"]) <= 0.0

func invite_arena(from: int, name_part: String) -> void:
	var to := find_peer(name_part)
	if to < 0 or to == from:
		_say_to(from, "Nie ma takiego gracza.", "error")
		return
	if not _arena_ok(from) or not _arena_ok(to):
		_say_to(from, "Obaj gracze muszą być w kampanii lub na Pustkowiu i nie rozmawiać.", "error")
		return
	open_choice(to, "%s wyzywa Cię na arenę! Walczycie 1 na 1 swoimi postaciami. Przyjmujesz?" % peers[from]["name"],
		[{"text": "Walczę!"}, {"text": "Nie teraz"}], Color(1.0, 0.45, 0.4), {"kind": "arena_invite", "from": from})
	_say_to(from, "Wysłano zaproszenie na arenę do: %s." % peers[to]["name"], "system")

func answer_arena(to: int, from: int, accept: bool) -> void:
	if not peers.has(from):
		_say_to(to, "Wyzywający już wyszedł.", "error")
		return
	if not accept:
		_say_to(from, "%s odrzucił zaproszenie na arenę." % peers[to]["name"], "system")
		return
	if not _arena_ok(from):
		_say_to(to, "Wyzywający nie może teraz walczyć.", "error")
		return
	start_arena(from, to)

func start_arena(a: int, b: int) -> void:
	var key := "arena:%d:%d" % [a, b]
	enter_zone(a, key)
	enter_zone(b, key)
	var inst: ZoneInstance = peers[a]["inst"]
	inst.arena_peers = [a, b]
	var pa := player_of(a)
	var pb := player_of(b)
	if pa == null or pb == null:
		return
	pa.position = Vector2(700.0, 780.0)
	pb.position = Vector2(1500.0, 780.0)
	pb.team_tag = "player2"
	pb.hurtbox.team = "player2"
	pb.facing = -1.0
	pb.visual.set_facing(-1.0)
	pa.add_to_group("enemies")
	pb.add_to_group("enemies")
	peers[a]["frozen"] = 3.2
	peers[b]["frozen"] = 3.2
	broadcast_zone_ev(inst, "banner", {"title": "ARENA", "sub": "%s vs %s" % [peers[a]["name"], peers[b]["name"]]})
	get_tree().create_timer(3.0).timeout.connect(func():
		if is_instance_valid(inst) and not inst.finished:
			broadcast_zone_ev(inst, "banner", {"title": "WALCZ!", "sub": ""}))

func on_arena_over(inst: ZoneInstance, winner: int, loser: int) -> void:
	var wn := String(peers[winner]["name"]) if peers.has(winner) else "przeciwnik"
	var ln := String(peers[loser]["name"]) if peers.has(loser) else "przeciwnik"
	if peers.has(winner):
		var rw: Dictionary = peers[winner]["rec"]
		if not (rw.get("arena") is Dictionary):
			rw["arena"] = {}
		rw["arena"]["wins"] = int(rw["arena"].get("wins", 0)) + 1
	if peers.has(loser):
		var rl: Dictionary = peers[loser]["rec"]
		if not (rl.get("arena") is Dictionary):
			rl["arena"] = {}
		rl["arena"]["losses"] = int(rl["arena"].get("losses", 0)) + 1
	chars.mark_dirty()
	broadcast_zone_ev(inst, "banner", {"title": "KO!", "sub": "Wygrywa %s" % wn})
	broadcast_zone_chat(inst, "system", "", "Arena: %s pokonał gracza %s." % [wn, ln])
	broadcast_chat("system", "", "Arena: %s pokonał gracza %s!" % [wn, ln])

func on_hunt_died(inst: ZoneInstance, qid: String) -> void:
	StoryActions.hunt_died(self, inst, qid)

func shop_stock() -> Array:
	var out: Array = []
	for slot in SHOP_SLOTS:
		for iid in ItemDB.by_slot(slot):
			if ItemDB.price_of(iid) <= 0:
				continue
			if ItemDB.RARITIES.find(ItemDB.rarity_of(iid)) >= ItemDB.RARITIES.find("legendarny"):
				continue
			out.append(String(iid))
	return out

func _shop_op(id: int, kind: String, item: String, n: int) -> void:
	var pl = peers.get(id)
	if pl == null or not bool(pl["shop"]):
		return
	var rec: Dictionary = pl["rec"]
	n = clampi(n, 1, 99)
	if kind == "buy":
		if item not in shop_stock():
			return
		var price := ItemDB.price_of(item) * n
		if int(rec["gold"]) < price:
			_say_to(id, "Za mało złota.", "error")
			return
		if ServerChars.inv_add(rec, item, n) < n:
			_say_to(id, "Plecak pełny.", "error")
			return
		rec["gold"] = int(rec["gold"]) - price
	elif kind == "sell":
		if not ServerChars.inv_remove(rec, item, n):
			return
		rec["gold"] = int(rec["gold"]) + int(round(float(ItemDB.price_of(item)) * SELL_RATIO)) * n
	chars.mark_dirty()
	_push_me(id)
	send_ev(id, "shop", {"stock": shop_stock(), "gold": int(rec["gold"])})

## Fabuła: rozdział ukończony — nagrody dla graczy z tym questem (pierwsze ukończenie) i awans do następnego.
func on_story_finished(inst: ZoneInstance) -> void:
	var quest := QuestDB.get_data(inst.quest_id)
	var reward: Dictionary = quest.get("reward", {})
	for id in inst.peer_ids:
		var pl = peers.get(id)
		if pl == null:
			continue
		var rec: Dictionary = pl["rec"]
		var story := story_of(rec)
		var first: bool = inst.quest_id not in story["done"]
		if first:
			story["done"].append(inst.quest_id)
			rec["gold"] = int(rec["gold"]) + int(reward.get("gold", 0))
			var gained := ServerChars.add_xp(rec, int(reward.get("xp", 0)))
			for it in reward.get("items", {}):
				ServerChars.inv_add(rec, String(it), int(reward["items"][it]))
			if gained > 0:
				broadcast_chat("system", "", "%s awansuje na poziom %d!" % [rec["name"], int(rec["level"])])
			if ChapterExtras.has(inst.quest_id):
				var fb := ChapterExtras.final_bonus(inst.quest_id, story["flags"])
				rec["gold"] = int(rec["gold"]) + int(fb["gold"])
				for fit in fb["items"]:
					ServerChars.inv_add(rec, String(fit), int(fb["items"][fit]))
				if int(fb["gold"]) > 0 or not (fb["items"] as Dictionary).is_empty():
					_say_to(id, "Wdzięczność za twoje wybory: +%d złota%s" % [int(fb["gold"]), "" if (fb["items"] as Dictionary).is_empty() else " i przedmioty"], "system")
		story["flags"][inst.quest_id + "_done"] = true
		if String(story["quest"]) == inst.quest_id:
			_advance_story(int(id), rec, inst.quest_id, first)
			for cl in _act_cinematic(inst.quest_id):
				_say_to(int(id), String(cl), "system")
		chars.mark_dirty()
		_say_to(id, "%s ukończony! %s" % [String(quest.get("label", "Rozdział")), ("+%d złota, +%d XP" % [int(reward.get("gold", 0)), int(reward.get("xp", 0))]) if first else "(powtórka — bez nagród)"], "system")
		refresh_loadout(int(id))
	var ob: Array = inst.zone.get("outro_banner", ["ROZDZIAŁ UKOŃCZONY", ""])
	broadcast_zone_ev(inst, "banner", {"title": String(ob[0]), "sub": String(ob[1])})

func advance_after_finish(inst: ZoneInstance, _info: Dictionary) -> void:
	instances.erase(inst.key)
	for id in inst.peer_ids.duplicate():
		var pl = peers.get(id)
		if pl != null:
			enter_zone(int(id), zone_key_for(pl["rec"]))
	inst.queue_free()

# ------------------------------------------------------------ RPC od klientów ---

func on_login(id: int, proto: int, player_name: String, password: String, pack: Dictionary) -> void:
	if not running or peers.has(id):
		return
	if proto != Mmo.PROTOCOL:
		_reject(id, "Zła wersja gry/serwera (klient %d, serwer %d)." % [proto, Mmo.PROTOCOL])
		return
	var nm := player_name.strip_edges()
	if not ServerChars.valid_name(nm):
		_reject(id, "Nazwa postaci: 2–16 znaków (litery, cyfry, spacja, _ lub -).")
		return
	if password.length() < 3 or password.length() > 64:
		_reject(id, "Hasło musi mieć 3–64 znaków.")
		return
	if ServerChars.key_of(nm) in cfg["banned"]:
		_reject(id, "Ta postać jest zbanowana.")
		return
	if peers.size() >= int(cfg["max_players"]):
		_reject(id, "Serwer pełny.")
		return
	for other in peers.values():
		if ServerChars.key_of(String(other["name"])) == ServerChars.key_of(nm):
			_reject(id, "Ta postać jest już zalogowana.")
			return
	var rec: Dictionary
	if chars.has_rec(nm):
		rec = chars.get_rec(nm)
		if not chars.check_pw(rec, password):
			_reject(id, "Złe hasło do postaci „%s”." % nm)
			return
		var want := String(pack.get("class", ""))
		if want == "admin" and bool(cfg["allow_admin_class"]) and String(rec["class"]) != "admin":
			rec["class"] = "admin"
		if String(rec["class"]) == "admin" and not bool(cfg["allow_admin_class"]):
			rec["class"] = "wojownik"
		rec["last_login"] = Time.get_unix_time_from_system()
	else:
		if pack.is_empty() or not pack.has("char"):
			_reject(id, "Brak postaci do przeniesienia na serwer.")
			return
		rec = chars.create(nm, password, pack, bool(cfg["allow_admin_class"]))
		log_msg("Nowa postać na serwerze: %s (poz. %d, %s)." % [nm, int(rec["level"]), rec["class"]])
		chars.save_all(true)  # nowa postać od razu na dysk, nie czekamy na autozapis
	ServerChars.normalize(rec)
	ServerChars.refresh_class(rec)
	story_of(rec)
	chars.mark_dirty()
	peers[id] = {"id": id, "name": String(rec["name"]), "rec": rec, "node": null, "inst": null, "move": Vector2.ZERO,
		"held": {}, "actions": [], "respawn": 0.0, "god": false, "last_chat": 0.0, "last_use": 0.0,
		"frozen": 0.0, "token": {}, "shop": false, "choice": {}, "side_objs": [], "forge": {}}
	Mmo.send_login_result(id, true, String(cfg["motd"]), me_info(id))
	enter_zone(id, zone_key_for(rec))
	broadcast_chat("system", "", "%s dołączył do gry (poziom %d)." % [rec["name"], int(rec["level"])])
	log_msg("%s zalogowany (peer %d, strefa %s). Online: %d." % [rec["name"], id, zone_key_for(rec), peers.size()])
	players_changed.emit()

func _reject(id: int, msg: String) -> void:
	Mmo.send_login_result(id, false, msg, {})
	log_msg("Odrzucono logowanie (peer %d): %s" % [id, msg])
	get_tree().create_timer(0.4).timeout.connect(func(): Mmo.kick_peer(id))

func on_input(id: int, move: Vector2, held: Dictionary, actions: Array) -> void:
	var pl = peers.get(id)
	if pl == null:
		return
	pl["move"] = move
	pl["held"] = held
	var q: Array = pl["actions"]
	for a in actions:
		if q.size() < 32:
			q.append(a)

func on_act(id: int, kind: String, data: Dictionary) -> void:
	if not peers.has(id):
		return
	match kind:
		"interact":
			_interact(id)
		"dialog_done":
			_dialog_done(id, int(data.get("token", -1)))
		"buy", "sell":
			_shop_op(id, kind, String(data.get("id", "")), int(data.get("n", 1)))
		"shop_close":
			peers[id]["shop"] = false
		"choice_pick":
			_choice_pick(id, int(data.get("token", -1)), int(data.get("i", -1)))
		"forge_buy":
			ForgeOps.buy(self, id, String(data.get("what", "")))
		"forge_start":
			ForgeOps.start(self, id, String(data.get("kind", "")), String(data.get("metal", "")))
		"forge_finish":
			ForgeOps.finish(self, id, float(data.get("score", 0.0)))
		"rune_apply":
			ForgeOps.rune(self, id, String(data.get("kind", "")), String(data.get("key", "")), String(data.get("word", "")))
		"forge_close":
			ForgeOps.close(self, id)
		"hosp_heal":
			SupportOps.hospital_act(self, id, "heal", String(data.get("key", "")))
		"hosp_revive":
			SupportOps.hospital_act(self, id, "revive", String(data.get("key", "")))
		"stash_put":
			SupportOps.stash_act(self, id, "put", int(data.get("idx", -1)), int(data.get("tab", 0)))
		"stash_take":
			SupportOps.stash_act(self, id, "take", int(data.get("tab", 0)), int(data.get("slot", -1)))
		"lab_buy":
			SupportOps.lab_act(self, id, "buy", data)
		"lab_start":
			SupportOps.lab_act(self, id, "start", data)
		"lab_bu":
			SupportOps.lab_act(self, id, "bu", data)
		"lab_kurcz":
			SupportOps.lab_act(self, id, "kurcz", data)
		"pet_equip":
			SupportOps.pet_act(self, id, "equip", String(data.get("pet", "")), "")
		"pet_gear":
			SupportOps.pet_act(self, id, "gear", String(data.get("pet", "")), String(data.get("item", "")))
		"pet_ungear":
			SupportOps.pet_act(self, id, "ungear", String(data.get("pet", "")), "")
		"panel_close":
			peers[id]["panel"] = ""
		"act2_pick":
			_act2_pick(id, String(data.get("id", "")))
		"travel":
			_travel(id, int(data.get("index", -1)))
		"act2_started":
			act2_state(peers[id]["rec"])["started"] = true
			chars.mark_dirty()
		"waves_save":
			peers[id]["rec"]["custom_waves"] = ServerChars.sanitize_waves(data.get("cfg", {}))
			chars.mark_dirty()
			_push_me(id)
		"waves_start":
			peers[id]["rec"]["custom_waves"] = ServerChars.sanitize_waves(data.get("cfg", {}))
			chars.mark_dirty()
			start_custom(id)

func on_disconnect(id: int) -> void:
	if peers.has(id):
		_drop_player(id, true)

func on_chat(id: int, text: String) -> void:
	var pl = peers.get(id)
	if pl == null or text == "":
		return
	var now := Time.get_ticks_msec() * 0.001
	if now - float(pl["last_chat"]) < 0.35:
		return
	pl["last_chat"] = now
	if text.begins_with("/"):
		cmds.run(self, id, text)
		return
	broadcast_chat("chat", String(pl["name"]), text)
	log_msg("<%s> %s" % [pl["name"], text])

func on_inv(id: int, op: String, a: String, b: String) -> void:
	var pl = peers.get(id)
	if pl == null:
		return
	var rec: Dictionary = pl["rec"]
	var err := ""
	match op:
		"equip":
			err = ServerChars.equip_index(rec, int(a))
		"unequip":
			err = ServerChars.unequip(rec, a)
		"skill":
			var slot := int(a)
			if slot < 0 or slot >= ServerChars.SKILL_SLOTS:
				err = "Zły slot."
			elif b != "" and b not in rec["known_skills"]:
				err = "Nie znasz tej umiejętności."
			else:
				rec["skills"][slot] = b
		"use":
			var ui := int(a)
			err = _use_item(id, String(rec["inv"][ui]["id"])) if ui >= 0 and ui < (rec["inv"] as Array).size() else "Nie masz tego."
		"drop":
			var di := int(a)
			if di >= 0 and di < (rec["inv"] as Array).size():
				(rec["inv"] as Array).remove_at(di)
			else:
				err = "Nie masz tego."
		"swap":
			var inv_a: Array = rec["inv"]
			var si := int(a)
			var di2 := int(b)
			if si < 0 or si >= inv_a.size() or di2 < 0 or di2 >= GameState.INV_SIZE or si == di2:
				err = "Zły slot."
			elif di2 >= inv_a.size():
				inv_a.append(inv_a.pop_at(si))
			else:
				var tmp: Variant = inv_a[si]
				inv_a[si] = inv_a[di2]
				inv_a[di2] = tmp
		"sort":
			(rec["inv"] as Array).sort_custom(func(x, y):
				var sx := String(ItemDB.get_data(String(x["id"])).get("slot", ""))
				var sy := String(ItemDB.get_data(String(y["id"])).get("slot", ""))
				if sx != sy:
					return sx < sy
				var rx := ItemDB.RARITIES.find(ItemDB.rarity_of(String(x["id"])))
				var ry := ItemDB.RARITIES.find(ItemDB.rarity_of(String(y["id"])))
				if rx != ry:
					return rx > ry
				return String(x["id"]) < String(y["id"]))
		"give":
			if not is_admin(id):
				err = "Tylko admin."
			else:
				var n := clampi(int(b) if b != "" else 1, 1, 999)
				if ServerChars.inv_add(rec, a, n) < 1:
					err = "Nieznany przedmiot albo plecak pełny."
	if err != "":
		_say_to(id, err, "error")
		return
	chars.mark_dirty()
	refresh_loadout(id)

func _count_of(rec: Dictionary, id: String) -> int:
	var n := 0
	for e in rec["inv"]:
		if String(e["id"]) == id:
			n += int(e["n"])
	return n

func _use_item(id: int, item: String) -> String:
	var pl = peers[id]
	var now := Time.get_ticks_msec() * 0.001
	if now - float(pl["last_use"]) < 0.5:
		return ""
	var d := ItemDB.get_data(item)
	var use: Dictionary = d.get("use", {})
	if use.is_empty():
		return "Tego nie da się użyć."
	var node := player_of(id)
	if node == null or node.state == Player.S.DEAD:
		return "Teraz nie."
	if not ServerChars.inv_remove(pl["rec"], item, 1):
		return "Nie masz tego."
	pl["last_use"] = now
	node.heal(float(use.get("health", 0.0)))
	node.add_energy(float(use.get("energy", 0.0)))
	if use.has("invuln"):
		node.invuln = maxf(node.invuln, float(use["invuln"]))
	return ""

# ------------------------------------------------------------------- gracze ---

func find_peer(name_part: String) -> int:
	var q := name_part.strip_edges().to_lower()
	if q == "":
		return -1
	var best := -1
	for id in peers:
		var n := String(peers[id]["name"]).to_lower()
		if n == q:
			return int(id)
		if n.begins_with(q) and best < 0:
			best = int(id)
	return best

func player_of(id: int) -> Player:
	var pl = peers.get(id)
	if pl == null:
		return null
	var n = pl.get("node")
	return n if (n != null and is_instance_valid(n)) else null

func is_admin_rec(rec: Dictionary) -> bool:
	if bool(rec.get("admin", false)):
		return true
	if ServerChars.key_of(String(rec.get("name", ""))) in cfg["admins"]:
		return true
	return String(rec.get("class", "")) == "admin" and bool(cfg["allow_admin_class"])

func is_admin(id: int) -> bool:
	return id == 0 or (peers.has(id) and is_admin_rec(peers[id]["rec"]))

func _apply_loadout(p: Player, rec: Dictionary) -> void:
	p.apply_server_loadout(ServerChars.compute_stats(rec), rec["equip"], rec["skills"], ServerChars.ranks_of(rec))

func refresh_loadout(id: int) -> void:
	var pl = peers.get(id)
	if pl == null:
		return
	var node := player_of(id)
	if node != null:
		_apply_loadout(node, pl["rec"])
	_push_me(id)
	_push_roster()

func me_info(id: int) -> Dictionary:
	var pl = peers[id]
	var rec: Dictionary = pl["rec"]
	var st := ServerChars.compute_stats(rec)
	return {
		"name": rec["name"], "char": rec["char"], "class": rec["class"], "level": int(rec["level"]), "xp": int(rec["xp"]),
		"xp_need": ServerChars.xp_needed(int(rec["level"])), "gold": int(rec["gold"]), "attr_points": int(rec.get("attr_points", 0)),
		"attrs": rec["attrs"], "equip": rec["equip"], "equip_q": rec["equip_q"], "equip_m": rec["equip_m"], "inv": rec["inv"], "skills": rec["skills"],
		"known_skills": rec["known_skills"], "admin": is_admin_rec(rec), "pets": SupportOps.pets_of(rec), "custom_waves": rec.get("custom_waves", UiWaveEditor.default_config()),
		"stats": {"max_health": st["max_health"], "strength": st["strength"], "defense": st["defense"], "speed": st["speed"], "crit": st["crit"]},
		"server": String(cfg["name"]), "act2_choice": act2_needs_choice(rec), "chapter": int(story_of(rec)["chapter"]), "best": int(story_of(rec)["best"]),
	}

func _push_me(id: int) -> void:
	if peers.has(id):
		Mmo.send_me(id, me_info(id))

func _push_roster() -> void:
	var r := {}
	for id in peers:
		var rec: Dictionary = peers[id]["rec"]
		r[id] = {"name": rec["name"], "char": rec["char"], "class": rec["class"], "level": int(rec["level"]),
			"look": rec.get("look", ""), "appearance": rec["appearance"], "equip": rec["equip"], "admin": is_admin_rec(rec)}
	Mmo.send_roster(peers.keys(), r)

func _drop_player(id: int, announce: bool) -> void:
	var pl = peers.get(id)
	if pl == null:
		return
	var node = pl.get("node")
	if node != null and is_instance_valid(node):
		node.queue_free()
	var inst: ZoneInstance = pl.get("inst")
	if inst != null and is_instance_valid(inst):
		inst.on_peer_left(id)
		inst.remove_player(id)
	peers.erase(id)
	chars.save_all(true)  # wylogowanie = zapis postępu
	if inst != null and is_instance_valid(inst):
		_cleanup_instance(inst)
	chars.mark_dirty()
	chars.save_all()
	if announce:
		broadcast_chat("system", "", "%s opuścił grę." % pl["name"])
		log_msg("%s rozłączony. Online: %d." % [pl["name"], peers.size()])
		_push_roster()
	players_changed.emit()

func kick(id: int, reason: String) -> void:
	if not peers.has(id):
		return
	_say_to(id, "Wyrzucono z serwera: %s" % reason, "error")
	get_tree().create_timer(0.3).timeout.connect(func(): Mmo.kick_peer(id))

func _on_player_died(id: int) -> void:
	var pl = peers.get(id)
	if pl == null:
		return
	var inst: ZoneInstance = pl["inst"]
	if inst != null and inst.kind == "arena":
		pl["respawn"] = 9999.0
		inst.arena_ko(id)
		return
	if inst != null and inst.kind == "challenge":
		pl["respawn"] = 9999.0
		inst.challenge_over()
		return
	if inst != null and inst.kind == "custom":
		pl["respawn"] = 9999.0
		inst.custom_fail()
		return
	pl["respawn"] = RESPAWN_SECS
	pl["scroll"] = false
	var rec: Dictionary = pl["rec"]
	if _count_of(rec, "zwoj_wskrzeszenia") > 0 and ServerChars.inv_remove(rec, "zwoj_wskrzeszenia", 1):
		pl["respawn"] = 1.5
		pl["scroll"] = true
		chars.mark_dirty()
		_push_me(id)
		_say_to(id, "Zwój Wskrzeszenia rozpada się — za chwilę wstaniesz w tym samym miejscu.")
	broadcast_chat("system", "", "%s poległ." % pl["name"])

# --------------------------------------------------------------------- czat ---

func broadcast_chat(kind: String, from: String, text: String) -> void:
	Mmo.broadcast_chat(peers.keys(), kind, from, text)

func broadcast_zone_chat(inst: ZoneInstance, kind: String, from: String, text: String) -> void:
	Mmo.broadcast_chat(inst.peer_ids, kind, from, text)

func broadcast_zone_ev(inst: ZoneInstance, kind: String, data: Dictionary) -> void:
	for id in inst.peer_ids:
		send_ev(int(id), kind, data)

func send_ev(id: int, kind: String, data: Dictionary) -> void:
	if peers.has(id):
		Mmo.send_event(id, kind, data)

func _say_to(id: int, text: String, kind: String = "system") -> void:
	if id == 0:
		log_msg(text)
	elif peers.has(id):
		Mmo.send_chat(id, kind, "", text)

func reply(id: int, text: String, kind: String = "system") -> void:
	for line in text.split("\n"):
		_say_to(id, String(line), kind)

# --------------------------------------------------------------- pętla główna ---

func _physics_process(delta: float) -> void:
	if not running:
		return
	for id in peers.keys():
		var pl: Dictionary = peers[id]
		var node := player_of(int(id))
		if node == null:
			continue
		var inst: ZoneInstance = pl["inst"]
		var acts: Array = (pl["actions"] as Array).duplicate()
		(pl["actions"] as Array).clear()
		if float(pl["frozen"]) > 0.0:
			pl["frozen"] = float(pl["frozen"]) - delta
			node.net_apply_input(Vector2.ZERO, {}, [])
			node.invuln = maxf(node.invuln, 0.5)
		else:
			node.net_apply_input(pl["move"], pl["held"], acts)
		var safe: bool = inst != null and inst.kind == "swiat" and node.position.distance_to(inst.spawn) < SAFE_RADIUS
		if bool(pl["god"]) or safe:
			node.invuln = maxf(node.invuln, 0.5)
		SupportOps.tick(self, int(id), delta)
		if node.state == Player.S.DEAD:
			pl["respawn"] = float(pl["respawn"]) - delta
			if float(pl["respawn"]) <= 0.0 and inst != null and inst.kind not in ["arena", "challenge", "custom"]:
				if not bool(pl.get("scroll", false)):
					node.position = inst.spawn + Vector2(randf_range(-80.0, 80.0), randf_range(-60.0, 60.0))
				pl["scroll"] = false
				node.celebrate()
				node.energy = node.max_energy
	for k in instances.keys():
		if is_instance_valid(instances[k]):
			(instances[k] as ZoneInstance).tick(delta)
	_snap_acc += delta
	if _snap_acc >= SNAP_INTERVAL:
		_snap_acc = 0.0
		for k in instances:
			var inst2: ZoneInstance = instances[k]
			if not inst2.peer_ids.is_empty():
				Mmo.send_snapshot(inst2.peer_ids, inst2.build_snapshot())
	_save_acc += delta
	if _save_acc >= SAVE_EVERY:
		_save_acc = 0.0
		chars.save_all()

# ------------------------------------------------------------------- nagrody ---

func _peer_of_node(node: Node) -> int:
	for id in peers:
		if peers[id]["node"] == node:
			return int(id)
	return -1

func on_mob_died(enemy: Enemy, inst: ZoneInstance) -> void:
	var killer := _peer_of_node(enemy.last_killer) if enemy.last_killer != null else -1
	if killer < 0:
		return
	var origin := enemy.position
	for id in inst.peer_ids.duplicate():
		var node := player_of(int(id))
		if node == null:
			continue
		var full: bool = int(id) == killer
		if not full and node.position.distance_to(origin) > 700.0 and not enemy.is_boss:
			continue
		_reward(int(id), enemy, 1.0 if (full or enemy.is_boss) else 0.5, full)

func _reward(id: int, enemy: Enemy, share: float, full: bool) -> void:
	var pl: Dictionary = peers[id]
	var rec: Dictionary = pl["rec"]
	var st := ServerChars.compute_stats(rec)
	var xp := int(round(float(enemy.xp_value) * share * (1.0 + float(st.get("xp_mult", 0.0)))))
	var gold := int(round(float(enemy.gold_value) * share * randf_range(0.7, 1.4) * (1.0 + float(st.get("gold_mult", 0.0)))))
	rec["gold"] = int(rec["gold"]) + gold
	if full and randf() < 0.45:
		var pool := ["mikstura_miodu", "jajko", "eliksir_pietra"]
		if enemy.tier >= 2:
			pool.append("jajko_ogromne")
		ServerChars.inv_add(rec, pool[randi() % pool.size()], 1)
	if enemy is BossBig:
		var bd := BossDB.get_data((enemy as BossBig).boss_id)
		for it in bd.get("reward", {}).get("items", {}):
			ServerChars.inv_add(rec, String(it), int(bd["reward"]["items"][it]))
		rec["gold"] = int(rec["gold"]) + int(bd.get("reward", {}).get("gold", 0))
		_say_to(id, "Pokonano bossa: %s!" % String(bd.get("name", "")), "system")
	var gained := ServerChars.add_xp(rec, xp)
	chars.mark_dirty()
	if gained > 0:
		broadcast_chat("system", "", "%s awansuje na poziom %d!" % [rec["name"], int(rec["level"])])
		refresh_loadout(id)
		var node := player_of(id)
		if node != null:
			node.hp = node.max_hp
			node.energy = node.max_energy
		players_changed.emit()
	else:
		_push_me(id)
