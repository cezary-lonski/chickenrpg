class_name UiUpdater
extends PanelContainer
## Auto-aktualizacja: przy starcie menu sprawdza najnowsze wydanie na GitHubie. Jeśli jest nowsze niż
## wersja gry (application/config/version), pokazuje pasek z przyciskiem „Aktualizuj". Na Windows pobiera
## paczkę .zip, podmienia ChickenRPG.exe (skrypt pomocniczy działa po zamknięciu gry) i uruchamia nową wersję.

const REPO := "cezary-lonski/chickenrpg"
const API := "https://api.github.com/repos/%s/releases?per_page=10" % REPO
const PAGE := "https://github.com/%s/releases" % REPO

var _http: HTTPRequest
var _label: Label
var _btn: Button
var _bar: ProgressBar
var _asset_url := ""
var _tag := ""
var _zip_path := ""

## Wersja gry jako liczby (np. "0.1.0-beta" → [0,1,0], "v0.2-beta" → [0,2]).
static func parse_version(v: String) -> Array:
	var out: Array = []
	var cur := ""
	for ch in v.strip_edges().trim_prefix("v").trim_prefix("V"):
		if ch >= "0" and ch <= "9":
			cur += ch
		elif ch == "." and cur != "":
			out.append(int(cur))
			cur = ""
		else:
			break
	if cur != "":
		out.append(int(cur))
	return out

## Czy wersja `a` jest nowsza od `b`.
static func is_newer(a: String, b: String) -> bool:
	var x := parse_version(a)
	var y := parse_version(b)
	for i in maxi(x.size(), y.size()):
		var xi: int = x[i] if i < x.size() else 0
		var yi: int = y[i] if i < y.size() else 0
		if xi != yi:
			return xi > yi
	return false

static func current_version() -> String:
	return String(ProjectSettings.get_setting("application/config/version", "0.0.0"))

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	position = Vector2(14, 14)
	var s := UiKit.sb(Color(0.12, 0.08, 0.04, 0.92), 6, 3, UiKit.ACCENT)
	add_theme_stylebox_override("panel", s)
	var v := UiKit.vbox(6)
	add_child(v)
	_label = UiKit.label("", 15, UiKit.TEXT)
	v.add_child(_label)
	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(300, 14)
	_bar.show_percentage = false
	_bar.visible = false
	v.add_child(_bar)
	_btn = UiKit.button("Aktualizuj teraz", 16, UiKit.GOOD)
	_btn.pressed.connect(_on_update)
	v.add_child(_btn)
	if OS.has_feature("editor") or not UiUpdater.auto_enabled():
		return
	_http = HTTPRequest.new()
	_http.timeout = 12.0
	add_child(_http)
	_http.request_completed.connect(_on_list)
	_http.request(API, ["User-Agent: ChickenRPG-updater", "Accept: application/vnd.github+json"])

static func auto_enabled() -> bool:
	return true

func _on_list(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return
	var data = JSON.parse_string(body.get_string_from_utf8())
	if not (data is Array):
		return
	var best_tag := ""
	var best_url := ""
	for rel in data:
		if not (rel is Dictionary) or bool(rel.get("draft", false)):
			continue
		var tag := String(rel.get("tag_name", ""))
		var url := ""
		for a in rel.get("assets", []):
			var n := String(a.get("name", "")).to_lower()
			if n.ends_with(".zip") and (n.contains("win") or n.contains("windows")):
				url = String(a.get("browser_download_url", ""))
				break
		if url == "":
			continue
		if best_tag == "" or UiUpdater.is_newer(tag, best_tag):
			best_tag = tag
			best_url = url
	if best_tag == "" or not UiUpdater.is_newer(best_tag, current_version()):
		return
	_tag = best_tag
	_asset_url = best_url
	_label.text = "Dostępna nowa wersja: %s (masz %s)" % [_tag, current_version()]
	visible = true

func _on_update() -> void:
	if OS.get_name() != "Windows" or _asset_url == "":
		OS.shell_open(PAGE)
		return
	_btn.disabled = true
	_bar.visible = true
	_label.text = "Pobieram %s…" % _tag
	var dir := OS.get_executable_path().get_base_dir()
	_zip_path = dir.path_join("ChickenRPG-update.zip")
	var f := FileAccess.open(_zip_path, FileAccess.WRITE)
	if f == null:
		_zip_path = ProjectSettings.globalize_path("user://ChickenRPG-update.zip")
	else:
		f.close()
	var dl := HTTPRequest.new()
	dl.download_file = _zip_path
	dl.timeout = 0.0
	add_child(dl)
	dl.request_completed.connect(_on_downloaded)
	set_process(true)
	_dl = dl
	if dl.request(_asset_url, ["User-Agent: ChickenRPG-updater"]) != OK:
		_fail("Nie udało się rozpocząć pobierania.")

var _dl: HTTPRequest

func _process(_d: float) -> void:
	if _dl and is_instance_valid(_dl):
		var total := _dl.get_body_size()
		if total > 0:
			_bar.value = 100.0 * float(_dl.get_downloaded_bytes()) / float(total)

func _fail(msg: String) -> void:
	_label.text = msg + " Pobierz ręcznie: strona wydań."
	_btn.disabled = false
	_btn.text = "Otwórz stronę wydań"
	_btn.pressed.disconnect(_on_update)
	_btn.pressed.connect(func(): OS.shell_open(PAGE))
	_bar.visible = false

## Skrypt .bat: czeka na zamknięcie gry, rozpakowuje paczkę, podmienia exe, uruchamia nową wersję i sam się usuwa.
static func build_script(exe_path: String, zip_path: String) -> String:
	var exe := exe_path.replace("/", "\\")
	var zip := zip_path.replace("/", "\\")
	var tmp := exe.get_base_dir().path_join("ChickenRPG-update-tmp").replace("/", "\\")
	var lines := PackedStringArray([
		"@echo off",
		"timeout /t 2 /nobreak >nul",
		"powershell -NoProfile -Command \"Expand-Archive -LiteralPath '%s' -DestinationPath '%s' -Force\"" % [zip, tmp],
		"for /l %%i in (1,1,30) do (",
		"  move /Y \"%s\\ChickenRPG.exe\" \"%s\" >nul 2>&1 && goto done" % [tmp, exe],
		"  timeout /t 1 /nobreak >nul",
		")",
		":done",
		"del \"%s\" >nul 2>&1" % zip,
		"rmdir /s /q \"%s\" >nul 2>&1" % tmp,
		"start \"\" \"%s\"" % exe,
		"del \"%~f0\"",
	])
	return "\r\n".join(lines) + "\r\n"

func _on_downloaded(result: int, code: int, _h: PackedStringArray, _b: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_fail("Pobieranie nie powiodło się (%d)." % code)
		return
	_label.text = "Instaluję… gra uruchomi się ponownie."
	var exe := OS.get_executable_path().replace("/", "\\")
	var bat := exe.get_base_dir().path_join("ChickenRPG-update.bat").replace("/", "\\")
	var script := UiUpdater.build_script(exe, _zip_path)
	var f := FileAccess.open(bat, FileAccess.WRITE)
	if f == null:
		_fail("Brak uprawnień do zapisu w folderze gry.")
		return
	f.store_string(script)
	f.close()
	OS.create_process("cmd.exe", ["/c", bat])
	get_tree().quit()
