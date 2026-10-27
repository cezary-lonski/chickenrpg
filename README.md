# Chicken RPG (Chicken Brawl)

## 👉 Pobierz — beta 0.2.1

| | Windows | Linux | Android (telefon) |
|---|---|---|---|
| **Gra** | [ChickenRPG (.zip)](https://github.com/cezary-lonski/chickenrpg/releases/download/v0.2.1-beta/ChickenRPG-0.2.1-beta.zip) | [ChickenRPG (.tar.gz)](https://github.com/cezary-lonski/chickenrpg/releases/download/v0.2.1-beta/ChickenRPG-0.2.1-beta-linux.tar.gz) | [ChickenRPG.apk](https://github.com/cezary-lonski/chickenrpg/releases/download/v0.2.1-beta/ChickenRPG-0.2.1-beta-android.apk) |
| **Serwer (ChickenSerwer)** | w tym samym zipie (`ChickenSerwer.exe`) | w tej samej paczce (`start-server.sh`) | [ChickenSerwer.apk](https://github.com/cezary-lonski/chickenrpg/releases/download/v0.2.1-beta/ChickenSerwer-0.2.1-beta-android.apk) |

**Windows:** rozpakuj zip i uruchom `ChickenRPG.exe` (bez instalacji).
**Linux:** `tar xzf ChickenRPG-0.2.1-beta-linux.tar.gz`, potem `./start-game.sh` lub `./start-server.sh`.
**Android:** pobierz `.apk` na telefon, otwórz go i zezwól na instalację z nieznanych źródeł (telefony 64-bitowe, gra w poziomie).

Wszystkie wersje: [Releases](https://github.com/cezary-lonski/chickenrpg/releases).
Jeśli Windows pokaże ostrzeżenie SmartScreen: „Więcej informacji” → „Uruchom mimo to” (plik nie jest podpisany).

Kurczak kontra ptasia armia Czarniego Kruka. Gra akcyjna 2D w Godot 4.7 z trybem
**RPG top-down** (widok z góry) oraz klasycznym trybem platformowym (z boku).

## Tryby gry

- **Kontynuuj** — od razu wchodzisz do gry zapisaną postacią (bez wyboru klasy i trudności). **Nowa gra RPG** — wybór slotu, bohatera, klasy i poziomu trudności (tylko przy tworzeniu).
- **Własne fale** — wybierasz potwory, ich liczbę i liczbę fal; pod tym trybem jest też **Arena graczy** (PvP tylko w LAN i online).
- **Gra online / Gra LAN** — hostujesz z poziomu gry zapisaną postacią, a dołączając wybierasz własną (KOD, a online dodatkowo IP hosta).
- **Tryb platformowy** — klasyczna gra z boku (etapy, sklep), dostępna w menu głównym.
- **Kreator postaci** — własny wygląd kurczaka, a w nim **Kreator animacji**.

Grafika to ręcznie generowany **pixel art** (stworzenia, rekwizyty, teren, ikony przedmiotów).

## Kampania RPG

Akt I (rozdziały I–VII), Akt II (mapa świata z wioskami) i finał w twierdzy Kruka, a w środku wyprawa przez stolicę:

| Część | Co się dzieje |
|-------|---------------|
| Rozdziały I–VII | Nocny najazd, trakt, płonąca stolica, wieża królowej, trzy próby, czarny marsz, serce Kruka |
| Akt II | Sześć wiosek pod władzą Kruka, wybory i wdzięczność mieszkańców |
| Rozdziały VIII–XII | Cień w popiele, zdrada w koronie, pustynny trakt, gniazdo nad burzą, ostatni świt |
| **Pałac** | 5 pięter z krukami-arystokratami, schody bez ekranu statystyk i sekretne komnaty z animowanymi historyjkami |
| **Narada wojenna** | animowana historyjka na 6. piętrze, wybór strategii, potem zamach |
| **Uwolnienie króla** | loch z klawiszami i więźniami, naczelnik więzienia |
| **Twierdza Kruka** | 2 piętra: mury i brama, koszary generałów (schody bez ekranu statystyk) |
| **Miasto i Zamek Kruka** | miasto, 3 piętra zamku (dziedziniec, krużganki, wieża generałów), sala tronowa i obowiązkowy pojedynek z rycerzem |

**Mapa świata**: osady rozmieszczone jak na prawdziwej mapie. Klikasz miejsce, gra wytycza trasę i maszerujesz przez wszystkie etapy; po bitwie wybierasz: idź dalej, zmień cel albo anuluj. **Zwój teleportacji** przenosi tylko do zbadanych miejsc.

**Poziomy trudności**, **powtórki rozdziałów**, **skrytka** w stylu Diablo 2 Resurrected, **pojedynki** z rycerzem (idealnie paruje, może nosić hiperlegendarną zbroję) oraz **legendarne przedmioty wyłącznie z bossów jaskiń**.

**Strażnicy i pety** mają własne życie, nie regenerują go, po śmierci przyjeżdża karetka, a po śmierci leżą w **szpitalu** i wracają po 5 minutach gry. Są też **sierżant Cezary**, **kowal z węglem** do kucia i **kryształy/diamenty** do kupienia.

Każdy rozdział: prolog → rozmowa z dawcą zadania → 3–4 fale wrogów (z przerywnikiem
z bossem) → rozmowa po bitwie → nagroda i przejście do kolejnego rozdziału.

## Rozwój postaci

Za każdy poziom dostajesz **5 punktów atrybutów**. Wydajesz je na siłę, życie, energię,
obronę, szybkość i szczęście — ekran pojawia się automatycznie po awansie, a niewydane
punkty czekają w pauzie pod przyciskiem „Atrybuty”.

## Sterowanie

- **W / A / S / D** — ruch (top-down: 8 kierunków)
- **J / K** — lekki / ciężki atak, **L** — unik, **U** — blok
- **I** — rzut przedmiotem, **O** — furia, **Shift** — sprint
- **1–6** — umiejętności klasowe
- **E** — interakcja (top-down)
- **Q** — dziennik zadań, **T** — drzewko umiejętności, **Esc** — pauza

## Klasy

Wojownik, Łucznik, Fechmistrz, Złodziej, Mag oraz Lady (tylko dla Lady).

## Ekwipunek (40 slotów)

Ekwipunek w stylu Minecrafta: **40 slotów plecaka**, osobne sloty **broni, hełmu, zbroi, butów,
akcesorium i dwóch amuletów**. Przedmioty przenosi się przeciąganiem lub przyciskami
(Załóż / Zdejmij / Użyj / Wyrzuć); mikstury i materiały układają się w stosy, a przedmioty, które
się nie zmieszczą, trafiają do **skrytki**. Każdy przedmiot ma stabilny identyfikator, rzadkość
(zwykły → niezwykły → rzadki → epicki → **legendarny** → **hiperlegendarny**) i jakość wykonania.

Zasada amuletów: działają **wyłącznie w slotach amuletów** (nie z plecaka); ten sam amulet nie
założy się dwa razy. Bonusy liczone są z aktualnego wyposażenia, więc zdjęcie amuletu od razu je
odbiera. Założona broń, zbroja, hełm, buty i amulet są widoczne na postaci.

## Poziomy i drzewko umiejętności

Maksymalny poziom to **100**. Za każdy poziom dostajesz **1 punkt umiejętności** (oraz 5 punktów
atrybutów). W drzewku (klawisz **T** lub pauza → *Umiejętności*) umiejętności mają wymagania
poziomu i poprzednich węzłów, widoczne przed zakupem; kolejne rangi zwiększają skuteczność.

## Kreator postaci i kreator animacji

* **Kreator postaci** (menu główne i początek nowej gry): bazowy wygląd, kolory części, ubrania
  (nakrycie głowy, szyja, plecy), nazwa, podgląd. Wygląd jest tylko kosmetyczny i zapisuje się.
* **Kreator animacji** (przycisk w kreatorze postaci): wybór części ciała, klatki, obrót/przesunięcie, odtwarzanie, czas i płynność. Animacje: bezczynność, chodzenie, bieg, atak, umiejętność, obrażenia, śmierć.

## Kowal, materiały i kucie

U kowala (rozmowa → kuźnia) kujesz **miecz** (1 sztabka + 1 węgiel), **zbroję** (5 sztabek + 3 węgle) lub **amulet**
(2 sztabki + diament + węgiel; węgiel kupisz też u kowala) z żelaza, **kurczalu** albo **kurczalium**. Minigra ma trzy etapy:
nagrzewanie, kucie i hartowanie; wynik wyznacza jakość przedmiotu (przy porażce przepada tylko połowa
składników). Zbroja z kurczalium jest **hiperlegendarna** i daje fioletową aurę płomieni, dopóki jest założona.

## Sekrety, pety i legendarne przedmioty

W wielu strefach są skrzynie (także ukryte), dźwignie i **sekretne jaskinie** – wejście odsłania się
po pociągnięciu trzech dźwigni. Na końcu jaskini czeka skarbiec z legendarną nagrodą, a czasem
**towarzysz**. Pety (Kurczaczek, Wiewiórka-zbieraczka, Lis-łowca, Sówka-uzdrowicielka,
Żółw-tarczownik) mają różne role i własne, tylko dla nich przeznaczone wyposażenie (menu *Towarzysze*).

## Kampania

* **Akt I** (rozdziały I–VII): każdy rozdział ma dodatkowych NPC z dialogami i wyborami, cele
  (rozmowy, zbieranie informacji, uwolnienie jeńców, sabotaż, elitarni wrogowie), cele po walce z
  bossem oraz własnego **bossa z areną, fazami i zapowiedziami ataków**. Finał: **Czarny Kruk (5000 HP)**.
* **Akt II – Zemsta na Czarnym Kruku**: mapa świata z sześcioma wioskami kontrolowanymi przez Kruka.
  Misje wybierasz w dowolnej kolejności, decyzje dają wdzięczność wiosek, a gniazdo odblokowuje się
  po wyzwoleniu pięciu wiosek. Dalej kampania wraca do rozdziałów VIII–XII.

## Uruchomienie

Wymagany Godot 4.7+. W katalogu projektu:

```
godot --path .
```

## LAN

1. Host: `Gra LAN` → `Hostuj` → `Generuj` (kod) → `Start`. Podaj kod drugiej osobie.
2. Gość: `Gra LAN` → `Dołącz` → wpisz kod → wybierz klasę → `Start`.

Host rozgłasza kod w sieci lokalnej (UDP broadcast), więc gość zwykle nie wpisuje IP.
Jeśli sieć blokuje broadcast, w polu **IP HOSTA** można podać adres ręcznie.

## Online

1. Host: `Gra online` → `Hostuj` → `Generuj` (kod) → `Start`. Gra pokaże IP i kod do udostępnienia.
2. Gość: `Gra online` → `Dołącz` → wpisz **publiczne IP hosta** i kod → wybierz klasę → `Start`.

Host automatycznie próbuje przekierować port UDP przez **UPnP**. Jeśli router tego nie
obsługuje, trzeba ręcznie przekierować podany port UDP i wpisać swoje publiczne IP.
Gra nie używa serwera pośredniczącego — połączenie jest bezpośrednie.

## Struktura

```
autoload/    GameState (profil, ekwipunek, drzewko, pety, Akt II), Flow, Net, Audio, Fx, Art
actors/      player, enemy, pociski
scripts/     bazy danych (klasy, przedmioty, questy, strefy, NPC) + UI
scenes/      menu, etapy, wioska, gracze
docs/        rpg_design.md
```

## Żołnierze, laboratoria i LAN

* Podczas kampanii towarzyszą ci **żołnierze Korony** (2 w Akcie I, 3 w Akcie II), którzy walczą u twojego boku.
* **Laboratoria** (w kilku strefach): pierwiastek **BU** powstaje z poświęcenia przedmiotu legendarnego (minigra: zmniejszasz się i zjadasz jądra atomowe, na końcu wybuch i okna błędów na ekranie); z węgla, diamentu, 2 sztabek kurczalu i pierwiastka BU powstaje sztabka **kurczalium**.
* Wrogowie skalują się do siły postaci, więc legendarny sprzęt nie rozwala ich jednym ciosem.
* **LAN**: obaj gracze mogą rozmawiać z NPC, otwierać skrzynie, wykonywać cele, ciągnąć dźwignie i wchodzić do jaskiń.
  Flagi fabuły są wspólne (autorytetem jest host), nagrody i skrzynie liczą się każdemu graczowi osobno.

## Runy

Każde słowo wymaga **wzorca** („Wzorzec run: SŁOWO”) — kowal nie wie, jak runy wyglądają. Wzorce wypadają z potworów (rzadziej, lepsze z silniejszych), leżą w skrzyniach i jaskiniach, są nagrodą za bossów i zadania, a słowa rzadkie kupisz w sklepie. Kowal uczy się wzoru na stałe po otwarciu „Zapis run…”.

U kowala („Zapis run…”) możesz wyrzeźbić słowo runami na dowolnym wyposażeniu (klikasz punkty obrysu każdej runy).
Zbroja z kurczalium jest **legendarna**; wyższe rzadkości daje tylko zapis run:

| Słowo | Efekt |
|---|---|
| **KURCZAK** (7) | rzadkość HIPEREKSTRALEGENDARNA, +5% kradzieży życia i +5% redukcji obrażeń, złota aura |
| **CZARKA** (6) | HIPERLEGENDARNA (fioletowa aura na zbroi) + 4% kradzieży życia |
| **KURZA**, **ZAKAZ** | słabszy przedmiot → LEGENDARNY; już legendarny → statystyki +20% (do 3 razy) |
| **KURA**, **KURZ**, **CZAR**, **ARKA** | słabszy przedmiot → EPICKI |
| **KUC**, **RAK**, **RAZ**, **UCZ** | słabszy przedmiot → RZADKI |

Przy podniesieniu rzadkości statystyki przedmiotu rosną proporcjonalnie. Kurczalium w skrzynkach i nagrodach jest teraz znacznie rzadsze.

## Poziomy trudności, powtórki rozdziałów i własne fale

* **Poziom trudności** (ekran „Nowa gra RPG"): *Normalny* (jak dotąd), *Koszmarny* (potwory 5× wytrzymalsze i 3× groźniejsze, XP ×3, złoto ×2,5) i *Piekielny* (10× / 5×, XP ×6, złoto ×5). Postać, poziomy i ekwipunek zostają, więc nie zaczynasz od zera. Im wyższa trudność, tym lepsze legendarki.
* **Powtarzanie rozdziałów**: na tym samym ekranie strzałkami wybierasz dowolny odblokowany rozdział i grasz go od nowa (fabuła cofa się do niego, ekwipunek zostaje).
* **Własne fale** (przycisk na ekranie nowej gry): edytor — liczba fal, potwory i ich ilość, bossowie, elita, mnożniki życia / ataku / XP każdej fali, teren. Konfiguracja zapisuje się w profilu.
* **Legendarki umiejętności** (14 wzorów × 3 jakości: legendarna / hiperlegendarna / hiperekstralegendarna): dają m.in. moc umiejętności, krótsze odnowienie, tańsze umiejętności, większy zasięg i regenerację energii. Wypadają z potworów, elit, bossów i ze skrzyń; na trudniejszych poziomach częściej i w lepszej wersji.
* **Pixel art**: postacie, drzewa, domy, studnia, kolumny, skały, kowadło, stragan, skrzynie i podłoże są rysowane od zera jako prawdziwy pixel art (siatka 4 px, płaskie cieniowanie, czarny kontur). Napisy i interfejs zostają ostre.

* **Własne fale** są w menu głównym. W grze LAN / online wybierasz zapisaną postać (zapis gry z ekwipunkiem i poziomem) — zarówno hostując, jak i dołączając.

* **Menu pod Esc**: ekwipunek, atrybuty, umiejętności, towarzysze, Własne fale, Hostuj grę LAN / online, ustawienia.

* **Arena graczy** (tylko LAN / online; menu główne albo Esc): pojedynek dwóch graczy zapisanymi postaciami — każdy walczy swoimi statystykami i wyglądem z własnego zapisu, skillami i atakami (trafiają wrogiego gracza). Odliczanie 3-2-1, paski życia u góry, KO kończy walkę.
* **Animacje umiejętności**: każda umiejętność ma znak przywołania pod stopami, a część własny efekt w stylu pixel art — pierścienie, unoszące się strzałki / plusy / tarcze / łapy, błysk wystrzału, celownik headshota, linie prędkości, potężny zamach, płomienie ognistego kręgu i kopuła bariery.

* **Żołnierze i pety mają życie** (pasek nad głową). Wrogowie biją je tak jak gracza. Gdy któryś polegnie, przyjeżdża karetka (pixel art, migający kogut), zabiera go, a walka toczy się dalej. Poległy leży w szpitalu (Esc → „Szpital”: życie rośnie, widać czas do powrotu) i wraca karetką po **5 minutach** gry.
* **Tworzenie BU**: przy wybuchu na ekranie pojawia się 5000 okien błędów.

* **Tablica zleceń** (w każdej strefie, obok miejsca startu): trzy zlecenia poboczne, w których nie chodzi o walkę — **zbieranie ziół**, **tropienie śladów** do skrzyni zaginionego kupca, **doręczenie paczki listów** wybranemu mieszkańcowi oraz **polowanie na łowcę nagród**. Dwa aktywne zlecenia naraz, nagroda to złoto, XP, przedmioty i punkt reputacji; postęp widać w dzienniku zadań.
* **Wspólna gra nie niszczy zapisu**: fabuła wspólnej gry (LAN / arena) jest tymczasowa i po wyjściu wraca własny postęp.

* **Pałac i nowa fabuła Aktu I**: po Płonącej stolicy wchodzisz do **pałacu** — 6 pięter (hol, biblioteka, sala bankietowa, galeria portretów, kaplica i zbrojownia, a na szczycie wieża królowej). Na każdym piętrze są strażnicy, schody (szambelan) i komnaty kruczych arystokratów ze śmiesznymi historyjkami. Dalej: **narada w sali narad** z królową i doradcami (wybór strategii), **uwolnienie Króla** z lochu (podchodzisz do celi i go uwalniasz), twierdza Kruka z generałami, **Miasto Kruka**, **Zamek Kruka** (generałowie, bez dworzan) i walka w sali tronowej. Stare zapisy są migrowane do nowej numeracji rozdziałów.
* **Mapa świata** (klawisz M albo Esc → „Mapa świata"): pixelowa mapa, na której osada, trakty, stolica, pałac, twierdze i wioski leżą jak na prawdziwej mapie (bez numerów rozdziałów). Klikasz miejsce, mapa wytycza drogę przez kolejne etapy, a „Maszeruj" prowadzi cię przez nie: w każdym pokonujesz potwory, a potem wybierasz — idziesz dalej, zmieniasz cel albo anulujesz marsz. Zablokowane są miejsca jeszcze nieodkryte. **Zwój teleportacji** (nagroda za zadania i rozdziały) przenosi natychmiast, bez marszu, ale tylko do miejsc już zbadanych.
* **Jaskinie**: na końcu czeka boss, który dzierży legendarny przedmiot z nagrody; skrzynia otwiera się dopiero po jego pokonaniu.
* **Ikony przedmiotów** narysowane w pixel arcie (16×16), błędy przy tworzeniu BU pojawiają się po kolei, coraz szybciej.

* **Pety**: wyposażenie hiperekstralegendarne (Słoneczna Obroża, Napierśnik i Łuk pupila — łup z Piekielnego poziomu) otacza peta ogromną aurą płonącego, złotego słońca; hiperlegendarne daje fioletowy wir. Polegli towarzysze wracają po **5** poziomach.

* **Sierżant Cezary** dołączył do żołnierzy Korony: w kampanii walczą z tobą Szeregowy Antek, Kapral Bolek i Sierżant Cezary (w Akcie II także Szeregowy Dominik).

* **Osobne drzewka umiejętności dla każdej klasy** (Wojownik, Łucznik, Fechmistrz, Złodziej, Mag, Lady): każda ma własne trzy gałęzie, kolejność odblokowywania i wymagania. Klasa zapisanej postaci jest na stałe — przy kontynuowaniu gry (i w lobby LAN) nie można jej zmienić.

* **Sekretne komnaty** pałacu: zamiast rozmów z arystokratami — dobrowolne drzwi, a w środku animowana scenka (kąpiel Barona, kapelusz z dżdżownicami, kazanie dla śpiących…) z tłem pokoju, oknem, dywanem i napisami. Schody na kolejne piętro prowadzą od razu na górę, bez ekranu statystyk. Etapy mają meble zgodne z opisem (regały w bibliotece, stoły na bankiecie, portrety w galerii, ławy w kaplicy), a wrogowie mają przebrania pasujące do nazw fal (czytelnicy z mieczami i księgami, kelnerzy z tacą, konserwatorzy z pędzlem…).
* **Skrytka** (Esc → „Skrytka" albo skrzynia obok miejsca startu): wspólna dla wszystkich postaci, 3 zakładki po 60 miejsc, jak w Diablo 2 Resurrected.
* **Pojedynek z rycerzem**: czasem między falami rycerz w zbroi (zwykłej, legendarnej albo hiperlegendarnej z fioletową aurą) wyzywa cię na pojedynek. Doskonale paruje ciosy z przodu, a odsłania się tylko podczas własnego ataku i po nim.
* **Legendarki** wypadają wyłącznie z bossów sekretnych jaskiń.

* **Dużo historyjek**: oprócz pałacu sekretne komnaty ze scenkami są też w sali narad (mapa-obrus Marszałka, długi Kanclerza, Mistrz Szpiegów za kotarą, próba przemówienia królowej), w wieży królowej, lochu, Mieście i Zamku Kruka oraz we wcześniejszych etapach (chata Kasi, wóz Bronka, piekarnia Zosi).
* **Uzbrojeni wrogowie**: każdy żołnierz wroga ma pasujące do gatunku zbroję, hełm i broń (miecz, włócznia, łuk, buzdygan, laska maga, zbroja królewska). Podczas pojedynku z rycerzem strażnicy i pety nie atakują jego celu.

## Narada, laboratorium, strażnicy
- **Narada wojenna** to teraz animowana historyjka (16 kwestii: kłótnia Marszałka, Kanclerza i Mistrza Szpiegów, ostatnie ciastko…), po której wybierasz strategię, a w sali pojawiają się zamachowcy.
- **Laboratorium** jest budynkiem (z kominem i zielonymi oknami) — wejście przez drzwi.
- **Strażnicy** zadają o połowę mniejsze obrażenia i biją wolniej.
- Tablica zleceń i skrytka stawiane są w miejscu najdalej od NPC, żeby łatwo rozmawiać (np. ze Strażnikiem Michałem).

## Płomienie na postaci
Założony **hiperekstralegendarny** przedmiot (dowolny slot) otacza gracza dużym **złotym płomieniem** (ok. 2 kurczaków), a **hiperlegendarny** — fioletowym. Złoty ma pierwszeństwo.

## Historyjki zakończeń, osiągnięcia i wyzwania
- Po bossach i kluczowych rozdziałach grają **animowane historyjki epilogowe**, każda z własną **muzyką generowaną w grze**. Rozdział „Ostatni świt” kończy **finałowa sekwencja** (wieś, koronacja, ostatni zachód słońca).
- **Osiągnięcia** (Esc → „Osiągnięcia” w grze RPG) z dziennikiem odkryć: sekretne komnaty, jaskinie, legendarki, pojedynki, rekord wyzwań.
- **Wyzwania — pojedynki**: kolejni rycerze z rosnącą siłą, ranking 5 najlepszych wyników.
- Raport balansu: [docs/balance_report.md](docs/balance_report.md).

## Drobne usprawnienia
- Przedmioty leżące na ziemi mają własne ikony (wcześniej wszystkie wyglądały jak jajka).
- Komunikaty na ekranie pojawiają się po kolei, trwają ok. 5 s i gasną powoli; można je wyłączyć w ustawieniach („Komunikaty na ekranie”, domyślnie włączone).
- **Szpital**: poległy strażnik/pet leży w szpitalu (życie rośnie, wraca po 5 minutach gry). Podgląd: Esc → „Szpital”. W wioskach stoi **budynek szpitala** — za złoto leczy rannych i od razu wypisuje poległych.

## Nowy interfejs (HUD)
- Życie i energia to **puste w środku kurczaki** przy rzędzie jajek: widać kontur i oko, a wnętrze wypełnia się od dołu.
- **Dziewięć umiejętności** (klawisze 1–9) jako jajka w równym rzędzie z odstępami, nazwa na jajku, numer pod nim, cooldown zaciemnia jajko.
- Drewniane panele (statystyki, zadanie, złoto) i komunikaty; pasek szybkich przedmiotów zniknął z ekranu (rzut przedmiotem nadal na klawisz I).

## Zasady rzadkości
- Z walk, skrzyń i jaskiń wypadają co najwyżej **legendarne** przedmioty. Hiperlegendarne i hiperekstralegendarne da się zdobyć tylko przez **runy**.
- Sklep w trybie platformowym sprzedaje wyłącznie przedmioty za złoto i poniżej legendarnych (bez „gratisowych” legendarek).
- Menu startowe ma pixelartowe tło (świt, zamek, wioska), a ikoną aplikacji jest logo Chicken RPG.

## Ustawienia grafiki
W ustawieniach (i w menu Esc) są przełączniki: **Animacje** (oddychanie, mruganie, cząstki w tle) i **Aury i płomienie** (aury ekwipunku, szału i wsparcia). Oba domyślnie włączone.

## Import zapisu
Menu → „Nowa gra RPG” → przy każdym slocie jest przycisk **Importuj zapis…**: wybierasz plik `chicken_brawl_save_*.json` (np. skopiowany z innego komputera lub folderu), a gra wczytuje go do tego slotu i ustawia go jako ostatni, więc „Kontynuuj” od razu go otwiera. Przy istniejącym slocie trzeba potwierdzić nadpisanie, a stary zapis zostaje jako kopia `*.bak.json`.

## Menu startowe i gra wieloosobowa
- Menu startowe (układ z logo po lewej) ma **animowane pikselowe tło**: płyną chmury, lecą ptaki, powiewa flaga na zamku, dymi komin, błyska rzeka i latają świetliki (można wyłączyć w ustawieniach → „Animacje”).
- **Gry wieloosobowej (LAN) nie ma w menu startowym.** Otwierasz ją w trakcie gry: Esc → **Multiplayer (LAN)** (hostowanie albo dołączanie z kodem).
- **Arena** też jest tylko w menu Esc, w grze wieloosobowej: Esc → **Arena: zaproś gracza**. Wybierasz gracza, on dostaje zaproszenie i się **zgadza albo odrzuca**. Po zgodzie host przełącza obu graczy w arenę 1 na 1. Tryb online został wyłączony z menu.
