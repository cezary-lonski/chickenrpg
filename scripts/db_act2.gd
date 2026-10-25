class_name Act2DB
extends RefCounted
## AKT II — ZEMSTA NA CZARNYM KRUKU. Gracz sam prowadzi ataki na wioski kontrolowane
## przez Kruka. Misje wybiera się na mapie świata; ostatnia (gniazdo) odblokowuje się po
## wyzwoleniu pięciu wiosek. Decyzje w misjach dają wdzięczność wiosek (rep), która
## osłabia finałowego bossa i zwiększa nagrodę.

const ORDER := ["akt2_zielonka", "akt2_mlynowka", "akt2_bagniska", "akt2_wzgorze", "akt2_dymiaca", "akt2_gniazdo"]
const FINAL := "akt2_gniazdo"

## Pozycje na mapie świata (okno 1000×520).
const MAP := {
	"akt2_zielonka": Vector2(170, 360),
	"akt2_mlynowka": Vector2(360, 190),
	"akt2_bagniska": Vector2(520, 400),
	"akt2_wzgorze": Vector2(700, 200),
	"akt2_dymiaca": Vector2(840, 380),
	"akt2_gniazdo": Vector2(500, 70),
}

const ENEMIES := {
	"wrona_pikinier": {
		"name": "Wrona Pikinier", "ai": "charger", "scale": 1.16, "tier": 4,
		"health": 150.0, "defense": 0.14, "speed": 102.0, "poise": 0.4, "xp": 60, "gold": 20,
		"pal": {"body": Color(0.2, 0.22, 0.3), "shade": Color(0.1, 0.11, 0.17), "beak": Color(0.75, 0.75, 0.8), "eye": Color(1.0, 0.45, 0.2)},
		"aggro": 640.0, "attack_range": 64.0, "cooldown": [1.0, 1.8],
		"attacks": [
			{"name": "pchniecie", "range": 74.0, "windup": 0.36, "active": 0.14, "recover": 0.46, "dmg": 17.0, "kb": 240.0, "stun": 0.4},
			{"name": "szarza_pikiniera", "range": 230.0, "windup": 0.5, "active": 0.34, "recover": 0.7, "dmg": 21.0, "kb": 300.0, "stun": 0.5, "leap": true},
		],
	},
	"wrona_lucznik": {
		"name": "Wrona Łucznik", "ai": "ranged", "scale": 1.0, "tier": 4,
		"health": 92.0, "defense": 0.08, "speed": 112.0, "poise": 0.15, "xp": 54, "gold": 18,
		"pal": {"body": Color(0.18, 0.2, 0.26), "shade": Color(0.09, 0.1, 0.15), "beak": Color(0.85, 0.7, 0.3), "eye": Color(1.0, 0.8, 0.2)},
		"aggro": 700.0, "attack_range": 360.0, "keep_distance": 300.0, "cooldown": [1.1, 1.9],
		"attacks": [
			{"name": "salwa_lucznika", "range": 440.0, "windup": 0.46, "active": 0.1, "recover": 0.55, "dmg": 13.0, "kb": 130.0, "stun": 0.25, "projectile": "feather", "volley": 2},
		],
	},
	"kruk_rzeznik": {
		"name": "Kruk Rzeźnik", "ai": "grappler", "scale": 1.3, "tier": 5,
		"health": 220.0, "defense": 0.18, "speed": 92.0, "poise": 0.55, "xp": 96, "gold": 32,
		"pal": {"body": Color(0.14, 0.1, 0.12), "shade": Color(0.07, 0.05, 0.07), "beak": Color(0.7, 0.2, 0.15), "eye": Color(1.0, 0.25, 0.1)},
		"aggro": 640.0, "attack_range": 70.0, "cooldown": [1.2, 2.0],
		"attacks": [
			{"name": "chwyt_rzeznika", "range": 78.0, "windup": 0.44, "active": 0.2, "recover": 0.62, "dmg": 24.0, "kb": 100.0, "stun": 0.9, "grab": true},
			{"name": "ciecie", "range": 88.0, "windup": 0.4, "active": 0.16, "recover": 0.52, "dmg": 20.0, "kb": 300.0, "stun": 0.5},
		],
	},
	"jaskolka_zwiadowca": {
		"name": "Jaskółka Zwiadowca", "ai": "sprinter", "scale": 0.86, "tier": 4,
		"health": 72.0, "defense": 0.04, "speed": 235.0, "poise": 0.05, "xp": 48, "gold": 15,
		"pal": {"body": Color(0.18, 0.26, 0.42), "shade": Color(0.1, 0.16, 0.3), "beak": Color(0.95, 0.8, 0.4), "eye": Color(0.9, 0.95, 1.0)},
		"aggro": 760.0, "attack_range": 46.0, "cooldown": [0.6, 1.1],
		"attacks": [
			{"name": "cios_zwiadowcy", "range": 50.0, "windup": 0.14, "active": 0.1, "recover": 0.22, "dmg": 14.0, "kb": 150.0, "stun": 0.3},
		],
	},
}

