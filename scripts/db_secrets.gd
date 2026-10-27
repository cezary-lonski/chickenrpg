class_name SecretDB
extends RefCounted
## Skrzynie, ukryte skrzynie, dźwignie i sekretne jaskinie przypisane do stref.
## Stan (otwarte skrzynie, pociągnięte dźwignie, zaliczone jaskinie) trafia do profilu.

## Pozycje skrzyń są stałe względem mapy 2200×1500.
const CHESTS := {
	"obrona_wioski": [
		{"id": "a", "pos": Vector2(190, 860), "loot": {"mikstura_miodu": 2, "sztabka_zelaza": 2}, "gold": 60},
		{"id": "b", "pos": Vector2(2020, 300), "hidden": true, "loot": {"wzorzec_ucz": 1, "sztabka_kurczalu": 1, "krysztal_cienia": 1}, "gold": 90},
	],
	"droga_do_stolicy": [
		{"id": "a", "pos": Vector2(1100, 1380), "loot": {"wzorzec_raz": 1, "mikstura_miodu": 2, "sztabka_zelaza": 2, "wegiel": 2}, "gold": 80},
		{"id": "b", "pos": Vector2(1900, 250), "hidden": true, "loot": {"sztabka_kurczalu": 1, "luk_przepiorczy": 1}, "gold": 120},
	],
	"atak_na_stolice": [
		{"id": "a", "pos": Vector2(200, 1020), "loot": {"wzorzec_kura": 1, "sztabka_zelaza": 3, "eliksir_mocy": 1, "wegiel": 3}, "gold": 100},
		{"id": "b", "pos": Vector2(1100, 1000), "hidden": true, "loot": {"sztabka_kurczalu": 2}, "gold": 140},
	],
	"uwolnij_krolowa": [
		{"id": "a", "pos": Vector2(2000, 1060), "loot": {"mikstura_miodu": 3, "krysztal_cienia": 1}, "gold": 120},
	],
	"trojka_prob": [
		{"id": "a", "pos": Vector2(250, 1300), "loot": {"sztabka_kurczalu": 2, "mikstura_miodu": 2}, "gold": 130},
		{"id": "b", "pos": Vector2(2000, 250), "hidden": true, "loot": {"wzorzec_kurz": 1, "helm_zelazny": 1, "krysztal_cienia": 2}, "gold": 160},
	],
	"marsz_na_forteca": [
		{"id": "a", "pos": Vector2(1100, 1360), "loot": {"wzorzec_czar": 1, "sztabka_kurczalu": 2, "eliksir_mocy": 1, "wegiel": 3}, "gold": 150},
	],
	"krol_i_kruk": [
		{"id": "a", "pos": Vector2(250, 300), "loot": {"wzorzec_arka": 1, "sztabka_kurczalu": 3, "krysztal_cienia": 2, "wegiel": 4}, "gold": 220},
		{"id": "b", "pos": Vector2(1950, 1300), "hidden": true, "loot": {"buty_okute": 1, "sztabka_kurczalu": 2}, "gold": 260},
	],
	"cien_w_popiele": [
		{"id": "a", "pos": Vector2(300, 1250), "loot": {"wzorzec_kurza": 1, "sztabka_kurczalu": 2, "mikstura_miodu": 3, "wegiel": 4}, "gold": 200},
	],
	"zdrada_w_koronie": [
		{"id": "a", "pos": Vector2(1900, 1000), "loot": {"wzorzec_zakaz": 1, "sztabka_kurczalu": 3, "krysztal_cienia": 2}, "gold": 240},
	],
	"pustynny_trakt": [
		{"id": "a", "pos": Vector2(1000, 300), "loot": {"sztabka_kurczalu": 2, "kolczuga_pupila": 1}, "gold": 260},
	],
	"gniazdo_nad_burza": [
		{"id": "a", "pos": Vector2(2000, 1250), "loot": {"sztabka_kurczalu": 4}, "gold": 300},
	],
	"ostatni_swit": [
		{"id": "a", "pos": Vector2(200, 1280), "loot": {"sztabka_kurczalium": 2, "eliksir_mocy": 2}, "gold": 400},
	],
	"akt2_zielonka": [
		{"id": "a", "pos": Vector2(220, 900), "loot": {"mikstura_miodu": 3, "wegiel": 2}, "gold": 140},
		{"id": "b", "pos": Vector2(2000, 1280), "hidden": true, "loot": {"sztabka_kurczalu": 2}, "gold": 200},
	],
	"akt2_mlynowka": [
		{"id": "a", "pos": Vector2(1500, 1380), "loot": {"sztabka_kurczalu": 2, "wegiel": 3}, "gold": 160},
	],
	"akt2_bagniska": [
		{"id": "a", "pos": Vector2(250, 1300), "loot": {"krysztal_cienia": 2, "wegiel": 3}, "gold": 180},
		{"id": "b", "pos": Vector2(1950, 300), "hidden": true, "loot": {"sztabka_kurczalu": 3}, "gold": 240},
	],
	"akt2_wzgorze": [
		{"id": "a", "pos": Vector2(2000, 1050), "loot": {"eliksir_mocy": 1, "wegiel": 3}, "gold": 200},
	],
	"akt2_dymiaca": [
		{"id": "a", "pos": Vector2(1000, 300), "loot": {"sztabka_kurczalu": 3, "wegiel": 4}, "gold": 240},
		{"id": "b", "pos": Vector2(250, 1380), "hidden": true, "loot": {"krysztal_cienia": 2, "sztabka_kurczalu": 3}, "gold": 300},
	],
}

