# RC25 – Kosten der Wasserspiegelung

28.09.2026. Das gesamte Performance-Ziel bleibt offen. Diese Runde verbessert den Desktop-Pfad mit vollständigen Wasserspiegelungen; sie ist keine Abnahme aller Karten oder der gemeldeten 4-FPS-Fälle.

## Belegte Ursache

Einzelne Teile des Wasserpfads wurden in Celadon bei Nacht/Regen getrennt ausgeschaltet, jeweils zwischen zwei unveränderten Referenzphasen derselben festen Kamera. 180 Frames pro Phase, 1710×955 Renderpixel, LOVE 11.5, isolierte stumme QA.

- Der zusätzliche Figuren-/Gebäudepass für die Spiegelung kostet in zwei Wasseransichten ungefähr 6,5 und 6,7 ms pro Bild.
- Die Reflexionssuche kostet etwa 1,8 und 0,8 ms.
- Das Weglassen der Wellenrelief-Berechnung spart nur etwa 0,7 bzw. 0,1 ms.
- Die zusätzliche Wasserbeleuchtung ist hier deutlich kleiner als der erneute Szenenpass.

Das sind Differenzen der gesamten Frame-Zeit einschließlich Treiber/Systemlast, keine isolierten GPU-Zeitstempel. Die diagnostisch abgeschalteten Effekte bleiben produktiv aktiv.

## Umsetzung

`WaterReflection.lua` kopiert Szenenfarbe und Geländetiefe zusammen in ein dauerhaft wiederverwendetes Spiegelungsziel. Ab 640×360 Szenenpixeln hat dieses Ziel halbe Breite und Höhe; kleinere Ziele behalten ihre Abmessungen. Bei 1710×955 sind es 855×478 Pixel.

Der zusätzliche Szenenpass zeichnet in dieses kleinere Ziel und darf dessen eigene Tiefe aktualisieren. Damit verdecken nahe Objekte entfernte Objekte auch innerhalb dieses Passes. Die Tiefe der eigentlichen Szene wird dabei nicht verändert. Wasseroberfläche, Wellenrelief, Reflexionssuche, Beleuchtung und sichtbare Welt bleiben in der bisherigen Auflösung. Der bestehende mobile Wasserpfad wird nicht erweitert oder verändert.

Das **Spiegelbild ist nicht pixelgleich**: Es wird gröber abgetastet und berücksichtigt nun die gegenseitige Verdeckung der erneut gezeichneten Objekte. Die Vergleichsbilder zeigen weiter Gebäude, Figuren und Licht im Wasser. Aufnahmen ohne sichtbaren Einfluss der Wasserspiegelung sind in den acht geprüften Ansichten exakt gleich. Einzelne Reflexionskanten können größere Farbunterschiede aufweisen; kein pauschales Versprechen unveränderter Gesamtoptik.

Shader-Vorbereitung läuft in der vorhandenen Vorbereitungsschleife. Die Ziele entstehen bei vorhandenem Wasser auch dann, wenn die erste Kamera davon wegschaut. Größenwechsel/Invalidierung geben beide Ziele frei. Compiler-, Allokations- und Bindefehler fallen auf den bisherigen Vollauflösungspfad zurück und werden nicht jedes Bild erneut versucht. Die neuen Teiloperationen sind in der begrenzten Hitch-Diagnose erfasst.

## Messung des produktiven Pfads

300 Frames pro Phase, Nacht/Regen, festes Celadon-Kamerazentrum bei Zelle 24/23. Die Referenz deaktiviert ausschließlich den neuen Spiegelungspfad. Sonstige Effekte bleiben aktiv. Mittelwerte in Millisekunden:

| Ansicht / Runde | Referenz vorher | Neu | Referenz danach |
|---|---:|---:|---:|
| 3 / 1 | 18,66 | 19,20 | 23,93 |
| 3 / 2 | 24,49 | 19,01 | 23,87 |
| 4 / 1 | 21,31 | 16,08 | 21,27 |
| 4 / 2 | 21,29 | 17,26 | 23,11 |

Die erste Runde driftet stark und belegt für sich keinen Gewinn. In den stabilen Vergleichen 3/2 und 4/1 sinkt die Frame-Zeit um etwa 5,2 ms. Das entspricht ungefähr 41→53 bzw. 47→62 FPS in genau diesen Ansichten. Keine allgemeine oder geräteübergreifende FPS-Zusage.

