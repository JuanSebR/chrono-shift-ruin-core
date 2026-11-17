# Sala 5 — H.1: diagnóstico de Attack 3 y diseño del segundo ataque

16 de noviembre de 2026. **Solo análisis y propuestas para aprobación. No se implementó otro ataque ni IA automática.** Se conservan íntegros haz, escenas, scripts, arte, atlas, física, dimensiones, progreso y transiciones.

Se utilizaron game-designer y godot-gamedev, sus guías de sistemas/playtesting y los documentos pertinentes de AGENTS, GDD, diseño del Guardián y fases A/F/G. No se repitió el inventario general. Las láminas técnicas bastan para esta decisión; no se regeneraron diagramas previos ni se creó otro diagrama mediante diagram-design.

## 1. Evidencia y límites

MCP confirmó Room5, proyecto correcto, escena2586308586909, revisión10063650:0:1, `playing=false`, `unsaved=false`. Se inspeccionó el árbol real: VisualRoot/AnimatedSprite2D, CoreWeakpoint/CollisionShape2D y BeamAttack bajo una única entidad CoreGuardian. No se cambió ni recargó la escena.

Fuentes comprobadas: original `assets/sprites/jefe/attacking 3 GuardianNucleo.png`, atlas `assets/sprites/jefe/derived/atlases/attack3_atlas.png`, manifiesto A, recursos relacionados del mismo directorio y scripts reales de Player/Guardián/haz. Attack3 **no está cargado en los SpriteFrames funcionales actuales**: existen seis animaciones corporales de F más el componente de haz de G. El atlas está preparado para integración futura.

Las mediciones son lecturas de código, manifiesto y píxeles, cálculos analíticos y composiciones estáticas. No se ejecutó un segundo ataque, no se probaron sus colisiones ni se realizó playtest con personas. Los PASS históricos de F/G no validan estas propuestas.

## 2. Seis poses de Attack 3

Fuente2172×724; seis recortes originales de anchuras diferentes, ya registrados en A. El atlas normalizado usa640×800 por pose y anclaje(320,720). Se reutilizó ese atlas: **no se extrajo ni normalizó nuevamente**. Orden original izquierda→derecha, índices base0. La fuente mira a derecha; Room5 aplica espejo para mirar a izquierda.

| Índice | Observación visual | Uso candidato, no evento aprobado | Boca en mundo, espejo actual |
|---|---|---|---|
|0 |Cañón extendido, luz magenta, postura alta de la secuencia |Preparación |1010,64;536,13 |
|1 |Torso baja, brazo/arma retroceden ligeramente |Carga o anticipación |1013,89;539,77 |
|2 |Boca blanca intensa, cuerpo comprimido |Único evento candidato de emisión al entrar en esta pose |1018,11;537,28 |
|3 |Destello blanco exterior y retroceso más evidente |Continuidad de descarga/retroceso; no emitir otro disparo automáticamente |1027,49;538,62 |
|4 |Se apaga el blanco, chasis todavía comprimido |Recuperación |1016,19;543,02 |
|5 |Vuelve cerca de la postura inicial de Attack3 |Fin de secuencia; empalme a Repose pendiente |1010,83;536,13 |

Los centros del núcleo oscilan aproximadamente entreX1060,62–1070,77 eY537,09–544,55. La iluminación del núcleo y visor cambia, pero no demuestra exposición jugable. La descarga blanca pertenece al cañón: **no es un proyectil separado** ni una región ofensiva ya definida.

Fórmula de referencia conservada: mundo=(1070,620)+(−(x−320),y−720)×0,375. Durante el retroceso la boca se desplaza≈17 unidades en X; la posición de emisión futura se tomaría una sola vez al entrar en pose2. El proyectil no debe perseguir después el cañón en retroceso.

El apoyo está registrado en la misma cota. Esto no garantiza continuidad anatómica: la primera silueta de Attack3 ronda130 unidades de alto, frente a194,25 en Repose. La diferencia es de unos64px y no se debe ocultar igualando alturas por escalado. No hay animación de apuntado vertical, giro de torso, trayectoria, proyectil ni impacto que complete automáticamente un ataque funcional. Sí hay preparación/descarga/recuperación corporal utilizables, con tiempos aún por diseñar.

