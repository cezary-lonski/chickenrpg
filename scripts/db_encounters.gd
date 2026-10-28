class_name EncounterDB
extends RefCounted
## Spotkania w stylu starych RPG (Baldur's Gate): rozmowy z kilkoma rozwiązaniami zamiast walki.
## Odpowiedzi mogą wymagać złota, przedmiotu albo klasy, a część to PRÓBY UMIEJĘTNOŚCI: rzut k20 + modyfikator
## (cechy, klasa, poziom) kontra poziom trudności. Wybory mają skutki: nagrody, koszty, flagi i reputację.
## Silnik jest wspólny dla gry jednoosobowej i serwera (serwer rzuca kośćmi); spotkanie można rozegrać raz.
##
## Węzeł: {text, options:[…], effects?:{gold,xp,items,rep}} — węzeł bez opcji kończy rozmowę.
## Opcja: {text, next | check:{stat,dc,ok,fail}, cost?, take?:{item:n}, req?:{class:[…], item, flag, noflag}, set?:flag}
## Statystyki prób: urok (Szczęście), sila (Siła), zrecznosc (Szybkość), intelekt (Energia).

const STATS := {
	"urok": {"name": "Urok", "attr": "luck", "classes": {"lady": 3, "mag": 1, "lucznik": 1, "zlodziej": 1}},
	"sila": {"name": "Siła", "attr": "strength", "classes": {"wojownik": 3, "fechmistrz": 1}},
	"zrecznosc": {"name": "Zręczność", "attr": "speed", "classes": {"zlodziej": 3, "lucznik": 2, "fechmistrz": 2}},
	"intelekt": {"name": "Intelekt", "attr": "energy", "classes": {"mag": 3, "lady": 1, "fechmistrz": 1}},
}
const CLASS_NAMES := {"wojownik": "Wojownik", "lucznik": "Łucznik", "fechmistrz": "Fechmistrz", "zlodziej": "Złodziej", "mag": "Mag", "lady": "Lady"}

