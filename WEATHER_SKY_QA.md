# Wetter-/Himmelprüfung

Geprüft mit LÖVE 11.5 unter macOS, isolierte Identitäten vasc-weather-sky-qa-20260928 und vasc-weather-sky-gen2-qa-20260928. Keine Benutzer-Spielstände verändert.

- Deterministischer Test: Einheitsvektoren, keine wiederholten Sternhöhen, Verteilung über Azimut/Elevation, stabil bei anderer Abfragereihenfolge, Mindestabstand. PASS.
- Regen: feste Weltpositionen beim Kamerawechsel, begrenzte Vertexzahl, Aufschläge nur auf erlaubten Oberflächen, Gelände-Höhen, monotone Zeit und derselbe Zeitpunkt für beide VR-Augen. PASS.
- Wiederverwendeter Mesh, Nullarbeit bei klarem Wetter/Innenraum, wiederhergestellter Grafikzustand bei absichtlichem Zeichenfehler, Fehler-Latch und Wiederherstellung nach Invalidation. PASS.
- Arena-Himmelregression. PASS.
- Native Gen 1: Alabastia bei Tag, Regen/Sturm, Nahansicht der Pfützen, Nacht in drei Blickrichtungen, Innenraum ohne Regen, echter Overworld-Kampf mit Regen. PASS.
- Native Crystal: Neuborkia bei Regen/Sturm/Nacht; 3D-Brücke aktiv. PASS.
- Produktions-Bodenshader in Gen 1/2 sowie neue Wolken-/Regenprogramme mit love.graphics.validateShader für GL und GLES geprüft. PASS.
- In den geprüften Gen-1-Szenen 424 Regen- bzw. 545 Sturmquads; Gen 2 409/530. Jeweils ein Wetter-Draw. Dies sind Zähler, keine FPS-Messung.

Native Bilder und Logs: output/vasc-weather-sky-20260928/evidence im Recompile-Arbeitsbereich. Physische iOS-/Android-Geräte und VR-Hardware wurden nicht live geprüft. Gen-2-Kampfprüfung ergänzt in weather.3. Die GLES-Prüfung ersetzt keine Geräteabnahme.

## weather.2 – Starter und konsistenter Regenhimmel

- Datenprüfung für alle sechs neuen Starter: richtige regionale IDs, identische Ersatzplätze, gültige Linienindizes, begrenzte Punkt-/Linienzahl. PASS.
- Nativer Gen-1-/Crystal-Renderer: sechs Sternbilder pro Region, korrekte Starter, alle Punkte im zentrierten Sichtfeld; je eine Dreieransicht direkt mit Sky._paintStars gerendert. Visuell geprüft. PASS.
- Produktions-Wolkenshader auf GPU mit weißem Quellpixel: Regen/Sturm bei Tag/Nacht ergeben neutrale graue Highlights unter 0,53 statt Weiß. GL-/GLES-Kompilierung. PASS.
- Echter SkyEvents-Painter mit garantiertem Nachregen-Ereignis: nachts null Regenbogen-Draws, bei Tag ein Draw. PASS.
- Gemeinsame Sonnen-/Mondsichtbarkeit für Regen, Sturm, Schnee, Nebel sowie klare/heiße Gegenproben. Native Sturmaufnahme in Crystal nach Korrektur ohne Sonnenscheibe visuell geprüft. PASS.
- Gen-1-/Crystal-Szenen, Innenraum, Gen-1-Kampf und Shaderprüfungen nach der Änderung wiederholt. PASS.

Native Zusatzprüfung: tests/native/weather_sky_details.lua. Sternbild-Detailbilder sind Ansichten des echten Renderers mit gezielt ausgerichteter Kamera, keine Screenshots aus einer laufenden Erkundung. Wolken und Regen in der Galerie stammen aus den Spielaufnahmen. Keine zusätzlichen Texturatlanten oder bildschirmfüllenden Pässe; keine neue FPS-Messung.

## weather.3 – Abschlussprüfung

