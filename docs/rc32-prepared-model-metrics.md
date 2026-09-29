# RC32 – Animationsmaße vorab berechnen

28.09.2026. Weiterer Zwischenstand; das übergreifende Performanceziel bleibt offen.

## Änderung

Der erste Cobblemon-Aufbau durchläuft bisher 16 Animationsstellungen für die
Kampfgröße und bis zu 32 weitere für die Overworld-Größe. Jede Stellung berechnet
Skeletttransformationen und tatsächliche Vertex-Grenzen. Diese Zahlen hängen von
Modelldaten und Algorithmen ab, nicht vom laufenden Spielstand.

`tests/native/rc32_bake_metrics.lua` berechnet diese Maße mit den echten nativen
`StadiumRig`-, `CobblemonSize`- und `CobblemonOverworldSize`-Routinen vorab. Es setzt
vorhandene Metadaten ausdrücklich zurück, damit eine erneute Generierung wirklich
misst. Ausgabe zunächst nach `SHOT_DIR/metrics.bin`; erst der bestandene vollständige
Roundtrip wurde als `assets/cobblemon-binary/metrics.bin` übernommen.

Die Datei enthält sechs ungerundete LE-Doubles je ursprünglichem Modellhash:
Kampfhöhe/-spanne, Overworld-Höhe/-spanne und Mews körperbezogene Grenzen. Alle
1.069 referenzierten Modelle konnten vorbereitet werden; keine fehlgeschlagenen
Messungen. Gesamtgröße **85.592 Bytes**.

`CobblemonMetrics` verifiziert Format, Länge, Gesamtchecksumme und den Hash der
exakten fünf mathematischen Implementierungen. Erst dann darf `CobblemonContent`
die passenden Modellmetadaten anhängen. Die Größenroutinen übernehmen die geprüften
Maße in ihre bestehenden modellgebundenen Caches. Endgültige Größenpolicy,
Animation und sichtbare Geometrie bleiben unverändert. Andere/neu importierte
Modelle oder geänderte Berechnungsquellen verwenden weiterhin die Live-Berechnung.
Fehlende oder beschädigte optionale Daten blockieren die Darstellung nicht.
Die Metadaten verursachen keine Dateizugriffe pro Frame und keine neuen GPU-Bilder.

Primo 2 löst den neutralen Metrikleser sowie die Overworld-Messquelle zum Prüfen
ihres Algorithmushashs am Paketwurzelpfad auf. Seine eigene Größenpolicy wird nicht
auf die Gen-1-Overworld-Policy umgestellt. Der Paketbauer prüft zusätzlich den
aktuellen Algorithmusstempel, Dateihash, Struktur und Modellzuordnung.

## Verifikation und Messergebnis

Native LOVE-Läufe auf dem Entwicklungs-Mac, stumme isolierte QA. Referenz ist
RC31 **mit aktivem Binärmodellcache**, jedoch ohne die neuen vorbereiteten Maße.
Je zwölf erstmals erzeugte Modelle; Referenz/Kandidat in alternierender Reihenfolge.
Zeit umfasst Laden, Rig, Größenberechnung, Pose und Upload. Kein FPS-Benchmark.

| Stichprobe | bisher Summe | vorbereitet Summe | größte Einzelzeit bisher → vorbereitet |
| --- | ---: | ---: | ---: |
| Primo 1 inklusive Overworld-Größe | 326,55 ms | 107,74 ms | 56,97 → 18,69 ms |
| Primo 2 / Crystal, eigene Modellgröße | 168,82 ms | 98,47 ms | 32,65 → 18,88 ms |

Die absoluten Werte beider Generationen sind wegen unterschiedlicher Größenpfade
nicht unmittelbar vergleichbar. In beiden Vergleichen stimmen Skalierung, sämtliche
geposeten Mesh-Zeilen und die von GPU-Texturen zurückgelesenen Pixel exakt überein.
Alle Kandidaten verwendeten nachweislich vorbereitete Maße, alle Referenzen die
Live-Berechnung. Beide Varianten lasen ausschließlich die binären Modelldaten.

Weitere Prüfungen:

- Vollständige native Erstellung und exakter Double-Roundtrip aller 1.069 Modelle.
- `rc32_metrics_lifecycle`: wiederholte Abfragen ohne wiederholte Dateizugriffe,
  unbekannter Modellhash, fehlende/werfende/stale Quelldaten, Trunkierung, falsches
  Format/Checksumme/Anzahl, sowie gültige Checksumme mit ungültigen Zahlen. Frischer
  Loader erholt sich mit intakten Daten. Alle Fälle bestanden.
- Bestehende Kampf- und Overworld-Größenprüfungen, Receipt-Fallback und
  Gen-2-Modulpfade bestanden. Der erste Headless-Aufruf des Overworld-Tests hatte
  keinen erforderlichen Root-Parameter; der korrigierte Wrapper besteht.
- Paket-Dateiliste enthält alle 1.070 Binärdateien inklusive Metriken. Aktueller
  Algorithmusstempel und vollständige Prüfsumme separat geprüft.

## Fahrt mit voller Darstellung

`travel` besteht Celadon → Route 7 → Celadon → Route 16 → Celadon. Voxel-Gebäude
explizit an, Voxelstufe 6, Nacht, Regen, Tiltshift 3; 2.275 aufgezeichnete
Streckenframes und vier Kartenwechsel. Der erweiterte Trace enthält 2.746 Frames
einschließlich Setup/Abdeckung. Er ist kein direkter Vorher-Nachher-FPS-Vergleich.

Die vorbereitete Kampfgröße benötigte höchstens 0,0043 ms pro sichtbarem Frame
statt der früheren Animationsdurchläufe. Mehrere neue Modelle in demselben Frame
benötigen zusammen weiterhin bis zu 34,1 ms für `setSpecies`. Beim Rückweg nach
Celadon kommen beispielsweise zwei Modelllesevorgänge (11,2 + 14,3 ms) zusammen.

Nach Ausschluss von Setup-Frame 0, Abdeckungen und Frames mit der künstlichen
QA-Wegsuche sowie deren direkt folgendem Timing-Frame verbleiben 2.629 Frames:
Frameabstände Median 13,42 ms, p95 22,23 ms, p99 32,50 ms, Maximum 83,23 ms.
CPU-Messung in derselben Auswahl: Median 10,73 ms, Maximum 59,22 ms.
Unzugeordnete Wartezeit wird nicht als GPU-Zeit ausgegeben. Der 512-ms-Frame 0
gehört zur synchron eingesetzten Testszene und ist kein Nachweis eines sichtbaren
Spielrucklers. Der echte Weiter-Ladeablauf war zuletzt unter RC31 separat geprüft.

Es bleiben reale Spitzen beim Kartenwechsel, bei gleichzeitig neuen Modellen und
bei Gelände-/Einrichtungsarbeit. Konstante 60 FPS und schwache Mobilgeräte sind
weiterhin nicht nachgewiesen. Diese Änderung reduziert den Erstaufbau deutlich,
ersetzt aber weder eine saubere Lastverteilung noch weitere Streckenprüfungen.

Artefakte im Hauptarbeitsbereich: `artifacts/performance-model-metrics-20260928`.
Kein Release oder persönlicher Spielstand verändert; alle gestarteten Tests beendet.