# Każde spotkanie: NPC (jak w ChapterExtras.NPCS), rozdział, węzły rozmowy.
const LIST := {
	"dezerter": {
		"zone": "obrona_wioski",
		"npc": {"name": "Dezerter Wojtek", "title": "Zbiegły żołnierz", "species": "kogut", "scale": 1.4, "pos": Vector2(1280, 1180), "accent": Color(0.8, 0.6, 0.5), "role": "lore"},
		"start": "a",
		"nodes": {
			"a": {"text": "Siedzący przy dogasającym ognisku kogut w poszarpanym mundurze odwraca dziób. „Nie wołaj straży! Uciekłem, bo Hrabia Sroka kazał nam szarżować na płot. Na płot! Płot się nie bronił, ale zrobił nam krzywdę.”", "options": [
				{"text": "„Wróć do swoich. Wioska potrzebuje każdego.”", "check": {"stat": "urok", "dc": 11, "ok": "ok_wroc", "fail": "fail_wroc"}},
				{"text": "„Wracaj albo zawołam straż.” (zastraszenie)", "check": {"stat": "sila", "dc": 12, "ok": "ok_wroc", "fail": "fail_grozba"}},
				{"text": "Dyskretnie przeszukaj jego plecak. (kradzież)", "check": {"stat": "zrecznosc", "dc": 14, "ok": "ok_kradziez", "fail": "fail_kradziez"}},
				{"text": "Daj mu 40 zł na drogę. „Uciekaj, ale daleko.”", "cost": 40, "next": "ok_datek"},
				{"text": "Zostaw go w spokoju.", "next": "koniec"},
			]},
			"ok_wroc": {"text": "Wojtek długo milczy, po czym wstaje i otrzepuje mundur. „Masz rację. Płot jeszcze mi tego nie wybaczył, ale wrócę.” Wręcza ci swoją manierkę.", "effects": {"xp": 90, "gold": 30, "items": {"mikstura_miodu": 1}, "rep": 1}},
			"fail_wroc": {"text": "„Łatwo ci mówić!” Wojtek spluwa w ognisko. „Zostaw mnie.” Odwraca się plecami. Chyba nie dziś.", "effects": {}},
			"fail_grozba": {"text": "Dezerter wyciąga zardzewiały miecz. „Spróbuj mnie zmusić!” Po chwili jednak go chowa, ale nie zamierza słuchać.", "effects": {"xp": 20}},
			"ok_kradziez": {"text": "W plecaku jest mapa płotu, trzy skarpetki i zawiniątko z monetami. Wojtek niczego nie zauważa. Nie wiesz, czy czujesz się z tym dobrze.", "effects": {"gold": 70, "xp": 60}},
			"fail_kradziez": {"text": "„Złodziej!” Wojtek wyrywa plecak i sam sobie wyjmuje z niego 20 zł, żeby ci oddać. „Za kłopot.” Chyba źle go oceniłeś.", "effects": {"xp": 15, "gold": 20}},
			"ok_datek": {"text": "Wojtek chowa monety. „Pamiętaj: jeśli kiedyś pomyślisz, że płot cię atakuje, to ucieknij. Ja tak zrobiłem.” Znika w krzakach.", "effects": {"xp": 70, "rep": 1}},
			"koniec": {"text": "Zostawiasz go przy ognisku. Ogień trzaska, a ktoś w oddali gdacze piosenkę o płocie.", "effects": {}},
		},
	},
	"celnik": {
		"zone": "droga_do_stolicy",
		"npc": {"name": "Celnik Mosiądz", "title": "Pobiera opłatę za most", "species": "indyk", "scale": 1.5, "pos": Vector2(1160, 780), "accent": Color(0.9, 0.8, 0.4), "role": "lore"},
		"start": "a",
		"nodes": {
			"a": {"text": "Przy kładce stoi indyk z kwitariuszem. „Opłata za przejście: 30 zł. To dla twojego bezpieczeństwa. Most jest bezpieczny, bo ja za niego odpowiadam, a odpowiadam, bo płacisz.”", "options": [
				{"text": "Zapłać 30 zł.", "cost": 30, "next": "zaplata"},
				{"text": "„Sprawa jest pilna, w imieniu Korony.” (perswazja)", "check": {"stat": "urok", "dc": 13, "ok": "ok_urok", "fail": "fail_urok"}},
				{"text": "Przemknij pod kładką, gdy odwróci wzrok. (zręczność)", "check": {"stat": "zrecznosc", "dc": 12, "ok": "ok_przemkniecie", "fail": "fail_przemkniecie"}},
				{"text": "„Zapłacę. Skoro to tak ważne, pokaż regulamin.” (intelekt)", "check": {"stat": "intelekt", "dc": 13, "ok": "ok_regulamin", "fail": "fail_regulamin"}},
				{"text": "Nic nie mów i zawróć.", "next": "koniec"},
			]},
			"zaplata": {"text": "Celnik kłania się, wystawia pokwitowanie i stempluje twoje pióro. „Do zobaczenia przy powrocie.” Kładka skrzypi pod twoim ciężarem, ale trzyma.", "effects": {"xp": 40}},
			"ok_urok": {"text": "Indyk prostuje się z godnością. „W imieniu Korony? Oczywiście. Przepraszam, nie poznałem. Przechodź, a przy okazji weź to, to nasza zniżka dla służb.”", "effects": {"xp": 90, "gold": 40}},
			"fail_urok": {"text": "„W imieniu Korony płacą podwójnie.” Indyk uśmiecha się nieprzyjemnie. Musisz jednak zapłacić.", "effects": {"gold": -30}},
			"ok_przemkniecie": {"text": "Przechodzisz pod belkami i wychodzisz po drugiej stronie, kiedy celnik gania chmurę komarów. Niczego ci to nie kosztowało. Prawie.", "effects": {"xp": 100}},
			"fail_przemkniecie": {"text": "Belka pęka, ty lądujesz w strumieniu, a celnik wystawia ci rachunek za naprawę kładki: 25 zł.", "effects": {"gold": -25, "xp": 10}},
			"ok_regulamin": {"text": "Przeglądasz regulamin. Punkt 7: «Posiadacze piór w kolorze niebieskim są zwolnieni». Masz niebieskie pióro? Celnik rozkłada skrzydła i niechętnie przepuszcza. Dostajesz jeszcze pieczątkę jako pamiątkę.", "effects": {"xp": 110, "items": {"wytrych": 1}}},
			"fail_regulamin": {"text": "Regulamin jest długi, nudny i nikt go nie umie czytać. Tracisz cierpliwość i płacisz.", "effects": {"gold": -30}},
			"koniec": {"text": "Zawracasz. Celnik macha ci skrzydłem. „Do zobaczenia przy mostku!”", "effects": {}},
		},
	},
	"pustelnik": {
		"zone": "atak_na_stolice",
		"npc": {"name": "Pustelnik Zagadkowy", "title": "Mędrzec z rozbitej wieży", "species": "paw", "scale": 1.5, "pos": Vector2(1120, 1250), "accent": Color(0.7, 0.8, 1.0), "role": "lore"},
		"start": "a",
		"nodes": {
			"a": {"text": "Paw o rozczochranym ogonie siedzi nad zwojem. „Zadam ci zagadkę. Odpowiesz dobrze — dostaniesz coś pożytecznego. Odpowiesz źle — posłuchasz mojego wykładu o żywocie kruków. Brzmi tak: ‘Im więcej mam, tym mniej widać. Co to?’”", "options": [
				{"text": "„Ciemność.” (odpowiedź prawidłowa)", "next": "ok"},
				{"text": "„Dym.”", "next": "zle"},
				{"text": "Spróbuj odgadnąć po jego minie. (intelekt)", "check": {"stat": "intelekt", "dc": 11, "ok": "ok_mina", "fail": "zle"}},
				{"text": "Podaj mu miodu zamiast odpowiedzi. (przedmiot: Mikstura Miodu)", "take": {"mikstura_miodu": 1}, "next": "miod"},
				{"text": "Pomiń zagadkę.", "next": "koniec"},
			]},
			"ok": {"text": "„Tak! Ciemność!” Paw klaszcze skrzydłami. „Nikt jeszcze nie zgadł, nawet kruk, który mnie o to samo zapytał. Weź to. Daje światło tam, gdzie go brak.”", "effects": {"xp": 130, "items": {"g_eliksir_duzy": 1}}},
			"zle": {"text": "„Niestety, nie.” Paw wzdycha i zaczyna godzinny wykład o żywocie kruków. Gdy kończy, zaczyna się ściemniać. Na szczęście masz wrażenie, że czegoś się nauczyłeś.", "effects": {"xp": 40}},
			"ok_mina": {"text": "Paw mimowolnie szarpie ogonem w stronę okna, za którym zapada zmierzch. „Czyżbyś…” Mruga. „No dobrze, zgadłeś. Ale metodą nieczystą. Weź nagrodę.”", "effects": {"xp": 110, "items": {"g_eliksir_maly": 2}}},
			"miod": {"text": "Pustelnik rozpływa się nad miodem. „Mądrość nie zna cen, ale zna smak.” Opowiada ci, gdzie ostatnio widziano wojska Kruka. Cenna wiedza.", "effects": {"xp": 100, "gold": 50}},
			"koniec": {"text": "„Zagadki zostaną, wy zginiecie. Wróć, kiedy będziesz mądrzejszy.”", "effects": {}},
		},
	},
	"kupiec": {
		"zone": "uwolnij_krolowa",
		"npc": {"name": "Kupiec Bonifacy", "title": "Chory handlarz", "species": "indyk", "scale": 1.5, "pos": Vector2(1500, 1280), "accent": Color(0.9, 0.75, 0.5), "role": "lore"},
		"start": "a",
		"nodes": {
			"a": {"text": "Przy wozie leży indyk w pelerynie, mocno rozgrzany. „Gorączka… Mam towary, ale nie mam sił. Pomóż mi, a odwdzięczę się.” Obok stoi jego skrzynia, niezamknięta.", "options": [
				{"text": "Podaj mu mieszkankę z apteczki. (przedmiot: Mikstura Miodu)", "take": {"mikstura_miodu": 1}, "next": "pomoc"},
				{"text": "„Posiedzę przy tobie.” (urok)", "check": {"stat": "urok", "dc": 10, "ok": "ok_przy", "fail": "fail_przy"}},
				{"text": "Zajrzyj do jego skrzyni. (kradzież)", "check": {"stat": "zrecznosc", "dc": 13, "ok": "ok_skrzynia", "fail": "fail_skrzynia"}},
				{"text": "Zabierz skrzynię i odejdź. (zastraszenie)", "check": {"stat": "sila", "dc": 9, "ok": "ok_rabunek", "fail": "fail_rabunek"}},
				{"text": "Przejdź obok.", "next": "koniec"},
			]},
			"pomoc": {"text": "Bonifacy wypija miksturę, rumieniec wraca na jego dziób. „Uratowałeś mi życie. Weź, co chcesz z wozu — ale tylko jedno.” Wybierasz solidny wytrych i sakiewkę złota.", "effects": {"xp": 130, "gold": 90, "items": {"wytrych_stalowy": 1}, "rep": 1}},
			"ok_przy": {"text": "Siedzisz przy nim do wieczora. Gorączka mija, wraca humor. „Ludzie tacy jak ty to rzadkość.” Dostajesz drobiazg na pamiątkę.", "effects": {"xp": 90, "gold": 40}},
			"fail_przy": {"text": "Bonifacy chce rozmawiać, a ty chcesz iść. Rozmowa się nie klei. Kupiec zasypia z dąsem.", "effects": {"xp": 10}},
			"ok_skrzynia": {"text": "Na dnie skrzyni leży sakiewka i zestaw drobnych wytrychów. Bierzesz trochę, bez rozgłosu. Kupiec śpi.", "effects": {"gold": 80, "items": {"wytrych_zardzewialy": 2}, "xp": 40}},
			"fail_skrzynia": {"text": "Wieko trzaska, kupiec się budzi. „Złodziej!” Rzuca w ciebie czajnikiem. Tracisz 15 zł (zostały w kałuży).", "effects": {"gold": -15}},
			"ok_rabunek": {"text": "Kupiec jest zbyt słaby, by protestować. Wynosisz skrzynię i dzielisz się łupem z samym sobą. Sumienie szepcze coś o złych uczynkach.", "effects": {"gold": 120, "xp": 30}},
			"fail_rabunek": {"text": "Bonifacy okazuje się silniejszy, niż wyglądał. Wyrzuca cię z wozu za dziób. Skrzynia została na miejscu.", "effects": {}},
			"koniec": {"text": "Mijasz wóz. Z środka dobiega jęk i prośba o wodę. Idziesz dalej.", "effects": {}},
		},
	},
	"sedzia": {
		"zone": "trojka_prob",
		"npc": {"name": "Gospodarz Gniewko", "title": "Skłócony sąsiad", "species": "kurczak", "scale": 1.4, "pos": Vector2(1100, 1100), "accent": Color(0.8, 0.85, 0.5), "role": "lore"},
		"start": "a",
		"nodes": {
			"a": {"text": "Gniewko wymachuje skrzydłami. „On twierdzi, że mój płot stoi na jego ziemi! A ja twierdzę, że jego kura przechodzi na moją stronę po ziarno! Rozsądź nas, bohaterze!” Za płotem stoi drugi gospodarz z kwaśną miną.", "options": [
				{"text": "Przemów do rozsądku obu stron. (urok)", "check": {"stat": "urok", "dc": 12, "ok": "ok_pokoj", "fail": "fail_pokoj"}},
				{"text": "Zmierz grunt i przeanalizuj akty własności. (intelekt)", "check": {"stat": "intelekt", "dc": 13, "ok": "ok_pomiar", "fail": "fail_pomiar"}},
				{"text": "Przesuń płot siłą. (siła)", "check": {"stat": "sila", "dc": 11, "ok": "ok_sila", "fail": "fail_sila"}},
				{"text": "Weź łapówkę od Gniewki: 50 zł za wyrok na jego korzyść.", "set": "enc_lapowka", "next": "lapowka"},
				{"text": "Odejdź. To nie twoja sprawa.", "next": "koniec"},
			]},
			"ok_pokoj": {"text": "Po godzinie obie strony padają sobie w skrzydła. Płot zostaje, kura dostaje przepustkę, a ty — chleb z masłem. „Nie ma jak dobry sąsiad.”", "effects": {"xp": 120, "gold": 40, "rep": 1}},
			"fail_pokoj": {"text": "Obaj gospodarze wykrzykują, że to ty ich obraziłeś. Gdacząc, rozchodzą się w swoje strony.", "effects": {"xp": 15}},
			"ok_pomiar": {"text": "Po godzinie mierzenia stwierdzasz, że płot stoi dokładnie na granicy, a granica na kurzym kopcu. Wyrok: kopiec wspólny. Obaj są zadowoleni, a to zdarza się rzadko.", "effects": {"xp": 140, "gold": 60}},
			"fail_pomiar": {"text": "Miarka się plącze, mapa jest do góry nogami. Obie strony spoglądają na ciebie z politowaniem.", "effects": {"xp": 20}},
			"ok_sila": {"text": "Przesuwasz płot o dwa kroki. Obaj gospodarze zamierają, po czym Gniewko triumfuje, a sąsiad robi się purpurowy. „Siła rozstrzyga,” mówi ktoś w tle.", "effects": {"xp": 60, "gold": 50}},
			"fail_sila": {"text": "Płot przewraca się razem z tobą. Obaj gospodarze śmieją się do łez, a spór się kończy — z braku płotu.", "effects": {"xp": 40}},
			"lapowka": {"text": "Przyjmujesz 50 zł i ogłaszasz wyrok. Sąsiad z płotu rzuca ci spojrzenie, od którego kury stają dęba. Ale kasa jest kasa.", "effects": {"gold": 50, "xp": 20, "rep": -1}},
			"koniec": {"text": "Odchodzisz. Za plecami słyszysz tylko: „…a jego kura!”", "effects": {}},
		},
	},
	"handlarz": {
		"zone": "marsz_na_forteca",
		"npc": {"name": "Handlarz Dziwów", "title": "Wędrowny sprzedawca", "species": "kogut", "scale": 1.4, "pos": Vector2(1320, 1020), "accent": Color(0.95, 0.7, 0.4), "role": "lore"},
		"start": "a",
		"nodes": {
			"a": {"text": "Kogut w kapeluszu z piór prezentuje tacę: kilka błyszczących drobiazgów i butelkę o nieokreślonym kolorze. „Zioła, trunki, talizmany! Dla ciebie specjalnie: Wywar Siły za 60 zł!”", "options": [
				{"text": "Kup Wywar Siły za 60 zł.", "cost": 60, "next": "kupno"},
				{"text": "„Dwadzieścia!” Targuj się. (urok)", "check": {"stat": "urok", "dc": 12, "ok": "ok_targ", "fail": "fail_targ"}},
				{"text": "Sprawdź, czy wywar jest prawdziwy. (intelekt)", "check": {"stat": "intelekt", "dc": 12, "ok": "ok_test", "fail": "fail_test"}},
				{"text": "Weź flaszkę, kiedy nie patrzy. (kradzież)", "check": {"stat": "zrecznosc", "dc": 14, "ok": "ok_kradziez", "fail": "fail_kradziez"}},
				{"text": "Odmów uprzejmie.", "next": "koniec"},
			]},
			"kupno": {"text": "Wywar jest prawdziwy, gorzki i wyraźnie wzmacnia. Handlarz dopisuje cię do księgi stałych klientów.", "effects": {"items": {"g_wywar_sily": 1}, "xp": 40}},
			"ok_targ": {"text": "Po burzliwej dyskusji o rodzie piór, wartości złota i oddechu smoka handlarz opuszcza cenę do 20 zł. Wywar trafia do ciebie, a on wygląda na zachwyconego.", "effects": {"gold": -20, "items": {"g_wywar_sily": 1}, "xp": 100}},
			"fail_targ": {"text": "Handlarz wyciąga kalkulator i wylicza, że przy twojej propozycji traci na każdej kropli. Cena rośnie do 80 zł. Przesadziłeś. Odchodzisz bez zakupu.", "effects": {"xp": 15}},
			"ok_test": {"text": "Wywar jest w istocie rozcieńczoną nalewką z naparstnicy. „Oszuście!” Handlarz blednie i oddaje ci rzeczywisty wywar oraz sakiewkę na pocieszenie.", "effects": {"gold": 50, "items": {"g_wywar_sily": 1}, "xp": 110}},
			"fail_test": {"text": "Smakujesz kroplę i nie wiesz, co to jest. Handlarz klepie cię po plecach. „Prawdziwy znawca!” Zapłacisz 60 zł albo nie weźmiesz wywaru. Odchodzisz.", "effects": {"xp": 10}},
			"ok_kradziez": {"text": "Flaszka ląduje w twoim rękawie, a handlarz widzi tylko pustą tacę. „Dziwne, wydawało mi się…” Głowa mu opada na bok, gdy się zastanawia.", "effects": {"items": {"g_wywar_sily": 1}, "xp": 80}},
			"fail_kradziez": {"text": "Przyłapał cię. „Złodziej! Zapłać czterokrotność!” Musisz oddać 40 zł, by uniknąć skandalu.", "effects": {"gold": -40}},
			"koniec": {"text": "Handlarz kłania się nisko. „Do zobaczenia przy następnym targu, drogi kliencie!”", "effects": {}},
		},
	},
	"wdowa": {
		"zone": "krol_i_kruk",
		"npc": {"name": "Wdowa Pelagia", "title": "Żona poległego strażnika", "species": "kwoka", "scale": 1.3, "pos": Vector2(1000, 1180), "accent": Color(0.8, 0.7, 0.85), "role": "lore"},
		"start": "a",
		"nodes": {
			"a": {"text": "Pelagia siedzi na ławce, przy niej mała torebka. „Mój mąż strzegł tej wieży do końca. Mam jego sakiewkę, ale nie mam serca jej otworzyć. Powiedz mi, co powinnam z nią zrobić?”", "options": [
				{"text": "„Zatrzymaj. To pamiątka.”", "next": "pamiatka"},
				{"text": "„Przekaż ją sierotom wojennym.”", "next": "sieroty"},
				{"text": "„Wydaj na pogrzeb godny bohatera.” (urok)", "check": {"stat": "urok", "dc": 11, "ok": "ok_pogrzeb", "fail": "fail_pogrzeb"}},
				{"text": "„Daj mi, ja się nią zaopiekuję.” (oszustwo)", "check": {"stat": "urok", "dc": 15, "ok": "ok_oszust", "fail": "fail_oszust"}},
				{"text": "Pogłaszcz ją po skrzydle i odejdź.", "next": "koniec"},
			]},
			"pamiatka": {"text": "Pelagia chowa torebkę do kieszeni. „Masz rację. Jej wartość nie jest w monetach.” Z wdzięcznością wręcza ci pamiątkową szpilkę z kołnierza męża.", "effects": {"xp": 110, "items": {"g_pierscien_kuchenny": 1}, "rep": 1}},
			"sieroty": {"text": "Oczy Pelagii błyszczą. „Przekażę wszystko. Mąż by tego chciał.” Twoje imię zostanie zapisane w sierocińcu.", "effects": {"xp": 150, "rep": 2}},
			"ok_pogrzeb": {"text": "Przekonujesz ją, że cały zakład pogrzebowy da pochówek z honorami. Pelagia płacze, dziękuje i obiecuje zająć się wszystkim. Na koniec daje ci grzeczny uścisk i monety za fatygę.", "effects": {"xp": 120, "gold": 30, "rep": 1}},
			"fail_pogrzeb": {"text": "„Pogrzeb? Mój mąż wolał kąpiel w stawie.” Pelagia patrzy w dal. Nie dociera do niej, co chciałeś powiedzieć.", "effects": {"xp": 10}},
			"ok_oszust": {"text": "Wdowa oddaje ci sakiewkę, wierząc, że przekażesz ją sierotom. Wiesz, że tego nie zrobisz. Sakiewka jest ciężka od złota i winy.", "effects": {"gold": 200, "rep": -2}},
			"fail_oszust": {"text": "„Znam twoje oczy. Idź precz!” Pelagia wstaje i odchodzi, wyraźnie zraniona. Nie wiesz, co powiedzieć.", "effects": {"rep": -1}},
			"koniec": {"text": "Pelagia kiwa głową w milczeniu. Zbliża się zmierzch.", "effects": {}},
		},
	},
	"szpieg": {
		"zone": "cien_w_popiele",
		"npc": {"name": "Podróżnik w Kapturze", "title": "Podejrzana postać", "species": "gasior", "scale": 1.4, "pos": Vector2(1450, 1060), "accent": Color(0.6, 0.6, 0.75), "role": "lore"},
		"start": "a",
		"nodes": {
			"a": {"text": "Gąsior w kapturze szepcze coś do własnego kołnierza. Kiedy podchodzisz, milknie. „A, podróżny. Nie przeszkadzaj. Mam ważne sprawy… handlowe. Bardzo handlowe.”", "options": [
				{"text": "Podsłuchaj, o czym szeptał. (zręczność)", "check": {"stat": "zrecznosc", "dc": 12, "ok": "ok_sluch", "fail": "fail_sluch"}},
				{"text": "„Wiem, kim jesteś.” Blefuj. (urok)", "check": {"stat": "urok", "dc": 13, "ok": "ok_blef", "fail": "fail_blef"}},
				{"text": "Przyjrzyj się dokładnie jego ubraniu. (intelekt)", "check": {"stat": "intelekt", "dc": 12, "ok": "ok_ubior", "fail": "fail_ubior"}},
				{"text": "Zaproponuj mu 50 zł za informację.", "cost": 50, "next": "info"},
				{"text": "Zostaw go w spokoju.", "next": "koniec"},
			]},
			"ok_sluch": {"text": "Słyszysz nazwę „Kanclerz Piórko” i datę: «Przy pierwszej pełni». Zakapturzony wysyła list do kogoś w zamku. Możesz teraz użyć tej informacji.", "effects": {"xp": 120, "gold": 40}},
			"fail_sluch": {"text": "Gąsior przerywa w pół słowa, odwraca się i patrzy ci prosto w oczy. „Szpiegowanie jest niegrzeczne.” Nie znasz dalszego ciągu.", "effects": {"xp": 10}},
			"ok_blef": {"text": "Podróżnik bledne. „To nie tak, jak myślisz!” Wręcza ci sakiewkę i prosi, żebyś nic nie mówił. Na dowód zaufania odsłania herb. Jesteś teraz o krok bliżej do prawdy.", "effects": {"xp": 130, "gold": 90}},
			"fail_blef": {"text": "„Wiesz? To ciekawe. Zatem wiesz, że niczego nie wiesz.” Gąsior rozpływa się w tłumie.", "effects": {"xp": 15}},
			"ok_ubior": {"text": "Zauważasz herb Czarnego Kruka, ukryty pod płaszczem. Podróżnik w panice oddaje ci notatnik. Nic w nim nie rozumiesz, ale jest drogocenny.", "effects": {"xp": 140, "items": {"g_pierscien_kuchenny": 1}}},
			"fail_ubior": {"text": "Przyglądasz się z uwagą i nic nie widzisz. Zwykły płaszcz. Zwykłe ubranie. Chyba.", "effects": {"xp": 10}},
			"info": {"text": "Gąsior chowa monety. „Przy pierwszej pełni kruki zaatakują od wschodu.” Znika. Wiedza jest bezcenna, ale spokojnie zapłaciłeś.", "effects": {"xp": 110, "rep": 1}},
			"koniec": {"text": "Zakapturzony wraca do szeptania do własnego kołnierza.", "effects": {}},
		},
	},
	"weteran": {
		"zone": "ostatni_swit",
		"npc": {"name": "Weteran Bogusz", "title": "Stary żołnierz", "species": "kogut", "scale": 1.4, "pos": Vector2(1180, 1230), "accent": Color(0.9, 0.8, 0.55), "role": "lore"},
		"start": "a",
		"nodes": {
			"a": {"text": "Stary kogut stoi pod murem, wsparty na kiju. „Przed wielką bitwą każdy ma coś do powiedzenia. Ty też. Powiedz mi, bohaterze: po co walczysz?”", "options": [
				{"text": "„Dla wioski, w której się wychowałem.”", "next": "wioska"},
				{"text": "„Dla chwały i złota.”", "next": "zloto"},
				{"text": "„Bo nikt inny nie powinien.”", "next": "powinnosc"},
				{"text": "„Nie wiem. Chyba po to, żeby wrócić do domu.” (szczerość)", "check": {"stat": "urok", "dc": 9, "ok": "ok_szczery", "fail": "fail_szczery"}},
				{"text": "Skinąć głową bez słów.", "next": "koniec"},
			]},
			"wioska": {"text": "Bogusz uśmiecha się szeroko. „Dobry powód. Trzymaj się go, kiedy będzie źle.” Wręcza ci medalion, który nosił przez całą wojnę.", "effects": {"xp": 160, "items": {"g_mikstura_duza": 1}, "rep": 1}},
			"zloto": {"text": "„Złoto… ma swoje zalety.” Bogusz wzrusza ramionami. Daje ci sakiewkę ze swoich oszczędności, żebyś na pewno miał po co wracać.", "effects": {"xp": 100, "gold": 120}},
			"powinnosc": {"text": "„Ci, którzy tak mówią, zwykle dożywają starości. Albo nie dożywają wcale. Ale historia ich pamięta.” Przekazuje ci stary sztandar do przeczytania.", "effects": {"xp": 170, "rep": 2}},
			"ok_szczery": {"text": "Weteran milknie i długo patrzy na horyzont. „To najlepsza odpowiedź, jaką słyszałem. Nikt nie powinien walczyć dla czegoś, co jest większe niż jego dom.” Obejmuje cię mocno.", "effects": {"xp": 200, "items": {"wytrych_mistrzowski": 1}, "rep": 1}},
			"fail_szczery": {"text": "Weteran kręci głową. „Takie odpowiedzi pasują do ludzi, którzy już dawno nie wracają.” Odchodzi w milczeniu.", "effects": {"xp": 20}},
			"koniec": {"text": "Bogusz mruga do ciebie porozumiewawczo. „Wracaj cały.”", "effects": {}},
		},
	},
	# ---------------------------------------------- wędrowni podróżnicy (losowe spotkania na Pustkowiu) ---
	"wiedzma": {
		"zone": "", "roam": true,
		"npc": {"name": "Wiedźma Brzoskwinia", "title": "Wędrowna zielarka", "species": "kwoka", "scale": 1.3, "pos": Vector2.ZERO, "accent": Color(0.7, 0.55, 0.85), "role": "lore"},
		"start": "a",
		"nodes": {
			"a": {"text": "Kwoka w kapeluszu z piór przegląda kociołek pośrodku drogi. „Trafił swój na swego. Mam eliksiry, wróżby i gorzkie ziółka. Czego potrzebujesz, podróżny?”", "options": [
				{"text": "„Powróż mi z fusów.” (30 zł)", "cost": 30, "next": "wrozba"},
				{"text": "Poproś o eliksir w zamian za rozmowę. (urok)", "check": {"stat": "urok", "dc": 12, "ok": "ok_urok", "fail": "fail_urok"}},
				{"text": "Zajrzyj do kociołka. (intelekt)", "check": {"stat": "intelekt", "dc": 13, "ok": "ok_intelekt", "fail": "fail_intelekt"}},
				{"text": "Sięgnij po fiolkę ze stołu. (kradzież)", "check": {"stat": "zrecznosc", "dc": 14, "ok": "ok_kradziez", "fail": "fail_kradziez"}},
				{"text": "Odmów i idź dalej.", "next": "koniec"},
			]},
			"wrozba": {"text": "Fusy układają się w kształt miecza, a potem w kształt kapusty. „Czeka cię dużo walki i trochę gotowania.” Dostajesz mały eliksir na drogę.", "effects": {"xp": 60, "items": {"g_eliksir_maly": 1}}},
			"ok_urok": {"text": "Wiedźma śmieje się chrapliwie. „Tak szczerze prosił jeszcze nikt. Masz.” Wręcza ci eliksir energii i szczyptę rozsądku.", "effects": {"xp": 90, "items": {"g_eliksir_duzy": 1}}},
			"fail_urok": {"text": "„Rozmowa kosztuje, miły.” Wiedźma odwraca się plecami do ciebie i miesza w kociołku.", "effects": {"xp": 10}},
			"ok_intelekt": {"text": "W kociołku bulgocze żabie oko, korzeń i coś, co kiedyś było kapeluszem. Zauważasz, że brakuje szczypty soli. Wiedźma jest pod wrażeniem i dzieli się wywarem.", "effects": {"xp": 110, "items": {"g_wywar_zwinnosci": 1}}},
			"fail_intelekt": {"text": "Pochylasz się zbyt blisko i opary uderzają cię w głowę. Przez chwilę widzisz dwa kociołki.", "effects": {"xp": 10}},
			"ok_kradziez": {"text": "Fiolka zniknęła w twoim rękawie szybciej niż sama wiedźma zdążyła mrugnąć. Płyn w środku wygląda na bardzo wartościowy.", "effects": {"items": {"g_mikstura_duza": 1}, "xp": 70}},
			"fail_kradziez": {"text": "„Złodziejko, złodzieju, kto cię uczył manier?” Wiedźma sięga po miotłę, a ty tracisz 25 zł w ucieczce.", "effects": {"gold": -25}},
			"koniec": {"text": "Wiedźma wzrusza ramionami. „Gdyby co, zawsze tu będę. Chyba że nie.”", "effects": {}},
		},
	},
	"rozbitek": {
		"zone": "", "roam": true,
		"npc": {"name": "Rozbitek Ptaszyński", "title": "Zagubiony żeglarz", "species": "gasior", "scale": 1.4, "pos": Vector2.ZERO, "accent": Color(0.6, 0.8, 0.9), "role": "lore"},
		"start": "a",
		"nodes": {
			"a": {"text": "Gąsior w podartej koszuli siedzi na kamieniu i wpatruje się w piasek. „Mój statek rozbił się trzy dni temu. Kapitan uciekł z łodzią. Jedyne, co mam, to ta mapa i trochę dumy.”", "options": [
				{"text": "Daj mu miksturę miodu. (przedmiot: Mikstura Miodu)", "take": {"mikstura_miodu": 1}, "next": "pomoc"},
				{"text": "„Zaprowadzę cię do najbliższej wioski.” (siła)", "check": {"stat": "sila", "dc": 10, "ok": "ok_wioska", "fail": "fail_wioska"}},
				{"text": "Zapytaj o mapę. (intelekt)", "check": {"stat": "intelekt", "dc": 12, "ok": "ok_mapa", "fail": "fail_mapa"}},
				{"text": "Zabierz mu mapę i odejdź. (kradzież)", "check": {"stat": "zrecznosc", "dc": 11, "ok": "ok_kradziez", "fail": "fail_kradziez"}},
				{"text": "Idź dalej.", "next": "koniec"},
			]},
			"pomoc": {"text": "Gąsior wypija miksturę i po chwili wstaje. „Marynarze nie zapominają dobroci.” Wręcza ci coś, co ocalało z wraku: sakiewkę i amulet.", "effects": {"xp": 120, "gold": 70, "items": {"g_amulet_zielarki": 1}, "rep": 1}},
			"ok_wioska": {"text": "Podajesz mu ramię i po kilku godzinach docieracie do skraju wioski. Ptaszyński płacze ze wzruszenia i wciska ci garść monet.", "effects": {"xp": 100, "gold": 60, "rep": 1}},
			"fail_wioska": {"text": "Mylicie drogę, kręcicie się w kółko, a gąsior w końcu zaczyna narzekać. Po godzinie obaj siadacie na kamieniu.", "effects": {"xp": 20}},
			"ok_mapa": {"text": "Na mapie widnieje ukryty szlak, o którym nikt nie słyszał. Ptaszyński oddaje ci kopię bez żalu. „Ja i tak niczego nie widzę bez okularów.”", "effects": {"xp": 120, "items": {"wytrych_stalowy": 1}}},
			"fail_mapa": {"text": "Mapa jest zalana wodą, a jedyny widoczny napis to „tu byli ludzie”. Rozbitek wzdycha.", "effects": {"xp": 10}},
			"ok_kradziez": {"text": "Mapa trafia do twojego plecaka. Gąsior zerka na pusty kamień i wzrusza ramionami. „No tak. Pewnie zabrała fala.”", "effects": {"xp": 40, "gold": 40, "rep": -1}},
			"fail_kradziez": {"text": "„Oddaj mapę!” Gąsior rzuca się na ciebie z kamieniem. Ledwie uchodzisz, tracąc 20 zł.", "effects": {"gold": -20}},
			"koniec": {"text": "Rozbitek wraca do wpatrywania się w piasek.", "effects": {}},
		},
	},
	"kartograf": {
		"zone": "", "roam": true,
		"npc": {"name": "Kartograf Zygmunt", "title": "Wędrowny rysownik map", "species": "indyk", "scale": 1.5, "pos": Vector2.ZERO, "accent": Color(0.9, 0.8, 0.5), "role": "lore"},
		"start": "a",
		"nodes": {
			"a": {"text": "Indyk w okularach siedzi na kamieniu i rysuje coś na ogromnym zwoju. „Ach, podróżny! Rysuję mapę całego Pustkowia. Brakuje mi tylko kilku miejsc i… kilku ludzi do pomocy.”", "options": [
				{"text": "„Kupię kopię za 60 zł.”", "cost": 60, "next": "kupno"},
				{"text": "Pomóż mu z obliczeniami. (intelekt)", "check": {"stat": "intelekt", "dc": 12, "ok": "ok_obliczenia", "fail": "fail_obliczenia"}},
				{"text": "Pochlebiaj jego talentowi. (urok)", "check": {"stat": "urok", "dc": 11, "ok": "ok_pochlebstwo", "fail": "fail_pochlebstwo"}},
				{"text": "Pożegnaj się.", "next": "koniec"},
			]},
			"kupno": {"text": "Zygmunt starannie składa kopię. „Mapa nie wskazuje, gdzie są potwory, tylko gdzie ich nie ma.” Czujesz, że dobrze ci się podróżuje.", "effects": {"xp": 80, "items": {"g_buty_podroznika": 1}}},
			"ok_obliczenia": {"text": "Razem poprawiacie błędy w skali. Kartograf aż klaszcze. „Wreszcie ktoś, kto rozumie proporcje!” Dostajesz nagrodę z dumą.", "effects": {"xp": 130, "gold": 50, "items": {"g_okulary_skarbnika": 1}}},
			"fail_obliczenia": {"text": "Wasze obliczenia dają wynik, według którego Pustkowie jest trzy razy mniejsze od kurnika. Kartograf kręci głową.", "effects": {"xp": 15}},
			"ok_pochlebstwo": {"text": "Zygmunt rumieni się po koniuszki piór. „Naprawdę tak uważasz?” Z wdzięczności wręcza ci drobną mapkę kieszonkową i kilka monet.", "effects": {"xp": 80, "gold": 40}},
			"fail_pochlebstwo": {"text": "„Kłamstwo widać w proporcjach twojego dzioba.” Kartograf wraca do rysowania, urażony.", "effects": {"xp": 10}},
			"koniec": {"text": "Zygmunt macha ci piórem i wraca do rysowania.", "effects": {}},
		},
	},
	"lowca": {
		"zone": "", "roam": true,
		"npc": {"name": "Łowca Kruczy Dziób", "title": "Łowca nagród", "species": "kogut", "scale": 1.45, "pos": Vector2.ZERO, "accent": Color(0.85, 0.4, 0.35), "role": "lore"},
		"start": "a",
		"nodes": {
			"a": {"text": "Pod skałą stoi kogut z kuszą i listem gończym w skrzydle. „Zatrzymaj się, podróżny. Szukam kogoś podobnego do ciebie. Kogoś, za kogo płacą dwieście złotych.”", "options": [
				{"text": "„To nie ja. Pomylił się pan.” (urok)", "check": {"stat": "urok", "dc": 13, "ok": "ok_pomylka", "fail": "fail_pomylka"}},
				{"text": "„Spróbuj mnie zatrzymać.” (siła)", "check": {"stat": "sila", "dc": 13, "ok": "ok_pojedynek", "fail": "fail_pojedynek"}},
				{"text": "Podaj mu 50 zł za zapomnienie sprawy.", "cost": 50, "next": "lapowka"},
				{"text": "Rozprosz go i uciekaj. (zręczność)", "check": {"stat": "zrecznosc", "dc": 12, "ok": "ok_ucieczka", "fail": "fail_ucieczka"}},
				{"text": "Zapytaj, kogo szuka.", "next": "list"},
			]},
			"ok_pomylka": {"text": "Łowca przygląda ci się, marszczy dziób, potem porównuje twarz z listem. „Hm. Mniejszy dziób. Przepraszam, podróżny. Do zobaczenia.” Odchodzi, a ty głęboko oddychasz.", "effects": {"xp": 110}},
			"fail_pomylka": {"text": "„Nie wygląda mi to na pomyłkę.” Łowca zaczyna wyciągać kajdanki, ale w ostatniej chwili uciekasz. Tracisz 30 zł.", "effects": {"gold": -30}},
			"ok_pojedynek": {"text": "Łowca obserwuje cię z podziwem. „Takiego chłopa już dawno nie widziałem. Zostawię cię. Poza tym zaczyna mi się nudzić.” Odchodzi z szacunkiem.", "effects": {"xp": 140, "gold": 40, "rep": 1}},
			"fail_pojedynek": {"text": "Kusza celuje prosto w twój dziób. „Spokojnie. Pójdziesz ze mną.” Ledwo wymykasz się, tracąc 40 zł.", "effects": {"gold": -40}},
			"lapowka": {"text": "Łowca chowa monety i list. „Pomyłka. Prawdziwa pomyłka. Tacy jak ty często się mylą.” Zasalutowawszy, odchodzi.", "effects": {"xp": 70}},
			"ok_ucieczka": {"text": "Rzucasz kamieniem w krzaki. Łowca obraca się z kuszą, a ty znikasz między skałami. Za rogiem zostawiasz mu wiadomość: „Pomyłka. Z poważaniem.”", "effects": {"xp": 100}},
			"fail_ucieczka": {"text": "Kamyk trafia łowcę w kapelusz. Wściekły, ściga cię przez trzy wzgórza. Gubisz sakiewkę, a w końcu i jego.", "effects": {"gold": -35}},
			"list": {"text": "„Kruk Pierzasty. Wykradł z kancelarii plany obrony. A ty, podróżny, nie masz w kieszeni kilku zwojów, prawda?” Przerywa na chwilę. „Nie. Chyba nie.” Chowa list.", "effects": {"xp": 60}},
		},
	},
	"pielgrzym": {
		"zone": "", "roam": true,
		"npc": {"name": "Pielgrzym Natan", "title": "Wędrowny pątnik", "species": "paw", "scale": 1.5, "pos": Vector2.ZERO, "accent": Color(0.9, 0.85, 0.6), "role": "lore"},
		"start": "a",
		"nodes": {
			"a": {"text": "Paw w prostej szacie idzie powoli, wsparty na kiju. „Dokąd zmierzasz, wędrowcze? Ja idę do Świętej Chatki, by prosić o pogodę ducha. Chcesz, pomodlę się też za ciebie.”", "options": [
				{"text": "Poproś o błogosławieństwo.", "next": "blogoslawienstwo"},
				{"text": "Złóż datek na pielgrzymkę. (40 zł)", "cost": 40, "next": "datek"},
				{"text": "Porozmawiaj o sensie podróży. (intelekt)", "check": {"stat": "intelekt", "dc": 12, "ok": "ok_rozmowa", "fail": "fail_rozmowa"}},
				{"text": "Pożegnaj się grzecznie.", "next": "koniec"},
			]},
			"blogoslawienstwo": {"text": "Natan kładzie skrzydło na twojej głowie i mruczy kilka słów. Czujesz spokój. „Idź w pokoju. I nie bij nikogo bez potrzeby.”", "effects": {"xp": 80, "rep": 1}},
			"datek": {"text": "Natan przyjmuje datek z wdzięcznością. „Bóg widzi twoją hojność, a ja widzę twój portfel.” Dostajesz drobny amulet na drogę.", "effects": {"xp": 100, "items": {"g_amulet_straznika": 1}, "rep": 1}},
			"ok_rozmowa": {"text": "Rozmawiacie do zmierzchu o drodze, wojnie i kurzych sprawach. Natan jest pod wrażeniem twojej mądrości i wręcza ci swój stary kij pielgrzyma.", "effects": {"xp": 150, "gold": 30, "items": {"g_kij_pasterski": 1}}},
			"fail_rozmowa": {"text": "Rozmowa jakoś się nie klei. Natan uśmiecha się wyrozumiale i znów wraca do modlitwy.", "effects": {"xp": 15}},
			"koniec": {"text": "„Niech cię wiatr niesie, podróżny.”", "effects": {}},
		},
	},
	"karawana": {
		"zone": "", "roam": true,
		"npc": {"name": "Woźnica Hubert", "title": "Karawana z rozbitym kołem", "species": "kurczak", "scale": 1.4, "pos": Vector2.ZERO, "accent": Color(0.85, 0.75, 0.5), "role": "lore"},
		"start": "a",
		"nodes": {
			"a": {"text": "Przy poboczu stoi wóz z rozbitym kołem. Woźnica Hubert drapie się w głowę. „Przeklęta droga. Mam towar dla stolicy i ani jednego pomysłu, jak to naprawić. Pomożesz?”", "options": [
				{"text": "Podnieś wóz siłą, żeby podłożyć koło. (siła)", "check": {"stat": "sila", "dc": 12, "ok": "ok_sila", "fail": "fail_sila"}},
				{"text": "Zaprojektuj prowizoryczną oś. (intelekt)", "check": {"stat": "intelekt", "dc": 12, "ok": "ok_os", "fail": "fail_os"}},
				{"text": "Kup od niego towar za 70 zł.", "cost": 70, "next": "kupno"},
				{"text": "Zajrzyj na wóz, kiedy się odwróci. (kradzież)", "check": {"stat": "zrecznosc", "dc": 13, "ok": "ok_kradziez", "fail": "fail_kradziez"}},
				{"text": "Przeproś i idź dalej.", "next": "koniec"},
			]},
			"ok_sila": {"text": "Wóz unosi się, a Hubert w ostatniej chwili wsuwa koło. Wszyscy wiwatują. Dostajesz sakiewkę i skrzynkę z zapasami.", "effects": {"xp": 120, "gold": 80, "items": {"mikstura_miodu": 2}}},
			"fail_sila": {"text": "Wóz zsuwa się, a ty lądujesz w błocie. Hubert robi minę, której długo nie zapomnisz.", "effects": {"xp": 15}},
			"ok_os": {"text": "Twoja oś z dwóch kijów i liny trzyma jak żelazo. Hubert patrzy z uznaniem. „Że też sam na to nie wpadłem.” Dostajesz drobiazg z towaru.", "effects": {"xp": 140, "items": {"g_bomba_piorowa": 2}}},
			"fail_os": {"text": "Oś pęka przy pierwszej próbie. Hubert wzdycha, a koń kręci głową z politowaniem.", "effects": {"xp": 20}},
			"kupno": {"text": "Hubert pakuje towar z uśmiechem. „Dziękuję. Przynajmniej coś dziś sprzedałem.” Dostajesz pakiet przydatnych drobiazgów.", "effects": {"xp": 50, "items": {"g_wywar_sily": 1, "wytrych": 1}}},
			"ok_kradziez": {"text": "Z worka na tyle wozu wypada sakiewka prosto w twój plecak. Hubert niczego nie zauważa, bo właśnie kopie koło.", "effects": {"gold": 90, "xp": 50, "rep": -1}},
			"fail_kradziez": {"text": "„Hej!” Hubert łapie cię za dziób. Po krótkiej wymianie zdań wypada ci 30 zł z kieszeni.", "effects": {"gold": -30}},
			"koniec": {"text": "Hubert kiwa głową. „Dobra droga, podróżny.”", "effects": {}},
		},
	},
}

