class_name UiUpdater
extends PanelContainer
## Auto-aktualizacja: przy starcie menu sprawdza najnowsze wydanie na GitHubie. Jeśli jest nowsze niż
## wersja gry (application/config/version), pokazuje pasek i od razu rozpoczyna aktualizację (raz na uruchomienie, jeden raz na tag; przycisk „Aktualizuj" zostaje na wypadek błędu). Windows i Linux: pobiera paczkę
## (.zip / .tar.gz), podmienia program (skrypt pomocniczy działa po zamknięciu) i uruchamia nową wersję.
## Android: otwiera pobieranie .apk. Te same funkcje statyczne używa serwer (ServerUpdater).

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

## Paczka pasująca do systemu: Windows — .zip, Linux — .tar.gz, Android — .apk (serwer ma własny .apk).
static func asset_url(assets: Array) -> String:
	var os_name := OS.get_name()
	for a in assets:
		var n := String(a.get("name", "")).to_lower()
		var ok := false
		match os_name:
			"Windows":
				ok = n.ends_with(".zip") and n.begins_with("chickenrpg")
			"Linux":
				ok = n.ends_with("linux.tar.gz") and n.begins_with("chickenrpg")
			"Android":
				ok = n.ends_with(".apk") and n.begins_with("chickenserwer" if ServerMode.is_active() else "chickenrpg")
		if ok:
			return String(a.get("browser_download_url", ""))
	return ""

## Najnowsze wydanie z paczką dla tego systemu: {"tag", "url"} albo {} gdy brak.
static func pick_release(data: Variant) -> Dictionary:
	if not (data is Array):
		return {}
	var best_tag := ""
	var best_url := ""
	for rel in data:
		if not (rel is Dictionary) or bool(rel.get("draft", false)):
			continue
		var tag := String(rel.get("tag_name", ""))
		var url := asset_url(rel.get("assets", []))
		if url == "":
			continue
		if best_tag == "" or UiUpdater.is_newer(tag, best_tag):
			best_tag = tag
			best_url = url
	return {} if best_tag == "" else {"tag": best_tag, "url": best_url}

