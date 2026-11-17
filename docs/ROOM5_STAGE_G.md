# Sala 5 — Fase G: prototipo controlado del haz de energía

16 de noviembre de 2026. Se implementó exclusivamente el primer ataque del Guardián, invocable con `request_beam()`. Room5 sigue cargando al jefe pasivo. No hay selección de ataques, bucle ofensivo, encuentro automático, BossHUD, música nueva, otros ataques ni victoria.

**Decisión explícita del usuario durante esta fase:** «Haz peligroso solo en Presente; Pasado permite evadirlo». Esta regla pertenece a este haz y no declara Pasado seguro frente a todo el repertorio futuro. RF-05 del GDD permanece intacto: el jefe recibe daño únicamente en Presente y con núcleo expuesto.

## Diagnóstico previo del arte

Se aplicó godot-gamedev y se consultaron AGENTS, GDD, diseño del jefe, informes A/B/F, manifiesto, scripts del Player/Guardián y estado MCP. No se repitió el inventario de salas. El editor estaba en Room5, detenido, `unsaved=false`, escena2554901638544, revisión10063650:0:1. Los originales y atlas se inspeccionaron sin regenerarlos.

| Recurso A | Tamaño atlas / celda | Contenido medido |
|---|---|---|
| beam_start_atlas |2304×192 /384×192 |6 poses; grosor opaco central8,23,43,78,119,150px |
| beam_hold_atlas |64×64 /64×64 |1 segmento horizontal, banda opaca Y16–48,32px; bordes laterales idénticos |
| beam_finish_atlas |384×64 /64×64 |6 poses; grosor32,20,8,3,1,0px; última celda vacía |

Eje horizontal. Start usa centroY96; hold/finish,Y32. El hold coincide con la primera pose de finish y permite repetición sin uniones diferentes entre extremos. Start incluye márgenes/caps que dejarían huecos si se repitiera toda la celda; no se utilizó ese método defectuoso.

La comparación nativa evidencia el salto150→32. Se resolvió mediante composición de regiones existentes, sin crear ni sobrescribir un PNG jugable: Start usa la franja central X160–224 de cada celda, con escala uniforme0,20; Hold/Finish usan celdas completas con escala uniforme0,9375. Así el crecimiento llega a30 unidades de grosor, igual al sostén. Las regiones se repiten horizontalmente; la última se recorta en vez de estirarse. No hay escalas X/Y independientes.

Se conservan las bandas de color de crecimiento; al activarse, el sostén se vuelve una banda blanca más uniforme, tal como está dibujado. Este cambio de luminosidad permanece visible y se considera parte provisional de la activación, no continuidad artística definitiva. No se inventó una tapa emisora ni otro sprite. La franja central evita repetir los caps de cada celda; el extremo occidental termina enX80 y el oriental se une al cañón.

[Comparación diagnóstica del arte](../artifacts/room5_stage_g/diagnostic_art_comparison.png) — imagen externa de análisis rotulada, **no render jugable**. [Mediciones](../artifacts/room5_stage_g/beam_measurements.json). Las capturas de estado listadas más abajo sí proceden del viewport real.

## Arquitectura, emisor y estados

```text
CoreGuardian                         controlador y único reloj físico
├── VisualRoot/AnimatedSprite2D       Repose0 congelada durante la emisión
├── CoreWeakpoint                    región defensiva existente, intacta
└── BeamAttack                       Node2D, guardian_beam.gd
```

El componente local carga tres atlas una vez, dibuja sus regiones y ejecuta una consulta física solo cuando el controlador lo solicita. No añade un Area2D registrado, timer ni otra máquina de estados. Esto mantiene las identidades y cantidades de colliders de la arena y evita un área ofensiva persistente después de cancelar.

El controlador conserva IDLE, INTRO, VULNERABLE, RECOVER y DEFEATED con sus valores anteriores y añade BEAM_PREPARE, BEAM_GROW, BEAM_ACTIVE y BEAM_FINISH. Una única variable de tiempo físico gobierna la secuencia; no hay relojes visuales que decidan daño.

Repose0 registra muzzle(560,432) en la celda normalizada, anclaje(320,720). El espejo y escala0,375 dan offset local(−90,−108). Con pies(1070,620), el emisor queda en **(980,512)**. Se congela esa pose para evitar que el pulso de reposo desplace el cañón. El cuerpo no se mueve ni cambia de escala. Después se reanuda Repose.

El haz sale hacia izquierda, la orientación ilustrada y configurada del jefe situado al este del Player. No hay autoapuntado, rotación del arma ni persecución cuando el Player pasa detrás. Esta limitación debe revisarse al diseñar el encuentro completo.

## Parámetros provisionales

