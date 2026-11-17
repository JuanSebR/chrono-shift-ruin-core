# Room5 — Fase E: Llave del Reactor y conexión bidireccional

16 de noviembre de 2026. Precisión de progresión aprobada por el usuario: completar físicamente Sala4 concede automáticamente la Llave del Reactor, sin coleccionable ni interacción E. No se implementó el Guardián, BossHUD ni ataques.

## Implementación

GameProgress incorpora `has_reactor_key` y `reactor_key_acquired` al formato v1 existente. Ausencia del campo significa false, conservando espada, Lente, tutoriales y diálogos. La adquisición guarda primero; si falla revierte la posesión y no emite confirmación. Nueva Partida incluye rollback del campo si falla su guardado. Continuar utiliza la carga existente. No hay otro archivo de progreso ni autoload.

Room4 exige Lente, salud positiva, suelo real y contacto superior con ExitLedge después de haber tocado físicamente PastRight en un recorrido continuo. Un desplazamiento superior a40 unidades entre pasos invalida ese recorrido; las recuperaciones legítimas reinician el seguimiento, sin otorgar la llave. Una llegada FromRoom5 no inicia un recorrido de adquisición. Esto excluye colocaciones artificiales habituales, aparición, paso inferior y proximidad aérea; no es un sistema contra trampas ni una prueba criptográfica de procedencia del movimiento.

La llave se concede una sola vez. Ante fallo de guardado se permite reintentar después de1s mientras siga cumpliéndose el contacto. El trigger solo monitoriza cuando la posesión está confirmada. No cambia posición, salud, dimensión ni física para desbloquearlo.

La notificación reutiliza otra instancia de TutorialHints, llamada ReactorNotice: `LLAVE DEL REACTOR OBTENIDA`, durante2,5s, anclada en(1100,170). TemporalTutorial se pausa únicamente durante el aviso para evitar superposición. No bloquea controles ni toca el HUD circular. Las capturas verifican legibilidad sin tapar al Player o la salud.

## Transiciones

| Origen | Trigger / tamaño | Destino y llegada |
|---|---|---|
| Room4 | ToRoom5(1253,264),8×40 | Room5/FutureFromRoom4(180,600) |
| Room5 | ToRoom4(100,600),8×40 | Room4/FromRoom5(1160,264) |

Se conserva FutureRoom5Access(1188,264) y el marcador provisional de Room5 para no romper consumidores históricos. Los triggers reutilizan LevelTransition.gd intacto. La salida de Room5 se alcanza desde el interior, sin quitar paredes. Ningún marcador se superpone con el trigger de retorno.

La primera salida propuesta enX1234 interceptaba el frenado final del recorrido histórico. La regresión lo detectó: se desplazó exclusivamente aX1253, donde se alcanza aún con apoyo en la repisa y después del sector usado para descansar. El recorrido completo volvió a pasar, sin alterar plataformas ni expectativas.

Las nuevas escenas inicializan su propio gestor en Presente, sin cooldown ni protección heredada, incluso al salir desde Pasado. La llegada conserva salud, posesiones y tutoriales mediante el contrato existente. Room5 fuerza orientación derecha después de aplicar la llegada; Room4 ya lo hacía. Se mantienen cámara, Shapes y geometría.

Al volver a Room4 el checkpoint es Spawn(64,396); no se activa el central por llegar a la repisa. La prueba produce una caída posterior mediante movimiento real y confirma recuperación al checkpoint inicial, conservando salud y llave. No se guarda un checkpoint nuevo.

## Pruebas

Perfiles APPDATA aislados, Godot4.7.2, reloj fijo60fps. Se ejecutaron secuencialmente las once pruebas solicitadas. Las pruebas nuevas reutilizan el recorrido físico de room4_route_test: seis saltos reales, cambios dimensionales y contacto identificado con ExitLedge, sin teletransportar para declarar la adquisición. Los escenarios negativos de aire, zona inferior y colocación artificial son fixtures separados y no cuentan como recorrido.

