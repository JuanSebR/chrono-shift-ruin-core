# Chrono-Shift: Ruin Core · Traspaso de Codex

## 1. Identificación del proyecto

Proyecto local en `C:/Users/juans/chrono-shift-ruin-core`. Godot 4.7.2, GDScript y destino Windows. Abrir `project.godot`. El arranque normal es [MainMenu.tscn](../scenes/MainMenu.tscn). El juego es un micro-metroidvania 2D en la Torre Zaman, con plataformas, combate y alternancia entre Presente y Pasado. El [GDD v1.2](../GDD.md) contiene la visión de diseño. Para determinar qué funciona hoy, consultar escenas, scripts e informes de prueba.

## 2. Estado general

El recorrido disponible en disco comprende seis escenas jugables bidireccionales: Room1 ↔ Room1.5 ↔ Room2 ↔ Room2.2 ↔ Room3 ↔ Room4. La Fase H cerró el tutorial dimensional de Room4. La protección temporal y su efecto visual se implementaron y validaron después. Falta verificar las seis salas en una sola partida desde el comienzo.

El 16 de noviembre de 2026, `git status --short --branch` devolvió que la carpeta no pertenece a un repositorio Git. Rama, archivos rastreados y cambios o archivos nuevos respecto de Git quedan sin clasificación. El historial de este proyecto usa respaldos, entre ellos [backups/](../backups/) y los registrados en [STATE.md](STATE.md). Conservar el disco actual como punto de partida, en especial las plataformas de Room2 ajustadas por el usuario. Para ediciones futuras, respaldar los archivos afectados y verificar sus hashes antes de aplicar cambios.

## 3. Salas implementadas

| Sala | Escena y comportamiento |
|---|---|
| **1 · Tutorial** | [Room1_Tutorial.tscn](../scenes/Room1_Tutorial.tscn). Movimiento lateral y salto con el Player compartido, bajada segura y límite izquierdo. Enseña movimiento y salto mediante ayudas contextuales. Comparte con Sala 1.5 cinco secuencias del guion de Fase E, incluyendo diálogos con retratos y comentarios ambientales. Puerta bidireccional a Sala 1.5. Una partida nueva empieza sin espada ni Lente: el ataque está bloqueado hasta la espada y Shift está bloqueado hasta poseer la Lente. Room1 conserva el modo histórico TileMapLayer para un regreso posterior. |
| **1.5 · Espada** | [Room1_5.tscn](../scenes/Room1_5.tscn). Puente permanente, espada cronal coleccionable mediante [CronalSwordPickup.tscn](../scenes/items/CronalSwordPickup.tscn), ayuda contextual de ataque y Autómata de Guardia con patrulla y proyectiles. Reutiliza el daño por ventana de la espada. Conecta con Sala 1 y Sala 2 mediante marcadores de llegada. |
| **2 · Mantenimiento** | [Room2.tscn](../scenes/Room2.tscn). Escenario industrial con suelo, pendiente y apoyos elevados. La escalera de mantenimiento atraviesa apoyos unidireccionales y conduce a Upper. El acceso superior conecta con Sala 2.2 y el otro acceso vuelve a Sala 1.5. Hay dos guardias (GuardA y GuardB), cámara de seguimiento del Player con límites 1672 × 941 y CombatHUD compartido. Usar las posiciones del archivo actual, ya ajustadas manualmente. Preservar la geometría en vez de reponerla desde informes o respaldos. |
| **2.2 · Transporte** | [Room2_2.tscn](../scenes/Room2_2.tscn). Plataforma cian sólida de ida y vuelta con AnimatableBody2D, X=260–365, superficie Y=440, 60 px/s y pausa de 1 s en cada extremo. Embarque, traslado y desembarque con la física del Player. Tres guardias y cámara limitada a 2172 × 724. Pasar por debajo de Y=750 desencadena derrota local y reinicio. Accesos activos hacia Sala 2 y Sala 3. [El informe provisional](ROOM2_2_PROVISIONAL.md) conserva una versión anterior de la puerta y la caída. |
| **3 · Adquisición** | [Room3.tscn](../scenes/Room3.tscn). Pedestal al 85 % con arte derivado. El módulo levita en bucle de seis cuadros. En el área de interacción y con el Player en suelo aparece E. La recogida bloquea el control y la puerta de retorno mientras el Player reproduce 12 cuadros y el módulo desaparece. Al guardar con éxito, se oculta el módulo y queda habilitada la puerta a Room4. Volver conserva la Lente y muestra el pedestal vacío. Retorno a Room2.2 por la izquierda y acceso a Room4 por el arco derecho, saltando el pedestal. El montaje usa [derivados de Sala 3](../assets/tiles/sala%203/derived/) y admite una mejora artística opcional futura. [Capturas del pedestal](../artifacts/room3_altar_fix/). |
| **4 · Tutorial dimensional** | [Room4.tscn](../scenes/Room4.tscn). Presente rojo, Pasado azul, siete apoyos y alternancia real con Shift. Incluye tutorial contextual, HUD dinámico, checkpoints y retorno a Sala 3 desde ambas dimensiones. La repisa final tiene el marcador FutureRoom5Access, reservado para una salida futura. |

