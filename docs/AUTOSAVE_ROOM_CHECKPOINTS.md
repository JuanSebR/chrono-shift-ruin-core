# Guardado automático por sala y CONTINUAR

Implementado y verificado el 17 de noviembre de 2026 con Godot 4.7.2 stable. Se utiliza el autoload `GameProgress` existente; no se ha creado otro sistema de guardado.

## Archivo y campo

`user://progress_v1.json` conserva `version: 1` y añade `last_room_checkpoint`, una cadena con la ruta de la última sala visitada correctamente. No guarda coordenadas, salud ni dimensión en disco.

Se mantienen los campos existentes: `has_cronal_sword`, `has_temporal_lens`, `has_reactor_key`, `core_guardian_defeated`, `completed_tutorials` y `completed_dialogues`. No se modifican las condiciones de adquisición. Los datos transitorios de una transición (salud, orientación, protección y cooldown) siguen conservándose en memoria como antes.

## Salas y aparición segura

Tutorial y Sala 1 son **una única escena real**, `Room1_Tutorial.tscn`; no existen dos salas consecutivas distintas con esos nombres. Las siete escenas jugables están conectadas en ambos sentidos:

`Room1_Tutorial ↔ Room1_5 ↔ Room2 ↔ Room2_2 ↔ Room3 ↔ Room4 ↔ Room5`.

Las coordenadas siguientes son el centro inicial del Player, en píxeles del mundo, antes de su asentamiento normal por física. Se reutilizan nodos existentes; no se añadieron marcadores ni se editaron escenas.

| Sala | Escena, bajo `res://scenes/` | Punto usado por CONTINUAR | Centro inicial |
|---|---|---|---|
| Tutorial / Sala 1 | `Room1_Tutorial.tscn` | posición original de `Player` | (45, 304) |
| Sala 1.5 | `Room1_5.tscn` | `EntryFromTutorial` | (60, 352) |
| Sala 2 | `Room2.tscn` | `EntryMarkers/Spawn` | (100, 560) |
| Sala 2.2 | `Room2_2.tscn` | `EntryMarkers/FromRoom2` | (125, 382) |
| Sala 3 | `Room3.tscn` | `EntryMarkers/FromRoom2_2` | (130, 695) |
| Sala 4 | `Room4.tscn` | `EntryMarkers/Spawn` | (64, 396) |
| Sala 5 | `Room5.tscn` | `EntryMarkers/Spawn` | (140, 600) |

Se comprobó que los siete puntos no intersectan terreno sólido, que el Player permanece en su sala, se apoya en suelo y conserva 3HP después de asentarse. No se reutiliza automáticamente el marcador por el que se salió o regresó. Cada sala recrea sus reglas dimensionales originales; Sala 4 y Sala 5 comienzan en Presente.

## Confirmación y fallos

`LevelTransition.gd` identifica la transición real al preparar el traspaso existente. `apply_room_arrival()` coloca al Player en el marcador de destino y difiere la confirmación hasta que `SceneTree.current_scene` identifica esa sala. Se comprueban el origen jugable, la instancia real del Player, el destino permitido y cargable, el marcador existente, la posición finita, salud positiva y la vigencia del traspaso.

Solo entonces se guarda la sala. Retroceder actualiza el checkpoint igual que avanzar. Si ya coincide con la última sala confirmada, no se rota de nuevo el archivo. El mecanismo `.tmp` → principal / `.bak`, con comprobación de escritura, se conserva. Si `save_progress()` falla, se restaura el checkpoint previo en memoria y no se anuncia una confirmación falsa.

No se registra un checkpoint al caminar, cambiar de dimensión, morir, recargar la sala, ejecutar directamente una escena de diagnóstico, abrir el menú, usar F9 ni entrar en FinalRoom. Los traspasos sintéticos anteriores siguen funcionando, pero no acreditan por sí solos una transición legítima. Si cambia la escena, se cancela el traspaso o falta el marcador, la confirmación pendiente no reemplaza el checkpoint anterior.

## CONTINUAR, Nueva Partida y v1 anterior

El menú lee el progreso existente, acepta también la recuperación desde `.bak` y habilita CONTINUAR solo si existe un guardado válido. Un guardado nuevo válido puede continuar incluso antes de adquirir la espada. Sin guardado, el botón permanece deshabilitado, el foco va a Nueva Partida y pulsarlo no crea archivos.

CONTINUAR valida la ruta permitida y su `PackedScene`, prepara la aparición segura correspondiente y carga esa escena con 3HP, velocidad cero, orientación inicial y sin protección/cooldown heredados de otra sesión. Este traspaso desde el menú no genera otro autosave.

