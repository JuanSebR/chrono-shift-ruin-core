# Sala 5 — Fase H.2: paquete de arco fijado

Implementación controlada en Godot 4.7.2, 2026-11-16. El segundo ataque está disponible mediante `CoreGuardian.request_arc()`. No se dispara al entrar en Room5 ni selecciona ataques automáticamente. La vulnerabilidad del núcleo continúa siendo explícita; no hay fases nuevas, BossHUD, selector ni victoria.

## Recursos y propiedad de la acción

Se reutilizan los seis cuadros originales de `attack3_atlas.png`, los landmarks de `room5_stage_a_manifest.json`, la celda de 64×64 de `beam_hold_atlas.png` y las seis celdas de `beam_finish_atlas.png`. No se crearon ni sobrescribieron imágenes jugables. El fragmento Hold tiene una banda visible aproximada de 64×32; escala uniforme 0,75 produce aproximadamente 48×24. Finish usa la misma escala.

El controlador del Guardián posee el único reloj ofensivo, `beam_elapsed`, reutilizado durante el arco. El hijo local ArcAttack recibe edad absoluta desde ese reloj, dibuja el aviso y gestiona la única entidad EnergyPacket. No tiene Timer, reloj físico independiente, selección de ataque ni callbacks diferidos de disparo. El SpriteFrames de Attack3 se conserva separado y se sustituye temporalmente durante la acción: las seis animaciones base y su recurso se restauran al volver a reposo.

## Secuencia y tiempos

| Estado | Comportamiento |
|---|---|
| IDLE | Solo acepta una petición controlada con jefe y Player vivos y DimensionManager válido. |
| CANNON_AIM | 1,00 s: seguimiento inicial 0,25 s y objetivo fijo durante los 0,75 s restantes. Pose 0 durante 0–0,40 s y pose 1 durante 0,40–1,00 s. |
| CANNON_RELEASE | Pose 2 al emitir; pose 3 después de 0,125 s de vuelo. |
| CANNON_SETTLE | Pose 4 a los 0,250 s y pose 5 a los 0,375 s. Sostiene la última pose mientras siga viajando o disipándose el paquete. |
| RECOVER | Empieza después de completar al menos 0,50 s de secuencia corporal y terminar la disipación. Espera otros 0,40 s; vuelve a IDLE. |
| DEFEATED | Cancela aviso y paquete, cierra núcleo y conserva la animación terminal existente. |

El identificador creciente `arc_execution_id`, el flag de emisión del controlador y `last_emitted_id` del componente impiden disparos repetidos. Se emite exclusivamente al entrar en pose 2, nunca también en pose 3. Todas las poses son las seis originales; no se interpola ni deforma el cuerpo para inventar poses.

El arco rechaza solicitudes durante haz, arco, Intro, Vulnerable, Recover y Defeated. El haz también rechaza solicitudes durante el arco. Las peticiones inválidas no cancelan ni sustituyen la acción vigente. No se abre CoreWeakpoint al finalizar.

## Orientación, anclaje y objetivo

La orientación se elige al iniciar: Player con X menor o igual a la del jefe → izquierda; mayor → derecha. Permanece fija durante toda la ejecución, aunque el Player cruce el cuerpo. Al cancelar o terminar se restaura el espejo izquierdo seguro de Repose. El jefe continúa en (1070,620), con escala corporal uniforme 0,375 y atlas normalizado de 640×800.

El origen se transforma desde el landmark `muzzle_atlas_estimate` de pose 2 mediante espejo del ancho del atlas, posición del sprite y transformación global de VisualRoot. Valores confirmados en Godot:

| Orientación | P0 mundial, unidades |
|---|---|
| Izquierda | (1018,106375; 537,2765) |
| Derecha | (1121,893625; 537,2765) |

Se captura P0 al emitir y queda inmutable. El retroceso del cañón no desplaza el paquete. El núcleo usa su propio landmark con la misma transformación de espejo; la región física no se amplía y su matriz de daño conserva las condiciones anteriores. El origen del haz sigue siendo (980,512).

El objetivo proviene del centro mundial del CollisionShape2D real del Player: X limitado a 80–1200, Y física completa. Durante los primeros 0,25 s se vuelve a muestrear; después queda congelado aunque el Player se mueva, salte, aterrice o haga Shift. La prueba incluye seguimiento por movimiento real y fijación durante un salto real. Las colocaciones sobre plataformas y en los bordes son fixtures independientes, no recorridos continuos.

## Aviso y efecto provisional

El aviso utiliza pequeñas regiones luminosas de Hold: ruta discontinua, tres marcas cortas al seguir y esquinas cortas al quedar fijado. Los textos FIJANDO/FIJO distinguen ambos momentos. Cinco pequeños indicadores de carga muestran el avance hacia la emisión. No existe consulta ofensiva durante este aviso.

