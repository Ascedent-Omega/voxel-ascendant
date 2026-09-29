# RC21 – Nachladearbeit und Stabilität

Stand: 28.09.2026. Implementierung im Worktree `vasc-video-polish-halloween-20260926`.

Die Änderungen reduzieren nachträgliche Ressourcen-Erzeugung und doppelte Vorbereitung. Ein allgemeiner FPS-Gewinn und die Behebung aller gemeldeten 4-FPS-Einbrüche sind damit **nicht belegt**.

## Umgesetzt

- **Instanz-Batches:** Update und Draw teilen sich eine Vorbereitung pro Frame (3 ms unter Ladeabdeckung, 0,5 ms im Spiel). Das Budget beginnt vor der Bestandsaufnahme. Große Kopien nutzen die vorhandenen portionierten GPU-Uploads. Fehlende Batches werden beim Zeichnen nicht mehr synchron erzeugt: Bis zur Vorbereitung werden dieselben Original-Meshes gezeichnet. Unter vollständiger Ladeabdeckung wartet die Darstellung auf vorbereitete Batches.
- **Unveränderte Szenen:** Die vorhandenen unveränderlichen Möbel-Snapshots dienen als Gültigkeitsnachweis. Gleiche Geometrie und gleiche Nachbarschaft müssen nicht erneut für Batches gezählt werden. Änderungen, fehlgeschlagene Auflösungen und dynamische Ansichten umgehen die Wiederverwendung. Systeme ohne Instancing, einschließlich des derzeitigen Mobilpfads, bezahlen diese zusätzliche Prüfung nicht.
- **Doppelte Validierung:** Nach einem wirkungslosen oder pausierten Mesher-Aufruf wird die bereits validierte Möbelszene nicht nochmals verworfen. Ein Zähler tatsächlicher Coroutine-Aufrufe erhält die erneute Prüfung nach echten Bauschritten.
- **Figuren:** Im natürlichen Animationsmodus werden die zwölf vorhandenen Richtungs-/Schritt-Kompositionen der tatsächlichen Figuren im aktuellen Raum vorbereitet, jeweils eine pro Update. Vorbereitung und Darstellung verwenden denselben Cache und verändern keine Animationsposition. Bestehende Grenzen gelten weiter: 128 Quellen und 10.692.000 Canvas-Pixel (rund 40,8 MiB RGBA-Pixeldaten, ohne Treiber-Overhead). Ein endlicher Cursor verhindert endlose Verdrängungs-/Ladeschleifen bei großen Figurenmengen; optionale Fehler blockieren den Übergang nicht.
- **Beleuchtung:** Auch beim Kartenwechsel wird die CPU-Aufteilung des Lichtgitters respektiert. Eine neue Karte erhält währenddessen nicht versehentlich das Gitter der vorherigen Karte. Mehrere Shader-Abfragen desselben Frames liefern dieselbe noch ausstehende Antwort. Auf derselben Karte bleibt das vorige vollständige Gitter bis zum atomaren Austausch nutzbar.

Die Zeitbudgets sind kooperativ: einzelne native Grafikaufrufe, Texturpaketierung und synchrone Fremdaufrufe können weiterhin länger dauern. Sie sind keine harte Obergrenze für die gesamte Frame-Zeit.

## Messung nach „Weiter“

Celadon, Nacht/Regen, natürliche Voxel-Figuren, zwei vollständige Kameradrehungen über 600 Frames, 128-MiB-Szeneriecache, bestehende 1710×958-Testkonfiguration. Separates QA-Save, alle Testläufe stumm.

| Messwert | Vorher | Aktueller Stand |
|---|---:|---:|
| Neue Meshes in den 600 Spielframes | 47 | 34 |
| Neue Canvas-Texturen | 15 | 1 |
| Neue Bilder | 4 | 7 |
| Neue Shader | 0 | 0 |
| Ø erfasste Update-/Draw-CPU-Zeit | 9,58 ms | 8,75 ms |
| Ø FPS | 48,98 | 49,73 |
| 95. Perzentil Frame-Zeit | 33,28 ms | 33,30 ms |
| Schlechtester Spielframe | 54,09 ms | 54,98 ms |
| Gemeldeter Texturspeicher | 130,65 MiB | 156,53 MiB |

Im aktuellen Lauf gab es nach Freigabe **keine GPU-Neuanlage aus VoxelPropBatch**. Andere Figuren-Meshes und optionale Umgebungsbilder entstehen noch während des Spiels. Die rund 26 MiB zusätzlich früh belegten Texturen sind der Preis für vorbereitete Figurenansichten.

