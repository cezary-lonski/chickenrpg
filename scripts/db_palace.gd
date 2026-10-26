class_name PalaceDB
extends RefCounted
## Główna fabuła — rozbudowa środka Aktu I:
##  • Pałac w stolicy (6 pięter: strażnicy, schody, komnaty kruczych arystokratów ze śmiesznymi historyjkami),
##    na 6. piętrze wieża królowej, potem narada wojenna w sali narad,
##  • uwolnienie Króla z lochu (podchodzisz do klatki i go uwalniasz),
##  • twierdza Kruka (generałowie), Miasto Kruka i Zamek Kruka, a na końcu walka w sali tronowej.
## Dane są scalane z QuestDB / ZoneDB / ChapterExtras / NpcDB.

const A := Vector2(330, 930)
const B := Vector2(1860, 900)
const C := Vector2(1000, 440)
const D := Vector2(1420, 1400)
const E := Vector2(700, 350)
const F := Vector2(1650, 400)
const G := Vector2(260, 1390)
const H := Vector2(1250, 1130)
const I := Vector2(900, 1260)
const J := Vector2(2000, 1380)

const ITEMS := {
	"zwoj_teleportacji": {
		"name": "Zwój teleportacji", "slot": "material", "tier": 6, "price": 0, "icon": "list", "stack": 20, "rarity": "epicki",
		"desc": "Na mapie świata (M) przenosi cię natychmiast do dowolnego zbadanego miejsca, bez marszu przez kolejne etapy. Zużywa się przy użyciu.",
		"stats": {}, "tint": Color(0.6, 0.8, 1.0),
	},
}

# ---------------------------------------------------------------- NPC ---

static func _npc(name: String, title: String, species: String, pos: Vector2, accent: Color, scale: float = 1.45) -> Dictionary:
	return {"name": name, "title": title, "species": species, "scale": scale, "pos": pos, "accent": accent, "role": "lore"}

const NPCS := {
	# piętro 1
	"szambelan_1": {"name": "Szambelan Pióropusz", "title": "Pilnuje schodów", "species": "kogut", "scale": 1.5, "pos": Vector2(1560, 1000), "accent": Color(0.9, 0.7, 0.4), "role": "lore"},
	"baron_gawron": {"name": "Baron Gawron", "title": "Kruczy arystokrata", "species": "kogut", "scale": 1.5, "pos": Vector2(520, 780), "accent": Color(0.55, 0.5, 0.75), "role": "lore"},
	"hrabina_wrona": {"name": "Hrabina Wrona", "title": "Kruczy arystokrata", "species": "kwoka", "scale": 1.4, "pos": Vector2(1700, 700), "accent": Color(0.75, 0.5, 0.7), "role": "lore"},
	# piętro 2
	"szambelan_2": {"name": "Szambelan Tomik", "title": "Pilnuje schodów", "species": "gasior", "scale": 1.5, "pos": Vector2(1560, 1000), "accent": Color(0.9, 0.7, 0.4), "role": "lore"},
	"ksiaze_kruczek": {"name": "Książę Kruczek", "title": "Kruczy arystokrata", "species": "kogut", "scale": 1.45, "pos": Vector2(480, 820), "accent": Color(0.5, 0.55, 0.8), "role": "lore"},
	"diuk_kawka": {"name": "Diuk Kawka", "title": "Kruczy arystokrata", "species": "gasior", "scale": 1.5, "pos": Vector2(1720, 760), "accent": Color(0.6, 0.6, 0.7), "role": "lore"},
	# piętro 3
	"szambelan_3": {"name": "Szambelan Kielich", "title": "Pilnuje schodów", "species": "indyk", "scale": 1.55, "pos": Vector2(1560, 1000), "accent": Color(0.9, 0.7, 0.4), "role": "lore"},
	"margrabia_kos": {"name": "Margrabia Kos", "title": "Kruczy arystokrata", "species": "indyk", "scale": 1.5, "pos": Vector2(500, 800), "accent": Color(0.7, 0.45, 0.35), "role": "lore"},
	"dama_sroczka": {"name": "Dama Sroczka", "title": "Kruczy arystokrata", "species": "kwoka", "scale": 1.4, "pos": Vector2(1700, 720), "accent": Color(0.9, 0.85, 0.5), "role": "lore"},
	# piętro 4
	"szambelan_4": {"name": "Szambelan Rama", "title": "Pilnuje schodów", "species": "kogut", "scale": 1.5, "pos": Vector2(1560, 1000), "accent": Color(0.9, 0.7, 0.4), "role": "lore"},
	"lady_szpaczek": {"name": "Lady Szpaczek", "title": "Kruczy arystokrata", "species": "kwoka", "scale": 1.45, "pos": Vector2(520, 820), "accent": Color(0.8, 0.55, 0.85), "role": "lore"},
	"wicehrabia_czarnuszek": {"name": "Wicehrabia Czarnuszek", "title": "Kruczy arystokrata", "species": "gasior", "scale": 1.5, "pos": Vector2(1700, 780), "accent": Color(0.45, 0.45, 0.6), "role": "lore"},
	# piętro 5
	"szambelan_5": {"name": "Szambelan Dzwon", "title": "Pilnuje schodów", "species": "indyk", "scale": 1.55, "pos": Vector2(1560, 1000), "accent": Color(0.9, 0.7, 0.4), "role": "lore"},
	"kanonik_gawrosz": {"name": "Kanonik Gawrosz", "title": "Kruczy arystokrata", "species": "kogut", "scale": 1.5, "pos": Vector2(500, 800), "accent": Color(0.6, 0.6, 0.85), "role": "lore"},
	"hrabia_puchacz": {"name": "Hrabia Puchacz", "title": "Kruczy arystokrata", "species": "indyk", "scale": 1.6, "pos": Vector2(1720, 740), "accent": Color(0.5, 0.45, 0.4), "role": "lore"},
	# narada wojenna
	"krolowa": {"name": "Królowa Aurelia", "title": "Władczyni", "species": "kwoka", "scale": 1.6, "pos": Vector2(1100, 760), "accent": Color(1.0, 0.85, 0.5), "role": "lore"},
	"marszalek": {"name": "Marszałek Dziobacz", "title": "Doradca wojenny", "species": "kogut", "scale": 1.55, "pos": Vector2(640, 880), "accent": Color(0.9, 0.5, 0.4), "role": "lore"},
	"kanclerz_korony": {"name": "Kanclerz Piórko", "title": "Doradca dworu", "species": "gasior", "scale": 1.5, "pos": Vector2(1560, 880), "accent": Color(0.7, 0.8, 0.95), "role": "lore"},
	"mistrz_szpiegow": {"name": "Mistrz Szpiegów Cichopiór", "title": "Doradca wywiadu", "species": "kogut", "scale": 1.45, "pos": Vector2(1100, 1010), "accent": Color(0.55, 0.55, 0.7), "role": "lore"},
	# loch
	"klawisz": {"name": "Klawisz Zbigniew", "title": "Strażnik lochu", "species": "gasior", "scale": 1.5, "pos": Vector2(1500, 1040), "accent": Color(0.6, 0.6, 0.65), "role": "lore"},
	"wiezien_bajarz": {"name": "Więzień Bajarz", "title": "Więzień", "species": "kurczak", "scale": 1.4, "pos": Vector2(560, 1020), "accent": Color(0.8, 0.75, 0.55), "role": "lore"},
	# miasto kruka
	"szpieg_piorko": {"name": "Szpieg Podróbka", "title": "Przewodnik po mieście", "species": "kogut", "scale": 1.45, "pos": Vector2(560, 1000), "accent": Color(0.7, 0.55, 0.9), "role": "lore"},
	"straganiarz_kruczy": {"name": "Kruczy Straganiarz", "title": "Mieszkaniec", "species": "indyk", "scale": 1.5, "pos": Vector2(1580, 940), "accent": Color(0.55, 0.5, 0.65), "role": "lore"},
	"babcia_wrona": {"name": "Babcia Wrona", "title": "Mieszkanka", "species": "kwoka", "scale": 1.35, "pos": Vector2(840, 1100), "accent": Color(0.7, 0.6, 0.8), "role": "lore"},
	# zamek kruka
	"buntownik_zamku": {"name": "Buntownik Kruk Młodszy", "title": "Wróg Czarnego Kruka", "species": "kogut", "scale": 1.5, "pos": Vector2(560, 980), "accent": Color(0.85, 0.5, 0.45), "role": "lore"},
}