[Hoja de las seis poses y landmarks](../artifacts/room5_stage_h1/01_attack3_sequence.png). Los marcadores y etiquetas son diagnósticos sobre una copia de presentación, no cambios al sprite.

## 3. Efectos disponibles y ausentes

La revisión acotada de los archivos relacionados confirma el mismo límite de A: no aparece un proyectil, impacto, onda de suelo o rastro propio de Attack3. No se deduce la existencia de Attack2 por numeración. El destello integrado de2–3 no puede separarse sin una propuesta de recorte adicional.

Recursos reutilizables para estudiar: beam_hold64×64, con banda luminosa64×32; beam_finish con seis celdas, primera idéntica a Hold y última vacía; beam_start como indicación fina. No se reutiliza Enemy1 por conveniencia técnica.

**Composición candidata:** Hold a escala uniforme0,75 produce una banda48×24, dentro de celda48×48; podría representar un paquete energético corto, orientado por su trayectoria. Finish aportaría disipación con la misma escala. No se genera un sprite nuevo ni se inventa una explosión radial: la procedencia sigue siendo un segmento de haz con extremos planos. La lectura como paquete independiente necesita aprobación y validación visual antes de producir daño.

La advertencia de objetivo tampoco existe como recurso propio. Se propone componer tres barras cortas con regiones luminosas existentes, más un recorrido discontinuo; si esa composición no resulta legible, solicitar al artista una retícula, paquete e impacto coherentes. Esa dependencia no se considera resuelta por el dibujo de una caja diagnóstica.

[Comparación de reutilización y orientación](../artifacts/room5_stage_h1/02_effect_reuse.png). Solo muestra arte existente reubicado/escalado para examinarlo; no entrega un proyectil implementado.

## 4. Arena y amenaza actual

| Superficie | X | Cota superior | Collider Player apoyado | Haz ofensivo Y500–524 en Presente |
|---|---|---:|---|---|
|F0, Shared |80–1200 |620 |Y580–620 |No lo alcanza en suelo |
|R1, Shared |300–460 |560 |Y520–560 |Solape vertical≈4u |
|P1, Presente |500–660 |500 |Y460–500 |Contacto de borde; no afirmar solape robusto en reposo |
|T1, Pasado |700–860 |500 |Y460–500 |En Pasado el haz es inocuo; en Presente T1 es intangible |
|R2, Shared |780–940 |560 |Y520–560 |Solape vertical≈4u |

Haz actual: X80–980, Y500–524, solo Presente. El Player puede permanecer quieto en F0, debajo de esa banda, o ir al Pasado. La franja oriental, incluyendo detrás del Guardián, queda fuera de su alcance horizontal. P1 puede servir como refugio contra este haz pero el borde requiere ensayo físico; saltar hacia ella puede cruzar la banda peligrosa. T1 también queda segura frente al haz mientras sostiene al Player en Pasado. R1/R2 no son refugios en Presente mientras emite. No se modifica ninguna de estas reglas.

La ruta horizontal sobre F0 pasa por debajo de los descansos sin saltos obligatorios. El jefe no tiene cuerpo sólido, por lo que se puede atravesar su silueta y permanecer debajo o detrás. **Espejar el cañón por sí solo no resuelve todo:** entre el cuerpo y la boca extendida también queda una zona próxima a la que un disparo puramente horizontal no puede dirigirse coherentemente.

Los contornos tienen molduras que pueden sostener temporalmente al Player; se conservan. El retorno de Room5 está en(100,600): desplazarse al extremo izquierdo puede abandonar la sala, no formar parte de un encuentro cerrado. No se propone bloquearlo en esta fase. Un ataque futuro debe cancelarse al salir y no perseguir al Player a Room4.

Riesgos de injusticia: aviso fijado contra una pared sin espacio lateral; obligar Shift cuando está en cooldown o su destino ocupado; lanzar haz y presión de suelo a la vez; seguir apuntando después del anuncio; disparar desde el cañón hacia atrás sin indicación; daño de área sin efecto propio. Las propuestas evitan o condicionan explícitamente esos casos.

