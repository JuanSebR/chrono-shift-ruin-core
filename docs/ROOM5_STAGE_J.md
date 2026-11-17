# Sala 5 — Fase J: HUD del Guardián del Núcleo

16/11/2026 · Godot4.7.2 · BossHUD local integrado. **No se cambió el controlador del Guardián ni se activó el combate al entrar.**

## Resultado y alcance

El HUD aparece cuando el ciclo real está activo, representa los12HP mediante el arte original, muestra la etapa confirmada y reproduce la destrucción original al recibir DEFEATED. Se oculta al detener el ciclo, al finalizar la destrucción o al liberarse el jefe/sala. No gobierna la IA ni contiene otra salud.

El combate continuo con HUD conserva exactamente las métricas headless de I.3: **73,833s hasta DEFEATED**,74,083s hasta terminar la rutina de entrada,6 arcos,3 haces,6 ventanas,12 impactos,6 cambios dimensionales,0 daños recibidos y Player3/3. La destrucción del HUD termina después, sin cambiar escena, progreso ni el resultado del combate.

Se aplicaron godot-gamedev y game-designer. Antes de editar se revisaron AGENTS, GDD/STATE, plan maestro, inventario/fase A, F/I.2 y el informe I.3; las señales y recursos actuales determinan la integración. MCP confirmó Room5 guardada, detenida y en el proyecto correcto. No se repitieron auditorías de otras salas.

## 1. Recursos originales y derivados

Las hojas se inspeccionaron visualmente y mediante dimensiones/canal alfa. El número de HP no se dedujo de sus filas.

| Original conservado | Dimensiones exactas | Contenido real |
|---|---:|---|
| `assets/sprites/jefe/barra de vida GuardianNucleo.png` |1247×1261 RGBA |4 estados verticales:3,2,1 y0 cámaras iluminadas |
| `assets/sprites/jefe/defeated barraDeVida GuardianNucleo.png` |1182×1330 RGBA |5 cuadros verticales: fisuras, fractura, paneles separados, restos y partículas finales |

La quinta fila de derrota contiene partículas visibles; no es un cuadro vacío y no son seis cuadros. El espacio inferior de la hoja es mayormente vacío con restos débiles de alfa, no otra pose de destrucción. El orden real es de arriba hacia abajo.

Se reutilizan íntegramente los derivados de Fase A:

- `assets/sprites/jefe/derived/atlases/hud_health_atlas.png`:1280×128,4 celdas de320×128.
- `assets/sprites/jefe/derived/atlases/hud_defeated_atlas.png`:1600×128,5 celdas de320×128.
- `assets/sprites/jefe/derived/room5_stage_a_manifest.json`: correspondencia y orden de recortes fuente.

No se extraen nuevamente las hojas ni se modifican PNG/importaciones. No se generan imágenes nuevas de barra ni se sustituye por un diseño genérico. El recurso completo de la hoja nunca se dibuja como una sola barra: se crean AtlasTexture por celda.

En salud se utiliza la carcasa vacía del estado3 y energía recortada del estado0 lleno. Los estados1/2 se cargan y validan como parte del atlas original, pero no se usan como una animación temporal de daño. En derrota se muestran las cinco celdas originales en orden.

### Transparencia y fidelidad

Las fuentes y derivados contienen transparencia real, píxeles alfa fuerte≈252–254 y algunos residuos débiles alfa1. No se aplicó ningún umbral nuevo de color/alfa, no se borraron negros ni se reconstruyeron remaches, sombras, extremos o luces. Se conservan las decisiones de limpieza A; la revisión no muestra una cuadrícula invasiva en el HUD final. Persisten halos débiles de origen, sin prometer una restauración artística nueva.

La carcasa útil de salud ocupa aproximadamente280×62 píxeles de alfa≥128 dentro de cada lienzo320×128. Los márgenes vacíos del atlas no se confunden con tamaño visible. [assets.json](../artifacts/room5_stage_j/assets.json) contiene hashes originales/derivados, dimensiones, rectángulos de alfa y significado de cada cuadro. Los recursos originales y derivados previos conservan sus SHA-256.

## 2. Componente y estructura

Nueva escena `scenes/ui/BossHUD.tscn`, controlador `scripts/ui/boss_hud.gd`:

```text
BossHUD (CanvasLayer, layer11)
└── Anchor (Control, 300×80)
    ├── HealthArt (Control, dibujo de barra y destrucción)
    ├── BossName (Label)
    ├── PhaseIndicator (Label)
    └── HealthValue (Label)
```

La destrucción reutiliza HealthArt; no necesita un segundo conjunto de nodos superpuestos. Room5 instancia este componente local y llama `bind_guardian($CoreGuardian)` al preparar la sala. Eso solo enlaza y sincroniza; no inicia el ciclo. Room5.tscn no necesitó edición. No se duplica CombatHUD ni se modifica TemporalLensHUD/GuardianHint compartido.

El nombre es **GUARDIÁN DEL NÚCLEO**. Labels14/12px lógicos, sombra y contorno negro para mantener lectura sobre el borde inferior metálico de la arena. El indicador usa texto, además de tono ámbar; no depende únicamente del color. No se recolorean animaciones corporales del jefe.

## 3. Posición, escala y convivencia

Anclaje a pantalla mediante CanvasLayer; posición del Anchor = tamaño visible del viewport −(320,92), redondeada. Su área300×80 deja20 unidades lógicas a derecha y12 abajo. No utiliza posición del jefe ni mueve cámara. La escala del arte es uniforme(0,75;0,75), con nearest; los textos se mantienen en su tamaño lógico propio. La carcasa visible queda en≈210×46,5 unidades de UI.

El proyecto aplica su estiramiento de ventana existente. Medidas reales registradas en los renders:

| Ventana física | Viewport lógico medido | Anchor lógico | Carcasa útil física aproximada |
|---|---|---|---|
|1024×572 |1160×648 |(840,556),300×80 |185×41px |
|1280×720 |1152×648 |(832,556),300×80 |233×52px |

No se cambió ese estiramiento, la cámara ni `_fit_camera()`. Los valores headless de viewport pueden ser distintos y no se usan para acreditar la composición de las capturas. Los rectángulos medidos de cada render quedan dentro de su JSON.

GuardianHint permanece arriba al centro; salud del Player arriba a izquierda y Lente arriba a derecha. La prueba mide y rechaza intersecciones entre esos rectángulos y BossHUD. El núcleo, las plataformas superiores y el aviso de descarga permanecen visibles. El encabezado del BossHUD queda cerca del borde gráfico de F0, por lo que se añadió contorno a los textos para contraste; no se presenta como pulido final de accesibilidad. El propio arte de barra queda debajo del sector de impacto del núcleo. Todos los controles ignoran mouse y no bloquean movimiento.

## 4. Representación proporcional de doce puntos

`health_fraction()` lee directamente `guardian.health / guardian.max_health`, limitado a0–1. No hay HP independiente, máximo propio ni cola de daño simulada. `HealthValue` también lee esos valores reales.

El arte tiene tres cámaras. Para la cámara i=0,1,2:

`fracción = clamp(3 * health_fraction - i, 0, 1)`

Se dibuja la carcasa vacía completa y se revela una región proporcional de la energía original llena dentro de cada cámara. Las regiones de muestreo son(58,52,70,28),(129,52,64,28),(193,52,67,28), en coordenadas del atlas/celda. El ancho se redondea hacia abajo a píxel entero. Esto conserva proporciones y detalles metálicos; solo recorta energía. No se crean sprites de salud intermedia.

| Salud real | Presentación |
|---|---|
|12/12 |Tres cámaras llenas |
|11/12 |Dos llenas y tercera al75% |
|9/12 |Dos llenas y tercera al25% |
|6/12 |Una llena y segunda al50%; total mitad |
|3/12 |Primera al75% |
|1/12 |Primera al25% |
|0/12 |Carcasa vacía y contador0, antes de destruirse |

En esta configuración cada cámara equivale a4HP; esa equivalencia proviene de12HP reales y3 cámaras, no fija la vida del jefe. El corte parcial tiene borde vertical dentro de la cámara: es una máscara del original, no una nueva ilustración de LED. El número complementa esa lectura para distinguir cada punto.

