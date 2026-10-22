class_name ZoneDB
extends RefCounted
## Definicje stref dla każdego rozdziału RPG. Każda strefa jest w widoku z góry
## (top-down), z falami wrogów i NPC. Fabuła sterowana krokami QuestDB:
##   step 0        -> porozmawiaj z dawcą zadania (start fal)
##   step 1..N     -> kolejne fale (N = liczba fal)
##   step N+1      -> porozmawiaj po bitwie (ukończenie rozdziału)

## Typy terenu: village, road, city, tower, forest, fortress
const ZONES := {
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
		"npcs": ["straznik", "kupiec"],
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
		"npcs": ["straznik", "kupiec"],
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
		"npcs": ["straznik", "kupiec"],
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
			{"enemies": [["bocian_gruby", 3], ["indyk_krolewski", 3]], "name": "Popielna Kuźnia"},
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
		"npcs": ["straznik", "kupiec"],
		"giver": "straznik",
		"waves": [
			{"enemies": [["indyk_krolewski", 4], ["bocian_gruby", 4]], "name": "Czarny marsz"},
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
		"npcs": ["straznik"],
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
			["", "To ostatnia bitwa. Za wioskę, za stolicę, za świt."],
		],
		"outro_banner": ["ROZDZIAŁ VII UKOŃCZONY", "Serce kruka"],
	},
}

static func get_data(id: String) -> Dictionary:
	return ZONES.get(id, {})

static func has(id: String) -> bool:
	return ZONES.has(id)

static func for_chapter(index: int) -> Dictionary:
	var c := QuestDB.chapter(index)
	var id := String(c.get("id", ""))
	if id != "" and ZONES.has(id):
		return ZONES[id]
	return ZONES[String(QuestDB.chapter(0).get("id", "obrona_wioski"))]

static func terrain(id: String) -> String:
	return String(get_data(id).get("terrain", "village"))
