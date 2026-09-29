# Render-Optimierung: Zwischenstand und Messungen, 28.09.2026

Der vorherige Arbeitsstand wurde vollständig und wiederherstellbar gesichert.
Diese Runde reduziert nachweislich die Anzahl statischer Schatten-Neuberechnungen.
Ein verlässlicher allgemeiner FPS-Zuwachs ist mit den vorliegenden Messungen **nicht belegt**.

## Sicherung

`/Users/maarten/Documents/Recompile/artifacts/performance-checkpoint-20260928/`

- `workspace.tar.gz`: 472.129.017 Bytes; 17.478 reguläre Dateien beim Zurücklesen per SHA-256 geprüft.
- Enthält den gesamten Arbeitsbaum einschließlich unversionierter und ignorierter Dateien sowie Symlinks, ohne `.git`.
- `sha256.json`, `HEAD.txt`, `status.txt`, `tracked.patch` dokumentieren Inhalt und Git-Ausgangslage.
- Wiederherstellung in einen **neuen leeren Ordner**, siehe `README.txt`. Der bestehende Arbeitsbaum wurde nicht zurückgesetzt.

Die Änderungen dieser Runde sind zusätzlich als `implementation.patch` unter
`/Users/maarten/Documents/Recompile/artifacts/render-round2-20260928/` abgelegt.
Dieser Patch bezieht sich auf die vollständige Sicherung, nicht auf Git-HEAD.

## Aktive Änderungen

1. **Statische Schatten länger wiederverwenden.** Das Zentrum der Schattenprojektion
   bleibt innerhalb einer 64-Welteinheiten-Zelle konstant. Eine Erweiterung um 32
   Einheiten je Seite deckt die Verschiebung ab. Bewegliche Figuren werden weiter
   pro Bild gezeichnet; bestehende Geometrie- und Lichtinvalidierungen bleiben wirksam.
   Die zusätzliche Abdeckung kann die Texeldichte der Schatten leicht verändern.
2. **Optionale Hintergrundarbeit begrenzen.** Bei teuren Vordergrundbildern pausieren
   zusätzliche Horizont-/Survey-Arbeiten; ein kleines Intervallbudget verhindert
   dauerhafte Starvation. Erforderliches Terrain, dringende Jobs und Arbeit unter
   der Ladeanzeige behalten ihre eigenen Fortschrittsbudgets. Das ersetzt keine
   Vorbereitung an Wärterhaus-/Höhlengrenzen, sondern ergänzt sie.
3. **Fernmodelle vorbereiten.** Bei geeigneten statischen Modellen entfallen nur
   vollständig in vorherigen Körpern enthaltene Detailboxen. Die belegte Geometrie
   bleibt gleich; Oberflächendetails können sich vereinfachen. Landmarken bleiben
   ausgenommen. Auswahl erst ab 320 Welteinheiten und unter 72 Pixel Bildhöhe,
   ausschließlich bei ungekrümmter Welt und reiner Verschiebung des Modells.
   Die Reservierung für zusätzliche Quellvorlagen ist auf 8 MiB begrenzt; dies
   ist ausdrücklich kein Gesamt-GPU-Speicherlimit inklusive Instanzkopien.
   Farbpass-Instanzen werden im bestehenden Vorbereitungspfad mit aufgebaut.
4. **Unschärfe-Ressourcen aufräumen.** Alte Zwischenbilder werden bei Größenwechsel
   und Invalidierung freigegeben, ebenso Teilallokationen nach einem Fehler.
   Die reguläre Unschärfe bleibt unverändert aktiv.

## Implementiert, aber standardmäßig deaktiviert

- **Zusätzliche Verdeckungsprüfung:** prüft tatsächliche massive Flächen, keine
  geschlossenen Gebäudehüllen über Fenster/Türen hinweg. In einer Szene wurden
  bis zu 31 bzw. 64 Prop-Zeichnungen eingespart. Die CPU-Prüfung lieferte aber
  keinen konsistenten Gesamtgewinn. `PropOcclusion.enabled=false`.
- **Kleinere Unschärfe-Zwischenbilder:** zwei halb aufgelöste Puffer und ein
  voll aufgelöstes Komposit benötigen rechnerisch 25 % weniger Scratch-Fläche
  als zwei Vollauflösungspuffer. Der scharfe Bildstreifen bleibt pixelgleich;
  außerhalb verändert sich das Filterbild. Kein verlässlicher FPS-Gewinn im
  Vergleichslauf, daher `TiltShift.optimized=false`.

## Native Messungen

LOVE 11.5 auf dem verfügbaren Mac, getrennte QA-Identität, stummgeschaltet.
1710 × 955 tatsächliche Rendergröße, 600 Bewegungs-/Kamerabilder pro Variante,
VSync aus, festes Kartenbudget 128 MiB. Keine Messung auf iPhone oder Switch.
Referenz schaltet die neuen Renderpfade ab; die neuen Vorlagen waren in allen
Varianten bereits verfügbar. Das ist **kein A/B-Test der kalten Vorlagen-Erstellung**.

Tag, klar, ungekrümmte Welt; abschließender Lauf mit den beibehaltenen Defaults:

| Karte | Variante | Ø FPS | p95 ms | p99 ms |
| --- | --- | ---: | ---: | ---: |
| Saffron | Referenz vorher | 67,00 | 20,35 | 28,63 |
| Saffron | Aktive Änderungen | 55,70 | 23,55 | 37,58 |
| Saffron | Referenz danach | 49,67 | 26,15 | 41,29 |
| Celadon | Referenz vorher | 42,59 | 30,15 | 43,62 |
| Celadon | Aktive Änderungen | 42,93 | 30,21 | 39,55 |
| Celadon | Referenz danach | 40,29 | 31,41 | 52,84 |

