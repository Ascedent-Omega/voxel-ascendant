# RC26 – synchroner Geometrieaufbau durch Fensterlicht

28.09.2026. Das gesamte Performance-Ziel bleibt offen. Diese Runde behebt einen
reproduzierten langen Einzelruckler beim nahtlosen Kartenwechsel. Sie belegt
weder allgemeine 60 FPS noch die Behebung aller gemeldeten 4-FPS-Fälle.

## Ursache und Änderung

Die Lichtvorbereitung verwendet eine Nachbarschaft, die auch noch nicht fertig
gebaute Karten enthalten kann. `NativeWindowLights.append()` rief dort bisher
`Structures.forMap()` auf. Bei fehlendem Analyse-Cache löste dies unmittelbar
`VoxelFurniture.claim()` sowie Dekodierung und GPU-Aufbau der Möbelmodelle aus.
Der Aufruf kam aus dem Update-Hauptpfad, außerhalb der Mesher-Coroutine. Deshalb
konnten die vorhandenen `BuildBudget`-Prüfungen diese Arbeit nicht verteilen.
Eine bereits laufende Mesher-Vorbereitung verhinderte diesen zweiten Aufbau nicht.

Gen 1 liest jetzt ausschließlich `Structures.peek()`: Nur veröffentlichte
Analysen liefern Fensterlicht. Fehlende Geometrie baut weiterhin der reguläre
Mesher auf. Sobald sie veröffentlicht ist, wird sie im nächsten Lichtdurchlauf
berücksichtigt; es gibt keinen negativen Cache, kein dauerhaftes Abschalten von
Fenstern und keinen zusätzlichen RAM-Puffer. Der Gen-2-Pfad nutzte bereits
`lightingForMap()` und bleibt unverändert.

Die begrenzte Produktionsdiagnose erfasst zusätzlich `LocalLights.prepare`,
`NativeWindowLights.append` und `Gen1OverworldStadium.prepare`, damit künftige
Hänger nicht nur als unspezifische Update-/Renderzeit erscheinen.

## Native Streckenmessung

LOVE 11.5 auf dem verfügbaren Mac, 1710×955 Renderpixel, Nacht/Regen,
Voxel-Modus 6, Unschärfe 3, 128 MiB Kartenbudget, VSync aus. Isolierte, stumme
QA-Identität; persönliche Spielstände bleiben unberührt.

Die Messstrecke läuft tatsächlich von Celadon nach Route 7, zurück, nach Route
16 und zurück. Nur die Startposition wird im Setup gesetzt. Der Wegfinder
beachtet Voxel-Kollisionen und plant bei beweglichen NPCs neu; Bewegung,
Kartenverknüpfungen und Eintrittsereignisse laufen durch den normalen Spielcode.
Ein erster vollständiger Lauf umfasst zwei Runden / acht Übergänge. Detaillierte
Diagnoseläufe umfassen jeweils eine Runde / vier Übergänge.

| Diagnoselauf | Spielframes | Langsamster Lichtaufruf | Möbelauflösungen >4 ms aus Fensterlicht | Größter erfasster Hitch |
| --- | ---: | ---: | ---: | ---: |
| Alter Pfad | 2302 | 650,16 ms | 25 | 679,45 ms |
| Neuer Pfad | 2266 | 11,75 ms | 0 | 113,79 ms |
| Alter Pfad erneut | 2248 | 448,17 ms | 23 | 464,47 ms |

Der Rückwechsel zum alten Pfad erfolgte ausschließlich im QA-Treiber; die
Arbeitskopie blieb auf der Korrektur. Unterschiedliche NPC-Wege und Systemlast
verhindern eine allgemeine FPS-Prozentangabe. Die Aufrufstapel belegen jedoch,
dass der lange synchrone Möbelaufbau aus dem Lichtpfad mit der Änderung entfällt
und beim Rückwechsel erneut auftritt. Das sind CPU-seitige Wandzeiten, keine
isolierten GPU-Zeitstempel. Trace-Instrumentierung hat eigenen Aufwand.

