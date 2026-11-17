# Room4 · Validación final

Sala 4 cumple los criterios funcionales de cierre como tutorial dimensional jugable. La geometría de colisiones coincide con el respaldo anterior a la Fase G. Se revisaron Room3 y Room4 mediante el puente del editor, con las escenas guardadas y detenidas. Las pruebas cargaron las escenas desde disco con Godot 4.7.2.

## Integración

La prueba nueva empieza en el tramo final de Room2.2, cerca de la puerta. Desde ahí usa movimiento real para entrar a Room3, acercarse al pedestal, recoger la Lente, saltar sobre el pedestal y llegar a Room4. Verifica levitación, E, bloqueo durante la desaparición, desbloqueo de la puerta y llegada en (64,396) con velocidad cero, Presente y 2/3 de salud. Lee posición y velocidad en scene_changed.

Recorre los siete apoyos y llega a X≥1210 sobre la repisa final. Antes de completar el recorrido provoca dos caídas reales: desde la entrada y desde el centro en Pasado. Verifica recuperación en el punto debido, sin pérdida de salud. Completa los tres aprendizajes, recorre el camino inverso y regresa a Room3 desde Presente. Reingresa, confirma una instancia limpia y vuelve a Room3 desde Pasado con pedestal vacío y HUD neutral. El marcador FutureRoom5Access permanece en la repisa y la única transición activa apunta a Room3.

Continuar se ejecuta desde el menú real con el estado en memoria reinicializado para obligar a leer el archivo. Recupera espada, Lente y aprendizajes. También se verifica una derrota con reinicio en Room1.5 y Nueva Partida desde el menú real. Después de Nueva Partida, una carga de diagnóstico de Room3 comprueba que el módulo vuelve y el indicador permanece oculto.

## Regresiones

| Prueba | Resultado |
|---|---|
| room4_base_test | PASS · geometría, apoyos, cámara y HUD únicos |
| room4_dimension_test | PASS · matrices, cooldown, rechazo, cambios en suelo y aire |
| temporal_lens_hud_test | PASS · posesión e integración compartida |
| temporal_lens_hud_dynamic_test | PASS · disponibilidad, recarga real y rechazo |
| room4_route_test | PASS · ida y vuelta, incluido cambio cerca del ápice |
| room4_fall_recovery_test | PASS · ambos checkpoints, recuperación durante recarga y tras rechazo |
| room3_room4_transition_test | PASS · adquisición y transiciones |
| room4_tutorial_test | PASS · apoyo físico, orden flexible y persistencia |
| validate | PASS · validación de sintaxis |
| room_transition_test y room2_transition_test | PASS · Room1 ↔ Room1.5 y Room1.5 ↔ Room2 |
| room4_final_integration_test | PASS · flujo integrado desde el acceso final de Room2.2 |

Las pruebas se ejecutaron secuencialmente con perfiles aislados y reloj fijo de 60 fps. No se ejecutó el recorrido de las seis salas en una sola partida. No reapareció el fallo temporal de la prueba del HUD observado en una corrida concurrente anterior.

Algunas pruebas repitieron mensajes de ObjectDB y recursos todavía en uso durante el cierre. Los mensajes salieron de la limpieza final del motor. No se observó un fallo de juego asociado en los casos ejecutados. Este diagnóstico no determina si hay crecimiento de memoria en una sesión larga.

## Evidencia visual

Renders del viewport de Godot en artifacts/room4_stage_h a 1024 × 572 y 1280 × 720. Los hitos incluyen entrada, salto con cambio, descanso, recuperación, repisa final y retorno con pedestal vacío. Los renders específicos de la recarga y del rechazo de Fase D complementan la revisión.

Cambios de Fase H: prueba de integración, este informe y capturas. No hubo archivos existentes que modificar o respaldar.
