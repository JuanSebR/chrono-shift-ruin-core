# Sala 5 — Fase K.2: victoria persistente

16/11/2026 · Godot4.7.2 · Persistencia integrada en progreso v1. K.3 y el final narrativo quedan fuera de esta entrega.

## Resultado

Una victoria real guarda `core_guardian_defeated=true` al confirmarse DEFEATED. La siguiente instancia de Room5 conserva la arena explorable, oculta/desactiva al jefe y no arma EncounterTrigger, BossHUD ni instrucciones de combate. La salida queda disponible desde la llegada. Continuar restaura la victoria desde disco conservando su destino histórico Room1.5. Nueva Partida restablece el campo y revierte el cambio si su guardado falla.

La integración continua **Room4 → Room5 → trigger → intro → dos etapas → derrota real → guardado → destrucción de HUD → Room4 → Room5 superada** termina con Player3/3. Se conservan **73,433s hasta DEFEATED**, intro1s,6 arcos,3 haces,6 ventanas,12 impactos y6 Shift, iguales a K.1. No se cambian controlador del jefe, ataques, salud12, umbral6, selector, pausas, vulnerabilidad2s, física, cámara ni plataformas.

Se aplicaron godot-gamedev y game-designer. Antes de editar se revisaron instrucciones, GDD, estado, K.1 y antecedentes E/I.3/J, GameProgress, formato v1, Llave, menú, llegada, señales y presentación de derrota. MCP confirmó el proyecto correcto y Room5 guardada/detenida. No se auditó extensamente el resto de salas, ni se modificaron servicios o memorias.

## Progreso v1 y compatibilidad

Único dato persistente nuevo:

```json
"core_guardian_defeated": false
```

El guardado continúa en `user://progress_v1.json`, `version:1`, utilizando los mismos `.tmp` y `.bak` de su escritura existente. No hay otro archivo de progreso, autoload ni migración destructiva. Se serializa el booleano junto a espada, Lente, Llave, tutoriales y diálogos. No se guardan HP, etapa, animación, ataque ni posición del Player.

`load_progress()` interpreta ausencia del campo como false y conserva las reglas de carga anteriores, incluido el respaldo. El test carga un v1 sin el campo nuevo después de haber puesto true en memoria: confirma false y conserva las tres posesiones, tutoriales y diálogos. Los guardados reales no se usaron como perfiles de prueba ni se reescribieron.

`record_core_guardian_victory()` aplica el patrón de la Llave: establece provisionalmente true, llama `save_progress()` y revierte a false si falla. Solo tras éxito emite `core_guardian_victory_recorded`. Si ya era true devuelve éxito sin otra escritura ni señal. La implementación de escritura temporal, flush, respaldo y renombrado no se reestructura.

## Confirmación terminal y momento del guardado

La señal está conectada exclusivamente al CoreGuardian real de la sala. Antes de reconocer derrota se exige salud0 y estado real DEFEATED. Para persistir se exige además:

- Encuentro local ACTIVE, iniciado por el trigger físico.
- Trigger consumido, una activación y un inicio aceptado del ciclo original.
- Player vivo, ningún reinicio pendiente.
- Room5 como escena actual y ninguna transición ToRoom4 pendiente.
- Activación de producción habilitada, sin modalidad manual de diagnóstico.

La sala pasa a BOSS_DEFEATED y guarda en el mismo manejo de la señal terminal. No espera el final del cuerpo ni de BossHUD. La prueba observa disco y memoria ya en true en esa señal, con `destruction_completed=false` y un solo intento. Los eventos repetidos posteriores y una llamada idempotente a GameProgress no cambian principal ni backup ni repiten la confirmación.

No conceden victoria: entrada, intro, Etapa2/umbral6, cancelación, cierre de la sala durante combate, muerte previa del Player, una animación de diagnóstico, una señal inválida ni HP0 preparado solo como fixture visual.

### Eventos terminales próximos

Se usa el orden real de las señales, sin temporizador de arbitraje. Si Player alcanza primero su derrota, Room5 ya está PLAYER_DEFEATED y un DEFEATED posterior del jefe no concede victoria. Si el jefe llega primero a DEFEATED con Player vivo, la victoria confirmada se conserva aunque inmediatamente después muera el Player. El reinicio heredado vuelve a consultar el progreso.

