extends Node
## Net — obsługa gry LAN i online. Host tworzy pokój i dostaje krótki KOD;
## drugi gracz wpisuje tylko ten kod (LAN) albo IP hosta + kod (online).
## Host rozgłasza kod (UDP broadcast), więc w LAN łączący poznaje adres hosta
## automatycznie. W trybie online host próbuje przekierować port przez UPnP.
##
## Kod 4-znakowy (bez znaków mylących) koduje port z zakresu LAN_PORT_BASE..

signal hosting_ready(code: String)
signal joined_ok()
signal join_failed(reason: String)
signal peer_joined(id: int)
signal peer_left(id: int)
signal client_info_received(id: int, info: Dictionary)
signal start_received(config: Dictionary)
signal game_started_received(config: Dictionary)
signal snapshot_received(snapshot: Dictionary)
signal flow_received(event: String, data: Dictionary)
signal online_info_ready(info: Dictionary)
signal world_event_received(event_name: String, data: Dictionary)

const LAN_PORT_BASE := 26000
const LAN_PORT_COUNT := 999
const DISCOVERY_PORT := 25999
const MAX_PLAYERS := 1  # liczba gości (host + 1 gość)
const ALLOWED_ACTIONS := ["light_attack", "heavy_attack", "dash", "jump", "special", "throw_item", "block", "skill_1", "skill_2", "skill_3", "skill_4", "skill_5", "skill_6"]
const MAX_QUEUED_ACTIONS := 32
const ALPHABET := "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"  # bez 0,O,1,I

var is_host := false
var host_code := ""
var my_name := "Gracz"
var my_class := "wojownik"
var client_info: Dictionary = {}
var latest_snapshot: Dictionary = {}
var pending_game_start: Dictionary = {}
var last_snapshot_bytes := 0
var last_snapshot_wire_bytes := 0
var snapshot_sent_count := 0
var snapshot_bad_count := 0
var online_mode := false
var online_external_ip := ""
var online_local_ip := ""
var online_mapped := false
var online_busy := false
var online_error := ""

var _discovery: PacketPeerUDP = null
var _discovery_timer: Timer = null
var _remote_move := Vector2.ZERO
var _remote_held: Dictionary = {}
var _remote_actions: Array = []
var _upnp: UPNP = null
var _upnp_thread: Thread = null
var _upnp_port := 0
var _upnp_mapping_added := false
var _net_gen := 0
var _joining := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	multiplayer.peer_connected.connect(func(id): peer_joined.emit(id))
	multiplayer.peer_connected.connect(func(_id): _stop_discovery())
	multiplayer.peer_disconnected.connect(func(id):
		_remote_move = Vector2.ZERO
		_remote_held.clear()
		_remote_actions.clear()
		peer_left.emit(id))
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(func(): join_failed.emit("Host rozłączył się."))

func _process(_delta: float) -> void:
	if _upnp_thread != null and not _upnp_thread.is_alive():
		_upnp_thread.wait_to_finish()
		_upnp_thread = null

# --------------------------------------------------------------- kod/port ---

static func code_to_port(code: String) -> int:
	code = code.strip_edges().to_upper()
	if code.length() != 4:
		return -1
	var n := 0
	for i in 4:
		var idx := ALPHABET.find(code[i])
		if idx < 0:
			return -1
		n = n * ALPHABET.length() + idx
	return LAN_PORT_BASE + (n % LAN_PORT_COUNT)

static func port_to_code(port: int) -> String:
	var n := int(posmod(port - LAN_PORT_BASE, LAN_PORT_COUNT))
	var out := ""
	for i in 4:
		out = ALPHABET[n % ALPHABET.length()] + out
		n /= ALPHABET.length()
	return out

func make_code() -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return port_to_code(LAN_PORT_BASE + rng.randi_range(0, LAN_PORT_COUNT - 1))

# ------------------------------------------------------------------ host ----

func host_game(code: String, online: bool = false) -> void:
	code = code.strip_edges().to_upper()
	if code_to_port(code) < 0:
		code = make_code()
	var port := code_to_port(code)
	if has_peer() or _discovery != null:
		reset()
	_clear_upnp()
	online_mode = online
	online_mapped = false
	online_external_ip = ""
	online_local_ip = _local_ipv4()
	online_error = ""
	online_busy = false
	_upnp_port = port
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		join_failed.emit("Nie udało się otworzyć pokoju (kod zajęty?).")
		return
	multiplayer.multiplayer_peer = peer
	is_host = true
	host_code = code
	_start_discovery(code, port)
	if online_mode:
		_start_upnp(port)
	hosting_ready.emit(code)

func _start_upnp(port: int) -> void:
	online_busy = true
	online_error = ""
	if _upnp_thread != null:
		_upnp_thread.wait_to_finish()
	_upnp_thread = Thread.new()
	_upnp_thread.start(_upnp_worker.bind(port, _net_gen))

