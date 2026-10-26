class_name FortressDB
extends RefCounted
## Piętra twierdzy i zamku Kruka: bez arystokratów i dowcipów — tylko generałowie i ich straż.
## Działają jak piętra pałacu: schody prowadzą od razu wyżej, bez ekranu statystyk.
##  • Twierdza Kruka (2 piętra) — po rozdziale „Marsz na twierdzę”,
##  • Zamek Kruka (3 piętra) — po Mieście Kruka, przed salą tronową.

const CHAPTERS_FORT := [
	{
		"id": "twierdza_1", "title": "Twierdza Kruka — mury i brama", "giver": "Kapitan Odwetu",
		"intro": "Czarne mury twierdzy sięgają chmur. Na blankach stoją łucznicy, a w bramie czeka pierwszy z generałów Kruka.",
		"objs": ["Sforsuj bramę twierdzy", "Pokonaj łuczników z murów", "Pokonaj generała bramy", "Wejdź schodami do koszar"],
		"outro": "Brama pękła, mury są wasze. Schody prowadzą do koszar generałów.",
		"reward": {"gold": 500, "xp": 480, "items": {"mikstura_miodu": 3}},
	},
	{
		"id": "twierdza_2", "title": "Twierdza Kruka — koszary generałów", "giver": "Kapitan Odwetu",
		"intro": "Wewnątrz twierdzy pachnie smarem i stalą. W koszarach generałowie szykują się do obrony i nie zamierzają rozmawiać.",
		"objs": ["Przejdź przez koszary", "Pokonaj generała zbrojowni", "Pokonaj generała jazdy", "Wejdź schodami na dziedziniec"],
		"outro": "Koszary zdobyte, generałowie pokonani. Droga do Miasta Kruka stoi otworem.",
		"reward": {"gold": 540, "xp": 520, "items": {"eliksir_mocy": 1}},
	},
]

const CHAPTERS_CASTLE := [
	{
		"id": "zamek_1", "title": "Zamek Kruka — dziedziniec", "giver": "Królowa Aurelia",
		"intro": "Dziedziniec zamku jest pusty — tylko szereg żołnierzy w czarnych zbrojach i generał, który nie zna słowa „wycofać”.",
		"objs": ["Wejdź na dziedziniec", "Pokonaj straż dziedzińca", "Pokonaj generała dziedzińca", "Wejdź schodami do krużganków"],
		"outro": "Dziedziniec zdobyty. Krużganki zamku czekają wyżej.",
		"reward": {"gold": 620, "xp": 600, "items": {"krysztal_cienia": 1}},
	},
	{
		"id": "zamek_2", "title": "Zamek Kruka — krużganki", "giver": "Królowa Aurelia",
		"intro": "Wąskie krużganki ciągną się wzdłuż murów. Każdy zakręt skrywa generała, a każde okno — łucznika.",
		"objs": ["Przejdź przez krużganki", "Pokonaj generała łuczników", "Pokonaj generała gwardii", "Wejdź schodami do wieży"],
		"outro": "Krużganki oczyszczone. Została tylko wieża generałów.",
		"reward": {"gold": 660, "xp": 640, "items": {"eliksir_mocy": 2}},
	},
	{
		"id": "zamek_3", "title": "Zamek Kruka — wieża generałów", "giver": "Królowa Aurelia",
		"intro": "Wieża generałów to ostatnia przeszkoda przed salą tronową. Na szczycie czeka Naczelny Generał Kruka.",
		"objs": ["Wejdź do wieży", "Pokonaj generałów wieży", "Pokonaj Naczelnego Generała", "Wejdź schodami do sali tronowej"],
		"outro": "Naczelny Generał pokonany. Przed tobą ostatnie drzwi — do sali tronowej.",
		"reward": {"gold": 720, "xp": 700, "items": {"zwoj_teleportacji": 1, "eliksir_mocy": 2}},
	},
]

static func _floor(banner_title: String, banner: String, waves: Array, intro: Array, villain: Dictionary, terrain: String) -> Dictionary:
	return {
		"terrain": terrain, "spawn": Vector2(1100, 1300), "npcs": ["kowal"], "giver": "", "waves": waves, "stairs": true,
		"villain": villain, "intro_banner": [banner_title, banner], "intro": intro, "outro_banner": ["SCHODY WOLNE", banner],
	}

static var ZONES: Dictionary = _zones()