Ambos órdenes se prueban como **fixtures terminales** mediante entradas controladas de daño y preparación explícita del último HP/ventana. No se presentan como derrotas naturales por proyectil ni como parte del recorrido12→0. La partida principal usa exclusivamente espada y salud reales sin esas asignaciones.

## Fallo de guardado

Room5 distingue `victory_persisted` de su estado local BOSS_DEFEATED. Tras el primer fallo conserva al jefe derrotado, las animaciones continúan y la salida se libera según K.1. Programa **un solo reintento tras aproximadamente1s**, con máximo **dos intentos totales por instancia**. No hay escrituras infinitas ni reactivación automática del combate.

Mientras no hay confirmación, una instancia del componente existente TutorialHints muestra «VICTORIA LOCAL — NO SE PUDO GUARDAR. / La memoria también tiene días inútiles.». Se registra un warning con el número de intento. No se modifica la UI compartida ni se inventa un final narrativo. Un reintento exitoso quita ese aviso; si ambos fallan permanece hasta abandonar la sala.

Se prueba un **fallo real de apertura del archivo temporal** creando un directorio vacío en `user://progress_v1.json.tmp`, exclusivamente dentro del perfil APPDATA K.2 protegido por guardia de ruta. No se cambian permisos ni se llena el disco. Ese conflicto hace fallar FileAccess.open y ejecuta el rollback de producción. Se elimina únicamente ese directorio vacío después del escenario.

Dos combates completos adicionales e independientes prueban:

| Escenario aislado | Resultado |
|---|---|
|Conflicto mantenido durante ambos intentos |Rollback del booleano; disco previo intacto; jefe local derrotado; salida libre; no tercer intento; reconstruir Room5 permite que reaparezca |
|Conflicto retirado después del primer fallo |Segundo intento guarda true; victoria permanente confirmada |

No se simularon disco lleno, corte eléctrico ni fallo de renombrado. El uso de la ruta temporal valida la apertura fallida y el rollback real; no demuestra recuperación frente a todos los fallos del sistema de archivos. Si se abandona/libera la instancia antes de un reintento pendiente, no se mantiene un escritor en segundo plano. Sin confirmación en disco, al recargar puede reaparecer el jefe.

## Room5 superada

Se lee el campo en `_ready()` antes de enlazar el HUD al jefe y antes de armar el trigger diferido. Con false se conserva K.1. Con true se inicializa la sala como superada:

- CoreGuardian permanece como nodo estructural, **oculto y con process_mode DISABLED**; su sprite queda pausado.
- CoreWeakpoint queda no monitorable, sin capa de colisión y con su forma deshabilitada. CoreGuardian no tiene un cuerpo sólido que obstruya el paso.
- EncounterTrigger conserva su estructura pero no se arma; hay cero activaciones/ciclos nuevos.
- BossHUD se instancia oculto y no se vincula a una batalla nueva. No se emite `defeated` ni se reproduce destrucción para representar el pasado.
- GuardianHint y ExitBlockHint quedan inactivos; ToRoom4 conserva monitoring, callback único, forma, posición, destino y marcador originales.

No se fuerza la máquina de estados interna del jefe a una derrota pasada ni se asigna otra salud. El estado local de la sala expresa que está superada. No se dibujan restos nuevos ni se reproduce un cuerpo vivo en reposo. La escena Room5.tscn permanece idéntica a K.1.

La prueba de reentrada cruza físicamente el área del antiguo trigger y espera sin ataques ni daño. Hace Shift real a Pasado y de vuelta, comprueba alternancia de P1/T1 y sube a R2 con movimiento/salto reales. Salud y Lente siguen visibles; no hay barra flotante de jefe. Las constantes0,20s/0,16s y los sistemas dimensionales conservan sus fuentes; la suite dimensional completa verifica también rechazo por ocupación y protección originales.

## Continuar y Nueva Partida

La suite se ejecuta en **procesos distintos de Godot con el mismo perfil aislado**:

