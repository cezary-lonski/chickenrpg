class_name MinesDB
extends RefCounted
## Kopalnie wroga do zatopienia: osobne wnętrza (jak obozy niewolników) z patrolami straży, straż i sztygarem,
## uwięzionymi górnikami w klatkach oraz trzema urządzeniami do uruchomienia (każde z inną zagadką). Po trzecim
## kroku śluza zalewa kopalnię (historyjka), strażnicy odchodzą, a na starcie pojawia się wyjście.
## Wejście jest w rozdziale (zone); cel „mine” liczy kroki jak zwykłe cele. Dwie kopalnie: żelaza i soli.

const CAVE_START := Vector2(300, 1300)

const LIST := {
	"kopalnia_zelaza": {
		"zone": "marsz_na_forteca", "name": "Kopalnia Żelaza Kruka", "entrance": Vector2(1900, 1320),
		"shafts": [[Vector2(450, 1180), Vector2(1900, 600)]],
		"hint": "Pod ruiną wieży widać wejście do sztolni. Z głębi dochodzi stukot kilofów i szczekanie sztygara.",
		"intro": [["", "Sztolnie Kopalni Żelaza ciągną się pod całą górą. Strażnicy kruków pilnują korytarzy, a w klatkach siedzą uwięzieni górnicy. Gdzieś w głębi znajdziesz taśmociąg, zasuwę zbiornika i dźwignię śluzy — wystarczy użyć ich po kolei, a woda z rzeki zrobi resztę."]],
		"guards": [
			{"path": [Vector2(500, 1150), Vector2(1200, 1150)], "range": 250.0},
			{"path": [Vector2(1500, 1250), Vector2(1500, 800)], "range": 250.0},
			{"path": [Vector2(900, 700), Vector2(1500, 700), Vector2(1500, 560), Vector2(900, 560)], "range": 230.0},
			{"path": [Vector2(1650, 450), Vector2(2050, 450)], "range": 220.0},
		],
		"waves": [
			{"enemies": [["kruk", 3, false, "straz"], ["wronszek", 2, false, "wlocznik"]], "name": "Straż kopalni"},
			{"enemies": [["bocian_gruby", 1, true]], "name": "Sztygar Kruków", "elite": true},
		],
		"miners": [
			{"id": "gorn_stach", "pos": Vector2(400, 500), "label": "Uwolnij górnika", "name": "Górnik Brodacz",
				"thanks": [["Górnik Brodacz", "Trzy zmiany bez wypłaty! Dzięki. Dźwignia śluzy jest w głębi, ale pamiętaj: najpierw taśmociąg i zasuwa, inaczej woda nie przejdzie."]],
				"reward": {"gold": 90, "xp": 100, "items": {"sztabka_zelaza": 2}}},
			{"id": "gorn_wiercipieta", "pos": Vector2(1100, 380), "label": "Uwolnij górnika", "name": "Młody Wiercipięta",
				"thanks": [["Młody Wiercipięta", "Ja? Ja nic nie robiłem! No, może trochę kilofem. Uciekam do domu, powiedzcie mamie, że żyję!"]],
				"reward": {"gold": 70, "xp": 90, "items": {"mikstura_miodu": 1}}},
			{"id": "gorn_stary", "pos": Vector2(1800, 1180), "label": "Uwolnij górnika", "name": "Stary Sztygar Matejko",
				"thanks": [["Stary Sztygar Matejko", "Pracowałem tu, zanim Kruk wziął kopalnię. Weź ten stary klucz — otwiera zamki, które się zacinają."]],
				"reward": {"gold": 110, "xp": 120, "items": {"wytrych": 2}}},
		],
		"steps": [
			{"pos": Vector2(1700, 350), "kind": "crate", "label": "Zablokuj taśmociąg", "msg": "Taśmociąg stanął. Górnicy kruków nie mają czym wozić rudy."},
			{"pos": Vector2(2000, 800), "kind": "crate", "label": "Otwórz zasuwę zbiornika", "msg": "Zasuwa zbiornika puściła. Za górą coś zaczyna szumieć."},
			{"pos": Vector2(700, 450), "kind": "lever", "label": "Pociągnij dźwignię śluzy", "msg": "Śluza otwarta! Woda z górskiej rzeki zalewa sztolnie Kopalni Żelaza."},
		],
		"objective": "Zatop Kopalnię Żelaza Kruka: wejdź do sztolni i uruchom taśmociąg, zasuwę i dźwignię śluzy (opcjonalnie)",
		"scene": "flood_iron",
		"reward": {"gold": 400, "xp": 400, "items": {"sztabka_zelaza": 6, "wytrych_stalowy": 1}},
	},
	"kopalnia_soli": {
		"zone": "gniazdo_nad_burza", "name": "Kopalnia Soli nad Zatoką", "entrance": Vector2(300, 1350),
		"shafts": [[Vector2(450, 1180), Vector2(1600, 600)]],
		"hint": "W klifie nad zatoką wykuto bramę. Z kopalni wiatr niesie zapach soli i dźwięk pomp.",
		"intro": [["", "Białe sztolnie Kopalni Soli lśnią w świetle latarni. Strażnicy krążą między beczkami, a górnicy w klatkach dłubią solą w kajdankach. Klapa kanału, zawór pompy i wrota przypływu — oto trzy rzeczy, które zalewają kopalnię od środka."]],
		"guards": [
			{"path": [Vector2(400, 1100), Vector2(1000, 1100)], "range": 250.0},
			{"path": [Vector2(1250, 1100), Vector2(1850, 1100)], "range": 250.0},
			{"path": [Vector2(500, 760), Vector2(1700, 760)], "range": 240.0},
			{"path": [Vector2(700, 560), Vector2(1500, 560)], "range": 230.0},
			{"path": [Vector2(900, 440), Vector2(1300, 440)], "range": 210.0},
		],
		"waves": [
			{"enemies": [["kruk", 3, false, "straz"], ["wronszek", 3, false, "wlocznik"]], "name": "Straż soli"},
			{"enemies": [["bocian_gruby", 1, true]], "name": "Dozorca Soli", "elite": true},
		],
		"miners": [
			{"id": "gorn_morski", "pos": Vector2(300, 520), "label": "Uwolnij górnika", "name": "Górnik Morski",
				"thanks": [["Górnik Morski", "Sól mam we krwi, a we krwi niewiele więcej. Dzięki! Wrota przypływu są w głębi — pociągnij je na końcu."]],
				"reward": {"gold": 100, "xp": 110, "items": {"g_eliksir_maly": 2}}},
			{"id": "gorn_kucharz", "pos": Vector2(1800, 1250), "label": "Uwolnij górnika", "name": "Kucharz-Zesłaniec",
				"thanks": [["Kucharz-Zesłaniec", "Przez pół roku solili mi zupę ich własną solą. Gorzką! Weź ode mnie ten rosół i uciekam."]],
				"reward": {"gold": 80, "xp": 100, "items": {"g_rosol_zolnierski": 1}}},
			{"id": "gorn_latarnik", "pos": Vector2(1100, 330), "label": "Uwolnij górnika", "name": "Latarnik Piaskowy",
				"thanks": [["Latarnik Piaskowy", "Latarnia z kopalni świeci w dół, nie w górę. Mówiłem im! Dziękuję za wolność."]],
				"reward": {"gold": 110, "xp": 120, "items": {"wytrych_stalowy": 1}}},
		],
		"steps": [
			{"pos": Vector2(300, 500), "kind": "crate", "label": "Otwórz klapę kanału", "msg": "Klapa kanału otwarta. Słony wiatr wpada do sztolni."},
			{"pos": Vector2(1800, 1150), "kind": "crate", "label": "Odkręć zawór pompy", "msg": "Zawór pompy odkręcony — pompy pracują wstecz."},
			{"pos": Vector2(1100, 300), "kind": "lever", "label": "Pociągnij dźwignię wrót przypływu", "msg": "Wrota przypływu otwarte! Morze wlewa się do Kopalni Soli."},
		],
		"objective": "Zalej Kopalnię Soli nad Zatoką: wejdź do sztolni i uruchom klapę, zawór i wrota przypływu (opcjonalnie)",
		"scene": "flood_salt",
		"reward": {"gold": 450, "xp": 450, "items": {"g_mikstura_duza": 2, "wytrych_mistrzowski": 1}},
	},
}

