class_name ZoneDB
extends RefCounted
## Definicje stref dla każdego rozdziału RPG. Każda strefa jest w widoku z góry
## (top-down), z falami wrogów i NPC. Fabuła sterowana krokami QuestDB:
##   step 0        -> porozmawiaj z dawcą zadania (start fal)
##   step 1..N     -> kolejne fale (N = liczba fal)
##   step N+1      -> porozmawiaj po bitwie (ukończenie rozdziału)

## Typy terenu: village, road, city, tower, forest, fortress
const BASE_ZONES := {
	"obrona_wioski": {
		"terrain": "village",
		"spawn": Vector2(1100, 1080),
		"npcs": ["starosta", "kowal", "kasia", "straznik", "kupiec"],
		"giver": "starosta",
		"waves": [
			{"enemies": [["wrzos", 4]], "name": "Wrzosy"},
			{"enemies": [["sroka", 3], ["wrzos", 3]], "name": "Sroki i wrzosy"},
			{"enemies": [["kawka", 3], ["sroka", 3], ["wrzos", 2]], "name": "Kawki, sroki, wrzosy"},
		],
		"villain": {
			"who": "Hrabia Sroka",
			"after_wave": 2,
			"lines": [
				"DOŚĆ TEGO CYRKU. Starosta obiecuje wam świt? Kruk obiecuje wam tylko popiół.",
				"Wioska to tylko przynęta. Królowa już wie, że idziemy. A ty, %s... jesteś już martwy, tylko jeszcze o tym nie wiesz.",
				"Ostatnia fala! Zmiażdżcie ich!",
			],
		},
		"intro_banner": ["PROLOG", "Nocny najazd"],
		"intro": [
			["", "Noc miała być spokojna. Nad wioską zapłonęły ognie, a niebo zakryły czarne skrzydła."],
			["", "To nie były zwykłe ptaki. To była armia Kruka — zwiastun czegoś gorszego."],
			["", "%s, mieszkańcy ufają ci. Chwyć broń i stań między nimi a ciemnością."],
		],
		"outro_banner": ["ROZDZIAŁ I UKOŃCZONY", "Nocny najazd"],
	},
	"droga_do_stolicy": {
		"terrain": "road",
		"spawn": Vector2(300, 750),
		"npcs": ["straznik", "kupiec", "kowal"],
		"giver": "straznik",
		"waves": [
			{"enemies": [["szpak", 4], ["golab", 3]], "name": "Zwiad traktu"},
			{"enemies": [["sokol", 3], ["kawka", 4]], "name": "Posterunek buntowników"},
			{"enemies": [["jastrzab", 4], ["czajka", 4]], "name": "Zasadzka na moście"},
		],
		"villain": {
			"who": "Herold Kruka",
			"after_wave": 2,
			"lines": [
				"Hola, drobny ptaku! Stolica dawno przestała słuchać królowej.",
				"Zawróć, %s, zanim trakt pochłonie cię jak wszystkich śmiałków.",
			],
		},
		"intro_banner": ["ROZDZIAŁ II", "Trakt do stolicy"],
		"intro": [
			["", "Wioska została za tobą. Przed tobą długi trakt w stronę stolicy, usłany posterunkami straży."],
			["", "Nie wszystkie noszą barwy korony. Niektóre dawno sprzedały się Krukowi."],
			["", "Strażnik Michał prowadzi szpicę. Trzymaj się drogi i miej oczy otwarte."],
		],
		"outro_banner": ["ROZDZIAŁ II UKOŃCZONY", "Trakt do stolicy"],
	},
	"atak_na_stolice": {
		"terrain": "city",
		"spawn": Vector2(1100, 1300),
		"npcs": ["straznik", "kupiec", "kowal"],
		"giver": "straznik",
		"waves": [
			{"enemies": [["golab", 5], ["szpak", 4]], "name": "Płonące ulice"},
			{"enemies": [["kruk", 3], ["sroka", 4]], "name": "Gwardia Kruka"},
			{"enemies": [["kawka", 4], ["wronszek", 4]], "name": "Ostatni opór na placu"},
		],
		"villain": {
			"who": "Kapitan zdrajców",
			"after_wave": 2,
			"lines": [
				"Plac należy do Kruka! Królowa jest już w kajdanach.",
				"Zginiesz jak reszta wiernych koronie.",
			],
		},
		"intro_banner": ["ROZDZIAŁ III", "Płonąca stolica"],
		"intro": [
			["", "Stolica tonie w ogniu. Ulicami płynie czarny dym, a w powietrzu krąży popiół."],
			["", "Wróg uderzył równocześnie z trzech stron. Miasto pogrążone jest w panice."],
			["", "Znajdź kapitan straży i odbij główny plac, nim stolica upadnie na dobre."],
		],
		"outro_banner": ["ROZDZIAŁ III UKOŃCZONY", "Płonąca stolica"],
	},
	"uwolnij_krolowa": {
		"terrain": "tower",
		"spawn": Vector2(1100, 1250),
		"npcs": ["straznik", "kupiec", "kowal"],
		"giver": "straznik",
		"waves": [
			{"enemies": [["puchacz", 3], ["wronszek", 3]], "name": "Straż przednia"},
			{"enemies": [["kruk", 3], ["jastrzab", 3]], "name": "Warta wieży"},
			{"enemies": [["orzel_szarak", 2], ["bocian_gruby", 2], ["kruk", 2]], "name": "Kat u drzwi"},
		],
		"villain": {
			"who": "Dowódca straży",
			"after_wave": 1,
			"lines": [
				"Kto śmie dobijać się do wieży królowej?",
				"Nikt nie przejdzie. Rozszarpać go!",
			],
		},
		"intro_banner": ["ROZDZIAŁ IV", "Królowa w kajdanach"],
		"intro": [
			["", "Wieża królowej góruje nad zgliszczami stolicy. U jej stóp roi się od straży Kruka."],
			["", "Królowa Aurelia jest uwięziona na szczycie. Każda chwila zwłoki to kolejny dzień jej kajdan."],
			["", "Przedrzyj się przez warty i uwolnij królową."],
		],
		"outro_banner": ["ROZDZIAŁ IV UKOŃCZONY", "Królowa w kajdanach"],
	},
	"trojka_prob": {
		"terrain": "forest",
		"spawn": Vector2(1100, 1200),
		"npcs": ["kowal", "kupiec"],
		"giver": "kowal",
		"waves": [
			{"enemies": [["puchacz", 4], ["czajka", 4]], "name": "Kryształowa Grota"},
			{"enemies": [["bocian_gruby", 3], ["orzel_szarak", 3]], "name": "Popielna Kuźnia"},
			{"enemies": [["puchacz", 3], ["orzel_szarak", 3], ["wronszek", 3]], "name": "Mroczny Gaj"},
		],
		"villain": {
			"who": "Leśny Strażnik",
			"after_wave": 2,
			"lines": [
				"Trzy relikty strzegą trzy bestie. Żadnej nie pokonasz sam.",
				"Ostatnia próba, %s. Ciemność Mrocznego Gaju pożera śmiałków.",
			],
		},
		"intro_banner": ["ROZDZIAŁ V", "Trzy próby"],
		"intro": [
			["", "Bez reliktów forteca Kruka pozostanie niezdobyta. Królowa wskazała trzy miejsca."],
			["", "Ostrze z Kryształowej Groty, pancerz z Popielnej Kuźni, talizman z Mrocznego Gaju."],
			["", "Kowal Grzegorz ruszył z tobą. Zdobądź wszystko, nim Kruka wzmocni kolejna noc."],
		],
		"outro_banner": ["ROZDZIAŁ V UKOŃCZONY", "Trzy próby"],
	},
	"marsz_na_forteca": {
		"terrain": "road",
		"spawn": Vector2(300, 750),
		"npcs": ["straznik", "kupiec", "kowal"],
		"giver": "straznik",
		"waves": [
			{"enemies": [["orzel_szarak", 4], ["bocian_gruby", 4]], "name": "Czarny marsz"},
			{"enemies": [["kruk", 4], ["orzel_szarak", 3]], "name": "Obóz wroga"},
			{"enemies": [["kruk", 3], ["krol_krukow", 1], ["bocian_gruby", 3]], "name": "Brama fortecy"},
		],
		"villain": {
			"who": "Kruk",
			"after_wave": 2,
			"lines": [
				"Więc dotarłeś aż tutaj. Twoja odwaga mnie bawi.",
				"Za tą bramą czekam ja. Wejdź, jeśli ważysz się spojrzeć w moje oczy.",
			],
		},
		"intro_banner": ["ROZDZIAŁ VI", "Czarny marsz"],
		"intro": [
			["", "Armia korony maszeruje pod mury twierdzy Kruka. Idziesz na czele."],
			["", "Rozbij obóz wroga i stań pod bramą fortecy. To ostatni krok przed starciem."],
			["", "Nad polem unosi się cisza — cisza przed największą burzą."],
		],
		"outro_banner": ["ROZDZIAŁ VI UKOŃCZONY", "Czarny marsz"],
	},
	"krol_i_kruk": {
		"terrain": "fortress",
		"spawn": Vector2(1100, 1250),
			"npcs": ["straznik", "kupiec", "kowal"],
		"giver": "straznik",
		"waves": [
			{"enemies": [["kruk", 4], ["wronszek", 4]], "name": "Sala tronowa"},
			{"enemies": [["orzel_szarak", 3], ["krol_krukow", 1], ["kruk", 2]], "name": "Cień króla"},
			{"enemies": [["krol_krukow", 2], ["kruk", 4], ["orzel_szarak", 3]], "name": "Serce Kruka"},
		],
		"villain": {
			"who": "Czarny Kruk",
			"after_wave": 2,
			"lines": [
				"Oto koniec drogi, %s. Królestwo kur będzie moje — a ty padniesz u moich stóp.",
				"Nie walczysz z ptakiem. Walczysz z nocą.",
			],
		},
		"intro_banner": ["ROZDZIAŁ VII", "Serce kruka"],
		"intro": [
			["", "Wnętrze fortecy jest zimne jak grób. Gdzieś w mroku czeka sam Czarny Kruk."],
			["", "Królowa mówiła, że w fortecy odnajdziesz zaginionego króla — albo jego cień."],
			["", "To ostatnia bitwa o koronę. Za wioskę, za stolicę, za świt."],
		],
		"outro_banner": ["ROZDZIAŁ VII UKOŃCZONY", "Serce kruka"],
	},
	"cien_w_popiele": {
		"terrain": "ash",
		"spawn": Vector2(1100, 1250),
		"npcs": ["straznik", "kowal", "kupiec"],
		"giver": "straznik",
		"waves": [
			{"enemies": [["kruk", 3], ["wronszek", 3]], "name": "Popioły"},
			{"enemies": [["puchacz", 4], ["szpak", 3]], "name": "Krypta straży"},
			{"enemies": [["krol_krukow", 1], ["kruk", 3], ["wronszek", 3]], "name": "Cień Kruka"},
			{"enemies": [["orzel_szarak", 4], ["bocian_gruby", 3], ["kruk", 2]], "name": "Pieczęć skarbca"},
		],
		"villain": {
			"who": "Cień Kruka",
			"after_wave": 2,
			"lines": [
				"Kruk nie umiera. Kruk tylko zmienia gospodarza.",
				"Czarne serce już bije w Gnieździe Sępów, %s. Idź tam, jeśli chcesz je zatrzymać.",
			],
		},
		"intro_banner": ["ROZDZIAŁ VIII", "Cień w popiele"],
		"intro": [
			["", "Zwycięstwo nie przyniosło ciszy. W piwnicach fortecy coś szura skrzydłami."],
			["", "Strażnicy mówią o czarnym sercu zamkniętym w skarbcu. Mapa prowadzi na południe."],
			["", "%s, zanim świt wstanie nad królestwem, musisz zgasić cień Kruka."],
		],
		"outro_banner": ["ROZDZIAŁ VIII UKOŃCZONY", "Cień w popiele"],
	},
	"zdrada_w_koronie": {
		"terrain": "city",
		"spawn": Vector2(1100, 1300),
		"npcs": ["kupiec", "straznik", "kowal"],
		"giver": "kupiec",
		"waves": [
			{"enemies": [["golab", 5], ["sroka", 4]], "name": "Targowe plotki"},
			{"enemies": [["sokol", 4], ["kawka", 4]], "name": "Skrytki kanclerza"},
			{"enemies": [["orzel_szarak", 3], ["orzel_szarak", 1], ["szpak", 3]], "name": "Straż pałacowa"},
			{"enemies": [["sep", 3], ["kruk", 4], ["bocian_gruby", 2]], "name": "Sala tronowa"},
		],
		"villain": {
			"who": "Kanclerz Sępik",
			"after_wave": 2,
			"lines": [
				"Korona? Korona jest tylko ładniejszym gniazdem.",
				"Jajo należy do Cesarza. A wy, kurczaki, jesteście już martwe.",
			],
		},
		"intro_banner": ["ROZDZIAŁ IX", "Zdrada w koronie"],
		"intro": [
			["", "W stolicy zapanował pozorny spokój. Zbyt pozorny jak na miasto, które ocalało."],
			["", "Czarny skarbiec jest pusty, a straż donosi o pieczęci kanclerza Sępika."],
			["", "Kupiec Wacław zna wszystkie skrytki zdrajcy. Czas je otworzyć."],
		],
		"outro_banner": ["ROZDZIAŁ IX UKOŃCZONY", "Zdrada w koronie"],
	},
	"pustynny_trakt": {
		"terrain": "desert",
		"spawn": Vector2(300, 750),
		"npcs": ["straznik", "kupiec", "kowal"],
		"giver": "straznik",
		"waves": [
			{"enemies": [["czajka", 5], ["sokol", 4]], "name": "Przełęcz"},
			{"enemies": [["sep", 4], ["sroka", 4]], "name": "Sępie zwiady"},
			{"enemies": [["jastrzab", 4], ["puchacz", 3], ["sep", 2]], "name": "Karawana"},
			{"enemies": [["orzel_szarak", 4], ["sep", 4], ["orzel_szarak", 1]], "name": "Straż karawany"},
		],
		"villain": {
			"who": "Sęp Zwiadowca",
			"after_wave": 2,
			"lines": [
				"Cesarz widzi każde pióro na tym trakcie.",
				"Zawróć, kurczaku. Piasek już czeka na twoje kości.",
			],
		},
		"intro_banner": ["ROZDZIAŁ X", "Pustynny trakt"],
		"intro": [
			["", "Za przełęczą kończy się zieleń. Wiatr niesie piasek i zapach padliny."],
			["", "Karawana z czarnym jajem zdążyła uciec na południe. Musisz ją dogonić."],
			["", "Sępy krążą wysoko. To nie padlinożerne ptaki — to zwiadowcy Cesarza."],
		],
		"outro_banner": ["ROZDZIAŁ X UKOŃCZONY", "Pustynny trakt"],
	},
	"gniazdo_nad_burza": {
		"terrain": "storm",
		"spawn": Vector2(1100, 1200),
		"npcs": ["kowal", "kupiec"],
		"giver": "kowal",
		"waves": [
			{"enemies": [["sowa", 4], ["czajka", 4]], "name": "Totemy burzy"},
			{"enemies": [["puchacz", 4], ["orzel_szarak", 3], ["sowa", 2]], "name": "Gniazdo"},
			{"enemies": [["sowa_wieszczka", 1], ["sowa", 3], ["puchacz", 2]], "name": "Wieszczka Sowa"},
			{"enemies": [["sep", 4], ["bocian_gruby", 3], ["sowa", 2]], "name": "Szczyt"},
		],
		"villain": {
			"who": "Wieszczka Sowa",
			"after_wave": 2,
			"lines": [
				"Widzę twoją śmierć, kurczaku. Jest biała jak kość i cicha jak śnieg.",
				"Cesarz nie potrzebuje armii. Wystarczy mu jedno jajo i jedno serce.",
			],
		},
		"intro_banner": ["ROZDZIAŁ XI", "Gniazdo nad burzą"],
		"intro": [
			["", "Gniazdo Sępów wisi nad chmurami, splecione z korzeni i kości."],
			["", "Kowal Grzegorz wykuł hak na skały. Najpierw trzeba złamać totemy burzy."],
			["", "Na szczycie czuwa Wieszczka Sowa. Jej krzyk słychać nawet w dolinie."],
		],
		"outro_banner": ["ROZDZIAŁ XI UKOŃCZONY", "Gniazdo nad burzą"],
	},
	"ostatni_swit": {
		"terrain": "dawn",
		"spawn": Vector2(1100, 1250),
		"npcs": ["starosta", "straznik", "kowal", "kupiec"],
		"giver": "starosta",
		"waves": [
			{"enemies": [["kruk", 5], ["sep", 3]], "name": "Gwardia cesarska"},
			{"enemies": [["orzel_szarak", 4], ["bocian_gruby", 3], ["sowa", 2]], "name": "Sala Świtu"},
			{"enemies": [["krol_krukow", 1], ["kruk", 3], ["wronszek", 3]], "name": "Cień Kruka"},
			{"enemies": [["sep_cesarski", 1], ["sep", 3], ["sowa", 2]], "name": "Cesarz Sępów"},
		],
		"villain": {
			"who": "Cesarz Sępów",
			"after_wave": 3,
			"lines": [
				"Więc dotarłeś do mojego gniazda, mały ptaku.",
				"Kruk był tylko cieniem. Ja jestem nocą, która go zrodziła.",
				"Ostatni świt należy do mnie!",
			],
		},
		"intro_banner": ["ROZDZIAŁ XII", "Ostatni świt"],
		"intro": [
			["", "Noc nad Gniazdem jest tak gęsta, że gasi pochodnie."],
			["", "Cesarz Sępów czeka w Sali Świtu. Za nim bije czarne jajo, większe niż dom."],
			["", "%s, to ostatnia bitwa. Nie o koronę — o każdy poranek, który jeszcze nadejdzie."],
		],
		"outro_banner": ["ROZDZIAŁ XII UKOŃCZONY", "Ostatni świt"],
	},
}