Der vorherige Lauf ohne detaillierte Zusatzinstrumentierung (`walk-v3`) hatte
4717 Spielframes und acht echte Übergänge. Dort wurde ein 535-ms-Hitch erfasst.
Die 47 `WorldResidency.record`-Ereignisse zählen Bestandsaufnahmen, nicht 47
Geometrie-Neubauten. Die erfassten `ChunkMesher.invalidate`-/
`TerrainAtlas.invalidate`-Aufrufe liefern in dieser Strecke keinen Beleg für
eine allgemeine Cache-Verdrängungsschleife.

## Korrektheit und Ladefreigabe

- Sechs passende Headless-Suiten bestanden: kalte/veröffentlichte Fensterlichter,
  Lichtinstanzen, Lichtauswahl, Fehlerisolierung, Hitch-Diagnose und Wasserziele.
- Der neue Regressionstest verbietet synchronen Analyseaufbau aus der Beleuchtung
  ausdrücklich. Er prüft nachträgliche Veröffentlichung, Nachbarschaftsversatz,
  Höhen, Stärke, Entfernung nach Invalidierung sowie den separaten Gen-2-Pfad.
- 24 native Bildvergleiche: je vier Ansichten in Celadon, Route 7 und Saffron,
  mit umgebauten und ursprünglichen Gebäuden. Die finalen Läufe sind vollständig
  pixelgleich. Der native Test toleriert höchstens eine 8-Bit-Farbstufe;
  tatsächlich war in diesen finalen Läufen die Differenz null.
- Mit ursprünglichen Gebäuden wurden 305 / 839 / 625 native Fensterlichtquellen
  verglichen. Positionen, Stärke und Blocker stimmen als Daten exakt überein.
  Die umgebauten Gebäude beziehen ihr Licht aus dem bestehenden anderen Pfad;
  dort ist die native Fensterlichtliste leer.
- Referenz- und Kandidatenbilder wurden mit eingefrorenem Frame-Delta **und**
  eingefrorener Wandzeit aufgenommen. Frühere Versuche waren durch weiterlaufende
  Figuren-/Schwimmbewegungen verfälscht und gelten nicht als Bildvergleich.
- Native „Weiter“-Prüfung in Celadon bestanden: Nachbarschaftsfreigabe und
  Grafikvorbereitung weiterhin erfüllt. Kaltes Spiegelungsziel 855×478 entstand
  unter Ladeabdeckung; keine späte Zielanlage im Spiel. Ladeanzeige nach 4,84 ms,
  Szene bereit nach 3,35 s; Gesamtmessung 4,80 s. Maximaler abgedeckter Frame
  133,95 ms. Kein belegter allgemeiner Ladezeitgewinn.

Ein versehentlicher Headless-Aufruf der GPU-Suite `local_light_grid_test.lua`
scheiterte an deren nativer `arg`-Voraussetzung. Er ist in
`headless-first-attempt.log` erhalten und wird nicht als bestandener Test gezählt.
Die sechs finalen Headless-Suiten stehen in `headless.log`.

## Verbleibende Arbeit

Die übrigen Ausschläge sind nicht wegoptimiert. Der neue Lauf enthält weiterhin
Frames über 100 ms, teils außerhalb der erfassten Spiel-Callbacks. Weitere
konkrete Ansatzpunkte sind erste Pokémon-Modellvorbereitung im Renderpfad und
Karten-Eintrittsereignisse (`internal_wilds`, `extended_characters`). Auch die
Ladeanimation hat noch lange Einzelbilder. Weitere Strecken, Innenräume und
physische schwächere Geräte sind für eine breite Abnahme erforderlich.

## Sicherung

`/Users/maarten/Documents/Recompile/artifacts/performance-travel-20260928/`
enthält Rohtraces, Vergleichsdaten, Bilder, ursprüngliche Produktionsdateien,
einen auf diese Runde begrenzten Patch und SHA-256-Prüfsummen. Keine Releases,
Commits oder Änderungen persönlicher Spielstände. Die fehlgeschlagenen frühen
Weg-/Bildtest-Versionen bleiben als Diagnosematerial erhalten; gültige Läufe
sind `walk-v3`, `traced`, `fixed-traced`, `reference-repeat`, `quality-clock`,
`quality-native-final` und `continue`.