La ruta termina en la altura real del objetivo, no en una proyección artificial sobre el suelo. El efecto usa z-index local 2 sobre el jefe de z-index −1: queda delante de las plataformas y del Player. La cámara y el HUD son los existentes, sin modificaciones. Las capturas verifican la lectura en Presente rojo y Pasado azul, a 1024×572 y 1280×720.

La banda blanca/magenta resulta identificable pero rectangular: sigue pareciendo un fragmento de haz. Es arte provisional, no un proyectil final ni una explosión. Finish se reproduce durante 0,30 s en el punto de consumo, sin nueva área ofensiva. El giro sigue la tangente de la trayectoria; sprite y centro ofensivo comparten posición. No hay estela dañina.

## Trayectoria

P0 = boca al emitir; P1 = P0 + (60 × orientación, 0); P2 = centro fijado. Para u limitado a 0–1:

`B(u) = lerp(lerp(P0,P1,u), lerp(P1,P2,u), u)`

`T = max(0.45, 2 * max(distance(P0,P1), distance(P1,P2)) / 1400)`

La trayectoria es una curva diseñada determinista; no usa gravedad, rebotes ni seguimiento. La edad se divide entre T y se limita a 1. Los casos extremos alcanzan aproximadamente 1,26 s; los cercanos al lado derecho utilizan el mínimo de 0,45 s. No se retocaron estos parámetros para hacer pasar la evasión.

## Colisión y daño real

Collider ofensivo: círculo de radio 8, contenido dentro de la banda visual de 48×24. Cada intervalo recorre desde la posición anterior a la siguiente. Se subdivide la curva con una cota de longitud de 4 unidades por segmento y se consulta el volumen completo de cada segmento; no se evalúa únicamente la posición final.

