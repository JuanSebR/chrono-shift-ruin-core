# Sala 5 — I.3: dos etapas y descarga del escudo

16/11/2026 · Godot4.7.2 · Prototipo funcional controlado. **No se activa al entrar en Room5.**

## Resultado

El Guardián comienza en Etapa1 con12HP. Al alcanzar6HP registra una transición pendiente, conserva la apertura vigente, cierra el núcleo y completa Retorn/descanso. Después presenta1s de Repose protegido con aviso de sobrecarga y activa Etapa2 una sola vez, sin restaurar salud.

En Etapa2, un arco completo vuelve al descanso con núcleo protegido. Solo un haz realmente elegible al seleccionarlo, terminado con disipación y recuperación, habilita la siguiente aproximación/apertura. Se mantiene exposición2s y daño1 de espada real únicamente en Presente. No se exige recibir daño ni utilizar Shift: también se validó una evasión por movimiento.

**Victoria continua final desde el spawn, 12→0:** DEFEATED a73,833 s; rutina de prueba terminada a74,083 s. Player3/3,6 arcos,3 haces,6 aperturas,12 impactos,0 tajos fallidos y6 cambios dimensionales confirmados. Los intentos anteriores, incluidos uno fallido y otro que ganó con daño, se conservan y describen abajo. No es un playtest humano ni balance final.

## 1. Inspección y requisito previo, antes de implementar la regla

Se consultaron AGENTS, GDD/STATE, plan maestro, diseño del Guardián e informes H.3/I.1/I.2; se revisaron controlador, selector, final de ataques, pausa adaptativa, vulnerabilidad y recursos Starting/Retorn/Repose. No se auditaron otras salas. MCP confirmó Room5, proyecto correcto, juego detenido, sin cambios pendientes, y el árbol real CoreGuardian. Se aplicaron game-designer y godot-gamedev; las condiciones y diferencias se presentan en tablas sin regenerar diagramas previos.

Antes de editar el comportamiento de producción se creó y ejecutó `core_guardian_phase_two_test.gd --preflight` contra I.2:

1. Spawn(140,600), jefe12, Player3, equipo habilitado en sesión aislada.
2. Movimiento horizontal real hasta el sector R2 y salto desde F0; apoyo estable en R2, centroY≈540.
3. Inicio manual del ciclo. El selector eligió un haz en Presente sin llamar a `request_beam()` diagnósticamente.
4. Shift real a Pasado; R2 compartida mantuvo apoyo y no hubo daño.
5. Final del haz, disipación y recuperación; APPROACH recibió4,75s por altura.
6. Movimiento hacia el núcleo, caída legítima a F0, regreso a Presente, salto y dos tajos reales: jefe12→10, Player3/3.

**8/8 controles previos PASS.** Esta evidencia antecede a la nueva condición, no es una deducción geométrica. Datos en [preflight.json](../artifacts/room5_stage_i3/preflight.json) y log terminado en `_preflight`. No fue necesario recurrir a R1 como ruta alternativa. R1 sigue indicada como otra posición elegible, pero el procedimiento completo nuevo I.3 se acreditó sobre R2; no se declara una partida I.3 continua por R1.

## 2. Controlador, etapas y transición segura

Se amplía el mismo controlador/reloj físico. `combat_phase` es un dato lógico1/2; se añade únicamente PHASE_TRANSITION al enum de estados existentes. No hay otra máquina de estados, autoload, Timer ni dependencia instalada.

| Dato/configuración | Función |
|---|---|
| cycle_phase_two_enabled=true |Prototipo de dos etapas; false conserva Etapa1 para comparación diagnóstica |
| phase_two_health_threshold=6 |Umbral configurable; acotado al máximo de salud al cargar y al evaluar |
| phase_transition_time=1,0s |Presentación protegida, después de la recuperación del cierre |
| combat_phase / phase_two_activated |Etapa lógica y protección contra activación duplicada |
| phase_transition_pending |Solicitud diferida al cruzar umbral con salud positiva |
| phase_transition_count |Registro por instancia de activación completada |
| cycle_beam_was_eligible |Comprobante de la selección física de un haz del ciclo |
| shield_discharge_ready |Permiso para una apertura después de completar ese haz |
| phase_two_openings |Permite reducir la instrucción tras la primera apertura conseguida |

