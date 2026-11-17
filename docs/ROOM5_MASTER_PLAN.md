# Sala 5 — Plan maestro para revisión

Fecha: 16 de noviembre de 2026. Estado: **PROPUESTA; ninguna fase A–L autorizada ni ejecutada**. Esta sesión únicamente produjo documentación y diagnósticos. Las coordenadas y valores de ajuste de este documento son candidatos, no datos de una escena existente.

## Fuentes y diagnóstico de continuidad

Se consultaron AGENTS.md, GDD v1.2, CODEX_HANDOFF_2026-11-16.md, STATE.md, ROOM4_STAGE_H.md y TEMPORAL_SHIFT_PROTECTION.md. La inspección de código se limitó a Player, espada, Enemy1, Room2/Room4, DimensionManager, GameProgress, LevelTransition y HUD temporal; no se repitió la investigación de las seis salas.

El editor respondió por MCP: proyecto `c:/users/juans/chrono-shift-ruin-core`, Room4, escena `1654334234622`, revisión `10063650:0:1`, protocolo 4, `playing=false`, `unsaved=false`. Esto acredita el estado de la escena activa, no la limpieza de todos los recursos externos en caché. No se guardó ni cambió de pestaña. Motor previamente verificado: `C:/Godot/godot.exe.exe`, 4.7.2.stable.official.ed1daf0bf. No se inició otra instancia del proyecto.

| Tema | GDD | Estado observado / consecuencia |
|---|---|---|
| Vulnerabilidad | RF-05: escudos en Pasado; daño solo en Presente con punto débil expuesto | Regla obligatoria del diseño propuesto; no ofrecer daño en ambas dimensiones como equivalente aprobado |
| Entrada | Llave de Acceso al Reactor, RF-04 | GameProgress no contiene llave. Bloquea E hasta aprobar su procedencia/obtención o una excepción explícita al GDD |
| Espada | Daño 1, espera 0,5 s | Código: cooldown 0,35 s y presentación 12/24 = 0,50 s; no son el mismo temporizador. Mantener código actual |
| Salto | Altura fija | El código reduce velocidad ascendente al soltar salto. Planificar con salto sostenido y comprobar también suelta temprana |
| Salas | Cinco salas principales y hub | Disco: seis escenas hasta Room4, con subdivisiones 1.5/2.2. Preservar progreso lineal existente |
| Guardado | Automático por sala / continuar último punto | v1 guarda posesiones, tutoriales y diálogos; Continuar vuelve a Room1.5 con espada. Victoria/Room5 no existen |
| Color | Presente cian, Pasado magenta en dirección artística | Room4 usa ambiente rojo/azul; Sala5 suministrada usa ruina roja, pasado industrial ámbar/cian, plataformas presentes magenta. No recolorear originales ni confundir color de plataforma con dimensión |
| Final / BossHUD | Final y créditos; barra inferior derecha | Conservar ambos compromisos; guion de cierre y disposición concreta requieren revisión |

El traspaso decía que los recursos de Sala5 aún no estaban identificados. Ahora hay **13 PNG de arena y 15 PNG del jefe** en las rutas indicadas por el usuario. Esa es una actualización observada, sin reescribir STATE ni el GDD.

## Entregables de esta planificación

- [Inventario diagnóstico](ROOM5_ASSET_INVENTORY.md): archivos exactos, alfa, medidas, superficies y límites de animación.
- [Diseño del jefe](ROOM5_BOSS_DESIGN.md): contratos, ataques, estados, fases, derrota, HUD y decisiones.
- `room5_diagnostics/`: contactos visuales, métricas, celdas candidatas y manifiesto de conservación. Son herramientas de revisión, no texturas listas para importar.
- Diagramas conceptuales en `diagrams/`: arquitectura, estados y flujo. Todos propuestos, estilo claro elegido por el usuario. No constituyen aprobación de mecánicas.

## Arena: composición y mapa físico candidato

### Lo que no permite el arte por sí solo

