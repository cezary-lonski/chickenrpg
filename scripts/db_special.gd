class_name SpecialDB
extends RefCounted
## Zadania ratunkowe (poboczne). Zleceniodawca w wiosce prosi o odbicie bliskiej osoby z obozu niewolników na pustkowiu.
## Przyjęcie zadania (rozmowa z NPC) odblokowuje wejście do obozu — osobnej strefy w stylu sekretnej jaskini (zob. camp_cave).
## W obozie stoją zwykłe potwory (straż i naczelnik), które budzą się z dymkiem „!”, gdy cię zauważą. Klatka jest zamknięta
## do pokonania naczelnika (ma klucz). Uwolniony jeniec sam dziękuje i daje nagrodę. Dwa największe zadania dają Zwój Wskrzeszenia.

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
			"pre": [["Młynarz Marian", "Nie wyglądasz na kogoś, kto odwraca wzrok… Błagam, wysłuchaj mnie. Porywacze Kruka zabrali mi córkę, Tosię."], ["Młynarz Marian", "Handlarze niewolników trzymają ją w obozie na pustkowiu. Ścieżka zaczyna się na skraju wsi. Przebij się przez straż i pokonaj naczelnika — klucz do jej klatki ma on. Byle wróciła cała."]],
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
			"pre": [["Babcia Kokoszka", "Wnuczka, Pisklaczka, poszła z kotłem do wojska i nie wróciła. Trzymają ją w obozie niewolników na pustkowiu."], ["Babcia Kokoszka", "Ścieżka zaczyna się na skraju wsi. Straż cię zauważy, kiedy podejdziesz za blisko — a klucz do klatki ma naczelnik obozu. Pokonaj go."]],
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
			"pre": [["Karawaniarz Hasan", "Łowcy z pustyni napadli na karawanę. Wozy mi spalili, a córkę, Leilę, wzięli do obozu niewolników za wydmami."], ["Karawaniarz Hasan", "Ścieżka do obozu zaczyna się na skraju wsi. Strażników jest wielu, a klucz do klatki ma herszt. Pokonaj go i wyprowadź Leilę."]],
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
			"pre": [["Latarnik Burzan", "Moja Iskierka… Strażnicy burzy zamknęli ją w klatce w obozie niewolników, bo wie, jak wyłączyć ich maszyny pogodowe."], ["Latarnik Burzan", "Ścieżka zaczyna się na skraju wsi. Strażnicy mają bystry wzrok, a klucz do klatki nosi ich dowódca. Pokonaj go."]],
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
		"intro": [["", "Obóz handlarzy rozbito w opuszczonej kopalni na pustyni — wokół hałdy, szyby i wózki z rudą. W głębi stoi klatka z warkoczastą dziewczynką — to Tosia. Strażnicy stoją między namiotami i ruszą na ciebie, gdy cię zobaczą. Klucz do klatki ma naczelnik."]],
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
		"intro": [["", "Za palisadą opuszczonej kopalni na pustyni widać klatkę Pisklaczki, a między hałdami ziejące szyby. Strażnicy obozu stoją między namiotami i ruszą na ciebie, gdy cię zobaczą. Klucz do klatki ma naczelnik."]],
		"captive": {"id": "pisklaczka", "name": "Pisklaczka", "pos": Vector2(1850, 420), "label": "Uwolnij Pisklaczkę",
			"thanks": [["Pisklaczka", "Babcia mówiła, że ktoś się zjawi! Ten kogut rozprawił się z całą strażą!"], ["Pisklaczka", "Weź to, dziecko… to znaczy, kogucie. Powiedz babci, że placki będą na ciebie czekać."]],
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
		"intro": [["", "Obóz niewolników rozbito w opuszczonej kopalni na pustyni, wśród hałd i szybów. Klatka Leili stoi w głębi, a strażnicy stoją między namiotami. Klucz do klatki ma herszt — pokonaj go."]],
		"captive": {"id": "leila", "name": "Leila", "pos": Vector2(1900, 360), "label": "Uwolnij Leilę",
			"thanks": [["Leila", "Tata nie przestawał we mnie wierzyć! Ten bohater przebił się przez cały obóz!"], ["Leila", "Weź to, co ocalało z naszego towaru. Droga jest teraz bezpieczniejsza."]],
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
		"intro": [["", "W opuszczonej kopalni u stóp strażniczej latarni stoi klatka z Iskierką, a wokół ziejące szyby. Strażnicy burzy stoją w kilku rzędach i ruszą na ciebie, gdy cię zobaczą. Klucz do klatki ma dowódca."]],
		"captive": {"id": "iskierka", "name": "Iskierka", "pos": Vector2(1100, 330), "label": "Uwolnij Iskierkę",
			"thanks": [["Iskierka", "Wiedziałam, że tata kogoś przyśle! Ten bohater wyprowadził mnie spod nosa strażnikom!"], ["Iskierka", "Weź to, to dar od całej wyspy. A maszyny pogodowe… już ich nie włączą."]],
			"reward": {"gold": 400, "xp": 340, "items": {"mikstura_miodu": 3, "zwoj_wskrzeszenia": 1}}},
	},
}

## Etap 1 (strefa zleceniodawcy): ślady porywaczy. Dwa miejsca do zbadania, zanim ścieżka do obozu stanie się czytelna.
const TRACKS := {
	"oboz_tosia": [Vector2(1500, 1000), Vector2(520, 620)],
	"oboz_pisklaczka": [Vector2(1700, 880), Vector2(600, 520)],
	"oboz_leila": [Vector2(1600, 1180), Vector2(520, 820)],
	"oboz_iskierka": [Vector2(1700, 700), Vector2(520, 900)],
}