## 4. Mecánicas compartidas

| Componente | Responsabilidad |
|---|---|
| [Player.gd](../Player.gd) y [Player.tscn](../scenes/Player.tscn) | CharacterBody2D compartido para movimiento, salto, presentación, espada, daño, protección temporal y derrota. Collider principal de 24 × 40 e integridad máxima de 3. Ataque de 12 cuadros a 24 FPS, 0,50 s de presentación, recarga de 0,35 s y ventana de daño de 0,10 s. |
| [GameManager.gd](../GameManager.gd) | Control de sala empleado por Room1. Conecta Player, gestor dimensional y HUD, procesa la ruta histórica de Shift y atiende salud y derrota. Room2 y sus derivadas usan [room2.gd](../scripts/rooms/room2.gd), con comportamiento local en [room2_2.gd](../scripts/rooms/room2_2.gd), [room3.gd](../scripts/rooms/room3.gd) y [room4.gd](../scripts/rooms/room4.gd). |
| [GameProgress](../scripts/game_progress.gd) | Autoload de posesión, tutoriales, diálogos, guardado y transferencia entre salas. |
| [DimensionManager.gd](../DimensionManager.gd) | Alterna colisiones y visibilidad de los grupos de Room4 en física. Comprueba si las formas de destino penetran al jugador, acepta o rechaza el cambio y publica las señales. Conserva la ruta histórica por TileMapLayer de Room1. |
| [CombatHUD](../scripts/ui/combat_hud.gd) y [TemporalLensHUD](../scripts/ui/temporal_lens_hud.gd) | HUD compartido de salud, alertas y mensajes, con una instancia del indicador circular de la Lente. |
| [Enemy1](../scripts/enemies/enemy1.gd) | Autómata reutilizado en Sala 1.5, Sala 2 y Sala 2.2. Patrulla, detecta, dispara y reacciona a daño y derrota. Su [proyectil](../scripts/combat/enemy_projectile.gd) usa Player.take_damage(). |
| [LevelTransition.gd](../LevelTransition.gd) | Transiciones por Area2D. Comprueba el cuerpo, registra el estado de llegada y carga la escena destino con su Marker2D. |
| [DialoguePanel](../scripts/ui/dialogue_panel.gd), [NarrativeEvents](../scripts/ui/narrative_events.gd) y [TutorialHints](../scripts/ui/tutorial_hints.gd) | Presentación, avance y bloqueo de diálogos, disparadores y comentarios ambientales de Room1/1.5, y ayudas de entrada contextual. Room4 tiene [controlador de tutorial propio](../scripts/rooms/room4_tutorial.gd) para sus tres aprendizajes. |

## 5. Sistema de progreso

GameProgress escribe en `user://progress_v1.json`. El esquema v1 registra espada, Lente, aprendizajes y diálogos completados. Continuar recupera esos datos y carga Room1.5 si está adquirida la espada. Nueva Partida reinicia el progreso, carga Room1 y permite volver a encontrar el módulo. Para el cambio directo de sala, el autoload pasa en memoria marcador, integridad, orientación, invulnerabilidad normal y recarga de ataque. La llegada usa velocidad cero. Los checkpoints de Room4, su dimensión, la recarga de Shift y la protección temporal pertenecen a la instancia.

## 6. Lente Temporal

