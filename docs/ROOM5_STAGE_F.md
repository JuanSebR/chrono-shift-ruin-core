# Sala 5 — Fase F: entidad base del Guardián del Núcleo

16 de noviembre de 2026. Integración defensiva y visual, sin encuentro automático, IA ofensiva, ataques, proyectiles, BossHUD, victoria ni cambios de progreso. Se utilizó la skill local godot-gamedev. La regla de RF-05 del GDD se aplica en la recepción real de daño: exclusivamente Presente y núcleo expuesto.

## Estructura e integración

```text
Room5
└── CoreGuardian                   Node2D, posición(1070,620), escala física1
    ├── VisualRoot                 escala uniforme0,375
    │   └── AnimatedSprite2D        orientado a izquierda
    └── CoreWeakpoint              Area2D, grupo enemy_hurtbox, capa8, máscara0
        └── CollisionShape2D       CircleShape2D independiente, radio9 unidades
```

Escena reutilizable: `scenes/bosses/CoreGuardian.tscn`; controlador: `scripts/bosses/core_guardian.gd`. Room5 configura mediante export la referencia a su DimensionManager original. El Guardián es una única instancia compartida entre dimensiones, con salud y animación propias. No hay copia Past/Present ni un segundo gestor. Sin gestor asignado, la entidad independiente sigue visible pero rechaza daño por defecto.

La colocación coincide con FutureBossSpawn y con la cota superior de F0. El jefe queda anclado por diseño; no necesita gravedad ni un collider corporal para sostener una entidad estacionaria pasiva. No se convirtió la silueta en un muro ni se añadieron daños por contacto. El Player puede acercarse sin bloquear la ruta o el acceso de regreso. La necesidad de un cuerpo físico se revisará al definir interacciones de combate posteriores.

El orden de dibujo del jefe es−1: delante de Visuals(−10), detrás del Player. La primera revisión mostró que la silueta podía tapar al personaje al acercarse; este ajuste local corrige la legibilidad sin tocar colisiones o cámara.

## Arte y animaciones

No se modificó ningún PNG ni se regeneraron atlas. Se leen las regiones exactas del manifiesto de A, celdas640×800, anclaje(320,720). AnimatedSprite2D usa posición local(−320,−720), centered=false y flip_h=true; VisualRoot escala ambos ejes a0,375. El reposo conserva la altura corporal candidata≈194,25 unidades; sigue siendo un prototipo de escala.

SpriteFrames se construye una vez al cargar la entidad, mediante constructores Godot, sin editar un .tres manualmente. Las regiones y número de poses proceden del manifiesto; no se recortan nuevamente las fuentes. El editor sin ejecutar la escena no genera estos frames; F6 y las pruebas los cargan en runtime.

| Animación | Poses | Presentación provisional | Comportamiento |
|---|---:|---|---|
| starting |8 |8fps, no loop | Llamada explícita, luego Repose |
| repose |4 |6fps, loop | Inicial pasiva |
| vulnerable |6 |8fps, no loop | Entrada controlada; mantiene última pose |
| retorn |4 |8fps, no loop | Diagnóstico de descenso/incorporación, luego Repose |
| exit |4 |8fps, no loop | Diagnóstico de impulso, sin trayectoria, luego Repose |
| defeated |7 |8fps, no loop | Terminal, mantiene pose final |

Los tiempos no venían especificados por el autor: son valores de presentación para pruebas, sin balance ofensivo. Attack3, beam_start/hold/finish, retorn_repose, exit_repose y atlas de barra permanecen disponibles en disco, sin incorporarse al ciclo ni a las animaciones funcionales de esta entidad.

Persisten diferencias de proporción y anatomía entre las hojas; la postura vulnerable reduce mucho la envolvente corporal respecto a Repose. Retorn conserva sus offsets aéreos y puede mostrar discontinuidad al empalmar con reposo. La pose final de Starting tiene el cañón truncado ya presente en la fuente. No se estiraron extremidades, no se completaron píxeles y no se igualaron alturas por animación. Una corrección artística requeriría hojas coherentes del autor o una propuesta no destructiva aprobada; estas secuencias no se declaran artísticamente finales.

## Estados, salud y API controlada

Estados implementados: IDLE, INTRO, VULNERABLE, RECOVER y DEFEATED. No se añadieron estados vacíos de ataques. IDLE reproduce Repose sin detectar, perseguir ni dañar al Player. No existe temporizador de exposición automática.