La señal nueva `combat_phase_changed(current:int)` informa la activación. Se conservan las señales de salud, estado y exposición. `start_combat_cycle()` y `stop_combat_cycle()` continúan siendo las únicas APIs de activación del encuentro. El modo diagnóstico no se conecta a `_ready`, entrada, llave ni proximidad.

Cruzar6 no termina el tajo ni la ventana. La solicitud permanece pendiente hasta que se cierra lógicamente el núcleo y termina CORE_CLOSING con Retorn0,50s y descanso0,40s originales. Solo sin peligros se entra en PHASE_TRANSITION. La presentación dura1s y luego vuelve al descanso entre ataques1s. La salud sigue siendo la alcanzada; no se instancia otro jefe.

La derrota tiene prioridad: al llegar a0 se cancela pendiente/descarga/acciones y se conserva DEFEATED. Stop también invalida pendiente y descarga; si se reinicia una instancia detenida con salud≤6, se vuelve a solicitar la transición segura, sin curar. Una segunda etapa ya activada permanece como etapa de esa instancia y no vuelve a presentarse. Una instancia nueva comienza en1 y salud12.

### Decisión artística

Starting tiene ocho poses de incorporación con cambios de silueta/anatomía respecto a Repose; no es arte explícito de sobrecarga. Se eligió la opción conservadora **Repose durante1s más el aviso holográfico**, después del Retorn existente. No se reutilizó Starting automáticamente, no se deformó ni redibujó el cuerpo y no se atribuyó vuelo al recurso Exit. El aviso da claridad al cambio de regla aunque no haya una animación artística exclusiva de etapa.

## 3. Regla de descarga y exclusividad

| Tramo | Etapa1 | Etapa2 |
|---|---|---|
| Selección |Selector original, dimensión y volumen reales |Exactamente el mismo selector |
| Después de arco completo |APPROACH → descenso → exposición |Descanso/selección, núcleo cerrado |
| Después de haz completo |APPROACH → descenso → exposición |Solo si fue elegible al seleccionar: descarga → APPROACH → descenso → exposición |
| Apertura |2s, solo Presente |2s, solo Presente y descarga autorizada |
| Cierre |Antes de Retorn |Antes de Retorn, invalida permiso consumido |

La elegibilidad se registra en el despacho del ciclo, consultando `beam_eligible()` real. Un Player en F0 no produce ese comprobante. La marca se mantiene aunque el Player esquive/cambie de dimensión después del aviso: no exige que siga en peligro ni reciba daño. El permiso de apertura se concede únicamente cuando el ataque retorna a IDLE seguro, sin peligro y después de su recuperación. Durante BEAM_ACTIVE la descarga todavía no está lista.

El permiso se limpia al cerrar, detener, derrotarse o iniciar una nueva ejecución controlada; no se reutiliza para otra ventana. Las solicitudes diagnósticas externas están bloqueadas mientras gobierna el ciclo. Un haz artificialmente solicitado fuera de él no acredita una apertura del ciclo. La validación de daño añade la condición de escudo a la matriz existente, sin cambiar CoreWeakpoint ni su alcance.

La alternancia original importa: después de un haz, si el Player vuelve a R2 en Presente, ambos ataques son elegibles y puede seguir un arco. Eso **no** descarga ni abre. Tras superarlo, el selector puede elegir el siguiente haz. No se fuerza un haz para cumplir una cuota y nunca hay dos ofensivas simultáneas.

## 4. Feedback local, ligado a condiciones reales

Se reutiliza una instancia local de `TutorialHints.tscn`, llamada GuardianHint, creada por `scripts/rooms/room5.gd`. El recurso/script compartido no se modifica. No se edita Room5.tscn, no se crea BossHUD ni se agrega audio o diálogo narrativo.

