class_name ChapterExtras
extends RefCounted
## Rozbudowa rozdziałów: dodatkowi NPC z dialogami i wyborami, cele fabularne
## (rozmowy, zbieranie informacji, uwolnienie jeńców, sabotaż, elitarni wrogowie),
## cele po walce z bossem oraz nagrody. Postęp cel-po-celu zapisuje się we flagach fabuły.
##
## Cele: phase "pre" = przed obroną (wymagane muszą być ukończone, by dawca zadania
## rozpoczął bitwę), "post" = po bossie (wymagane muszą być ukończone, by zakończyć rozdział).

const A := Vector2(330, 930)
const B := Vector2(1860, 900)
const C := Vector2(1000, 440)
const D := Vector2(1420, 1400)
const E := Vector2(700, 350)
const F := Vector2(1650, 400)
const G := Vector2(260, 1390)
const H := Vector2(1250, 1130)
const I := Vector2(900, 1260)
const J := Vector2(2000, 1380)

const BASE_NPCS := {
	"hela": {"name": "Wdowa Hela", "title": "Mieszkanka", "species": "kwoka", "scale": 1.3, "pos": Vector2(420, 1000), "accent": Color(0.9, 0.7, 0.6), "role": "lore"},
	"piotrus": {"name": "Gospodarz Piotruś", "title": "Gospodarz", "species": "kurczak", "scale": 1.4, "pos": Vector2(1950, 1010), "accent": Color(0.8, 0.85, 0.5), "role": "lore"},
	"bronek": {"name": "Kupiec Bronek", "title": "Wędrowny handlarz", "species": "indyk", "scale": 1.5, "pos": Vector2(600, 600), "accent": Color(0.95, 0.8, 0.4), "role": "lore"},
	"janek": {"name": "Zwiadowca Janek", "title": "Zwiadowca", "species": "gasior", "scale": 1.4, "pos": Vector2(1700, 880), "accent": Color(0.6, 0.85, 0.6), "role": "lore"},
	"zosia": {"name": "Piekarka Zosia", "title": "Mieszczanka", "species": "kwoka", "scale": 1.3, "pos": Vector2(780, 980), "accent": Color(0.95, 0.8, 0.5), "role": "lore"},
	"olek": {"name": "Ranny Strażnik Olek", "title": "Żołnierz", "species": "gasior", "scale": 1.4, "pos": Vector2(1500, 1000), "accent": Color(0.6, 0.8, 0.7), "role": "lore"},
	"lila": {"name": "Pokojówka Lila", "title": "Służba", "species": "kwoka", "scale": 1.25, "pos": Vector2(700, 1000), "accent": Color(0.9, 0.7, 0.85), "role": "lore"},
	"skarbnik": {"name": "Stary Skarbnik", "title": "Więzień", "species": "indyk", "scale": 1.45, "pos": Vector2(1600, 980), "accent": Color(0.85, 0.8, 0.5), "role": "lore"},
	"druid": {"name": "Stary Druid", "title": "Strażnik gaju", "species": "paw", "scale": 1.5, "pos": Vector2(640, 930), "accent": Color(0.55, 0.9, 0.6), "role": "lore"},
	"mira": {"name": "Łowczyni Mira", "title": "Zwiadowczyni", "species": "gasior", "scale": 1.4, "pos": Vector2(1560, 1050), "accent": Color(0.6, 0.9, 0.55), "role": "lore"},
	"kapitan": {"name": "Kapitan Wojsk Korony", "title": "Dowódca", "species": "kogut", "scale": 1.5, "pos": Vector2(560, 940), "accent": Color(0.95, 0.5, 0.4), "role": "lore"},
	"kucharz": {"name": "Kucharz Polowy Stach", "title": "Kwatermistrz", "species": "kurczak", "scale": 1.4, "pos": Vector2(1460, 1040), "accent": Color(0.9, 0.7, 0.4), "role": "lore"},
	"pierzak": {"name": "Spiskowiec Pierzak", "title": "Zbieg z fortecy", "species": "kogut", "scale": 1.45, "pos": Vector2(520, 960), "accent": Color(0.7, 0.55, 0.9), "role": "lore"},
	"obronca": {"name": "Ostatni Obrońca", "title": "Ranny weteran", "species": "gasior", "scale": 1.5, "pos": Vector2(1600, 1060), "accent": Color(0.85, 0.75, 0.5), "role": "lore"},
	"popielnik": {"name": "Popielnik Szary", "title": "Strażnik zgliszcz", "species": "indyk", "scale": 1.5, "pos": Vector2(560, 980), "accent": Color(0.7, 0.65, 0.65), "role": "lore"},
	"kasztelan": {"name": "Kasztelan Fryderyk", "title": "Urzędnik dworu", "species": "kogut", "scale": 1.5, "pos": Vector2(1560, 980), "accent": Color(0.9, 0.7, 0.4), "role": "lore"},
	"wedrowiec": {"name": "Pustynny Wędrowiec", "title": "Przewodnik", "species": "paw", "scale": 1.4, "pos": Vector2(620, 960), "accent": Color(0.95, 0.8, 0.45), "role": "lore"},
	"skrzydlaty": {"name": "Skrzydlaty Poseł", "title": "Posłaniec", "species": "gasior", "scale": 1.4, "pos": Vector2(1500, 1080), "accent": Color(0.7, 0.8, 0.95), "role": "lore"},
	"rybak": {"name": "Rybak Burzy", "title": "Mieszkaniec gniazda", "species": "kurczak", "scale": 1.4, "pos": Vector2(560, 1000), "accent": Color(0.6, 0.8, 0.9), "role": "lore"},
	"szamanka": {"name": "Szamanka Wichura", "title": "Wieszczka", "species": "kwoka", "scale": 1.5, "pos": Vector2(1560, 1020), "accent": Color(0.75, 0.7, 0.95), "role": "lore"},
	"gwardzista": {"name": "Gwardzista Świtu", "title": "Strażnik", "species": "kogut", "scale": 1.5, "pos": Vector2(560, 1000), "accent": Color(1.0, 0.8, 0.5), "role": "lore"},
	"bard": {"name": "Bard Kukuryk", "title": "Wędrowny pieśniarz", "species": "kogut", "scale": 1.4, "pos": Vector2(860, 1090), "accent": Color(0.95, 0.6, 0.8), "role": "lore"},
	"zakladnik": {"name": "Zakładniczka Aurelia", "title": "Królowa", "species": "kwoka", "scale": 1.5, "pos": Vector2(1560, 1060), "accent": Color(1.0, 0.85, 0.5), "role": "lore"},
}