func _upnp_worker(port: int, gen: int) -> void:
	var upnp := UPNP.new()
	var info := {
		"port": port,
		"ok": false,
		"external_ip": "",
		"local_ip": online_local_ip,
		"error": "",
	}
	var err := upnp.discover(1800, 2)
	if err != UPNP.UPNP_RESULT_SUCCESS:
		info["error"] = "Router nie odpowiedział na UPnP."
	else:
		var gateway := upnp.get_gateway()
		if gateway == null or not gateway.is_valid_gateway():
			info["error"] = "Router nie obsługuje przekierowania portów."
		else:
			var map_err := gateway.add_port_mapping(port, port, "Chicken Brawl", "UDP", 0)
			if map_err == UPNP.UPNP_RESULT_SUCCESS:
				info["ok"] = true
				info["external_ip"] = gateway.query_external_address()
			else:
				info["error"] = "Nie udało się przekierować portu (kod %d)." % map_err
	info["upnp"] = upnp
	info["gen"] = gen
	info["port"] = port
	call_deferred("_on_upnp_done", info)

func _on_upnp_done(info: Dictionary) -> void:
	var upnp: UPNP = info.get("upnp")
	if int(info.get("gen", -1)) != _net_gen or not is_host or not online_mode:
		# sesja już zamknięta: nie zostawiaj przekierowania portu
		if upnp != null and bool(info.get("ok", false)):
			var gw := upnp.get_gateway()
			if gw != null:
				gw.delete_port_mapping(int(info.get("port", 0)), "UDP")
		return
	_upnp = upnp
	_upnp_mapping_added = bool(info.get("ok", false))
	online_busy = false
	online_mapped = bool(info.get("ok", false))
	online_external_ip = String(info.get("external_ip", ""))
	online_error = String(info.get("error", ""))
	online_info_ready.emit(online_info())

func _clear_upnp() -> void:
	if _upnp_thread != null:
		_upnp_thread.wait_to_finish()
		_upnp_thread = null
	if _upnp != null and _upnp_mapping_added and _upnp_port > 0:
		_upnp.delete_port_mapping(_upnp_port, "UDP")
	_upnp = null
	_upnp_port = 0
	_upnp_mapping_added = false
	online_busy = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_clear_upnp()

func _local_ipv4() -> String:
	for addr in IP.get_local_addresses():
		if addr.contains(".") and not addr.begins_with("127.") and not addr.begins_with("169.254."):
			return addr
	return "127.0.0.1"

func online_info() -> Dictionary:
	return {
		"code": host_code,
		"port": code_to_port(host_code) if host_code != "" else 0,
		"external_ip": online_external_ip,
		"local_ip": online_local_ip,
		"mapped": online_mapped,
		"busy": online_busy,
		"error": online_error,
	}

func _stop_discovery() -> void:
	if _discovery_timer and is_instance_valid(_discovery_timer):
		_discovery_timer.queue_free()
	_discovery_timer = null
	if _discovery:
		_discovery.close()
		_discovery = null

func _start_discovery(code: String, port: int) -> void:
	if _discovery_timer and is_instance_valid(_discovery_timer):
		_discovery_timer.queue_free()
	_discovery_timer = null
	_discovery = PacketPeerUDP.new()
	_discovery.set_broadcast_enabled(true)
	var bind_err := _discovery.bind(0)
	if bind_err != OK:
		push_warning("LAN: nie udało się otworzyć gniazda rozgłaszania: %s" % error_string(bind_err))
	var msg := ("CHICKENRPG:" + code).to_utf8_buffer()
	# rozgłaszaj cyklicznie
	var t := Timer.new()
	t.wait_time = 0.5
	t.autostart = true
	add_child(t)
	_discovery_timer = t
	t.timeout.connect(func():
		if _discovery:
			for addr in ["255.255.255.255", "127.0.0.1"]:
				_discovery.set_dest_address(addr, DISCOVERY_PORT)
				_discovery.put_packet(msg))

# ------------------------------------------------------------------ join ----

func join_game(code: String) -> void:
	code = code.strip_edges().to_upper()
	var port := code_to_port(code)
	if port < 0:
		join_failed.emit("Nieprawidłowy kod.")
		return
	if _joining:
		return
	if has_peer():
		reset()
	# nasłuchuj rozgłoszeń hosta, żeby poznać adres IP
	_joining = true
	var gen := _net_gen
	var ip := await _discover_host(code, port, 2.5)
	_joining = false
	if gen != _net_gen:
		return  # gracz wyszedł z lobby w trakcie szukania
	if ip == "":
		join_failed.emit("Nie znaleziono pokoju o kodzie %s." % code)
		return
	_connect_to(ip, port)

