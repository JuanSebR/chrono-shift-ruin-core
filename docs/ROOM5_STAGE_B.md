# Sala 5 — Fase B: diseño conceptual de arena

16 de noviembre de 2026. **Preparada técnicamente para revisión; ninguna propuesta está aprobada ni implementada.** Se entregan dos tamaños de mundo, dos paletas del Pasado, dos distribuciones físicas candidatas, comparación de jefe/cámara y análisis de espada. No se creó Room5, jefe, colisiones ni lógica. No se regeneraron atlas de A ni diagramas.

## 1. Fuentes y conservación

Se reutilizaron AGENTS, GDD v1.2, STATE, MASTER_PLAN, ASSET_INVENTORY, BOSS_DESIGN, STAGE_A y los manifiestos de A. Relectura acotada de Player.gd, Player.tscn, sword_hitbox.gd, DimensionManager, GameProgress y HUD; no se repitió el inventario completo.

MCP inicial: proyecto `c:/users/juans/chrono-shift-ruin-core`, Room4, escena1654334234622, revisión10063650:0:1, protocolo4, `playing=false`, `unsaved=false`. No se cambió de escena ni guardó/reimportó. La bandera corresponde a la escena activa, no certifica todos los recursos externos en caché.

Antes de escribir se registraron hashes de archivos existentes, incluidos recursos originales, derivados A, documentación, configuraciones y diagramas. Manifiesto externo: `C:/Users/juans/.codex/visualizations/2026/11/16/01a1e570-850c-7a83-8965-7511f3d3ed84/phase_b_work/before_hashes.json`. No se necesitó respaldar un documento existente para editarlo: esta fase solo crea archivos nuevos. La comparación final y catálogo de nuevos archivos están en [validation.json](room5_stage_b/validation.json).

## 2. Recomendación general para aprobación

Mundo **1280×720 unidades**, fondo/marco reducido de forma uniforme; Pasado **azul derivado**, conservando el ámbar/cian como alternativa; base Shared continua visible y cuatro apoyos superiores opcionales. PlayerSpawn(140,600) corresponde a piesY620; jefe principalmente estacionario con pies(1070,620), mirando a la izquierda, escala intermedia0,375 del atlas A: cuerpo en reposo194,25px.

Cámara única del Player: seguimiento normal en vestíbulo; al activar pelea, encuadre local fijo centrado(640,360), zoom equivalente0,80 a1024×572 y1,00 a1280×720. Se conserva la misma cámara; no es una modificación de Player.tscn ni de la resolución global. Política preferida: reducir las caídas mediante suelo continuo; derrota por salud sigue el reinicio local existente, no crear una penalización de caída adicional para compensar el diseño.

La espada puede alcanzar el núcleo de rodilla con un salto corto o durante el descenso de un salto normal, según cálculos con el ataque existente. **No se propone atacar desde suelo sin saltar cuando el punto medido queda fuera de su banda.** La caja corporal futura del jefe todavía puede bloquear esa aproximación: es una condición de aceptación de F, no una garantía obtenida de imágenes.

## 3. Tamaño de mundo: alternativas comparables

Lámina [01_world_scale.png](room5_stage_b/01_world_scale.png). Ambos casos usan Player visible≈42,9×74,58px y jefe194,25px en unidades de mundo, sin multiplicarlos por el tamaño de fondo. En la alternativa nativa, las posiciones y superficies propuestas se multiplican por1672/1280=1,30625 para conservar la composición relativa. Se muestran ambos mundos completos en una vista equivalente1024×572; se compara diseño, no rendimiento de motor.

| Criterio | Nativo1672×941 | Compacto1280×720 |
|---|---|---|
| Transformación de fondo |1:1 | Factor uniforme1280/1672≈0,765550 |
| Subida de60 de la propuesta compacta |78,375px |60px |
| Margen frente a salto90 |11,625px verticales |30px verticales |
| Distancia spawn→jefe proporcional |≈1214,8px |930px |
| Carrera ideal a240, sin paradas/aceleración |≈5,06s |3,875s |
| Zoom para ancho entero a1024 |≈0,61244 |0,80 |
| Player visible a ese zoom |≈45,7px de alto |≈59,7px |
| Jefe a ese zoom |≈119px de alto |≈155,4px |
| Zoom1,14, vista1024 |Solo parte del recinto |Solo parte del recinto, menos acción fuera |
| Riesgo principal |Menos margen de saltos, actores pequeños al abarcar todo |Nearest reduce detalle de arquitectura; revisar claridad |

Recomiendo compacto por el margen físico, la proximidad entre retiro/contraataque y la legibilidad de actores. No por ser automáticamente mejor todo mundo pequeño. El nativo es viable con combate más localizado y otro mapa de apoyos que no escale sus alturas; eso dejaría más espacio decorativo y exige revisar nuevamente cámara/trayectos.

