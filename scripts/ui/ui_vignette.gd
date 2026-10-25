class_name UiVignette
extends Control
## Sekretna komnata: krótka animowana scenka (jak mini-film), w której gracz się nie rusza.
## Pałacowi arystokraci mają tu swoje śmieszne historyjki. Zamykasz ją kliknięciem / E po końcu,
## albo Esc, żeby pominąć.

signal on_close

const CELL := 6.0
const SCENES := {
	"bath": {"title": "Baron Gawron w kąpieli", "npc": "baron_gawron", "bg": Color(0.55, 0.7, 0.8), "lines": [
		["", "Uchylasz drzwi sekretnej komnaty. Z pary wyłania się Baron Gawron — w wannie, w pianie po sam dziób."],
		["Baron Gawron", "To nie tak, jak myślisz! Ja tylko... szukam monokla!"],
		["", "Monokl połyskuje na jego dziobie. Baron zanurza się z godnością."],
		["Baron Gawron", "Nic nie widziałeś. Wystawię ci rachunek za milczenie."]]},
	"worms": {"title": "Kapelusz Hrabiny Wrony", "npc": "hrabina_wrona", "bg": Color(0.6, 0.45, 0.55), "lines": [
		["", "Hrabina Wrona siedzi przed lustrem w gigantycznym kapeluszu. Coś się w nim rusza."],
		["Hrabina Wrona", "Szsz! Nie wystrasz mi spiżarni."],
		["", "Z kapelusza wychyla się dżdżownica i macha do ciebie."],
		["Hrabina Wrona", "Poczęstujesz się? Mam jeszcze na deser."]]},
	"book": {"title": "Książę Kruczek czyta", "npc": "ksiaze_kruczek", "bg": Color(0.45, 0.4, 0.6), "lines": [
		["", "Książę Kruczek zatopił się w lekturze. Książka jest do góry nogami."],
		["Książę Kruczek", "Fabuła taka wciągająca... Czytam to od trzech tygodni."],
		["", "Książę obraca księgę. Na okładce: „Poradnik gotowania kur”."],
		["Książę Kruczek", "A to dopiero zwrot akcji!"]]},
	"lost": {"title": "Diuk Kawka w regałach", "npc": "diuk_kawka", "bg": Color(0.5, 0.42, 0.34), "lines": [
		["", "Między regałami kręci się Diuk Kawka z kartką w skrzydle. Wygląda na wyczerpanego."],
		["Diuk Kawka", "Wszedłem po książkę trzy lata temu. Wyjście musiało się przeprowadzić."],
		["", "Diuk mija drzwi dokładnie trzy razy, nie zauważając ich."],
		["Diuk Kawka", "Jeśli spotkasz kogoś z mapą — nie mów mu, że tu jestem!"]]},
	"feast": {"title": "Uczta Margrabiego Kosa", "npc": "margrabia_kos", "bg": Color(0.6, 0.4, 0.3), "lines": [
		["", "Margrabia Kos siedzi sam przy stole na pięćset osób. Przed nim góra pieczeni."],
		["Margrabia Kos", "Goście się spóźniają. Zacznę bez nich — dla przyzwoitości."],
		["", "Margrabia pochłania kolejne danie i chowa kości pod serwetę."],
		["Margrabia Kos", "Uczta była udana. Tylko deser trochę się powtarza."]]},
	"spoon": {"title": "Skarbiec Damy Sroczki", "npc": "dama_sroczka", "bg": Color(0.55, 0.5, 0.35), "lines": [
		["", "Dama Sroczka stoi nad stosem błyskotek, wielkim jak mały pagórek."],
		["Dama Sroczka", "Ta łyżka lśni najpiękniej. Pamiętasz ją? To twoja."],
		["", "Łyżka z cichym brzdękiem ląduje na szczycie stosu."],
		["Dama Sroczka", "Wypożyczona na wieki. Dziękuję za ofiarę dla sztuki."]]},
	"portraits": {"title": "Galeria Lady Szpaczek", "npc": "lady_szpaczek", "bg": Color(0.5, 0.4, 0.55), "lines": [
		["", "Ściana pokryta jest portretami Lady Szpaczek. Wszystkie wyglądają tak samo."],
		["Lady Szpaczek", "Ten pierwszy — szczerzy dziób. Ten drugi — unosi brew. Ten trzeci — też."],
		["", "Lady zmienia pozę. Wszystkie portrety zmieniają ją o sekundę później."],
		["Lady Szpaczek", "Geniusz malarza! Albo mój."]]},
	"talk": {"title": "Wicehrabia i portret", "npc": "wicehrabia_czarnuszek", "bg": Color(0.38, 0.4, 0.5), "lines": [
		["", "Wicehrabia Czarnuszek stoi przed starym portretem i żywo gestykuluje."],
		["Wicehrabia Czarnuszek", "Mówisz, że za schodami jest przejście? A kto ci uwierzy!"],
		["", "Portret mruga. Wicehrabia też. Obaj udają, że to nic takiego."],
		["Wicehrabia Czarnuszek", "On kłamie od czterystu lat, ale ma ciekawe teorie."]]},
	"sermon": {"title": "Kazanie Kanonika", "npc": "kanonik_gawrosz", "bg": Color(0.5, 0.45, 0.6), "lines": [
		["", "W małej kaplicy Kanonik Gawrosz wygłasza kazanie. Ławki zapełnione są śpiącymi słuchaczami."],
		["Kanonik Gawrosz", "...a dalej, o ziarnku, które kiełkuje w sercu każdego z was..."],
		["", "Ktoś głośno chrapie. Kanonik robi się jeszcze bardziej natchniony."],
		["Kanonik Gawrosz", "Amen! Widzę, że wasza pobożność sięga snu!"]]},
	"owl": {"title": "Hrabia Puchacz śpi", "npc": "hrabia_puchacz", "bg": Color(0.3, 0.32, 0.45), "lines": [
		["", "Hrabia Puchacz pochrapuje w fotelu pod zegarem. Zegar wskazuje południe."],
		["Hrabia Puchacz", "Zzz... Nocna warta... zzz... trwa..."],
		["", "Hrabia otwiera jedno oko, patrzy na ciebie i... zamyka je z powrotem."],
		["Hrabia Puchacz", "Nikogo nie ma. Zzz. Dobranoc."]]},
}

