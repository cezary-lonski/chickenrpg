class_name QuestDB
extends RefCounted

const BASE_CHAPTERS := [
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
		"outro": "Kruk pokonany, lecz w popiele fortecy biło jeszcze jedno, czarne serce.",
		"reward": {"gold": 800, "xp": 900, "items": {}},
		"ready": true,
	},
	{
		"id": "cien_w_popiele",
		"label": "Rozdział VIII",
		"title": "Cień w popiele",
		"giver": "Strażnik Michał",
		"intro": "Twierdza Kruka nie chce umrzeć. W jej piwnicach coś wciąż oddycha.",
		"objs": [
			"Przeszukaj zgliszcza fortecy",
			"Zniszcz krypty straży",
			"Pokonaj cień Kruka",
			"Odkryj mapę Gniazda Sępów",
		],
		"outro": "Czarny skarbiec otwarty. Mapa prowadzi na południe — do Gniazda Sępów.",
		"reward": {"gold": 900, "xp": 1000, "items": {"mikstura_miodu": 3}},
		"ready": true,
	},
	{
		"id": "zdrada_w_koronie",
		"label": "Rozdział IX",
		"title": "Zdrada w koronie",
		"giver": "Kupiec Wacław",
		"intro": "Ktoś wykradł czarne jajo z fortecy. Zdrajca nosi koronę i pachnie strachem.",
		"objs": [
			"Przesłuchaj kupców w stolicy",
			"Przejmij skrytki kanclerza",
			"Rozbij straż pałacową",
			"Oczyść salę tronową",
		],
		"outro": "Kanclerz Sępik uciekł na południe, zabierając jajo i połowę skarbca.",
		"reward": {"gold": 1000, "xp": 1150, "items": {"eliksir_mocy": 2}},
		"ready": true,
	},
	{
		"id": "pustynny_trakt",
		"label": "Rozdział X",
		"title": "Pustynny trakt",
		"giver": "Strażnik Michał",
		"intro": "Za przełęczą kończy się zieleń. Piasek pamięta każde pióro, które tu spadło.",
		"objs": [
			"Przekrocz przełęcz",
			"Odbij karawanę z jajem",
			"Pokonaj sępie zwiady",
			"Dotrzyj do Gniazda Sępów",
		],
		"outro": "Karawana rozbita. Nad horyzontem wznosi się cień Gniazda Sępów.",
		"reward": {"gold": 1150, "xp": 1300, "items": {"rosol_z_ptaka": 2}},
		"ready": true,
	},
	{
		"id": "gniazdo_nad_burza",
		"label": "Rozdział XI",
		"title": "Gniazdo nad burzą",
		"giver": "Kowal Grzegorz",
		"intro": "Gniazdo wisi nad chmurami. Żeby wejść, trzeba najpierw złamać trzy straże burzy.",
		"objs": [
			"Zniszcz totemy burzy",
			"Przedrzyj się przez gniazdo",
			"Pokonaj Wieszczkę Sowę",
			"Otwórz drogę do szczytu",
		],
		"outro": "Sowa spadła, a burza ucichła. Na szczycie czeka Cesarz Sępów.",
		"reward": {"gold": 1300, "xp": 1500, "items": {"koktajl_domowy": 2}},
		"ready": true,
	},
	{
		"id": "ostatni_swit",
		"label": "Rozdział XII",
		"title": "Ostatni świt",
		"giver": "Starosta Bartosz",
		"intro": "O świcie wszystkie ptaki milkną. Cesarz Sępów czeka na ostatnie pióro.",
		"objs": [
			"Wejdź do Sali Świtu",
			"Zniszcz gwardię cesarską",
			"Pokonaj Cesarza Sępów",
			"Wróć do wioski ze świtem",
		],
		"outro": "Cesarz upadł. Po raz pierwszy od wielu nocy słońce wzeszło nad wioską.",
		"reward": {"gold": 1800, "xp": 2000, "items": {"jaja_feniks": 1}},
		"ready": true,
	},
]

