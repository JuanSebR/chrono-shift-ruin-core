# Sala 5 — Fase H.3: ciclo ofensivo controlado

Implementado el 16 de noviembre de 2026 con Godot 4.7.2. Room5 conserva la entrada pasiva. El ciclo solo empieza mediante `CoreGuardian.start_combat_cycle() -> bool`; `stop_combat_cycle() -> void` lo detiene y puede repetirse con seguridad. No se conectó ningún disparador, proximidad ni activación en `_ready`.

## Arquitectura y estados reales

El mismo CoreGuardian gobierna selección, ataques y ventanas con su reloj físico `beam_elapsed/beam_duration`. No hay otro controlador, autoload, Timer ni máquina de estados paralela. Se añaden CYCLE_WAIT, APPROACH, CORE_OPENING y CORE_CLOSING al enum existente. El ciclo llama a las APIs originales de los ataques y espera su retorno efectivo a IDLE después de eliminar peligros y completar su recuperación.

| Tramo | Estado/animación | Núcleo |
|---|---|---|
| Descanso inicial o entre ciclos | CYCLE_WAIT / Repose | Cerrado |
| Selección determinista | Transición inmediata desde descanso | Cerrado |
| Haz o arco | Estados originales de G/H.2 | Cerrado |
| Recuperación ofensiva | RECOVER original, incluido fin de disipación | Cerrado |
| Aproximación | APPROACH / Repose | Cerrado |
| Descenso | CORE_OPENING / Vulnerable completo | Cerrado |
| Oportunidad de ataque | VULNERABLE / última pose baja sostenida | Expuesto, daño solo en Presente |
| Cierre | CORE_CLOSING / Retorn | Cerrado desde antes de cambiar de pose |
| Descanso siguiente | CYCLE_WAIT / Repose | Cerrado |
| Derrota | DEFEATED existente | Cerrado, ciclo detenido |

La API de inicio valida IDLE, salud del jefe y Player, DimensionManager, ausencia de núcleo abierto y ausencia de peligros/acciones. Una segunda llamada es rechazada. Mientras está activo, las APIs diagnósticas externas de ataque/exposición/animación no pueden sustituir la acción del ciclo. La selección tiene un permiso interno de despacho limitado a su llamada; no hay ataques simultáneos. `cancel_arc()` durante un ciclo lo detiene por completo.

## Selección, elegibilidad y alternancia

`select_cycle_attack()` consulta al Player actual y la dimensión confirmada. `beam_eligible()` calcula exactamente la banda rectangular del haz: origen derivado del landmark Repose0, longitud configurada, altura24, hacia izquierda. Intersecta ese volumen con el CollisionShape2D real del Player mediante las transformaciones mundiales, y exige Presente y Player vivo. No gira el haz ni cambia su geometría. El arco es la alternativa válida con Player vivo y referencias válidas.

- F0, fuera de banda o detrás del jefe: arco, aunque el último ataque haya sido otro arco.
- Dentro de banda y en Presente: haz si el último ataque no fue haz; si ambos son elegibles y se acaba de usar haz, arco.
- Pasado: arco; no se considera peligroso un haz que no puede dañar en esa dimensión.
- `cycle_alternate=false`: prioriza el haz cuando sea elegible; no añade aleatoriedad.

Caso medido importante: Player en P1, centro (580,480), es elegible por contacto de su borde inferior con la banda. La prueba ejecutó el haz real y redujo la salud a2/3. No se presupone que P1 sea siempre segura ni siempre peligrosa. Un fixture aéreo más alto, (580,440), queda fuera de banda y selecciona arco. R1 permite haz; F0 y la parte posterior del jefe no lo fuerzan. La elegibilidad es una fotografía al seleccionar: los avisos originales permiten que el Player se mueva después.

## Parámetros y ventana efectiva

Todos los tiempos siguientes están exportados en el controlador, en segundos; no fue necesario editar la escena.

