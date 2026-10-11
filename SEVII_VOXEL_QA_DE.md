# Sevii Full Voxel – VASC 3.0.61, lokaler Test 7

Historischer Prüfbericht für Test 7. Die Übernahme auf die aktuelle
öffentliche VASC-Version 3.0.62 ist ein neuer Entwicklungsstand; die hier
genannten Spiel- und Sichtprüfungen belegen diesen neuen Stand noch nicht.

Basis: öffentlicher VASC-Stand 3.0.61, Commit `68e33c328df623bfee3ed07a83fb39dfb370eee2`. Der komplette öffentliche Stand einschließlich Halloween-Hotfix bleibt enthalten. Testversion: `3.0.61-sevii.7`. Dies ist ein lokaler Teststand; kein Online-Release wurde veröffentlicht.

## Darstellung

Alle 135 importierten Feuerrot-Quellgebiete mit 266 KASC-Laufzeitkarten werden über ihren genauen Importvertrag erkannt. Sie verwenden die vorhandene Kanto-Architektur, Möbel, Vegetation, Küstenwasser und Raum-/Höhlenpanoramen. 36 Quellen sind Außengebiete, 52 Innenräume und 47 echte Höhlen. Das erste Haus auf Sieben Eiland teilt einen sekundären Atlas mit der Eisfallhöhle, wird aber anhand seiner tatsächlichen Wohnmöbel und seines Holzbodens als Haus behandelt.

Gebäude besitzen getrennte Dach- und Fassadenflächen, freie tatsächliche Eingänge und zusammenhängende Geometrie über Laufzeit-Kartengrenzen. Stühle, Topfpflanzen und Lagerkisten sind einzelne Objekte auf ihren Quellflächen. Fenster lesen die importierten Sevii-Verbindungen und zeigen die zugehörige Außenkarte. Wandbilder, Sockel, Raumabschlüsse, Innentreppen und Schnittansichten folgen der vorhandenen Gen-1-Darstellung. Quelltische, Regale, Kleiderschränke und Loreleis einzelnes Bett wurden gegen die jeweiligen Originalzeichnungen korrigiert; Teppiche bleiben Bodenflächen.

Meeresfelsen werden aus ihren vollständigen 32-Pixel-Quellzeichnungen als einzelne runde Körper erkannt. Ihr blau getöntes Grau bleibt erhalten; umgebende Wellen werden freigestellt. Der Overhaul verwendet passende bestehende Kanto-Felsformen auf der tatsächlichen Quellfläche. Beide Modi behalten lebendes Küstenwasser unter der freigestellten Zeichnungsfläche.

Die sieben Fähranleger sind offene Kais mit Wasser, Metallgeländern, originalen Fensterpositionen und freien Terminaltüren. Im Rocket-Lager bleiben sieben einzelne große Kisten und 74 niedrige gelbe Rätselhindernisse von tatsächlichen Maschinen getrennt. Importierte Leerflächen und entfernte Wandkurse erzeugen keinen falschen Boden oder zusätzliche Trennwände. Alle 80 statischen interaktiven KASC-Sevii-Objekte haben passende eigene Modelle; lebende Figuren behalten ihre vorhandenen Figurenprovider.

## Vegetation und Jahreszeiten

Beerenforst und Musterbuschwald mischen vier bestehende Kanto-Baumformen mit drei unterscheidbaren Laubpaletten. Stamm und Rinde behalten ihre Materialien. Die vorhandenen Jahreszeiten erzeugen Frühlingsblüten, Sommergrün, Herbstlaub, überwiegend kahle Winterkronen und wiederkehrendes Laub. Baumidentität und Blütenauswahl verwenden die Koordinaten der ganzen Quellkarte, damit Kartenteile keine anderen Bäume erzeugen. 13 vorhandene Kanto-Palmen stehen als immergrüne Akzente auf nachgewiesenen blockierten Küstenbaumflächen.

Die Waldabschattung verwendet unregelmäßige Lichtflecken und eine aus tatsächlichen Baumflächen abgeleitete Maske. Lichtungen behalten Tageslicht; die Abschattung nimmt beim winterlichen Laubfall ab. Die Maske verwendet einen bereits vorhandenen, im Wald freien Texturplatz. Der vollständige Shader bleibt damit innerhalb von 16 Fragment-Samplern. Kantos bestehende Beleuchtung wird nicht verändert.

Gras nutzt im Overhaul die tatsächliche bestehende Kanto-Geometrie und Materialien. Alle vier ursprünglichen Büschelplätze und Encounterflächen bleiben erhalten. Küstengras hat sechs Prozent schmalere und acht Prozent niedrigere Halme; Inland und Wald behalten das unveränderte Modell. Der normale Modus verwendet die freigestellten Originalhalme. Blaugrüner Quellboden wird nicht als massive Grasplatte aufgerichtet.

## Vorhandene Landschaftsmerkmale

