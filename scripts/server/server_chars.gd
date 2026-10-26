class_name ServerChars
extends RefCounted
## Postacie przechowywane na serwerze (user://chickenserwer/characters.txt, format var_to_str).
## Rekord postaci: name, salt, pw, char, class, level, xp, gold, attr_points, attrs, equip, inv, skills,
## known_skills, appearance, admin, created, last_login.

## Katalog danych serwera; `--data=nazwa` pozwala uruchomić drugi, osobny serwer (np. do testów).
static func dir() -> String:
	var d := ServerMode.arg("data")
	return "user://chickenserwer" + ("_" + d if d != "" else "")

static func file() -> String:
	return dir() + "/characters.txt"

const INV_MAX := 40
const SKILL_SLOTS := 9
const MAX_LEVEL := 100
const STAT_KEYS := ["max_health", "max_energy", "strength", "defense", "speed", "crit", "fury_rate", "luck", "throw_power", "poise", "regen",
		"lifesteal", "dmg_reduction", "xp_mult", "gold_mult", "skill_power", "skill_cdr", "skill_cost", "skill_range", "energy_regen"]

var records: Dictionary = {}   # nazwa_lower -> rekord
var _dirty := false

func load_all() -> void:
	records.clear()
	if not FileAccess.file_exists(file()):
		return
	var f := FileAccess.open(file(), FileAccess.READ)
	if f == null:
		return
	var v = str_to_var(f.get_as_text())
	f.close()
	if typeof(v) == TYPE_DICTIONARY:
		records = v

func save_all(force: bool = false) -> void:
	if not _dirty and not force:
		return
	DirAccess.make_dir_recursive_absolute(dir())
	var f := FileAccess.open(file() + ".tmp", FileAccess.WRITE)
	if f == null:
		return
	f.store_string(var_to_str(records))
	f.close()
	DirAccess.rename_absolute(file() + ".tmp", file())
	_dirty = false

func mark_dirty() -> void:
	_dirty = true

static func key_of(name: String) -> String:
	return name.strip_edges().to_lower()

static func valid_name(name: String) -> bool:
	var n := name.strip_edges()
	if n.length() < 2 or n.length() > 16:
		return false
	for i in n.length():
		var c := n[i]
		if not (c == "_" or c == "-" or c == " " or c.to_lower() != c.to_upper() or (c >= "0" and c <= "9")):
			return false
	return true

func get_rec(name: String) -> Dictionary:
	return records.get(key_of(name), {})

func has_rec(name: String) -> bool:
	return records.has(key_of(name))

static func hash_pw(salt: String, pw: String) -> String:
	return (salt + ":" + pw).sha256_text()

func check_pw(rec: Dictionary, pw: String) -> bool:
	return String(rec.get("pw", "")) == hash_pw(String(rec.get("salt", "")), pw)

func names() -> Array:
	var out: Array = []
	for k in records:
		out.append(String(records[k].get("name", k)))
	out.sort()
	return out

# ------------------------------------------------------------------ tworzenie ---