Un v1 sin `last_room_checkpoint` sigue siendo válido. Con espada utiliza el destino histórico de continuación, Sala 1.5; sin espada utiliza Tutorial/Sala 1. Lo mismo ocurre si el campo tiene un tipo incorrecto, una ruta inexistente o una escena excluida como FinalRoom. Se conservan las posesiones, tutoriales, diálogos y victoria; leer el archivo no realiza una migración ni una escritura.

Nueva Partida restaura el progreso inicial existente y guarda `Room1_Tutorial.tscn` como checkpoint inicial, reemplazando el de la partida anterior. Si falla el guardado, revierte también este campo junto con los objetos y victoria y el menú no cambia de escena.

## Sala 5, victoria, final y F9

CONTINUAR hacia Sala 5 coloca al Player en (140, 600), antes del EncounterTrigger. El Guardián no derrotado permanece pasivo y el encuentro conserva su activación natural. Con victoria guardada, permanece derrotado y el acceso invisible `E · SALIR` sigue habilitado. Entrar al final y volver al menú no sustituyen ni reescriben el checkpoint de Sala 5.

El lanzador `Probar-Sala5.cmd`, `tools/Start-Room5Practice.ps1` y su controlador no se modificaron. El contexto de práctica identificado por `CHRONOSHIFT_ROOM5_PROFILE` excluye las confirmaciones automáticas. F9 sigue cargando Sala 5 independientemente del checkpoint, restableciendo equipo, 3HP, Presente y victoria falsa exclusivamente en su perfil aislado. También se verificó F9 desde FinalRoom.

## Aspecto del botón

Se utiliza directamente `res://assets/inicio/Continuar.png`: **2172×724 RGBA**, proporción 3:1, con transparencia. El archivo original no se modificó ni se recortó. El antiguo botón de texto se sustituyó por un único `TextureButton` de tamaño mínimo 300×88, filtrado nearest y `STRETCH_KEEP_ASPECT_CENTERED`.

Comparte foco, hover y pulsación con los otros botones y atenúa su apariencia cuando está deshabilitado. Los otros tres botones, su espaciado, el fondo y la animación del personaje permanecen intactos. No se editó `MainMenu.tscn`.

| Resolución | Habilitado | Sin guardado |
|---|---|---|
| 1024×572 | [Captura](../artifacts/autosave_room_checkpoints/menu_enabled_1024.png) | [Captura](../artifacts/autosave_room_checkpoints/menu_disabled_1024.png) |
| 1280×720 | [Captura](../artifacts/autosave_room_checkpoints/menu_enabled_1280.png) | [Captura](../artifacts/autosave_room_checkpoints/menu_disabled_1280.png) |

Las cuatro capturas se inspeccionaron visualmente. No hay deformación, duplicados, solapamientos ni botones fuera de pantalla.

## Pruebas y resultados

Todas las ejecuciones usaron **APPDATA aislado**. La suite nueva comprueba la ruta exacta resuelta por Godot contra `CHRONOSHIFT_AUTOSAVE_TEST_PROFILE` y exige un directorio `autosave_tests` antes de escribir fixtures. La prueba F9 utiliza además la protección de aislamiento del controlador original.

| Prueba | Resultado |
|---|---|
| `tests/room_checkpoint_test.gd`, suite completa | PASS: 128 comprobaciones, 0 fallos |
| Seis conexiones hacia adelante y seis de regreso con Player y señales físicas reales | PASS: última sala, salud y progreso conservados |
| CONTINUAR en las siete salas: punto inicial, 3HP, suelo, ausencia de intersección y estabilidad | PASS |
| Muerte, movimiento, Shift, escena directa y checkpoint repetido | PASS: no generan escrituras adicionales |
| Fallo real de escritura: directorio aislado ocupa `.tmp`; Nueva Partida fallida | PASS: reversión de checkpoint y progreso |
| Marcador ausente, destino inexistente y fallo de `change_scene_to_file` con recurso no escena | PASS: checkpoint anterior conservado; traspaso fallido cancelado |
| v1 anterior, campo inválido, corrupción del principal y recuperación desde `.bak` | PASS |
| Espada, Lente, Llave, tutoriales, diálogos y victoria | PASS |
| Arranque en frío de cada una de las siete salas | PASS: 14 procesos separados, escritor y lector, todos con salida 0 |
| Menú renderizado a 1024×572 y 1280×720, clic, habilitado/deshabilitado | PASS en ambas resoluciones |
| Teclado Enter, Nueva Partida, continuación antes de recoger espada | PASS |
| Sala 5 pasiva, victoria persistente, E al final y botón de regreso | PASS |
| F9 repetido, desde otra sala y desde el final | PASS; conserva su perfil y no avanza checkpoint |
| `tests/progress_menu_test.gd` | PASS: música, opciones, continuación v1 y Nueva Partida |
| `tests/room_transition_test.gd` | PASS: tres idas/vueltas, salud, cámara, HUD y reinicio local |
| `tests/final_room_test.gd` | PASS: 0 fallos, acceso, animaciones, regreso, continuación y F9 |
| `tests/validate.gd` | PASS: salida 0, validación de sintaxis exitosa |
| `tests/core_guardian_victory_persistence_test.gd --check-only` | PASS: compila la expectativa de continuación actualizada |