# ------------------------------------------------------------ rozdziały ---

const CHAPTERS_FLOORS := [
	{
		"id": "palac_1", "title": "Pałac — hol główny", "giver": "Szambelan Pióropusz",
		"intro": "Wielkie wrota pałacu stoją otworem, a w holu roi się od straży Kruka. Królowa jest na samej górze — sześć pięter stąd.",
		"objs": ["Wejdź do pałacu", "Wysłuchaj arystokratów w komnatach", "Pokonaj straż holu", "Wejdź schodami na 2. piętro"],
		"outro": "Straż holu pokonana. Schody na drugie piętro są wolne.",
		"reward": {"gold": 260, "xp": 240, "items": {"mikstura_miodu": 2}},
	},
	{
		"id": "palac_2", "title": "Pałac — biblioteka", "giver": "Szambelan Tomik",
		"intro": "Drugie piętro to biblioteka. Cisza, kurz i uzbrojeni lokaje, którzy bardzo nie lubią, gdy się im przeszkadza w czytaniu.",
		"objs": ["Przejdź przez bibliotekę", "Wysłuchaj arystokratów w komnatach", "Pokonaj straż biblioteczną", "Wejdź schodami na 3. piętro"],
		"outro": "Straż biblioteczna pokonana. Przed tobą sala bankietowa.",
		"reward": {"gold": 290, "xp": 270, "items": {"eliksir_mocy": 1}},
	},
	{
		"id": "palac_3", "title": "Pałac — sala bankietowa", "giver": "Szambelan Kielich",
		"intro": "Trzecie piętro pachnie pieczenią i zdradą. Na stołach leży uczta, której nikt nie dokończył, a pod stołami czają się gwardziści.",
		"objs": ["Przejdź przez salę bankietową", "Wysłuchaj arystokratów w komnatach", "Pokonaj straż bankietową", "Wejdź schodami na 4. piętro"],
		"outro": "Uczta przerwana, straż rozbita. Schody w górę stoją otworem.",
		"reward": {"gold": 320, "xp": 300, "items": {"zwoj_teleportacji": 1}},
	},
	{
		"id": "palac_4", "title": "Pałac — galeria portretów", "giver": "Szambelan Rama",
		"intro": "Czwarte piętro to galeria portretów dawnych władców. Oczy na obrazach śledzą cię uważnie, ale prawdziwe niebezpieczeństwo kryje się za nimi.",
		"objs": ["Przejdź przez galerię", "Wysłuchaj arystokratów w komnatach", "Pokonaj straż galerii", "Wejdź schodami na 5. piętro"],
		"outro": "Galeria oczyszczona. Zostały jeszcze dwa piętra.",
		"reward": {"gold": 350, "xp": 330, "items": {"krysztal_cienia": 1}},
	},
	{
		"id": "palac_5", "title": "Pałac — kaplica i zbrojownia", "giver": "Szambelan Dzwon",
		"intro": "Piąte piętro: kaplica i pałacowa zbrojownia. Dzwony biją na alarm — Kruk wie, że ktoś wspina się po schodach.",
		"objs": ["Przejdź przez kaplicę", "Wysłuchaj arystokratów w komnatach", "Pokonaj straż zbrojowni", "Wejdź schodami na szczyt wieży"],
		"outro": "Zbrojownia zdobyta. Ostatnie schody wiodą do wieży królowej.",
		"reward": {"gold": 380, "xp": 360, "items": {"eliksir_mocy": 2}},
	},
]

const CHAPTER_COUNCIL := {
	"id": "narada_wojenna", "title": "Narada w sali narad", "giver": "Królowa Aurelia",
	"intro": "Królowa wolna! Zbiera doradców w sali narad, by ustalić, jak zatrzymać Kruka. Twój głos liczy się tak samo jak ich.",
	"objs": ["Wejdź do sali narad", "Naradź się z królową i doradcami", "Odeprzyj zamachowców", "Wysłuchaj decyzji królowej"],
	"outro": "Plan ustalony. Zanim wyruszycie na Kruka, trzeba uwolnić Króla z lochu.",
	"reward": {"gold": 420, "xp": 400, "items": {"zwoj_teleportacji": 1}},
}

const CHAPTER_KING := {
	"id": "uwolnij_krola", "title": "Król w lochu", "giver": "Klawisz Zbigniew",
	"intro": "Król od miesięcy gnije w lochu pod twierdzą. Przejdź przez straż, podejdź do jego celi i uwolnij go.",
	"objs": ["Zejdź do lochu", "Pokonaj strażników więziennych", "Podejdź do celi i uwolnij Króla"],
	"outro": "Król wolny! Królestwo odzyskało prawowitego władcę.",
	"reward": {"gold": 480, "xp": 450, "items": {"eliksir_mocy": 2}},
}

const CHAPTER_CITY := {
	"id": "miasto_kruka", "title": "Miasto Kruka", "giver": "Szpieg Podróbka",
	"intro": "Za twierdzą rozciąga się Miasto Kruka — czarne dachy, ciasne uliczki i bramy, których pilnują generałowie. Zamek Kruka widać z każdej ulicy.",
	"objs": ["Wejdź do Miasta Kruka", "Znajdź drogę do zamku", "Pokonaj straż miejską", "Stań pod bramą zamku"],
	"outro": "Brama zamku Kruka stoi przed tobą. Wewnątrz czekają generałowie.",
	"reward": {"gold": 540, "xp": 520, "items": {"krysztal_cienia": 2}},
}