const BASE_EXTRAS := {
	"obrona_wioski": {
		"npcs": ["hela", "piotrus"],
		"dialogs": {
			"hela": {
				"pre": [["Wdowa Hela", "Widziałam ich! Czarne skrzydła, szpony jak kosy... Zabrali mi pół kurnika."], ["Wdowa Hela", "Zanim ruszysz do walki — w mojej zagrodzie leżą kawałki jakichś rozkazów. Ptaki pogubiły je, uciekając."]],
				"choice": {"prompt": "Hela prosi o pomoc w odbudowie kurnika. Co robisz?", "options": [
					{"text": "Pomogę — daj mi chwilę.", "flag": "hela_pomoc", "reply": "Hela ściska cię za skrzydło. „Odwdzięczę się, gdy to wszystko minie.”", "final": {"gold": 90, "items": {"mikstura_miodu": 2}}},
					{"text": "Nie mam czasu. Wioska czeka.", "flag": "hela_odmowa", "reply": "Hela kiwa głową. „Rozumiem. Idź, ratuj, co się da.”"},
				]},
				"post": [["Wdowa Hela", "Wioska stoi, a ja mam jeszcze kurnik. Dziękuję, bohaterze."]],
			},
			"piotrus": {
				"pre": [["Gospodarz Piotruś", "Siedziałem w piwnicy całą noc. Starosta mówił, że Hrabia Sroka dowodzi najazdem."], ["Gospodarz Piotruś", "Podobno kradnie wszystko, co się świeci. Zamiast mieczem, walcz z nim blaskiem — odwróć jego uwagę!"]],
				"post": [["Gospodarz Piotruś", "Słyszałem, że starosta chce wyprawić posłańca do stolicy. Może to ty?"]],
			},
		},
		"objectives": [
			{"id": "swiadkowie", "phase": "pre", "type": "talk", "npcs": ["hela", "piotrus"], "text": "Porozmawiaj z mieszkańcami wsi", "required": true},
			{"id": "rozkazy", "phase": "pre", "type": "collect", "puzzle": "cipher", "kind": "document", "label": "Podnieś strzęp rozkazu", "count": 3, "positions": [A, B, C], "text": "Zbierz strzępy rozkazów wroga", "required": true,
				"clues": ["„…uderzyć z trzech stron, nim wzejdzie księżyc. Hrabia Sroka osłania tyły.”", "„…starosta jest kluczem. Złapać, nie zabijać. Rozkaz: Czarny Kruk.”", "„…wioska to tylko przynęta. Prawdziwy cel — stolica.”"],
				"reward": {"gold": 60}},
			{"id": "zagrody", "phase": "pre", "type": "free", "puzzle": "lockpick", "kind": "cage", "label": "Uwolnij uwięzione kury", "count": 2, "positions": [G, J], "text": "Uwolnij uwięzione kury (opcjonalnie)", "required": false,
				"reward": {"gold": 80, "items": {"mikstura_miodu": 1, "sztabka_zelaza": 1}, "xp": 60}},
		],
	},
	"droga_do_stolicy": {
		"npcs": ["bronek", "janek"],
		"dialogs": {
			"bronek": {
				"pre": [["Kupiec Bronek", "Pierze mi jeży na grzbiecie, kiedy słyszę o tym trakcie. Co drugi posterunek zmienił właściciela."], ["Kupiec Bronek", "Wiem, gdzie schowano meldunki. Kto je przeczyta, będzie wiedział, które posterunki są wrogie."]],
				"choice": {"prompt": "Bronek chce sprzedać ci mapę posterunków. Co robisz?", "options": [
					{"text": "Kupuję (40 zł).", "flag": "bronek_mapa", "reply": "„Dobra decyzja! Znam skrót, który oszczędzi ci czasu.”", "cost": 40, "final": {"gold": 100}},
					{"text": "Poradzę sobie sam.", "flag": "bronek_bez", "reply": "„Twoja strata, kolego.”"},
				]},
				"post": [["Kupiec Bronek", "Zatrzymaj się w stolicy na dłużej. Ceny tam teraz jak z nieba."]],
			},
			"janek": {
				"pre": [["Zwiadowca Janek", "Herold Kruka stoi przy bramie. Wygląda niepozornie, ale zabija pazurami z dystansu."], ["Zwiadowca Janek", "Uważaj na jego pióropusz — kiedy się nadyma, zaraz poleci wachlarz piór."]],
				"post": [["Zwiadowca Janek", "Trakt oczyszczony. Stolica jest już blisko."]],
			},
		},
		"objectives": [
			{"id": "wywiad", "phase": "pre", "type": "talk", "npcs": ["bronek", "janek"], "text": "Zbierz wieści od podróżnych", "required": true},
			{"id": "meldunki", "phase": "pre", "type": "collect", "puzzle": "pairs", "kind": "document", "label": "Przeczytaj meldunek", "count": 3, "positions": [A, C, B], "text": "Znajdź meldunki posterunków", "required": true,
				"clues": ["„Posterunek północny — wierny koronie, do czasu.”", "„Herold Kruka przybywa z rozkazem: zablokować trakt.”", "„Zapasy zbrojne ukryto w trzech skrzyniach przy drodze.”"], "reward": {"gold": 70}},
			{"id": "zapasy", "phase": "pre", "type": "sabotage", "puzzle": "lights", "kind": "crate", "label": "Zniszcz skrzynię zapasów", "count": 3, "positions": [F, H, I], "text": "Zniszcz zapasy buntowników (opcjonalnie)", "required": false,
				"reward": {"gold": 120, "items": {"sztabka_kurczalu": 1}, "xp": 90}},
		],
	},
	"atak_na_stolice": {
		"npcs": ["zosia", "olek"],
		"dialogs": {
			"zosia": {
				"pre": [["Piekarka Zosia", "Piekarnia płonęła, a ja uratowałam tylko ostatnie bułki. Czarne ptaki wrzeszczą po ulicach."], ["Piekarka Zosia", "Kapitan zdrajców chowa plany obrony w kilku skrzynkach. Dla zwykłego mieszczanina zbyt niebezpieczne."]],
				"choice": {"prompt": "Zosia prosi o miód na leczenie rannych. Co robisz?", "options": [
					{"text": "Oddaj Miksturę Miodu.", "flag": "zosia_miod", "reply": "Zosia płacze ze wzruszenia. „Zapamiętam to na całe życie!”", "take": {"mikstura_miodu": 1}, "final": {"gold": 130, "items": {"sztabka_kurczalu": 1}}},
					{"text": "Przykro mi, sam potrzebuję.", "flag": "zosia_odmowa", "reply": "Zosia opuszcza skrzydła. „Rozumiem...”"},
				]},
				"post": [["Piekarka Zosia", "Rano upiekę chleb dla całej stolicy. Dzięki tobie jest dla kogo."]],
			},
			"olek": {
				"pre": [["Ranny Strażnik Olek", "Kapitan nas zdradził. Otworzył bramy, gdy zapadła ciemność. Ledwo uszedłem z życiem."], ["Ranny Strażnik Olek", "Zbierz plany obrony, pokażą ci, gdzie stoją jego ludzie. Potem rozprawimy się z nim."]],
				"post": [["Ranny Strażnik Olek", "Nigdy bym nie uwierzył, że ktoś odbije plac. Dziękuję."]],
			},
		},
		"objectives": [
			{"id": "swiadkowie", "phase": "pre", "type": "talk", "npcs": ["zosia", "olek"], "text": "Porozmawiaj z ocalałymi", "required": true},
			{"id": "plany", "phase": "pre", "type": "collect", "puzzle": "cipher", "kind": "document", "label": "Przeczytaj plan obrony", "count": 3, "positions": [A, B, I], "text": "Zbierz plany obrony miasta", "required": true,
				"clues": ["„Brama północna zostanie otwarta o północy. Hasło: «czarne pióro».”", "„Główny plac strzeże kapitan. Ma słabość do wiernych sług.”", "„Cywile zamknięci w piwnicach ratusza. Uwolnić po bitwie.”"], "reward": {"gold": 90}},
			{"id": "cywile", "phase": "pre", "type": "free", "puzzle": "lockpick", "kind": "cage", "label": "Uwolnij cywila", "count": 2, "positions": [G, J], "text": "Uwolnij uwięzionych cywilów (opcjonalnie)", "required": false,
				"reward": {"gold": 140, "items": {"krysztal_cienia": 1}, "xp": 110}},
		],
	},
	"uwolnij_krolowa": {
		"npcs": ["lila", "skarbnik"],
		"dialogs": {
			"lila": {
				"pre": [["Pokojówka Lila", "Królowa jest na szczycie wieży. Strażnicy zabrali klucze, ale ja widziałam, gdzie je ukryli."], ["Pokojówka Lila", "Dowódca straży nosi jeden klucz, resztę rozrzucono po wieży. Szukaj części klucza!"]],
				"choice": {"prompt": "Lila drży ze strachu. Zabierasz ją ze sobą?", "options": [
					{"text": "Zostań tu, bądź bezpieczna.", "flag": "lila_zostaje", "reply": "„Będę się modlić za ciebie.”", "final": {"gold": 60}},
					{"text": "Chodź za mną, pokażesz drogę.", "flag": "lila_idzie", "reply": "„Pokażę ci ukryte przejścia!”", "final": {"items": {"sztabka_kurczalu": 1}}},
				]},
				"post": [["Pokojówka Lila", "Królowa wolna! Nareszcie!"]],
			},
			"skarbnik": {
				"pre": [["Stary Skarbnik", "Przez dwa lata liczyłem monety królowej. Potem Kruk kazał mi je oddać. Odmówiłem."], ["Stary Skarbnik", "Jeśli pokonasz dowódcę, w jego pasie znajdziesz drugi klucz. Cele otwiera się dwoma."]],
				"post": [["Stary Skarbnik", "Wolność... zapomniałem, jak pachnie."]],
			},
		},
		"objectives": [
			{"id": "swiadkowie", "phase": "pre", "type": "talk", "npcs": ["lila", "skarbnik"], "text": "Porozmawiaj ze świadkami w wieży", "required": true},
			{"id": "klucze", "phase": "pre", "type": "collect", "puzzle": "pairs", "kind": "document", "label": "Podnieś część klucza", "count": 3, "positions": [E, B, I], "text": "Znajdź części klucza do cel", "required": true,
				"clues": ["Kawałek żelaznego klucza z wygrawerowaną koroną.", "Środek klucza — brzeszczot z fragmentem pieczęci.", "Rękojeść klucza z napisem: «Tylko dla Aurelii».”"], "reward": {"gold": 100}},
			{"id": "zaloga", "phase": "pre", "type": "free", "puzzle": "lockpick", "kind": "cage", "label": "Uwolnij jeńca", "count": 2, "positions": [G, J], "text": "Uwolnij jeńców z cel (opcjonalnie)", "required": false,
				"reward": {"gold": 150, "items": {"eliksir_mocy": 1}, "xp": 130}},
			{"id": "krolowa", "phase": "post", "type": "free", "puzzle": "lockpick", "kind": "cage", "label": "Uwolnij królową Aurelię", "count": 1, "positions": [Vector2(1100, 420)], "text": "Uwolnij królową Aurelię na szczycie wieży", "required": true,
				"reward": {"gold": 200, "xp": 150}},
		],
	},
	"trojka_prob": {
		"npcs": ["druid", "mira"],
		"dialogs": {
			"druid": {
				"pre": [["Stary Druid", "Trzy próby: odwagi, mądrości i współczucia. Każda ma swój kamień, rozsiany po gaju."], ["Stary Druid", "Ten, kto zbierze trzy kamienie, obudzi serce lasu. Ale strażnik gaju nie ustąpi bez walki."]],
				"choice": {"prompt": "Druid pyta: czy chcesz zostać pod opieką lasu?", "options": [
					{"text": "Przyjmuję opiekę lasu.", "flag": "druid_blogoslawienstwo", "reply": "„Niech korzenie cię wspierają.”", "final": {"items": {"mikstura_miodu": 3}}},
					{"text": "Nie potrzebuję błogosławieństw.", "flag": "druid_bez", "reply": "„Jak zechcesz. Las zapamięta twoją dumę.”", "final": {"gold": 120}},
				]},
				"post": [["Stary Druid", "Las uznał cię za godnego. Idź, i niech wiatr niesie ci pióra."]],
			},
			"mira": {
				"pre": [["Łowczyni Mira", "Gaj pilnuje Generał Kruków, elitarny strażnik w zbroi z księżycowym piórem — pokonaj go, a gaj się uspokoi."], ["Łowczyni Mira", "Uważaj na ich skrzydła. Uderzają z góry."]],
				"post": [["Łowczyni Mira", "Tropiłam wielu, ale taki jak ty to rzadkość."]],
			},
		},
		"objectives": [
			{"id": "swiadkowie", "phase": "pre", "type": "talk", "npcs": ["druid", "mira"], "text": "Porozmawiaj z druidem i łowczynią", "required": true},
			{"id": "kamienie", "phase": "pre", "type": "collect", "puzzle": "cipher", "kind": "document", "label": "Podnieś Kamień Próby", "count": 3, "positions": [A, F, J], "text": "Zbierz trzy Kamienie Prób", "required": true,
				"clues": ["Kamień Odwagi: ciepły i ciężki, jakby tętnił.", "Kamień Mądrości: gładki, jak oślepiający szafir.", "Kamień Współczucia: miękki, pachnie żywicą."], "reward": {"gold": 110, "xp": 90}},
			{"id": "elita", "phase": "pre", "type": "elite", "enemy": "krol_krukow", "name": "Generał Kruków", "pos": Vector2(1100, 1000), "text": "Pokonaj Generała Kruków, elitarnego strażnika gaju (opcjonalnie)", "required": false,
				"reward": {"gold": 160, "items": {"sztabka_kurczalu": 1, "krysztal_cienia": 1}, "xp": 180}},
		],
	},
	"marsz_na_forteca": {
		"npcs": ["kapitan", "kucharz"],
		"dialogs": {
			"kapitan": {
				"pre": [["Kapitan Wojsk Korony", "Forteca Czarnego Kruka stoi na skale. Brama jest niezdobyta, chyba że zniszczymy machiny oblężnicze wroga."], ["Kapitan Wojsk Korony", "Zbierz mapy fortecy, to pomoże nam wybrać punkt natarcia."]],
				"choice": {"prompt": "Kapitan pyta o plan natarcia. Co proponujesz?", "options": [
					{"text": "Uderzmy od frontu — szybko i mocno.", "flag": "marsz_front", "reply": "„Odważnie! Armia pójdzie za tobą.”", "final": {"gold": 160}},
					{"text": "Obejdźmy fortecę — mniej strat.", "flag": "marsz_obejscie", "reply": "„Rozważnie. Zadbam o zapasy.”", "final": {"items": {"eliksir_mocy": 2}}},
				]},
				"post": [["Kapitan Wojsk Korony", "Brama runęła! Do ataku, wojsko!"]],
			},
			"kucharz": {
				"pre": [["Kucharz Polowy Stach", "Nikt nie walczy na pusty brzuch. Weź to, bohaterze, i nie daj się zjeść."], ["Kucharz Polowy Stach", "Wróg ma trzy machiny przy palisadzie. Spal je — oszczędzisz mnóstwo żywotów."]],
				"post": [["Kucharz Polowy Stach", "Zupa dla bohatera! Smacznego."]],
			},
		},
		"objectives": [
			{"id": "swiadkowie", "phase": "pre", "type": "talk", "npcs": ["kapitan", "kucharz"], "text": "Zgłoś się do kapitana i kucharza", "required": true},
			{"id": "mapy", "phase": "pre", "type": "collect", "puzzle": "pairs", "kind": "document", "label": "Przeczytaj fragment mapy", "count": 3, "positions": [A, C, J], "text": "Zbierz fragmenty mapy fortecy", "required": true,
				"clues": ["Mapa: brama główna, dwie wieże, wąska droga do dziedzińca.", "Mapa: boczne wejście przez kuźnię — słabo strzeżone.", "Mapa: sala tronowa na szczycie. Czarny Kruk śpi w ostatniej komnacie."], "reward": {"gold": 120}},
			{"id": "machiny", "phase": "pre", "type": "sabotage", "puzzle": "reflex", "kind": "crate", "label": "Zniszcz machinę oblężniczą", "count": 3, "positions": [F, H, I], "text": "Zniszcz machiny oblężnicze wroga", "required": true,
				"reward": {"gold": 180, "items": {"sztabka_kurczalu": 1}, "xp": 140}},
		],
	},
	"krol_i_kruk": {
		"npcs": ["pierzak", "obronca"],
		"dialogs": {
			"pierzak": {
				"pre": [["Spiskowiec Pierzak", "Uciekłem z komnat Czarnego Kruka. Jego moc czerpie z krwi pisklaków — z ich strachu."], ["Spiskowiec Pierzak", "Zbierz trzy pióra cienia, rozsypane po komnacie. Osłabią jego pierwszą ochronę."]],
				"choice": {"prompt": "Pierzak błaga, byś go nie wydał. Co robisz?", "options": [
					{"text": "Daję ci słowo. Uciekaj.", "flag": "pierzak_wolny", "reply": "„Nie zapomnę tej łaski.”", "final": {"gold": 220}},
					{"text": "Idę prosto do straży.", "flag": "pierzak_wydany", "reply": "Pierzak blednie. „To... było konieczne?”", "final": {"items": {"eliksir_mocy": 2, "krysztal_cienia": 1}}},
				]},
				"post": [["Spiskowiec Pierzak", "Czarny Kruk... pokonany. Ale jego cień jeszcze wróci."]],
			},
			"obronca": {
				"pre": [["Ostatni Obrońca", "Pamiętam czasy, gdy Kruk był tylko kruczkiem. Zazdrość zmieniła go w potwora."], ["Ostatni Obrońca", "Jest szybki, a w gniewie przywołuje stado. Nie daj się zapędzić w kozi róg!"]],
				"post": [["Ostatni Obrońca", "Wygrałeś. Tej nocy królestwo odetchnie."]],
			},
		},
		"objectives": [
			{"id": "swiadkowie", "phase": "pre", "type": "talk", "npcs": ["pierzak", "obronca"], "text": "Wysłuchaj zbiega i obrońcy", "required": true},
			{"id": "pioro", "phase": "pre", "type": "collect", "puzzle": "cipher", "kind": "document", "label": "Podnieś Pióro Cienia", "count": 3, "positions": [A, B, I], "text": "Zbierz trzy Pióra Cienia (przygotowanie do bossa)", "required": true,
				"clues": ["Pióro Cienia: szepcze imię Kruka.", "Pióro Cienia: chłodne jak lód i ostre jak sztylet.", "Pióro Cienia: znaczy drogę do komnaty tronowej."], "reward": {"gold": 150, "items": {"eliksir_mocy": 1}}},
			{"id": "elita", "phase": "pre", "type": "elite", "enemy": "orzel_szarak", "name": "Strażnik Komnaty", "pos": Vector2(1100, 1050), "text": "Pokonaj elitarnego strażnika komnaty (opcjonalnie)", "required": false,
				"reward": {"gold": 220, "items": {"sztabka_kurczalu": 2}, "xp": 260}},
			{"id": "zakladnicy", "phase": "post", "type": "free", "puzzle": "lockpick", "kind": "cage", "label": "Uwolnij zakładnika", "count": 2, "positions": [Vector2(900, 420), Vector2(1300, 420)], "text": "Uwolnij zakładników Czarnego Kruka", "required": true,
				"reward": {"gold": 300, "xp": 300}},
		],
	},
	"cien_w_popiele": {
		"npcs": ["popielnik"],
		"dialogs": {
			"popielnik": {
				"pre": [["Popielnik Szary", "Tu nie ma już nic prócz popiołu. A jednak coś patrzy. Cień Kruka krąży po zgliszczach."], ["Popielnik Szary", "Dokumenty zdrajców zostały pod gruzami. Wyciągnij trzy, a dowiesz się, kogo ścigasz."]],
				"choice": {"prompt": "Popielnik prosi o amulet na szczęście. Co robisz?", "options": [
					{"text": "Daj mu 60 złota.", "flag": "popielnik_dar", "reply": "„Ogrzeję się nim w zimie.”", "cost": 60, "final": {"items": {"sztabka_kurczalu": 2}}},
					{"text": "Nie mam nic do oddania.", "flag": "popielnik_brak", "reply": "„Tak bywa.”"},
				]},
				"post": [["Popielnik Szary", "Cień rozwiał się, ale zgliszcza pamiętają."]],
			},
		},
		"objectives": [
			{"id": "swiadkowie", "phase": "pre", "type": "talk", "npcs": ["popielnik"], "text": "Porozmawiaj z Popielnikiem", "required": true},
			{"id": "gruzy", "phase": "pre", "type": "collect", "puzzle": "pairs", "kind": "document", "label": "Wygrzeb dokument", "count": 3, "positions": [A, C, J], "text": "Wydobądź dokumenty spod gruzów", "required": true,
				"clues": ["Dokument: spis agentów w koronie.", "Dokument: rozkaz o spaleniu spichlerzy.", "Dokument: «Cień nie ginie — wraca z popiołu»."], "reward": {"gold": 160}},
			{"id": "jency", "phase": "pre", "type": "free", "puzzle": "lockpick", "kind": "cage", "label": "Uwolnij jeńca", "count": 2, "positions": [G, B], "text": "Uwolnij jeńców Cienia (opcjonalnie)", "required": false,
				"reward": {"gold": 180, "items": {"krysztal_cienia": 1}, "xp": 200}},
		],
	},
	"zdrada_w_koronie": {
		"npcs": ["kasztelan"],
		"dialogs": {
			"kasztelan": {
				"pre": [["Kasztelan Fryderyk", "Kanclerz Sępik wynosi skarbiec po kawałku. Nikt nie chce uwierzyć, że ten miły urzędnik to zdrajca."], ["Kasztelan Fryderyk", "W ratuszu są księgi. Znajdź trzy tomy, to będzie dowód."]],
				"choice": {"prompt": "Fryderyk proponuje przekupić strażnika. Co robisz?", "options": [
					{"text": "Przekupić (80 zł) — ominąć walkę.", "flag": "fryderyk_przekupstwo", "reply": "„Uczciwie? Nie. Skutecznie? Tak.”", "cost": 80, "final": {"gold": 200}},
					{"text": "Nie. Pokonam go.", "flag": "fryderyk_uczciwie", "reply": "„Szlachetnie. Ale daleko tak nie zajdziesz.”", "final": {"items": {"eliksir_mocy": 2}}},
				]},
				"post": [["Kasztelan Fryderyk", "Sędziowie zbiorą dowody. Dziękuję w imieniu korony."]],
			},
		},
		"objectives": [
			{"id": "swiadkowie", "phase": "pre", "type": "talk", "npcs": ["kasztelan"], "text": "Porozmawiaj z kasztelanem", "required": true},
			{"id": "ksiegi", "phase": "pre", "type": "collect", "puzzle": "cipher", "kind": "document", "label": "Przejrzyj tom ksiąg", "count": 3, "positions": [B, C, I], "text": "Zbierz księgi rachunkowe kanclerza", "required": true,
				"clues": ["Księga: skarbiec uszczuplony o 12 000 złotych koron.", "Księga: wypłaty dla najemników z Gniazda Sępów.", "Księga: «Korona wolna, gdy król milczy»."], "reward": {"gold": 180}},
			{"id": "skladzik", "phase": "pre", "type": "sabotage", "puzzle": "lockpick", "kind": "crate", "label": "Otwórz skrytkę kanclerza", "count": 3, "positions": [F, H, J], "text": "Wyłam skrytki kanclerza (opcjonalnie)", "required": false,
				"reward": {"gold": 220, "items": {"sztabka_kurczalu": 2}, "xp": 220}},
		],
	},
	"pustynny_trakt": {
		"npcs": ["wedrowiec"],
		"dialogs": {
			"wedrowiec": {
				"pre": [["Pustynny Wędrowiec", "Piasek wszystko pamięta. Karawany znikają co noc, a Sęp Zwiadowca zbiera daninę."], ["Pustynny Wędrowiec", "Są trzy oazy, a w każdej zostawiłem wskazówkę. Zbierz je, a trafisz do jego obozu."]],
				"choice": {"prompt": "Wędrowiec oferuje bukłak wody za dar. Co robisz?", "options": [
					{"text": "Przyjmij bukłak (dar: 50 zł).", "flag": "wedrowiec_woda", "reply": "„Woda to życie. Wracaj żywy.”", "cost": 50, "final": {"items": {"mikstura_miodu": 4}}},
					{"text": "Wystarczy mi własna.", "flag": "wedrowiec_nic", "reply": "„Pustynia lubi pewnych siebie. Do czasu.”", "final": {"gold": 150}},
				]},
				"post": [["Pustynny Wędrowiec", "Karawany znowu pójdą. Pustynia Cię pamięta."]],
			},
		},
		"objectives": [
			{"id": "swiadkowie", "phase": "pre", "type": "talk", "npcs": ["wedrowiec"], "text": "Porozmawiaj z Wędrowcem", "required": true},
			{"id": "oazy", "phase": "pre", "type": "collect", "puzzle": "pairs", "kind": "document", "label": "Odczytaj wskazówkę", "count": 3, "positions": [A, C, J], "text": "Zbierz wskazówki z trzech oaz", "required": true,
				"clues": ["Oaza północna: ślady kilkudziesięciu sępów.", "Oaza wschodnia: popiół po obozie, ślady skrzyń.", "Oaza południowa: kamienny znak z wizerunkiem Cesarza."], "reward": {"gold": 190}},
			{"id": "elita", "phase": "pre", "type": "elite", "enemy": "sep", "name": "Pustynny Łowca", "pos": Vector2(1100, 1000), "text": "Pokonaj pustynnego łowcę (opcjonalnie)", "required": false,
				"reward": {"gold": 260, "items": {"sztabka_kurczalu": 2}, "xp": 300}},
		],
	},
	"gniazdo_nad_burza": {
		"npcs": ["rybak", "szamanka"],
		"dialogs": {
			"rybak": {
				"pre": [["Rybak Burzy", "Burza nigdy nie przestaje. Tu, w gnieździe, każdy błysk to wyrok Wieszczki Sowy."], ["Rybak Burzy", "W jaskiniach pod skałą chowają się uciekinierzy. Pomóż im."]],
				"post": [["Rybak Burzy", "Fale ucichły. Pierwszy raz od lat."]],
			},
			"szamanka": {
				"pre": [["Szamanka Wichura", "Wieszczka przepowiedziała twoją porażkę. Ale przepowiednie lubią się mylić."], ["Szamanka Wichura", "Zbierz trzy znaki burzy, a odsłonią ci jej słabość."]],
				"choice": {"prompt": "Wichura oferuje rytuał ochronny. Zgadzasz się?", "options": [
					{"text": "Zgadzam się (60 zł).", "flag": "wichura_rytual", "reply": "„Niech burza cię omija.”", "cost": 60, "final": {"items": {"eliksir_mocy": 2}}},
					{"text": "Wolę polegać na sobie.", "flag": "wichura_bez", "reply": "„Odważnie.”", "final": {"gold": 200}},
				]},
				"post": [["Szamanka Wichura", "Przepowiednia pęknęła. Nowe czasy nadchodzą."]],
			},
		},
		"objectives": [
			{"id": "swiadkowie", "phase": "pre", "type": "talk", "npcs": ["rybak", "szamanka"], "text": "Porozmawiaj z mieszkańcami gniazda", "required": true},
			{"id": "znaki", "phase": "pre", "type": "collect", "puzzle": "cipher", "kind": "document", "label": "Odczytaj znak burzy", "count": 3, "positions": [A, B, I], "text": "Zbierz trzy znaki burzy", "required": true,
				"clues": ["Znak: runa piorunów, wyryta w skale.", "Znak: pióro owinięte srebrnym drutem.", "Znak: kamień z odciskiem sowich szponów."], "reward": {"gold": 220}},
			{"id": "uciekinierzy", "phase": "pre", "type": "free", "puzzle": "lockpick", "kind": "cage", "label": "Uwolnij uciekiniera", "count": 3, "positions": [G, J, D], "text": "Uwolnij uciekinierów z jaskiń (opcjonalnie)", "required": false,
				"reward": {"gold": 300, "items": {"sztabka_kurczalu": 2}, "xp": 340}},
		],
	},
	"ostatni_swit": {
		"npcs": ["gwardzista", "zakladnik"],
		"dialogs": {
			"gwardzista": {
				"pre": [["Gwardzista Świtu", "Cesarz Sępów zamknął się w sali tronowej. Jego gwardia stoi na każdym schodku."], ["Gwardzista Świtu", "Zbierz trzy sygnety cesarskie. Pozwolą ci wejść do komnaty bez alarmu."]],
				"post": [["Gwardzista Świtu", "Świt wstaje nad zamkiem. Zwyciężyłeś."]],
			},
			"zakladnik": {
				"pre": [["Zakładniczka Aurelia", "Dziękuję, że jeszcze walczysz. Cesarz nie zna miłosierdzia, więc nie miej go i ty."], ["Zakładniczka Aurelia", "Gdy zadasz mu ostatni cios, zagrają trąby świtu. Nikt nie zapomni twojego imienia."]],
				"choice": {"prompt": "Aurelia pyta, co zrobisz po zwycięstwie.", "options": [
					{"text": "Wrócę do wioski, do zwykłego życia.", "flag": "swit_wioska", "reply": "„Zasłużyłeś na spokój.”", "final": {"gold": 400}},
					{"text": "Będę bronić korony do końca.", "flag": "swit_korona", "reply": "„Królestwo zyska bohatera.”", "final": {"items": {"sztabka_kurczalium": 1}}},
				]},
				"post": [["Zakładniczka Aurelia", "Świt wstał. Dziękuję, mój bohaterze."]],
			},
		},
		"objectives": [
			{"id": "swiadkowie", "phase": "pre", "type": "talk", "npcs": ["gwardzista", "zakladnik"], "text": "Porozmawiaj ze strażnikiem i królową", "required": true},
			{"id": "sygnety", "phase": "pre", "type": "collect", "puzzle": "pairs", "kind": "document", "label": "Podnieś sygnet", "count": 3, "positions": [A, C, J], "text": "Zbierz trzy sygnety cesarskie", "required": true,
				"clues": ["Sygnet: złoty, z wizerunkiem sępa.", "Sygnet: czerwony kamień, ciężki od gniewu.", "Sygnet: pęknięty — ktoś chciał go zniszczyć."], "reward": {"gold": 300}},
			{"id": "elita", "phase": "pre", "type": "elite", "enemy": "sep", "name": "Strażnik Cesarski", "pos": Vector2(1100, 1000), "text": "Pokonaj strażnika cesarskiego (opcjonalnie)", "required": false,
				"reward": {"gold": 400, "items": {"sztabka_kurczalu": 2}, "xp": 450}},
		],
	},
}

