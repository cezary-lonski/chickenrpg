class_name CosmeticDB
extends RefCounted
## Kosmetyka postaci: kolorowane części, ubrania (warstwy), animacje części ciała
## i wizualizacja wyposażenia. Nic tu nie zmienia statystyk.

## Części, których kolor można zmienić (klucz palety → nazwa w UI).
const PARTS := {
	"body": "Upierzenie",
	"shade": "Cień / skrzydła",
	"comb": "Grzebień i dzwonki",
	"beak": "Dziób",
	"leg": "Nogi",
	"eye": "Oczy",
}

## Sloty ubrań. Każdy element ma kolor główny i dodatkowy (wykończenie).
const CLOTH_SLOTS := {
	"head": "Nakrycie głowy",
	"neck": "Szyja",
	"back": "Plecy",
}

const CLOTHES := {
	"head": {
		"czapka": {"name": "Czapka z pomponem", "main": "#3a6ea5", "trim": "#f0e6c8"},
		"cylinder": {"name": "Cylinder", "main": "#202028", "trim": "#a32a3a"},
		"korona": {"name": "Korona", "main": "#e8b923", "trim": "#c0302f"},
		"chustka": {"name": "Chustka", "main": "#b02f2f", "trim": "#f2f2f2"},
	},
	"neck": {
		"szalik": {"name": "Szalik", "main": "#c0392b", "trim": "#f4d03f"},
		"muszka": {"name": "Mucha", "main": "#2c3e8f", "trim": "#ffffff"},
	},
	"back": {
		"peleryna": {"name": "Peleryna", "main": "#5b2a86", "trim": "#e8b923"},
		"plecak": {"name": "Plecak podróżny", "main": "#7a5230", "trim": "#c9a66b"},
	},
}

## Nazwy części, którymi steruje edytor animacji.
const ANIM_PARTS := {
	"body": "Tułów",
	"head": "Głowa",
	"wing": "Skrzydło",
	"legs": "Nogi",
	"tail": "Ogon",
	"weapon": "Broń",
}

const ANIM_NAMES := {
	"idle": "Bezczynność",
	"walk": "Chodzenie",
	"run": "Bieg",
	"attack": "Atak",
	"skill": "Użycie umiejętności",
	"hurt": "Otrzymanie obrażeń",
	"death": "Śmierć",
}

const EMBLEM_SIZE := 12

static func blank_appearance() -> Dictionary:
	return {
		"look": "",            # id bazowego wyglądu z CharacterDB ("" = wg postaci)
		"name": "",
		"colors": {},          # część → "#rrggbb"
		"clothes": {},         # slot → {id, main, trim}
		"emblem": [],          # EMBLEM_SIZE² kolorów html lub ""
	}

static func cloth_default(slot: String, id: String) -> Dictionary:
	var d: Dictionary = CLOTHES.get(slot, {}).get(id, {})
	return {"id": id, "main": String(d.get("main", "#ffffff")), "trim": String(d.get("trim", "#ffffff"))}

# ----------------------------------------------------------------- animacje ---

## Domyślne animacje (addytywne względem animacji proceduralnej). Format klatki:
## {"t": czas, "parts": {część: [x, y, obrót_rad]}}
static func default_anims() -> Dictionary:
	return {
		"idle": _anim(1.6, true, [
			[0.0, {"head": [0, 0, 0.0], "body": [0, 0, 0.0], "wing": [0, 0, 0.0]}],
			[0.8, {"head": [0, -1, 0.08], "body": [0, 1, 0.0], "wing": [0, 0, 0.06]}],
		]),
		"walk": _anim(0.5, true, [
			[0.0, {"head": [0, 0, -0.06], "tail": [0, 0, 0.1]}],
			[0.25, {"head": [0, -1, 0.06], "tail": [0, 0, -0.1]}],
		]),
		"run": _anim(0.4, true, [
			[0.0, {"head": [2, 0, 0.1], "body": [0, 0, 0.12], "tail": [0, 0, 0.2]}],
			[0.2, {"head": [2, -1, 0.14], "body": [0, -1, 0.14], "tail": [0, 0, 0.3]}],
		]),
		"attack": _anim(0.35, false, [
			[0.0, {"body": [-3, 0, -0.1], "wing": [0, 0, -0.5], "weapon": [0, 0, -0.5]}],
			[0.12, {"body": [4, 0, 0.12], "wing": [0, 0, 0.9], "weapon": [0, 0, 1.0]}],
			[0.35, {"body": [0, 0, 0.0], "wing": [0, 0, 0.0], "weapon": [0, 0, 0.0]}],
		]),
		"skill": _anim(0.6, false, [
			[0.0, {"body": [0, 0, 0.0], "wing": [0, 0, 0.0], "head": [0, 0, 0.0]}],
			[0.25, {"body": [0, -3, -0.08], "wing": [0, -2, -1.0], "head": [0, -2, -0.15]}],
			[0.6, {"body": [0, 0, 0.0], "wing": [0, 0, 0.0], "head": [0, 0, 0.0]}],
		]),
		"hurt": _anim(0.3, false, [
			[0.0, {"body": [-4, 0, -0.2], "head": [-3, 0, -0.3]}],
			[0.3, {"body": [0, 0, 0.0], "head": [0, 0, 0.0]}],
		]),
		"death": _anim(0.8, false, [
			[0.0, {"body": [0, 0, 0.0], "head": [0, 0, 0.0], "wing": [0, 0, 0.0]}],
			[0.8, {"body": [-6, 4, -0.5], "head": [-4, 6, -0.7], "wing": [0, 0, -1.2]}],
		]),
	}

