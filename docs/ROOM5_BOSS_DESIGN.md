# Guardián del Núcleo — Diseño propuesto

16/11/2026. No implementado. Canon: GDD v1.2, RF-05, Trasfondo y UI. Números, repertorio y etapas de este documento son hipótesis para aprobación y playtest. Véanse [plan maestro](ROOM5_MASTER_PLAN.md) e [inventario](ROOM5_ASSET_INVENTORY.md).

## Promesa del encuentro

El jugador interpreta el aviso del cañón, escoge suelo o plataforma, utiliza Pasado para cambiar su ruta de seguridad y regresa a Presente para golpear el núcleo durante el cortocircuito. Mantenerse junto al jefe atacando no debe ser la solución permanente. La retirada deja tiempo para recuperar posición; la exigencia es leer y elegir, no acertar Shift cada0,20 s.

Ejemplo propuesto: desde S1 se anuncia una línea de haz a altura del Player. El jugador salta o usa T1 en Pasado; el haz termina, el Guardián cae a vulnerable, el jugador vuelve a Presente y se aproxima a su pecho con espada. Puede arriesgar un segundo golpe o retirarse antes del siguiente aviso. Un jugador que permanece en Pasado puede sobrevivir temporalmente, pero no gana porque el escudo bloquea daño.

## Canon y margen de diseño

El GDD prescribe escudos impenetrables en Pasado, núcleo expuesto por cortocircuitos en Presente, derrota seguida de final/créditos, llave previa a Sala5 y BossHUD inferior derecho. No fija vida del jefe, daño de cada patrón, número de etapas, umbrales, duración de vulnerabilidad, desplazamiento, puerta irreversible ni política de repetición/victoria guardada. Estas decisiones no se presentan como implementadas ni aprobadas.

El material trae un androide con cañón, reposo, incorporación, despegue/retorno, rodilla vulnerable y explosión; no hay evidencia de marcha cíclica ni de tres fases artísticas. `attacking 3` son seis poses de disparo. `starting atack 1` es crecimiento del haz; no animación de brazo preparándose. No apareció ataque2 por nombre en assets. Esto no demuestra que un archivo de nombre arbitrario sea imposible, pero no permite prometer ese ataque.

## Cuerpo, escala y núcleo

Propuesta: jefe principalmente estacionario, ~190–220 px de altura corporal en reposo frente a collider Player40 (relación física visual orientativa≈5:1, no comparación de lienzos). A zoom0,78 ocuparía148–172 px, ≈26–30% de los572 px de pantalla. Medir el sprite visible real del Player en A para cerrar relación artística; su escala0,33 no identifica por sí sola altura visual.

Reposo tiene cuerpo opaco principal de≈518 px en la primera pose: escala de hoja ~0,4 produce207 px. Otras hojas dibujan anatomía a distinto tamaño: ataque3≈339 px, inicio cambia de240 a307, vulnerable se agacha. **No usar una escala raíz universal para todas las hojas**. Normalizar derivados por tamaño de cabeza/pecho/botas a un lienzo común y registrar offsets por pose; referencia inicial comparativa repose0,4, ataque3≈0,6, no valores definitivos. Conservar el descenso de postura real de vulnerable; no estirar cada pose hasta igualar altura. El documento de celdas candidatas muestra dónde un corte uniforme tocaría silueta vecina.

Raíz Node2D anclada por pies; VisualPivot contiene el AnimatedSprite2D normalizado, no escala las áreas de daño. Pivot candidato (0,0) en el suelo, offsets medidos por pose. Body sólido solo si necesario: volumen físico limitado de piernas/torso, fuera de rutas obligatorias; primera versión sin daño por contacto. CoreHurtbox de≈32×28 px como candidato a probar, centrado sobre núcleo **visible** arrodillado, siempre alcanzable con espada real; no hurtbox del lienzo entero. Muzzle/CoreAnchor se registran tras espejo horizontal. Jefe frente al centro desde la derecha de arena; reservar180–240 px de ancho y espacio superior de despegue solo si se aprueba usarlo.

