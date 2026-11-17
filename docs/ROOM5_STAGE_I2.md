# Sala 5 — I.2: aproximación adaptativa

16/11/2026 · Godot4.7.2 · Implementación limitada al ritmo de APPROACH. Room5 sigue pasiva; no hay Etapa2, ataques nuevos ni cambios de selección, salud, daño, exposición, física o dimensiones.

## Resultado

La pausa ahora se calcula una sola vez al entrar en APPROACH. Las rutas directas verificables sobre F0 pueden usar menos tiempo; las lejanas, elevadas, aéreas, posteriores o inciertas conservan el presupuesto anterior de4,75 s. El modo fijo sigue disponible mediante configuración, sin restaurar archivos.

Las cinco políticas originales de I.1 se ejecutaron en ambos modos. El modo fijo reprodujo exactamente las métricas principales de I.1. En modo adaptativo, la victoria de dos golpes por apertura pasó de **69,117 a51,533 s hasta DEFEATED**, reducción17,583 s (25,44%). Conservó6 arcos,6 ventanas,12 impactos y Player3/3. El ensayo sin entradas sigue muriendo al tercer arco. No se optimizaron entradas ni se reintentaron derrotas silenciosamente.

## Inspección, respaldo y alcance

Se consultaron AGENTS, I.1 completo, H.3 y el controlador actual. MCP confirmó el proyecto correcto, Room5 guardada y detenida. APPROACH empezaba en `_tick_cycle`, después de IDLE seguro y de `_no_offensive_hazard()`. El mismo reloj físico `beam_elapsed/beam_duration` sigue gobernando todo. Se conservaron APIs de inicio/detención y matriz de daño del núcleo.

Respaldo previo con SHA-256: `C:/Users/juans/chrono-shift-backups/room5_stage_i2_20261116_174835/`, con controlador, diagnóstico I.1 y prueba H.3. Esta última finalmente no necesitó cambios. No se sobrescribieron respaldos anteriores. Se aplicaron game-designer y godot-gamedev para contrastar comportamiento y evidencia física, sin ampliar el diseño.

## Implementación real y configuración

| Propiedad | Valor inicial / función |
|---|---|
| cycle_adaptive_approach_enabled |true; false recupera el comportamiento fijo |
| cycle_approach_time |4,75 s; propiedad existente, máximo y respaldo conservador |
| cycle_approach_min_time |1,25 s |
| cycle_approach_extra_margin |0,85 s |
| cycle_approach_reference_speed |240 unidades/s; referencia para calcular espera, no modifica Player |

No se añadió otra propiedad de máximo que pudiera discrepar de la anterior. No fue necesario serializar parámetros en CoreGuardian.tscn.

El punto de ataque se deriva del landmark de núcleo Vulnerable final, transformado a mundo, menos32 unidades en X: aproximadamente1049,093. Es la separación utilizada por las pruebas físicas anteriores; no se mueve el núcleo ni se amplía espada/hurtbox.

Para una ruta admitida:

`duración = clamp(abs(player_collider_x - attack_x)/reference_speed + extra_margin, minimum, cycle_approach_time)`

El cálculo usa el centro físico real del Player. `_begin_approach()` registra posición, razón y duración elegida, incrementa `approach_samples` y pasa esa duración a `_enter_cycle`. El tramo APPROACH solo avanza el reloj hasta CORE_OPENING: no consulta otra vez distancia, dimensión ni velocidad para modificar el presupuesto. No hay Timer ni segundo controlador.

### Reglas conservadoras

Solo se acorta si el Player está apoyado sobre una superficie horizontal, a la altura esperada de F0 (centro≈600, tolerancia2u), dentro del sector delantero y a menos de600u horizontales del punto de ataque. Ese límite explícito acota la optimización a trayectos cercanos/intermedios; no pretende ser un algoritmo de navegación general.

