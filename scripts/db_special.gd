class_name SpecialDB
extends RefCounted
## Zadania ratunkowe. Trzy krótkie: ktoś prosi o odbicie bliskiej osoby z obozu — idziesz do obozu, wykradasz jeńca
## spod stożków wzroku strażników (albo wcześniej pokonujesz naczelnika obozu, a strażnicy odchodzą) i wracasz
## po nagrodę. Czwarte jest długie: młynarz Marian prosi o Tosię na początku, a ona siedzi w lochach zamku Kruka
## (zob. SecretDB, jaskinia „Lochy Zamku Kruka”). Dwa największe zadania dają Zwój Wskrzeszenia.

const NPCS := {
	"mlynarz": {"name": "Młynarz Marian", "title": "Zrozpaczony ojciec", "species": "kurczak", "scale": 1.4, "pos": Vector2(1180, 1090), "accent": Color(0.85, 0.8, 0.6), "role": "lore"},
	"babcia": {"name": "Babcia Kokoszka", "title": "Szukająca wnuczki", "species": "kwoka", "scale": 1.3, "pos": Vector2(1000, 1090), "accent": Color(0.9, 0.75, 0.8), "role": "lore"},
	"karawaniarz": {"name": "Karawaniarz Hasan", "title": "Kupiec bez karawany", "species": "indyk", "scale": 1.5, "pos": Vector2(1100, 1090), "accent": Color(0.95, 0.75, 0.4), "role": "lore"},
	"latarnik": {"name": "Latarnik Burzan", "title": "Ojciec Iskierki", "species": "paw", "scale": 1.45, "pos": Vector2(1100, 1090), "accent": Color(0.6, 0.8, 0.95), "role": "lore"},
}

## Flaga rozmowy z Marianem — odblokowuje Tosię w lochach zamku Kruka.
const TOSIA_FLAG := "o:droga_do_stolicy:tosia_marian:0"

