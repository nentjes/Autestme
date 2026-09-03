# Opdracht aan Claude — Autestme iOS in de wereld van The Toy Mint

**Opdrachtgever:** Roel Nentjes  
**Creative direction:** Codex  
**Status:** uitvoerbaar ontwerpbesluit  
**Website-referentie:** <https://www.autestme.com/>  
**Website-commit:** `314f5aa`  

## 1. Opdracht in één zin

Breng de volledige Autestme iOS-app onder in dezelfde scherpe, speelse en
retro-futuristische wereld als de nieuwe website, zonder de spelwerking,
lokalisatie, toegankelijkheid, Firebase- of Web3-logica te beschadigen.

De app mag geen verkleinde website worden. De website verleidt en vertelt; de
app is de werkende Toy Mint: geconcentreerd, begrijpelijk, snel en betrouwbaar.

## 2. Waarom dit nu moet

Autestme staat in de App Store naast 2R als een andere app van Roel Nentjes. De
oude website en de huidige standaard-SwiftUI-uitstraling passen niet meer bij
de kwaliteit en oorspronkelijkheid van het merk. De nieuwe website is inmiddels
live. De app moet nu herkenbaar uit dezelfde wereld komen.

De huidige functionele basis blijft leidend. Dit is een visueel en UX-redesign,
geen herschrijving van het spel of de infrastructuur.

## 3. Niet onderhandelen over deze uitgangspunten

1. Behoud de bestaande GitHub-repository als enige bron van waarheid.
2. Werk voort op de aanwezige, nog niet gecommitte wijzigingen; overschrijf of
   herstel niets van Roel of andere agents zonder eerst de diff te beoordelen.
3. Scheid uiterlijk van spel- en netwerklogica. Geen Firebase-, Web3-, timer-,
   score- of audiowijzigingen tenzij ze aantoonbaar nodig zijn voor de UI.
4. Geen emoji als pictogrammen, geen generieke blauwe knoppen, geen regenboog-
   gradients, geen glazen dashboardstijl en geen crypto-clichés.
5. Geen menselijke handen of mensen als illustratief motief. Autestme gaat over
   spelers en autonome agents; de machine en de spelstukken dragen het beeld.
6. De scherpe Toy Mint-fotografie hoort bij marketing en introductie. Tijdens
   het actieve geheugenspel gebruiken we geen fotografie of bewegend decor.
7. Alle vijf talen blijven werken: Engels, Nederlands, Spaans, vereenvoudigd
   Chinees en Hindi. Voeg geen zichtbare hardcoded tekst toe.
8. Dynamic Type, VoiceOver, Reduce Motion, voldoende contrast en minimaal 44×44
   pt aanraakvlak zijn acceptatie-eisen, geen latere optimalisaties.

## 4. Merkgedachte

Autestme begon toen een vader, zijn kinderen en ChatGPT samen met vormen,
letters en cijfers een spel maakten. Daarna ontstond de AUTEST-token en de regel
die het project werkelijk eigen maakt:

> Wie de hoogste score heeft, moet wachten totdat iemand anders hem verslaat.

De visuele wereld is daarom geen casino en geen cryptobeurs. Het is een uiterst
verzorgde speelgoedmuntmachine: nieuwsgierigheid, tellen, zelfbeheersing,
techniek en doorgeven.

Kernzin:

> Play. Think. Pass it on.

## 5. Beeldmerk en app-icon

Het oude 1R/2R-afgeleide logo vervalt voor Autestme. Gebruik het nieuwe
**Mint Mark**: de crèmekleurige poort van de machine waaruit een koraalkleurige
spelmunt verschijnt.

Bronnen:

- Websitebeeldmerk: `website/images/autestme-mint-mark.svg`
- Kleine websitevariant: `website/images/autestme-mint-mark-micro.svg`
- Vierkante app-iconmaster: `docs/design-assets/autestme-app-icon-master.svg`
- Gerenderde App Store-master: `docs/design-assets/autestme-app-icon-1024.png`

Voor het iOS-appicon geldt:

- gebruik de vierkante master zonder transparantie;
- voeg zelf geen afgeronde hoeken toe — iOS past het masker toe;
- controleer herkenbaarheid op 1024, 180, 120, 60, 40, 29 en 20 pt;
- verwijder de kleine spelstukken uit varianten onder 60 pt als ze dichtlopen;
- verander de bestaande `AppIcon.appiconset` pas nadat alle vereiste formaten
  correct zijn gegenereerd en in `Contents.json` zijn gekoppeld.

## 6. Kleursysteem

Gebruik semantische tokens. Schrijf geen losse hex- of RGB-waarden door de
views heen.

| Token | Hex | Gebruik |
|---|---:|---|
| `mintPetrol` | `#082F2C` | primaire achtergrond, merkvlak |
| `mintPetrolDeep` | `#031F21` | actieve spelruimte, diepte |
| `mintPetrolSoft` | `#17433E` | kaarten en secundaire panelen |
| `mintCream` | `#F5ECDA` | hoofdtekst en lichte machinepanelen |
| `mintCreamBright` | `#FFF8EA` | sterke titel/hoogste contrast |
| `mintCoral` | `#F06452` | primaire actie, actieve status, munt |
| `mintCoralDark` | `#CA493B` | ingedrukte/hovervariant |
| `mintGreen` | `#A8CBB8` | positieve en rustige secundaire status |
| `mintYellow` | `#F6C65B` | score, aandacht, driehoek |
| `mintLilac` | `#A999D4` | letterspel en aanvullend accent |
| `mintChrome` | `#C7C7BD` | dunne machinecontouren, nooit hoofdtekst |

Voeg deze kleuren bij voorkeur als named color sets aan `Assets.xcassets` toe,
met gecontroleerde light/dark appearances. De merkervaring mag standaard donker
zijn, maar respecteer systeemcontrast en verhoogd contrast.

## 7. Typografie

Gebruik Apple-systeemfonts voor betrouwbaarheid en Dynamic Type:

- expressieve titels: `.system(.largeTitle, design: .serif, weight: .semibold)`;
- functionele tekst: standaard SF Pro via `.body`, `.callout`, `.caption`;
- counters en score: `.system(.title2, design: .monospaced, weight: .semibold)`;
- bedieningslabels: `.system(.headline, design: .rounded, weight: .semibold)`.

Bundel Fraunces niet in fase 1. De app moet eerst met system fonts volledig
toegankelijk en stabiel worden. Een eigen lettertype kan later als gecontroleerd
merkbesluit worden toegevoegd.

## 8. Nieuwe herbruikbare componenten

Maak eerst één kleine designlaag, bijvoorbeeld:

- `ToyMintTheme.swift` — kleuren, spacing, radii, strokes en schaduwen;
- `MintPanel.swift` — petrol/cream machinepaneel;
- `MintPrimaryButtonStyle.swift` — koraalkleurige hoofdactie;
- `MintSecondaryButtonStyle.swift` — rustige omlijnde actie;
- `MintCounter.swift` — mechanische/monospaced teller;
- `MintSegmentedControl.swift` — vormen, letters, cijfers;
- `MintSliderRow.swift` — label, waarde, slider en toegankelijkheid;
- `MintStatusLamp.swift` — status met kleur én tekst/symbool;
- `MintWordmark.swift` — nieuw beeldmerk plus woordmerk.

De componenten zijn functioneel SwiftUI, geen afbeelding van een knop. Gebruik
subtiele 1-punts contouren, kleine highlights en gecontroleerde schaduw om het
gevoel van metaal en speelgoed te geven. Geen zware animatie of skeuomorfisme
dat de bediening verhult.

## 9. Scherm voor scherm

### 9.1 `StartScreen.swift` — het bedieningspaneel

Doel: binnen vijf seconden begrijpen wat je kunt doen en hoe je begint.

Nieuwe hiërarchie:

1. Mint Mark + `Autestme` + korte regel `Play. Think. Pass it on.`
2. Mechanische highscoreteller en knop naar ranglijst.
3. Keuze `Vormen / Letters / Cijfers` als drie grote, fysieke maar heldere
   segmenten met cirkel, A en 3 als voorbeeld.