Los fondos/contornos usan 1672×941. `plataformasPresent.png` usa **1671×941**, es RGB opaco y presenta dos filas a Y≈144 y 683. `plataformasPast.png` es RGB opaco con una fila a Y≈420. Esas alturas son regiones de color, no caras de colisión. Los saltos entre filas de 263–276 px superan la capacidad del Player incluso con escala de escenario 1280/1672. El contorno tampoco suministra un suelo inferior continuo. No hay un plano físico jugable aprobado en estas imágenes.

Recomiendo recomponer apoyos desde `plataforma_presente.png` y `plataforma_pasado.png`, con sus fantasmas individuales alineados por la cara superior sólida, y conservar los montajes completos como referencia. Esto necesita aprobación en B por cambiar la distribución respecto de las hojas de referencia. Alternativa: conservar la distribución original y agregar apoyos intermedios visibles, con un coste mayor de arte y navegación. No arreglar saltos ajustando físicas.

### Composición de referencia

Un único origen (0,0), misma transformación uniforme para fondo y contorno en ambas dimensiones. Candidato: mundo 1280×720, escala de fondos `1280/1672≈0,76555`; altura resultante 720,38 px, sin estiramiento independiente. Confirmar recorte inferior de 0,38 px o límites de 721 px en B. Los apoyos individuales se colocan en coordenadas de mundo, no se hereda ciegamente la escala del fondo.

| Grupo | Presente | Pasado |
|---|---|---|
| Fondo | `fondo s5.png` | `fondoPast s5.png` |
| Marco | `contorno s5.png` | `contornoPast correcion s5.png` |
| Fantasmas | pasado translúcido, solo visual | presente translúcido, solo visual |
| Apoyos propios | presente sólido | pasado sólido |
| Shared | Base y descansos diseñados expresamente para ambas dimensiones | Exactamente las mismas formas físicas y origen |

Orden candidato: fondo z=-20; fantasmas -12; apoyos/contorno -10; jefe 0; Player 1; efectos 2; HUD CanvasLayer. El contorno frontal no puede tapar avisos ni el núcleo. No superponer las hojas sólidas RGB: borrarían el fondo. Tampoco mezclar los montajes translúcidos ruidosos como si su alfa fuera limpio. A debe producir derivados verificados o reutilizar sprites individuales limpios. No aplicar chroma-key global al negro: perdería sombra legítima del metal.

### Mapa candidato, unidades de mundo (requiere A/B)

Las superficies de esta tabla son **diseño nuevo**, no coordenadas extraídas como colisiones del arte. Se dan para evaluar el plan; B decide posiciones definitivas.

| ID / superficie | Dimensión | X inicial–final | Y de apoyo | Función |
|---|---|---|---|---|
| S0, base continua visible | Ambas | 80–1200 | 620 | Entrada, evasión y ataque; sin vacío de muerte durante pelea |
| S1, descanso izquierdo | Ambas | 240–380 | 560 | Preparación y cambio seguro |
| P1, apoyo superior izquierdo | Presente | 440–580 | 500 | Evasión y lectura del núcleo |
| T1, apoyo superior derecho | Pasado | 640–780 | 500 | Ruta de seguridad contra haz |
| S2, descanso derecho | Ambas | 820–960 | 560 | Aproximación, regreso al suelo y cambio seguro |

El arte de S0/S1/S2 se debe acordar: recomponer metal existente con tratamiento visual compartido legible y juntas claras, sin duplicar cuerpos físicos. No afirmar que una imagen coincidente prueba que son compartidos. S0 requiere un derivado de suelo visible antes de aceptar colisiones; si no se aprueba ese derivado, B debe rediseñar el mapa.

Candidato PlayerSpawn: centro (140,600), pies Y=620; retorno al extremo izquierdo con llegada separada del Area2D. Encuentro a X≈400 tras vestíbulo seguro; jefe anclado por pies en (1030,620), mirando a la izquierda. La dirección original del cañón mira a la derecha: espejo visual y anclajes deben verificarse juntos. Volumen corporal candidato X≈940–1120; núcleo arrodillado debe quedar alcanzable desde la base por espada/salto. Ningún apoyo obligatorio bajo el cuerpo ni junto al borde de cámara. Revisar S2 para que no invada animaciones.

