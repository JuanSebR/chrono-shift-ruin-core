# Tutoriales y diálogos: fases A–D

Implementado el 10 de noviembre de 2026. La fase E sigue pendiente: ningún diálogo narrativo se activa en ROOM1 o ROOM1.5.

## Controles y secuencia

- ROOM1: `A / D — MOVERSE` aparece al iniciar una nueva partida en x45. Se completa tras 28 px de desplazamiento efectivo del Player. `ESPACIO — SALTAR` aparece desde x300, antes del ascenso del terreno cerca de x512, y se completa al detectar inicio de salto desde suelo. A/D, flechas, Espacio y mando continúan operando mediante InputMap. El cambio dimensional no recibe tutorial.
- ROOM1.5: `CLIC IZQUIERDO — ATACAR` aparece tras adquirir la espada en x120, con anclaje holográfico cerca del puente x300, antes de Enemy1 en x700. También aparece al entrar con la espada ya adquirida. Desaparece únicamente al recibir la señal existente `energy_slash_used`, emitida cuando Player acepta el ataque. La pista anterior de cinco segundos fue retirada. J y mando siguen siendo entradas válidas.
- El panel único se proyecta desde coordenadas del mundo con la transformación de cámara, se limita a la pantalla, ignora el ratón y no adquiere foco. Su capa 8 queda por debajo del CombatHUD de capa 10.

El estado de tutoriales y conversaciones únicas se guarda en el JSON v1 existente junto a `has_cronal_sword`. Los archivos antiguos, que solo contienen el booleano de espada, cargan con indicadores falsos. Continuar recupera el guardado; Nueva partida restablece espada, tutoriales y conversaciones. La muerte y los cambios de sala no borran las marcas.

## Retratos y diálogo

Las tres hojas y el marco originales son PNG RGBA de 2172 × 724. Se obtuvieron seis recortes de cabeza limpios de `expression sheet 1.png` en `assets/sprites/Dialogos/derived/`; no se modificó ninguna fuente. Las hojas 2 y 3 contienen 16 expresiones adicionales, pero sus siluetas cruzan límites de columna y el recorte rectangular directo incluye píxeles de retratos vecinos o corta el cabello. Permanecen disponibles en los originales para una separación manual posterior. La vista `expression-diagnostic.png` etiqueta las 22 posiciones originales; `portraits.json` enumera solo los seis derivados utilizables.

`DialoguePanel.tscn` muestra un retrato a la izquierda, el marco holográfico a la derecha y texto dinámico dentro del marco. Acepta varias líneas con `text` y `expression`, avanza con `dialogue_advance` (tecla E), emite señales de inicio y fin, impide dos conversaciones simultáneas, y permite conversaciones únicas persistentes o repetibles. Bloquea movimiento, salto, ataque y cambio dimensional durante su uso y libera los controles al cerrar o destruir el panel. Solo se activa desde código que lo instancie; no está añadido a las salas. El texto `Diagnostico de interfaz` es exclusivo del script de prueba aislada.

## Pruebas y límites

| Prueba | Resultado |
| --- | --- |
| `tests/validate.gd` en proyecto real, Godot 4.7.2 | PASS |
| Prueba aislada: movimiento, salto, ataque rechazado y aceptado, nueva partida, guardado antiguo, diálogo multilínea, duplicados, bloqueo y liberación | PASS |
| `tests/progress_menu_test.gd` en perfil aislado | PASS |
| `tests/attack12_test.gd` en perfil aislado | PASS |
| `tests/room_transition_test.gd` en perfil aislado | PASS |
| `tests/combat_test.gd` | FAIL: 5 comprobaciones de impacto de espada |
| `tests/player_presentation_test.gd` | FAIL: 4 comprobaciones de ventana de daño/derrota del enemigo |
| Repetición de combat y presentation con los archivos anteriores de Player y ROOM1.5 en la copia aislada | mismos 5 y 4 fallos; no introducidos por esta implementación |
| Render aislado de ROOM1 y panel de diálogo a 1024 × 572 | PASS visual estático; texto dentro del marco |
| MCP: identidad, escenas recargadas y nodos nuevos en ambas salas | PASS |
| Reproducción visual interactiva completa | PENDIENTE |

Las suites antiguas fallan en impacto de espada tanto con la implementación nueva como con Player/ROOM1.5 anteriores; la causa preexistente requiere diagnóstico independiente. No se cambiaron hitbox, daño, fotogramas, cooldown, Enemy1, colisiones ni transiciones.

Respaldo de los siete archivos originales, scripts de prueba, logs, comparaciones y vista visual: `C:/Users/juans/AppData/Local/GodotMCPCodex/tests/tutorial-dialogue-v1/`. Los respaldos fueron tomados antes de editar. La carpeta `project/` es la copia aislada que usa el perfil `Core9_Combat_Isolated`; ninguna prueba escribió en el progreso real del usuario.