La espada consulta Areas con máscara8, grupo `enemy_hurtbox`, y llama `take_damage(amount)` al **padre inmediato**. Por ello CoreHurtbox debe ser hijo directo de CoreGuardian, o necesitaría un adaptador explícito. Preferir hijo directo. El jefe valida dimensión+estado+vida al recibir daño. Si añade otra hurtbox hija directa, el deduplicador de espada las trata como el mismo target. No crear dos receptores parent independientes ni conectar daño por segunda vía.

Layers observadas: mundo1, Player2 (mask1), Enemy cuerpo4, hurtbox8; espada consulta8. Hurtbox jefe Area2D layer8, mask0, grupo `enemy_hurtbox`. Haz consulta Player2, y geometría1 si su regla lo requiere; no usar layer8 como ofensiva. Reutilizar la interfaz de daño, no la patrulla/gravedad/escala de Enemy1. Enemy1 no declara `damage_taken`; Player sí. Proponer señales propias tipadas del jefe: `health_changed(current,max)`, `state_changed(state)`, `vulnerability_changed(active)`, `phase_changed(index)`, `defeated`; BossHUD solo escucha.

## Estados propuestos

Enum en GDScript estáticamente tipado; estado y etapa son datos distintos. No plugins.

| Estado | Entrada / salida | Daño y presentación |
|---|---|---|
| DORMANT | Sala cargada→trigger con Player vivo+posesiones y acceso aprobado | Ofensiva apagada; HUD jefe oculto |
| INTRO | Trigger válido una vez→animación starting completada | Bloqueo de acceso local al comenzar; jefe no daña; Player se posiciona en zona segura |
| IDLE | Intro/fin de ciclo→temporizador+patrón permitido | Reposo; no invulnerabilidad arbitraria de Player |
| PREPARE | Ataque elegido→aviso mínimo completo | Fijar línea/objetivo una vez, no persecución instantánea posterior |
| ATTACK | Evento de emisión único→fin de ventana | Daño por volumen real, no brillo ni reproducción visual |
| RECOVERY | Fin activo→fin recuperación | Apagar ofensiva primero; decidir transición de etapa o abrir núcleo |
| VULNERABLE | Cortocircuito anunciado→tiempo de ventana | Daño solo Presente+núcleo; usar secuencia vulnerable en orden y poses finales, sin invertirla para inventar levantarse |
| PHASE_TRANSITION | Umbral pendiente tras recuperación/vulnerable→IDLE | Sin ofensiva; mensaje/pausa si no hay animación específica; no fabricar sprite |
| DEFEATED | Salud0 desde estado susceptible→fin animación | Terminal idempotente: cancelar todo, no más daño; señala victoria una vez |

Reglas globales: Player derrotado cancela encuentro y limpia, no mata ficticiamente al jefe. Muerte del jefe tiene prioridad sobre transición de etapa. Si ambos llegan a0 en el mismo paso físico, propuesta: priorizar derrota del Player y no guardar victoria; necesita aprobación y test de orden. PREPARE→RECOVERY si objetivo no válido; ninguna coroutine antigua vuelve a emitir tras cambio: usar token de ejecución o temporizador/ciclo único cancelable. No cambiar state a HURT con cada corte para interrumpir indefinidamente; feedback de golpe superpuesto sin resetear ventana.

Cada ataque usa identificador de ejecución, marca de emisión y registro de objetivos golpeados. El estado calcula tiempo de física; AnimationPlayer o frame_changed solicita el evento en el fotograma verificado en A, nunca un evento de daño anterior al aviso. Se desconecta/cancela al salir de árbol, cambiar sala, derrotar o reiniciar. Los proyectiles viven bajo BossProjectiles y se consumen por impacto/expiración/limpieza.

## Repertorio recomendado

Estos valores son semillas de ajuste, en segundos y píxeles de mundo. Validar duración total contra rects y FPS aprobados; no rellenar segundos con poses nuevas.

