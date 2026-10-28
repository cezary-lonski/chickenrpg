class_name SpecialDB
extends RefCounted
## Zadania ratunkowe (poboczne). Zleceniodawca w wiosce prosi o odbicie bliskiej osoby z obozu niewolników na pustkowiu.
## Przyjęcie zadania (rozmowa z NPC) odblokowuje wejście do obozu — osobnej strefy w stylu sekretnej jaskini (zob. camp_cave).
## W obozie uwolnisz jeńca na dwa sposoby: szybko i po cichu (przemykasz za plecami strażników ze stożkami wzroku;
## zauważenie cofa cię na start) albo gwałtownie i hałaśliwie (bijesz straż, a po pokonaniu naczelnika reszta strażników
## odchodzi). Uwolniony jeniec sam dziękuje i daje nagrodę. Dwa największe zadania dają Zwój Wskrzeszenia.

const NPCS := {
	"mlynarz": {"name": "Młynarz Marian", "title": "Zrozpaczony ojciec", "species": "kurczak", "scale": 1.4, "pos": Vector2(1180, 1090), "accent": Color(0.85, 0.8, 0.6), "role": "lore"},
	"babcia": {"name": "Babcia Kokoszka", "title": "Szukająca wnuczki", "species": "kwoka", "scale": 1.3, "pos": Vector2(1000, 1090), "accent": Color(0.9, 0.75, 0.8), "role": "lore"},
	"karawaniarz": {"name": "Karawaniarz Hasan", "title": "Kupiec bez karawany", "species": "indyk", "scale": 1.5, "pos": Vector2(1100, 1090), "accent": Color(0.95, 0.75, 0.4), "role": "lore"},
	"latarnik": {"name": "Latarnik Burzan", "title": "Ojciec Iskierki", "species": "paw", "scale": 1.45, "pos": Vector2(1100, 1090), "accent": Color(0.6, 0.8, 0.95), "role": "lore"},
}

## Flaga starej rozmowy z Marianem (zostaje dla zgodności ze starymi zapisami).
const TOSIA_FLAG := "o:droga_do_stolicy:tosia_marian:0"

## Gdzie w strefie zleceniodawcy stoi ścieżka do obozu (jednakowo we wszystkich).
const CAMP_ENTRANCE := Vector2(2000, 1340)