1. `win`: prepara progresión previa, obtiene victoria real, verifica archivo, sale a Room4 y reingresa.
2. `resume`: un proceso nuevo restaura el campo en el autoload, abre MainMenu y ejecuta su acción existente de Continuar; confirma Room1.5 y las tres posesiones, tutoriales y diálogo guardado.
3. `new_game`: parte de esa victoria restaurada. Primero fuerza el fallo de apertura temporal y usa Nueva Partida desde el menú: no cambia de escena, conserva el disco y revierte todas las posesiones, tutoriales, diálogos y victoria. Retirado el conflicto, la misma acción carga Room1_Tutorial y guarda todos los valores iniciales, incluida victoria=false.

Después de comprobar el destino real de Continuar, se prepara un **fixture de llegada a Room4** y se entra por ToRoom5 con movimiento real. Confirma arena superada. No se afirma haber recorrido Room1.5→Room2→Room2.2→Room3→Room4 en esa prueba. Para Nueva Partida se utiliza otro fixture explícito de progresión previa, sin conceder victoria: el jefe vuelve con12HP/Etapa1, el trigger inicia la intro y el ciclo naturalmente.

MainMenu.gd no cambia; Continuar sigue enviando a Room1.5. No se añade selección de salas, posición persistente ni opción de menú.

## Derrota y reintento del Player

No se modifica el flujo K.1 de muerte, animación y reinicio heredado. La regresión de reintento recibe tres impactos reales del Guardián y verifica nueva instancia con Player3, jefe12/Etapa1, Presente, cooldown0, núcleo cerrado, HUD oculto, peligros limpios, trigger preparado y posesiones conservadas. Morir sin vencer no escribe victoria. Un progreso con victoria ya confirmada inicializa cualquier Room5 posterior como superada.

## Validación continua, regresiones y límites

La partida principal prepara únicamente progresión legítima y llegada en la repisa Room4(1160,264). Desde el desplazamiento hacia ToRoom5 no reasigna posiciones ni HP, no invoca manualmente inicio/ataques y no fuerza el selector. Se observan12 tajos aceptados, transición real al umbral6, haces elegibles de Etapa2, seis Shift, guardado terminal y transición de ida/vuelta.

| Métrica headless60Hz | K.2 | K.1 |
|---|---:|---:|
|Introducción |1,000s |1,000s |
|Ciclo → DEFEATED |73,433s |73,433s |
|Arcos /haces /ventanas |6 /3 /6 |6 /3 /6 |
|Impactos /Shift /daño recibido |12 /6 /0 |12 /6 /0 |
|Player final |3/3 |3/3 |
|Confirmaciones de victoria /intentos en caso normal |1 /1 |Sin persistencia |

[combat.json](../artifacts/room5_stage_k2/combat.json) guarda eventos y snapshot terminal; [resume.json](../artifacts/room5_stage_k2/resume.json), [new_game.json](../artifacts/room5_stage_k2/new_game.json) y [failures.json](../artifacts/room5_stage_k2/failures.json) documentan las demás etapas. Los archivos por resolución son de ejecuciones independientes con render, no sustituyen la reapertura headless.

Las18 suites obligatorias se ejecutan **secuencialmente**, con APPDATA externo y Godot4.7.2:

| Suite | Resultado |
|---|---|
|core_guardian_base_test |30 PASS |
|core_guardian_beam_test |29 PASS |
|core_guardian_arc_test |57 PASS |
|core_guardian_combat_cycle_test |51 PASS |
|core_guardian_adaptive_approach_test |74 PASS |
|core_guardian_phase_two_test |54 PASS |
|core_guardian_hud_test |75 PASS |
|room5_encounter_activation_test |37 PASS |
|room5_encounter_retry_test |38 PASS |
|core_guardian_victory_persistence_test |win48 /resume17 /new_game25 /failures123 PASS |
|room5_base_test |71 PASS |
|room5_dimension_test |153 PASS |
|room4_room5_transition_test |Sin fallos |
|room4_reactor_key_test |Sin fallos |
|progress_menu_test |Sus tres grupos PASS |
|attack12_test |Sin fallos |
|temporal_shift_protection_test |Sin fallos |
|validate |Sintaxis exitosa |