const QUESTS := {
	"droga_do_stolicy": {
		"npc": "mlynarz",
		"dialog": {
			"pre": [["Młynarz Marian", "Nie wyglądasz na kogoś, kto odwraca wzrok… Błagam, wysłuchaj mnie. Porywacze Kruka zabrali mi córkę, Tosię."], ["Młynarz Marian", "Podsłuchałem, że wywieźli ją do lochów zamku Kruka. To daleko stąd, ale kiedyś tam dotrzesz. Szukaj jej wśród więźniów — pamiętasz? Tosia, córka młynarza."]],
			"post": [["Młynarz Marian", "Jeśli kiedyś staniesz pod zamkiem Kruka, zajrzyj do lochów. Błagam."]],
			"choice": {"prompt": "Marian wyciąga z kieszeni woreczek. Co robisz?", "options": [
				{"text": "Biorę zaliczkę.", "flag": "mlynarz_zaliczka", "reply": "„Weź, weź. Reszta po powrocie Tosi.”", "final": {"gold": 100}},
				{"text": "Pomogę bez zapłaty.", "flag": "mlynarz_bez", "reply": "„Niech ci pióra błyszczą do końca świata.”"},
			]},
		},
		"objectives": [
			{"id": "tosia_marian", "phase": "pre", "type": "talk", "npcs": ["mlynarz"], "text": "Wysłuchaj młynarza Mariana: jego córka Tosia siedzi w lochach zamku Kruka", "required": false, "reward": {"gold": 40, "xp": 40}},
		],
	},
	"marsz_na_forteca": {
		"npc": "babcia",
		"dialog": {
			"pre": [["Babcia Kokoszka", "Wnuczka, Pisklaczka, poszła z kotłem do wojska i nie wróciła. Trzymają ją w obozie jeńców za palisadą."], ["Babcia Kokoszka", "Wykradnij ją, kiedy strażnicy patrzą w drugą stronę — albo zbij naczelnika obozu, a reszta się rozbiegnie. Potem przyprowadź ją do mnie."]],
			"post": [["Babcia Kokoszka", "Pisklaczka piecze już placki. Dla ciebie zawsze będzie pierwszy."]],
			"choice": {"prompt": "Babcia podaje ci koszyk z jedzeniem na drogę. Co robisz?", "options": [
				{"text": "Dziękuję, przyda się.", "flag": "babcia_kosz", "reply": "„Jedz, jedz, na pusty brzuch się nie walczy.”", "final": {"items": {"mikstura_miodu": 2}}},
				{"text": "Zostaw dla wnuczki.", "flag": "babcia_dla_wnuczki", "reply": "„Taki z ciebie dobry kogut…”"},
			]},
		},
		"objectives": [
			{"id": "pisk_babcia", "phase": "pre", "type": "talk", "npcs": ["babcia"], "text": "Wysłuchaj Babci Kokoszki (zadanie ratunkowe)", "required": false, "reward": {"gold": 40, "xp": 40}},
			{"id": "pisk_naczelnik", "phase": "pre", "type": "elite", "enemy": "bocian_gruby", "name": "Naczelnik Obozu Jeńców", "pos": Vector2(1100, 1000), "text": "Pokonaj naczelnika obozu jeńców — jego straż odejdzie (opcjonalnie)", "required": false,
				"reward": {"gold": 120, "xp": 130}},
			{"id": "pisk_obozu", "phase": "pre", "type": "heist", "required": false, "disarm": "pisk_naczelnik", "item": "jeniec_pisklaczka", "npc": "babcia",
				"text": "Wykradnij Pisklaczkę z obozu jeńców i zaprowadź do babci (opcjonalnie)", "label": "Uwolnij Pisklaczkę",
				"start": Vector2(300, 1300), "pos": Vector2(1850, 420),
				"guards": [
					{"path": [Vector2(500, 1150), Vector2(1200, 1150)], "range": 260.0},
					{"path": [Vector2(1600, 1300), Vector2(1600, 800)], "range": 250.0},
					{"path": [Vector2(900, 650), Vector2(1500, 650), Vector2(1500, 520), Vector2(900, 520)], "range": 230.0},
					{"path": [Vector2(1650, 450), Vector2(2050, 450)], "range": 220.0},
				],
				"intro": [["", "Za palisadą widać klatkę Pisklaczki. Strażnicy obozu patrolują między namiotami — kryj się za ich plecami albo najpierw zbij naczelnika."]],
				"take_msg": "Pisklaczka jest wolna i idzie za tobą! Wymknij się z obozu i zaprowadź ją do babci.",
				"thanks": [["Babcia Kokoszka", "Pisklaczko! Moje ty kurczątko! Cała i zdrowa!"], ["Pisklaczka", "Ten kogut przeszedł tuż obok strażników, babciu. Nawet się nie spocił."], ["Babcia Kokoszka", "Weź to, dziecko. I nie zapomnij, że w tym obozie zostali jeszcze inni."]],
				"reward": {"gold": 300, "xp": 260, "items": {"sztabka_kurczalu": 2}}},
		],
	},
	"pustynny_trakt": {
		"npc": "karawaniarz",
		"dialog": {
			"pre": [["Karawaniarz Hasan", "Łowcy z pustyni napadli na karawanę. Wozy mi spalili, a córkę, Leilę, wzięli do obozu niewolników za wydmami."], ["Karawaniarz Hasan", "Strażników jest wielu, ale patrzą tylko przed siebie. Wykradnij Leilę albo zbij herszta — wtedy sami uciekną. Czekam tutaj."]],
			"post": [["Karawaniarz Hasan", "Leila śpiewa przy ognisku. Karawana pojedzie znowu."]],
			"choice": {"prompt": "Hasan oferuje ci amulet z pustyni. Co robisz?", "options": [
				{"text": "Przyjmuję amulet.", "flag": "hasan_amulet", "reply": "„Chroni przed piaskiem i złym okiem.”", "final": {"gold": 120}},
				{"text": "Zachowaj go dla Leili.", "flag": "hasan_dla_leili", "reply": "„Szlachetny z ciebie ptak.”"},
			]},
		},
		"objectives": [
			{"id": "leila_hasan", "phase": "pre", "type": "talk", "npcs": ["karawaniarz"], "text": "Wysłuchaj karawaniarza Hasana (zadanie ratunkowe)", "required": false, "reward": {"gold": 40, "xp": 40}},
			{"id": "leila_herszt", "phase": "pre", "type": "elite", "enemy": "sep", "name": "Herszt Handlarzy Niewolników", "pos": Vector2(1420, 1400), "text": "Pokonaj herszta handlarzy niewolników — jego straż odejdzie (opcjonalnie)", "required": false,
				"reward": {"gold": 130, "xp": 150}},
			{"id": "leila_obozu", "phase": "pre", "type": "heist", "required": false, "disarm": "leila_herszt", "item": "jeniec_leila", "npc": "karawaniarz",
				"text": "Wykradnij Leilę z obozu niewolników i zaprowadź do ojca (opcjonalnie)", "label": "Uwolnij Leilę",
				"start": Vector2(300, 1300), "pos": Vector2(1900, 360),
				"guards": [
					{"path": [Vector2(450, 1250), Vector2(1000, 1250)], "range": 250.0},
					{"path": [Vector2(1300, 1300), Vector2(1300, 900)], "range": 250.0},
					{"path": [Vector2(800, 800), Vector2(1400, 800)], "range": 240.0},
					{"path": [Vector2(1750, 1100), Vector2(1750, 600)], "range": 230.0},
					{"path": [Vector2(1500, 430), Vector2(2050, 430)], "range": 220.0},
				],
				"intro": [["", "Obóz niewolników rozbito w kotlinie między wydmami. Klatka Leili stoi w głębi, a strażnicy krążą między namiotami. Przemknij za ich plecami albo zbij herszta."]],
				"take_msg": "Leila wymyka się z klatki i idzie za tobą! Zaprowadź ją do ojca.",
				"thanks": [["Karawaniarz Hasan", "Leila! Alhamdulillah… Jesteś cała!"], ["Leila", "Ten bohater przeszedł przez obóz jak cień, tato. Nikt go nie zauważył."], ["Karawaniarz Hasan", "Weź to, co ocalało z mojego towaru. Droga jest teraz bezpieczniejsza."]],
				"reward": {"gold": 320, "xp": 280, "items": {"sztabka_kurczalu": 2, "krysztal_cienia": 1}}},
		],
	},
	"gniazdo_nad_burza": {
		"npc": "latarnik",
		"dialog": {
			"pre": [["Latarnik Burzan", "Moja Iskierka… Strażnicy burzy zamknęli ją w klatce u stóp latarni, bo wie, jak wyłączyć ich maszyny pogodowe."], ["Latarnik Burzan", "Strażnicy mają stożki wzroku jak reflektory. Wykradnij ją, kiedy się odwrócą, albo zbij ich dowódcę. Potem przyprowadź ją tutaj."]],
			"post": [["Latarnik Burzan", "Latarnia znów świeci, a Iskierka śpi w domu. Dziękuję."]],
			"choice": {"prompt": "Burzan zdejmuje z szyi okulary przeciwburzowe. Co robisz?", "options": [
				{"text": "Biorę okulary.", "flag": "burzan_okulary", "reply": "„Widać w nich błyskawice o ułamek sekundy wcześniej.”", "final": {"gold": 150}},
				{"text": "Niech zostaną u ciebie.", "flag": "burzan_zostaw", "reply": "„Ocalisz moją córkę — to więcej niż okulary.”"},
			]},
		},
		"objectives": [
			{"id": "iskra_burzan", "phase": "pre", "type": "talk", "npcs": ["latarnik"], "text": "Wysłuchaj latarnika Burzana (zadanie ratunkowe)", "required": false, "reward": {"gold": 40, "xp": 40}},
			{"id": "iskra_dowodca", "phase": "pre", "type": "elite", "enemy": "bocian_gruby", "name": "Dowódca Straży Latarni", "pos": Vector2(1100, 1000), "text": "Pokonaj dowódcę straży latarni — jego ludzie odejdą (opcjonalnie)", "required": false,
				"reward": {"gold": 140, "xp": 160}},
			{"id": "iskra_latarni", "phase": "pre", "type": "heist", "required": false, "disarm": "iskra_dowodca", "item": "jeniec_iskierka", "npc": "latarnik",
				"text": "Wykradnij Iskierkę spod latarni i zaprowadź do ojca (opcjonalnie)", "label": "Uwolnij Iskierkę",
				"start": Vector2(300, 1300), "pos": Vector2(1100, 330),
				"guards": [
					{"path": [Vector2(400, 1100), Vector2(1000, 1100)], "range": 250.0},
					{"path": [Vector2(1250, 1100), Vector2(1850, 1100)], "range": 250.0},
					{"path": [Vector2(500, 760), Vector2(1700, 760)], "range": 240.0},
					{"path": [Vector2(700, 560), Vector2(1500, 560)], "range": 230.0},
					{"path": [Vector2(900, 440), Vector2(1300, 440)], "range": 210.0},
				],
				"intro": [["", "U stóp latarni stoi klatka z Iskierką. Strażnicy burzy patrolują w kilku rzędach — przekradaj się rzędami, kiedy się odwracają."]],
				"take_msg": "Iskierka jest wolna i idzie za tobą! Wymknij się spod latarni i zaprowadź ją do ojca.",
				"thanks": [["Latarnik Burzan", "Iskierko! Moje światełko!"], ["Iskierka", "Tato, ten bohater wyprowadził mnie spod nosa strażnikom!"], ["Latarnik Burzan", "Latarnia znów będzie świecić. Weź to, to dar od całej wyspy."]],
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

## Więźniowie lochów zamku Kruka: Tosia (z zadania Mariana) i kilku innych. Lista trafia do jaskini
## „lochy_kruka” (SecretDB), a jeśli gracz znał prośbę Mariana, Tosia jest nagrodzona hojniej i dziękuje po imieniu.
static func prisoners() -> Array:
	return [
		{"id": "tosia", "pos": Vector2(1900, 430), "tosia": true,
			"label": "Uwolnij więźniarkę", "name": "Tosia",
			"thanks": [["Tosia", "Tata mówił, że ktoś przyjdzie! Jestem Tosia, córka młynarza z Drogi do Stolicy."], ["Tosia", "Biegnę do domu. Powiedz tacie, że się nie poddałam!"]],
			"thanks_plain": [["Więźniarka", "Dziękuję… Mam na imię Tosia. Porwali mnie z młyna przy trakcie. Ojciec pewnie mnie szuka."]],
			"reward": {"gold": 350, "xp": 300, "items": {"mikstura_miodu": 2, "zwoj_wskrzeszenia": 1}},
			"reward_plain": {"gold": 120, "xp": 100, "items": {"mikstura_miodu": 1}}},
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
