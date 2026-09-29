# RC49 – Zeichenpfade geprüft, keine Produktionsänderung

29.09.2026. Stumme native LOVE-QA, Saffronia/Celadon, volle Gebäude, Nacht/Regen, FULL-Wasser.

Die Möbel-Snapshots waren in allen gemessenen Ansichten gültig: keine ständig verworfenen Snapshot-Caches. Ihre laufende Prüfung kostet unter zusätzlicher Methodeninstrumentierung etwa 1–1,5 ms pro Frame. Daraus wurde kein unbelegter Cache-Umbau abgeleitet.

Ein zweiter Versuch prüft Wasserflächen zusätzlich in räumlichen Dreiecksgruppen. In den je zwölf festen Ansichten von Saffronia und Celadon blieb die Entscheidung, ob ein Reflexionspass erforderlich ist, in jeder Phase identisch. Diese zusätzliche Prüfung wurde daher nicht in den Produktionspfad übernommen. Der Test kann mit QA_CLUSTER_WATER den experimentellen Filter aktivieren; die gespeicherte Probe zählt nur und zeichnet weiterhin den bisherigen Pfad.

Artefakte: `/Users/maarten/Documents/Recompile/artifacts/performance-furniture-validation-20260929`, Unterordner `profile` und `water-probe`. Beide nativen Prozesse erfolgreich beendet.
