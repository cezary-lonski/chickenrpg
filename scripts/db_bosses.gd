class_name BossDB
extends RefCounted
## Prawdziwi bossowie (kampania top-down): własna arena, wejście, fazy, zapowiedzi ataków.
## phases: lista {"at": próg zdrowia (ułamek), "attacks": [ataki], "cd": [min, max], "speed": mnożnik,
## "adds": liczba przywołanych, "name": komunikat}. Ataki: patrz BossBig._run_attack.
## dmg: bazowe obrażenia ataków (skalowane do poziomu gracza).

const ARENA_CENTER := Vector2(1100.0, 750.0)
const ARENA_RADIUS := 560.0

const BASE_LIST := {
	"hrabia_sroka": {
		"name": "Hrabia Sroka", "title": "Błyskotliwy Łupieżca", "species": "sroka", "scale": 2.1, "hp": 700.0, "dmg": 16.0, "speed": 120.0,
		"xp": 260, "gold": 160, "defense": 0.05,
		"phases": [
			{"at": 1.0, "attacks": ["swipe_combo", "feather_fan"], "cd": [1.2, 1.8], "speed": 1.0},
			{"at": 0.5, "attacks": ["swipe_combo", "feather_fan", "lightning"], "cd": [0.9, 1.4], "speed": 1.15, "name": "SROKA SZALEJE"},
		],
		"intro": [["Hrabia Sroka", "Wszystko, co błyszczy, należy do mnie. Ty też zaraz będziesz!"]],
		"death": [["Hrabia Sroka", "To... niemożliwe. Błyskotki... uciekają mi z dziobu."]],
		"reward": {"gold": 120, "items": {"sztabka_zelaza": 2}},
		"pal": {"body": Color(0.12, 0.12, 0.16), "shade": Color(0.5, 0.55, 0.65), "beak": Color(0.9, 0.85, 0.5), "eye": Color(1.0, 0.8, 0.2)},
	},
	"herold_kruka": {
		"name": "Herold Kruka", "title": "Głos Czarnych Skrzydeł", "species": "kruk", "scale": 2.2, "hp": 950.0, "dmg": 19.0, "speed": 125.0,
		"xp": 330, "gold": 200, "defense": 0.08,
		"phases": [
			{"at": 1.0, "attacks": ["swipe_combo", "charge", "feather_fan"], "cd": [1.1, 1.7], "speed": 1.0},
			{"at": 0.55, "attacks": ["charge", "feather_fan", "ground_pound"], "cd": [0.85, 1.3], "speed": 1.2, "name": "HEROLD WZYWA STADO"},
		],
		"intro": [["Herold Kruka", "Mój pan nakazał: zatrzymać każdego, kto zmierza do stolicy."]],
		"death": [["Herold Kruka", "Czarny Kruk... zapamięta... to imię..."]],
		"reward": {"gold": 160, "items": {"sztabka_kurczalu": 1}},
		"pal": {"body": Color(0.1, 0.1, 0.14), "shade": Color(0.05, 0.05, 0.08), "beak": Color(0.7, 0.7, 0.75), "eye": Color(1.0, 0.45, 0.1)},
	},
	"kapitan_zdrajcow": {
		"name": "Kapitan Zdrajców", "title": "Pierzasta Hańba", "species": "orzel_szarak", "scale": 2.2, "hp": 1250.0, "dmg": 22.0, "speed": 130.0,
		"xp": 420, "gold": 260, "defense": 0.12,
		"phases": [
			{"at": 1.0, "attacks": ["charge", "ground_pound", "swipe_combo"], "cd": [1.1, 1.6], "speed": 1.0},
			{"at": 0.5, "attacks": ["summon", "charge", "ground_pound", "lightning"], "cd": [0.9, 1.4], "speed": 1.15, "adds": 3, "name": "ZDRAJCY NA POMOC"},
		],
		"intro": [["Kapitan Zdrajców", "Stolica jest nasza! Straż królowej dawno przeszła na właściwą stronę."]],
		"death": [["Kapitan Zdrajców", "Zdradziłem... wszystkich. Po co..."]],
		"reward": {"gold": 220, "items": {"sztabka_kurczalu": 1, "krysztal_cienia": 1}},
		"pal": {"body": Color(0.32, 0.25, 0.2), "shade": Color(0.18, 0.14, 0.12), "beak": Color(0.9, 0.7, 0.2), "eye": Color(1.0, 0.3, 0.2)},
	},
	"dowodca_strazy": {
		"name": "Dowódca Straży", "title": "Strażnik Wieży", "species": "bocian_gruby", "scale": 2.2, "hp": 1600.0, "dmg": 25.0, "speed": 118.0,
		"xp": 520, "gold": 320, "defense": 0.14,
		"phases": [
			{"at": 1.0, "attacks": ["swipe_combo", "ground_pound", "lightning"], "cd": [1.1, 1.6], "speed": 1.0},
			{"at": 0.55, "attacks": ["ring_wave", "ground_pound", "lightning", "charge"], "cd": [0.85, 1.3], "speed": 1.2, "name": "BRAMA WIEŻY ZAMKNIĘTA"},
		],
		"intro": [["Dowódca Straży", "Nikt nie opuści tej wieży. Królowa jest pod moją pieczą!"]],
		"death": [["Dowódca Straży", "Klucze... zostały w moim pasie..."]],
		"reward": {"gold": 260, "items": {"sztabka_kurczalu": 2}},
		"pal": {"body": Color(0.45, 0.42, 0.4), "shade": Color(0.28, 0.26, 0.26), "beak": Color(0.95, 0.5, 0.2), "eye": Color(1.0, 0.8, 0.3)},
	},
	"lesny_straznik": {
		"name": "Leśny Strażnik", "title": "Cień Starego Gaju", "species": "sowa", "scale": 2.3, "hp": 1900.0, "dmg": 27.0, "speed": 115.0,
		"xp": 640, "gold": 380, "defense": 0.14,
		"phases": [
			{"at": 1.0, "attacks": ["dive", "feather_fan", "lightning"], "cd": [1.1, 1.6], "speed": 1.0},
			{"at": 0.5, "attacks": ["summon", "dive", "ring_wave", "feather_fan"], "cd": [0.9, 1.4], "speed": 1.15, "adds": 3, "name": "LAS OŻYWA"},
		],
		"intro": [["Leśny Strażnik", "Trzy próby minęły, ale gaj nie wypuści nikogo, kto nie jest godny."]],
		"death": [["Leśny Strażnik", "Idź... Las... uznaje cię."]],
		"reward": {"gold": 300, "items": {"sztabka_kurczalu": 2, "krysztal_cienia": 1}},
		"pal": {"body": Color(0.35, 0.3, 0.22), "shade": Color(0.2, 0.17, 0.12), "beak": Color(0.9, 0.7, 0.25), "eye": Color(0.5, 1.0, 0.4)},
	},
	"kruk_wodz": {
		"name": "Kruk Wódz", "title": "Dowódca Czarnego Marszu", "species": "kruk", "scale": 2.4, "hp": 2300.0, "dmg": 30.0, "speed": 128.0,
		"xp": 780, "gold": 460, "defense": 0.16,
		"phases": [
			{"at": 1.0, "attacks": ["charge", "feather_fan", "swipe_combo", "dive"], "cd": [1.0, 1.5], "speed": 1.0},
			{"at": 0.6, "attacks": ["ring_wave", "charge", "dive", "lightning"], "cd": [0.85, 1.3], "speed": 1.15, "name": "WÓDZ WZYWA CAŁĄ ARMIĘ"},
			{"at": 0.25, "attacks": ["beam_storm", "charge", "summon", "dive"], "cd": [0.7, 1.1], "speed": 1.3, "adds": 3, "name": "SZAŁ WODZA"},
		],
		"intro": [["Kruk Wódz", "Przy tej bramie twoja podróż się kończy!"]],
		"death": [["Kruk Wódz", "Brama... runęła. Ale w środku czeka On."]],
		"reward": {"gold": 380, "items": {"sztabka_kurczalu": 3}},
		"pal": {"body": Color(0.13, 0.12, 0.17), "shade": Color(0.06, 0.06, 0.09), "comb": Color(0.6, 0.1, 0.12), "beak": Color(0.65, 0.65, 0.7), "eye": Color(1.0, 0.4, 0.1)},
	},
	"czarny_kruk": {
		"name": "Czarny Kruk", "title": "Władca Czarnych Skrzydeł", "species": "krol_krukow", "scale": 2.8, "hp": 5000.0, "dmg": 30.0, "speed": 140.0,
		"xp": 1800, "gold": 1000, "defense": 0.18, "vuln_bonus": 0.3,
		"phases": [
			{"at": 1.0, "attacks": ["swipe_combo", "feather_fan", "dive", "ground_pound"], "cd": [1.0, 1.5], "speed": 1.0},
			{"at": 0.68, "attacks": ["ring_wave", "charge", "feather_fan", "summon", "lightning"], "cd": [0.85, 1.3], "speed": 1.15, "adds": 4, "name": "FAZA II — PIEŚŃ CIENIA"},
			{"at": 0.34, "attacks": ["beam_storm", "dive", "ring_wave", "lightning", "charge"], "cd": [0.7, 1.1], "speed": 1.3, "adds": 3, "name": "FAZA III — BURZA MROKU"},
			{"at": 0.12, "attacks": ["beam_storm", "dive", "charge", "lightning", "ring_wave", "feather_fan"], "cd": [0.55, 0.9], "speed": 1.45, "name": "FAZA IV — FURIA KRUKA"},
		],
		"intro": [
			["Czarny Kruk", "Więc to ty. Kurczak, który śmiał zakłócić moje żniwa."],
			["Czarny Kruk", "Wszystko, co kochasz, spłonęło. Teraz dołączysz do popiołów!"],
		],
		"death": [
			["Czarny Kruk", "Niemożliwe... Skrzydła Mroku... nie mogą upaść."],
			["Czarny Kruk", "To nie koniec, kurczaku. Wrócę z własnym stadem... a wtedy odbiorę wszystko."],
		],
		"reward": {"gold": 800, "items": {"wzorzec_czarka": 1, "pazur_czarnego_kruka": 1, "sztabka_kurczalu": 5, "krysztal_cienia": 3}},
		"pal": {"body": Color(0.09, 0.08, 0.13), "shade": Color(0.04, 0.03, 0.07), "comb": Color(0.7, 0.1, 0.2), "beak": Color(0.75, 0.7, 0.5), "eye": Color(1.0, 0.25, 0.1)},
	},
	"cien_kruka": {
		"name": "Cień Kruka", "title": "Echo Mroku", "species": "krol_krukow", "scale": 2.3, "hp": 2800.0, "dmg": 32.0, "speed": 135.0,
		"xp": 900, "gold": 520, "defense": 0.16,
		"phases": [
			{"at": 1.0, "attacks": ["dive", "beam_storm", "swipe_combo"], "cd": [1.0, 1.5], "speed": 1.0},
			{"at": 0.5, "attacks": ["summon", "dive", "beam_storm", "ring_wave"], "cd": [0.8, 1.2], "speed": 1.25, "adds": 3, "name": "CIEŃ SIĘ ROZDZIERA"},
		],
		"intro": [["Cień Kruka", "Jestem wszystkim, czego Czarny Kruk się wyrzekł."]],
		"death": [["Cień Kruka", "Rozpływam się... ale mrok pozostaje."]],
		"reward": {"gold": 420, "items": {"sztabka_kurczalu": 3}},
		"pal": {"body": Color(0.06, 0.05, 0.1), "shade": Color(0.02, 0.02, 0.05), "comb": Color(0.45, 0.2, 0.8), "beak": Color(0.5, 0.4, 0.7), "eye": Color(0.7, 0.4, 1.0)},
	},
	"kanclerz_sepik": {
		"name": "Kanclerz Sępik", "title": "Szara Eminencja", "species": "sep", "scale": 2.3, "hp": 3200.0, "dmg": 34.0, "speed": 125.0,
		"xp": 1000, "gold": 560, "defense": 0.18,
		"phases": [
			{"at": 1.0, "attacks": ["lightning", "ring_wave", "swipe_combo"], "cd": [1.0, 1.5], "speed": 1.0},
			{"at": 0.5, "attacks": ["summon", "lightning", "ring_wave", "charge"], "cd": [0.8, 1.2], "speed": 1.2, "adds": 4, "name": "INTRYGA PĘKA"},
		],
		"intro": [["Kanclerz Sępik", "Korona powinna należeć do kogoś, kto potrafi liczyć. Do mnie."]],
		"death": [["Kanclerz Sępik", "Moje rachunki... nie zgadzały się... od początku."]],
		"reward": {"gold": 500, "items": {"sztabka_kurczalu": 3, "krysztal_cienia": 2}},
		"pal": {"body": Color(0.45, 0.4, 0.34), "shade": Color(0.28, 0.24, 0.2), "beak": Color(0.8, 0.7, 0.3), "eye": Color(0.9, 0.85, 0.3)},
	},
	"sep_zwiadowca": {
		"name": "Sęp Zwiadowca", "title": "Pan Pustynnych Szlaków", "species": "sep", "scale": 2.3, "hp": 3600.0, "dmg": 36.0, "speed": 140.0,
		"xp": 1100, "gold": 620, "defense": 0.18,
		"phases": [
			{"at": 1.0, "attacks": ["charge", "dive", "feather_fan"], "cd": [1.0, 1.5], "speed": 1.0},
			{"at": 0.5, "attacks": ["charge", "dive", "ring_wave", "lightning"], "cd": [0.75, 1.2], "speed": 1.3, "name": "BURZA PIASKOWA"},
		],
		"intro": [["Sęp Zwiadowca", "Pustynia zjada słabych. Ty wyglądasz na przekąskę."]],
		"death": [["Sęp Zwiadowca", "Piach... wszystko pochłonie."]],
		"reward": {"gold": 540, "items": {"sztabka_kurczalu": 3}},
		"pal": {"body": Color(0.62, 0.5, 0.35), "shade": Color(0.4, 0.3, 0.2), "beak": Color(0.9, 0.7, 0.3), "eye": Color(1.0, 0.8, 0.2)},
	},
	"wieszczka_sowa": {
		"name": "Wieszczka Sowa", "title": "Głos Burzy", "species": "sowa_wieszczka", "scale": 2.5, "hp": 4000.0, "dmg": 38.0, "speed": 120.0,
		"xp": 1250, "gold": 700, "defense": 0.2,
		"phases": [
			{"at": 1.0, "attacks": ["lightning", "beam_storm", "feather_fan"], "cd": [1.0, 1.5], "speed": 1.0},
			{"at": 0.55, "attacks": ["beam_storm", "ring_wave", "lightning", "summon"], "cd": [0.8, 1.2], "speed": 1.2, "adds": 3, "name": "BURZA WIESZCZEK"},
			{"at": 0.25, "attacks": ["beam_storm", "ring_wave", "lightning", "dive"], "cd": [0.6, 1.0], "speed": 1.35, "name": "OKO BURZY"},
		],
		"intro": [["Wieszczka Sowa", "Widziałam twój koniec w piorunach, kurczaku. Mimo to, spróbuj."]],
		"death": [["Wieszczka Sowa", "Przepowiednia... była niepełna."]],
		"reward": {"gold": 640, "items": {"sztabka_kurczalium": 1, "eliksir_mocy": 2}},
		"pal": {"body": Color(0.55, 0.52, 0.62), "shade": Color(0.32, 0.3, 0.42), "beak": Color(0.95, 0.8, 0.3), "eye": Color(0.6, 0.8, 1.0)},
	},
	"cesarz_sepow": {
		"name": "Cesarz Sępów", "title": "Pan Wszystkich Stad", "species": "sep_cesarski", "scale": 2.7, "hp": 5500.0, "dmg": 40.0, "speed": 135.0,
		"xp": 1800, "gold": 1000, "defense": 0.2, "vuln_bonus": 0.3,
		"phases": [
			{"at": 1.0, "attacks": ["swipe_combo", "charge", "ground_pound", "feather_fan"], "cd": [0.95, 1.4], "speed": 1.0},
			{"at": 0.7, "attacks": ["ring_wave", "dive", "summon", "lightning"], "cd": [0.8, 1.2], "speed": 1.2, "adds": 4, "name": "CESARSKA GWARDIA"},
			{"at": 0.4, "attacks": ["beam_storm", "dive", "charge", "ring_wave", "lightning"], "cd": [0.65, 1.0], "speed": 1.35, "adds": 3, "name": "GNIEW CESARZA"},
			{"at": 0.15, "attacks": ["beam_storm", "dive", "charge", "lightning", "ring_wave", "feather_fan"], "cd": [0.5, 0.85], "speed": 1.5, "name": "OSTATNI ŚWIT"},
		],
		"intro": [["Cesarz Sępów", "Klęknij, kurczaku. Ten świat należy do tych, którzy żywią się upadłymi."]],
		"death": [["Cesarz Sępów", "Świt... naprawdę... nadchodzi."]],
		"reward": {"gold": 900, "items": {"wzorzec_kurczak": 1, "sztabka_kurczalium": 1, "pazur_czarnego_kruka": 1}},
		"pal": {"body": Color(0.25, 0.18, 0.12), "shade": Color(0.12, 0.08, 0.06), "comb": Color(0.9, 0.7, 0.2), "beak": Color(0.95, 0.75, 0.25), "eye": Color(1.0, 0.5, 0.15)},
	},
}

## Boss rozdziału (id strefy → id bossa).
static var LIST: Dictionary = BASE_LIST.merged(Act2DB.BOSSES).merged(CaveBossDB.LIST)

const BASE_BY_ZONE := {
	"obrona_wioski": "hrabia_sroka",
	"droga_do_stolicy": "herold_kruka",
	"atak_na_stolice": "kapitan_zdrajcow",
	"uwolnij_krolowa": "dowodca_strazy",
	"trojka_prob": "lesny_straznik",
	"marsz_na_forteca": "kruk_wodz",
	"krol_i_kruk": "czarny_kruk",
	"cien_w_popiele": "cien_kruka",
	"zdrada_w_koronie": "kanclerz_sepik",
	"pustynny_trakt": "sep_zwiadowca",
	"gniazdo_nad_burza": "wieszczka_sowa",
	"ostatni_swit": "cesarz_sepow",
}

static var BY_ZONE: Dictionary = BASE_BY_ZONE.merged(Act2DB.BOSS_BY_ZONE)

static func get_data(id: String) -> Dictionary:
	return LIST.get(id, {})

static func has(id: String) -> bool:
	return LIST.has(id)

static func for_zone(zone_id: String) -> String:
	return String(BY_ZONE.get(zone_id, ""))