## Zwalidowana kopia postaci z przesłanej paczki klienta (wszystko przycięte do znanych wartości).
static func sanitize_pack(pack: Dictionary, allow_admin_class: bool) -> Dictionary:
	var cid := String(pack.get("char", "kurczak"))
	if not CharacterDB.LIST.has(cid):
		cid = "kurczak"
	var cls := String(pack.get("class", "wojownik"))
	if not ClassDatabase.has(cls) or (cls == "admin" and not allow_admin_class):
		cls = "wojownik"
	var level := clampi(int(pack.get("level", 1)), 1, MAX_LEVEL)
	var equip := {}
	var src_eq = pack.get("equip", {})
	if src_eq is Dictionary:
		for slot in src_eq:
			var iid := String(src_eq[slot])
			if ItemDB.has(iid) and ItemDB.is_gear_slot(String(slot)) and ItemDB.fits_slot(iid, String(slot)):
				equip[String(slot)] = iid
	for slot in ItemDB.defaults():
		if not equip.has(slot):
			equip[slot] = ItemDB.defaults()[slot]
	var inv: Array = []
	var src_inv = pack.get("inv", [])
	if src_inv is Array:
		for e in src_inv:
			if inv.size() >= INV_MAX:
				break
			if e is Dictionary and ItemDB.has(String(e.get("id", ""))):
				var ent := {"id": String(e["id"]), "n": clampi(int(e.get("n", 1)), 1, 999)}
				if ItemDB.is_gear(String(e["id"])):
					var q := clampf(float(e.get("q", 1.0)), 0.5, 1.3)
					var m := _clean_meta(e.get("m", {}))
					if not is_equal_approx(q, 1.0):
						ent["q"] = q
					if not m.is_empty():
						ent["m"] = m
				inv.append(ent)
	var skills: Array = []
	var known: Array = []
	var src_sk = pack.get("skills", [])
	if src_sk is Array:
		for s in src_sk:
			var sid := String(s)
			if sid != "" and SkillDB.has(sid) and sid not in known:
				known.append(sid)
	for s in ClassDatabase.get_data(cls).get("skills", []):
		if s not in known:
			known.append(s)
	if "furia" not in known:
		known.append("furia")
	for i in SKILL_SLOTS:
		var sid2 := ""
		if src_sk is Array and i < (src_sk as Array).size() and String(src_sk[i]) in known:
			sid2 = String(src_sk[i])
		skills.append(sid2)
	var any_skill := false
	for s in skills:
		if s != "":
			any_skill = true
	if not any_skill:
		for i in mini(known.size(), SKILL_SLOTS):
			skills[i] = known[i]
	var attrs := {}
	var attr_points := 0
	var src_at = pack.get("attrs", {})
	for k in GameState.ATTR_ORDER:
		attrs[k] = clampi(int((src_at as Dictionary).get(k, 0)) if src_at is Dictionary else 0, 0, 500)
	attr_points = clampi(int(pack.get("attr_points", 0)), 0, 2000)
	var ap := CosmeticDB.blank_appearance()
	var src_ap = pack.get("appearance", {})
	if src_ap is Dictionary:
		for k in ap.keys():
			if src_ap.has(k) and typeof(src_ap[k]) == typeof(ap[k]):
				ap[k] = src_ap[k].duplicate(true) if (src_ap[k] is Dictionary or src_ap[k] is Array) else src_ap[k]
	var look := String(pack.get("look", ""))
	var story := _sanitize_story(pack.get("story", {}))
	var equip_q := {}
	var equip_m := {}
	for slot in equip:
		var qs = pack.get("equip_q", {}) if pack.get("equip_q") is Dictionary else {}
		var ms = pack.get("equip_m", {}) if pack.get("equip_m") is Dictionary else {}
		if (qs as Dictionary).has(slot):
			equip_q[String(slot)] = clampf(float(qs[slot]), 0.5, 1.3)
		var cm := _clean_meta((ms as Dictionary).get(slot, {}))
		if not cm.is_empty():
			equip_m[String(slot)] = cm
	var out := {
		"char": cid, "class": cls, "level": level, "xp": maxi(0, int(pack.get("xp", 0))),
		"gold": clampi(int(pack.get("gold", 0)), 0, 99999999),
		"attr_points": attr_points, "attrs": attrs, "equip": equip, "inv": inv, "equip_q": equip_q, "equip_m": equip_m,
		"skills": skills, "known_skills": known, "appearance": ap,
		"look": look if CharacterDB.LIST.has(look) else "",
	}
	out["gsx"] = {"act2": _sanitize_act2(pack.get("act2", {}))}
	if not story.is_empty():
		out["story"] = story
		out["zone"] = "story"
	return out

## Własne fale: tylko znane potwory/bossowie i ograniczone mnożniki (ochrona przed farmieniem XP i przeciążeniem serwera).
static func sanitize_waves(src) -> Dictionary:
	var out := {"terrain": "village", "gold": 1.0, "waves": []}
	if not (src is Dictionary):
		return UiWaveEditor.default_config()
	var terr := String((src as Dictionary).get("terrain", "village"))
	out["terrain"] = terr if UiWaveEditor.TERRAINS.has(terr) else "village"
	var waves: Array = []
	for w in ((src as Dictionary).get("waves", []) if (src as Dictionary).get("waves") is Array else []):
		if waves.size() >= 30 or not (w is Dictionary):
			break
		var ens: Array = []
		var total := 0
		for e in ((w as Dictionary).get("enemies", []) if (w as Dictionary).get("enemies") is Array else []):
			if ens.size() >= 12 or not (e is Array) or (e as Array).size() < 2:
				break
			var id := String(e[0])
			var n := clampi(int(e[1]), 1, 60)
			if id.begins_with("BOSS:"):
				var bid := id.substr(5)
				if not BossDB.has(bid) or bid.begins_with("cavebos_"):
					continue
				n = mini(n, 2)
			elif not EnemyDB.LIST.has(id) or bool(EnemyDB.LIST[id].get("boss", false)):
				continue
			if total + n > 120:
				n = maxi(0, 120 - total)
			if n <= 0:
				continue
			total += n
			ens.append([id, n])
		if ens.is_empty():
			continue
		waves.append({"name": String((w as Dictionary).get("name", "Fala")).left(40), "enemies": ens,
			"hp": clampf(float((w as Dictionary).get("hp", 1.0)), 0.5, 200.0), "dmg": clampf(float((w as Dictionary).get("dmg", 1.0)), 0.1, 200.0),
			"xp": clampf(float((w as Dictionary).get("xp", 1.0)), 0.0, 1.5), "elite": bool((w as Dictionary).get("elite", false))})
	if waves.is_empty():
		return UiWaveEditor.default_config()
	out["waves"] = waves
	return out

