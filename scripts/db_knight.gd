class_name KnightDB
extends RefCounted
## Rycerz w zbroi: wyzywa na pojedynek. Doskonale paruje (patrz Enemy._try_parry), a odsłania się
## tylko podczas własnego ataku i tuż po nim. Trzy stopnie: zwykła zbroja, legendarna i hiperlegendarna.

const PAL := {"body": Color(0.8, 0.78, 0.74), "shade": Color(0.55, 0.53, 0.52), "comb": Color(0.85, 0.2, 0.25), "beak": Color(0.95, 0.75, 0.25), "eye": Color(0.1, 0.1, 0.12), "leg": Color(0.9, 0.7, 0.2)}

const LIST := {
	"rycerz_pojedynku": {
		"name": "Rycerz w zbroi", "ai": "charger", "scale": 1.45, "tier": 5, "duelist": true, "skin": "rycerz_pojedynku", "knight_tier": 0,
		"health": 320.0, "defense": 0.2, "speed": 118.0, "poise": 1.0, "xp": 220, "gold": 90, "pal": PAL,
		"aggro": 900.0, "attack_range": 80.0, "cooldown": [0.9, 1.5],
		"attacks": [
			{"name": "cięcie", "range": 82.0, "windup": 0.32, "active": 0.14, "recover": 0.55, "dmg": 18.0, "kb": 260.0, "stun": 0.4},
			{"name": "pchnięcie", "range": 110.0, "windup": 0.5, "active": 0.14, "recover": 0.7, "dmg": 26.0, "kb": 340.0, "stun": 0.5, "lunge": 180.0},
		],
	},
	"rycerz_legenda": {
		"name": "Rycerz w legendarnej zbroi", "ai": "charger", "scale": 1.5, "tier": 6, "duelist": true, "skin": "rycerz_legenda", "knight_tier": 1,
		"health": 520.0, "defense": 0.3, "speed": 128.0, "poise": 1.0, "xp": 380, "gold": 160, "pal": PAL,
		"aggro": 900.0, "attack_range": 84.0, "cooldown": [0.7, 1.2],
		"attacks": [
			{"name": "cięcie", "range": 86.0, "windup": 0.28, "active": 0.14, "recover": 0.5, "dmg": 24.0, "kb": 280.0, "stun": 0.4},
			{"name": "pchnięcie", "range": 120.0, "windup": 0.45, "active": 0.14, "recover": 0.65, "dmg": 32.0, "kb": 360.0, "stun": 0.5, "lunge": 200.0},
			{"name": "zamach znad głowy", "range": 96.0, "windup": 0.6, "active": 0.18, "recover": 0.8, "dmg": 40.0, "kb": 420.0, "stun": 0.7},
		],
	},
	"rycerz_hiper": {
		"name": "Rycerz w hiperlegendarnej zbroi", "ai": "charger", "scale": 1.6, "tier": 7, "duelist": true, "skin": "rycerz_hiper", "knight_tier": 2,
		"health": 800.0, "defense": 0.4, "speed": 140.0, "poise": 1.0, "xp": 640, "gold": 280, "pal": PAL,
		"aggro": 900.0, "attack_range": 90.0, "cooldown": [0.55, 1.0],
		"attacks": [
			{"name": "cięcie", "range": 90.0, "windup": 0.24, "active": 0.14, "recover": 0.45, "dmg": 30.0, "kb": 300.0, "stun": 0.4},
			{"name": "pchnięcie", "range": 130.0, "windup": 0.4, "active": 0.14, "recover": 0.6, "dmg": 40.0, "kb": 380.0, "stun": 0.5, "lunge": 220.0},
			{"name": "zamach znad głowy", "range": 104.0, "windup": 0.55, "active": 0.18, "recover": 0.75, "dmg": 52.0, "kb": 460.0, "stun": 0.8},
		],
	},
}

## Losuje rycerza stosownie do postępu (rzadziej wyższe zbroje).
static func roll() -> String:
	var r := randf()
	var prog := GameState.progress_index()
	if prog >= 8 and r < 0.18:
		return "rycerz_hiper"
	if prog >= 4 and r < 0.5:
		return "rycerz_legenda"
	return "rycerz_pojedynku"