| Regla | A1 — Haz de cañón | A2 — Pulsos de presión (condicional H) |
|---|---|---|
| Activación | IDLE, Player en zona de combate; primer patrón fijo para enseñar | Etapa2 o alternancia aprobada, nunca a la vez que A1 |
| Distancia | Lane visible hasta borde interior; tope≈800 px, nunca vestíbulo | Pulsos horizontales desde boca, sin homing |
| Preparación | 0,75 s aviso, línea fijada al principio; reposo corporal, sin animación inexistente | 0,65 s aviso+poses1–2 de attacking3 si registro lo confirma |
| Inicio | Crecimiento visual de seis poses del haz; no daña hasta grosor reconocible | Emisión candidata pose3/4 (boca blanca); A fija frame exacto |
| Activo | 0,24 s inicial; volumen interior del haz con forma visible y final claro | 2 pulsos a intervalo≈0,36 s, velocidad≈180 px/s, vida≤4 s; máximo2 activos |
| Daño |1 por ejecución, `take_damage(1)` |1 por pulso, invulnerabilidad normal evita pérdidas repetidas inmediatas |
| Peligro | Franja horizontal a altura fijada del Player; no llenar toda la pantalla | Ruta recta anunciada; desaparece contra mundo sólido activo o borde de arena |
| Esquiva | Salto/descenso/posicionamiento; Shift protegido atraviesa daño breve si timing correcto | Saltar, cambiar de apoyo o Shift oportuno; nunca exigir dos Shifts antes de cooldown |
| Dimensión | A1 amenaza ambas inicialmente, con misma advertencia visible; versiones solo Pasado se ensayan en I como variación aprobada | Propuesta pulsos ligados a Pasado, fantasmas sin daño en Presente; distinguir por símbolo/texto, no solo color |
| Fin | Desactivar daño; finishing6×64, última celda vacía; no hitbox durante disipación | Consumir al impactar; limpiar todos antes de abrir núcleo |
| Recuperación |0,55 s + ventana vulnerable1,6 s |0,65 s + ventana vulnerable1,6–1,9 s |
| Recursos | Crecimiento, tile64, disipación; cuerpo repose, cañón anclado | attacking3 muestra descarga pero **no incluye proyectil aislado identificado** |

A2 no queda autorizada por existir la hoja. Para pulsos usar derivado del efecto64 si el usuario acepta que represente proyectil; alternativa sin arte nuevo: variante temporal de A1 con pulsos, aprobando ese uso. Si no se aprueba ninguno, no inventar ataque2: quedarse con A1 y cambiar sus líneas/ritmo de forma legible; evaluar si eso sostiene dos etapas.

`exit`/`retorn` parecen despegue/aterrizaje, no tránsito lateral de caminata. Recomendación: reservar para intro/cierre o futura variante aprobada; no infligir daño de caída sin aviso/efecto. Repose independientes son poses aéreas; no renombrarlas como suelo sin comparar base. La condición de victoria viene de salud0, no del final del sprite defeated.

Geometría de ataques: propuesta haz A1 detiene visual y daño en el primer obstáculo sólido activo; fantasmas no lo bloquean. La ruta de aviso debe reflejar ese corte y fijarse durante esa ejecución para que cambiar de dimensión no alargue súbitamente el haz hacia un Player sin aviso. Si cambian colisiones durante activo, mantener alcance avisado o abortar ese ataque; decidir en G y probar. No comprobar este bloqueo mediante TileMap antiguo de Room1; las formas reales de Room5 mandan.

## Shift y equilibrio

0,16/0,20 equivale a cobertura temporal nominal del80% si se logran cambios sin huecos de input ni rechazo; quedan0,04 s sin protección por ciclo. Es una cota teórica, no inmunidad garantizada: cooldown baja en proceso, solicitud en física y temporizador independiente, y no hay auto-repeat continuo por mantener tecla. Los límites dependen de fases de actualización. Probar spam con pulsos de input reales, no resetear timers artificialmente.

No bajar protección/cooldown ni agregar ataques que la ignoren. Un haz de0,24 s no cabe entero en una protección0,16; moverse fuera de la línea sigue teniendo valor. Garantizar salidas geométricas para quien llega con cooldown activo. No diseñar una ráfaga únicamente para acertar el hueco de0,04 s. Conectar la utilidad de Shift a ruta/refugio dimensional y al retorno a Presente para dañar. Estar en Pasado es defensa, no pausa del jefe. Ningún estado, salud, aviso o tiempo de vulnerable se reinicia al alternar.

