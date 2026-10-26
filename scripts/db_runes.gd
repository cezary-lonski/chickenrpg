class_name RuneDB
extends RefCounted
## Runy: zapis słowa runami (alfabet z tablicy) na przedmiocie. Słowo zmienia rzadkość,
## wzmacnia statystyki albo dodaje kradzież życia. Efekt zapisuje się w meta przedmiotu
## ("m": {r: rzadkość, b: wzmocnienia, fx: {...}, ws: [słowa]}).
##
## tier: rare | epic | legend | hyper | extra

const WORDS := {
	"KURCZAK": {"tier": "extra", "cost": {"gold": 3000, "krysztal_cienia": 4, "pierwiastek_bu": 2, "sztabka_kurczalium": 2},
		"desc": "Rzadkość HIPEREKSTRALEGENDARNA, ogromne statystyki, +5% kradzieży życia i +5% redukcji obrażeń."},
	"CZARKA": {"tier": "hyper", "cost": {"gold": 1500, "krysztal_cienia": 3, "sztabka_kurczalium": 1},
		"desc": "Rzadkość HIPERLEGENDARNA i dodatkowa kradzież życia (+4%)."},
	"KURZA": {"tier": "legend", "cost": {"gold": 700, "krysztal_cienia": 2},
		"desc": "Przedmiot staje się LEGENDARNY; jeśli już jest — jego statystyki rosną o 20%."},
	"ZAKAZ": {"tier": "legend", "cost": {"gold": 700, "krysztal_cienia": 2},
		"desc": "Przedmiot staje się LEGENDARNY; jeśli już jest — jego statystyki rosną o 20%."},
	"KURA": {"tier": "epic", "cost": {"gold": 250, "krysztal_cienia": 1}, "desc": "Słabszy przedmiot staje się EPICKI."},
	"KURZ": {"tier": "epic", "cost": {"gold": 250, "krysztal_cienia": 1}, "desc": "Słabszy przedmiot staje się EPICKI."},
	"CZAR": {"tier": "epic", "cost": {"gold": 250, "krysztal_cienia": 1}, "desc": "Słabszy przedmiot staje się EPICKI."},
	"ARKA": {"tier": "epic", "cost": {"gold": 250, "krysztal_cienia": 1}, "desc": "Słabszy przedmiot staje się EPICKI."},
	"KUC": {"tier": "rare", "cost": {"gold": 80}, "desc": "Słabszy przedmiot staje się RZADKI."},
	"RAK": {"tier": "rare", "cost": {"gold": 80}, "desc": "Słabszy przedmiot staje się RZADKI."},
	"RAZ": {"tier": "rare", "cost": {"gold": 80}, "desc": "Słabszy przedmiot staje się RZADKI."},
	"UCZ": {"tier": "rare", "cost": {"gold": 80}, "desc": "Słabszy przedmiot staje się RZADKI."},
}

const TIER_RARITY := {
	"rare": "rzadki", "epic": "epicki", "legend": "legendarny", "hyper": "hiperlegendarny", "extra": "hiperextralegendarny",
}

## Obrysy run (znormalizowane 0..1, y w dół): lista linii łamanych.
const GLYPHS := {
	"U": [[Vector2(0.2, 1.0), Vector2(0.2, 0.15), Vector2(0.8, 0.15), Vector2(0.8, 1.0)]],
	"K": [[Vector2(0.3, 0.0), Vector2(0.3, 1.0)], [Vector2(0.3, 0.0), Vector2(0.14, 0.12)], [Vector2(0.3, 0.45), Vector2(0.5, 0.3), Vector2(0.72, 0.4), Vector2(0.78, 0.7), Vector2(0.72, 1.0)]],
	"C": [[Vector2(0.3, 0.0), Vector2(0.3, 1.0)], [Vector2(0.3, 0.1), Vector2(0.85, 0.65)]],
	"Z": [[Vector2(0.5, 0.0), Vector2(0.5, 1.0)], [Vector2(0.12, 0.75), Vector2(0.5, 0.4), Vector2(0.88, 0.75)]],
	"R": [[Vector2(0.25, 1.0), Vector2(0.25, 0.0), Vector2(0.8, 0.25), Vector2(0.25, 0.5), Vector2(0.8, 1.0)]],
	"A": [[Vector2(0.25, 1.0), Vector2(0.25, 0.0), Vector2(0.8, 0.2)], [Vector2(0.25, 0.4), Vector2(0.8, 0.6)]],
}

static func has(word: String) -> bool:
	return WORDS.has(word)

static func cost_text(word: String) -> String:
	var parts: Array = []
	var c: Dictionary = WORDS[word]["cost"]
	for id in c:
		if id == "gold":
			parts.append("%d zł" % int(c[id]))
		else:
			parts.append("%s ×%d" % [String(ItemDB.get_data(String(id)).get("name", id)), int(c[id])])
	return ", ".join(parts)

