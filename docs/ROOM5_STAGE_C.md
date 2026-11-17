# Sala 5 — Fase C: arena base jugable

16 de noviembre de 2026. Fase C construida y validada con Godot 4.7.2. La autorización de C permite probar las propuestas de B: mundo1280×720, base continua, cuatro plataformas superiores y Pasado azul preparado. Este documento registra la implementación; los documentos de A/B conservan su carácter histórico de propuestas.

## Alcance y conservación

Se creó `scenes/Room5.tscn`, cargable de forma independiente con F6. No se creó el Guardián, IA, BossHUD, ataque del jefe, trigger de combate, transición, checkpoint, recuperación por caída ni cambio dimensional. El ataque comprobado es exclusivamente el ataque existente del Player.

Se aplicó la skill local `godot-gamedev`. Se consultaron AGENTS, STATE y la planificación de Sala5, los derivados y manifiestos de A, y los resultados de B, sin repetir el inventario del jefe. Se inspeccionaron las convenciones de Room4, Player, Room2, progreso y HUD. No se modificaron esos archivos.

Godot MCP ampliado respondió con protocolo4. Antes de crear archivos, la escena activa era Room4 (`1654334234622`, revisión`10063650:0:1`), detenida y `unsaved=false`. Tras comprobar nuevamente su identidad y revisión, se abrió Room5 mediante MCP, sin guardar ni sobrescribir Room4. Room5 quedó abierta, detenida y sin cambios pendientes (`2452426399980`).

El directorio no dispone de Git. Se registraron SHA-256 de los1440 archivos preexistentes, excluyendo caché `.godot` y `.git`, antes de las escrituras. La comparación final, el listado completo de creaciones y sus hashes están en [verification.json](../artifacts/room5_stage_c/verification.json). No se necesitó modificar ni respaldar para edición un archivo preexistente. El manifiesto previo externo permanece en `C:/Users/juans/.codex/visualizations/2026/11/16/01a1e570-850c-7a83-8965-7511f3d3ed84/phase_c_work/before_hashes.json`; su hash consta en la verificación.

La importación normal de Godot añadió metadatos `.png.import` para recursos de A/B y originales que aún no estaban importados, incluidos recursos del jefe: son metadatos generados, no nuevos sprites ni cambios de contenido. También creó los `.gd.uid` de los dos scripts nuevos. El catálogo distingue estas creaciones. No se cambiaron configuraciones, credenciales, OpenViking ni AgentMemory.

## Árbol final

```text
Room5                                      room5.gd, extiende room2.gd
├── Visuals                                z=-10, nearest heredado
│   ├── Present                            visible
│   │   ├── Background / Architecture      capas originales independientes
│   │   ├── P1                             sólido magenta
│   │   └── T1                             fantasma cian
│   ├── Past                               oculto
│   │   ├── Background / Architecture      derivados azules independientes
│   │   ├── P1                             fantasma magenta
│   │   └── T1                             sólido cian
│   └── SharedPlatforms
│       ├── F0Piece1 … F0Piece7             metal neutro, solapado
│       └── R1 / R2                        mismo metal neutro
├── WorldCollision
│   ├── SharedCollision                    F0, R1, R2, LeftWall, RightWall
│   ├── PresentCollision                   P1
│   └── PastCollision                      T1, forma desactivada
├── EntryMarkers                           Spawn, FutureFromRoom4, FutureBossSpawn
├── Player                                 instancia de Player.tscn
│   └── Camera2D                           cámara heredada, configuración local
└── CombatHUD                              instancia original única
    └── TemporalLensHUD                     posesión neutral / oculto sin Lente
```

No se añadió un contenedor vacío de transiciones ni un DimensionManager provisional. Present y Past contienen cada uno fondo, contorno, sólido propio y fantasma contrario; Shared queda separado para no alternarlo en D.

## Recursos y escala

Base común de rutas: `assets/tiles/sala 5/`.

| Función | Recurso |
|---|---|
| Fondo y marco Presente | `fondo s5.png`, `contorno s5.png` |
| Exclusivos y fantasmas | `derived/room5_platform_pairs_atlas.png` de A, cuatro AtlasTexture de512×288 |
| Fondo Pasado preparado | `derived/room5_stage_c_past_blue_background.png`, derivado de `fondoPast s5.png` |
| Marco Pasado preparado | `derived/room5_stage_c_past_blue_architecture.png`, derivado de `contornoPast correcion s5.png` |
| F0, R1, R2 | `derived/room5_stage_c_shared_platform.png`, derivado RGBA512×256 de `plataforma_pasado.png` |
| Player y HUD | `scenes/Player.tscn`, `scenes/ui/CombatHUD.tscn`, sin copias ni modificaciones |