Ventana vulnerable empieza con cortocircuito visible tras ataque; dura inicialmente1,6 s desde que el núcleo es legible y alcanzable. En ambos mundos se muestra estado, pero en Pasado la hurtbox rechaza y comunica escudo; en Presente recibe1 por corte. No cerrar al primer golpe ni cambiar de etapa a mitad de la ventana. Si acercarse desde refugio consume casi toda ventana, aumentar duración o ajustar anclaje/ruta en B/I con aprobación, no ampliar espada. Después volver a reposo usando pose de reposo registrada; interpolación/flash de transición no se vende como animación inédita. Evitar relanzar toda la incorporación starting tras cada golpe.

## Etapas, salud y dificultad

Recomendación provisional: **dos etapas**, 12 puntos de jefe, daño1 por corte y por ataque. Justificación: salud12 permite usar tres segmentos visuales (4 puntos por segmento) y varias ventanas de contraataque, sin diez minutos de pelea. Umbral6/12: etapa2 en el siguiente límite seguro, con aviso0,8–1,0 s y sin ataque superpuesto. No curar al jefe al cambiar de etapa. Etapa1 enseña A1 y núcleo; etapa2 alterna alturas o A2 condicional, sin acelerar tanto que borre avisos. No tercera etapa: no está exigida ni tiene arte exclusivo identificado.

Presentación de0,50 s limita cadencia real aun con cooldown0,35; una ventana1,6 s deja típicamente2–3 golpes solo si ya se está cerca, no prometer4. Objetivo de prueba:4–6 ventanas exitosas para victoria; ajustar vida/ventana tras observar. Alternativa sencilla:9 HP, una etapa y variaciones claras; reduce producción pero arriesga monotonía. No afirmar diversión/equilibrio por cálculos.

Playtest planificado:3 intentos por persona; registrar qué aviso entendió, golpes por ventana, tiempo de aproximación, cambios útiles frente a spam, muertes por patrón y causa, visibilidad de núcleo y salud al entrar. Revisar muerte sin oportunidad de decisión antes de tocar números. Accesibilidad: rótulos breves/símbolos para escudo y vulnerabilidad, forma del haz antes de daño, contraste contra ambos fondos, respetar input map y modo de mando real. Cualquier log futuro debe usar voz cínica C.O.R.E.-9; no se fijan diálogos finales aquí.

## HUD propuesto

Fuente barra: cuatro estados verticales (3,2,1,0 segmentos), no cuatro frames de vaciado automático. Derrota barra: secuencia vertical de fractura/dispersión, recortes irregulares por verificar. Escala por ancho visible, candidato240–280 px de UI, alto≈50–64; extraer barra única, no reducir lienzo1247×1261 entero.

Ubicación canon inferior derecha, margen16–24 px. Valor exacto textual `12/12` o pequeño relleno por segmento subordinado a salud real para no ocultar pérdidas1/12 con arte de solo tres segmentos. Propuesta cuantizada: ceil(3*hp/max_hp) segmentos, valor exacto siempre visible; alternativa recorte parcial del segmento con máscara aprobada. A hp0 fijar cero inmediatamente, luego reproducir destrucción una vez. La barra no autoriza victoria ni escribe progreso. Mover cajas de diálogo locales o posponer líneas durante peligro para no tapar cuerpo/avisos; no reubicar HUD Player ni Lente.

## Entrada, derrota y final

Entrada reversible en vestíbulo, bloqueo al trigger posterior una vez, salida no encima de Spawn. Room4 FutureRoom5Access es Marker2D en (1188,264), no transición activa. Solo ToRoom3 existe. No afirmar que esté resuelta la llave; ver decisiones.

