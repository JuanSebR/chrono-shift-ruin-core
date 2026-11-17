# Sala 5 — Fase D: cambio dimensional integrado

16 de noviembre de 2026. Room5 alterna entre Presente y Pasado mediante el sistema compartido de Room4. La escena sigue siendo independiente y comienza en Presente. La Fase D termina aquí: no hay Guardián, BossHUD, ataques nuevos, transiciones, puertas, checkpoints ni recuperación por caída.

## Integración realizada

Solo se modificó `scenes/Room5.tscn`. Se añadieron tres secciones: referencia a `DimensionManager.gd`, un nodo `DimensionManager` configurado y una conexión de `dimension_changed` con la API existente `CombatHUD.update_dimension_theme`. No se reescribió la escena.

El gestor utiliza prioridad física −10, igual que en Room4, antes del Player. Referencias locales:

```text
Room5
├── Visuals
│   ├── Present                 fondo rojo, arquitectura, P1 sólida, T1 fantasma
│   ├── Past                    fondo azul, arquitectura, P1 fantasma, T1 sólida
│   └── SharedPlatforms         F0, R1 y R2; siempre visible
├── WorldCollision
│   ├── SharedCollision         F0, R1, R2 y ambos contornos laterales
│   ├── PresentCollision/P1/Shape
│   └── PastCollision/T1/Shape
├── EntryMarkers                marcadores de C, sin cambios
├── Player                      instancia original
├── DimensionManager            script compartido original
└── CombatHUD                   instancia original
```

`present_visuals` y `past_visuals` apuntan a sus conjuntos existentes. `present_shapes` contiene únicamente P1; `past_shapes`, únicamente T1. `controlled_player` y `player_collider` apuntan al Player original y su CollisionShape2D. Shared queda fuera de esos arrays.

`scripts/rooms/room5.gd` permanece intacto, incluida su herencia de `room2.gd`. La base ya realiza llegada efímera, conexiones de salud/daño/derrota, sincronización de salud y reinicio local. No se duplicó ninguna responsabilidad. Tampoco se añadió GameManager: es un controlador de la escena tutorial, no un autoload; su ruta histórica de Shift para TileMapLayer no corresponde a esta integración. El gestor compartido procesa la entrada real mediante `_unhandled_input` y confirma en física.

TemporalLensHUD descubre el mismo script de gestor y se conecta mediante su código existente. La conexión nueva del archivo de escena solo actualiza el tema cromático de salud; no duplica la lógica del HUD circular. En ejecución hay dos observadores de producción para `dimension_changed`: HUD temporal y tema de salud. El tercer observador del test es instrumental y no forma parte de Room5 guardada.

## Estado inicial y reglas

Con o sin Lente: Presente activo, P1 habilitada, T1 deshabilitada, Shared y paredes activas, cooldown cero y sin protección temporal. La escena no concede la Lente ni escribe progreso.

Sin Lente en GameProgress, el HUD temporal permanece oculto y pulsar Shift no acepta cambios, no inicia cooldown ni protección y no activa Pasado. Con Lente poseída, el HUD muestra PRESENTE disponible y la entrada existente permite alternar. Las pruebas asignan posesiones solo en memoria dentro de perfiles aislados; esta preparación no existe en producción.

| Superficie | X útil | Y superior | Presente | Pasado | Tipo conservado |
|---|---:|---:|---|---|---|
| F0 | 80–1200 | 620 | Activa | Activa | Firme, Rectangle1120×8 |
| R1 | 300–460 | 560 | Activa | Activa | One-way, Rectangle160×8 |
| P1 | 500–660 | 500 | Activa | Inactiva | One-way, Rectangle160×8 |
| T1 | 700–860 | 500 | Inactiva | Activa | One-way, Rectangle160×8 |
| R2 | 780–940 | 560 | Activa | Activa | One-way, Rectangle160×8 |
| Paredes | Contornos de C | — | Activas | Activas | CollisionPolygon2D existentes |

Se conservaron las cinco identidades de Shape independientes, tamaños, posiciones, transformaciones, one-way, capas y máscaras. No se añadieron colliders. El gestor deshabilita primero los exclusivos salientes y después habilita los entrantes: P1 y T1 no aparecen sólidas simultáneamente. La prueba observa la matriz en cada paso de su recorrido, además de comprobar estados confirmados.