# ----------------------------------------------------------------- dostęp ---

static func has(id: String) -> bool:
	return LIST.has(id)

## Wędrowni podróżnicy (losowe spotkania na Pustkowiu): id spotkań bez przypisanego rozdziału.
static func roaming() -> Array:
	var out: Array = []
	for e in LIST:
		if bool((LIST[e] as Dictionary).get("roam", false)):
			out.append(String(e))
	return out

static func npc_id(enc: String) -> String:
	return "enc_" + enc

## Id spotkania prowadzone przez NPC (npc_id → enc), "" gdy to nie spotkanie.
static func enc_of_npc(npc: String) -> String:
	if not npc.begins_with("enc_"):
		return ""
	var e := npc.substr(4)
	return e if LIST.has(e) else ""

## NPC spotkań w formacie ChapterExtras.NPCS (id enc_<spotkanie>).
static func npcs() -> Dictionary:
	var out := {}
	for e in LIST:
		var n: Dictionary = (LIST[e]["npc"] as Dictionary).duplicate()
		n["encounter"] = e
		out[npc_id(String(e))] = n
	return out

## Dopisuje NPC spotkań do rozdziałów (npcs w ChapterExtras.EXTRAS).
static func patch_extras(extras: Dictionary) -> Dictionary:
	for e in LIST:
		var zone := String(LIST[e]["zone"])
		if not extras.has(zone):
			continue
		var ex: Dictionary = extras[zone]
		var list: Array = ex.get("npcs", [])
		var nid := npc_id(String(e))
		if nid not in list:
			list.append(nid)
		ex["npcs"] = list
	return extras