**Pixel art:** conservar escala1 del fondo no garantiza píxel perfecto al mostrarlo con zoom fraccional. Al encuadrar todo, el factor combinado del fondo nativo0,61244 coincide aproximadamente con0,76555×0,80 del compacto: la arquitectura ocupa casi el mismo tamaño de pantalla, mientras Player/jefe sí cambian su tamaño relativo porque sus unidades se conservaron. El beneficio nativo depende de no alejar tanto la cámara.

En las láminas finales el compacto usa transformación afín con el mismo factor en X/Y, no estiramiento independiente: su altura natural sería≈720,383 unidades; el lienzo720 recorta≈0,383 unidades inferiores (0,5px fuente). Ambos mundos temporales comparten esa operación, origen y encuadre. No cambia resolución del proyecto ni archivos fuente.

## 4. Pasado: ámbar/cian frente a azul

Lámina [02_past_palette.png](room5_stage_b/02_past_palette.png). Misma geometría de base, apoyos, anclajes, Player, jefe, HUD de referencia y opacidad; solo fondo y contorno cambian RGB según la gradación candidata documentada en A. El Guardián no se recoloreó. Las plataformas fantasma llevan el mismo multiplicador alfa0,55 propuesto en las dos imágenes; Shared usa el mismo tratamiento neutro. Ninguno fue aplicado a los atlas.

| Evaluación | Ámbar/cian original | Azul derivado |
|---|---|---|
| Identidad industrial |Más rica: reactor cálido, maquinaria conservada, latón |Más fría; pierde parte de la distinción material del ámbar |
| Continuidad con Room4 rojo/azul |Menos directa |Más directa |
| Diferencia frente a Presente rojo |Cambia mucho por luz/estado, pero mantiene temperatura cálida |Más inmediata por temperatura y luminancia |
| Guardián rojo/oscuro |Legible; hombros compiten con algunos tonos cálidos |Mejor separación de sus hombros rojos frente al ambiente |
| Metal sólido Pasado |Cian contra ámbar destaca |Cian comparte familia con fondo; cuidar bordes y luminosidad |
| Fantasma magenta |Legible, pero se suma a cálidos |Magenta se separa claramente del fondo frío |
| Shared neutro |Legible por forma y neutralidad |Legible; necesita sostener borde claro |
| HUD de referencia |Lectura buena, atención dividida por reactor brillante |Lectura más limpia en la comparación; no prueba accesibilidad universal |
| Señales de peligro |Los avisos cálidos podrían confundirse con reactor |Avisos magenta/blancos tienen contraste cromático claro |

Recomiendo azul para enlazar con Room4 y distinguir jefe/peligros; mantener originales ámbar y opción reversible. No se declara definitivo. Alternativa conservadora: original ámbar con señales de ataque de forma/valor inequívocos y reducción local de distracción del reactor, si se aprueba. No resolver amenazas solo por color: diferenciar aviso, sólido y fantasma también por contorno, opacidad y regla constante. Las muestras de HUD son composición raster de arte existente, no una nueva interfaz funcional.

## 5. Comparación de geometrías

Lámina [03_geometry.png](room5_stage_b/03_geometry.png).

**G1, seis apoyos de A:** respeta su propuesta de cuatro Shared y dos exclusivos. Hay huecos obligatorios; el de100px entre S1/S2 queda estrecho al incluir cuerpo y seguridad. Permite exploración dimensional, pero mezcla derrota por combate con fallos de navegación. Conservarlo sería una opción si se busca un jefe centrado en plataformas y se acepta una política de recuperación adicional. No es la preferida para el objetivo de esta fase.

**G2, base continua y cuatro apoyos superiores:** caminar hasta el área de combate no exige saltos. Las plataformas permiten elevarse, cambiar de ruta y volver al suelo al fallar, sin precipicio entre apoyos. La presión debe venir de patrones legibles, y el núcleo solo puede dañarse en Presente según RF-05. Riesgo: si los ataques no amenazan el suelo, se vuelve refugio permanente; véase sección15. No se declara que la geometría por sí sola produzca un combate equilibrado.

## 6. Coordenadas candidatas G2

Todas en mundo1280×720, origen superior izquierdo; Y es cota candidata de apoyo. Son propuestas para la escena futura, no geometría del juego.

| ID / función | Dimensión | X | Y | Anchura | Diseño físico futuro, no creado |
|---|---|---|---|---|---|
| F0 base útil |Shared |80–1200 |620 |1120 |Un soporte continuo, no7 cuerpos solapados |
| R1 descanso izquierdo |Shared |300–460 |560 |160 |Apoyo superior de una vía candidato |
| P1 superior izquierdo |Presente |500–660 |500 |160 |Exclusivo de una vía candidato |
| T1 superior derecho |Pasado |700–860 |500 |160 |Exclusivo de una vía candidato |
| R2 descanso derecho |Shared |780–940 |560 |160 |Apoyo superior de una vía candidato |
| Spawn, centro del Player |Ambas |140 |600 |Collider24×40 |Pies620; sin trigger encima |
| FromRoom4, centro candidato |Ambas |180 |600 |— |Separado de área de retorno |
| Reserva de retorno |Ambas |En torno a100 |A nivel del suelo |— |Interacción/Area futura, sin dibujar puerta |
| Preparación de cámara |Ambas |400 |— |— |Antes de activar ofensiva |
| Activación |Ambas |480 |Sobre F0 |— |Solo una vez por encuentro |
| BossSpawn, pies |Ambas |1070 |620 |— |Mirando hacia la izquierda |

