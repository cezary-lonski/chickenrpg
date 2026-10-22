# Chicken RPG (Chicken Brawl)

Kurczak kontra ptasia armia Czarniego Kruka. Gra akcyjna 2D w Godot 4.7 z trybem
**RPG top-down** (z góry) oraz klasycznym trybem platformowym (z boku).

## Tryby gry

- **Wybierz kurczaka** — klasyczna gra platformowa (etapy z boku).
- **Nowa gra RPG** — kampania fabularna w widoku z góry, 7 rozdziałów.
- **Gra LAN** — host tworzy pokój i dostaje **KOD**, drugi gracz wpisuje kod i wybiera klasę.

## Kampania RPG (7 rozdziałów)

| # | Rozdział | Strefa | Wróg |
|---|----------|--------|------|
| I | Nocny najazd | wioska | Hrabia Sroka |
| II | Trakt do stolicy | trakt | Herold Kruka |
| III | Płonąca stolica | miasto | Kapitan zdrajców |
| IV | Królowa w kajdanach | wieża | Dowódca straży |
| V | Trzy próby | las | Leśny Strażnik |
| VI | Czarny marsz | trakt | Kruk |
| VII | Serce kruka | forteca | Czarny Kruk |

Każdy rozdział: prolog → rozmowa z dawcą zadania → 3 fale wrogów (z przerywnikiem
z bossem) → rozmowa po bitwie → nagroda i przejście do kolejnego rozdziału.

## Sterowanie

- **A / D / W / S** — ruch (top-down: 8 kierunków)
- **Spacja / LPM** — atak
- **Shift** — unik
- **1–6** — umiejętności klasowe
- **E** — interakcja z NPC (top-down)
- **I** — ekwipunek, **Q** — dziennik zadań, **Esc** — pauza

## Klasy

Wojownik, Łucznik, Fechmistrz, Złodziej, Mag oraz Lady (tylko dla Lady).

## Ekwipunek

Broń / pancerz / akcesoria posiadane przez postać (kupione w sklepie lub wygrane).
W ekwipunku widoczne są **tylko przedmioty, które posiadasz**.

## Uruchomienie

Wymagany Godot 4.7+. W katalogu projektu:

```
godot --path .
```

## LAN

1. Host: `Gra LAN` → `Hostuj` → `Generuj` (kod) → `Start`. Podaj kod drugiej osobie.
2. Gość: `Gra LAN` → `Dołącz` → wpisz kod → wybierz klasę → `Start`.

Host rozgłasza kod w sieci lokalnej (UDP broadcast), więc gość nie wpisuje IP.

## Struktura

```
autoload/    GameState, Flow, Net, Audio, Fx, Art
actors/      player, enemy, pociski
scripts/     bazy danych (klasy, przedmioty, questy, strefy, NPC) + UI
scenes/      menu, etapy, wioska, gracze
docs/        rpg_design.md
```
