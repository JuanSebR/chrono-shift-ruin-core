# Sala 5 — Verificación de la planificación

16 de noviembre de 2026. Este informe acredita documentación y diagnósticos estáticos, no gameplay.

## Alcance producido

- `ROOM5_MASTER_PLAN.md`: estado y diferencias con GDD; mapa físico candidato, composición de ambas dimensiones, cuentas de salto, cámara, árbol/contratos y doce fases con sus doce campos requeridos.
- `ROOM5_ASSET_INVENTORY.md`: 13 PNG de arena y 15 de jefe; medidas exactas, transparencia, funciones, regiones, conteos visibles y rects candidatos; cierre productivo pendiente A.
- `ROOM5_BOSS_DESIGN.md`: reglas RF-05,9 estados propuestos, ataques posibles y límites artísticos,2 etapas provisionales,12HP candidatos, Shift sin modificar, HUD, reintento, final, persistencia y19 decisiones con alternativas/aprobación.
- `diagrams/room5_architecture.html`, `diagrams/core_guardian_state_machine.html`, `diagrams/room5_boss_flow.html`: propuestas estáticas en estilo claro original elegido por el usuario.
- `room5_diagnostics/asset_metrics.json`, `frame_candidates.json`, `protected_hashes.json`: evidencia de medidas/recortes candidatos y conservación.
- `room5_diagnostics/arena_contact.png`, `boss_contact.png`: contacto visual de todos los originales, checkerboard de fondo para inspeccionar alfa.
- `room5_diagnostics/architecture_review.png`, `states_review.png`, `flow_review.png`: capturas de revisión de los HTML, no exports PNG de los diagramas para producción.

Los scripts Python auxiliares de generación se conservaron fuera del proyecto en el espacio de visualizaciones de Codex. No son código jugable ni dependencias nuevas. Se usó Pillow13 ya instalado y Microsoft Edge ya disponible. Los nombres `opaque_dark_pct` del JSON de métricas cuentan píxeles RGB casi negros con alfa mayor que cero; para RGBA describen oscuridad visible, **no** garantizan alfa255. Los porcentajes de alfa se obtienen por histograma separado. En RGB las cifras sí corresponden a fondo opaco.

## Validación efectuada

1. Lectura MCP antes y después: mismo proyecto, Room4, escena1654334234622, revisión10063650:0:1, protocolo4, jugando=false, unsaved=false. No se cambió escena ni se guardó/reimportó un recurso. No se diagnosticaron todos los recursos externos en caché: la garantía de unsaved pertenece a la escena activa.
2. Medidas reales de28 PNG: archivos originales intactos. Hash del primer frame64×64 de finishing atack1 comparado en memoria con attacking1 haz: RGBA exactamente iguales. Última celda64×64 de finishing vacía. Ningún recorte candidato repetido exactamente dentro de cada hoja; esto no equivale a certificar unicidad perceptual después de limpiar residuos/alinear poses.
3. `python .agents/skills/diagram-design/scripts/self_check.py <cada HTML>`:3 OK.
4. `python .agents/skills/diagram-design/scripts/verify_geometry.py <cada HTML>`:3 pases,0 hallazgos.
5. Render de los3 HTML con Edge headless en perfil temporal externo dedicado, capturas1400×1120 inspeccionadas visualmente. Sin solapamientos de nodos ni texto recortado en las vistas revisadas. Tipografías web declaradas con fallback del sistema; no se certificó por computedStyle la familia efectivamente resuelta ni se instaló ninguna fuente. Los HTML funcionan con fallback si las fuentes web no cargan.
6. Manifiesto SHA-256: **367 archivos originales protegidos;0 diferencias**. Incluye escenas/scripts/recursos/PNG del juego y project.godot; excluye caches de Godot y nuevos documentos. Verificado además que `scenes/Room5.tscn` no existe.
7. No se ejecutó validate ni pruebas del juego: no cambió GDScript y esta sesión no autorizaba implementación. Las suites A–L descritas son futuras, no resultados PASS. Tampoco se escribió progreso ni memoria.

## Cómo influyeron las skills

`game-designer` separó canon, observación, hipótesis de balance y decisiones por aprobar, y vinculó ataques a decisiones del jugador. `godot-gamedev` llevó a conservar APIs/sistemas reales, verificar parent inmediato de hurtbox y distinguir análisis estático de prueba física.

`diagram-design/SKILL.md`, sección0, exige ante guía sin personalizar: **“pause and ask the user”**. Se preguntó por estilo y el usuario eligió **estilo claro original**. Esa elección solo se aplicó a los nuevos HTML; no se modificó la guía, perfiles, marcador del proyecto ni configuración. Sus referencias de arquitectura, estados, flujo, presupuesto y primitivas guiaron los tres diagramas. No se usó un patrón semántico especial para la IA: la tabla de guardas requiere una máquina de estados ordinaria. Se mantuvieron8 componentes /9 estados /8 nodos de flujo y se trasladaron detalles a notas y tablas.

## Límites pendientes

No hay contrato definitivo de recortes por pose, anclajes ni FPS suministrado por artista; el conteo visible no autoriza usar rejillas uniformes que corten siluetas. El salto analítico y las coordenadas de mapa son propuestas sin simulación. Falta aprobación de Llave del Reactor, recomposición de arena, tamaño/normalización, repertorio/etapas y política de final/guardado. El directorio no dispone de Git; se requieren respaldos por fase. Las observaciones históricas de pruebas de combate/cierre siguen documentadas en el traspaso y no se reinterpretan como regresiones nuevas.

**Detención:** planificación entregada para revisión. Ninguna fase productiva A–L empezó. La autorización global del plan no sustituye la autorización independiente de cada fase.