static func flag_done(enc: String) -> String:
	return "enc_done:" + enc

# ------------------------------------------------------------------ silnik ---

## Modyfikator próby: cecha (1 pkt / 6 rozdanych punktów, maks. +8) + bonus klasy + poziom/6.
static func modifier(stat: String, ctx: Dictionary) -> int:
	var s: Dictionary = STATS.get(stat, {})
	if s.is_empty():
		return 0
	var attr := int((ctx.get("attrs", {}) as Dictionary).get(String(s["attr"]), 0))
	var cls := String(ctx.get("class", ""))
	var bonus := int((s["classes"] as Dictionary).get(cls, 0))
	return mini(8, attr / 6) + bonus + int(ctx.get("level", 1)) / 6

## Szansa sukcesu w % (rzut k20: 20 zawsze trafia, 1 zawsze pudłuje).
static func chance(stat: String, dc: int, ctx: Dictionary) -> int:
	var need := dc - modifier(stat, ctx)
	return clampi(int(round(float(21 - need) / 20.0 * 100.0)), 5, 95)

static func _req_failure(opt: Dictionary, ctx: Dictionary) -> String:
	var req: Dictionary = opt.get("req", {})
	if req.has("class") and String(ctx.get("class", "")) not in (req["class"] as Array):
		return "Tylko: " + ", ".join((req["class"] as Array).map(func(c): return String(CLASS_NAMES.get(c, c))))
	if int(opt.get("cost", 0)) > int(ctx.get("gold", 0)):
		return "Za mało złota (%d)" % int(opt["cost"])
	var cnt: Callable = ctx.get("count", Callable())
	for tk in opt.get("take", {}):
		if cnt.is_valid() and int(cnt.call(String(tk))) < int(opt["take"][tk]):
			return "Brakuje przedmiotu: %s" % String(ItemDB.get_data(String(tk)).get("name", tk))
	return ""