La base visible reutiliza7 copias de `plataforma_pasado.png`, cada una192px de anchura visible, paso160px (solape32px), envolvente visualX64–1216. La línea útil X80–1200 está enteramente cubierta con alfa255 en la lámina, por tanto no se propone una banda de colisión sin arte debajo. Se reescala uniformemente cada copia y no se dibuja un sprite nuevo. La cota usa un punto ligeramente dentro del labio metálico, no el halo ni el propulsor.

La construcción futura deberá alinear los extremos de F0 con la cara interior del contorno visible para que no haya ranuras junto a pared. La tabla define superficie útil, no autoriza muros interiores invisibles ni un rectángulo de la imagen entera. C confirma perfil de colisión, juntas y límites; cualquier ajuste se presenta para aprobación antes de aplicarlo.

## 7. Matriz dimensional y Shared

| Elemento | Presente | Pasado |
|---|---|---|
| F0, R1, R2 |Visible y soporte activo |Mismo aspecto/origen y soporte activo |
| P1 |Sólido visible/activo |Fantasma, sin colisión |
| T1 |Fantasma, sin colisión |Sólido visible/activo |
| Fondos/contornos |Capa Presente |Capa Pasado de paleta elegida |
| Decoración del reactor y pasarela pintada |Sin colisión deducida |Sin colisión deducida |

Shared no se dedujo del arte: es una reutilización deliberada propuesta. Tratamiento candidato en las láminas: conservar metal y sombras, reducir saturación al20% solo en esas instancias; base larga y descansos neutros permanecen idénticos entre dimensiones. Exclusivos conservan su color; fantasmas conservan contorno y un alfa visual0,55 adicional en estas comparaciones. El alfa y RGB originales de A no se tocaron.

La distinción tiene tres apoyos: forma de base continua, aspecto neutro persistente y ausencia de parpadeo/cambio al alternar. No depender solo de cian frente a magenta. Alternativa si se desea máxima fidelidad de color: mantener metal original en Shared, distinguirlo por base continua/descansos siempre visibles y comprobar con jugadores que no se interpreta como Pasado. El tratamiento neutro es la recomendación para aprobación; no un nuevo material aplicado al proyecto.

DimensionManager exacto existente: Shared fuera de sus arrays de formas exclusivas; `present_visuals` incluye Presente sólido y fantasma Pasado, y viceversa. No segundo gestor. La protección0,16s y cooldown0,20s permanecen. Su prueba de ocupación geométrica también se aplica a formas de destino de una vía: no asumir que el sentido one-way permite un Shift con collider penetrando.

## 8. Cálculo de saltos y criterio de margen

Datos actuales leídos, no cambiados: SPEED240px/s, aceleración1600, collider24×40; gravedad base980 sin override, ascendente1470, descendente2205, salto inicial≈−514,393. Salto sostenido ideal90px, ápice≈0,349927s. Alcance ideal a misma altura:152,554px con carrera y134,554px desde reposo, descontando18px de aceleración. Soltar salto reduce velocidad ascendente; no se supone idéntica altura con pulsación corta.

Para subida h≤90: tiempo hasta cruce descendente de destino `t=0,349927+sqrt(2*(90−h)/2205)`. Distancia con carrera240t; desde reposo240t−18 (t supera el tiempo0,15s hasta velocidad máxima en estos casos). En cada borde se reserva20px para el centro:12 de medio collider más8 de seguridad. Dos plataformas separadas por hueco g exigen movimiento del centro de **g+40px**, no solo g. Si hay solape útil≥40px, puede elegirse un salto vertical. Intervalos de lanzamiento/aterrizaje para todos los enlaces y vueltas: [análisis JSON](room5_stage_b/room5_stage_b_analysis.json).

**Corrección de interpretación de A:** el hueco100px no tiene margen cómodo desde reposo una vez incluidos collider y reserva: requiere140px de desplazamiento del centro, frente a134,554 disponibles. Déficit≈5,446px; con carrera sobra≈12,554px, todavía pequeño frente a errores/reacciones del combate. No usarlo como salto obligatorio de la pelea. Escalado al nativo, las separaciones/alturas se agrandan, pero el Player conserva su física.

## 9. Matriz de enlaces G2 y regreso

Distancias/márgenes en px; ascendentes/descentes se analizan desde un salto con impulso completo. Deslizarse/dejarse caer ofrece otras rutas que no se certifican aquí.

