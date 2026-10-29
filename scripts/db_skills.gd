class_name SkillDB
extends RefCounted
## Baza skilli przypisywanych do slotów w ekwipunku (3x3).
## Skile kosztują energię (żółty pasek) i mają cooldown.

const BASE := {
	"furia": {
		"name": "Furia", "type": "special",
		"desc": "Wściekły atak obszarowy. Ładuje się trafieniami (nie podczas trwania furii).",
		"cost": 60.0, "cd": 2.0, "col": Color(1.0, 0.65, 0.15),
	},
	"cios_mocy": {
		"name": "Cios Mocy", "type": "aoe",
		"desc": "Rozwala wrogów wokół ciosm o dużym odrzucie.",
		"cost": 28.0, "cd": 5.0, "dmg": 46.0, "radius": 140.0, "kb": 320.0,
		"col": Color(0.95, 0.45, 0.4),
	},
	"eklipsa": {
		"name": "Eklipsa", "type": "aoe",
		"desc": "Potężna fala uderzeniowa na dużym obszarze.",
		"cost": 55.0, "cd": 18.0, "dmg": 72.0, "radius": 210.0, "kb": 420.0,
		"col": Color(0.6, 0.35, 0.9),
	},
	"pocisk": {
		"name": "Pocisk", "type": "projectile",
		"desc": "Wystrzukuje szybki pocisk przed siebie.",
		"cost": 14.0, "cd": 2.5, "dmg": 20.0,
		"col": Color(0.5, 0.8, 0.95),
	},
	"kopniak": {
		"name": "Kopniak", "type": "dash_strike",
		"desc": "Pędzi do przodu z ciosem w biegu.",
		"cost": 22.0, "cd": 4.0, "dmg": 30.0,
		"col": Color(0.75, 0.9, 0.4),
	},
	"uzdrowienie": {
		"name": "Uzdrowienie", "type": "heal",
		"desc": "Strefa leczenia: sojusznicy w zasięgu odzyskują życie przez 5 s.",
		"cost": 45.0, "cd": 14.0, "heal": 36.0, "radius": 220.0, "duration": 5.0,
		"col": Color(0.4, 0.9, 0.5),
	},
	"tarcza": {
		"name": "Tarcza", "type": "shield",
		"desc": "Kopuła ochronna: sojusznicy w środku otrzymują o 60% mniej obrażeń przez 6 s.",
		"cost": 34.0, "cd": 16.0, "duration": 6.0, "radius": 240.0, "reduction": 0.6,
		"col": Color(0.85, 0.9, 1.0),
	},
	"warcry": {
		"name": "Wojenny Krzyk", "type": "buff",
		"desc": "Chwilowo zwiększa siłę i szybkość.",
		"cost": 30.0, "cd": 20.0, "duration": 8.0, "strength": 0.35, "speed": 0.25,
		"col": Color(1.0, 0.8, 0.3),
	},
	# --- Wojownik ---
	"szal_bojowy": {
		"name": "Szał Bojowy", "type": "berserk",
		"desc": "Przez 10 s tracisz panowanie. Wirujesz z normalną prędkością, ścigasz najbliższego wroga/gracza i atakujesz wszystko wokół. Trwa dokładnie 10 s.",
		"cost": 50.0, "cd": 45.0, "duration": 10.0, "hp_mult": 1.6, "atk_mult": 1.7,
		"col": Color(0.95, 0.25, 0.2),
	},
	"potezny_zamach": {
		"name": "Potężny Zamach", "type": "power_swing",
		"desc": "Potężny, szeroki zamach odrzucający wszystko przed tobą.",
		"cost": 30.0, "cd": 6.0, "dmg": 60.0, "kb": 520.0, "range": 96.0,
		"col": Color(0.95, 0.55, 0.25),
	},
	# --- Łucznik ---
	"headshot": {
		"name": "Headshot", "type": "headshot",
		"desc": "Precyzyjny strzał w głowę — zawsze krytyczny.",
		"cost": 22.0, "cd": 6.0, "dmg": 44.0,
		"col": Color(0.85, 0.95, 0.4),
	},
	"trojszot": {
		"name": "Trójszot", "type": "triple_shot",
		"desc": "Wypuszcza trzy strzały w wachlarzu.",
		"cost": 30.0, "cd": 7.0, "dmg": 18.0, "spread": 22.0,
		"col": Color(0.6, 0.9, 0.5),
	},
	# --- Fechmistrz ---
	"piruet": {
		"name": "Piruet", "type": "pirouette",
		"desc": "Obraca się z mieczem, raniąc wszystko dookoła.",
		"cost": 26.0, "cd": 5.0, "dmg": 34.0, "radius": 120.0,
		"col": Color(0.7, 0.85, 1.0),
	},
	"krag_antypotworowy": {
		"name": "Krąg Antypotworowy", "type": "barrier",
		"desc": "Przez 30 s potwory nie mogą wejść do kręgu. Gracze mogą.",
		"cost": 45.0, "cd": 40.0, "duration": 30.0, "radius": 130.0,
		"col": Color(0.5, 0.95, 0.95),
	},
	# --- Złodziej ---
	"kradziez": {
		"name": "Kradzież", "type": "steal",
		"desc": "Okradasz najbliższy cel — potwora, NPC albo gracza: otwiera się jego ekwipunek i zabierasz, co chcesz. Każda rzecz to ryzyko zauważenia.",
		"cost": 0.0, "cd": 10.0,
		"col": Color(0.55, 0.5, 0.65),
	},
	"cien": {
		"name": "Cień", "type": "shadow",
		"desc": "Ukrywa się w cieniach — nietykalny i niewidzialny dla wrogów.",
		"cost": 25.0, "cd": 16.0, "duration": 4.5,
		"col": Color(0.25, 0.25, 0.4),
	},
	# --- Mag (zaklęcia z księgi) ---
	"kula_ognia": {
		"name": "Kula Ognia", "type": "projectile",
		"desc": "Zaklęcie: ognisty pocisk zadający duże obrażenia.",
		"cost": 18.0, "cd": 2.5, "dmg": 30.0,
		"col": Color(1.0, 0.55, 0.2),
	},
	"lodowa_lanca": {
		"name": "Lodowa Lanca", "type": "projectile",
		"desc": "Zaklęcie: lodowy pocisk, który ogłusza trafionych.",
		"cost": 20.0, "cd": 4.0, "dmg": 22.0, "stun": 1.0,
		"col": Color(0.55, 0.8, 1.0),
	},
	"iskra": {
		"name": "Iskra", "type": "aoe",
		"desc": "Zaklęcie: błyskawica rażąca wszystko dookoła.",
		"cost": 25.0, "cd": 6.0, "dmg": 40.0, "radius": 150.0, "kb": 260.0,
		"col": Color(0.9, 0.85, 0.4),
	},
	# --- Drzewko umiejętności -----------------------------------------
	"odnowa": {
		"name": "Odnowa", "type": "hot",
		"desc": "Leczy Cię stopniowo przez 6 s.",
		"cost": 25.0, "cd": 16.0, "heal": 60.0, "duration": 6.0, "col": Color(0.45, 0.95, 0.55),
	},
	"unik_mgla": {
		"name": "Mglisty Unik", "type": "blink",
		"desc": "Błyskawicznie przemieszczasz się o kilka kroków i na chwilę stajesz się nietykalny.",
		"cost": 14.0, "cd": 5.0, "dist": 210.0, "duration": 0.35, "col": Color(0.7, 0.85, 1.0),
	},
	"zelazna_skora": {
		"name": "Żelazna Skóra", "type": "iron_skin",
		"desc": "Przez 8 s otrzymujesz o 50% mniej obrażeń.",
		"cost": 28.0, "cd": 22.0, "duration": 8.0, "reduction": 0.5, "col": Color(0.7, 0.75, 0.85),
	},
	"wstrzas": {
		"name": "Wstrząs", "type": "aoe",
		"desc": "Uderzenie w ziemię rani i odpycha wrogów wokół.",
		"cost": 30.0, "cd": 7.0, "dmg": 55.0, "radius": 170.0, "kb": 380.0, "stun": 0.5, "col": Color(0.85, 0.6, 0.35),
	},
	"szarza": {
		"name": "Szarża Taranem", "type": "dash_strike",
		"desc": "Pędzisz naprzód i uderzasz potężnym ciosem.",
		"cost": 24.0, "cd": 6.0, "dmg": 45.0, "col": Color(0.9, 0.7, 0.4),
	},
	"chmurowy_wzlot": {
		"name": "Chmurowy Wzlot", "type": "leap",
		"desc": "Wzbijasz się w powietrze i lądujesz z falą uderzeniową. W locie jesteś nietykalny.",
		"cost": 26.0, "cd": 9.0, "dist": 280.0, "dmg": 30.0, "radius": 110.0, "duration": 0.45, "col": Color(0.8, 0.9, 1.0),
	},
	"krzyk_ogluszajacy": {
		"name": "Ogłuszający Krzyk", "type": "stun_all",
		"desc": "Fala dźwięku oszałamia wszystkich wrogów w zasięgu.",
		"cost": 36.0, "cd": 20.0, "duration": 2.0, "radius": 250.0, "col": Color(0.85, 0.65, 1.0),
	},
	"okowy_lodu": {
		"name": "Lodowe Okowy", "type": "aoe",
		"desc": "Lodowa fala zamraża wrogów w miejscu na prawie 2 s.",
		"cost": 30.0, "cd": 10.0, "dmg": 22.0, "radius": 210.0, "kb": 60.0, "stun": 1.8, "col": Color(0.5, 0.85, 1.0),
	},
	"krag_ognia": {
		"name": "Krąg Ognia", "type": "fire_zone",
		"desc": "Płonący krąg pali wrogów przez 5 s.",
		"cost": 34.0, "cd": 14.0, "dmg": 30.0, "radius": 150.0, "duration": 5.0, "col": Color(1.0, 0.5, 0.2),
	},
	"burza_pior": {
		"name": "Burza Piór", "type": "aoe",
		"desc": "Ogromna burza piór niszczy wszystko wokół i ogłusza.",
		"cost": 44.0, "cd": 16.0, "dmg": 95.0, "radius": 240.0, "kb": 420.0, "stun": 0.7, "col": Color(0.95, 0.9, 0.7),
	},
	"bastion": {
		"name": "Bastion", "type": "iron_skin",
		"desc": "Przez 6 s otrzymujesz o 70% mniej obrażeń.",
		"cost": 40.0, "cd": 28.0, "duration": 6.0, "reduction": 0.7, "col": Color(0.6, 0.7, 1.0),
	},
	"komenda_ataku": {
		"name": "Komenda Ataku", "type": "pet_command",
		"desc": "Towarzysze atakują dwa razy szybciej przez 8 s.",
		"cost": 20.0, "cd": 16.0, "duration": 8.0, "col": Color(1.0, 0.85, 0.4),
	},
	"ochrona_pupila": {
		"name": "Ochrona Pupila", "type": "pet_guard",
		"desc": "Przez 8 s towarzysze wzmacniają ochronę: sowa leczy 1,8× mocniej, a żółw daje podwójną redukcję obrażeń.",
		"cost": 24.0, "cd": 22.0, "duration": 8.0, "col": Color(0.95, 0.8, 0.5),
	},
	"zew_wsparcia": {
		"name": "Zew Wsparcia", "type": "rally",
		"desc": "Leczy sojuszników w zasięgu i wzmacnia ich siłę.",
		"cost": 38.0, "cd": 20.0, "heal": 40.0, "radius": 260.0, "duration": 6.0, "strength": 0.2, "col": Color(1.0, 0.8, 0.9),
	},
	"blogoslawienstwo": {
		"name": "Błogosławieństwo", "type": "buff",
		"desc": "Drużyna zyskuje siłę i szybkość na 10 s.",
		"cost": 40.0, "cd": 30.0, "duration": 10.0, "strength": 0.3, "speed": 0.2, "col": Color(1.0, 0.9, 0.6),
	},
	"wicher_ostrzy": {
		"name": "Wicher Ostrzy", "type": "pirouette",
		"desc": "Niszczycielski wir tnie wszystko wokół.",
		"cost": 45.0, "cd": 14.0, "dmg": 90.0, "radius": 170.0, "col": Color(0.85, 0.95, 1.0),
	},
	"furia_tytana": {
		"name": "Furia Tytana", "type": "titan",
		"desc": "Przez 12 s: +60% siły i o 40% mniejsze obrażenia.",
		"cost": 60.0, "cd": 60.0, "duration": 12.0, "strength": 0.6, "reduction": 0.4, "col": Color(1.0, 0.35, 0.3),
	},
	# --- Lady ---
	"oszolomienie": {
		"name": "Korona Oszołomienia", "type": "stun_all",
		"desc": "Wokół Lady rozprzestrzenia się fala oszołomienia. Wrogowie tracą zdolność ruchu i ataku na krótki czas.",
		"cost": 40.0, "cd": 18.0, "duration": 3.2, "radius": 190.0,
		"col": Color(0.9, 0.7, 1.0),
	},
}

## Skille bazowe i skille poszczególnych klas (ClassSkillDB).
static var LIST: Dictionary = BASE.merged(ClassSkillDB.skills())

static func default_slots() -> Array:
	return ["furia", "", "", "", "", ""]

static func has(id: String) -> bool:
	return LIST.has(id)

static func get_data(id: String) -> Dictionary:
	return LIST.get(id, {})

static func all() -> Array:
	return LIST.keys()
