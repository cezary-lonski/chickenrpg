extends Node
## Mmo — protokół ChickenSerwera. Ten sam węzeł (/root/Mmo) działa po stronie serwera i klienta gry,
## więc RPC mają identyczne sygnatury. Serwer (MmoServer) jest autorytetem; klient wysyła tylko wejście,
## czat/komendy i żądania ekwipunku. Opis: docs/chickenserwer_spec.md

signal connected()
signal connect_failed(reason: String)
signal disconnected(reason: String)
signal login_result(ok: bool, msg: String, info: Dictionary)
signal chat_received(kind: String, from: String, text: String)
signal snapshot_received(snapshot: Dictionary)
signal roster_received(roster: Dictionary)
signal me_received(info: Dictionary)
signal zone_received(info: Dictionary)
signal event_received(kind: String, data: Dictionary)

const DEFAULT_PORT := 7777
const PROTOCOL := 1
const MAX_PLAYERS := 32
const MAX_CHAT := 200
const ALLOWED_ACTIONS := ["light_attack", "heavy_attack", "dash", "jump", "special", "throw_item", "block",
		"skill_1", "skill_2", "skill_3", "skill_4", "skill_5", "skill_6", "skill_7", "skill_8", "skill_9"]
const ACT_KINDS := ["interact", "dialog_done", "buy", "sell", "shop_close", "choice_pick", "puzzle_done", "puzzle_hint", "enc_pick", "forge_buy", "forge_start", "forge_finish", "rune_apply", "forge_close", "hosp_heal", "hosp_revive", "stash_put", "stash_take", "lab_buy", "lab_start", "lab_bu", "lab_kurcz", "pet_equip", "pet_gear", "pet_ungear", "panel_close", "waves_save", "waves_start", "act2_pick", "act2_started", "travel"]
const INV_OPS := ["equip", "unequip", "use", "skill", "give", "drop"]

## MmoServer — ustawiane po stronie serwera.
var server: Node = null
var role := ""   # "" | "server" | "client"
var logged_in := false
var my_peer := 0
var my_info: Dictionary = {}
var zone_info: Dictionary = {}
## Zdarzenia od serwera czekają, aż świat gry (MmoWorld) będzie gotowy je odebrać.
var events_ready := false
var _pending_events: Array = []
var roster: Dictionary = {}
var latest_snapshot: Dictionary = {}
var last_snapshot_bytes := 0
var _pending_login: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_gone)
	multiplayer.peer_disconnected.connect(func(id: int):
		if role == "server" and server != null:
			server.on_disconnect(id))

# ------------------------------------------------------------------ serwer ---

func start_server(port: int, max_players: int) -> int:
	stop()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, clampi(max_players, 1, MAX_PLAYERS))
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	role = "server"
	return OK

func is_server() -> bool:
	return role == "server"

func is_client() -> bool:
	return role == "client"

func kick_peer(id: int) -> void:
	var p := multiplayer.multiplayer_peer
	if p is ENetMultiplayerPeer:
		(p as ENetMultiplayerPeer).disconnect_peer(id)

func send_login_result(id: int, ok: bool, msg: String, info: Dictionary) -> void:
	_rpc_login_result.rpc_id(id, ok, msg, info)

func send_me(id: int, info: Dictionary) -> void:
	_rpc_me.rpc_id(id, info)

func send_zone(id: int, info: Dictionary) -> void:
	_rpc_zone.rpc_id(id, info)

func send_event(id: int, kind: String, data: Dictionary) -> void:
	_rpc_ev.rpc_id(id, kind, data)

func send_chat(id: int, kind: String, from: String, text: String) -> void:
	_rpc_chat_msg.rpc_id(id, kind, from, text)

func broadcast_chat(ids: Array, kind: String, from: String, text: String) -> void:
	for id in ids:
		_rpc_chat_msg.rpc_id(int(id), kind, from, text)

func send_roster(ids: Array, data: Dictionary) -> void:
	for id in ids:
		_rpc_roster.rpc_id(int(id), data)

func send_snapshot(ids: Array, snapshot: Dictionary) -> void:
	if ids.is_empty():
		return
	var raw := var_to_bytes(snapshot)
	var packed := raw.compress(FileAccess.COMPRESSION_ZSTD)
	for id in ids:
		if packed.is_empty():
			if raw.size() > 1200:
				_rpc_snapshot_big.rpc_id(int(id), -1, raw)
			else:
				_rpc_snapshot.rpc_id(int(id), -1, raw)
		elif packed.size() > 1200:
			_rpc_snapshot_big.rpc_id(int(id), raw.size(), packed)
		else:
			_rpc_snapshot.rpc_id(int(id), raw.size(), packed)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_login(proto: int, player_name: String, password: String, pack: Dictionary) -> void:
	if role != "server" or server == null:
		return
	server.on_login(multiplayer.get_remote_sender_id(), proto, player_name, password, pack)

@rpc("any_peer", "call_remote", "unreliable_ordered")
func _rpc_input(move: Vector2, held: Dictionary, actions: Array) -> void:
	if role != "server" or server == null:
		return
	if not (is_finite(move.x) and is_finite(move.y)):
		return
	var clean: Array = []
	for a in actions:
		if clean.size() >= 32:
			break
		if String(a) in ALLOWED_ACTIONS:
			clean.append(String(a))
	server.on_input(multiplayer.get_remote_sender_id(), move.limit_length(1.0),
			{"block": bool(held.get("block", false)), "sprint": bool(held.get("sprint", false))}, clean)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_chat(text: String) -> void:
	if role != "server" or server == null:
		return
	server.on_chat(multiplayer.get_remote_sender_id(), text.strip_edges().left(MAX_CHAT))