func join_game_at(code: String, address: String) -> void:
	code = code.strip_edges().to_upper()
	var port := code_to_port(code)
	var ip := address.strip_edges()
	if port < 0:
		join_failed.emit("Nieprawidłowy kod.")
		return
	if ip == "":
		join_failed.emit("Nieprawidłowy adres hosta.")
		return
	_connect_to(ip, port)

func _connect_to(ip: String, port: int) -> void:
	if has_peer():
		reset()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, port)
	if err != OK:
		join_failed.emit("Nie udało się połączyć.")
		return
	multiplayer.multiplayer_peer = peer

func _discover_host(code: String, port: int, timeout: float) -> String:
	var udp := PacketPeerUDP.new()
	if udp.bind(DISCOVERY_PORT) != OK:
		# port może być zajęty przez hosta na tej samej maszynie — próbuj bez bindu
		udp.close()
	var want := "CHICKENRPG:" + code
	var t := 0.0
	while t < timeout:
		while udp.get_available_packet_count() > 0:
			var pkt := udp.get_packet().get_string_from_utf8()
			if pkt == want:
				var ip := udp.get_packet_ip()
				udp.close()
				return ip
		await get_tree().create_timer(0.1).timeout
		t += 0.1
	udp.close()
	return ""

func _on_connected() -> void:
	joined_ok.emit()

func _on_connection_failed() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	join_failed.emit("Połączenie odrzucone.")

# ------------------------------------------------------------------ co-op ---

func has_peer() -> bool:
	var p := multiplayer.multiplayer_peer
	return p != null and not (p is OfflineMultiplayerPeer)

func peer_count() -> int:
	if not has_peer():
		return 0
	return multiplayer.get_peers().size()

func send_client_info(info: Dictionary) -> void:
	if is_host:
		client_info[1] = info
		client_info_received.emit(1, info)
		return
	_rpc_client_info.rpc_id(1, info)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_client_info(info: Dictionary) -> void:
	if not is_host:
		return
	var sender := multiplayer.get_remote_sender_id()
	if sender != _guest_id():
		return
	var clean := {
		"char": String(info.get("char", "lady")) if CharacterDB.LIST.has(String(info.get("char", ""))) else "lady",
		"class": String(info.get("class", "wojownik")) if ClassDatabase.has(String(info.get("class", ""))) else "wojownik",
		"name": String(info.get("name", "Gracz 2")).left(24),
	}
	# statystyki i wygląd zapisanej postaci gościa (ograniczone do znanych kluczy i rozsądnych wartości)
	if info.get("stats") is Dictionary:
		var stats := {}
		for k in ["max_health", "max_energy", "strength", "defense", "speed", "crit", "fury_rate", "luck", "poise", "regen", "lifesteal",
				"dmg_reduction", "skill_power", "skill_cdr", "skill_cost", "skill_range", "energy_regen", "xp_mult", "gold_mult"]:
			if (info["stats"] as Dictionary).has(k):
				stats[k] = clampf(float((info["stats"] as Dictionary)[k]), -50.0, 5000.0)
		if stats.has("max_health"):
			clean["stats"] = stats
	if info.get("gear") is Dictionary:
		var gear := {}
		for slot in (info["gear"] as Dictionary):
			if ItemDB.has(String((info["gear"] as Dictionary)[slot])):
				gear[String(slot)] = String((info["gear"] as Dictionary)[slot])
		clean["gear"] = gear
	client_info[sender] = clean
	client_info_received.emit(sender, clean)

## Id jedynego dozwolonego gościa (najniższy id połączonego peera).
func _guest_id() -> int:
	var ids := multiplayer.get_peers()
	if ids.is_empty():
		return -1
	ids.sort()
	return int(ids[0])

func first_client_info() -> Dictionary:
	for id in client_info:
		if int(id) != 1:
			return client_info[id]
	if client_info.has(1):
		return client_info[1]
	return {}

func broadcast_start(config: Dictionary) -> void:
	if not is_host or not has_peer():
		return
	_rpc_start.rpc(config)

@rpc("authority", "call_remote", "reliable")
func _rpc_start(config: Dictionary) -> void:
	start_received.emit(config)

func broadcast_game_started(config: Dictionary) -> void:
	pending_game_start = config.duplicate(true)
	if not is_host or not has_peer():
		return
	_rpc_game_started.rpc(config)

@rpc("authority", "call_remote", "reliable")
func _rpc_game_started(config: Dictionary) -> void:
	pending_game_start = config.duplicate(true)
	game_started_received.emit(config)

func broadcast_flow(event: String, data: Dictionary = {}) -> void:
	if not is_host or not has_peer():
		return
	_rpc_flow.rpc(event, data)

@rpc("authority", "call_remote", "reliable")
func _rpc_flow(event: String, data: Dictionary) -> void:
	flow_received.emit(event, data)

