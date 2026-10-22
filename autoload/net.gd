extends Node
## Net — obsługa gry LAN. Host tworzy pokój i dostaje krótki KOD; drugi gracz
## wpisuje tylko ten kod. Host rozgłasza kod (UDP broadcast), więc łączący
## poznaje adres hosta automatycznie — nie trzeba wpisywać IP.
##
## Kod 4-znakowy (bez znaków mylących) koduje port z zakresu LAN_PORT_BASE..

signal hosting_ready(code: String)
signal joined_ok()
signal join_failed(reason: String)
signal peer_joined(id: int)
signal peer_left(id: int)

const LAN_PORT_BASE := 26000
const LAN_PORT_COUNT := 999
const DISCOVERY_PORT := 25999
const MAX_PLAYERS := 4
const ALPHABET := "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"  # bez 0,O,1,I

var is_host := false
var host_code := ""
var my_name := "Gracz"
var my_class := "wojownik"

var _discovery: PacketPeerUDP = null

func _ready() -> void:
	multiplayer.peer_connected.connect(func(id): peer_joined.emit(id))
	multiplayer.peer_disconnected.connect(func(id): peer_left.emit(id))
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(func(): join_failed.emit("Host rozłączył się."))

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

func host_game(code: String) -> void:
	if code.length() != 4:
		code = make_code()
	var port := code_to_port(code)
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		join_failed.emit("Nie udało się otworzyć pokoju (kod zajęty?).")
		return
	multiplayer.multiplayer_peer = peer
	is_host = true
	host_code = code
	_start_discovery(code, port)
	hosting_ready.emit(code)

func _start_discovery(code: String, port: int) -> void:
	_discovery = PacketPeerUDP.new()
	_discovery.set_broadcast_enabled(true)
	var msg := ("CHICKENRPG:" + code).to_utf8_buffer()
	# rozgłaszaj cyklicznie
	var t := Timer.new()
	t.wait_time = 0.5
	t.autostart = true
	add_child(t)
	t.timeout.connect(func():
		if _discovery:
			_discovery.set_dest_address("255.255.255.255", DISCOVERY_PORT)
			_discovery.put_packet(msg))

# ------------------------------------------------------------------ join ----

func join_game(code: String) -> void:
	code = code.strip_edges().to_upper()
	var port := code_to_port(code)
	if port < 0:
		join_failed.emit("Nieprawidłowy kod.")
		return
	# nasłuchuj rozgłoszeń hosta, żeby poznać adres IP
	var ip := await _discover_host(code, port, 2.5)
	if ip == "":
		join_failed.emit("Nie znaleziono pokoju o kodzie %s." % code)
		return
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
	join_failed.emit("Połączenie odrzucone.")

# ---------------------------------------------------------------- stop/close ---

func reset() -> void:
	if _discovery:
		_discovery.close()
		_discovery = null
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	is_host = false
	host_code = ""
