# Presentación jugable de C.O.R.E.-9 — 9 de noviembre de 2026

Integración probada primero en copia aislada y después aplicada al proyecto real. No se modificó el GDD, PNG originales, físicas generales ni recursos de animación anteriores.

## Diseño comprobado

El documento vigente está en `GDD.md` en la raíz (no en docs/GDD.md). Líneas175/177 y RF-02: salud3, protección1segundo/60frames y parpadeo. Líneas376/441: tres células de energía. Se conservan salud3, daño de proyectil1, daño de espada1 e invulnerabilidad60ticks a la configuración actual de60Hz. Se añadió parpadeo sin retroceso físico. El cooldown de espada sigue siendo .35s por autorización expresa; el GDD dice .5s y permanece pendiente de actualización.

El GDD menciona el último punto de guardado; esta fase utiliza el punto de entrada de la sala actual, conforme a la petición y al sistema existente. No se añadió un sistema general de checkpoints.

## Animaciones y delimitación

Todas las hojas utilizadas son RGBA y tienen12 poses visibles. Attack mide2171×724; pickup/hurt/defeat,2172×724. No se divide por una cuadrícula uniforme durante la construcción: el manifiesto contiene regiones, anclajes, duraciones y exclusiones explícitas.

| Animación | Archivo | Cuadros fuente, numerados desde1 | Reproducción |
|---|---|---|---|
| attack | attacking v1.png | 1,3,4,5,10,11,12 | 20FPS base; duraciones .5,.5,1,2,1,1,1; total .35s |
| pickup | interacting down.png | 1,3,4,5,7,8,9,10,11,12 | 25FPS, .40s |
| hurt | damaged.png | 4,5,6,9,11,12 | 24FPS, .25s |
| defeat | defeated.png | 1–12 | 16FPS, .75s; pausa posterior .25s |

Todas son de reproducción única. Se eligió interacting down frente a interacting porque representa agacharse y recoger; la otra hoja representa interacción frontal con un efecto proyectado.

Attack utiliza un golpe de extensión y recuperación del arma. Los grandes arcos de las poses6–8 se superponen a cuadros vecinos: se excluyen de esta versión. En la pose5 hay un fragmento del arco siguiente en la esquina inferior derecha. El constructor extrae una textura derivada y vuelve transparente solo esa zona, definida en el manifiesto; conserva personaje y espada. El original no se modifica. No se reconstruyen ni inventan píxeles del arco ausente.

Las regiones no uniformes de defeat evitan cortar las botas de las poses tumbadas o incluir partes de la siguiente pose. La vista previa final contiene los12 cuadros completos. Se preservan las proporciones originales y la escala del nodo; las hojas mantienen sus diferencias originales de postura y silueta.

Canvas virtual de las acciones300×724, apoyo y502, con anclajes por pose. AnimatedSprite2D conserva posición(0,-26.2), escala(.33,.33). El apoyo virtual corresponde a y20 local del Player, la base de su collider24×40. No hay desplazamiento de físicas ni knockback.

## Comportamiento

- Prioridad: defeat > hurt > pickup > attack > locomoción. Las cinco animaciones previas conservan cuadros, FPS, bucles, regiones, márgenes y referencias de texturas.
- Attack: .10s de preparación, .10s de ventana activa durante la pose de espada extendida, .15s de recuperación. La señal de cambio de fotograma activa el hitbox; salir de esa pose lo cancela. Un golpe por enemigo. La dirección visual queda fijada durante la acción. Pulsaciones inválidas no reinician la animación. Se elimina SwordVisual provisional.
- Pickup: contacto con Player apoyado inicia la presentación. Se frena usando la fricción existente durante .40s; no se cambia esa constante. Al terminar se concede/persiste el arma, desaparece el objeto y se emite el mensaje existente. Daño o salto cancelan sin conceder ni perder el objeto. El salto conserva su impulso. Si continúa dentro del área al volver a un estado válido, puede intentarse de nuevo.
- Hurt: solo ante daño real; cancela ataque/recogida, dura .25s y retorna al estado físico correcto. Invulnerabilidad y parpadeo continúan durante el segundo completo. Se ignoran ataques durante la reacción; no hay buffer automático de entradas.
- Defeat: bloquea movimiento voluntario, salto, ataque y cambio dimensional; la gravedad sigue resolviendo el apoyo. El Player emite una señal al terminar la animación. Los gestores existentes de ROOM1 y ROOM1.5 esperan esa señal y .25s antes de recargar la sala. No se duplicó el reinicio dentro del Player.
- FallReset ignora al Player derrotado, para no teletransportarlo antes de terminar. LevelTransition tampoco cambia de sala a un Player derrotado. Ambas guardas fueron probadas con contacto físico.
- ROOM1.5 muestra tres células cian y el contador de integridad. ROOM1 conserva sus células y tema dimensional; su mensaje de daño ahora calcula el porcentaje real, en lugar de mostrar siempre66%.
- La espada persiste al morir. Recargar la sala restaura salud y reinicializa enemigo/proyectiles. Continuar y Nueva partida mantienen el comportamiento aprobado.

