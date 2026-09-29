# RC29 – begrenzter Rückkehrcache für Cobblemon-Modelle

28.09.2026. Das Performanceziel ist weiterhin offen; diese Änderung beseitigt
wiederholte Vorbereitung kürzlich benutzter Modelle, nicht alle ersten Uploads.

## Ursache und Änderung

`CobblemonPack` hielt dekodierte Modelle ausschließlich über schwache Referenzen.
Nach Entfernen ihrer Figuren konnte die Speicherbereinigung dadurch auch die
Modelldaten, Texturen und einmalig ermittelten Größen verlieren. Beim nächsten
Auftauchen fielen Dekodierung und Silhouettenmessungen erneut an.

Die gemeinsame Gen-1-/Gen-2-Datenimplementierung hält jetzt die zuletzt benutzten
Modelle in einem begrenzten Cache: maximal 16 Einträge und 12 MiB geschätzte
Daten-/Texturkosten. Die Schätzung zählt Tabellenplätze und geteilte Strings
konservativ mehrfach; sie ist keine Messung verfügbarer Geräte-RAM-Kapazität.
GPU-Texturen werden bei ihrem Upload zusätzlich angerechnet. Eine Überschreitung
entfernt die ältesten Cache-Referenzen, ohne Ressourcen aktiver Figuren freizugeben.
Varianten bleiben getrennt; eine neue Content-Epoche entfernt die alten Cache-Leases.
Größere Einzelmodelle funktionieren weiterhin, erhalten aber keinen Rückkehr-Lease.
Es wird kein zusätzlicher Modellbestand vorab geladen und keine Grafikoption reduziert.

Produktionsänderung: `lib/CobblemonPack.lua`. Die unabhängige schwache Referenztabelle
bleibt bestehen, damit aktive Figuren auch nach Cache-Verdrängung ihr Modell teilen.
`residency()` macht Treffer, Fehlzugriffe, Verdrängungen und Schätzbudget überprüfbar.

## Kontrollierter nativer Vergleich

Isolierte, stumme LOVE-QA; ursprüngliches Pack und Kandidat im selben Prozess,
wechselnde Reihenfolge. Acht reale Arten: 16, 19, 25, 52, 72, 81, 92, 133.
Jeweils vollständiger Rig-Aufbau, Größenbestimmung für die Oberwelt, Pose und
Textur-Upload. Danach Rig-Freigabe und volle Speicherbereinigung zwischen Durchläufen.
Kein laufendes Spiel während der Messschleife, deshalb kein Gesamt-FPS-Benchmark.

| Durchlauf | Bisher | Cache |
| --- | ---: | ---: |
| Erstaufbau aller acht, Standardlauf | 178,62 ms | 180,82 ms |
| Wiedersehen 1 | 171,55 ms | 5,75 ms |
| Wiedersehen 2 | 168,42 ms | 5,78 ms |
| Wiedersehen 1, JIT explizit aus | 171,33 ms | 6,11 ms |
| Wiedersehen 2, JIT explizit aus | 194,51 ms | 6,24 ms |

Über drei Runden dekodiert die Referenz 24 JSON-Modelldateien, der Cache nur acht.
Die acht Cache-Modelle belegen am Ende 10.006.917 geschätzte Bytes; der im ersten
Cache-Durchlauf nach GC verbleibende zusätzliche Lua-Heap betrug rund 3,37 MiB.
Das ist ein Szenariowert und kein allgemeiner physischer Speicherbedarf.

Alle vollständigen posierten Mesh-Zeilen, Skalierungen und über Canvas ausgelesenen
Texturen waren in sämtlichen Runden identisch. Der JIT-aus-Lauf ist weiterhin ein
Mac-LuaJIT-Interpretertest, kein Test auf iPhone oder Switch.

## Reale Strecke und Grenzen

Celadon → Route 7 → Celadon → Route 16 → Celadon, zweimal. Voxel-Gebäude ausdrücklich
aktiv, Voxel 6, Unschärfe 3, Nacht/Regen, 128-MiB-Kartenbudget. Beide Läufe bestanden
acht echte Kartenwechsel. Kandidat: 4.612 gemessene Spielframes, 15 Cache-Treffer,
10 Dekodierungen, vier Verdrängungen; zuletzt sechs Modelle / 9.508.009 geschätzte Bytes.
Referenz: 5.013 Frames, 14 Dekodierungen. Zeitabhängige Figurenbewegung und Repathing
unterscheiden sich trotz gleichem Zufallsseed; daraus wird kein FPS-Prozentgewinn abgeleitet.

Erstmaliger Modellaufbau, erste Figurentexturen und andere Hänger bleiben sichtbar.
Mehrere Kandidatenframes verbringen etwa 100 ms im normalen Update außerhalb der
bislang gemessenen Unterfunktionen. Die QA-Aufschlüsselung wurde daher um explizite
GC-Schritte, Music.update, DiscordPresence.update und Game.updateSync ergänzt.

## Prüfungen und Rücknahme

Headless bestanden: `cobblemon_residency_test.lua` (GC, LRU, aktive Referenzen,
Varianten, Content-Wechsel, übergroße Modelle und Texturen), vorhandener
`cobblemon_failure_lifecycle_test.lua` und `gen2_model_data_paths_test.lua`.

Artefakte: `artifacts/performance-model-residency-20260928` im Hauptarbeitsbereich.
`native-visual` und `native-no-jit` enthalten die kontrollierten Vergleiche;
`travel` und `travel-reference` die realen Strecken. Keine persönlichen Spielstände
verändert, kein Release und keine Leistungszusage für andere Geräte.

## Korrektur der Update-Attribution

`travel-detail` schließt die vermuteten Dienste für seine langen Update-Spitzen aus:
explizite GC-Schritte maximal 7,85 ms, Music.update 3,40 ms, DiscordPresence.update
0,16 ms, Game.updateSync 0,06 ms. Die rund 100-ms-Pausen blieben unzugeordnet.

Der anschließende Lauf `travel-qa-attribution` misst deshalb zusätzlich
`QA.pathToExit`, die automatische Breitensuche des Testfahrers. Zwei lange Updates
enthalten 93,88 von 94,91 ms bzw. 108,66 von 110,07 ms **Test-Wegeplanung**.
Diese Messspitzen sind keine Belege für Spielruckler. Ungefilterte Maximalwerte der
bisherigen RC27/RC29-Teststrecken enthalten diesen Aufwand und dürfen nicht als
reine Engine-/Mod-Performance oder als Nachweis bestimmter Spiel-FPS verwendet werden.
Der Trace behält die Rohwerte, benennt den QA-Aufwand nun aber separat.

Der Lauf bestand vier Übergänge / 2.227 Spielframes mit Voxel-Gebäuden. Ohne Frames
mit QA-Wegeplanung bleiben reale CPU-Spitzen von 119,72 und 99,32 ms. Beim ersten
Route-16-Eintritt entfallen 33,42 ms auf setMap, 32,15 ms auf Modellvorbereitung und
22,24 ms auf neue GPU-Images; diese verschachtelten Werte dürfen nicht einfach
summiert werden. Weitere erste Figuren-Uploads und Modellaufbauten sind deshalb
weiterhin zu bearbeiten. Die Zuordnung beweist weder die Ursache aller früheren
209-ms-Wartezeiten noch eine allgemeine Spielflüssigkeit.