- `set_core_exposed(true)` entra en Vulnerable; false vuelve a Repose y cierra el núcleo.
- `play_diagnostic(starting/retorn/exit)` reproduce únicamente esas secuencias controladas, cerrando exposición. Las solicitudes de attack3 se rechazan.
- `take_damage(amount)` vuelve a comprobar todas las condiciones reales en cada impacto.
- Al llegar a cero, cierra el núcleo, reproduce Defeated una vez y no vuelve a Idle. Las llamadas posteriores no cambian salud ni estado.

`max_health` es exportado, mínimo1, predeterminado12. Salud actual se inicializa por instancia y satura en cero. **12 es diagnóstico provisional, no balance aprobado**, y no guarda relación con los segmentos de la barra no implementada. Señales: health_changed, damage_accepted, core_exposure_changed, state_changed y defeated. No se registra victoria ni se escribe progreso.

## Núcleo y matriz de daño

CoreWeakpoint no bloquea ni causa daño. Su CircleShape2D es independiente, de radio9 unidades de mundo. Se actualiza en cada cambio de fotograma usando los centros aproximados de A, con la misma transformación uniforme y el espejo horizontal del sprite:

`posición local = (−(core_x−320), core_y−720) × 0,375`.

| Pose Vulnerable | Centro en atlas | Centro aproximado en Room5 |
|---|---|---|
|0 |319,442;429,767 |1070,209;511,163 |
|1 |308,279;498,419 |1074,395;536,907 |
|2 |299,907;568,186 |1077,535;563,070 |
|3 |298,791;593,860 |1077,953;572,697 |
|4 |293,209;570,419 |1080,047;563,907 |
|5 |290,419;576,000 |1081,093;566,000 |

El radio es candidato, contrastado con la presentación a escala de juego y el alcance físico; no es un collider definitivo del arte. El brillo no es uniforme y algunas poses tienen un centro oscuro o ambiguo. Los landmarks siguen siendo estimaciones visuales: la aceptación de un impacto en las poses bajas no certifica una máscara pixel-perfect de todas las variaciones. La revisión artística de G deberá comprobar especialmente bordes del núcleo durante las poses de descenso.

| Dimensión confirmada | Exposición lógica | Daño |
|---|---|---|
| Presente | Expuesto | Permitido |
| Presente | Protegido | Rechazado |
| Pasado | Expuesto | Rechazado |
| Pasado | Protegido | Rechazado |

La Shape se deshabilita de forma diferida cuando no corresponde recibir daño. La comprobación en take_damage protege también el intervalo hasta aplicar ese cambio físico: salud positiva, estado VULNERABLE, exposición y `DimensionManager.active_dimension == 0` son obligatorios. Un Shift rechazado no altera la condición. Cambiar de dimensión solo refresca el núcleo, sin reiniciar salud, estado, animación o posición. No se leen teclas para decidir la vulnerabilidad.

## Espada real y alcance

La espada existente consulta Area2D en capa8, exige grupo enemy_hurtbox y llama a take_damage en su padre; el Guardián implementa esa interfaz directamente. SwordHitbox conserva su lista de objetivos por tajo, duración0,10s y ventana original de los12 fotogramas del Player. No se modificaron Player, espada, Enemy1 ni gestores compartidos.

En la pose vulnerable final el núcleo queda en≈(1081,093;566),54 unidades sobre F0. El Player se coloca en un fixture inicial sobre suelo real,≈(1049,093;600), mirando a la derecha, y después ejecuta saltos/ataques reales. Estos fixtures no se presentan como recorrido continuo desde la entrada.

Resultados:

- Desde suelo, la banda vertical de espada queda aproximadamente entre Y582–610: no alcanza el núcleo y no reduce salud.
- Con salto sostenido y ataque solicitado después de20 pasos físicos, la ventana real coincide con el núcleo durante el descenso. Un tajo resta1; otro tajo completo resta otro1.
- A140 unidades horizontales del núcleo, el salto y tajo no causan daño. No se amplió la espada ni se desplazó el núcleo para lograr el impacto.
- Sin espada poseída no hay daño; con núcleo protegido tampoco. En Pasado, el tajo real y una llamada directa son rechazados.
- Una prueba empieza en Pasado con núcleo expuesto, abre la ventana real de espada y pulsa Shift mientras sigue activa. La confirmación de Presente permite el impacto restante, exactamente una vez.
- Un fixture de ocupación rechaza Shift a Pasado; el jefe conserva el permiso de daño correspondiente al Presente todavía confirmado.

La primera medición de ventana activa se tomó antes del inicio real del frame6. Se corrigió el instante de observación del test a15 pasos desde la solicitud, manteniendo intacta la animación, su duración y la ventana de producción.