Los perfiles de pruebas históricas comienzan sin victoria; se conserva su modalidad manual explícita cuando corresponde. La prueba K.1 se respalda y actualiza para esperar sala superada al reingresar tras victoria; su fixture de bloqueo comienza después una Nueva Partida aislada. No se eliminan aserciones ni se relajan controles físicos. La llegada de esa prueba reconoce el estado pasivo o superado según el progreso.

`progress_menu_test` requiere `application/config/name=Core9_Combat_Isolated`. El runner cambia solamente la copia externa de project.godot durante esa prueba y restaura exactamente sus bytes en finally. El proyecto real conserva su nombre/configuración. Los renders de persistencia ejecutan win/resume/new_game por separado en cada resolución.

Todas las ejecuciones finales terminan con exit0. En cada tamaño, los renders pasan59 controles de victoria,17 de reapertura/Continuar y26 de Nueva Partida. La revisión visual confirma en ambos tamaños arena superada sin jefe/barra, HUDs normales, Pasado jugable y jefe disponible en el fixture de Nueva Partida. Los24 PNG conservan su tamaño físico exacto y SHA-256 registrado.

No hay fallos de aserción ni errores de script en las ejecuciones finales. Los warnings de guardado de `new_game`/`failures` son los fallos IO inyectados esperados. Además aparecen avisos ObjectDB/recursos al cerrar algunas suites históricas **y también etapas de la suite nueva**. Se conservan completos en `.err`; no se atribuyen todos automáticamente a problemas históricos ni se declara resuelta su causa. Queda pendiente un diagnóstico de liberación al cerrar las pruebas, separado de los resultados funcionales y de integridad. No se modifican sistemas compartidos para silenciarlos.

## Capturas reales

Veinticuatro PNG directos del viewport,12 por tamaño. Las primeras11 vistas pertenecen a la partida continua de victoria y su reentrada en la misma ejecución; esa permanencia se respalda además mediante la prueba de proceso nuevo/Continuar. La última es el fixture de progresión tras Nueva Partida, identificado en el nombre. Se combinan reingreso/arena/HUD normal y combate iniciado/Etapa1 para evitar duplicados.

| Estado |1024×572 |1280×720 |
|---|---|---|
|Antes de vencer |[PNG](../artifacts/room5_stage_k2/01_antes_de_vencer_1024x572.png) |[PNG](../artifacts/room5_stage_k2/01_antes_de_vencer_1280x720.png) |
|Introducción |[PNG](../artifacts/room5_stage_k2/02_intro_1024x572.png) |[PNG](../artifacts/room5_stage_k2/02_intro_1280x720.png) |
|Encuentro iniciado, Etapa1 |[PNG](../artifacts/room5_stage_k2/03_etapa1_1024x572.png) |[PNG](../artifacts/room5_stage_k2/03_etapa1_1280x720.png) |
|Transición Sobrecarga |[PNG](../artifacts/room5_stage_k2/04_sobrecarga_1024x572.png) |[PNG](../artifacts/room5_stage_k2/04_sobrecarga_1280x720.png) |
|Etapa2 confirmada |[PNG](../artifacts/room5_stage_k2/05_etapa2_1024x572.png) |[PNG](../artifacts/room5_stage_k2/05_etapa2_1280x720.png) |
|Derrota real |[PNG](../artifacts/room5_stage_k2/06_derrota_real_1024x572.png) |[PNG](../artifacts/room5_stage_k2/06_derrota_real_1280x720.png) |
|Destrucción BossHUD |[PNG](../artifacts/room5_stage_k2/07_destruccion_HUD_1024x572.png) |[PNG](../artifacts/room5_stage_k2/07_destruccion_HUD_1280x720.png) |
|Salida libre |[PNG](../artifacts/room5_stage_k2/08_salida_libre_1024x572.png) |[PNG](../artifacts/room5_stage_k2/08_salida_libre_1280x720.png) |
|Regreso Room4 |[PNG](../artifacts/room5_stage_k2/09_regreso_Room4_1024x572.png) |[PNG](../artifacts/room5_stage_k2/09_regreso_Room4_1280x720.png) |
|Reingreso, arena sin jefe y HUD normal |[PNG](../artifacts/room5_stage_k2/10_reingreso_arena_HUD_1024x572.png) |[PNG](../artifacts/room5_stage_k2/10_reingreso_arena_HUD_1280x720.png) |
|Pasado tras vencer |[PNG](../artifacts/room5_stage_k2/11_pasado_tras_victoria_1024x572.png) |[PNG](../artifacts/room5_stage_k2/11_pasado_tras_victoria_1280x720.png) |
|Fixture Nueva Partida: jefe disponible |[PNG](../artifacts/room5_stage_k2/fixture_12_nueva_partida_1024x572.png) |[PNG](../artifacts/room5_stage_k2/fixture_12_nueva_partida_1280x720.png) |

