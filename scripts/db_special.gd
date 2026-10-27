class_name SpecialDB
extends RefCounted
## Duże zadania poboczne („ratunkowe”): w czterech rozdziałach ktoś prosi o odbicie bliskiej osoby z niewoli.
## Każde to łańcuszek istniejących typów celów (rozmowa → ślady → elita/sabotaż → uwolnienie), więc działa
## tak samo w grze jednoosobowej, LAN i na serwerze MMO. Dwa największe dają Zwój Wskrzeszenia.

const NPCS := {
	"mlynarz": {"name": "Młynarz Marian", "title": "Zrozpaczony ojciec", "species": "kurczak", "scale": 1.4, "pos": Vector2(1180, 1090), "accent": Color(0.85, 0.8, 0.6), "role": "lore"},
	"babcia": {"name": "Babcia Kokoszka", "title": "Szukająca wnuczki", "species": "kwoka", "scale": 1.3, "pos": Vector2(1000, 1090), "accent": Color(0.9, 0.75, 0.8), "role": "lore"},
	"karawaniarz": {"name": "Karawaniarz Hasan", "title": "Kupiec bez karawany", "species": "indyk", "scale": 1.5, "pos": Vector2(1100, 1090), "accent": Color(0.95, 0.75, 0.4), "role": "lore"},
	"latarnik": {"name": "Latarnik Burzan", "title": "Ojciec Iskierki", "species": "paw", "scale": 1.45, "pos": Vector2(1100, 1090), "accent": Color(0.6, 0.8, 0.95), "role": "lore"},
}