## Jaskinie: zone → cave. Wejście odsłania się po pociągnięciu 3 dźwigni.
const CAVES := {
	"obrona_wioski": {
		"id": "piwnica_mlyna", "name": "Piwnica Starego Młyna",
		"hint": "Na tablicy ktoś nabazgrał: „Trzy dźwignie rdzewieją na krańcach wsi. Pociągnij wszystkie, a ziemia ustąpi.”",
		"levers": [Vector2(210, 330), Vector2(2000, 520), Vector2(900, 1380)],
		"entrance": Vector2(1100, 215),
		"pet": "wiewiorka_zbieracz",
		"reward": {"items": {"amulet_zlotej_kury": 1, "sztabka_kurczalu": 2}, "gold": 200, "xp": 150},
		"waves": [
			{"enemies": [["sroka", 3], ["kawka", 2]], "name": "Strażnicy piwnicy", "elite": true},
			{"enemies": [["wrzos", 4], ["jastrzab", 2]], "name": "Łowcy ciemności", "elite": true},
		],
	},
	"atak_na_stolice": {
		"id": "katakumby", "name": "Katakumby Stolicy",
		"hint": "W ścianie wyryto: „Ci, co pociągną trzy dźwignie, usłyszą jęk kamienia. Reszta usłyszy tylko krzyk.”",
		"levers": [Vector2(300, 330), Vector2(1920, 340), Vector2(1100, 1390)],
		"entrance": Vector2(1100, 230),
		"pet": "lis_lowca",
		"reward": {"items": {"helm_krola": 1, "sztabka_kurczalu": 3, "krysztal_cienia": 2}, "gold": 320, "xp": 260},
		"waves": [
			{"enemies": [["kruk", 3], ["orzel_szarak", 1]], "name": "Warta katakumb", "elite": true},
			{"enemies": [["kruk", 3], ["bocian_gruby", 2]], "name": "Cisi zabójcy", "elite": true},
		],
	},
	"trojka_prob": {
		"id": "gaj_cieni", "name": "Gaj Cieni",
		"hint": "Pień sękatego drzewa szepcze: „Dźwignie ukryto w trzech kątach gaju. Ciągnij, a korzenie się rozstąpią.”",
		"levers": [Vector2(230, 330), Vector2(2000, 700), Vector2(1100, 1380)],
		"entrance": Vector2(1100, 205),
		"pet": "sowka_uzdrowicielka",
		"reward": {"items": {"buty_wichru": 1, "obroza_polowania": 1, "luk_cienia_kruka": 1, "sztabka_kurczalu": 2}, "gold": 360, "xp": 320},
		"waves": [
			{"enemies": [["jastrzab", 3], ["sokol", 3]], "name": "Cienie gaju", "elite": true},
			{"enemies": [["orzel_szarak", 2], ["jastrzab", 3]], "name": "Strażnicy korzeni", "elite": true},
		],
	},
	"marsz_na_forteca": {
		"id": "skarbiec_garnizonu", "name": "Skarbiec Garnizonu",
		"hint": "Na drogowskazie widać pazurem nabazgrane: „Trzy dźwignie. Trzy skrzydła. Jedna nagroda.”",
		"levers": [Vector2(260, 300), Vector2(1950, 330), Vector2(1100, 1380)],
		"entrance": Vector2(1100, 225),
		"pet": "",
		"reward": {"items": {"wzorzec_zakaz": 1, "szpon_burzy": 1, "luk_burzowy": 1, "sztabka_kurczalu": 3, "eliksir_mocy": 2}, "gold": 420, "xp": 380},
		"waves": [
			{"enemies": [["kruk", 4], ["orzel_szarak", 2]], "name": "Gwardia skarbca", "elite": true},
			{"enemies": [["bocian_gruby", 2], ["krol_krukow", 1]], "name": "Skarbnik Kruków", "elite": true},
		],
	},
	"cien_w_popiele": {
		"id": "popielna_krypta", "name": "Popielna Krypta",
		"hint": "W popiele widać ślady pazurów: „Ciągnij za trzy żelazne rączki, a krypta się otworzy.”",
		"levers": [Vector2(300, 1270), Vector2(1950, 1260), Vector2(1100, 330)],
		"entrance": Vector2(240, 220),
		"pet": "",
		"reward": {"items": {"wzorzec_czarka": 1, "zbroja_switu": 1, "sztabka_kurczalium": 2}, "gold": 480, "xp": 460, "learn_metal": "kurczalium"},
		"waves": [
			{"enemies": [["kruk", 4], ["wronszek", 4]], "name": "Popielni strażnicy", "elite": true},
			{"enemies": [["orzel_szarak", 3], ["bocian_gruby", 2]], "name": "Wartownicy krypty", "elite": true},
		],
	},
	"pustynny_trakt": {
		"id": "grota_piaskow", "name": "Grota Piasków",
		"hint": "Kamienny drogowskaz: „Trzy dźwignie pod piachem. Za nimi — schron starych bohaterów.”",
		"levers": [Vector2(300, 400), Vector2(1980, 450), Vector2(1100, 1360)],
		"entrance": Vector2(1100, 215),
		"pet": "zolw_tarczownik",
		"reward": {"items": {"wzorzec_kurza": 1, "amulet_feniksa": 1, "luk_zlotego_skowronka": 1, "sztabka_kurczalium": 2}, "gold": 520, "xp": 520},
		"waves": [
			{"enemies": [["sep", 3], ["kruk", 3]], "name": "Piaskowi łowcy", "elite": true},
			{"enemies": [["sep", 3], ["bocian_gruby", 2]], "name": "Strażnicy grobowca", "elite": true},
		],
	},
	"gniazdo_nad_burza": {
		"id": "oko_burzy", "name": "Oko Burzy",
		"hint": "Wiatr niesie szept: „Pociągnij trzy dźwignie, a burza ustąpi.”",
		"levers": [Vector2(250, 330), Vector2(1950, 330), Vector2(1100, 1390)],
		"entrance": Vector2(1100, 210),
		"pet": "",
		"reward": {"items": {"wzorzec_czarka": 1, "sztabka_kurczalium": 2, "eliksir_mocy": 3, "obroza_polowania": 1, "luk_z_kurczalium": 1, "luk_wschodzacego_slonca": 1}, "gold": 640, "xp": 620},
		"waves": [
			{"enemies": [["sep", 3], ["orzel_szarak", 3]], "name": "Burzowe skrzydła", "elite": true},
			{"enemies": [["sowa", 2], ["sep", 3]], "name": "Oko burzy", "elite": true},
		],
	},
	"akt2_zielonka": {
		"id": "piwnica_spichlerza", "name": "Piwnica Spichlerza",
		"hint": "Na ścianie stodoły wyskrobano pazurem: „Trzy zardzewiałe dźwignie, jedno ukryte przejście. Kruk o nim nie wie.”",
		"levers": [Vector2(220, 340), Vector2(1980, 560), Vector2(1100, 1390)],
		"entrance": Vector2(1100, 220),
		"pet": "puchacz_zwiadowca",
		"reward": {"items": {"helm_krukobojcy": 1, "sztabka_kurczalu": 3, "wegiel": 3}, "gold": 450, "xp": 500},
		"waves": [
			{"enemies": [["wrona_pikinier", 3], ["wrona_lucznik", 2]], "name": "Strażnicy piwnicy", "elite": true},
			{"enemies": [["kruk_rzeznik", 2], ["jaskolka_zwiadowca", 3]], "name": "Rzeźnicy spichlerza", "elite": true},
		],
	},
	"akt2_mlynowka": {
		"id": "tunel_mlynarzy", "name": "Tunel Młynarzy",
		"hint": "Pod żarnami wyryto: „Młynarze kopali tunel przez trzy noce. Trzy dźwignie otwierają drzwi.”",
		"levers": [Vector2(300, 420), Vector2(1950, 380), Vector2(1100, 1370)],
		"entrance": Vector2(1100, 215),
		"pet": "",
		"reward": {"items": {"amulet_zemsty": 1, "sztabka_kurczalu": 3, "krysztal_cienia": 2}, "gold": 520, "xp": 580},
		"waves": [
			{"enemies": [["wrona_pikinier", 4], ["jaskolka_zwiadowca", 3]], "name": "Wartownicy tunelu", "elite": true},
			{"enemies": [["kruk_rzeznik", 3], ["wrona_lucznik", 3]], "name": "Rzeźnicy z konwoju", "elite": true},
		],
	},
	"akt2_bagniska": {
		"id": "jaskinia_blotna", "name": "Jaskinia Błotna",
		"hint": "Na kładce ktoś wyciął w drewnie: „W mgle ukryto trzy dźwignie. Pociągnij je, a bagno odda skarb.”",
		"levers": [Vector2(250, 360), Vector2(2000, 700), Vector2(1100, 1380)],
		"entrance": Vector2(1100, 210),
		"pet": "",
		"reward": {"items": {"buty_cienia": 1, "sztabka_kurczalu": 3, "wegiel": 4}, "gold": 560, "xp": 620},
		"waves": [
			{"enemies": [["wrona_lucznik", 4], ["jaskolka_zwiadowca", 3]], "name": "Cienie bagien", "elite": true},
			{"enemies": [["kruk_rzeznik", 3], ["wrona_pikinier", 3]], "name": "Strażnicy mułu", "elite": true},
		],
	},
	"akt2_wzgorze": {
		"id": "krypta_wzgorza", "name": "Krypta Wzgórza",
		"hint": "Pod wieżą alarmową wyryto: „Trzy dźwignie strzegą krypty dowódców. Alarm ich nie obudzi.”",
		"levers": [Vector2(280, 330), Vector2(1960, 360), Vector2(1100, 1390)],
		"entrance": Vector2(1100, 225),
		"pet": "",
		"reward": {"items": {"szpon_burzy": 1, "sztabka_kurczalu": 4, "eliksir_mocy": 2}, "gold": 640, "xp": 700},
		"waves": [
			{"enemies": [["wrona_pikinier", 4], ["wrona_lucznik", 3]], "name": "Wartownicy krypty", "elite": true},
			{"enemies": [["kruk_rzeznik", 3], ["jaskolka_zwiadowca", 4]], "name": "Gwardia dowódców", "elite": true},
		],
	},
	"akt2_dymiaca": {
		"id": "piec_kowali", "name": "Piec Kowali",
		"hint": "Na kowadle wydrapano: „Prawdziwy piec ukryto pod kuźnią. Trzy dźwignie go rozpalą.”",
		"levers": [Vector2(300, 1270), Vector2(1950, 1260), Vector2(1100, 330)],
		"entrance": Vector2(240, 220),
		"pet": "",
		"reward": {"items": {"sztabka_kurczalium": 2, "zbroja_switu": 1, "wegiel": 5}, "gold": 720, "xp": 780},
		"waves": [
			{"enemies": [["kruk_rzeznik", 3], ["wrona_pikinier", 3]], "name": "Strażnicy pieca", "elite": true},
			{"enemies": [["wrona_lucznik", 4], ["kruk_rzeznik", 2], ["jaskolka_zwiadowca", 3]], "name": "Młoty i pióra", "elite": true},
		],
	},
	"akt2_gniazdo": {
		"id": "podziemia_gniazda", "name": "Podziemia Gniazda",
		"hint": "W skale wypalono ostrzeżenie: „Trzy dźwignie. Za nimi — to, czego nawet Kruk się boi.”",
		"levers": [Vector2(270, 340), Vector2(1950, 340), Vector2(1100, 1390)],
		"entrance": Vector2(1100, 210),
		"pet": "",
		"reward": {"items": {"wzorzec_kurczak": 1, "sztabka_kurczalium": 2, "amulet_feniksa": 1, "eliksir_mocy": 3}, "gold": 900, "xp": 900},
		"waves": [
			{"enemies": [["kruk_rzeznik", 4], ["wrona_pikinier", 3]], "name": "Straż podziemi", "elite": true},
			{"enemies": [["kruk_rzeznik", 3], ["wrona_lucznik", 4], ["jaskolka_zwiadowca", 3]], "name": "Cienie Kruka", "elite": true},
		],
	},
}