| Condición real | Presentación |
|---|---|
| Transición |«ESCUDO DEL NÚCLEO REFORZADO»; «Provoca el haz desde R2 o R1 en Presente»; comentario breve de C.O.R.E.-9 |
| Etapa2 sin apertura conseguida |Instrucción persistente; aclara que el arco no abre el núcleo |
| Haz en curso |«DESCARGA EN CURSO — no hace falta recibirla» |
| Descarga lista / aproximación |«DESCARGA COMPLETADA — acércate al núcleo» |
| Descenso |«ABRIENDO NÚCLEO — espera la postura baja» |
| Expuesto y daño permitido |«NÚCLEO EXPUESTO — espada en Presente» |
| Expuesto lógicamente, pero Pasado |«ESCUDO TEMPORAL — vuelve a Presente» |
| Cierre |«NÚCLEO CERRADO — se acabó la generosidad» |
| Protección después del aprendizaje |Estado breve «ESCUDO PROTEGIDO», sin repetir el bloque de instrucciones |
| Stop / derrota / carga pasiva |Sin panel activo |

La instrucción se reduce después de la primera apertura de Etapa2; no depende de una tecla ni de un temporizador arbitrario. La UI consulta `guardian_hint_text()` del jefe y la dimensión confirmada; solo cambia texto cuando cambia ese resultado. Los estados del jefe la actualizan inmediatamente y una lectura local por frame mantiene correcta la presentación dimensional, sin agregar observadores a DimensionManager.

Se conserva mouse_filter IGNORE del control, sin bloquear movimiento. El panel se ancla en la zona superior central, separado de salud y Lente en1024×572 y1280×720. No es un efecto ofensivo ni una retícula de daño. No dice «expuesto» cuando `can_receive_damage()` rechaza el daño.

Durante la revisión visual se detectó que TutorialHints solo reemplaza texto al cambiar su identificador. Se corrigió **en la llamada local** usando un ID asociado al contenido, sin tocar el componente compartido, y se añadieron aserciones del Label visible. También se retiró una suscripción dimensional local adicional que hacía fallar el conteo histórico de observadores: ahora se lee el estado y esa prueba conserva sus expectativas originales. Las capturas previas al arreglo de ID quedan en `diagnostics/`, claramente separadas de la evidencia final.

## 5. Pausa adaptativa y mecánicas conservadas

La lógica I.2 permanece: mínimo1,25s, máximo/respaldo4,75s, margen0,85s, referencia240u/s, muestreo único al entrar APPROACH. Una descarga completada desde R2 obtiene4,75s por altura; no se recorta por estar horizontalmente cerca. Si el Player ya ha abandonado la plataforma antes de APPROACH, se usa su posición/apoyo real al muestrear, como en I.2.

No cambian los dos componentes ofensivos, sus hitboxes, tiempos, curvas, barrido, daño ni reglas dimensionales. Player conserva física, espada12 cuadros,3HP, cooldown Shift0,20s y protección0,16s. El haz sigue dañando solo en Presente y el arco en ambas dimensiones. La exposición sigue comenzando en la postura baja tras0,75s y dura2s configurados, con la cuantización física histórica. Salud12 y daño1 no se ajustaron.

## 6. Recorrido continuo final, sin recolocaciones ni cambios de HP

1. Spawn normal(140,600), salud3/3, jefe12, Etapa1 pasiva; activación explícita.
2. Tres arcos seleccionados por F0. Saltos reales de evasión, primer desplazamiento hasta el núcleo y dos saltos/tajos en cada apertura:12→10→8→6.
3. A6HP la ventana sigue abierta hasta su fin; cierre y Retorn completos. Presentación protegida1s; Etapa2 activa una sola vez.
4. El siguiente arco de Etapa2 no concede apertura. Después de fijar su objetivo en F0, el Player camina hacia R2 y salta hasta quedar apoyado, manteniéndose en Presente.
5. Se elige un haz realmente elegible sobre R2. Shift a Pasado conserva apoyo y evita el daño; se espera toda la secuencia y recuperación.
6. La descarga habilita APPROACH4,75s. Movimiento hacia núcleo, regreso a Presente, espera de postura baja y dos tajos:6→4.
7. Se vuelve a R2 con movimiento/salto reales. El selector alterna un arco; se evade, sin apertura. El haz siguiente se provoca y supera en Pasado:4→2 tras su exposición.
8. Se repite la ruta y alternancia, sin manipular el selector ni solicitar haces diagnósticos:2→0 mediante espada. DEFEATED cancela el ciclo.