const CHAPTER_CASTLE := {
	"id": "zamek_kruka", "title": "Zamek Kruka", "giver": "Królowa Aurelia",
	"intro": "Mury zamku strzegą generałowie Czarnego Kruka — nie udają dworzan ani nie opowiadają dowcipów. Zaatakują cię bez ostrzeżenia.",
	"objs": ["Wejdź do zamku", "Pokonaj generałów Kruka", "Odeprzyj straż zamkową", "Otwórz drzwi sali tronowej"],
	"outro": "Drzwi sali tronowej pękły. Czarny Kruk czeka na tronie.",
	"reward": {"gold": 600, "xp": 580, "items": {"zwoj_teleportacji": 1, "eliksir_mocy": 2}},
}

# ------------------------------------------------------------------ strefy ---

static func _floor_zone(_giver: String, _a: String, _b: String, waves: Array, banner: String, intro: Array, villain: Dictionary) -> Dictionary:
	# Piętro zaczyna się samo, a kończy schodami — bez rozmowy ze szambelanem.
	return {
		"terrain": "palace", "spawn": Vector2(1100, 1300), "npcs": ["kowal"], "giver": "", "waves": waves, "stairs": true,
		"villain": villain, "intro_banner": ["PAŁAC", banner], "intro": intro, "outro_banner": ["SCHODY WOLNE", banner],
	}

static var ZONES: Dictionary = _zones()