## Laboratoria (wytwarzanie BU i kurczalium) w wybranych strefach.
const LABS := {
	"atak_na_stolice": Vector2(1560, 330),
	"marsz_na_forteca": Vector2(1560, 330),
	"cien_w_popiele": Vector2(1560, 330),
	"pustynny_trakt": Vector2(1560, 330),
	"akt2_mlynowka": Vector2(1560, 330),
	"akt2_dymiaca": Vector2(1560, 330),
	"akt2_gniazdo": Vector2(1560, 330),
}

static func lab_for(zone_id: String) -> Variant:
	return LABS.get(zone_id, null)

static func chests_for(zone_id: String) -> Array:
	return CHESTS.get(zone_id, [])

static func cave_for(zone_id: String) -> Dictionary:
	return CAVES.get(zone_id, {})

static func cave_by_id(cave_id: String) -> Dictionary:
	for z in CAVES:
		if String(CAVES[z]["id"]) == cave_id:
			var c: Dictionary = CAVES[z].duplicate(true)
			c["zone"] = z
			return c
	return {}

## Strefa-jaskinia w formacie ZoneDB (obsługiwana przez Village).
## Punkty zasadzek w jaskini: po jednym na watahę (wpis fali), z dala od wejścia i od siebie nawzajem.
static func ambush_centers(count: int, size: Vector2, margin: float, start: Vector2, rng: RandomNumberGenerator) -> Array:
	var out: Array = []
	var tries := 0
	while out.size() < count and tries < 400:
		tries += 1
		var p := Vector2(rng.randf_range(margin + 160.0, size.x - margin - 160.0), rng.randf_range(margin + 160.0, size.y - margin - 160.0))
		var min_gap := 520.0 if tries < 200 else 320.0
		var ok := p.distance_to(start) > 650.0
		for q in out:
			if p.distance_to(q) < min_gap:
				ok = false
		if ok:
			out.append(p)
	while out.size() < count:
		out.append(Vector2(rng.randf_range(margin + 160.0, size.x - margin - 160.0), margin + 200.0))
	return out