const NPCS := {
	"kapitan_odwetu": {"name": "Kapitan Odwetu Hanna", "title": "Dowódca ruchu oporu", "species": "kogut", "scale": 1.6, "pos": Vector2(1120, 985), "accent": Color(1.0, 0.55, 0.35), "role": "quest"},
	"rolnik_zielonka": {"name": "Rolnik Kazimierz", "title": "Mieszkaniec Zielonki", "species": "kurczak", "scale": 1.4, "pos": Vector2(520, 1000), "accent": Color(0.7, 0.9, 0.5), "role": "lore"},
	"mlynarka": {"name": "Młynarka Agata", "title": "Mieszkanka Młynówki", "species": "kwoka", "scale": 1.35, "pos": Vector2(560, 960), "accent": Color(0.95, 0.85, 0.6), "role": "lore"},
	"przewoznik": {"name": "Przewoźnik Gustaw", "title": "Przewoźnik z Bagnisk", "species": "gasior", "scale": 1.45, "pos": Vector2(640, 940), "accent": Color(0.6, 0.85, 0.75), "role": "lore"},
	"wartownik_wzgorza": {"name": "Wartownik Rudy", "title": "Zbiegły wartownik", "species": "kogut", "scale": 1.45, "pos": Vector2(500, 980), "accent": Color(0.85, 0.65, 0.5), "role": "lore"},
	"kowalowa": {"name": "Kowalowa Brygida", "title": "Wdowa po kowalu", "species": "kwoka", "scale": 1.4, "pos": Vector2(560, 1000), "accent": Color(0.95, 0.6, 0.4), "role": "lore"},
	"wiesniak_gniazdo": {"name": "Uciekinier Tomek", "title": "Zbieg z gniazda", "species": "kurczak", "scale": 1.35, "pos": Vector2(620, 980), "accent": Color(0.8, 0.8, 0.95), "role": "lore"},
}

const QUESTS := [
	{
		"id": "akt2_zielonka", "act": 2, "label": "Akt II — Misja 1", "title": "Zielonka: Spichlerz Kruka", "giver": "Kapitan Odwetu Hanna",
		"intro": "Zielonka została spichlerzem armii Kruka. Wyzwól wioskę i odetnij mu zaopatrzenie.",
		"objs": ["Porozmawiaj z kapitanem Odwetu", "Odeprzyj odsiecz — fala 1 / 2", "Odeprzyj odsiecz — fala 2 / 2", "Wróć do kapitana"],
		"outro": "Zielonka wolna. Zboże znów trafia do wieśniaków.",
		"reward": {"gold": 700, "xp": 800, "items": {"sztabka_kurczalu": 2}}, "ready": true,
	},
	{
		"id": "akt2_mlynowka", "act": 2, "label": "Akt II — Misja 2", "title": "Młynówka: Szlak zaopatrzenia", "giver": "Kapitan Odwetu Hanna",
		"intro": "Wozy Kruka jadą przez Młynówkę. Przejmij szlak i uwolnij młynarzy.",
		"objs": ["Porozmawiaj z kapitanem Odwetu", "Odeprzyj konwój — fala 1 / 2", "Odeprzyj konwój — fala 2 / 2", "Wróć do kapitana"],
		"outro": "Młynówka wolna. Koła młyna zaczęły się obracać.",
		"reward": {"gold": 800, "xp": 950, "items": {"sztabka_kurczalu": 2, "krysztal_cienia": 1}}, "ready": true,
	},
	{
		"id": "akt2_bagniska", "act": 2, "label": "Akt II — Misja 3", "title": "Bagniska: Przeprawa", "giver": "Kapitan Odwetu Hanna",
		"intro": "Jedyna przeprawa przez bagna jest w rękach Kruka. Przejmij ją, zanim spadną deszcze.",
		"objs": ["Porozmawiaj z kapitanem Odwetu", "Odeprzyj straż przeprawy — fala 1 / 2", "Odeprzyj straż przeprawy — fala 2 / 2", "Wróć do kapitana"],
		"outro": "Przeprawa odzyskana. Droga do wzgórz stoi otworem.",
		"reward": {"gold": 900, "xp": 1100, "items": {"sztabka_kurczalu": 3}}, "ready": true,
	},
	{
		"id": "akt2_wzgorze", "act": 2, "label": "Akt II — Misja 4", "title": "Wzgórze Wron: Posterunek", "giver": "Kapitan Odwetu Hanna",
		"intro": "Z posterunku na wzgórzu wrony widzą każdy ruch. Zgaś ich wieże alarmowe.",
		"objs": ["Porozmawiaj z kapitanem Odwetu", "Odeprzyj wartę — fala 1 / 2", "Odeprzyj wartę — fala 2 / 2", "Wróć do kapitana"],
		"outro": "Wieże zgasły. Armia Kruka straciła oczy.",
		"reward": {"gold": 1000, "xp": 1250, "items": {"sztabka_kurczalu": 3, "eliksir_mocy": 1}}, "ready": true,
	},
	{
		"id": "akt2_dymiaca", "act": 2, "label": "Akt II — Misja 5", "title": "Dymiąca Wioska: Kuźnia Kruka", "giver": "Kapitan Odwetu Hanna",
		"intro": "W Dymiącej Wiosce kują pancerze dla armii Kruka. Zniszcz kuźnie i uwolnij kowali.",
		"objs": ["Porozmawiaj z kapitanem Odwetu", "Odeprzyj straż kuźni — fala 1 / 2", "Odeprzyj straż kuźni — fala 2 / 2", "Wróć do kapitana"],
		"outro": "Kuźnie zgasły. Kowale wrócili do wolnych kowadeł.",
		"reward": {"gold": 1100, "xp": 1400, "items": {"krysztal_cienia": 1, "sztabka_kurczalu": 3}}, "ready": true,
	},
	{
		"id": "akt2_gniazdo", "act": 2, "label": "Akt II — Misja 6", "title": "Gniazdo Czarnego Kruka", "giver": "Kapitan Odwetu Hanna",
		"intro": "Pięć wiosek jest wolnych. Czas zakończyć to, co zaczęło się w Sercu Kruka.",
		"objs": ["Porozmawiaj z kapitanem Odwetu", "Przebij się przez gniazdo — fala 1 / 2", "Przebij się przez gniazdo — fala 2 / 2", "Wróć do kapitana"],
		"outro": "Czarny Kruk Odrodzony pokonany. Zemsta dopełniona — a wioski wreszcie śpią spokojnie.",
		"reward": {"gold": 2000, "xp": 2400, "items": {"sztabka_kurczalium": 1, "eliksir_mocy": 3}}, "ready": true,
	},
]

