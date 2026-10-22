class_name NpcDB
extends RefCounted

const LIST := {
	"starosta": {
		"name": "Starosta Bartosz",
		"title": "Starosta wioski",
		"species": "kurczak",
		"scale": 1.6,
		"pos": Vector2(1120, 985),
		"accent": Color(1.0, 0.72, 0.25),
		"role": "quest",
	},
	"kowal": {
		"name": "Kowal Grzegorz",
		"title": "Kowal",
		"species": "kogut",
		"scale": 1.55,
		"pos": Vector2(610, 1165),
		"accent": Color(0.95, 0.55, 0.3),
		"role": "smith",
	},
	"kasia": {
		"name": "Kasia",
		"title": "Dziecko",
		"species": "kwoka",
		"scale": 1.25,
		"pos": Vector2(905, 875),
		"accent": Color(0.95, 0.8, 0.4),
		"role": "lore",
	},
	"straznik": {
		"name": "Strażnik Michał",
		"title": "Straż wioski",
		"species": "gasior",
		"scale": 1.5,
		"pos": Vector2(1350, 1175),
		"accent": Color(0.6, 0.85, 0.6),
		"role": "guard",
	},
	"kupiec": {
		"name": "Kupiec Wacław",
		"title": "Kupiec",
		"species": "indyk",
		"scale": 1.65,
		"pos": Vector2(1600, 950),
		"accent": Color(0.95, 0.85, 0.45),
		"role": "shop",
	},
}

static func get_data(id: String) -> Dictionary:
	return LIST.get(id, {})

static func pal_for(id: String) -> Dictionary:
	var d := get_data(id)
	var species := String(d.get("species", "kurczak"))
	return CharacterDB.get_data(species).get("pal", {})

static func hero_title(char_id: String) -> String:
	return String(CharacterDB.get_data(char_id).get("title", "Lord"))

## Linie dialogu jako [[kto, tekst], ...]. Puste "kto" = narrator.
## quest_id: aktywny rozdział (dla rozdziałów II+ generujemy dialog z ZoneDB).
static func lines_for(id: String, step: int, flags: Dictionary, char_id: String, quest_id: String = "obrona_wioski") -> Array:
	if quest_id != "" and quest_id != "obrona_wioski" and ZoneDB.has(quest_id):
		return _zone_lines(id, step, char_id, quest_id)
	match id:
		"starosta":
			return _hero_lines(step, flags, char_id)
		"kowal":
			return _kowal(step, flags, char_id)
		"kasia":
			return _kasia(step, flags, char_id)
		"straznik":
			return _straznik(step, flags, char_id)
		"kupiec":
			return _kupiec(char_id)
	return [[get_data(id).get("name", "?"), "..." ]]

## Dialog dla rozdziałów II+. Dawca zadania prowadzi fabułę, inni komentują.
static func _zone_lines(id: String, step: int, char_id: String, quest_id: String) -> Array:
	var t := hero_title(char_id)
	var zone := ZoneDB.get_data(quest_id)
	var quest := QuestDB.get_data(quest_id)
	var giver := String(zone.get("giver", "straznik"))
	var waves_n: int = (zone.get("waves", []) as Array).size()
	var who := String(get_data(id).get("name", "?"))
	var qtitle := String(quest.get("title", "wyprawa"))
	if id == "kupiec":
		return _kupiec(char_id)
	if id == "kowal":
		if step > waves_n:
			return [["Kowal Grzegorz", "Kuźnia pracuje dla ciebie, %s. Wracaj caly z tej wyprawy." % t]]
		return [["Kowal Grzegorz", "Ostroga ostra, serce twarde. Idź i nie oglądaj się za siebie."]]
	if id == giver:
		if step == 0:
			return [
				["", "%s rozgląda się po okolicy i kiwa na ciebie." % who],
				[who, "%s. Wiem, że jesteś gotów. Neprzyjaciel czeka — ruszaj, a my ruszamy z tobą." % t],
				[who, "Trzy starcia i oczyścimy drogę. Potem ruszamy dalej."],
			]
		if step > waves_n:
			return [
				["", "Wróg cofnięty. %s odzyskuje oddech." % qtitle],
				[who, "Udało się, %s. Jesteś o krok bliżej Kruka." % t],
				[who, "Odpocznij chwilę. Droga wiedzie dalej — kolejny rozdział czeka."],
			]
		return [[who, "Fala %d z %d! Trzymaj szyk, %s — dajemy radę!" % [step, waves_n, t]]]
	# inni NPC w strefie
	if step >= 1 and step <= waves_n:
		return [[who, "Widzę je! Nadciągają! Wal w skrzydła — tam nie mają pancerza!"]]
	if step > waves_n:
		return [[who, "Daliśmy radę! Zapamiętam ten dzień do końca życia."]]
	return [
		[who, "Jesteśmy z tobą, %s. Trzymaj się blisko i słuchaj rozkazów." % t],
		[who, "Gdy wróg szarżuje — unik i kontra. Proste rzeczy ratują życie."],
	]