| Conexión | Subida / hueco | Centro requerido | Desde reposo / carrera | Margen reposo / carrera | Regreso |
|---|---|---|---|---|---|
| F0→R1 |+60 /0, solape160 |0 vertical |105,57 /123,57 |Misma holgura horizontal |R1→F0 baja60, espacio inferior continuo |
| R1→P1 |+60 /40 |80 |105,57 /123,57 |25,57 /43,57 |P1→R1 baja60: margen74,51 /92,51 |
| P1→T1 |0 /40 |80 |134,55 /152,55 |54,55 /72,55 |Igual en sentido inverso; exige dimensión destino correcta |
| R2→T1 |+60 /0, solape80 |0 vertical |105,57 /123,57 |Misma holgura horizontal |T1→R2 baja60, Shared sigue activo |
| F0→R2 |+60 /0, solape160 |0 vertical |105,57 /123,57 |Misma holgura horizontal |R2→F0 baja60 |
| F0→P1/T1 directo |+120 |— |Supera90 |Descartado |Usar descanso correspondiente |

Ejemplos de centros seguros: R1[320,440], P1[520,640], T1[720,840], R2[800,920], F0[100,1180]. Para salto vertical R2→T1 puede elegirse X820, dentro del solape seguro[800,840]. Para R1→P1 salir cerca deX440 y aterrizar desdeX520 deja el recorrido80 usado en el cálculo. No confundir los intervalos completos del JSON con una orden de saltar desde cualquier punto: cada salto debe elegir origen/destino compatibles.

Espacio superior: una subida60 entre apoyos y slab candidato de8 deja12px nominales para collider40 bajo el apoyo. Es holgura reducida; proponer superiores one-way y comprobar que no haya túneles sólidos ni superficies verticales que atrapen. En el ápice desde F0, cabeza física≈Y490; desde R1/R2≈Y430 y desde P1/T1≈Y370. No se ha propuesto techo a esas alturas. El sprite visible es más alto que el collider; plataformas deben dibujarse detrás del Player para que el arte colgante no oculte cabeza/ataques. Esa ordenación no sustituye colisión correcta.

**Estado de evidencia:** cuentas analíticas con supuestos, láminas estáticas y cobertura alfa. Ninguna conexión fue probada físicamente con el Player. No se ejecutó una escena aislada porque no se necesitaba para comparar alternativas; la comprobación definitiva corresponde a C/D.

## 10. Zonas seguras y movilidad

Vestíbulo propuesto X100–400 sobre F0: aparición, regreso antes de activar y tiempo para leer la sala. Combate principal X480–1180; retirada preferente X300–480. No es inmunidad permanente: “seguro” significa soporte estable y cambio sin jaulas de plataformas, no permiso para recibir ataques sin daño.

Descansos R1/R2 permiten revisar ambas siluetas y cambiar. Fallar una conexión superior vuelve a F0 en lugar de a un abismo; P1/T1 son rutas opcionales. El cambio sobre una exclusiva que desaparece puede iniciar caída: el suelo Shared sigue debajo. No conceder protección adicional por aterrizar, ni añadir impulso/knockback al Player para fabricar dificultad. El script actual de daño cancela presentación y respeta sus protecciones; esta fase no introduce una nueva reacción física.

Hay unos930px entre spawn y jefe y unos590px de longitud de combate desde trigger. F0 permite parar, aproximarse, retroceder y recuperar control. Quedarse junto al jefe sigue siendo un riesgo de patrones por diseñar; no se da por resuelto con geometría.

## 11. Guardián: posición, escala y volumen reservado

Propuesta principal: raíz por pies(1070,620), mirando a izquierda, factor0,375 del atlas A. Reposo194,25px de alto; frente a Player visible74,58px, relación≈2,60. En pantalla con encuadre recomendado1024: jefe≈155,4px y Player≈59,7px. A1280:194,25 y74,58px. Lámina [04_guardian_scale.png](room5_stage_b/04_guardian_scale.png) compara intermedia con imponente233,1.

Envolvente medida de masa alfa≥128 de **todas las poses preparadas** con raíz fija y espejo, incluida elevación dibujada en exit/retorn: intermediaX960,125–1163,375; Y425,75–621,125. ImponenteX938,15–1182,05; Y386,9–621,35. No son cuerpos físicos ni incluyen un vuelo futuro añadido a la raíz. Reservar aproximadamenteX950–1180/Y400–640 para intermedia; R2 termina940, dejando separación horizontal antes de la envolvente medida. No instalar un apoyo obligatorio a través del torso.

Preferencia intermedia: mayor margen contra marco/plataformas, punto de rodilla menos alto, buena presencia. Imponente es viable como alternativa visual, pero acerca brazo/cuerpo a R2 y eleva la primera postura de núcleo; no mejorarla agrandando espada. Se conservan reservas de A: cañón de última pose starting incompleto y proporciones variables entre hojas. No se regeneraron/corrigieron esos atlas. No bloquea el análisis de C sin jefe, sí necesita decisión artística antes de F.

## 12. Alcance real estimado de espada

Lámina [06_sword_reach.png](room5_stage_b/06_sword_reach.png). Se dibuja **la consulta existente**, no una hurtbox nueva. Hacia derecha: offset(28,−4), rectángulo36×28; Player24×40. Desde su centroX, espada cubreX+10..X+46. Desde sus piesF, cubreY=F−38..F−10. Para el caso espejo del jefe, se transforman los centros medidos del atlas A con raíz(1070,620), escala0,375.