Todos los cambios dimensionales fueron entradas reales; no se forzó dimensión desde scripts. No se desactivaron colisiones ni la salida. La Lente tiene ventaja defensiva al conservar R2 durante el haz, aunque no se exige usarla: el fixture descrito abajo valida una salida por movimiento en Presente.

### Métricas del ensayo final headless

| Métrica | Resultado |
|---|---:|
| Tiempo hasta DEFEATED |73,833s |
| Rutina completa de prueba |74,083s; incluye0,25s de finalización del último tajo |
| Etapa1 antes de transición |28,633s |
| Presentación de transición |1,000s |
| Etapa2 hasta derrota |44,200s |
| Arcos |6:3 en cada etapa |
| Haces |3, todos en Etapa2 y con elegibilidad registrada |
| Ventanas |6:3 por etapa |
| Impactos / tajos fallidos |12 /0 |
| Cambios confirmados / rechazados |6 /0 |
| Daño recibido / salud final Player |0 /3 de3 |
| Salud final jefe |0, estado DEFEATED |

Eventos completos con tiempos, posición, fase, HP y comprobante de elegibilidad en [continuous.json](../artifacts/room5_stage_i3/continuous.json); resumen en [metrics.json](../artifacts/room5_stage_i3/metrics.json). Las dos reproducciones con render tienen archivos por resolución, sin sustituir el ensayo headless. Las capturas pueden añadir un paso físico de presentación; sus tiempos no se mezclan con la tabla.

### Intentos anteriores conservados

| Intento | Resultado y causa | Evidencia |
|---|---|---|
|01, política inicial |El agente se reposicionó hacia izquierda junto al núcleo y atacó en sentido contrario; no completó el umbral, siguió esperando y murió. El diagnóstico antiguo generó errores al continuar con una escena liberada; se terminó el proceso de prueba. No se declara victoria. |`logs/attempt01_policy_failure.log/.err` |
|02, orientación corregida |Victoria real12→0 a73,667s; rutina73,917s;6 arcos,3 haces, Player1/3. El agente esperó haces ignorando dos arcos alternados y recibió2 daños. Fallaron las aserciones que esperaban3/3; no falló la regla de descarga. |[JSON conservado](../artifacts/room5_stage_i3/attempt02_continuous_with_damage.json) y logs `attempt02_completed_with_damage` |
|03, política consciente de la alternancia |Victoria de la tabla con3/3; evade los arcos reales intermedios. No se cambió el selector, las físicas ni HP para conseguirla. |Ensayo final y reproducciones en regresiones/renders |

Se añadieron salidas finitas y conservación del resultado cuando el diagnóstico no alcanza un estado esperado. Las reproducciones posteriores verifican el mismo procedimiento corregido; no se buscaron semillas ni se reiniciaron intentos perdidos silenciosamente. El rendimiento del agente informado no representa dificultad ni comprensión humanas.

## 7. Softlock, rutas alternativas y cancelación

Fixtures separados, identificados por preparación controlada de salud/posición (no son la prueba continua):

- Etapa2 en F0: dos arcos evadidos sin moverse horizontalmente no abren núcleo, no conceden descarga y conservan6HP del jefe. El Player sigue3/3, con instrucción visible y salida abierta; no hay timeout de muerte.
- R2: el haz elegible se esquiva moviéndose a F0/fuera de banda **sin Shift**, en Presente. Salud conservada y descarga concedida después de recuperación. Esto acredita que no es obligatorio recibir daño ni pulsar Shift.
- Stop invalida permiso/token, oculta el panel y cancela cualquier acción. Detener durante transición impide activación tardía. Reiniciar con salud6 solicita la presentación segura, sin curar ni duplicar etapa.
- Derrota real del Player durante transición cancela el ciclo. Un fixture terminal del jefe a0 confirma prioridad DEFEATED y ausencia de transición posterior. La derrota continua por espada confirma el caso terminal normal.
- Una instancia nueva conserva etapa1,12HP y umbral acotado. Las regresiones existentes mantienen cancelación, liberación de sala y transiciones de Room4/Room5.