El mundo ocupa1280×720. Fondo y contorno conservan origen(0,0) y escala uniforme1280/1672≈0,765550239. Su altura natural es720,382775; el encuadre720 recorta el excedente inferior≈0,382775, equivalente a0,5px de origen. No se forzó una escala Y distinta. Ambas dimensiones usan la misma transformación. El filtrado nearest es local a Room5; no cambia `project.godot`.

Azul derivado: con L=0,2126R+0,7152G+0,0722B, RGB'=0,22RGB+0,78L·(0,62;0,92;1,35), limitado a0–255, alfa intacto. El original ámbar/cian sigue disponible. Shared conserva alfa y usa RGB'=0,20RGB+0,80L; queda neutro frente al sólido cian exclusivo. Los halos de fantasmas conservan su RGBA y reciben alfa local0,55.

F0 muestra siete copias de anchura visible192, paso160, escala uniforme192/416. Los centros están en160,320,480,640,800,960,1120; envolvente visible64–1216, con solape32. El anclaje fuente(256,80) coloca Y620 dentro del labio metálico, sin usar el halo como apoyo. La comprobación de alfa cubre todos los1121 puntos enteros de X80–1200 con alfa255. Las capturas reales muestran superficie continua y juntas modulares coherentes, sin un rectángulo de suelo invisible ni estirar el detalle horizontalmente.

R1/R2 usan escala160/416 y el mismo anclaje neutro. Los exclusivos de A usan anclaje de celda(256,96): P1 a160/468 y T1 a160/416. Las correcciones de registro de A permanecen intactas. No se usa ningún montaje completo de diagnóstico como textura de escena.

## Física, spawn y reserva del jefe

| ID | Estado inicial | X útil | Y superior | Forma / cuerpo |
|---|---|---|---|---|
| F0 | Shared activa |80–1200 |620 |StaticBody2D, Rectangle1120×8, firme |
| R1 | Shared activa |300–460 |560 |StaticBody2D, Rectangle160×8, one-way |
| P1 | Presente activa |500–660 |500 |StaticBody2D, Rectangle160×8, one-way |
| T1 | Pasado desactivada |700–860 |500 |StaticBody2D, Rectangle160×8, one-way, disabled |
| R2 | Shared activa |780–940 |560 |StaticBody2D, Rectangle160×8, one-way |

Cada superficie posee su propio CollisionShape2D y su propio RectangleShape2D, con cinco identidades distintas. Los cuerpos están centrados cuatro unidades bajo la cota superior, sin escalas físicas en padres. Entorno: capa1, máscara0. Player conserva capa2, máscara1 y collider24×40. Las plataformas superiores permiten atravesar desde abajo y descender con el control existente; F0 no se atraviesa al pulsar descenso.

Spawn(140,600), pies620, velocidad inicial cero, orientación derecha y salud3/3 cuando no existe una llegada pendiente. `room5.gd` reutiliza el contrato de llegada y sincronización del HUD de `room2.gd`; no reinicia el progreso. La prueba de una llegada efímera a `FutureFromRoom4`(180,600) conserva salud1/3 y posesiones, sin crear una transición ni escribir un guardado.

`FutureBossSpawn`(1070,620) representa pies. Es únicamente un Marker2D. La altura corporal candidata194,25 ocuparía aproximadamente Y425,75–620 y permanece dentro del encuadre. La zona a la derecha de R2 está disponible sobre F0. El volumen corporal, pivote y alcance de ataques siguen pendientes de validación con el jefe real.

Los dos límites físicos son StaticBody2D con CollisionPolygon2D propios. Siguen el borde opaco contiguo al exterior de los contornos, usando la intersección de ambas siluetas y un margen interior de1unidad; no se obtuvieron del fondo decorativo. No hay colisiones en el reactor ni pasarelas pintadas. La cámara no sustituye estos límites físicos.

Al caminar, los extremos comprobados fueron X≈76,915 y1203,917, con pies≈620 y apoyo F0. El collider real todavía solapa F0 y las piezas visibles se extienden hasta64/1216; no se abre una ranura transitable. Saltar contra las molduras deja al Player temporalmente sobre un saliente visible, a centros≈(68,496;530,997) o(1212,274;530,925). Se comprobó el regreso andando a F0 en ambos casos. No se añadió recuperación ni muerte por caída. Las futuras puertas requieren revisar estos contornos localmente.

## Cámara efectiva y HUD

Se usa exclusivamente la Camera2D heredada del Player. El controlador local la separa del seguimiento del personaje mediante `top_level`, fija el centro(640,360), desactiva suavizado y conserva límites(0,0,1280,720). Ajusta el zoom uniforme al viewport lógico actual mediante max(ancho/1280,alto/720), también al redimensionar la ventana. No se modificó Player.tscn.