static func cave_zone(cave_id: String) -> Dictionary:
	var c := cave_by_id(cave_id)
	if c.is_empty():
		return {}
	return {
		"terrain": "cave",
		"spawn": Vector2(1100, 1280),
		"npcs": [],
		"giver": "",
		"cave": true,
		"cave_id": cave_id,
		"waves": c["waves"],
		"intro_banner": ["SEKRETNA JASKINIA", String(c["name"])],
		"outro_banner": ["JASKINIA OCZYSZCZONA", String(c["name"])],
	}

# ------------------------------------------------------------- stan w profilu ---

static func _secrets() -> Dictionary:
	if not (GameState.profile.get("secrets") is Dictionary):
		GameState.profile["secrets"] = {"found": [], "chests": []}
	var s: Dictionary = GameState.profile["secrets"]
	if not (s.get("found") is Array): s["found"] = []
	if not (s.get("chests") is Array): s["chests"] = []
	if not (s.get("levers") is Dictionary): s["levers"] = {}
	return s

static func chest_opened(uid: String) -> bool:
	return uid in _secrets()["chests"]

static func mark_chest(uid: String) -> void:
	var s := _secrets()
	if uid not in s["chests"]:
		s["chests"].append(uid)
	GameState.save_game()

static func cave_done(cave_id: String) -> bool:
	return ("cave:" + cave_id) in _secrets()["found"]

