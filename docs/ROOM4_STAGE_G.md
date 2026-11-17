# Room4 · Fase G

| Salida | Centro del área | Llegada |
|---|---|---|
| Room3 → Room4 | (1630, 680), arco derecho | FromRoom3 (64, 396), hacia la derecha |
| Room4 → Room3 | (38, 396), extremo izquierdo | FromRoom4 (1570, 703), hacia la izquierda |

Ambas puertas reutilizan LevelTransition. Room3 activa la salida después de guardar la Lente y terminar la adquisición. Se llega al arco saltando sobre el pedestal existente. La repisa inicial de Room4 y el marcador de retorno de Room3 están fuera de las áreas de sus puertas. Cada entrada a Room4 crea un gestor en Presente con recarga cero y checkpoint Spawn. El regreso conserva salud, espada, Lente y pedestal vacío. FutureRoom5Access (1188, 264) es un marcador.

El componente TutorialHints presenta un aviso contextual a la vez. SHIFT se completa con un cambio aceptado por el gestor. PRESENTE se completa por contacto de suelo con MetalLeft, incluso antes del primer Shift. PASADO exige un salto con cambio confirmado al Pasado y contacto de suelo con PastLeft en ese mismo vuelo. El aterrizaje y la recuperación limpian la evidencia temporal del salto. Los avisos se ocultan con controles bloqueados o diálogo activo.

GameProgress amplía la lista de claves de tutoriales del guardado v1. Los guardados antiguos reciben valores false para las nuevas claves, Continuar recupera los valores guardados y Nueva Partida los reinicia. No se introducen campos nuevos ni persistencia de checkpoints.

Pruebas con perfil aislado: adquisición real, acceso, ida y vuelta desde Pasado, reingreso y persistencia de avisos. Pasaron también las regresiones de caída, recorrido, dimensión, HUD, escena base y validate. Las pruebas base y de caída ahora verifican el retorno autorizado en lugar de exigir un contenedor vacío. Algunas regresiones repiten avisos de liberación al cerrar.

Capturas del viewport de Godot en artifacts/room4_stage_g. Fase H queda pendiente.