Los conjuntos visuales cambian juntos: fondo, arquitectura, sólido propio y fantasma contrario. Shared no se oculta ni duplica. Texturas, orígenes, escalas uniformes, modulación alfa, nearest y z-index de C permanecen intactos. No se regeneró ningún PNG, atlas ni derivado de A/C.

## Ocupación, cooldown y protección

Se reutiliza sin modificaciones la comprobación geométrica de `DimensionManager.gd`: el rectángulo del Player con inset0,1 se compara contra los Shape de destino, aunque estén deshabilitados. También se aplica a plataformas one-way. Un rechazo conserva dimensión, visuales, colisiones, posición y velocidad, no consume recarga ni activa protección, y el HUD muestra CAMBIO BLOQUEADO.

Un cambio aceptado aplica la matriz, fija `SWITCH_COOLDOWN = 0.20`, llama a la protección real del Player y emite `dimension_changed`. El Player conserva su Timer independiente con `wait_time = 0.16`. No se añadieron temporizadores ni controladores locales de Shift, recarga o protección.

El test observa los seis fotogramas de recarga y las cinco poses de protección existentes. Daño normal y el proyectil original son rechazados durante la protección, sin consumir salud ni iniciar invulnerabilidad ordinaria. El proyectil solo se instancia en la prueba controlada y se consume allí; la escena guardada no incorpora enemigos ni proyectiles. Después de la ventana, daño y salud 2/3, 1/3 y 0/3 utilizan los sistemas originales.

Con reloj fijo de60fps, los eventos de protección quedaron separados por9 intervalos de fotograma, aproximadamente0,1500s, y la observación de cooldown cero llegó a0,2167s. Estos son tiempos discretos observados, con resolución de un paso; no son valores nuevos de diseño. Se verificaron exactamente0,16s en la señal/Timer y0,20s al confirmar el gestor. La protección terminó con≈0,05s de recarga todavía pendiente. No se alteraron las implementaciones compartidas para corregir cuantización o redondeo flotante.

Shift sin Lente, durante recarga, rechazado o con salud cero no inicia otra protección. Una ráfaga de cuatro pulsaciones adicionales durante cooldown no produjo cambios ni señales duplicadas. Una instancia nueva comienza en Presente, sin recarga ni efectos heredados. El daño ordinario no dispara el destello temporal.

## Recorrido continuo real

`tests/room5_dimension_test.gd` utiliza InputEventKey con KEY_SHIFT izquierdo y pulsación/liberación reales; no llama a `toggle_dimension` ni al método de aplicación de estado. Movimiento y salto usan las acciones originales. El recorrido siguiente no reposiciona al Player:

| Paso | Posición o resultado observado |
|---|---|
| Spawn y movimiento en F0 | (140,600), salud3/3, velocidad cero; llegada a X≈280,444 |
| F0→R1 | Aterrizaje≈(352,897;539,964), cuerpo R1, vuelo≈0,567s |
| R1→P1 en Presente | Aterrizaje≈(533,790;479,963), cuerpo P1, vuelo≈0,567s |
| Shift sobre P1 | Se acepta Pasado, desaparece el apoyo y comienza caída física |
| P1→F0 | Aterrizaje≈(533,790;599,988), cuerpo F0 |
| F0→R2 en Pasado | Aterrizaje≈(834,685;539,964), cuerpo R2 |
| Shift sobre R2 | Vuelve a Presente conservando apoyo Shared |
| R2→T1 | Salto vertical real, Shift en ascenso y aterrizaje≈(834,685;479,963) sobre T1; vuelo≈0,567s |
| T1→R2 | Shift a Presente retira T1; caída y aterrizaje real sobre R2 |
| R2→F0 | Descenso mediante control existente y aterrizaje en F0 |
| Regreso | Movimiento hasta≈(138,240;599,994), Presente, salud3/3 y posesiones conservadas |

La activación aérea se solicita aproximadamente en(834,685;463,996), con velocidad vertical≈−244,893. La confirmación se produce tras un paso normal, aproximadamente enY460,323 con velocidad≈−220,393. La diferencia coincide con la integración física de gravedad; no es un impulso ni una reposición del gestor.