El proyecto usa `canvas_items` y aspecto`expand`; la base efectiva observada es1152×648. Por eso el zoom numérico de Camera2D no coincide con el factor final en píxeles:

| Ventana / captura real | Viewport lógico observado | Zoom Camera2D | Stretch observado | Zoom efectivo horizontal |
|---|---|---|---|---|
|1280×720 |1152×648 |0,90 |≈1,111111 |1,00 |
|1024×572 |1160×648 |0,90625 |≈0,882759X /0,882716Y |0,80 |

Los valores efectivos aprobados para prueba se cumplen sin cambiar renderizado global. La diferencia mínima entre ejes del stretch a1024×572 procede del redondeo del viewport existente; las escalas del arte y cámara siguen siendo uniformes. El encuadre cubre el ancho1280 y recorta unos pocos píxeles verticales según aspecto, sin franjas exteriores negras. Se verificaron Player en ambos extremos, P1, R1, centro y futuro apoyo del jefe. No se afirma compatibilidad de combate con cualquier relación de aspecto estrecha.

CombatHUD es la instancia original única. Se comprobó salud3/3, daño2/3 y estado crítico1/3, posición fija durante el recorrido, Lente poseída con texto`LENTE INSTALADA`, sin recarga/protección/dimensión dinámica; sin posesión se oculta. Sin gestor dimensional, Shift no cambia capas, posición, colisiones, HUD ni protección temporal.

## Recorrido y pruebas

`tests/room5_base_test.gd` utiliza el Player original e Input Map real, avance de física, salto sostenido y comprobación del cuerpo de aterrizaje. No se teletransporta al Player para declarar conexiones viables. Solo la comprobación separada del contrato de llegada cambia de instancia y utiliza un marcador.

| Recorrido | Resultado medido |
|---|---|
| F0→R1 |PASS, despegue(280,444;600), aterrizaje(352,897;539,964), cuerpo R1 |
| R1→P1 |PASS, despegue(441,341;539,964), aterrizaje(533,790;479,963), cuerpo P1 |
| P1→F0 |PASS, descenso real con control existente, cuerpo F0 |
| F0→R2 |PASS, despegue(762,234;599,978), aterrizaje(834,684;539,964), cuerpo R2 |
| R2→F0 |PASS, descenso real, cuerpo F0 |
| R2→fantasma T1→R2 |PASS, pies mínimos465,64; atraviesa Y500 al subir y caer, aterriza en R2 |
| Horizontal / jefe / regreso |PASS, desplazamiento hasta≈1071,128, ambos límites y retorno≈140,496 |
| Salto contra ambos contornos |PASS, apoyo en moldura visible y regreso andando a F0 |
| Ataque existente sobre F0 |PASS con espada poseída en memoria del perfil de prueba |

Ninguna conexión ensayada necesitó cambiar las coordenadas ni la física. Estas rutas demuestran viabilidad con los inputs indicados; todavía no equivalen a una sesión manual de evaluación de dificultad con jugadores.

Pruebas finales ejecutadas:70 comprobaciones físicas por resolución y86 comprobaciones por ejecución con render (incluyen16 comprobaciones de tamaño/guardado de capturas), cero fallos. Los JSON individuales y `verification.json` son la fuente de los resultados finales. El validador general existente `tests/validate.gd` finalizó con salida0 y `VALIDACION DE SINTAXIS EXITOSA`.

La primera ejecución reveló problemas del comprobador, registrados en los logs externos: el backend headless exponía inicialmente un viewport predeterminado distinto; el estado de suelo al rozar pared podía no producir un contacto de deslizamiento nuevo; y la expectativa de volver directamente a F0 ignoraba las molduras visibles. Se corrigió el perfil de viewport headless, se agregó consulta física bajo los pies para identificar apoyos retenidos por floor snap y se comprobó el regreso físico desde las molduras. No se cambiaron los saltos, gravedad, aceleración, Shapes ni coordenadas para ocultar fallos.

Los renders reales se obtuvieron del Viewport de Godot con Forward+ / D3D12, NVIDIA GTX1660SUPER, a60fps fijos para reproducción. No son prototipos de B. La prueba headless emula explícitamente el viewport solicitado porque no dispone de ventana física; las ejecuciones con GPU conservan el stretch real y comprueban por separado ventana, viewport lógico y píxeles capturados.

Los procesos de prueba usan APPDATA externo bajo`phase_c_work/profile`, con guardia en el script que rechaza el perfil real. No llaman a adquisición ni guardado de progreso: ajustan posesiones solo en memoria. Se verificó que ni siquiera apareció `progress_v1.json` en el perfil aislado y que los dos archivos de guardado reales registrados conservaron sus hashes.