| Condición muestreada | Decisión |
|---|---|
| Modo fijo |4,75 s por defecto, sin fórmula |
| Distancia≥600u |Presupuesto máximo, razón `far` |
| Elevado, en vuelo, apoyo inclinado o ruta no reconocida |Máximo, `route_unverified` |
| Detrás del jefe o fuera del límite izquierdo admitido |Máximo, `rear_or_boundary` |
| Velocidad horizontal contraria a la aproximación |Máximo, `moving_away` |
| F0 directo restante |Fórmula limitada, `direct_f0` |

El máximo es una protección contra subestimar rutas, no una promesa de alcanzabilidad universal. Los valores inválidos de referencia o un presupuesto fijo inferior al mínimo admitido no usan la fórmula. Los parámetros exportados conservan sus rangos; la configuración evaluada es la de la tabla.

### Spawn y margen

La candidata sin protección daría desde X140:

`abs(140 - 1049.092875)/240 + .85 = 4.637887 s`.

Frente a4,567 s del recorrido original con dos Shift/freno, dejaría solo≈0,071 s. Por estar a909u del punto de ataque, se descarta esa reducción y se mantienen4,75 s. El recorrido continuo nuevo conserva las mismas entradas y el mismo primer trayecto. El fixture adicional, que incluye una entrada final para orientar la espada, llegó en4,583 s dentro de esa pausa.

## Rutas físicas y acceso al núcleo

Nueva prueba: `tests/core_guardian_adaptive_approach_test.gd`, **74 controles PASS**. Los siguientes son fixtures independientes: se fija el objetivo de un arco a la derecha, se coloca el inicio de ruta después del bloqueo del objetivo y se deja completar la ofensiva. Desde APPROACH no se recoloca al Player: movimiento, caídas, Shift, salto y espada son reales. El combate continuo A–E se evalúa aparte desde el spawn original, sin esa preparación artificial.

| Inicio muestreado | Duración elegida | Llegada física* | Razón | Golpes de espada en ventana |
|---|---:|---:|---|---:|
| Spawn/F0 (140,600) |4,750 s |4,583 s |Lejano |2 |
| Centro/F0 (600,600) |2,721 s |2,667 s |Directo |2 |
| Cerca (1049,600) |1,250 s |0,750 s |Directo |2 |
| R1 (380,540) |4,750 s |2,983 s |Elevado |2 |
| R2 (860,540) |4,750 s |0,983 s |Elevado |2 |
| P1 en Presente (580,480) |4,750 s |2,150 s |Elevado |2 |
| T1 en Pasado (780,480) |4,750 s |1,617 s |Elevado |2 |
| Detrás (1150,600) |4,750 s |0,583 s |Posterior |2 |

*Incluye frenado/orientación y cambios dimensionales de la política de ese fixture. Spawn, centro y cercanía realizan ida/vuelta con Shift; T1 inicia en Pasado y regresa a Presente después del descenso a una zona libre. R1/R2/P1 se recorren en Presente. No son ocho mediciones de una política idéntica ni partidas continuas completas.

Todos llegaron durante APPROACH, esperaron el descenso y acertaron dos tajos independientes en Presente. El fixture posterior conserva2/3 de salud por el arco previo apuntado a su posición; no es daño causado por la pausa. Los demás conservan3/3. No hubo ruta insuficiente entre las ocho ensayadas; posiciones, velocidades iniciales y trayectorias no incluidas quedan **no ensayadas**.

El margen intermedio de X600 con dos Shift es pequeño:≈0,054 s antes del descenso. El descenso posterior sigue protegido, pero estos resultados de Input informado no certifican margen humano. No se declara alcanzabilidad universal ni se usa ese resultado para reducir más los tiempos. Las plataformas mantienen4,75 s aunque algunas rutas medidas sean cortas; no se aplica una fórmula horizontal que ignore su descenso.

Datos íntegros en [routes.json](../artifacts/room5_stage_i2/routes.json). La prueba comprueba además muestra única, presupuesto inmutable durante movimiento/Shift, núcleo cerrado, descenso≈45 pasos, exposición≈120/121 pasos, Retorn+descanso≈54 pasos, siguiente ciclo, Stop idempotente, desconexión de señal y cancelación por derrotas. La derrota de jefe en esta prueba usa un fixture terminal de salud; la prueba continua demuestra12→0 exclusivamente con espada.