# ------------------------------------------------------------------ pomocnicze ---

static var NPCS: Dictionary = BASE_NPCS.merged(Act2DB.NPCS).merged(PalaceDB.NPCS).merged(SpecialDB.NPCS)
static var EXTRAS: Dictionary = DecisionDB.annotate(SpecialDB.patch(PalaceDB.patch_extras(_with_bard(BASE_EXTRAS).merged(Act2DB.EXTRAS)).merged(PalaceDB.EXTRAS).duplicate(true)))

## Wędrowny bard Kukuryk śpiewa w kolejnych rozdziałach jedną długą „Pieśń o Pierwszym Kogucie”.
## Rozmowa z nim jest dobrowolna (nagroda za wysłuchanie), a w ostatnim rozdziale pieśń kończy się wyborem.
const BARD_TALES := {
	"obrona_wioski": [
		["Bard Kukuryk", "Cóż to za pióra w tej wsi! Ja, Kukuryk, wędrowny bard, zbieram opowieści o odwadze. Posłuchaj pierwszej zwrotki."],
		["Bard Kukuryk", "„Dawno temu, gdy świat był tylko jednym wielkim kurnikiem, wstał Pierwszy Kogut i zapiał tak głośno, że noc uciekła za góry.”"],
		["Bard Kukuryk", "Pieśni jest dwanaście zwrotek. Znajdziesz mnie w każdym miejscu, w którym będzie coś do opowiedzenia."],
	],
	"droga_do_stolicy": [
		["Bard Kukuryk", "Och, znowu ty! Szedłem tym traktem za tobą, ale ty biegasz szybciej, niż piszę wiersze."],
		["Bard Kukuryk", "„Pierwszy Kogut miał grzebień z czerwonego złota. Ptaki z całego świata przychodziły się nim ogrzać.”"],
		["Bard Kukuryk", "„Lecz złoto budzi zazdrość. Pewien młody kruk zapragnął grzebienia tylko dla siebie.”"],
	],
	"atak_na_stolice": [
		["Bard Kukuryk", "Przyznam, że śpiewałem w piwnicy, ale ludzie... to znaczy ptaki, klaskały. Trzecia zwrotka!"],
		["Bard Kukuryk", "„Kruk poprosił Koguta o jedno pióro. Kogut dał dwa. Kruk poprosił o trzecie, a Kogut roześmiał się i odmówił.”"],
		["Bard Kukuryk", "„I wtedy po raz pierwszy w kurniku zrobiło się cicho.”"],
	],
	"uwolnij_krolowa": [
		["Bard Kukuryk", "Wieża to dobre miejsce na pieśń — dźwięk niesie się aż do chmur. Czwarta zwrotka, jeśli pozwolisz."],
		["Bard Kukuryk", "„Aurelia, pierwsza królowa, była córką Koguta. Gdy ojciec zniknął, objęła tron i zapaliła na wieży latarnię.”"],
		["Bard Kukuryk", "„Póki latarnia płonie, mówiła, ojciec znajdzie drogę do domu.”"],
	],
	"trojka_prob": [
		["Bard Kukuryk", "Gaj! Nigdzie nie śpiewa się tak czysto. Posłuchaj, tu zwrotka o trzech kamieniach."],
		["Bard Kukuryk", "„Odwaga, Mądrość i Współczucie leżały w gnieździe Koguta. Kruk ukradł je i rozsypał po świecie.”"],
		["Bard Kukuryk", "„Kto zbierze wszystkie trzy, ten usłyszy, dokąd odszedł Pierwszy Kogut.”"],
	],
	"marsz_na_forteca": [
		["Bard Kukuryk", "Obóz wojenny pachnie zupą i strachem. Zaśpiewam coś na otuchę — szósta zwrotka."],
		["Bard Kukuryk", "„Kruk zbudował fortecę na skale, by nikt nie dosięgnął jego łupów. Zapomniał tylko, że skały też mają szczeliny.”"],
		["Bard Kukuryk", "„Przez szczelinę wpadło światło. Przez światło wszedł ktoś, kto się nie bał.”"],
	],
	"krol_i_kruk": [
		["Bard Kukuryk", "Siódma zwrotka jest smutna. Obiecaj, że nie będziesz płakać w pióra."],
		["Bard Kukuryk", "„Kruk nie urodził się zły. Zazdrość wzrastała w nim jak chwast, aż zagłuszyła wszystko, co dobre.”"],
		["Bard Kukuryk", "„A gdy był już wielki, spojrzał w lustro i zobaczył tylko czarne pióra. Wtedy zrozumiał, że za późno.”"],
	],
	"cien_w_popiele": [
		["Bard Kukuryk", "Zgliszcza... Dobre miejsce, by pomyśleć o tym, co przeminęło. Ósma zwrotka."],
		["Bard Kukuryk", "„Cień Kruka nie chciał zemsty. Chciał, by ktoś wreszcie go zrozumiał.”"],
		["Bard Kukuryk", "„Lecz nikt nie słuchał cieni, więc ten stał się głośniejszy od burzy.”"],
	],
	"zdrada_w_koronie": [
		["Bard Kukuryk", "Kancelarie, księgi, pieczątki! Dziewiąta zwrotka opowiada o tym, że zdrada najczęściej nosi garnitur."],
		["Bard Kukuryk", "„Kanclerz uśmiechał się do wszystkich i liczył cudze monety. Ptaki ufały mu, bo miał miły głos.”"],
		["Bard Kukuryk", "„Miły głos to najlepsze przebranie dla fałszu.”"],
	],
	"pustynny_trakt": [
		["Bard Kukuryk", "Piasek w dziobie, ale pieśń gotowa! Dziesiąta zwrotka, na dwa głosy: mój i wiatru."],
		["Bard Kukuryk", "„Pierwszy Kogut wędrował przez pustynię trzy dni i trzy noce. Czwartego dnia usłyszał echo własnego piania.”"],
		["Bard Kukuryk", "„Wtedy pojął, że nie jest sam — że gdzieś daleko ktoś odpowiada.”"],
	],
	"gniazdo_nad_burza": [
		["Bard Kukuryk", "Burza! Idealna oprawa dla jedenastej zwrotki. Krzycz, jeśli nie słyszysz."],
		["Bard Kukuryk", "„Wieszczka Sowa widziała przyszłość, ale nie widziała, jak ją zmienić. Dlatego bała się wszystkiego.”"],
		["Bard Kukuryk", "„Przyszłość, mówił Kogut, nie jest wyryta w kamieniu. Jest pisana piórem — i każdy ma własne.”"],
	],
	"ostatni_swit": [
		["Bard Kukuryk", "Ostatnia zwrotka. Chyba jeszcze nigdy tak się nie denerwowałem. Pozwól, że zaśpiewam."],
		["Bard Kukuryk", "„Gdy nad zamkiem wstał świt, Pierwszy Kogut zapiał po raz ostatni. Nie z żalu — z radości, że kurnik znów ma obrońców.”"],
		["Bard Kukuryk", "„A obrońcą może być każdy, kto nie odwróci wzroku, gdy robi się ciemno.” Koniec pieśni."],
	],
}

