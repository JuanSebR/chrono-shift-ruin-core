# ROOM1.5: primer combate — implementación del 9 de noviembre de 2026

Implementado con Godot 4.7.2. GDD v1.2 sin modificar. La espada ahora se recoge al inicio de ROOM1.5; no es un arma disponible al comenzar una partida nueva.

## Secuencia y controles

Nueva partida reinicia la adquisición y abre ROOM1. El acceso existente lleva a ROOM1.5. Espada por contacto en (120,348), puente permanente, Enemy1 en (700,352.5), patrulla x560..820. J, clic izquierdo o el botón de ataque ya configurado ejecutan el golpe. No se añadió una salida ni DimensionManager.

Tras adquirir la espada aparece Continuar en el menú: abre ROOM1.5 con el arma. No restaura posiciones arbitrarias, salud ni enemigos derrotados; es un checkpoint mínimo de adquisición. Al morir en ROOM1.5 se recarga la sala tras un segundo, conservando el arma y recuperando salud. El enemigo vuelve a aparecer.

## Reglas de combate

- Player: collider principal 24×40, escala .33 y posición visual (0,-26.2), físicas, controles y cinco animaciones preservados.
- SwordHitbox: rectángulo 36×28, centro local (±28,-4), daño 1, ventana .10 s y una aplicación por enemigo y golpe. Consulta física solo durante la ventana; no altera las máscaras del cuerpo del Player.
- Cooldown .35 s existente conservado. El GDD indica .5 s: diferencia explícita pendiente de actualizar, no ajuste silencioso.
- El golpe muestra brevemente el sprite existente de la espada con un giro. `attacking v1.png` del Player no se integró: los arcos invaden cuadros vecinos y necesitan una revisión visual separada. Ningún PNG fue alterado.
- Enemy1: salud2, velocidad45, detección190 con línea de visión, carga .6 s, recuperación .9 s, intervalo mínimo1.8 s. Parámetros exportados para balance.
- Proyectil: daño1, velocidad120, TTL3 s, horizontal, máximo uno por enemigo. Detecta terreno/Player, se consume una sola vez. Se elimina también al derrotar al emisor.
- Sin daño por roce. El daño recibido interrumpe la carga. Estados IDLE, PATROL, CHARGE, RECOVER, HURT, DEAD. La derrota finaliza con la animación y libera el nodo.
- Patrulla protegida por límites, rayos de suelo y pared. No detecta al jugador antes de x400. La invulnerabilidad y `take_damage` originales permanecen intactos.
- Capas: terreno1, Player2, cuerpo enemigo4/máscara1, hurtbox8, espada máscara8, proyectil máscara3. Cuerpo enemigo no bloquea al Player.

## Arte y recursos reproducibles

`tools/combat_manifest.json` define cortes explícitos y anclajes por hoja. `tools/build_combat_resources.gd` construye recursos y escenas nuevas mediante APIs Godot; no edita `.tres` como texto.

Animaciones Enemy1: walking8/10FPS/bucle, attacking10/10FPS/una vez, damaged5/15FPS/una vez, ka-boom10/12FPS/una vez. Escalas uniformes por animación .20/.22/.13/.24 para compensar diferencias de tamaño de las hojas, con pies anclados al mismo nivel. Sin deformación individual.

Espada: `sword environment v1.png`, 1536×1024 RGBA, región (480,240,560,500), escala .12. Se conserva el brillo. Proyectil: imagen individual `enemy_1 proyectil_flying v1.png`, escala .04 y orientación según disparo. No se utiliza la hoja finishing con fondo cuadriculado.

Los halos grises propios de attacking y el humo de ka-boom siguen siendo parte del arte fuente. La vista previa aislada permite revisarlos antes de un eventual retoque autorizado.

## Progreso

Autoload `GameProgress`, estado `has_cronal_sword`. Archivo `user://progress_v1.json`: versión1 y booleano. Escritura temporal, flush, rotación `.bak`, renombrado final. Lectura validada, máximo4096bytes, respaldo si el principal es inválido. No se deserializan objetos ni rutas provenientes del archivo. Si falla el guardado, el arma sigue disponible en sesión y se muestra advertencia; Nueva partida no avanza si no puede persistir el reinicio.