Sevault-Canyon, Ruinental, Tanoby und Inselküsten besitzen zusammenhängende regionale Klippen statt einzelner identischer Felsblöcke. Nachbarschaftsmasken und Höhenphase stammen aus der ganzen Quelle und bleiben über Kartenteilgrenzen kontinuierlich. Glutberg-Außenkarte und Gipfel bleiben offen: Ascheboden, Basalt und echte Treppenkurse unterscheiden sich vom Kanto-Gras. Lava wird nicht auf Quellflächen erfunden, die keine enthalten. Das Trainerturm-Dach bleibt ebenfalls ein offenes Gebiet.

Eisfallhöhlen besitzen eigene Frost-/Eispaletten, begrenzte facettierte Eisbrocken und zusammenhängende Eisklippen. Dünnes Eis, Risse, Sprungkanten, Leitern und Schächte behalten ihre ursprünglichen Rollen. Die zwei Quellwasserfälle verbinden ihre tatsächlichen oberen und unteren Kurse. Gedenksäule und Tanoby-Eingänge besitzen passende zusammenhängende Steinmodelle mit freier Türspur.

Alle 47 echten Höhlenquellen erhalten Konturwände und einen geschlossenen Innenraum. Innere Schächte und echte Ausgänge bleiben offen. Kartenfragmente erhalten keine Wand an einer geladenen gemeinsamen Naht. Der Overhaul verwendet Gen-1-Höhlenpanoramen; normales Voxel verwendet die laufenden Quell-Wandpixel in ihrer ursprünglichen Größe. Ego und Verfolger sehen den Raumabschluss, die Übersicht behält ihre Schnittansicht.

## Normales Voxel ohne Overhaul

Der normale Modus hat eine eigene Geometrie aus dem Originalatlas: geneigte Dächer, geschlossene farbige Fassaden, elliptische Baum-/Pflanzenvolumen, schmale Stämme, einzelne Sitzflächen, Lehnen und Beine. Gebäude-Fragmente teilen dieselbe vollständige Dachhöhe, Tiefe und Materialphase. Wasserfarben werden aus Küsten-/Fährengrafik entfernt; Gangways und Warps bleiben frei.

Pflanzenkronen und Töpfe werden zusammen erkannt. Die tatsächlichen `$12e`-Kronen gehören zu ihren `$136`-Töpfen; ihr Laub darf weder flach auf dem Boden bleiben noch dessen Farbpalette verfälschen. Mehrfarbige Teppichränder hinter Pflanzen werden von außen freigestellt, während eingeschlossene Blatt-/Topfflächen erhalten bleiben. Die Wandvorlage stammt aus einer vollständigen Wandkachel. Schwarze Atlasränder, schmale Eckstreifen und Maschinenkanten dienen nicht als wiederholtes Wandmaterial. Das gilt auch für Märkte, Rocket-Lager und Trainerturm. Räume besitzen Quellwände, Sockel und aufrechte Originalbilder/Fenster. Beanspruchte Wandflächen verwenden echten Quellboden statt zufälliger Kanto-Kachelnummern.

Die ursprünglichen Atlasfarben bleiben erhalten. Optionale Baum-Replacement-Paletten und Blüten werden bei ausgeschaltetem Overhaul nicht aktiviert. Der normale Modus übernimmt damit die bestehende Kanto-Trennung zwischen Originalgrafik und optionalen Ersatzmodellen.

## Laufzeit und Sicherheit der Darstellung

Reine Meeres-Kartenteile veröffentlichen einen gültigen leeren Terrainverbund zusammen mit ihrem separat besessenen Wassermesh. Das erzeugt keinen erfundenen Boden und zeichnet Wasser nicht doppelt. Trockene Karten ohne Geometrie gelten weiterhin als unvollständig. Erforderliche direkte Panorama-Nachbarn erhalten auch bei langsamen Frames einen garantierten gemeinsamen Vordergrundschritt; optionale Fernkulisse behält ihre Drosselung und das gemeinsame Zeitbudget.

Die sichtbare Sevii-Außennachbarschaft enthält auch unmittelbar berührende diagonale Teile derselben Originalkarte. Dadurch bleiben zwischen den direkten Nachbarn keine rechteckigen Himmelslücken offen. Diese Ecken werden vor Freigabe der Nachbarschaft tatsächlich fertiggestellt. Entfernte Zweischritt-Routen, Kantos bestehende Nachbarschaft und Innenräume behalten ihren bisherigen Umfang.

Fertig geladene Sevii-Quellnachbarn erhalten gemeinsam einen vollständigen Panorama-Aufbau statt mehrerer Zwischenfassungen. Beim Wechsel des Kartenursprungs bleibt die geschlossene vorherige Ansicht erhalten, bis der neue Verbund fertig ist. Wiederverwendung prüft die tatsächlichen Kartenkennungen: Gleich viele Karten allein beweisen keine vollständige neue Nachbarschaft. Der Ersatzverbund erhält denselben begrenzten erforderlichen Aufbauschritt; das gemeinsame Zeitbudget wird nicht erhöht.