static func has(id: String) -> bool:
	return LIST.has(id)

static func mines_in(zone_id: String) -> Array:
	var out: Array = []
	for id in LIST:
		if String(LIST[id]["zone"]) == zone_id:
			out.append(String(id))
	return out

## Kopalnia jako jaskinia (format SecretDB.CAVES): wejście w rozdziale, dwie watahy (straż i sztygar).
static func cave(id: String) -> Dictionary:
	var m: Dictionary = LIST.get(id, {})
	if m.is_empty():
		return {}
	return {
		"id": id, "name": String(m["name"]), "hint": String(m["hint"]), "levers": [], "entrance": m["entrance"],
		"repeatable": false, "camp": false, "mine": true, "zone": String(m["zone"]),
		"reward": {}, "waves": (m["waves"] as Array).duplicate(true),
	}

## Dane strefy wnętrza: straż ze stożkami (jak w obozie), górnicy w klatkach, trzy kroki i baner.
static func zone_extra(id: String) -> Dictionary:
	var m: Dictionary = LIST.get(id, {})
	if m.is_empty():
		return {}
	var prisoners: Array = []
	for p in (m["miners"] as Array):
		var pr: Dictionary = (p as Dictionary).duplicate(true)
		pr["mine_miner"] = true
		prisoners.append(pr)
	return {
		"spawn": CAVE_START,
		"prisoners": prisoners, "shafts": (m["shafts"] as Array).duplicate(true),
		"camp": {"id": id, "guards": m["guards"], "start": CAVE_START, "intro": m["intro"]},
		"mine": {"id": id, "zone": String(m["zone"]), "steps": (m["steps"] as Array).duplicate(true), "scene": String(m["scene"]),
			"reward": (m["reward"] as Dictionary).duplicate(true), "text": String(m["objective"])},
		"intro_banner": ["KOPALNIA", String(m["name"])],
		"outro_banner": ["KOPALNIA ZALANA", String(m["name"])],
	}

## Dopisuje cele „mine” do rozdziałów (ChapterExtras.EXTRAS): licznik kroków liczony we flagach.
static func patch_extras(extras: Dictionary) -> Dictionary:
	for id in LIST:
		var m: Dictionary = LIST[id]
		var zone := String(m["zone"])
		if not extras.has(zone):
			continue
		var ex: Dictionary = extras[zone]
		var objs: Array = ex.get("objectives", [])
		objs.append({"id": String(id), "phase": "pre", "type": "mine", "required": false, "count": (m["steps"] as Array).size(),
			"text": String(m["objective"]), "reward": {}})
		ex["objectives"] = objs
	return extras

## Opis kroku i zagadka dla pozycji idx celu (pola per-krok mają pierwszeństwo nad polami ogólnymi).
static func step_value(o: Dictionary, plural: String, single: String, idx: int, fallback: String = "") -> String:
	var arr: Array = o.get(plural, [])
	if idx >= 0 and idx < arr.size():
		return String(arr[idx])
	return String(o.get(single, fallback))
