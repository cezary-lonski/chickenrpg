# Chicken Brawl → Top-Down RPG

Dokument projektowy: konwersja z side-view brawlera falowego na top-down 2D RPG.
Wersja: 0.1 · Silnik: Godot 4.7 (GL Compatibility)

---

## 1. Przegląd

Chicken Brawl to dziś brawler boczny: gracz idzie w prawo, kamera nie cofa się,
a `Stage` (`scripts/stage.gd`) wypuszcza kolejne fale wrogów (`StageDB.LIST`).
Cel: przebudować to w **top-down 2D RPG** z otwartym terenem (overworld), strefami
zadań, NPC, questami i fabułą o najeździe na królestwo kur.

Gracz wciela się w **Lorda albo Lady** (wybór na starcie), przechodzi kampanię
fabularną, rozwija postać (poziomy, ekwipunek, skille) i może grać **solo lub
przez LAN we dwójkę**.

Fundament techniczny zostaje: autoloady `GameState`, `Flow`, `Art`, `Audio`, `Fx`,
bazy danych `CharacterDB`, `ItemDB`, `SkillDB`, `EnemyDB`. Wymieniany jest głównie:
ruch gracza, camera, struktura sceny świata i reżyseria (fale → strefy/questy).

---

## 2. Cele

- Przenieść walkę i rozwój postaci bez utraty „feelingu" obecnego brawlera.
- Ruch top-down (8 kierunków), kamera śledząca, brak grawitacji.
- Świat złożony z **overworldu + osobnych stref** (dungeony/miasta/fortece).
- Kampania liniowo-otwarta: wioska → stolica → forteca.
- Wybór bohatera Lord/Lady (kosmetyka + drobne różnice statystyk/skilli).
- Kooperacja LAN/solo (2 graczy) jako opcja, nie przymus.
- Zachować obecny ekwipunek/plecak/sklep/poziomy (minimalizacja przepisywania).

---

## 3. Zakres