static func _with_bard(base: Dictionary) -> Dictionary:
	var src: Dictionary = base.duplicate(true)
	var ids: Array = BARD_TALES.keys()
	for n in ids.size():
		var zid: String = ids[n]
		if not src.has(zid):
			continue
		var ex: Dictionary = src[zid]
		var npcs: Array = ex.get("npcs", [])
		if "bard" not in npcs:
			npcs.append("bard")
		ex["npcs"] = npcs
		var dialogs: Dictionary = ex.get("dialogs", {})
		var d := {
			"pre": BARD_TALES[zid],
			"post": [["Bard Kukuryk", "Zwrotka %d z 12 zapisana. Pieśń rośnie, a ty razem z nią." % (n + 1)]],
		}
		if zid == "ostatni_swit":
			d["choice"] = {"prompt": "Kukuryk pyta: jak ma się kończyć pieśń o Pierwszym Kogucie?", "options": [
				{"text": "O tym, kto zapiał pierwszy.", "flag": "bard_kogut", "reply": "„Piękne. Pierwszy Kogut będzie żył w każdym świcie.”", "final": {"gold": 250}},
				{"text": "O tym, kto nie odwrócił wzroku.", "flag": "bard_ty", "reply": "„Odważnie! W pieśni zapiszę twoje imię zaraz obok jego.”", "final": {"items": {"sztabka_kurczalium": 1}}},
			]}
		dialogs["bard"] = d
		ex["dialogs"] = dialogs
		var objs: Array = ex.get("objectives", [])
		objs.append({"id": "bard", "phase": "pre", "type": "talk", "npcs": ["bard"], "text": "Wysłuchaj zwrotki barda Kukuryka (opcjonalnie)", "required": false,
			"reward": {"gold": 40 + 15 * n, "xp": 30 + 15 * n}})
		ex["objectives"] = objs
	# Włamanie: w kancelarii kanclerza strażnicy skonfiskowali bardowi lutnię.
	var heist: Dictionary = src["zdrada_w_koronie"]
	(heist["objectives"] as Array).append(HEIST)
	return src