static func _zones() -> Dictionary:
	return {
		"palac_1": _floor_zone("szambelan_1", "baron_gawron", "hrabina_wrona", [
			{"enemies": [["kruk", 3, false, "straz"], ["szpak", 3, false, "straz"]], "name": "Straż holu"},
			{"enemies": [["kawka", 4, false, "lokaj"], ["golab", 3, false, "lokaj"]], "name": "Lokaje w zbrojach"},
			{"enemies": [["orzel_szarak", 1, true, "rycerz"], ["kruk", 3, false, "straz"]], "name": "Kapitan holu"},
		], "Hol główny", [
			["", "Marmurowy hol lśni jak lustro, a pod każdą kolumną stoi strażnik z kruczym piórem na hełmie."],
			["", "Na schodach nikt nie pilnuje porządku, bo wszyscy są zajęci wytykaniem sobie błędów. Doskonały moment, by się wśliznąć."],
		], {"who": "Kapitan holu", "after_wave": 2, "lines": ["Kto wpuścił tu tego kurczaka?!", "Straż! Zatrzymać go, zanim zbrudzi dywany!"]}),
		"palac_2": _floor_zone("szambelan_2", "ksiaze_kruczek", "diuk_kawka", [
			{"enemies": [["kawka", 4, false, "czytelnik"], ["jastrzab", 2, false, "czytelnik"]], "name": "Czytelnicy z mieczami"},
			{"enemies": [["sroka", 4, false, "bibliotekarz"], ["kruk", 3, false, "bibliotekarz"]], "name": "Bibliotekarze"},
			{"enemies": [["puchacz", 2, false, "straznik_ksiag"], ["kruk", 3, false, "straznik_ksiag"]], "name": "Strażnicy ksiąg"},
		], "Biblioteka", [
			["", "Regały sięgają sufitu, a w powietrzu unosi się kurz tak gęsty, że można by go smarować na chleb."],
			["", "Lokaje w zbrojach udają, że czytają. Żaden nie trzyma książki w dobrą stronę."],
		], {"who": "Naczelny bibliotekarz", "after_wave": 2, "lines": ["Cisza w bibliotece!", "Wszyscy, którzy hałasują — do kolejnej fali!"]}),
		"palac_3": _floor_zone("szambelan_3", "margrabia_kos", "dama_sroczka", [
			{"enemies": [["golab", 5, false, "kelner"], ["sroka", 3, false, "kelner"]], "name": "Kelnerzy bojowi"},
			{"enemies": [["kruk", 4, false, "gosc"], ["wronszek", 3, false, "gosc"]], "name": "Goście z nożami"},
			{"enemies": [["orzel_szarak", 2, false, "ochrona"], ["kawka", 3, false, "ochrona"]], "name": "Ochrona uczty"},
		], "Sala bankietowa", [
			["", "Stoły uginają się od pieczeni, ciasta i pawich pasztetów. Nikt nie jadł od tygodnia, bo wszyscy czekali na toast."],
			["", "Toast się nie odbył, bo Kruk zabronił podnosić kielichy bez jego zgody. Goście są nieszczęśliwi i uzbrojeni."],
		], {"who": "Mistrz ceremonii", "after_wave": 2, "lines": ["Kto zakłóca ucztę?!", "Do broni, panowie! Deser jest na końcu!"]}),
		"palac_4": _floor_zone("szambelan_4", "lady_szpaczek", "wicehrabia_czarnuszek", [
			{"enemies": [["szpak", 4, false, "ramiarz"], ["kruk", 3, false, "ramiarz"]], "name": "Strażnicy ram"},
			{"enemies": [["jastrzab", 3, false, "cien"], ["sokol", 3, false, "cien"]], "name": "Cienie z portretów"},
			{"enemies": [["bocian_gruby", 2, false, "konserwator"], ["kruk", 3, false, "konserwator"]], "name": "Konserwatorzy"},
		], "Galeria portretów", [
			["", "Portrety dawnych władców patrzą z dezaprobatą. Jeden z nich mruga — a może to tylko cień."],
			["", "Strażnicy pilnują obrazów tak gorliwie, że zapomnieli, kogo mieli bronić przed złodziejami."],
		], {"who": "Główny konserwator", "after_wave": 2, "lines": ["Nie dotykać ram!", "Obrazy są ważniejsze niż życie!"]}),
		"palac_5": _floor_zone("szambelan_5", "kanonik_gawrosz", "hrabia_puchacz", [
			{"enemies": [["kruk", 4, false, "chorzysta"], ["puchacz", 2, false, "chorzysta"]], "name": "Chórzyści z mieczami"},
			{"enemies": [["orzel_szarak", 2, false, "rycerz"], ["bocian_gruby", 2, false, "rycerz"]], "name": "Rycerze zbrojowni"},
			{"enemies": [["krol_krukow", 1, true, "general"], ["kruk", 3, false, "rycerz"]], "name": "Dowódca zbrojowni"},
		], "Kaplica i zbrojownia", [
			["", "Kaplica jest pełna świec, a zbrojownia pełna zbroi, w których nikt nie mieści się z powodu pierzastych ogonów."],
			["", "Dzwony biją na alarm. Tym razem — niestety — z powodu ciebie."],
		], {"who": "Dowódca zbrojowni", "after_wave": 2, "lines": ["Dzwony biją na alarm!", "Zbrojownia, do broni — dosłownie!"]}),
		"narada_wojenna": {
			"terrain": "palace", "spawn": Vector2(1100, 1300), "npcs": ["krolowa", "marszalek", "kanclerz_korony", "mistrz_szpiegow", "kowal"], "giver": "krolowa",
			"council": true,
			"waves": [{"enemies": [["kruk", 4], ["jastrzab", 3]], "name": "Zamachowcy w sali narad", "elite": true}],
			"villain": {}, "intro_banner": ["NARADA", "Sala narad królowej"],
			"intro": [
				["", "Sala narad mieści się pod kopułą najwyższej wieży. Okrągły stół, mapy królestwa i królowa, która nareszcie może rządzić."],
				["", "Doradcy kłócą się od rana. Czekają na ciebie, bo tylko ty widziałeś Kruka z bliska."],
			],
			"outro_banner": ["NARADA ZAKOŃCZONA", "Sala narad królowej"],
		},
		"uwolnij_krola": {
			"terrain": "tower", "spawn": Vector2(1100, 1300), "npcs": ["klawisz", "wiezien_bajarz", "kowal"], "giver": "klawisz",
			"waves": [
				{"enemies": [["kruk", 3, false, "straz"], ["wronszek", 3, false, "straz"]], "name": "Strażnicy lochu"},
				{"enemies": [["jastrzab", 3], ["orzel_szarak", 2]], "name": "Kaci i klawisze"},
				{"enemies": [["bocian_gruby", 2], ["krol_krukow", 1], ["kruk", 2]], "name": "Naczelnik więzienia"},
			],
			"villain": {"who": "Naczelnik więzienia", "after_wave": 2, "lines": ["Nikt nie opuszcza tego lochu!", "Król zostanie tu na zawsze — a ty z nim!"]},
			"intro_banner": ["KRÓL W LOCHU", "Loch pod twierdzą"],
			"intro": [
				["", "Schody w dół prowadzą do lochu, gdzie pachnie wilgocią, zbutwiałą słomą i nieudanymi planami ucieczki."],
				["", "Gdzieś w głębi celi, za kratami, siedzi prawowity Król. Podejdź do niego i go uwolnij."],
			],
			"outro_banner": ["KRÓL WOLNY", "Loch pod twierdzą"],
		},
		"miasto_kruka": {
			"terrain": "ash", "spawn": Vector2(1100, 1300), "npcs": ["szpieg_piorko", "straganiarz_kruczy", "babcia_wrona", "kowal", "kupiec"], "giver": "szpieg_piorko",
			"waves": [
				{"enemies": [["kruk", 4, false, "straz"], ["wronszek", 4, false, "straz"]], "name": "Straż miejska"},
				{"enemies": [["orzel_szarak", 2], ["jastrzab", 3]], "name": "Łowcy z dachów"},
				{"enemies": [["bocian_gruby", 2, false, "rycerz"], ["kruk", 4, false, "straz"]], "name": "Gwardia bramy"},
			],
			"villain": {"who": "Burmistrz Kruka", "after_wave": 2, "lines": ["Nikt nie wchodzi do Miasta Kruka bez zezwolenia!", "A zezwolenia wydajemy tylko przed śmiercią!"]},
			"intro_banner": ["MIASTO KRUKA", "Czarne dachy"],
			"intro": [
				["", "Miasto Kruka wygląda tak, jak powinno wyglądać miasto złoczyńcy: wąskie uliczki, czarne dachy, żadnego koloru i bardzo mało śmiechu."],
				["", "Mieszkańcy udają, że cię nie widzą. To dobry znak — i bardzo zły."],
			],
			"outro_banner": ["BRAMA ZAMKU", "Czarne dachy"],
		},
		"zamek_kruka": {
			"terrain": "fortress", "spawn": Vector2(1100, 1300), "npcs": ["krolowa", "buntownik_zamku", "kowal"], "giver": "krolowa",
			"waves": [
				{"enemies": [["orzel_szarak", 2, false, "general"], ["kruk", 4, false, "rycerz"]], "name": "Pierwszy dziedziniec", "elite": true},
				{"enemies": [["bocian_gruby", 2, false, "general"], ["krol_krukow", 1, false, "general"], ["kruk", 3, false, "rycerz"]], "name": "Gwardia zamkowa", "elite": true},
				{"enemies": [["krol_krukow", 2, false, "general"], ["orzel_szarak", 2, false, "general"]], "name": "Gwardia sali tronowej", "elite": true},
			],
			"villain": {"who": "Generał Pazur", "after_wave": 2, "lines": ["Nikt nie stanie przed obliczem Czarnego Kruka!", "Jestem generałem. Nie żartuję, nie gadam i nie biorę jeńców."]},
			"intro_banner": ["ZAMEK KRUKA", "Pod murami"],
			"intro": [
				["", "Mury Zamku Kruka są czarne jak smoła, a wartownicy nie mówią ani słowa. Generałowie nie opowiadają dowcipów."],
				["", "Za tymi murami są tylko wojownicy. Każdy z nich zaatakuje cię bez ostrzeżenia."],
			],
			"outro_banner": ["SALA TRONOWA", "Pod murami"],
		},
	}

# ------------------------------------------------------------ dodatki ---

static func _talk(npcs: Array, text: String) -> Dictionary:
	return {"id": "arystokraci", "phase": "pre", "type": "talk", "npcs": npcs, "text": text, "required": true}

static var EXTRAS: Dictionary = _strip_floors(_extras())

## Piętra pałacu nie mają obowiązkowych rozmów: arystokraci siedzą w sekretnych komnatach.
static func _strip_floors(d: Dictionary) -> Dictionary:
	for id in ["palac_1", "palac_2", "palac_3", "palac_4", "palac_5"]:
		var ex: Dictionary = d[id]
		ex["npcs"] = []
		ex["dialogs"] = {}
		var objs: Array = []
		for o in ex.get("objectives", []):
			if String(o.get("type", "")) != "talk":
				objs.append(o)
		ex["objectives"] = objs
	return d

