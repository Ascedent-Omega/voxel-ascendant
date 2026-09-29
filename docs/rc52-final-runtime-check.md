# RC52/53 – Bildausgabe und abschließende Laufstrecken

29.09.2026. Diagnose und Prüfung; diese beiden Treiber verändern keine Produktionsfunktionen auf der Festplatte.

`rc52_present_travel.lua` ergänzt die vorhandene CPU-Diagnose um Bildausgabe, Event-Pump und die Warte-/Pacing-Funktionen der Hauptschleife. Diese Arbeit liegt nach `love.draw` beziehungsweise vor dem folgenden `love.update`; sie wird deshalb dem vorangehenden Trace-Frame zugeordnet und mit dem nächsten `dt` verglichen. Wall-Time ist kein GPU-Timer.

Der zuvor beobachtete Abstand von 191,72 ms ließ sich im Wiederholungslauf nicht reproduzieren. Gemessen wurden einzelne Wartezeiten von 20,94 ms in `present` und 20,68 ms in der Event-Pump. Die größten nicht vom QA-Treiber verursachten Ausschläge auf der synthetischen Celadon-/Route-7-/Route-16-Strecke waren 69,90 und 53,34 ms, mit Geometrie-/Lichtaufbereitung und Karteninitialisierung als wesentlichen Callback-Anteilen. Die synthetischen Kartenwechsel garantieren keine vollständige Region-Vorbereitung.

Der zweite Lauf nutzt den echten Übergang aus Silph nach Saffronia und wartet auf die normale Gebietsvorbereitung. 13 Karten wurden vorbereitet. Vier optionale Nachbarpanoramen wurden wegen unvollständiger Nachbarschaft nicht zusätzlich vorgebaut. Auf der anschließenden Strecke: 5622 ausgewertete Frames, mittlerer Bildabstand 14,36 ms, p95 19,60 ms, Maximum 91,76 ms. Der größte Ausschlag kombiniert etwa 49 ms Callback-Zeit und 38 ms `present`. Das belegt keine isolierte Ursache im Grafiktreiber.

## Weniger Messaufwand

`rc53_lightweight_walk.lua` misst nur Update, Draw und Present sowie die diagnostische Wegsuche. Die zahlreichen Detail-Wrapper auf Modell-, Shader-, Ereignis- und Dateifunktionen entfallen. Die Wegsuche und ihr folgender Frame, Vorbereitung, Beruhigungsframes sowie Screenshots/Dateiausgabe werden aus der Laufstrecke ausgeschlossen.

Gemeinsame Einstellungen: Voxelgebäude und Figuren, Fenster aktiviert, Nacht, Regen, FULL-Wasser, Third Person, 1710 × 958 Ausgabefenster, interne Auflösung BALANCED, AA 0. **Die bisherigen Referenzstrecken hatten Tilt-Shift ausgeschaltet.** Sie sind deshalb kein Beleg für die vollständige Nachbearbeitung aus den Nutzerbildern. Ein gesonderter Lauf aktiviert ausdrücklich Stufe 3; der Treiber prüft und speichert den tatsächlich aktiven Wert.

| Lauf | Frames | Mittlerer Bildabstand | p95 | Maximum | >33,33 ms |
|---|---:|---:|---:|---:|---:|
| Saubere Wiederholung, 512-MB-Cache, Tilt-Shift aus | 5680 | 16,25 ms | 21,36 ms | 45,04 ms | 19 |
| 128-MB-Cache, Tilt-Shift aus | 5670 | 15,65 ms | 20,83 ms | 106,40 ms | 17 |
| 512-MB-Cache, Tilt-Shift Stufe 3 | 5616 | 16,41 ms | 24,08 ms | 80,67 ms | 52 |