static func _anim(duration: float, loop: bool, frames: Array) -> Dictionary:
	var fr: Array = []
	for f in frames:
		fr.append({"t": float(f[0]), "parts": (f[1] as Dictionary).duplicate(true)})
	return {"duration": duration, "loop": loop, "smooth": true, "frames": fr}

## Wartość [x, y, rot] części w czasie t. Zwraca zera, gdy brak danych.
static func sample(anim: Dictionary, part: String, t: float) -> Array:
	var frames: Array = anim.get("frames", [])
	if frames.is_empty():
		return [0.0, 0.0, 0.0]
	var dur := maxf(0.05, float(anim.get("duration", 1.0)))
	if bool(anim.get("loop", true)):
		t = fposmod(t, dur)
	else:
		t = clampf(t, 0.0, dur)
	var prev: Dictionary = frames[0]
	var next: Dictionary = frames[frames.size() - 1]
	for i in frames.size():
		var f: Dictionary = frames[i]
		if float(f["t"]) <= t:
			prev = f
		if float(f["t"]) >= t:
			next = f
			break
	var a := _vec(prev, part)
	var b := _vec(next, part)
	var span := float(next["t"]) - float(prev["t"])
	var k := 0.0 if span <= 0.0001 else clampf((t - float(prev["t"])) / span, 0.0, 1.0)
	if bool(anim.get("smooth", true)):
		k = k * k * (3.0 - 2.0 * k)
	return [lerpf(a[0], b[0], k), lerpf(a[1], b[1], k), lerpf(a[2], b[2], k)]

static func _vec(frame: Dictionary, part: String) -> Array:
	var p: Array = frame.get("parts", {}).get(part, [0.0, 0.0, 0.0])
	return [float(p[0]), float(p[1]), float(p[2])]

# ---------------------------------------------------------------- wyposażenie ---

## Opis wizualny przedmiotu (kolory/kształt) do narysowania na postaci.
static func item_visual(id: String) -> Dictionary:
	var d := ItemDB.get_data(id)
	if d.is_empty():
		return {}
	if d.has("vis"):
		return d["vis"]
	var tier := int(d.get("tier", 1))
	var metals := [Color(0.62, 0.64, 0.68), Color(0.72, 0.75, 0.82), Color(0.9, 0.78, 0.35), Color(0.45, 0.8, 0.95), Color(0.75, 0.4, 0.95), Color(0.95, 0.4, 0.3)]
	var c: Color = metals[clampi(tier - 1, 0, metals.size() - 1)]
	return {"col": c, "style": "plain"}

## Wizualizacja całego zestawu: {weapon, armor, helmet, boots, amulet, aura}
## meta (slot → meta run) decyduje o aurze: rzadkość ≥ hiperlegendarna na zbroi daje płomienie.
static func gear_visual(equip: Dictionary, meta: Dictionary = {}) -> Dictionary:
	var out := {}
	for slot in ["weapon", "armor", "helmet", "boots", "amulet"]:
		var id := String(equip.get(slot, ""))
		if id != "" and ItemDB.has(id):
			var v := item_visual(id)
			if not v.is_empty():
				out[slot] = v
	var acc := String(equip.get("accessory", ""))
	if acc != "" and not out.has("amulet") and ItemDB.has(acc):
		var va := item_visual(acc)
		if not va.is_empty():
			out["amulet"] = va
	for slot in ["weapon", "armor", "helmet", "boots", "amulet"]:
		if out.has(slot):
			var aura := String((out[slot] as Dictionary).get("aura", ""))
			if aura != "":
				out["aura"] = aura
	var aid := String(equip.get("armor", ""))
	if aid != "":
		var rar := ItemDB.meta_rarity(aid, meta.get("armor", {}))
		if rar == "hiperextralegendarny":
			out["aura"] = "gold_flame"
		elif rar == "hiperlegendarny":
			out["aura"] = "purple_flame"
	return out