| Fase | Parámetro exportado | Tiempo nominal | Daño |
|---|---|---:|---|
| Preparación |beam_prepare_time |0,50s |No; primera pose fina de Start |
| Crecimiento |beam_grow_time |0,60s |No; poses1–5 de Start |
| Sostén |beam_active_time |0,50s |Sí en Presente; Hold |
| Disipación |beam_finish_time |0,50s |No; Finish0–5 incluida celda vacía |
| Recuperación |beam_recover_time |0,40s |No; efecto oculto |

Longitud exportada900 unidades y daño exportado1. Duración nominal total2,50s; cada frontera se resuelve en un paso físico, con cuantización de aproximadamente1/60s. No es balance definitivo.

Solo IDLE puede iniciar el haz. Se rechazan solicitudes simultáneas, durante intro, vulnerabilidad, ejecución, recuperación o derrota. La vulnerabilidad controlada y otras animaciones de diagnóstico no interrumpen el haz ni exponen el núcleo. Tras recuperar, se vuelve una sola vez a IDLE y no se solicita otro ataque automáticamente.

## Geometría ofensiva y evasión

Con los valores predeterminados, el tramo visible va deX80 a980, ejeY512. Grosor máximo≈30, banda visible≈Y497–527. La región de daño es un RectangleShape2D local de **900×24**, centro mundial(530,512): **X80–980, Y500–524**, dentro de la zona luminosa. No incluye toda la imagen ni se agranda hasta el suelo.

Se consulta el mundo físico con máscara2, cuerpos activados y áreas desactivadas. Solo cuerpos del grupo core9_player reciben `take_damage(beam_damage)`. No se usa CoreWeakpoint como hitbox ofensiva ni se modifica Player. No hay un collider ofensivo permanente que pueda quedar monitorizando.

El Player en F0 ocupa aproximadamenteY580–620 y puede permanecer debajo. En R1 su collider ocupaY520–560: se superpone cuatro unidades con la región ofensiva. También puede entrar en esa altura durante un salto desde F0. P1 se sitúa junto al borde superior; los bordes exactos dependen de márgenes físicos y trayectoria, y no se declara que cada plataforma sea un refugio o amenaza definitivos.

El test coloca al Player real sobre R1, deja que se estabilice con gravedad y comprueba el impacto por intersección real. Los fixtures son estados iniciales controlados de daño, no recorridos continuos desde la entrada. Se comprueban además una posición a la derecha del emisor y F0 bajo la línea: no reciben daño. No se desplazó el cañón ni se alteró el arte o física para forzar daño a todo el suelo.

## Dimensión, protección y cancelación

Solo BEAM_ACTIVE y `DimensionManager.active_dimension == PRESENT` ejecutan la consulta ofensiva. Shift aceptado o rechazado no modifica el reloj del haz, su origen ni su secuencia. Pasado conserva el efecto visible pero evita el daño, según la decisión aprobada para este ataque.

Player.take_damage continúa siendo la fuente de verdad. La descarga respeta sus60 pasos de invulnerabilidad por daño y el Timer real de protección temporal0,16s. Con sostén0,50s, la primera descarga contra el Player de R1 resta una sola célula. Una ventana configurable más larga puede volver a dañar después de expirar la invulnerabilidad normal; no se añadió inmunidad específica permanente al haz.

La prueba de protección usa Shift real: inicia el haz en Pasado, vuelve a Presente cerca del final de crecimiento y entra en la fase activa todavía protegido. El primer contacto se descarta; una vez terminada la protección, el haz aún activo puede causar daño. Otro fixture solapa T1 al solicitar Shift: el rechazo conserva Presente, no inicia protección ni recarga, y el haz puede golpearlo al activarse.

Se conserva la matriz defensiva del jefe: no recibe daño normal durante el haz porque no está en Vulnerable. Para probar cancelación por derrota se utiliza una asignación letal controlada de salud0, **no un tajo que atraviese un núcleo protegido**. En el siguiente paso físico el controlador confirma DEFEATED, cancela el reloj y oculta el haz antes de consultar daño. La rama normal de derrota por salud también utiliza esta misma cancelación. Las solicitudes posteriores son rechazadas y no queda efecto ni daño residual.

## Validación

`tests/core_guardian_beam_test.gd` verifica29 condiciones físicas, con Player, gestor, consultas de colisión, daño y Shift reales. No se valida el impacto únicamente llamando a take_damage en el test. Comprueba secuencia de estados completa, emisor estable, fases inocuas, daño activo, inmunidades, regiones excluidas, regla dimensional, solicitudes duplicadas, ausencia de repetición automática, recuperación y derrota.

La primera ejecución detectó un orden incorrecto de argumentos de draw_texture_rect_region en el componente nuevo; se corrigió antes de los resultados finales. No se modificaron recursos ni pruebas anteriores para ocultarlo.

