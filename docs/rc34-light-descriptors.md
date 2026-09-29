# RC34 – Lichtquellen ohne Möbel-Meshaufbau

28.09.2026. Performanceziel weiterhin offen.

## Ursache und Änderung

LocalLights.prepare nutzte VoxelFurniture.eachWorld(..., true). Dessen
Snapshot-Pfad baut trotz lightsOnly den vollständigen Möbel-Snapshot auf. Damit
konnte eine frühe Lichtvorbereitung auch Objekte ohne Licht einschließlich Meshes,
Texturen und Wintervarianten vorbereiten. Im RC33-Streckenlauf steckten 43,1 ms in
dieser Enumeration; der komplette Frame benötigte 139,3 ms CPU-Zeit.

VoxelFurniture.eachWorldLights liefert nun nur Licht-Metadaten und die gleichen
Weltmatrizen. Sie liest Claimed-/Enabled-Status, Glas-Sichtbarkeit, Modelldaten,
Höhendatum und die aktuelle Leuchtintensität. Nachbar-Offsets und deren
Duplikatunterdrückung verwenden dieselbe Implementierung wie die Renderliste.
Separate lightExtra-Objekte halten die frühen Lichtdaten aus den GPU-Snapshots
heraus. eachWorld und each behalten ihre bisherigen Mesh-Verträge.

LocalLights verwendet die neue Abfrage. Das reduziert unnötige synchrone Arbeit;
das Laden tatsächlich benötigter sichtbarer Möbel bleibt Aufgabe der bestehenden
Geometrievorbereitung. Kein Objekt wird zur Optimierung ausgeschaltet.

Gen2 besitzt einen eigenen LocalLights.prepare-Pfad. Er benutzt bereits
NativeWindowLights und Structures.lightingForMap, das nur bestehende Analyse-
Ergebnisse liest. Die hier reparierte Möbel-Snapshot-Kopplung besteht dort nicht.
Der gemeinsame Lichtkern wurde zusätzlich nativ unter Crystal geprüft.

## Validierung

- Headless: gleiche Metadaten bei Änderungen von Leuchtintensität,
  Glas-Sichtbarkeit, Claims, Enabled, Cutaway, Nachbar-Offsets und Duplikaten.
  Geländehöhe, Dekorationsdatum und gefangene Sichtlisten ebenfalls geprüft.
  Die neue Abfrage führt keine resolveKind-Aufrufe aus und schreibt keine
  GPU-Platzhalter in drawExtra. Bestehender Möbel-Receipt-Test besteht.
- Native Qualität: Celadon, Route 7 und Saffronia, je vier Blickrichtungen,
  Voxel-Gebäude ausdrücklich an, Voxelstufe 6, Nacht und Regen. Zwölf komplette
  Rendervergleiche haben **null abweichende Pixel**. Lichtmodell, Glow, Shade und
  alle 16 Matrixwerte stimmen exakt überein. In der Metadatenabfrage wurden
  resolveKind und snapshot durch werfende Guards ersetzt: kein Aufruf.
  Die 38/80/55 erfassten Deskriptoren pro Kartenansicht sind keine Lampenzählung.
  Das rohe JSON nennt das Feld aus dem Vorgängertest noch nativeLights; der
  gespeicherte Test schreibt zukünftig lightDescriptors.
- Native Crystal: 171/171 erfolgreiche Szenenrender, Voxel3D an, keine
  LocalLights.failure. Das ist ein Funktionskontrolltest, kein FPS-Nachweis.
- Lichtauswahl, Fassadeninstanzen und Fehlerisolation bestehen headless.
  Der GPU-Grid-Test wurde zuerst irrtümlich headless aufgerufen (fehlendes arg,
  danach fehlendes love). Der richtige native Treiber besteht vollständig:
  72 gleichzeitige Lichtquellen, mobiles Budget, Actor-Licht, Blocker, Flicker,
  OFF/Reset, zeitlich begrenzter Aufbau und atomare Veröffentlichung.

## Streckenmessung

Isolierte stumme native QA auf dem Entwicklungs-Mac. Beide Läufe bestehen
Celadon → Route 7 → Celadon → Route 16 → Celadon mit aktivierten Voxel-Gebäuden.
Die Referenz ersetzt ausschließlich eachWorldLights durch den bisherigen
Snapshot-Aufruf. Keine andere Produktionsdatei wird dafür zurückgesetzt.

Setup, abgedeckte Frames und künstliche QA-Wegsuche samt direkt folgendem
Timing-Frame sind aus der Auswertung entfernt. comparison.json enthält Werte:

| Beobachtung | neue Abfrage | alte Abfrage, nachfolgender Gegenlauf |
| --- | ---: | ---: |
| ausgewertete Frames | 2.655 | 2.649 |
| LocalLights.prepare Maximum | 4,11 ms | 9,07 ms |
| LocalLights.prepare Mittel pro Frame | 0,289 ms | 0,404 ms |
| Licht-Enumeration Maximum | 3,89 ms | 8,86 ms |
| gesamte CPU-Framezeit Maximum | 56,63 ms | 78,73 ms |
| Frameabstand p95 | 22,70 ms | 20,69 ms |
| Frameabstand Maximum | 93,73 ms | 82,50 ms |

Das sind zeitabhängige Spielstrecken mit unterschiedlichen Spawns. Die frühere
43-ms-Lichtspitze trat im Gegenlauf nicht erneut auf. Deshalb wird weder aus
43 → 4 ms noch aus einzelnen Frame-Maxima ein allgemeiner FPS-Gewinn abgeleitet.
Die zusätzliche GPU-/Snapshot-Arbeit entfällt nachweislich, und die Lichtabfrage
ist in diesem Gegenlauf günstiger; die Gesamtstabilität ist weiterhin ungenügend.

Verbleibende Spitzen im neuen Lauf: Kartenwechsel-Callbacks (bis 37,3 ms
setMap, darunter Stadt-Pokémon und Charakterzuordnung mit jeweils etwa 15 ms),
sowie erstmals benötigte Pokémon-Modelle (bis 22,4 ms Content.record). Deren
Vorladen beziehungsweise Lastverteilung bleiben nächste notwendige Arbeiten.

Artefakte: artifacts/performance-light-descriptors-20260928. Kein Release und
keine persönlichen Spielstände verändert. Alle Testprozesse sind beendet.
