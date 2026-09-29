# RC36 – Kampfplatzsuche auf benötigte Felder begrenzen

28.09.2026. Gesamtziel Performance weiterhin offen.

## Ursache und Änderung

extended_characters.installRivalPresentation fragt beim Kartenwechsel bereits
OverworldBattle.wantsFront ab. Dessen Preflight sucht einen sicheren Kampfplatz.
Der native RC35-Detailtrace zeigte dafür auf Route 16 18,73 ms. Die Auswahl darf
nicht durch eine bloße Optionsabfrage ersetzt werden: eine fehlgeschlagene
Platzierung muss weiterhin die richtige Porträtvariante erhalten.

lib/BattleArena.lua baut das Kollisionsraster nun bedarfsgerecht innerhalb genau
eines Suchaufrufs auf. Authored courts prüfen ihre tatsächlichen Grundflächen;
die lokale Suche besucht nur Kandidaten im bereits bisher vorgeschriebenen
Radius. Reihenfolge, Distanzbewertung, Gleichstände, Shapes, Wasser, Gras,
Warp-Ausschlüsse, Möbel, Höhen und Sichtprüfung bleiben erhalten. Es gibt keinen
über Aufrufe hinweg behaltenen Kollisionscache und keine neue Ungültigkeitsfrist.

## Überprüfung

- tests/arena_footprints_test.lua: 1.152 exakte Vergleiche gegen die gesicherte
  Vorversion, einschließlich Radien null/negativ/gebrochen, Kartenränder,
  Wasser, Höhe, kompakter Möbelprüfung, freier/belegter Sicht und gleichen
  Kartenobjekten nach Änderung ihrer Hindernisse. Bestanden.
- Native rc36_arena_footprints.lua: Celadon, Route 7, Route 16, Saffronia,
  Silph 1F, Mansion 2F und Rock Tunnel 1F, jeweils drei Positionen auf Land und
  surfend. Alle 42 Arenen und Review-Daten exakt gleich. Wiederholung mit
  umgekehrter Messreihenfolge ebenfalls exakt gleich (84 Paare im zweiten Lauf).
- Warmer Vergleich, Kandidat vor Referenz: über 42 Abfragen 22,59 statt
  47,61 ms. Das ist die Summe einzelner Suchaufrufe, keine Framezeit.
  Auf Route 16 sank die Anzahl der Walkable-Abfragen von 4.509 auf 615,
  in Celadon von 5.637 auf 408. Diese Zählung umfasst alle sechs Fälle pro Karte.
- Native Spielstrecke Celadon → Route 7 → Celadon → Route 16 → Celadon bestand,
  mit Voxel-Gebäuden an, Voxel 6, Nacht, Regen und Tilt Shift. Rivalen-Callback
  auf Route 16: 12,81 ms, zuvor 18,73; die zwei Celadon-Eintritte: 1,22/1,07 ms,
  zuvor 4,40/4,77. Spielstrecken sind zeitabhängig und kein kontrollierter FPS-A/B.

Nach Ausschluss des Setups, abgedeckter Frames und künstlicher QA-Wegsuche samt
Folgeframe: 2.671 Frames, Abstand p95 22,47 ms, p99 28,75 ms, Maximum 76,74 ms;
CPU-Maximum 54,28 ms. RC35-Detail davor: 2.880 Frames, p95 23,93 ms,
p99 31,69 ms, Maximum 103,41 ms, CPU-Maximum 101,83 ms. Nicht alle Wartezeit ist
zugeordnet; sie wird nicht als GPU-Kosten ausgegeben. Unterschiedliche Spawns
verbieten einen allgemeinen FPS-Gewinn aus den Maxima.

Die größte verbliebene CPU-Spitze im neuen Lauf enthält ein erstmals benötigtes
Pokémon-Modell: Content.record 26,77 ms. Weitere offene Arbeit: Modelle zuverlässig
vor Sichtbarkeit vorbereiten, die synchrone Möbel-Auflistung vor dem eigentlichen
PropBatch-Zeitbudget begrenzen und beide Generationen auf längeren Strecken prüfen.
Gen2 hat einen eigenen BattleArena-Pfad und wurde hier nicht geändert. Dieser
Schritt belegt weder flüssiges Spielen aller Karten noch kleiner Geräte.

Artefakte: artifacts/performance-arena-footprints-20260928. quality und
warm-quality enthalten exakte Referenzvergleiche, travel den vollständigen Trace.
QA_STALL_TRACE war zunächst „1“; der dadurch im Worktree entstandene Trace wurde
anschließend unverändert nach travel/trace.json verschoben. Kein Release und
keine persönlichen Optionen/Spielstände verändert. Alle nativen Prozesse beendet.