## Scenki sterowane danymi: rekwizyty ("props"), animacja aktora ("anim") i dodatkowe postacie ("extras").
const SCENES2 := {
	"map_cloth": {"title": "Mapa Marszałka", "npc": "marszalek", "bg": Color(0.5, 0.35, 0.3), "anim": "pace", "ax": -140.0,
		"props": [["map_table", 120, 0], ["soup", 120, -120]],
		"context": "Przy okrągłym stole Marszałek Dziobacz planuje kampanię na wielkiej mapie. Obok stoi miseczka zupy.",
		"lines": [["Marszałek Dziobacz", "Tu przekroczymy rzekę, tu uderzymy z flanki, a tu... zjemy obiad."], ["", "Miseczka przewraca się. Zupa rozlewa się po całej „mapie”."], ["Marszałek Dziobacz", "Hm. Okazuje się, że to nie mapa, tylko obrus. Dlatego rzeka była taka kwadratowa."]]},
	"debts": {"title": "Księgi Kanclerza", "npc": "kanclerz_korony", "bg": Color(0.35, 0.4, 0.5), "anim": "pace", "ax": -120.0,
		"props": [["ledger", 140, 0], ["coins", -330, 0]],
		"context": "Kanclerz Piórko przesiaduje nad księgami skarbca. Stos monet jest wyraźnie mniejszy niż stos rachunków.",
		"lines": [["Kanclerz Piórko", "Należności: zero. Zobowiązania: nieskończoność. Bilans... bardzo ciekawy."], ["", "Z góry sypie się deszcz rachunków. Jedna moneta turla się po podłodze i ucieka."], ["Kanclerz Piórko", "Dług mamy właściwie wobec wszystkich. Nawet wobec tych, którzy już nie żyją."]]},
	"spy": {"title": "Mistrz Szpiegów", "npc": "mistrz_szpiegow", "bg": Color(0.3, 0.3, 0.4), "anim": "hide", "ax": 20.0,
		"props": [["shelf_bottles", 330, 0]],
		"context": "Za ciężką kotarą w sali narad chowa się Mistrz Szpiegów. Z zasłony wystaje dziób. I ogon.",
		"lines": [["Mistrz Szpiegów Cichopiór", "Ciii! Jestem całkowicie niewidoczny. Nikt mnie nie widzi."], ["", "Kotara faluje. Szpieg robi krok w prawo. Cała kotara robi krok w prawo."], ["Mistrz Szpiegów Cichopiór", "Wiem wszystko o wszystkich. Niestety, zapomniałem, co wiem."]]},
	"queen_speech": {"title": "Próba przemówienia", "npc": "krolowa", "bg": Color(0.55, 0.4, 0.5), "anim": "preach", "ax": -80.0,
		"props": [["mirror", 160, 0], ["bed", -330, 0]],
		"context": "W alkowie obok sali narad Królowa Aurelia ćwiczy przemówienie przed lustrem. Nikt nie powinien tego widzieć.",
		"lines": [["Królowa Aurelia", "Obywatele! Ptaki! Rodacy! ...Kury! Nie. Kury brzmią niepoważnie."], ["", "Królowa poprawia koronę, odchrząkuje i próbuje jeszcze raz, głębszym głosem."], ["Królowa Aurelia", "Kurczaki — nie lękajcie się! ...Och, nie wiedziałam, że ktoś tu jest. To była tylko... próba."]]},
	"guard_nap": {"title": "Drzemka strażnika", "npc": "straznik", "bg": Color(0.4, 0.4, 0.5), "anim": "sleep", "ax": 40.0,
		"props": [["bed", -300, 0], ["clock", 330, -150]],
		"context": "W wartowni na szczycie wieży strażnik dzielnie pilnuje drzwi. Z zamkniętymi oczami, dla pewności.",
		"lines": [["Strażnik Michał", "Kto idzie?... Zzz... Hasło brzmi... zzz... pierzyna."], ["", "Hełm zsuwa się mu na dziób. Strażnik odruchowo salutuje śpiąc."], ["Strażnik Michał", "Wszystko w porządku. Nikt nie przeszedł. Chrrr."]]},
	"soup": {"title": "Zupa Kucharza", "npc": "kucharz", "bg": Color(0.5, 0.35, 0.25), "anim": "eat", "ax": -60.0,
		"props": [["cauldron", 130, 0], ["shelf_bottles", -300, 0]],
		"context": "Polowa kuchnia Kucharza Stacha: ogromny kocioł, półka z podejrzanymi przyprawami i zapach, który trudno nazwać.",
		"lines": [["Kucharz Stach", "Zupa dnia: rosół z wody, trochę wody i szczypta dumy."], ["", "Kucharz próbuje łyżką. Mina mu rzednie, a w kotle coś bulgocze zadowolone."], ["Kucharz Stach", "Za mało soli. Za dużo wody. Ale wojsko zje wszystko, więc czemu nie."]]},
	"tale": {"title": "Bajka Więźnia", "npc": "wiezien_bajarz", "bg": Color(0.28, 0.3, 0.36), "anim": "preach", "ax": -80.0,
		"props": [["bars", 0, 0]], "extras": [["gasior", -300, 0], ["kurczak", 280, 0]],
		"context": "W głębi lochu Więzień Bajarz opowiada współwięźniom swoją czterdziestą siódmą bajkę. Słuchają z zapartym tchem.",
		"lines": [["Więzień Bajarz", "...i wtedy dzielny kurczak zerwał kajdany jednym kopnięciem!"], ["", "Słuchacze wciągają powietrze. Jeden z nich z wrażenia wypuszcza łyżkę."], ["Więzień Bajarz", "Koniec jeszcze nie wiem, bo dopiero się go wymyśla. Ale będzie szczęśliwy."]]},
	"keys": {"title": "Klucze Klawisza", "npc": "klawisz", "bg": Color(0.3, 0.3, 0.34), "anim": "pace", "ax": -100.0,
		"props": [["bars", 160, 0], ["keys", 160, -260]],
		"context": "Klawisz Zbigniew mocuje się z celą. Jego kółko ma sto kluczy i żaden nie pasuje.",
		"lines": [["Klawisz Zbigniew", "Ten? Nie. Ten? Nie. Ten... ach, to klucz do mojej szafki."], ["", "Klucze brzęczą jak orkiestra bez kapelmistrza. Krata nie drgnie."], ["Klawisz Zbigniew", "Zawsze mówiłem, że nie ma sensu zamykać drzwi. Cela sama się nie zamknęła."]]},
	"dark_jars": {"title": "Ciemność w słoikach", "npc": "straganiarz_kruczy", "bg": Color(0.25, 0.22, 0.32), "anim": "pace", "ax": -140.0,
		"props": [["jars", 150, 0], ["jars", -310, 0]],
		"context": "Kruczy Straganiarz handluje ciemnością w słoikach. Zawartość się porusza, a jeden słoik patrzy na ciebie.",
		"lines": [["Kruczy Straganiarz", "Ciemność na wagę! Czysta, nieoświetlona, bez konserwantów!"], ["", "Jeden słoik otwiera oko. Straganiarz szybko przykrywa go ścierką."], ["Kruczy Straganiarz", "Interes się kręci. Gorzej, że światła na rynku zabrakło — ktoś je wykupił."]]},
	"garden": {"title": "Ogródek Babci Wrony", "npc": "babcia_wrona", "bg": Color(0.4, 0.5, 0.4), "anim": "pace", "ax": -120.0,
		"props": [["flowers", 120, 0], ["flowers", -320, 0]], "extras": [["kogut", 270, -10]],
		"context": "Ogródek Babci Wrony: rzędy stokrotek, grządka marchewki i wnuki, które właśnie ćwiczą walkę mieczem.",
		"lines": [["Babcia Wrona", "Uważaj na stokrotki! Moje wnuki ćwiczą szermierkę — tylko dlaczego zawsze na mojej grządce?"], ["", "Wnuk wykonuje piruet. Jedna stokrotka żegna się z życiem."], ["Babcia Wrona", "Nie ta! Trzecia od lewej była moją ulubioną! Na obiad dostaniesz... brukiew."]]},
	"diary": {"title": "Pamiętnik Buntownika", "npc": "buntownik_zamku", "bg": Color(0.3, 0.28, 0.35), "anim": "write", "ax": -20.0,
		"props": [["desk_candle", 40, 0], ["shelf_bottles", -300, 0]],
		"context": "W komnacie na dziedzińcu Kruk Młodszy zapisuje w tajnym pamiętniku coś, czego dziadek nigdy nie może przeczytać.",
		"lines": [["Buntownik Kruk Młodszy", "Drogi pamiętniku. Dziadek znowu krzyczał na generałów. Ci znowu nic nie odpowiedzieli."], ["", "Pióro skrzypi. Świeca trzeszczy. Kruczek ukradkiem zerka na drzwi."], ["Buntownik Kruk Młodszy", "Postscriptum: jeśli ktoś to czyta, to jestem martwy. Albo ty jesteś bardzo ciekawski."]]},
	"doll": {"title": "Lalki Kasi", "npc": "kasia", "bg": Color(0.65, 0.5, 0.45), "anim": "jump", "ax": -40.0,
		"props": [["doll", 150, 0], ["bed", -320, 0]],
		"context": "W kącie chaty Kasia bawi się lalkami: jedna to Starosta, druga Kowal, a trzecia — dzielny kurczak, czyli ty.",
		"lines": [["Kasia", "A tu przychodzi Starosta i mówi: Obronimy wioskę! A Kowal mówi: Dajcie mi młotek!"], ["", "Lalka-kurczak ląduje na głowie lalki-Starosty. Kasia wybucha śmiechem."], ["Kasia", "I wszyscy żyli długo, bo kurczak ich obronił! A teraz idź, bo spóźnisz się na bitwę."]]},
	"cart": {"title": "Wóz Kupca Bronka", "npc": "bronek", "bg": Color(0.5, 0.55, 0.4), "anim": "pace", "ax": -140.0,
		"props": [["cart", 130, 0]],
		"context": "Kupiec Bronek sprzedaje podróżnym mapy. Nad wozem wisi baner: „NAJLEPSZE MAPY W OKOLICY”. Okolica jest bardzo mała.",
		"lines": [["Kupiec Bronek", "Mapa do stolicy! Tylko dziś, z podpisem autora i plamą po kawie."], ["", "Mapa przedstawia... kurczaka z kreską do stolicy. Kreska jest zygzakiem."], ["Kupiec Bronek", "Czytelna, prawda? Wystarczy iść za kreską. Ewentualnie za sercem. Albo za mną."]]},
	"bread": {"title": "Pożar w piekarni", "npc": "zosia", "bg": Color(0.6, 0.35, 0.25), "anim": "pace", "ax": -140.0,
		"props": [["bread", 130, 0], ["cauldron", -320, 0]],
		"context": "W piekarni Zosi buchnął ogień — ale piekarka nie traci głowy. Gasi pożar... pieczywem.",
		"lines": [["Piekarka Zosia", "Pożar! Gaście! Czym? Chlebem! Mamy go za dużo!"], ["", "Bochenki lecą w ogień. Płomienie gasną, a pod sufitem unosi się zapach grzanek."], ["Piekarka Zosia", "Pożar ugaszony, śniadanie gotowe. Bierz bułkę, dzielny kurczaku."]]},
}