const ZONES := {
	"akt2_zielonka": {
		"terrain": "village", "spawn": Vector2(1100, 1080), "npcs": ["kapitan_odwetu", "kupiec", "kowal"], "giver": "kapitan_odwetu",
		"waves": [
			{"enemies": [["wrona_pikinier", 3], ["wronszek", 3]], "name": "Pikinierzy Zielonki"},
			{"enemies": [["wrona_lucznik", 3], ["wrona_pikinier", 2], ["jaskolka_zwiadowca", 2]], "name": "Łucznicy i zwiadowcy"},
		],
		"intro_banner": ["AKT II — MISJA 1", "Zielonka"],
		"intro": [
			["", "Zielonka kiedyś pachniała chlebem. Teraz pachnie dymem — i strachem."],
			["", "Czarny Kruk uciekł z fortecy, lecz jego sieć pozostała. Wioski pracują dla niego pod batami wron."],
			["", "Tym razem to ty uderzasz pierwszy. Wyzwól Zielonkę."],
		],
		"outro_banner": ["MISJA UKOŃCZONA", "Zielonka wyzwolona"],
	},
	"akt2_mlynowka": {
		"terrain": "road", "spawn": Vector2(300, 750), "npcs": ["kapitan_odwetu", "kupiec", "kowal"], "giver": "kapitan_odwetu",
		"waves": [
			{"enemies": [["wrona_pikinier", 4], ["jaskolka_zwiadowca", 3]], "name": "Eskorta konwoju"},
			{"enemies": [["kruk_rzeznik", 2], ["wrona_lucznik", 3]], "name": "Rzeźnicy szlaku"},
		],
		"intro_banner": ["AKT II — MISJA 2", "Młynówka"],
		"intro": [
			["", "Szlak do Młynówki prowadzi wzdłuż rzeki. Wozy Kruka jadą nim dzień i noc."],
			["", "Jeśli odetniesz konwój, jego armia zgłodnieje. Młynarze czekają w ukryciu."],
			["", "Przejmij szlak i uwolnij Młynówkę."],
		],
		"outro_banner": ["MISJA UKOŃCZONA", "Młynówka wyzwolona"],
	},
	"akt2_bagniska": {
		"terrain": "storm", "spawn": Vector2(1100, 1250), "npcs": ["kapitan_odwetu", "kupiec", "kowal"], "giver": "kapitan_odwetu",
		"waves": [
			{"enemies": [["wrona_pikinier", 3], ["wrona_lucznik", 3], ["jaskolka_zwiadowca", 2]], "name": "Straż przeprawy"},
			{"enemies": [["kruk_rzeznik", 3], ["wrona_lucznik", 3]], "name": "Rzeźnicy bagien"},
		],
		"intro_banner": ["AKT II — MISJA 3", "Bagniska"],
		"intro": [
			["", "Bagna są oślizgłe, a mgła nie przepuszcza nawet światła. Jedyna przeprawa jest w rękach Kruka."],
			["", "Przewoźnik Gustaw zna każdą kładkę. Jeśli mu zaufasz, przeprowadzi cię na drugi brzeg."],
			["", "Bądź czujny: deszcz dopiero się zaczyna."],
		],
		"outro_banner": ["MISJA UKOŃCZONA", "Bagniska wyzwolone"],
	},
	"akt2_wzgorze": {
		"terrain": "fortress", "spawn": Vector2(1100, 1250), "npcs": ["kapitan_odwetu", "kupiec", "kowal"], "giver": "kapitan_odwetu",
		"waves": [
			{"enemies": [["wrona_pikinier", 4], ["wrona_lucznik", 3]], "name": "Warta wzgórza"},
			{"enemies": [["kruk_rzeznik", 2], ["wrona_pikinier", 3], ["jaskolka_zwiadowca", 3]], "name": "Pułk wron"},
		],
		"intro_banner": ["AKT II — MISJA 4", "Wzgórze Wron"],
		"intro": [
			["", "Z Wzgórza Wron widać całą dolinę. Dlatego Kruk ustawił tu swój posterunek."],
			["", "Wieże alarmowe zawołają posiłki, jeśli ktoś zauważy twoje skrzydła."],
			["", "Zgaś wieże, nim zabrzmi alarm. Potem rozprawimy się z pułkownikiem."],
		],
		"outro_banner": ["MISJA UKOŃCZONA", "Wzgórze wyzwolone"],
	},
	"akt2_dymiaca": {
		"terrain": "ash", "spawn": Vector2(1100, 1250), "npcs": ["kapitan_odwetu", "kupiec", "kowal"], "giver": "kapitan_odwetu",
		"waves": [
			{"enemies": [["kruk_rzeznik", 3], ["wrona_pikinier", 3]], "name": "Straż kuźni"},
			{"enemies": [["wrona_lucznik", 4], ["kruk_rzeznik", 2], ["jaskolka_zwiadowca", 3]], "name": "Młoty i pióra"},
		],
		"intro_banner": ["AKT II — MISJA 5", "Dymiąca Wioska"],
		"intro": [
			["", "Z komina każdego domu wali czarny dym. Kowale Kruka kują dniem i nocą."],
			["", "Jeśli kuźnie padną, jego armia straci pancerze. Kowale, którym kazano pracować, czekają na ratunek."],
			["", "Zniszcz kuźnie i uwolnij kowali."],
		],
		"outro_banner": ["MISJA UKOŃCZONA", "Dymiąca Wioska wyzwolona"],
	},
	"akt2_gniazdo": {
		"terrain": "dawn", "spawn": Vector2(1100, 1250), "npcs": ["kapitan_odwetu", "kupiec", "kowal"], "giver": "kapitan_odwetu",
		"waves": [
			{"enemies": [["kruk_rzeznik", 3], ["wrona_pikinier", 4], ["wrona_lucznik", 3]], "name": "Brama gniazda"},
			{"enemies": [["kruk_rzeznik", 3], ["jaskolka_zwiadowca", 4], ["wrona_lucznik", 3]], "name": "Dziedziniec gniazda"},
		],
		"intro_banner": ["AKT II — MISJA 6", "Gniazdo Czarnego Kruka"],
		"intro": [
			["", "Na szczycie skały, w kręgu zgliszcz, stoi Gniazdo Czarnego Kruka. To tu zebrał resztki swojej mocy."],
			["", "Wyzwolone wioski wsparły cię, jak mogły. Dziś jest tylko jeden cel."],
			["", "Raz na zawsze skończ to, co zaczęło się w Sercu Kruka."],
		],
		"outro_banner": ["AKT II UKOŃCZONY", "Zemsta dopełniona"],
	},
}

