class_name EnemySkins
extends RefCounted
## Przebrania wrogów dopasowane do nazwy fali: „czytelnicy z mieczami” naprawdę niosą księgi i miecze,
## kelnerzy tacę, konserwatorzy pędzel i beret, rycerze noszą pełną zbroję. Pole "prop" rysuje
## CreatureVisual (_draw_prop).

const STEEL := Color(0.78, 0.8, 0.86)

const SKINS := {
	"straz": {"weapon": {"col": STEEL, "style": "sword", "len": 22.0}, "armor": {"col": Color(0.3, 0.38, 0.7), "trim": Color(0.9, 0.9, 1.0)}, "helmet": {"col": Color(0.65, 0.68, 0.75)}},
	"lokaj": {"weapon": {"col": STEEL, "style": "sword", "len": 20.0}, "armor": {"col": Color(0.12, 0.12, 0.16), "trim": Color(0.95, 0.9, 0.7)}},
	"czytelnik": {"weapon": {"col": STEEL, "style": "sword", "len": 22.0}, "armor": {"col": Color(0.5, 0.36, 0.22), "trim": Color(0.9, 0.8, 0.5)}, "prop": "book"},
	"bibliotekarz": {"armor": {"col": Color(0.2, 0.38, 0.28), "trim": Color(0.85, 0.8, 0.5)}, "prop": "tome"},
	"straznik_ksiag": {"weapon": {"col": STEEL, "style": "sword", "len": 26.0}, "armor": {"col": Color(0.25, 0.28, 0.45), "trim": Color(0.9, 0.8, 0.4)}, "helmet": {"col": Color(0.6, 0.62, 0.7)}},
	"kelner": {"weapon": {"col": STEEL, "style": "sword", "len": 14.0}, "armor": {"col": Color(0.95, 0.95, 0.97), "trim": Color(0.2, 0.2, 0.25)}, "prop": "tray"},
	"gosc": {"weapon": {"col": STEEL, "style": "sword", "len": 14.0}, "armor": {"col": Color(0.5, 0.2, 0.55), "trim": Color(0.95, 0.8, 0.3)}, "helmet": {"col": Color(0.2, 0.15, 0.25)}},
	"ochrona": {"weapon": {"col": STEEL, "style": "sword", "len": 24.0}, "armor": {"col": Color(0.65, 0.15, 0.2), "trim": Color(0.95, 0.85, 0.4)}, "helmet": {"col": Color(0.7, 0.72, 0.78)}},
	"ramiarz": {"armor": {"col": Color(0.5, 0.4, 0.2), "trim": Color(0.95, 0.8, 0.3)}, "helmet": {"col": Color(0.9, 0.75, 0.3)}, "prop": "frame"},
	"cien": {"weapon": {"col": Color(0.6, 0.5, 0.9), "style": "sword", "len": 22.0, "glow": true}, "modulate": Color(0.55, 0.45, 0.8, 0.7)},
	"konserwator": {"armor": {"col": Color(0.85, 0.8, 0.65), "trim": Color(0.6, 0.3, 0.2)}, "helmet": {"col": Color(0.75, 0.2, 0.25)}, "prop": "brush"},
	"chorzysta": {"weapon": {"col": STEEL, "style": "sword", "len": 22.0}, "armor": {"col": Color(0.93, 0.93, 0.97), "trim": Color(0.95, 0.8, 0.3)}},
	"rycerz": {"weapon": {"col": STEEL, "style": "sword", "len": 28.0}, "armor": {"col": Color(0.62, 0.65, 0.74), "trim": Color(0.95, 0.85, 0.4)}, "helmet": {"col": Color(0.7, 0.72, 0.8)}},
	"lekki": {"weapon": {"col": Color(0.7, 0.72, 0.78), "style": "sword", "len": 16.0}, "armor": {"col": Color(0.5, 0.36, 0.22), "trim": Color(0.8, 0.7, 0.45)}},
	"luk": {"weapon": {"col": Color(0.6, 0.42, 0.22), "style": "bow", "len": 22.0}, "armor": {"col": Color(0.25, 0.4, 0.28), "trim": Color(0.8, 0.8, 0.5)}, "helmet": {"col": Color(0.3, 0.45, 0.3)}},
	"wlocznik": {"weapon": {"col": Color(0.8, 0.82, 0.88), "style": "spear", "len": 34.0}, "armor": {"col": Color(0.4, 0.4, 0.55), "trim": Color(0.9, 0.85, 0.5)}, "helmet": {"col": Color(0.65, 0.67, 0.74)}},
	"ciezki": {"weapon": {"col": Color(0.6, 0.62, 0.7), "style": "club", "len": 28.0}, "armor": {"col": Color(0.5, 0.52, 0.6), "trim": Color(0.8, 0.8, 0.9)}, "helmet": {"col": Color(0.55, 0.57, 0.65)}},
	"mag_ptak": {"weapon": {"col": Color(0.7, 0.5, 0.95), "style": "staff", "len": 30.0, "glow": true}, "armor": {"col": Color(0.4, 0.2, 0.55), "trim": Color(0.9, 0.7, 1.0)}, "helmet": {"col": Color(0.35, 0.18, 0.5)}},
	"krolewski": {"weapon": {"col": Color(0.95, 0.85, 0.5), "style": "sword", "len": 32.0, "glow": true}, "armor": {"col": Color(0.2, 0.2, 0.28), "trim": Color(0.98, 0.82, 0.3)}, "helmet": {"col": Color(0.98, 0.82, 0.3)}},
	"general": {"weapon": {"col": Color(0.85, 0.85, 0.9), "style": "sword", "len": 30.0}, "armor": {"col": Color(0.2, 0.2, 0.26), "trim": Color(0.85, 0.25, 0.25)}, "helmet": {"col": Color(0.25, 0.25, 0.32)}},
	"rycerz_pojedynku": {"weapon": {"col": Color(0.88, 0.9, 0.95), "style": "sword", "len": 32.0}, "armor": {"col": Color(0.6, 0.63, 0.74), "trim": Color(0.95, 0.85, 0.4)}, "helmet": {"col": Color(0.72, 0.74, 0.82)}},
	"rycerz_legenda": {"weapon": {"col": Color(1.0, 0.8, 0.3), "style": "sword", "len": 34.0, "glow": true}, "armor": {"col": Color(0.95, 0.75, 0.25), "trim": Color(1.0, 0.95, 0.7)}, "helmet": {"col": Color(0.98, 0.82, 0.3)}},
	"rycerz_hiper": {"weapon": {"col": Color(0.85, 0.5, 1.0), "style": "sword", "len": 36.0, "glow": true}, "armor": {"col": Color(0.55, 0.2, 0.75), "trim": Color(1.0, 0.85, 1.0)}, "helmet": {"col": Color(0.65, 0.3, 0.85)}, "aura": "purple_flame"},
}