## Comparación de las cinco políticas I.1

El diagnóstico existente se amplió solo para elegir modo, separar las evidencias I.2 y registrar presupuesto/capturas. `--i2 --fixed-approach` ejecuta el control fijo; `--i2` usa el adaptativo. El bloque de entradas continuas, helpers de Shift y espada permanecen iguales al respaldo. No se cambió el momento de salto, número de tajos, omisiones3/6 ni condición de victoria.

El modo fijo reprodujo exactamente las métricas de I.1: duración terminal y total, estados acumulados, ataques, ventanas, golpes, salud y Shift. Los datos comparativos incluyen esa reproducción nueva, además del histórico. La política E no gana: su derrota se conserva como resultado, aunque la infraestructura diagnóstica pase.

### Duración hasta estado terminal

| Política | I.1 y fijo reproducido | Adaptativo medido | Reducción | Reducción % | Resultado adaptativo |
|---|---:|---:|---:|---:|---|
| A:2 golpes, Shift ida/vuelta |69,117 s |51,533 s |17,583 s |25,44% |Guardián DEFEATED |
| B:2 golpes, Presente |69,117 s |51,533 s |17,583 s |25,44% |Guardián DEFEATED |
| C:1 golpe por ventana |138,183 s |99,500 s |38,683 s |27,99% |Guardián DEFEATED |
| D:2 golpes, omite3 y6 |92,417 s |67,800 s |24,617 s |26,64% |Guardián DEFEATED |
| E:inmóvil |27,867 s |27,867 s |0 |0% |Player derrotado |

Los ensayos de espada terminan0,250 s después del evento terminal para completar la rutina de entrada. Tiempos totales de ensayo adaptativo: A/B51,783;C99,750;D68,050;E27,867 s. No se comparan terminales de un modo con totales del otro. Los renderizados pueden incluir un paso inicial de captura; sus eventos y logs se conservan separados de la tabla headless.

### Contadores, iguales en ambos modos

| Política | Arcos /haces | Ventanas | Impactos | Tajos fallidos | Golpes por apertura | Player final | Shift confirmados |
|---|---:|---:|---:|---:|---|---:|---:|
| A |6 /0 |6 |12 |0 |2 en cada una |3/3 |12 |
| B |6 /0 |6 |12 |0 |2 en cada una |3/3 |0 |
| C |12 /0 |12 |12 |0 |1 en cada una |3/3 |0 |
| D |8 /0 |8 |12 |0 |2,2,0,2,2,0,2,2 |3/3 |0 |
| E |3 /0 |2 completas |0 |0 |0,0 |0/3 |0 |

D omite dos oportunidades deliberadamente; no son tajos emitidos que fallan por precisión. A–D reciben0 daños; E recibe3. No se crea invulnerabilidad adicional. No se manipula la salud del jefe, no se teletransporta al Player ni se cambia la geometría durante estos combates continuos.

### Distribución del tiempo (anterior → nuevo)

| Política | APPROACH total | Secuencia ofensiva del jefe | Exposición acumulada |
|---|---:|---:|---:|
| A/B |28,600 →11,017 s |11,417 →11,417 s |11,500 →11,500 s |
| C |57,200 →18,517 s |22,117 →22,117 s |22,767 →22,767 s |
| D |38,133 →13,517 s |14,983 →14,983 s |15,533 →15,533 s |
| E |9,533 →9,533 s |7,133 →7,133 s |4,033 →4,033 s |

«Secuencia ofensiva» conserva la definición I.1: estados CANNON_* y BEAM_*, incluidos preparación/disipación, no segundos exactos de collider activo. La última exposición acaba antes por derrota. El ahorro medido coincide con el ahorro en APPROACH; las demás fases y las oportunidades de daño no se aceleran.