const BOSS_BY_ZONE := {
	"akt2_zielonka": "kruczy_kwatermistrz",
	"akt2_mlynowka": "straznik_mlyna",
	"akt2_bagniska": "blotnik",
	"akt2_wzgorze": "pulkownik_wron",
	"akt2_dymiaca": "kruczy_kowal",
	"akt2_gniazdo": "czarny_kruk_odrodzony",
}

const BOSSES := {
	"kruczy_kwatermistrz": {
		"name": "Kruczy Kwatermistrz", "title": "Strażnik Spichlerza", "species": "orzel_szarak", "scale": 2.3, "hp": 2000.0, "dmg": 26.0, "speed": 120.0,
		"xp": 1100, "gold": 600, "defense": 0.14,
		"phases": [
			{"at": 1.0, "attacks": ["swipe_combo", "ground_pound", "feather_fan"], "cd": [1.0, 1.5], "speed": 1.0},
			{"at": 0.5, "attacks": ["summon", "charge", "ground_pound", "lightning"], "cd": [0.8, 1.3], "speed": 1.2, "adds": 3, "name": "SPICHLERZ PĘKA"},
		],
		"intro": [["Kruczy Kwatermistrz", "Każde ziarno w tej wiosce jest własnością Kruka. Również twoje kości."]],
		"death": [["Kruczy Kwatermistrz", "Spichlerz... pusty... pan mnie rozliczy."]],
		"reward": {"gold": 500, "items": {"sztabka_kurczalu": 2}},
		"pal": {"body": Color(0.35, 0.28, 0.22), "shade": Color(0.2, 0.15, 0.12), "comb": Color(0.6, 0.2, 0.15), "beak": Color(0.9, 0.7, 0.3), "eye": Color(1.0, 0.5, 0.2)},
	},
	"straznik_mlyna": {
		"name": "Strażnik Młyna", "title": "Pan Szlaku", "species": "bocian_gruby", "scale": 2.3, "hp": 2400.0, "dmg": 28.0, "speed": 118.0,
		"xp": 1300, "gold": 700, "defense": 0.16,
		"phases": [
			{"at": 1.0, "attacks": ["charge", "swipe_combo", "lightning"], "cd": [1.0, 1.5], "speed": 1.0},
			{"at": 0.5, "attacks": ["charge", "ring_wave", "summon", "feather_fan"], "cd": [0.8, 1.2], "speed": 1.25, "adds": 3, "name": "ŻARNA KRĘCĄ SIĘ SZYBCIEJ"},
		],
		"intro": [["Strażnik Młyna", "Nie przejdziesz. Koła tego młyna kręcą się dla Kruka, a ja pilnuję szlaku."]],
		"death": [["Strażnik Młyna", "Zamilknij, młynie... zamilknij."]],
		"reward": {"gold": 600, "items": {"sztabka_kurczalu": 2, "krysztal_cienia": 1}},
		"pal": {"body": Color(0.5, 0.5, 0.45), "shade": Color(0.3, 0.3, 0.27), "beak": Color(0.9, 0.5, 0.25), "eye": Color(1.0, 0.8, 0.3)},
	},
	"blotnik": {
		"name": "Błotnik", "title": "Duch Bagien", "species": "bocian_gruby", "scale": 2.4, "hp": 2800.0, "dmg": 30.0, "speed": 112.0,
		"xp": 1500, "gold": 800, "defense": 0.16,
		"phases": [
			{"at": 1.0, "attacks": ["dive", "ground_pound", "lightning"], "cd": [1.0, 1.5], "speed": 1.0},
			{"at": 0.55, "attacks": ["ring_wave", "dive", "summon", "feather_fan"], "cd": [0.8, 1.2], "speed": 1.2, "adds": 3, "name": "BAGNO OŻYWA"},
			{"at": 0.25, "attacks": ["beam_storm", "ring_wave", "dive", "lightning"], "cd": [0.65, 1.0], "speed": 1.3, "name": "WIR BŁOTA"},
		],
		"intro": [["Błotnik", "Bagno pamięta każdego, kto próbował przejść. Wszyscy zostali tutaj."]],
		"death": [["Błotnik", "Rozpuszczam się... wracam do błota."]],
		"reward": {"gold": 700, "items": {"sztabka_kurczalu": 3}},
		"pal": {"body": Color(0.3, 0.38, 0.28), "shade": Color(0.18, 0.24, 0.16), "beak": Color(0.8, 0.7, 0.3), "eye": Color(0.7, 1.0, 0.4)},
	},
	"pulkownik_wron": {
		"name": "Pułkownik Wron", "title": "Dowódca Wzgórza", "species": "kruk", "scale": 2.5, "hp": 3200.0, "dmg": 32.0, "speed": 128.0,
		"xp": 1700, "gold": 900, "defense": 0.18,
		"phases": [
			{"at": 1.0, "attacks": ["charge", "feather_fan", "swipe_combo", "dive"], "cd": [0.95, 1.4], "speed": 1.0},
			{"at": 0.6, "attacks": ["ring_wave", "charge", "summon", "lightning"], "cd": [0.8, 1.2], "speed": 1.2, "adds": 4, "name": "PUŁK WRON"},
			{"at": 0.25, "attacks": ["beam_storm", "dive", "charge", "feather_fan"], "cd": [0.65, 1.0], "speed": 1.35, "name": "ALARM"},
		],
		"intro": [["Pułkownik Wron", "Dzwony milczą, ale ja nie. Jeden mój krzyk i zlecą się setki."]],
		"death": [["Pułkownik Wron", "Nie... alarm... nie zadzwonił."]],
		"reward": {"gold": 800, "items": {"sztabka_kurczalu": 3, "eliksir_mocy": 1}},
		"pal": {"body": Color(0.12, 0.13, 0.18), "shade": Color(0.05, 0.06, 0.1), "comb": Color(0.7, 0.15, 0.15), "beak": Color(0.75, 0.75, 0.8), "eye": Color(1.0, 0.4, 0.1)},
	},
	"kruczy_kowal": {
		"name": "Kruczy Kowal", "title": "Pan Młotów", "species": "krol_krukow", "scale": 2.4, "hp": 3600.0, "dmg": 34.0, "speed": 115.0,
		"xp": 1900, "gold": 1000, "defense": 0.2,
		"phases": [
			{"at": 1.0, "attacks": ["ground_pound", "swipe_combo", "lightning", "charge"], "cd": [1.0, 1.5], "speed": 1.0},
			{"at": 0.55, "attacks": ["ring_wave", "ground_pound", "summon", "beam_storm"], "cd": [0.8, 1.2], "speed": 1.2, "adds": 3, "name": "GORĄCA STAL"},
			{"at": 0.25, "attacks": ["beam_storm", "dive", "ground_pound", "lightning"], "cd": [0.65, 1.0], "speed": 1.35, "name": "ROZPALONY MŁOT"},
		],
		"intro": [["Kruczy Kowal", "Wykułem tysiąc pancerzy dla Kruka. Z twojego dziobu zrobię gwóźdź."]],
		"death": [["Kruczy Kowal", "Młot... wypadł... z mojej łapy."]],
		"reward": {"gold": 900, "items": {"krysztal_cienia": 1, "sztabka_kurczalu": 3}},
		"pal": {"body": Color(0.2, 0.14, 0.12), "shade": Color(0.1, 0.07, 0.06), "comb": Color(0.95, 0.5, 0.15), "beak": Color(0.9, 0.55, 0.2), "eye": Color(1.0, 0.6, 0.1)},
	},
	"czarny_kruk_odrodzony": {
		"name": "Czarny Kruk Odrodzony", "title": "Pan Gniazda", "species": "krol_krukow", "scale": 3.0, "hp": 6500.0, "dmg": 36.0, "speed": 145.0,
		"xp": 3000, "gold": 1500, "defense": 0.2, "vuln_bonus": 0.3,
		"phases": [
			{"at": 1.0, "attacks": ["swipe_combo", "feather_fan", "dive", "ground_pound", "lightning"], "cd": [0.95, 1.4], "speed": 1.0},
			{"at": 0.7, "attacks": ["ring_wave", "charge", "summon", "lightning", "feather_fan"], "cd": [0.8, 1.2], "speed": 1.2, "adds": 4, "name": "FAZA II — POWRÓT CIENIA"},
			{"at": 0.4, "attacks": ["beam_storm", "dive", "ring_wave", "charge", "lightning"], "cd": [0.65, 1.0], "speed": 1.35, "adds": 3, "name": "FAZA III — NOC BEZ KOŃCA"},
			{"at": 0.15, "attacks": ["beam_storm", "dive", "charge", "lightning", "ring_wave", "feather_fan", "ground_pound"], "cd": [0.5, 0.85], "speed": 1.5, "name": "FAZA IV — OSTATNIE PIÓRO"},
		],
		"intro": [
			["Czarny Kruk Odrodzony", "Spaliłem tę ziemię i podniosłem się z popiołu. Dziś spalę ciebie."],
			["Czarny Kruk Odrodzony", "Twoje wioski? Moje. Twoja królowa? Moja. Ty? Zaraz będziesz niczyj."],
		],
		"death": [
			["Czarny Kruk Odrodzony", "Nie mogę... przegrać... drugi raz..."],
			["", "Czarne pióra opadają jak śnieg. W gnieździe zapada cisza, a nad skałą wstaje świt."],
		],
		"reward": {"gold": 1500, "items": {"wzorzec_kurczak": 1, "sztabka_kurczalium": 2, "pazur_czarnego_kruka": 1, "eliksir_mocy": 3}},
		"pal": {"body": Color(0.07, 0.05, 0.1), "shade": Color(0.03, 0.02, 0.05), "comb": Color(0.8, 0.1, 0.25), "beak": Color(0.85, 0.75, 0.5), "eye": Color(1.0, 0.2, 0.1)},
	},
}

