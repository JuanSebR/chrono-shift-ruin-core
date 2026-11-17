# Sala 5 — I.1: evaluación completa y propuesta de etapas

16/11/2026 · Godot 4.7.2 · **Diagnóstico y diseño para aprobación. Ningún cambio jugable.**

## 1. Conclusión de la evaluación

**Sí se completó el combate real desde la aparición normal y salud12 hasta DEFEATED**, mediante Player, Input, espada, física y ciclo H.3 originales. El primer ensayo alcanzó DEFEATED a69,117 s; terminó de resolver la entrada de ataque a69,367 s, con salud3/3. No hubo recolocaciones, cambios de salud, manipulación de estados ni ajustes de tiempos durante ningún ensayo continuo.

La victoria acredita completabilidad física, **no calidad de combate final**. Las cuatro políticas ofensivas ensayadas ganaron usando exclusivamente arcos, sobre F0 y sin apoyarse en plataformas superiores. Una ganó permaneciendo en Presente de principio a fin. Después de acercarse una vez, fue suficiente repetir el mismo salto de evasión y dos tajos por apertura. No se gana estando inmóvil: el ensayo sin entradas murió al tercer arco. El problema es la rutina estable, no la ausencia total de peligro.

Recomendación: conservar12HP como referencia de comparación, reducir espera innecesaria cerca del jefe y aprobar una regla que dé propósito a la posición elevada antes de implementar Etapa2. Cambiar solo prioridades o restar vida no resuelve la falta de variedad ni vuelve importante la Lente.

## 2. Alcance, inspección y fuentes

Se leyeron AGENTS, GDD (Guardián, RF-05 y requisitos finales), STATE, informes/diseño del Guardián y el informe H.3 íntegro. Se revisaron controlador, selector, estados, daño y componentes de ataque; no se auditaron las otras salas. MCP confirmó Room5 en este proyecto, detenida y guardada, e inspeccionó CoreGuardian con VisualRoot, CoreWeakpoint, BeamAttack y ArcAttack. No se editó ni recargó la escena durante I.1.

Se aplicaron game-designer y godot-gamedev, con sus guías de playtesting/verificación. Las comparaciones y condiciones se expresan en tablas; no se regeneraron diagramas anteriores ni se necesitó un diagrama nuevo. No hay participantes humanos: los agentes de entrada conocen estados, curva y tiempos. El resultado no mide descubribilidad, diversión, reacción humana ni probabilidad de victoria.

El GDD exige protección del jefe en Pasado y daño al punto débil expuesto en Presente; también contempla jefe final, HUD y resolución/final. **No fija número de etapas, umbral, salud12 ni estos tiempos.** El diseño anterior de dos etapas era una propuesta, no una obligación de canon. HUD, activación y final siguen sin implementarse en este diagnóstico.

## 3. Estado funcional conservado

Carga pasiva → `start_combat_cycle()` explícito → descanso → selección → ataque original → recuperación completa → aproximación → descenso Vulnerable → exposición → cierre Retorn → descanso siguiente. `stop_combat_cycle()` y las derrotas limpian peligros. No hay activación por entrada, puertas cerradas ni victoria persistida.

| Parámetro efectivo | Valor conservado |
|---|---:|
| Salud jefe / daño de espada / salud Player |12 /1 /3 |
| Descanso inicial / entre ciclos |1,00 s /1,00 s |
| Aproximación |4,75 s configurados;≈4,767 s por tramo medido |
| Descenso Vulnerable |6 poses a8fps =0,75 s |
| Exposición baja |2,00 s configurados;121 pasos≈2,017 s en ventanas completas |
| Retorn / descanso de cierre |0,50 s /0,40 s |
| Recuperación ofensiva |0,40 s por ataque, después de terminar peligros |
| Shift / protección temporal |0,20 s /0,16 s |

El selector consulta dimensión confirmada y collider real. Alterna cuando ambos ataques son elegibles; si solo sirve arco, repite arco. El haz nunca gira ni baja a F0. El arco conserva sus seis poses, seguimiento0,25 s, objetivo congelado, curva, barrido radio8 y daño en ambas dimensiones. El núcleo sigue en su landmark bajo, círculo9, con daño únicamente por espada válida en Presente expuesto.