Al aceptar daño, la lógica del Guardián actualiza HP primero y emite su señal. El HUD refresca inmediatamente la textura/contador y aplica un acento ámbar breve0,12s al número. No retrasa la salud ni cambia el arte corporal. Otro golpe actualiza inmediatamente y reinicia solo ese acento visual; no pierde el segundo tajo ni espera a terminar una animación anterior.

## 5. Señales y fuentes de verdad

`bind_guardian()` conecta una sola vez:

- `health_changed(current, maximum)`: refresco de salud desde propiedades reales.
- `combat_phase_changed(current)`: refresco desde `combat_phase`.
- `state_changed(current)`: transición/visibilidad consultando estado real y `cycle_running`.
- `defeated`: comienza destrucción solo si salud0 y estadoDEFEATED reales.
- `tree_exiting`: desvincula y oculta sin fabricar una derrota.

El reenlace a la misma instancia solo sincroniza, sin duplicar conexiones. Al cambiar objetivo, liberarse HUD o salir el jefe, se desconectan las señales del objetivo anterior. No se suscribe a DimensionManager ni a salud del Player. El HUD no llama a APIs de ataque, inicio/detención, daño o progreso. **No se modificó core_guardian.gd.**

Como parte de la prueba de liberar el jefe, GuardianHint local intentaba leer un CoreGuardian ya eliminado. Se añadió una lectura segura con `get_node_or_null` en room5.gd, sin modificar el recurso compartido. El primer log de ese fixture se conserva en `logs/initial_guardian_free_fixture.*`; la ejecución final no contiene esos errores.

## 6. Etapa, transición y derrota

| Estado real | Texto/acción del HUD |
|---|---|
|Sala pasiva |Oculto; CombatHUD sigue visible |
|Ciclo activo Etapa1 |Salud real, «ETAPA 1» |
|6HP con ventana vigente |6/12, sigue Etapa1 |
|PHASE_TRANSITION aún en fase1 |«TRANSICIÓN», sin restaurar barra |
|combat_phase2 confirmado |«SOBRECARGA», conserva6/12 u HP actual |
|Stop con jefe vivo |Oculta sin destrucción; salud del jefe intacta |
|DEFEATED |Salud0, secuencia de destrucción única, luego oculta |
|Cambio de sala/liberación |Se elimina/desconecta; no aparece fuera de Room5 |

La indicación de segunda etapa no se infiere del50% ni de un temporizador de UI. El test observa6HP durante ventana/retorno/transición y confirma que no hubo «SOBRECARGA» prematura. El daño rechazado por protección o Pasado no emite reducción aceptada y no produce pérdida falsa en barra/contador.

## 7. Destrucción original

Solo la señal de derrota válida inicia la secuencia. Primero se conserva0/12 y carcasa vacía durante0,08s. Después se reproducen los cinco cuadros originales, **0,12s por cuadro** (≈0,60s de animación), con orden fisuras → fractura → paneles separados → restos → partículas. Duración visual total≈0,68s, cuantizada por frame. Esta velocidad se eligió para percibir la fragmentación sin espera larga, no por heredar el FPS del cuerpo.

El último cuadro contiene partículas; no se inventó un final vacío. Al terminar se oculta Anchor completo y se conserva el índice4 como estado terminal visual. No vuelve a una textura llena. Una señal DEFEATED repetida no reinicia nada. Stop, cambio de etapa y salida no disparan destrucción. Enlazar un jefe ya derrotado tampoco fabrica una nueva muerte.

Este reloj es exclusivamente visual. No altera animaciones, recuperación, ventanas ni decisiones del Guardián. La arena sigue cargada tras la derrota; no hay créditos, reactor, cambio de sala automático ni persistencia de victoria.

## 8. Validación integrada

Prueba nueva `tests/core_guardian_hud_test.gd`: **75 controles PASS**. Reutiliza mediante herencia el recorrido físico I.3 sin editar esa prueba; añade observación del HUD y guarda sus propios resultados en Fase J para no sobrescribir informes anteriores.

La progresión continua es real: spawn(140,600), jefe12, activación manual, tres aperturas en Etapa1, umbral6 y transición segura, R2 con movimiento/salto, haz elegido realmente, Shift a Pasado, regreso a Presente, espada y derrota. Ningún HP ni posición del Player se reasigna durante ese recorrido. Se observan todos los valores12→0 del contador,12 eventos de salud aceptados y la indicación de etapa confirmada.