## Zdarzenia świata (LAN): gość → host: flagi fabuły, żądania akcji; host → goście: nagrody, jaskinia.
const WORLD_UP := ["flag", "begin_defense", "finish_story", "enter_cave", "leave_cave"]
const WORLD_DOWN := ["rewards", "cave_cleared"]

func send_world_event(event_name: String, data: Dictionary = {}) -> void:
	if is_host or not has_peer() or event_name not in WORLD_UP:
		return
	_rpc_world_up.rpc_id(1, event_name, data)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_world_up(event_name: String, data: Dictionary) -> void:
	if not is_host or multiplayer.get_remote_sender_id() != _guest_id():
		return
	if event_name not in WORLD_UP:
		return
	if event_name == "flag":
		var fname := String(data.get("name", ""))
		if fname == "" or fname.length() > 64:
			return
		data = {"name": fname, "value": bool(data.get("value", true))}
	else:
		data = {}
	world_event_received.emit(event_name, data)

func broadcast_world_event(event_name: String, data: Dictionary = {}) -> void:
	if not is_host or not has_peer() or event_name not in WORLD_DOWN:
		return
	_rpc_world_down.rpc(event_name, data)

@rpc("authority", "call_remote", "reliable")
func _rpc_world_down(event_name: String, data: Dictionary) -> void:
	if event_name in WORLD_DOWN:
		world_event_received.emit(event_name, data)

func send_input(move: Vector2, held: Dictionary, actions: Array) -> void:
	if is_host or not has_peer():
		return
	_rpc_input.rpc_id(1, move, held, actions)

@rpc("any_peer", "call_remote", "unreliable_ordered")
func _rpc_input(move: Vector2, held: Dictionary, actions: Array) -> void:
	if not is_host or multiplayer.get_remote_sender_id() != _guest_id():
		return
	if not (is_finite(move.x) and is_finite(move.y)):
		return
	_remote_move = move.limit_length(1.0)
	_remote_held = {"block": bool(held.get("block", false)), "sprint": bool(held.get("sprint", false))}
	for a in actions:
		if _remote_actions.size() >= MAX_QUEUED_ACTIONS:
			break
		var act := String(a)
		if act in ALLOWED_ACTIONS:
			_remote_actions.append(act)

func remote_move() -> Vector2:
	return _remote_move

func remote_held() -> Dictionary:
	return _remote_held

func take_remote_actions() -> Array:
	var out := _remote_actions.duplicate()
	_remote_actions.clear()
	return out

func broadcast_snapshot(snapshot: Dictionary) -> void:
	if not is_host or not has_peer():
		return
	snapshot_sent_count += 1
	var raw := var_to_bytes(snapshot)
	last_snapshot_bytes = raw.size()
	var packed := raw.compress(FileAccess.COMPRESSION_ZSTD)
	if packed.is_empty():
		last_snapshot_wire_bytes = raw.size()
		if raw.size() > 1200:
			_rpc_snapshot_big.rpc(-1, raw)
		else:
			_rpc_snapshot.rpc(-1, raw)
		return
	last_snapshot_wire_bytes = packed.size()
	if last_snapshot_wire_bytes > 1200:
		_rpc_snapshot_big.rpc(raw.size(), packed)
	else:
		_rpc_snapshot.rpc(raw.size(), packed)

@rpc("authority", "call_remote", "unreliable_ordered")
func _rpc_snapshot(raw_size: int, wire: PackedByteArray) -> void:
	_accept_snapshot(raw_size, wire)

@rpc("authority", "call_remote", "reliable")
func _rpc_snapshot_big(raw_size: int, wire: PackedByteArray) -> void:
	_accept_snapshot(raw_size, wire)

func _accept_snapshot(raw_size: int, wire: PackedByteArray) -> void:
	var raw := wire if raw_size < 0 else wire.decompress(raw_size, FileAccess.COMPRESSION_ZSTD)
	var value = bytes_to_var(raw if not raw.is_empty() else wire)
	if typeof(value) != TYPE_DICTIONARY:
		snapshot_bad_count += 1
		return
	latest_snapshot = value
	snapshot_received.emit(latest_snapshot)

# ---------------------------------------------------------------- stop/close ---

func reset() -> void:
	_net_gen += 1
	_joining = false
	_clear_upnp()
	online_mode = false
	online_external_ip = ""
	online_local_ip = ""
	online_mapped = false
	online_busy = false
	online_error = ""
	_stop_discovery()
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	is_host = false
	host_code = ""
	client_info.clear()
	latest_snapshot.clear()
	pending_game_start.clear()
	last_snapshot_bytes = 0
	last_snapshot_wire_bytes = 0
	snapshot_sent_count = 0
	snapshot_bad_count = 0
	_remote_move = Vector2.ZERO
	_remote_held.clear()
	_remote_actions.clear()