1. **Posesión permanente.** Room3 ejecuta `acquire_temporal_lens()` de GameProgress tras la recogida. La posesión habilita Shift donde hay gestor y persiste al salir, regresar, perder o usar Continuar. Nueva Partida la restablece.
2. **Cambio real.** Room4 encola la acción `dimension_shift` y la resuelve en física antes de Player. Comprueba posesión, recarga y espacio de destino. Al aceptar, cambia colisiones, grupos visuales y dimensión. El rechazo conserva el estado y emite aviso.
3. **Recarga de 0,20 s.** Empieza con cada cambio confirmado de Room4. La fuente del tiempo es DimensionManager.
4. **Protección de 0,16 s.** Timer independiente del Player que empieza al confirmar el cambio real de Room4, antes de emitir `dimension_changed`. Un golpe normal se descarta sin tocar la salud, HUD ni los 60 pasos físicos de invulnerabilidad por daño. El proyectil se consume al impactar. La protección termina al vencer, caer al checkpoint o ser derrotado. Un rechazo, la ausencia de la Lente y el toggle histórico de Room1 no la disparan.
5. **HUD.** Oculto sin posesión, neutral con Lente en salas sin alternancia dinámica, disponible por dimensión en Room4. El HUD sigue la recarga real y, durante la protección, reutiliza LensIcon con cinco poses gobernadas por el Timer del Player. Después vuelve a la recarga ya avanzada. El aviso de rechazo tiene su propia duración.
6. **Recuperación.** Room4 cancela solicitudes, protección y recarga. Restaura Presente disponible, velocidad cero, orientación derecha y cámara en el checkpoint, conservando salud y posesiones. Room2.2 aplica su derrota local al caer.

Detalle y resultados en [TEMPORAL_SHIFT_PROTECTION.md](TEMPORAL_SHIFT_PROTECTION.md). Pruebas específicas en [temporal_shift_protection_test.gd](../tests/temporal_shift_protection_test.gd) y [temporal_lens_protection_visual_test.gd](../tests/temporal_lens_protection_visual_test.gd).

## 7. Estado de Room4

- Tres apoyos compartidos, dos plataformas metálicas activas en Presente y dos escalones activos en Pasado. Los apoyos exclusivos de la otra dimensión se muestran como fantasmas. El fondo industrial inferior es decorativo. Preservar geometría, colores y recorrido de la Fase H.
- Spawn (64,396) y CentralCheckpoint (646,442). El segundo exige contacto físico con la plataforma central y dura hasta abandonar esa instancia. Se recupera al cruzar Y=680 con los pies y se puede volver a jugar sin penalización de salud.
- Room3 → Room4 por el arco derecho de Room3 (1630,680), con llegada en Spawn y Presente. Room4 → Room3 por el extremo izquierdo, con llegada en FromRoom4 (1570,703), pedestal vacío y HUD neutral. FutureRoom5Access (1188,264) es Marker2D.
- [Fase H](ROOM4_STAGE_H.md) documenta el cierre jugable, siete apoyos, caída real en ambas secciones, tres aprendizajes, retorno desde ambas dimensiones e integración desde el tramo final de Room2.2. Los [renders de Fase H](../artifacts/room4_stage_h/) cubren los hitos a 1024 × 572 y 1280 × 720.

## 8. Audio y HUD

[Player.tscn](../scenes/Player.tscn) y [Player.gd](../Player.gd) gestionan pasos, aterrizaje y espada con reproductores de SFX. [MainMenu.tscn](../scenes/MainMenu.tscn) reproduce ambiente de inicio en Music, y el volumen de opciones ajusta Master. Fuentes y derivados en [assets/Sonidos](../assets/Sonidos/) y buses en [default_bus_layout.tres](../default_bus_layout.tres). La carpeta incluye `Enemy1_Sound.wav` como fuente. El [test de audio del guardia](../tests/enemy_audio_test.gd) comprueba patrulla, disparo y derrota silenciosos. [CombatHUD.tscn](../scenes/ui/CombatHUD.tscn) reúne integridad, pérdida de salud, alerta crítica, mensajes y [TemporalLensHUD.tscn](../scenes/ui/TemporalLensHUD.tscn). Los cinco gráficos de protección tienen alfa real y derivan del original de [assets/Barras](../assets/Barras/). La estética roja/azul del escenario y los iconos cian/magenta de disponibilidad usan paletas distintas.

