class_name EnemyDB
extends RefCounted
## Definicje wrogów. ai: charger | ranged | dasher | grappler | sprinter | boss
## attacks: lista dict {name, range, windup, active, recover, dmg, kb, stun, launch, type}

const LIST := {
	"wrzos": {
		"name": "Wrzoseł", "ai": "charger", "scale": 0.82, "tier": 1,
		"health": 34.0, "defense": 0.0, "speed": 118.0, "poise": 0.0, "xp": 12, "gold": 3,
		"pal": {"body": Color(0.78, 0.62, 0.3), "shade": Color(0.6, 0.46, 0.2), "beak": Color(0.98, 0.8, 0.3), "eye": Color(0.05, 0.05, 0.06)},
		"aggro": 420.0, "attack_range": 44.0, "cooldown": [0.9, 1.7],
		"attacks": [
			{"name": "dziobanie", "range": 48.0, "windup": 0.28, "active": 0.12, "recover": 0.34, "dmg": 7.0, "kb": 150.0, "stun": 0.3},
		],
	},
	"sroka": {
		"name": "Sroka", "ai": "ranged", "scale": 0.88, "tier": 1,
		"health": 28.0, "defense": 0.0, "speed": 128.0, "poise": 0.0, "xp": 14, "gold": 4,
		"pal": {"body": Color(0.35, 0.38, 0.45), "shade": Color(0.22, 0.25, 0.32), "beak": Color(0.9, 0.85, 0.5), "eye": Color(0.95, 0.9, 0.85)},
		"aggro": 520.0, "attack_range": 330.0, "keep_distance": 250.0, "cooldown": [1.2, 2.2],
		"attacks": [
			{"name": "pióro", "range": 400.0, "windup": 0.42, "active": 0.1, "recover": 0.5, "dmg": 8.0, "kb": 120.0, "stun": 0.25, "projectile": "feather"},
		],
	},
	"wronszek": {
		"name": "Wrończyk", "ai": "sprinter", "scale": 0.78, "tier": 2,
		"health": 26.0, "defense": 0.0, "speed": 205.0, "poise": 0.0, "xp": 15, "gold": 4,
		"pal": {"body": Color(0.92, 0.6, 0.25), "shade": Color(0.74, 0.44, 0.16), "beak": Color(0.99, 0.82, 0.3), "eye": Color(0.1, 0.08, 0.05)},
		"aggro": 620.0, "attack_range": 42.0, "cooldown": [0.7, 1.3],
		"attacks": [
			{"name": "szarp", "range": 46.0, "windup": 0.16, "active": 0.1, "recover": 0.26, "dmg": 9.0, "kb": 130.0, "stun": 0.3},
		],
	},
	"kawka": {
		"name": "Kawka", "ai": "charger", "scale": 1.0, "tier": 2,
		"health": 58.0, "defense": 0.06, "speed": 105.0, "poise": 0.15, "xp": 22, "gold": 7,
		"pal": {"body": Color(0.24, 0.25, 0.3), "shade": Color(0.15, 0.16, 0.2), "beak": Color(0.85, 0.85, 0.88), "eye": Color(0.9, 0.85, 0.3)},
		"aggro": 500.0, "attack_range": 50.0, "cooldown": [1.0, 1.9],
		"attacks": [
			{"name": "dziobanie", "range": 54.0, "windup": 0.3, "active": 0.12, "recover": 0.36, "dmg": 12.0, "kb": 190.0, "stun": 0.35},
			{"name": "skok_dziobiem", "range": 190.0, "windup": 0.44, "active": 0.3, "recover": 0.6, "dmg": 14.0, "kb": 240.0, "stun": 0.4, "leap": true},
		],
	},
	"jastrzab": {
		"name": "Jastrząb", "ai": "dasher", "scale": 0.98, "tier": 3,
		"health": 62.0, "defense": 0.05, "speed": 175.0, "poise": 0.1, "xp": 30, "gold": 9,
		"pal": {"body": Color(0.72, 0.48, 0.22), "shade": Color(0.52, 0.32, 0.12), "beak": Color(0.95, 0.85, 0.35), "eye": Color(0.98, 0.75, 0.1)},
		"aggro": 700.0, "attack_range": 54.0, "cooldown": [0.8, 1.5],
		"attacks": [
			{"name": "szpon", "range": 56.0, "windup": 0.2, "active": 0.12, "recover": 0.28, "dmg": 13.0, "kb": 170.0, "stun": 0.3},
			{"name": "nurk", "range": 340.0, "windup": 0.5, "active": 0.42, "recover": 0.7, "dmg": 17.0, "kb": 300.0, "stun": 0.5, "dash": true},
		],
	},
	"kruk": {
		"name": "Kruk Łupieżca", "ai": "grappler", "scale": 1.18, "tier": 3,
		"health": 120.0, "defense": 0.12, "speed": 88.0, "poise": 0.4, "xp": 46, "gold": 15,
		"pal": {"body": Color(0.14, 0.14, 0.18), "shade": Color(0.07, 0.07, 0.1), "beak": Color(0.6, 0.6, 0.65), "eye": Color(1.0, 0.5, 0.2)},
		"aggro": 620.0, "attack_range": 60.0, "cooldown": [1.2, 2.0],
		"attacks": [
			{"name": "lapacz", "range": 66.0, "windup": 0.42, "active": 0.18, "recover": 0.6, "dmg": 18.0, "kb": 90.0, "stun": 0.9, "grab": true},
			{"name": "moknięcie", "range": 74.0, "windup": 0.36, "active": 0.14, "recover": 0.5, "dmg": 12.0, "kb": 260.0, "stun": 0.45},
		],
	},
	"orzel_szarak": {
		"name": "Orzeł Szarak", "ai": "sprinter", "scale": 1.12, "tier": 4,
		"health": 96.0, "defense": 0.1, "speed": 230.0, "poise": 0.25, "xp": 58, "gold": 18,
		"pal": {"body": Color(0.45, 0.5, 0.58), "shade": Color(0.28, 0.32, 0.4), "beak": Color(0.98, 0.8, 0.2), "eye": Color(0.99, 0.7, 0.1)},
		"aggro": 800.0, "attack_range": 56.0, "cooldown": [0.6, 1.1],
		"attacks": [
			{"name": "cięcie", "range": 60.0, "windup": 0.18, "active": 0.1, "recover": 0.24, "dmg": 15.0, "kb": 200.0, "stun": 0.3},
		],
	},
	"bocian_gruby": {
		"name": "Bocian Gruby", "ai": "grappler", "scale": 1.3, "tier": 4,
		"health": 160.0, "defense": 0.16, "speed": 78.0, "poise": 0.6, "xp": 66, "gold": 22,
		"pal": {"body": Color(0.93, 0.93, 0.95), "shade": Color(0.72, 0.72, 0.78), "beak": Color(0.95, 0.3, 0.25), "eye": Color(0.1, 0.1, 0.12)},
		"aggro": 640.0, "attack_range": 72.0, "cooldown": [1.1, 1.8],
		"attacks": [
			{"name": "dziobanie", "range": 78.0, "windup": 0.46, "active": 0.16, "recover": 0.55, "dmg": 22.0, "kb": 280.0, "stun": 0.6},
			{"name": "trzepot", "range": 200.0, "windup": 0.5, "active": 0.4, "recover": 0.7, "dmg": 14.0, "kb": 420.0, "stun": 0.7, "push": true},
		],
	},
	"szpak": {
		"name": "Szpak Wściekły", "ai": "ranged", "scale": 1.0, "tier": 4,
		"health": 110.0, "defense": 0.12, "speed": 100.0, "poise": 0.3, "xp": 70, "gold": 24,
		"pal": {"body": Color(0.16, 0.16, 0.2), "shade": Color(0.08, 0.08, 0.11), "beak": Color(0.95, 0.85, 0.2), "eye": Color(1.0, 0.35, 0.2)},
		"aggro": 700.0, "attack_range": 380.0, "keep_distance": 300.0, "cooldown": [1.0, 1.7],
		"attacks": [
			{"name": "salwa", "range": 420.0, "windup": 0.5, "active": 0.2, "recover": 0.55, "dmg": 11.0, "kb": 140.0, "stun": 0.25, "projectile": "feather", "volley": 3},
			{"name": "pióro_ciąże", "range": 420.0, "windup": 0.7, "active": 0.12, "recover": 0.7, "dmg": 20.0, "kb": 320.0, "stun": 0.5, "projectile": "rock", "slow": true},
		],
	},
	"indyk_krolewski": {
		"name": "Indyk Królewski", "ai": "boss", "scale": 1.9, "tier": 5, "boss": true,
		"health": 900.0, "defense": 0.18, "speed": 92.0, "poise": 1.0, "xp": 400, "gold": 200,
		"pal": {"body": Color(0.7, 0.36, 0.2), "shade": Color(0.48, 0.22, 0.1), "comb": Color(0.9, 0.2, 0.22), "beak": Color(0.97, 0.76, 0.2), "eye": Color(1.0, 0.35, 0.15)},
		"aggro": 2000.0, "attack_range": 80.0, "cooldown": [0.7, 1.3],
		"attacks": [
			{"name": "deptanie", "w": 4.0, "range": 96.0, "windup": 0.5, "active": 0.2, "recover": 0.5, "dmg": 20.0, "kb": 220.0, "stun": 0.5, "shock": 90.0},
			{"name": "rozbiezka", "w": 3.0, "range": 520.0, "windup": 0.66, "active": 0.7, "recover": 0.8, "dmg": 24.0, "kb": 380.0, "stun": 0.6, "dash": true},
			{"name": "wichr", "w": 3.0, "range": 420.0, "windup": 0.62, "active": 0.3, "recover": 0.7, "dmg": 14.0, "kb": 200.0, "stun": 0.35, "projectile": "feather", "volley": 7},
			{"name": "kle_noto", "w": 3.0, "range": 130.0, "windup": 0.85, "active": 0.25, "recover": 1.0, "dmg": 30.0, "kb": 260.0, "stun": 1.0, "unblockable": true},
			{"name": "pijar", "w": 2.5, "range": 700.0, "windup": 1.1, "active": 0.4, "recover": 1.2, "dmg": 26.0, "kb": 340.0, "stun": 0.8, "shock": 130.0},
		],
	},
	"golab": {
		"name": "Gołąb Miejski", "ai": "ranged", "scale": 0.9, "tier": 2,
		"health": 44.0, "defense": 0.04, "speed": 122.0, "poise": 0.05, "xp": 20, "gold": 6,
		"pal": {"body": Color(0.62, 0.66, 0.72), "shade": Color(0.44, 0.48, 0.56), "beak": Color(0.95, 0.6, 0.35), "eye": Color(0.9, 0.85, 0.2)},
		"aggro": 560.0, "attack_range": 300.0, "keep_distance": 220.0, "cooldown": [1.1, 2.0],
		"attacks": [
			{"name": "gruchanie", "range": 360.0, "windup": 0.4, "active": 0.1, "recover": 0.45, "dmg": 9.0, "kb": 130.0, "stun": 0.25, "projectile": "feather"},
		],
	},
	"sokol": {
		"name": "Sokół Wędrowny", "ai": "dasher", "scale": 0.95, "tier": 3,
		"health": 58.0, "defense": 0.05, "speed": 190.0, "poise": 0.1, "xp": 28, "gold": 9,
		"pal": {"body": Color(0.55, 0.5, 0.46), "shade": Color(0.36, 0.32, 0.3), "beak": Color(0.9, 0.8, 0.3), "eye": Color(0.98, 0.75, 0.1)},
		"aggro": 720.0, "attack_range": 56.0, "cooldown": [0.7, 1.3],
		"attacks": [
			{"name": "pazur", "range": 58.0, "windup": 0.18, "active": 0.1, "recover": 0.26, "dmg": 12.0, "kb": 170.0, "stun": 0.3},
			{"name": "lot_swiszczacy", "range": 330.0, "windup": 0.44, "active": 0.4, "recover": 0.6, "dmg": 16.0, "kb": 280.0, "stun": 0.45, "dash": true},
		],
	},
	"czajka": {
		"name": "Czajka Krzykliwa", "ai": "sprinter", "scale": 0.85, "tier": 3,
		"health": 40.0, "defense": 0.02, "speed": 215.0, "poise": 0.0, "xp": 26, "gold": 8,
		"pal": {"body": Color(0.3, 0.34, 0.3), "shade": Color(0.18, 0.22, 0.18), "beak": Color(0.95, 0.85, 0.3), "eye": Color(1.0, 0.4, 0.2)},
		"aggro": 660.0, "attack_range": 44.0, "cooldown": [0.6, 1.1],
		"attacks": [
			{"name": "wrzask", "range": 48.0, "windup": 0.16, "active": 0.1, "recover": 0.24, "dmg": 10.0, "kb": 150.0, "stun": 0.3},
		],
	},
	"puchacz": {
		"name": "Puchacz", "ai": "grappler", "scale": 1.22, "tier": 4,
		"health": 135.0, "defense": 0.14, "speed": 86.0, "poise": 0.45, "xp": 54, "gold": 17,
		"pal": {"body": Color(0.42, 0.34, 0.26), "shade": Color(0.26, 0.2, 0.15), "beak": Color(0.2, 0.18, 0.16), "eye": Color(1.0, 0.6, 0.15)},
		"aggro": 640.0, "attack_range": 66.0, "cooldown": [1.1, 1.9],
		"attacks": [
			{"name": "chwyt_szpon", "range": 70.0, "windup": 0.44, "active": 0.18, "recover": 0.6, "dmg": 19.0, "kb": 95.0, "stun": 0.9, "grab": true},
			{"name": "cios_skrzydlem", "range": 80.0, "windup": 0.36, "active": 0.14, "recover": 0.5, "dmg": 14.0, "kb": 270.0, "stun": 0.45},
		],
	},
	"krol_krukow": {
		"name": "Król Kruków", "ai": "boss", "scale": 2.0, "tier": 6, "boss": true,
		"health": 1050.0, "defense": 0.2, "speed": 96.0, "poise": 1.0, "xp": 520, "gold": 280,
		"pal": {"body": Color(0.11, 0.11, 0.15), "shade": Color(0.05, 0.05, 0.08), "comb": Color(0.6, 0.1, 0.12), "beak": Color(0.7, 0.7, 0.75), "eye": Color(1.0, 0.35, 0.1)},
		"aggro": 2200.0, "attack_range": 84.0, "cooldown": [0.7, 1.2],
		"attacks": [
			{"name": "deptanie", "w": 4.0, "range": 100.0, "windup": 0.5, "active": 0.2, "recover": 0.5, "dmg": 22.0, "kb": 230.0, "stun": 0.5, "shock": 95.0},
			{"name": "rozbiezka", "w": 3.0, "range": 540.0, "windup": 0.62, "active": 0.7, "recover": 0.8, "dmg": 26.0, "kb": 400.0, "stun": 0.6, "dash": true},
			{"name": "wichr", "w": 3.5, "range": 440.0, "windup": 0.6, "active": 0.3, "recover": 0.7, "dmg": 15.0, "kb": 210.0, "stun": 0.35, "projectile": "feather", "volley": 9},
			{"name": "kle_noto", "w": 3.0, "range": 140.0, "windup": 0.85, "active": 0.25, "recover": 1.0, "dmg": 32.0, "kb": 270.0, "stun": 1.0, "unblockable": true},
			{"name": "pijar", "w": 2.5, "range": 720.0, "windup": 1.05, "active": 0.4, "recover": 1.2, "dmg": 28.0, "kb": 350.0, "stun": 0.8, "shock": 140.0},
		],
	},
}

static func get_data(id: String) -> Dictionary:
	return LIST.get(id, LIST["wrzos"])

static func ids_of_tier(t: int) -> Array:
	var out := []
	for id in LIST:
		if int(LIST[id]["tier"]) == t:
			out.append(id)
	return out
