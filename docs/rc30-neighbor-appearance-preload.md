# RC30 – tatsächlich ausgewählte Nachbarfiguren vorladen

28.09.2026. Teilverbesserung des laufenden Performanceziels. Erstmalige
Pokémon-Modelle und weitere Kartenwechselarbeit sind weiterhin offen.

## Ursache

Der in RC28 verworfene Versuch betrachtete nur die Sprite-Definitionen von
Nachbar-NPCs. Sie tragen vor dem Kartenwechsel noch die ursprüngliche Darstellung.
Das spätere Voxel-/HD-Bild war deshalb nicht Bestandteil der Kartenfreigabe.

Die vorhandene `walkingSprites.scenerySprite`-Schnittstelle wählt dieselbe
Katalogdarstellung samt Grafikstil für eine reine Ansicht aus. RC30 verwendet
sie während der bestehenden, abgedeckten Vorbereitung für bereits vorhandene
NPCs unmittelbar angeschlossener, residenter Karten. Es werden keine Figuren
in die Spielwelt eingesetzt, bewegt oder aktualisiert.

`prewarmWorldCards` erledigt weiter höchstens einen Vorbereitungsschritt pro
Aufruf. Nach der aktuellen Karte werden die ausgewählten Bildatlanten und
Laufbilder der Nachbarfiguren in den bereits existierenden gemeinsamen Caches
vorbereitet. Zukünftige Animations-Kompositflächen werden dabei nicht vorgebaut,
damit sie nicht die laufende Besetzung aus deren Budget verdrängen.

`worldCardsReady` wartet nun auch auf diese endliche Arbeit. Die Abfrage liest
keine Dateien und erzeugt keine GPU-Bilder. Die Metadaten gehören zu genau einer
aktuellen Karten-/Nachbarlisten-/Stil-Kombination; Kartenwechsel oder neue Quellen
machen sie ungültig. Nicht verbundene und nicht residente Karten werden ignoriert.
Optionale Bildfehler bleiben terminal und blockieren die Freigabe nicht dauerhaft.
Beim Entfernen des Render-Patches werden die zusätzlichen Referenzen verworfen.

Die Bilddateien bleiben im vorhandenen Assets-Cache; es wird keine zweite GPU-Kopie
angelegt. RC30 begrenzt die Auswahl auf die vorhandene direkte Nachbarschaft, führt
aber keinen neuen globalen Speicherverwalter für die gesamten Personenbilder ein.

## Kontrollierter nativer Vergleich

Isolierte stumme QA, Voxel-Gebäude ausdrücklich aktiv, Route 16 mit den direkt
angrenzenden Karten. In der Referenz wird ausschließlich die neue Nachbarvorbereitung
für diesen Test deaktiviert. Beide Varianten bereiten zunächst die aktuelle Karte
vor und lösen anschließend die später ausgewählte Darstellung von 18 Nachbarfiguren
auf. NPC-Positionen und Sprite-Referenzen bleiben unverändert.

| Messung | Bisher nur aktuelle Karte | Mit Nachbarvorbereitung |
| --- | ---: | ---: |
| Vorbereitungsschritte | 26 | 69 |
| gesamte Funktionszeit Vorbereitung | 152,02 ms | 289,96 ms |
| Bildladeaufrufe nach Freigabe | 10 | 0 |
| Zeit dieser nachträglichen Bildladeaufrufe | 114,19 ms | 0 ms |

Das sind Funktionssummen, keine Gesamt-Ladezeit oder FPS-Werte. Die Arbeit wird
vorgezogen, nicht vollständig beseitigt. Alle 18 ausgewählten Bildpfade stimmen
pro NPC-ID zwischen Referenz und Kandidat überein; die Reihenfolge der Ghost-Liste
ist nicht stabil und wurde deshalb nicht als Identitätsvergleich verwendet.

Der zusätzliche Lauf `lifecycle-final` bestand außerdem: wiederholte Bereitschaftsabfragen
ohne Bildladen, neue Kartenidentität, nicht verbundene Karte, absichtlich fehlschlagende
Vorschau und anschließende Wiederherstellung. Die Figuren behalten ihre Originalrenderer.

## Echte Übergänge

`travel-final` bestand Celadon → Route 7 → Celadon → Route 16 → Celadon mit
2.297 erfassten Spielframes und aktivierten Voxel-Gebäuden. Die Ausgangskarte erhielt
in dieser Teststrecke zunächst abgedeckte Updates über die reguläre Vorladelogik;
danach erfolgten vier native Kartenwechsel. Alle erfassten Personenbild-Ladevorgänge
über 5 ms lagen unter der Abdeckung, einschließlich der Biker-Bilder mit 21–22 ms.
Während der sichtbaren Strecke gab es keinen Personenbild-Ladeaufruf über 5 ms.
Das ist kein Nachweis, dass sämtliche sonstigen Frame-Hänger behoben sind.

Die verworfenen Fixture-Läufe `travel` und `travel-cards` sind keine Spiel-Regressionsbelege:
Der erste erwartete von einer direkt eingesetzten Testszene eine Warp-Prop-Batch-Quittung;
der zweite ließ nach dem Testmenü eine weitere Abdeckung auf dem Stack zurück.
`travel-final` verwendet eine einfache QA-Abdeckung und prüft den Kartenbild-Gate
gezielt. Der tatsächliche Weiter-Ablauf wird separat getestet.

Artefakte: `artifacts/performance-neighbor-appearance-20260928` im Hauptarbeitsbereich.
Produktionsänderung ausschließlich in der integrierten `src/voxel_characters.lua`.
Keine persönlichen Spielstände und kein Release verändert.

## Abschließender Weiter-Test

`continue-verified` bestand mit dem finalen Code den echten Weiter-Ladeablauf in
Celadon, Voxel-Gebäude eingeschaltet und 128 MiB Testbudget. Die Freigabe erfolgte
nach 3,07 s und 151 abgedeckten Frames; der längste abgedeckte Frame dauerte
66,96 ms. Szene und Personenbilder waren bei Freigabe bereit. Das ist ein einzelner
Funktionslauf und kein Vergleich der Gesamtperformance. Das bestehende Speicherlimit
begrenzte die regionale Vorbereitung auf drei von acht entdeckten Karten.

Der vorausgehende Lauf `continue-final` bestand ebenfalls; sein fertiges Bild wurde
visuell geprüft (Voxel-Figuren, Gebäude und beleuchtete Fenster sichtbar). Die letzten
Guards verwerfen die Nachbarreferenzen beim Kartenwechsel oder ausgeschalteten
Figurenmodus und prüfen den Typ der Verbindungsdaten. `lifecycle-final` und
`continue-verified` liefen danach erfolgreich. Beide nativen Prozesse sind beendet.

Konstante FPS, insbesondere in den zuvor gemeldeten Problemstädten und auf mobilen
Geräten, sind damit weiterhin nicht nachgewiesen. Kalte Pokémon-Modelle und andere
Kartenwechselspitzen bleiben Teil des offenen Performanceziels.
