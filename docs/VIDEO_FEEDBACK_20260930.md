# Voxel Ascendant Verbesserungsvorschläge aus dem ZEROstig Video vom 30.09.2026

Quelle: [Kanto Ascendant Just Got EVERYTHING I Asked For! Elevators, Volcano & More!](https://www.youtube.com/watch?v=n469F1XRCx0), ZEROstig, veröffentlicht am 30.09.2026, Laufzeit 42:22.

Das Video zeigt einen älteren Entwicklungsstand. Die ursprüngliche Aufnahme enthält **17 konkrete Rückmeldungen, 5 neue Wünsche und 15 Beobachtungen zur Klärung**; das sind ausdrücklich keine 37 noch offenen Aufgaben. Alle Punkte wurden inzwischen mit dem aktuellen Quellstand, bestehenden Abnahmeberichten, Bildbelegen und gezielten Regressionstests abgeglichen. Der doppelte Pokéball stammt laut Nutzer aus einer anderen Mod und entfällt für VASC.

Grundlage ist das vollständige automatisch erzeugte englische [Transkript](/Users/maarten/Documents/Recompile/artifacts/vasc-video-feedback-20260930/transcript-en.txt). Einzelbilder bei 11:54, 15:03, 18:25, 37:41 und 39:23 wurden zusätzlich angesehen. Das ist keine vollständige audiovisuelle Sichtung und keine lokale Fehlerreproduktion. Automatische Untertitel erkennen Namen und einzelne Begriffe falsch. Trotz des Videotitels betrifft die Mehrheit der Rückmeldungen Voxel Ascendant. Die genaue gezeigte Paketversion ist nicht sicher bestimmt.

**Aktueller Stand: lokaler VASC 3.0.61-rc.6, auf dem vorhandenen rc.2 aufgebaut.** Radfahrer, Sitz-Kompatibilität und Sprachfix waren bereits in rc.2 enthalten und werden hier nicht erneut als neue Reparaturen gezählt. Öffentliche Basis bleibt 3.0.60. Die Änderungen liegen in [diesem Arbeitsstand](/Users/maarten/Documents/Recompile/.worktrees/vasc-hotel-counter-20261001); ZIP, Prüfsummen und Paketprüfung stehen unter `deliverables/VASC-3.0.61-rc.6-Hotel-Counter-Local`.

## In dieser Runde umgesetzt

- Fernglas-Hilfe größer, mit Zeilenumbruch und EN/DE; nach der Welt-Unschärfe gezeichnet, damit die Schrift klar bleibt.
- Safari-Zähler und die vier Aktionsbeschriftungen deutlich vergrößert; native Safari-Sequenz aufgenommen.
- Museum-/Turm-/Rocket-Treppen flacher und kompakt. Auf ausdrückliche Nutzerkorrektur keine langen, steilen Läufe und keine dafür erhöhten Wände. Sechs native Etagenwechsel bestanden.
- Drei vollständige Laborplakate an einer Wand, in nativer Ballreihenfolge **Glumanda → Schiggy → Bisasam**. Größe 50 Weltpixel erhalten; Unterkante von 34 auf 22 gesenkt, Laborwand von der Zwischenfassung 90 auf 76,25 gesenkt. Regale behalten ihre Größe. Schiggy ist sichtbar. Verwendet die bestehende 2172×724-Bildquelle; kein behaupteter neuer 4K-Ersatz.
- Museums-Raumfähre mit erkennbaren Deltaflügeln, Cockpit, Leitwerk und Triebwerken; Vitrine und native Kollisionsfläche erhalten.
- Mistys Arena: ruhigere trockene Fliesen und gerahmte Wellenmotive. Becken, Aquarien, Sprungbretter und Raumaufteilung erhalten.
- Nach Mutters nativer Heilung erscheinen vorübergehend Teller, Suppe, Besteck und Becher auf dem vorhandenen Esstisch.
- Mewtu-Sternbild ergänzt, mit Abstand zu den bestehenden Starter-Sternbildern.
- Mew als seltene, dezente Sternsilhouette: sechs Sekunden je ungefähr 20 Minuten Himmelszeit, nachts und bei passendem Wetter. Nur rechtzeitiges A mit Mew im mittleren Blickfeld fängt die Sichtung. **Kleines Auswahlfenster über der Himmelsansicht**: Nugget, Elixier oder Hyperball, ein Item je Sichtung. Auswahl nach rechtzeitigem A ohne Zeitdruck; B bricht ab. Kein Masterball. Native Interaktionen haben Vorrang, voller Beutel verbraucht die Belohnung nicht. Speicherung und Laden nativ geprüft.
- Der zusätzliche Fernvulkan-Zugang ist **vom Nutzer gestrichen**, weil der KASC-Vulkan bereits vorhanden ist. Kein zweites Gebiet angelegt.

## Noch offene Abnahme / unbestimmte Video-Beobachtungen

Ein physisches iPhone/iPad ist laut Nutzer verfügbar, aber im USB-Inventar dieses Mac war kein Testgerät angebunden. Physische mobile Sea-/UI-Abnahme bleibt offen. Desktop-Hochformat und reine iOS-Regressionsnachbildungen ersetzen keinen Gerätebeleg. Korrektur nach Quell- und Laufzeitprüfung: Der vorbereitete mobile Himmel zeigt bereits die semantischen Ereignisse. iOS- und Android-Codepfade auf dem Mac bestehen Mew in Hoch-/Querformat, Abbrechen, Belohnung und Speichern/Laden. Dabei entdecktes spiegelverkehrtes iOS-Mew-/Fernglas-HUD in rc.4 korrigiert und visuell erneut geprüft. Das ist keine physische Geräteabnahme.

Der Silph-Glaslift erhält ein leises, durchgehendes Motorgeräusch mit Ein-/Ausblenden anstelle der 100 wiederholten Collision-Sounds. Ankunftsgong bleibt erhalten; SFX=0, Pause, Ausstieg, Glas AUS und andere Lifte sind berücksichtigt. Native Fahrt bestanden. Ob genau dieser Ton im historischen Video gemeint war, bleibt akustisch unbestimmt.

Der sitzende Center-Mann ist jetzt in Voxel und Cobble ersetzt. Der zwischenzeitliche handgebaute Blockkörper wurde auf Nutzerkorrektur verworfen. Cobble verwendet den vorhandenen Kanto-Roster-/Bedrock-Workflow mit Augen-/Lid-Blinzeln und transparenten Sprite-Exports; Voxel erhält ein eigenes Voxel-HD-Bild anhand der bestehenden Figur und Voxel-Krankenschwester als Stilvorlage. Sitzpose und Bankanker bleiben fest. Drei Center je Stil und AUS-Rückfall nativ geprüft. HD behält seine vorhandene Quelle, wenn das optionale Paket verfügbar ist; auf diesem QA-Host fällt die HD-Auswahl mangels Paket auf Voxel zurück.

Alle 30 registrierten Outfitrezepte von RED/BLUE/GREEN sind jetzt jeweils in HD, Voxel, Cobble und 2D geprüft: 120 gerenderte Rezeptbilder, alle vom jeweiligen Original verschieden und je Figur/Stil eindeutig. Champion-Auswahl funktioniert. Das Schlafzimmerfenster wurde mit aus der echten Südfensterquelle abgeleiteter Kamera frei vom Fernseher aufgenommen: Außenansicht mit Straße, Nachbardach und dynamischen Wolken sichtbar. Die exakte historische Perspektive wird damit nicht behauptet.

Zum Casino wurde die alte A-Logo-Wand mit dem aktuellen, bereits anders ausgestalteten Raum abgeglichen; kein neuer pauschaler Wandumbau. Das unbestimmte Surfmenü zeigt im Video die Team-/Feld-Auswahl; kein aktueller Funktionsausfall nachgewiesen.

## Vollständiger Abgleich aller 37 Punkte

`KANDIDAT` bezeichnet die lokale rc.6 einschließlich ihrer vorhandenen rc.2-Basis; keine Veröffentlichung. `BESTAND` bezeichnet bereits vorhandene Lösungen. `NACHPRÜFEN` bleibt eine unbestimmte Szene oder externe Abnahme und ist kein bestätigter neuer Fehler.

| ID | Aktueller Status | Ergebnis / noch erforderlicher Schritt |
|---|---|---|
| Z30-01 | **AUSGESCHLOSSEN** | Doppelter Pokéball: laut Nutzer andere Mod; keine VASC-Aufgabe. |
| Z30-02 | BESTAND, nativ geprüft | Die Video-T-Pose betrifft Nidoking. Aktueller Cobble-Nidoking und Tauros laufen mit echten Animationsclips; zusätzlich 64 tatsächlich sichtbare Nidoking-Wachstumsframes mit Animationsclip und früher/mittlerer/später Aufnahme geprüft. Kein neuer pauschaler Figurenfix. |
| Z30-03 | BESTAND, nativ geprüft | Hausquelle, Etagenhöhe, Fensterlagen und Pallet-Horizonttests bestehen. Zusätzliche Kamera aus der echten Südfensterquelle zeigt unverdeckte Außenwelt; Screenshot geprüft. Kein neuer Fensterdefekt nachgewiesen, exakte alte Videoperspektive bleibt unbestimmt. |
| Z30-04 | ERLEDIGT, vorhandene Auswahl | D/P-/ORAS-WIDE- und FRLG-Taschenstile sind vorhanden; aktueller WIDE-Standardtest besteht. Kein belegter Bedarf für einen erneuten Taschenumbau. |
| Z30-05 | KANDIDAT | Drei große, tiefer hängende Plakate in Ballreihenfolge; Schiggy sichtbar. Originalbild per UV-Zuschnitt verwendet, kein neuer 4K-Asset behauptet. |
| Z30-06 | BESTAND / keine bestätigte Störung | Bei 11:56–12:01 ist die Team-/Feld-Auswahl zu sehen. Aktuelle Menü- und Reiseintegration vorhanden; kein bestimmter aktueller Defekt nachgewiesen. |
| Z30-07 | ERLEDIGT, mobile Abnahme offen | Sea Terrarium seit öffentlicher 3.0.60; native Surfkämpfe, beide Kameras und Attacken geprüft. Gilt für die vorgesehenen Kanto-Seerouten, nicht pauschal für Binnenwasser oder Angeln vom Land. Physische Mobilgeräte noch nicht abgenommen. |
| Z30-08 | BESTAND, neu nativ abgenommen | Drei vollständige First-Person-Eintritt-/Austritt-Schleifen Vertania → Giovannis Arena → Vertania bestanden. Nativer Austritt muss von Norden nach Süden angelaufen werden. |
| Z30-09 | KANDIDAT, Nutzerkorrektur | Kompakter 12-Pixel-Lauf mit sechs flacheren Stufen; Aufstieg 10, Abstieg 6 Weltpixel. Zusätzliche Wandhöhe zurückgenommen; Museum 1F↔2F nativ bestanden. |
| Z30-10 | KANDIDAT | Raumfähren-Silhouette, Cockpit, Flügel, Leitwerk und drei Triebwerke nachgearbeitet; native Museumsaufnahme geprüft. |
| Z30-11 | KANDIDAT, kosmetisch | Trockene Fliesen und Wellenmotive angeglichen; native Aufnahme geprüft. Keine pauschale Zusage, jede optionale NPC-Quelle durch Cobble zu ersetzen. |
| Z30-12 | KANDIDAT, Nutzerkorrektur | Flachere kompakte Turmtreppen statt langer steiler Läufe. Turm 1F↔2F nativ bestanden; normale Kollisions-/Warp-Regeln erhalten. |
| Z30-13 | KANDIDAT, nativ geprüft | Responsive EN/DE-Hilfe mit größerer Schrift außerhalb der Welt-Unschärfe. Native Aufnahme und Größenprüfungen bestanden. |
| Z30-14 | KANDIDAT, nativ geprüft | Leiser kontinuierlicher Motor statt 100 Collision-Sounds im Voxel-Glaslift; Ein-/Ausblenden, SFX, Pause, Ausstieg und Ankunftsgong geprüft. Andere Lifte/Glas AUS behalten native Töne. Historische Hörzuordnung bleibt unbestimmt; Brunnen bereits vorhanden und geprüft. |
| Z30-15 | KANDIDAT, Nutzerkorrektur | Flachere kompakte Rocket-Treppen; B1F↔B2F nativ bestanden. Keine zusätzliche Raumhöhe. |
| Z30-16 | BESTAND, aktueller Bildabgleich | Historisches Bild zeigt umlaufende A-Logo-Panels. Aktueller Raum besitzt bereits andere Wandmotive, native Aufnahme geprüft. Die exakte im Ton referenzierte Wand bleibt nicht sicher bestimmt. |
| Z30-17 | KANDIDAT, nativ geprüft | Safari-Ballzähler und BALL/BAIT/ROCK/RUN-Kartenbeschriftungen vergrößert; tatsächliches natives Safari-Menü aufgenommen. |
| Z30-18 | KANDIDAT, nativ geprüft | Mutters echte Heilungsroutine löst 180 Sekunden Tischdekoration aus. Native Interaktion sowie Spielstand-/Kartenwechsel geprüft. |
| Z30-19 | GESTRICHEN / KASC vorhanden | Nutzer: nicht umsetzen, bereits mit KASC vorhanden. Kein separater Fernkegel-Aufstieg und keine neuen Surfwege. |
| Z30-20 | KANDIDAT, nativ geprüft | Eigenes Mewtu-Sternbild mit Abstand zu den Starter-Sternbildern; native Nachtaufnahme geprüft. |
| Z30-21 | KANDIDAT, Nutzerpräzisierung | Dezente, selten vorbeifliegende Mew-Sternsilhouette statt buntem Atlas-Pokémon. Sechs Sekunden Sichtungsfenster, an echte Himmelsrichtung gebunden. |
| Z30-22 | KANDIDAT, nativ geprüft | Rechtzeitiges A im Blickfeld öffnet ein kleines Fenster für Nugget/Elixier/Hyperball. Ein Item je Sichtung, kein Masterball; nativer Input und Speichern/Laden geprüft. |
| Z30-23 | KANDIDAT, Nutzerkorrektur | Sitzender Center-Mann: Cobble via bestehendem Roster-/Bedrock-Modell mit echtem Blinzeln; eigener Voxel-HD-Sprite. Keine handgebaute Ersatzbox. Gemeinsame Erkennung an zwölf Fundstellen (elf Center plus Hotel); drei Center je Stil sowie Hotel in Voxel/Cobble/AUS nativ geprüft. Fester Bankanker erhalten. HD-Quelle vorhanden, separates optionales HD-Paket auf diesem Host nicht angebunden. |
| Z30-24 | BESTAND, gezielt nachgeprüft | Nidoking/Tauros mit aktueller Cobble-Quelle und gültigen Animationsclips im nativen Kampf aufgenommen. Die exakt historische einzelne Intro-Sekunde wurde nicht lückenlos nachgestellt. |
| Z30-25 | ERLEDIGT | Your-Look-Führung, Quellenwahl, Verfügbarkeits-/Downloadstatus vorhanden. Eingebettete Cobble-Inhalte benötigen keinen separaten Download. |
| Z30-26 | BESTAND, nativ geprüft | CUSTOM SPRITES öffnet den registrierten Bildschirm. Native RESCAN-Auswahl ausgeführt und Rückkehr ins Spiel geprüft; nutzt vorhandene Funktion. |
| Z30-27 | BESTAND, alle Stile geprüft | 30 registrierte RED/BLUE/GREEN-Rezepte jeweils in HD, Voxel, Cobble und 2D gerendert: 120 Bilder, vom jeweiligen Original verschieden und je Figur/Stil eindeutig. Champion und native Auswahl geprüft. |
| Z30-28 | ERLEDIGT, ältere Quelle im KANDIDAT | Aktuelle eingebettete Mutter sitzt korrekt, nativer Bildbeleg vorhanden. 3.0.61-rc.2 ergänzt Sitzquellen-Kompatibilität für eine ältere optionale Cobble-Card. |
| Z30-29 | ERLEDIGT / Fortschrittslob | Turmmaterialien und Blockersatz bereits verbessert. Keine neue allgemeine Aufgabe aus dem damaligen Fortschrittslob ableiten. |
| Z30-30 | KEIN AUFTRAG | Fernbild-Caches und nahe Live-Geometrie haben bewusst unterschiedliche Auflösungen. Kein gefordertes Mindestformat und kein aktueller Schärfedefekt belegt; nur bei sichtbarem Problem nacharbeiten. |
| Z30-31 | ERLEDIGT | Aktuelle Spielhallen-Automatenmodelle vorhanden und im nativen Bildbeleg sichtbar. |
| Z30-32 | ERLEDIGT, ältere Quelle im KANDIDAT | Eingebettete Casino-NPCs sitzen bereits seit 3.0.56; aktueller Bildbeleg bestätigt das. Ältere optionale Card zusätzlich in 3.0.61-rc.2 berücksichtigt. |
| Z30-33 | ERLEDIGT | Dach-Fliegen auf sechs ausdrücklich vorgesehenen Terrassen implementiert; Regeltests und native Abnahme vorhanden. |
| Z30-34 | KANDIDAT, umgesetzt und geprüft | Cobble-Radfahrer für Routes 16/17 in 3.0.61-rc.2 repariert und nativ geprüft. Noch keine öffentliche Releasezuordnung dieses Kandidaten; kein neuer Modellbauauftrag. |
| Z30-35 | KEIN AUFTRAG | Größen-/Bodenhöhenbehandlung vorhanden. „Lapras ist klein, gefällt mir“ verlangt keine automatische Vergrößerung. |
| Z30-36 | BESTAND, Quellenwahl geprüft | Gehege aufgenommen; native Tauros-Kampfdarstellung ausdrücklich mit Cobble-Quelle und gültiger Animation geprüft. AUTO kann bewusst eine andere Originalquelle wählen. |
| Z30-37 | ERLEDIGT / KEIN NEUER AUFTRAG | Neuere Wolken-/Himmelsüberarbeitung integriert, aktueller Regressionstest besteht. Die gelobten Wolken und vermutete spätere Variante begründen keinen weiteren Pflichtumbau. |

## Nachprüfung vom 01.10.2026

- `native-mobile-wish-android.log` und `native-mobile-wish-ios-rc4.log`: vorbereiteter mobiler Himmel und Wunschablauf bestanden; iOS-HUD nach Korrektur aufrecht.
- `rc4-regressions.log`: fünf gezielte Tests bestanden, einschließlich beider finalen HUDs und vollständiger Wiederherstellung des Grafikzustands.
- `native-remainders-review4.log`: 30 HD-Outfits und drei Center-Figuren tatsächlich geprüft. Frühere Hilfsläufe mit leerer Freischaltliste werden nicht als Outfitbeleg gewertet.
- `native-last-remainders.log`: sichtbares Nidoking-Intro, echte Aufzugfahrt mit Tonaufrufzählung und Brunnen-Stopp bestanden. Keine akustische Zuordnung des Videotons behauptet.
- Diese rc.4-Befunde wurden durch die rc.5-Abschlussprüfung oben ergänzt; die damals offenen Outfit-/Figuren-/Fensterbelege sind dort eingeordnet.

## Hotelkorrektur rc.6 vom 01.10.2026

- Nutzerbild identifiziert als `CELADON_HOTEL`, Hotel in Prismania. Empfangsdame steht nativ auf Bodenhöhe 0; die Zeichen-Tiefenverschiebung ließ ihre Füße über dem Tresen erscheinen.
- Nur bei unverändertem Hotel/Tresenmuster wird ihr Kamerabias auf 0 gesetzt. Originalposition, Kollisionsregeln und Ansprechen über den Tresen bleiben erhalten. Keine Raumumgestaltung.
- `rc6-regressions.json`: vier fokussierte Tests bestanden. `native-hotel-desk-isolated2.log`: Voxel/Cobble in vier Kamerawinkeln, 396 tatsächliche Zeichnungen, Bodenhöhe und native Interaktion bestanden; FULL-Voxel-Aufnahme visuell geprüft.
- `native-center-hotel-locations.log`: zwölf tatsächliche Sitzfiguren-Fundstellen ermittelt (elf Center plus Hotel), Hotel in Voxel/Cobble/AUS zusätzlich geprüft. Der Austausch greift über das gemeinsame Kachelmuster auch in den anderen Häusern.
- Vollständiges Paket und entpackte native Abnahme: `deliverables/VASC-3.0.61-rc.6-Hotel-Counter-Local/verification.json` und `PACKED-QA.md`.

## Abschlussprüfung rc.5 vom 01.10.2026

- `rc5-regressions.json`: acht gezielte Prüfungen bestanden, einschließlich separater Figurenstile, festem Bankanker, gecachtem Blinzeln, AUS/Fehler-Rückfall, Lift-Audio, nativer Fahrttaktung und finalen iOS-HUDs.
- `native-center-accepted.log`: Voxel und Cobble in Vermilion, Viridian und Cinnabar; originale Figur bei Walking Sprites AUS. Screenshots visuell geprüft. Frühere Bilder der verworfenen Ersatzbox sind kein finaler Beleg.
- `native-outfit-styles-final.log`: weitere 90 Rezeptbilder in Voxel/Cobble/2D; zusammen mit 30 HD-Rezepten vollständiger aktueller Stilabgleich.
- `native-window-lift-final.log`: echtes Südfenster ohne TV-Blockade; native Liftfahrt 1→7 mit hörfähiger Motorquelle, keinem durchgereichten Collision-Ton, genau einem Ankunftsgong und Stopp am Ausgang. Die Systemlautstärke blieb im QA-Host auf null; keine persönliche Hörabnahme behauptet.
- Cobble-Modelle, Animations-/Poserdateien, Palette und Export-Herkunft sind im Kandidaten erhalten. `tools/center_sitter/roster-preview.html` enthält die lokale Authoring-Vorschau.
- Vollständiger Kandidat, CRC-/Quellgleichheit-/Syntax-/Modellprüfung und Paket-Lauf: `deliverables/VASC-3.0.61-rc.5-Local/verification.json` und `PACKED-QA.md`.

## Prüfbelege und verbleibende Abnahme

- **23 gezielte Regressionstests bestanden**: [Ergebnisse](/Users/maarten/Documents/Recompile/artifacts/vasc-video-polish-20260930/regressions-final.json). Der veraltete Stub in `window_landmark_test.lua` ist dauerhaft an die vorhandene Schnittstelle angepasst; Produktions-Volkancode dafür unverändert.
- [Native finale UI-/Wunsch-/Speicherprüfung](/Users/maarten/Documents/Recompile/artifacts/vasc-video-polish-20260930/native-final-review4.log), [drei Giovanni-Schleifen](/Users/maarten/Documents/Recompile/artifacts/vasc-video-polish-20260930/native-final-review3.log), [sechs Etagenwechsel](/Users/maarten/Documents/Recompile/artifacts/vasc-video-polish-20260930/native-comprehensive.log). Der letzte dieser historischen QA-Läufe endet danach an einem falschen Gym-Testanlauf; dieser Testfehler ist in der gesonderten Giovanni-Prüfung korrigiert, keine versteckte Produktionsreparatur.
- [Aktuelle Räume und Cobble-Modelle](/Users/maarten/Documents/Recompile/artifacts/vasc-video-polish-20260930/native-exact-reviews.log), [Mewtu ohne Überlappung und Custom-Sprites-Rescan](/Users/maarten/Documents/Recompile/artifacts/vasc-video-polish-20260930/native-ui-completion.log).
- Bilder: [Labor](/Users/maarten/Documents/Recompile/artifacts/vasc-video-polish-20260930/lab-large-low-ball-order.png), [kleines Wunschfenster](/Users/maarten/Documents/Recompile/artifacts/vasc-video-polish-20260930/mew-small-choice-window.png), [Safari](/Users/maarten/Documents/Recompile/artifacts/vasc-video-polish-20260930/safari-large.png), [Museum](/Users/maarten/Documents/Recompile/artifacts/vasc-video-polish-20260930/MUSEUM_2F-final.png), [Misty](/Users/maarten/Documents/Recompile/artifacts/vasc-video-polish-20260930/CERULEAN_GYM-final.png).
- Bestehende Sea-/Pyro-, Radfahrer-/Sitz-, Fenster-/Dach- und Your-Look-Abnahmen bleiben gültige Basis. Diese Runde ist keine erneute vollständige Abnahme aller 37 historischen Beobachtungen und kein physischer Mobilgeräte-Test.

## Historische Aufnahme der Videorückmeldungen

Die folgenden Tabellen bewahren die ursprünglichen Aussagen und Zeitmarken. Ihre damaligen `TODO`-/`AUDIT`-Markierungen sind durch den aktuellen Abgleich oben ersetzt. P1/P2/P3 und nächste Schritte sind unsere Ableitung, keine Vorgaben des Reviewers oder Releasezusagen.

## Konkrete Kritik und Nacharbeiten

| ID | Prio / Status | Zeit | Rückmeldung | Abgeleiteter nächster Schritt |
|---|---|---|---|---|
| Z30-01 | AUSGESCHLOSSEN | [03:33](https://www.youtube.com/watch?v=n469F1XRCx0&t=213s) | In der Kampfszene sind doppelte Pokébälle zu sehen. | Laut Nutzer Darstellung einer anderen Mod; keine VASC-Aufgabe. |
| Z30-02 | BESTAND, nativ geprüft | Die Video-T-Pose betrifft Nidoking. Aktueller Cobble-Nidoking und Tauros laufen mit echten Animationsclips; zusätzlich 64 tatsächlich sichtbare Nidoking-Wachstumsframes mit Animationsclip und früher/mittlerer/später Aufnahme geprüft. Kein neuer pauschaler Figurenfix. |
| Z30-03 | BESTAND, nativ geprüft | Hausquelle, Etagenhöhe, Fensterlagen und Pallet-Horizonttests bestehen. Zusätzliche Kamera aus der echten Südfensterquelle zeigt unverdeckte Außenwelt; Screenshot geprüft. Kein neuer Fensterdefekt nachgewiesen, exakte alte Videoperspektive bleibt unbestimmt. |
| Z30-04 | P2 / TODO | [09:05–09:20](https://www.youtube.com/watch?v=n469F1XRCx0&t=545s) | Die Tasche benötigt noch Nacharbeit und ist für ihn der verbleibende auffällige Menübereich. | Taschenansicht an die übrige Oberfläche angleichen; vorhandene Modern-Bag-/FRLG-/ORAS-Auswahl vorher prüfen. Kein ausdrücklich verlangter kompletter UI-Neuentwurf. |
| Z30-05 | KANDIDAT | Drei große, tiefer hängende Plakate in Ballreihenfolge; Schiggy sichtbar. Originalbild per UV-Zuschnitt verwendet, kein neuer 4K-Asset behauptet. |
| Z30-06 | BESTAND / keine bestätigte Störung | Bei 11:56–12:01 ist die Team-/Feld-Auswahl zu sehen. Aktuelle Menü- und Reiseintegration vorhanden; kein bestimmter aktueller Defekt nachgewiesen. |
| Z30-07 | P1 / AUDIT | [12:15–12:24](https://www.youtube.com/watch?v=n469F1XRCx0&t=735s) | Die Darstellung der Kämpfe auf dem Wasser muss verbessert werden. | Gleiche Surfbegegnung nachstellen und Platzierung, Wasserbezug, Kamera sowie Sichtbarkeit beider Pokémon prüfen. Ursache und Rendererzuständigkeit sind im Video nicht bestimmt. |
| Z30-08 | BESTAND, neu nativ abgenommen | Drei vollständige First-Person-Eintritt-/Austritt-Schleifen Vertania → Giovannis Arena → Vertania bestanden. Nativer Austritt muss von Norden nach Süden angelaufen werden. |
| Z30-09 | KANDIDAT, Nutzerkorrektur | Kompakter 12-Pixel-Lauf mit sechs flacheren Stufen; Aufstieg 10, Abstieg 6 Weltpixel. Zusätzliche Wandhöhe zurückgenommen; Museum 1F↔2F nativ bestanden. |
| Z30-10 | KANDIDAT | Raumfähren-Silhouette, Cockpit, Flügel, Leitwerk und drei Triebwerke nachgearbeitet; native Museumsaufnahme geprüft. |
| Z30-11 | KANDIDAT, kosmetisch | Trockene Fliesen und Wellenmotive angeglichen; native Aufnahme geprüft. Keine pauschale Zusage, jede optionale NPC-Quelle durch Cobble zu ersetzen. |
| Z30-12 | KANDIDAT, Nutzerkorrektur | Flachere kompakte Turmtreppen statt langer steiler Läufe. Turm 1F↔2F nativ bestanden; normale Kollisions-/Warp-Regeln erhalten. |
| Z30-13 | KANDIDAT, nativ geprüft | Responsive EN/DE-Hilfe mit größerer Schrift außerhalb der Welt-Unschärfe. Native Aufnahme und Größenprüfungen bestanden. |
| Z30-14 | KANDIDAT, nativ geprüft | Leiser kontinuierlicher Motor statt 100 Collision-Sounds im Voxel-Glaslift; Ein-/Ausblenden, SFX, Pause, Ausstieg und Ankunftsgong geprüft. Andere Lifte/Glas AUS behalten native Töne. Historische Hörzuordnung bleibt unbestimmt; Brunnen bereits vorhanden und geprüft. |
| Z30-15 | KANDIDAT, Nutzerkorrektur | Flachere kompakte Rocket-Treppen; B1F↔B2F nativ bestanden. Keine zusätzliche Raumhöhe. |
| Z30-16 | BESTAND, aktueller Bildabgleich | Historisches Bild zeigt umlaufende A-Logo-Panels. Aktueller Raum besitzt bereits andere Wandmotive, native Aufnahme geprüft. Die exakte im Ton referenzierte Wand bleibt nicht sicher bestimmt. |
| Z30-17 | KANDIDAT, nativ geprüft | Safari-Ballzähler und BALL/BAIT/ROCK/RUN-Kartenbeschriftungen vergrößert; tatsächliches natives Safari-Menü aufgenommen. |

## Neue Erkundungswünsche und Easter Eggs

| ID | Prio / Status | Zeit | Wunsch des Reviewers | Abgeleiteter nächster Schritt |
|---|---|---|---|---|
| Z30-18 | KANDIDAT, nativ geprüft | Mutters echte Heilungsroutine löst 180 Sekunden Tischdekoration aus. Native Interaktion sowie Spielstand-/Kartenwechsel geprüft. |
| Z30-19 | GESTRICHEN / KASC vorhanden | Nutzer: nicht umsetzen, bereits mit KASC vorhanden. Kein separater Fernkegel-Aufstieg und keine neuen Surfwege. |
| Z30-20 | KANDIDAT, nativ geprüft | Eigenes Mewtu-Sternbild mit Abstand zu den Starter-Sternbildern; native Nachtaufnahme geprüft. |
| Z30-21 | KANDIDAT, Nutzerpräzisierung | Dezente, selten vorbeifliegende Mew-Sternsilhouette statt buntem Atlas-Pokémon. Sechs Sekunden Sichtungsfenster, an echte Himmelsrichtung gebunden. |
| Z30-22 | KANDIDAT, nativ geprüft | Rechtzeitiges A im Blickfeld öffnet ein kleines Fenster für Nugget/Elixier/Hyperball. Ein Item je Sichtung, kein Masterball; nativer Input und Speichern/Laden geprüft. |

## Beobachtungen die zunächst geklärt werden müssen

Diese Punkte bleiben sichtbar im Backlog, gelten aber noch nicht als eindeutig verlangte Änderungen oder bestätigte Fehler. Priorität P2, sofern nicht anders angegeben; Status jeweils `AUDIT`.

| ID | Zeit | Beobachtung | Möglicher Prüfpunkt und Grenze der Aussage |
|---|---|---|---|
| Z30-23 | KANDIDAT, Nutzerkorrektur | Sitzender Center-Mann: Cobble via bestehendem Roster-/Bedrock-Modell mit echtem Blinzeln; eigener Voxel-HD-Sprite. Keine handgebaute Ersatzbox. Drei Center je Stil, fester Bankanker und AUS nativ geprüft. HD-Quelle vorhanden, separates optionales HD-Paket auf diesem Host nicht angebunden. |
| Z30-24 | BESTAND, gezielt nachgeprüft | Nidoking/Tauros mit aktueller Cobble-Quelle und gültigen Animationsclips im nativen Kampf aufgenommen. Die exakt historische einzelne Intro-Sekunde wurde nicht lückenlos nachgestellt. |
| Z30-25 | [05:34–06:06](https://www.youtube.com/watch?v=n469F1XRCx0&t=334s) | Er weiß nicht sicher, ob neue Downloads bereits vorhanden sind bzw. noch geladen werden müssen. | Aktive Assetquelle und Downloadstatus verständlicher anzeigen. Installationserfordernis oder Downloadfehler sind nicht belegt. |
| Z30-26 | BESTAND, nativ geprüft | CUSTOM SPRITES öffnet den registrierten Bildschirm. Native RESCAN-Auswahl ausgeführt und Rückkehr ins Spiel geprüft; nutzt vorhandene Funktion. |
| Z30-27 | BESTAND, alle Stile geprüft | 30 registrierte RED/BLUE/GREEN-Rezepte jeweils in HD, Voxel, Cobble und 2D gerendert: 120 Bilder, vom jeweiligen Original verschieden und je Figur/Stil eindeutig. Champion und native Auswahl geprüft. |
| Z30-28 | [10:32](https://www.youtube.com/watch?v=n469F1XRCx0&t=632s) | Er fordert die Mutter scherzhaft auf, von ihrer erhöhten Position herunterzukommen. | Bodenhöhe und Platzierung prüfen, falls die Szene tatsächlich einen Höhenversatz zeigt. Die Bemerkung allein beweist keinen Fehler. |
| Z30-29 | [23:21–23:57](https://www.youtube.com/watch?v=n469F1XRCx0&t=1401s) | Im Pokémon-Turm werden bunte Blöcke bereits durch passende massive Objekte ersetzt. | Verbliebene alte Blöcke inventarisieren und den begonnenen Stil fortführen. Dies ist überwiegend Fortschrittslob, kein neuer genereller Umbauauftrag. |
| Z30-30 | [25:05–25:18](https://www.youtube.com/watch?v=n469F1XRCx0&t=1505s) | Das Aussichtspanorama hat eine andere bzw. niedrigere Auflösung als die vorherige Ansicht. | Schärfe und konsistente Auflösung der Fernsicht prüfen. Seine Reaktion bleibt sehr positiv; kein klar verlangtes Mindestformat. |
| Z30-31 | [33:19–33:24](https://www.youtube.com/watch?v=n469F1XRCx0&t=1999s) | Die „cabinets“ in der Spielhalle seien noch nicht eingesetzt; anschließend sagt er „That's good“. | Gemeinte Automaten/Schränke und Aussage im Bild bzw. Ton klären. Daraus noch keine zwingende Nachrüstung ableiten. |
| Z30-32 | [33:35–33:38](https://www.youtube.com/watch?v=n469F1XRCx0&t=2015s) | Die Spielhallennutzer stehen weiterhin. | Passende Sitz- oder Bedienposen prüfen; wiederkehrender Restbereich aus früherem Feedback, hier nur beobachtet. |
| Z30-33 | [35:26–35:33](https://www.youtube.com/watch?v=n469F1XRCx0&t=2126s) | Er fragt, ob man vom Kaufhausdach fliegen kann, und stellt fest, dass es nicht geht. | P3: Fliegen vom Dach als optionalen Bedienwunsch festhalten. Die Frage belegt keine fehlerhafte native Reiseregel. |
| Z30-34 | [36:24–36:30](https://www.youtube.com/watch?v=n469F1XRCx0&t=2184s) | Die Figuren auf dem Fahrradweg entsprechen noch nicht dem Cobblemon-Stil. | Verbliebene Biker-/Trainerdarstellungen angleichen; den ansonsten ausdrücklich gelobten Fahrradweg erhalten. |
| Z30-35 | [37:49–37:56](https://www.youtube.com/watch?v=n469F1XRCx0&t=2269s) | Lapras im Fuchsania-Gehege ist klein, gefällt ihm aber trotzdem. | Größenlesbarkeit prüfen; kein eindeutig geforderter Größenwechsel. |
| Z30-36 | BESTAND, Quellenwahl geprüft | Gehege aufgenommen; native Tauros-Kampfdarstellung ausdrücklich mit Cobble-Quelle und gültiger Animation geprüft. AUTO kann bewusst eine andere Originalquelle wählen. |
| Z30-37 | [14:31–14:52](https://www.youtube.com/watch?v=n469F1XRCx0&t=871s) | Die Wolken gefallen ihm; er vermutet künftig eine realistischere leichte Variante. | P3: Als mögliche Stilpräferenz festhalten. Keine ausdrücklich geforderte Wolkenumstellung und kein gemessener Performancebefund. |

## Gelobte Verbesserungen die erhalten bleiben sollen

- **Laden und Einstieg:** kurze Ladebildschirme gefallen ihm (00:44, 01:53, 14:19); daraus folgt kein Auftrag, sie zu entfernen.
- **Spielerhaus und Figuren:** neue Häuser, Mutter im Anime-Stil, bessere Treppen, Nintendo Switch, Outfitwahl und korrekte Spielergröße/-farbe werden gelobt (03:53–04:48, 09:43–10:28).
- **Menüs und Darstellungswahl:** Cobblemon-Pokédex und dessen bestehendes Design gefallen ihm (08:49–09:05). Das rechtfertigt keinen vollständigen Austausch dieses Layouts.
- **Zinnoberinsel:** Vulkan, Lavafluss, Sand, Inselwirkung, gefüllter Markt und Pyros Arena gefallen ihm (12:27–13:57). Die Zugänglichkeitsidee Z30-19 bleibt davon getrennt.
- **Welt und Atmosphäre:** Regenbogen samt weichem Ausblenden, gruseliger Vertania-Wald, Museumfossilien, Terrainhöhen, Musik, Mondberg-Nebel und Fackeln, goldene Nugget-Brücke sowie Tiergeräusche werden gelobt (16:11–22:50).
- **Arenen und Turm:** Giovannis Darstellung und die farbige Bodenprojektion gefallen ihm; Mistys Aquarien/Sprungbretter und die neue Turmatmosphäre ebenfalls (15:48–16:03, 21:00–21:32, 23:13–23:57). Kogas unsichtbare Wände nennt er ausdrücklich als Verbesserung (37:27).
- **Fernsicht und Aufzüge:** Aussichts-/Fernglasfunktion und Sternbilder, Silph-Fenster mit nachvollziehbarer Höhe, bewegter Aufzug und Brunnen gefallen ihm sehr (24:59–32:19). Den geschlossenen Kaufhausaufzug ohne Außenblick hält er ausdrücklich für passend (34:38–34:48).
- **Späte Orte:** Kaufhausdach, Fahrradweg, Fuchsania-Gehege mit echten Pokémon, Safari-Wege/-Statuen und Höhen/Statue auf dem Indigo-Plateau werden gelobt (35:08–40:58).

## Abgleich mit bisherigen Rückmeldungen

Die [Auswertung vom 18.09.2026](/Users/maarten/Documents/Recompile/docs/VOXEL_ASCENDANT_VIDEO_FEEDBACK_2026-09-18.md) und die [Auswertung vom 25.09.2026](/Users/maarten/Documents/Recompile/artifacts/vasc-video-review-20260925/VIDEO-REVIEW-DE.md) enthalten bereits verwandte Aufgaben. Tasche, Treppen-/Wandanschlüsse, NPC-Posen, Wasser-Kämpfe und konsistente Modellquellen erhalten durch dieses Video neue Belege. Die neuen Belege sollen an bestehende Aufgaben angehängt werden, sobald deren aktueller Arbeitsstand geprüft ist; sie beweisen weder eine Regression noch, dass sämtliche früheren Punkte erledigt sind.

Der neue Film bestätigt im gezeigten Stand insbesondere Fortschritte beim Cobblemon-Pokédex, bei Silph-Höhe und Fenstern, bewegten Aufzügen, Dachpanoramen, Fernglas, Turmmaterialien sowie mehreren Arenen. Die kleinen Bedienelemente, einzelne Treppen und neue Featurewünsche bleiben separat offen.

Die KASC-Lavados-Vulkan-Card ist im zentralen Backlog bereits als implementiert vermerkt. Z30-19 beschreibt dagegen den Wunsch, den sichtbaren Fernvulkan zu betreten; vor einer Zusammenführung muss geklärt werden, ob die Gebiete zusammengehören.

Die aktuelle Reihenfolge und die verbleibenden Aufgaben stehen am Anfang dieses Dokuments. Bereits implementierte Punkte werden nicht erneut als offene Entwicklung eingeplant.

## Nicht als neue Aufgaben übernommen

Die Teamansicht bei 37:41 zeigt ein geöffnetes Menü. „Get rid of this“ bezieht sich dort offenbar auf das Schließen der Ansicht, nicht auf deren Abschaffung. Die Erdbebenanimation um 03:42 ordnet er selbst Gen-III-Attacken zu; er fordert keine Abschaltung. Das Lob bzw. die Erwartung eines weiteren Projekts am Ende enthält keinen konkreten Änderungsauftrag für dieses Paket.

Die Videobeschreibung enthält außerdem einen allgemeinen Ultimate-Kanto-Modkatalog und einen Bericht über einen schwarzen Bildschirm mit Kanto Gear. Diese Angaben sind als separate Kompatibilitätskontexte zu behandeln und belegen keinen neuen KASC-/VASC-Fehler in diesem Rundgang.

**Ursprüngliches Erfassungsergebnis vor der Umsetzung:** Alle 37 aufgenommenen Punkte gegen den neuesten Hauptstand abgeglichen, externe Moddarstellung ausgeschlossen, veraltete offene Status korrigiert und echte Restarbeit von Reproduktionsbedarf und Erweiterungen getrennt. Zentraler Backlog aktualisiert. Keine Produktimplementierung oder Veröffentlichung vorgenommen.