static func _zones() -> Dictionary:
	return {
		"twierdza_1": _floor("TWIERDZA", "Mury i brama", [
			{"enemies": [["kruk", 4, false, "straz"], ["szpak", 3, false, "luk"]], "name": "Łucznicy na murach"},
			{"enemies": [["wronszek", 4, false, "wlocznik"], ["kruk", 3, false, "ciezki"]], "name": "Włócznicy bramy"},
			{"enemies": [["krol_krukow", 1, true, "general"], ["orzel_szarak", 2, false, "ciezki"]], "name": "Generał bramy"},
		], [
			["", "Czarne mury twierdzy wznoszą się nad wami jak ściana burzy. Na blankach błyskają groty."],
			["", "Tu nikt nie opowiada dowcipów ani nie narzeka na portrety. Straż Kruka ma jedno zadanie: nie wpuścić nikogo."],
		], {"who": "Generał bramy", "after_wave": 2, "lines": ["Nikt nie przekroczy bramy Kruka!", "Zamknąć kraty! Pozostali — do broni!"]}, "fortress"),
		"twierdza_2": _floor("TWIERDZA", "Koszary generałów", [
			{"enemies": [["jastrzab", 4, false, "rycerz"], ["kruk", 4, false, "ciezki"]], "name": "Gwardia koszar"},
			{"enemies": [["bocian_gruby", 2, false, "krolewski"], ["orzel_szarak", 3, false, "rycerz"]], "name": "Generał zbrojowni"},
			{"enemies": [["krol_krukow", 1, true, "general"], ["sokol", 3, false, "lekki"], ["kruk", 3, false, "wlocznik"]], "name": "Generał jazdy"},
		], [
			["", "W koszarach rzędy łóżek, stojaki z mieczami i zapach oliwy do zbroi. Czuć dyscyplinę — i strach."],
			["", "Generałowie pilnują, żeby nikt nie zasnął na służbie. Właśnie dlatego nie zasnęli, kiedy weszliście."],
		], {"who": "Generał jazdy", "after_wave": 2, "lines": ["Jazda, na koń! Tu nie ma dokąd uciekać!", "Za Kruka! Za koszary!"]}, "fortress"),
		"zamek_1": _floor("ZAMEK", "Dziedziniec", [
			{"enemies": [["kruk", 5, false, "straz"], ["wronszek", 3, false, "wlocznik"]], "name": "Szereg straży"},
			{"enemies": [["orzel_szarak", 3, false, "rycerz"], ["szpak", 3, false, "luk"]], "name": "Rycerze dziedzińca"},
			{"enemies": [["krol_krukow", 1, true, "general"], ["bocian_gruby", 2, false, "krolewski"]], "name": "Generał dziedzińca"},
		], [
			["", "Dziedziniec zamku jest wyłożony czarnym kamieniem, po którym stuk butów niesie się jak werbel."],
			["", "Na środku stoi szereg żołnierzy, jakby ktoś rozrysował linię i kazał jej oddychać."],
		], {"who": "Generał dziedzińca", "after_wave": 2, "lines": ["Żołnierze, ani kroku wstecz!", "Zamek nie wpuszcza kurczaków!"]}, "fortress"),
		"zamek_2": _floor("ZAMEK", "Krużganki", [
			{"enemies": [["szpak", 4, false, "luk"], ["sokol", 3, false, "lekki"]], "name": "Łucznicy z okien"},
			{"enemies": [["jastrzab", 4, false, "ciezki"], ["kruk", 4, false, "krolewski"]], "name": "Gwardia krużganków"},
			{"enemies": [["krol_krukow", 1, true, "general"], ["bocian_gruby", 2, false, "rycerz"], ["kruk", 3, false, "straz"]], "name": "Generał gwardii"},
		], [
			["", "Krużganki są wąskie i długie, a w oknach co kilka kroków czai się łucznik."],
			["", "Echo niesie każdy krok. Tutaj nie da się podejść po cichu — ale da się podejść szybko."],
		], {"who": "Generał gwardii", "after_wave": 2, "lines": ["Wszyscy do krużganków, natychmiast!", "Strzelcy — ognia! A reszta — za mną!"]}, "fortress"),
		"zamek_3": _floor("ZAMEK", "Wieża generałów", [
			{"enemies": [["kruk", 5, false, "krolewski"], ["orzel_szarak", 3, false, "ciezki"]], "name": "Gwardia wieży"},
			{"enemies": [["krol_krukow", 1, true, "general"], ["jastrzab", 3, false, "rycerz"]], "name": "Generałowie wieży"},
			{"enemies": [["krol_krukow", 2, true, "general"], ["bocian_gruby", 2, false, "krolewski"], ["kruk", 4, false, "ciezki"]], "name": "Naczelny Generał"},
		], [
			["", "Wieża generałów to spiralne schody, mapy na ścianach i pokój narad, w którym nikt nie śmiał się od lat."],
			["", "Ostatni generał czeka na szczycie. Za nim — drzwi do sali tronowej Czarnego Kruka."],
		], {"who": "Naczelny Generał", "after_wave": 2, "lines": ["Kruk powierzył mi to miejsce. Nie zawiodę go!", "Ostatnia obrona. Nikt nie przejdzie!"]}, "fortress"),
	}

const DECOR := {
	"twierdza_1": [["banner", Vector2(420, 260)], ["banner", Vector2(780, 260)], ["banner", Vector2(1420, 260)], ["banner", Vector2(1780, 260)],
		["statue", Vector2(560, 560)], ["statue", Vector2(1640, 560)], ["rack", Vector2(300, 1200)], ["rack", Vector2(1900, 1200)]],
	"twierdza_2": [["rack", Vector2(340, 400)], ["rack", Vector2(520, 400)], ["rack", Vector2(1680, 400)], ["rack", Vector2(1860, 400)],
		["table", Vector2(700, 900)], ["table", Vector2(1500, 900)], ["banner", Vector2(1100, 260)]],
	"zamek_1": [["statue", Vector2(520, 500)], ["statue", Vector2(1680, 500)], ["statue", Vector2(520, 1100)], ["statue", Vector2(1680, 1100)],
		["banner", Vector2(420, 260)], ["banner", Vector2(1780, 260)]],
	"zamek_2": [["banner", Vector2(300, 260)], ["banner", Vector2(660, 260)], ["banner", Vector2(1540, 260)], ["banner", Vector2(1900, 260)],
		["statue", Vector2(420, 760)], ["statue", Vector2(1780, 760)], ["rack", Vector2(560, 1200)], ["rack", Vector2(1640, 1200)]],
	"zamek_3": [["round", Vector2(1100, 880)], ["banner", Vector2(500, 260)], ["banner", Vector2(1700, 260)], ["rack", Vector2(300, 700)], ["rack", Vector2(1900, 700)]],
}