## Zadanie skradankowe: przemknij obok strażników (stożki wzroku), zwędź lutnię i zanieś ją bardowi.
## Zauważenie wraca gracza na start. Cel liczy się dopiero po oddaniu lutni (flaga indeksu 0).
const HEIST := {
	"id": "lutnia", "phase": "pre", "type": "heist", "required": false,
	"text": "Zwędź lutnię Kukuryka z gabinetu kanclerza i zanieś ją bardowi (opcjonalnie)",
	"label": "Zwędź lutnię", "start": Vector2(300, 1300), "pos": Vector2(1900, 380),
	"guards": [
		{"path": [Vector2(520, 1180), Vector2(1100, 1180)], "range": 260.0},
		{"path": [Vector2(1500, 1250), Vector2(1500, 800)], "range": 250.0},
		{"path": [Vector2(900, 700), Vector2(1500, 700), Vector2(1500, 560), Vector2(900, 560)], "range": 230.0},
		{"path": [Vector2(1750, 520), Vector2(2050, 520)], "range": 220.0},
	],
	"intro": [["", "Przez okno gabinetu widać lutnię Kukuryka. Strażnicy patrolują dziedziniec — mają stożki wzroku. Skradaj się za ich plecami."]],
	"scene": "lute_gift",
	"thanks": [["Bard Kukuryk", "Moja lutnia! Mój złoty, drewniany skarb! Ukradłeś ją spod nosa strażników?"], ["Bard Kukuryk", "Teraz pieśń zabrzmi jak trzeba. Weź to — i zapamiętaj: nie każdy bohater walczy mieczem."]],
	"reward": {"gold": 220, "xp": 220, "items": {"mikstura_miodu": 2, "zwoj_wskrzeszenia": 1}},
}