| Pose vulnerable | Centro de núcleo estimado | ¿Espada en suelo con pies620? | Lectura |
|---|---|---|---|
|0 |(1070,21;511,16) |No: banda582..610 |Necesitaría aproximarse al ápice; no basar toda oportunidad en este instante |
|2, rodilla |(1077,53;563,07) |No: faltan18,93px hasta tocar el punto |Con pies590, banda552..580 sí incluye el punto |
|3, rodilla |(1077,95;572,70) |No: faltan9,30px |Más próxima; brillo cambia, futura regla de exposición debe ser clara |

Ejemplo geométrico: Player centroX1045,53, pies590 (30px de elevación), espadaX1055,53–1091,53/Y552–580. Núcleo pose2(1077,53;563,07) queda dentro, con≈14px de margen horizontal al extremo cercano y≈11px verticales. Sus pies en ese snapshot están en el aire: **no hay plataforma invisible en590**. El rectángulo blanco es su collider actual, no una nueva forma de juego.

Todavía falta comprobar que una futura colisión corporal del jefe permita colocar al Player allí sin interpenetración. Usar todo el lienzo o todo el brazo como bloqueador haría inalcanzable el punto; no se autoriza compensarlo agrandando la espada o hurtbox. Primero revisar cuerpo, postura y posición del jefe. Los landmarks son estimaciones visuales y una hurtbox real tendrá su propia extensión por aprobar.

## 13. Oportunidad temporal con el ataque EXISTENTE

No se fijan aquí tiempos del jefe. Sí se debe respetar la espada ya implementada:12 cuadros a24FPS, comienzo de consulta en índice5 (≈0,20833s tras solicitar ataque), ventana0,10s, cooldown0,35s, y presentación0,50s. No basta una foto de contacto si el daño se emite antes/después del cruce.

Con núcleo pose2 fijo, el salto debe elevar al Player entre≈18,93 y46,93px para que ese punto esté en la banda de espada. En un salto sostenido normal, durante descenso se cruza esa franja entre≈0,54758 y0,60382s desde salto. La solicitud de ataque podría intersectarla, idealmente, si ocurre entre≈0,23924 y0,39549s, considerando los0,20833s de arranque y0,10 activos. Es una banda de entrada≈0,15624s (≈9,4 pasos a60Hz), **no** una duración de vulnerabilidad aprobada ni una prueba de controles.

Recomendación de lectura: salto y corte cerca del ápice para que la consulta alcance el núcleo al descender. No exigir un tap de salto de pocos cuadros: la liberación temprana tiene otra parábola. La ventana del jefe deberá cubrir postura legible, aproximación desde ruta segura y acción de espada completa; no cerrarse antes porque el sprite parpadeó. No se asigna aquí su duración. En pruebas, si la ejecución exige precisión excesiva, revisar primero postura/altura/posición del Guardián o longitud espacial de aproximación, sin tocar físicas ni alcance global.

## 14. Zona de combate y despegue/retorno

Suelo principal delante del jefe X480–1000; ataque cercano alrededor deX1040–1060, sujeto a colisión futura. R2 termina940 y sirve de retirada; no se convierte en plataforma para atacar desde arriba cuando su altura hace pasar la espada sobre la rodilla. Las exclusivas superiores permiten cambiar altura/ruta, no son necesarias para simplemente llegar al jefe.

Exit/retorn pueden utilizarse para aparición, pausa de cambio de comportamiento o elevación/retorno al **mismo** anclaje: coste mínimo de IA, sin navegación continua ni nueva marcha. La elevación ya dibujada está incluida en la envolvente; no duplicarla moviendo también la raíz por el mismo desplazamiento. Alternativa posterior si se aprueba: dos anclajes fijos y reposicionamiento con aviso, destino libre y esas poses aéreas. No se aprueba un segundo punto, trayectoria ni velocidad, y la caída del jefe no inflige daño por simple nombre de animación.

## 15. Espacio y riesgos de ataques

Con escala intermedia y espejo, reposo0 sitúa cañón aproximadamente(980,512); attacking3 sitúa la boca aproximadamenteX1011..1027/Y536..543 según pose. La dirección ilustrada es hacia izquierda. Hay corredor visible hacia X480 y zona de retiro al oeste; no debe emitirse una amenaza fuera del encuadre o tapada por marco/HUD. No se dibujó un ataque funcional ni se creó un efecto adicional.

**Hallazgo importante:** un haz estrecho horizontal desde reposoY512 pasa sobre el collider de Player en suelo(Y580..620). Un disparo de cañón centradoY536..543 también puede pasar alto si su volumen es pequeño. Por tanto, una arena con suelo continuo no puede darse por desafiante suponiendo que esas rectas siempre amenazan al jugador. Esto es una dependencia de diseño de G/H, no un motivo para forzar saltos imposibles.