const EXTRAS := {
	"akt2_zielonka": {
		"npcs": ["rolnik_zielonka"],
		"dialogs": {
			"rolnik_zielonka": {
				"pre": [["Rolnik Kazimierz", "Wrony zabrały cały urodzaj. Zostało mi tylko to, co schowałem w stodole."], ["Rolnik Kazimierz", "Spichlerz stoi pod strażą. Jeśli rozbijesz sygnałowe dzwony, nie wezwą posiłków."]],
				"choice": {"prompt": "Spichlerz jest pełen zboża Kruka. Co z nim zrobisz?", "options": [
					{"text": "Rozdaj zboże wieśniakom.", "flag": "zielonka_rozdaj", "rep": 1, "reply": "Rolnik płacze ze szczęścia. „Zielonka nie zapomni.”", "final": {"gold": 120, "items": {"mikstura_miodu": 3}}},
					{"text": "Sprzedaj zboże i zabierz złoto.", "flag": "zielonka_sprzedaj", "reply": "„Cóż... w końcu to wojna.”", "final": {"gold": 450}},
				]},
				"post": [["Rolnik Kazimierz", "Spichlerz otwarty. Dziękuję, Panie Bohaterze."]],
			},
		},
		"objectives": [
			{"id": "rozmowa", "phase": "pre", "type": "talk", "npcs": ["rolnik_zielonka"], "text": "Porozmawiaj z rolnikiem", "required": true},
			{"id": "dzwony", "phase": "pre", "type": "sabotage", "kind": "crate", "label": "Rozbij dzwon alarmowy", "count": 3, "positions": [Vector2(1650, 400), Vector2(1250, 1130), Vector2(900, 1260)], "text": "Zniszcz dzwony alarmowe", "required": true,
				"reward": {"gold": 200, "items": {"sztabka_kurczalu": 1}, "xp": 160}},
			{"id": "jency", "phase": "pre", "type": "free", "kind": "cage", "label": "Uwolnij jeńca", "count": 2, "positions": [Vector2(260, 1390), Vector2(2000, 1380)], "text": "Uwolnij wieśniaków z klatek (opcjonalnie)", "required": false,
				"reward": {"gold": 220, "items": {"mikstura_miodu": 2}, "xp": 180}},
		],
	},
	"akt2_mlynowka": {
		"npcs": ["mlynarka"],
		"dialogs": {
			"mlynarka": {
				"pre": [["Młynarka Agata", "Wozy jadą dzień i noc. Wrony pilnują ich jak oczka w głowie."], ["Młynarka Agata", "Rozkazy transportu są pochowane w trzech punktach szlaku. Kto je przeczyta, zna trasę konwoju."]],
				"choice": {"prompt": "Młynarka prosi o mąkę dla głodnych dzieci. Co robisz?", "options": [
					{"text": "Daj im Miksturę Miodu.", "flag": "mlynowka_dar", "rep": 1, "reply": "„Niech cię Bóg błogosławi!”", "take": {"mikstura_miodu": 1}, "final": {"gold": 140, "items": {"sztabka_kurczalu": 1}}},
					{"text": "Nie mogę tym razem.", "flag": "mlynowka_odmowa", "reply": "Agata spuszcza wzrok. „Rozumiem.”", "final": {"gold": 220}},
				]},
				"post": [["Młynarka Agata", "Młyn mieli już dla nas. Dziękuję."]],
			},
		},
		"objectives": [
			{"id": "rozmowa", "phase": "pre", "type": "talk", "npcs": ["mlynarka"], "text": "Porozmawiaj z młynarką", "required": true},
			{"id": "rozkazy", "phase": "pre", "type": "collect", "kind": "document", "label": "Przeczytaj rozkaz konwoju", "count": 3, "positions": [Vector2(330, 930), Vector2(1000, 440), Vector2(1860, 900)], "text": "Zbierz rozkazy konwoju", "required": true,
				"clues": ["„Konwój numer 1 jedzie do fortecy przez bród.”", "„Konwój numer 2 niesie zbroje z Dymiącej Wioski.”", "„Wozy opuszczają Młynówkę przed świtem. Straż: 12 wron.”"], "reward": {"gold": 220, "xp": 170}},
			{"id": "wozy", "phase": "pre", "type": "sabotage", "kind": "crate", "label": "Zniszcz wóz z zapasami", "count": 3, "positions": [Vector2(1650, 400), Vector2(1250, 1130), Vector2(700, 350)], "text": "Zniszcz wozy z zapasami (opcjonalnie)", "required": false,
				"reward": {"gold": 260, "items": {"sztabka_kurczalu": 1}, "xp": 200}},
		],
	},
	"akt2_bagniska": {
		"npcs": ["przewoznik"],
		"dialogs": {
			"przewoznik": {
				"pre": [["Przewoźnik Gustaw", "Przeprawa to jedyna droga. Straż wron zabrała mi łódź, ale znam każdą kładkę."], ["Przewoźnik Gustaw", "Zbierz trzy znaki przeprawy — wskażą ukryte kładki. Pamiętaj: w bagnach nie ufaj światełkom."]],
				"choice": {"prompt": "Przewoźnik żąda zapłaty za prowadzenie. Co robisz?", "options": [
					{"text": "Zapłać 50 złota.", "flag": "bagniska_zaplata", "rep": 1, "reply": "„Uczciwie. Poprowadzę cię.”", "cost": 50, "final": {"items": {"sztabka_kurczalu": 2}}},
					{"text": "Obiecuję zapłatę po misji.", "flag": "bagniska_obietnica", "reply": "„Rozumiem. Ale pamiętam.”", "final": {"gold": 200}},
				]},
				"post": [["Przewoźnik Gustaw", "Łódź wróciła. Szlak jest znów wolny."]],
			},
		},
		"objectives": [
			{"id": "rozmowa", "phase": "pre", "type": "talk", "npcs": ["przewoznik"], "text": "Porozmawiaj z przewoźnikiem", "required": true},
			{"id": "znaki", "phase": "pre", "type": "collect", "kind": "document", "label": "Odczytaj znak przeprawy", "count": 3, "positions": [Vector2(330, 930), Vector2(1860, 900), Vector2(900, 1260)], "text": "Zbierz znaki przeprawy", "required": true,
				"clues": ["Znak: trzy kreski na pniu — kładka na północ.", "Znak: pióro wbite w błoto — kładka na wschód.", "Znak: kamień z rysunkiem łodzi — przeprawa główna."], "reward": {"gold": 240, "xp": 190}},
			{"id": "elita", "phase": "pre", "type": "elite", "enemy": "kruk_rzeznik", "name": "Rzeźnik Bagien", "pos": Vector2(1100, 1000), "text": "Pokonaj Rzeźnika Bagien (opcjonalnie)", "required": false,
				"reward": {"gold": 320, "items": {"sztabka_kurczalu": 2}, "xp": 260}},
		],
	},
	"akt2_wzgorze": {
		"npcs": ["wartownik_wzgorza"],
		"dialogs": {
			"wartownik_wzgorza": {
				"pre": [["Wartownik Rudy", "Uciekłem z posterunku, bo nie chciałem być jedną z nich. Wieże sygnalizują ruch w całej dolinie."], ["Wartownik Rudy", "Trzy wieże. Zgaś je po cichu, a pułkownik będzie walczył sam."]],
				"choice": {"prompt": "Rudy chce ci pomóc, ale boi się kary. Co robisz?", "options": [
					{"text": "Zaufaj mu — niech prowadzi.", "flag": "wzgorze_zaufanie", "rep": 1, "reply": "„Nie zawiodę cię!”", "final": {"gold": 160, "items": {"eliksir_mocy": 1}}},
					{"text": "Odeślij go. Sam sobie poradzę.", "flag": "wzgorze_samotnie", "reply": "Rudy spuszcza głowę i odchodzi.", "final": {"gold": 320}},
				]},
				"post": [["Wartownik Rudy", "Wzgórze wolne. Pierwszy raz od lat."]],
			},
		},
		"objectives": [
			{"id": "rozmowa", "phase": "pre", "type": "talk", "npcs": ["wartownik_wzgorza"], "text": "Porozmawiaj z wartownikiem", "required": true},
			{"id": "wieze", "phase": "pre", "type": "sabotage", "kind": "crate", "label": "Zgaś wieżę alarmową", "count": 3, "positions": [Vector2(700, 350), Vector2(1650, 400), Vector2(1250, 1130)], "text": "Zgaś wieże alarmowe", "required": true,
				"reward": {"gold": 280, "items": {"sztabka_kurczalu": 1}, "xp": 220}},
			{"id": "jency", "phase": "pre", "type": "free", "kind": "cage", "label": "Uwolnij jeńca", "count": 3, "positions": [Vector2(260, 1390), Vector2(2000, 1380), Vector2(1420, 1400)], "text": "Uwolnij jeńców (opcjonalnie)", "required": false,
				"reward": {"gold": 340, "items": {"eliksir_mocy": 1}, "xp": 280}},
		],
	},
	"akt2_dymiaca": {
		"npcs": ["kowalowa"],
		"dialogs": {
			"kowalowa": {
				"pre": [["Kowalowa Brygida", "Mój mąż kuł dla Kruka pod batem. Dziś kowale płaczą nad własnymi młotami."], ["Kowalowa Brygida", "Plany pancerzy leżą w trzech kuźniach. Znajdź je, a zniszczysz produkcję."]],
				"choice": {"prompt": "Brygida prosi, by nie palić kuźni — to ich jedyny dobytek.", "options": [
					{"text": "Oszczędzę je. Przydadzą się wolnym kowalom.", "flag": "dymiaca_oszczedz", "rep": 1, "reply": "„Kowale będą ci wdzięczni.”", "final": {"gold": 180, "items": {"sztabka_kurczalu": 2}}},
					{"text": "Spalę wszystko. Kruk nie dostanie żadnego pancerza.", "flag": "dymiaca_spal", "reply": "Brygida milczy.", "final": {"gold": 520}},
				]},
				"post": [["Kowalowa Brygida", "Kowale wracają do pracy. Dla siebie."]],
			},
		},
		"objectives": [
			{"id": "rozmowa", "phase": "pre", "type": "talk", "npcs": ["kowalowa"], "text": "Porozmawiaj z kowalową", "required": true},
			{"id": "plany", "phase": "pre", "type": "collect", "kind": "document", "label": "Przeczytaj plan pancerza", "count": 3, "positions": [Vector2(330, 930), Vector2(1000, 440), Vector2(1860, 900)], "text": "Zbierz plany pancerzy", "required": true,
				"clues": ["Plan: pancerz grenadiera kruków, 5 sztabek.", "Plan: hełm wodza, stal z Dymiącej Wioski.", "Plan: tajna zbroja Czarnego Kruka — kurczalium."], "reward": {"gold": 300, "xp": 230}},
			{"id": "kuznie", "phase": "pre", "type": "sabotage", "kind": "crate", "label": "Zniszcz kuźnię Kruka", "count": 3, "positions": [Vector2(1650, 400), Vector2(1250, 1130), Vector2(700, 350)], "text": "Zniszcz kuźnie Kruka", "required": true,
				"reward": {"gold": 340, "items": {"sztabka_kurczalu": 2}, "xp": 280}},
		],
	},
	"akt2_gniazdo": {
		"npcs": ["wiesniak_gniazdo"],
		"dialogs": {
			"wiesniak_gniazdo": {
				"pre": [["Uciekinier Tomek", "Widziałem rytuał. Czarny Kruk wskrzesza się z własnych piór. Jego moc jest w trzech fragmentach."], ["Uciekinier Tomek", "Zniszcz fragmenty, a nie wróci po raz trzeci. Wioski ci pomogą, jeśli je wyzwoliłeś."]],
				"post": [["Uciekinier Tomek", "Koniec. Naprawdę koniec."]],
			},
		},
		"objectives": [
			{"id": "rozmowa", "phase": "pre", "type": "talk", "npcs": ["wiesniak_gniazdo"], "text": "Porozmawiaj z uciekinierem", "required": true},
			{"id": "fragmenty", "phase": "pre", "type": "collect", "kind": "document", "label": "Zniszcz fragment rytuału", "count": 3, "positions": [Vector2(330, 930), Vector2(1860, 900), Vector2(1000, 440)], "text": "Zniszcz trzy fragmenty rytuału", "required": true,
				"clues": ["Fragment rytuału: czarne pióro owinięte w drut. Trzaska i rozpada się.", "Fragment rytuału: kamień z odciskiem szponów. Pęka na pół.", "Fragment rytuału: miseczka z czarnym płynem. Rozlewa się i paruje."], "reward": {"gold": 500, "xp": 400}},
		],
	},
}

# ----------------------------------------------------------------- stan Aktu II ---

static func state() -> Dictionary:
	if not (GameState.profile.get("act2") is Dictionary):
		GameState.profile["act2"] = {"liberated": [], "rep": 0, "started": false}
	var s: Dictionary = GameState.profile["act2"]
	if not (s.get("liberated") is Array): s["liberated"] = []
	if not s.has("rep"): s["rep"] = 0
	return s

static func liberated() -> Array:
	return state()["liberated"]

static func is_liberated(id: String) -> bool:
	return id in liberated()

static func is_available(id: String) -> bool:
	if is_liberated(id):
		return false
	if id == FINAL:
		return liberated().size() >= ORDER.size() - 1
	return true

static func rep() -> int:
	return int(state().get("rep", 0))

static func add_rep(n: int = 1) -> void:
	state()["rep"] = rep() + n
	GameState.save_game()

static func liberate(id: String) -> void:
	var s := state()
	if id not in s["liberated"]:
		s["liberated"].append(id)
	GameState.save_game()

static func all_done() -> bool:
	return liberated().size() >= ORDER.size()