| Parámetro | Valor inicial |
|---|---:|
| cycle_initial_rest |1,00 |
| cycle_between_rest |1,00 |
| cycle_approach_time |4,75 |
| cycle_exposure_time |2,00 |
| cycle_close_rest |0,40 |
| cycle_alternate |true |

Las recuperaciones ofensivas originales permanecen intactas: haz0,40 s y arco0,40 s, además de sus fases/efectos originales. No se aplica ninguna reducción por salud.

La aproximación empieza después de la recuperación ofensiva, sin paquete ni haz persistentes. El descenso usa las seis poses Vulnerable a8fps (0,75 s). La apertura lógica espera ese tiempo y la pose5 final; entonces sostiene la pose y empieza el contador de exposición. El núcleo final conserva su landmark mundial aproximado (1081,092875;566), círculo9 y la matriz original de defensa.

La duración configurada es2,00 s; la observación entre apertura y cierre en los ensayos fue121 pasos físicos a60Hz (≈2,017 s, un paso de cuantización). No se cuentan los0,75 s de descenso como exposición. Al terminar se cierra la lógica antes de Retorn; su duración0,50 s más descanso de cierre0,40 s precede al siguiente descanso1,00 s. No queda Vulnerable indefinidamente.

## Espada, dimensiones y salud

Se conserva `max_health=12`, daño1 por tajo y espada original de12 cuadros a24fps. La prueba emplea Input, salto y área ofensiva real; no demuestra las oportunidades de daño llamando directamente a `take_damage` del jefe.

Resultados: un tajo válido resta exactamente1; dos saltos/tajos independientes restan2 en una apertura; espada desde suelo, fuera de alcance, en Pasado o después del cierre no resta salud. Una prueba terminal separada parte de salud diagnóstica1 y aplica el último daño mediante la espada real: llega a0, reproduce derrota y cancela el ciclo. Esto no equivale a haber vencido desde12HP en una partida completa.

El haz conserva peligro solo en Presente. El arco conserva peligro en ambas dimensiones y sus invulnerabilidades. Shift continúa usando cooldown0,20 s y protección0,16 s; el ciclo nunca deduce la dimensión por una tecla. Se ensayó evitar haz en Pasado y regresar a Presente durante aproximación. La espada real en Pasado durante exposición fue rechazada. Un Shift rechazado por ocupación en un fixture separado conserva Presente, no concede protección y no altera la regla de vulnerabilidad; el tajo fuera de alcance sigue sin causar daño.

## Recorrido continuo desde aparición normal

Este tramo se distingue de los fixtures posteriores: no recoloca al Player ni desactiva la salida. Comienza en la aparición normal de Room5, (140,600), con perfil aislado, espada y Lente habilitadas en memoria de prueba.

1. Se activa la API; tras1 s selecciona arco por F0.
2. El Player espera el momento de evasión conocido de H.2 e introduce un salto real; conserva3/3.
3. Finalizan paquete, disipación y recuperación. Empieza la aproximación.
4. Shift real a Pasado, desplazamiento hacia derecha mediante Input y freno normal, hasta aproximadamente (1056,444;599,975).
5. El desplazamiento desde X140 requiere230 pasos, **3,833 s**. Las esperas de Shift/freno también caben en los4,75 s. Se regresa a Presente con Shift real antes de golpear.
6. Se espera el descenso completo. Dos saltos y tajos independientes bajan salud del jefe12→11→10 durante una ventana; Player sigue3/3.
7. Se espera cierre/recuperación. Un tajo posterior no hace daño. Comienza el siguiente arco, contado como ataque2 y ventana1 terminada.
8. Stop repetido elimina el aviso y devuelve reposo; no reinicia espontáneamente.

Los fixtures siguientes cambian posiciones iniciales para aislar altura, dimensiones, cancelaciones y derrota. No se presentan como parte del recorrido continuo anterior.

## Cancelación y ciclo de vida

Stop cierra el núcleo, apaga el haz, elimina paquete/aviso, desconecta la señal del Player y restaura Repose, salvo si ya está DEFEATED. Se probó durante descanso, haz activo, emisión de arco, aproximación, descenso, exposición y cierre. Las solicitudes externas quedan rechazadas durante el ciclo. No se quedan ataques esperando al final de una señal para reiniciarse.

