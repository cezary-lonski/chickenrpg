class_name ItemsGen
extends RefCounted
## Dużo dodatkowych przedmiotów do sklepu i skrzyń: broń, zbroje, hełmy, buty, akcesoria, amulety,
## mikstury i rzutki. Statystyki liczone są z poziomu (tier 1–6) i profilu przedmiotu, więc cała
## rodzina skaluje się równo. Id mają przedrostek "g_". Scalane z ItemDB.LIST przy starcie.
##
## Profile: tank (obrona, mniej szybkości), agile (szybkość, krytyk), mage (energia), lucky (szczęście, złoto),
## brute (siła), vital (życie).

# [id, nazwa, tier, ikona, profil, opis, kolor]
const WEAPONS := [
	["g_miecz_stajenny", "Miecz stajenny", 1, "miecz", "brute", "Pamięta lepsze czasy. Stajnia też.", Color(0.75, 0.78, 0.85)],
	["g_szabla_targowa", "Szabla targowa", 2, "szabla", "agile", "Do targowania się z wrogami o ostatnie pióro.", Color(0.8, 0.82, 0.9)],
	["g_kosa_zniwna", "Kosa żniwna", 2, "kosa", "brute", "Zbiera plony. Wszelkie.", Color(0.8, 0.82, 0.88)],
	["g_kij_pasterski", "Kij pasterski", 1, "kij", "vital", "Terminowo przypomina baranom o tym, kto tu rządzi.", Color(0.6, 0.4, 0.22)],
	["g_mlot_kowalski", "Młot kowalski", 3, "mlot", "brute", "Dobry do podków i do wszystkiego innego.", Color(0.62, 0.64, 0.72)],
	["g_widly_obronne", "Widły obronne", 2, "widelec", "tank", "Chłopska tradycja w ostrej wersji.", Color(0.8, 0.82, 0.88)],
	["g_pioro_kronikarza", "Pióro kronikarza", 3, "pioro", "lucky", "Wpisuje wrogów do księgi poległych.", Color(0.95, 0.95, 0.9)],
	["g_kolce_jeza", "Kolce jeża", 3, "kolce", "agile", "Najeżone i bardzo obrażone.", Color(0.7, 0.72, 0.8)],
	["g_laska_druida", "Laska druida", 3, "laska", "mage", "Szumi liśćmi nawet wtedy, kiedy nie ma wiatru.", Color(0.55, 0.9, 0.6)],
	["g_miecz_gwardii", "Miecz gwardii", 4, "miecz", "tank", "Standardowe uzbrojenie wojsk Korony.", Color(0.8, 0.84, 0.92)],
	["g_dziobak_najemnika", "Dziobak najemnika", 4, "dziobak", "brute", "Płacą od trafienia, więc trafia często.", Color(0.97, 0.75, 0.2)],
	["g_szabla_szpiega", "Szabla szpiega", 4, "szabla", "agile", "Cicha. Nawet kiedy się o tym zapomni.", Color(0.5, 0.55, 0.7)],
	["g_kosa_zmierzchu", "Kosa zmierzchu", 5, "kosa", "lucky", "Tnie wszystko, co ma jeszcze coś do powiedzenia.", Color(0.65, 0.5, 0.9)],
	["g_mlot_burzowy", "Młot burzowy", 5, "mlot", "brute", "Grzmi, zanim uderzy. Dla uprzejmości.", Color(0.5, 0.75, 1.0)],
	["g_laska_pioruna", "Laska pioruna", 5, "laska", "mage", "Zapach ozonu i lekka obraza majestatu.", Color(0.55, 0.9, 1.0)],
	["g_miecz_wawelski", "Miecz Smoczego Kura", 6, "miecz", "brute", "Podobno zabił smoka. Smok się nie zgadza.", Color(1.0, 0.55, 0.25)],
	["g_kolce_kruka", "Kolce Czarnego Kruka", 6, "kolce", "agile", "Skonfiskowane po bitwie. Z tego, co zostało.", Color(0.4, 0.35, 0.5)],
	["g_pioro_feniksa", "Pióro feniksa", 6, "pioro", "lucky", "Płonie, ale nie parzy. Zawsze wraca.", Color(1.0, 0.6, 0.25)],
]