Para demostrarlo sin confundir el tiempo entre entrada y confirmación, un observador exclusivamente del test toma posición y velocidad con prioridad−11, inmediatamente antes del gestor−10. Ambas permanecen exactamente iguales al emitirse la confirmación, antes del paso del Player. La primera versión del comprobador comparaba contra el instante de entrada y detectó ese paso natural como una discontinuidad; se corrigió la instrumentación del test, sin cambiar producción ni físicas.

Después del recorrido principal se confirma físicamente R1 en Pasado y su descenso one-way. F0 sostiene al Player en ambos estados. R2 conserva apoyo al alternar. P1 y T1 retiran el apoyo al desactivarse, con gravedad y aterrizaje normales. No se detectó atrapamiento causado por Shift en los casos ensayados. Las molduras y límites siguen exactamente como en C; no se afirma que todas las secuencias posibles de inputs estén exploradas.

## Escenarios aislados de ocupación

Separados explícitamente del recorrido continuo, con física del Player pausada:

- Presente, Player en(780,490), velocidad(75,−20): T1 de destino solapa el cuerpo; Pasado se rechaza.
- Pasado, Player en(580,490), velocidad(−75,20): P1 de destino solapa el cuerpo; Presente se rechaza.
- Pasado, pies exactamente enY500, centro(580,480): el contacto de borde sin penetración permite volver a Presente y limpia el feedback anterior.

Los dos rechazos conservan exactamente posición y velocidad y no consumen cooldown ni protección. El test no considera estas colocaciones prueba de un salto o aterrizaje. En la traza su apoyo se identifica como `fixture_physics_paused`, para no confundir la información de suelo almacenada antes de reposicionar con un contacto nuevo.

La traza JSON registra posición, velocidad, dimensión, recarga, protección/restante, plataforma de contacto, fotograma, aceptación/rechazo y tiempos de vuelo. Hay11 confirmaciones y2 rechazos de ocupación por ejecución completa, además de pulsaciones ignoradas por falta de Lente, cooldown y derrota.

## Cámara y HUD

La cámara de C no se modificó: instancia heredada única, centro fijo(640,360), sin suavizado, límites1280×720 y ajuste al viewport lógico. En cada confirmación se comparan transformación, zoom, límites, viewport, centro y posición del HUD con la instantánea inicial. No se detectaron desplazamientos al alternar.

Se mantienen los valores observados en C: a1280×720, viewport lógico1152×648, zoom local0,90 y escala efectiva1,00; a1024×572, viewport lógico1160×648, zoom local0,90625 y escala efectiva horizontal0,80. No se alteró stretch, Player.tscn ni `project.godot`.

CombatHUD y TemporalLensHUD son los originales. Se comprueban disponibilidad e iconos en ambas dimensiones, protección real, recarga posterior, feedback de rechazo, salud de tres células, daño y derrota. La pérdida de vida usa únicamente las conexiones heredadas de `room2.gd`, sin duplicarlas.

## Pruebas y regresiones

La batería solicitada se ejecutó secuencialmente, a60fps fijos, en el orden indicado. Los scripts anteriores permanecen intactos:

| Prueba | Resultado |
|---|---|
| `room5_base_test.gd` | **FAIL histórico:3 de70**;67 PASS. Exige tres condiciones exclusivas de C que D sustituye explícitamente. |
| `room5_dimension_test.gd` | **PASS:153 comprobaciones**, salida0,11 cambios y2 rechazos |
| `room4_dimension_test.gd` | **PASS**, salida0; incluye ruta histórica de Room1 |
| `room4_route_test.gd` | **PASS**, salida0; tres idas y vueltas,6 cambios por intento y comprobaciones de ápice |
| `room4_fall_recovery_test.gd` | **PASS**, salida0 |
| `temporal_shift_protection_test.gd` | **PASS**, salida0 |
| `temporal_lens_hud_dynamic_test.gd` | **PASS**, salida0 |
| `validate.gd` | **PASS**, salida0 y validación de sintaxis exitosa |