const QUESTS := {
	"droga_do_stolicy": {
		"npc": "mlynarz",
		"dialog": {
			"pre": [["Młynarz Marian", "Nie wyglądasz na kogoś, kto odwraca wzrok… Błagam, wysłuchaj mnie. Porywacze Kruka zabrali mi córkę, Tosię."], ["Młynarz Marian", "Handlarze niewolników trzymają ją w obozie na pustkowiu. Ścieżka zaczyna się na skraju wsi. Wykradnij ją po cichu albo wyrżnij straż — byle wróciła cała."]],
			"post": [["Młynarz Marian", "Jeśli kiedyś znajdziesz ścieżkę do obozu niewolników, pamiętaj: Tosia ma warkocz i nie lubi ciemności."]],
			"choice": {"prompt": "Marian wyciąga z kieszeni woreczek. Co robisz?", "options": [
				{"text": "Biorę zaliczkę.", "flag": "mlynarz_zaliczka", "reply": "„Weź, weź. Reszta po powrocie Tosi.”", "final": {"gold": 100}},
				{"text": "Pomogę bez zapłaty.", "flag": "mlynarz_bez", "reply": "„Niech ci pióra błyszczą do końca świata.”"},
			]},
		},
		"objective": {"id": "tosia_marian", "text": "Wysłuchaj młynarza Mariana: jego córkę Tosię porwano do obozu niewolników (poboczne)"},
	},
	"marsz_na_forteca": {
		"npc": "babcia",
		"dialog": {
			"pre": [["Babcia Kokoszka", "Wnuczka, Pisklaczka, poszła z kotłem do wojska i nie wróciła. Trzymają ją w obozie niewolników na pustkowiu."], ["Babcia Kokoszka", "Ścieżka zaczyna się na skraju wsi. Wykradnij ją, kiedy strażnicy patrzą w drugą stronę — albo zbij naczelnika obozu, a reszta się rozbiegnie."]],
			"post": [["Babcia Kokoszka", "Pisklaczka piecze już placki. Dla ciebie zawsze będzie pierwszy."]],
			"choice": {"prompt": "Babcia podaje ci koszyk z jedzeniem na drogę. Co robisz?", "options": [
				{"text": "Dziękuję, przyda się.", "flag": "babcia_kosz", "reply": "„Jedz, jedz, na pusty brzuch się nie walczy.”", "final": {"items": {"mikstura_miodu": 2}}},
				{"text": "Zostaw dla wnuczki.", "flag": "babcia_dla_wnuczki", "reply": "„Taki z ciebie dobry kogut…”"},
			]},
		},
		"objective": {"id": "pisk_babcia", "text": "Wysłuchaj Babci Kokoszki: Pisklaczka siedzi w obozie niewolników (poboczne)"},
	},
	"pustynny_trakt": {
		"npc": "karawaniarz",
		"dialog": {
			"pre": [["Karawaniarz Hasan", "Łowcy z pustyni napadli na karawanę. Wozy mi spalili, a córkę, Leilę, wzięli do obozu niewolników za wydmami."], ["Karawaniarz Hasan", "Ścieżka do obozu zaczyna się na skraju wsi. Strażników jest wielu, ale patrzą tylko przed siebie. Wykradnij Leilę albo zbij herszta — wtedy sami uciekną."]],
			"post": [["Karawaniarz Hasan", "Leila śpiewa przy ognisku. Karawana pojedzie znowu."]],
			"choice": {"prompt": "Hasan oferuje ci amulet z pustyni. Co robisz?", "options": [
				{"text": "Przyjmuję amulet.", "flag": "hasan_amulet", "reply": "„Chroni przed piaskiem i złym okiem.”", "final": {"gold": 120}},
				{"text": "Zachowaj go dla Leili.", "flag": "hasan_dla_leili", "reply": "„Szlachetny z ciebie ptak.”"},
			]},
		},
		"objective": {"id": "leila_hasan", "text": "Wysłuchaj karawaniarza Hasana: Leila siedzi w obozie niewolników (poboczne)"},
	},
	"gniazdo_nad_burza": {
		"npc": "latarnik",
		"dialog": {
			"pre": [["Latarnik Burzan", "Moja Iskierka… Strażnicy burzy zamknęli ją w klatce w obozie niewolników, bo wie, jak wyłączyć ich maszyny pogodowe."], ["Latarnik Burzan", "Ścieżka zaczyna się na skraju wsi. Strażnicy mają stożki wzroku jak reflektory. Wykradnij ją, kiedy się odwrócą, albo zbij ich dowódcę."]],
			"post": [["Latarnik Burzan", "Latarnia znów świeci, a Iskierka śpi w domu. Dziękuję."]],
			"choice": {"prompt": "Burzan zdejmuje z szyi okulary przeciwburzowe. Co robisz?", "options": [
				{"text": "Biorę okulary.", "flag": "burzan_okulary", "reply": "„Widać w nich błyskawice o ułamek sekundy wcześniej.”", "final": {"gold": 150}},
				{"text": "Niech zostaną u ciebie.", "flag": "burzan_zostaw", "reply": "„Ocalisz moją córkę — to więcej niż okulary.”"},
			]},
		},
		"objective": {"id": "iskra_burzan", "text": "Wysłuchaj latarnika Burzana: Iskierka siedzi w obozie niewolników (poboczne)"},
	},
}