## Skradanka bywa też ratunkiem jeńca: przedmiot do zwędzenia, NPC-odbiorca i wróg, którego pokonanie
## odsyła strażników (wartości domyślne to lutnia i bard).
static func heist_item(o: Dictionary) -> String:
	return String(o.get("item", "lutnia_kukuryka"))

static func heist_npc(o: Dictionary) -> String:
	return String(o.get("npc", "bard"))

static func heist_disarmed(zone_id: String, o: Dictionary, fl = null) -> bool:
	var did := String(o.get("disarm", ""))
	if did == "":
		return false
	for x in objectives(zone_id):
		if String(x["id"]) == did:
			return is_done(zone_id, x, fl)
	return false

static func has(zone_id: String) -> bool:
	return EXTRAS.has(zone_id)

static func get_extras(zone_id: String) -> Dictionary:
	return EXTRAS.get(zone_id, {})

static func npc_ids(zone_id: String) -> Array:
	return get_extras(zone_id).get("npcs", [])

static func dialog(zone_id: String, npc_id: String) -> Dictionary:
	return get_extras(zone_id).get("dialogs", {}).get(npc_id, {})

static func objectives(zone_id: String, phase: String = "") -> Array:
	var out: Array = []
	for o in get_extras(zone_id).get("objectives", []):
		if phase == "" or String(o.get("phase", "pre")) == phase:
			out.append(o)
	return out

