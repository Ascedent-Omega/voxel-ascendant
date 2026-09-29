# Silph-Co.-Voxelteleporter

Lokaler Entwicklungsstand auf `39c69bda` (Silph-Innenräume / RC14-Basis), Branch `codex/silph-voxel-teleport-20260927`. Keine Veröffentlichung und keine Änderung an Spielständen.

Die Figur löst sich von Kopf/Schulter abwärts in kleine, seitlich aufwärts driftende Würfel auf. Am Ziel läuft die Bewegung rückwärts. Der Effekt liest das fertige Darstellungsnetz nach Charakterwahl, Kleidung und Figuren-Rig; Texturkoordinaten und Kleidung bleiben erhalten. Red, Blue und Green benötigen keine getrennten Effektgrafiken.

- 66 Logikframes Auflösung, 12 Frames Übergangsblende, 12 Frames Aufblende, 66 Frames Rekonstruktion: nominell 2,6 Sekunden bei 60 Hz, zuzüglich bestehender Ladefreigabe.
- Nur echte Warp-Pads zwischen Silph-Etagen 2–11 bei aktivem Voxelmodus. 2D, Aufzüge, Türen, Treppen, Löcher und die Teleport-Attacke behalten ihre ursprünglichen Abläufe.
- Die Engine behält Zielauflösung, Zustandsstapel, Kollisions-/Ankunftszelle und Kartenwechsel. Die vorhandene Ladefreigabe hält kalte Ziele weiterhin verdeckt. Neuere Engine-Versionen liefern eine vorgelagerte Drehphase; deren bereits aufgelöste Fortsetzung wird direkt in den Effekt übernommen.
- Ein dynamisches Effektmesh pro Phase, Wiederverwendung der Vertexdaten, keine Textur-Rücklesung und keine globale Zufallsfolge. Bei Abschluss/Kartenabbruch wird das Netz freigegeben. Die Figur bleibt während der Animation auf ihrem Pad; ihr Schatten zerfällt mit.
- Der generierte Effekt wird erst innerhalb des finalen `Voxel3D.draw` angewandt. So bleiben die bestehenden HD-/Voxel-/Kleidungsanbieter Besitzer der Figur. Die Kamera-Silhouette verwendet ebenfalls die Fragmente; ohne Schattenkarten entfällt der sonst zurückbleibende volle Figurenschatten.

## Prüfung

`tests/silph_teleport_test.lua`: alte native Transition, Ziel-/Pad-/2D-Ausschlüsse, Auflösungs-/Blendentrennung, gehaltene Ladefreigabe, exakte Callback-/Parameterweitergabe, wiederholte Installation, neue vorgeschaltete Drehphase, getrennte Hin-/Rückblendendauer, Eingabefreigabe und Kartenabbruch. Geometrieprüfung: ursprüngliche Positionen/UVs bei beiden Endpunkten, vollständiges Verschwinden, gültige Indizes, keine Mesh-Neuanlage je Frame, Freigabe.

`tests/native/silph_teleport.lua`: LÖVE 11.5 / Engine 0.3.2 / KASC 6.7.27. Red: echtes Silph-3F-Pad zu einem anderen Pad derselben Karte. Blue und Green: echte Pads von Silph 3F nach 5F, einschließlich kaltem Ziel. Alle drei mit Voxel-Figuren, korrektem Ziel, freier Steuerung, ohne nachlaufende Drehbewegung; anschließend echter 2D-Teleport unverändert. Beobachtet: Red/Blue je 220 Fragmente / 5.280 Vertices, Green 286 / 6.864. Native Screenshots, Log und animierte Vorschau unter `output/vasc-silph-teleport-20260927` im Recompile-Arbeitsbereich.

Keine physische Mobilgeräteprüfung. Diese Änderung ist ein separater Arbeitsstand, kein neues veröffentlichtes Modpaket.
