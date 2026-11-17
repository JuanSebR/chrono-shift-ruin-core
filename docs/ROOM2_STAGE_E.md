# Room2 — Etapa E: transiciones bidireccionales

Room1.5 añade `EntryFromRoom2` en (950,351) y `LevelTransition_Room2` en (1007,351), con forma 34×160, máscara 2 y destino `res://scenes/Room2.tscn` → `EntryMarkers/FromRoom1_5`.

Room2 conserva `EntryMarkers/Spawn` para ejecución independiente y añade `EntryMarkers/FromRoom1_5` en (100,560). `RoomTransitions/ToRoom1_5` está en (28,550), forma 40×130 y máscara 2. Su destino es `res://scenes/Room1_5.tscn` → `EntryFromRoom2`. Ambos `Area2D` reutilizan `LevelTransition.gd`; no hay puerta gráfica adicional.

`scripts/rooms/room2.gd` aplica la llegada durante `_ready()` con `GameProgress.apply_room_arrival()`. Esto conserva salud, orientación, invulnerabilidad y cooldown de ataque conforme al contrato existente. La espada sigue en el autoload, sin cambio de formato del guardado. El Player de Room2 continúa apareciendo en (100,560) al ejecutar la escena de forma independiente.

Seguridad: la llegada a Room2 está 52 unidades a la derecha del borde del área de retorno. La llegada a Room1.5 está a la izquierda de su salida y a más de 40 unidades del Enemy1, incluso durante los tres ciclos de prueba. Las llegadas se registraron sincrónicamente en `SceneTree.scene_changed`, después de `_ready()` y antes del siguiente movimiento físico: (100,560) y (950,351), velocidad (0,0) en cada ciclo.

Pruebas: `tests/room2_transition_test.gd`: 43 PASS, 0 FAIL, tres ciclos completos. Salud 2/3, espada, orientación, inmunidad inicial, movimiento voluntario, suelo seguro, un Player y ausencia de bucles comprobados. `tests/room_transition_test.gd`: 57 PASS, 0 FAIL. `tests/attack12_test.gd`: 38 PASS, 0 FAIL. `tests/validate.gd`: PASS. Los registros están en `C:/Users/juans/AppData/Local/GodotMCPCodex/tests/room2_stage_e/`.

Cuatro capturas reales OpenGL de las salidas y llegadas se encuentran junto a los registros. Las áreas son funcionales e invisibles, sin señalización gráfica añadida. Una sesión visual interactiva con control humano sigue pendiente.

Respaldos SHA-256 verificables previos: `Room1_5.before.tscn` y `Room2.before.tscn` en el mismo directorio de pruebas. No se modificaron ROOM1, Player, HUD, combate, diálogos, Enemy1, GameProgress ni LevelTransition.

Pendiente para Etapa F: integrar HUD, daño y derrota de Room2 mediante sus señales existentes. Room2 todavía no tiene esos nodos o conexiones, por decisión de alcance de esta etapa.
