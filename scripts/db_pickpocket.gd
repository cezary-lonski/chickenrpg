class_name Pickpocket
extends RefCounted
## Kradzież kieszonkowa (umiejętność „Kradzież”): okno łupu z ekwipunkiem ofiary — potwora, NPC albo gracza.
## Zabierasz, co chcesz, ale każda rzecz to ryzyko: ofiara może zauważyć (NPC się obraża i nie chce rozmawiać,
## potwór rzuca się do walki, gracz dostaje wiadomość, kim jesteś).

const NPC_POOL := ["mikstura_miodu", "g_cebula_bojowa", "wytrych_zardzewialy", "g_eliksir_maly", "g_mikstura_mala", "wytrych",
	"g_jajko_zgnile", "g_pierscien_kuchenny", "g_wstazka_targowa", "luk_mysliwski", "g_amulet_zielarki", "g_czapka_slomiana"]
const ENEMY_POOL := ["mikstura_miodu", "g_cebula_bojowa", "g_jajko_zgnile", "wytrych_zardzewialy", "g_eliksir_maly"]
## NPC z tych ról nie da się okraść (zleceniodawca fabuły, handlarze, kowal) — żeby nie zablokować gry.
const SAFE_ROLES := ["shop", "smith", "giver"]

## Zawartość kieszeni NPC (zawsze ta sama dla danego NPC): {"gold": int, "items": [{id, n}]}.
static func npc_box(npc_id: String) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("pp:" + npc_id)
	var items: Array = []
	var pool: Array = NPC_POOL.duplicate()
	for k in rng.randi_range(1, 3):
		var id: String = pool.pop_at(rng.randi_range(0, pool.size() - 1))
		if ItemDB.has(id):
			items.append({"id": id, "n": 1 if ItemDB.stack_of(id) <= 1 else rng.randi_range(1, 2)})
	return {"gold": rng.randi_range(25, 110), "items": items}

## Kieszenie potwora: jego złoto i szansa na drobiazg.
static func enemy_box(gold_value: int) -> Dictionary:
	var items: Array = []
	if randf() < 0.45:
		var id: String = ENEMY_POOL[randi() % ENEMY_POOL.size()]
		if ItemDB.has(id):
			items.append({"id": id, "n": 1})
	return {"gold": maxi(1, gold_value), "items": items}

## Szansa zauważenia: rośnie z każdą zabraną rzeczą, malejąca ze zręcznością złodzieja (modyfikator z EncounterDB).
static func notice_chance(taken: int, gold: bool, mod: int) -> float:
	return clampf(0.12 + 0.12 * float(taken) + (0.08 if gold else 0.0) - 0.02 * float(mod), 0.05, 0.85)

static func make_box(title: String, mode: String, gold: int, items: Array, sub: String = "") -> Dictionary:
	var b := {"title": title, "mode": mode, "gold": gold, "items": items}
	if sub != "":
		b["sub"] = sub
	return b