## Akt I po rozbudowie: pałac (6 pięter) → narada → król w lochu → twierdza → Miasto i Zamek Kruka → sala tronowa.
static func _act1() -> Array:
	var out: Array = []
	for c in BASE_CHAPTERS:
		var d: Dictionary = (c as Dictionary).duplicate(true)
		match String(d["id"]):
			"uwolnij_krolowa":
				for f in PalaceDB.CHAPTERS_FLOORS:
					out.append((f as Dictionary).duplicate(true))
				d["title"] = "Wieża królowej — 6. piętro"
				d["intro"] = "Szóste piętro: najwyższa wieża pałacu. Królowa Aurelia jest uwięziona na szczycie. Przedrzyj się przez straż i uwolnij ją."
				out.append(d)
				out.append((PalaceDB.CHAPTER_COUNCIL as Dictionary).duplicate(true))
				out.append((PalaceDB.CHAPTER_KING as Dictionary).duplicate(true))
				continue
			"marsz_na_forteca":
				out.append(d)
				for f2 in FortressDB.CHAPTERS_FORT:
					out.append((f2 as Dictionary).duplicate(true))
				continue
			"krol_i_kruk":
				out.append((PalaceDB.CHAPTER_CITY as Dictionary).duplicate(true))
				for f3 in FortressDB.CHAPTERS_CASTLE:
					out.append((f3 as Dictionary).duplicate(true))
				out.append((PalaceDB.CHAPTER_CASTLE as Dictionary).duplicate(true))
				d["title"] = "Sala tronowa Kruka"
		out.append(d)
	return out

static func _roman(n: int) -> String:
	var vals := [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1]
	var syms := ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"]
	var out := ""
	for i in vals.size():
		while n >= int(vals[i]):
			out += String(syms[i])
			n -= int(vals[i])
	return out

static func _assemble() -> Array:
	var base := _act1()
	var split := 0
	for i in base.size():
		if String(base[i]["id"]) == "krol_i_kruk":
			split = i + 1
	var all: Array = base.slice(0, split) + Act2DB.QUESTS + base.slice(split)
	var n := 0
	for c in all:
		if int(c.get("act", 1)) == 2 and c in Act2DB.QUESTS:
			continue
		n += 1
		c["label"] = "Rozdział %s" % _roman(n)
		c["ready"] = true
	return all

## Kolejność: Akt I (rozdziały I–XVI), Akt II (misje wiosek), dalsze rozdziały.
static var CHAPTERS: Array = _assemble()

static func index_of(id: String) -> int:
	for i in CHAPTERS.size():
		if String(CHAPTERS[i].get("id", "")) == id:
			return i
	return -1

static func act_of(index: int) -> int:
	return int(chapter(index).get("act", 1))

## Pierwszy indeks rozdziału danego aktu (lub -1).
static func act_start(act: int) -> int:
	for i in CHAPTERS.size():
		if int(CHAPTERS[i].get("act", 1)) == act:
			return i
	return -1

static func act_count(act: int) -> int:
	var n := 0
	for c in CHAPTERS:
		if int(c.get("act", 1)) == act:
			n += 1
	return n

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
	var wn: int = ZoneDB.normal_waves(id) if ZoneDB.has(id) else 0
	var boss_id := BossDB.for_zone(id)
	if boss_id != "" and wn > 0:
		if step == wn + 1:
			return "Pokonaj bossa: %s" % String(BossDB.get_data(boss_id).get("name", "Boss"))
		if step > wn + 1:
			return "Porozmawiaj z: %s" % String(d.get("giver", "zleceniodawca"))
	if wn > 0 and objs.size() < wn + 2:
		# jeden cel na falę; po ostatniej fali — rozmowa ze zleceniodawcą
		if step > wn:
			return "Porozmawiaj z: %s" % String(d.get("giver", "zleceniodawca"))
		return String(objs[clampi(step - 1, 0, objs.size() - 1)])
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
