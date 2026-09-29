# RC24 – Wiederherstellung: unnötige Regeldaten-Arbeit entfernen

28.09.2026. Gesamtziel weiterhin offen.

## Ursache und Änderung

Die vorherige Hitch-Aufzeichnung lokalisierte etwa 90 ms im frühen Update nach „Weiter“. Die neue native Diagnose trennt Wiederherstellung, Optionsanwendung, Kartenwechsel, einzelne Event-Listener und deren Teilfunktionen. Der größte Listener ist `kanto_ascendant/generation_rules.lua` beim Event `save.loaded`. Die Save-Validierung und Optionsanwendung waren nicht der gemessene Hauptverursacher.

Zwei eng begrenzte Optimierungen liegen im verwendeten KASC-Worktree `/Users/maarten/Documents/Recompile/.worktrees/kasc-errors-send-logs-20260925/`:

1. `backend_live_learnsets_67.lua`: Die Live-TM-Liste übernimmt aktuelle und historische Maschinen-IDs direkt, mit gleicher Reihenfolge, Duplikatbehandlung und Prüfung gegen die aktuelle Attackenregistrierung. Zuvor wurde dafür `rowsFor(..., 'M')` aufgerufen, das zusätzlich andere Lernquellen durchläuft und umfangreiche Herkunftsdatensätze anlegt, deren Metadaten anschließend verworfen werden. Lehrmeister-/Geschenk-Abfragen selbst bleiben auf ihrem bisherigen Pfad. Ergebnisse werden weiterhin neu kopiert; keine gemeinsam veränderbaren Lerndaten.
2. `generation_rules.lua`: Die Verfügbarkeit derselben Attacke wird innerhalb eines einzigen Projektionsdurchlaufs nur einmal berechnet. Die Tabelle endet mit dem Aufruf; spätere Profilwechsel und Änderungen an der Attackenregistrierung werden vollständig neu geprüft. Die Wiederherstellung der Datenbasis, Provider und eigentliche Profil-/Spielstandlogik laufen unverändert.

Die bereits vorhandene fremde Änderung an `backend_gift_profiles_67.lua` wurde nicht angefasst. Kein Commit, keine Veröffentlichung und kein persönlicher Spielstand geändert.

## Belege

Native, stumme QA mit dem tatsächlich geladenen KASC- und VASC-Code:

- Direkter Vergleich der alten und neuen Live-Lernlisten für Generation 1–7, jeweils Rot und Gelb (14 Varianten), auf der echten Registry mit 1.189 Backend-Artenkennungen. Verglichen wurden die vorhandenen Arten, Attackenreihenfolge, Leveldaten, TM-Listen, Ei-Registry und Audit. Zusätzlich Live-Entfernung ausgewählter Attacken. Alle Vergleiche identisch.
- Abwechselnd gemessene, warme Live-Lernlisten: Median bisher 47,08 ms, neu 19,85 ms über jeweils sieben Aufrufe. Einzelwerte schwanken durch Speicherbereinigung/Systemlast; kein Worst-Frame-Versprechen.
- Zweiter nativer Vergleich des vollständigen Datenprojektionskörpers vor/nach Verfügbarkeitswiederverwendung: 13 Varianten einschließlich Auf-/Abwechseln, OFF sowie geänderter und wiederhergestellter Attacken-Epoche. Verglich Typen, Attackenwerte, Lernlisten und Typentabelle. Keine Unterschiede. Das prüft Datenprojektion; Generation 7 wird dadurch nicht als neue Kampfunterstützung aktiviert.
- Headless-Verträge für geordnete Maschinen-Union, Duplikate, entfernte/wiederhergestellte Attacken, fehlende Aliase auf Projektionscaches und die ausdrücklich authored Familien-TMs bestanden. Separater Test weist genau eine Verfügbarkeitsberechnung je Attacken-ID und Durchlauf sowie frische Prüfung nach Epoch-/Registry-Wechsel nach.
- Echter „Weiter“-Ablauf nach den Änderungen besteht: direkter Nachbarbereich vollständig vorbereitet, gültiger Lichtcache-Treffer, keine Cachefehler, Freigabe nach präsentierter Szene.

Die instrumentierte Wiederherstellung zeigt folgende Teilzeiten:

| Teil | vor beiden Änderungen | nach beiden Änderungen |
|---|---:|---:|
| Datenbasis wiederherstellen | 10,61 ms | 8,60 ms |
| Live-Lernlisten aufbauen | 49,12 ms | 19,83 ms |
| gesamter Generationen-Abgleich | 91,71 ms | 39,61 ms |

Der vollständige `save.loaded`-Event dauert im letzten Lauf 56,18 ms. Andere Listener tragen weiterhin Zeit bei. Die größte vom Continue-Treiber gemessene abgedeckte Pause liegt bei 71,28 ms. Gesamtladung 3,46 s; der unmittelbar vorherige Lauf nur mit der TM-Optimierung lag bei 4,09 s / 104,46 ms. Diese Gesamtwerte sind **kein kontrollierter Ladezeit-Benchmark**: Cachezustand und Systemlast schwanken. Die Call-Attribution, direkte Funktionsmessung und Ausgabeäquivalenz belegen die konkrete Optimierung stärker als Gesamt-FPS.

## Noch offen

Breite Laufstrecken/Kartenübergänge und die gemeldeten 4-FPS-Fälle sind nicht insgesamt abgenommen. Die instrumentierten Testfahrten enthalten Diagnose-Overhead und eignen sich nicht als Produktions-FPS-Zusage. Das Wasser-Rendering sowie verbleibende Lade- und Aufbau-Spitzen bleiben weitere Arbeitsfelder.

## Reproduktion und Sicherung

VASC-Testtreiber: `rc24_restore_trace.lua`, `rc24_learnset_equivalence.lua`, `rc24_generation_equivalence.lua`. Start ausschließlich mit `POKEPORT_IDENTITY=vasc-video-polish-qa`, passendem absoluten `POKEPORT_DRIVER`, `QA_VASC_ROOT` und `SHOT_DIR`. Die Vergleichstests benötigen die jeweilige `QA_LEARNSET_BASELINE` bzw. `QA_RULES_BASELINE` aus der Sicherung.

Artefakte: `/Users/maarten/Documents/Recompile/artifacts/performance-restore-trace-20260928/`. Separate Patches für KASC und VASC, Ausgangsdateien, finale Dateien, SHA256, Logs und Messdaten. Vorwärts-/Rückwärtsbezüge beachten: Der KASC-Patch gehört in den oben genannten KASC-Worktree; der VASC-Patch in `.worktrees/vasc-video-polish-halloween-20260926`.