## Domyślne uzbrojenie wrogów-żołnierzy według gatunku (a gdy brak — według poziomu).
const DEFAULTS := {
	"wrzos": "lekki", "kawka": "lekki", "golab": "lekki", "wronszek": "lekki", "czajka": "lekki",
	"sroka": "luk", "szpak": "luk",
	"kruk": "straz", "jastrzab": "wlocznik", "sokol": "wlocznik", "orzel_szarak": "rycerz",
	"bocian_gruby": "ciezki", "puchacz": "mag_ptak", "sowa": "mag_ptak", "krol_krukow": "krolewski", "sep": "rycerz",
}

static func default_for(species: String, tier: int) -> String:
	if DEFAULTS.has(species):
		return String(DEFAULTS[species])
	if tier <= 2:
		return "lekki"
	if tier <= 4:
		return "straz"
	return "ciezki"

static func apply(visual: CreatureVisual, skin: String) -> void:
	var s: Dictionary = SKINS.get(skin, {})
	if s.is_empty():
		return
	var g := {}
	for k in ["weapon", "armor", "helmet"]:
		if s.has(k):
			g[k] = s[k]
	if s.has("prop"):
		g["prop"] = {"kind": s["prop"]}
	if s.has("aura"):
		g["aura"] = s["aura"]
	visual.set_gear(g)
	if s.has("modulate"):
		visual.modulate = s["modulate"]
