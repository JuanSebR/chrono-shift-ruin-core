# Fase E: cinco escenas narrativas

Integrada el 10 de noviembre de 2026 en ROOM1 y ROOM1.5. Se reutiliza `DialoguePanel` y su registro de conversaciones únicas; no se alteraron Player, combate, Enemy1, HUD, físicas, colisiones, transiciones ni menú.

| ID persistente | Sala y activación | Tipo | Retratos |
| --- | --- | --- | --- |
| `awakening` | ROOM1, inicio de Nueva Partida cerca de X=45; al regresar por X=960 ya está completada | Tres líneas, avance E, bloquea controles | 1-01, 1-06, 1-03 |
| `corridor_memory` | ROOM1, X≥720, después del primer tramo deteriorado y fuera de la zona del tutorial de salto | Ambiente, 5 s | 1-04 |
| `old_tool` | ROOM1.5, señal real `sword_acquired` en X≈120, una vez termina la animación de recogida | Dos líneas, avance E, bloquea controles | 1-04, 1-03 |
| `movement_detected` | ROOM1.5, X410–559, antes de la patrulla de Enemy1 (X560–820), sin invulnerabilidad por daño | Ambiente, 5 s | 1-04 |
| `incident_resolved` | ROOM1.5, señal real `Enemy1.defeated` | Ambiente, 5 s | 1-06 |

Los textos son exactamente los cinco diálogos aprobados. Las tres escenas ambientales usan el mismo panel en tamaño discreto, no bloquean controles, no avanzan con E y se marcan completadas al expirar. Las conversaciones completas se marcan solo al cerrar la última línea. Si una escena ambiental coincide con una conversación activa, espera a que termine mientras permanezca en la misma sala; si se cambia de sala antes, se descarta y no queda marcada. Solo se muestra una intervención a la vez. Los tutoriales flotantes se ocultan mientras el panel está activo; al cerrar `old_tool`, reaparece el tutorial de ataque si sigue pendiente.

## Verificación

- PASS: cinco activaciones, contenido y avance de líneas, bloqueo y liberación, comentarios sin bloqueo, exclusión mutua, expiración, persistencia y reingreso, en copia `Core9_Combat_Isolated`.
- PASS: `tests/validate.gd`, `tests/progress_menu_test.gd`, `tests/attack12_test.gd`, `tests/room_transition_test.gd`.
- FAIL preexistente: `tests/combat_test.gd` mantiene cinco fallos de impacto. Se ajustó su recorrido para avanzar con E la nueva conversación de espada; así vuelve a la misma línea base de cinco fallos anterior a esta fase. `tests/player_presentation_test.gd` mantiene cuatro fallos de impacto, también presentes en la línea base de la fase anterior. No se modificó combate para ocultarlos.
- PASS visual estático: renders de introducción y comentario ambiental de Godot/OpenGL, ambos con texto dentro del marco; MCP confirma las escenas recargadas y los nodos `DialoguePanel` y `NarrativeEvents`. La reproducción visual interactiva sigue pendiente.
- Compatibilidad de guardados antiguos y Nueva Partida/Continuar: comprobada por la infraestructura de la fase anterior y la prueba de menú aislada. Esta fase no modifica el esquema del guardado.

Respaldo verificable de los archivos anteriores, pruebas y renders: `C:/Users/juans/AppData/Local/GodotMCPCodex/tests/narrative-phase-e-v1/`. Archivos modificados: `GameManager.gd`, `Room1_5.gd`, `scripts/ui/dialogue_panel.gd`, las dos escenas de salas, `tests/combat_test.gd`, este informe y `docs/STATE.md`. Archivo creado: `scripts/ui/narrative_events.gd`. Los seis retratos originales derivados permanecen intactos.