Llegada conserva salud actual1–3, orientación, invulnerabilidad normal y recarga de espada por GameProgress; velocidad0; Room5 inicia Presente con cooldown dimensional0 y protección inactiva. No curar silenciosamente al cruzar puerta. En muerte, detener ataques en señal `defeated` del Player, apagar trigger/salidas, limpiar contenedor, dejar acabar animación y reload local. Instancia nueva comienza salud3 por comportamiento base actual, jefe lleno, Presente, timers limpios y posesiones permanentes intactas. Propuesta intro abreviada por flag **de sesión** al reintentar; no omitir avisos necesarios. En salida al menú ese flag puede perderse sin corromper progreso. Validar que no queda llegada efímera pendiente antes de reload.

Fuera de arena/por debajo de suelo sería fallo de geometría: proponer recuperación local antes del trigger y derrota local durante pelea solo si B aprueba abismo. Mapa recomendado no usa abismos y evita nueva política de checkpoints.

Guardián0: salud clamped, estado terminal, apagar ofensiva inmediatamente, limpiar efectos peligrosos, derrota corporal, barra destruida una vez, desbloquear interacción/evento final. Propuesta narrativa mínima: resolver/reiniciar reactor y terminar turno; después final/créditos como exige GDD. No agregar villano, rescate o giro nuevo. Revisar primero guion aprobado antes de escribir líneas definitivas. El orden reactor→final frente a final automático necesita decisión.

Persistencia recomendada, solo con permiso posterior explícito: añadir campo opcional `core_guardian_defeated=false` y llave si acordada, lectura compatible v1 y fallback seguro; salud/etapa del jefe no se guardan a mitad. Victoria se marca al completar resolución aprobada del reactor, no solo disparar explosión. Si falla guardar, informar y permitir reintentar guardado sin rehacer pelea ni perder datos. Continuar tras victoria ofrece final/créditos; rematch como opción explícita futura sin borrar victoria. Nueva Partida reinicia flags mediante la misma vía y rollback de error que posesiones actuales. Alternativa sin tocar GameProgress: victoria de sesión y final, declarando que Continuar repite trayecto; solo aceptable si usuario aprueba ese alcance reducido. No modificar GameProgress ahora.

## Registro de decisiones para aprobación

Todas las propuestas de esta tabla requieren aprobación en la fase indicada; ninguna altera el GDD por sí misma.

