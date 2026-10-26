class_name PlaceDB
extends RefCounted
## Miejsca na mapie świata: nazwa, położenie (0–1 na mapie) i rodzaj ikony dla każdego etapu kampanii.
## Kolejność = kolejność rozdziałów w QuestDB. Etapy pałacu tworzą wieżę na mapie.

const PLACES := {
	"obrona_wioski": {"name": "Twoja osada", "pos": Vector2(0.05, 0.80), "kind": "village", "label": true},
	"droga_do_stolicy": {"name": "Trakt do stolicy", "pos": Vector2(0.115, 0.72), "kind": "road", "label": true},
	"atak_na_stolice": {"name": "Stolica", "pos": Vector2(0.185, 0.64), "kind": "city", "label": true},
	"palac_1": {"name": "Pałac — hol", "pos": Vector2(0.245, 0.58), "kind": "tower", "label": true},
	"palac_2": {"name": "Pałac — biblioteka", "pos": Vector2(0.262, 0.535), "kind": "tower", "label": false},
	"palac_3": {"name": "Pałac — sala bankietowa", "pos": Vector2(0.279, 0.49), "kind": "tower", "label": false},
	"palac_4": {"name": "Pałac — galeria", "pos": Vector2(0.296, 0.445), "kind": "tower", "label": false},
	"palac_5": {"name": "Pałac — kaplica", "pos": Vector2(0.313, 0.40), "kind": "tower", "label": false},
	"uwolnij_krolowa": {"name": "Wieża królowej", "pos": Vector2(0.33, 0.355), "kind": "tower", "label": true},
	"narada_wojenna": {"name": "Sala narad", "pos": Vector2(0.385, 0.30), "kind": "castle", "label": true},
	"uwolnij_krola": {"name": "Loch pod pałacem", "pos": Vector2(0.37, 0.52), "kind": "cave", "label": true},
	"trojka_prob": {"name": "Gaj Cieni", "pos": Vector2(0.43, 0.68), "kind": "forest", "label": true},
	"marsz_na_forteca": {"name": "Twierdza Kruka", "pos": Vector2(0.50, 0.56), "kind": "castle", "label": true},
	"twierdza_1": {"name": "Twierdza — mury", "pos": Vector2(0.52, 0.535), "kind": "castle", "label": false},
	"twierdza_2": {"name": "Twierdza — koszary", "pos": Vector2(0.54, 0.495), "kind": "castle", "label": false},
	"miasto_kruka": {"name": "Miasto Kruka", "pos": Vector2(0.575, 0.43), "kind": "city", "label": true},
	"zamek_1": {"name": "Zamek — dziedziniec", "pos": Vector2(0.595, 0.385), "kind": "castle", "label": false},
	"zamek_2": {"name": "Zamek — krużganki", "pos": Vector2(0.615, 0.355), "kind": "castle", "label": false},
	"zamek_3": {"name": "Zamek — wieża generałów", "pos": Vector2(0.63, 0.33), "kind": "tower", "label": false},
	"zamek_kruka": {"name": "Zamek Kruka", "pos": Vector2(0.645, 0.31), "kind": "castle", "label": true},
	"krol_i_kruk": {"name": "Sala tronowa", "pos": Vector2(0.715, 0.20), "kind": "castle", "label": true},
	"akt2_zielonka": {"name": "Zielonka", "pos": Vector2(0.50, 0.84), "kind": "village", "label": true},
	"akt2_mlynowka": {"name": "Młynówka", "pos": Vector2(0.575, 0.89), "kind": "village", "label": true},
	"akt2_bagniska": {"name": "Bagniska", "pos": Vector2(0.65, 0.85), "kind": "village", "label": true},
	"akt2_wzgorze": {"name": "Wzgórze Wron", "pos": Vector2(0.725, 0.79), "kind": "village", "label": true},
	"akt2_dymiaca": {"name": "Dymiąca Wioska", "pos": Vector2(0.795, 0.70), "kind": "village", "label": true},
	"akt2_gniazdo": {"name": "Gniazdo Kruka", "pos": Vector2(0.85, 0.60), "kind": "castle", "label": true},
	"cien_w_popiele": {"name": "Popielna Forteca", "pos": Vector2(0.86, 0.47), "kind": "castle", "label": true},
	"zdrada_w_koronie": {"name": "Pałac Zdrajców", "pos": Vector2(0.90, 0.38), "kind": "city", "label": true},
	"pustynny_trakt": {"name": "Pustynny trakt", "pos": Vector2(0.935, 0.28), "kind": "road", "label": true},
	"gniazdo_nad_burza": {"name": "Gniazdo nad burzą", "pos": Vector2(0.955, 0.17), "kind": "tower", "label": true},
	"ostatni_swit": {"name": "Sala Świtu", "pos": Vector2(0.90, 0.09), "kind": "castle", "label": true},
}

static func of(chapter_id: String) -> Dictionary:
	return PLACES.get(chapter_id, {"name": chapter_id, "pos": Vector2(0.5, 0.5), "kind": "village", "label": true})

static func name_of(chapter_index: int) -> String:
	return String(of(String(QuestDB.chapter(chapter_index).get("id", ""))).get("name", "?"))

## Etapy, przez które przejdziesz (bez celu): od sąsiedniego po przedostatni w kierunku celu.
static func route(from_idx: int, to_idx: int) -> Array:
	var out: Array = []
	if from_idx == to_idx:
		return out
	var step := 1 if to_idx > from_idx else -1
	var i := from_idx + step
	while i != to_idx:
		out.append(i)
		i += step
	return out
