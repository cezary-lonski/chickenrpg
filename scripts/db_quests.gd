class_name QuestDB
extends RefCounted

const CHAPTERS := [
	{
		"id": "obrona_wioski",
		"label": "Rozdział I",
		"title": "Nocny najazd",
		"giver": "Starosta Bartosz",
		"intro": "Czarne skrzydła nad wioską. Chwyć broń i obroń swoich.",
		"objs": [
			"Porozmawiaj ze starostą Bartoszem",
			"Obroń wioskę — fala 1 / 3",
			"Obroń wioskę — fala 2 / 3",
			"Obroń wioskę — fala 3 / 3",
			"Porozmawiaj ze starostą po bitwie",
		],
		"outro": "Wioska ocalała. Kruk cofnął się... na razie.",
		"reward": {"gold": 150, "xp": 120, "items": {"mikstura_miodu": 2}},
		"ready": true,
	},
	{
		"id": "droga_do_stolicy",
		"label": "Rozdział II",
		"title": "Trakt do stolicy",
		"giver": "Strażnik Michał",
		"intro": "Trakt prowadzi przez posterunki straży. Nie wszystkie są wierne koronie.",
		"objs": [
			"Wyrusz z wioski o świcie",
			"Przejdź przez posterunek straży",
			"Dotrzyj do bram stolicy",
		],
		"outro": "Stolica płonie. Królowa wzywa.",
		"reward": {"gold": 220, "xp": 200, "items": {}},
		"ready": true,
	},
	{
		"id": "atak_na_stolice",
		"label": "Rozdział III",
		"title": "Płonąca stolica",
		"giver": "Kapitan straży",
		"intro": "Wróg uderzył równolegle. Miasto tonie w ogniu i panice.",
		"objs": [
			"Przedrzyj się przez płonące ulice",
			"Znajdź kapitan straży",
			"Odbij główny plac",
		],
		"outro": "Plac odzyskany, ale królowa wciąż w rękach wroga.",
		"reward": {"gold": 300, "xp": 260, "items": {}},
		"ready": true,
	},
	{
		"id": "uwolnij_krolowa",
		"label": "Rozdział IV",
		"title": "Królowa w kajdanach",
		"giver": "Królowa Aurelia",
		"intro": "Królowa jest uwięziona w wieży. Czas na misję ratunkową.",
		"objs": [
			"Odnajdź wejście do wieży",
			"Pokonaj straż przednią",
			"Uwolnij królową Aurelię",
		],
		"outro": "Królowa wolna. Kruk stracił swoją najcenniejszą kartę.",
		"reward": {"gold": 380, "xp": 340, "items": {}},
		"ready": true,
	},
	{
		"id": "trojka_prob",
		"label": "Rozdział V",
		"title": "Trzy próby",
		"giver": "Królowa Aurelia",
		"intro": "Bez odpowiedniego sprzętu forteca pozostanie niezdobyta.",
		"objs": [
			"Zdobądź ostrze z Kryształowej Groty",
			"Zdobądź pancerz z Popielnej Kuźni",
			"Zdobądź talizman z Mrocznego Gaju",
		],
		"outro": "Trzy relikty zebrane. Czas ruszać na fortecę.",
		"reward": {"gold": 450, "xp": 420, "items": {}},
		"ready": true,
	},
	{
		"id": "marsz_na_forteca",
		"label": "Rozdział VI",
		"title": "Czarny marsz",
		"giver": "Królowa Aurelia",
		"intro": "Armia korony maszeruje pod twierdzę Kruka.",
		"objs": [
			"Poprowadź wojska traktem",
			"Rozbij obóz wroga",
			"Stań pod bramą fortecy",
		],
		"outro": "Brama runęła. W środku czeka sam Kruk.",
		"reward": {"gold": 520, "xp": 500, "items": {}},
		"ready": true,
	},
	{
		"id": "krol_i_kruk",
		"label": "Rozdział VII",
		"title": "Serce kruka",
		"giver": "Królowa Aurelia",
		"intro": "W fortecy odnajdziesz zaginionego króla — albo jego cień.",
		"objs": [
			"Wejdź do sali tronowej",
			"Odnajdź króla",
			"Pokonaj Kruka",
		],
		"outro": "Kruk pokonany. Królestwo kur odzyskało świt.",
		"reward": {"gold": 800, "xp": 900, "items": {}},
		"ready": true,
	},
]

static func count() -> int:
	return CHAPTERS.size()

static func chapter(index: int) -> Dictionary:
	if CHAPTERS.is_empty():
		return {}
	return CHAPTERS[clampi(index, 0, CHAPTERS.size() - 1)]

static func get_data(id: String) -> Dictionary:
	for c in CHAPTERS:
		if String(c.get("id", "")) == id:
			return c
	return {}

static func objective(id: String, step: int) -> String:
	var d := get_data(id)
	if d.is_empty():
		return ""
	var objs: Array = d.get("objs", [])
	if objs.is_empty():
		return ""
	if step < 0:
		step = 0
	if step >= objs.size():
		return String(objs[objs.size() - 1])
	return String(objs[step])

static func ready(id: String) -> bool:
	return bool(get_data(id).get("ready", false))

static func reward_text(id: String) -> String:
	var r: Dictionary = get_data(id).get("reward", {})
	var parts: Array = []
	if int(r.get("gold", 0)) > 0:
		parts.append("%d złota" % int(r.get("gold", 0)))
	if int(r.get("xp", 0)) > 0:
		parts.append("%d XP" % int(r.get("xp", 0)))
	var items: Dictionary = r.get("items", {})
	for it in items:
		parts.append("%s x%d" % [String(ItemDB.get_data(String(it)).get("name", it)), int(items[it])])
	return ", ".join(parts)