## Widok węzła do wyświetlenia: {speaker, text, accent, terminal, options:[{text, tag, disabled, hint}]}.
static func view(enc: String, node: String, ctx: Dictionary) -> Dictionary:
	var e: Dictionary = LIST.get(enc, {})
	var n: Dictionary = (e.get("nodes", {}) as Dictionary).get(node, {})
	var v := {"speaker": String((e.get("npc", {}) as Dictionary).get("name", "")), "text": String(n.get("text", "…")),
		"accent": (e.get("npc", {}) as Dictionary).get("accent", Color(1.0, 0.85, 0.5)), "terminal": not n.has("options"), "options": []}
	if not n.has("options"):
		(v["options"] as Array).append({"text": "Odejdź", "tag": "", "disabled": false, "hint": ""})
		return v
	for o in n["options"]:
		var opt: Dictionary = o
		var tag := ""
		if opt.has("check"):
			var ck: Dictionary = opt["check"]
			tag = "[%s · trudność %d · %d%%]" % [String(STATS[ck["stat"]]["name"]), int(ck["dc"]), chance(String(ck["stat"]), int(ck["dc"]), ctx)]
		elif int(opt.get("cost", 0)) > 0:
			tag = "[%d zł]" % int(opt["cost"])
		elif opt.has("take"):
			tag = "[przedmiot]"
		var why := _req_failure(opt, ctx)
		(v["options"] as Array).append({"text": String(opt["text"]), "tag": tag, "disabled": why != "", "hint": why})
	return v