| Métrica headless | Con HUD J | Referencia I.3 |
|---|---:|---:|
|DEFEATED |73,833s |73,833s |
|Rutina de entradas completa |74,083s |74,083s |
|Arcos /haces |6 /3 |6 /3 |
|Ventanas /impactos |6 /12 |6 /12 |
|Shift confirmados |6 |6 |
|Daño recibido /Player final |0 /3 de3 |0 /3 de3 |
|Actualizaciones de salud del HUD |12 |No existía HUD |
|Reproducciones de destrucción |1 |No existía HUD |

Los renders en ambas resoluciones también completan el recorrido y muestran todos los cuadros. Sus esperas de captura pueden añadir un paso físico; no se mezclan sus tiempos con los headless. [metrics.json](../artifacts/room5_stage_j/metrics.json), [continuous.json](../artifacts/room5_stage_j/continuous.json), [1024×572](../artifacts/room5_stage_j/continuous_1024x572.json), [1280×720](../artifacts/room5_stage_j/continuous_1280x720.json) contienen eventos y traza visual.

Fixtures separados y explícitos: espada real contra núcleo protegido, espada real en Pasado, dos tajos aceptados en Presente, estados visuales12/11/9/6/3/1, reenlace de señales, Stop/reinicio, salida real Room5→Room4 y liberación del jefe. Las asignaciones de HP de los fixtures solo comprueban máscaras; no se usan como prueba de la progresión12→0. La notificación terminal repetida se emite después de una derrota auténtica por espada para verificar idempotencia.

Se verifican independencia de salud del Player, transparencia externa/sombras internas, celdas4/5, frame final no vacío, orden observado−1(carcasavacía),0,1,2,3,4, ocultación terminal y ausencia del HUD fuera de Room5. El movimiento del Player no desplaza el Anchor.

### Regresiones secuenciales finales

| Suite |Resultado |
|---|---|
|core_guardian_base_test |30 PASS |
|core_guardian_beam_test |29 PASS |
|core_guardian_arc_test |57 PASS |
|core_guardian_combat_cycle_test |51 PASS |
|core_guardian_adaptive_approach_test |74 PASS |
|core_guardian_phase_two_test |54 PASS |
|core_guardian_hud_test |75 PASS |
|room5_combat_playtest_test |21 controles de infraestructura, modo diagnóstico Etapa1 |
|room5_base_test |71 PASS |
|room5_dimension_test |153 PASS |
|room4_room5_transition_test |Sin fallos |
|attack12_test |Sin fallos |
|temporal_shift_protection_test |Sin fallos |
|validate |Sintaxis exitosa |

Todas se ejecutaron con APPDATA aislado, Godot4.7.2 y reloj fijo60Hz. Los renders pasan87 controles cada uno, incluidos12 PNG. Las pruebas históricas no se editaron ni se eliminaron aserciones. Persisten avisos ObjectDB/recursos al cerrar algunas suites históricas; se conservan aparte y no se declaran resueltos. El diagnóstico HUD final termina sin errores de script.

## 9. Capturas reales

Veinticuatro PNG directos del viewport. Todas las siguientes imágenes son de la partida continua con HUD en su resolución, incluida la destrucción posterior. Los fixtures sintéticos de estados intermedios no se presentan como recorrido continuo.

