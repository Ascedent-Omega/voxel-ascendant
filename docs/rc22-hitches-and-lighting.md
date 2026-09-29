# RC22 – Einzelruckler, Effektvergleich und gemeinsame Lichtberechnung

Stand: 28.09.2026. Die allgemeine Performance-Aufgabe bleibt aktiv; alle gemeldeten 4-FPS-Einbrüche sind noch nicht reproduziert und behoben.

## Produktive Änderungen

`RuntimePerformanceDiagnostics` ergänzt die bisherigen Drei-Sekunden-Fenster um einzelne Intervalle über 50 ms. Je 24 letzte und acht schlechteste werden ausschließlich im RAM gespeichert. Erfasst werden Karten-/Phasenwechsel, Ladeabdeckung am Anfang und Ende, verschachtelte Aufrufe mit Eigenzeit, Lua-Speicher und das Alter der zuletzt erfassten Grafikstatistik. Der Supportbericht enthält diese Daten. Keine Datei-Schreibvorgänge, Grafik-Synchronisierung oder Stacktraces pro Frame.

Ein Intervall läuft von Draw-Beginn zu Draw-Beginn und enthält den vorigen Draw sowie den folgenden Update. Nicht von den Spiel-Callbacks erfasste Zeit bleibt ausdrücklich **nicht zugeordnet**; sie ist keine GPU-Messung. Über mehrere Frames suspendierte Coroutinen werden nicht fälschlich als lange CPU-Aufrufe gezählt. Der tatsächliche TiltShift-Einstieg heißt `apply` und wird jetzt erfasst.

Der Welt-Shader nutzt für Figuren und Umgebung dieselbe `localCombinedIrradiance`-Funktion. Nur die bisherigen Gewichtungen, Fenster-Normalen und der Mosaic-Empfänger unterscheiden sich. Lichtanzahl, Schatten, Texturen, Renderauflösung und Effekte wurden nicht reduziert; es entstehen keine zusätzlichen Textur-Slots. Die alten getrennten Funktionen bleiben für andere bestehende Verbraucher und den Vergleichstest verfügbar.

## Messverfahren und Ergebnis

Separates QA-Save, stumm, 1710×958-Fenster mit 1710×955-Weltcanvas, Nacht/Regen, Voxel-Stufe 6, Wasser FULL, TiltShift 3, 128-MiB-Szeneriecache. Zunächst wechselnde Vollreferenzen und einzelne ausgeschaltete Effekte. Wegen erheblicher Systemlast-Schwankungen wurden zusätzlich vier feste Blickrichtungen pro Stadt jeweils unmittelbar als Vorher/Variante/Nachher gemessen. Kameraursprung und Winkel sind identisch, die Simulation läuft mit festen 1/60-Schritten. Wasser-Draws, Lichtzustand, Blur, Rendergröße und Cache-Zustand werden erfasst; ein unerwarteter Beleuchtungsausfall bricht den Test ab.

Im Effektvergleich kostete lokale Beleuchtung in diesen Ansichten etwa 7–20 ms pro Frame. In den zwei Celadon-Ansichten mit sichtbarem Wasser sparte Wasser OFF rund 11 ms; in Ansichten ohne Wasser praktisch nichts. Blur OFF sparte in den kurzen Vergleichen meist unter 1 ms. Diese Diagnose deaktiviert keine produktiven Effekte.

Der finale Vergleich verwendet den produktiven Shader und stellt für die Referenz ausschließlich dessen alten Licht-Funktionsaufruf wieder her. Pro Variante 600 gemessene Frames einer vollständigen Kameradrehung, vor jeder Variante eine Aufwärmrunde:

| Stadt | Referenz vorher | Gemeinsame Lichtfunktion | Referenz nachher | p95 Referenz vorher → neu |
|---|---:|---:|---:|---:|
| Celadon | 39,61 FPS | 57,91 FPS | 39,01 FPS | 33,80 → 23,13 ms |
| Saffron | 46,20 FPS | 65,65 FPS | 46,51 FPS | 28,97 → 19,76 ms |

Auch die wiederholten kurzen Vergleichspaare zeigen den Gewinn. Das ist ein Rendergewinn in diesen Szenen, keine Zusage konstanter 60 FPS auf allen Karten/Geräten. In Saffron blieb im neuen Lauf ein einzelner 39,23-ms-Frame; ein besserer Mittelwert beseitigt nicht jede Spitze.