No se genera arte ni se editan imágenes fuente. Las vistas clave de reentrada y Pasado permiten comprobar la ausencia visual del Guardián/BossHUD y la conservación de HUDs y plataformas. La prueba automatizada no sustituye una evaluación humana de la sensación del combate.

## Cambios y respaldo

Archivos preexistentes modificados:

- `scripts/game_progress.gd`: booleano, serialización/carga, rollback de Nueva Partida y API idempotente de victoria.
- `scripts/rooms/room5.gd`: persistencia terminal, reintento acotado, aviso local e inicialización superada.
- `tests/room5_encounter_activation_test.gd`: expectativas de reentrada y preparación separada del fixture de bloqueo.
- `docs/STATE.md`: actualización puntual del estado implementado y conexión de Sala5.

Nuevos: `tests/core_guardian_victory_persistence_test.gd`, este informe, evidencias/JSON/logs y metadatos `.gd.uid` generados automáticamente por Godot. Estos acompañan la prueba nueva y scripts de HUD/pruebas de J/K.1 que todavía no tenían UID: `core_guardian_hud_test`, `room5_encounter_activation_test`, `room5_encounter_retry_test` y `scripts/ui/boss_hud.gd`. Se conservan esos metadatos; el contenido de los scripts de HUD/pruebas previas, salvo la adaptación autorizada del test de activación, sigue intacto. No se cambia **ninguna escena**, MainMenu, Player, DimensionManager, LevelTransition, Room4, CoreGuardian, ataques, HUDs ni recursos originales/derivados. El método de cámara permanece idéntico.

Respaldo previo verificado: **`C:/Users/juans/chrono-shift-backups/room5_stage_k2_20261116_193926/`**, con los cuatro archivos preexistentes y SHA-256 en hashes.json. Se conservan todos los respaldos anteriores. La comparación de **2385 archivos preexistentes** confirma exactamente esos cuatro cambios y los dos guardados reales intactos. La comparación final de inventario, archivos modificados, recursos y guardados está en [verification.json](../artifacts/room5_stage_k2/verification.json). MCP termina conectado al proyecto correcto, Room5 sin cambios de escena pendientes y ejecución detenida.

Helpers/perfiles: `C:/Users/juans/.codex/visualizations/2026/11/16/01a1e570-850c-7a83-8965-7511f3d3ed84/phase_k2_work/` y directorio padre. `run_stage_k2.ps1` ejecuta las etapas en procesos separados con un mismo perfil por modo/resolución; las suites headless usan el espejo externo y los renders escriben solo evidencias K.2 en el proyecto.

## Preparación para K.3

La victoria persistente queda disponible como condición para una futura resolución narrativa. K.3 debe definir explícitamente qué sucede con el reactor, secuencia final, reentrada después del final y compatibilidad con partidas que ya tengan `core_guardian_defeated=true`. No usar la destrucción visual del HUD como disparador persistente ni volver a emitir derrotas antiguas para iniciar narrativa.

Pendientes: diagnóstico de avisos de recursos al cerrar pruebas, revisión humana y limitaciones artísticas ya documentadas de Starting/Attack3/paquete de arco. No se implementan diálogos nuevos, reactor, créditos ni final. **K.2 termina aquí; K.3 requiere autorización independiente.**