Die beobachteten Zahlen sind keine kontrollierte Hardware-Leistungszusage: Instrumentierung verursacht Aufwand, optionale Hintergrundbilder variieren, und die diskbasierten Lichtdaten waren vorher kalt und zuletzt bereits vorhanden. Die Ladezeit von 3,50 auf 3,34 Sekunden ist deshalb **kein belegter Ladezeitgewinn**. Die praktisch gleichen oberen Frame-Zeiten zeigen, dass die verbleibenden Renderkosten noch nicht gelöst sind.

Ein Zwischenlauf fiel auf 30,38 FPS. Während der späteren Messungen war außerdem ein separater, nicht von diesen Tests gestarteter LOVE-Prozess aktiv; dieser wurde nicht verändert. Alle Ergebnisse einschließlich schlechterer Läufe bleiben im Artefaktordner erhalten.

## Nachtbeleuchtung: getesteter Versuch verworfen

Ein zusätzlicher Shader-Zweig übersprang garantiert schwarze Lichtzellen. Ein nativer Pixelvergleich inklusive Interpolationsrand, schrägen Flächen und dynamischen Lampen ergab exakt gleiche Pixel. In abwechselnden Bewegungsdurchläufen in Celadon und Saffron war der Zweig jedoch nicht zuverlässig schneller und mehrfach langsamer. Shader-Zweig, zusätzliche Indexdaten und produktiver Schalter wurden vollständig zurückgenommen. Versuchscode und Ergebnisse liegen unter `rejected-empty-cell/` und `empty-probe/`.

Die bestehende Beleuchtungsqualität wurde nicht reduziert.

## Prüfungen

- 11 Headless-Testdateien bestanden: Batch-Vorbereitung, Snapshot-Gültigkeit, bisherige Renderoptimierungen, Ressourcenfreigabe, Frame-/Horizon-Budgets, Außenweltaufbau, Regionen, Wärterhaus-Vorbereitung, Cache-Verdrängung und isolierte Beleuchtungsfehler. Der Batch-Test bestand zusätzlich 100 unabhängige Läufe mit unterschiedlicher Tabellenreihenfolge.
- Native Grafiktests bestanden: 72 gleichzeitige Lichter, neuer Kartenwechsel mit gestaffeltem Lichtgitter, atomare Veröffentlichung, OFF/Reset sowie statisches Lichtfeld und Disk-Cache. Finale produktive Shader geprüft.
- Neuer Figuren-Grafiktest bestanden: zwölf vorbereitete Kompositionen pixelgleich zum bisherigen Bedarfspfad; eine Komposition pro Schritt; Wiederverwendung beim Zeichnen; unveränderte Pose; vollständiges Freigeben; endlicher optionaler Fehlerpfad.
- Native „Weiter“-Tests in Celadon und Saffron bestanden, jeweils mit anschließender Kamerafahrt. Im letzten Saffron-Lauf wurde die Ladeabdeckung nach rund 5 ms sichtbar; es gab trotzdem einen 231-ms-Frame unter der Abdeckung. Solche langen Einzelaufrufe bleiben eine Grenze.
- Wärterhaus Route 7 in beiden Richtungen bestanden. Zusätzlich wurde das Ziel künstlich vier Sekunden blockiert: Ladeabdeckung, Eingabesperre und animiertes Ladesymbol blieben erhalten; benötigte direkte Nachbar-Terrain-/Atlasdaten waren vor Freigabe vollständig. Bei 128 MiB bleibt die optionale Regionsvorbereitung bewusst begrenzt; nicht alle entdeckten Innenräume werden gleichzeitig resident.
- Bewegungsprüfungen über je 600 Frames, Nacht/Regen: Celadon 36,28 FPS (p95 35,91 ms), Saffron 46,59 FPS (p95 29,33 ms). Diese Diagnosewerte unter wechselnder Systemlast sind kein fairer Vergleich mit früheren Läufen.
- Ladebild und Ankunftsbild visuell geprüft. Physische iPhone-/Switch-Tests wurden nicht durchgeführt.

## Sicherung und Nachvollziehbarkeit

Der vollständige, bereits SHA256-geprüfte Zwischenstand liegt weiterhin unter:
`/Users/maarten/Documents/Recompile/artifacts/performance-checkpoint-20260928/workspace.tar.gz`.

Der aktuelle Durchgang liegt unter:
`/Users/maarten/Documents/Recompile/artifacts/performance-stability-20260928/`.

Dort stehen ursprüngliche Dateien in `baseline/`, die begrenzte Änderung in `implementation.patch`, SHA256-Werte in `implementation-files.json`, alle nativen Logs/Bilder, Rohtraces und `trace-comparison.json`. Die Rückwärts-Anwendbarkeit des Patches wurde geprüft. Der Patch betrifft nur diesen Durchgang; fremde oder frühere Änderungen des Worktrees bleiben erhalten.