func _on_list(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return
	var best := UiUpdater.pick_release(JSON.parse_string(body.get_string_from_utf8()))
	if best.is_empty() or not UiUpdater.is_newer(String(best["tag"]), current_version()):
		return
	_tag = String(best["tag"])
	_asset_url = String(best["url"])
	_label.text = "Dostępna nowa wersja: %s (masz %s)" % [_tag, current_version()]
	visible = true
	if _auto_tried or OS.get_name() not in ["Windows", "Linux", "Android"] or UiUpdater._last_auto_tag() == _tag:
		return
	# po każdym uruchomieniu gry nowa wersja instaluje się sama; ten sam tag nie jest ponawiany automatycznie
	# (gdyby wersja w paczce nie zgadzała się z tagiem, gra nie wpadnie w pętlę aktualizacji)
	_auto_tried = true
	UiUpdater._save_last_auto_tag(_tag)
	_label.text = "Nowa wersja %s — uruchamiam aktualizację…" % _tag
	_on_update()

static var _auto_tried := false
const AUTO_TAG_FILE := "user://last_auto_update.txt"

static func _last_auto_tag() -> String:
	if not FileAccess.file_exists(AUTO_TAG_FILE):
		return ""
	return FileAccess.get_file_as_string(AUTO_TAG_FILE).strip_edges()

static func _save_last_auto_tag(tag: String) -> void:
	var f := FileAccess.open(AUTO_TAG_FILE, FileAccess.WRITE)
	if f:
		f.store_string(tag)

func _on_update() -> void:
	if _asset_url == "" or OS.get_name() not in ["Windows", "Linux"]:
		# Android: przeglądarka pobiera .apk, a system pyta o instalację; inne systemy — strona wydań
		OS.shell_open(_asset_url if OS.get_name() == "Android" and _asset_url != "" else PAGE)
		return
	_btn.disabled = true
	_bar.visible = true
	_label.text = "Pobieram %s…" % _tag
	_zip_path = UiUpdater.download_path()
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

## Gdzie zapisać pobraną paczkę: obok programu (a jeśli się nie da, w danych użytkownika).
static func download_path() -> String:
	var ext := ".tar.gz" if OS.get_name() == "Linux" else ".zip"
	var path := OS.get_executable_path().get_base_dir().path_join("ChickenRPG-update" + ext)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return ProjectSettings.globalize_path("user://ChickenRPG-update" + ext)
	f.close()
	return path

## Argumenty uruchomienia (np. --headless -- --server), żeby po aktualizacji program wystartował tak samo.
static func restart_args() -> PackedStringArray:
	var out := PackedStringArray(OS.get_cmdline_args())
	var user := PackedStringArray(OS.get_cmdline_user_args())
	if ServerMode.is_active() and "--autostart" not in user:
		user.append("--autostart")      # serwer po aktualizacji od razu wstaje, bez klikania
	if not user.is_empty():
		out.append("--")
		out.append_array(user)
	return out

static func _q(s: String) -> String:
	return "\"%s\"" % s

## Skrypt .bat: czeka na zamknięcie programu, rozpakowuje paczkę, podmienia exe (ChickenRPG.exe albo ChickenSerwer.exe),
## uruchamia nową wersję z tymi samymi argumentami i sam się usuwa.
static func build_script(exe_path: String, zip_path: String, args: PackedStringArray = PackedStringArray()) -> String:
	var exe := exe_path.replace("/", "\\")
	var zip := zip_path.replace("/", "\\")
	var tmp := exe.get_base_dir().path_join("ChickenRPG-update-tmp").replace("/", "\\")
	var quoted: Array = []
	for a in args:
		quoted.append(_q(String(a)))
	var arg_s := " ".join(quoted)
	var lines := PackedStringArray([
		"@echo off",
		"timeout /t 2 /nobreak >nul",
		"powershell -NoProfile -Command \"Expand-Archive -LiteralPath '%s' -DestinationPath '%s' -Force\"" % [zip, tmp],
		"for /l %%i in (1,1,30) do (",
		"  move /Y \"%s\\%s\" \"%s\" >nul 2>&1 && goto done" % [tmp, exe.get_file(), exe],
		"  timeout /t 1 /nobreak >nul",
		")",
		":done",
		"del \"%s\" >nul 2>&1" % zip,
		"rmdir /s /q \"%s\" >nul 2>&1" % tmp,
		"start \"\" \"%s\" %s" % [exe, arg_s],
		"del \"%~f0\"",
	])
	return "\r\n".join(lines) + "\r\n"

## Skrypt .sh (Linux): czeka na zamknięcie, rozpakowuje tar.gz, podmienia plik wykonywalny i uruchamia go ponownie.
static func build_script_linux(exe_path: String, tar_path: String, args: PackedStringArray = PackedStringArray()) -> String:
	var tmp := exe_path.get_base_dir().path_join("ChickenRPG-update-tmp")
	var quoted: Array = []
	for a in args:
		quoted.append("'%s'" % String(a).replace("'", "'\\''"))
	var arg_s := " ".join(quoted)
	var lines := PackedStringArray([
		"#!/bin/sh",
		"sleep 2",
		"mkdir -p '%s'" % tmp,
		"tar xzf '%s' -C '%s'" % [tar_path, tmp],
		"NEW=$(find '%s' -name '%s' | head -n 1)" % [tmp, exe_path.get_file()],
		"if [ -n \"$NEW\" ]; then cp -f \"$NEW\" '%s' && chmod +x '%s'; fi" % [exe_path, exe_path],
		"rm -rf '%s' '%s'" % [tmp, tar_path],
		"cd '%s'" % exe_path.get_base_dir(),
		"nohup '%s' %s >/dev/null 2>&1 &" % [exe_path, arg_s],
		"rm -- \"$0\"",
	])
	return "\n".join(lines) + "\n"

## Zapisuje skrypt aktualizacji i uruchamia go; po udanym wywołaniu wołający MUSI zamknąć program. Zwraca "" albo błąd.
static func launch_update(pack_path: String) -> String:
	var exe := OS.get_executable_path()
	var win := OS.get_name() == "Windows"
	var script_path := exe.get_base_dir().path_join("ChickenRPG-update.bat" if win else "ChickenRPG-update.sh")
	var script := build_script(exe, pack_path, restart_args()) if win else build_script_linux(exe, pack_path, restart_args())
	var f := FileAccess.open(script_path, FileAccess.WRITE)
	if f == null:
		return "Brak uprawnień do zapisu w folderze programu."
	f.store_string(script)
	f.close()
	if win:
		OS.create_process("cmd.exe", ["/c", script_path.replace("/", "\\")])
	else:
		OS.create_process("sh", [script_path])
	return ""

func _on_downloaded(result: int, code: int, _h: PackedStringArray, _b: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_fail("Pobieranie nie powiodło się (%d)." % code)
		return
	_label.text = "Instaluję… program uruchomi się ponownie."
	var err := UiUpdater.launch_update(_zip_path)
	if err != "":
		_fail(err)
		return
	get_tree().quit()