## Sekretne komnaty arystokratów: wejście nic nie zmienia w fabule, w środku jest śmieszna scenka.
const ROOMS := {
	"palac_1": [
		{"id": "p1_laznia", "pos": Vector2(330, 560), "kind": "bath", "name": "Sekretna łaźnia"},
		{"id": "p1_garderoba", "pos": Vector2(1860, 600), "kind": "worms", "name": "Garderoba hrabiny"},
	],
	"palac_2": [
		{"id": "p2_czytelnia", "pos": Vector2(330, 580), "kind": "book", "name": "Cicha czytelnia"},
		{"id": "p2_labirynt", "pos": Vector2(1860, 560), "kind": "lost", "name": "Labirynt regałów"},
	],
	"palac_3": [
		{"id": "p3_jadalnia", "pos": Vector2(330, 580), "kind": "feast", "name": "Prywatna jadalnia"},
		{"id": "p3_skarbiec", "pos": Vector2(1860, 600), "kind": "spoon", "name": "Skarbiec błyskotek"},
	],
	"palac_4": [
		{"id": "p4_galeria", "pos": Vector2(330, 560), "kind": "portraits", "name": "Pokój portretów"},
		{"id": "p4_rozmowa", "pos": Vector2(1860, 580), "kind": "talk", "name": "Komnata rozmów"},
	],
	"palac_5": [
		{"id": "p5_kaplica", "pos": Vector2(330, 580), "kind": "sermon", "name": "Mała kaplica"},
		{"id": "p5_sypialnia", "pos": Vector2(1860, 560), "kind": "owl", "name": "Sypialnia Hrabiego"},
	],
	"uwolnij_krolowa": [
		{"id": "kq_wartownia", "pos": Vector2(300, 620), "kind": "guard_nap", "name": "Wartownia"},
		{"id": "kq_kuchnia", "pos": Vector2(1900, 640), "kind": "soup", "name": "Polowa kuchnia"},
	],
	"narada_wojenna": [
		{"id": "nw_mapa", "pos": Vector2(300, 560), "kind": "map_cloth", "name": "Gabinet map"},
		{"id": "nw_dlugi", "pos": Vector2(1900, 560), "kind": "debts", "name": "Skarbiec ksiąg"},
		{"id": "nw_szpieg", "pos": Vector2(300, 1100), "kind": "spy", "name": "Za kotarą"},
		{"id": "nw_przemowa", "pos": Vector2(1900, 1100), "kind": "queen_speech", "name": "Alkowa królowej"},
	],
	"uwolnij_krola": [
		{"id": "kk_bajarz", "pos": Vector2(300, 720), "kind": "tale", "name": "Cela Bajarza"},
		{"id": "kk_klucze", "pos": Vector2(1900, 720), "kind": "keys", "name": "Dyżurka klawisza"},
	],
	"miasto_kruka": [
		{"id": "mk_sloiki", "pos": Vector2(300, 760), "kind": "dark_jars", "name": "Skład ciemności"},
		{"id": "mk_ogrod", "pos": Vector2(1900, 780), "kind": "garden", "name": "Ogródek Babci"},
	],
	"zamek_kruka": [
		{"id": "zk_pamietnik", "pos": Vector2(300, 780), "kind": "diary", "name": "Komnata buntownika"},
	],
	"obrona_wioski": [
		{"id": "ow_lalki", "pos": Vector2(250, 400), "kind": "doll", "name": "Chata Kasi"},
	],
	"droga_do_stolicy": [
		{"id": "ds_woz", "pos": Vector2(260, 280), "kind": "cart", "name": "Wóz Bronka"},
	],
	"atak_na_stolice": [
		{"id": "as_piekarnia", "pos": Vector2(260, 520), "kind": "bread", "name": "Piekarnia Zosi"},
	],
}

## Wystrój etapów — zgodny z opisem miejsca: [rodzaj, pozycja].
const DECOR := {
	"palac_1": [["statue", Vector2(560, 470)], ["statue", Vector2(1640, 470)], ["statue", Vector2(560, 1180)], ["statue", Vector2(1640, 1180)],
		["banner", Vector2(400, 260)], ["banner", Vector2(760, 260)], ["banner", Vector2(1440, 260)], ["banner", Vector2(1800, 260)]],
	"palac_2": [["shelf", Vector2(300, 280)], ["shelf", Vector2(480, 280)], ["shelf", Vector2(660, 280)], ["shelf", Vector2(1540, 280)], ["shelf", Vector2(1720, 280)], ["shelf", Vector2(1900, 280)],
		["shelf", Vector2(200, 760)], ["shelf", Vector2(200, 960)], ["shelf", Vector2(2000, 760)], ["shelf", Vector2(2000, 960)],
		["desk", Vector2(560, 820)], ["desk", Vector2(1640, 820)], ["desk", Vector2(560, 1120)], ["desk", Vector2(1640, 1120)]],
	"palac_3": [["table", Vector2(560, 560)], ["table", Vector2(1640, 560)], ["table", Vector2(560, 860)], ["table", Vector2(1640, 860)],
		["table", Vector2(560, 1160)], ["table", Vector2(1640, 1160)], ["banner", Vector2(300, 260)], ["banner", Vector2(1900, 260)]],
	"palac_4": [["portrait", Vector2(300, 250)], ["portrait", Vector2(520, 250)], ["portrait", Vector2(740, 250)], ["portrait", Vector2(1460, 250)], ["portrait", Vector2(1680, 250)],
		["portrait", Vector2(1900, 250)], ["statue", Vector2(560, 700)], ["statue", Vector2(1640, 700)], ["statue", Vector2(560, 1100)], ["statue", Vector2(1640, 1100)]],
	"palac_5": [["altar", Vector2(1100, 260)], ["pew", Vector2(560, 560)], ["pew", Vector2(560, 760)], ["pew", Vector2(560, 960)], ["pew", Vector2(1640, 560)],
		["rack", Vector2(1480, 260)], ["rack", Vector2(1640, 260)], ["rack", Vector2(1800, 260)], ["rack", Vector2(1960, 260)], ["rack", Vector2(1900, 1180)]],
	"narada_wojenna": [["round", Vector2(1100, 880)], ["banner", Vector2(300, 260)], ["banner", Vector2(700, 260)], ["banner", Vector2(1500, 260)], ["banner", Vector2(1900, 260)]],
	"uwolnij_krola": [["cell", Vector2(340, 330)], ["cell", Vector2(560, 330)], ["cell", Vector2(1640, 330)], ["cell", Vector2(1860, 330)], ["cell", Vector2(340, 1250)], ["cell", Vector2(1860, 1250)]],
	"zamek_kruka": [["statue", Vector2(520, 480)], ["statue", Vector2(1680, 480)], ["rack", Vector2(380, 1200)], ["rack", Vector2(1820, 1200)], ["banner", Vector2(700, 260)], ["banner", Vector2(1500, 260)]],
}

