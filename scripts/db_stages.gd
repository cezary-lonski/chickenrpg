class_name StageDB
extends RefCounted
## Etapy. Fala = {"enemies": [[id, ile], ...], "air": bool, "tag": String}
## Pozycje w "platforms" to [x, y, szerokość] — półki, na które można wskoczyć.

const LIST := [
	{
		"id": "podworko",
		"name": "Podwórko",
		"subtitle": "Tu zaczyna się wszystko",
		"length": 3600.0,
		"ground_y": 560.0,
		"sky": [Color(0.36, 0.62, 0.78), Color(0.75, 0.86, 0.9)],
		"sun": Color(1.0, 0.95, 0.72),
		"ground": [Color(0.36, 0.48, 0.26), Color(0.25, 0.34, 0.18)],
		"accent": Color(0.62, 0.45, 0.24),
		"props": {"fence": true, "hay": 2, "trees": 0, "barn": false, "fog": 0.0},
		"platforms": [[1250, 430, 190], [2400, 400, 210]],
		"waves": [
			{"enemies": [["wrzos", 2]], "air": false},
			{"enemies": [["wrzos", 3]], "air": false},
			{"enemies": [["sroka", 2], ["wrzos", 2]], "air": true},
			{"enemies": [["kawka", 2], ["wrzos", 2]], "air": false},
			{"enemies": [["wronszek", 3], ["sroka", 1]], "air": false},
			{"enemies": [["kawka", 1], ["wronszek", 2], ["sroka", 1]], "air": true},
		],
		"reward": {"gold": 60, "cod": 1},
	},
	{
		"id": "sad",
		"name": "Sad jabłoniowy",
		"subtitle": "Głośno, ale nie tak źle",
		"length": 4200.0,
		"ground_y": 560.0,
		"sky": [Color(0.5, 0.55, 0.72), Color(0.92, 0.78, 0.66)],
		"sun": Color(1.0, 0.82, 0.6),
		"ground": [Color(0.3, 0.42, 0.22), Color(0.2, 0.3, 0.15)],
		"accent": Color(0.5, 0.36, 0.2),
		"props": {"fence": true, "hay": 0, "trees": 7, "barn": false, "fog": 0.08, "apples": true},
		"platforms": [[900, 420, 200], [2050, 450, 170], [3100, 400, 230]],
		"waves": [
			{"enemies": [["kawka", 3]], "air": false},
			{"enemies": [["wronszek", 3], ["sroka", 2]], "air": true},
			{"enemies": [["jastrzab", 2], ["wrzos", 2]], "air": false},
			{"enemies": [["kruk", 1], ["wronszek", 2]], "air": false},
			{"enemies": [["jastrzab", 3], ["szpak", 1]], "air": true},
			{"enemies": [["kruk", 2], ["sroka", 2]], "air": false},
		],
		"reward": {"gold": 110, "cod": 2},
	},
	{
		"id": "las",
		"name": "Gaj Kruczy",
		"subtitle": "Tu mieszka ten, o którym szeptali",
		"length": 4600.0,
		"ground_y": 560.0,
		"sky": [Color(0.16, 0.24, 0.3), Color(0.42, 0.55, 0.5)],
		"sun": Color(0.7, 0.85, 0.75),
		"ground": [Color(0.2, 0.3, 0.2), Color(0.11, 0.18, 0.13)],
		"accent": Color(0.35, 0.3, 0.22),
		"props": {"fence": false, "hay": 0, "trees": 14, "barn": false, "fog": 0.25, "mushrooms": true},
		"platforms": [[1000, 400, 220], [1900, 340, 200], [2900, 420, 190], [3700, 360, 240]],
		"waves": [
			{"enemies": [["jastrzab", 3], ["wronszek", 2]], "air": true},
			{"enemies": [["kruk", 2]], "air": false},
			{"enemies": [["szpak", 2], ["jastrzab", 2]], "air": true},
			{"enemies": [["kruk", 1], ["jastrzab", 2], ["wronszek", 2]], "air": false, "tag": "miniboss"},
			{"enemies": [["orzel_szarak", 2], ["szpak", 2]], "air": true},
			{"enemies": [["bocian_gruby", 1], ["kruk", 2]], "air": false},
		],
		"reward": {"gold": 170, "cod": 3},
	},
	{
		"id": "stodola",
		"name": "Stodoła Pod Piórem",
		"subtitle": "Ostatnie gniazdo",
		"length": 3000.0,
		"ground_y": 560.0,
		"sky": [Color(0.1, 0.1, 0.16), Color(0.4, 0.2, 0.18)],
		"sun": Color(1.0, 0.6, 0.3),
		"ground": [Color(0.3, 0.24, 0.18), Color(0.18, 0.14, 0.1)],
		"accent": Color(0.55, 0.35, 0.2),
		"props": {"fence": false, "hay": 4, "trees": 3, "barn": true, "fog": 0.35, "embers": true},
		"platforms": [[1100, 400, 220], [2000, 380, 240]],
		"waves": [
			{"enemies": [["kruk", 2], ["szpak", 2]], "air": true},
			{"enemies": [["bocian_gruby", 1], ["orzel_szarak", 2]], "air": false},
			{"enemies": [["kruk", 3], ["jastrzab", 2], ["szpak", 1]], "air": true, "tag": "last"},
			{"enemies": [["indyk_krolewski", 1]], "air": false, "tag": "boss"},
		],
		"reward": {"gold": 300, "cod": 6},
	},
	{
		"id": "bagno",
		"name": "Bagno Szeptów",
		"subtitle": "Ziemia ssie, ptaki krzyczą",
		"length": 4400.0,
		"ground_y": 560.0,
		"sky": [Color(0.22, 0.3, 0.32), Color(0.55, 0.62, 0.5)],
		"sun": Color(0.85, 0.9, 0.7),
		"ground": [Color(0.24, 0.32, 0.24), Color(0.14, 0.2, 0.16)],
		"accent": Color(0.4, 0.38, 0.26),
		"props": {"fence": false, "hay": 0, "trees": 9, "barn": false, "fog": 0.3, "mushrooms": true},
		"platforms": [[950, 410, 200], [1850, 360, 190], [2750, 420, 210], [3550, 380, 200]],
		"waves": [
			{"enemies": [["czajka", 3], ["golab", 2]], "air": true},
			{"enemies": [["puchacz", 1], ["czajka", 3]], "air": false},
			{"enemies": [["sokol", 2], ["golab", 2]], "air": true},
			{"enemies": [["kruk", 2], ["sokol", 2], ["golab", 1]], "air": false, "tag": "miniboss"},
			{"enemies": [["puchacz", 2], ["czajka", 3]], "air": false},
			{"enemies": [["bocian_gruby", 1], ["sokol", 2], ["golab", 2]], "air": true},
		],
		"reward": {"gold": 240, "cod": 4},
	},
	{
		"id": "gniazdo",
		"name": "Orle Gniazdo",
		"subtitle": "Ostatnia skała, ostatni król",
		"length": 3200.0,
		"ground_y": 560.0,
		"sky": [Color(0.08, 0.14, 0.28), Color(0.5, 0.62, 0.82)],
		"sun": Color(1.0, 0.92, 0.8),
		"ground": [Color(0.32, 0.3, 0.34), Color(0.18, 0.17, 0.2)],
		"accent": Color(0.5, 0.42, 0.3),
		"props": {"fence": false, "hay": 0, "trees": 2, "barn": false, "fog": 0.2},
		"platforms": [[1050, 380, 220], [1950, 340, 230]],
		"waves": [
			{"enemies": [["puchacz", 2], ["sokol", 2]], "air": true},
			{"enemies": [["kruk", 3], ["czajka", 3], ["golab", 2]], "air": false, "tag": "last"},
			{"enemies": [["krol_krukow", 1]], "air": false, "tag": "boss"},
		],
		"reward": {"gold": 520, "cod": 8},
	},
]

static func count() -> int:
	return LIST.size()

static func get_stage(i: int) -> Dictionary:
	if i < 0 or i >= LIST.size():
		return LIST[LIST.size() - 1]
	return LIST[i]

static func index_of(id: String) -> int:
	for i in LIST.size():
		if String(LIST[i]["id"]) == id:
			return i
	return 0