| ID / decisión | Recomendación y motivo | Riesgo | Alternativa viable | Puerta de aprobación |
|---|---|---|---|---|
| D01 tamaño |190–220 px de cuerpo; normalizar anatomía antes de hitboxes | Núcleo alto/inconsistencia de hojas | Jefe160–180 si pruebas de espada/encuadre lo requieren | A/B/F |
| D02 posición/movimiento | Derecha (1030,620) candidato, estacionario, espejo hacia centro | Cañón/anclaje mal espejado, estrategia estática | Centro con rutas a ambos lados; requiere nuevo plano B | B/F |
| D03 alcance | Haz≤800 px dentro de arena y cortado por sólido avisado | Ocultación por geometría cambiante | Haz atraviesa plataformas solo con regla visual y aprobación expresa | G |
| D04 animaciones | Conteos visuales del inventario; rects y offsets finales en A | Celdas vecinas invadidas, residuos alfa | Recorte irregular por pose sin regenerar arte | A |
| D05 etapas |2 a umbral6/12, en límite seguro | Repertorio insuficiente para diferenciarlas |1 etapa con9HP | H/I |
| D06 vida/daño |12/1, compatible con3 segmentos y arma daño1 | Pelea larga o trivial por múltiples cortes |9HP; mantener daño del Player existente | I |
| D07 vulnerable | Tras cada ciclo,1,6 s; solo Presente y núcleo (canon RF-05) | Tiempo de viaje excesivo |1,9–2,2 s antes de cambiar geometría; nunca daño en Pasado sin desviación aprobada | F/I |
| D08 escenario | Fondo uniforme≈0,76555; apoyos individuales redistribuidos | Cambia composición artística original | Mantener arte completo con apoyos adicionales visibles | A/B |
| D09 Player/suelo | Spawn seguro (140,600), base Shared visible Y620 | Nuevo arte de suelo necesario | Base segmentada con descansos más cercanos y fall recovery local | B/C |
| D10 plataformas | Dos descansos Shared y dos exclusivas Y500; saltos≤60 | Ruta ornamental sin razón durante ataque | Usar una exclusiva por etapa manteniendo retorno seguro | B/D/I |
| D11 peligro/cámara | Sin abismos ni contacto de jefe inicial; cámara Player zoom local0,78 | Campo demasiado amplio reduce detalle | Una cámara local fija, heredada desactivada | B/C |
| D12 función Shift | Refugio/ruta Pasado, contraataque Presente; sin nerf0,16/0,20 | Spam80% cobertura, camping | A1 ambas dimensiones con salida espacial; no daño que ignore protección | G/I |
| D13 entrada/llave | Respetar RF-04 y decidir adquisición antes de E | Requiere fase de progreso fuera de Room5 | Excepción explícita: acceso con Lente/tutorial en vez de llave; cambia GDD y necesita aprobación específica | Antes E |
| D14 bloqueo | Regreso antes trigger; bloquear solo durante pelea | Bloqueo al cargar/softlock | Entrada irreversible solo si usuario la elige | E/F |
| D15 retry | Reload local,3 salud nueva instancia, jefe lleno, intro breve por sesión | Cambia experiencia respecto de salud de entrada | Restaurar snapshot de entrada; riesgo de reintentos con1HP | K |
| D16 victoria/final | Cancelación inmediata, reactor, final/créditos | Guion no inventariado en esta sesión | Final automático tras derrota acorde GDD | K |
| D17 guardado/rematch | Flag opcional compatible; rematch explícito futuro | Scope requiere GameProgress/menú y pruebas migración | Final solo sesión, Continuar comportamiento previo declarado | K, permiso adicional |
| D18 UI | Inferior derecha240–280 px, segmentos+valor exacto | Oculta rutas o cuantiza salud | Máscara de relleno parcial sobre arte derivado aprobado | A/J |
| D19 empate | Si Player0 y jefe0 mismo paso, derrota Player; no guardar victoria | Orden de señales decide resultado si no se arbitra | Dar victoria y bloquear derrota; solo con política aprobada | K |

## Matriz de aceptación del combate

| Estado inicial / acción | Resultado observable esperado | Suite futura |
|---|---|---|
| Player vivo entra vestíbulo | No daño/intro; retorno posible; posesiones intactas | transición |
| Cruza trigger2 veces | Una intro, un bloqueo y un jefe | base/flow |
| Sin Lente o acceso no válido en prueba | Encuentro no inicia, salida/diagnóstico seguro | base |
| Espada toca núcleo en Pasado/cerrado | Salud jefe igual, feedback escudo/cerrado | base/phase |
| Espada toca vulnerable Presente |−1 una vez por ejecución, HUD real | base/attack |
| Player recibe haz durante telegraph | Sin pérdida | attack |
| Activo toca Player protegido0,16 o invulnerable | Sin pérdida; efecto se limpia según tipo | attack/dimension |
| Activo toca Player sin protección |−1, inmunidad normal; sin−3 en mismo frame | attack |
| Cambio rechazado | Dimensión/salud/IA intactas; sin protección nueva | dimension/phase |
| Shift repetido con cada patrón | Sin softlock y sin reinicio de ventanas/vida; salida espacial disponible | phase |
| HP cruza umbral durante espada | Una etapa pendiente, no corta vulnerabilidad actual | phase |
| Muerte en PREPARE/ATTACK/VULNERABLE | Cero emisiones posteriores; reload limpio | attack/flow |
| HP jefe0 y efecto activo | Daño apagado inmediatamente, victoria una sola vez | flow |
| Save v1 sin campos nuevos / error de guardado | Defaults seguros / rollback sin perder posesiones | persistence |
| Reinicio/Nueva Partida/Continuar final | Política elegida por usuario cumplida, sin victoria falsa | persistence/flow |

Ninguna prueba de esta matriz se ejecutó durante la planificación. Las cuentas de salto y mediciones de imagen son diagnósticos estáticos, no evidencia de combate jugado.