static var ALL: Dictionary = SCENES.merged(SCENES2)

const CONTEXT := {
	"bath": "Za gobelinem w holu kryje się sekretna łaźnia. Z kranu leci gorąca woda, a w powietrzu unosi się para i zapach lawendy.",
	"worms": "Garderoba hrabiny: lustra, pudła na kapelusze i suknie wiszące jak ptaki na gałęzi.",
	"book": "W cichej czytelni nawet kurz stąpa na palcach. Przy kominku stoi fotel i stos zaczętych książek.",
	"lost": "Labirynt regałów ciągnie się w głąb komnaty. Drabiny opierają się o wszystko, tylko nie o regały.",
	"feast": "Prywatna jadalnia Margrabiego: lśniący żyrandol, krzesła na pięćset osób i ani jednego gościa.",
	"spoon": "Skarbiec Damy Sroczki mieści wszystko, co błyszczy: łyżki, guziki, zęby i jedną koronę.",
	"portraits": "Pokój portretów Lady Szpaczek: aksamitna lina, złote ramy i bardzo dużo jej samej.",
	"talk": "Komnata rozmów: dwa świeczniki, ciężkie zasłony i portret, który wie zbyt wiele.",
	"sermon": "Mała kaplica. Witraże rzucają kolorowe plamy na ławki, w których wszyscy smacznie śpią.",
	"owl": "Sypialnia Hrabiego Puchacza: księżyc w oknie, zegar wskazuje południe, a gospodarz śpi na służbie.",
}