- Automatisiert: Dach-/Wandunterscheidung, geneigte Dächer, instanzierte Versätze, atomarer Austausch, getrennte Prop-/Terrain-Schichten, Blattverlust ohne verbliebene Kronenmaske, Kartenadapter und persistenter Cache einschließlich abgelehnter unvollständiger Metadaten. PASS.
- Audio mit kontrollierten Quellen: Freiluft-/Dach-Überblendung, keine Quellallokation beim Schritt, verzögerter/eindeutiger Donner auch bei doppelten Renderereignissen, SFX=0, Fokusverlust, Innenraum und Freigabe. PASS. Alle 23 WAVs: Hashes, Stereo-PCM, Pegel/DC und Schleifennaht numerisch geprüft. Native Decoder-/Quellladung in beiden Generationen ohne Fehler. Die Hörprobe ist eine Mischung der tatsächlichen Samples; subjektive Hörabnahme durch den Benutzer steht aus.
- Winter: 864/961 deterministische Laubbaumplätze kahl, 97 grün; Nadelbäume unverändert, Astboxen innerhalb des Fußabdrucks, Originalkronen unverändert, Rückkehr zur belaubten Variante nach Winter. PASS. Native Alabastia-Aufnahme zeigt kahle Randbäume und kahlen Voxel-Horizont. Der saisonale Cachewechsel funktioniert ohne Neustart.
- Native Gen 1 erneut: Regen, Sturm, anfangender und aufgebauter Schnee, Winter, drei Nachtsichten, Innenraum und echter Voxel-Kampf. PASS. Erkannte obere Flächen in Alabastia: 2008 Rasterzellen, davon 810 mit ausreichender Überdeckung; Nachbarschaftstextur 227328 Byte.
- Native Crystal erneut: Regen, Sturm, Nacht, anfangender/aufgebauter Schnee und echter MAP-Voxel-Kampf Typhlosion gegen Sentret bis zum Befehlsmenü. PASS. Neuborkia: 2132 obere Rasterzellen, davon 1464 mit ausreichender Überdeckung; Nachbarschaftstextur 230912 Byte.
- Beide Produktions-Bodenshader: full/mobile-safe/mobile-core, Rastervarianten, GL/GLES; räumlicher Schnee/Regen und Wolkenprogramme ebenfalls erfolgreich kompiliert. PASS.
- Bestehende Wetter-/Sternen-, Arena-Mobil-, Material-/Lichtregressionen sowie 8223 Fenster-/Wand-Volumenpaare. PASS.

Schneeakkumulation wurde gezielt um 119 Sekunden vorgerückt, Jahreszeit für das Winterbild auf den Winterabschnitt gesetzt. Keine FPS-/Geräteabnahme. Der Laubverlust umfasst die Kanto-Voxelmodelle und deren echten Voxel-Horizont; Johto-Atlasbäume und vorgerenderte Fernbilder sind nicht enthalten.

## weather.4 – Tiefschnee und Optimierung

- Neue Option in beiden Generationen registriert; NORMAL bleibt Vorgabe. Geometrieprüfung: Stufen 2/4/6, begrenzte Quads, keine Schneeberge auf Wasser/gesperrten Zellen, unter Dächern, über Höhenkanten oder in Eingangs-/Antrittszellen. PASS.
- Rendererprüfung: NORMAL/Innenraum/kein Schneerest ohne Zusatzdraw; unveränderter Blick verwendet den Mesh weiter; Aufbau/Tauen lädt nur neue Höhen hoch; Dachrevision löst Neubau aus; Fehlerpfad stellt Grafikzustand wieder her und kann nach Invalidation wieder anlaufen. PASS.
- Exakte Bodenabfrage-Parität gegen den bisherigen Einzelpfad: 2048 Testabfragen, identische vier Oberflächenwerte, acht vollständige Zellauflösungen. Trockener Himmel überspringt Dachvorbereitung und deaktiviert den Texturzugriff. PASS.
- Native macOS Gen 1: normaler Schnee/Tiefschnee/Umschalten sowie Winter, Regen, Sturm, Nacht und Innenraum; Tiefschnee im echten MAP-Kampf. PASS. Gen-1-Aufnahme: 1227 Schneequads in einem zusätzlichen Draw, bei unveränderter Kamera kein neuer Aufbau.
- Native macOS Crystal: normaler Schnee/Tiefschnee/Umschalten und echter MAP-Kampf mit Regen sowie Tiefschnee. PASS. Johto-Aufnahme: 898 Schneequads in einem zusätzlichen Draw. Die Weltgeometrie kann beim Nachladen eine weitere gültige Dachrevision liefern; nach stabilem Aufbau wird der Mesh wiederverwendet.
- Native Partikel-Abfragezähler: Gen 1 2210 Abfragen / 432 vollständige Bodenauflösungen; Gen 2 1980 / 385. Rund 80 Prozent weniger vollständige Geländeprüfungen für diese Partikelaufbauten. Keine FPS-Messung oder Kostenneutralitätszusage für die zusätzliche Tiefschneegeometrie.
- GL/GLES-Kompilierung aller bisherigen Boden-/Regen-/Wolkenvarianten sowie Wetter-, Audio-, Schutzfeld-, Cache-, Sternen-, Winterbaum- und Materialregressionen. PASS.

Bilder: deep-snow-after.png, gen2-deep-snow.png, battle-deep-snow-after.png, gen2-battle-deep-snow.png. Die Tiefschneeschichten nutzen den bestehenden Schneebelag als Zustandsgeber. Die Vorschau spult 119 Sekunden Schneeaufbau vor. Mobil-/VR-Geräte sind weiterhin nicht physisch geprüft.