const QUESTS := {
	"droga_do_stolicy": {
		"npc": "mlynarz",
		"dialog": {
			"pre": [["Młynarz Marian", "Nie wyglądasz na kogoś, kto odwraca wzrok… Błagam, wysłuchaj mnie. Porywacze Kruka zabrali mi córkę, Tosię."], ["Młynarz Marian", "Zostawili ślady na trakcie, ale ja nie umiem walczyć. Znajdź je, pokonaj ich herszta i wyprowadź Tosię z klatki."]],
			"post": [["Młynarz Marian", "Tosia jest w domu. Nigdy ci tego nie zapomnę."]],
			"choice": {"prompt": "Marian wyciąga z kieszeni woreczek. Co robisz?", "options": [
				{"text": "Biorę zaliczkę.", "flag": "mlynarz_zaliczka", "reply": "„Weź, weź. Reszta po powrocie Tosi.”", "final": {"gold": 100}},
				{"text": "Pomogę bez zapłaty.", "flag": "mlynarz_bez", "reply": "„Niech ci pióra błyszczą do końca świata.”"},
			]},
		},
		"objectives": [
			{"id": "tosia_marian", "phase": "pre", "type": "talk", "npcs": ["mlynarz"], "text": "Wysłuchaj młynarza Mariana (zadanie ratunkowe)", "required": false, "reward": {"gold": 40, "xp": 40}},
			{"id": "tosia_slady", "phase": "pre", "type": "collect", "kind": "document", "label": "Zbadaj ślad porywaczy", "count": 3, "positions": [Vector2(700, 350), Vector2(1420, 1400), Vector2(2000, 1380)],
				"clues": ["Ślad kopyt na trakcie — wozu z klatką nikt tu nie ukrył.", "Pióro z czarnym końcem, wplątane w gałąź. Porywacze skręcili na południe.", "Zgnieciona wstążka Tosi. Klatka stoi niedaleko."],
				"text": "Wytropić porywaczy Tosi (opcjonalnie)", "required": false, "reward": {"gold": 90, "xp": 80}},
			{"id": "tosia_herszt", "phase": "pre", "type": "elite", "enemy": "orzel_szarak", "name": "Herszt Porywaczy", "pos": Vector2(1100, 1000), "text": "Pokonaj herszta porywaczy (opcjonalnie)", "required": false,
				"reward": {"gold": 120, "xp": 140}},
			{"id": "tosia_klatka", "phase": "pre", "type": "free", "kind": "cage", "label": "Uwolnij Tosię", "count": 1, "positions": [Vector2(260, 1390)], "text": "Uwolnij córkę młynarza z niewoli (opcjonalnie)", "required": false,
				"reward": {"gold": 350, "xp": 300, "items": {"mikstura_miodu": 2, "zwoj_wskrzeszenia": 1}}},
		],
	},
	"marsz_na_forteca": {
		"npc": "babcia",
		"dialog": {
			"pre": [["Babcia Kokoszka", "Wnuczka, Pisklaczka, poszła z kotłem do wojska i nie wróciła. Mówią, że trzymają ją w obozie jeńców za palisadą."], ["Babcia Kokoszka", "Zamek na klatce pilnują dwie beczki prochu — jak je rozbijesz, strażnicy się rozbiegną. Potem otwórz klatkę."]],
			"post": [["Babcia Kokoszka", "Pisklaczka piecze już placki. Dla ciebie zawsze będzie pierwszy."]],
			"choice": {"prompt": "Babcia podaje ci koszyk z jedzeniem na drogę. Co robisz?", "options": [
				{"text": "Dziękuję, przyda się.", "flag": "babcia_kosz", "reply": "„Jedz, jedz, na pusty brzuch się nie walczy.”", "final": {"items": {"mikstura_miodu": 2}}},
				{"text": "Zostaw dla wnuczki.", "flag": "babcia_dla_wnuczki", "reply": "„Taki z ciebie dobry kogut…”"},
			]},
		},
		"objectives": [
			{"id": "pisk_babcia", "phase": "pre", "type": "talk", "npcs": ["babcia"], "text": "Wysłuchaj Babci Kokoszki (zadanie ratunkowe)", "required": false, "reward": {"gold": 40, "xp": 40}},
			{"id": "pisk_beczki", "phase": "pre", "type": "sabotage", "kind": "crate", "label": "Rozbij beczkę prochu", "count": 2, "positions": [Vector2(1860, 900), Vector2(700, 350)], "text": "Rozbij beczki prochu przy obozie jeńców (opcjonalnie)", "required": false,
				"reward": {"gold": 110, "xp": 100}},
			{"id": "pisk_klatka", "phase": "pre", "type": "free", "kind": "cage", "label": "Uwolnij Pisklaczkę", "count": 1, "positions": [Vector2(260, 1390)], "text": "Uwolnij wnuczkę Babci Kokoszki (opcjonalnie)", "required": false,
				"reward": {"gold": 300, "xp": 260, "items": {"sztabka_kurczalu": 2}}},
		],
	},
	"pustynny_trakt": {
		"npc": "karawaniarz",
		"dialog": {
			"pre": [["Karawaniarz Hasan", "Łowcy z pustyni napadli na karawanę. Wozy mi spalili, a córkę, Leilę, wzięli jako zakładniczkę."], ["Karawaniarz Hasan", "Mają obóz za wydmami, a herszt nosi czerwony turban. Przynieś mi Leilę, a oddam ci wszystko, co zostało z mojego towaru."]],
			"post": [["Karawaniarz Hasan", "Leila śpiewa przy ognisku. Karawana pojedzie znowu."]],
			"choice": {"prompt": "Hasan oferuje ci amulet z pustyni. Co robisz?", "options": [
				{"text": "Przyjmuję amulet.", "flag": "hasan_amulet", "reply": "„Chroni przed piaskiem i złym okiem.”", "final": {"gold": 120}},
				{"text": "Zachowaj go dla Leili.", "flag": "hasan_dla_leili", "reply": "„Szlachetny z ciebie ptak.”"},
			]},
		},
		"objectives": [
			{"id": "leila_hasan", "phase": "pre", "type": "talk", "npcs": ["karawaniarz"], "text": "Wysłuchaj karawaniarza Hasana (zadanie ratunkowe)", "required": false, "reward": {"gold": 40, "xp": 40}},
			{"id": "leila_slady", "phase": "pre", "type": "collect", "kind": "document", "label": "Zbadaj ślad łowców", "count": 3, "positions": [Vector2(1860, 900), Vector2(1650, 400), Vector2(900, 1260)],
				"clues": ["Zgaszone ognisko, a w popiele czerwona nić z turbanu.", "Tropy wielbłąda skręcają za wydmę.", "Szkic obozu łowców na kawałku skóry — klatka stoi na północy."],
				"text": "Wytropić obóz łowców (opcjonalnie)", "required": false, "reward": {"gold": 90, "xp": 90}},
			{"id": "leila_herszt", "phase": "pre", "type": "elite", "enemy": "sep", "name": "Herszt Pustynnych Łowców", "pos": Vector2(1420, 1400), "text": "Pokonaj herszta łowców (opcjonalnie)", "required": false,
				"reward": {"gold": 130, "xp": 150}},
			{"id": "leila_klatka", "phase": "pre", "type": "free", "kind": "cage", "label": "Uwolnij Leilę", "count": 1, "positions": [Vector2(1250, 1130)], "text": "Uwolnij córkę karawaniarza (opcjonalnie)", "required": false,
				"reward": {"gold": 320, "xp": 280, "items": {"sztabka_kurczalu": 2, "krysztal_cienia": 1}}},
		],
	},
	"gniazdo_nad_burza": {
		"npc": "latarnik",
		"dialog": {
			"pre": [["Latarnik Burzan", "Moja Iskierka… Strażnicy burzy zamknęli ją w klatce u stóp latarni, bo wie, jak wyłączyć ich maszyny pogodowe."], ["Latarnik Burzan", "Zniszcz dwa generatory, a strażnik latarni zejdzie ze stanowiska. Wtedy otwórz klatkę."]],
			"post": [["Latarnik Burzan", "Latarnia znów świeci, a Iskierka śpi w domu. Dziękuję."]],
			"choice": {"prompt": "Burzan zdejmuje ze szyi okulary przeciwburzowe. Co robisz?", "options": [
				{"text": "Biorę okulary.", "flag": "burzan_okulary", "reply": "„Widać w nich błyskawice o ułamek sekundy wcześniej.”", "final": {"gold": 150}},
				{"text": "Niech zostaną u ciebie.", "flag": "burzan_zostaw", "reply": "„Ocalisz moją córkę — to więcej niż okulary.”"},
			]},
		},
		"objectives": [
			{"id": "iskra_burzan", "phase": "pre", "type": "talk", "npcs": ["latarnik"], "text": "Wysłuchaj latarnika Burzana (zadanie ratunkowe)", "required": false, "reward": {"gold": 40, "xp": 40}},
			{"id": "iskra_generatory", "phase": "pre", "type": "sabotage", "kind": "crate", "label": "Zniszcz generator burzy", "count": 2, "positions": [Vector2(1000, 440), Vector2(700, 350)], "text": "Zniszcz generatory burzy (opcjonalnie)", "required": false,
				"reward": {"gold": 110, "xp": 110}},
			{"id": "iskra_straznik", "phase": "pre", "type": "elite", "enemy": "bocian_gruby", "name": "Strażnik Latarni", "pos": Vector2(1100, 1000), "text": "Pokonaj strażnika latarni (opcjonalnie)", "required": false,
				"reward": {"gold": 140, "xp": 160}},
			{"id": "iskra_klatka", "phase": "pre", "type": "free", "kind": "cage", "label": "Uwolnij Iskierkę", "count": 1, "positions": [Vector2(1250, 1130)], "text": "Uwolnij córkę latarnika (opcjonalnie)", "required": false,
				"reward": {"gold": 400, "xp": 340, "items": {"mikstura_miodu": 3, "zwoj_wskrzeszenia": 1}}},
		],
	},
}

## Dopisuje zadania ratunkowe do rozdziałów (NPC, dialog z wyborem i cele).
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
		var objs: Array = ex.get("objectives", [])
		for o in q["objectives"]:
			objs.append((o as Dictionary).duplicate(true))
		ex["objectives"] = objs
	return src