## Construcción y archivos

Recurso nuevo: `assets/animations/core9_presentation_frames.tres`, copia ampliada de las cinco animaciones aprobadas. Derivado nuevo: `assets/animations/player_actions/attack_05.res`. Generación con APIs Godot mediante `tools/build_player_presentation.gd`, a partir de `tools/player_presentation_manifest.json`. No editar .tres a mano.

Modificados: Player.gd, GameManager.gd, HUD.gd, Room1_5.gd, LevelTransition.gd, scenes/Player.tscn, scenes/Room1_5.tscn, scripts/items/cronal_sword_pickup.gd, scripts/combat/sword_hitbox.gd, tests/validate.gd y tests/combat_test.gd.

Creados: los dos recursos, constructor y manifiesto anteriores, tests/player_presentation_test.gd y este documento. Los .gd.uid que pueda generar Godot son metadatos asociados.

## Evidencia

Carpeta externa: `C:\Users\juans\AppData\Local\GodotMCPCodex\tests\player-presentation-v1`.

- PASS:36 comprobaciones aisladas de presentación, incluyendo sincronización de golpe en ambos sentidos, recogida diferida, cancelación por daño/salto, HUD, parpadeo, derrota y reinicio en ambas salas, igualdad de las cinco animaciones y collider.
- PASS:28 comprobaciones del combate existente, con tiempos de espera actualizados para recogida/reacción; dos pruebas del menú; regresiones de ROOM1 y sus colisiones.
- PASS: guardas de derrota en FallReset y transición, aisladas y reales.
- PASS real headless: ataque con daño, hurt, derrota/reinicio en ROOM1 y ROOM1.5, y tests/validate.gd. El arnés real habilitó la espada únicamente en memoria del proceso de prueba: no llamó a guardar, nueva partida ni adquirir; no cambió el progreso persistido del usuario.
- MCP: inspección de estado/nodos, recarga segura de escenas limpias, confirmación del recurso nuevo y transformaciones. La pestaña Player conservaba una copia antigua limpia y se recargó para evitar dejar referencias obsoletas. Se dejó ROOM1.5 abierta.
- El MCP rechazó cambiar animation/frame para previsualización por sus restricciones de instancia/propiedad. No se ampliaron permisos ni se modificó el MCP. No se efectuó una partida visual interactiva en Desktop. La vista previa animada externa es una representación de los cuadros derivados, no una captura del juego.

## Recursos pendientes y reversión

El guardado protegido sigue detectando `core9_running_v2_frames.tres` pendiente. No se limpió ni sobrescribió; no se afirmó igualdad exhaustiva de su copia en memoria. Se verificaron hashes de los recursos originales y todos los PNG. Las escenas estaban detenidas y limpias antes de aplicar archivos y recargar mediante MCP. No se guardó desde el editor.

Respaldos verificados en `backup`, inventario en `changes.json`, hashes en `baseline.json`/`integrity.json`, logs y resultados en la carpeta externa. No hay Git inicializado en esta raíz. La integración por archivos se revierte mediante esos respaldos, no mediante Undo del editor: restaurar únicamente los11 archivos modificados y retirar los seis nuevos cuando no tengan referencias posteriores, con partida detenida y escenas limpias. No restaurar el GDD ni otros recursos y no guardar recursos externos pendientes.

Ajustes finos recomendados tras jugar: revisar la lectura del golpe de extensión frente al tajo amplio original, la rapidez de recogida y la reacción .25s. Si se quieren los arcos completos, se necesitan cuadros separados o una revisión visual específica; esta fase no inventa el contenido solapado. No añadir retroceso ni cambiar balance para resolver diferencias visuales.
