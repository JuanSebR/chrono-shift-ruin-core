# Sala 5 — Fase K.1: activación real del Guardián

16/11/2026 · Godot 4.7.2 · Encuentro local integrado. Victoria persistente y final narrativo pendientes de autorización para K.2/K.3.

## Resultado

Room5 llega pasiva desde Room4. Caminar hacia el centro activa una introducción original de aproximadamente **1 segundo**, seguida por un único ciclo ofensivo. La salida queda bloqueada con aviso contextual; la derrota del Player reutiliza el reinicio automático existente y la derrota del Guardián libera la salida después de sus animaciones. No se modifica la IA, la salud, los ataques ni ningún sistema compartido de producción.

La prueba continua utiliza transición, movimiento, saltos, Shift y espada reales: **Room4 → Room5 → introducción → dos etapas → 12 impactos → derrota del Guardián → destrucción de BossHUD → Room4**. Resultado headless: Player **3/3**, 6 arcos, 3 haces, 6 ventanas, 6 cambios dimensionales y ningún daño recibido.

Se aplicaron godot-gamedev y game-designer. La inspección previa incluyó instrucciones, GDD, estado, plan maestro, E/F/I.3/J, señales, animaciones, transiciones, llegada y derrota heredada. MCP confirmó el proyecto correcto, Room5 guardada y ejecución detenida antes del respaldo. No se repitió una auditoría completa de otras salas.

## Trigger y condiciones

Se añaden únicamente estos nodos a la escena:

```text
Room5
└── EncounterTrigger (Area2D)
    └── Shape (CollisionShape2D, RectangleShape2D)
```

Centro real **(420,360)**, rectángulo **20×520**: x410–430, y100–620. Collision layer0, mask2. Es un área de detección, sin cuerpo sólido. Cubre la ruta de suelo y los saltos/plataformas accesibles. Con la hitbox del Player de24×40, la entrada se produce cerca de x398; la inercia tras soltar movimiento deja al jugador alrededor de x417 durante la intro.

Está después de la llegada desde Room4 en(180,600) y antes del sector del Guardián en(1070,620). El reinicio local usa el spawn normal(140,600), también fuera del trigger. No cambia F0/R1/R2/P1/T1, límites, colisiones existentes ni cámara.

La detección se arma diferida después de `_ready()`. Requiere Player real, ambos actores vivos, sala inicializada y actual, estado INACTIVE, intento todavía no consumido, jefe IDLE sin ciclo, ningún reinicio pendiente y `ToRoom4.transition_pending == false`. Marca el intento antes de iniciar la intro y desactiva el trigger. La Llave, cargar la escena, permanecer inmóvil, cambiar dimensión o volver a cruzar el área no inician otro ciclo.

## Estados y señales locales

| Estado de Room5 | Comportamiento |
|---|---|
|INACTIVE |Jefe pasivo, HUD oculto, salida disponible, Player libre |
|INTRO |Starting, salida bloqueada, sin ofensivas ni exposición |
|ACTIVE |API original del ciclo activa una vez, BossHUD real visible |
|PLAYER_DEFEATED |Sin ofensivas, presentación de derrota heredada y recarga local |
|BOSS_DEFEATED |Derrota terminal en esa instancia; animaciones, desbloqueo y salida libre |

Room5 conecta una vez `EncounterTrigger.body_entered`, `CoreGuardian.state_changed` y `CoreGuardian.defeated`. Emite `encounter_state_changed` para su ciclo de vida y conserva contadores diagnósticos por instancia. No selecciona ataques, no contiene un reloj ofensivo y no duplica HP.

Se reutiliza `play_diagnostic(&"starting")`, interfaz existente que reproduce las ocho poses a8FPS sin bucle. El manejador original de `AnimatedSprite2D.animation_finished` devuelve el Guardián a IDLE/repose y emite `state_changed`. Solo estando Room5 en INTRO se acepta esa finalización y se llama una vez a `start_combat_cycle()`. No se añade un temporizador de introducción ni se modifica CoreGuardian. El estado local cambia antes de llamar la API para evitar reentrada de señales anidadas.

El Player conserva controles libres durante la presentación. No fue necesario intervenir Player.gd ni añadir un bloqueo global. GuardianHint reutiliza TutorialHints con «GUARDIÁN INICIALIZÁNDOSE / ACCESO BLOQUEADO — qué hospitalidad.». El BossHUD sigue oculto hasta que el ciclo real comienza; no aparece por tener la Llave ni por entrar.

## Acceso a Room4 y cancelación

`RoomTransitions/ToRoom4` conserva posición(100,600), forma, destino y marcador de Room4. Durante INTRO/ACTIVE se desconecta **localmente** su callback `body_entered → _on_body_entered` y se deshabilita `monitoring` de manera diferida. La desconexión inmediata impide despachar eventos residuales mientras termina la actualización física. No se edita LevelTransition.gd ni se añade una pared invisible.