@rpc("any_peer", "call_remote", "reliable")
func _rpc_inv(op: String, a: String, b: String) -> void:
	if role != "server" or server == null or op not in INV_OPS:
		return
	server.on_inv(multiplayer.get_remote_sender_id(), op, a.left(64), b.left(64))

@rpc("any_peer", "call_remote", "reliable")
func _rpc_act(kind: String, data: Dictionary) -> void:
	if role != "server" or server == null or kind not in ACT_KINDS:
		return
	server.on_act(multiplayer.get_remote_sender_id(), kind, data)

# ------------------------------------------------------------------ klient ---

func connect_to(ip: String, port: int, player_name: String, password: String, pack: Dictionary) -> void:
	stop()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip.strip_edges(), clampi(port, 1, 65535))
	if err != OK:
		connect_failed.emit("Nie udało się połączyć (%s)." % error_string(err))
		return
	_pending_login = {"name": player_name, "pw": password, "pack": pack}
	multiplayer.multiplayer_peer = peer
	role = "client"

func send_input(move: Vector2, held: Dictionary, actions: Array) -> void:
	if role == "client" and logged_in:
		_rpc_input.rpc_id(1, move, held, actions)

func send_chat_text(text: String) -> void:
	if role == "client" and logged_in and text.strip_edges() != "":
		_rpc_chat.rpc_id(1, text.strip_edges().left(MAX_CHAT))

func send_act(kind: String, data: Dictionary = {}) -> void:
	if role == "client" and logged_in:
		_rpc_act.rpc_id(1, kind, data)

func send_inv(op: String, a: String = "", b: String = "") -> void:
	if role == "client" and logged_in:
		_rpc_inv.rpc_id(1, op, a, b)

func _on_connected() -> void:
	if role != "client":
		return
	my_peer = multiplayer.get_unique_id()
	connected.emit()
	_rpc_login.rpc_id(1, PROTOCOL, String(_pending_login.get("name", "")), String(_pending_login.get("pw", "")),
			_pending_login.get("pack", {}))
	_pending_login = {}

func _on_connection_failed() -> void:
	stop()
	connect_failed.emit("Nie można połączyć z serwerem (adres, port, zapora?).")

func _on_server_gone() -> void:
	if role != "client":
		return
	var was := logged_in
	stop()
	disconnected.emit("Serwer się rozłączył." if was else "Rozłączono.")

@rpc("authority", "call_remote", "reliable")
func _rpc_login_result(ok: bool, msg: String, info: Dictionary) -> void:
	logged_in = ok
	if ok:
		my_info = info
	login_result.emit(ok, msg, info)

@rpc("authority", "call_remote", "reliable")
func _rpc_me(info: Dictionary) -> void:
	my_info = info
	me_received.emit(info)

@rpc("authority", "call_remote", "reliable")
func _rpc_zone(info: Dictionary) -> void:
	zone_info = info
	latest_snapshot = {}
	zone_received.emit(info)

@rpc("authority", "call_remote", "reliable")
func _rpc_ev(kind: String, data: Dictionary) -> void:
	if not events_ready:
		_pending_events.append([kind, data])
		return
	event_received.emit(kind, data)

## Wywoływane przez świat gry po podłączeniu sygnałów: odtwarza zdarzenia z czasu ładowania.
func flush_events() -> void:
	events_ready = true
	var list := _pending_events
	_pending_events = []
	for e in list:
		event_received.emit(e[0], e[1])

@rpc("authority", "call_remote", "reliable")
func _rpc_chat_msg(kind: String, from: String, text: String) -> void:
	chat_received.emit(kind, from.left(32), text.left(400))

@rpc("authority", "call_remote", "reliable")
func _rpc_roster(data: Dictionary) -> void:
	roster = data
	roster_received.emit(data)

@rpc("authority", "call_remote", "unreliable_ordered")
func _rpc_snapshot(raw_size: int, wire: PackedByteArray) -> void:
	_accept_snapshot(raw_size, wire)

@rpc("authority", "call_remote", "reliable")
func _rpc_snapshot_big(raw_size: int, wire: PackedByteArray) -> void:
	_accept_snapshot(raw_size, wire)

func _accept_snapshot(raw_size: int, wire: PackedByteArray) -> void:
	var raw := wire if raw_size < 0 else wire.decompress(raw_size, FileAccess.COMPRESSION_ZSTD)
	last_snapshot_bytes = wire.size()
	var value = bytes_to_var(raw if not raw.is_empty() else wire)
	if typeof(value) != TYPE_DICTIONARY:
		return
	latest_snapshot = value
	snapshot_received.emit(latest_snapshot)

# -------------------------------------------------------------------- stop ---

func stop() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	role = ""
	logged_in = false
	my_peer = 0
	my_info = {}
	zone_info = {}
	events_ready = false
	_pending_events = []
	roster = {}
	latest_snapshot = {}
	_pending_login = {}