static func can_pay(word: String) -> bool:
	var c: Dictionary = WORDS[word]["cost"]
	for id in c:
		if id == "gold":
			if GameState.gold() < int(c[id]): return false
		elif GameState.item_count(String(id)) < int(c[id]):
			return false
	return true

static func pay(word: String) -> bool:
	if not can_pay(word):
		return false
	var c: Dictionary = WORDS[word]["cost"]
	for id in c:
		if id == "gold":
			GameState.spend(int(c[id]))
		else:
			GameState.remove_item(String(id), int(c[id]))
	return true

## Czy runy dadzą jakiś efekt na tym przedmiocie? Zwraca {ok, msg}.
static func check(item_id: String, meta: Dictionary, word: String) -> Dictionary:
	if not ItemDB.is_gear(item_id):
		return {"ok": false, "msg": "Runy można zapisać tylko na wyposażeniu."}
	var tier := String(WORDS[word]["tier"])
	var cur := ItemDB.rarity_index(ItemDB.meta_rarity(item_id, meta))
	var target := ItemDB.rarity_index(String(TIER_RARITY[tier]))
	if tier in ["rare", "epic"] and cur >= target:
		return {"ok": false, "msg": "Przedmiot jest już co najmniej tej rzadkości — runy nie mają efektu."}
	if int(meta.get("b", 0)) >= 3 and cur >= target and tier in ["legend", "hyper", "extra"]:
		return {"ok": false, "msg": "Przedmiot osiągnął maksymalne wzmocnienie runami."}
	return {"ok": true, "msg": ""}

## Nowe meta po zapisie słowa (nie zmienia argumentu).
static func apply(item_id: String, meta: Dictionary, word: String) -> Dictionary:
	var m := meta.duplicate(true)
	var tier := String(WORDS[word]["tier"])
	var cur := ItemDB.rarity_index(ItemDB.meta_rarity(item_id, m))
	var target_name := String(TIER_RARITY[tier])
	var target := ItemDB.rarity_index(target_name)
	if cur < target:
		m["r"] = target_name
	elif tier in ["legend", "hyper", "extra"]:
		m["b"] = int(m.get("b", 0)) + 1
	var fx: Dictionary = m.get("fx", {})
	if tier == "hyper":
		fx["lifesteal"] = maxf(float(fx.get("lifesteal", 0.0)), 0.04)
	elif tier == "extra":
		fx["lifesteal"] = maxf(float(fx.get("lifesteal", 0.0)), 0.05)
		fx["dmg_reduction"] = maxf(float(fx.get("dmg_reduction", 0.0)), 0.05)
	m["fx"] = fx
	var ws: Array = m.get("ws", [])
	if word not in ws:
		ws.append(word)
	m["ws"] = ws
	return m

# ------------------------------------------------------------------- wzorce ---
## Kowal zna wzór słowa dopiero po zdobyciu wzorca („wzorzec_<słowo>”): z potworów, skrzyń,
## jaskiń, bossów albo ze sklepu (najprostsze). Użyty wzorzec zostaje w pamięci kowala na stałe.

const PATTERN_TIERS := {"rare": 0, "epic": 1, "legend": 2, "hyper": 3, "extra": 4}

static func pattern_id(word: String) -> String:
	return "wzorzec_" + word.to_lower()

static func word_of_pattern(id: String) -> String:
	if id.begins_with("wzorzec_"):
		var w := id.substr(8).to_upper()
		return w if WORDS.has(w) else ""
	return ""

static func pattern_items() -> Dictionary:
	var out := {}
	var rar := {"rare": "rzadki", "epic": "epicki", "legend": "legendarny", "hyper": "legendarny", "extra": "hiperlegendarny"}
	for w in WORDS:
		var tier := String(WORDS[w]["tier"])
		out[pattern_id(String(w))] = {
			"name": "Wzorzec run: %s" % String(w), "slot": "pattern", "tier": 2 + int(PATTERN_TIERS[tier]), "price": 60 if tier == "rare" else 0,
			"icon": "krysztal", "stack": 5, "rarity": rar[tier], "tint": Color(1.0, 0.85, 0.45),
			"desc": "Szkic run słowa %s. Przekaż go kowalowi (zapis run), a nauczy się go na stałe." % String(w), "stats": {},
		}
	return out

static func is_known(word: String) -> bool:
	return word in GameState.known_runes()

## Losowy wzorzec dla wroga danego poziomu (tylko nieznany i nieposiadany); "" jeśli brak.
static func random_pattern(enemy_tier: int) -> String:
	var max_t := 0
	if enemy_tier >= 3: max_t = 1
	if enemy_tier >= 5: max_t = 2
	if enemy_tier >= 6: max_t = 3
	var pool: Array = []
	for w in WORDS:
		if int(PATTERN_TIERS[String(WORDS[w]["tier"])]) <= max_t and not is_known(String(w)) and GameState.item_count(pattern_id(String(w))) == 0:
			pool.append(pattern_id(String(w)))
	return "" if pool.is_empty() else String(pool[randi() % pool.size()])