Cerca del acceso, con Player vivo y x<280, una instancia local de TutorialHints muestra **«ACCESO BLOQUEADO — GUARDIÁN ACTIVO»**. Mientras finaliza la derrota se usa «SISTEMA REINICIANDO». Se reutiliza la arquitectura gráfica; no se crea puerta, sprite ni recurso artístico. Al liberar el acceso se reconecta el callback una sola vez y se restaura monitoring.

`cancel_encounter()` detiene la API original, cierra la exposición, devuelve el estado local a INACTIVE y libera la salida. Ese intento no vuelve a presentar al jefe: salir y cargar una instancia nueva rearma el trigger. Una detención externa durante ACTIVE también cancela el encuentro local. Los controles no necesitan restauración porque no se bloquearon.

## Derrota del Player y reintento

Se conserva el flujo de `room2.gd`: señal de derrota → log de CombatHUD → animación normal de muerte → espera heredada0,25s → `reload_current_scene`. No se implementa otra interfaz de resurrección ni una pantalla nueva.

Room5 marca PLAYER_DEFEATED, desarma el trigger, libera el acceso lógico y solicita limpieza del Guardián. La API de limpieza adicional se difiere para no liberar el paquete de arco dentro de su propia llamada de colisión letal; el controlador existente cancela la ofensiva en ese mismo flujo. No se cambian CoreGuardian ni GuardianArc.

La prueba recibe **tres impactos reales** (salud2→1→0), confirma ciclo/peligros desactivados y núcleo cerrado, observa la presentación de derrota y comprueba que no se reproduce la destrucción del HUD del jefe. La recarga elimina Room5, Player, jefe y BossHUD anteriores, verificado mediante WeakRef; sus señales no sobreviven como instancias retenidas.

El nuevo intento contiene un único Player3, un único jefe12, Etapa1, núcleo protegido, Presente, cooldown0, ninguna solicitud de Shift ni protección temporal heredada, ningún proyectil y BossHUD oculto. Se rearma el trigger y la salida queda disponible. Espada, Lente y Llave sobreviven en el GameProgress ya existente en memoria. No se escribe un guardado permanente. El segundo intento camina de nuevo por el trigger y ejecuta su primer ataque con un único ciclo.

## Derrota del Guardián y dimensiones

La derrota real por espada establece BOSS_DEFEATED; no se inicia otro combate. Se conserva el cuerpo derrotado y la destrucción original de BossHUD. La salida se habilita cuando termina la animación corporal y `destruction_completed` está confirmado. El jugador puede caminar normalmente y regresar a Room4 sin bucles.

**La victoria todavía no persiste.** Abandonar Room5 y entrar otra vez crea una instancia pasiva con jefe12; esta conducta provisional se prueba expresamente. No se modifica GameProgress, no se añade estado de victoria, reactor, créditos ni final narrativo.

DimensionManager, Player y los dos ataques conservan sus hashes previos. Haz peligroso solo en Presente; arco en ambas dimensiones; núcleo dañable únicamente en Presente; protección0,16s y cooldown0,20s. P1/T1 alternan y F0/R1/R2 siguen compartidas. Salud12, umbral6, ventana2s, pausa adaptativa y selector permanecen íntegros.

## Partida continua y métricas

Se prepara solamente un perfil aislado con espada/Lente/Llave y Player en la repisa legítima de salida de Room4(1160,264). Esa posición inicial es un fixture de progresión, no una afirmación de haber recorrido las salas anteriores. Desde el primer desplazamiento hacia ToRoom5 no se asignan posiciones ni HP, no se fuerza el selector y no se llama manualmente a `start_combat_cycle()`.

| Medición headless60Hz | K.1 | Referencia J/I.3 |
|---|---:|---:|
|Introducción |1,000s |No había activación natural |
|Inicio del ciclo → DEFEATED real |73,433s |73,833s |
|Inicio del ciclo → fin de rutina de entradas |73,683s |74,083s |
|Activación del trigger → DEFEATED real |74,433s |No aplicaba |
|Salida de Room4 → fin de rutina de combate |76,817s |No aplicaba |
|Llegada a Room5 → fin de rutina de combate |76,250s |No aplicaba |
|DEFEATED → salida liberada |≈0,883s |No se bloqueaba salida |
|Arcos / haces / ventanas |6 /3 /6 |6 /3 /6 |
|Impactos / Shift / daño recibido |12 /6 /0 |12 /6 /0 |
|Player final |3/3 |3/3 |