|Estado |1024×572 |1280×720 |
|---|---|---|
|Pasiva, HUD oculto |[PNG](../artifacts/room5_stage_j/01_pasiva_1024x572.png) |[PNG](../artifacts/room5_stage_j/01_pasiva_1280x720.png) |
|Inicio lleno |[PNG](../artifacts/room5_stage_j/02_llena_1024x572.png) |[PNG](../artifacts/room5_stage_j/02_llena_1280x720.png) |
|10/12 |[PNG](../artifacts/room5_stage_j/03_salud10_1024x572.png) |[PNG](../artifacts/room5_stage_j/03_salud10_1280x720.png) |
|6/12, aún Etapa1 |[PNG](../artifacts/room5_stage_j/04_salud6_1024x572.png) |[PNG](../artifacts/room5_stage_j/04_salud6_1280x720.png) |
|Transición |[PNG](../artifacts/room5_stage_j/05_transicion_1024x572.png) |[PNG](../artifacts/room5_stage_j/05_transicion_1280x720.png) |
|Sobrecarga confirmada |[PNG](../artifacts/room5_stage_j/06_sobrecarga_1024x572.png) |[PNG](../artifacts/room5_stage_j/06_sobrecarga_1280x720.png) |
|Núcleo expuesto |[PNG](../artifacts/room5_stage_j/07_nucleo_expuesto_1024x572.png) |[PNG](../artifacts/room5_stage_j/07_nucleo_expuesto_1280x720.png) |
|2/12 |[PNG](../artifacts/room5_stage_j/08_salud2_1024x572.png) |[PNG](../artifacts/room5_stage_j/08_salud2_1280x720.png) |
|0/12 antes de fractura |[PNG](../artifacts/room5_stage_j/09_salud0_1024x572.png) |[PNG](../artifacts/room5_stage_j/09_salud0_1280x720.png) |
|Destrucción inicial |[PNG](../artifacts/room5_stage_j/10_destruccion_inicial_1024x572.png) |[PNG](../artifacts/room5_stage_j/10_destruccion_inicial_1280x720.png) |
|Destrucción media |[PNG](../artifacts/room5_stage_j/11_destruccion_media_1024x572.png) |[PNG](../artifacts/room5_stage_j/11_destruccion_media_1280x720.png) |
|Partículas finales |[PNG](../artifacts/room5_stage_j/12_destruccion_final_1024x572.png) |[PNG](../artifacts/room5_stage_j/12_destruccion_final_1280x720.png) |

La revisión confirma separación de GuardianHint/salud/Lente, núcleo visible, proporción de la barra, lectura del estado y final de partículas. No se afirma pulido artístico final del combate: siguen las discontinuidades corporales de Attack3 y el paquete provisional.

## 10. Archivos, respaldo e integridad

Único archivo preexistente modificado: `scripts/rooms/room5.gd`, para instanciar/enlazar BossHUD y tolerar la ausencia del Guardián al refrescar su hint local. **Room5.tscn, CoreGuardian.tscn, core_guardian.gd y todos los componentes ofensivos permanecen byte a byte iguales.** No cambian cámara, geometría ni plataformas.

Nuevos: `scenes/ui/BossHUD.tscn`, `scripts/ui/boss_hud.gd`, `tests/core_guardian_hud_test.gd`, este informe y evidencias/JSON/logs/metadatos. No se generan nuevos PNG de arte jugable ni se modifican recursos originales/derivados previos. Los únicos PNG nuevos son capturas diagnósticas.

Respaldo previo: `C:/Users/juans/chrono-shift-backups/room5_stage_j_20261116_183807/`, con SHA-256 en `hashes.json`. Incluye Room5.tscn y el controlador del jefe por precaución aunque no se editaron. La línea base de todos los archivos anteriores y los dos guardados reales se coteja en [verification.json](../artifacts/room5_stage_j/verification.json). Los hashes de recursos figuran además en assets.json.

Helpers y perfiles: `C:/Users/juans/.codex/visualizations/2026/11/16/01a1e570-850c-7a83-8965-7511f3d3ed84/phase_j_work/` y directorio padre. Las pruebas headless históricas escriben en el espejo externo; los renders usan el proyecto real. No se usan guardados reales como perfiles, no se escribe GameProgress y no se tocan servicios, memorias, credenciales ni configuraciones MCP.

## 11. Preparación para la siguiente fase

El HUD queda listo para que una activación futura llame a la API existente; no debe mostrarse por llave, llegada o proximidad antes de esa decisión. Recomiendo revisión humana de lectura de nombres/indicador sobre F0 y discriminación de1HP, manteniendo primero el diseño original. Si se ajusta tamaño o posición, repetir ambas resoluciones y la destrucción completa sin tocar cámara ni núcleo.

La fase siguiente debe autorizar explícitamente inicio real, barreras, intro, música o resolución narrativa/persistencia si se desean. Nada de ello se implementó en J. El trabajo se detiene aquí.