## Pruebas y regresiones

`tests/core_guardian_base_test.gd` integra la escena real Room5 y el Player original; no hizo falta otra prueba room5_boss_base_test separada. Utiliza llamadas controladas para exponer, reproducir secuencias y ensayar derrota; las validaciones principales de alcance y daño usan salto, animación y ventana de espada reales.

| Prueba | Resultado final |
|---|---|
| core_guardian_base_test | PASS:30 comprobaciones físicas |
| room5_base_test | PASS:71 comprobaciones |
| room5_dimension_test | PASS:153 comprobaciones |
| room4_room5_transition_test | PASS: tres ciclos reales y recuperación posterior |
| room4_reactor_key_test | PASS |
| attack12_test | PASS; incluye impactos reales en Enemy1 hacia ambos lados |
| temporal_shift_protection_test | PASS |
| validate | PASS, salida0 |

Se ejecutaron secuencialmente, con perfiles APPDATA aislados y reloj fijo60fps. El test nuevo exige un perfil externo bajo phase_f_work; no guarda progreso ni victoria. Los tests de fases anteriores conservan sus guardias de aislamiento. La ruta histórica de AGENTS en Downloads es un directorio; el mismo validador se ejecuta con `C:/Godot/godot.exe.exe`, versión4.7.2.

La adaptación localizada autorizada de las pruebas base/dimensional reconoce la tercera Area2D (CoreWeakpoint), verifica que está pasiva y mantiene los controles físicos. La prueba dimensional contabiliza ahora cuatro observadores de dimension_changed dentro del test: HUD circular, tema de salud, núcleo y observador de prueba; dos para rechazo. No se quitó la comprobación de señales duplicadas.

Las ejecuciones siguen emitiendo algunos avisos de ObjectDB/recursos todavía en uso al cerrar. Los códigos y aserciones funcionales pasan; no se declara resuelto ni investigado aquí ese problema de limpieza. No se realizó combate completo ni una sesión larga con jugadores.

## Capturas reales

Renders del viewport, Forward+ / D3D12, en1024×572 y1280×720. En `artifacts/room5_stage_f/`:

| Nombre | Evidencia |
|---|---|
| idle_scale | Repose y comparación con Player, pies sobre F0 |
| intro | Incorporación controlada |
| vulnerable_core | Postura de descenso y núcleo visible |
| near_core | Player cercano al núcleo en postura final |
| sword_real | Animación real del primer tajo válido |
| past | Pasado con la misma entidad y daño rechazado |
| retorn | Secuencia de descenso/incorporación sin trayectoria |
| defeated | Secuencia de derrota controlada |

Se mantiene el encuadre de C/E, HUD único y legibilidad de la entidad en ambas dimensiones. No se muestran prototipos externos como prueba de ejecución. Las discontinuidades señaladas proceden de los recursos normalizados y no se ocultan con escalado por animación.

## Integridad y entrega

Creaciones: CoreGuardian.tscn, core_guardian.gd, core_guardian_base_test.gd, este informe y evidencias. Modificados: Room5.tscn y únicamente las expectativas topológicas/de observadores autorizadas de room5_base_test y room5_dimension_test. Ningún script de producción existente se modifica.

Respaldos previos, comparados por SHA-256: `C:/Users/juans/chrono-shift-backups/room5_stage_f_20261116_153734/`; manifiesto `hashes.json`. Se conserva línea base de archivos y hashes de guardados reales. La comparación de secciones previas de Room5 confirma geometría, cámara, HUD, marcadores y transiciones intactos; solo se añaden referencia e instancia del jefe.

Catálogo verificable, resultados, logs y capturas: `artifacts/room5_stage_f/verification.json`. Helpers externos y perfiles: `C:/Users/juans/.codex/visualizations/2026/11/16/01a1e570-850c-7a83-8965-7511f3d3ed84/phase_f_work/`. Las pruebas históricas escriben en el espejo externo existente; los renders nuevos solo en el directorio de F. No se sobrescribe el ZIP de transferencia, arte, atlas, memoria ni configuración.

## Pendiente para G

Revisar continuidad artística, radio/centros del núcleo durante todas las poses, feedback de exposición, volumen corporal si el diseño futuro lo necesita y balance de salud. Antes de programar ofensiva deben aprobarse repertorio, telegráficos y condiciones del encuentro. No se activó intro automática, selección de ataques, bloqueo de puertas, música, victoria o guardado de derrota del jefe. Detención en F.