const ARMORS := [
	["g_kamizela_slomiana", "Kamizela słomiana", 1, "kamizelka", "vital", "Wygodna, tania i wrażliwa na ogień.", Color(0.85, 0.75, 0.4)],
	["g_skora_nocna", "Skóra nocna", 2, "kamizelka", "agile", "Cichnie, kiedy się zbliża wróg.", Color(0.35, 0.3, 0.45)],
	["g_kolczuga_gwardii", "Kolczuga gwardii", 3, "kolczuga", "tank", "Waży tyle, że nie trzeba kamieni w kieszeniach.", Color(0.7, 0.72, 0.8)],
	["g_szata_wedrowca", "Szata wędrowca", 3, "plaszcz", "mage", "Pachnie drogą i trochę cebulą.", Color(0.5, 0.6, 0.8)],
	["g_napiersnik_zolnierski", "Napierśnik żołnierski", 4, "pancerz", "tank", "Wgnieciony dokładnie tam, gdzie trzeba.", Color(0.62, 0.64, 0.72)],
	["g_plaszcz_zwiadowcy", "Płaszcz zwiadowcy", 4, "plaszcz", "agile", "Wtapia się w krzaki lepiej niż same krzaki.", Color(0.4, 0.6, 0.4)],
	["g_pancerz_skorupowy", "Pancerz skorupowy", 5, "skorupa", "tank", "Pękniętą skorupę trzeba tylko przykleić.", Color(0.45, 0.6, 0.4)],
	["g_szata_astrologa", "Szata astrologa", 5, "plaszcz", "mage", "Gwiazdy układają się w nią same.", Color(0.55, 0.4, 0.9)],
	["g_zbroja_korony", "Zbroja Korony", 6, "pancerz", "tank", "Dla tych, którzy mają się czym wykazać.", Color(1.0, 0.85, 0.35)],
	["g_skrzydla_burzy", "Skrzydła burzy", 6, "skrzydla", "agile", "Wiatr w piórach, piorun w kieszeni.", Color(0.6, 0.8, 1.0)],
]

const HELMETS := [
	["g_czapka_slomiana", "Czapka słomiana", 1, "helm", "lucky", "Chroni przed słońcem, nie przed czymkolwiek innym.", Color(0.9, 0.8, 0.45)],
	["g_kaptur_zwiadowcy", "Kaptur zwiadowcy", 2, "helm", "agile", "Za duży, ale za to kryje dziób.", Color(0.4, 0.55, 0.35)],
	["g_helm_gwardii", "Hełm gwardii", 3, "helm", "tank", "Z żelaza i z poczucia misji.", Color(0.7, 0.72, 0.8)],
	["g_diadem_uczonego", "Diadem uczonego", 3, "korona", "mage", "Podpowiada, kiedy lepiej się uchylić.", Color(0.6, 0.7, 1.0)],
	["g_helm_rogaty", "Hełm rogaty", 4, "helm", "brute", "Rogi są do szarży. Do niczego innego.", Color(0.75, 0.6, 0.4)],
	["g_kaptur_cienia", "Kaptur cienia", 5, "helm", "agile", "Ciemniejszy od cienia, w którym się ukrywa.", Color(0.3, 0.25, 0.4)],
	["g_korona_oblezonego", "Korona oblężonego", 5, "korona", "tank", "Nosiła ją czwórka monarchów. Żaden jej nie oddał.", Color(0.95, 0.8, 0.35)],
	["g_helm_smoczy", "Hełm smoczy", 6, "helm", "brute", "Prychnie ogniem, jeśli ktoś o niego zapyta.", Color(1.0, 0.5, 0.3)],
]

const BOOTS := [
	["g_chodaki_drewniane", "Chodaki drewniane", 1, "buty", "tank", "Głośne, solidne i nieśmiertelne.", Color(0.6, 0.4, 0.22)],
	["g_buty_podroznika", "Buty podróżnika", 2, "buty", "agile", "Zaczynają się rozchodzić dopiero po tysiącu mil.", Color(0.65, 0.5, 0.3)],
	["g_trzewiki_zwiadowcy", "Trzewiki zwiadowcy", 3, "buty", "agile", "Skrzypią tylko wtedy, gdy nie powinny.", Color(0.4, 0.55, 0.35)],
	["g_buty_gwardii", "Buty gwardii", 3, "buty", "tank", "Wypastowane na lustro i nigdy nie przepuszczą błota.", Color(0.7, 0.72, 0.8)],
	["g_buty_kurierskie", "Buty kurierskie", 4, "buty", "agile", "Dostarczają przesyłkę szybciej niż sam kurier.", Color(0.5, 0.8, 0.9)],
	["g_buty_cienia", "Buty cienia", 5, "buty", "agile", "Nie zostawiają śladów. Nawet w śniegu.", Color(0.35, 0.3, 0.5)],
	["g_buty_burzowe", "Buty burzowe", 5, "buty", "mage", "Przy każdym kroku coś iskrzy.", Color(0.5, 0.75, 1.0)],
	["g_buty_ksiecia", "Buty księcia", 6, "buty", "lucky", "Nie dotykały gruntu od trzech pokoleń.", Color(1.0, 0.85, 0.4)],
]