## 9. Herramientas disponibles

- **Godot MCP ampliado.** En OpenCode, las entradas `godot` y `openviking_core9` existen en [opencode.json](../opencode.json). Codex expuso las herramientas `mcp__godot__editor_*`. [project.godot](../project.godot) habilita C.O.R.E.-9 Editor Bridge. El complemento escucha según AGENTS en 127.0.0.1:6008.
- **Editor el 16/11.** `editor_get_state` devolvió `EDITOR_BRIDGE_UNAVAILABLE`. Tampoco se observó un proceso Godot ni un listener en el puerto 6008. Escena activa, marca de cambios sin guardar y ejecución quedaron sin verificación en vivo. Room3 y Room4 existen en disco. La comprobación histórica de Fase H las registró guardadas y detenidas. Al disponer del puente, consultar estado, identidad y revisión de escena antes de cualquier edición y atender la protección de guardado de recursos externos.
- **OpenViking dedicado.** `openviking_core9.health` respondió saludable con VikingFS. La memoria de `core-9` usa un proceso local privado y sigue aislada de otros proyectos. Conservar el aislamiento y evitar sincronizaciones automáticas con AgentMemory.
- **AgentMemory.** [AGENTS.md](../AGENTS.md) exige el filtro explícito `project=chrono-shift-ruin-core` para consultar o escribir. Esta sesión carecía de una herramienta AgentMemory expuesta para confirmar su conexión. La cuenta entrante debe verificar sus propias conexiones y credenciales.

### Diagram Design — herramienta de diagramación