func _lines() -> Array:
	var ctx := String(CONTEXT.get(kind, ALL[kind].get("context", "")))
	return [["", ctx]] + (ALL[kind]["lines"] as Array)

var kind := "bath"
var _t := 0.0
var _line := 0
var _line_t := 0.0
var _caption: Label
var _speaker: Label
var _hint: Label
var _stage: _Stage
var _done := false

func setup(p_kind: String) -> void:
	kind = p_kind if ALL.has(p_kind) else "bath"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	add_child(UiKit.dim(Color(0.0, 0.0, 0.02, 0.9)))
	var d: Dictionary = ALL[kind]
	var title := UiKit.title(String(d["title"]), 30)
	title.position = Vector2(0, 14)
	title.size = Vector2(1280, 44)
	add_child(title)
	# scena jest przycięta do własnej ramki, żeby nic nie zasłaniało napisów
	var clip := Control.new()
	clip.clip_contents = true
	clip.position = Vector2(160, 74)
	clip.size = Vector2(960, 440)
	add_child(clip)
	var frame := ColorRect.new()
	frame.color = Color(0.05, 0.04, 0.07)
	frame.position = Vector2(154, 68)
	frame.size = Vector2(972, 452)
	add_child(frame)
	move_child(frame, 1)
	_stage = _Stage.new()
	_stage.kind = kind
	_stage.position = Vector2(480, 430)
	clip.add_child(_stage)
	var panel := UiKit.panel(Color(0.04, 0.05, 0.08, 0.97), 4)
	panel.position = Vector2(140, 534)
	panel.custom_minimum_size = Vector2(1000, 150)
	add_child(panel)
	var v := UiKit.vbox(4)
	panel.add_child(v)
	_speaker = UiKit.label("", 18, UiKit.ACCENT)
	v.add_child(_speaker)
	_caption = UiKit.label("", 20, UiKit.TEXT)
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.custom_minimum_size = Vector2(960, 56)
	v.add_child(_caption)
	_hint = UiKit.label("[Esc] pomiń", 13, UiKit.DIM, HORIZONTAL_ALIGNMENT_RIGHT)
	v.add_child(_hint)
	_show_line(0)

func _show_line(i: int) -> void:
	var lines: Array = _lines()
	if i >= lines.size():
		_done = true
		_hint.text = "[E] / klik — zamknij"
		return
	_line = i
	_line_t = 0.0
	_speaker.text = String(lines[i][0])
	_caption.text = String(lines[i][1])
	_stage.beat = i

func _process(delta: float) -> void:
	_t += delta
	_stage.t = _t
	if not _done:
		_line_t += delta
		var lines: Array = _lines()
		var need := 2.2 + float(String(lines[_line][1]).length()) * 0.03
		if _line_t >= need:
			_show_line(_line + 1)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
	elif _done and ((event is InputEventMouseButton and event.pressed) or event.is_action_pressed("equipment")):
		get_viewport().set_input_as_handled()
		_close()

func _close() -> void:
	Audio.play("back")
	on_close.emit()

# ---------------------------------------------------------------- scena ---

