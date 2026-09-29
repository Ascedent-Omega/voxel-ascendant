# RC23 – Lichtcache ohne vollständigen synchronen Schreibaufruf

28.09.2026. Die allgemeine Performance-Aufgabe bleibt offen.

## Änderung

Die zuletzt belegte Cache-Persistierung enthielt GPU-Readback, SHA-256, Kompression und Dateischreiben im selben Aufruf. Ein nativer 10-MB-Versuch isolierte etwa 70 ms allein für die Prüfsumme. Jetzt liest der Hauptthread höchstens 512 KiB (mindestens eine Bildzeile) je Vorbereitungsschritt und beginnt erst nach einem zusätzlichen Frame. Ein fester lokaler Worker fügt die Streifen zusammen, prüft und komprimiert sie. Schreiben und Übernahme des Ergebnisses sind getrennte Schritte. Der Cache bleibt im vorhandenen SLF1-Format.

Auch der Laufzeit-Lesepfad validiert und dekomprimiert im Hintergrund; der GPU-Upload erfolgt im nächsten Schritt. Größenlimit (16 MiB), Header, LZ4-Ausgabelänge und SHA-256 werden weiterhin geprüft. Höchstens zwei Cache-Worker dürfen einschließlich verworfener, noch laufender Aufträge existieren. Kein Spielzustand und kein Dateizugriff im Worker. Geräte ohne die bereits deklarierte Compute-Fähigkeit verwenden die normale Lichtberechnung und verzichten auf diesen optionalen Diskcache.

Persistierung zählt zur Ladebereitschaft. Sie arbeitet nur unter der Abdeckung, wird beim Freigeben/Ersetzen ihres Canvas verworfen und kann die Beleuchtung bei einem Schreibfehler nicht deaktivieren. Die Diagnose erfasst nun auch diese Schritte. Der synchrone Leser bleibt für Offline-Prüfwerkzeuge verfügbar; das Spiel verwendet ihn nicht mehr.

## Nachweise

- Nativer 1536×1703-Pixel-Cache: exakt gleiche Pixel nach gestaffeltem Schreiben und Lesen; auch der bisherige Leser versteht die erzeugte Datei. Staged Schreibschritte im isolierten Test maximal 2,46 ms, Lesen maximal 2,94 ms. Falsche Prüfsumme, manipulierte LZ4-Größe und abgeschnittene Datei werden verworfen. Abbruch und Schreibfehler geben Zwischenpuffer frei.
- Echter isolierter, stummer „Weiter“-Ablauf in Celadon mit Nacht, Regen, Wasser, Beleuchtung, 1710×955-Weltcanvas und 128-MiB-Residenzbudget. Je Lauf frischer Cache-Schlüssel ohne Löschen vorhandener Dateien. Die Referenz verwendet ausschließlich den vorherigen synchronen Diskcache im ansonsten gleichen Spielstand. Vorher/Änderung/Nachher:

| Messung | Referenz vorher | Gestaffelt | Referenz nachher |
|---|---:|---:|---:|
| längster Cache-Schritt | 47,21 ms | 8,02 ms | 39,48 ms |
| gesamte Ladezeit | 3,85 s | 3,82 s | 3,57 s |
| größtes abgedecktes Frameintervall | 95,63 ms | 111,50 ms | 98,87 ms |
| anschließende Kamerafahrt, 360 Frames | 56,69 FPS | 57,60 FPS | 57,61 FPS |

Alle drei Läufe bestehen den bestehenden Continue-Vertrag: direkter Nachbarbereich vorbereitet, vollständige Szene vor Freigabe, Cache gespeichert, keine Cachefehler. Die insgesamt rund 81 ms Hauptthread-Arbeit für die gestaffelte Persistierung sind auf 17 Aufrufe verteilt; zusätzliche Readback-Synchronisierung kostet also Gesamtarbeit. Der Nutzen ist der kleinere Einzelblock, kein belegter Gewinn an Gesamtladezeit oder laufenden FPS. Die weiterhin großen abgedeckten Intervalle widerlegen eine pauschale Aussage, alle Laderuckler seien behoben.

- Headless: Ladeabdeckung bis zum Schreibabschluss, keine Persistierung während des Spielens, Abbruch vor Canvas-Freigabe, asynchroner Treffer; außerdem Hitch-Diagnose, Lichtauswahl/-Geometrie, GPU-Ausfallisolierung, Fenster-Tageslicht und bisherige Renderoptimierungen bestanden.
- Bestehender nativer Beleuchtungsvergleich: 11.200 Proben, maximaler Pixelfehler 0.

## Weiter offen

Das frühe Update während der Spielstand-Wiederherstellung hat weiterhin etwa 90 ms Eigenzeit unter der Ladeabdeckung. `restoreSave` ist der nächste Untersuchungsort; seine inneren Teilkosten sind noch nicht getrennt erfasst. Der Lichtcache erklärt diese Spitze nicht. Test-Teleport und Screenshot-Readbacks erscheinen ebenfalls im Gesamt-Hitchbericht, gehören aber nicht zu den 360 gemessenen Spielframes. Keine Aussage über physische iPhone-/Switch-Leistung und keine Behauptung, die gemeldeten 4-FPS-Einbrüche seien insgesamt gelöst.

## Sicherung

Ausgangsdateien, scoped Patch, finale Dateien mit SHA256, Testlogs und Rohdaten liegen unter `/Users/maarten/Documents/Recompile/artifacts/performance-cache-staging-20260928/`. Der vorherige RC22-Zwischenstand bleibt erhalten. Kein persönlicher Spielstand verändert, keine Veröffentlichung.