## 4. Protocolo de ensayos continuos

Prueba nueva: `tests/room5_combat_playtest_test.gd`. Cada política empieza en una instancia independiente, spawn(140,600), jefe12, Player3 y equipo habilitado solo en la sesión/perfil aislado. Las cinco políticas se declararon antes del primer lanzamiento; no hay reintentos dentro de cada ensayo ni reinicios ocultos después de fallar.

La política ofensiva espera el arco seleccionado realmente, salta con Input, se desplaza hasta X≈1056 durante aproximación y usa saltos/tajos reales en la exposición. Los ciclos posteriores mantienen esa posición sin teletransportar. El salto lejano usa el margen de H.2; cerca del cañón se anticipa más. El diagnóstico lee estados para decidir entradas, nunca los escribe. Los golpes se cuentan desde `damage_accepted`; los tajos desde `energy_slash_used`, no por restar salud artificialmente. La política E no emite entradas.

Tiempo simulado de física a60Hz, independiente de cuánto tarda el proceso headless. El origen temporal es la activación manual. Se registran eventos, HP, posiciones, duración por estado, entradas/confirmaciones/rechazos de Shift, golpes, apoyos elevados y limpieza. Los0,25 s posteriores al golpe terminal son la finalización de la rutina de entrada, no tiempo adicional necesario para matar al jefe.

### Resultados conservados

| Ensayo | Política | Terminal / fin ensayo | Arcos / haces | Ventanas | Golpes por ventana | Salud Player / daño | Shift confirmado | Resultado |
|---|---|---|---:|---:|---|---|---:|---|
| A, principal |2 golpes, Shift ida/vuelta durante aproximación |69,117 /69,367 s |6 /0 |6 |2,2,2,2,2,2 |3/3 /0 |12 |DEFEATED |
| B |2 golpes, siempre Presente |69,117 /69,367 s |6 /0 |6 |2,2,2,2,2,2 |3/3 /0 |0 |DEFEATED |
| C |1 golpe por apertura, siempre Presente |138,183 /138,433 s |12 /0 |12 |1 en cada ventana |3/3 /0 |0 |DEFEATED |
| D |2 golpes; omite deliberadamente ventanas3 y6 |92,417 /92,667 s |8 /0 |8 |2,2,0,2,2,0,2,2 |3/3 /0 |0 |DEFEATED |
| E, control negativo |Quieto, sin espada ni evasión |27,867 /27,867 s |3 /0 |2 completas |0,0 |0/3 /3 |0 |Player derrotado; jefe12 |

En A–D se emitieron12 tajos y acertaron12; cero tajos fallidos. D representa **oportunidades omitidas**, no errores motores de espada ni una distribución humana de fallos. No hubo cambios rechazados en los combates continuos. No hubo pasos apoyados sobre plataformas superiores en ninguno. El total de arcos entre políticas independientes fue35 y de haces0; no es una sola partida ni una estadística de jugadores.

El ensayo A se reprodujo además con render real1280×720: misma victoria y contadores principales. Esa reproducción visual se conserva por separado; no sustituye ni borra ninguno de los cinco resultados iniciales.

Datos completos: [attempts.json](../artifacts/room5_stage_i1/attempts.json), [metrics.json](../artifacts/room5_stage_i1/metrics.json), [render_attempts.json](../artifacts/room5_stage_i1/render_attempts.json). Cada evento conserva su tiempo/posición/salud, incluidos los del ensayo perdido.

## 5. Ritmo y balance de salud

Se define «secuencia ofensiva del jefe» como estados BEAM_* y CANNON_*, incluidos aviso y disipación; RECOVER, aproximación, descenso, exposición y cierres se cuentan aparte. Esto no mide segundos de collider activo. «Sin ofensiva del jefe» **no equivale a inactividad del Player**: incluye desplazarse, cambiar dimensión y atacar el núcleo.