static func mark_cave(cave_id: String) -> void:
	var s := _secrets()
	if ("cave:" + cave_id) not in s["found"]:
		s["found"].append("cave:" + cave_id)
	GameState.save_game()

static func levers_pulled(zone_id: String) -> Array:
	return _secrets()["levers"].get(zone_id, [])

static func pull_lever(zone_id: String, idx: int) -> void:
	var s := _secrets()
	var arr: Array = s["levers"].get(zone_id, [])
	if idx not in arr:
		arr.append(idx)
	s["levers"][zone_id] = arr
	GameState.save_game()

## Wydaje nagrody ({items, gold, xp, pet, learn_metal}) i zwraca listę linii do pokazania.
static func grant(loot: Dictionary) -> Array:
	var lines: Array = []
	var items: Dictionary = loot.get("items", loot) if loot.has("items") else {}
	for id in items:
		GameState.add_item(String(id), int(items[id]))
		lines.append("%s ×%d" % [String(ItemDB.get_data(String(id)).get("name", id)), int(items[id])])
	var dl := float(loot.get("diff_loot", 0.0))
	var lvl := int(GameState.diff_data()["loot"])
	while dl > 0.0:
		if randf() < dl:
			var gid := ItemsHard.roll(lvl)
			GameState.add_item(gid, 1)
			lines.append(String(ItemDB.get_data(gid).get("name", gid)))
		dl -= 1.0
	if int(loot.get("gold", 0)) > 0:
		GameState.add_gold(int(loot["gold"]))
		lines.append("%d złota" % int(loot["gold"]))
	if int(loot.get("xp", 0)) > 0:
		GameState.add_xp(int(loot["xp"]))
		lines.append("%d XP" % int(loot["xp"]))
	if String(loot.get("pet", "")) != "":
		if GameState.unlock_pet(String(loot["pet"])):
			lines.append("Nowy towarzysz: %s" % String(PetDB.get_data(String(loot["pet"])).get("name", "")))
	if String(loot.get("learn_metal", "")) != "":
		ForgeDB.learn_metal(String(loot["learn_metal"]))
		lines.append("Receptura: %s" % String(ForgeDB.METALS[String(loot["learn_metal"])]["name"]))
	return lines