La regla no es irresoluble: hay ruta física demostrada y feedback. Pero quien permanezca en F0 indefinidamente no recibe una apertura gratuita: deberá interpretar la instrucción y usar una posición elegible. No se afirma que todas las velocidades/posiciones iniciales o rutas por R1/P1/T1 estén validadas para toda la Etapa2. Antes de activación final hay que observar si personas comprenden esa decisión sin ayuda.

## 8. Pruebas y regresiones finales

`core_guardian_phase_two_test.gd`: **54 controles físicos/lógicos/UI PASS**, más la prueba previa8/8 archivada. Incluye umbral mediante espada real, ventana no interrumpida, transición única/protegida, salud conservada, arcos sin apertura, subida real a R2, selección elegible, defensa dimensional y por movimiento, descarga posterior al peligro, espada, UI visible, Stop y derrotas. Los renders pasan64 controles cada uno, incluidos10 PNG continuos.

| Suite, ejecutada secuencialmente | Resultado |
|---|---|
| core_guardian_base_test |30 PASS |
| core_guardian_beam_test |29 PASS |
| core_guardian_arc_test |57 PASS |
| core_guardian_combat_cycle_test |51 PASS |
| core_guardian_adaptive_approach_test |74 PASS |
| core_guardian_phase_two_test |54 PASS |
| room5_combat_playtest_test |21 controles de infraestructura; comparación solo Etapa1 |
| room5_base_test |71 PASS |
| room5_dimension_test |153 PASS; conteo original de observadores conservado |
| room4_room5_transition_test |Sin fallos |
| attack12_test |Sin fallos |
| temporal_shift_protection_test |Sin fallos |
| validate |Sintaxis exitosa |

El diagnóstico histórico I.1/I.2 usa `--phase-one-only`, que establece `cycle_phase_two_enabled=false` únicamente en su instancia de prueba. No es el valor de producción. No se eliminó ni suavizó ninguna aserción histórica. Las suites nuevas usan dos etapas activadas por defecto. No se modificaron tests G/H.2/H.3/I.2 ni la prueba de observadores.

Todos los perfiles APPDATA son aislados, a60Hz; los guardados reales no son perfiles de ejecución. Las suites históricas escriben en el espejo externo para conservar evidencias previas; los renders usan este proyecto real. Los avisos de ObjectDB/recursos al cerrar algunas suites siguen separados de los resultados y no se declaran solucionados. La regresión inicial de conteo de observadores y la imagen de texto sin actualizar se conservan como diagnósticos de los arreglos locales, no como evidencia final PASS.

## 9. Capturas finales reales de Godot

Veinte PNG directos del viewport, sin montaje. Todos los siguientes pertenecen al recorrido continuo reproducido en su resolución. Los fixtures de seguridad no se presentan como continuidad de esas imágenes.

| Estado |1024×572 |1280×720 |
|---|---|---|
| Reposo Etapa1 |[PNG](../artifacts/room5_stage_i3/01_reposo_etapa1_1024x572.png) |[PNG](../artifacts/room5_stage_i3/01_reposo_etapa1_1280x720.png) |
| Umbral6 pendiente |[PNG](../artifacts/room5_stage_i3/02_umbral6_1024x572.png) |[PNG](../artifacts/room5_stage_i3/02_umbral6_1280x720.png) |
| Transición protegida |[PNG](../artifacts/room5_stage_i3/03_transicion_sobrecarga_1024x572.png) |[PNG](../artifacts/room5_stage_i3/03_transicion_sobrecarga_1280x720.png) |
| Instrucción de escudo reforzado |[PNG](../artifacts/room5_stage_i3/04_escudo_reforzado_1024x572.png) |[PNG](../artifacts/room5_stage_i3/04_escudo_reforzado_1280x720.png) |
| Aproximación a R2 |[PNG](../artifacts/room5_stage_i3/05_aproximacion_R2_1024x572.png) |[PNG](../artifacts/room5_stage_i3/05_aproximacion_R2_1280x720.png) |
| Haz seleccionado desde R2 |[PNG](../artifacts/room5_stage_i3/06_haz_elegible_R2_1024x572.png) |[PNG](../artifacts/room5_stage_i3/06_haz_elegible_R2_1280x720.png) |
| Pasado y apoyo seguro |[PNG](../artifacts/room5_stage_i3/07_pasado_defensa_1024x572.png) |[PNG](../artifacts/room5_stage_i3/07_pasado_defensa_1280x720.png) |
| Núcleo expuesto Etapa2 |[PNG](../artifacts/room5_stage_i3/08_expuesto_etapa2_1024x572.png) |[PNG](../artifacts/room5_stage_i3/08_expuesto_etapa2_1280x720.png) |
| Espada real |[PNG](../artifacts/room5_stage_i3/09_espada_etapa2_1024x572.png) |[PNG](../artifacts/room5_stage_i3/09_espada_etapa2_1280x720.png) |
| Derrota continua |[PNG](../artifacts/room5_stage_i3/10_derrota_continua_1024x572.png) |[PNG](../artifacts/room5_stage_i3/10_derrota_continua_1280x720.png) |