## Meta przedmiotu (runy): tylko znane klucze i rozsądne wartości.
static func _clean_meta(m) -> Dictionary:
	if not (m is Dictionary) or (m as Dictionary).is_empty():
		return {}
	var out := {}
	var r := String((m as Dictionary).get("r", ""))
	if r != "" and ItemDB.RARITIES.has(r):
		out["r"] = r
	var b := clampi(int((m as Dictionary).get("b", 0)), 0, 3)
	if b > 0:
		out["b"] = b
	var ws: Array = []
	if (m as Dictionary).get("ws") is Array:
		for w in (m as Dictionary)["ws"]:
			if RuneDB.has(String(w)) and String(w) not in ws:
				ws.append(String(w))
	if not ws.is_empty():
		out["ws"] = ws
	var fx := {}
	if (m as Dictionary).get("fx") is Dictionary:
		for k in ["lifesteal", "dmg_reduction"]:
			if ((m as Dictionary)["fx"] as Dictionary).has(k):
				fx[k] = clampf(float(((m as Dictionary)["fx"] as Dictionary)[k]), 0.0, 0.1)
	if not fx.is_empty():
		out["fx"] = fx
	return out

## Uzupełnia pola dodane w późniejszych wersjach serwera w starych rekordach.
static func normalize(rec: Dictionary) -> void:
	if not (rec.get("equip_q") is Dictionary):
		rec["equip_q"] = {}
	if not (rec.get("equip_m") is Dictionary):
		rec["equip_m"] = {}
	if not (rec.get("gsx") is Dictionary):
		rec["gsx"] = {}
	if not (rec.get("support") is Dictionary):
		rec["support"] = {"hp": {}, "fallen": {}}

## Postęp fabuły z zapisu gracza: tylko znane rozdziały z kampanii i flagi rozdziałów.
static func _sanitize_story(src) -> Dictionary:
	if not (src is Dictionary):
		return {}
	var quest := String((src as Dictionary).get("quest", ""))
	var chapter := clampi(int((src as Dictionary).get("chapter", 0)), 0, maxi(0, QuestDB.count() - 1))
	var a2start := QuestDB.act_start(2)
	var in_act2 := a2start >= 0 and chapter >= a2start and chapter < a2start + QuestDB.act_count(2)
	if quest != "" and not ZoneDB.has(quest):
		quest = ""
	if quest == "" and not in_act2:
		quest = String(QuestDB.chapter(chapter).get("id", ""))
	if quest != "" and not ZoneDB.has(quest):
		return {}
	var done: Array = []
	if (src as Dictionary).get("done") is Array:
		for q in (src as Dictionary)["done"]:
			if QuestDB.index_of(String(q)) >= 0 and String(q) not in done:
				done.append(String(q))
	var flags := {}
	if (src as Dictionary).get("flags") is Dictionary:
		for f in (src as Dictionary)["flags"]:
			var fs := String(f)
			if fs == "kowal_gift" or (fs.ends_with("_done") and QuestDB.index_of(fs.trim_suffix("_done")) >= 0):
				flags[fs] = bool((src as Dictionary)["flags"][f])
	return {"chapter": QuestDB.index_of(quest) if quest != "" else chapter, "quest": quest, "done": done, "flags": flags}