| Ensayo | Secuencia ofensiva | Sin ofensiva del jefe | Aproximación acumulada | Exposición acumulada |
|---|---:|---:|---:|---:|
| A/B |11,42 s (16,46%) |57,95 s (83,54%) |28,60 s |11,50 s |
| C |22,12 s (15,98%) |116,32 s (84,02%) |57,20 s |22,77 s |
| D |14,98 s (16,17%) |77,68 s (83,83%) |38,13 s |15,53 s |

La última exposición se interrumpe por derrota; no se infiere que todas duren menos de2s. En A, la aproximación sola ocupa41,2% del ensayo. El primer trayecto consume3,833 s de desplazamiento (H.3),4,567 s incluyendo dos Shift y frenado en I.1. Desde la segunda apertura no hay distancia por recorrer; las rutinas de Shift/freno consumen0,733 s, pero la pausa sigue siendo4,767 s. Allí quedan≈4 s sin necesidad física de aproximarse.

Con un golpe por apertura,138 s es largo para un patrón que no cambia. Dos omisiones elevan el caso de dos golpes a92,7 s. Los3HP permiten dos impactos no letales; el tercero mata. Los ensayos ofensivos no estiman riesgo humano porque conocen el momento de salto y reciben0 daños. E demuestra el límite real3 impactos, separados por ciclos, sin daño acumulativo ficticio.

### Salud: comparación analítica, no modificaciones ni nuevas partidas

| Salud candidata | Ventanas a2 golpes | Ventanas a1 golpe | Duración estimada con ritmo actual |
|---|---:|---:|---|
|12 actual |6 |12 |69,4 /138,4 s medidos |
|10 |5 |10 |≈57,7 /115,1 s, extrapolación |
|8 |4 |8 |≈46,1 /91,8 s, extrapolación |

Extrapolación por el intervalo repetido observado≈11,65 s, conservando política/posiciones; no predice otro selector o etapa. **Recomiendo mantener12 durante el primer prototipo aprobado de ritmo/variedad.** Recortar HP deja intacta la solución repetitiva y oculta cuánto tiempo sobra cerca del núcleo. Si después de ajustar ritmo un playtest representativo sigue mayoritariamente a1 golpe/ventana y demasiado largo, evaluar10 como siguiente variable única. No aprobar8 por estos ensayos expertos aislados.

Objetivos de playtest propuestos, no resultados: combate aprendido de≈45–90 s, margen suficiente para un golpe sin precisión extrema y dos como recompensa; verificar tolerancia a omisiones antes de fijar vida final.

## 6. Aproximación, núcleo y justicia

La pausa4,75 s fue suficiente desde el spawn con dos Shift y frenado, con margen reducido≈0,18 s bajo esta política automatizada. No se demuestra suficiencia universal desde cualquier pared/velocidad inicial. La salida izquierda está abierta: huir por ella no se cuenta como evasión dentro del encuentro. Cerca del jefe la pausa es excesiva; no debe acortarse globalmente penalizando el primer trayecto lejano.

**Candidato futuro:** fijar una pausa dependiente de distancia al punto de ataque X≈1049, muestreada una vez al terminar el peligro, nunca recalculada para perseguir al Player:

`pausa = clamp(abs(player_x - attack_x)/240 + 0.85, 1.25, 4.75)`

Valores orientativos para aprobación: mínimo1,25 s, máximo4,75 s, margen0,85 s. El cálculo es geométrico, no navegación; ignora obstáculos, velocidad contraria y rutas desde plataformas. En esos casos conservar4,75 s o un presupuesto de ruta validado, nunca asumir una línea horizontal libre. Verificar posiciones lejanas y retorno dimensional antes de adoptarlo. Si se reduce de4,767 a1,25 en las cinco pausas cercanas de A, el ahorro aritmético sería≈17,6 s: ensayo≈51,8 s. **No es una simulación de esa propuesta.**