Während der Arbeit liefen zeitweise fremde LOVE-Instanzen und weitere Anwendungen. Sie wurden nicht verändert. Die erste lange Effektmessung ist deshalb allein kein sauberer Leistungsbeleg; ihre Rohdaten bleiben erhalten. Die kurze Paarmessung und die eng beieinanderliegenden Vorher-/Nachher-Referenzen des finalen Laufs sind die stärkere Evidenz.

## Qualität und Regressionen

- 11.200 native Lichtproben exakt pixelgleich: sechs Flächennormalen und schräge Flächen, Figuren-/Umgebungsgewichtung, Höhen-/Randbereiche, statisches Lichtfeld, dynamische Fackeln, kleine direkte Lichtlisten, Sonnenlichtportale und farbiges Glas.
- Eingefrorene vollständige Celadon- und Saffron-Szenen zwischen den Shadern verglichen: keine abweichenden Pixel, maximaler Kanalfehler 0.
- LÖVE validierte 20 vollständige Shaderprogramme für Desktop und GLES; 60 Stufen wurden zur Nachvollziehbarkeit exportiert. Kein Test auf physischem iPhone oder Switch.
- Headless-Verträge bestanden: Hitch-Aufzeichnung (schnelle Frames, Kartenwechsel, fremde Wartezeit, verschachtelte Zeit, begrenzte Historie, Yield, Fehler und nil-Rückgaben), vorhandene Lichtauswahl/-Wiederverwendung, Ausfallisolierung, Fenster-Tageslicht, Diagnose-Schreibbudget, Instanz-Vorbereitung und bisherige Renderoptimierungen. Mobiler Renderpolicy-Test mit korrekt übergebenem Repository-Pfad bestanden.
- Synthetischer Lua-Vergleich mit 42 gemessenen Aufrufen je Frame: Diagnose vorher rund 0,0155 ms, jetzt 0,0220 ms. Das ist nur der CPU-Overhead dieses Headless-Mikrotests, keine Geräteleistungszusage.
- „Weiter“ in Celadon: Ladeabdeckung nach 6,8 ms sichtbar, Freigabe nach 3,71 s, benötigte direkte Nachbarschaft bereit; 600 anschließende Frames bei 55,99 FPS, p95 33,24 ms, Maximum 33,98 ms. Kein fairer Vorhervergleich der Ladezeit (Cachezustand/Systemlast). Unter der Abdeckung blieb ein 105,51-ms-Intervall.

## Verworfener Versuch

Vier Licht-IDs gemeinsam in einer Float-Textur zu speichern blieb trotz pixelgleicher Ausgabe praktisch ohne messbaren Gewinn. Der erste Entwurf überschritt zusätzlich das Limit von 16 Fragment-Textur-Slots; dessen hohe FPS waren ein Beleuchtungsausfall und **kein Gewinn**. Der korrigierte Entwurf verwendete denselben Textur-Slot, war aber nicht zuverlässig schneller. Sämtliche produktiven Änderungen dieses Versuchs an `LocalLightGrid` und `StaticLightField` wurden bytegleich auf den Stand vor RC22 zurückgesetzt. Versuch und ungültige/negative Läufe sind archiviert.

## Offene Arbeit

Die Ruckler-Aufzeichnung sieht weiterhin lange Einzelaufrufe, unter anderem beim ersten Wasser-/Figurenaufbau und bei der Vorbereitung/Persistierung des statischen Lichtfelds. Direkte Test-Teleports und Screenshot-Readbacks dürfen dabei nicht mit einem regulären „Weiter“-Vorgang verwechselt werden. Im Continue-Trace liegt z. B. ein langer `StaticLightField.prepare`-Aufruf unter der Ladeabdeckung; der erste schwere Wasser-Frame davor stammt aus dem vorbereitenden Test-Teleport. Diese Ladepfade müssen gezielt weiter zerlegt und anschließend mit echten Übergängen und längeren Laufstrecken geprüft werden.

## Sicherung

`/Users/maarten/Documents/Recompile/artifacts/performance-hitches-20260928/` enthält Ausgangsdateien, begrenzten Änderungspatch, finale Dateien mit SHA256, native Logs, Bilder und Rohdaten. Der ältere vollständige Projekt-Zwischenstand bleibt unter `artifacts/performance-checkpoint-20260928/` erhalten. Keine Veröffentlichung und keine Änderungen am persönlichen Spielstand.