La ruta histórica de AGENTS `C:/Users/juans/Downloads/Godot_v4.7.2-stable_win64.exe` no existe. Se ejecutó el mismo validador con `C:/Godot/godot.exe.exe`, versión4.7.2.stable.official.ed1daf0bf. No se corrigió AGENTS ni se reinstaló nada. El ejecutable gráfico requiere esperar su proceso para recoger la salida; el helper externo utiliza Start-Process con Wait y logs.

## Capturas reales

Directorio: `artifacts/room5_stage_c/`. Cada estado existe a1024×572 y1280×720. `01` combina vista general, spawn y HUD; no son tres estados físicos diferentes.

| Estado |1024×572 |1280×720 |
|---|---|---|
| General / spawn / HUD |[PNG](../artifacts/room5_stage_c/01_general_spawn_hud_1024x572.png) |[PNG](../artifacts/room5_stage_c/01_general_spawn_hud_1280x720.png) |
| Player en R1 |[PNG](../artifacts/room5_stage_c/02_R1_1024x572.png) |[PNG](../artifacts/room5_stage_c/02_R1_1280x720.png) |
| Player en P1 |[PNG](../artifacts/room5_stage_c/03_P1_1024x572.png) |[PNG](../artifacts/room5_stage_c/03_P1_1280x720.png) |
| Player en R2 |[PNG](../artifacts/room5_stage_c/04_R2_1024x572.png) |[PNG](../artifacts/room5_stage_c/04_R2_1280x720.png) |
| Futuro BossSpawn |[PNG](../artifacts/room5_stage_c/05_future_boss_1024x572.png) |[PNG](../artifacts/room5_stage_c/05_future_boss_1280x720.png) |
| Extremo derecho |[PNG](../artifacts/room5_stage_c/06_right_limit_1024x572.png) |[PNG](../artifacts/room5_stage_c/06_right_limit_1280x720.png) |
| Extremo izquierdo |[PNG](../artifacts/room5_stage_c/07_left_limit_1024x572.png) |[PNG](../artifacts/room5_stage_c/07_left_limit_1280x720.png) |
| HUD crítico |[PNG](../artifacts/room5_stage_c/08_hud_critical_1024x572.png) |[PNG](../artifacts/room5_stage_c/08_hud_critical_1280x720.png) |

## Archivos y reproducción

Archivos fuente creados: `scenes/Room5.tscn`, `scripts/rooms/room5.gd`, `tests/room5_base_test.gd`, este documento y los tres PNG`room5_stage_c_*` descritos arriba. Evidencias:16PNG, cuatro JSON de resultados y`verification.json`; metadatos de importación/UID generados aparte. El catálogo final enumera todos los archivos y SHA-256. No hay archivos fuente preexistentes modificados.

Helpers de construcción, ejecución y verificación conservados fuera del proyecto, en`C:/Users/juans/.codex/visualizations/2026/11/16/01a1e570-850c-7a83-8965-7511f3d3ed84/`: `build_room5_stage_c.py`, `compose_room5_stage_c.py`, `run_room5_stage_c.ps1`, `verify_room5_stage_c.py`. El generador de escena rechaza sobrescribir una Room5 existente. No es necesario ejecutarlos para jugar la escena.

Para repetir la prueba desde el directorio del proyecto, ejecutar el helper PowerShell con`-Mode physics -Size 1024x572` y`-Mode physics -Size 1280x720`; para capturas,`-Mode render` con cada tamaño. Utiliza el Godot instalado, perfil aislado,60fps y espera la salida real del proceso. Alternativamente el script GDScript acepta`-- --viewport=1280x720 --capture` en un proceso Godot con perfil aislado bajo un directorio llamado`phase_c_work`; sin`--capture` funciona headless. Importar los recursos nuevos antes de ejecutarlo en una copia sin caché.

## Pendientes y dependencias de Fase D

La arena está preparada para probar la alternancia después de una nueva autorización. D debe vincular el DimensionManager existente con Present/Past y los arrays exclusivos P1/T1, dejando Shared activo. Debe validar ocupación, one-way, caída al retirar apoyo, cooldown y protección actuales, sin duplicar controladores. Las condiciones seguras de Shift no se han ensayado aquí.

La paleta azul está preparada pero aún no validada en un combate real. Nearest y escalas fraccionales producen el muestreo esperado del pixel art; no se promete píxel perfecto en ambas ventanas. Las juntas de F0 son modulares y permanecen visibles como estructura repetida, sin grietas de soporte. Las molduras pueden alojar al Player al saltar contra paredes; revisar su conveniencia para ataques futuros. Los límites actuales cierran ambos extremos y deberán ajustarse cuando se diseñen puertas/transiciones. No se declara una política definitiva de salida o caída.

La reserva del jefe es visual y geométrica. Su collider, ataques, daño, ventana del núcleo y balance necesitan pruebas posteriores. No se integró Room4→Room5. El desarrollo se detiene al terminar C.
