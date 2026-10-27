class_name ServerUpdater
extends Node
## Auto-aktualizacja serwera: po starcie i co kilka godzin sprawdza GitHub (te same wydania co gra). Gdy jest nowsza wersja,
## a konfiguracja ma "auto_update" (domyślnie tak) i na serwerze nie ma graczy, pobiera paczkę, zapisuje postacie, podmienia
## ChickenSerwer i uruchamia się ponownie z tymi samymi argumentami. Ręcznie: komendy /update i /version.
## Android nie umie podmienić sam siebie — tam serwer tylko podaje link do pobrania.

const CHECK_EVERY := 6.0 * 3600.0
const RETRY_BUSY := 600.0          # gdy są gracze, próbujemy ponownie co 10 minut

var srv: MmoServer
var tag := ""
var url := ""
var busy := false
var _http: HTTPRequest
var _timer := 30.0                  # pierwsze sprawdzenie 30 s po starcie
var _pack := ""
var _force := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if busy or OS.has_feature("editor"):
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer = CHECK_EVERY
		check(false)

func _log(text: String) -> void:
	if srv != null:
		srv.log_msg("[aktualizacja] " + text)
	else:
		print("[aktualizacja] " + text)

func available() -> bool:
	return tag != "" and UiUpdater.is_newer(tag, UiUpdater.current_version())

func _auto_on() -> bool:
	return srv == null or bool(srv.cfg.get("auto_update", true))

## Sprawdza wydania; `force` = od razu instaluj (komenda /update), inaczej decyduje auto_update i brak graczy.
func check(force: bool) -> void:
	if busy:
		return
	_force = force
	if _http == null:
		_http = HTTPRequest.new()
		_http.timeout = 15.0
		add_child(_http)
		_http.request_completed.connect(_on_list)
	if _http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	if _http.request(UiUpdater.API, ["User-Agent: ChickenSerwer-updater", "Accept: application/vnd.github+json"]) != OK:
		_log("Nie udało się sprawdzić wydań.")

func _on_list(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		if _force:
			_log("Nie udało się sprawdzić wydań (kod %d)." % code)
		return
	var best := UiUpdater.pick_release(JSON.parse_string(body.get_string_from_utf8()))
	if best.is_empty() or not UiUpdater.is_newer(String(best["tag"]), UiUpdater.current_version()):
		tag = ""
		url = ""
		if _force:
			_log("Masz najnowszą wersję (%s)." % UiUpdater.current_version())
		return
	tag = String(best["tag"])
	url = String(best["url"])
	_log("Dostępna nowa wersja %s (masz %s)." % [tag, UiUpdater.current_version()])
	if OS.get_name() not in ["Windows", "Linux"]:
		_log("Pobierz ją ręcznie: %s" % url)
		return
	var players := srv.peers.size() if srv != null else 0
	if _force or (_auto_on() and players == 0):
		_install()
	elif _auto_on():
		_log("Na serwerze są gracze (%d) — zainstaluję, gdy serwer opustoszeje (albo wpisz /update)." % players)
		_timer = minf(_timer, RETRY_BUSY)
	else:
		_log("Wpisz /update, aby zainstalować (auto_update jest wyłączone w config.json).")

func _install() -> void:
	if busy:
		return
	busy = true
	_log("Pobieram %s…" % tag)
	_pack = UiUpdater.download_path()
	var dl := HTTPRequest.new()
	dl.download_file = _pack
	dl.timeout = 0.0
	add_child(dl)
	dl.request_completed.connect(_on_downloaded)
	if dl.request(url, ["User-Agent: ChickenSerwer-updater"]) != OK:
		busy = false
		_log("Nie udało się rozpocząć pobierania.")

func _on_downloaded(result: int, code: int, _h: PackedStringArray, _b: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		busy = false
		_log("Pobieranie nie powiodło się (%d)." % code)
		return
	_log("Instaluję %s — serwer uruchomi się ponownie." % tag)
	if srv != null:
		srv.stop()      # wyrzuca graczy i zapisuje postacie
	var err := UiUpdater.launch_update(_pack)
	if err != "":
		busy = false
		_log(err)
		return
	get_tree().quit()