- **Origen e instalación.** [Repositorio oficial](https://github.com/cathrynlavery/diagram-design), revisión [f6db0decea96de66b901331a0f79a8d4b147ebae](https://github.com/cathrynlavery/diagram-design/tree/f6db0decea96de66b901331a0f79a8d4b147ebae). Copia directa del directorio oficial `skills/diagram-design/` en `C:/Users/juans/chrono-shift-ruin-core/.agents/skills/diagram-design/`. Para reproducirla, extraer ese directorio de la revisión indicada y copiarlo completo, incluidos `assets/`, `references/` y `scripts/`. Es una skill local para documentación. La instalación no requiere un plugin de marketplace ni un servidor MCP.
- **Uso.** Abrir la raíz del proyecto en Codex Desktop y escribir `$diagram-design` junto con el pedido, por ejemplo, «prepara un diagrama de arquitectura de Godot». Esta instalación independiente se invoca como skill. Los comandos slash adicionales de Diagram Design pertenecen al paquete nativo. Guardar diagramas futuros con nombres descriptivos en `docs/diagrams/`, que se podrá crear en el primer uso.
- **Formatos y requisitos.** Salida principal HTML con SVG en línea y un navegador moderno para abrirla. Los validadores, importadores y la exportación SVG usan Python 3. El equipo tiene Python 3.14.5. La exportación PNG requiere el paquete Python Playwright y su Chromium. Playwright no estaba instalado y el flujo PNG queda pendiente. Los HTML y SVG con tipografía web pueden cargar Google Fonts. Para un flujo sin esa solicitud, elegir `Font source: system` en el perfil. El uso local de la skill no requiere Node.js, claves API ni servicios adicionales. [Política de privacidad](https://github.com/cathrynlavery/diagram-design/blob/f6db0decea96de66b901331a0f79a8d4b147ebae/PRIVACY.md).
- **Estilo del proyecto.** Emplear cian neón `#00F0FF`, rosa neón `#FF0055`, gris oscuro `#1A1A24`, negro profundo `#0A0A0C` y naranja ámbar `#F6AA1C`. Mantener una interfaz oscura gótico-industrial y chronopunk, con buen contraste, jerarquía visible, conectores claros, espaciado uniforme, etiquetas cortas y ausencia de solapamientos. Para fijar la paleta más adelante, preparar una copia completa de la guía de estilo como perfil `~/.diagram-design/profiles/chrono-shift.md` y seleccionarla con un archivo `.diagram-design` de una línea, `profile: chrono-shift`, en la raíz. Este flujo lee el perfil directamente y permite conservar intacta la guía distribuida. El perfil y el marcador quedan para una sesión futura. [Formato de perfiles](../.agents/skills/diagram-design/references/profiles.md).
- **Verificación y cambio de cuenta.** Codex `0.169.0-alpha.11.1` devolvió la ruta correcta con ámbito `repo` y `enabled: true` en `skills/list`. Los 317 archivos coincidieron con la revisión descargada. `self_check.py` y `verify_geometry.py` pasaron sobre el ejemplo oficial de arquitectura. En la próxima cuenta, abrir un chat local en la raíz y comprobar que `$diagram-design` aparece. Si el selector no se actualiza, reiniciar Codex y volver a comprobar. La cuenta entrante todavía no se ha verificado. [Descubrimiento de skills en Codex](https://learn.chatgpt.com/docs/build-skills#where-codex-loads-local-skills).
- **Respaldo.** La carpeta de la skill y esta ampliación del traspaso son posteriores al ZIP validado antes del cambio de cuenta. El ZIP anterior se conservó. Para recuperar la skill a partir de ese respaldo, repetir la copia de la revisión fijada arriba.

### GameDev Skills — diseño y desarrollo Godot

Instaladas el 16 de noviembre de 2026 desde [setcodes/gamedev-skills](https://github.com/setcodes/gamedev-skills), commit exacto `096c224aa498a789fa99d476583029fcb9f538e1`. Ambas declaran versión `1.0.0` y licencia MIT de Egor Maximov (Setcode), incluida en cada carpeta. Se copiaron exclusivamente los directorios oficiales seleccionados desde una descarga temporal. Las actualizaciones futuras requieren elegir y revisar otra revisión específica.

- [game-designer](../.agents/skills/game-designer/SKILL.md) está en `C:/Users/juans/chrono-shift-ruin-core/.agents/skills/game-designer/`. Sus seis archivos incluyen SKILL.md, LICENSE, agents/openai.yaml y tres referencias de sistemas, playtesting y enseñanza. Invocar `$game-designer` para planificación, GDD, progresión, encuentros y fases del combate.
- [godot-gamedev](../.agents/skills/godot-gamedev/SKILL.md) está en `C:/Users/juans/chrono-shift-ruin-core/.agents/skills/godot-gamedev/`. Sus cuatro archivos incluyen SKILL.md, LICENSE, agents/openai.yaml y la referencia de verificación. Invocar `$godot-gamedev` para implementar o revisar fases autorizadas con Godot 4.7.2, usando `C:/Godot/godot.exe.exe` y las herramientas existentes.
- Ambas son guías de texto, sin scripts ejecutables, paquetes adicionales ni servidores MCP requeridos. La revisión de su contenido no encontró acceso a credenciales ni instrucciones de instalación privilegiada. Las referencias de Godot incluyen comandos ilustrativos que deben adaptarse al alcance autorizado y a la versión del proyecto.
- Aplicar primero las instrucciones del usuario y del entorno, AGENTS.md, el diseño aprobado del GDD, el estado real de escenas y scripts y la documentación de continuidad. Las recomendaciones generales de las skills deben ajustarse a esa información. Conservar la arquitectura existente y someter cualquier reemplazo de un sistema funcional a una fase aprobada.
- Combinar `$game-designer` con `$diagram-design` para planificación visual futura y usar `$godot-gamedev` al implementar las fases aprobadas. Diagram Design conserva su contenido y revisión.
- Codex `0.169.0-alpha.11.1` reconoció las tres skills mediante `skills/list`, con ámbito `repo` y `enabled: true`. Se cotejaron los diez archivos nuevos con la revisión oficial y se verificaron enlaces internos, licencias y metadatos. SHA-256 de SKILL.md de game-designer: `db793b3fdbbbe569cfd0e11e45f953e04d2eb245190c83995a480724e6fa3ac2`. SHA-256 de SKILL.md de godot-gamedev: `44dc291eba09a3b4703ca8efb4af11d610e24f348657f5747224ceaa5b2af7d3`.
- En la próxima cuenta, abrir la misma raíz local y comprobar los tres nombres en el selector. Si no aparecen, abrir un chat nuevo o reiniciar Codex y repetir la consulta. El reconocimiento en esa cuenta queda pendiente. Las conexiones Godot MCP y OpenViking siguen sujetas a la verificación de la cuenta entrante. AgentMemory debe usar `project=chrono-shift-ruin-core`.
- Estas incorporaciones y la actualización de continuidad son posteriores al respaldo principal. Se preparó un complemento independiente en `C:/Users/juans/chrono-shift-backups/gamedev_skills_20261116.zip` con las tres skills y este documento.

## 10. Pruebas importantes

Resultados históricos de los informes. Este traspaso usó inspección estática y ejecutó cero pruebas de juego.

| Área | Archivos bajo [tests/](../tests/) y evidencia |
|---|---|
| Movimiento y recorrido | `room2_stair_route_test.gd` recorrió el ascenso y descenso con inputs según [ROOM2_STAIR_ROUTE](ROOM2_STAIR_ROUTE.md). [Fase D de Room2](ROOM2_STAGE_D.md) registra apoyo, salto y aterrizaje aprobados. Existen `room2_camera_follow_test.gd`, `room22_transport_test.gd` y `room22_guards_test.gd`; resultado reciente sin confirmar en los informes consultados. |
| Combate y espada | `attack12_test.gd` PASS en fase narrativa E y Room2 F. `combat_test.gd` y `player_presentation_test.gd` registraron 5 y 4 fallos de impacto respectivamente en las fases narrativas, reproducidos con archivos anteriores. El informe original de combate registra 28 comprobaciones aisladas aprobadas en su fase. Ambas suites exigen una copia con `application/config/name = Core9_Combat_Isolated`, además de aislar el guardado. El informe de protección indica que omitió `combat_test.gd` por esa precondición. |
| Salud y derrota | `room2_health_test.gd` y `room2_health_transfer_test.gd` PASS en [Room2 F](ROOM2_STAGE_F.md). `room2_health_test.gd` y `room22_void_death_test.gd` PASS en el informe de protección. |
| Audio | `player_movement_audio_test.gd`, `player_sword_audio_test.gd` y `enemy_audio_test.gd` existen. Sin resultado confirmado en los informes consultados. La verificación auditiva se omitió en la campaña de protección. |
| Transiciones y progreso | `room_transition_test.gd`, `room2_transition_test.gd`, `room3_room4_transition_test.gd` y `room4_final_integration_test.gd` PASS en Fase H. `progress_menu_test.gd` PASS en fase narrativa E. |
| Adquisición y HUD temporal | `room3_room4_transition_test.gd`, `temporal_lens_hud_test.gd`, `temporal_lens_hud_dynamic_test.gd` y la integración final PASS en Fase H. Existe `temporal_lens_lock_test.gd`; resultado reciente sin confirmar en los informes consultados. |
| Dimensión, ruta y caída | `room4_base_test.gd`, `room4_dimension_test.gd`, `room4_route_test.gd`, `room4_fall_recovery_test.gd` y `room4_tutorial_test.gd` PASS en Fase H. |
| Protección y validación | `temporal_shift_protection_test.gd`, `temporal_lens_protection_visual_test.gd` a 1024×572 y 1280×720 y `validate.gd` PASS según el informe de protección. |

Para pruebas que escriben progreso, usar perfiles de APPDATA aislados y ejecutar secuencialmente. La Fase H usó reloj fijo de 60 FPS. Para validar tras cambios en scripts, desde la raíz:

```powershell
& "C:\Users\juans\Downloads\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/validate.gd
```

## 11. Problemas conocidos

- Algunas pruebas reportaron ObjectDB y recursos aún en uso al cerrar. Las aserciones de recuperación pasaron y la última corrida citada terminó con código 0 y cuatro recursos reportados. Falta investigar el cierre y medir sesiones largas.
- Un fallo temporal del HUD en ejecución concurrente dejó de aparecer en los pases secuenciales de Fase H.
- Las suites antiguas de combate y presentación conservan la deuda de investigación de los fallos de impacto. Sigue pendiente revisar visualmente de forma interactiva transiciones, ataque y reproducción del menú donde los informes documentaron solo capturas.
- [STATE.md](STATE.md) registra una marca histórica de guardado de `core9_presentation_attack12.tres`. Su estado en vivo sigue por verificar. Si reaparece, diagnosticar antes de guardar o recargar.

## 12. Pendientes priorizados

1. Verificar las seis salas en una sola partida desde el inicio, con progreso aislado. La integración de Fase H empieza en el tramo final de Room2.2.
2. Investigar avisos de cierre y fallos históricos de combate en sesiones separadas.
3. Incorporar e inspeccionar el material entregado de Sala 5 y del Guardián del Núcleo. Preparar el plan maestro de Sala 5 para aprobación.
4. Cuando exista la escena de Sala 5 y se autorice la fase correspondiente, preparar la salida desde FutureRoom5Access e implementar el jefe final y su combate por fases aprobadas.
5. Considerar la mejora artística opcional del montaje de Sala 3 con los originales a salvo.

## 13. Recursos nuevos de Sala 5

El colaborador ya entregó al usuario los gráficos de Sala 5, el diseño del jefe final y sus sprites y animaciones. La búsqueda se restringió al proyecto y revisó nombres, estructura de assets y los recursos de enemigos existentes. No se identificaron archivos atribuibles con seguridad a Sala 5 o al Guardián del Núcleo. Los recursos entregados todavía deben incorporarse al proyecto para analizarlos. Tampoco se encontró una escena de Sala 5. El marcador de Room4 es la referencia concreta de enlace. El inventario se podrá elaborar cuando estén los archivos fuente.

## 14. Instrucciones para la próxima sesión

- Abrir el mismo proyecto local y verificar las conexiones de la cuenta entrante. Consultar primero el estado del editor. Si hay cambios manuales pendientes, preservar el estado y documentar la discrepancia con disco antes de guardar o recargar. El cambio de cuenta se realiza manualmente.
- Conservar diseño original, proporciones compactas y animaciones de C.O.R.E.-9. Mantener su voz sarcástica y cínica en UI y logs, la estética gótico-industrial y chronopunk, y las paletas aprobadas.
- Conservar físicas del Player y las plataformas manuales, especialmente las de Room2, así como la geometría aprobada de Room4. Preservar los gráficos fuente y producir derivados no destructivos. Reutilizar Player, escenas compartidas, combate, HUD y DimensionManager.
- Trabajar con prompts por fases. El usuario aprueba cada fase antes de continuar. Registrar respaldo verificable antes de editar. Presentar el árbol propuesto para escenas complejas, comprobar identidad y revisión en el MCP y usar constructores Godot para recursos `.tres`.
- Usar API de Godot 4 y tipos estáticos explícitos en GDScript. Ejecutar validación general y las pruebas pertinentes. Conservar las aserciones y reportar cualquier fallo con evidencia.
- El alcance de este traspaso es documental. Para iniciar Sala 5 o modificar el juego, esperar la aprobación de la fase por el usuario.

## 15. Archivos clave para retomar

1. [AGENTS.md](../AGENTS.md), [STATE.md](STATE.md) y las secciones de mecánicas, arte y salas del [GDD](../GDD.md).
2. [ROOM4_STAGE_H.md](ROOM4_STAGE_H.md), [ROOM4_STAGE_G.md](ROOM4_STAGE_G.md) y [TEMPORAL_SHIFT_PROTECTION.md](TEMPORAL_SHIFT_PROTECTION.md).
3. [Room3.tscn](../scenes/Room3.tscn), [room3.gd](../scripts/rooms/room3.gd), [Room4.tscn](../scenes/Room4.tscn), [room4.gd](../scripts/rooms/room4.gd) y [DimensionManager.gd](../DimensionManager.gd).
4. [ROOM2_STAIR_ROUTE.md](ROOM2_STAIR_ROUTE.md), [Room2.tscn](../scenes/Room2.tscn) y [Room2_2.tscn](../scenes/Room2_2.tscn). Para la narrativa y el combate temprano, [NARRATIVE_PHASE_E.md](NARRATIVE_PHASE_E.md), [TUTORIAL_DIALOGUE_IMPLEMENTATION.md](TUTORIAL_DIALOGUE_IMPLEMENTATION.md) y [COMBAT_ROOM1_5.md](COMBAT_ROOM1_5.md).
5. [room4_final_integration_test.gd](../tests/room4_final_integration_test.gd), [temporal_shift_protection_test.gd](../tests/temporal_shift_protection_test.gd) y [validate.gd](../tests/validate.gd).