Los casos negativos generan deliberadamente avisos de disco y errores de marcador/destino/carga. Son parte de las aserciones; no se ocultan. Las pruebas renderizadas usan eventos reales del viewport de Godot y capturas del juego, no una sesión humana manual. Las transiciones se prueban con fixtures de aproximación al área, seguidos por movimiento del Player y `body_entered`; no se afirma un recorrido manual completo desde el tutorial.

Durante el desarrollo de la suite acelerada se identificó un aviso de cierre del playback Ogg del menú. El teardown del test ahora detiene el audio y deja 100ms al hilo de audio para liberar sus recursos antes de salir. La ejecución final conserva las 128 comprobaciones PASS y ya no muestra avisos de recursos retenidos. No se cambió el audio de producción.

La suite histórica de combate K.2 contiene referencias al antiguo jefe de 6HP y dos etapas. Solo se actualizó su expectativa afectada de CONTINUAR y se comprobó su compilación; no se presenta esa suite histórica completa como aprobada. La persistencia y el acceso actuales se verifican en las suites nuevas y de FinalRoom.

El ejecutable indicado por AGENTS en Downloads corresponde a una carpeta, no a un archivo ejecutable. Se utilizó el binario instalado y verificado `C:\Godot\godot.exe.exe` (4.7.2) para ejecutar `--headless --path . --script res://tests/validate.gd`, sin modificar instalaciones ni configuraciones.

## Respaldo, archivos y protección del guardado real

Respaldo previo: `C:\Users\juans\chrono-shift-backups\autosave_rooms_20261117_145246`.

Incluye copias anteriores de los archivos editados, `source_before.json`, `backup_verification.json` con SHA-256 coincidentes, `real_saves_before.json`, perfiles de prueba y logs. `Run-Checks.ps1` en ese directorio reproduce las suites `main`, `cold`, `render`, `smoke` y `f9` con perfiles aislados; los escritores y lectores en frío comparten únicamente su perfil de caso. El resumen está en `artifacts/autosave_room_checkpoints/verification.json`.

Archivos de producción modificados:

- `scripts/game_progress.gd`: campo v1, destinos seguros, continuación y confirmación/rollback.
- `LevelTransition.gd`: acredita el origen del traspaso existente.
- `MainMenu.gd`: PNG original y destino del checkpoint.

Pruebas/documentación: nueva `tests/room_checkpoint_test.gd`; ajustes acotados de `tests/progress_menu_test.gd`, `tests/final_room_test.gd` y `tests/core_guardian_victory_persistence_test.gd`; `docs/STATE.md`, este informe y las capturas/resultados de `artifacts/autosave_room_checkpoints/`.

No se modificaron escenas, Player, combate, ataques, geometría, plataformas, física, sprites originales, BossHUD, sala final, lanzador/controlador F9, GDD, MCP, memoria ni credenciales. El editor informó sin cambios pendientes y sin partida en ejecución antes del respaldo y durante la verificación final.

SHA-256 del perfil real, idénticos antes y después:

- Principal: `E17420872503007B288DBC8E050E85BB449BFDFA0F644BB5D92E710FC4951CC8`.
- `.bak`: `55A0B0DF4981F1CDBD63EE9C05B7A612C045FC0270B2FB3EAA1AD4B702F9EEA6`.

El guardado real actual es un v1 anterior con victoria; al utilizar CONTINUAR aplicará el fallback histórico a Sala 1.5 hasta que una transición legítima registre su nueva última sala. No se modificó para imponerle un checkpoint retrospectivo.

## Pendientes

No quedan fallos funcionales encontrados en el alcance de checkpoints y menú. La suite histórica de combate de dos etapas mencionada arriba sigue fuera de esta tarea; no se migraron sus pruebas de ataques ni sus fixtures antiguos.