## Postęp Aktu II z zapisu: wyzwolone wioski z listy, wdzięczność w rozsądnych granicach.
static func _sanitize_act2(src) -> Dictionary:
	var out := {"liberated": [], "rep": 0, "started": false}
	if not (src is Dictionary):
		return out
	if (src as Dictionary).get("liberated") is Array:
		for v in (src as Dictionary)["liberated"]:
			if String(v) in Act2DB.ORDER and String(v) not in out["liberated"]:
				out["liberated"].append(String(v))
	out["rep"] = clampi(int((src as Dictionary).get("rep", 0)), 0, 50)
	out["started"] = bool((src as Dictionary).get("started", false))
	return out

func create(name: String, password: String, pack: Dictionary, allow_admin_class: bool) -> Dictionary:
	var rec := sanitize_pack(pack, allow_admin_class)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var salt := "%08x%08x" % [rng.randi(), rng.randi()]
	rec["name"] = name.strip_edges()
	rec["salt"] = salt
	rec["pw"] = hash_pw(salt, password)
	rec["admin"] = false
	rec["created"] = Time.get_unix_time_from_system()
	rec["last_login"] = rec["created"]
	if rec["class"] == "admin":
		_grant_admin_skills(rec)
	records[key_of(name)] = rec
	mark_dirty()
	return rec

static func _grant_admin_skills(rec: Dictionary) -> void:
	rec["known_skills"] = SkillDB.all()

## Klasa admin ma wszystkie umiejętności (także po zmianie klasy komendą).
static func refresh_class(rec: Dictionary) -> void:
	if String(rec.get("class", "")) == "admin":
		_grant_admin_skills(rec)
		var sl: Array = rec.get("skills", [])
		var empty := true
		for s in sl:
			if String(s) != "":
				empty = false
		if empty:
			var cs: Array = ClassDatabase.get_data("admin").get("skills", [])
			for i in mini(cs.size(), SKILL_SLOTS):
				sl[i] = cs[i]

# --------------------------------------------------------------- statystyki ---

static func compute_stats(rec: Dictionary) -> Dictionary:
	var cd := CharacterDB.get_data(String(rec.get("char", "kurczak")))
	var base: Dictionary = cd.get("base", {})
	var gains: Dictionary = cd.get("gains", {})
	var lv := float(int(rec.get("level", 1)) - 1)
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
	var eq: Dictionary = rec.get("equip", {})
	var eq_q: Dictionary = rec.get("equip_q", {})
	var eq_m: Dictionary = rec.get("equip_m", {})
	for slot in eq:
		var iid := String(eq[slot])
		var emeta: Dictionary = eq_m.get(slot, {})
		var qm := float(eq_q.get(slot, 1.0)) * ItemDB.meta_mult(iid, emeta)
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
	var attrs: Dictionary = rec.get("attrs", {})
	for k in GameState.ATTR_ORDER:
		var key2 := String(k)
		var bonus := float(int(attrs.get(k, 0))) * float(GameState.ATTRS.get(k, {}).get("per", 0.0))
		if key2 == "health": key2 = "max_health"
		elif key2 == "energy": key2 = "max_energy"
		s[key2] = float(s.get(key2, 0.0)) + bonus
	if String(rec.get("class", "")) == "admin":
		s["max_health"] = float(s["max_health"]) + 9000.0
		s["max_energy"] = float(s["max_energy"]) + 5000.0
		s["strength"] = float(s["strength"]) + 25.0
		s["defense"] = float(s["defense"]) + 25.0
		s["speed"] = float(s["speed"]) + 0.3
		s["crit"] = 0.5
		s["skill_cdr"] = 0.6
		s["skill_cost"] = 0.6
		s["energy_regen"] = 60.0
		s["regen"] = 30.0
	for k in s.keys():
		s[k] = clampf(float(s[k]), -50.0, 100000.0)
	return s

static func xp_needed(level: int) -> int:
	return CharacterDB.xp_for_level(clampi(level, 1, MAX_LEVEL))

## Dodaje XP i zwraca liczbę zdobytych poziomów.
static func add_xp(rec: Dictionary, amount: int) -> int:
	var lvl := int(rec.get("level", 1))
	if lvl >= MAX_LEVEL or amount <= 0:
		return 0
	var xp := int(rec.get("xp", 0)) + amount
	var start := lvl
	while lvl < MAX_LEVEL and xp >= xp_needed(lvl):
		xp -= xp_needed(lvl)
		lvl += 1
	if lvl >= MAX_LEVEL:
		xp = 0
	rec["xp"] = xp
	rec["level"] = lvl
	var gained := lvl - start
	if gained > 0:
		rec["attr_points"] = int(rec.get("attr_points", 0)) + gained * GameState.ATTR_POINTS_PER_LEVEL
	return gained

