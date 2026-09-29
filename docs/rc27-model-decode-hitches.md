# RC27 – vorbereitete Pokémon-Modelldaten und verbleibende Reisespitzen

28.09.2026. Das Gesamtziel bleibt offen. Die Änderung reduziert gemessene
Dekodierarbeit ohne zusätzliche Modellresidenz oder geänderte Darstellung.
Ein allgemeiner Gewinn der schlechtesten Spielframes ist nicht nachgewiesen.

## Befund und Änderung

Die native Strecke Celadon → Route 7 → Celadon → Route 16 → Celadon wurde mit
den RC26-Einstellungen wiederholt: Nacht/Regen, Voxel 6, Unschärfe 3,
1710×955 Renderpixel, 128 MiB Kartenbudget, isolierte stumme QA-Identität.
**Nachträglich entdeckter Testfehler:** `baseline-travel`, `fixed-travel` und
`fixed-detail` erbten `palletBuildings=false` vom RC26-Test ursprünglicher
Fensterbeleuchtung. Diese Läufe gelten deshalb ausschließlich für ursprüngliche
Gebäude und belegen keine Performance mit Voxel-Architektur. Der Nutzer hat die
sichtbare Abweichung bemerkt. RC27 setzt und prüft Voxel-Gebäude jetzt vor jeder
Strecke ausdrücklich und schreibt die Einstellung in das Ergebnis. RC26s
Bildvergleich setzt beide Varianten ausdrücklich und stellt beim Beenden die
vorherige Einstellung wieder her. Nur die isolierte QA-Konfiguration ist betroffen.
RC27 erfasst zusätzlich die tatsächlichen Gen-1-Modellpfade, darunter
`CobblemonContent.record`, `StadiumMon.setSpecies`, Rig-Aufbau und Texturen.

Im Referenzlauf beanspruchten erste Modelldaten-Aufrufe bis zu 38,33 ms.
`ContentJson` erzeugte und prüfte für jede Ziffer einzelne Teilstrings mit
Lua-Mustern. Direkte Byte-Prüfungen ersetzen diese Arbeit. Zahlen werden weiter
mit `tonumber` konvertiert; JSON-Grammatik, Bereichsprüfung, UTF-8-Prüfung,
Objekt-/Arraystruktur und Fehlerbehandlung bleiben erhalten. Die Wertauswahl
prüft zudem nur die zum ersten Byte passende JSON-Konstante.

Produktionsänderung ausschließlich `lib/ContentJson.lua`; Gen 2 lädt denselben
Datenleser. Keine Modelländerungen, neuen Cacheformate oder größeren RAM-Budgets.

## Gleichheit und Laufzeit

Der native Vergleich lädt alle 1.071 unterschiedlichen ausgelieferten
Modelldateien (109.917.775 Bytes). Referenz und Kandidat laufen in wechselnder
Reihenfolge auf denselben bereits eingelesenen Bytes. Dateizugriff, rekursive
Gleichheitsprüfung und explizite Speicherbereinigung sind außerhalb der
Dekodiermessung. Alle Felder/Zahlen/Strukturen stimmen exakt überein.

| Lauf | Referenz gesamt | Kandidat gesamt | Weniger Dekodierzeit |
| --- | ---: | ---: | ---: |
| Standardlauf | 20.858 ms | 16.146 ms | 22,6 % |
| LuaJIT-JIT explizit abgeschaltet | 23.622 ms | 18.177 ms | 23,0 % |

Standardlauf pro Modelldatei: Median 17,52 → 13,50 ms; 95. Perzentil
39,23 → 30,51 ms. Das sind Vergleichswerte über den kompletten Modellbestand,
keine Verbesserung jeder einzelnen Datei und keine FPS-Prozentangabe.
Der Interpreterlauf verwendet LuaJIT 2.1 mit `jit.status() == false` auf dem
Mac; er ersetzt keinen Hardwaretest auf iPhone oder Switch.

In beiden Läufen bestanden zusätzlich 22.222 differenzielle Grammatikfälle
(auch ungültige Eingaben mit identischen Fehlerrückgaben). Ein separater
Regressionstest deckt Vorzeichen, Brüche, Exponenten, Überlauf, führende Nullen,
Trennzeichen, Null-/Bool-Werte, UTF-8 und Surrogatpaare ab. Bestehende Prüfungen
für Modellfehler-Lebenszyklus, ungültige Cache-Receipts und gemeinsame
Gen-2-Datenpfade bestanden ebenfalls.

