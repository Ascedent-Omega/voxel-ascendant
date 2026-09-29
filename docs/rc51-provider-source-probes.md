# RC51 – Provider-Quellen einmal je aktiver Karte prüfen

29.09.2026. Im internen Wilds-Renderer von Kanto Ascendant führte jeder Versuch, die aktive Spawn-Funktion abzusichern, erneut die Dateisuche der eingebauten Sprite-Provider aus. Die Registry merkt sich jetzt die abgeschlossene Suche für dieselbe Game-/Map-Instanz. Kartenwechsel, neue Map-Instanzen bei Reload, Provider-Registrierung/Entfernung und explizite Finalisierung verwerfen diese Abkürzung. Fehlgeschlagene Prüfungen werden erneut versucht. Die Prüfung der aktuellen Spawn-Funktion läuft weiterhin bei jedem Versuch.

`tests/sprite_provider_finalization_test.lua` im Kanto-Worktree prüft 100 wiederholte Aufrufe, Karten-/Game-Wechsel, Reload, explizite Aktualisierung, Registrierung/Entfernung, Fehlerwiederholung, fehlenden Kartenkontext und den Fallback für ältere Registries. Bestanden. Zwei stumme native Rundläufe über Celadon, Route 7 und Route 16 sind regulär beendet; Voxelgebäude, Nacht, Regen und FULL-Wasser bleiben aktiv.

Direktes Ergebnis: Bei jeweils 35 Absicherungen sinken die vollständigen Quellensuchen von 35 auf 8; zusammen von 18,07 auf 7,35 ms. Die laufende Absicherung selbst findet weiterhin 35-mal statt. Acht Kartenladungen pro Lauf.

Kein nachgewiesener Gesamt-FPS-Gewinn aus diesem Paar: mittlere CPU-Zeit 14,39 → 15,48 ms, p95 25,15 → 26,08 ms. Nach Setup, überdeckten Ladephasen und diagnostischer Wegsuche wurden 5161 beziehungsweise 5111 Frames ausgewertet. Das sind synthetische Kartenwechsel und kein Beleg für vollständig vorbereitete Regionen. Im zweiten Lauf trat ein 191,72-ms-Frameabstand auf, während Update und Draw des vorhergehenden Frames zusammen nur 28,45 ms beanspruchten. Dieser ungeklärte Abstand benötigt zusätzliche Messung außerhalb von Update/Draw; die Änderung behebt ihn nicht nachweislich.

Artefakte: `/Users/maarten/Documents/Recompile/artifacts/performance-spawn-provider-probes-20260929`. Der Checkpoint umfasst zwei Produktionsdateien, den Registry-Test, den nativen Treiber und dieses Dokument. Keine visuellen Funktionen abgeschaltet; keine Prüfung auf physischem iPhone oder Switch.