La diferencia de0,400s no es una aceleración de la IA. J comenzaba manualmente con Player en x140; K.1 comienza naturalmente alrededor de x417. Las trazas mantienen WAIT1s, AIM1s y RELEASE0,25s; el primer arco, cuyo recorrido depende del objetivo real, llega a RECOVER en3,100s frente a3,500s en J. Después conserva la diferencia acumulada. El controlador, sus parámetros y los ataques son byte a byte iguales.

[activation.json](../artifacts/room5_stage_k1/activation.json) contiene la traza completa. `combat_trial_seconds` incluye los últimos0,25s de la rutina de espada después de DEFEATED. El campo `activation_to_defeat_seconds` de este diagnóstico también incluye esa cola: para el instante terminal preciso se utiliza el evento DEFEATED de `combat.events`, como hace [verification.json](../artifacts/room5_stage_k1/verification.json). Los renders tienen esperas de captura y no se mezclan con los tiempos headless.

Los fixtures de bloqueo se ejecutan **después** del recorrido continuo, en otra instancia: salida pasiva real, nueva entrada, intro por movimiento, emisión explícita de un evento residual, aproximación física al acceso bloqueado, aviso visible, Shift y cancelación con regreso. La emisión sintética del evento residual no se presenta como un cruce físico. El test de reintento es otra partida independiente, con derrota real por ataques.

## Regresiones y diagnósticos

Las siguientes suites se ejecutan secuencialmente con Godot4.7.2, reloj fijo60Hz y APPDATA externo aislado:

| Suite | Resultado final |
|---|---|
|core_guardian_base_test |30 PASS |
|core_guardian_beam_test |29 PASS |
|core_guardian_arc_test |57 PASS |
|core_guardian_combat_cycle_test |51 PASS |
|core_guardian_adaptive_approach_test |74 PASS |
|core_guardian_phase_two_test |54 PASS |
|core_guardian_hud_test |75 PASS |
|room5_encounter_activation_test |36 PASS |
|room5_encounter_retry_test |38 PASS |
|room5_base_test |71 PASS |
|room5_dimension_test |153 PASS |
|room4_room5_transition_test |Sin fallos |
|attack12_test |Sin fallos |
|temporal_shift_protection_test |Sin fallos |
|validate |Sintaxis exitosa |

Las pruebas históricas usan `--room5-manual-diagnostic`, modalidad explícita que desarma solo la activación natural; no elimina nodos ni modifica el combate. Los dos tests nuevos usan el comportamiento de producción. Los tests base/dimensional conservan todas sus condiciones y cambian únicamente el conteo de Area2D de3 a4 por EncounterTrigger; se respaldaron antes de editarlos. El conteo de siete cuerpos sólidos sigue intacto.

Los renders finales pasan **48 controles de activación y40 de reintento en cada resolución**. Las cuatro ejecuciones terminan con exit0, sin diagnósticos de script; las15 suites headless también terminan con exit0. Las capturas principales conservan los mismos conteos ofensivos y salud final de la partida headless.

Se conservan los fallos iniciales en `artifacts/room5_stage_k1/logs/`: una aserción consultaba monitoring antes de completarse el cambio diferido; otra detenía el Player fuera del área al comprobar cancelación; dos expectativas antiguas contaban tres áreas. Se corrigieron las comprobaciones, sin alterar salud, geometría ni IA para obtener PASS. Los avisos históricos de ObjectDB/recursos de ciertas suites se conservan en sus `.err` y no se declaran resueltos. Las pruebas nuevas deben terminar sin errores de script.

## Capturas reales

PNG directos del viewport, sin composición ni generación de arte. Las once vistas principales de cada resolución corresponden a su recorrido continuo. El bloqueo usa el fixture separado identificado en el nombre; derrota y reintento pertenecen a la partida independiente de reintento. BossHUD visible y combate activo comparten una captura para evitar duplicados.

