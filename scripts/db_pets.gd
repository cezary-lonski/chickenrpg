class_name PetDB
extends RefCounted
## Towarzysze. Każdy ma inną rolę: strzelec, zbieracz, łowca, uzdrowiciel, obrońca.
## role: shooter (jaja przepiórcze z dystansu), looter (przyciąga łupy i zbiera złoto),
## hunter (szybki atak w zwarciu), healer (leczy właściciela), tank (redukuje obrażenia).

const LIST := {
	"kurczaczek": {
		"name": "Kurczaczek", "role": "shooter", "species": "kwoka", "scale": 0.5,
		"desc": "Dzielny pisklak. Obrzuca wrogów jajkami przepiórczymi z bezpiecznej odległości.",
		"pal": {"body": Color(0.99, 0.93, 0.62), "shade": Color(0.9, 0.78, 0.4), "comb": Color(0.9, 0.3, 0.25), "beak": Color(0.98, 0.65, 0.15), "leg": Color(0.95, 0.7, 0.2)},
		"dmg": 8.0, "cd": 1.1, "range": 380.0, "speed": 230.0,
	},
	"wiewiorka_zbieracz": {
		"name": "Wiewiórka-zbieraczka", "role": "looter", "species": "wrzos", "scale": 0.55,
		"desc": "Zwinna zbieraczka. Przyciąga łupy z daleka i podrzuca odrobinę złota.",
		"pal": {"body": Color(0.78, 0.45, 0.22), "shade": Color(0.6, 0.32, 0.15), "beak": Color(0.2, 0.12, 0.08), "leg": Color(0.5, 0.3, 0.15)},
		"dmg": 3.0, "cd": 1.6, "range": 220.0, "speed": 260.0, "magnet": 520.0,
	},
	"lis_lowca": {
		"name": "Lis-łowca", "role": "hunter", "species": "sokol", "scale": 0.6,
		"desc": "Szybki myśliwy. Doskakuje do wrogów i tnie pazurami.",
		"pal": {"body": Color(0.92, 0.5, 0.2), "shade": Color(0.75, 0.38, 0.14), "beak": Color(0.15, 0.1, 0.1), "leg": Color(0.2, 0.15, 0.12)},
		"dmg": 14.0, "cd": 0.8, "range": 260.0, "speed": 300.0, "melee": true,
	},
	"sowka_uzdrowicielka": {
		"name": "Sówka-uzdrowicielka", "role": "healer", "species": "sowa", "scale": 0.45,
		"desc": "Mądra sówka. Co kilka sekund uleczy Cię pióropuszem świetlistego pyłu.",
		"pal": {"body": Color(0.85, 0.82, 0.72), "shade": Color(0.65, 0.6, 0.5), "beak": Color(0.95, 0.75, 0.2), "leg": Color(0.9, 0.7, 0.2)},
		"dmg": 0.0, "cd": 3.5, "range": 300.0, "speed": 230.0, "heal": 14.0,
	},
	"puchacz_zwiadowca": {
		"name": "Puchacz-zwiadowca", "role": "shooter", "species": "puchacz", "scale": 0.5,
		"desc": "Nocny zwiadowca. Z dużej odległości obrzuca wrogów jajkami i zdobywa przewagę.",
		"pal": {"body": Color(0.55, 0.45, 0.33), "shade": Color(0.35, 0.28, 0.2), "beak": Color(0.95, 0.75, 0.25), "leg": Color(0.8, 0.65, 0.25)},
		"dmg": 12.0, "cd": 1.0, "range": 430.0, "speed": 240.0,
	},
	"zolw_tarczownik": {
		"name": "Żółw-tarczownik", "role": "tank", "species": "golab", "scale": 0.55,
		"desc": "Opancerzony towarzysz. Dopóki jest przy Tobie, otrzymujesz o 8% mniej obrażeń.",
		"pal": {"body": Color(0.35, 0.6, 0.35), "shade": Color(0.25, 0.45, 0.28), "beak": Color(0.8, 0.7, 0.3), "leg": Color(0.55, 0.45, 0.25)},
		"dmg": 4.0, "cd": 1.4, "range": 160.0, "speed": 180.0, "dr": 0.08,
	},
}

const ROLE_NAMES := {
	"shooter": "Strzelec", "looter": "Zbieracz", "hunter": "Łowca", "healer": "Uzdrowiciel", "tank": "Obrońca",
}

static func get_data(id: String) -> Dictionary:
	return LIST.get(id, {})

static func has(id: String) -> bool:
	return LIST.has(id)