Die Erkennung prüft Besitzer, Quellursprung, Abmessungen, Tilesetkennung, Atlasstruktur und Zellkollisionen. Andere Karten und Generation 2 werden nicht als Sevii behandelt. Kartenblöcke, Kollisionen, Warps, Storyflags und Spieler-Saves werden nicht geschrieben. Die QA verwendet eigene LÖVE-Profile und ein eingefrorenes KASC-Paket.

## Prüfnachweise

Der aktuelle native Audit prüft 266 Karten, alle 73.868 Zellen, 22.365 Möbel-/Landschaftsplatzierungen, 38 Gebäudeteile und die tatsächlichen Meshes aller 80 statischen interaktiven Objekte. Keine geprüfte statische Objektzelle bleibt ohne Replacement. Der unabhängige Quellvergleich enthält 8.660 Erwartungen und importiert keine Produktionsklassifikation. Sein reproduzierter Vergleich ist identisch.

31 unterschiedliche gezielte Lua-Prüfungen bestehen: Sevii-Verträge, Originalgeometrie einschließlich tatsächlicher Volumen-/Hüllenprüfung und Teppichrand-Freistellung, Raum-/Höhlenabschlüsse, Fenster, Gras, Quellwasser, regionale Landschaften, Jahreszeiten/Blüten, Lichtfehler-Isolation, Panorama-Budget, mobile Streaminggrenzen, Wasser-only-Besitz, die erforderlichen Sevii-Kartenecken, Kartenkennung beim Cachewechsel und der unveränderte öffentliche Halloween-Hotfix.

Der native Jahreszeitenlauf besteht für beide Wälder in Frühling, Sommer, Herbst, Winter und erneutem Frühling. Im Beerenforst verlieren 242 von 273 geprüften Bäumen ihr Laub; 31 bleiben immergrün. Im Musterbuschwald sind es 117 kahle und fünf immergrüne Bäume. Beide Wälder besitzen acht ausgewählte Frühlingsblütenkronen. Ein separater normaler Voxel-Lauf besteht alle fünf Phasen mit erhaltenen Originalfarben. Der Jahreszeitencode ist seit diesen Aufnahmen unverändert.

Der vollständige native Sichtvergleich besteht für alle 135 Quellgebiete plus 16 Kanto-Referenzen in beiden Modi. Je Modus wurden 182 Aufnahmen einschließlich Innen-/Höhlenansichten manuell geprüft. Zusätzlich bestehen Brückenspuren, Moduswechsel, Kameras, Nacht, Hochformat und tatsächlich gerenderte MAP-Kämpfe im Wald und auf See. Abgebrochene frühere Rundgänge zählen nicht als bestanden.

Nachweise: `quality7-complete-r20-full`, `quality7-complete-r19-basic`, `quality7-regression-r23-full`, `quality7-regression-r21-basic`, `quality7-water-r22-full` und `quality7-water-r20-basic`. Die vollständigen Sichtläufe verwenden byteidentische Geometrie, Modelle und Quelldaten; spätere Änderungen betreffen ausschließlich den Panorama-/Cacheübergang und passive Fehlerdiagnostik. Die korrigierten Laufzeitpfade sind durch erneute Regression und den vollständigen Küsten-/Meer-Wechsel geprüft. 31 gezielte Prüfungen bestehen auf `r22`; 64 Lua-Dateien bestehen den Syntaxcheck auf dem abschließenden `r23`.

Die letzten gezielten Wasserprüfungen bestehen in beiden Modi einschließlich Surfposition auf einem reinen Meeres-Kartenteil. Der Lagerlauf besteht mit Quellkisten, gelben Hindernissen und Maschinen. Die erneuten Hausaufnahmen prüfen beide primären Sieben-Eiland-Häuser, Resort und Loreleis Haus einschließlich Verfolgeransichten. Private Screenshots und Protokolle liegen unter `/Users/maarten/Documents/Recompile/.qa/vasc-sevii-20260930/`.

## Installation und Grenzen

Benötigt wird der KASC-Sevii-Expeditionsstand mit lokal importiertem `kasc.sevii-expedition/v1`-Bundle. Geprüft wird das eingefrorene KASC-Paket `package-dev6` vom 30.09.2026. Das VASC-Paket enthält weder die ROM noch extrahierte Sevii-Bilder und registriert selbst keine Inselkarten. Den vorhandenen Ordner `VOXEL_ASCENDANT` ersetzen, keine zweite VASC-Kopie parallel aktivieren und das Spiel neu starten. Saves und Einstellungen behalten.

Die Rezepterzeugung erfolgt lokal über `scripts/build_sevii_voxel_profiles.py`; nur semantische Rollen und Modellflächen gelangen ins Paket. Physische Mobilgeräte werden in diesem Lauf nicht getestet. Hochformat und mobile Budgetgrenzen werden am Desktop geprüft. Test 6 bleibt als früheres, unverändertes Paket erhalten.