4. Instellingen in één cream/petrol machinepaneel:
   - duur;
   - snelheid;
   - aantal items;
   - vaste of wisselende kleur.
5. Grote koraalkleurige knop om het spel te starten.
6. Spelernaam als rustig veld vóór de hoofdactie, niet als los formulierblok.
7. Tokenbeloningen/Web3 in een zichtbare, inklapbare lade `AUTEST-beloningen`.

Vervang de verborgen veegbeweging voor crypto niet door nóg een verborgen
gebaar. De huidige `swipeInstruction` en `isCryptoEnabled` mogen functioneel
blijven bestaan tijdens migratie, maar de eindtoestand moet een expliciete,
toegankelijke disclosure/toggle zijn. Een kritieke functie mag niet uitsluitend
door een onzichtbare swipe bereikbaar zijn.

Diagnostics horen achter een duidelijke `Technische details`-actie in de lade,
niet in het primaire pad.

### 9.2 `GameContainerView.swift` — absolute concentratie

Doel: tijdens het onthouden niets tonen dat niet noodzakelijk is.

- volle achtergrond `mintPetrolDeep`;
- bovenin alleen de resterende tijd als compacte mechanische teller en een
  geluidknop;
- middenin één groot spelobject met royale lege ruimte;
- geen fotografie, kaart, card-stack of marketingtekst;
- vormen gebruiken koraal, mint, geel, lila, cream en petrol-soft;
- letters en cijfers krijgen dezelfde schaal, optische centrering en ritme;
- overgangen maximaal 120–180 ms, zonder stuiteren;
- bij Reduce Motion: directe wissel of eenvoudige opacity-transitie;
- geluidstatus altijd ook door label/VoiceOver begrijpelijk, niet alleen kleur.

Onderzoek of de titel `game_screen_title` tijdens het spelen werkelijk nodig is.
Zo niet: verwijderen en de ruimte aan het spelobject geven.

### 9.3 `EndScreen.swift` — de telconsole

Doel: antwoorden invoeren zonder spreadsheetgevoel.

- gebruik een scrollbare telconsole in plaats van een standaard `List`;
- iedere regel toont het spelstuk/teken, een duidelijke numerieke invoer en
  voldoende witruimte;
- numeriek toetsenbord en focusgedrag blijven werken;
- primaire knop `Bekijk resultaat` in koraal;
- resultaatregels gebruiken niet uitsluitend rood/groen: voeg `goed`, `anders`
  of een toegankelijk symbool toe;
- score verschijnt in een groot mechanisch telraam;
- bij een nieuwe highscore: ingetogen kroon/muntmoment, geen confetti-casino;
- leg vervolgens de hoofdregel uit: de winnaar wacht tot iemand hem verslaat;
- Firebase- en Web3-status krijgen een aparte rustige statuslade en mogen de
  score niet visueel overheersen.

### 9.4 `LeaderboardView.swift` — het scorebord

Doel: voelen als het fysieke tellerbord op de machine.

- petrol achtergrond met cream scorebordpaneel;
- rangen en scores monospaced;
- plaats 1 krijgt geel, 2 chrome, 3 warm koper; de rest cream/petrol;
- bewaar pull-to-refresh;
- toon per speler naam, speltype en score zonder standaard iOS-lijstscheidingen;
- leg bovenaan in één zin uit dat nummer één tijdelijk niet opnieuw mag spelen.

### 9.5 Wallet, netwerkstatus en fouten

Crypto blijft optioneel en mag het eenvoudige spel nooit blokkeren.

- geen `Color.blue`, `Color.indigo`, `Color.green` of `Color.orange` als losse
  systeemkeuren; map elke status naar een Toy Mint-token;
- combineer statuskleur altijd met tekst en eventueel een eenvoudig SF Symbol;
- valideer walletadres inline en begrijpelijk;
- verbindingsproblemen moeten spelen zonder beloning mogelijk blijven maken;
- zet debugdetails achter een disclosure voor gevorderden.

## 10. Animatie en geluid