La derrota del Player solicita cancelación en el controlador. Si ocurre dentro del contacto del paquete, se termina primero ese callback físico y se limpia inmediatamente después, evitando liberar el sprite mientras su componente todavía resuelve el contacto. El siguiente paso también comprueba salud/referencias por seguridad. El ensayo con salud1 recibe el impacto letal real del arco y no conserva peligros ni otra ventana.

La derrota del jefe tiene prioridad: desconecta el objetivo y cancela las dos ofensivas antes de DEFEATED. No admite nuevo inicio. La salida real Room5→Room4 fue probada mediante movimiento izquierdo con arco en vuelo: se libera jefe y paquete. También se prueba liberación directa de Room5 y una instancia nueva pasiva. LevelTransition y las puertas no se modificaron.

## Pruebas y regresiones

`tests/core_guardian_combat_cycle_test.gd`: **51 comprobaciones físicas PASS** en su versión final, incluidas la salida real con ciclo activo y la medición de exposición. Cubre selección, alternancia, exclusividad, aproximación continua, espada, dimensiones, cierre, siguiente ataque, cancelaciones y derrotas. Las capturas se obtuvieron con el mismo comportamiento de producción; los renders de ambas resoluciones ejecutan50 controles más11 capturas (61 PASS); la comprobación adicional de salida activa se incorporó después y se ejecutó sin render.

Regresiones ejecutadas secuencialmente con perfiles APPDATA aislados:

| Suite | Resultado |
|---|---|
| core_guardian_base_test |30 PASS |
| core_guardian_beam_test |29 PASS |
| core_guardian_arc_test |57 PASS, conserva limitación lateral explícita H.2 |
| core_guardian_combat_cycle_test |50 PASS en batería;51 PASS tras añadir salida activa |
| room5_base_test |71 PASS |
| room5_dimension_test |153 PASS |
| room4_room5_transition_test |Sin fallos |
| attack12_test |Sin fallos |
| temporal_shift_protection_test |Sin fallos |
| validate |Sintaxis exitosa |

Los procesos se ejecutan con Godot4.7.2 y reloj fijo60fps. Los renders usan el proyecto real; las pruebas históricas utilizan el espejo externo de fases anteriores para preservar sus evidencias. Todos los logs y códigos de salida se copian a `artifacts/room5_stage_h3/logs/`. Los avisos existentes de ObjectDB/recursos al cerrar algunas pruebas se conservan aparte; no se investigaron ni se declaran solucionados. La nueva prueba se revisa tanto por aserciones como por diagnósticos.

## Capturas reales

22 PNG directos del viewport, sin retoque. El recorrido principal aporta diez estados; el haz proviene de su fixture R1. Las capturas no representan una partida completa hasta victoria.

| Estado |1024×572 |1280×720 |
|---|---|---|
| Reposo inicial |[PNG](../artifacts/room5_stage_h3/01_reposo_1024x572.png) |[PNG](../artifacts/room5_stage_h3/01_reposo_1280x720.png) |
| Arco seleccionado |[PNG](../artifacts/room5_stage_h3/02_arco_seleccionado_1024x572.png) |[PNG](../artifacts/room5_stage_h3/02_arco_seleccionado_1280x720.png) |
| Recuperación |[PNG](../artifacts/room5_stage_h3/03_recuperacion_1024x572.png) |[PNG](../artifacts/room5_stage_h3/03_recuperacion_1280x720.png) |
| Aproximación |[PNG](../artifacts/room5_stage_h3/04_aproximacion_1024x572.png) |[PNG](../artifacts/room5_stage_h3/04_aproximacion_1280x720.png) |
| Descenso |[PNG](../artifacts/room5_stage_h3/05_descenso_1024x572.png) |[PNG](../artifacts/room5_stage_h3/05_descenso_1280x720.png) |
| Expuesto |[PNG](../artifacts/room5_stage_h3/06_nucleo_expuesto_1024x572.png) |[PNG](../artifacts/room5_stage_h3/06_nucleo_expuesto_1280x720.png) |
| Espada real |[PNG](../artifacts/room5_stage_h3/07_espada_real_1024x572.png) |[PNG](../artifacts/room5_stage_h3/07_espada_real_1280x720.png) |
| Cierre |[PNG](../artifacts/room5_stage_h3/08_cierre_1024x572.png) |[PNG](../artifacts/room5_stage_h3/08_cierre_1280x720.png) |
| Siguiente ciclo |[PNG](../artifacts/room5_stage_h3/09_siguiente_ciclo_1024x572.png) |[PNG](../artifacts/room5_stage_h3/09_siguiente_ciclo_1280x720.png) |
| Stop |[PNG](../artifacts/room5_stage_h3/10_detenido_1024x572.png) |[PNG](../artifacts/room5_stage_h3/10_detenido_1280x720.png) |
| Haz seleccionado |[PNG](../artifacts/room5_stage_h3/11_haz_seleccionado_1024x572.png) |[PNG](../artifacts/room5_stage_h3/11_haz_seleccionado_1280x720.png) |