Die Vergleichsbasis driftet selbst deutlich. Deshalb lässt sich weder der
Saffron-Unterschied noch der kleine Celadon-Vorteil zuverlässig der Änderung
zurechnen. Eine Ursache wie Temperatur wurde nicht gemessen.

Die Schattenzähler erlauben eine engere Aussage: Zwischen den jeweiligen
Ergebniszeilen entstanden in Saffron 104 neue statische Schattenbilder in der
Referenzphase, 25 mit Wiederverwendung und 101 bei erneuter Referenz. In Celadon
waren es 126 / 24 / 126. Diese Intervalle enthalten auch Vorbereitung/Einlaufzeit;
sie sind keine reinen Zähler der 600 Messbilder. Es sind etwa 76–81 % weniger
Neuberechnungen in diesen Testintervallen, **keine entsprechende FPS-Steigerung**.

Im abschließenden Lauf wurden bis zu 21 Fernvorlagen mit zusammen 8.444 weniger
Vertices gegenüber ihren detaillierten Quellvorlagen erzeugt. In den gemessenen
Straßenansichten erfüllte jedoch kein sichtbares Modell die konservative
Auswahlgrenze (`peakLOD=0`). Daher ist daraus kein Straßen-FPS-Gewinn ableitbar.
Die tatsächliche Auswahl in der Ferne wird separat getestet.

Weitere Diagnoseläufe:

- Nacht/Regen in Saffron: Referenz 55,40, alle Versuche 55,63, erneute Referenz
  55,33 FPS. Kein belastbarer Unterschied; Sonnen-Schattenoptimierung greift bei
  diesem Wetter nicht.
- Alle Versuche bei Tag: Saffron 49,53 / 48,89 / 49,20 FPS, Celadon
  45,48 / 44,75 / 41,86 FPS (Referenz / Versuche / Referenz). Das begründet,
  Verdeckungsprüfung und kleinere Unschärfe nicht standardmäßig einzuschalten.
- Ein früher Tag-Lauf driftete ebenfalls stark und wurde nicht als Leistungsgewinn
  gewertet. Rohdaten bleiben zur Nachvollziehbarkeit erhalten.

## Prüfungen

Neun relevante Headless-Testdateien bestanden, einschließlich Budgetierung,
Regionen, Gate-Vorladen, Schatten-Lebenszyklus und Vorbereitung der Instanzvorlagen.

Native Bildprüfungen:

- Verdeckung: 32 Perspektiven, insgesamt 243 ausgelassene Zeichnungen;
  Ergebnis pixelgleich zur vollständigen Szene, einschließlich Türlücke.
- Fernmodelle: acht echte Modelle mit je acht Ansichten; Silhouetten pixelgleich.
  Zusätzlich Auswahl einer fernen Vorlage geprüft; gedrehte/skalierten Modelle
  bleiben im detaillierten Pfad (Headless-Test).
- Unschärfe: drei Stufen; scharfer Streifen pixelgleich. Mittlerer maximaler
  RGB-Kanalfehler außerhalb/über das Bild etwa 0,0125–0,0133, einzelne harte
  Kontrastkanten bis etwa 0,21–0,23. Deshalb keine Behauptung identischer Gesamtoptik.
- Referenz- und Ergebnisbilder von Saffron/Celadon visuell geprüft. Bereits in
  der Referenz sichtbare diagonale Fassadenmuster bestehen weiter; diese Runde
  beansprucht nicht, diese Darstellungsfehler zu beheben.

Start über **Weiter**, Saffron, 128 MiB Kartenbudget:

- Ladeanzeige erstmals nach 0,0061 s gezeichnet.
- Szene bereit nach 4,021 s; Freigabe nach 4,388 s.
- Regionstatus `done`, speicherbedingt begrenzt: 13 Karten entdeckt, eine im
  Regionplan vorbereitet; der aktive Nachbarschaftsplan umfasst Saffron und die
  Routen 5–8. Die eigenen Readiness-Bedingungen und direkten Nachbarschaftsprüfungen
  waren vor der Freigabe erfüllt. Dies bedeutet nicht, dass alle entdeckten Karten
  vollständig gleichzeitig im RAM lagen.
- Maximaler Frame unter der Ladeanzeige 177,7 ms. Der Cover verhindert sichtbaren
  Weltaufbau, garantiert aber noch keine durchgehend flüssige Ladeanimation.
- `PASS_COLD_CONTINUE`; kein belegter Ladezeitgewinn ohne passenden Vorher-Lauf.

Rohdaten: `headless.log`, `night.log`, `day-flat.log`, `final-flat.log`,
`retained.log`, `quality.log`, `occlusion-quality.log`, `continue.log` und die
zugehörigen Bilder/JSON unter dem oben genannten Ergebnisordner.

## Verbleibende Grenze

Diese Runde löst nicht alle Nachladeruckler und belegt keine stabilen 60 FPS.
Die zusätzliche Occlusion und Blur-Variante bleiben aus, solange ihr Nutzen nicht
nachgewiesen ist. Für weitere Entscheidungen sind getrennte CPU-/GPU-Zeitmessung
und wiederholbare Läufe ohne starke Drift wertvoller als weitere pauschale Caches.
Reale Mobilgeräte müssen separat auf Speichergrenzen, Framezeiten und Optik geprüft
werden; die Desktopmessung ersetzt diese Abnahme nicht.