S0 permite retirarse y alternar sin depender de plataformas exclusivas. P1/T1 añaden rutas, pero cambiar sobre una exclusiva implica caer si no existe apoyo destino; esa caída debe terminar en S0, sin jaulas de colisión. Usar superficies one-way superiores donde corresponda y formas delgadas. Muros visibles y suelos normales permanentes; nada de paredes invisibles por usar el borde de una textura. En combate no activar trampas nuevas ni daño por contacto corporal hasta tener una lectura clara aprobada.

### Comprobación analítica del salto y cámara

Player: SPEED=240 px/s, ACCELERATION=1600 px/s²; base_gravity 980 por defecto al no haber override; gravity efectiva ascendente 1470, descendente 2205. `_ready()` obtiene velocidad inicial ≈−514,39 px/s para conservar altura máxima ideal de **90 px**. Tiempo al ápice≈0,350 s; vuelta a igual altura≈0,636 s; recorrido con velocidad horizontal plena≈153 px. Desde reposo se pierde ≈18 px por aceleración: ≈135 px. Integración discreta, soltar salto, ancho 24 y márgenes reducen garantías. No se ejecutó una prueba física.

Diseñar saltos ascendentes con desnivel ≤60 px y hueco ≤60–70 px desde el borde de salida al inicio del destino; apoyo útil ≥100 px. S1→P1 tiene hueco60/desnivel60: tiempo ideal descendente a Y−60≈0,515 s, recorrido desde reposo≈106 px, suficiente con margen antes de la discretización. P1→T1 requiere Shift y hueco60 a misma altura; si se falla, caída segura a S0. T1→S2 es descenso60 con hueco40. S0→S1 y S0→S2 son ascensos60 desde debajo/cerca. Comprobar ambos sentidos, salida en reposo, velocidad plena, ápice, soltado y rechazo dimensional en D. No aprobar el recorrido solo por esta cuenta.

Una sola Camera2D del Player. Candidato override local de Room5: zoom 0,78 para abarcar 1280×720 a 1024×572 (campo≈1313×733); a 1280×720 se verá margen adicional. Límites 0..1280/0..720 y centrado/límite coherente necesitan prueba visual con viewport expand. Si el seguimiento no mantiene avisos y jefe visibles, ajustar propiedades locales de esa cámara; alternativa permitida: una Camera2D local fija y deshabilitar la heredada, manteniendo una sola activa. No crear sistema de cámara ni modificar Player.tscn. BossHUD inferior derecho no debe ocultar S2 ni pies del jefe.

## Arquitectura prevista y contratos

Room5 puede extender `room2.gd`: ya resuelve llegada, salud y HUD. Sobrescribir localmente `_on_player_defeated()` para cancelar inmediatamente el encuentro y luego usar el flujo base de derrota/reload. No copiar `_recover()` de Room4; si la arena no tiene abismos, no necesita checkpoints internos.

Árbol propuesto para aprobación antes de C:

```text
Room5 (Node2D, room5.gd; prioridad física -20 si hay lógica previa)
  Visuals / Present, Past, Shared
  WorldCollision / SharedCollision, PresentCollision, PastCollision
  Arena / BossSpawn, EncounterTrigger, ArenaBoundaries
  EntryMarkers / Spawn, FromRoom4
  RoomTransitions / ToRoom4
  EncounterController (Node; desde F)
  BossProjectiles (Node2D; desde G)
  CoreGuardian (instancia; desde F)
  DimensionManager (script existente; prioridad -10)
  Player (instancia con única Camera2D)
  CombatHUD (instancia)
  BossHUD (CanvasLayer, desde J)
```