Datos: [comparison.json](../artifacts/room5_stage_i2/comparison.json), [adaptativo](../artifacts/room5_stage_i2/attempts.json), [fijo reproducido](../artifacts/room5_stage_i2/attempts_fixed.json). Se conservaron todos los resultados. No se ajustaron parámetros para alcanzar el objetivo orientativo45–90 s: A/B y D quedan dentro; C necesita≈99,5 s a1 golpe, resultado válido que no se oculta.

## Sistemas que permanecen intactos

Descenso0,75 s, exposición2,00 s configurados (≈121 pasos por cuantización), cierre Retorn0,50 s y descanso0,40 s permanecen iguales. La apertura empieza en la pose baja, sigue cerrada durante APPROACH y solo permite daño válido en Presente. No cambia CoreWeakpoint ni se facilita un golpe desde el suelo.

Shift no recalcula ni reinicia la espera; conserva cooldown0,20 s/protección0,16 s. Pasado no abre el núcleo ni elimina el arco. Un cambio bloqueado conserva las reglas originales. La prueba comprueba cambio confirmado/protección reales sin añadir otra invulnerabilidad. El Player derrotado y el jefe derrotado cancelan el ciclo como antes.

Haz, arco, selector, salud12 y daño1 permanecen sin cambios. La verificación compara byte a byte los componentes y los cuerpos de los métodos existentes del controlador: solo cambia la entrada a APPROACH y el registro de sus muestras. El enum no se amplía. No se añaden señales, Timer, estados o autoloads.

## Regresiones secuenciales

| Prueba | Resultado |
|---|---|
| core_guardian_base_test |30 PASS |
| core_guardian_beam_test |29 PASS |
| core_guardian_arc_test |57 PASS |
| core_guardian_combat_cycle_test |51 PASS, sin editar expectativas |
| core_guardian_adaptive_approach_test |74 PASS |
| room5_combat_playtest_test |21 controles de infraestructura, A–E conservados |
| room5_base_test |71 PASS |
| room5_dimension_test |153 PASS |
| room4_room5_transition_test |Sin fallos |
| attack12_test |Sin fallos |
| temporal_shift_protection_test |Sin fallos |
| validate |Sintaxis exitosa |

Todos con APPDATA aislado, Godot4.7.2 y reloj fijo60fps. No se cambiaron pruebas H.3/G/H.2 para ocultar regresiones. Se conservan separados los avisos ObjectDB/recursos al cerrar algunas suites históricas; no se investigaron ni se declaran solucionados. Los renders A en ambas resoluciones pasan15 controles incluidas10 capturas; no equivalen a15 comprobaciones nuevas de balance. Logs/códigos de salida: `artifacts/room5_stage_i2/logs/`.

## Capturas reales del viewport

Veinte PNG, sin retoques ni UI de temporizador. Las imágenes01–09 pertenecen a la reproducción continua A en su resolución;10 es un fixture independiente de Stop después de ese combate, identificado en el nombre. El inicio lejano y el posterior estado cercano se distinguen por posición/estado, no por una cuenta atrás agregada a la UI.