El descenso0,75 s sí diferencia la postura; la apertura lógica espera la pose final baja. El arte inspeccionado muestra que el núcleo se oscurece en las poses finales, lo que dificulta inferir vulnerabilidad solo por brillo. El cierre tampoco tiene una cuenta atrás visible. No se probó comprensión humana. Recomendación mínima futura: contraste/contorno del núcleo alineado a su círculo cuando realmente acepta daño y aviso breve de cierre, sin cambiar alcance, anclaje ni agrandar hurtbox; revisión de accesibilidad para no depender solo del color.

El salto obligatorio con espada fue ejecutable dos veces en2s por el agente. No prueba que resulte intuitivo ni poco preciso para una persona. Mantener2s en el primer ajuste, medir éxito a1/2 golpes y errores por alcance antes de acortar exposición.

Persisten límites H.2: correr desde izquierda hacia el centro puede cruzar la curva; un salto tardío derecho recibe daño. A–D usan una política informada que evita ambos, por tanto no los invalidan. Prioridad futura: señal de objetivo fijado y cuenta de emisión más legibles, ruta curva con contraste, explicación visible de que Shift no vuelve seguro el arco salvo protección temporal real. Para el haz, reforzar su aviso fino sobre ambos fondos. Conservar hitboxes/velocidades/tiempos hasta probar lectura; no extender daño a F0 ni dejar daño fuera del sprite.

## 7. Elegibilidad y plataformas

Se ejecutaron20 fixtures separados mediante `--eligibility-only`; el Player se coloca solo en estos fixtures con su física detenida, sin combate ni daño. No son parte de los recorridos anteriores. El cambio a Pasado se hizo con Shift real desde F0 seguro. [Datos completos](../artifacts/room5_stage_i1/eligibility.json).

| Posición física de muestra | Haz en Presente | Haz en Pasado | Selección inicial |
|---|---|---|---|
| F0 (400,600) |No |No |Arco |
| R1 (380,540), R2 (860,540) |Sí |No |Haz en Presente; arco en Pasado |
| P1 (580,480) |Sí, borde del collider |No |Según dimensión |
| Lugar de T1 (780,480) |Sí geométricamente |No |El lugar no implica que T1 esté activa en Presente |
| Aire alto (600,460) |No |No |Arco |
| Detrás (1150,600) |No |No |Arco |
| Centro Y480 /Y544 |Sí, bordes |No |Haz solo en Presente |
| Centro Y545 |No |No |Arco |

La banda del haz es X80–980,Y500–524; Player24×40. Los fixtures confirman contacto en los bordes, coherente con el impacto real P1 de H.3. El grupo completo elegible no es «estar elevado»: depende de volumen, X y dimensión. No se fuerza el haz por alternancia cuando el volumen queda fuera.

Actualmente no hay recompensa de combate por visitar P1/T1; la espada llega al núcleo desde F0 y la seguridad repetible también está allí. R1/R2 ofrecen posiciones para provocar haz y bajar/cambiar dimensión, pero eso añade riesgo y recorrido sin mejorar la apertura. P1 permite apoyo en Presente y T1 ruta alternativa en Pasado; en estos ensayos su ventaja no fue necesaria ni utilizada.

## 8. Lente Temporal: utilidad observada y potencial

- A realizó12 cambios confirmados, todos durante aproximación sin peligro. B ganó sin ninguno, con el mismo tiempo y salud. En esta solución Shift es opcional y esos usos no aportaron ventaja defensiva.
- Frente a un haz realmente elegible, Pasado sí es defensa importante: evita toda su fase activa, permite conservar posición y exige volver a Presente para dañar. Se apoya en reglas/pruebas H.3, no en haces de los combates I.1 (hubo0).
- El arco persiste en ambas dimensiones. La protección0,16 s puede consumir un contacto sin daño, según H.2, pero no se ensayó como estrategia continua I.1 ni debe exigirse una sincronización de ese margen para ganar.
- Cambio bloqueado por ocupación no cambia dimensión ni concede protección. P1/T1 pueden hacer inseguro cambiar dentro de la geometría exclusiva destino. Antes de exigir una ruta dimensional deben probarse sus aterrizajes y volumen destino.

