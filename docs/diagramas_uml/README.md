# Diagramas UML de Chrono-Shift: Ruin Core

Esta carpeta contiene siete diagramas UML de la versión implementada del videojuego. Las fuentes editables están en PlantUML (`.puml`) y cada fuente se entrega también como SVG y PNG de alta resolución. El estilo es UML clásico, de fondo blanco y trazos oscuros, pensado para documentación académica y compatible visualmente con el registro de herramientas como Astah. Los `.puml` son fuentes PlantUML; no se presentan como archivos nativos de Astah.

## Contenido

- `casos_de_uso_menu_y_progreso`: reúne Nueva Partida, Continuar, guardado automático, reinicio tras morir y regreso al menú.
- `casos_de_uso_jugabilidad`: presenta movimiento, espada, cambio dimensional, interacción, habilidades y superación de salas como objetivos del jugador.
- `casos_de_uso_combate_y_cierre`: resume los enemigos, el Guardián del Núcleo, el acceso condicionado al cierre y el regreso al menú.
- `secuencia_guardado`: representa Nueva Partida, Continuar, el handoff efímero entre salas y la confirmación diferida del checkpoint. Distingue `GameProgress` del guardado real mediante `FileAccess` y `DirAccess`.
- `secuencia_combate`: documenta la activación física de Sala 5, la introducción, los tres ataques, el ciclo de 45 segundos, la vulnerabilidad de 6 segundos, el daño, `BossHUD` y la persistencia de la victoria.
- `secuencia_final`: muestra las condiciones reales de `FinalAccessDoor`, la interacción `E · SALIR`, la validación de `FinalRoom` y el regreso al menú.
- `diagrama_clases`: presenta la arquitectura principal de scripts y controladores. Se omiten nodos puramente visuales y miembros secundarios para conservar legibilidad.

## Fuentes de implementación consultadas

- `project.godot`: autoloads `GameProgress` y `BackgroundMusic`, escena principal y mapa de entrada.
- `Player.gd`, `GameManager.gd`, `DimensionManager.gd`, `LevelTransition.gd` y `MainMenu.gd`.
- `scripts/game_progress.gd`: formato v1, Nueva Partida, Continuar, handoff de llegada, checkpoint y victoria.
- `scripts/rooms/room2.gd`, `room3.gd`, `room4.gd` y `room5.gd`.
- `scripts/bosses/core_guardian.gd`, `guardian_vertical_burst.gd`, `guardian_horizontal_laser.gd` y `guardian_direct_projectile.gd`.
- `scripts/ui/combat_hud.gd` y `boss_hud.gd`.
- `scripts/ending/final_access_door.gd` y `final_room.gd`.
- `scenes/Room5.tscn`, `scenes/bosses/CoreGuardian.tscn`, `scenes/MainMenu.tscn` y `scenes/FinalRoom.tscn`.
- `docs/STATE.md`, `docs/AUTOSAVE_ROOM_CHECKPOINTS.md`, `docs/GUARDIAN_FINAL_TUNING.md`, `docs/GUARDIAN_THREE_ATTACKS.md` y `docs/FINAL_ROOM.md`.

## Parámetros reflejados

### Convenciones de los casos de uso

- `Guardar progreso automáticamente` no mantiene una asociación manual con **Jugador**. Nueva Partida lo incluye porque `GameProgress.new_game()` exige guardar el estado inicial antes de cargar la sala.
- `Reiniciar sala tras morir` representa el reinicio automático posterior a la derrota y por ello tampoco se asocia como una acción manual del actor.
- `Combatir contra el Guardián del Núcleo` especializa `Enfrentar enemigos` mediante generalización UML.
- `Acceder al cierre` tiene como precondición que el Guardián esté derrotado y que la victoria haya sido persistida.

- Jugador: 3 HP; cooldown de espada de 0,35 s; protección temporal de 0,16 s.
- Cambio dimensional: cooldown de 0,20 s.
- Guardián: 3 HP; fase ofensiva de 45 s; sobrecalentamiento vulnerable de 6 s.
- Láser vertical: aviso de 1,4 s y fase activa de 0,75 s.
- Láser horizontal: aviso de 0,75 s y fase activa de 0,5 s.
- Proyectil directo: preparación de 0,6 s, 900 unidades/s y vuelo máximo de 1,8 s.
- Victoria: hasta 2 intentos de persistencia, separados por 1 s.

## Regeneración

Los archivos se generaron con PlantUML 1.2025.3 y Graphviz. Desde la raíz del proyecto:

```powershell
$jar = "C:\Users\juans\.astah\professional\cache\bundle43\version0.0\bundle.jar-embedded\plantuml-1.2025.3.jar"
$env:PLANTUML_LIMIT_SIZE = "8192"
& java '-Dfile.encoding=UTF-8' -jar $jar -charset UTF-8 -tpng -Sdpi=220 "docs\diagramas_uml\*.puml"
& java '-Dfile.encoding=UTF-8' -jar $jar -charset UTF-8 -tsvg "docs\diagramas_uml\*.puml"
```

PlantUML informa errores de sintaxis en el código de salida y devuelve un código distinto de cero cuando la generación no es válida.