## Obozy niewolników: po jednym na zadanie. `zone` = strefa zleceniodawcy (tam jest ścieżka), `guards` = patrole ze stożkami
## wzroku (skradanka), `waves` = straż i naczelnik (siłowe rozwiązanie), `captive` = jeniec z podziękowaniem i nagrodą.
const CAMPS := {
	"oboz_tosia": {
		"shafts": [[Vector2(450, 1200), Vector2(1700, 720)], [Vector2(1050, 1000), Vector2(1700, 330)]],
		"zone": "droga_do_stolicy", "name": "Obóz niewolników — Tosia",
		"hint": "Wydeptana ścieżka znika w wydmach. Ktoś wbił w ziemię tabliczkę: „Opuszczona kopalnia. Obóz Handlarzy. Wstęp tylko z kajdankami.”",
		"start": Vector2(300, 1300), "reward": {"gold": 60, "xp": 80},
		"chief": ["sep", "Naczelnik Handlarzy"],
		"guards": [
			{"path": [Vector2(500, 1150), Vector2(1200, 1150)], "range": 250.0},
			{"path": [Vector2(1500, 1250), Vector2(1500, 800)], "range": 250.0},
			{"path": [Vector2(900, 650), Vector2(1500, 650)], "range": 240.0},
			{"path": [Vector2(1650, 450), Vector2(2050, 450)], "range": 220.0},
		],
		"intro": [["", "Obóz handlarzy rozbito w opuszczonej kopalni na pustyni — wokół hałdy, szyby i wózki z rudą. W głębi stoi klatka z warkoczastą dziewczynką — to Tosia. Strażnicy patrolują między namiotami: przemknij za ich plecami albo zbij naczelnika."]],
		"captive": {"id": "tosia", "name": "Tosia", "pos": Vector2(1900, 430), "label": "Uwolnij Tosię",
			"thanks": [["Tosia", "Tata mówił, że ktoś po mnie przyjdzie! Jestem Tosia, córka młynarza."], ["Tosia", "Weź to, ukradłam strażnikom, kiedy spali. Biegnę do domu — powiedz tacie, że się nie poddałam!"]],
			"reward": {"gold": 350, "xp": 300, "items": {"mikstura_miodu": 2, "zwoj_wskrzeszenia": 1}}},
	},
	"oboz_pisklaczka": {
		"shafts": [[Vector2(450, 1200), Vector2(1650, 780)], [Vector2(1000, 950), Vector2(1700, 330)]],
		"zone": "marsz_na_forteca", "name": "Obóz niewolników — Pisklaczka",
		"hint": "Za palisadą widać dym ognisk. Na słupie wisi kolczatka: „Obóz jeńców. Własność wojska.”",
		"start": Vector2(300, 1300), "reward": {"gold": 60, "xp": 80},
		"chief": ["bocian_gruby", "Naczelnik Obozu Jeńców"],
		"guards": [
			{"path": [Vector2(500, 1150), Vector2(1200, 1150)], "range": 260.0},
			{"path": [Vector2(1600, 1300), Vector2(1600, 800)], "range": 250.0},
			{"path": [Vector2(900, 650), Vector2(1500, 650), Vector2(1500, 520), Vector2(900, 520)], "range": 230.0},
			{"path": [Vector2(1650, 450), Vector2(2050, 450)], "range": 220.0},
		],
		"intro": [["", "Za palisadą opuszczonej kopalni na pustyni widać klatkę Pisklaczki, a między hałdami ziejące szyby. Strażnicy obozu patrolują między namiotami — kryj się za ich plecami albo najpierw zbij naczelnika."]],
		"captive": {"id": "pisklaczka", "name": "Pisklaczka", "pos": Vector2(1850, 420), "label": "Uwolnij Pisklaczkę",
			"thanks": [["Pisklaczka", "Babcia mówiła, że ktoś się zjawi! Ten kogut przeszedł tuż obok strażników. Nawet się nie spocił."], ["Pisklaczka", "Weź to, dziecko… to znaczy, kogucie. Powiedz babci, że placki będą na ciebie czekać."]],
			"reward": {"gold": 300, "xp": 260, "items": {"sztabka_kurczalu": 2}}},
	},
	"oboz_leila": {
		"shafts": [[Vector2(450, 1150), Vector2(1700, 1000)], [Vector2(900, 900), Vector2(1750, 300)]],
		"zone": "pustynny_trakt", "name": "Obóz niewolników — Leila",
		"hint": "Wydmy rozstępują się nad kotliną pełną namiotów. Wiatr niesie zapach dymu i brzęk łańcuchów.",
		"start": Vector2(300, 1300), "reward": {"gold": 60, "xp": 80},
		"chief": ["sep", "Herszt Handlarzy Niewolników"],
		"guards": [
			{"path": [Vector2(450, 1250), Vector2(1000, 1250)], "range": 250.0},
			{"path": [Vector2(1300, 1300), Vector2(1300, 900)], "range": 250.0},
			{"path": [Vector2(800, 800), Vector2(1400, 800)], "range": 240.0},
			{"path": [Vector2(1750, 1100), Vector2(1750, 600)], "range": 230.0},
			{"path": [Vector2(1500, 430), Vector2(2050, 430)], "range": 220.0},
		],
		"intro": [["", "Obóz niewolników rozbito w opuszczonej kopalni na pustyni, wśród hałd i szybów. Klatka Leili stoi w głębi, a strażnicy krążą między namiotami. Przemknij za ich plecami albo zbij herszta."]],
		"captive": {"id": "leila", "name": "Leila", "pos": Vector2(1900, 360), "label": "Uwolnij Leilę",
			"thanks": [["Leila", "Tata nie przestawał we mnie wierzyć! Ten bohater przeszedł przez obóz jak cień — nikt go nie zauważył."], ["Leila", "Weź to, co ocalało z naszego towaru. Droga jest teraz bezpieczniejsza."]],
			"reward": {"gold": 320, "xp": 280, "items": {"sztabka_kurczalu": 2, "krysztal_cienia": 1}}},
	},
	"oboz_iskierka": {
		"shafts": [[Vector2(450, 1200), Vector2(1500, 900)], [Vector2(700, 980), Vector2(1300, 300)]],
		"zone": "gniazdo_nad_burza", "name": "Obóz niewolników — Iskierka",
		"hint": "Na burzowym pustkowiu błyska bez przerwy. Między głazami świeci strażnicza latarnia.",
		"start": Vector2(300, 1300), "reward": {"gold": 60, "xp": 80},
		"chief": ["bocian_gruby", "Dowódca Straży Burzy"],
		"guards": [
			{"path": [Vector2(400, 1100), Vector2(1000, 1100)], "range": 250.0},
			{"path": [Vector2(1250, 1100), Vector2(1850, 1100)], "range": 250.0},
			{"path": [Vector2(500, 760), Vector2(1700, 760)], "range": 240.0},
			{"path": [Vector2(700, 560), Vector2(1500, 560)], "range": 230.0},
			{"path": [Vector2(900, 440), Vector2(1300, 440)], "range": 210.0},
		],
		"intro": [["", "W opuszczonej kopalni u stóp strażniczej latarni stoi klatka z Iskierką, a wokół ziejące szyby. Strażnicy burzy patrolują w kilku rzędach — przekradaj się rzędami, kiedy się odwracają."]],
		"captive": {"id": "iskierka", "name": "Iskierka", "pos": Vector2(1100, 330), "label": "Uwolnij Iskierkę",
			"thanks": [["Iskierka", "Wiedziałam, że tata kogoś przyśle! Ten bohater wyprowadził mnie spod nosa strażnikom!"], ["Iskierka", "Weź to, to dar od całej wyspy. A maszyny pogodowe… już ich nie włączą."]],
			"reward": {"gold": 400, "xp": 340, "items": {"mikstura_miodu": 3, "zwoj_wskrzeszenia": 1}}},
	},
}