La mejora debe dar una razón para elegir altura y momento, no ordenar Shift por tiempo fijo. Asegurar que el haz sea un desafío que merezca visitar hace que la defensa dimensional existente importe; no basta aumentar la frecuencia de la tecla ni hacer el arco inmune a la protección.

## 9. Dos alternativas de variedad, sin modificar los ataques

El siguiente diseño **no está implementado ni aprobado**. Con las reglas actuales intactas no se puede garantizar variedad sobre F0: el haz es inelegible y la apertura está accesible allí. Cambiar solo pesos, alternar obligatoriamente o bajar el haz sería una falsa solución.

| Alternativa | Regla futura | Ventaja | Coste/riesgo |
|---|---|---|---|
| A: incentivo elevado opcional | Al seleccionar desde R1/R2 o P1 en Presente, registrar un ciclo elevado y premiar su apertura siguiente con2,75 s, manteniendo2s para F0. Aplicar selección física actual. | Jugador puede buscar tercer golpe a cambio de provocar haz; Shift permite defender la altura y regresar. No bloquea victoria base. | Regla de recompensa nueva que requiere feedback/aprobación; puede no superar el coste de viajar. La ruta no garantiza que el selector llegue a elegir haz si el Player se queda siempre abajo. No venderla como variedad asegurada. |
| B: descarga del escudo en Etapa2 | En la segunda etapa, una apertura se obtiene después de completar un haz que fue elegible al seleccionarlo; arcos mantienen presión pero no abren por sí solos. El Player debe provocar una descarga desde altura y puede usar Pasado para conservarla. | Motivo directo para visitar plataformas; el haz y el retorno a Presente importan. No se selecciona un ataque inútil ni se altera su banda. | Cambia la regla de apertura de H.3. Riesgo de bloqueo de comprensión para quien sigue en F0, tiempo muerto/arcos repetidos y mayor viaje. Debe comunicarse y admitir rutas demostradas antes de aprobarla para producción. |

Para A,2,75 s es candidato para intentar un tercer salto/tajo, no garantía de tres impactos. Para B, la descarga se registra al completar el ataque, no al recibir daño: no exige que el Player se deje golpear ni que use necesariamente Shift; bajar/saltar fuera de la banda debe seguir siendo alternativa física.

**Recomendación:** estudiar B como prototipo de diseño I.2, manteniendo A como alternativa conservadora si la regla de descarga resulta opaca. B conecta cortocircuito/escudo con las reglas dimensionales existentes, pero esa relación causal no está fijada por el GDD y necesita aprobación explícita. No añadir un tercer ataque para ocultar el problema. No mover al jefe a una altura distinta: también movería el haz y exigiría revalidar sus anclajes.

## 10. Propuesta de etapas y parámetros candidatos

Una sola etapa con pausa adaptativa y recompensa A es alternativa válida si se prefiere menor coste/menor aprendizaje. El GDD no obliga a dos. **Dos etapas se recomiendan solo si la segunda cambia una decisión**, no para repetir el mismo arco más rápido.

| Elemento | Etapa1 — Reconocimiento | Etapa2 — Sobrecarga, candidata B |
|---|---|---|
| Salud |12→6 |6→0, sin curar ni duplicar entidad |
| Ataques |Los mismos, elegibilidad original |Los mismos; conservar elegibilidad y alternancia |
| Apertura |Después de cada ataque completo |Tras descarga de haz elegible; arcos no abren solos |
| Aproximación |Pausa por distancia con máximo conservador |Mismo presupuesto; no recortar si la ruta elevada es más larga |
| Exposición |2,00 s efectivos |2,00 s efectivos inicialmente |
| Descanso |Inicial1s; entre ciclos1s |Entre ciclos candidato0,75s, solo tras validar lectura; no reducir avisos ofensivos |
| Aprendizaje |Aviso, salto, postura baja y Presente |Provocar haz desde altura, defenderla con Pasado o retirarse y volver a Presente |

La Etapa1 todavía puede resolverse solo con arcos; no promete enseñar ambos si el jugador nunca sube. Antes de lanzar la segunda etapa, la regla elevada necesita señalización/ensayo de comprensión. No compensar esto con un haz falso contra F0. Evitar secuencias dobles obligatorias como primer ajuste: dos ataques antes de cada ventana aumentarían aún más la duración y castigarían salud3.

