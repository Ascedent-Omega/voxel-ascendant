# RC50 – Pokémon-Grafikcaches beim Gehen erhalten

29.09.2026. Gezielte Änderung im integrierten Overworld-Pokémon-Adapter.

Bisher führte jeder `world.stepped`-Aufruf zu einer vollständigen Provider-Aktualisierung: Resolver-Cache leeren, Wilds-Darstellungen erneut anwenden, Ambient-Cache leeren und alle aktiven Ambient-Pokémon neu binden. Die normale Schrittprüfung entdeckt jetzt weiterhin neue Provider und prüft jeden aktuellen Actor, verwirft aber die Provider-Caches nur noch bei einer erstmals installierten Provider-Brücke. Karten-/Save-/Start-Ereignisse, eigene Einstellungsänderungen und die öffentliche explizite Refresh-Funktion aktualisieren weiterhin vollständig.

## Prüfung

`tests/pokemon_step_refresh_test.lua` führt echte Event-Registrierung, Live-Card-Bindung, Model-Ownership und Wiederherstellung aus. Es prüft 100 Schritte ohne Cache-Verwerfung, spät auftauchende Actors und Provider, Identitätswechsel, ausgetauschte Owner-Renderer, Einstellungswechsel, expliziten Refresh sowie die fünf Lifecycle-Ereignisse. Quellkatalog-Auflösung und Skalierung sind isoliert; dieser Test ersetzt die nativen Läufe nicht.

Zwei native, stumme Saffronia-Läufe mit vollständig ausgelöster Gebietsvorbereitung, Voxelgebäuden, Nacht/Regen und FULL-Wasser:

- Referenz: 300 vollständige Provider-Refreshes, zusammen 247,91 ms, maximal 2,06 ms pro betroffenem Frame. Gesamter Bridge-Refresh zusammen 410,78 ms.
- Änderung: 298 Schrittprüfungen, null vollständige Provider-Refreshes. Gesamter Bridge-Refresh zusammen 241,00 ms. Die laufende Actor-Prüfung bleibt aktiv.
- Die Laufstrecke weicht durch einen NPC um eine Zelle ab. Die mittlere Gesamt-CPU-Zeit ist im zweiten Prozess schlechter (12,88 gegenüber 17,50 ms); daraus folgt ausdrücklich kein nachgewiesener globaler FPS-Gewinn. Die beobachteten Mesh-Neuanlagen sinken 418 → 45, sind aber auch von Animationen/Aufwärmung abhängig und deshalb kein isolierter Kausalnachweis.

Zusätzlich Alt/Neu/Alt im selben Prozess, vier feste Ansichten, jeweils 240 Frames und 16 diagnostisch ausgelöste Schritt-Ereignisse pro Phase. In allen neuen Phasen entfallen die 16 Provider-Refreshes. Die Signaturen für Grafikquelle, Dex, Modell-Ownership und Darstellungsmodus aller nativen NPCs bleiben zwischen den Varianten gleich. CPU-Mittelwerte in ms:

| Ansicht | Alt | Neu | Kontrolle |
|---|---:|---:|---:|
| 1 | 10,42 | 10,13 | 10,53 |
| 2 | 9,48 | 8,66 | 9,73 |
| 3 | 9,75 | 9,35 | 10,39 |
| 4 | 17,43 | 18,38 | 18,89 |

Die vierte Ansicht driftet deutlich. Keine konstante 60-FPS-Zusage, kein Nachweis für die gemeldeten 4-FPS-Einbrüche. Native Sichtprüfung des Saffronia-Straßenbildes nach der Änderung: Gebäude, Nachtbeleuchtung, Regen und Figuren vorhanden. Keine physische iPhone-/Switch-Prüfung.

Artefakte: `/Users/maarten/Documents/Recompile/artifacts/performance-step-refresh-20260929`, einschließlich `comparison.json` und `paired/summary.json`. Nur die eine integrierte Produktionsdatei wird geändert; keine Assets oder visuellen Einstellungen reduziert.
