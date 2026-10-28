class_name ClassSkillDB
extends RefCounted
## Umiejętności i drzewka KAŻDEJ klasy osobno: wojownik (wo_), łucznik (lu_), fechmistrz (fe_), złodziej (zl_),
## mag (ma_) i lady (la_). Każda klasa ma własne, niepowtarzalne umiejętności z własnymi nazwami, kolorami
## i parametrami; sygnaturowe umiejętności klasy (SkillDB) są dostępne od początku i otwierają gałęzie.
## Skille korzystają z istniejących typów efektów (aoe, projectile, leap…), więc działają w grze i na serwerze.
## Wersja drzew (TREE_VERSION): po zmianie stare rozdanie punktów jest zerowane, a punkty wracają do puli.

const TREE_VERSION := 2

# [id, nazwa, typ, opis, koszt, cd, kolor, dodatkowe parametry]
const SKILLS := [
	# ---------------------------------------------------------------- Wojownik ---
	["wo_ciecie", "Cięcie Toporem", "aoe", "Szerokie cięcie wokół: ranni wrogowie lecą w tył.", 22.0, 4.0, Color(0.95, 0.5, 0.35), {"dmg": 38.0, "radius": 125.0, "kb": 380.0, "stun": 0.3}],
	["wo_miazdza", "Miażdżący Cios", "power_swing", "Jeden wielki zamach przed siebie, który odrzuca nawet ciężkich przeciwników.", 34.0, 8.0, Color(0.9, 0.4, 0.25), {"dmg": 85.0, "kb": 680.0, "range": 112.0}],
	["wo_rzeznik", "Pierścień Rzeźnika", "aoe", "Okrągłe uderzenie, które na chwilę ogłusza wszystkich wokół.", 38.0, 11.0, Color(0.85, 0.25, 0.2), {"dmg": 70.0, "radius": 195.0, "kb": 420.0, "stun": 0.8}],
	["wo_trzesienie", "Trzęsienie Ziemi", "aoe", "Uderzasz w ziemię, a cały plac drży i rozrzuca wrogów.", 55.0, 20.0, Color(0.7, 0.5, 0.3), {"dmg": 115.0, "radius": 270.0, "kb": 560.0, "stun": 1.0}],
	["wo_rzez", "Rzeź", "pirouette", "Wir ostrzy tnie wszystko, co stoi zbyt blisko.", 46.0, 14.0, Color(1.0, 0.3, 0.3), {"dmg": 100.0, "radius": 180.0}],
	["wo_tytan", "Wrzask Tytana", "titan", "Przez 12 s: +50% siły i o 35% mniejsze obrażenia.", 60.0, 60.0, Color(1.0, 0.45, 0.2), {"duration": 12.0, "strength": 0.5, "reduction": 0.35}],
	["wo_tarcza_kowala", "Tarcza Kowala", "iron_skin", "Przez 8 s otrzymujesz o 45% mniej obrażeń.", 26.0, 20.0, Color(0.65, 0.7, 0.8), {"duration": 8.0, "reduction": 0.45}],
	["wo_mur", "Mur Tarcz", "iron_skin", "Przez 5 s stajesz się murem: 70% mniej obrażeń.", 38.0, 28.0, Color(0.55, 0.7, 1.0), {"duration": 5.0, "reduction": 0.7}],
	["wo_byk", "Szarża Byka", "dash_strike", "Rozpędzasz się i taranujesz wszystko na drodze.", 24.0, 6.0, Color(0.9, 0.65, 0.35), {"dmg": 52.0}],
	["wo_podkowa", "Kopniak Podkowy", "dash_strike", "Krótki, szybki doskok z kopniakiem.", 14.0, 3.0, Color(0.85, 0.75, 0.4), {"dmg": 32.0}],
	["wo_skok", "Skok Ciężkozbrojnego", "leap", "Skaczesz w powietrze i lądujesz z hukiem.", 28.0, 10.0, Color(0.75, 0.8, 0.95), {"dist": 250.0, "dmg": 45.0, "radius": 125.0, "duration": 0.5}],
	["wo_okrzyk", "Okrzyk Bojowy", "buff", "Na 10 s: więcej siły i trochę szybkości.", 28.0, 22.0, Color(1.0, 0.75, 0.3), {"duration": 10.0, "strength": 0.4, "speed": 0.15}],
	["wo_ryk", "Ryk Przywódcy", "stun_all", "Ryk, który zatrzymuje wrogów w miejscu.", 34.0, 20.0, Color(0.95, 0.6, 0.3), {"duration": 1.8, "radius": 245.0}],
	["wo_rozkaz", "Rozkaz Szturmu", "pet_command", "Towarzysze atakują dwa razy szybciej przez 8 s.", 20.0, 16.0, Color(1.0, 0.85, 0.4), {"duration": 8.0}],
	["wo_weteran", "Opatrunek Weterana", "hot", "Opatrujesz rany: leczenie rozłożone na 7 s.", 22.0, 16.0, Color(0.5, 0.9, 0.55), {"heal": 70.0, "duration": 7.0}],

	# ------------------------------------------------------------------ Łucznik ---
	["lu_strzal", "Szybki Strzał", "projectile", "Błyskawiczna strzała bez zbędnego celowania.", 12.0, 2.0, Color(0.7, 0.95, 0.5), {"dmg": 22.0}],
	["lu_przebijajaca", "Strzała Przebijająca", "projectile", "Ciężka strzała o dużych obrażeniach.", 20.0, 4.0, Color(0.85, 0.85, 0.6), {"dmg": 44.0}],
	["lu_zapalajaca", "Strzała Zapalająca", "fire_zone", "Strzała zostawia płonące pole, które pali wrogów.", 30.0, 12.0, Color(1.0, 0.55, 0.2), {"dmg": 26.0, "radius": 130.0, "duration": 5.0}],
	["lu_deszcz", "Deszcz Strzał", "aoe", "Chmura strzał spada na wskazany obszar.", 42.0, 14.0, Color(0.6, 0.85, 0.5), {"dmg": 78.0, "radius": 210.0, "kb": 220.0, "stun": 0.3}],
	["lu_snajper", "Strzał Snajpera", "headshot", "Strzał, który zawsze trafia krytycznie.", 28.0, 8.0, Color(0.95, 0.9, 0.4), {"dmg": 90.0}],
	["lu_lawina", "Lawina Strzał", "triple_shot", "Wachlarz strzał rozchodzący się szeroko.", 36.0, 9.0, Color(0.5, 0.9, 0.55), {"dmg": 26.0, "spread": 30.0}],
	["lu_unik", "Zwinny Unik", "blink", "Przeskakujesz kilka kroków i na chwilę jesteś nietykalny.", 14.0, 5.0, Color(0.6, 0.9, 0.9), {"dist": 220.0, "duration": 0.35}],
	["lu_wzlot", "Wzlot Sokoła", "leap", "Wzbijasz się i lądujesz z falą uderzeniową.", 24.0, 9.0, Color(0.7, 0.95, 1.0), {"dist": 290.0, "dmg": 28.0, "radius": 100.0, "duration": 0.45}],
	["lu_kamuflaz", "Kamuflaż Myśliwego", "shadow", "Wtapiasz się w las: wrogowie cię nie widzą.", 24.0, 18.0, Color(0.35, 0.55, 0.35), {"duration": 4.0}],
	["lu_pulapka", "Pułapka Lodowa", "aoe", "Zamrażasz wrogów w miejscu na prawie 2 s.", 30.0, 12.0, Color(0.55, 0.85, 1.0), {"dmg": 20.0, "radius": 200.0, "kb": 40.0, "stun": 1.8}],
	["lu_blysk", "Błysk Oślepiający", "stun_all", "Rozbłysk oślepia wszystkich wokół.", 30.0, 18.0, Color(1.0, 1.0, 0.7), {"duration": 1.6, "radius": 230.0}],
	["lu_haslo", "Sygnał Łowcy", "pet_command", "Pupile atakują dwa razy szybciej.", 18.0, 16.0, Color(0.8, 0.95, 0.5), {"duration": 8.0}],
	["lu_okrzyk", "Szybkość Wiatru", "buff", "Na 8 s: duża szybkość i trochę siły.", 24.0, 20.0, Color(0.6, 0.95, 0.8), {"duration": 8.0, "strength": 0.1, "speed": 0.35}],
	["lu_ziola", "Leśne Zioła", "hot", "Opatrunek z ziół leczy przez 6 s.", 20.0, 15.0, Color(0.5, 0.9, 0.45), {"heal": 55.0, "duration": 6.0}],

	# -------------------------------------------------------------- Fechmistrz ---
	["fe_pchniecie", "Pchnięcie", "dash_strike", "Błyskawiczny wypad z ukłuciem w biegu.", 16.0, 3.5, Color(0.8, 0.9, 1.0), {"dmg": 36.0}],
	["fe_riposta", "Riposta", "dash_strike", "Ostry kontratak, który tnie przeciwnika w biegu.", 24.0, 6.0, Color(0.95, 0.85, 0.5), {"dmg": 58.0}],
	["fe_kolo", "Koło Szabli", "pirouette", "Szybki obrót raniący wszystko dookoła.", 24.0, 5.0, Color(0.75, 0.9, 1.0), {"dmg": 46.0, "radius": 130.0}],
	["fe_wir", "Wir Floretu", "pirouette", "Szeroki taniec ostrzy: duże obrażenia obszarowe.", 44.0, 14.0, Color(0.85, 0.95, 1.0), {"dmg": 95.0, "radius": 175.0}],
	["fe_cios_mistrza", "Cios Mistrza", "power_swing", "Precyzyjny, mocny cios przed siebie.", 30.0, 7.0, Color(1.0, 0.85, 0.4), {"dmg": 70.0, "kb": 380.0, "range": 100.0}],
	["fe_krok", "Krok Fechtunku", "blink", "Zwinny wykrok w bok i chwila nietykalności.", 12.0, 4.0, Color(0.7, 0.85, 1.0), {"dist": 190.0, "duration": 0.4}],
	["fe_tancerz", "Skok Tancerza", "leap", "Efektowny skok z lądowaniem na czubku szpady.", 24.0, 8.0, Color(0.9, 0.9, 1.0), {"dist": 270.0, "dmg": 36.0, "radius": 105.0, "duration": 0.45}],
	["fe_parada", "Parada", "iron_skin", "Przez 5 s odbijasz większość ciosów: 65% mniej obrażeń.", 26.0, 20.0, Color(0.7, 0.8, 1.0), {"duration": 5.0, "reduction": 0.65}],
	["fe_postawa", "Postawa Obronna", "iron_skin", "Przez 8 s: 40% mniej obrażeń.", 20.0, 18.0, Color(0.65, 0.75, 0.9), {"duration": 8.0, "reduction": 0.4}],
	["fe_zasieki", "Zasieki Szermierza", "barrier", "Przez 20 s potwory nie wchodzą w wyznaczony krąg.", 40.0, 35.0, Color(0.5, 0.95, 0.95), {"duration": 20.0, "radius": 140.0}],
	["fe_tempo", "Tempo Walki", "buff", "Na 8 s: szybszy ruch i mocniejsze ciosy.", 26.0, 18.0, Color(0.95, 0.9, 0.55), {"duration": 8.0, "strength": 0.25, "speed": 0.3}],
	["fe_zamroczenie", "Zamroczenie", "stun_all", "Oszałamiający pokaz sztuki wokół ciebie.", 32.0, 16.0, Color(0.85, 0.75, 1.0), {"duration": 1.7, "radius": 200.0}],
	["fe_bandaz", "Bandaż Pojedynkowicza", "hot", "Leczenie rozłożone na 6 s.", 20.0, 15.0, Color(0.55, 0.9, 0.6), {"heal": 55.0, "duration": 6.0}],
	["fe_mistrz", "Taniec Ostrzy", "pirouette", "Ostateczny wir ostrzy: ogromne obrażenia.", 55.0, 20.0, Color(1.0, 1.0, 1.0), {"dmg": 140.0, "radius": 190.0}],

	# ---------------------------------------------------------------- Złodziej ---
	["zl_noz", "Rzut Nożem", "projectile", "Szybki rzut nożem.", 10.0, 1.8, Color(0.8, 0.8, 0.9), {"dmg": 20.0}],
	["zl_wachlarz", "Wachlarz Noży", "triple_shot", "Trzy noże w wachlarzu.", 26.0, 6.0, Color(0.75, 0.75, 0.9), {"dmg": 18.0, "spread": 26.0}],
	["zl_cios_w_plecy", "Cios w Plecy", "headshot", "Zawsze krytyczne cięcie z zaskoczenia.", 24.0, 7.0, Color(0.65, 0.5, 0.8), {"dmg": 80.0}],
	["zl_doskok", "Doskok z Cienia", "dash_strike", "Błyskawiczny doskok z cięciem.", 18.0, 4.0, Color(0.5, 0.45, 0.7), {"dmg": 40.0}],
	["zl_mgla", "Mglisty Krok", "blink", "Rozpływasz się i pojawiasz kilka kroków dalej.", 12.0, 4.0, Color(0.7, 0.7, 0.9), {"dist": 230.0, "duration": 0.4}],
	["zl_skok", "Skok przez Mur", "leap", "Wskakujesz na przeciwnika od góry.", 22.0, 8.0, Color(0.6, 0.55, 0.8), {"dist": 280.0, "dmg": 34.0, "radius": 95.0, "duration": 0.45}],
	["zl_welon", "Welon Mroku", "shadow", "Dłuższa niewidzialność i nietykalność.", 30.0, 20.0, Color(0.3, 0.25, 0.45), {"duration": 6.0}],
	["zl_dym", "Bomba Dymna", "stun_all", "Chmura dymu dezorientuje wszystkich wokół.", 28.0, 14.0, Color(0.6, 0.6, 0.65), {"duration": 2.2, "radius": 220.0}],
	["zl_kwas", "Fiolka z Kwasem", "fire_zone", "Kwas wypala podłogę przez 5 s.", 28.0, 12.0, Color(0.6, 0.95, 0.4), {"dmg": 28.0, "radius": 120.0, "duration": 5.0}],
	["zl_haczyk", "Haczyk Pułapkowy", "aoe", "Pułapka rzuca wrogów w powietrze.", 30.0, 10.0, Color(0.9, 0.7, 0.4), {"dmg": 50.0, "radius": 160.0, "kb": 300.0, "stun": 1.0}],
	["zl_lupy", "Pochlebstwo Łupieżcy", "buff", "Na 8 s: szybsze ruchy i krytyki.", 22.0, 18.0, Color(0.95, 0.8, 0.4), {"duration": 8.0, "strength": 0.2, "speed": 0.3}],
	["zl_zasadzka", "Zasadzka", "pirouette", "Szybki wir sztyletów, kiedy ktoś się zbliży.", 30.0, 9.0, Color(0.7, 0.6, 0.9), {"dmg": 60.0, "radius": 130.0}],
	["zl_lek", "Sztuczki Medyka", "hot", "Leczenie rozłożone na 6 s.", 20.0, 15.0, Color(0.5, 0.85, 0.65), {"heal": 50.0, "duration": 6.0}],
	["zl_mistrz", "Taniec Sztyletów", "pirouette", "Najlepsza sztuczka: ogromne obrażenia dookoła.", 50.0, 18.0, Color(0.85, 0.8, 1.0), {"dmg": 125.0, "radius": 165.0}],

	# --------------------------------------------------------------------- Mag ---
	["ma_pocisk", "Magiczny Pocisk", "projectile", "Mały, szybki pocisk arkanów.", 10.0, 1.6, Color(0.75, 0.6, 1.0), {"dmg": 24.0}],
	["ma_kula_arkan", "Kula Arkanów", "projectile", "Potężna kula czystej magii.", 24.0, 4.0, Color(0.6, 0.45, 0.95), {"dmg": 52.0}],
	["ma_piorun", "Piorun", "projectile", "Błyskawica przed siebie.", 18.0, 3.0, Color(1.0, 0.95, 0.4), {"dmg": 38.0}],
	["ma_jad", "Zaklęcie Jadu", "fire_zone", "Trujące opary zostają w miejscu przez 6 s.", 28.0, 12.0, Color(0.5, 0.9, 0.35), {"dmg": 24.0, "radius": 140.0, "duration": 6.0}],
	["ma_burza_ognia", "Burza Ognia", "fire_zone", "Płonący krąg o dużym zasięgu.", 40.0, 16.0, Color(1.0, 0.5, 0.2), {"dmg": 38.0, "radius": 190.0, "duration": 5.0}],
	["ma_oslepienie", "Oślepienie", "stun_all", "Błysk oślepia wszystkich wokół.", 30.0, 16.0, Color(1.0, 0.95, 0.7), {"duration": 2.0, "radius": 240.0}],
	["ma_mroz", "Mroźny Pierścień", "aoe", "Lodowa fala zamraża wrogów w miejscu.", 32.0, 10.0, Color(0.55, 0.85, 1.0), {"dmg": 28.0, "radius": 215.0, "kb": 60.0, "stun": 1.9}],
	["ma_sztorm", "Sztorm Arkanów", "aoe", "Burza energii rozrywa wszystko dookoła.", 52.0, 18.0, Color(0.7, 0.4, 1.0), {"dmg": 105.0, "radius": 235.0, "kb": 420.0, "stun": 0.7}],
	["ma_kometa", "Kometa", "aoe", "Spada z nieba i miażdży całe skupisko.", 60.0, 22.0, Color(1.0, 0.7, 0.3), {"dmg": 135.0, "radius": 270.0, "kb": 520.0, "stun": 0.9}],
	["ma_teleport", "Teleport", "blink", "Natychmiast pojawiasz się kilka kroków dalej.", 14.0, 5.0, Color(0.75, 0.6, 1.0), {"dist": 250.0, "duration": 0.35}],
	["ma_bariera", "Bariera Arkanów", "shield", "Kopuła magii osłania drużynę.", 34.0, 18.0, Color(0.7, 0.6, 1.0), {"duration": 5.0, "radius": 200.0, "reduction": 0.55}],
	["ma_skora", "Skóra z Kamienia", "iron_skin", "Przez 7 s otrzymujesz o 50% mniej obrażeń.", 28.0, 22.0, Color(0.65, 0.6, 0.7), {"duration": 7.0, "reduction": 0.5}],
	["ma_medytacja", "Medytacja", "hot", "Leczenie rozłożone na 6 s.", 20.0, 15.0, Color(0.6, 0.85, 1.0), {"heal": 60.0, "duration": 6.0}],
	["ma_wzmocnienie", "Wzmocnienie Arkanów", "buff", "Na 10 s: mocniejsze czary i szybszy ruch.", 30.0, 22.0, Color(0.8, 0.65, 1.0), {"duration": 10.0, "strength": 0.35, "speed": 0.1}],

	# -------------------------------------------------------------------- Lady ---
	["la_iskra", "Iskra Światła", "projectile", "Mały pocisk światła do obrony.", 12.0, 2.2, Color(1.0, 0.95, 0.7), {"dmg": 20.0}],
	["la_opieka", "Troskliwa Dłoń", "hot", "Leczenie rozłożone na 6 s.", 20.0, 12.0, Color(0.5, 0.95, 0.6), {"heal": 65.0, "duration": 6.0}],
	["la_krag_zdrowia", "Krąg Zdrowia", "heal", "Strefa leczenia na 6 s.", 40.0, 14.0, Color(0.45, 0.95, 0.6), {"heal": 42.0, "radius": 230.0, "duration": 6.0}],
	["la_zew", "Zew Wsparcia", "rally", "Leczy sojuszników i wzmacnia ich siłę.", 38.0, 20.0, Color(1.0, 0.8, 0.9), {"heal": 45.0, "radius": 270.0, "duration": 6.0, "strength": 0.25}],
	["la_blogoslawienstwo", "Błogosławieństwo", "buff", "Drużyna zyskuje siłę i szybkość na 10 s.", 40.0, 30.0, Color(1.0, 0.9, 0.6), {"duration": 10.0, "strength": 0.3, "speed": 0.2}],
	["la_oslona", "Osłona Dłoni", "shield", "Kopuła chroni sojuszników: 50% mniej obrażeń.", 30.0, 14.0, Color(0.85, 0.9, 1.0), {"duration": 5.0, "radius": 220.0, "reduction": 0.5}],
	["la_twierdza", "Twierdza Światła", "shield", "Duża kopuła: 70% mniej obrażeń, krócej.", 46.0, 26.0, Color(1.0, 1.0, 0.85), {"duration": 4.0, "radius": 270.0, "reduction": 0.7}],
	["la_ochrona", "Łaska Pupila", "pet_guard", "Pupile dostają wzmocnioną ochronę.", 24.0, 22.0, Color(0.95, 0.8, 0.5), {"duration": 8.0}],
	["la_zew_pupili", "Zew Pupili", "pet_command", "Pupile atakują dwa razy szybciej.", 20.0, 16.0, Color(1.0, 0.85, 0.4), {"duration": 8.0}],
	["la_blask", "Błysk Łaski", "stun_all", "Jasny błysk zatrzymuje wrogów.", 34.0, 18.0, Color(1.0, 0.95, 0.75), {"duration": 2.4, "radius": 220.0}],
	["la_gniew", "Gniew Pani", "aoe", "Fala jasności odpycha wrogów od drużyny.", 34.0, 12.0, Color(1.0, 0.8, 0.85), {"dmg": 48.0, "radius": 190.0, "kb": 450.0, "stun": 0.6}],
	["la_kajdany", "Kajdany Światła", "aoe", "Wrogowie zamarzają w miejscu.", 30.0, 12.0, Color(0.85, 0.85, 1.0), {"dmg": 18.0, "radius": 205.0, "kb": 40.0, "stun": 1.8}],
	["la_slonce", "Słoneczny Płomień", "fire_zone", "Płonący krąg światła parzy wrogów.", 36.0, 14.0, Color(1.0, 0.85, 0.4), {"dmg": 28.0, "radius": 165.0, "duration": 5.0}],
	["la_odnowa_zycia", "Odnowa Życia", "heal", "Potężne leczenie w dużym promieniu.", 55.0, 24.0, Color(0.55, 1.0, 0.7), {"heal": 70.0, "radius": 280.0, "duration": 5.0}],
]