| Patrón posible, sin aprobar | Necesidad espacial | Defensa/ruta potencial | Dependencia pendiente |
|---|---|---|---|
|Haz horizontal alto |Lectura de boca, línea y plataformas superiores |Bajar a F0 o cambiar a ruta de la otra dimensión |Aceptarlo como presión de altura, no ataque que castiga siempre suelo |
|Haz dirigido con aviso |Línea de emisión que realmente cruza posición avisada, libre de tracking sorpresivo |Moverse fuera de la línea/descender; Shift con geometría libre |Autorizar orientación del efecto y compatibilidad visual con cañón; no hay preparatorias para todos los ángulos |
|Descarga de attacking3 |Espacio frente a boca, sin spawn dentro del Player cercano |Retirada/ascenso/ruta alternativa; sin exigir recarga imposible |No hay proyectil independiente confirmado: no se inventó bala ni ataque2 |
|Presión ligada a dimensión |Aviso distinguible por forma/estado y ruta alternativa alcanzable |Pasado para posicionarse, Presente para contraatacar |Elegir ataques activos por dimensión en I; no existe inmunidad ambiental ya implementada |

La expansión del haz llega a≈150px de grosor fuente y el hold tiene32px visibles: combinarlos exige una escala coherente de efectos aprobada después, no estirar altura y anchura por separado en esta fase. No se fija anchura dañina, duración, FPS, daño, velocidad, tracking o tiempo vulnerable. No dar por solución un haz gigante que cubra toda la arena ni uno estrecho que nunca toca suelo.

En cercanía, el Player puede quedar detrás de la boca frontal al alcanzar el núcleo. Esa zona ciega puede ser la recompensa de recuperación, pero no un camping permanente durante todos los estados. Resolver selección de objetivos/postura/reposicionamiento antes de cerrar patrones. No añadir daño corporal inevitable sin aviso para tapar el problema.

## 16. Función dimensional y bloqueos

Canon RF-05: daño al jefe solo en Presente+núcleo expuesto. Propuesta de ciclo: leer aviso, escoger altura/ruta, usar Pasado para llegar a T1 o reposicionarse, bajar a R2/F0, volver a Presente antes del contraataque, acercarse, saltar/cortar y retirarse. El fondo no es protección automática; cualquier ataque ligado a una dimensión debe declararse y enseñarse en I.

La base Shared evita que el cambio destruya el único soporte de seguridad. P1/T1 están separados40px a la misma altura; cambiar durante su transferencia es una decisión espacial, no repetir Shift cada0,20s. Las plataformas desaparecidas quedan fantasma con el mismo anclaje. Un cambio rechazado mantiene dimensión y no concede protección nueva. El jefe no reinicia vida/estado por `dimension_changed`.

Riesgos: intentar activar el destino mientras collider atraviesa su slab; ghost que parezca sólido; confundir Shared neutro con metal Pasado; refugiarse permanentemente abajo si todos los tiros son altos. Diseñar rutas que funcionen con cooldown activo y no se basen en el hueco temporal0,04 entre protección/cooldown. Probar bloqueo junto a labios, aire, suelo y debajo de superiores; el diseño no autoriza desactivar las validaciones del gestor.

## 17. Cámara: comparación en ambas resoluciones

Lámina [05_camera.png](room5_stage_b/05_camera.png). Se muestra el Player enX480, punto de activación candidato. Las posiciones del HUD se dibujan con arte existente y barra del jefe de A únicamente como referencia; no se creó BossHUD. Las cuentas usan viewport efectivo indicado, sin alterar stretch del proyecto.

| Opción |1024×572 |1280×720 | Resultado / riesgo |
|---|---|---|---|
|Seguimiento actual zoom1,14 |Campo≈898,25×501,75 |≈1122,81×631,58 |Al activar cerca deX480, jefe queda fuera o cortado a derecha. Más detalle, lectura inicial insuficiente |
|Local recortada, escala por ancho |Zoom0,90, campo≈1137,78×635,56 |Zoom1,125, campo≈1137,78×640 |Muestra combate, pero no todo retiro/vestíbulo; necesita política si Player va muy a izquierda |
|Local completa recomendada |Zoom0,80, campo1280×715 |Zoom1,00, campo1280×720 |Muestra F0/actores/avisos durante pelea, sin nuevo seguimiento |

Recomendación: misma Camera2D del Player, encuadre de batalla centrado(640,360) y `zoom equivalente=ancho visible/1280` en estas relaciones de aspecto. A1024 se recortan≈2,5 unidades arriba/abajo; todos los elementos jugables Y425..620 quedan dentro. A1280 se ve el mundo completo. No es fijar resolución de proyecto ni suponer que coordenadas de pantalla son mundo.

Antes del encuentro se puede conservar seguimiento1,14 con límites locales de Room5. Preparar el encuadre desdeX400 y confirmar que cámara/jefe son legibles antes de habilitar ofensiva al triggerX480. Tras victoria/reinicio/salida restaurar propiedades de esa misma cámara; no dejar dos activas ni añadir controlador global. La coordinación futura cabe en el controlador local de sala, con permiso de implementación posterior. El suavizado no debe retrasar avisos; comprobar durante la transición, no prometerlo por el cálculo estático.