Las pruebas destructivas de guardado se ejecutan exclusivamente con application/config/name=Core9_Combat_Isolated. No se modificó el progreso real del usuario durante las pruebas.

## Archivos de esta fase

Modificados: `Player.gd`, `Room1_5.gd`, `MainMenu.gd`, `project.godot`, `scenes/Player.tscn`, `scenes/Room1_5.tscn`, `tests/validate.gd`.

Creados:

- `scripts/game_progress.gd`
- `scripts/items/cronal_sword_pickup.gd`
- `scripts/combat/sword_hitbox.gd`
- `scripts/combat/enemy_projectile.gd`
- `scripts/enemies/enemy1.gd`
- `scenes/items/CronalSwordPickup.tscn`
- `scenes/combat/EnemyProjectile.tscn`
- `scenes/enemies/Enemy1.tscn`
- `assets/animations/enemy1_frames.tres`
- `assets/animations/cronal_sword_texture.tres`
- `tools/build_combat_resources.gd`
- `tools/combat_manifest.json`
- `tests/combat_test.gd`
- `tests/progress_menu_test.gd`
- Este documento. Godot puede generar archivos `.gd.uid` asociados.

## Validación y límites

PASS: 28 comprobaciones de combate aisladas, incluyendo recogida, persistencia, daño por ventana, dos golpes, ambos sentidos, patrulla, proyectil, invulnerabilidad, interrupción, secuencia completa por inputs, esquiva mediante salto, línea de visión, caducidad, derrota del Player y recuperación de guardado corrupto.

PASS: dos pruebas de menú (Continuar/Nueva partida), regresiones de ROOM1 (bajada segura, LeftBoundary, escalón, salto, aterrizaje), transición ROOM1→ROOM1.5, validación de scripts y recursos.

PASS real headless: `tests/validate.gd`, carga de ROOM1.5 con ambos actores apoyados, HUD/autoload y progreso sin cambios; transición real desde ROOM1.

MCP utilizado: editor_get_state, editor_get_scene_tree, editor_diagnose_player_frames, editor_reload_scene, editor_inspect_node, editor_get_viewport_preview. Confirmó posiciones, jerarquía, capas y aspecto en el editor real. No es una prueba visual interactiva de una partida en Desktop; esa revisión queda pendiente.

La ruta antigua del ejecutable en AGENTS.md no se pudo ejecutar; se utilizó `C:\Godot\godot.exe.exe`, Godot4.7.2, siempre con --headless. AGENTS.md no se modificó.

## Protección y reversión

La escena activa estaba detenida y limpia. Los cambios se prepararon en copia aislada, se aplicaron a disco y se recargaron mediante MCP. No se registraron como acciones Undo del editor: la reversión de esta integración es por respaldo. No se alteró historial con cambios de usuario pendientes ni se guardó desde el editor.

`core9_running_v2_frames.tres` continúa marcado como pendiente; el guardado protegido sigue rechazándolo. No se limpió su marca, no se afirmó igualdad memoria/disco y no se sobrescribió. Sus hashes, los otros recursos originales, todos los PNG y ROOM1 permanecen intactos. No se forzó un guardado ni se modificó el MCP.

Respaldo y evidencias: `C:\Users\juans\AppData\Local\GodotMCPCodex\tests\room15-combat-v1`. `baseline.json`, `integrity.json`, `changes.json`, logs, copia aislada, preview y carpeta `backup`. No hay repositorio Git inicializado en la raíz; se verificaron respaldos con SHA-256.

Para revertir solo esta fase: detener partida, verificar escenas limpias, restaurar los siete archivos modificados desde backup y retirar únicamente los archivos nuevos enumerados si no tienen referencias posteriores. No restaurar ROOM1, recursos anteriores ni MCP. Conservar el archivo user:// como respaldo si se desea; no es necesario borrarlo. No guardar recursos externos pendientes durante la reversión.