Der Lauf mit Stufe 3 ist regulär beendet; der aktive Pipelinewert wurde am Ende geprüft und im Trace gespeichert. Acht Bildabstände überschreiten 50 ms. Screenshot visuell geprüft: Voxelgebäude, beleuchtete Fenster, Figuren, Regen und Tiefenunschärfe sind vorhanden. Ein NPC verändert einen Zielpunkt um eine Zelle. Das ist kein gepaarter Effektkosten-Benchmark; die drei Laufmittel dürfen nicht als isolierter Vorher/Nachher-Gewinn interpretiert werden.

Beim 128-MB-Lauf endet die optionale Gebietsvorbereitung mit `limited=memory` und einem Eintrag in der Vorbereitungsliste. Die benötigte sichtbare Nachbarschaft bleibt separat geschützt. Das ist kein vollständiger 13-Karten-Vorladevorgang und keine 128-MB-Grenze für den gesamten Prozess. Die Cachebegrenzung wurde für den Test gesetzt; Produktionsdefaults wurden nicht erhöht.

Der erste leichtgewichtige Lauf ist zusätzlich abgelegt, aber wegen kurzer Überschneidung mit einem CPU-Mikrobenchmark am Ende nicht die saubere Abschlussreferenz. Auch die Wiederholung läuft auf dem normalen Desktop mit bestehenden anderen Anwendungen. Diese wurden nicht beendet. Testgerät: Mac14,15, 16 GiB RAM. Keine physische iPhone-/Switch-Prüfung.

## Abschließende Übergänge (RC55)

`rc55_transition_final.lua` nutzt dieselbe leichtgewichtige Messung und aktiviert Tilt-Shift Stufe 3 für den vorhandenen echten Übergangstest. Bestanden: Eintritt in Silph, Terrain-/Atlas-/Hilfsgeometrie-Bereitschaft aller elf Etagen plus Aufzug, verdeckte Vorbereitung mit Ladeanzeige, einmalige Callback-Ausführung, Etagenwechsel ohne erneuten Gebäudeplan sowie Austritt. Eintritt 6,64 s; 914 Wiederverwendungen der verdeckten Szene über den gesamten Test. Kameraschwenk auf der Etage: p95 18,30 ms, Maximum 28,52 ms. Der Schwenk nach Austritt ist kein Ersatz für die getrennte freie Straßenstrecke.

Zusätzlich wurde „Weiter“ aus Silph 6F getestet. Der erste Versuch scheiterte an der neuen Diagnose, weil im Titelmenü `overworld.map` fehlt; die Abfrage im Diagnosetreiber ist korrigiert. Im zweiten Versuch waren Zielszene und zwölf Innenkarten bereit, die zusätzliche Bedingung `QA_LAST_OUTDOOR=SAFFRON_CITY` schlug jedoch fehl: Saffronia gehört nicht zum abgeschlossenen Gebäude-Vorbereitungssatz. Das entspricht dem derzeitigen getrennten `building`-Plan, beweist aber **keine** gemeinsame Vorbereitung von Innengebäude und Außenstadt beim Fortsetzen. Dieser zusätzliche Test ist nicht bestanden; die Produktionslogik wurde dafür nicht kurzfristig verändert. Beide Versuche sind terminal beendet, nicht weiterlaufend.

Artefakte und Rohdaten: `/Users/maarten/Documents/Recompile/artifacts/performance-present-stalls-20260929`. `retained-state-verification.json` prüft die jeweils letzte Version aus den RC39–RC51-/RC54-Checkpoints: 75 Dateien ohne Abweichung. Ein gesonderter Checkpoint enthält nur diese Dokumentation und die drei neuen Diagnosetreiber. `transition-final` enthält den bestandenen Übergangstest, `continue-final` und `continue-final-retry` die beiden oben beschriebenen fehlgeschlagenen Zusatzversuche.

Konstante 60 FPS sind damit nicht nachgewiesen. Die gemeldeten 4-FPS-Einbrüche bleiben unaufgeklärt; insbesondere fehlt ein reproduzierbarer Lauf mit genau dieser Spielsituation. Die gesicherten gezielten Optimierungen und die verbleibenden Laufzeitspitzen müssen getrennt bewertet werden.