## Wybór odpowiedzi: zwraca {ok, next, roll, cost, take, set}; ok=false, gdy odpowiedź jest niedostępna.
## roll: {stat, dc, d20, mod, total, success}. Węzeł końcowy nie ma opcji — wybór 0 kończy spotkanie.
static func choose(enc: String, node: String, i: int, ctx: Dictionary, rng: RandomNumberGenerator = null) -> Dictionary:
	var e: Dictionary = LIST.get(enc, {})
	var n: Dictionary = (e.get("nodes", {}) as Dictionary).get(node, {})
	if not n.has("options"):
		return {"ok": true, "next": "", "roll": {}, "cost": 0, "take": {}}
	var opts: Array = n["options"]
	if i < 0 or i >= opts.size():
		return {"ok": false}
	var opt: Dictionary = opts[i]
	if _req_failure(opt, ctx) != "":
		return {"ok": false}
	var res := {"ok": true, "next": String(opt.get("next", "")), "roll": {}, "cost": int(opt.get("cost", 0)), "take": opt.get("take", {}), "set": String(opt.get("set", ""))}
	if opt.has("check"):
		var ck: Dictionary = opt["check"]
		var r := rng if rng != null else RandomNumberGenerator.new()
		if rng == null:
			r.randomize()
		var d20 := r.randi_range(1, 20)
		var mod := modifier(String(ck["stat"]), ctx)
		var ok := d20 == 20 or (d20 != 1 and d20 + mod >= int(ck["dc"]))
		res["roll"] = {"stat": String(ck["stat"]), "dc": int(ck["dc"]), "d20": d20, "mod": mod, "total": d20 + mod, "success": ok}
		res["next"] = String(ck["ok"] if ok else ck["fail"])
	return res