## 5. Propuesta A — Paquete de arco fijado (recomendada)

**Decisión del jugador:** al ver un punto anunciado y su ruta, abandonar ese punto o preparar un salto. Cambiar al Pasado no sustituye esa respuesta.

- **Cuerpo:** Attack3 poses0–1 para apuntado/carga,2 para emitir una sola vez,3 para retroceso,4–5 para recuperación. Tiempos candidatos:0,40s +0,60s de preparación;2–5 a0,125s por pose. Se usan poses existentes, no una nueva animación de brazo.
- **Orientación propuesta:** elegir lado al anunciar según la posición del Player respecto al jefe, usando espejo horizontal del mismo arte. Congelar orientación antes de emitir; nunca girar un disparo ya creado. Espejo hacia derecha y posterior empalme al reposo izquierdo necesitan aprobación artística y técnica.
- **Objetivo:** centro real del Player al fijar, no una proyección obligatoria sobre F0: Y600 si está en suelo, Y540 en R1/R2, Y480 en P1/T1, o su altura anunciada si está en el aire. `x` se limita a80–1200. Sigue al Player solo durante los primeros0,25s del aviso; después queda fijado y se muestra como tal. El objetivo no se corrige durante el vuelo. Esta regla evita que P1 o T1 se conviertan en refugios permanentes de los dos patrones. Los mapas ilustran el caso de presión sobre F0.
- **Trayectoria propuesta, no inferida del dibujo:** curva cuadrática fija. P0=boca real en pose2; P1=P0+(60×orientación,0); P2=objetivo anunciado. La tangente inicial sale del cañón en su orientación correcta. La curva puede volver hacia una posición cercana al cuerpo sin un giro instantáneo del arma ni persecución del Player. Esta es energía con trayectoria diseñada, **no balística de gravedad ya existente**.
- **Vuelo:** T=max(0,45;2×max(|P1−P0|,|P2−P1|)/1400), segundos. En esta arena ronda0,45–1,26s; la cota de rapidez de esta curva es≈1400u/s. Hace falta colisión barrida: a60fps puede recorrer≈23u por paso, comparable al ancho24 del Player.
- **Representación candidata:** paquete48×24 luminosos de Hold y disipación de Finish. Se orienta con la tangente, sin deformarlo. No se considera aprobado como arte de proyectil. Durante la carga, tres marcas cortas indican el objetivo; una ruta discontinua mostraría también el peligro aéreo, para no anunciar solo el punto final.
- **Daño candidato:**1; círculo de radio8 dentro de la banda luminosa, con consulta barrida contra Player. No es una explosión96px de ancho ni una zona invisible de suelo. En un contacto consume el paquete incluso si el Player está protegido por Shift. Sin contacto, se disipa al llegar al punto anunciado; no se promete un impacto contra suelo que no está dibujado. El aviso debe marcar ese punto en su altura real, también sobre plataformas o en el aire.
- **Alcance:** puede elegir cualquier punto útil de F0, incluidos extremos y cercanía/detrás del cuerpo, condicionado a aprobar espejo y curva. Permanecer exactamente en el objetivo deja de ser seguro. El anuncio fijo permite escapar sin que el ataque vuelva a perseguir.
- **Dimensión recomendada:** peligroso en ambas. Mantener el mismo paquete/contador entre dimensiones. La protección0,16s de Shift conserva su efecto normal y puede descartar un contacto oportuno, pero no es obligatoria para esquivar.
- **Plataformas:** se propone que el paquete energético atraviese los apoyos superiores, como el haz actual; consulta de daño contra Player, sin colisión con sus one-way. Si se exigiera choque con plataformas, R2 puede interceptar parte de las curvas y anular el objetivo de presionar F0. Esta regla requiere aprobación y previsualización clara del recorrido.
- **Ventajas:** un único paquete, mismo lenguaje energético, contraparte de suelo al haz, soporta bordes y proximidad con respuesta lateral. **Desventajas:** curva/orientación no vienen demostradas por la fuente; retícula y paquete son composiciones pendientes, no assets originales dedicados. **Dificultad técnica:** media, concentrada en trayectoria barrida, anclaje por pose y sincronización.

