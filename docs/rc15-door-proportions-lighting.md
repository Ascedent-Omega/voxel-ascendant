# VASC 3.0.57-rc.15 – Türproportionen und beleuchtete Glasscheiben

Zwei nebeneinanderliegende native Ausgangsfelder wurden zu einer breiten Öffnung zusammengefasst; rc.14 legte darüber eine einzige Holztürtextur. Jetzt begrenzt die Raumdarstellung geschlossene einzelne Holzflügel auf maximal zwei Drittel der Türhöhe, mittig in der Öffnung. Die übrige Breite wird wieder von der vorhandenen Wand ausgefüllt. Native Warps, Kollisionen, Geländehöhen und Karten bleiben unangetastet.

Bewegliche äußere Glastürflügel enthalten getrennte, beim Laden vorbereitete Rahmen- und Glasmeshes. Nur die Scheiben erhalten dieselbe zeitabhängige Aufhellung wie die Gebäudefenster, einschließlich des bestehenden Lichtschalters. Rahmen/Querstreben bleiben normal schattiert. Beide Meshes bewegen sich mit derselben zwischengespeicherten Matrix. Es entstehen beim Öffnen keine neuen Texturen/Geometrien; keine separate pro-Frame-Ansicht der Zielkarte.

Validierung: sechs Regressionstests (Glas, Arenen, Raumgrenzen, überschneidungsfreie Wandflächen, native Raummasken, Alabastia-Fenster) bestanden. Der native Kartenlauf prüft 145 Räume / 103 geschlossene Holztüröffnungen. Tag-/Nachtaufnahmen zeigen blaue Gläser bei Tag und warme beleuchtete Scheiben bei Nacht; Rahmen bleiben dunkel. Sichtbare Holztüren in Hotel, Blau-Haus und Vertania kontrolliert. Die erste Aufnahme der Prismania-Villa zeigte aufgrund der Kameraposition eine Wand und wird nicht als visueller Nachweis verwendet. Geometrieprüfung dieses Raums besteht.

Zusammen mit KASC 6.7.30-rc.1 geprüft: Pyro fehlt in der alten Arena auch nach Speichern/Laden, einmaliger Standort im Vulkan. KASC-Basisprüfung und Grenzen stehen im zugehörigen BASE_INTEGRATION_AUDIT.md. Keine physische Android-FPS-Messung, keine Behauptung eines vollständigen Spieldurchlaufs.

Native Belege: artifacts/kasc-complete-base-audit-20260930/{native.log,glass-close.log,*-proportions.png,saffron-glass-close-*.png}. Wiederholbarer Treiber: tools/qa_door_proportions_lighting.lua.