PlayerSpawn vive en EntryMarkers para respetar GameProgress, no duplicado bajo Arena. Room5 no agrega Autoload. DimensionManager se configura mediante `present_visuals`, `past_visuals`, `present_shapes`, `past_shapes`, `controlled_player` y `player_collider`; formas compartidas quedan fuera de los dos arrays. Los grupos visuales contienen también los fantasmas de la dimensión opuesta. El gestor conmuta visibilidad de grupos enteros, no calcula por sí solo el ghosting de estos sprites.

TemporalLensHUD busca un nodo con **el script exacto** `DimensionManager.gd` y `controlled_player` asignado. Mantener gestor como hermano del Player/HUD y no envolverlo en un sustituto ni subclase. Su lógica es reutilizable en Room5 sin cambiar archivo: el texto histórico «Room4» describe su integración, no una restricción por nombre de escena.

El jefe obtiene referencia al gestor y observa `dimension_changed`; jamás ejecuta otro Shift ni reinicia salud/IA al cambiar. Room5 posee ciclo del encuentro, bloqueos y limpieza. Guardian posee salud, vulnerabilidad, animación y selección de ataques. BossHUD solo observa salud/estado. GameProgress conserva posesiones mediante llegada; cualquier campo de llave/victoria exige aprobación expresa de ampliación de alcance en E/K.

## Contrato de aprobación por fases

Antes de cada fase: autorización **independiente**, lista exacta de archivos afectados, respaldo externo recuperable y SHA-256 de originales, lectura MCP fresca (identidad/revisión), protección de recursos externos y comparación antes/después. No modificar un original que haya cambiado desde su respaldo. Este directorio carece de Git; el respaldo no es opcional. Nuevos archivos se verifican inexistentes; no sobrescribir documentos del usuario. Las pruebas que guarden usan APPDATA aislado y ejecución secuencial; `combat_test` requiere además nombre de proyecto aislado en una copia. Tras cambios GDScript: validate con el ejecutable autorizado 4.7.2 (la ruta antigua de AGENTS debe comprobarse; no editar AGENTS para corregirla automáticamente).

Cada fase incluye documentación de resultado y un pase de revisión; un PASS automatizado no autoriza la fase siguiente.

### A — Inventario productivo y registro de fotogramas

1. Objetivo: convertir el diagnóstico actual en inventario utilizable con recortes, bases y alineaciones verificadas.
2. Previo: aprobar A, decidir tratamiento de hojas opacas y normalización del jefe; revisar el inventario diagnóstico sin sobrescribirlo sin permiso.
3. Nuevos: comparaciones y manifiestos en `assets/tiles/sala 5/derived/` y `assets/sprites/jefe/derived/`; versión de inventario con sufijo de fase si se conserva este documento.
4. Existentes posibles: únicamente documentación de inventario, tras autorización; PNG fuente intocables.
5. Escenas/nodos: ninguno; láminas de comparación fuera de escena.
6. Incluye: alfa, recortes individuales, offsets, poses vacías/repetidas, anclaje por botas/cañón/núcleo, escala anatómica entre hojas.
7. Excluye: Room5, IA, ataques, importación masiva y cambios de sistemas.
8. Riesgos: alfa residual, bordes cortados, rejillas no uniformes, barras con tamaños incompatibles.
9. Respaldo: los 28 PNG y sus hashes; documentos que se autorice actualizar.
10. Pruebas: comparar píxeles originales; superponer origen/pivote/huella sobre checkerboard; contact sheets a escala real; no pérdida de metal oscuro.
11. Aprobación: 28 recursos clasificados y tabla definitiva de rects sin invasión injustificada; escalas y arte faltante explícitos.
12. Paso a B: revisión del inventario y aprobación independiente B.

### B — Diseño de arena