static func _n(branch: String, lv: int, req: Array, rank: int) -> Dictionary:
	return {"branch": branch, "req_level": lv, "req": req, "max_rank": rank}

static func _br(name: String, col: Color) -> Dictionary:
	return {"name": name, "col": col}

## Skille klas jako słownik w formacie SkillDB.LIST.
static func skills() -> Dictionary:
	var out := {}
	for r in SKILLS:
		var d := {"name": r[1], "type": r[2], "desc": r[3], "cost": r[4], "cd": r[5], "col": r[6], "class_only": String(r[0]).substr(0, 2)}
		for k in (r[7] as Dictionary):
			d[k] = r[7][k]
		out[String(r[0])] = d
	return out

## Drzewka: każda klasa używa wyłącznie własnych umiejętności (oraz sygnaturowych jako wymagań).
static func trees() -> Dictionary:
	var t := {}
	t["wojownik"] = {
		"branches": {"a": _br("Furia i siła", Color(0.95, 0.45, 0.35)), "b": _br("Pancerz i szarża", Color(0.6, 0.75, 1.0)), "c": _br("Dowodzenie", Color(1.0, 0.85, 0.4))},
		"nodes": {
			"wo_ciecie": _n("a", 3, [], 3), "wo_miazdza": _n("a", 8, ["wo_ciecie"], 3), "wo_rzeznik": _n("a", 14, ["wo_ciecie"], 3),
			"wo_trzesienie": _n("a", 24, ["wo_rzeznik"], 2), "wo_rzez": _n("a", 30, ["wo_miazdza", "wo_rzeznik"], 3), "wo_tytan": _n("a", 40, ["wo_rzez", "wo_mur"], 1),
			"wo_podkowa": _n("b", 4, [], 3), "wo_tarcza_kowala": _n("b", 5, [], 3), "wo_byk": _n("b", 8, ["wo_podkowa"], 3),
			"wo_skok": _n("b", 12, ["wo_podkowa"], 3), "wo_mur": _n("b", 18, ["wo_tarcza_kowala"], 2),
			"wo_weteran": _n("c", 3, [], 3), "wo_okrzyk": _n("c", 6, [], 3), "wo_rozkaz": _n("c", 7, [], 3), "wo_ryk": _n("c", 12, ["wo_okrzyk"], 2),
		},
	}
	t["lucznik"] = {
		"branches": {"a": _br("Strzelectwo", Color(0.6, 0.9, 0.5)), "b": _br("Zwinność", Color(0.45, 0.85, 0.95)), "c": _br("Pułapki i natura", Color(0.8, 0.6, 1.0))},
		"nodes": {
			"lu_strzal": _n("a", 3, [], 3), "lu_przebijajaca": _n("a", 8, ["lu_strzal"], 3), "lu_snajper": _n("a", 14, ["lu_przebijajaca"], 3),
			"lu_lawina": _n("a", 20, ["lu_strzal"], 3), "lu_deszcz": _n("a", 28, ["lu_lawina", "lu_zapalajaca"], 3), "lu_zapalajaca": _n("a", 16, ["lu_strzal"], 3),
			"lu_unik": _n("b", 4, [], 3), "lu_wzlot": _n("b", 10, ["lu_unik"], 3), "lu_kamuflaz": _n("b", 15, ["lu_unik"], 2), "lu_okrzyk": _n("b", 6, [], 3),
			"lu_pulapka": _n("c", 9, [], 3), "lu_blysk": _n("c", 12, ["lu_pulapka"], 2), "lu_haslo": _n("c", 7, [], 3), "lu_ziola": _n("c", 3, [], 3),
		},
	}
	t["fechmistrz"] = {
		"branches": {"a": _br("Szermierka", Color(1.0, 0.65, 0.35)), "b": _br("Zwinność", Color(0.45, 0.85, 0.95)), "c": _br("Obrona i styl", Color(0.6, 0.75, 1.0))},
		"nodes": {
			"fe_pchniecie": _n("a", 3, [], 3), "fe_kolo": _n("a", 6, ["fe_pchniecie"], 3), "fe_cios_mistrza": _n("a", 10, ["fe_pchniecie"], 3),
			"fe_riposta": _n("a", 14, ["fe_kolo"], 3), "fe_wir": _n("a", 22, ["fe_riposta"], 3), "fe_mistrz": _n("a", 38, ["fe_wir", "fe_parada"], 2),
			"fe_krok": _n("b", 4, [], 3), "fe_tancerz": _n("b", 10, ["fe_krok"], 3), "fe_tempo": _n("b", 7, [], 3), "fe_zamroczenie": _n("b", 14, ["fe_krok"], 2),
			"fe_postawa": _n("c", 5, [], 3), "fe_parada": _n("c", 12, ["fe_postawa"], 3), "fe_zasieki": _n("c", 18, ["fe_postawa"], 2), "fe_bandaz": _n("c", 3, [], 3),
		},
	}
	t["zlodziej"] = {
		"branches": {"a": _br("Cień", Color(0.7, 0.6, 0.9)), "b": _br("Ostrza", Color(0.95, 0.8, 0.4)), "c": _br("Sztuczki", Color(0.5, 0.95, 0.6))},
		"nodes": {
			"zl_mgla": _n("a", 4, [], 3), "zl_skok": _n("a", 10, ["zl_mgla"], 3), "zl_welon": _n("a", 15, ["zl_mgla"], 2), "zl_doskok": _n("a", 8, ["zl_mgla"], 3),
			"zl_noz": _n("b", 3, [], 3), "zl_wachlarz": _n("b", 9, ["zl_noz"], 3), "zl_cios_w_plecy": _n("b", 14, ["zl_noz"], 3),
			"zl_zasadzka": _n("b", 20, ["zl_wachlarz"], 3), "zl_mistrz": _n("b", 38, ["zl_zasadzka", "zl_welon"], 2),
			"zl_dym": _n("c", 6, [], 3), "zl_kwas": _n("c", 10, [], 3), "zl_haczyk": _n("c", 14, ["zl_dym"], 3), "zl_lupy": _n("c", 7, [], 3), "zl_lek": _n("c", 3, [], 3),
		},
	}
	t["mag"] = {
		"branches": {"a": _br("Żywioły", Color(1.0, 0.55, 0.3)), "b": _br("Arkana", Color(0.8, 0.6, 1.0)), "c": _br("Ochrona many", Color(0.6, 0.85, 1.0))},
		"nodes": {
			"ma_piorun": _n("a", 4, [], 3), "ma_mroz": _n("a", 7, [], 3), "ma_jad": _n("a", 10, [], 3), "ma_burza_ognia": _n("a", 18, ["ma_jad"], 3),
			"ma_kometa": _n("a", 32, ["ma_burza_ognia", "ma_mroz"], 2),
			"ma_pocisk": _n("b", 3, [], 3), "ma_kula_arkan": _n("b", 9, ["ma_pocisk"], 3), "ma_oslepienie": _n("b", 12, ["ma_pocisk"], 2),
			"ma_sztorm": _n("b", 26, ["ma_kula_arkan"], 3), "ma_wzmocnienie": _n("b", 16, ["ma_pocisk"], 3),
			"ma_teleport": _n("c", 4, [], 3), "ma_skora": _n("c", 8, [], 3), "ma_bariera": _n("c", 14, ["ma_skora"], 3), "ma_medytacja": _n("c", 3, [], 3),
		},
	}
	t["lady"] = {
		"branches": {"a": _br("Uzdrawianie", Color(0.5, 0.95, 0.6)), "b": _br("Opieka", Color(1.0, 0.85, 0.4)), "c": _br("Światło", Color(0.8, 0.6, 1.0))},
		"nodes": {
			"la_opieka": _n("a", 3, [], 3), "la_krag_zdrowia": _n("a", 8, ["la_opieka"], 3), "la_zew": _n("a", 12, ["la_opieka"], 3),
			"la_blogoslawienstwo": _n("a", 20, ["la_zew"], 2), "la_odnowa_zycia": _n("a", 32, ["la_krag_zdrowia", "la_twierdza"], 2),
			"la_oslona": _n("b", 5, [], 3), "la_twierdza": _n("b", 18, ["la_oslona"], 2), "la_ochrona": _n("b", 15, [], 2), "la_zew_pupili": _n("b", 7, [], 3),
			"la_iskra": _n("c", 3, [], 3), "la_gniew": _n("c", 8, ["la_iskra"], 3), "la_kajdany": _n("c", 11, ["la_iskra"], 3),
			"la_blask": _n("c", 14, ["la_gniew"], 2), "la_slonce": _n("c", 22, ["la_gniew", "la_kajdany"], 3),
		},
	}
	return t