const ACCESSORIES := [
	["g_wstazka_targowa", "Wstążka targowa", 1, "szalik", "lucky", "Podobno przynosi szczęście. Podobno.", Color(0.9, 0.35, 0.4)],
	["g_pierscien_kuchenny", "Pierścień kuchenny", 1, "piercien", "vital", "Czajnik i miska są w pakiecie.", Color(0.85, 0.75, 0.4)],
	["g_szalik_wedrowca", "Szalik wędrowca", 2, "szalik", "agile", "Dziesięć metrów i ani jednej dziury.", Color(0.3, 0.6, 0.8)],
	["g_obroza_straznicza", "Obroża strażnicza", 2, "obroza", "tank", "Jeżeli ktoś ją nosi, nikt nie pyta dlaczego.", Color(0.8, 0.5, 0.3)],
	["g_koraliki_szamana", "Koraliki szamana", 3, "koraliki", "mage", "Dzwonią dokładnie w tonacji zaklęcia.", Color(0.55, 0.4, 0.8)],
	["g_pierscien_awanturnika", "Pierścień awanturnika", 3, "piercien", "brute", "Kosztuje mniej niż cztery wybite zęby.", Color(0.9, 0.45, 0.25)],
	["g_kiel_basiora", "Kieł basiora", 4, "kiel", "brute", "Zerwany z kogoś, kto się nie zgodził.", Color(0.95, 0.93, 0.85)],
	["g_okulary_skarbnika", "Okulary skarbnika", 4, "okulary", "lucky", "Widzą monety nawet w ciemności.", Color(0.3, 0.3, 0.38)],
	["g_szalik_burzy", "Szalik burzy", 5, "szalik", "agile", "Furkocze, nawet w pokoju bez okien.", Color(0.5, 0.75, 1.0)],
	["g_pierscien_krola", "Pierścień królewski", 6, "piercien", "vital", "Dostał go ten, kto zapomniał oddać.", Color(1.0, 0.85, 0.35)],
]

const AMULETS := [
	["g_amulet_zielarki", "Amulet zielarki", 1, "amulet", "vital", "Pachnie rumiankiem i dobrymi intencjami.", Color(0.5, 0.85, 0.5)],
	["g_amulet_szczescia", "Amulet szczęścia", 2, "amulet", "lucky", "Odwrócony, bo tak jest lepiej.", Color(0.95, 0.85, 0.35)],
	["g_amulet_straznika", "Amulet strażnika", 3, "amulet", "tank", "Cały czas czuwa i nigdy nie śpi.", Color(0.6, 0.7, 0.85)],
	["g_amulet_wilka", "Amulet wilka", 3, "amulet", "brute", "Wyje tylko wtedy, gdy ma coś do roboty.", Color(0.7, 0.7, 0.75)],
	["g_amulet_runiczny", "Amulet runiczny", 4, "amulet", "mage", "Runy zmieniają się, ilekroć nikt nie patrzy.", Color(0.6, 0.45, 0.95)],
	["g_amulet_cienia", "Amulet cienia", 5, "amulet", "agile", "Nie rzuca cienia. Za to rzuca podejrzenia.", Color(0.4, 0.35, 0.55)],
	["g_amulet_feniksa", "Amulet feniksa", 5, "amulet", "vital", "Po każdej bitwie świeci trochę jaśniej.", Color(1.0, 0.55, 0.25)],
	["g_amulet_krolewski", "Amulet królewski", 6, "amulet", "lucky", "Nikt nie pamięta, kto go zgubił.", Color(1.0, 0.85, 0.4)],
]

