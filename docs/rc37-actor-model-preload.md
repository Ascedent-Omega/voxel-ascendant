# RC37 – Importierte Pokémon-Modelle in der Ladevorbereitung

28.09.2026. Das Performanceziel für beide Generationen bleibt offen.

## Ursache und Umsetzung

Die vorhandenen prewarmWorldCards/worldCardsReady-Schnittstellen bereiteten
Menschen-Atlanten vor. Cobblemon-Modelle bereits vorhandener Pokémon wurden
hingegen noch beim ersten sichtbaren StadiumMon:setSpecies dekodiert.

CobblemonPack stellt jetzt prewarmEntities und entitiesReady bereit. Sie lesen
nur die bereits vorhandenen Figuren des angefragten Gebiets mit explizit
gewählter Quelle cobblemon. Dex, Erscheinungsvariante und Inhaltsrevision
bestimmen die Identität. Jede Vorbereitungsabfrage lädt höchstens ein Modell
samt seiner regulären Textur; die Bereitschaftsabfrage lädt nichts. Kein
hypothetisches Pokémon wird erzeugt, kein Pose-/Bewegungszustand verändert.

Die integrierte APO-Vorbereitung bezieht diese Prüfung vor den Menschen-Sprites
in ihre bestehenden Schnittstellen ein, auch bei ausgeschalteten HD-Menschen.
Beide Generationen verwenden denselben öffentlichen CobblemonPack. Vorhandene
Ladefreigaben können damit auf die Modelle warten. Fehler optionaler Inhalte
oder GPU-Ressourcen geben weiterhin den vorhandenen Sprite-Fallback frei.

Die tatsächlichen Figuren halten die vorbereiteten Modellobjekte bis zum
Kartenwechsel beziehungsweise ihrer Entfernung fest. Sonst würden bereits
vier bis fünf große Modelle den 12-MiB-Rückkehrcache füllen und frühe Modelle
vor dem ersten Bild wieder verlieren. Dieser Cache bleibt unverändert begrenzt;
die aktiven Figurenreferenzen sind wie aktive Render-Rigs zusätzlicher Speicher,
kein Teil dieser 12-MiB-Garantie. Kartenwechsel lösen alle Vorbereitungsreferenzen,
innerhalb der Karte werden entfernte Figuren über schwache Schlüssel freigegeben.
Die späteren Rigs teilen dieselben Daten und Texturen, keine zweite GPU-Kopie.

## Belege

- Headless Actor-Test: höchstens ein Modell pro Schritt, 20 Figuren über der
  LRU-Anzahlgrenze, kein erneutes Dekodieren nach GC, gleiche Texturen,
  unveränderte Positionen, Variantenänderungen inklusive In-place-Geschlecht,
  Inhaltsrevision, Kartenidentität, fehlende Inhalte, reine Bereitschaftsabfrage
  und Freigabe entfernter Figuren. Unter dem Lua-Testlauf braucht die Freigabe
  verschachtelter schwacher Referenzen zwei vollständige GC-Runden.
- Bestehende Residency- und Failure-Lifecycle-Tests bestehen: LRU-/Bytegrenzen,
  Live-Modelle bei Eviction, Varianten, Epochen, Übergröße, Texturbuchhaltung,
  fehlende Modelle und fünf Teilfehler beim Texturaufbau.
- Native Red und Crystal: jeweils neun Modellvarianten über die echten
  worldCardsReady/prewarmWorldCards-APIs vorbereitet (normale Arten, weibliches
  und schillerndes Pikachu). Je neun Dekodierungen während der Vorbereitung,
  null zusätzliche Dekodierungen beim anschließenden Rig-/Texturaufbau.
  Diese Prüfung nutzt isolierte QA-Figurenlisten, keine neun Gameplay-Spawns.
  Vorbereitung insgesamt 79,30/80,96 ms; anschließendes setSpecies plus
  Texturabfrage zusammen 7,25/7,75 ms, maximal je 1,56 ms pro Figur.
  Dies misst nicht die komplette Pose-/Upload-/Framezeit. Ein Modell pro Schritt
  ist außerdem keine harte Millisekunden-Garantie.
- Echter Continue-Ablauf mit Voxel-Gebäuden an: bestanden. Celadon, 128-MiB-
  Weltcache, Ladefreigabe nach 3,93 s; unter diesem Budget drei von acht
  gefundenen Karten vorbereitet. Kein Anspruch, die ganze Region sei resident.
- Bestehender Nachbarfiguren-Test geprüft: Laden, reine Bereitschaft, geänderte
  Kartenobjekte, fehlgeschlagene optionale Vorschauen und Rückkehr zur alten Karte.

- Abschließender nativer Crystal-Szenentest: 171/171 erfolgreiche Render,
  kein Lichtfehler; Screenshot mit Gebäuden, Nacht und Regen geprüft.
  Alle Testprozesse beendet.

## Streckenmessung und Grenzen

Native Strecke Celadon → Route 7 → Celadon → Route 16 → Celadon bestanden;
Voxel-Gebäude an, Nacht/Regen/Voxel 6/Tilt Shift wie zuvor. Nach Ausschluss von
Setup, abgedeckten Frames und künstlicher QA-Wegsuche samt Folgeframe:
2.646 Frames, p95 21,21 ms, p99 26,79 ms, maximaler Abstand 66,28 ms,
CPU-Maximum 49,74 ms. Zeitabhängige Spawns machen dies nicht zu einem
kontrollierten FPS-Vergleich gegen RC36.

Das letzte sichtbare Maximum enthält weiterhin eine neue Modellanforderung
mit 23,22 ms Content.record. Figuren, die erst später entstehen, kennt die
Ankunftsvorbereitung noch nicht. Die nächste notwendige Arbeit ist deshalb
zeitlich aufgeteiltes oder vorausschauendes Vorbereiten dieser späteren Modelle,
nicht lediglich weiteres Vergrößern des Start-Ladebildschirms. Auch Licht-Shader
und Kartenwechsel-Callbacks bleiben messbare Spitzen. Die letzte Änderung zur
Freigabe von Modellreferenzen beim Kartenwechsel wurde anschließend mit dem
gezielten Lifecycle-Test und dem nativen Nachbar-Test nachgeprüft; die genannten
Streckenwerte stammen vom Lauf unmittelbar davor.

Artefakte: artifacts/performance-actor-model-preload-20260928. Tests arbeiten
stumm ausschließlich in der QA-Identität. Keine persönlichen Spielstände oder
Optionen geändert. Kein Release und kein Beleg für alle Karten/kleine Geräte.