| Estado / procedencia | 1024×572 | 1280×720 |
|---|---|---|
|Llegada pasiva / continuo |[PNG](../artifacts/room5_stage_k1/01_llegada_pasiva_1024x572.png) |[PNG](../artifacts/room5_stage_k1/01_llegada_pasiva_1280x720.png) |
|Aproximación / continuo |[PNG](../artifacts/room5_stage_k1/02_aproximacion_trigger_1024x572.png) |[PNG](../artifacts/room5_stage_k1/02_aproximacion_trigger_1280x720.png) |
|Inicio intro / continuo |[PNG](../artifacts/room5_stage_k1/03_inicio_intro_1024x572.png) |[PNG](../artifacts/room5_stage_k1/03_inicio_intro_1280x720.png) |
|Incorporación / continuo |[PNG](../artifacts/room5_stage_k1/04_guardian_incorporandose_1024x572.png) |[PNG](../artifacts/room5_stage_k1/04_guardian_incorporandose_1280x720.png) |
|Combate y BossHUD / continuo |[PNG](../artifacts/room5_stage_k1/05_combate_activo_HUD_1024x572.png) |[PNG](../artifacts/room5_stage_k1/05_combate_activo_HUD_1280x720.png) |
|Acceso bloqueado / fixture |[PNG](../artifacts/room5_stage_k1/fixture_06_salida_bloqueada_1024x572.png) |[PNG](../artifacts/room5_stage_k1/fixture_06_salida_bloqueada_1280x720.png) |
|Ataque, aviso de arco / continuo |[PNG](../artifacts/room5_stage_k1/08_ataque_del_guardian_1024x572.png) |[PNG](../artifacts/room5_stage_k1/08_ataque_del_guardian_1280x720.png) |
|Etapa2 / continuo |[PNG](../artifacts/room5_stage_k1/09_etapa2_1024x572.png) |[PNG](../artifacts/room5_stage_k1/09_etapa2_1280x720.png) |
|Núcleo expuesto / continuo |[PNG](../artifacts/room5_stage_k1/10_nucleo_expuesto_1024x572.png) |[PNG](../artifacts/room5_stage_k1/10_nucleo_expuesto_1280x720.png) |
|Player derrotado / reintento |[PNG](../artifacts/room5_stage_k1/retry_11_player_derrotado_1024x572.png) |[PNG](../artifacts/room5_stage_k1/retry_11_player_derrotado_1280x720.png) |
|Sala limpia / reintento |[PNG](../artifacts/room5_stage_k1/retry_12_reintento_limpio_1024x572.png) |[PNG](../artifacts/room5_stage_k1/retry_12_reintento_limpio_1280x720.png) |
|Jefe derrotado / continuo |[PNG](../artifacts/room5_stage_k1/13_jefe_derrotado_1024x572.png) |[PNG](../artifacts/room5_stage_k1/13_jefe_derrotado_1280x720.png) |
|Destrucción HUD / continuo |[PNG](../artifacts/room5_stage_k1/14_destruccion_BossHUD_1024x572.png) |[PNG](../artifacts/room5_stage_k1/14_destruccion_BossHUD_1280x720.png) |
|Salida liberada / continuo |[PNG](../artifacts/room5_stage_k1/15_salida_desbloqueada_1024x572.png) |[PNG](../artifacts/room5_stage_k1/15_salida_desbloqueada_1280x720.png) |

Revisión visual de vistas clave en ambos tamaños: introducción legible sin BossHUD prematuro, feedback del acceso dentro de pantalla, HUD de combate separado de salud/Lente y GuardianHint, núcleo visible, destrucción con salud0 y sala limpia al reintentar. Los28 PNG tienen las dimensiones físicas indicadas y su hash consta en verification.json.

## Archivos, respaldo e integridad

Modificados: `scenes/Room5.tscn`, `scripts/rooms/room5.gd` y las dos expectativas numéricas de `tests/room5_base_test.gd` / `tests/room5_dimension_test.gd`. Nuevos: las dos pruebas de encuentro, este informe y diagnósticos/capturas/metadatos generados.

Respaldo previo: **`C:/Users/juans/chrono-shift-backups/room5_stage_k1_20261116_191047/`**, con hashes verificados. Room5 escena/controlador se copiaron antes de editar; los dos tests históricos se añadieron al respaldo antes de adaptar sus expectativas. Los respaldos anteriores se conservan.

La comparación de **2283 archivos preexistentes** elimina únicamente las secciones nuevas de EncounterTrigger y exige igualdad exacta de todo el resto de Room5.tscn. `_fit_camera()` conserva su contenido; CoreGuardian, Player, DimensionManager, LevelTransition, GameProgress, HUDs y ambos ataques conservan hashes. Los dos guardados reales conservan SHA-256. El inventario completo, logs y comprobaciones están en [verification.json](../artifacts/room5_stage_k1/verification.json).

Helpers/perfiles externos: `C:/Users/juans/.codex/visualizations/2026/11/16/01a1e570-850c-7a83-8965-7511f3d3ed84/phase_k1_work/` y su directorio padre. Las suites headless escriben en el espejo externo; los renders generan evidencias K.1 en el proyecto. No se cambian servicios, configuraciones, memorias, credenciales ni recursos originales.

## Límites y siguiente fase

Persisten las discontinuidades anatómicas de Starting/Attack3, el fragmento truncado de cañón ya documentado y el paquete provisional del arco. No se redibuja, deforma ni extrae nuevamente ese arte. La salida se representa con bloqueo lógico y aviso, sin nueva puerta artística. La evidencia automatizada y visual no sustituye una evaluación humana del ritmo y la sensación del combate.

Para K.2: autorizar y definir una victoria persistente compatible con los guardados existentes, comportamiento de Continuar y reentrada tras vencer; probar migración y ausencia de reaparición no deseada. Mantener separado el final narrativo de K.3. **K.1 termina aquí; no se implementa K.2.**