Los tres fallos de la prueba histórica son exactamente: Lente neutral sin gestor, Shift sin alternancia y ausencia de DimensionManager. Son incompatibles con la funcionalidad autorizada en D. No se cambiaron expectativas, se ocultó el gestor ni se desactivó Shift para conseguir un verde artificial. Su salida completa está en [room5_base_stage_c_on_stage_d.json](../artifacts/room5_stage_d/room5_base_stage_c_on_stage_d.json). El mantenimiento de esa prueba para el contrato de D queda identificado como pendiente; no es un fallo de los67 controles físicos restantes.

Las ejecuciones con GPU a1024×572 y1280×720 pasan **167 comprobaciones cada una**, incluidas14 comprobaciones de tamaño/guardado de sus siete capturas. Tras aclarar en las trazas la etiqueta de los escenarios pausados, se repitió la prueba nueva y sus renders secuencialmente; no se amplió la batería compartida por un cambio exclusivo de instrumentación. El validador volvió a pasar al final.

Room4 route emitió al cerrar `3 ObjectDB instances were leaked` y `1 resources still in use`, con salida0. `ROOM4_STAGE_H.md` y `TEMPORAL_SHIFT_PROTECTION.md` ya documentan diagnósticos de limpieza en estas suites. No se modificaron Room4 ni sistemas compartidos; no se atribuye este aviso a la nueva integración ni se declara resuelto. No se realizó un ensayo largo de memoria ni revisión auditiva.

Detalles, códigos de salida, aserciones fallidas, diagnósticos y rutas/hashes de logs: [regression_results.json](../artifacts/room5_stage_d/regression_results.json). Los tres informes `results_*.json` contienen todas las aserciones y trazas de Room5.

## Capturas reales

Renders del Viewport de Godot4.7.2, Forward+ / D3D12 en NVIDIA GTX1660SUPER. Son14 imágenes: siete estados por resolución. No son prototipos externos. Los estados combinan los diez objetivos visuales solicitados sin duplicar vistas equivalentes.

| Estado |1024×572 |1280×720 |
|---|---|---|
| Presente inicial, P1 sólida y T1 fantasma |[PNG](../artifacts/room5_stage_d/01_present_ready_1024x572.png) |[PNG](../artifacts/room5_stage_d/01_present_ready_1280x720.png) |
| Pasado activo, T1 sólida, P1 fantasma y protección HUD |[PNG](../artifacts/room5_stage_d/02_past_protected_1024x572.png) |[PNG](../artifacts/room5_stage_d/02_past_protected_1280x720.png) |
| Recarga posterior a protección |[PNG](../artifacts/room5_stage_d/03_past_recharge_1024x572.png) |[PNG](../artifacts/room5_stage_d/03_past_recharge_1280x720.png) |
| Player sobre P1 |[PNG](../artifacts/room5_stage_d/04_present_P1_1024x572.png) |[PNG](../artifacts/room5_stage_d/04_present_P1_1280x720.png) |
| Cambio en el aire |[PNG](../artifacts/room5_stage_d/05_air_shift_1024x572.png) |[PNG](../artifacts/room5_stage_d/05_air_shift_1280x720.png) |
| Player sobre T1 y Pasado disponible |[PNG](../artifacts/room5_stage_d/06_past_T1_1024x572.png) |[PNG](../artifacts/room5_stage_d/06_past_T1_1280x720.png) |
| Rechazo por ocupación, escenario aislado |[PNG](../artifacts/room5_stage_d/07_rejected_1024x572.png) |[PNG](../artifacts/room5_stage_d/07_rejected_1280x720.png) |

Se revisaron fondo y arquitectura sin saltos de origen, Shared estable, superficies exclusivas y fantasmas correctos, Player visible, HUD fijo y ausencia de franjas negras externas. El Presente conserva el ambiente oscuro original; el Pasado muestra las instalaciones azules ya preparadas en C.

## Respaldos, aislamiento y conservación

Antes de editar se respaldaron ambos archivos requeridos en `C:/Users/juans/chrono-shift-backups/room5_stage_d_20261116_144906/`, con comparación SHA-256 contra origen y manifiesto propio:

| Archivo | SHA-256 del respaldo previo |
|---|---|
| `scenes/Room5.tscn` | `343e2f592969b7c72d69a485355c6162351df1a58d616f82bc0d487942c865ac` |
| `scripts/rooms/room5.gd` | `4d5cb918b108811cdd6edbc09fba33afb886089522857e699c307363c20c8541` |

El controlador conserva ese hash también al terminar. Se registraron1540 archivos preexistentes fuera de `.godot`/`.git`. La comparación final admite únicamente el cambio de Room5.tscn, y además compara todas sus secciones anteriores: permanecen intactas; solo se añadieron las tres secciones indicadas. Se conservan PNG originales, derivados, escenas anteriores, Player, GameManager, DimensionManager, GameProgress, HUD, cámara, pruebas anteriores, documentos anteriores, configuraciones y credenciales.

MCP inicial: Room5, escena2452426399980, revisión10063650:0:1, detenida y sin cambios pendientes. Tras la edición en disco se recargó mediante MCP con comprobación de identidad/revisión y sin guardar la escena ni recursos externos. La nueva identidad es2488614858525; el editor continúa detenido y `unsaved=false`.

Las regresiones se ejecutaron en `phase_d_work/runtime_project`: archivos raíz copiados sin cambios, directorios de recursos mediante junctions de lectura durante la ejecución y directorio de artefactos independiente. Así el test histórico puede escribir su informe sin sobrescribir las evidencias de C. No se abrió ese espejo en modo editor ni se lanzó importación sobre él. Los renders nuevos utilizaron el proyecto real y escribieron exclusivamente en el directorio nuevo de D.

Cada ejecución utiliza APPDATA propio fuera del proyecto, bajo `phase_d_work/profiles/phase_c_work/`; los nombres satisfacen también la guardia histórica de C. El test dimensional exige un perfil que contenga `phase_d_work`. No llama a adquisición ni guardado de progreso, y comprueba que no aparece `progress_v1.json` en su perfil. Se verifican aparte los hashes de los dos archivos reales de guardado, sin cambios. Las regresiones antiguas pueden guardar únicamente en sus propios perfiles aislados.

La ruta de AGENTS en Downloads resulta ser un **directorio** llamado `Godot_v4.7.2-stable_win64.exe`, no un ejecutable. Se utilizó `C:/Godot/godot.exe.exe`, versión4.7.2.stable.official.ed1daf0bf, para ejecutar el mismo `tests/validate.gd`. No se corrigió AGENTS ni se reinstaló/reconfiguró ningún servicio.

Archivos de implementación: modificado `scenes/Room5.tscn`; creados `tests/room5_dimension_test.gd` y este documento. Evidencias nuevas en `artifacts/room5_stage_d/`:14PNG, tres informes dimensionales, informe histórico, resumen de regresiones y verificación. Un UID nuevo, si lo genera el editor, consta como metadato en el catálogo. No hay cambios en scripts de producción.

La verificación completa, catálogo de creaciones, hashes, comprobación de respaldos, originales y guardados están en [verification.json](../artifacts/room5_stage_d/verification.json). Helpers y logs externos: `C:/Users/juans/.codex/visualizations/2026/11/16/01a1e570-850c-7a83-8965-7511f3d3ed84/phase_d_work/`. Sus scripts auxiliares `backup_room5_stage_d.py`, `run_room5_stage_d.ps1` y `verify_room5_stage_d.py` se conservan en el directorio padre. El respaldo nunca se sobrescribe.

## Pendientes para autorización posterior

La alternancia está integrada sin necesitar al Guardián. No se avanzó a E. La futura etapa deberá partir de esta matriz y mantener las APIs de cooldown/protección, revisar ocupación con el volumen real del jefe y decidir cómo abordar las molduras y accesos cuando corresponda. No se implementaron esas decisiones.

Queda pendiente adaptar explícitamente la prueba base histórica al nuevo contrato dimensional, preservando sus controles de física, geometría y cámara; el test nuevo ya cubre el contrato de D. Permanecen las limitaciones de C respecto a relaciones de aspecto diferentes de las dos ensayadas y la falta de una política definitiva de salida/caída. No se investigaron aquí los avisos de limpieza antiguos ni se evaluó combate final o balance con jugadores.
