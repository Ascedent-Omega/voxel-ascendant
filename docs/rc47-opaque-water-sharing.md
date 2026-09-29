# RC47 – feste Objekte für Wasserspiegelungen nur einmal zeichnen

29.09.2026. Zwischenstand, keine Abnahme der gesamten Performance. Der gemeldete 4-FPS-Fall bleibt unaufgeklärt.

## Änderung

Im Gen-1-Desktop-Pfad mit FULL-Wasser und lesbarer Tiefe werden die festen Möbel, Bäume und Voxelgebäude vor der Spiegelungskopie in die Szene gezeichnet. Die Kopie enthält damit bereits deren Farbe und Tiefe. Der Reflexions- und der spätere sichtbare Figurenpass zeichnen weiterhin Figuren, Blüten und sonstige Dekoration, aber die festen Objekte nicht erneut. Der bisherige kombinierte Furniture.draw-Einstieg bleibt für andere Aufrufer erhalten.

SKY, OFF, fehlende lesbare Tiefe und der bestehende mobile Pfad behalten ihre bisherige Reihenfolge. Die Anzahl der Modelle, Gebäude, Lichter oder Wasserwellen wird nicht reduziert. Die Reflexion ist nicht pixelidentisch: Ihre Tiefensuche kennt jetzt auch die tatsächlich davorstehenden festen Objekte. Gen 2 ist nicht Teil dieser Änderung.

## Messung

Isolierte, stumme LOVE-11.5-QA, volle Voxelgebäude, Nacht/Regen, FULL-Wasser, 1710×958, bestehende balanced-Auflösung. Zwei bewegte Saffronia-Referenzen und ein Kandidat liefen jeweils mehr als 5.600 sichtbare Frames. Pfadsuche des Testtreibers sowie der folgende Delta-Frame wurden ausgeschlossen. Die ursprünglichen Treiber notierten den Frame nach dem Coroutine-Resume; die korrigierte Auswertung ordnet ihn dem tatsächlich gemessenen vorherigen Frame zu. Damit gehören JSON-/Screenshot-Erzeugung am Ende nicht zur Spielmessung. Die Treiber speichern diese Zuordnung jetzt direkt.

Der bewegte Vergleich ist **kein eindeutiger Mittelwertgewinn**: mittlere CPU-Zeit 10,88 / 11,54 ms in den Referenzen und 13,41 ms im Kandidaten. Die CPU-p95 lag bei 20,22 / 21,03 und 20,39 ms. Der Kandidat hatte 14 CPU-Frames über 33,33 ms, die Referenzen 17 und 37. Laufstrecke/NPC-Ausweichwege und Systemlast schwanken; daraus keine generelle FPS-Steigerung ableiten.

Zusätzlich derselbe Prozess mit festen Third-Person-Ansichten, je 240 Frames alt / neu / alt:

| Szene | CPU alt | CPU neu | CPU Kontrolle | gesamte Framezeit alt / neu / Kontrolle |
|---|---:|---:|---:|---:|
| Saffronia, Ansicht 1 | 14,84 ms | 13,40 ms | 13,94 ms | 17,35 / 16,23 / 16,90 ms |
| Celadon, Ansicht 2 | 13,09 ms | 10,87 ms | 12,50 ms | 16,35 / 14,34 / 15,63 ms |

Dort fallen die Prop-Batch-Aufrufe von zwei auf einen pro Frame. Andere Phasen zeigen deutliche Drift oder keinen belastbaren Gesamtgewinn; sämtliche Daten bleiben in paired/summary-corrected.json erhalten. CPU-Messungen enthalten Treiberwartezeiten und sind keine GPU-Zeitstempel.

## Prüfungen und Grenzen

- Native Sichtprüfung: Celadon mit Teich, Figuren und Gebäudespiegelung, Saffronia sowie Silph-Eingang/Brunnenraum in erster und dritter Person. 24 Ansichten mit Alt/Neu/Kontrollbildern gespeichert. Einige trockene Ansichten sind exakt gleich; dynamische Reflexionen unterscheiden sich auch zwischen den zwei Alt-Aufnahmen. Deshalb kein pauschaler Pixelgleichheitsnachweis.
- Ausführbarer Reihenfolgetest prüft einmaliges Zeichnen fester Objekte, beide Dekorations-/Figurenpässe, Ghost-/Grasreihenfolge, Material-/Raumzustand sowie SKY/OFF/tiefenlosen/trockenen Rückfall.
- Bestehende Tests für iOS-Grasreihenfolge, Furniture-Receipts, Lichtbeschreibungen und WaterReflection-Fehler/Freigaben bestanden.
- Keine Messung auf physischem iPhone oder Switch. Keine dauerhaften 60 FPS zugesagt. Alle vorherigen Lade-/Cachekorrekturen bleiben erhalten.

Artefakte: `/Users/maarten/Documents/Recompile/artifacts/performance-saffron-street-20260929`.
