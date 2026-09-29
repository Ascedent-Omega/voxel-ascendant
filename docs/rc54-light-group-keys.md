# RC54 – Weniger temporäre Tabellen beim Gruppieren von Fensterlichtern

29.09.2026. Die sechs Bestandteile eines Lichtgruppen-Schlüssels werden direkt verkettet. Damit entfällt die kurzlebige Sechser-Tabelle für jede Scheibe. Zellgröße, Besitzertrennung, Fassadennormale, Reihenfolge und sämtliche resultierenden Lichtwerte bleiben gleich. Keine geringere Lichtanzahl oder Qualitätsstufe.

Anlass: Im nativen Celadon-/Route-7-Rundlauf wurden bis 9,73 ms für `LocalLightGrid.sources` innerhalb einer größeren Lichtvorbereitung gemessen. Die Funktion wird auch bei der einmaligen Aggregation dichter Gebäudefassaden verwendet.

Gleichheit: Vollständiger rekursiver Vergleich mit der gespeicherten vorherigen Implementierung für 300, 3000 und 12000 Eingangslichter sowie 96 Grenzfälle mit negativen/gebrochenen Koordinaten, vier Normalen und unterschiedlichen Besitzern. `tests/light_source_groups_test.lua` prüft zusätzlich konkrete Gruppenwerte und unveränderte Eingaben. Native Prüfung mit `tests/native/rc45_index_staging.lua`: Hashes der GPU-Texturen für Lichtdaten, Indizes und Sichtbarkeit sowie der statische Cache-Schlüssel unverändert; stufenweise Veröffentlichung und Abbruchfreigabe bestanden.

CPU-Mikrobenchmark mit der eingebetteten LÖVE-Lua-Laufzeit, Alt/Neu/Alt und vorheriger Aufwärmung. Drei Wiederholungen. Mediane in ms pro vollständiger Gruppierung:

| Eingangslichter | Alt | Neu | Alt-Kontrolle |
|---|---:|---:|---:|
| 300 | 0,097 | 0,080 | 0,100 |
| 3000 | 1,002 | 0,795 | 0,974 |
| 12000 | 6,206 | 4,604 | 6,336 |

Einzelmessungen schwanken, insbesondere beim größten Fall. Das ist ein gezielter Gewinn in dieser Funktion, kein Beleg für insgesamt 20–30 % mehr FPS und keine Lösung für alle Nachladeruckler.

Reproduzierbarer Vergleich und Rohdaten: `/Users/maarten/Documents/Recompile/artifacts/performance-light-group-keys-20260929/probe.lua`, `benchmark.txt`, `gpu/run.log`. Der dortige Checkpoint sichert exakt die eine Produktionsdatei, den Vertragstest und dieses Dokument.