1. Objetivo: cerrar plano visual/físico y contrato de cámara.
2. Previo: A aprobado; decidir redistribución respecto del montaje, arte de Shared y sentido del jefe.
3. Nuevos: `docs/ROOM5_ARENA_LAYOUT.md`, comparación Presente/Pasado y plano numerado de colisiones.
4. Existentes posibles: plan/inventario mediante revisión autorizada; ninguno del juego.
5. Escenas/nodos: propuesta refinada del árbol; sin `.tscn` todavía.
6. Incluye: apoyos, huecos, suelo compartido visible, núcleo alcanzable, trayectoria de haz y cámara a dos resoluciones.
7. Excluye: construcción, física nueva, daños y pelea.
8. Riesgos: saltos imposibles del montaje, jefe fuera de encuadre, HUD sobre plataformas, caída al alternar.
9. Respaldo: documentos a revisar y nuevos derivados de A.
10. Pruebas: cálculo de enlaces con física real, overlay con collider24×40, recorrido propuesto en ambas dimensiones; reservar prueba jugable para C/D.
11. Aprobación: geometría, superficies compartidas justificadas, escalas y límites aceptados por el usuario.
12. Paso a C: árbol y mapa aprobados, autorizar C.

### C — Escena base

1. Objetivo: arena recorrible sin jefe ni encuentro activo.
2. Previo: A/B aprobadas, respaldo y estado MCP limpio o discrepancias preservadas.
3. Nuevos: `scenes/Room5.tscn`, `scripts/rooms/room5.gd`, `tests/room5_base_test.gd` e informe C.
4. Existentes posibles: solo derivados/documentos aprobados; no Player ni Room4.
5. Nodos: Visuals, WorldCollision, Arena marcadores, EntryMarkers, RoomTransitions sin salida inexistente, Player/cámara y CombatHUD; gestor configurado inactivo hasta D si fuera necesario.
6. Incluye: Presente inicial, colisión propia/Shared, spawn, cámara y HUD.
7. Excluye: jefe, disparador activo, transiciones activas y alternancia no validada.
8. Riesgos: doble Player/cámara/HUD, `room2.gd` requiere nombres exactos, rutas sin destino.
9. Respaldo: recursos reutilizados y hashes; no respaldar otros originales para justificar tocarlos.
10. Pruebas: carga, instancias únicas, spawn libre con pies sobre S0, andar/saltar, alineación y encuadre; validate.
11. Aprobación: base estable y visualmente revisada a 1024×572 y1280×720.
12. Paso a D: aceptar C y autorizar D.

### D — Integración dimensional

1. Objetivo: recorrido completo y seguro con el gestor existente.
2. Previo: C aceptada y geometría de B cerrada.
3. Nuevos: `tests/room5_dimension_test.gd`, informe D.
4. Existentes posibles: Room5, controlador local y arrays/propiedades de su gestor; no `DimensionManager.gd`.
5. Nodos: mismo gestor exacto, grupos Present/Past con ghosts, shapes exclusivas y Shared fuera de arrays.
6. Incluye: Shift suelo/aire, rechazo, cooldown0,20, protección0,16, HUD real y regreso seguro a S0.
7. Excluye: ataques y ajustes automáticos a plataformas/físicas.
8. Riesgos: formas no registradas, collider equivocado, visuales sin físicas o viceversa, prioridades distintas de Room4.
9. Respaldo: Room5/controlador antes de cambio.
10. Pruebas: entradas a cada plataforma, rechazo dentro de destino conserva estado, solicitud sin Lente, caída sobre S0, 0,16/0,20 independientes, rutas ida/vuelta y regresiones Room4.
11. Aprobación: ningún atrapamiento y trayectorias jugables observadas, no solo cálculo.
12. Paso a E: D aceptada; llave y reglas de acceso resueltas antes de autorizar E.

### E — Conexión Room4 ↔ Room5

