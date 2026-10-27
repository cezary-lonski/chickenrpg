class_name DecisionDB
extends RefCounted
## Konsekwencje wyborów w dialogach: każda decyzja zostawia stały ślad w statystykach bohatera
## (bonus i często koszt). Działają tak samo w grze jednoosobowej, LAN i na serwerze MMO — liczy je
## compute_stats z flag fabuły. Opis efektu dopisuje się do tekstu opcji, więc gracz wie, co wybiera.

const NAMES := {
	"strength": "obrażenia", "defense": "obrona", "speed": "szybkość", "crit": "szansa na krytyk",
	"max_health": "życie", "max_energy": "energia", "luck": "szczęście", "xp_mult": "XP", "gold_mult": "złoto",
	"dmg_reduction": "redukcja obrażeń", "regen": "regeneracja", "lifesteal": "wampiryzm",
}
## Klucze mierzone w ułamkach (pokazywane jako procenty); reszta to wartości bezwzględne.
const PERCENT := ["strength", "defense", "speed", "crit", "luck", "xp_mult", "gold_mult", "dmg_reduction", "lifesteal"]

const EFFECTS := {
	"hela_pomoc": {"max_health": 12.0},
	"hela_odmowa": {"speed": 0.04},
	"bronek_mapa": {"gold_mult": 0.10},
	"bronek_bez": {"crit": 0.03},
	"zosia_miod": {"xp_mult": 0.08},
	"zosia_odmowa": {"max_energy": 12.0},
	"lila_zostaje": {"defense": 0.06},
	"lila_idzie": {"speed": 0.03, "luck": 0.05},
	"druid_blogoslawienstwo": {"max_health": 20.0, "strength": -0.04},
	"druid_bez": {"strength": 0.06, "max_health": -10.0},
	"marsz_front": {"strength": 0.08, "defense": -0.04},
	"marsz_obejscie": {"defense": 0.06, "speed": -0.02},
	"pierzak_wolny": {"luck": 0.08},
	"pierzak_wydany": {"gold_mult": 0.12},
	"popielnik_dar": {"luck": 0.05},
	"popielnik_brak": {"crit": 0.02},
	"fryderyk_przekupstwo": {"speed": 0.03, "defense": -0.03},
	"fryderyk_uczciwie": {"defense": 0.05, "speed": -0.01},
	"wedrowiec_woda": {"max_energy": 15.0},
	"wedrowiec_nic": {"strength": 0.04},
	"wichura_rytual": {"dmg_reduction": 0.04},
	"wichura_bez": {"crit": 0.04},
	"swit_wioska": {"max_health": 25.0, "luck": 0.05},
	"swit_korona": {"strength": 0.10},
	"bard_kogut": {"xp_mult": 0.05},
	"bard_ty": {"crit": 0.03, "luck": 0.03},
	"mlynarz_zaliczka": {"gold_mult": 0.06},
	"mlynarz_bez": {"luck": 0.05, "max_health": 8.0},
	"babcia_kosz": {"max_health": 10.0, "speed": -0.01},
	"babcia_dla_wnuczki": {"defense": 0.04},
	"hasan_amulet": {"dmg_reduction": 0.03},
	"hasan_dla_leili": {"max_energy": 10.0, "luck": 0.03},
	"burzan_okulary": {"crit": 0.04, "defense": -0.02},
	"burzan_zostaw": {"xp_mult": 0.05},
}

## Dodaje do słownika statystyk efekty wszystkich podjętych decyzji. `flags` — flagi fabuły gracza.
static func apply(stats: Dictionary, flags: Dictionary) -> void:
	for f in EFFECTS:
		if not bool(flags.get(f, false)):
			continue
		var fx: Dictionary = EFFECTS[f]
		for k in fx:
			stats[k] = float(stats.get(k, 0.0)) + float(fx[k])

## „+12 życie, −4% obrażenia” — opis efektu jednej decyzji.
static func describe(flag: String) -> String:
	var fx: Dictionary = EFFECTS.get(flag, {})
	var parts: Array = []
	for k in fx:
		var v := float(fx[k])
		var txt := ("%+d%%" % int(round(v * 100.0))) if k in PERCENT else ("%+d" % int(round(v)))
		parts.append("%s %s" % [txt.replace("-", "−"), String(NAMES.get(k, k))])
	return ", ".join(parts)

## Dopisuje opis skutków do tekstów opcji wyborów (tylko dla decyzji z tabeli).
static func annotate(extras: Dictionary) -> Dictionary:
	for zid in extras:
		var dialogs: Dictionary = (extras[zid] as Dictionary).get("dialogs", {})
		for npc in dialogs:
			var ch: Dictionary = (dialogs[npc] as Dictionary).get("choice", {})
			for opt in ch.get("options", []):
				var d := describe(String(opt.get("flag", "")))
				if d != "" and not String(opt["text"]).ends_with("]"):
					opt["text"] = "%s  [%s]" % [String(opt["text"]), d]
	return extras