class _Stage extends Node2D:
	var kind := "bath"
	var t := 0.0
	var beat := 0
	var actor: CreatureVisual
	var extra: Array = []
	const C := 6.0

	func _ready() -> void:
		var d: Dictionary = UiVignette.ALL[kind]
		actor = CreatureVisual.new()
		var npc := String(d["npc"])
		actor.configure(String(NpcDB.get_data(npc).get("species", "kogut")), NpcDB.pal_for(npc), 1.9)
		actor.idle_seed = 1.0
		add_child(actor)
		actor.z_index = 5
		if kind == "spy":
			var fr := _Front.new()
			fr.z_index = 10
			add_child(fr)
		if d.has("props"):
			actor.position = Vector2(float(d.get("ax", 0.0)), 0.0)
			for e in d.get("extras", []):
				var w := CreatureVisual.new()
				w.configure(String(e[0]), {}, 1.5)
				w.position = Vector2(float(e[1]), float(e[2]))
				w.z_index = 5
				add_child(w)
				extra.append(w)
		match kind:
			"bath":
				actor.position = Vector2(-60, -6)
			"worms":
				actor.position = Vector2(-60, 0)
			"book":
				actor.position = Vector2(-40, 0)
			"lost":
				actor.position = Vector2(-200, 0)
			"feast":
				actor.position = Vector2(-200, 0)
			"spoon":
				actor.position = Vector2(180, 0)
				actor.set_facing(-1.0)
			"portraits":
				actor.position = Vector2(0, 0)
			"talk":
				actor.position = Vector2(-150, 0)
			"sermon":
				actor.position = Vector2(120, -30)
				for i in 5:
					var w := CreatureVisual.new()
					w.configure("kurczak", {"body": Color(0.9, 0.85, 0.75), "comb": Color(0.8, 0.3, 0.3)}, 1.3)
					w.position = Vector2(-300 + (i % 3) * 150 + (i / 3) * 70, 4 - (i / 3) * 38)
					w.z_index = 6
					add_child(w)
					extra.append(w)
			"owl":
				actor.position = Vector2(0, 8)

	func _process(_dt: float) -> void:
		var d0: Dictionary = UiVignette.ALL[kind]
		if d0.has("anim"):
			_anim(String(d0["anim"]), float(d0.get("ax", 0.0)))
		match kind:
			"bath":
				actor.crouch = 0.3
			"lost":
				actor.position.x = -300.0 + fposmod(t * 60.0, 600.0)
				actor.moving = true
				actor.set_facing(1.0)
			"feast":
				actor.arm = 0.5 + 0.5 * sin(t * 6.0)
			"book":
				actor.lean = sin(t * 2.0) * 0.1
			"portraits":
				actor.arm = 1.0 if int(t * 1.2) % 2 == 0 else 0.0
			"sermon":
				actor.arm = 0.6 + 0.4 * sin(t * 4.0)
				for w in extra:
					(w as CreatureVisual).crouch = 0.8
			"owl":
				actor.crouch = 0.9
		queue_redraw()

	## Kotara rysowana przed aktorem (Mistrz Szpiegów chowa się za nią).
	class _Front extends Node2D:
		var t := 0.0

		func _process(dt: float) -> void:
			t += dt
			queue_redraw()

		func _draw() -> void:
			var sw := sin(t * 2.0) * 4.0
			for i in 6:
				var x := 60.0 + i * 28.0 + sw * (i % 2)
				draw_rect(Rect2(x - 3, -392, 34, 392), Color(0.05, 0.04, 0.07))
				draw_rect(Rect2(x, -392, 28, 392), Color(0.62, 0.14, 0.2).darkened(0.12 * float(i % 2)))
			draw_rect(Rect2(50, -400, 190, 16), Color(0.85, 0.7, 0.25))

	func _anim(a: String, ax: float) -> void:
		match a:
			"pace":
				var nx := ax + sin(t * 1.2) * 110.0
				actor.set_facing(1.0 if nx > actor.position.x else -1.0)
				actor.position.x = nx
				actor.moving = true
			"sleep":
				actor.crouch = 0.9
			"eat":
				actor.arm = 0.5 + 0.5 * sin(t * 5.0)
			"preach":
				actor.arm = 0.6 + 0.4 * sin(t * 3.0)
				actor.lean = sin(t * 1.5) * 0.12
			"hide":
				actor.position.x = ax + (60.0 if int(t * 0.6) % 2 == 0 else 0.0)
			"write":
				actor.arm = 0.4 + 0.2 * sin(t * 9.0)
				actor.lean = 0.2
			"jump":
				actor.position.y = -absf(sin(t * 3.0)) * 40.0

	func _snap(v: float) -> float:
		return roundf(v / C) * C

	func r(x: float, y: float, w: float, h: float, col: Color) -> void:
		draw_rect(Rect2(_snap(x), _snap(y), maxf(C, _snap(w)), maxf(C, _snap(h))), col)

	func ob(x: float, y: float, w: float, h: float, col: Color) -> void:
		draw_rect(Rect2(_snap(x) - 3, _snap(y) - 3, maxf(C, _snap(w)) + 6, maxf(C, _snap(h)) + 6), Color(0.05, 0.04, 0.07))
		r(x, y, w, h, col)

	func disc(cx: float, cy: float, rad: float, col: Color) -> void:
		var n := int(rad / C) + 1
		for gy in range(-n, n + 1):
			for gx in range(-n, n + 1):
				if Vector2(gx, gy).length() <= rad / C:
					draw_rect(Rect2(_snap(cx) + gx * C, _snap(cy) + gy * C, C, C), col)

	func _draw() -> void:
		var d: Dictionary = UiVignette.ALL[kind]
		var bg: Color = d["bg"]
		_room(bg)
		match kind:
			"bath":
				_bath()
				_bath_tub()
			"worms": _worms()
			"book": _book()
			"lost": _lost()
			"feast": _feast()
			"spoon": _spoon()
			"portraits": _portraits()
			"talk": _talk()
			"sermon": _sermon()
			"owl": _owl()
		if d.has("props"):
			_props(d)

	## Wnętrze: ściana z boazerią i gzymsem, okno z zasłonami, podłoga z kafelkami, dywan, kurz i cień przy krawędziach.
	func _room(bg: Color) -> void:
		var win := "moon" if kind in ["bath", "owl", "worms"] else ("stained" if kind == "sermon" else "day")
		# ściana
		r(-480, -430, 960, 340, bg)
		r(-480, -430, 960, 36, bg.darkened(0.45))                       # gzyms
		r(-480, -396, 960, 8, bg.lightened(0.18))
		r(-480, -200, 960, 110, bg.darkened(0.22))                      # boazeria
		for i in 9:
			r(-480 + i * 120, -194, 6, 98, bg.darkened(0.4))
			r(-462 + i * 120, -190, 92, 4, bg.darkened(0.12))
		r(-480, -204, 960, 8, bg.lightened(0.12))
		# okno
		var wx := -330.0
		ob(wx, -360, 170, 190, Color(0.45, 0.32, 0.2))
		var sky := Color(0.1, 0.12, 0.3) if win == "moon" else (Color(0.55, 0.75, 0.95) if win == "day" else Color(0.3, 0.3, 0.4))
		r(wx + 12, -348, 146, 166, sky)
		if win == "moon":
			disc(wx + 110, -300, 20, Color(1.0, 0.97, 0.8))
			for i in 7:
				r(wx + 24 + i * 19, -330 + (i * 37) % 90, C, C, Color(1, 1, 1, 0.5 + 0.5 * sin(t * 3.0 + i)))
		elif win == "day":
			disc(wx + 50, -290, 18, Color(1, 1, 1, 0.9))
			disc(wx + 80, -296, 22, Color(1, 1, 1, 0.9))
			disc(wx + 112, -290, 16, Color(1, 1, 1, 0.9))
		else:
			for i in 4:
				for j in 5:
					r(wx + 14 + i * 36, -346 + j * 32, 32, 28, Color.from_hsv(float(i * 5 + j) * 0.09, 0.7, 0.9, 0.85))
		r(wx + 82, -348, 6, 166, Color(0.45, 0.32, 0.2))
		r(wx + 12, -268, 146, 6, Color(0.45, 0.32, 0.2))
		ob(wx - 34, -370, 30, 210, Color(0.6, 0.15, 0.2))              # zasłony
		ob(wx + 176, -370, 30, 210, Color(0.6, 0.15, 0.2))
		# podłoga: kafelki
		r(-480, -90, 960, 100, bg.darkened(0.4))
		for row in 3:
			for col in 13:
				if (row + col) % 2 == 0:
					r(-480 + col * 76 + (row % 2) * 38, -90 + row * 30, 76, 30, bg.darkened(0.3))
		r(-480, -98, 960, 8, bg.darkened(0.55))                          # listwa
		# dywan
		ob(-230, -62, 460, 48, Color(0.55, 0.14, 0.2))
		r(-214, -54, 428, 32, Color(0.7, 0.25, 0.3))
		for i in 9:
			r(-200 + i * 48, -46, 20, 16, Color(0.95, 0.8, 0.35, 0.8))
		# płomienie świec po bokach
		for sx in [-440.0, 440.0]:
			r(sx - 5, -270, 10, 54, Color(0.95, 0.92, 0.8))
			var fl := 6.0 * sin(t * 9.0 + sx)
			r(sx - 3, -292 - fl * 0.3, 6, 18 + fl * 0.5, Color(1.0, 0.8, 0.3))
			disc(sx, -282, 34, Color(1.0, 0.85, 0.4, 0.07))
		# pyłki w powietrzu
		for i in 14:
			var px := -440.0 + fposmod(float(i) * 71.0 + t * 12.0, 900.0)
			var py := -340.0 + fposmod(float(i) * 53.0 + t * 9.0 * (1.0 + float(i % 3)), 220.0)
			r(px, py, 4, 4, Color(1, 1, 0.9, 0.3))
		# przyciemnienie krawędzi
		r(-480, -430, 70, 440, Color(0, 0, 0, 0.25))
		r(410, -430, 70, 440, Color(0, 0, 0, 0.25))

	func _bath() -> void:
		# kafelki łazienkowe na ścianie, wieszak z ręcznikami, para
		for i in 16:
			for j in 4:
				if (i + j) % 2 == 0:
					r(-60 + i * 36, -330 + j * 34, 36, 34, Color(0.8, 0.9, 0.95, 0.35))
		ob(190, -250, 150, 8, Color(0.6, 0.6, 0.65))
		r(200, -242, 40, 60, Color(0.95, 0.95, 0.98))
		r(250, -242, 40, 70, Color(0.8, 0.5, 0.55))
		for i in 6:
			var sy := fposmod(t * 24.0 + i * 31.0, 150.0)
			disc(-110 + i * 38.0 + sin(t * 2.0 + i) * 10.0, -150 - sy, 18, Color(1, 1, 1, 0.22 * (1.0 - sy / 150.0)))

	func _bath_tub() -> void:
		var b := 0.5 + 0.5 * sin(t * 3.0)
		ob(-150, -60, 180, 70, Color(0.95, 0.95, 0.98))
		r(-150, -30, 180, 30, Color(0.55, 0.78, 0.95))
		for i in 8:
			var p := fposmod(t * 30.0 + i * 41.0, 120.0)
			disc(-130 + i * 22, -50 - p, 8 + (i % 3) * 6, Color(1, 1, 1, 0.8))
		r(-130, 10, 12, 18, Color(0.8, 0.7, 0.3))
		r(10, 10, 12, 18, Color(0.8, 0.7, 0.3))
		# monokl na dziobie
		if beat >= 2:
			disc(-30 + 60 + b * 0.0, -126, 10, Color(1.0, 0.95, 0.6, 0.9))
		# kaczuszka
		disc(100 + sin(t * 2.0) * 20.0, -40, 14, Color(1.0, 0.9, 0.2))

	func _worms() -> void:
		ob(-300, -220, 140, 140, Color(0.55, 0.4, 0.3))     # lustro
		r(-290, -210, 120, 120, Color(0.75, 0.85, 0.95))
		# gigantyczny kapelusz
		ob(-150, -330, 180, 60, Color(0.55, 0.25, 0.5))
		r(-100, -380, 80, 60, Color(0.65, 0.3, 0.55))
		for i in 4:
			var h := 30.0 + 40.0 * (0.5 + 0.5 * sin(t * 3.0 + i * 1.7)) * (1.0 if beat >= 1 else 0.3)
			var x := -90.0 + i * 36.0
			r(x, -380 - h, C * 2, h, Color(0.95, 0.6, 0.7))
		if beat >= 2:
			disc(20, -400 - 20.0 * sin(t * 4.0), 10, Color(0.95, 0.6, 0.7))

	func _book() -> void:
		var flip := 1.0 if beat < 2 else -1.0
		ob(30, -190, 140, 100, Color(0.2, 0.3, 0.6))
		r(36, -184, 128, 88, Color(0.95, 0.92, 0.8))
		r(96, -184, 6, 88, Color(0.7, 0.65, 0.5))
		for i in 4:
			r(46, -170 + i * 20, 40 * flip if flip > 0.0 else 40, 6, Color(0.4, 0.35, 0.3))
			r(108, -170 + i * 20, 46, 6, Color(0.4, 0.35, 0.3))
		if beat >= 2:
			disc(100, -240 - 10.0 * sin(t * 5.0), 14, Color(1.0, 0.9, 0.3))

	func _lost() -> void:
		for i in 6:
			var x := -450.0 + i * 160.0
			ob(x, -360, 120, 280, Color(0.45, 0.3, 0.2))
			for s in 4:
				r(x + 6, -350 + s * 66, 108, 6, Color(0.3, 0.2, 0.12))
				for k in 6:
					r(x + 8 + k * 17, -344 + s * 66, 12, 54, Color.from_hsv(float(i * 6 + k + s) * 0.13, 0.5, 0.75))
		var q := 0.5 + 0.5 * sin(t * 4.0)
		disc(actor.position.x + 20, -230 - q * 10, 8, Color(1, 1, 1, 0.8))

	func _feast() -> void:
		# żyrandol i krzesła
		r(-3, -430, 6, 70, Color(0.4, 0.3, 0.2))
		ob(-70, -362, 140, 12, Color(0.95, 0.8, 0.3))
		for i in 5:
			var cx := -60.0 + i * 30.0
			r(cx - 3, -386, 6, 24, Color(0.95, 0.93, 0.85))
			r(cx - 3, -400 - 3.0 * sin(t * 8.0 + i), 6, 14, Color(1.0, 0.8, 0.3))
		disc(0, -380, 90, Color(1.0, 0.85, 0.4, 0.08))
		for i in 8:
			ob(-330 + i * 100, -100, 36, 70, Color(0.45, 0.28, 0.18))
		ob(-360, -110, 800, 60, Color(0.85, 0.78, 0.65))
		r(-340, -50, 40, 60, Color(0.4, 0.28, 0.18))
		r(360, -50, 40, 60, Color(0.4, 0.28, 0.18))
		for i in 12:
			var col := Color(0.8, 0.45, 0.25) if i % 3 == 0 else (Color(0.95, 0.8, 0.3) if i % 3 == 1 else Color(0.5, 0.75, 0.35))
			disc(-300 + i * 62, -130, 16 + (i % 2) * 6, col)
		for i in 6:
			var yy := fposmod(t * 40.0 + i * 20.0, 80.0)
			r(-130 + i * 30, -90 + yy, C, C, Color(0.95, 0.8, 0.5))

	func _spoon() -> void:
		# stos błyskotek
		for i in 40:
			var a := float(i) * 2.399
			var rad := 60.0 + (i % 7) * 12.0
			disc(-150 + cos(a) * rad, -50 - absf(sin(a)) * rad * 0.5, 10, Color(1.0, 0.9 - (i % 4) * 0.1, 0.3 + (i % 3) * 0.2))
		var f := clampf((t - 3.0) / 2.5, 0.0, 1.0)
		var sp := Vector2(80, -130).lerp(Vector2(-140, -170), f) + Vector2(0, -sin(f * PI) * 80.0)
		if f < 1.0 and beat >= 1:
			r(sp.x, sp.y, 10, 36, Color(0.85, 0.88, 0.95))
			disc(sp.x + 4, sp.y - 6, 12, Color(0.85, 0.88, 0.95))
		if f >= 1.0:
			r(-150, -230, 10, 36, Color(0.85, 0.88, 0.95))
			disc(-146, -236, 12, Color(0.85, 0.88, 0.95))

	func _portraits() -> void:
		for row in 2:
			for col in 4:
				var x := -420.0 + col * 220.0
				var y := -380.0 + row * 170.0
				ob(x, y, 170, 140, Color(0.75, 0.6, 0.25))
				r(x + 10, y + 10, 150, 120, Color(0.35, 0.3, 0.5))
				var bob := 4.0 * sin(t * 2.0 + (row * 4 + col) * 0.7) if beat >= 2 else 0.0
				disc(x + 85, y + 80 + bob, 28, Color(0.9, 0.85, 0.75))
				r(x + 70, y + 60 + bob, 6, 6, Color(0.1, 0.1, 0.12))
				r(x + 98, y + 60 + bob, 6, 6, Color(0.1, 0.1, 0.12))

	func _talk() -> void:
		ob(60, -380, 260, 320, Color(0.75, 0.6, 0.25))
		r(76, -364, 228, 288, Color(0.3, 0.28, 0.4))
		disc(190, -230, 54, Color(0.88, 0.8, 0.65))
		var blink := fposmod(t, 3.0) < 0.25
		r(166, -250, 12, 12 if not blink else 4, Color(0.1, 0.1, 0.12))
		r(206, -250, 12, 12 if not blink else 4, Color(0.1, 0.1, 0.12))
		if beat >= 1:
			ob(200, -420, 150, 50, Color(1, 1, 1))
			r(218, -406, 90, 6, Color(0.3, 0.3, 0.3))
			r(218, -394, 60, 6, Color(0.3, 0.3, 0.3))

	func _sermon() -> void:
		ob(-120, -300, 120, 220, Color(0.5, 0.35, 0.25))        # ambona
		r(-90, -280, 60, 140, Color(0.7, 0.55, 0.35))
		for i in 3:
			ob(-380 + i * 40, -50 + i * 26, 520, 22, Color(0.45, 0.3, 0.2))
		for i in 5:
			var w := extra[i] as CreatureVisual if i < extra.size() else null
			if w:
				var zz := fposmod(t * 20.0 + i * 12.0, 60.0)
				r(w.position.x + 20, w.position.y - 100 - zz, C * 2, C * 2, Color(0.9, 0.9, 1.0, 1.0 - zz / 60.0))

	func _owl() -> void:
		ob(-130, -120, 260, 130, Color(0.55, 0.25, 0.3))      # fotel
		ob(-100, -240, 200, 130, Color(0.65, 0.3, 0.35))
		ob(190, -360, 140, 160, Color(0.85, 0.8, 0.6))         # zegar
		disc(260, -280, 50, Color(1, 1, 0.9))
		r(256, -330, C, 50, Color(0.1, 0.1, 0.12))
		r(260, -282, 36, C, Color(0.1, 0.1, 0.12))
		for i in 3:
			var zz := fposmod(t * 25.0 + i * 25.0, 75.0)
			r(30 + i * 24, -190 - zz, C * 2 + i * 6, C * 2 + i * 6, Color(0.9, 0.9, 1.0, 1.0 - zz / 75.0))

	## Rekwizyty scenek sterowanych danymi.
	func _props(d: Dictionary) -> void:
		for p in d["props"]:
			_prop(String(p[0]), float(p[1]), float(p[2]))

	func _prop(k: String, x: float, y: float) -> void:
		match k:
			"map_table":
				ob(x - 200, y - 130, 400, 50, Color(0.55, 0.38, 0.22))
				r(x - 180, y - 120, 360, 30, Color(0.88, 0.8, 0.6))
				r(x - 110, y - 112, 70, 6, Color(0.5, 0.35, 0.25))
				disc(x + 60, y - 106, 10, Color(0.7, 0.2, 0.2))
				r(x - 180, y - 80, 14, 80, Color(0.4, 0.27, 0.16))
				r(x + 166, y - 80, 14, 80, Color(0.4, 0.27, 0.16))
			"soup":
				var tilt := clampf((t - 3.0) * 0.6, 0.0, 1.0)
				ob(x, y - 24, 70, 26, Color(0.95, 0.95, 0.98))
				r(x + 6, y - 20, 58, 6, Color(0.9, 0.6, 0.2))
				if tilt > 0.0:
					for i in 6:
						r(x + 70 + i * 8, y - 6 + i * 8 * tilt, 6, 14, Color(0.9, 0.6, 0.2, 1.0 - float(i) * 0.12))
			"ledger":
				ob(x - 100, y - 120, 220, 50, Color(0.45, 0.3, 0.2))
				r(x - 80, y - 114, 80, 36, Color(0.95, 0.92, 0.8))
				r(x + 4, y - 114, 80, 36, Color(0.95, 0.92, 0.8))
				for i in 4:
					r(x - 70, y - 106 + i * 8, 60, 3, Color(0.3, 0.25, 0.2))
				for i in 6:
					var yy := fposmod(t * 80.0 + i * 50.0, 340.0)
					r(x - 150 + i * 56, y - 400 + yy, 30, 20, Color(0.95, 0.92, 0.8))
			"coins":
				for i in 24:
					var a := float(i) * 2.4
					disc(x + cos(a) * (20.0 + (i % 6) * 14.0), y - 20 - absf(sin(a)) * 40.0, 9, Color(1.0, 0.85, 0.2))
			"mirror":
				ob(x - 50, y - 330, 120, 250, Color(0.7, 0.55, 0.2))
				r(x - 38, y - 318, 96, 226, Color(0.75, 0.88, 0.95))
				r(x - 20, y - 300, 20, 8, Color(1, 1, 1, 0.6))
				r(x + 4, y - 270, 12, 8, Color(1, 1, 1, 0.5))
			"bed":
				ob(x - 90, y - 70, 210, 60, Color(0.55, 0.3, 0.3))
				r(x - 84, y - 64, 90, 40, Color(0.95, 0.95, 0.98))
				r(x + 6, y - 64, 108, 40, Color(0.6, 0.65, 0.85))
				r(x - 90, y - 90, 14, 90, Color(0.4, 0.27, 0.16))
			"clock":
				ob(x - 36, y - 80, 72, 160, Color(0.45, 0.3, 0.2))
				disc(x, y - 20, 22, Color(1, 1, 0.92))
				r(x - 2, y - 40, 4, 22, Color(0.1, 0.1, 0.12))
				r(x, y - 22, 18, 4, Color(0.1, 0.1, 0.12))
			"cauldron":
				ob(x - 70, y - 90, 150, 90, Color(0.15, 0.15, 0.2))
				r(x - 58, y - 90, 126, 18, Color(0.9, 0.55, 0.2))
				for i in 4:
					var yy := fposmod(t * 40.0 + i * 20.0, 80.0)
					disc(x - 40 + i * 28, y - 100 - yy, 10, Color(1, 1, 1, 0.5 * (1.0 - yy / 80.0)))
				for i in 4:
					r(x - 48 + i * 30, y + 0, 14, 12 + 6.0 * sin(t * 9.0 + i), Color(1.0, 0.6, 0.15))
			"shelf_bottles":
				ob(x - 80, y - 210, 160, 14, Color(0.45, 0.3, 0.2))
				ob(x - 80, y - 140, 160, 14, Color(0.45, 0.3, 0.2))
				for i in 6:
					r(x - 70 + i * 26, y - 250, 16, 40, Color.from_hsv(float(i) * 0.15, 0.6, 0.85))
					r(x - 70 + i * 26, y - 180, 16, 40, Color.from_hsv(float(i) * 0.15 + 0.5, 0.6, 0.8))
			"bars":
				for i in 12:
					r(x - 220 + i * 40, y - 330, 10, 330, Color(0.55, 0.57, 0.64, 0.9))
				r(x - 230, y - 330, 460, 12, Color(0.5, 0.52, 0.58))
				r(x - 230, y - 90, 460, 12, Color(0.5, 0.52, 0.58))
			"keys":
				for i in 7:
					var sw := sin(t * 5.0 + i) * 8.0
					r(x - 90 + i * 28 + sw, y + 0, 8, 46, Color(0.95, 0.8, 0.3))
					disc(x - 86 + i * 28 + sw, y - 6, 9, Color(0.95, 0.8, 0.3))
			"jars":
				for i in 5:
					ob(x - 100 + i * 46, y - 130 - (i % 2) * 40, 34, 70, Color(0.1, 0.08, 0.14))
					r(x - 96 + i * 46, y - 136 - (i % 2) * 40, 26, 8, Color(0.6, 0.5, 0.3))
					if (int(t * 1.5) + i) % 3 == 0:
						r(x - 90 + i * 46, y - 100 - (i % 2) * 40, 8, 8, Color(1.0, 0.9, 0.3))
			"flowers":
				for i in 10:
					r(x - 120 + i * 26, y - 40 - (i % 3) * 8, 4, 40, Color(0.3, 0.6, 0.25))
					disc(x - 118 + i * 26, y - 48 - (i % 3) * 8, 9, Color.from_hsv(float(i) * 0.11, 0.5, 1.0))
			"desk_candle":
				ob(x - 100, y - 100, 220, 28, Color(0.45, 0.3, 0.2))
				r(x - 80, y - 190, 8, 8, Color(1, 1, 0.9))
				r(x - 30, y - 124, 50, 24, Color(0.95, 0.92, 0.8))
				r(x + 60, y - 160, 8, 56, Color(0.95, 0.93, 0.85))
				r(x + 62, y - 176 - 3.0 * sin(t * 9.0), 4, 16, Color(1.0, 0.8, 0.3))
				disc(x + 64, y - 170, 40, Color(1.0, 0.85, 0.4, 0.12))
			"doll":
				for i in 3:
					var jy := -absf(sin(t * 2.5 + i)) * 16.0
					r(x - 40 + i * 44, y - 56 + jy, 22, 36, Color.from_hsv(float(i) * 0.3, 0.6, 0.85))
					disc(x - 29 + i * 44, y - 64 + jy, 13, Color(0.95, 0.85, 0.7))
			"cart":
				ob(x - 160, y - 110, 320, 60, Color(0.5, 0.33, 0.2))
				disc(x - 110, y - 20, 36, Color(0.3, 0.2, 0.12))
				disc(x + 110, y - 20, 36, Color(0.3, 0.2, 0.12))
				r(x - 160, y - 320, 8, 220, Color(0.45, 0.3, 0.2))
				r(x + 152, y - 320, 8, 220, Color(0.45, 0.3, 0.2))
				ob(x - 160, y - 340, 320, 36, Color(0.85, 0.75, 0.45))
				for i in 5:
					r(x - 130 + i * 56, y - 150, 30, 36, Color(0.9, 0.85, 0.6))
			"bread":
				for i in 6:
					var fy := fposmod(t * 60.0 + i * 40.0, 240.0)
					ob(x - 140 + i * 56, y - 40 - fy, 44, 24, Color(0.85, 0.6, 0.3))
				for i in 6:
					r(x - 120 + i * 40, y - 20 + 4.0 * sin(t * 9.0 + i), 14, 22 + 8.0 * sin(t * 7.0 + i), Color(1.0, 0.55, 0.15, 0.9))