La propuesta es viable como diseño de un prototipo localizado, condicionada a aprobar composición, curva y espejo. No se afirma que su arte o daño estén terminados. Si se rechaza la lectura del fragmento de haz como paquete, se mantiene el diseño y se solicitan sprites específicos antes de implementar daño.

## 6. Propuesta B — Descarga bifurcada rasante

**Decisión distinta:** abandonar el anuncio con antelación o saltar sobre frentes bajos; esperar en el mismo punto después de la descarga resulta más comprometido.

- Usa las mismas seis poses Attack3 y preparación candidata1,0s, con fijación de objetivo tras0,25s. Si el Player se anuncia sobre F0, un único paquete viaja por curva fija hasta(xt,608), a12u sobre F0; la banda de24u puede tocar visualmente el suelo. Si está en otra altura, el paquete apunta a su centro anunciado como en A y se disipa allí, sin crear ondas de suelo ficticias. Mantener esta variante vertical es necesario para no regalar P1/T1 como refugios permanentes.
- Al llegar sin haber contactado al Player, se divide en dos segmentos bajos opuestos; no dispara dos veces desde las poses2/3. Cada frente reutilizaría Hold/Finish con escala uniforme y centroY608. El cambio de paquete a dos frentes necesita aprobar una composición de contacto/división; no existe una onda o impacto específico que lo resuelva automáticamente.
- Daño candidato1 por ejecución completa. Región de cada frente32×16 dentro de su visual48×24; velocidad candidata180u/s y vida ofensiva0,45s, recorrido81u por lado. Se recorta al rango80–1200 y se disipa. No cubre todo F0 simultáneamente ni queda persistente.
- El paquete se consume si golpea al Player antes de llegar; entonces no nacen frentes. Un ID de ejecución debe impedir que paquete y frentes resten dos células accidentalmente. No se sustituye la invulnerabilidad normal ni se registra un impacto descartado por protección como daño aceptado.
- Telegráfico: tres marcas y flechas cortas opuestas muestran expansión limitada, diferente del punto de A y de la línea larga del haz. El volumen completo de advertencia debe incluir el ancho del Player y la extensión máxima, no solo el punto central.
- Recomendación dimensional: ambas dimensiones; las cuatro alternativas se evalúan en la sección siguiente. Saltar permite elevar los pies más de24u y pasar sobre el frente bajo. R1/R2 aportan refugio temporal; llegar a ellas no debe ser requisito obligatorio desde una pared.
- **Ventajas:** respuesta de salto muy clara y presión de suelo más prolongada. **Desventajas:** más objetos/colisiones, composición de contacto ausente, mayores riesgos en molduras, dos frentes y esquinas. **Dificultad:** media-alta. No debería ser el primer prototipo mientras falte aprobar su lectura visual de división/impacto.

Ambas propuestas afectan F0 y tienen salida física propuesta; ninguna se considera probada ni aprobada. B conserva viabilidad técnica sin modificar plataformas, pero tiene más deuda artística y pruebas que A.

[Mapa A](../artifacts/room5_stage_h1/03_danger_proposal_A.png) · [Mapa B](../artifacts/room5_stage_h1/04_danger_proposal_B.png). Ámbar indica propuesta; rojo, haz actual; violeta, el refugio oriental que exige resolver orientación/proximidad. Las cajas y curvas son anotaciones técnicas sobre captura de F, no hitboxes creadas ni renders de un ataque funcional.

## 7. Alternativas dimensionales y recomendación

| Regla para el segundo ataque | Consecuencia | Evaluación |
|---|---|---|
|Ambas dimensiones |F0 en Pasado también requiere movimiento/salto |Recomendada para A; complementa el haz sin exigir Shift |
|Solo Pasado |Invita a volver a Presente, pero quedarse en F0 Presente evade los dos ataques |No resuelve por sí sola el refugio permanente de suelo |
|Zona distinta según dimensión |Podría combinar posición y Shift |Mayor carga de lectura/ocupación; riesgo de peligro no visible al cambiar |
|Solo Presente, como el haz |Pasado vuelve a ser refugio permanente |No recomendada para este objetivo |