1. Objetivo: acceso seguro con posesiones y llegada coherentes.
2. Previo: D aprobada; resolver Llave del Reactor y permiso explícito para cualquier trabajo de progreso necesario.
3. Nuevos: prueba `room4_room5_transition_test.gd`, informe E; recurso de llave solo si se aprueba su subalcance.
4. Existentes posibles: `scenes/Room4.tscn` para nueva salida junto a FutureRoom5Access; Room5 y marcador de retorno. No tocar transiciones anteriores ni `LevelTransition.gd`. GameProgress solo si autorización adicional de llave lo exige.
5. Nodos: ToRoom5/ToRoom4 y marcadores separados de áreas, shapes con máscara Player2.
6. Incluye: vestíbulo reversible antes de activación, Presente inicial; entrada no activa jefe.
7. Excluye: bloqueo de pelea efectivo hasta F; curación automática al entrar.
8. Riesgos: marcador no es puerta, bucle instantáneo, llegada con poca salud, puerta declarada sin llave.
9. Respaldo: Room4 exacta (preservar geometría aprobada), Room5, y progreso solo si autorizado.
10. Pruebas: transición real ida/vuelta con salud1/2/3, espada/Lente, velocidad0, orientación/cooldown transferidos; sin disparador encima de spawn.
11. Aprobación: flujo reversible sin cambios a apoyos Room4 ni pérdida de estado; llave conforme decisión explícita.
12. Paso a F: aprobar E y autoridad de combate base F.

### F — Guardián base y animaciones

1. Objetivo: aparición/reposo/vulnerabilidad/daño/derrota controlados en escenario de prueba, sin IA ofensiva.
2. Previo: A–E aceptadas; escalas/anclajes y contrato RF-05 aprobados.
3. Nuevos: CoreGuardian.tscn, `scripts/bosses/core_guardian.gd`, `scripts/rooms/room5_encounter.gd`, recursos SpriteFrames creados con Godot, `tests/core_guardian_base_test.gd`, informe F.
4. Existentes posibles: Room5/controlador y documentación local; ningún Enemy1/Player/espada compartidos.
5. Nodos: jefe Node2D estable, VisualPivot/AnimatedSprite2D, CoreHurtbox hijo directo, Muzzle/CoreAnchor, opcional body estático local separado; EncounterController.
6. Incluye: trigger una vez, intro, bloqueo local al comenzar, salud y señales, daño mediante interfaz real en vulnerabilidad de prueba, muerte una vez.
7. Excluye: patrulla, IA completa, nuevos ataques/animaciones y UI definitiva.
8. Riesgos: cambios de escala entre hojas; parent de hurtbox incorrecto rompe espada; colisión corporal desproporcionada.
9. Respaldo: Room5 y derivados aprobados; recursos nuevos no sobrescriben originales.
10. Pruebas: espada real daño1, Pasado/estado cerrado rechazan, dos áreas no duplican daño, base estable y derrota cancela; validate.
11. Aprobación: todas las poses registradas y núcleo alcanzable sin agrandar espada; combate artificial solo en prueba.
12. Paso a G: F aceptada y primer ataque especificado aprobado.

### G — Un ataque completo

1. Objetivo: haz horizontal con preparación, activo y recuperación legibles.
2. Previo: F, anclajes del cañón y rects de efecto aprobados.
3. Nuevos: escena/script de haz local si necesita Area2D, `tests/core_guardian_attack_test.gd`, informe G.
4. Existentes posibles: Guardian, controlador/Room5 para contenedor de ataques; ninguno de daño compartido.
5. Nodos: Muzzle, BossProjectiles/AttackVolume local, AnimationPlayer o llamadas de frame verificadas, shapes menores que brillo.
6. Incluye: A1 de BOSS_DESIGN, snapshot de línea al avisar, una emisión, daño por `Player.take_damage(1)`, cancelación.
7. Excluye: ráfaga A2, salto ofensivo y transición de fase.
8. Riesgos: confundir expansión del haz con pose corporal; telegraph causa daño; alcance incluye vestíbulo.
9. Respaldo: Guardian/Room5/recursos de animación existentes antes de G.
10. Pruebas: sin daño durante aviso, solo ventana activa, invulnerabilidad normal y temporal, entrada/salida de hitbox, muerte interrumpe y limpia.
11. Aprobación: ataque evitable por posicionamiento y Shift con aviso visible, sin necesidad de explotar huecos de4 centésimas.
12. Paso a H: usuario acepta G y alcance de patrones adicionales H.