static func flag(zone_id: String, obj_id: String, i: int = 0) -> String:
	return "o:%s:%s:%d" % [zone_id, obj_id, i]

## Flaga fabuły: z podanego słownika (serwer/klient online) albo z zapisu bieżącej gry.
static func _on(fl, key: String) -> bool:
	if fl is Dictionary:
		return bool((fl as Dictionary).get(key, false))
	return GameState.story_flag(key)

static func count_done(zone_id: String, obj: Dictionary, fl = null) -> int:
	var n := 0
	var total := _total(obj)
	for i in total:
		if _on(fl, flag(zone_id, String(obj["id"]), i)):
			n += 1
	return n

static func _total(obj: Dictionary) -> int:
	match String(obj.get("type", "")):
		"talk":
			return (obj.get("npcs", []) as Array).size()
		"elite":
			return 1
	return int(obj.get("count", 1))

static func is_done(zone_id: String, obj: Dictionary, fl = null) -> bool:
	return count_done(zone_id, obj, fl) >= _total(obj)

static func required_done(zone_id: String, phase: String, fl = null) -> bool:
	for o in objectives(zone_id, phase):
		if bool(o.get("required", false)) and not is_done(zone_id, o, fl):
			return false
	return true

## Lista postępu do dziennika i HUD: [{text, done, count, total, required, phase}]
static func progress(zone_id: String, phase: String = "", fl = null) -> Array:
	var out: Array = []
	for o in objectives(zone_id, phase):
		out.append({
			"text": String(o["text"]), "done": is_done(zone_id, o, fl), "count": count_done(zone_id, o, fl),
			"total": _total(o), "required": bool(o.get("required", false)), "phase": String(o.get("phase", "pre")),
		})
	return out

static func remaining_text(zone_id: String, phase: String, fl = null) -> String:
	var parts: Array = []
	for p in progress(zone_id, phase, fl):
		if bool(p["required"]) and not bool(p["done"]):
			parts.append("%s (%d/%d)" % [String(p["text"]), int(p["count"]), int(p["total"])])
	return ", ".join(parts)

## Dodatkowa nagroda końcowa za wybory w dialogach (wyliczana przy ukończeniu rozdziału).
static func final_bonus(zone_id: String, fl = null) -> Dictionary:
	var gold := 0
	var items := {}
	for npc_id in get_extras(zone_id).get("dialogs", {}):
		var ch: Dictionary = get_extras(zone_id)["dialogs"][npc_id].get("choice", {})
		for opt in ch.get("options", []):
			if _on(fl, String(opt["flag"])) and opt.has("final"):
				var f: Dictionary = opt["final"]
				gold += int(f.get("gold", 0))
				for it in f.get("items", {}):
					items[it] = int(items.get(it, 0)) + int(f["items"][it])
	return {"gold": gold, "items": items}