## Grenzen und nächste Ursachen

Beide Spielläufe bestanden vier echte Übergänge. Sie haben unterschiedliche
zufällige Pokémon/NPC-Verläufe und erlauben keinen direkten FPS-Vergleich.
Die begrenzte Liste ausführlicher Slow-Call-Stacks erreichte in beiden Läufen
3.000 Einträge; Frame-Zähler und Maxima wurden weiter vollständig erfasst.
Für die weitere Diagnose wurde die Stack-Schwelle konfigurierbar gemacht.

Der Kandidatenlauf hatte weiterhin große Spitzen: Fensterlichtaufbereitung
ca. 205 ms, Modellvorbereitung bis 118 ms und außerhalb gemessener Callbacks
liegende Wartezeit bis ca. 199 ms. Die JSON-Änderung behebt diese Ursachen nicht.
Aus den Callstacks belegt sind außerdem erstmalige Figurentextur-Uploads im
Wasserspiegelungsdurchlauf (ca. 31 ms im Referenzlauf). Sie wurden bisher nicht
vollständig vorgezogen. Kartenereignisse benötigen ebenfalls weitere Analyse.

Artefakte: `artifacts/performance-model-travel-20260928` im Hauptarbeitsbereich.
`baseline-travel`, `fixed-travel`, `decode`, `decode-no-jit` enthalten native
Logs und Rohwerte. `comparison.json` ist eine Auswertung der begrenzten
Slow-Call-Liste; für vollständige Aufrufmaxima sind `trace.json.frames.peaks`
maßgeblich. Kein Release und keine Änderung persönlicher Spielstände.

Der zusätzliche Lauf `fixed-detail` mit höherer Stack-Schwelle isolierte die
Fensterlichtspitze weiter: drei erstmalige `NativeWindowLights.shape`-Analysen
benötigten 65,22 / 36,55 / 31,42 ms. Diese verbleibende Arbeit gehört zum Pfad
ursprünglicher Gebäude; sie darf nicht mit Voxel-Gebäudeaufbau verwechselt werden.

## Wiederholung mit Voxel-Gebäuden

`voxel-travel`: vier echte Übergänge, 2.390 Spielframes, Status `passed`,
`voxelBuildings=true` im Ergebnis. Der lange native Fensterform-Aufbau entfällt
in diesem Lauf. Restliche Spitzen bleiben: Modellvorbereitung bis 95,89 ms,
Kartenwechsel bis 50,87 ms, Figurentexturen etwa 31 ms. Ein erfasster Frame von
209,4 ms enthält ca. 201,1 ms außerhalb gemessener Spielcallbacks. Das ist keine
isolierte GPU-Messung und hat bislang keine belastbare Ursachenattribution.
Dieser Lauf ersetzt die irrtümliche Einordnung der vorigen Strecken als
Voxel-Gebäudemessungen; er belegt noch keinen allgemeinen FPS-Gewinn.

Der abschließende native Voxel-Bildvergleich in Celadon, Route 7 und Saffron
bestand zwölf Ansichten ohne Pixeldifferenz (`voxel-quality`). Die erzeugte
Celadon-Ansicht wurde visuell geprüft; Voxel-Gebäude sind sichtbar. Nach Ende
stand die isolierte QA-Option weiterhin auf `palletBuildings=true`.

## Nachtrag aus RC29: Testaufwand getrennt erfassen

Die RC29-Wiederholung hat rund 100-ms-Update-Spitzen als automatische
Wegeplanung des Testfahrers identifiziert. Die RC27-Strecke enthielt diese
Arbeit ebenfalls, ohne eigenen Messbereich. Ungefilterte Frame-Maxima aus
solchen Strecken sind daher keine reine Spielperformance. Der Test zeichnet
`QA.pathToExit` jetzt separat auf. Reale Modell-/Texturspitzen bleiben bestehen;
die frühere nicht zugeordnete Wartezeit ist damit nicht pauschal erklärt.
Siehe `rc29-model-residency.md` für Rohwerte und die Grenzen der Zuordnung.