Ein zusätzlicher rotierender Tageslauf mit Krümmung veränderte während der Messung seinen Szenenbestand (122 gegenüber später 190 Wasserzeichnungen pro 240 Frames). Seine 14,87 / 17,07 / 16,67 ms sind deshalb kein belastbarer A/B-Vergleich. Die Daten bleiben erhalten. Die anschließende Wiederholung mit festen Tagesansichten, Krümmung 2 und jeweils 300 Frames ergibt:

| Ansicht / Runde | Referenz vorher | Neu | Referenz danach |
|---|---:|---:|---:|
| 3 / 1 | 17,20 | 15,53 | 19,37 |
| 3 / 2 | 20,01 | 16,71 | 20,47 |
| 4 / 1 | 20,00 | 16,22 | 19,49 |
| 4 / 2 | 20,79 | 19,05 | 20,72 |

Auch hier driftet die erste Referenz. Die späteren Paare zeigen etwa 1,7–3,5 ms Gewinn. Der Nutzen hängt weiterhin von Ansicht und Last ab.

## Prüfungen

- Headless: Wiederverwendung, ungerade Größen, kleine Ziele, Fehlerpfade, Freigabe, geschützte Zeichenfehler; bestehende Wasserprogramm-Vorbereitung und Hitch-Diagnose bestanden.
- Native GL- und GLES-Shaderprüfung bestanden. GPU-Test mit unterschiedlich tiefen Farbflächen prüft tatsächliche Verdeckung sowie unveränderten Original-Tiefeninhalt. Kein Ersatz für einen Test auf physischem iPhone oder Switch.
- Acht eingefrorene Szenenvergleiche bei Nacht und acht bei Tag mit Außenweltkrümmung; Referenz- und Ergebnisbilder gespeichert, Wasseransichten visuell geprüft.
- „Weiter“ mit absichtlich kaltem Spiegelungsziel und kaltem Kopierprogramm bestanden. Ziel 855×478 unter sichtbarer Continue-Ladeabdeckung angelegt (0,18 ms gemessener API-Aufruf, kein GPU-Timing). Keine spätere Zielanlage nach Freigabe. Direkte Nachbarschaft bereit, Lichtcache gültig, keine Cachefehler. Ladezeit 3,00 s, größter abgedeckter Frame 72,27 ms. Ohne kontrollierten Gesamtvergleich kein Ladezeitgewinn behauptet.

## Sicherung / Reproduktion

Artefakte: `/Users/maarten/Documents/Recompile/artifacts/performance-water-20260928/`.
Dort liegen Ausgangsdateien, begrenzter Patch, finale Dateien, SHA256, Rohmessungen, Bilder und verworfene Probevarianten. `depth-probe/` ist ausdrücklich ungültig: Ein Fehler im Test-Upvalue-Zugriff wurde vom alten geschützten Zeichenaufruf abgefangen und ließ den Spiegelungspass aus. Dieser scheinbare Gewinn wird nicht verwendet. Der korrigierte Vollauflösungs-Tiefenversuch half nur in einem Teil der Ansichten; daraus entstand der anschließend separat getestete kleinere Zielpfad.

Native Treiber unter `tests/native`: `rc25_water_ablation.lua`, `rc25_water_production.lua`, `rc25_water_target_contract.lua`, `rc25_water_continue.lua`. Ausschließlich QA-Identität `vasc-video-polish-qa`, stumm; keine persönlichen Spielstände. Der Produktionstreiber nutzt weiterhin die historischen Testschalter `QA_UNIFIED` (Bildvergleich), `QA_DEPTH_FIXED` (feste Vergleichsansichten), `QA_UNIFIED_MOVING` (Rotation). `QA_CURVE`, `QA_CLOCK`, `QA_WEATHER`, `QA_MAPS` und `QA_FRAMES` wählen das Szenario. Die frühere Ergebnisfeldbezeichnung `sharedIrradiance` bedeutet in diesen Wasser-Proben lediglich neuer Spiegelungspfad an/aus; der finale Treiber nennt es `optimizedReflection`.

Noch erforderlich: breite Strecken-/Übergangsmessungen, weitere Wasser-/Surf-/Innenraumszenen und die tatsächlichen extremen Framedrops. Diese Runde markiert das Gesamtziel nicht als erreicht.
