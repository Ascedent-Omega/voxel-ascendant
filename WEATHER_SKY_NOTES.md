# Wetter und Sternenhimmel – lokaler Teststand

Version: 3.0.53-rc.18.weather.4, Basis 986dc38b (3.0.53-rc.18.hoenn.2).

- Räumlicher Regen und Sturm in Gen 1/2: eine wiederverwendete, tiefengeprüfte Geometriecharge. Vorhandene Häuser, Bäume und Geländeflächen verdecken dahinter liegende Tropfen. Die Fallbahnen enden auf abgetasteten Oberflächen; dort erscheinen kleine abgestufte Aufschläge. Oberflächen außerhalb geladener Karten bekommen keine Aufschläge.
- Maximal 605 Quads einschließlich Aufschlägen; neue Vertexdaten nur bei Änderung des Kartenbereichs, der Nachbarn oder Regen/Sturm. Animation im Shader, ohne zusätzliche bildschirmfüllende Renderfläche. Begrenzte Tropfengröße in Nahansicht. Fallback auf vorhandenen 2D-Regen bei Grafikfehlern.
- Pfützen bleiben an festen Weltpositionen. Kantige 2-Pixel-Ränder, ein schmaler dunkler Rand, abgestufter Himmelsschimmer und kleine achteckige Ringe. Originaler Untergrund bleibt sichtbar; bestehende Nachregen-Trocknung über WX MICRO EVENTS bleibt erhalten.
- Vorhandener Wolkenatlas: fünf abgestufte Töne, neutralere Unterseiten und transparente Randsäume entfernt. Auflösung und Zeichenzahl bleiben erhalten. Kein Weichzeichnen.
- Unregelmäßiges, deterministisches Sternfeld mit Winkelabstand statt korrelierter Spiral-/Höhenfolgen; dezenteres Funkeln und weniger große Sterne.
- Pikachu, Karpador und Lapras bleiben als Sternbilder erhalten und haben deutlichere Silhouetten. Projektion über die Tangentialebene reduziert die Formverzerrung nahe dem Zenit.