## Flaga rozmowy ze zleceniodawcą (przyjęcie zadania): odblokowuje wejście do obozu.
static func accept_flag(camp_id: String) -> String:
	var c: Dictionary = CAMPS.get(camp_id, {})
	if c.is_empty():
		return ""
	var q: Dictionary = QUESTS[String(c["zone"])]
	return ChapterExtras.flag(String(c["zone"]), String(q["objective"]["id"]), 0)

static func giver_name(camp_id: String) -> String:
	var c: Dictionary = CAMPS.get(camp_id, {})
	if c.is_empty():
		return ""
	return String(NPCS[String(QUESTS[String(c["zone"])]["npc"])]["name"])

static func camps_in(zone_id: String) -> Array:
	var out: Array = []
	for id in CAMPS:
		if String(CAMPS[id]["zone"]) == zone_id:
			out.append(String(id))
	return out

static func is_camp(cave_id: String) -> bool:
	return CAMPS.has(cave_id)

## Obóz jako jaskinia (format SecretDB.CAVES): wejście w strefie zleceniodawcy, dwie watahy zasadzek (straż i naczelnik).
static func camp_cave(camp_id: String) -> Dictionary:
	var c: Dictionary = CAMPS.get(camp_id, {})
	if c.is_empty():
		return {}
	var chief: Array = c["chief"]
	return {
		"id": camp_id, "name": String(c["name"]), "hint": String(c["hint"]), "levers": [], "entrance": CAMP_ENTRANCE,
		"repeatable": false, "camp": true, "zone": String(c["zone"]),
		"reward": (c["reward"] as Dictionary).duplicate(true),
		"waves": [
			{"enemies": [["kruk", 3, false, "straz"], ["wronszek", 2, false, "wlocznik"]], "name": "Straż obozu"},
			{"enemies": [[String(chief[0]), 1, true]], "name": String(chief[1]), "elite": true},
		],
	}