## Etap 2 (w obozie): dwoje innych niewolników w klatkach. Jeniec z zadania ma dwa zamki — klucz naczelnika i zasuwę,
## którą zdejmą dopiero uwolnieni niewolnicy.
const EXTRA_POS := [Vector2(780, 930), Vector2(1350, 620)]

static func tracks_objective(camp_id: String) -> Dictionary:
	var c: Dictionary = CAMPS.get(camp_id, {})
	if c.is_empty():
		return {}
	return {"id": "slady_" + camp_id, "phase": "pre", "type": "collect", "kind": "tracks", "label": "Zbadaj ślady", "count": 2,
		"positions": (TRACKS[camp_id] as Array).duplicate(), "required": false,
		"text": "Zbadaj ślady porywaczy na pustkowiu, by znaleźć drogę do obozu (poboczne)", "reward": {"gold": 40, "xp": 40}}

## Czy ślady zbadane (fl: słownik flag serwera albo null dla gry jednoosobowej).
static func tracks_done(camp_id: String, fl = null) -> bool:
	var c: Dictionary = CAMPS.get(camp_id, {})
	if c.is_empty():
		return true
	return ChapterExtras.is_done(String(c["zone"]), tracks_objective(camp_id), fl)

static func tracks_left(camp_id: String, fl = null) -> int:
	var c: Dictionary = CAMPS.get(camp_id, {})
	if c.is_empty():
		return 0
	var o := tracks_objective(camp_id)
	return int(o["count"]) - ChapterExtras.count_done(String(c["zone"]), o, fl)

static func extra_prisoners(camp_id: String) -> Array:
	var out: Array = []
	var names := ["Niewolnik Burek", "Niewolnica Rudka"]
	for i in 2:
		out.append({"id": "%s_n%d" % [camp_id, i + 1], "pos": EXTRA_POS[i], "label": "Uwolnij niewolnika", "name": names[i], "extra": true,
			"thanks": [[names[i], "Dziękuję! Zasuwa przy klatce, w której siedzi ten, po kogo przyszedłeś, zejdzie tylko z naszą pomocą — już biegniemy ją zdjąć."]],
			"reward": {"gold": 40 + 15 * i, "xp": 40}})
	return out

## Ostatni etap zadania: po uwolnieniu jeńca wracasz do zleceniodawcy po podziękowanie i nagrodę (raz).
const REPORTS := {
	"oboz_tosia": {
		"lines": [["Młynarz Marian", "Tosia stoi w drzwiach! Cała, zdrowa, z warkoczem! Opowiedziała, jak pokonałeś naczelnika i wyprowadziłeś ją z obozu."], ["Młynarz Marian", "Nie mam jak ci podziękować, więc weź choć to. Przy młynie zawsze będzie dla ciebie mąka i ciepły kąt."]],
		"reward": {"gold": 150, "xp": 150, "items": {"mikstura_miodu": 2}}},
	"oboz_pisklaczka": {
		"lines": [["Babcia Kokoszka", "Pisklaczka już piecze placki i opowiada całej wsi, jak pokonałeś naczelnika obozu jeńców!"], ["Babcia Kokoszka", "Weź ten koszyk, kogucie. Placki jeszcze ciepłe, a w środku coś na czarną godzinę."]],
		"reward": {"gold": 130, "xp": 140, "items": {"mikstura_miodu": 3}}},
	"oboz_leila": {
		"lines": [["Karawaniarz Hasan", "Leila śpiewa przy ognisku, jakby nigdy nic! Powiedziała, że herszt padł, a ty wyprowadziłeś ją przez cały obóz."], ["Karawaniarz Hasan", "Karawana jedzie dalej dzięki tobie. Część zysku z pierwszego kursu należy się tobie — przyjmij ją."]],
		"reward": {"gold": 170, "xp": 150, "items": {"g_mikstura_mala": 2}}},
	"oboz_iskierka": {
		"lines": [["Latarnik Burzan", "Iskierka śpi w domu, a latarnia znów świeci. Powiedziała, że dowódca straży burzy padł od twojej ręki."], ["Latarnik Burzan", "Weź to w podzięce. Burza wie, kto jej pomógł — ominie twoje drogi."]],
		"reward": {"gold": 200, "xp": 170, "items": {"g_eliksir_maly": 2}}},
}

## Obóz, z którego `npc` czeka na wieści (gdy zleceniodawcą w tej strefie jest ten NPC), albo "".
static func report_camp(zone_id: String, npc: String) -> String:
	if not QUESTS.has(zone_id) or String(QUESTS[zone_id]["npc"]) != npc:
		return ""
	var list := camps_in(zone_id)
	return String(list[0]) if not list.is_empty() else ""

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
		for camp_id in camps_in(String(zid)):
			objs.append(tracks_objective(String(camp_id)))
		ex["objectives"] = objs
	return src

## Dane strefy obozu dla SecretDB.cave_zone: jeniec (klatka), patrole, punkt startu.
static func camp_zone_extra(camp_id: String) -> Dictionary:
	var c: Dictionary = CAMPS.get(camp_id, {})
	if c.is_empty():
		return {}
	return {
		"spawn": c["start"],
		"prisoners": [(c["captive"] as Dictionary).duplicate(true)] + extra_prisoners(camp_id),
		"camp": {"id": camp_id, "guards": c["guards"], "start": c["start"],
			"intro": (c["intro"] as Array) + [["", "Szyby (E) łączą odległe części kopalni: zejdź jednym, wyjdź drugim — skrócisz sobie drogę."]]},
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