Referenz: Kanto Dynamic Weather (https://github.com/1-Camp0-1/Kanto-Dynamic-Weather), insbesondere Weltkoordinaten, Tiefentest und zurückbleibende Nässe. Implementierung für VASC eigenständig geschrieben. Keine Laufzeitabhängigkeit und kein importierter Fremdcode. Zusätzliche volumetrische Wolken, echte Szenenspiegelungen und ein neues Wettersimulationsmodell wurden nicht übernommen.

Die bekannten Einschränkungen: Himmelsschimmer ist eine stilisierte Beleuchtung, keine Spiegelung von Spielfiguren. Bildbasierte Kampfarenen behalten den passenden bisherigen 2D-Regen. Kein physischer Mobilgerätetest und keine pauschale FPS-Zusage.

Ergänzungen in weather.2:
- Zusätzlich drei Starter-Sternbilder je Region: Schiggy, Bisasam und Glumanda in Gen 1; dieselben Himmelsplätze zeigen in Gen 2 Endivie, Feurigel und Karnimani. Pikachu, Karpador und Lapras bleiben in beiden Generationen erhalten. Insgesamt sechs Sternbilder pro Region, kantige Sternpunkte und dezente Verbindungslinien.
- Regenwolken durchgehend neutral grau, Sturmwolken dunkler; die Nacht dunkelt beide zusätzlich ab. Derselbe Farbwert gilt für die beweglichen Wolken, die tiefe Wetterbank und schattenbegleitende Formationen. Auch weiße Atlaspixel bekommen graue Highlights. Keine zusätzlichen Wolkentexturen oder Renderpässe.
- Sonne, Mond und deren Wasserspiegelung werden bei Regen, Sturm, Schnee und Nebel verdeckt. Behebt insbesondere die helle Sonnenscheibe im Johto-Sturm und einen Lua-Ausdruck, der trotz Verdeckung einen Himmelskörper zurückgab.
- Der garantierte Regenbogen nach Regen benötigt jetzt ebenfalls Tageslicht; keine nächtlichen Regenbögen mehr.

## weather.3 – Schnee, Wetterschutz, Geräusche und Winterbäume

- Räumlicher Schnee in Gen 1/2: 484 kleine, tiefengeprüfte Pixel-Flocken in einer wiederverwendeten Geometriecharge, langsamer Fall und seitliches Treiben. Schneebelag wächst über den vorhandenen Wetterzustand, mit abgestuften hellen und bläulichen Flächen statt einer flachen Weißfärbung. Nächtlicher Schnee folgt dem Umgebungslicht.
- Dach-/Kronenschutz aus tatsächlicher Terrain- und Voxelprop-Geometrie. Ein 4-Pixel-Höhenraster hält Niederschlag oberhalb der oberen Fläche und unterdrückt Schnee/Pfützen unter Überhängen. Terrain und zusätzliche Voxelhäuser/Bäume bilden getrennte, atomar veröffentlichte Schichten. Gen-2-Diskcache speichert die Schutzdaten mit; Kartenadapter übernehmen sie. Rasterung und vier Abtastungen entlang der Windbahn sind konservative Näherungen, keine vollständige Kollisionssimulation. Nachbarschaftstextur und Felder sind begrenzt; kein GPU-Readback.
- Pfützen unterscheiden grüne Vegetation anhand ihrer Materialfarbe: weniger Schimmer/Fläche, mehr dunkle Nässe; auf Wegen stärkerer Wasserfilm. Dies ist eine Materialheuristik, kein Geländeabflussmodell. Regenbogen-Glitzer erscheint nur bei aufgeklartem Himmel, nicht über Schneefall.
- 23 neue eigene Stereo-PCM-Sounds: Regen im Freien, gedämpfter Regen unter Dach, Wind, Schneewind, drei Donnerrollen und je vier Varianten für Schnee, Wasser, feuchten Boden und nasses Gras. Keine Fremdsamples, keine Audiosynthese im Spiel. Lautstärke folgt dem vorhandenen SFX-Regler, Wetterwechsel blenden weich, Donner folgt zeitversetzt auf Blitze; Mute/Fokusverlust stoppen die Quellen. Wettergeräusche senken die Musik nicht mehr bei jedem Schritt ab. Dateiherkunft/Hashes: assets/audio/weather/SOURCES.json.
- Die neu modellierten Kanto-Voxel-Laubbäume (einschließlich Alabastia-Randbäumen und Voxel-Horizont) verlieren im Winter zu rund 90 Prozent ihre Blätter. Kantige, verzweigte Astmodelle ersetzen die Krone; Nadelbäume und ein positionsstabiler kleiner Anteil grüner Laubbäume bleiben. Im Frühjahr kehren die ursprünglichen Kronen zurück. Jahreszeit entscheidet, nicht die Auswahl von SNOW. Mesh-/Horizont-Caches berücksichtigen Winter; der Kronenschutz folgt der sichtbaren Geometrie. Native Kollision bleibt unverändert.

Winterlaub gilt für die genannten neu modellierten Kanto-Bäume und den echten Voxel-Horizont. Die atlasbasierten Johto-Baumhüllen und vorgerenderten Bitmap-/Fenster-Fernbilder erhalten damit noch keine kahlen Astvarianten. Schnee, Regenschutz und Wetteraudio sind in beiden Generationen enthalten.

## weather.4 – Tiefschnee und weniger Wetterarbeit

- Neue Option unter Wetter/Kulisse: SCHNEETIEFE → NORMAL / TIEF (englisch SNOW DEPTH → NORMAL / DEEP), in Gen 1 und Gen 2. NORMAL bleibt Standard. TIEF ergänzt echte, kantige Schneeschichten auf freien Bodenflächen, mit drei Zielhöhen von 2/4/6 Weltpixeln. Der bestehende Schneezustand steuert Aufbau und Tauphase; sechzehn kleine Höhenschritte aktualisieren den bereits vorhandenen Mesh. Bei ausgeschalteten Mikroeffekten gilt wie beim bisherigen Belag die direkte Wetterumschaltung.
- Wasser, nicht begehbare Flächen, Unebenheiten, überdeckte Stellen und Eingänge einschließlich ihrer direkten Antrittszellen erhalten keine Schneeberge. Bewegung, Kollisionen und Kampfregeln bleiben unverändert. Dachschnee bleibt beim vorhandenen Oberflächenbelag. Kein zusätzlicher Vollbildpass und keine neue Shaderfamilie: Die Schneeschichten benutzen den vorhandenen Landschaftsrenderer.
- Ein begrenzter Tiefschnee-Mesh um den Blickfokus, maximal 5445 Quads; gleiche Nachbarhöhen sparen Innenwände. Am Rand sinkt die Zusatzhöhe in den weiter bestehenden flachen Belag ab. Geometrie wird nur bei geändertem Blickbereich oder Schutzfeld aufgebaut; wachsende/schmelzende Höhe aktualisiert Vertices, nicht die Geländeabfragen. NORMAL, Innenraum und abgeschmolzener Schnee zeichnen keine Zusatzgeometrie. Ein Rendererfehler fällt auf den bisherigen Belag zurück.
- Regen-/Schneeaufbau verwendet einen lokalen Cache für native 16-Pixel-Bodenzellen. Dachhöhen bleiben exakt pro Abfrage erhalten. In den geprüften Schneeszenen: Alabastia 432 statt 2210 vollständige Geländeabfragen; Neuborkia 385 statt 1980. Rund 80 Prozent weniger vollständige Bodenprüfungen bei diesen Partikelaufbauten, keine FPS-Angabe.
- Bei trockenem Wetter entfallen die Vorbereitung des Dachfeldes und seine Texturbindung. Der Bodenshader liest die Dachtextur nur für tatsächlich wetterbehandelte Oberseiten/Gras. Wetterbilder, Regentropfenzahl und der Voxel-Look bleiben erhalten.

Die Tiefschnee-Option ist eine Darstellungserweiterung, keine begehbare Schneehöhen- oder Spurenphysik. Geräteabnahme auf iOS/Android und VR bleibt offen.