| Estado |1024×572 |1280×720 |
|---|---|---|
| Inicio12HP |[PNG](../artifacts/room5_stage_i2/01_inicio_12HP_1024x572.png) |[PNG](../artifacts/room5_stage_i2/01_inicio_12HP_1280x720.png) |
| Ataque |[PNG](../artifacts/room5_stage_i2/04_ataque_1024x572.png) |[PNG](../artifacts/room5_stage_i2/04_ataque_1280x720.png) |
| APPROACH lejos |[PNG](../artifacts/room5_stage_i2/05_approach_lejos_1024x572.png) |[PNG](../artifacts/room5_stage_i2/05_approach_lejos_1280x720.png) |
| APPROACH cerca |[PNG](../artifacts/room5_stage_i2/06_approach_cerca_1024x572.png) |[PNG](../artifacts/room5_stage_i2/06_approach_cerca_1280x720.png) |
| Descenso |[PNG](../artifacts/room5_stage_i2/07_descenso_1024x572.png) |[PNG](../artifacts/room5_stage_i2/07_descenso_1280x720.png) |
| Expuesto |[PNG](../artifacts/room5_stage_i2/08_nucleo_expuesto_1024x572.png) |[PNG](../artifacts/room5_stage_i2/08_nucleo_expuesto_1280x720.png) |
| Espada real |[PNG](../artifacts/room5_stage_i2/02_impacto_continuo_1024x572.png) |[PNG](../artifacts/room5_stage_i2/02_impacto_continuo_1280x720.png) |
| Siguiente ciclo |[PNG](../artifacts/room5_stage_i2/09_siguiente_ciclo_1024x572.png) |[PNG](../artifacts/room5_stage_i2/09_siguiente_ciclo_1280x720.png) |
| Derrota12→0 |[PNG](../artifacts/room5_stage_i2/03_resultado_boss_defeated_1024x572.png) |[PNG](../artifacts/room5_stage_i2/03_resultado_boss_defeated_1280x720.png) |
| Stop, fixture separado |[PNG](../artifacts/room5_stage_i2/10_stop_fixture_separado_1024x572.png) |[PNG](../artifacts/room5_stage_i2/10_stop_fixture_separado_1280x720.png) |

La revisión confirma cámara/HUD originales y ausencia de peligros en aproximación/exposición/Stop. Las capturas no contienen BossHUD nuevo; la derrota y salud se acreditan mediante estado/eventos reales. Persisten silueta discontinua Repose→Attack3 y paquete rectangular provisional.

## Archivos e integridad

Modificados únicamente `scripts/bosses/core_guardian.gd` y `tests/room5_combat_playtest_test.gd`. El primero añade selección de presupuesto/muestreo; el segundo permite comparar modos, separar evidencias y capturar estados sin alterar entradas. Nuevos: `tests/core_guardian_adaptive_approach_test.gd`, este informe y evidencias/métricas/metadatos nuevos. `CoreGuardian.tscn` y la prueba H.3 no cambian.

La línea base SHA-256 coteja todos los archivos previos salvo caché .godot/.git, el respaldo y los dos guardados reales. Resultado en [verification.json](../artifacts/room5_stage_i2/verification.json). Se preservan escenas, componentes de ataques, Player, DimensionManager, HUD, progreso, transiciones, plataformas, geometría, cámara, atlas, sprites y configuraciones. No se escribieron memorias, servicios ni credenciales.

Helpers/perfiles externos: `C:/Users/juans/.codex/visualizations/2026/11/16/01a1e570-850c-7a83-8965-7511f3d3ed84/phase_i2_work/` y directorio padre. Las pruebas históricas usan el espejo externo existente para no sobrescribir evidencias anteriores; los renders usan el proyecto real. Tras los cambios se recargó Room5 guardada en el editor, sin activación ni cambios pendientes.

## Limitaciones y recomendación para I.3

La mejora reduce espera, no variedad: siguen0 haces en los combates F0, Shift opcional, plataformas superiores no necesarias y misma rutina de salto eficaz. No se corrigió evasión lateral del arco, salto tardío derecho, telegráfico ni arte. Tampoco se implementó Etapa2, activación, barreras, BossHUD, victoria persistente o final.

La política automática conoce los estados y tiempos; el margen intermedio estrecho y las rutas desde alturas necesitan playtest humano. El respaldo4,75 s sigue siendo una decisión conservadora, no navegación universal. No se optimiza detrás ni en plataformas aunque algunos fixtures lleguen rápido.

Para I.3 recomiendo evaluar primero lectura de apertura y retorno dimensional con personas, incluidas rutas intermedias y velocidades iniciales. Si se aprueba variedad, contrastar las alternativas I.1 en una fase independiente; no cambiar selección ni salud para «aprovechar» el nuevo ritmo sin medirlo. Mantener por ahora12HP y exposición2s para aislar variables. El trabajo se detiene al terminar I.2.
