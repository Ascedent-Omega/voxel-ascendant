# RC48 – Nachladespitzen gegen echte Gebietsvorbereitung geprüft

29.09.2026. Diagnose, keine neue Produktionsänderung.

Die vorherigen Saffronia-Lauftests verwendeten einen gleichartigen Außenkarten-Warp. Dieser aktiviert die Gebietsvorbereitung nicht. Der neue Lauf startet in Silph Co und verlässt das große Gebäude über den nativen Übergang. Dadurch wird der vorhandene regionale Ladeauftrag tatsächlich ausgelöst. Alle 13 entdeckten Karten wurden vorbereitet; vier optionale Nachbarschaftspanoramen blieben durch die bestehende Speicher-/Aufbaugrenze eingeschränkt. Der Test benutzt eine gültige Straßenposition als Ziel, nicht den durch das äußere Voxelgebäude überdeckten alten Testpunkt. Er ersetzt keinen manuellen Durchgang durch die Tür.

Über 5.616 sichtbare Geh-/Drehframes bei Nacht, Regen, FULL-Wasser und aktiven Voxelgebäuden:

- CPU-Mittel 11,84 ms, p95 18,88 ms, Maximum 38,90 ms.
- Gesamte Framezeit im Mittel 14,76 ms, p95 21,32 ms, Maximum 41,53 ms; sieben Frames über 33,33 ms.
- Update-Maximum 8,29 ms. Terrain-Pump maximal 0,027 ms.
- Mesh-Anlage maximal 0,80 ms, Vertex-Upload maximal 0,38 ms; keine Mesh-Anlage über 2 ms im gemessenen Lauf.

Die verbleibenden Spitzen sind überwiegend Zeichenarbeit bei Drehungen. Das bestätigt den Nutzen der bestehenden Gebietsvorbereitung, beweist aber weder dauerhaft 60 FPS noch die Behebung des gemeldeten 4-FPS-Falls. Physisches iPhone und Switch wurden nicht geprüft.

Ein Versuch mit früher einsetzenden kleinen Mesh-Upload-Portionen wurde zurückgenommen: Unter Last wanderte die Treiberwartezeit von der Anlage zum Befüllen des Puffers (bis 28,71 ms). Die isolierte GPU-Geometrieprüfung war für sechs Größen exakt gleich, lieferte aber keinen ausreichenden Beleg gegen die realen Spitzen. VoxelItems.lua entspricht wieder exakt dem gesicherten Ausgangsstand.

Die Treiber speichern den gemessenen Frame vor dem Coroutine-Warten. Ältere Dateien `before` benötigen bei der Auswertung minus eins; `after` und `region` bereits die direkte Zuordnung. Test-Pfadsuche, ihr anschließender Delta-Frame sowie Abschluss-JSON und Screenshots gehören nicht zur Spielmessung.

Artefakte: `/Users/maarten/Documents/Recompile/artifacts/performance-update-spikes-20260929`, insbesondere `region/analysis.json`, `region/trace.json`, `region/walk.json`, `geometry/paged.json` und `comparison.json`.