Umbral recomendado para comparar:50%=6HP. Con2 golpes por ventana, son3 aperturas por mitad; con1,6. Con10HP futuro sería5, no mantener6 automáticamente. Registrar umbral cruzado y ejecutar transición **después del cierre de la apertura actual y solo sin peligros**. No cerrar al recibir el golpe que cruza6, no reiniciar salud y no interrumpir un ataque. Si una ventana cruza el umbral y acaba en0, DEFEATED tiene prioridad y no hay transición.

## 11. Recursos de transición revisados visualmente

Se inspeccionaron los atlas ya existentes, sin extraer/regenerar sprites. No se dedujo su función solo del nombre.

| Recurso | Lectura visible | Uso actual / valoración |
|---|---|---|
| Starting,8 poses |Cabeza/cuerpo encogidos que se incorporan |Diagnóstico Intro existente. Candidato a rearranque visual, con discontinuidad anatómica respecto a Repose; no es una animación de sobrecarga explícita. |
| Repose,4 |Postura erguida con pequeños cambios |Reposo/esperas y cuerpo del haz. Seguro para pausa, poco enfático por sí solo. |
| Retorn,4 |Pose elevada, apoyo bajo y vuelta erguida |Cierre H.3; conservar su orden, no invertir Vulnerable para inventar recuperación. |
| Exit,4 |Flexión e impulso hacia postura con piernas suspendidas |Diagnóstico existente; no basta para afirmar vuelo funcional. Evitar desplazar al jefe o inventar recorrido al usarlo. |
| Exit Repose,1 |Una pose suspendida |No cargada en SpriteFrames jugables. No es un ciclo animado ni transición completa. |
| Vulnerable,6 |Bajada a rodilla, núcleo bajo más oscuro al final |Ya usada para apertura. No reutilizar como falsa exposición durante transición protegida. |
| Attack3,6 |Carga, cañón, retroceso y asentamiento |Ya ofensiva de arco; usarla sin disparar como transición confundiría el aviso aprendido. |

También existe Retorn Repose no cargado; no se asume un movimiento nuevo. No hay animación artística exclusiva «Etapa2» identificada.

**Secuencia candidata a aprobar:** cierre lógico → Retorn0,50 s → Starting8 poses a8fps (1,00 s) → Repose0,25 s → descanso de Etapa2 (total transición1,75 s). Player conserva movimiento y Shift; jefe protegido y sin ofensiva. Usar Starting aquí sería un rearranque deliberado, no atribuirle una función canónica. Sus diferencias de silueta requieren revisión visual al enlazar; si resultan bruscas, alternativa Retorn0,50 +Repose0,75 (1,25 s), con señal de etapa pendiente de diseño visual aprobado. No crear diálogo, cinemática ni arte nuevo en I.1. La transición no debe contarse como nueva pausa ofensiva peligrosa ni como exposición.

## 12. Flujo final del juego: dependencias, no implementación

| Paso futuro | Dependencias/recomendación |
|---|---|
| Room4→Room5 con Llave |Conservar transición y llegada actuales; no curar silenciosamente. |
| Preparación |Zona de entrada segura y explicación legible de reglas; falta aprobar activación. |
| Activación / Intro |EncounterTrigger futuro, idempotente, conectado a la API existente tras Intro; política de salida aún por aprobar. |
| Etapa1 |Repertorio original; comunicar defensa y punto débil antes de exigir una regla nueva. |
| Transición / Etapa2 |Umbral pendiente seguro y alternativa de variedad elegida; no solapar peligros. |
| Derrota |Cancelar ciclo primero, confirmar señal terminal una sola vez. |
| Reactor |Definir interacción/secuencia causal aprobada, sin asumir que matar guarda victoria automáticamente. |
| Final/créditos |Guion aprobado, HUD y persistencia compatibles con guardados v1; requiere alcance posterior propio. |