## Skutki wejścia do węzła (nagrody/kary): {gold, xp, items, rep}.
static func node_effects(enc: String, node: String) -> Dictionary:
	return (((LIST.get(enc, {}) as Dictionary).get("nodes", {}) as Dictionary).get(node, {}) as Dictionary).get("effects", {})

static func roll_text(roll: Dictionary) -> String:
	if roll.is_empty():
		return ""
	return "Próba: %s — k20 (%d) %s%d = %d wobec %d → %s" % [String(STATS[roll["stat"]]["name"]), int(roll["d20"]), "+" if int(roll["mod"]) >= 0 else "−", absi(int(roll["mod"])), int(roll["total"]), int(roll["dc"]), "SUKCES" if bool(roll["success"]) else "PORAŻKA"]

## Opis nagród do pokazania graczowi.
static func effects_text(fx: Dictionary) -> String:
	var parts: Array = []
	if int(fx.get("gold", 0)) != 0:
		parts.append("%+d zł" % int(fx["gold"]))
	if int(fx.get("xp", 0)) > 0:
		parts.append("+%d XP" % int(fx["xp"]))
	for id in fx.get("items", {}):
		parts.append("%s ×%d" % [String(ItemDB.get_data(String(id)).get("name", id)), int(fx["items"][id])])
	if int(fx.get("rep", 0)) != 0:
		parts.append("reputacja %+d" % int(fx["rep"]))
	return ", ".join(parts)