Primero se comprueba solapamiento inicial del círculo. Después una cápsula con radio 8 y altura igual a longitud del segmento +16 identifica candidatos dentro del volumen barrido exacto. `cast_motion` del círculo calcula la primera fracción de contacto para los cuerpos válidos; se excluyen otros cuerpos de la capa. La cápsula representa el barrido, no una ampliación de la hitbox del paquete. La comprobación inicial es necesaria porque `cast_motion` ignora los cuerpos ya solapados, según la [API oficial PhysicsDirectSpaceState2D](https://docs.godotengine.org/en/stable/classes/class_physicsdirectspacestate2d.html).

Solo se consideran cuerpos CharacterBody2D vivos del grupo `core9_player`, en capa 2; las áreas y plataformas quedan fuera de la consulta. No se cambia ninguna colisión del escenario. El paquete atraviesa F0 y las plataformas superiores cuando su ruta las cruza, sin empujar al Player.

En el primer contacto se invoca `Player.take_damage(1)` una sola vez y se consume el paquete. Se detiene en la fracción de impacto, disipa y se libera. Incluso si la invulnerabilidad ordinaria o temporal rechaza el daño, queda consumido: no permanece esperando a que expire la protección. Al terminar la trayectoria sin contacto se aplica la misma disipación sin daño radial.

## Dimensiones y limpieza

El paquete puede impactar en Presente y Pasado. No consulta la regla de inmunidad de Pasado específica del haz. Un Shift válido conserva objetivo, ID, origen y edad de vuelo; la protección real de 0,16 s puede rechazar el contacto y el paquete se consume. Un Shift rechazado no concede protección, no cambia dimensión ni cancela el arco.

`cancel_arc()` limpia la preparación, el vuelo o la disipación y restaura IDLE seguro. La derrota llama la misma limpieza antes de la animación terminal. La liberación del jefe/Room5 elimina el sprite hijo y su aviso; no hay timers, señales de disparo pendientes ni objetos independientes persistentes. Una instancia nueva comienza sin peligro heredado. No se escribe progreso ni victoria.

## Pruebas y resultado de evasión

La prueba nueva `tests/core_guardian_arc_test.gd` realiza 57 comprobaciones físicas sin render. Usa Player, Damage e invulnerabilidades reales. Los contactos sobre F0/R1/R2/P1/T1, ambos extremos y proximidad a ambos lados del jefe son fixtures independientes. Para situarse en X80 o X1200 se desactiva únicamente en la instancia de prueba el área de transición: el archivo de transición y las escenas de producción no se modifican. Esto no acredita una ruta continua desde Room4 ni una evasión saliendo por su puerta.

Incluye los 36 grupos de requisitos H.2: seis poses, aviso inocuo, seguimiento/fijación, origen y espejo, emisión única, curva/duración, barrido con ambos extremos fuera del collider, impactos y protecciones, exclusividad, defensa del núcleo, cancelación/derrota, liberación de escena, convivencia con haz y ausencia de automatismos. La regresión base comprueba además espada real y matriz defensiva del núcleo.

Evasiones con Input y movimiento/salto físicos existentes, sin recolocar al Player durante el ensayo:

| Inicio en F0 | Correr hacia el centro después de fijar | Saltar cerca de la llegada |
|---|---|---|
| X600 | Sin daño | Sin daño; salto iniciado aproximadamente T−0,28 s después de emitir. |
| X140 | **Recibe 1 punto** al cruzar la curva | Sin daño; mismo criterio T−0,28 s. |
| X1180 | Sin daño | Sin daño al iniciar aproximadamente T−0,50 s; el salto tardío T−0,28 s recibe daño. |

La limitación izquierda es reproducible: contacto cerca de (509,145;571,999), a 0,8833 s de vuelo sobre T≈1,17215 s. El Player que corre hacia el centro cruza por debajo del paquete antes de que llegue al objetivo antiguo; el borde superior de su cuerpo toca el círculo. La prueba marca explícitamente esta limitación esperada, no la registra como evasión lograda. El salto ofrece una salida física allí. En la derecha, el cañón cercano cruza antes la subida del salto; se requiere anticiparlo, no esperar al último instante.

Por tanto, no es inevitable en los tres puntos ensayados, pero **no se declara que toda salida lateral sea segura ni que el ataque esté equilibrado**. No se aumentaron velocidades, aviso ni salto para ocultar el problema. Antes de activar IA conviene playtest de lectura y reacción, incluido margen de salto derecho y trayectorias intermedias. Estas pruebas no estiman tasas humanas de éxito ni cubren todas las posiciones continuas.

### Regresiones secuenciales

| Prueba | Resultado |
|---|---|
| core_guardian_base_test | 30/30 |
| core_guardian_beam_test | 29/29 |
| core_guardian_arc_test | 57/57, incluida la limitación lateral declarada |
| room5_base_test | 71/71 |
| room5_dimension_test | 153/153 |
| room4_room5_transition_test | Sin fallos |
| attack12_test | Sin fallos |
| temporal_shift_protection_test | Sin fallos |
| validate | Validación de sintaxis exitosa |

Ejecución con reloj fijo a 60 fps y perfiles APPDATA externos aislados; los guardados reales no se usan como perfil de ejecución. Las pruebas históricas escriben en el espejo externo ya existente, preservando sus evidencias anteriores. Los renders se ejecutan sobre este proyecto real. El ejecutable verificado es `C:/Godot/godot.exe.exe`; la ruta histórica indicada en AGENTS es un directorio y no se reconfigura.

Todos los procesos y aserciones se registran en `artifacts/room5_stage_h2/logs/` y `verification.json`. Persisten avisos de cierre ObjectDB/recursos en algunas pruebas históricas, también observados en F/G; no son errores de compilación ni se declaran corregidos. Los logs conservan íntegros esos avisos. La prueba nueva se comprueba tanto sin render como en las dos resoluciones.

## Capturas reales de Godot

Los PNG proceden de la textura del viewport Godot, sin montaje ni retoque. La numeración 14–16 agrupa pruebas de orientación/aviso adicionales. El mismo estado de salto puede salvarse en pasos consecutivos sobre su nombre; la evidencia final es un único PNG por estado y resolución.

| Estado | 1024×572 | 1280×720 |
|---|---|---|
| Repose, comparación de altura | [PNG](../artifacts/room5_stage_h2/01_idle_Repose_1024x572.png) | [PNG](../artifacts/room5_stage_h2/01_idle_Repose_1280x720.png) |
| Seguimiento, pose0 | [PNG](../artifacts/room5_stage_h2/02_tracking_Attack3_pose0_1024x572.png) | [PNG](../artifacts/room5_stage_h2/02_tracking_Attack3_pose0_1280x720.png) |
| Fijación, pose1 | [PNG](../artifacts/room5_stage_h2/03_fixed_pose1_1024x572.png) | [PNG](../artifacts/room5_stage_h2/03_fixed_pose1_1280x720.png) |
| Emisión, pose2 | [PNG](../artifacts/room5_stage_h2/04_release_pose2_1024x572.png) | [PNG](../artifacts/room5_stage_h2/04_release_pose2_1280x720.png) |
| Vuelo y retroceso | [PNG](../artifacts/room5_stage_h2/05_flight_pose3_1024x572.png) | [PNG](../artifacts/room5_stage_h2/05_flight_pose3_1280x720.png) |
| Aproximación a F0 | [PNG](../artifacts/room5_stage_h2/06_cerca_F0_1024x572.png) | [PNG](../artifacts/room5_stage_h2/06_cerca_F0_1280x720.png) |
| Contacto ofensivo | [PNG](../artifacts/room5_stage_h2/07_contacto_real_F0_1024x572.png) | [PNG](../artifacts/room5_stage_h2/07_contacto_real_F0_1280x720.png) |
| Disipación | [PNG](../artifacts/room5_stage_h2/07b_disipacion_1024x572.png) | [PNG](../artifacts/room5_stage_h2/07b_disipacion_1280x720.png) |
| Evasión mediante salto | [PNG](../artifacts/room5_stage_h2/08_evasion_salto_F0_1024x572.png) | [PNG](../artifacts/room5_stage_h2/08_evasion_salto_F0_1280x720.png) |
| Vuelo en Pasado y Shift | [PNG](../artifacts/room5_stage_h2/09_Pasado_proteccion_1024x572.png) | [PNG](../artifacts/room5_stage_h2/09_Pasado_proteccion_1280x720.png) |
| Contacto protegido | [PNG](../artifacts/room5_stage_h2/10_contacto_protegido_disipacion_1024x572.png) | [PNG](../artifacts/room5_stage_h2/10_contacto_protegido_disipacion_1280x720.png) |
| Recover, pose5 | [PNG](../artifacts/room5_stage_h2/11_recover_pose5_1024x572.png) | [PNG](../artifacts/room5_stage_h2/11_recover_pose5_1280x720.png) |
| Cancelación explícita | [PNG](../artifacts/room5_stage_h2/12_cancelado_1024x572.png) | [PNG](../artifacts/room5_stage_h2/12_cancelado_1280x720.png) |
| Derrota y cancelación | [PNG](../artifacts/room5_stage_h2/13_derrota_cancelacion_1024x572.png) | [PNG](../artifacts/room5_stage_h2/13_derrota_cancelacion_1280x720.png) |
| Aviso hacia derecha | [PNG](../artifacts/room5_stage_h2/14_derecha_aviso_1024x572.png) | [PNG](../artifacts/room5_stage_h2/14_derecha_aviso_1280x720.png) |
| Emisión hacia derecha | [PNG](../artifacts/room5_stage_h2/15_derecha_emision_1024x572.png) | [PNG](../artifacts/room5_stage_h2/15_derecha_emision_1280x720.png) |
| Aviso fijo en Pasado | [PNG](../artifacts/room5_stage_h2/16_aviso_Pasado_1024x572.png) | [PNG](../artifacts/room5_stage_h2/16_aviso_Pasado_1280x720.png) |

## Problemas artísticos y siguiente etapa

Repose → Attack3 baja perceptiblemente la silueta superior unos 64 píxeles/unidades a esta escala. Se conserva el anclaje original a los pies: no se oculta mediante escala no uniforme ni desplazando al jefe. La comparación de reposo/pose0 muestra esa discontinuidad. El espejo derecho cubre al Player detrás del cuerpo, pero cambia bruscamente su lectura al iniciar/terminar; no se inventó una animación de giro. La posición física del núcleo acompaña su landmark y sigue cerrada durante el ataque.

El paquete rectangular y las marcas finas requieren revisión artística y de accesibilidad antes del combate automático. No se añade arte alternativo sin autorización. Balance pendiente: rutas de cruce izquierda, ventana de salto derecha, reacciones humanas y uso cerca de plataformas/cuerpo. Una fase posterior debe decidir estos ajustes y las aperturas/selección; H.2 no los activa.

## Archivos, respaldo e integridad

Únicos archivos preexistentes modificados:

- `scenes/bosses/CoreGuardian.tscn`: nueva referencia de script y hijo ArcAttack; se conservan las secciones anteriores.
- `scripts/bosses/core_guardian.gd`: estados locales, orientación, API controlada, reloj compartido, transformación de landmarks y limpieza.

Nuevos: `scripts/bosses/guardian_arc.gd`, `tests/core_guardian_arc_test.gd`, este documento y evidencias en `artifacts/room5_stage_h2/` (más metadatos UID/importación que genere el editor para los nuevos recursos).

Respaldo previo con SHA-256 verificado: `C:/Users/juans/chrono-shift-backups/room5_stage_h2_20261116_163932/`, incluyendo `hashes.json`. Helpers, línea base y perfiles: `C:/Users/juans/.codex/visualizations/2026/11/16/01a1e570-850c-7a83-8965-7511f3d3ed84/phase_h2_work/` y su directorio padre.

La comparación final en `verification.json` coteja los archivos anteriores, las secciones de la escena, el respaldo y los dos guardados reales. `guardian_beam.gd` permanece idéntico byte a byte. Se preservan Player, DimensionManager, GameProgress, GameManager, Room4/Room5, HUD, transiciones, Enemy1, cámara, plataformas, física, atlas y configuraciones. No se escriben memorias ni credenciales.

El editor fue inspeccionado antes de editar: Room5 guardada, juego detenido y puente MCP protocolo4 conectado. La recarga posterior de la escena guardada confirmó Room5 detenida y sin cambios pendientes. El trabajo termina en H.2; la siguiente etapa requiere autorización independiente.