La salida sigue abierta en la versión actual. No se bloqueó para obtener victorias. Barreras, BossHUD, música, checkpoint/reintento y resolución narrativa necesitan decisiones separadas; no se incorporan implícitamente por aprobar balance.

## 13. Validación, evidencias e integridad

Headless:21 comprobaciones de infraestructura/contabilidad, cero fallos. Eso **no transforma la derrota E en PASS de combate**: E queda registrada como Player derrotado. Probe:20 fixtures, una comprobación agregada correcta. Render A:8 comprobaciones incluidas3 capturas, cero fallos. `tests/validate.gd`: sintaxis exitosa tras crear/ampliar el diagnóstico. No se ejecutaron regresiones extensas porque no cambió código jugable. Los logs y códigos de salida se conservan en `artifacts/room5_stage_i1/logs/`.

Capturas reales1280×720: [inicio12HP](../artifacts/room5_stage_i1/01_inicio_12HP_1280x720.png), [espada en el recorrido](../artifacts/room5_stage_i1/02_impacto_continuo_1280x720.png), [derrota real del jefe con Player3/3](../artifacts/room5_stage_i1/03_resultado_boss_defeated_1280x720.png). La salud12→0 se acredita por eventos/contabilidad, no por una barra del jefe inexistente. No se generó BossHUD para la captura. Las capturas H.3 siguen siendo referencia de ambos tamaños y de descenso/cierre.

Perfiles APPDATA aislados externos; las pruebas headless escriben en el espejo externo y sus JSON se copian a esta carpeta diagnóstica. El render usa el proyecto real. El script rechaza ejecución sin `phase_i1_work` en el perfil. No escribe progreso permanente. Helpers/línea base: `C:/Users/juans/.codex/visualizations/2026/11/16/01a1e570-850c-7a83-8965-7511f3d3ed84/phase_i1_work/` y directorio padre.

Solo se creó este informe, el test y evidencias/JSON/logs/metadatos del diagnóstico. **Ningún archivo preexistente se debe modificar**: la comprobación SHA-256 final contra la línea base y los dos guardados reales está en [verification.json](../artifacts/room5_stage_i1/verification.json). Incluye controlador, escena, ambos ataques, Room5, Player, DimensionManager, HUD, progreso, transiciones, arte, atlas y configuraciones. No se escribieron OpenViking, AgentMemory ni credenciales. No se necesitó respaldo para editar producción porque no se editó producción.

## 14. Decisiones pendientes y plan I.2

Para aprobar una implementación concreta quedan estas decisiones:

1. Una etapa con incentivo A o dos etapas con regla B. Recomendada B para prototipo controlado, sujeta a comprobar que se entiende la descarga sin bloquear al jugador en F0.
2. Mantener12HP/daño1 mientras se compara ritmo, o estudiar10 después. Recomendación actual:12 para aislar el efecto de las pausas.
3. Aprobar pausa por distancia (mínimo1,25; máximo4,75; margen0,85), validando rutas/velocidades; exposición inicial2s en ambas etapas.
4. Umbral6HP y transición Starting enlazada tras Retorn, o alternativa visual conservadora. Revisar anatomía antes de cerrar la elección.
5. Forma de comunicar descarga, apertura y cierre; requiere feedback legible, no un tercer ataque ni cambios de física.

Plan I.2 propuesto: respaldar archivos autorizados; implementar primero pausa por distancia bajo API controlada; repetir A–E y fixtures de aproximación desde alturas; comparar tiempos y golpes; prototipar una sola alternativa de variedad; verificar rutas reales hacia banda del haz y regreso al núcleo en ambas dimensiones; añadir umbral pendiente/limpieza segura; ensayar victoria12→0 incluyendo ambos ataques; después playtest humano de comprensión, anticipación, fallos, salud y duración. Conservar el haz/arco y sus regresiones sin cambiar expectativas. La activación de entrada/final no es una dependencia necesaria de ese prototipo y no se implementa automáticamente.

I.1 termina aquí. Los valores y etapas anteriores son propuestas revisables; **no se implementó Etapa2 ni se cambió balance**.