## Dopisuje do rozdziałów NPC-zleceniodawcę, jego dialog z wyborem i cel „wysłuchaj” (przyjęcie zadania pobocznego).
static func patch(base: Dictionary) -> Dictionary:
	var src: Dictionary = base.duplicate(true)
	for zid in QUESTS:
		if not src.has(zid):
			continue
		var q: Dictionary = QUESTS[zid]
		var ex: Dictionary = src[zid]
		var npcs: Array = ex.get("npcs", [])
		npcs.append(q["npc"])
		ex["npcs"] = npcs
		var dialogs: Dictionary = ex.get("dialogs", {})
		dialogs[q["npc"]] = (q["dialog"] as Dictionary).duplicate(true)
		ex["dialogs"] = dialogs
		var o: Dictionary = q["objective"]
		var objs: Array = ex.get("objectives", [])
		objs.append({"id": String(o["id"]), "phase": "pre", "type": "talk", "npcs": [q["npc"]], "text": String(o["text"]), "required": false, "reward": {"gold": 40, "xp": 40}})
		ex["objectives"] = objs
	return src

## Dane strefy obozu dla SecretDB.cave_zone: jeniec (klatka), patrole, punkt startu.
static func camp_zone_extra(camp_id: String) -> Dictionary:
	var c: Dictionary = CAMPS.get(camp_id, {})
	if c.is_empty():
		return {}
	return {
		"spawn": c["start"],
		"prisoners": [(c["captive"] as Dictionary).duplicate(true)],
		"camp": {"id": camp_id, "guards": c["guards"], "start": c["start"],
			"intro": (c["intro"] as Array) + [["", "Szyby (E) łączą odległe części kopalni: zejdź jednym, wyjdź drugim — a ominiesz strażników."]]},
		"terrain": "desert", "shafts": (c["shafts"] as Array).duplicate(true),
		"intro_banner": ["OBÓZ NIEWOLNIKÓW", String(c["name"]).split(" — ")[1]],
		"outro_banner": ["OBÓZ ROZBITY", ""],
	}

## Więźniowie lochów zamku Kruka (bez Tosi — ta czeka w obozie niewolników). Lista trafia do jaskini „lochy_kruka” (SecretDB).
static func prisoners() -> Array:
	return [
		{"id": "kowal", "pos": Vector2(300, 430), "label": "Uwolnij więźnia", "name": "Kowal Gerwazy",
			"thanks": [["Kowal Gerwazy", "Trzy tygodnie bez młota! Dzięki, bohaterze — weź, co mam."]],
			"reward": {"gold": 130, "xp": 110, "items": {"sztabka_zelaza": 2}}},
		{"id": "zolnierz", "pos": Vector2(300, 950), "label": "Uwolnij więźnia", "name": "Żołnierz Bartek",
			"thanks": [["Żołnierz Bartek", "Wzięli mnie do niewoli pod Twierdzą. Biegnę do swoich — zamelduję, że lochy są otwarte."]],
			"reward": {"gold": 110, "xp": 120, "items": {"mikstura_miodu": 1}}},
		{"id": "skryba", "pos": Vector2(1900, 950), "label": "Uwolnij więźnia", "name": "Skryba Fiołek",
			"thanks": [["Skryba Fiołek", "Zapiszę to w kronice: kogut z lochów! Weź ten zwój — tyle dla ciebie zrobię."]],
			"reward": {"gold": 140, "xp": 130, "items": {"eliksir_mocy": 1}}},
	]