### H — Patrones adicionales e IA

1. Objetivo: secuencia limitada y comprensible de patrones soportados por arte.
2. Previo: G aceptada y confirmación del uso de `attacking 3`/retorn/exit.
3. Nuevos: efecto de pulso solo si arte existente sirve y se aprueba, prueba extendida de ataques e informe H.
4. Existentes posibles: Guardian, recursos propios y contenedor de ataques.
5. Nodos: máquina enum local y temporizador de estado; slots de ataque, no plugin.
6. Incluye: A2 provisional de pulsos; selección con límite de repetición y recuperación; exit/retorn inicialmente solo presentación.
7. Excluye: ataque2 inventado, explosión/salto ofensivo sin recursos confirmados, combos solapados.
8. Riesgos: falta de proyectil A2, vueltas asíncronas, proyectiles sin dueño tras reload, escalado de hitboxes.
9. Respaldo: todo archivo local del jefe afectado.
10. Pruebas: transiciones válidas, semilla/orden reproducible, no doble emisión, duración máxima de ataques, limpieza y límite de amenazas.
11. Aprobación: dos patrones solo si ambos tienen arte/reglas aprobados; si A2 queda sin arte, cerrar alcance con A1 antes de I.
12. Paso a I: aprobar repertorio y decidir si2 etapas aportan variación suficiente.

### I — Etapas y dimensión

1. Objetivo: exigir decisiones de tiempo/espacio y atacar núcleo en Presente conforme RF-05.
2. Previo: H aceptada, decidir salud y umbral; arena ya validada.
3. Nuevos: `tests/core_guardian_phase_test.gd`, informe I.
4. Existentes posibles: Guardian/controlador/parametrización de ataques locales.
5. Nodos: mismo jefe; phase como dato ortogonal al estado, sin segunda IA.
6. Incluye: dos etapas propuestas, vulnerabilidad accesible y legible, transición después de recuperación, peligro dimensional con señalización.
7. Excluye: tercera etapa automática, reducción de0,16/0,20, nuevo gestor y fases con sprites nuevos.
8. Riesgos: Shift repetido cubre gran parte del tiempo, refugio permanente en Pasado, núcleo cerrado demasiado tiempo.
9. Respaldo: scripts/recursos locales de H.
10. Pruebas: cruza umbral una vez, Shift no reinicia vida/estado, mismo patrón en todos los momentos del cooldown, núcleo solo Presente+ventana, retiro siempre posible.
11. Aprobación: daño evitable, oportunidades frecuentes de espada, ningún ataque inevitable por cooldown; playtest de al menos3 intentos por participante.
12. Paso a J: I aceptada y aprobación de integración HUD.

### J — BossHUD

1. Objetivo: salud/estado fieles al jefe usando las barras entregadas.
2. Previo: A/F/I aceptadas, decidir granularidad de3 segmentos para salud propuesta12.
3. Nuevos: `scenes/ui/BossHUD.tscn`, `scripts/ui/boss_hud.gd`, prueba `core_guardian_hud_test.gd`, informe J.
4. Existentes posibles: Room5 para instancia única y conexiones; no CombatHUD/TemporalLensHUD.
5. Nodos: CanvasLayer, Control anclado abajo derecha, estado/valor, región de barra y presentación de derrota.
6. Incluye: mapeo salud real→celdas, feedback de golpe/vulnerable, defeat una vez.
7. Excluye: temporizador de vida ficticia y cambios a UI del Player.
8. Riesgos: hojas verticales irregulares y partículas residuales; barra demasiado grande, conflicto con mensajes.
9. Respaldo: Room5, derivados de barra y conexiones locales.
10. Pruebas:12→0, bordes de segmento, rechazo sin descenso, terminal único, dos resoluciones, safe area y no tapar S2.
11. Aprobación: salud exacta legible y animación secundaria nunca manda sobre valor real.
12. Paso a K: aceptar J y elegir victoria/persistencia/narrativa.