RF-05 regula la defensa del jefe, no prescribe en qué dimensión daña Attack3. La recomendación no cambia cooldown0,20s, protección0,16s, matriz defensiva ni colisiones. La consulta del impacto debe usar estado confirmado, no la última tecla. Un rechazo de Shift no debe cancelar el paquete, regalar protección ni cambiar su trayectoria.

## 8. Reacción y evasión: cálculos, no prueba física

Valores leídos del Player: ancho24, alto40, velocidad240u/s, aceleración1600u/s², fricción2000u/s², salto inicial≈−514,39, gravedad ascendente1470 y descendente2205; altura ideal90u. Las pruebas antiguas muestran pequeñas diferencias discretas respecto a esa altura analítica, no una modificación de físicas.

Con advertencia de objetivo de96u de ancho se propone alejar el centro al menos48u de su punto. En el extremo, un Player cuyo centro esté alrededor de76 puede necesitar52u para escapar hacia dentro. Cálculo continuo desde reposo: (52+18)/240≈0,292s; viniendo a240 en sentido contrario, aproximadamente0,30+52/240≈0,517s. Añadiendo una **hipótesis de diseño** de0,25s para leer/reaccionar y0,10s de margen, resultan≈0,87s en el caso desfavorable. No es una medición universal de reacción humana.

El objetivo queda fijo0,75s antes de emitir y el vuelo mínimo es0,45s. Cerca del punto final hay, por tanto, aproximadamente1,20s desde fijación hasta llegada. Un contacto aéreo intermedio puede ocurrir antes: por eso la ruta también debe anunciarse y deberá verificarse el margen al abandonar cada plataforma. No se infiere seguridad de todo el recorrido solo de la cuenta del impacto final.

Para saltar con32u de despeje ideal, los pies cruzan esa altura alrededor de0,069s al subir y0,579s al bajar. Hay una ventana útil de≈0,51s, pero saltar inmediatamente al ver un aviso largo puede terminar demasiado pronto. El movimiento lateral es la respuesta primaria robusta de A; el salto se sincroniza con la emisión/llegada y se validará con el Player real. B necesita comprobar además el tiempo de paso de ambos frentes. One-way permite subir desde abajo, pero Shift durante penetración puede rechazarse; ninguna propuesta requiere que ese cambio salga siempre.

No se superponen el haz y los frentes de suelo. Su combinación podría convertir un salto normal en una colisión inevitable con la banda elevada, aunque cada ataque aislado fuera justo. No se acelera el telegráfico para compensar una primera prueba que resulte fácil.

## 9. Lectura del haz y diferenciación

El aviso actual de G usa8px fuente×0,20≈1,6u de grosor: alrededor de1,28px de pantalla a1024×572 y1,6px a1280×720. Su preparación dura0,50s; daño recién tras otros0,60s de crecimiento. Existe tiempo nominal, pero la primera línea puede perderse en las plataformas magenta y en los detalles del Pasado azul. El contraste perceptivo no se declara validado por una captura.

[Lámina de lectura del aviso](../artifacts/room5_stage_h1/05_beam_cue_review.png): Presente procede de captura G; Pasado contiene una superposición diagnóstica del mismo recurso para comparar, sin ejecutar/modificar el juego. El muestreo1024 es aproximado; no sustituye el stretch ni una prueba real de visibilidad/movimiento.

Attack3 debe anunciarse con **postura de cañón + objetivo fijado + ruta/forma corta**, frente a la línea larga del haz. La separación no debe depender solo de magenta/ámbar. La lámina usa colores de anotación para facilitar el análisis, no aprueba una nueva paleta de sprites. Solicitar feedback con usuarios sobre dirección, fijación de objetivo y seguridad dimensional antes de ajustar duraciones. El haz permanece intacto en esta fase.

## 10. Arquitectura futura de IA, sin implementación

Mantener la máquina del Guardián; no State Charts, Beehave ni controlador global. Cambios futuros candidatos:

| Estado/puerta | Responsabilidad propuesta |
|---|---|
|IDLE y encuentro explícitamente habilitado |Evaluar ataque elegible, solo tras recuperación; hoy esa habilitación no existe |
|CANNON_AIM, nuevo |Fijar orientación, seguir objetivo0,25s y después bloquearlo |
|CANNON_RELEASE, nuevo |Reproducir2–3 y emitir una sola vez con ID de ejecución |
|CANNON_SETTLE, nuevo |Poses4–5 y esperar a que paquete/frentes/disipación terminen |
|RECOVER existente |Cancelar peligros restantes, restaurar orientación segura y descansar |
|VULNERABLE existente |Apertura explícita con tiempo finito cuando se apruebe su ritmo |
|DEFEATED existente |Cancelar ejecución, marcadores, paquete/frentes y callbacks una sola vez |

Un único `current_action`/bloqueo local del Guardián sustituiría la exclusividad específica de beam_running cuando llegue esa implementación. Reutilizar el concepto de elapsed/duration del controlador como reloj común de acción; no añadir Timer de IA, Timer de aviso y Timer de disparo compitiendo. El componente de trayectoria recibe edad desde ese reloj y no selecciona ataques. El haz conserva su comportamiento y sus pruebas; una futura adaptación del nombre del reloj debe demostrar esa equivalencia.

Condiciones comunes de solicitud: vivo, IDLE, ningún peligro activo, no intro/vulnerabilidad/recuperación, referencias válidas y encuentro habilitado por una decisión posterior. El disparo se vincula a la entrada en pose2 y al ID, no a cada tick ni también a pose3. Al salir de Room5 o liberar el jefe se cancelan los objetos propietarios; ningún callback puede sobrevivir apuntando a una sala liberada.

Selección propuesta, determinista para el primer prototipo: si el Player está sobre F0 o detrás del jefe, priorizar A; si está en la banda elevada, priorizar haz cuando su trayectoria sea válida. No repetir el mismo ataque en ejecuciones consecutivas cuando ambos sean elegibles. Si el alternativo no es viable, esperar/restablecer una posición elegible o permitir una repetición explícitamente acotada; no emitir un ataque sin telegráfico o imposible solo para cumplir alternancia. P1/T1 requieren el apuntado de A a su altura real, no asumir que el haz siempre llega a ellas. No iniciar por proximidad ni al cargar sin autorización específica del encuentro.

El selector debe recordar último ataque/resultado y filtrar elegibilidad antes de ponderar. Las fases futuras pueden cambiar parámetros o pesos aprobados, no duplicar estados ni ejecutar dos acciones simultáneas. La dificultad no debe incrementarse acortando sin límite los márgenes de evasión. No se implementa ningún selector aquí.

## 11. Ventanas de Vulnerable y balance provisional

**Recomendación inicial:** ofrecer apertura predecible después de cada secuencia completa, una vez desaparecidos todos sus peligros. No exponer durante un haz activo ni mientras siga viajando el paquete. También es viable abrir tras cada pareja de ataques, pero alarga el encuentro y penaliza aprendizaje; no se recomienda como primera prueba.

F confirmó que el núcleo bajo requiere salto y tajo; no se baja su collider para permitir daño desde suelo. Un Player enX140 tarda idealmente≈3,86s desde reposo hasta la posición de ataqueX1049. Desde el extremo geométricoX76 y con velocidad inicial contraria, la aproximación ronda4,35s, antes del margen humano. Una apertura global de2s empezando inmediatamente después del ataque sería inalcanzable desde lejos.

Propuesta comprobable: después de limpiar peligros, aviso/pause de aproximación **4,75s**, después postura vulnerable baja con **2,0s de exposición**. La pausa debe comunicarse sin una animación inventada; se puede sostener una pose existente. Es deliberadamente generosa y podría reducirse tras playtest, nunca presentarse como balance final. La existencia de la transición izquierda limita qué extremo se visita en una partida real; no se bloquea ni cambia aquí.