De websitebeelden zijn scherp en stil. De app mag alleen bewegen wanneer dat
betekenis heeft:

- knop indrukt: maximaal 0,98 scale, 100–140 ms;
- spelstuk wisselt: korte opacity/scale-overgang;
- highscoremunt wordt uitgegeven: één rustige mechanische beweging;
- geen permanente pulsen, zwevende deeltjes, parallax of hypnotische achtergrond;
- respecteer Reduce Motion overal.

De bestaande spelgeluiden en `SoundManager` blijven leidend. Maak eerst de
visuele migratie af; vervang geluiden alleen in een afzonderlijke opdracht met
luistertest en volumebalans.

## 11. Lokalisatie en toegankelijkheid

- Gebruik voor zichtbare tekst `LocalizedStringKey` of `NSLocalizedString` op
  één consistente manier.
- Lokaliseer ook alle accessibility labels en hints. In de huidige code staan
  verschillende Engelse en Nederlandse labels hardcoded.
- Test extreem lange Spaanse en Duitse-achtige woordlengtes, ook al is Duits nu
  nog geen ondersteunde taal.
- Test Dynamic Type tot en met accessibility sizes.
- De spelobjecten moeten ook zonder kleur te onderscheiden zijn.
- Controleer contrast van koraal op petrol en cream op petrol volgens WCAG AA.
- Zorg dat VoiceOver niet iedere decoratieve machinecontour voorleest.

## 12. Uitvoeringsvolgorde

Werk in kleine, reviewbare commits:

1. **Nulmeting:** maak screenshots van alle huidige schermen en voer bestaande
   build/tests uit. Leg bekende functionele fouten apart vast.
2. **Theme:** voeg tokens en componenten toe zonder bestaande schermen te
   veranderen.
3. **Start:** migreer `StartScreen` en laat Roel op een echte kleine én grote
   iPhone beoordelen.
4. **Game:** migreer het actieve spel en test timer, geluid en navigatie.
5. **End:** migreer invoer en resultaat; test toetsenbord en alle speltypen.
6. **Leaderboard/Web3:** migreer scoreboard en statusladen.
7. **Icon/launch:** vervang pas nu appicon en launch-presentatie.
8. **QA:** vijf talen, light/dark, Reduce Motion, VoiceOver, Dynamic Type,
   offline/online, lege/ongeldige wallet, Firebase-fout en Web3-fout.

Na iedere fase: build, test en screenshots. Geen grote alles-in-één commit.

## 13. Acceptatiecriteria

Het werk is pas gereed wanneer:

- alle schermen visueel onmiskenbaar bij autestme.com horen;
- geen oud 1R-logo of generieke blauwe hoofdactie meer zichtbaar is;
- het actieve spel rustiger is dan vóór de redesign;
- de spelregels en highscoreblokkade functioneel onveranderd werken;
- spelen zonder crypto mogelijk blijft;
- alle vijf talen volledig en zonder afgekapt tekst werken;
- VoiceOver, Dynamic Type en Reduce Motion aantoonbaar zijn getest;
- de app op de kleinste ondersteunde iPhone en een groot Pro Max-scherm werkt;
- geen secrets, sleutels of configuratiebestanden in Git zijn beland;
- bestaande ongerelateerde wijzigingen niet zijn teruggedraaid;
- Roel screenshots of een TestFlight-build per fase heeft kunnen beoordelen.

## 14. Eerste concrete opdracht

Begin uitsluitend met fase 1 en fase 2:

1. inventariseer eerst de huidige uncommitted diff;
2. maak de theme/componentlaag;
3. bouw één volledig werkend Toy Mint-ontwerp voor `StartScreen.swift`;
4. laat spel-, Firebase- en Web3-logica ongemoeid;
5. lever screenshots op van ten minste een kleine iPhone en een Pro Max;
6. wacht op Roels visuele akkoord voordat `GameContainerView`, `EndScreen`,
   `LeaderboardView` of het productie-appicon wordt aangepast.

Deze fasering is bewust. Snelheid ontstaat hier door kleine zekere stappen, niet
door de hele app tegelijk te overschilderen.