| Prueba | Resultado final |
|---|---|
| room4_reactor_key_test | PASS: v1 antiguo, recorrido, evento único, aviso, persistencia, derrota y Nueva Partida |
| room4_room5_transition_test | PASS: tres ciclos reales, llegadas, salud2/3, posesiones, ausencia de bucles y caída posterior |
| room5_base_test | PASS:71 comprobaciones, incluidos contratos dimensionales actualizados |
| room5_dimension_test | PASS:153 comprobaciones |
| room4_route_test | PASS después del ajuste localizado del trigger |
| room4_fall_recovery_test | PASS |
| room3_room4_transition_test | PASS |
| temporal_shift_protection_test | PASS |
| temporal_lens_hud_dynamic_test | PASS |
| progress_menu_test | PASS con su configuración de aislamiento exigida |
| validate | PASS, salida0 |

progress_menu_test exige `application/config/name=Core9_Combat_Isolated`: la primera ejecución se detuvo en esa precondición. Se terminó solo ese proceso y se ajustó exclusivamente la copia externa del proyecto; después pasó. Se restauró esa copia antes de validar. El proyecto real y las expectativas del test no se modificaron para ello.

Los tests siguen mostrando advertencias de ObjectDB/recursos al cerrar algunas ejecuciones; se registran separadas de los resultados funcionales. No se declara resuelto ese diagnóstico previo ni realizada una prueba larga de memoria.

La prueba base conserva todos sus controles físicos. Durante su tramo específico de límites deshabilita la monitorización de la salida solo en la instancia de prueba, para medir las paredes sin salir de la sala; la transición real se prueba aparte. La prueba dimensional requirió una dependencia adicional localizada: ahora verifica dos Area2D y el destino real de retorno, conservando sus controles dimensionales. Se respaldó antes de actualizarla.

## Evidencia y respaldo

Renders reales del viewport en `artifacts/room5_stage_e/`, a1024×572 y1280×720: `key_exit_ledge` combina llegada final, aviso y acceso desbloqueado; `room5_arrival` combina spawn, salud y Presente; `room4_return` muestra el regreso sin readquisición ni bucle. Son seis imágenes, sin mockups externos.

Respaldos verificados: `C:/Users/juans/chrono-shift-backups/room5_stage_e_20261116_152139/`. El manifiesto `hashes.json` contiene SHA-256. La línea base y comparación final están en `artifacts/room5_stage_e/verification.json`, junto con logs de ejecución copiados para esta fase. Se comprueban aparte los guardados reales y las secciones físicas de ambas escenas.

Modificados: Room4.tscn, Room5.tscn, room4.gd, room5.gd, game_progress.gd, room5_base_test.gd y el control topológico de room5_dimension_test.gd. Creados: room4_reactor_key_test.gd, room4_room5_transition_test.gd, este informe y evidencias. Player, DimensionManager, GameManager, LevelTransition, HUD, escenas anteriores, arte y configuraciones reales se conservan.

Los helpers y perfiles externos se encuentran en `C:/Users/juans/.codex/visualizations/2026/11/16/01a1e570-850c-7a83-8965-7511f3d3ed84/phase_e_work/`. Se reutilizó el runner externo de D; las regresiones escribieron artefactos en su espejo independiente, conservando las evidencias anteriores del repositorio. La ruta ejecutable efectiva fue `C:/Godot/godot.exe.exe`; la ruta histórica de Downloads sigue siendo un directorio.

## Límites y siguiente fase

La validación no incluye fallo real de disco inyectado ni todas las trayectorias artificiales posibles; el rollback se implementa siguiendo la adquisición de Lente existente. No se cambió el punto al que Continuar envía al jugador: continúa en Room1.5, preservando la llave cargada. No se desarrolló intro, jefe, combate, barreras ni victoria. La Fase F requiere autorización independiente.
