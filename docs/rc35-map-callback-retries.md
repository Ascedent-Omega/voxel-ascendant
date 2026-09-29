# RC35 – Leere Begegnungstabellen nicht bei jedem Schritt neu initialisieren

28.09.2026. Gesamtziel Performance weiterhin offen.

Der native Trace zeigte 101 Aufrufe von Wilds.initializeForMap bei vier
Kartenwechseln. Städte ohne passende Begegnungstabelle blieben absichtlich
uninitialisiert; onStepped versuchte deshalb bei jedem Schritt erneut den
vollständigen Kartenscan. Die Summe der Initialisierungen betrug 107,74 ms.

Kanto vendor/wilds_1_12_2/lib/spawn_logic.lua überspringt diesen Versuch jetzt
nur bei der bereits bestätigten Ursache „no supported encounter surface“,
identischer Karte, keinem gespeicherten Fehler und weiterhin fehlender gültiger
Gras-/Wassertabelle. Jede Schrittabfrage liest die aktuellen Tabellen. In-place
Änderungen an Fangrate/Slots sowie ersetzte Daten werden damit berücksichtigt.
Andere Fehler und vorübergehend belegte Felder dürfen weiterhin erneut versuchen.
Kontakte, Schrittzähler, Despawn und Wandern behalten ihren Ablauf.

Der native Gegenlauf bestand mit vier statt 101 Initialisierungen (24,30 ms
Summe). Das ist ein Aufrufnachweis, kein allgemeiner FPS-Gewinn: die zeitabhängigen
Spawns der Streckenläufe sind nicht identisch. Der zusätzliche Detailtrace
zeigte danach weitere Spitzen in der Kampfplatzsuche beim Rivalenporträt; RC36
behandelt diese unabhängig.

Kanto tests/wilds_empty_map_retry_test.lua besteht: 100 leere Stadtschritte,
Kontakt- und Zählersemantik, Angeltabelle, Rate null, live aktivierte Rate/Slots,
Wassertabelle, ersetzte/fehlende Daten, Fehler und veraltete Kartenidentität.

Artefakte: artifacts/performance-map-callbacks-20260928, Läufe before/after/detail.
Alle drei nativen Strecken bestanden. Voxel-Gebäude waren ausdrücklich aktiviert.
Die zusätzliche Instrumentierung liegt in tests/native/rc27_model_trace.lua
und wird ausschließlich bei QA_CALLBACK_TRACE=1 aktiviert. Diese Änderung
betrifft den gebündelten Gen1-Wilds-Pfad; sie ist kein Gen2-Performancebeleg.