# [id, nazwa, tier, ikona, cena, stack, opis, kolor, use]
const CONSUMABLES := [
	["g_mikstura_mala", "Mikstura mała", 1, "mikstura", 12, 20, "Przywraca 30 punktów życia.", Color(0.9, 0.4, 0.4), {"health": 30.0}],
	["g_mikstura_duza", "Mikstura duża", 3, "mikstura", 55, 10, "Przywraca 120 punktów życia.", Color(0.85, 0.25, 0.3), {"health": 120.0}],
	["g_mikstura_krolewska", "Mikstura królewska", 5, "mikstura", 180, 5, "Przywraca 300 punktów życia i 30 energii.", Color(1.0, 0.3, 0.45), {"health": 300.0, "energy": 30.0}],
	["g_eliksir_maly", "Eliksir mały", 1, "eliksir", 12, 20, "Przywraca 35 punktów energii.", Color(0.4, 0.65, 0.95), {"energy": 35.0}],
	["g_eliksir_duzy", "Eliksir duży", 3, "eliksir", 55, 10, "Przywraca 120 punktów energii.", Color(0.3, 0.55, 0.95), {"energy": 120.0}],
	["g_wywar_sily", "Wywar siły", 2, "koktajl", 70, 8, "Na 20 sekund zwiększa siłę ciosów.", Color(0.95, 0.5, 0.3), {"buff_strength": 0.4, "buff_time": 20.0}],
	["g_wywar_zwinnosci", "Wywar zwinności", 2, "koktajl", 70, 8, "Na 20 sekund przyspiesza ruch.", Color(0.5, 0.9, 0.6), {"buff_speed": 0.3, "buff_time": 20.0}],
	["g_rosol_zolnierski", "Rosół żołnierski", 3, "rosol", 90, 5, "Życie do pełna i zryw siły na 15 sekund.", Color(0.95, 0.8, 0.4), {"health": 999.0, "buff_strength": 0.4, "buff_time": 15.0}],
	["g_napar_nieczuly", "Napar nieczuły", 4, "koktajl", 160, 3, "Krótka niezniszczalność i szybszy bieg.", Color(0.7, 0.5, 0.95), {"invuln": 5.0, "buff_speed": 0.25, "buff_time": 8.0}],
	["g_cebula_bojowa", "Cebula bojowa", 1, "cebula", 8, 20, "Przywraca 18 punktów życia. Nikt nie powstrzyma łez.", Color(0.78, 0.5, 0.7), {"health": 18.0}],
]

# [id, nazwa, tier, ikona, cena, stack, opis, kolor, obrażenia, promień, liczba]
const THROWABLES := [
	["g_jajko_zgnile", "Jajko zgniłe", 1, "jajko", 8, 20, "Rzut, trzask i zapach, który zostaje na długo.", Color(0.6, 0.7, 0.3), 22.0, 50.0, 1],
	["g_jajko_podwojne", "Jajko podwójne", 2, "jajko_duze", 22, 20, "Dwa naraz. Nikt nie liczył, że będzie taniej.", Color(0.97, 0.9, 0.7), 20.0, 48.0, 2],
	["g_bomba_piorowa", "Bomba piórowa", 3, "skamielina", 45, 15, "Piór pełno, hałasu jeszcze więcej.", Color(0.8, 0.8, 0.9), 55.0, 90.0, 1],
	["g_kamien_prozny", "Kamień próżny", 2, "skamielina", 18, 20, "Cieszy się, że w końcu się komuś przydał.", Color(0.65, 0.62, 0.55), 30.0, 40.0, 1],
	["g_jajko_ognia", "Jajko ognia", 4, "jajko", 80, 10, "Jajko pełne małych smoków. Mniej więcej.", Color(1.0, 0.5, 0.2), 90.0, 110.0, 1],
	["g_trojjajko", "Trójjajko", 4, "jajko_duze", 95, 10, "Trzy jajka na raz, żeby nie było kłótni.", Color(0.95, 0.85, 0.5), 45.0, 60.0, 3],
	["g_bomba_burzowa", "Bomba burzowa", 5, "skamielina", 150, 8, "Zamyka w sobie jedną burzę. Chyba małą.", Color(0.5, 0.75, 1.0), 140.0, 140.0, 1],
	["g_jajko_krolewskie", "Jajko królewskie", 6, "jajko_duze", 260, 5, "Specjalne, wyjątkowe i bardzo pewne siebie.", Color(1.0, 0.85, 0.35), 200.0, 160.0, 2],
]

static var LIST: Dictionary = _build()

static func _price(tier: int, mult: float) -> int:
	return int(round(28.0 * pow(float(tier), 1.7) * mult / 5.0) * 5.0)

