# Chrono-Shift: Ruin Core

- Proyecto desarrollado con Godot 4.x y GDScript.
- Usa la API moderna de Godot 4: `CharacterBody2D`, `TileMapLayer`, `move_toward()` y `Vector2.ZERO`.
- Declara tipos estaticos explicitos en variables y funciones de GDScript, por ejemplo: `var speed: float = 120.0`.
- Los mensajes de UI y logs deben usar la personalidad sarcastica y cinica de C.O.R.E.-9, "El Cinico Glitcheado".
- Tras modificar scripts, ejecuta `& "C:\Users\juans\Downloads\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/validate.gd` para verificar que no haya errores de compilacion.

## Herramientas MCP de Godot
- OpenCode usa la copia aislada ampliada configurada en `opencode.json`; el complemento del editor escucha en `127.0.0.1:6008`.
- Las herramientas `godot_editor_*` permiten inspeccionar y editar mediante deshacer/rehacer. Comprueba la identidad y revisión de la escena antes de modificarla y respeta la protección de guardado de recursos externos.
- El editor debe estar abierto con el complemento C.O.R.E.-9 Editor Bridge activo. Las herramientas originales adicionales están deshabilitadas selectivamente en la configuración local.

## Memoria y continuidad
- Para AgentMemory, utiliza siempre `project=chrono-shift-ruin-core` explícitamente en consultas y escrituras; no presupongas aislamiento por directorio.
- OpenViking utiliza la cuenta exclusiva `core-9` mediante un proceso local privado; no incluyas credenciales en el proyecto ni sincronices automáticamente ambas memorias.
- Consulta `docs/STATE.md` para el estado actual y `GDD.md` para la visión de diseño.