## Dane strefy; do listy fal dopinany jest boss rozdziału (BossDB), o ile jeszcze go nie ma.
## Scalone strefy: Akt I/III + Akt II (Act2DB).
static var ZONES: Dictionary = BASE_ZONES.merged(Act2DB.ZONES).merged(PalaceDB.ZONES)

static func get_data(id: String) -> Dictionary:
	var z: Dictionary = ZONES.get(id, {})
	if z.is_empty():
		return z
	return _relabel(id, _with_boss(id, z))

## Numer rozdziału w banerach wynika z jego miejsca w kampanii.
static func _relabel(id: String, z: Dictionary) -> Dictionary:
	var q := QuestDB.get_data(id)
	if q.is_empty():
		return z
	var lab := String(q.get("label", "")).to_upper()
	for key in ["intro_banner", "outro_banner"]:
		if z.get(key) is Array and (z[key] as Array).size() >= 2 and String(z[key][0]).begins_with("ROZDZIAŁ"):
			var b: Array = (z[key] as Array).duplicate()
			b[0] = lab + (" UKOŃCZONY" if key == "outro_banner" else "")
			z[key] = b
	return z

static func _with_boss(id: String, zone: Dictionary) -> Dictionary:
	var z := zone.duplicate(true)
	var bid := BossDB.for_zone(id)
	if bid == "":
		return z
	var w: Array = z.get("waves", [])
	for wave in w:
		for e in wave["enemies"]:
			if String(e[0]).begins_with("BOSS:"):
				return z
	w.append({"enemies": [["BOSS:" + bid, 1]], "name": String(BossDB.get_data(bid).get("name", "Boss")), "boss": true})
	z["waves"] = w
	return z

## Liczba zwykłych fal przed bossem.
static func normal_waves(id: String) -> int:
	var n := 0
	for wave in get_data(id).get("waves", []):
		if not bool(wave.get("boss", false)):
			n += 1
	return n

static func has(id: String) -> bool:
	return ZONES.has(id)

static func for_chapter(index: int) -> Dictionary:
	var c := QuestDB.chapter(index)
	var id := String(c.get("id", ""))
	if id != "" and ZONES.has(id):
		return get_data(id)
	return get_data(String(QuestDB.chapter(0).get("id", "obrona_wioski")))

static func terrain(id: String) -> String:
	return String(get_data(id).get("terrain", "village"))