### K — Derrota, victoria y final

1. Objetivo: ciclo completo de reintento y cierre narrativo compatible con GDD.
2. Previo: I/J aprobadas; usuario aprueba guion, persistencia y alcance explícito si modifica GameProgress.
3. Nuevos: final/créditos local o adaptación de pantalla existente tras inspección, prueba `room5_persistence_test.gd`, informe K.
4. Existentes posibles: Room5/encounter/Guardian; GameProgress y menú únicamente con autorización adicional de integración de victoria. Actualizar plan de cambio antes de tocar.
5. Nodos: flujo final, interacción con reactor si aprobada, controlador de sesión y presentación final.
6. Incluye: cancelación inmediata en derrota Player, reload local completo, victoria única, final/créditos, guardado atómico si autorizado.
7. Excluye: reescritura general de derrota, nuevo lore/diálogo definitivo no aprobado, borrar saves v1.
8. Riesgos: empate de muertes, victoria guardada antes de final, fallo de escritura, softlock al continuar.
9. Respaldo: archivos locales; copias de saves de prueba aislados, y scripts de progreso/menú solo si entran en alcance aprobado.
10. Pruebas: muerte en cada estado, limpio tras retry, salud/posesiones, simultaneous-death, error de guardado, v1 sin campos nuevos, Nueva Partida frente a Continuar.
11. Aprobación: final y créditos observados; derrota recuperable; datos previos compatibles; victoria no se simula por animación.
12. Paso a L: K aceptada y alcance de campaña de validación aprobado.

### L — Validación integral

1. Objetivo: cerrar Sala5 con evidencia automatizada y visual comparable a Room4.
2. Previo: A–K aceptadas y build congelada con hashes.
3. Nuevos: `tests/room5_boss_flow_test.gd`, `docs/ROOM5_FINAL_VALIDATION.md`, capturas con nombres/estado/resolución bajo artifacts de pruebas.
4. Existentes posibles: pruebas nuevas de Sala5 e informes; no cambiar pruebas antiguas para ocultar fallos.
5. Nodos: escenas reales y harness aislado; ninguna escena productiva nueva por conveniencia del test.
6. Incluye: suites base/dimensión/jefe/ataque/fase/HUD/progreso; Room4 y protección/HUD; transiciones, espada y progreso; recorrido completo desde Nueva Partida.
7. Excluye: cambios de balance o correcciones mezclados sin su propia revisión, validación auditiva fingida en headless.
8. Riesgos: fallos históricos5/4 de combate/presentación, avisos de recursos al cerrar, concurrencia de guardados, memorias creciendo.
9. Respaldo: build congelada, perfiles aislados, logs antes/después y resultados originales.
10. Pruebas: secuenciales, 60 FPS controlados donde aplica; visual interactiva1024×572/1280×720, teclado/mando según InputMap real; sesión30 min y audio; captura estado de protección en límites y tras muerte.
11. Aprobación: criterios por suite cumplidos, deuda histórica distinguida de regresión nueva, sin atrapamientos ni ataques postmortem, final completo observado y toda excepción explicada.
12. Siguiente: detenerse y presentar cierre; ninguna ampliación o publicación automática.

## Riesgos y decisiones antes de programar

El registro detallado de decisiones está en BOSS_DESIGN, con recomendación, alternativa, riesgo y aprobación. Bloqueos prioritarios: llave RF-04, normalización de fotogramas/celdas invadidas, suelo compartido visible, geometría distinta de montaje, orientación/anclajes y permisos posteriores de persistencia. No instalar State Charts ni Beehave: enum local, señales y temporizadores bastan para este encuentro pequeño; un plugin añadiría dependencia sin resolver los problemas reales del arte/daño.

Próxima acción permitida tras esta entrega: **revisión del usuario**. Incluso si se aprueba este plan global, A necesita autorización expresa; las otras once fases conservan su aprobación independiente.
