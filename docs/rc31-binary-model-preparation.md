# RC31 – vorgebaute Modelldaten und Primo-2-Lichtmodule

28.09.2026. Das übergreifende Performanceziel bleibt offen. Kein Release erstellt.

## Modellaufbau

Die früheren Fahrttests zeigen bis zu 69 ms in `CobblemonContent.record` innerhalb
von rund 102 ms `StadiumMon.setSpecies`. Der begrenzte RC29-RAM-Cache beseitigt diesen
Erstaufbau nicht. Die vorbereiteten Modelltabellen liegen bisher als JSON vor.

`scripts/prepare_cobblemon_binary.py` erzeugt nun reproduzierbare, datenbasierte
CMB1-Dateien für alle 1.069 unterschiedlichen, tatsächlich im vorbereiteten Index
referenzierten Modelle. Zwei unreferenzierte JSON-Dateien werden nicht übernommen.
Die komprimierten Dateien beanspruchen zusammen 14.382.276 Bytes, zusätzlich zum
weiterhin vorhandenen JSON-Fallback. Der Cache wird vor der Auslieferung gebaut,
nicht erst synchron im ersten sichtbaren Spielframe. Regenerierung:

```sh
python3 scripts/prepare_cobblemon_binary.py
```

`CobblemonContent` prüft die Zuordnung zum exakten JSON-Index, den Hash der ganzen
Binärdatei und deren ursprünglichen JSON-Hash. Der Decoder verwendet begrenzte
Datenstrukturen und LE-Doubles; keine Lua-Ausführung, Bytecode oder Plattform-FFI.
Numerische Arrays werden in 128er Blöcken entpackt. Fehlende, defekte oder nicht
passende optionale Daten fallen auf den bisherigen hashgeprüften JSON-Weg zurück.
Download-/Importmodelle behalten ihren bisherigen Weg. Der RC29-RAM-Cache und dessen
Budget bleiben unverändert. `build_local_candidate.py` prüft bei vorhandenen binären
Daten zusätzlich Vollständigkeit und Hashes und lehnt einen veralteten Index ab.

Der eigene Primo-2-Modulresolver lädt den neuen Decoder ausdrücklich am gemeinsamen
Paketwurzelpfad. Generationseigene Spiel- und Renderlogik bleibt generationseigen.

## Messung und Gleichheit

Native LOVE-Läufe auf dem Entwicklungs-Mac; keine iPhone-/Switch-Messung. Der
Lauf meldet JIT deaktiviert. Das ist kein Ersatz für einen Mobilgerätetest.

- `decode`: alle 1.069 Modelle rekursiv gegen JSON verglichen, jede Zahl, jeder
  Schlüssel und jeder Wert identisch. Hashprüfung plus Decoder insgesamt
  **17.619 → 5.695 ms** (67,7 % weniger). Datensatzsummen, keine Ladezeit/FPS.
  Größter einzelner Decoderaufruf in diesem Lauf: **74,0 → 29,5 ms**.
- `render-gen1`: 12 erstmalige Modelle, alternierende Reihenfolge, vollständiger
  Figurenaufbau inkl. Overworld-Größe, Pose und Upload: **399,33 → 347,04 ms**
  (13,1 % weniger). Größter Aufbau bleibt etwa 70 ms. Posed Mesh-Zeilen,
  Skalierung und aus GPU-Texturen zurückgelesene Pixel sind identisch.
- `render-crystal-fixed`: dieselben 12 Modelle im echten Primo-2/Crystal-Kontext,
  dessen reguläre Modellgröße ohne Gen-1-Overworld-Größenpolicy:
  **294,47 → 181,02 ms** (38,5 % weniger). Identische Geometrie und Texturpixel.
  Diese absoluten Zeiten sind wegen der verschiedenen Größenpfade nicht direkt
  zwischen den Generationen vergleichbar.
- In beiden Renderläufen: vorher 12 JSON-Modellzugriffe; nachher 12 Binärzugriffe
  und **0 JSON-Modellzugriffe**. Fehlende, beschädigte und werfende Datei-/Manifest-
  Lesewege behalten den funktionierenden JSON-Fallback.
- Native Decoderprüfungen: abgeschnittene Eingaben, falsche Quellhashes, unbekannte
  Tags, ungültige Längen/Elementzahlen, Nicht-Endlichkeit, Tiefe und Restdaten.
- Deterministische zweite Generierung sowie sämtliche Datei-/Quellhashes geprüft.
- Vorhandene fehlerhafte Import-Receipt-Tests und Gen-2-Modulpfadtests bestanden.

## Beim Primo-2-Start gefundener Fehler

Der geteilte `LocalLightGrid` benötigt mittlerweile `StaticLightField`, dessen
Datencache und Worker. Die Primo-2-Fassade leitete diese drei Namen jedoch in
nicht vorhandene Gen-2-Dateien um. Dadurch scheiterten sowohl der erweiterte als
auch der Basis-3D-Renderer bereits beim Laden. Die drei neutralen Lichtmodule
werden jetzt korrekt am gemeinsamen Paketwurzelpfad geladen. Die Gen-2-Quellen-
Ermittlung bleibt in `gen2/lib/LocalLights.lua`.

`gen2_static_light_paths_test.lua` schützt die vollständige Zuordnung und die
Trennung der Spielwelten. `gen2-scene` zeichnet New Bark Town in Crystal mit
aktivem 3D-Modus: **170 von 170 Renderaufrufen erfolgreich**, kein LocalLights-
Fehler, Bild visuell geprüft. Das ist ein Funktionstest, kein FPS-Benchmark.

Die ersten Gold-Fixtures erreichten wegen fehlender bzw. veralteter importierter
QA-Spieldaten nur den Importbildschirm und wurden gezielt beendet. Der erste
Crystal-Fixture-Aufruf nutzte irrtümlich die Gen-1-Startmethode. Der korrigierte
Test verwendet den Gen-2-Save-/Continue-Ablauf. Verwendet wurden ausschließlich
bereits importierte Daten anderer QA-Verzeichnisse; keine persönlichen Optionen
oder Spielstände kopiert oder verändert.

## Ladeablauf und Grenzen

Der reale Red-Weiter-Test `continue` besteht mit eingeschalteten Voxel-Gebäuden,
128 MiB Testbudget und fertiger Szene/Personenbildvorbereitung. Einzellauf: 3,45 s,
164 abgedeckte Frames, längster abgedeckter Frame 72,16 ms. Kein behaupteter Gewinn
der gesamten Ladezeit. Das bestehende Speicherbudget begrenzt die regionale
Vorbereitung weiterhin auf drei der acht entdeckten Karten.

Die Messungen beweisen weder dauerhaft 60 FPS noch die Beseitigung aller Hänger.
Animation, Größenberechnung, weitere Kartenwechselarbeit und längere Fahrttests
unter Nacht/Wetter mit voller Darstellung bleiben offen. Das neue Datenformat
verbessert den Erstaufbau ohne Detailreduktion; es ist kein fertiger globaler
Performance-Nachweis.

Artefakte im Hauptarbeitsbereich: `artifacts/performance-model-binary-20260928`.