**W zakresie (v1):**
- Ruch top-down dla Lorda/Lady (reuse stanów z `actors/player/player.gd`).
- Overworld + 6–8 stref zamiast 6 etapów liniowych.
- NPC z dialogami, sklep, questy główne i poboczne.
- Walka 360° (obrót/virtualny „facing" 8-kierunkowy) z zachowaniem broni,
  skilli i furii.
- HUD top-down (paski HP/energia/furia, minimapa, wskaźnik questa).
- Menu: wybór Lord/Lady + tryb Solo/LAN.
- Zapis stanu świata i questów w `profile` (`GameState`).

**Poza zakresem (v1):**
- Pełny multiplayer online (>2 graczy, matchmaking).
- Drop-in/drop-out w trakcie walki z bossem.
- Edytor map w grze, modding, pełne głosowanie dialogów.
- Nowy silnik/rendering, zmiana rozdzielczości bazowej (1280×720 zostaje).

---

## 4. Postacie

Dwie grywalne role, wybór na jednym ekranie (reuse `UiSelect`):

| Rola  | Profil | Przewaga | Uwagi |
|-------|--------|----------|-------|
| Lord  | siła/obrona | więcej HP, mocniejsze ciosy ciężkie, pancerz | domyślny |
| Lady  | szybkość/kryt | szybszy ruch, częstsze krytyki, uniki | alternatywa |

- Realizacja: dwa wpisy w `CharacterDB.LIST` (`lord`, `lady`) z własnymi `pal`,
  `base`/`gains` i `special`. Istniejące kurczaki (`kurczak`, `kogut`, `kwoka`…)
  zostają jako **alternatywne skiny/najemni NPC**, nie jako bohaterowie fabuły.
- **LAN co-op / solo** wybierane przy starcie:
  - Solo — jedna kamera, jeden bohater.
  - LAN — host + klient, autorytet hosta, drugi gracz = partner (drugi Lord/Lady
    albo NPC-towarzysz, jeśli solo). Kamera obejmuje obu graczy.

---

## 5. Fabuła (zarys)

1. **Atak na wioskę** — prolog. Rodzinna wioska kur płonie; gracz uczy się ruchu
   i walki, ratuje kilku mieszkańców.
2. **Straż + potwory** — droga do stolicy. Trzeba przedrzeć się przez punkty
   kontrolne straży (część przekupna, część wroga) oraz dzikie ptactwo-potwory.
3. **Atak na stolicę** — stolica pogrążona w chaosie; wróg uderzył równolegle.
4. **Uwolnić królową** — misja ratunkowa: uwolnić Królową z rąk najeźdźców.
5. **Zdobyć sprzęt** — quest ekwipunkowy: broń/pancerz/akcesorium z 3 mini-dungeonów.
6. **Marsz na fortecę** — przygotowanie i podejście pod twierdzę wroga.
7. **Poszukiwanie króla** — finał w fortecy: odnaleźć (lub pomścić) zaginionego Króla,
   rozprawa z bossem.

Wątek łączy istniejących bossów (`indyk_krolewski`, `krol_krukow`) jako
poruczników/bossów stref.

---

## 6. Systemy rdzeniowe

### 6.1 Ruch top-down
- Bazować na `player.gd`, ale usunąć grawitację i `is_on_floor()`.
- Wejście z `_input_x()/_input_y()` → wektor 2D znormalizowany.
- Zamiast `facing: float` (±1) wprowadzić `aim_dir: Vector2` (8 kierunków,
  ustawiany przez wejście mysłki/pada lub kierunek ciosu).
- Stany zmienić: `IDLE, MOVE, ATTACK, DASH, BLOCK, HURT, THROW, SPECIAL, DEAD`.
  Usuwamy `JUMP/FALL/AIR_ATTACK` (lub zostaje „hop" do omijania przeszkód — opcja).
- `move_and_slide()` zostaje; kolizje z przeszkodami terenu.

### 6.2 Kamera
- `Camera2D` z `position_smoothing_enabled`.
- Solo: śledzi bohatera, clamping do granic bieżącej strefy.
- Co-op: śledzi środek między graczami, dynamiczny zoom/korekta, clamp strefy.
- W strefach-arenach (boss) kamera blokowana do ramki areny.

### 6.3 Overworld + strefy
- **Overworld**: mapa świata z punktami wejścia do stref, szybsza podróż,
  przypadkowe spotkania (opcjonalne).
- **Strefy**: osobne sceny (`Zone.tscn`) — miasto, wioska, dungeon, forteca.
  Każda ma własną geometrię, NPC, spawn wrogów i questy.
- `StageDB` ewoluuje w `WorldDB`/`ZoneDB` (nowa baza), `Stage` → `Zone`
  (reżyseria: fale zastąpione spawnerami/triggerami zamiast „idź w prawo").
- Przejścia: `Area2D` trigger → `Flow.goto("zone", {"id": ...})`.

### 6.4 Walka — podejście: **zaadaptować, nie wyrzucać**
- **Broń** (`ItemDB.atk`, `weapon_attacks`) — bez zmian danych; tylko kierunek ciosu
  liczony z `aim_dir` (hitbox obracany wokół gracza zamiast `move_offset(facing*...)`).
- **Skille** (`SkillDB`) — zostają 1:1. `dash_strike`/`projectile` używają `aim_dir`.
- **Furia** (`add_fury`, `_start_special`) — zostaje; efekty AoE już są radialne,
  więc działają naturalnie w top-downie.
- **Blok/parry** — zostaje; `_facing_attacker` liczone po kącie między wektorami.
- **Wrogowie** (`EnemyDB`, `enemy.gd`) — zmiana z osiowej na 2D (patrol/aggro jako
  odległość, `leap/dash` w kierunku gracza zamiast w poziomie).
- **Optymalizacja hitboxów**: zamiast prostokąta 32×50 — `CircleShape2D`/łuk sektora.

### 6.5 Rozwój i ekonomia
- Poziomy/XP (`CharacterDB.xp_for_level`, `GameState.add_xp`) bez zmian.
- Złoto/piora (`gold`, `cod`), sklep (`ui_shop.gd`), loadout (`ui_loadout.gd`) —
  reuse.
- Nowe: drzewko umiejętności fabularnych (np. „Otwieranie zamków", „Perswazja").

---

## 7. UI — przepływ

```
Menu główne
 └─ Nowa gra
     ├─ Wybór postaci: Lord / Lady        (reuse UiSelect)
     └─ Tryb: Solo | LAN                   (nowy ekran)
         ├─ Solo → start kampanii
         └─ LAN  → Host / Dołącz (IP) → start kampanii (2 graczy)
 └─ Kontynuuj (z zapisu)
 └─ Ustawienia / Wyjście
```

- Ekran wyboru: rozszerzyć `ui_select.gd` o 2 role fabularne.
- Nowy `UiNetMode` (Solo/LAN) → konfiguracja hostowania/łączenia.
- HUD (`ui_hud.gd`): paski, minimapa, wskaźnik questa, znaczniki sojusznika w LAN.
- Pauza/loadout/sklep/results — zostają przez `Flow` (overlay).

---

## 8. Dane

- **Mapy**: `WorldDB` (overworld) + `ZoneDB` (strefy). Format jak `StageDB`:
  słowniki z geometrią, tłem, spawnerami i wejściami. Serializacja do `res`/JSON.
- **NPC**: nowa `NpcDB` — `{id, name, pal, dialog[], quest, shop[], tag}`.
  Renderowanie jak `CreatureVisual`.
- **Questy**: nowa `QuestDB` — `{id, title, steps[], rewards, next[]}`.
  Postęp trzymany w `GameState.profile["quests"]`.
- **Przedmioty**: `ItemDB` w większości bez zmian; dodać `"quest_item": true`
  i przedmioty fabularne (klucz fortecy, pieczęć królowej).
- **Zapis**: rozszerzyć `_blank_profile()` w `game_state.gd` o
  `"quests"`, `"world_flags"`, `"zone_pos"`, `"coop"`.

---

## 9. Minimalny pierwszy krok (MVP)

**Cel MVP:** udowodnić, że top-down „działa" na istniejącym kodzie.

1. Duplikat `player.gd` → `player_topdown.gd`: usunąć grawitację, ruch 2D,
   `aim_dir` z wejścia, obrót wizualny.
2. Prosta płaska `Zone` (jeden prostokąt terenu + kilka przeszkód) zamiast `Stage`.
3. Kamera śledząca + clamp do granic strefy.
4. 3–4 wrogów z `EnemyDB` z ruchem 2D i atakiem na odległość.
5. Atak: obrót hitboxa wg `aim_dir`, furia i jeden skill dla testu.
6. Wejście do strefy z „overworldu" placeholder (dwa `Area2D` przejścia).

Sukces MVP = da się swobodnie chodzić, walczyć i przejść między dwiema strefami.

---

## 10. Ryzyka

| Ryzyko | Wpływ | Mitygacja |
|--------|-------|-----------|
| Przepisanie `player.gd` psuje walkę (feeling) | wysoki | osobny plik top-down, testy A/B, reuse timingów |
| AI wrogów (osiowe `facing`, `leap/dash`) | średni | stopniowa migracja, wersja 2D obok 1D |
| Kamera co-op gubi graczy | średni | clamp + dynamiczny zoom + „tether" limitu dystansu |
| LAN: synchronizacja stanu walki | wysoki | autorytet hosta, tylko pozycje/HP/eventy po sieci |
| Overworld scope creep | wysoki | trzymać MVP: overworld jako lista punktów, nie otwarty świat |
| Rozjazd zapisu (nowe pola w `profile`) | średni | `_merge_defaults` już obsługuje brakujące klucze |
| Wydajność GL Compatibility przy wielu NPC | niski | pool obiektów, LOD AI, culling poza kamerą |

---

## Powiązania w kodzie

- `autoload/game_state.gd` — profil, run, questy, zapis
- `actors/player/player.gd` — do adaptacji na top-down
- `scripts/stage.gd` — do przekształcenia w `Zone`
- `scripts/db_stages.gd` — do zastąpienia przez `ZoneDB`
- `scripts/db_items.gd`, `db_skills.gd`, `db_enemies.gd` — reuse
- `autoload/flow.gd`, `scripts/ui/*` — przepływ ekranów i HUD