| Prueba solicitada | Resultado final |
|---|---|
| core_guardian_base_test |PASS:30 comprobaciones |
| core_guardian_beam_test |PASS:29 comprobaciones físicas |
| room5_base_test |PASS:71 comprobaciones |
| room5_dimension_test |PASS:153 comprobaciones |
| room4_room5_transition_test |PASS, tres ciclos y recuperación posterior |
| attack12_test |PASS, incluida compatibilidad real con Enemy1 |
| temporal_shift_protection_test |PASS |
| validate |PASS, salida0 |

Ejecución secuencial, perfiles APPDATA individuales externos, reloj fijo60fps. No se modificó ninguna prueba anterior. Los renders de cada resolución pasan35 comprobaciones, incluidas sus seis capturas. Continúan algunos avisos de ObjectDB/recursos al cerrar; se conservan en logs separados de las aserciones y no se declaran resueltos.

## Capturas reales

Viewport Godot4.7.2, Forward+/D3D12, a1024×572 y1280×720. Doce imágenes de juego en `artifacts/room5_stage_g/`; la comparación adicional de arte está rotulada como diagnóstico externo.

| Estado |1024×572 |1280×720 |
|---|---|---|
| Reposo |[PNG](../artifacts/room5_stage_g/01_idle_1024x572.png) |[PNG](../artifacts/room5_stage_g/01_idle_1280x720.png) |
| Preparación |[PNG](../artifacts/room5_stage_g/02_prepare_1024x572.png) |[PNG](../artifacts/room5_stage_g/02_prepare_1280x720.png) |
| Crecimiento |[PNG](../artifacts/room5_stage_g/03_grow_1024x572.png) |[PNG](../artifacts/room5_stage_g/03_grow_1280x720.png) |
| Haz activo |[PNG](../artifacts/room5_stage_g/04_active_1024x572.png) |[PNG](../artifacts/room5_stage_g/04_active_1280x720.png) |
| Disipación |[PNG](../artifacts/room5_stage_g/05_finish_1024x572.png) |[PNG](../artifacts/room5_stage_g/05_finish_1280x720.png) |
| Recuperación |[PNG](../artifacts/room5_stage_g/06_recover_1024x572.png) |[PNG](../artifacts/room5_stage_g/06_recover_1280x720.png) |

La revisión confirma anclaje al cañón, ausencia de huecos entre segmentos, grosor compatible entre crecimiento final y sostén, Player visible y cámara/HUD intactos. Durante la emisión se superponen intencionalmente las plataformas atravesadas por el haz. No se considera final el contraste del aviso fino ni el cambio de iluminación al sostén; requieren playtest de lectura y accesibilidad antes de un encuentro automático.

## Archivos, respaldos e integridad

Modificados únicamente `scenes/bosses/CoreGuardian.tscn` y `scripts/bosses/core_guardian.gd`. Creados el componente local `scripts/bosses/guardian_beam.gd`, la prueba, este documento y evidencias. El componente se justifica para separar dibujo repetido/consulta física de los estados y del único reloj del Guardián.

Respaldos previos verificados: `C:/Users/juans/chrono-shift-backups/room5_stage_g_20261116_155657/`, con `hashes.json`. Se preservan todos los archivos de Room5, cámara, plataformas, transiciones, llave, progreso, Player, HUD, espada, gestores, Enemy1, originales y atlas. Los guardados reales se cotejan mediante hashes separados. No se toca el ZIP de transferencia ni memorias/configuraciones.

La verificación final, nuevos archivos y resultados están en `artifacts/room5_stage_g/verification.json`; los logs copiados se encuentran en su subdirectorio logs. Helpers y perfiles externos: `C:/Users/juans/.codex/visualizations/2026/11/16/01a1e570-850c-7a83-8965-7511f3d3ed84/phase_g_work/`. Las pruebas históricas escriben en un espejo externo para conservar las evidencias anteriores; los renders nuevos usan el proyecto real. El Godot ejecutable sigue siendo `C:/Godot/godot.exe.exe`; la ruta histórica de AGENTS es un directorio y no se reconfiguró.

## Recomendación posterior

Antes de ampliar el repertorio: probar si la línea fina anuncia el ataque con suficiente claridad, si F0 como evasión permanente resulta deseable, y si conviene otro patrón/pose aprobado para presionar el suelo. El haz actual no barre, no apunta diagonalmente y no persigue al jugador situado detrás del jefe. Revisar también feedback de seguridad dimensional y la transición de iluminación entre atlas. No generalizar la inmunidad de Pasado a otros ataques.

No se implementaron ataques adicionales, fases, BossHUD, música, bloqueo de puertas, activación automática ni derrota/victoria narrativa. El trabajo se detiene al terminar este primer ataque controlado.