Se revisaron Player/HUD, núcleo bajo, espada visible y ausencia de efectos residuales al aproximar, abrir/cerrar y detener. Repose→Attack3 conserva la discontinuidad anatómica H.2 de unos64u; no se deforma el sprite para ocultarla. El arco sigue siendo un fragmento rectangular provisional. No hay una animación nueva para la aproximación.

## Balance provisional y Fase I

La ruta observada demuestra una oportunidad física de dos golpes con salud3/3, no una tasa de éxito humana. Las limitaciones de evasión lateral izquierda y salto tardío derecho de H.2 siguen vigentes. No se retocaron ataques, salto, velocidad ni geometría para hacer pasar las pruebas.

Con12HP y2 golpes por apertura serían necesarias6 ventanas; con1 golpe,12. Un ciclo entre ataques ronda11–13 s según recorrido/impacto del arco y cuantización. Esto sugiere aproximadamente70–150 s para esos escenarios ideales, no una victoria medida ni balance final. No hay una partida completa continua de12HP a0 ni frecuencia de daño humana medida; el recorrido ensayado conserva3/3, mientras el fixture terminal del Player acredita que puede morir por el ataque real.

Para Fase I se recomienda primero playtest de reconocimiento de pausas/apertura, retorno dimensional y margen de salto en extremos. Revisar feedback visible de núcleo protegido/abierto y continuidad artística antes de activar el encuentro por entrada, bloquear puertas o diseñar un final. Esas decisiones, BossHUD, música, segunda fase y persistencia de victoria siguen fuera de H.3.

## Archivos, respaldo e integridad

Único archivo preexistente modificado: `scripts/bosses/core_guardian.gd`. No fue necesario editar `CoreGuardian.tscn`. Nuevos: esta documentación, `tests/core_guardian_combat_cycle_test.gd`, evidencias y metadatos generados para el nuevo test.

Respaldo previo verificable de controlador y escena: `C:/Users/juans/chrono-shift-backups/room5_stage_h3_20261116_170503/`, con SHA-256 en `hashes.json`. Los dos componentes ofensivos, Room5, Player, gestores, transiciones, geometría, cámara, atlas, configuraciones y documentos anteriores conservan sus hashes. Los dos guardados reales se cotejan sin usarlos como perfiles de prueba.

La línea base y helpers están fuera del proyecto en `C:/Users/juans/.codex/visualizations/2026/11/16/01a1e570-850c-7a83-8965-7511f3d3ed84/phase_h3_work/` y su directorio padre. La prueba de integridad, hashes de capturas y resultados se encuentra en `artifacts/room5_stage_h3/verification.json`. No se escribieron memorias, credenciales ni configuraciones MCP.

Godot MCP confirmó antes de editar el proyecto correcto, Room5 detenida y sin cambios pendientes, e inspeccionó el árbol CoreGuardian. La recarga posterior conservó ese estado guardado. El trabajo se detiene en H.3.
