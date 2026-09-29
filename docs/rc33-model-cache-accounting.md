# RC33 – Modellcache ohne zweiten vollständigen Datenlauf

28.09.2026. Zwischenstand, das Performanceziel bleibt offen.

## Änderung

CobblemonPack schätzte nach jedem erstmaligen Content.record-Aufruf die Größe des
vollständigen Modellbaums mit einem weiteren rekursiven Durchlauf. CobblemonBinary
führt dieselbe konservative Buchhaltung jetzt während des ohnehin notwendigen
Decodierens aus: 128 Bytes pro Tabelle, 48 pro Eintrag, Stringlänge plus 24 pro
Stringvorkommen. Zahlenvektoren können ihre Einträge gesammelt anrechnen. Der
geteilte JSON-null-Sentinel wird nur einmal angerechnet.

Der Decoder gibt die Schätzung als zweiten Rückgabewert aus; Content reicht sie
am Modell weiter. Pack ergänzt die nachträglich angehängten Größenmetadaten und
die bisherige Reserve von 16 KiB. JSON-Fallbacks werden weiterhin vollständig
gemessen. Cache-Limit (12 MiB), LRU, Textureinrechnung und Besitz aktiver Bilder
bleiben gleich. Keine Änderung an Darstellung, Geometrie, Skalierung oder den
Quellen des vorberechneten Metrikstempels.

## Prüfung

Isolierte, stumme native LOVE-QA auf dem Entwicklungs-Mac. Vorher ist der RC32-
Stand, gesichert in baseline/lib. Beide Seiten verwenden Binärmodelle und bereits
vorbereitete Animationsmaße.

- Alle 1.069 Modelle: rekursiv gleiche Werte und exakt gleiche Speicherabschätzung.
  Binärprüfung/Decode samt Buchhaltung insgesamt 7.743 → 5.672 ms (-26,7 %).
  Das ist die Summe separater Modellladungen, kein Frame- oder Startzeitgewinn.
  Das rohe decode.json benutzt aus dem Vorgängertest noch die Bezeichnungen
  jsonMs/binaryMs; tatsächlich wurden auf beiden Seiten Binärdaten decodiert.
  Der gespeicherte Test benennt diese Felder künftig oldMs/newMs.
- Je zwölf vollständig aufgebaute Modelle, alte/neue Reihenfolge alternierend:
  Primo 1: 116,63 → 87,25 ms Summe, Maximum 20,43 → 17,18 ms.
  Primo 2 (Crystal): 101,59 → 81,01 ms Summe, Maximum 16,49 → 14,43 ms.
  Genaue Pose/Meshwerte, Skalierung, aus der GPU zurückgelesene Texturpixel und
  inklusive Texturen verrechnete Cache-Bytes stimmen überein.
- Fehlende, beschädigte und werfende Binärdaten verwenden weiter den JSON-Fallback.
  Gemeinsam verwendeter null-Sentinel separat nativ geprüft. Die bestehende
  Residency-Prüfung besteht (GC, LRU, lebende Modelle, Varianten, Epochwechsel,
  Übergröße, Textureinrechnung und Freigabe).

## Tatsächliche Strecke und verbleibende Lastspitzen

Celadon → Route 7 → Celadon → Route 16 → Celadon bestanden, vier Wechsel.
Voxel-Gebäude ausdrücklich an, Voxelstufe 6, Nacht, Regen, Tiltshift 3.
128-MiB-Gebietscache, unveränderte 12 MiB für zurückgehaltene Modelle.

Nach dem im Artefakt analyze_travel.py dokumentierten Ausschluss der künstlichen
Test-Wegsuche, Setup- und abgedeckten Frames bleiben 2.675 Frames: Median 12,25 ms,
p95 20,64 ms, p99 27,19 ms, Maximum **143,02 ms**. Höchste CPU-Zeit 139,30 ms.
Die Strecke ist wegen zeitabhängiger Spawns kein kontrollierter FPS-A/B-Vergleich.

Der schlechte Frame 1268 auf Route 7 enthält 43,4 ms LocalLights.prepare mit
43,1 ms VoxelFurniture.eachWorld sowie 42,6 ms setSpecies (37,1 ms Content.record).
Der zusätzliche Pack-Aufwand ist dort nur noch etwa 0,1 ms; die doppelte
Buchhaltung ist entfernt, aber ein synchroner Kaltstart und die Lichtvorbereitung
fallen weiterhin zusammen. Das nächste notwendige Arbeitsfeld ist deren Vorladen
und zeitliche Verteilung. Keine Aussage über stabile FPS oder schwächere Geräte.

Artefakte: artifacts/performance-model-accounting-20260928. Kein Release,
keine persönlichen Spielstände geändert. Alle gestarteten nativen Tests beendet.