static func _hero_lines(step: int, flags: Dictionary, char_id: String) -> Array:
	var t := hero_title(char_id)
	if bool(flags.get("chapter1_done", false)):
		return [
			["Starosta Bartosz", "%s! Wioska świętuje, ale spójrz na trakt — nadciąga kurz. To nie koniec." % t],
			["Starosta Bartosz", "Królowa musi wiedzieć o Kruku. Idź na wschód i nie ufaj każdemu strażnikowi."],
		]
	match step:
		0:
			return [
				["", "Starosta ściska ci ramię, jakby szukał w tobie ostatniej nadziei."],
				["Starosta Bartosz", "%s! Dobrze, że jesteś. Spójrz na niebo — Kruk przysłał swoje hordy." % t],
				["Starosta Bartosz", "Wioska nie ma murów, tylko nasze dzioby i twoje ramiona. Strażnik Michał zbiera ludzi przy studni."],
				["Starosta Bartosz", "Kowal przygotował, co mógł. Kasia ukryła się w chacie, ale wciąż pyta o ciebie."],
				["Starosta Bartosz", "Nie wiemy, czemu Kruk uderza akurat teraz. Wiemy tylko, że chce nas złamać."],
				["Starosta Bartosz", "Obroń nas. Trzy fale i doczekamy świtu. Potem ruszysz do stolicy — królowa musi się dowiedzieć."],
			]
		1:
			return [["Starosta Bartosz", "Pierwsza fala nadciąga od pól! Trzymaj się blisko studni — tam mamy osłonę."]]
		2:
			return [
				["Starosta Bartosz", "Sroki strzelają z dystansu. %s, nie stój w miejscu!" % t],
				["Starosta Bartosz", "Michał mówi, że widział chorągiew z herbem Kruka. To gorzej, niż myśleliśmy."],
			]
		3:
			return [
				["Starosta Bartosz", "Ostatnia fala! Kawki są ciężkie, ale wolne. Unikaj szarż i uderzaj z boku!"],
			]
		4:
			return [
				["", "Kurczaki podnoszą głowy. Nad dachami wschodzi świt — pierwszy od wielu nocy."],
				["Starosta Bartosz", "Udało się... Wioska żyje. Strażnik mówi, że to był tylko zwiad Kruka."],
				["Starosta Bartosz", "Królowa musi wiedzieć. W stolicy trwa walka o tron, a Kruk uderzy tam, gdzie najsłabiej."],
				["Starosta Bartosz", "Weź to złoto i mikstury. Kowal dołożył od siebie najlepszą stal."],
				["Starosta Bartosz", "Idź traktem na wschód, %s. I uważaj — nie każdy strażnik na drodze służy koronie." % t],
			]
	return [["Starosta Bartosz", "Świt jest nasz. Odpocznij, %s." % t]]

static func _kowal(step: int, flags: Dictionary, char_id: String) -> Array:
	var t := hero_title(char_id)
	if not bool(flags.get("kowal_gift", false)):
		return [
			["Kowal Grzegorz", "Stal hartuje się w ogniu, a przywódcę w bitwie. Dzisiaj przekonamy się, z czego jesteś."],
			["Kowal Grzegorz", "Masz, weź tę miksturę — warzyłem ją całą noc. Postawisz się na nogi, gdy będzie krucho."],
		]
	if bool(flags.get("chapter1_done", false)):
		return [
			["Kowal Grzegorz", "Wróciłeś cały, %s. Zrobię ci broń, o jakiej śniłeś — jak tylko dotrzesz do stolicy." % t],
		]
	return [
		["Kowal Grzegorz", "Trzymaj się z dala od dziobów i pamiętaj: blok nie kosztuje nic oprócz odwagi."],
	]

static func _kasia(step: int, flags: Dictionary, char_id: String) -> Array:
	var t := hero_title(char_id)
	if bool(flags.get("chapter1_done", false)):
		return [
			["Kasia", "Widziałam, jak walczysz! Byłeś jak burza, %s!" % t],
			["Kasia", "Mama mówi, że teraz pojedziesz do stolicy. Wróć do nas, dobrze?"],
		]
	return [
		["Kasia", "Mamo mówiła, że Czarny Kruk boi się światła. Ale to chyba bajka na dobranoc..."],
		["Kasia", "Widziałam czarne skrzydła nad lasem. Były ogromne. Nie mów staroście, że wyszłam z chaty."],
	]

static func _straznik(step: int, flags: Dictionary, char_id: String) -> Array:
	if step >= 1 and step <= 3:
		return [
			["Strażnik Michał", "Widzę je! Nadciągają! Trzymaj szyk, wal w skrzydła — tam nie mają pancerza."],
		]
	if bool(flags.get("chapter1_done", false)):
		return [
			["Strażnik Michał", "Daliśmy radę. Daliśmy radę! Zapamiętam ten świt do końca życia."],
		]
	return [
		["Strażnik Michał", "Jestem Michał, dowodzę tą garstką. Słuchaj: gdy wróg szarżuje, zejdź z linii i uderz z boku."],
		["Strażnik Michał", "A gdy zrobi się gorąco — unik, blok i kontra. Proste rzeczy ratują życie."],
	]

static func _kupiec(char_id: String) -> Array:
	var t := hero_title(char_id)
	return [
		["Kupiec Wacław", "O, %s we własnej osobie! W czasach wojny handel kwitnie — jeśli masz złoto." % t],
		["Kupiec Wacław", "Rozejrzyj się po moim kramie. Broń, pancerz, talizmany... wszystko, co utrzyma cię przy życiu."],
	]