Una muestra inicial de barra inferior tapaba pies/suelo: la lámina final usa el mismo recurso, tamaño útil≈252px de ancho y carcasa por debajo de la cota de pies, con margen inferior≈16px a1024. Se recortó únicamente padding transparente para dibujarla. Su ubicación/legibilidad real, salud/Lente y mensajes requieren J; no se movieron HUD existentes. No mostrar diálogo largo encima de una preparación peligrosa. Se verificará que barra no tape F0, corte ni zona de descenso.

## 18. Entrada, salida y activación

Room4 conserva `FutureRoom5Access` como Marker2D(1188,264), no transición; su única salida actual sigue apuntando a Room3. No se añadió ninguna. Propuesta para E: llegada en FromRoom4(180,600), velocidad0, Presente, posesiones/salud conservadas por la transferencia existente; spawn directo de prueba(140,600). Separar retorno y spawn para evitar bucles inmediatos.

Vestíbulo hastaX400; triggerX480, solo si Player vivo, espada/Lente y acceso válido. Se prepara cámara, se reproduce introducción aprobada y después empieza ofensiva. No arrancar jefe durante scene_changed ni restaurar salud al entrar de forma silenciosa.

Bloqueo recomendado: deshabilitar el **acceso de retorno** durante combate, no poner un muro invisible interior. La base continua y la cámara completa dejan retirada dentro del recinto; si el Player vuelve al vestíbulo, la pelea no se reinicia ni concede victoria. La política de alcance de ataques allí debe diseñarse de modo que no permita ganar desde fuera de combate. No asumir una puerta dibujada que no existe: la presentación visual del acceso/bloqueo queda pendiente de E y del arte aprobado. No se inventó arco, reja o sprite de puerta en estas láminas.

Al ganar: apagar amenazas, liberar acceso/evento final y cumplir final/créditos del GDD, con guion y persistencia pendientes de K. No escribir diálogos definitivos ni agregar lore aquí.

## 19. Caídas y reintentos

| Política | Ventaja | Problema | Recomendación |
|---|---|---|---|
|G1 caída mortal |Simple y tensa |Esquiva correcta puede terminar en derrota por hueco |No preferida para este objetivo |
|G1 checkpoint con penalización |Permite reintentar navegación |Añade regla/daño y limpieza que deben balancearse |Solo si se aprueba mantener huecos |
|G2 base segura |La dificultad puede concentrarse en ataques |No arregla por sí sola camping/ataques altos |**Preferida** |

En G2, caer de superiores significa aterrizar en Shared, sin nueva penalización. Debe impedirse salir por ranuras de borde alineando suelo/marco visibles, no usando paredes interiores inventadas. Si durante C se atraviesa el suelo o cae fuera por un fallo, se trata como defecto geométrico; no validarlo agregando una KillZone. Una futura recuperación local de diagnóstico sin penalización puede proponerse para anomalías, pero no fue creada ni adoptada como mecánica de pelea.

Derrota por salud: cancelar inmediatamente amenazas/encuentro, dejar terminar derrota y reiniciar Room5 local como base existente. Nueva instancia con salud base3, posesiones permanentes conservadas, jefe lleno y Presente limpio; opción de intro abreviada por sesión requiere K. No se modifica el sistema general de derrota ni se define aquí victoria guardada. Retirada a R1/F0 no cura ni resetea al jefe.

## 20. Llave del Reactor: dependencia sin ubicación canónica

El GDD menciona la Llave de Acceso al Reactor en Objetos y RF-04: se necesita **antes de entrar a Sala5**. No especifica sala de obtención, evento, autor del permiso, aspecto, condición ni si es una recompensa automática. En GameProgress solo se observan espada/Lente/tutoriales/diálogos y transferencia; no flag, método acquire ni guardado de llave. La inspección acotada no encontró un otorgamiento de llave en narrativa consultada. No afirmar que una línea de diálogo equivalga a obtenerla.

| Alternativa para decisión del usuario | Ventaja | Coste/riesgo |
|---|---|---|
|Otorgarla al completar tutorial Room4 |Evita retroceso y usa aprendizaje ya validado |Es una nueva decisión de diseño: requiere evento explícito, feedback y persistencia; no está en GDD |
|Objeto recogible anterior a Room5 |Cumple literal “encontrar”, interacción clara |Ubicación/arte/evento aún no aprobados; afecta una sala existente |
|Evento anterior aprobado que ya implique autorización |Reutiliza narrativa si el usuario confirma el vínculo |No se identificó uno concreto que otorgue la llave; no inventarlo |
|Sustituir requisito por Lente/tutorial |Reduce alcance |Desviación RF-04: solo con aprobación explícita, no opción por defecto |

Recomendación de menor coste técnico: otorgamiento explícito tras completar Room4, **si el usuario aprueba esa decisión narrativa y su presentación**; alternativa más fiel a “encontrar”: objeto previo al acceso. La salida de Room4 debe exigir llave en E mientras RF-04 siga vigente, además de condiciones aprobadas. C puede probar Room5 aislada sin conectar esa salida; no bloquear todo diseño de arena por una llave inexistente.