static func ranks_of(rec: Dictionary) -> Dictionary:
	var out := {}
	for s in rec.get("known_skills", []):
		out[String(s)] = 1
	return out

# ----------------------------------------------------------------- plecak ---

static func _plain(e: Dictionary) -> bool:
	return not e.has("m") and (not e.has("q") or is_equal_approx(float(e["q"]), 1.0))

static func inv_add(rec: Dictionary, id: String, n: int = 1, q: float = 1.0, meta: Dictionary = {}) -> int:
	if not ItemDB.has(id) or n <= 0:
		return 0
	var inv: Array = rec["inv"]
	var left := n
	var cap := ItemDB.stack_of(id)
	var plain := is_equal_approx(q, 1.0) and meta.is_empty()
	if plain:
		for e in inv:
			if String(e["id"]) == id and int(e["n"]) < cap and _plain(e):
				var add := mini(left, cap - int(e["n"]))
				e["n"] = int(e["n"]) + add
				left -= add
				if left <= 0:
					return n
	while left > 0 and inv.size() < INV_MAX:
		var add2 := mini(left, cap)
		var ent := {"id": id, "n": add2}
		if not plain:
			ent["q"] = q
			if not meta.is_empty():
				ent["m"] = meta.duplicate(true)
		inv.append(ent)
		left -= add2
	return n - left

static func inv_remove(rec: Dictionary, id: String, n: int = 1) -> bool:
	var inv: Array = rec["inv"]
	var have := 0
	for e in inv:
		if String(e["id"]) == id:
			have += int(e["n"])
	if have < n:
		return false
	var left := n
	for i in range(inv.size() - 1, -1, -1):
		if String(inv[i]["id"]) != id:
			continue
		var take := mini(left, int(inv[i]["n"]))
		inv[i]["n"] = int(inv[i]["n"]) - take
		left -= take
		if int(inv[i]["n"]) <= 0:
			inv.remove_at(i)
		if left <= 0:
			break
	return true

## Zakłada przedmiot z plecaka (po indeksie); poprzedni wraca do plecaka razem z jakością i runami. Zwraca "" albo błąd.
static func equip_index(rec: Dictionary, idx: int) -> String:
	var inv: Array = rec["inv"]
	if idx < 0 or idx >= inv.size():
		return "Nie ma takiego przedmiotu."
	var e: Dictionary = inv[idx]
	var id := String(e["id"])
	var slot := String(ItemDB.get_data(id).get("slot", ""))
	if not ItemDB.is_gear_slot(slot):
		return "Tego nie da się założyć."
	var eq: Dictionary = rec["equip"]
	var eq_q: Dictionary = rec["equip_q"]
	var eq_m: Dictionary = rec["equip_m"]
	var prev := String(eq.get(slot, ""))
	var prev_q := float(eq_q.get(slot, 1.0))
	var prev_m: Dictionary = eq_m.get(slot, {})
	var q := float(e.get("q", 1.0))
	var m: Dictionary = (e.get("m", {}) as Dictionary).duplicate(true)
	e["n"] = int(e["n"]) - 1
	if int(e["n"]) <= 0:
		inv.remove_at(idx)
	eq[slot] = id
	eq_q[slot] = q
	if m.is_empty():
		eq_m.erase(slot)
	else:
		eq_m[slot] = m
	if prev != "":
		inv_add(rec, prev, 1, prev_q, prev_m)
	return ""

static func unequip(rec: Dictionary, slot: String) -> String:
	var eq: Dictionary = rec["equip"]
	if not eq.has(slot):
		return "Nic tam nie masz."
	var id := String(eq[slot])
	if ItemDB.defaults().has(slot) and String(ItemDB.defaults()[slot]) == id:
		return "To podstawowy przedmiot."
	if inv_add(rec, id, 1, float(rec["equip_q"].get(slot, 1.0)), rec["equip_m"].get(slot, {})) < 1:
		return "Plecak pełny."
	rec["equip_q"].erase(slot)
	rec["equip_m"].erase(slot)
	if ItemDB.defaults().has(slot):
		eq[slot] = ItemDB.defaults()[slot]
	else:
		eq.erase(slot)
	return ""
