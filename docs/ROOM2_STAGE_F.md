# Room2 — Etapa F: HUD, salud y derrota

La escena `scenes/Room2.tscn` instancia una sola vez `scenes/ui/CombatHUD.tscn` como hijo directo `CombatHUD` (CanvasLayer). El árbol conserva BackgroundVisual, WorldCollision, ForegroundVisual, EntryMarkers, RoomTransitions y un solo Player con su Camera2D.

`scripts/rooms/room2.gd` aplica primero `GameProgress.apply_room_arrival()`, conecta `health_changed`, `damage_taken` y `defeated`, e inicializa el HUD con la salud real. El Player sigue siendo la fuente del valor lógico y de los 60 fotogramas de protección; el HUD solo presenta ese estado. La derrota muestra el mensaje existente, espera `defeat_animation_finished`, luego 0,25 s y recarga la escena. Una bandera evita programar dos reinicios.

La lógica de reinicio sigue el orden de ROOM1 y ROOM1.5. Room2 no añade enemigo, caída mortal ni guardado de ubicación. El Player reinicia en (100,560) con 3/3; la espada persiste mediante GameProgress. La salud transferida entre salas sigue siendo estado de sesión y aparece en el HUD en `SceneTree.scene_changed`, antes del siguiente movimiento físico.

Pruebas headless: `tests/room2_health_test.gd` 11 PASS/0 FAIL (3→2→1→0, daño aceptado, golpe rechazado durante invulnerabilidad, alerta, animación completa de derrota, reinicio y espada); `tests/room2_health_transfer_test.gd` 14 PASS/0 FAIL (3/3, 2/3, 1/3 en ambos sentidos, alerta crítica al llegar); `tests/room2_transition_test.gd` 43 PASS/0 FAIL; `tests/room_transition_test.gd` 57 PASS/0 FAIL; `tests/attack12_test.gd` 38 PASS/0 FAIL; `tests/validate.gd` PASS. Registros en `C:/Users/juans/AppData/Local/GodotMCPCodex/tests/room2_stage_f/`. Las suites antiguas combat/presentation mantienen antecedentes de 5/4 fallos; no se ejecutaron en esta etapa porque no se cambiaron esas mecánicas.

Diez capturas reales de Godot OpenGL, a 1024×572 y 1280×720, cubren 3/3, 2/3, 1/3, efecto de pérdida y derrota. La revisión de estas capturas confirmó HUD anclado arriba a la izquierda, sin tapar al Player en la aparición inicial. La prueba visual interactiva con control humano queda pendiente.

Respaldos previos con SHA-256 coincidente: `Room2.before.tscn` y `room2.before.gd` en el directorio de pruebas indicado. No se modificaron Player, HUD compartido, ROOM1, ROOM1.5, GameProgress, combate, animaciones, diálogos ni las transiciones.

Pendiente para una etapa posterior: contenido narrativo o enemigos, sujeto a autorización separada. No se incorporaron en esta etapa.
