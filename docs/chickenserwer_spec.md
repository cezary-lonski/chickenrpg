# ChickenSerwer — serwer dedykowany (spec v1)

Cel: aplikacja serwera (okno + tryb `--headless`), na której gracze z internetu dołączają zwykłym ChickenRPG
przez IP:port, wybierają postać i grają we wspólnym świecie. Postacie żyją na serwerze.

## Uruchamianie
- `ChickenSerwer.bat` (okno) / `ChickenSerwer-headless.bat` (bez okna) = Godot z flagą `--server`.
- `ServerMode.is_active()` (flaga `--server` lub cecha eksportu `chickenserwer`) przełącza `Flow` na ekran `server`
  i blokuje zapis profilu gry (`GameState.save_game`).
- Dane serwera: `user://chickenserwer/` (`config.json`, `characters.json`).

## Sieć (autoload `Mmo`, wspólny dla klienta i serwera)
ENet, port domyślny 7777 (UDP), max 32 graczy, UPnP próbuje otworzyć port. RPC (wszystkie na `/root/Mmo`):
- klient→serwer: `_rpc_login(proto, name, password, pack)`, `_rpc_input(move, held, actions)` (unreliable),
  `_rpc_chat(text)` (czat i komendy `/…`), `_rpc_inv(op, a, b)` (equip/unequip/use/skill/give).
- serwer→klient: `_rpc_login_result`, `_rpc_snapshot*` (gracze+moby, ZSTD), `_rpc_roster` (wygląd graczy),
  `_rpc_me` (karta własnej postaci), `_rpc_chat_msg`.
Serwer jest jedynym autorytetem; klient wysyła tylko wejście. Wszystkie dane od klienta są walidowane/przycinane.

## Postacie
`pack` (przy pierwszym wejściu) = postać z lokalnego zapisu: char, klasa, poziom, xp, złoto, ekwipunek, plecak,
sloty umiejętności, atrybuty, wygląd (walidowane przez ItemDB/SkillDB/CharacterDB, przycięte zakresy).
Serwer zapisuje własną kopię pod nazwą + hasło (sha256+sól). Kolejne wejścia: nazwa+hasło, `pack` ignorowany.
Statystyki liczy serwer (`ServerChars.compute_stats`) z bazy postaci, poziomu, ekwipunku i atrybutów.

## Świat
Jedna mapa 3000×2000, spawn w środku (strefa bezpieczna). `Player` (tryb `net_controlled`) per gracz, `Enemy` w
trybie `server_mode` (bez lokalnych nagród). Spawner utrzymuje liczbę mobów zależną od liczby graczy i ich poziomu
(tier wg średniego poziomu). Kill → XP/złoto/drop na postać serwerową (killer pełne, pobliscy pół). Śmierć → respawn 4 s.
Poza v1: fabuła, questy, sklepy, NPC, bossowie (poza `/spawn` zwykłych).

## Czat i komendy
Klawisz **T** otwiera czat (Enter wysyła, Esc zamyka). `/` = komenda. Gracz: `/help /list /w /me /pos /stats /skills
/skill /attr`. Admin: `/tp /tphere /give /heal /god /kill /kick /ban /unban /spawn /killall /xp /setlevel /gold /say
/op /deop /class /items /stop`. Konsola serwera wykonuje te same komendy z prawami admina.

## Klasa admin
`ClassDatabase` ma klasę `admin` (tymczasowa; wyłączana w config `allow_admin_class`). Admin: ogromne staty,
wszystkie umiejętności, panel Creative (**I** → zakładka Creative: wszystkie przedmioty z `ItemDB`), wszystkie komendy.
Uprawnienia sprawdza serwer (klasa admin + `allow_admin_class`, albo nazwa na liście `admins` w config).

## Klient
Menu → „Serwer online” (IP, port) → wybór slotu/postaci (+klasa, nick, hasło) → świat `MmoWorld`
(duchy `Player`/`Enemy` z snapshotów, kamera, HUD, czat T, ekwipunek I).