Dos tajos por apertura son una hipótesis: presentación de ataque0,50s, cooldown0,35s y dos saltos de≈0,64s permiten plantearlos a corta distancia, pero la intersección en descenso y la pose oscura deben probarse. La apertura comienza al alcanzar una pose baja anunciada, no durante la bajada inaccesible. Al vencer, cierra exposición y vuelve a recuperación; jamás resta salud automáticamente ni deja Vulnerable en bucle permanente.

Con12HP diagnósticos y daño1:6 aperturas si se consiguen2 golpes,12 si solo1. Un ciclo con ataque≈2–3s, aproximación4,75s, exposición2s y breve reposo ronda9–10s: estimación≈55–120s sin grandes interrupciones. No es una simulación de combate ni una predicción de diversión. Fallar un golpe no equivale necesariamente a perder salud. El Player3/3 tolera dos daños antes de la derrota; un encuentro largo puede castigar demasiado el aprendizaje y deberá medirse antes de cambiar HP o daño.

Plan de playtest futuro: comprobar que se distingue el ataque antes de emitir, se identifica el bloqueo del objetivo, existe evasión lateral desde centro/esquinas/cercanía, se entiende que A amenaza ambas dimensiones y se consigue al menos un golpe después de una retirada lejana. Registrar ayudas, reacción, colisiones, posiciones, tiempo de aproximación, golpes por apertura y daño recibido. Una muestra pequeña sirve para detectar confusiones, no para prometer tasas generales.

## 12. Implementación posterior y criterios de aprobación

Archivos previsibles si se autoriza A: core_guardian.gd/.tscn para estados, anclajes/orientación y propiedad de la acción; un componente local de paquete, pruebas específicas y documentación. No habría motivo inicial para modificar Player, espada, DimensionManager, GameProgress, plataformas o cámara. El haz no se retoca para presionar F0.

Pruebas futuras indispensables: las seis poses y emisión única2; alineación tras espejo a ambos lados; objetivo inmutable después de fijación; extremos y Player bajo/detrás del cuerpo; consulta barrida a la máxima velocidad; paquetes visibles al atravesar plataformas; daño en ambas dimensiones; protección y rechazo reales; cancelación al impactar, derrotarse o salir; ausencia de objetos/callbacks residuales; A→haz y haz→A sin solapamiento; ruta física hasta el núcleo y uno/dos tajos en apertura; regresiones F/G y transiciones.

Decisiones pendientes del usuario:

1. Elegir A, B u otra dirección; aprobar específicamente curva fijada y espejo del mismo cuerpo para cubrir proximidad/parte posterior.
2. Aprobar reutilización del fragmento Hold/Finish y composición de aviso, o pedir paquete/retícula/impacto al artista. No hay arte nuevo generado en H.1.
3. Aprobar peligro en ambas dimensiones para este segundo patrón y paso del paquete a través de plataformas, manteniendo al Player y sus colisiones intactos.
4. Aprobar parámetros de prototipo y apertura predecible con pausa de aproximación; la selección automática y activación del encuentro requieren autorización posterior propia.

## 13. Entregables e integridad

Se creó este documento y, en `artifacts/room5_stage_h1/`, cinco láminas, analysis.json y verification.json. Las imágenes son diagnósticos claramente rotulados; no son capturas de un segundo ataque funcionando ni recursos jugables nuevos. No se crearon scripts dentro del proyecto, proyectiles, hitboxes ni pruebas de combate. No se ejecutó la batería de regresiones ni validate porque no se modificó GDScript.

Se registraron hashes de archivos preexistentes antes de generar los entregables, excluyendo caché .godot/.git. La comparación final y hashes de los archivos creados se encuentran en [verification.json](../artifacts/room5_stage_h1/verification.json). También se cotejaron los guardados reales sin escribirlos. No se necesitó respaldar para edición un archivo anterior, ya que no se editó ninguno.

El helper y la línea base se conservan fuera del proyecto, en `C:/Users/juans/.codex/visualizations/2026/11/16/01a1e570-850c-7a83-8965-7511f3d3ed84/phase_h1_work/` y su directorio padre (`build_room5_h1.py`). Los sistemas y documentación anteriores no cambian. El trabajo se detiene después del diagnóstico y diseño; nada de lo propuesto queda aprobado por este informe.
