class_name ServerMode
extends RefCounted
## Czy ta instancja to aplikacja ChickenSerwer (flaga `--server` albo cecha eksportu `chickenserwer`).

static var _cached := -1

static func is_active() -> bool:
	if _cached < 0:
		var on := OS.has_feature("chickenserwer")
		if not on:
			on = "--server" in OS.get_cmdline_args() or "--server" in OS.get_cmdline_user_args()
		_cached = 1 if on else 0
	return _cached == 1

## Wartość opcji `--nazwa=wartość` albo `--nazwa wartość` z linii poleceń (puste, gdy brak).
static func arg(name: String, fallback: String = "") -> String:
	var all := OS.get_cmdline_args() + OS.get_cmdline_user_args()
	for i in all.size():
		var a := String(all[i])
		if a.begins_with("--%s=" % name):
			return a.substr(name.length() + 3)
		if a == "--" + name and i + 1 < all.size():
			return String(all[i + 1])
	return fallback

static func flag(name: String) -> bool:
	return ("--" + name) in OS.get_cmdline_args() or ("--" + name) in OS.get_cmdline_user_args()