# ----------------------------------------------- integracja z GameState ---

## Kontekst z bieżącego profilu (gra jednoosobowa albo wnętrze ServerCtx.run na serwerze).
static func ctx_game() -> Dictionary:
	var attrs := {}
	for k in ["luck", "strength", "speed", "energy"]:
		attrs[k] = GameState.attr_value(k)
	return {"level": GameState.player_level(), "class": GameState.class_id(), "attrs": attrs, "gold": GameState.gold(),
		"count": func(id: String): return GameState.item_count(id)}

## Zabiera koszt wybranej odpowiedzi i nagradza skutkami węzła; zwraca opisy do pokazania.
static func apply(res: Dictionary, fx: Dictionary) -> Array:
	var lines: Array = []
	if int(res.get("cost", 0)) > 0:
		GameState.spend(int(res["cost"]))
		lines.append("−%d zł" % int(res["cost"]))
	for tk in res.get("take", {}):
		GameState.remove_item(String(tk), int(res["take"][tk]))
		lines.append("−%s" % String(ItemDB.get_data(String(tk)).get("name", tk)))
	var g := int(fx.get("gold", 0))
	lines.append_array(SecretDB.grant({"items": fx.get("items", {}), "gold": maxi(g, 0), "xp": int(fx.get("xp", 0))}))
	if g < 0:
		var lost := mini(GameState.gold(), -g)
		if lost > 0:
			GameState.spend(lost)
			lines.append("−%d zł" % lost)
	var rp := int(fx.get("rep", 0))
	if rp > 0 or (rp < 0 and Act2DB.rep() > 0):
		Act2DB.add_rep(rp)
		lines.append("reputacja %+d" % rp)
	return lines