## Statystyki z poziomu i profilu.
static func _stats(slot: String, tier: int, profile: String) -> Dictionary:
	var t := float(tier)
	var s := {}
	match slot:
		"weapon":
			s["strength"] = 0.10 + 0.115 * t
			s["crit"] = 0.02 + 0.012 * t
		"armor":
			s["defense"] = 0.06 + 0.07 * t
		"helmet":
			s["defense"] = 0.04 + 0.04 * t
		"boots":
			s["speed"] = 0.03 + 0.018 * t
			s["defense"] = 0.02 + 0.02 * t
		"accessory", "amulet":
			s["health"] = 5.0 + 3.5 * t
	match profile:
		"tank":
			s["defense"] = float(s.get("defense", 0.0)) + 0.03 * t
			s["poise"] = 0.04 * t
			if slot != "armor":
				s["health"] = float(s.get("health", 0.0)) + 5.0 * t
			s["speed"] = float(s.get("speed", 0.0)) - 0.012 * t
		"agile":
			s["speed"] = float(s.get("speed", 0.0)) + 0.025 * t
			s["crit"] = float(s.get("crit", 0.0)) + 0.012 * t
		"mage":
			s["energy"] = 8.0 * t
		"lucky":
			s["luck"] = 0.04 * t
		"brute":
			s["strength"] = float(s.get("strength", 0.0)) + 0.06 * t
			s["fury"] = 0.03 * t
		"vital":
			s["health"] = float(s.get("health", 0.0)) + 8.0 * t
	return s

static func _fx(slot: String, tier: int, profile: String) -> Dictionary:
	var fx := {}
	if slot not in ["amulet", "accessory"] or tier < 3:
		return fx
	match profile:
		"vital":
			fx["regen"] = 0.35 * float(tier - 2)
		"lucky":
			fx["xp_mult"] = 0.02 * float(tier - 2)
			fx["gold_mult"] = 0.03 * float(tier - 2)
		"brute":
			fx["lifesteal"] = 0.008 * float(tier - 2)
		"tank":
			fx["dmg_reduction"] = 0.012 * float(tier - 2)
	return fx

static func _gear(out: Dictionary, rows: Array, slot: String, price_mult: float) -> void:
	for r in rows:
		var tier := int(r[2])
		var d := {
			"name": String(r[1]), "slot": slot, "tier": tier, "price": _price(tier, price_mult), "icon": String(r[3]),
			"desc": String(r[5]), "tint": r[6], "stats": _stats(slot, tier, String(r[4])),
		}
		var fx := _fx(slot, tier, String(r[4]))
		if not fx.is_empty():
			d["fx"] = fx
		if slot == "weapon":
			var atk := {"dmg": 1.0 + 0.07 * float(tier)}
			match String(r[4]):
				"agile":
					atk["on_hit"] = {"bleed": 0.3 + 0.1 * float(tier), "desc": "krwawi"}
				"brute":
					atk["heavy"] = {"s": 1.3, "kb": 300.0 + 20.0 * float(tier), "stun": 0.5, "lunge": 70.0, "range": 60.0}
				"tank":
					atk["on_hit"] = {"splash": true, "desc": "kosi tłumy"}
				"mage", "vital":
					atk["on_hit"] = {"heal": 0.4 + 0.1 * float(tier), "desc": "leczy"}
			d["atk"] = atk
		out[String(r[0])] = d

static func _build() -> Dictionary:
	var out := {}
	_gear(out, WEAPONS, "weapon", 1.25)
	_gear(out, ARMORS, "armor", 1.5)
	_gear(out, HELMETS, "helmet", 1.0)
	_gear(out, BOOTS, "boots", 0.9)
	_gear(out, ACCESSORIES, "accessory", 0.85)
	_gear(out, AMULETS, "amulet", 1.1)
	for r in CONSUMABLES:
		out[String(r[0])] = {
			"name": String(r[1]), "slot": "consumable", "tier": int(r[2]), "price": int(r[4]), "icon": String(r[3]), "stack": int(r[5]),
			"desc": String(r[6]), "tint": r[7], "stats": {}, "use": r[8],
		}
	for r in THROWABLES:
		out[String(r[0])] = {
			"name": String(r[1]), "slot": "throwable", "tier": int(r[2]), "price": int(r[4]), "icon": String(r[3]), "stack": int(r[5]),
			"desc": String(r[6]), "tint": r[7], "stats": {},
			"throw": {"damage": float(r[8]), "radius": float(r[9]), "speed": 620.0, "gravity": 900.0, "count": int(r[10])},
		}
	return out