static func _extras() -> Dictionary:
	return {
		"palac_1": {
			"npcs": ["baron_gawron", "hrabina_wrona"],
			"dialogs": {
				"baron_gawron": {
					"pre": [["Baron Gawron", "Och, nareszcie ktoś! Czy nie widziałeś mojego monokla? Zgubiłem go trzy lata temu, w sylwestra."], ["Baron Gawron", "Pytam każdego gościa, a każdy mówi, że ma go na dziobie. Absurd! Na dziobie to ja noszę tylko wąsy."]],
					"choice": {"prompt": "Baron wciąż szuka monokla. Co mu powiesz?", "options": [
						{"text": "Baronie, masz go na dziobie.", "flag": "gawron_monokl", "reply": "„Och! Faktycznie! Jak mogłem... Dziękuję, mój drogi.”", "final": {"gold": 120}},
						{"text": "Poszukam go po drodze.", "flag": "gawron_szukaj", "reply": "„Cóż za uprzejmość. Powiesz mi, jak znajdziesz.”", "final": {"items": {"mikstura_miodu": 1}}},
					]},
					"post": [["Baron Gawron", "Monokl wreszcie znaleziony! Teraz tylko muszę znaleźć drugi."]],
				},
				"hrabina_wrona": {
					"pre": [["Hrabina Wrona", "W kapeluszu hoduję dżdżownice. Wyobrażasz sobie, jak świetnie się to sprawdza w razie głodu?"], ["Hrabina Wrona", "Kruk twierdzi, że mój kapelusz jest zbyt wyrazisty. Ja twierdzę, że on jest zbyt czarny."]],
					"post": [["Hrabina Wrona", "Mój kapelusz przetrwał oblężenie. Dżdżownice, niestety, nie."]],
				},
			},
			"objectives": [
				_talk(["baron_gawron", "hrabina_wrona"], "Wysłuchaj kruczych arystokratów w komnatach"),
				{"id": "pamiatki", "phase": "pre", "type": "collect", "kind": "document", "label": "Podnieś pamiątkę", "count": 2, "positions": [E, H], "text": "Znajdź pamiątki z pałacowych komnat (opcjonalnie)", "required": false,
					"clues": ["Srebrna łyżeczka z inicjałami „G.”", "Złoty guzik od kapelusza hrabiny."], "reward": {"gold": 90}},
			],
		},
		"palac_2": {
			"npcs": ["ksiaze_kruczek", "diuk_kawka"],
			"dialogs": {
				"ksiaze_kruczek": {
					"pre": [["Książę Kruczek", "Czytam książkę o hodowli kur. Od trzech tygodni nie mogę jej skończyć — wciąż trzymam ją do góry nogami."], ["Książę Kruczek", "Ale muszę przyznać, że do góry nogami fabuła jest o wiele ciekawsza!"]],
					"post": [["Książę Kruczek", "Przewróciłem książkę i okazało się, że to poradnik gotowania. Teraz rozumiem, czemu nikt nie chce jeść kur."]],
				},
				"diuk_kawka": {
					"pre": [["Diuk Kawka", "Zgubiłem się w bibliotece. Wszedłem po książkę trzy lata temu i od tego czasu szukam wyjścia."], ["Diuk Kawka", "Jedzenie mi przynoszą lokaje, więc nie narzekam. Ale czasem tęsknię za światem!"]],
					"choice": {"prompt": "Diuk Kawka prosi o pomoc w wyjściu z biblioteki. Co robisz?", "options": [
						{"text": "Pokażę ci drzwi, Diuku.", "flag": "kawka_wyjscie", "reply": "„Drzwi?! Co za wspaniała koncepcja!”", "final": {"gold": 100}},
						{"text": "Zostań i czytaj, Diuku.", "flag": "kawka_zostaje", "reply": "„Mądra rada. Znowu będę szczęśliwy.”", "final": {"items": {"sztabka_zelaza": 2}}},
					]},
					"post": [["Diuk Kawka", "Wyszedłem! Okazało się, że drzwi były tam cały czas."]],
				},
			},
			"objectives": [
				_talk(["ksiaze_kruczek", "diuk_kawka"], "Wysłuchaj kruczych arystokratów w komnatach"),
				{"id": "zakladki", "phase": "pre", "type": "collect", "kind": "document", "label": "Podnieś zakładkę", "count": 2, "positions": [F, G], "text": "Znajdź zakładki w bibliotece (opcjonalnie)", "required": false,
					"clues": ["Zakładka w „Poradniku dobrych manier”.", "Zakładka w „Mapie pałacu” — ktoś zaznaczył schody."], "reward": {"gold": 100, "xp": 100}},
			],
		},
		"palac_3": {
			"npcs": ["margrabia_kos", "dama_sroczka"],
			"dialogs": {
				"margrabia_kos": {
					"pre": [["Margrabia Kos", "Wydałem ucztę na pięćset osób. Przyszły dwie, w tym jedna to szef kuchni, a druga to ja."], ["Margrabia Kos", "Resztę zjadłem sam. Nie czuję się dobrze, ale honoru nie można marnować."]],
					"post": [["Margrabia Kos", "Dieta pałacowa polega na tym, żeby jeść wszystko, co się nie rusza. Reszta jest dla straży."]],
				},
				"dama_sroczka": {
					"pre": [["Dama Sroczka", "Kocham błyskotki. Zbieram je od dzieciństwa. Dziś przypadkiem wpadła mi w dziób twoja łyżka."], ["Dama Sroczka", "Pomyśl o tym jak o uprzejmym darze na rzecz sztuki. Odeślę ci ją, gdy przestanie błyszczeć."]],
					"choice": {"prompt": "Dama Sroczka ukradła ci łyżkę. Co robisz?", "options": [
						{"text": "Zostaw, to dla sztuki.", "flag": "sroczka_dar", "reply": "„Wiedziałam, że masz gust!”", "final": {"gold": 130}},
						{"text": "Oddaj mi ją natychmiast!", "flag": "sroczka_zwrot", "reply": "„Och, jakie to nieeleganckie... ale proszę.”", "final": {"items": {"krysztal_cienia": 1}}},
					]},
					"post": [["Dama Sroczka", "Łyżka wciąż tu jest. Chciałaby wrócić do właściciela, ale ja jej nie puszczę."]],
				},
			},
			"objectives": [
				_talk(["margrabia_kos", "dama_sroczka"], "Wysłuchaj kruczych arystokratów w komnatach"),
				{"id": "przyprawy", "phase": "pre", "type": "collect", "kind": "document", "label": "Podnieś przyprawę", "count": 3, "positions": [A, C, J], "text": "Zbierz przyprawy dla szefa kuchni (opcjonalnie)", "required": false,
					"clues": ["Pieprz — gryzie w dziób.", "Sól — czysta, pałacowa.", "Szafran — droższy niż złoto."], "reward": {"gold": 130, "xp": 120}},
			],
		},
		"palac_4": {
			"npcs": ["lady_szpaczek", "wicehrabia_czarnuszek"],
			"dialogs": {
				"lady_szpaczek": {
					"pre": [["Lady Szpaczek", "Na tej galerii wisi czterdzieści moich portretów. Wszystkie bardzo podobne. Jeden jest do góry nogami, ale to ten, na którym wyglądam najlepiej."], ["Lady Szpaczek", "Malarz mówił, że to przypadek. Ja twierdzę, że geniusz."]],
					"post": [["Lady Szpaczek", "Dołożyłam jeszcze jeden portret. To będzie czterdziesty pierwszy."]],
				},
				"wicehrabia_czarnuszek": {
					"pre": [["Wicehrabia Czarnuszek", "Rozmawiam z portretami. One przynajmniej nie przerywają."], ["Wicehrabia Czarnuszek", "Tamten w złotej ramie twierdzi, że za schodami jest tajne przejście. Nie wiem, czy mu wierzyć, bo kłamie od czterystu lat."]],
					"choice": {"prompt": "Wicehrabia pyta, czy potwierdzisz historię portretu. Co mówisz?", "options": [
						{"text": "Portret mówi prawdę.", "flag": "czarnuszek_wierzy", "reply": "„Wiedziałem! Zawsze lubiłem go bardziej niż ciebie.”", "final": {"gold": 120}},
						{"text": "Portrety nie mówią.", "flag": "czarnuszek_sceptyk", "reply": "„To dlatego wciąż jestem sam.”", "final": {"items": {"mikstura_miodu": 2}}},
					]},
					"post": [["Wicehrabia Czarnuszek", "Portret wciąż się wymądrza. Ale schody za nim faktycznie są."]],
				},
			},
			"objectives": [
				_talk(["lady_szpaczek", "wicehrabia_czarnuszek"], "Wysłuchaj kruczych arystokratów w komnatach"),
				{"id": "elita", "phase": "pre", "type": "elite", "enemy": "kruk", "name": "Konserwator Pędzla", "pos": Vector2(1100, 900), "text": "Pokonaj konserwatora galerii (opcjonalnie)", "required": false,
					"reward": {"gold": 160, "xp": 200}},
			],
		},
		"palac_5": {
			"npcs": ["kanonik_gawrosz", "hrabia_puchacz"],
			"dialogs": {
				"kanonik_gawrosz": {
					"pre": [["Kanonik Gawrosz", "Kazanie o ziarnku trwało trzy godziny, ale nikt nie narzekał. Wszyscy spali."], ["Kanonik Gawrosz", "Kruk pochwalił mnie za takt. Ja uważam, że to była po prostu pozycja do snu."]],
					"post": [["Kanonik Gawrosz", "Kazanie o ziarnku dobiegło końca. Kolejne — o dwóch ziarnkach — trwa dwa razy dłużej."]],
				},
				"hrabia_puchacz": {
					"pre": [["Hrabia Puchacz", "Śpię całymi dniami, a w nocy czuwam. Wszyscy mówią, że to nienaturalne. Ja mówię, że jestem sową, a to bywa wygodne."], ["Hrabia Puchacz", "Kruk kazał mi pilnować pałacu w nocy. Pilnuję — z zamkniętymi oczami, dla bezpieczeństwa."]],
					"choice": {"prompt": "Hrabia Puchacz pyta, czy go obudzisz o północy.", "options": [
						{"text": "Obudzę cię, Hrabio.", "flag": "puchacz_budzi", "reply": "„Zapomnę, że prosiłem.”", "final": {"gold": 110}},
						{"text": "Śpij dalej.", "flag": "puchacz_sni", "reply": "„Zrozumiałem. Wyśpię się za nas obu.”", "final": {"items": {"eliksir_mocy": 1}}},
					]},
					"post": [["Hrabia Puchacz", "Obudziłem się na chwilę. Pałac jeszcze stoi. Idę spać."]],
				},
			},
			"objectives": [
				_talk(["kanonik_gawrosz", "hrabia_puchacz"], "Wysłuchaj kruczych arystokratów w komnatach"),
				{"id": "relikwie", "phase": "pre", "type": "collect", "kind": "document", "label": "Podnieś relikwię", "count": 2, "positions": [D, B], "text": "Znajdź relikwie kaplicy (opcjonalnie)", "required": false,
					"clues": ["Relikwia: pierwsze ziarnko, według kanonika.", "Relikwia: kapeć dawnego króla."], "reward": {"gold": 140, "xp": 140}},
			],
		},
		"narada_wojenna": {
			"npcs": ["krolowa", "marszalek", "kanclerz_korony", "mistrz_szpiegow"],
			"dialogs": {
				"krolowa": {
					"pre": [["Królowa Aurelia", "Dziękuję, że mnie uwolniłeś. Teraz musimy zdecydować, jak zatrzymać Kruka, zanim zniszczy całe królestwo."], ["Królowa Aurelia", "Posłuchaj doradców. Potem zadecyduj, jaki plan przyjmiemy. Dziś nie ma złych odpowiedzi — są tylko drogie."]],
					"choice": {"prompt": "Królowa pyta, jaką strategię wybierasz.", "options": [
						{"text": "Uderzmy od frontu i szybko.", "flag": "narada_front", "reply": "„Odważnie! Wojsko będzie gotowe do świtu.”", "final": {"gold": 220}},
						{"text": "Przemknijmy się chyłkiem przez miasto.", "flag": "narada_cicho", "reply": "„Rozważnie. Mistrz Szpiegów wam pomoże.”", "final": {"items": {"zwoj_teleportacji": 1}}},
						{"text": "Poszukajmy sojuszników.", "flag": "narada_sojusznicy", "reply": "„Mądrze. Poślę gołębie do sąsiednich wiosek.”", "final": {"items": {"eliksir_mocy": 2}}},
					]},
					"post": [["Królowa Aurelia", "Narada zakończona. Dziękuję, że byłeś z nami. Idź teraz uwolnić Króla — to jego głos zakończy wojnę."]],
				},
				"marszalek": {
					"pre": [["Marszałek Dziobacz", "Wojsko mamy, tylko nie wiem, gdzie zostawiłem mapę. W ogóle to ją trzymam, ale do góry nogami."], ["Marszałek Dziobacz", "Atak od frontu jest prosty: idziemy i bijemy. Niestety, tak samo prosta jest porażka."]],
					"post": [["Marszałek Dziobacz", "Mapa się znalazła. Okazuje się, że to nie mapa, tylko obrus."]],
				},
				"kanclerz_korony": {
					"pre": [["Kanclerz Piórko", "Skarbiec jest pusty, ale zapisy księgowe są doskonałe. Długi mamy jedynie wobec wszystkich."], ["Kanclerz Piórko", "Jeśli wygramy wojnę, odzyskamy kasę. Jeśli przegramy, nikt nie będzie miał pretensji."]],
					"post": [["Kanclerz Piórko", "Wciąż liczę, ale wynik jest coraz lepszy."]],
				},
				"mistrz_szpiegow": {
					"pre": [["Mistrz Szpiegów Cichopiór", "Wszystkie moje informacje są ściśle tajne. Dlatego nikomu ich nie mówię, nawet sobie."], ["Mistrz Szpiegów Cichopiór", "Wiem jedno: Kruk ma generałów, którzy nie rozumieją żartów. To wasza słabość i nasza szansa."]],
					"post": [["Mistrz Szpiegów Cichopiór", "Informacje są tajne. Ale dla ciebie zrobię wyjątek: nie wiem nic."]],
				},
			},
			"objectives": [
			],
		},
		"uwolnij_krola": {
			"npcs": ["klawisz", "wiezien_bajarz"],
			"dialogs": {
				"klawisz": {
					"pre": [["Klawisz Zbigniew", "Klucze do wszystkich cel mam na jednym kółku. Niestety, nigdy nie wiem, który do której."], ["Klawisz Zbigniew", "Cel Króla szukaj w głębi. Tylko nie dotykaj kraty, ona jest bardzo zimna."]],
					"post": [["Klawisz Zbigniew", "Król wolny, a ja bezrobotny. Chyba przejdę na emeryturę."]],
				},
				"wiezien_bajarz": {
					"pre": [["Więzień Bajarz", "Siedzę tu od roku i opowiadam bajki współwięźniom. Mam już czterdzieści siedem historii."], ["Więzień Bajarz", "Ostatnia jest o kurczaku, który uwolnił Króla. Niestety, jeszcze nie wiem, jak się kończy."]],
					"post": [["Więzień Bajarz", "Dobrze, że ta bajka ma szczęśliwe zakończenie."]],
				},
			},
			"objectives": [
				{"id": "swiadkowie", "phase": "pre", "type": "talk", "npcs": ["wiezien_bajarz"], "text": "Porozmawiaj z więźniem Bajarzem", "required": true},
				{"id": "krol", "phase": "post", "type": "free", "kind": "cage", "label": "Uwolnij Króla", "count": 1, "positions": [Vector2(1100, 420)], "text": "Podejdź do celi i uwolnij Króla", "required": true,
					"reward": {"gold": 300, "xp": 250, "items": {"zwoj_teleportacji": 1}}},
			],
		},
		"miasto_kruka": {
			"npcs": ["szpieg_piorko", "straganiarz_kruczy", "babcia_wrona"],
			"dialogs": {
				"szpieg_piorko": {
					"pre": [["Szpieg Podróbka", "Udaję mieszkańca od tygodnia. Nikt się nie zorientował, bo wszyscy tu wyglądają jak ja: ponuro."], ["Szpieg Podróbka", "Do zamku prowadzi tylko jedna brama. Pilnują jej trzej generałowie. Ci nie mają poczucia humoru."]],
					"post": [["Szpieg Podróbka", "Brama stoi otworem. Jestem z ciebie dumny — i trochę przerażony."]],
				},
				"straganiarz_kruczy": {
					"pre": [["Kruczy Straganiarz", "Sprzedaję ciemność w słoikach. Bardzo dobrze schodzi, bo nikt nie ma własnej."], ["Kruczy Straganiarz", "Chcesz kupić? Nie? To dobrze, bo już się skończyła."]],
					"post": [["Kruczy Straganiarz", "Po tym wszystkim sprzedaję teraz światło w słoikach. Idzie jeszcze lepiej."]],
				},
				"babcia_wrona": {
					"pre": [["Babcia Wrona", "Moje wnuki służą Krukowi. Mówię im: jedzcie, bo wyrośniecie. Czy któreś mnie słucha? Nie."], ["Babcia Wrona", "Ale kocham je, nawet gdy wymachują mieczami. Tylko niech nie niszczą mojego ogródka."]],
					"post": [["Babcia Wrona", "Ogródek ocalał. Wnuki — niestety, trochę mniej."]],
				},
			},
			"objectives": [
				{"id": "przewodnik", "phase": "pre", "type": "talk", "npcs": ["straganiarz_kruczy", "babcia_wrona"], "text": "Wypytaj mieszkańców o drogę do zamku", "required": true},
				{"id": "pieczecie", "phase": "pre", "type": "collect", "kind": "document", "label": "Podnieś pieczęć miejską", "count": 2, "positions": [A, J], "text": "Zbierz pieczęcie przepustkowe (opcjonalnie)", "required": false,
					"clues": ["Pieczęć: czarny kruk na szarym tle.", "Pieczęć: przepustka dla gołębi pocztowych."], "reward": {"gold": 160, "xp": 150}},
			],
		},
		"zamek_kruka": {
			"npcs": ["krolowa", "buntownik_zamku"],
			"dialogs": {
				"krolowa": {
					"pre": [["Królowa Aurelia", "Wchodzimy do zamku. Nie zatrzymuj się, dopóki nie dojdziesz do sali tronowej."], ["Królowa Aurelia", "Generałowie Kruka są niebezpieczni. Nie żartuj z nimi — nie odpowiedzą."]],
					"post": [["Królowa Aurelia", "Drzwi sali tronowej stoją otworem. Kruk jest tuż za nimi."]],
				},
				"buntownik_zamku": {
					"pre": [["Buntownik Kruk Młodszy", "Jestem wnukiem Czarnego Kruka i mam go dosyć. Opowiem ci, gdzie są generałowie."], ["Buntownik Kruk Młodszy", "Pierwszy — przy bramie. Drugi — na dziedzińcu. Trzeci pilnuje drzwi sali tronowej. Żaden nie ucieknie."]],
					"post": [["Buntownik Kruk Młodszy", "Generałowie pokonani! Dziadek będzie bardzo niezadowolony."]],
				},
			},
			"objectives": [
				{"id": "buntownik", "phase": "pre", "type": "talk", "npcs": ["buntownik_zamku"], "text": "Porozmawiaj z buntownikiem Krukiem Młodszym", "required": true},
				{"id": "general1", "phase": "pre", "type": "elite", "enemy": "orzel_szarak", "name": "Generał Szpon", "pos": Vector2(560, 800), "text": "Pokonaj generała Szpona", "required": true,
					"reward": {"gold": 220, "xp": 260}},
				{"id": "general2", "phase": "pre", "type": "elite", "enemy": "bocian_gruby", "name": "Generał Dziób", "pos": Vector2(1660, 820), "text": "Pokonaj generała Dzioba", "required": true,
					"reward": {"gold": 220, "xp": 260}},
			],
		},
	}

## Poprawki istniejących rozdziałów (twierdza Kruka: generałowie zamiast dworzan).
static func patch_extras(base: Dictionary) -> Dictionary:
	var out := base.duplicate(true)
	if out.has("marsz_na_forteca"):
		var ex: Dictionary = out["marsz_na_forteca"]
		var objs: Array = ex.get("objectives", [])
		objs.append({"id": "general_k", "phase": "pre", "type": "elite", "enemy": "krol_krukow", "name": "Generał Szpon Burzy", "pos": Vector2(1100, 760),
			"text": "Pokonaj generała twierdzy", "required": true, "reward": {"gold": 260, "xp": 300, "items": {"zwoj_teleportacji": 1}}})
		ex["objectives"] = objs
	return out