Trabajo faltante antes de E: definir adquisición, flag permanente con default seguro para saves v1, evento/senal, lectura/escritura/rollback, mensaje de acceso denegado/confirmado y Nueva Partida/Continuar. Resolver retrocompatibilidad de partidas que ya completaron Room4: no regalar llave ni dejar softlock sin decisión aprobada. Ninguno de esos archivos se modificó. No se fijó una nueva historia ni se editó GDD.

## 21. Pruebas necesarias en C y siguientes

C, tras aprobación: Room5 base sin IA, sin activar pelea ni conexión. Una instancia de Player, una Camera2D activa y CombatHUD; marcadores y reserva de volumen del jefe, sin entidad funcional. Probar carga, spawn libre, suelo continuo y juntas, bordes alineados con marco, ausencia de rutas de caída accidental, andar/parar/retroceder, altura física y orden visual de superiores, cámara local propuesta a ambas resoluciones. Crear tests focalizados de base y ejecutar validate tras cambios GDScript autorizados. Presentar árbol antes de editar escena compleja y respaldo con hashes.

D: gestor exacto, arrays/capas, rechazo seguro, cooldown/protección sin cambios, recorrido de todos los enlaces en ambos sentidos con reposo/carrera/salto liberado/ápice, caída desde exclusivas a F0, paso bajo superiores y cambio junto a labios. Incluir el caso de collider ocupando destino one-way. No ajustar plataformas automáticamente si falla: documentar y someter corrección de mapa a revisión.

F/G/I: aproximación al núcleo con espada real y cuerpo real del jefe; todos los estados/posturas, animación y frame5 de espada, interrupción por daño, punto oscuro/luminoso, rango de ataque, muerte/cancelación y señales. Validar que el Player no necesita atravesar una colisión del jefe ni acertar una ventana visual inaprovechable. Verificar amenazas de suelo y altura, ausencia de camping dominante, posibilidad de esquiva con cooldown activo, lectura de avisos dentro de cámara y tamaño real de HUD. No alterar tests previos para forzar PASS. Guardados siempre aislados y pruebas secuenciales cuando escriban progreso.

Estos son criterios futuros, no resultados de esta fase. La presente evidencia es analítica/visual y de integridad; no se ejecutó física Godot ni juego.

## 22. Decisiones pendientes, entregables y estado

| Decisión | Recomendación para aprobación | Alternativa / condición |
|---|---|---|
|Mundo |1280×720 |Nativo si se rediseña el área útil sin escalar saltos ciegamente |
|Pasado |Azul derivado |Ámbar original preservado |
|Geometría |G2, base continua visible |G1 solo aceptando navegación más exigente y política de caídas |
|Shared |F0/R1/R2, tratamiento neutro20% saturación |Metal original con señal persistente/forma, comprobar confusión |
|Player |Spawn(140,600), llegada(180,600) |Ajustes al alinear acceso real en E, sin solaparlo con retorno |
|Guardián |Pies(1070,620), espejo, escala0,375 |Imponente0,45 con menos margen; revisar anatomía A antes de F |
|Espada |Contraataque en postura de rodilla, salto/corte con interfaz existente |Ajustar postura/posición del jefe si cuerpo/ventana reales lo impiden |
|Cámara |Una cámara, encuadre local completo durante pelea |Recorte0,90 solo si retiro/avisos quedan siempre visibles |
|Caídas |Base segura; caída superior sin nueva penalización |Recuperación adicional solo si se eligen huecos |
|Activación/retorno |Trigger posterior, bloqueo del acceso durante combate |Presentación visual del acceso aún pendiente, sin puerta inventada |
|Llave |Decidir otorgamiento explícito tras Room4 antes de E |Recogible previo; no sustituir RF-04 tácitamente |
|Ataques |Revisar direcciones/alturas y futura amenaza de suelo |No aprobar combate por un haz alto que no toca al Player |

Archivos nuevos: este informe,6 PNG comparativos y2 JSON bajo `docs/room5_stage_b/`. [Análisis numérico](room5_stage_b/room5_stage_b_analysis.json), [verificación y hashes](room5_stage_b/validation.json). Las6 láminas A–F están enlazadas en sus secciones; nombres01_world_scale,02_past_palette,03_geometry,04_guardian_scale,05_camera,06_sword_reach.

`game-designer` guio la recomendación de priorizar combate legible sobre saltos obligatorios ajustados; `godot-gamedev` obligó a distinguir consultas reales de espada, fotografía de contacto y prueba física. No se actualizó diagram-design porque los diagramas de arquitectura/estados/flujo no contienen estas coordenadas ni necesitaban cambios; se preservaron.

**Cierre:** Fase B técnicamente preparada con alternativas comparables, recomendación y dependencias explícitas. Revisión del usuario pendiente. No se crean Room5, Boss/BossHUD, IA, ataques, hitboxes, KillZones, checkpoints o transiciones; no se cambian juego, GDD, plan maestro, originales, derivados A, cámara, memoria o configuración. C requiere autorización independiente.