La revisión comprueba legibilidad, salud/Lente libres, Player visible, panel correcto en Pasado y Presente y espada en el núcleo. El contenedor existente puede conservar altura de un mensaje anterior; es presentación provisional, sin ocultar el combate ni información de salud. Las discontinuidades Repose→Attack3 y el paquete rectangular siguen pendientes. No se declara pulido artístico final.

## 10. Archivos, respaldo e integridad

Únicos archivos preexistentes modificados:

- `scripts/bosses/core_guardian.gd`: etapa lógica, transición segura, condición de descarga y consulta de feedback.
- `scripts/rooms/room5.gd`: instancia local del control existente y actualización de presentación; cámara/ajuste original conservados.
- `tests/room5_combat_playtest_test.gd`: dos líneas para el modo diagnóstico explícito de Etapa1.

Nuevos: `tests/core_guardian_phase_two_test.gd`, este informe, JSON/logs/capturas y metadatos nuevos. **Room5.tscn, CoreGuardian.tscn y los componentes ofensivos no se modifican.**

Respaldo previo con SHA-256: `C:/Users/juans/chrono-shift-backups/room5_stage_i3_20261116_181012/`, incluyendo escenas por precaución aunque no se editaron. Línea base, perfiles y helpers: `C:/Users/juans/.codex/visualizations/2026/11/16/01a1e570-850c-7a83-8965-7511f3d3ed84/phase_i3_work/` y directorio padre.

La verificación final en [verification.json](../artifacts/room5_stage_i3/verification.json) coteja archivos anteriores, respaldos, hashes nuevos y los dos guardados reales. Se preservan Player, DimensionManager, HUD, progreso, transiciones, Room4, Enemy1, física, colisiones, geometría, cámara, sprites, atlas y servicios/configuraciones. No se escribieron OpenViking, AgentMemory ni credenciales. El editor se inspeccionó antes de editar y la recarga final usa la escena guardada sin cambios pendientes.

## 11. Balance y próxima fase recomendada

Se mantiene12HP, daño1 y todos los tiempos de ataque. La duración final≈74s incluye oportunidades de seis ventanas,3 arcos en Etapa1 y el aprendizaje/ruta de descarga en Etapa2. No es comparable como optimización de tiempo frente a I.2, pues cambió la regla de apertura y el recorrido. El ensayo con1/3 demuestra que ignorar arcos alternados cuesta salud real; no se aceleraron ataques para forzar plataformas.

Recomiendo playtest de comprensión: observar si se interpreta el aviso, se visita R2 sin guía externa, se distingue descarga/apertura, se atiende el arco intermedio y se regresa a Presente a tiempo. Evaluar R1 y rutas fallidas para no confundir una ruta probada con seguridad universal. Conservar cifras antes de decidir reducir vida o exposición.

BossHUD futuro debe escuchar salud/etapa reales sin duplicarlas, y la activación futura debe llamar la API una sola vez tras una preparación aprobada. Barreras, música, intro definitiva, checkpoints, resolución del reactor, final y persistencia de victoria requieren fases independientes. No se implementaron aquí. El trabajo se detiene en I.3.
