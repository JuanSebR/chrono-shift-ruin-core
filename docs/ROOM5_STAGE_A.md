# Sala 5 — Fase A: preparación de recursos

16 de noviembre de 2026. Alcance exclusivo autorizado: inventario, extracción derivada y prototipos visuales. **Preparación completada con reservas de origen; continuidad del jefe parcialmente resuelta.** No se construyeron escenas, IA, ataques, colisiones, HUD funcional ni transiciones. Fase B pendiente de aprobación independiente.

## 1. Resultado y archivos

Se verificaron13 PNG de escenario y15 del jefe. Inventario actualizado: [ROOM5_ASSET_INVENTORY.md](ROOM5_ASSET_INVENTORY.md). Se prepararon14 atlas de jefe/efectos/barra,63 celdas en total (62 con contenido y1 vacía final intencional), un atlas de4 plataformas y13 láminas/prototipos: **28 PNG derivados**. Se agruparon las poses por secuencia para evitar63 archivos individuales.

Metadatos exactos: [manifiesto del jefe](../assets/sprites/jefe/derived/room5_stage_a_manifest.json), [superficies](../assets/tiles/sala%205/derived/room5_surfaces.json), [alcanzabilidad](../assets/tiles/sala%205/derived/room5_reachability.json), [validación](../assets/sprites/jefe/derived/room5_stage_a_validation.json). El manifiesto incluye28 SHA-256 fuente, métricas alfa/resolución, rects/offsets por pose, ejes y estimaciones de núcleo/cañón. Los campos de centros son referencias visuales; no son coordenadas físicas aprobadas.

Archivos previos modificados: **solo docs/ROOM5_ASSET_INVENTORY.md**, con copia previa. Archivo documental nuevo: este informe. No se reescribieron MASTER_PLAN, BOSS_DESIGN, STATE ni GDD: sus hipótesis previas se interpretan con las correcciones explícitas de esta fase. Los tres diagramas conceptuales permanecen byte a byte iguales. No se necesitó otro diagrama de diagram-design: mapas y láminas con el arte aportan aquí información más útil.

## 2. Conservación y estado del editor

Antes de generar: MCP confirmó proyecto `c:/users/juans/chrono-shift-ruin-core`, Room4, escena1654334234622, revisión10063650:0:1, protocolo4, `playing=false`, `unsaved=false`. No se cambió de escena ni se guardó/reimportó desde herramientas. Esa bandera acredita la escena activa, no todos los recursos externos en caché; la antigua marca de SpriteFrames no se limpió ni sobrescribió.

Respaldo externo: `C:/Users/juans/chrono-shift-backups/room5_stage_a_20261116/`. Contiene `ROOM5_ASSET_INVENTORY.before.md`, `original_pngs.zip` y `before_hashes.json`. El ZIP conserva los28 PNG originales con rutas. Se registraron944 archivos existentes relevantes de proyecto/documentación/skills/configuración/diagramas/recursos antes de escribir derivados; caches `.godot` e imports generados quedan fuera de ese control. La comparación final debe mostrar únicamente la modificación autorizada del inventario. No hay Git en esta carpeta; el respaldo externo es el punto de recuperación.

Las herramientas empleadas fueron Pillow13 y NumPy ya instalados, y lecturas MCP. Scripts auxiliares de diagnóstico fuera del proyecto, bajo el espacio de visualizaciones de Codex; no son código jugable. No se instaló nada, no se ejecutó Playwright ni se escribió memoria/credenciales/progreso.

## 3. Fondos, composición y diferencias reales

Los5 recursos de fondo/marco/referencia son PNG1672×941: fondos RGB opacos, contornos RGBA con interior transparente, `diseño s5.png` RGB de referencia. Ambos fondos y ambos contornos se colocaron con **escala(1,1), origen(0,0), encuadre1672×941**. No hay transformación geométrica adicional justificada. La anchura de la hoja sólida de Presente es1671: no se estiró para forzar1672.

La referencia `diseño s5.png` se parece al montaje fondo+contorno del Presente, pero **no es el mismo bake píxel a píxel**: MAE RGB4,719708/255, solo0,002415% de píxeles idénticos. Hay diferencias en el centro, no únicamente una traslación de marco; no debe sumarse como capa encima ni corregirse con deformación. La alternativa modular conserva estructura/fondo por separado. Las superficies se reconstruyeron desde piezas transparentes, manteniendo las posiciones generales del montaje, no se presentan como copia exacta del RGB.

[Contornos superpuestos a1:1](../assets/tiles/sala%205/derived/room5_background_alignment.png): eje centralX836, referenciaY470 y límites de lienzo. La arquitectura cambia por dimensión: columna/pared no tienen que coincidir píxel a píxel para compartir coordenadas. El resultado no presenta salto de origen al alternar, pero los detalles/aberturas diferentes y los apoyos deberán revisarse en B con mapa definitivo.

El fondo del Pasado suministrado es **ámbar/cian**, no azul. Se preservó una [composición fiel a su color fuente](../assets/tiles/sala%205/derived/room5_past_source_preview.png) y se preparó la variante azul pedida como **propuesta cromática separada**. Gradación solo de fondo/marco: luminanciaL=0,2126R+0,7152G+0,0722B; RGBsalida=0,22RGBentrada+0,78L·(0,62;0,92;1,35), limitado a0..255; alfa sin cambio. No se recolorearon plataformas ni jefe. Elegir entre fuente ámbar y azul requiere aprobación visual, no es una sustitución ya aplicada al juego.

## 4. Negro opaco: solución y límites

Problema confirmado en `plataformasPresent.png` y `plataformasPast.png`: RGB sin alfa; los píxeles negros pertenecen al lienzo opaco y también a sombras del metal. Los fondos/referencia completos también son RGB, pero allí la opacidad es correcta. No se ejecutó chroma-key global ni borrado de negro.

Solución adoptada: reutilizar `plataforma_presente.png`, `plataforma_pasado.png` y sus dos fantasmas originales, que ya tienen alfa válido. Se empaquetaron mediante **traslación solamente**, sin escala ni cambio RGBA, en `room5_platform_pairs_atlas.png` (2048×288,4 celdas512×288). La validación compara cada área pegada con su fuente: **4/4 RGBA idénticos**, incluidos negros y RGB de píxeles transparentes. Esto resuelve la reutilización fiable sin inventar una máscara para las hojas RGB.

La reconstrucción de la distribución original usa las piezas individuales con escala uniforme por anchura visible; no extrae milagrosamente la misma silueta del montaje opaco. Algunas curvas/bordes difieren. Si B exige fidelidad exacta al montaje, hará falta una máscara de artista o confirmar equivalencia por pieza antes de extraer ese RGB. Los montajes translúcidos contienen residuos alfa y halos amplios; se conservaron originales y se prefirieron las versiones individuales.

## 5. Parejas sólido/fantasma

Cada pareja comparte un **ancla de labio superior candidata(256,96)** en la celda derivada. No se alineó usando bbox de halo. Contacto visual: [parejas](../assets/tiles/sala%205/derived/room5_platform_pairs_review.png).

| Recurso original | Ancla fuente candidata | Traslación al atlas | Celda X | Observación |
|---|---|---|---|---|
| plataforma_presente.png |(256,73)|(0,23)|0 | Sólido; contorno quebrado no equivale a plano rectangular lleno |
| plataforma_pasado.png |(256,76)|(0,20)|512 | Sólido; cara metálica superior, no propulsor inferior |
| plataforma_presente_translucida.png |(256,73)|(0,23)|1024 | Fantasma, nunca collider adicional |
| plataforma_pasado_translucida.png |(256,90)|(0,6)|1536 | Desfase vertical de−14 respecto del labio de su sólido si se usaran sin registro |

El halo se extiende más allá de los sólidos; no cortar brillo para igualar bbox. Las líneas de revisión muestran el registro propuesto. La cara quebrada del Presente y la forma del fantasma no son contornos físicamente idénticos; eso debe quedar en el contrato de colisión de B. No se fijó una shape.

## 6. Superficies visibles originales

Coordenadas en imagen1672×941, origen superior izquierdo. IntervalosX con extremo final exclusivo; Y es la cota superior aproximada del labio visible, no una colisión definitiva. Las mediciones de regiones luminosas se contrastaron visualmente; el borde oscuro puede extenderse unos píxeles. Las cifras no autorizan cuerpos físicos.

| ID | Clase | Fuente | X | Anchura visible | Y superior aprox. | Variante fantasma |
|---|---|---|---|---|---|---|
| P1 |B Presente |plataformasPresent.png |46–506 |460 |144 |PresenteTransLucid / individual presente translúcida |
| P2 |B Presente |misma |611–1060 |449 |144 |misma pareja |
| P3 |B Presente |misma |1166–1627 |461 |144 |misma pareja |
| P4 |B Presente |misma |46–506 |460 |683 |misma pareja |
| P5 |B Presente |misma |612–1061 aprox. |449 |683 |misma pareja |
| P6 |B Presente |misma |1167–1627 aprox. |460 |683 |misma pareja |
| T1 |C Pasado |plataformasPast.png |62–475 |413 |420 |PastTransLucid / individual pasado translúcida |
| T2 |C Pasado |misma |629–1043 |414 |420 |misma pareja |
| T3 |C Pasado |misma |1196–1610 |414 |420 |misma pareja |
| Arquitectura de fondo, reactor, tuberías y pasarela pintada |D decorativo |fondos |N/A |N/A |N/A | Sin colisión inferida |
| Contornos/paredes/molduras |D visual en esta fase |contornos |bordes |N/A |N/A | B decidirá límites físicos visibles |
| Compartidas originales |A |**ninguna confirmada** |— |— |— | No deducir Shared por repetición de dibujos |

Los9 apoyos son flotantes y no conectan con un suelo inferior continuo en el arte. El reactor y su pasarela del fondo del Pasado son D, no una plataforma de salvación deducida. No hay apoyo compartido probado en las dos dimensiones.

## 7. Alcanzabilidad: diagnóstico, no prueba jugada

Código actual: SPEED240px/s, ACCELERATION1600px/s², collider24×40. Sin override de gravedad en project.godot: gravedad base980, ascendente1470, descendente2205. Velocidad de salto inicial recalculada≈−514,393px/s. Salto sostenido ideal:90px, ápice0,349927s, vuelta a igual altura≈0,635641s; distancia con carrera≈152,554px y desde reposo≈134,554px (restando≈18px por aceleración). `_handle_jump` reduce velocidad al soltar: no prometer altura fija para pulsación corta. Discretización física y márgenes importan; no se ejecutó Player.

Original: ascender P4/P5/P6→T1/T2/T3 exige263px; T1/T2/T3→P1/P2/P3 exige276px. Hay superposición horizontal de unos413–414px, pero **no corrige la falta de altura**. Separaciones horizontales aproximadas de las columnas:105px y106–107px en Presente;154px y153px en Pasado. A igual altura, esas últimas están cerca o fuera del alcance ideal y sin margen de collider; no etiquetar viables. Entre las dos filas del Presente hay539px de altura.

Con escala de escenario1280/1672, desniveles263/276 quedan≈201,34/211,29px: tampoco se vuelven saltables por reducir fondo. El arte nativo es un catálogo de distribución visual, no un nivel navegable listo.

## 8. Variante candidata E

Se dibujó una alternativa reutilizando los **mismos sprites existentes**, sin dibujar plataformas nuevas ni crear un suelo invisible. Coordenadas candidatas en mundo1280×720; para la lámina se multiplican uniformemente por1672/1280. Ninguna posición fue aplicada a Godot.

| ID | Clase propuesta | X | Y superior | Función |
|---|---|---|---|---|
| S0 |A compartida |60–260 |620 | Aparición/retiro seguro |
| S1 |A compartida |300–500 |560 | Descanso izquierdo y cambio |
| P1 |B Presente |380–580 |500 | Ruta superior del Presente |
| T1 |C Pasado |640–840 |500 | Ruta superior del Pasado |
| S2 |A compartida |600–800 |560 | Descanso derecho y retorno |
| S3 |A compartida |840–1220 |620 | Apoyo amplio del jefe y Player |

Shared se propone como reutilización deliberada de metal existente en ambas dimensiones. Su aspecto cian podría confundirse con Pasado: B debe aprobar un tratamiento/etiqueta inequívoco antes de volverlo físico. No se certifica Shared por el color ni por una coincidencia de montajes. **Esta variante tiene huecos; no usa el suelo continuo del plan maestro.** Su política de caída y seguridad debe decidirse en B. Es una alternativa visual para no fabricar nuevo arte de suelo automáticamente, no un reemplazo aprobado del plan.

Enlaces candidatos: S0→S1 hueco40/subida60; S1→P1 solapan120/subida60; P1→T1 hueco60/mismaaltura con cambio; S1→S2 hueco100/mismaaltura; T1→S2 solapan160/descenso60; S2→S3 hueco40/descenso60 (vuelta requiere subir60). Salida por borde con centro al menos12px dentro y aterrizaje con centro al menos12px dentro: intervalos exactos por enlace en JSON. A subida60, distancia ideal desde reposo≈105,506px; aun así hay que ensayar borde real, salto corto, carrera, ápice, rechazo, llegada y recorrido inverso con Player real. El hueco100 entre Shared es el enlace más ajustado desde reposo; proponer reducirlo si B lo considera necesario, no mover automáticamente nada.

## 9. Atlas corporales y efectos

[Contacto de todas las poses](../assets/sprites/jefe/derived/boss_animation_contact_sheet.png). Archivos en `assets/sprites/jefe/derived/atlases/`. Las entradas del inventario y los63 rects del manifiesto son la fuente de corte. No usar el viejo frame_candidates.json uniforme.

| Atlas | Poses/celdas | Acción real | Aptitud / reserva |
|---|---|---|---|
| starting_atlas |8 | Incorporación | Último cañón truncado en fuente, no reparado |
| repose_atlas |4 | Reposo/pulso | Registro estable de suelo; anatomía más alta que otras hojas |
| attack3_atlas |6 | Carga/disparo/recoil del cañón | Descarga blanca en poses2–3 base0; sin bala independiente |
| vulnerable_atlas |6 | Bajada a rodilla y variaciones de núcleo/visor | No es6 veces la misma pose; iluminación del núcleo intermitente |
| retorn_atlas |4 | Aire→aterrizaje→incorporación | Mantiene desnivel dibujado; no inferir patrulla |
| exit_atlas |4 | Impulso/despegue | Mantiene elevación; no animación de retirada lateral probada |
| retorn_repose_atlas |1 | Pose aérea | Su empalme requiere revisión; no secuencia autónoma |
| exit_repose_atlas |1 | Pose aérea | Mismo límite |
| defeated_atlas |7 | Rodilla, explosión, humo, partículas | Última zona residual de fuente con alfa≤1 no inventa frame8 |
| beam_start_atlas |6 | Crecimiento del haz | No preparación corporal; ejeY361 fuente; recorte vertical265..457 |
| beam_hold_atlas |1 | Segmento de haz | Píxel idéntico al primer frame de finish; efecto, no bala demostrada |
| beam_finish_atlas |6 (5 visibles+vacía) | Disipación | Mantiene último frame transparente intencional |
| hud_health_atlas |4 |3/2/1/0 segmentos | Son estados de valor, no tiempos |
| hud_defeated_atlas |5 | Fractura/dispersión | Corrección frente al conteo anterior de4 |

Los atlas normalizados de cuerpo usan640×800 por celda y ancla(320,720). Para futura composición: centered=false con offset(−320,−720), o centered=true con offset(0,−320), escala general candidata por mundo; AtlasTexture por celda. No se escribió `.tres`, no se configuró AnimationPlayer ni SpriteFrames. Cada atlas tiene escala uniforme propia previa al empaquetado, documentada; no cambiar escala del nodo físico para seguir a los sprites.

Los recortes corporales se separan en intervalos irregulares libres de los componentes principales vecinos. Limpieza: envolvente geométrica de8px alrededor de masaA≥128, preservando RGB y alfa dentro; solo residuos externos de alfa menor128 se retiran. No es un borrado de negro: las sombras negras importantes se conservan. Los efectos y piezas recortadas no reconstruyen contenido oculto/truncado. Si se requiere conservación absoluta de halos débiles, volver a los PNG originales y revisar esa envolvente: no afirmar que todo píxel débil es error del artista.

## 10. Anclajes, tamaño y continuidad

[Referencia por poses](../assets/sprites/jefe/derived/boss_anchor_reference.png) y [superposición](../assets/sprites/jefe/derived/boss_anchor_overlay.png). Suelo de referencia fijo por secuencia; eje horizontal estimado por soporte inferior, sin pegar cada pose aérea al piso. Posiciones de núcleo/cañón por frame en manifiesto, con estado `visual center estimate`, especialmente las poses oscuras. Ninguno se convirtió en hurtbox ni evento de emisión.

La altura total no es un calibrador anatómico válido: repose tiene masa principal518px de alto y core49×48; attack3 tiene339px y core48×46. Igualar alturas agrandaría núcleo/cañón durante el ataque. Se usó referencia48px del núcleo luminoso inicial de cada hoja, factor constante por secuencia, conservando pulsos y agachado. Starting/defeated usan la postura de incorporación de referencia porque en el inicio/colapso el núcleo no siempre brilla.

**Reserva:** aun normalizando el núcleo, el chasis/piernas siguen teniendo proporciones distintas de origen. No se puede garantizar a la vez igual torso, cabeza, piernas y núcleo con un único factor uniforme. Se mantuvo el diseño fuente; no se retocaron miembros ni generaron interpolaciones. El cambio starting→repose y repose→attack3 requiere revisión artística antes de F. Los offsets de poses aéreas aisladas siguen siendo candidatos. No declarar continuidad perfecta ni root motion definitivo por esta lámina.

## 11. Tres escalas frente al Player real

[Comparación de escalas](../assets/sprites/jefe/derived/boss_scale_comparison.png). Player idle0: región130×226 a0,33, visible≈42,9×74,58px, distinta de su collider24×40. Se conserva el offset vertical visible respecto de pies/collider según el AtlasTexture y AnimatedSprite actuales. Las tres vistas usan la cámara **actual1,14**, ventana1024×572, centro candidato(830,440) dentro del mundo, y referencias del salto90/collider/núcleo. Son montajes raster, no viewport ejecutado. La cámara del proyecto no cambió.

| Candidata | Factor sobre repose normalizado | Alto corporal real | Alto en pantalla a1,14 | Relación visible frente a Player |
|---|---|---|---|---|
| Compacta |0,30 |155,4px |177,16px |2,08× |
| Intermedia |0,375 |194,25px |221,45px |2,60× |
| Imponente |0,45 |233,1px |265,73px |3,13× |

Recomendación provisional: **intermedia**, porque conserva presencia y lectura, deja más aire que imponente y no exige tanto alcance vertical al núcleo. En vulnerable, el núcleo se desplaza al bajar: en esa escala su primer estado luminoso queda≈109px sobre pies, y la rodilla pose2≈57px sobre pies. La espada en suelo está centrada24px por encima de pies y el Player puede saltar: la rodilla parece accesible analíticamente, pero no se ha probado una ventana real de contacto. Los círculos de escala muestran ambos lugares estimados, sin dibujar una hurtbox ficticia. No se aprueba todavía tamaño, salud, posición o alcance de daño.

La vista actual cubre≈898×502 unidades a1024×572, no1280×720: desde el combate derecho no ve el vestíbulo completo. B deberá decidir entre zoom local distinto o encuadre fijo reutilizando Camera2D. No se aplicó el zoom0,78 propuesto antes ni se agregó una cámara.

## 12. Disponibilidad de ataques

| Ataque/acción | Recursos y secuencia | Completitud visual | Posibles eventos y advertencias | Dependencia / riesgo |
|---|---|---|---|---|
| Haz A1 |beam_start6 → hold1 → finish6 | Efecto crecimiento/sostén/disipación disponible; preparación corporal exclusiva ausente | Start fino puede avisar; emisión dañina solo tras aviso aprobado, sin frame/tiempo definitivo | Grosor start final≈150px frente hold32: requieren factor uniforme/tiling compatibles, no conectar a escala1 sin revisar. Muzzle y alcance por decidir |
| Disparo de cañón de attacking3 |6 poses, descarga blanca en índices2–3 y recoil | Cuerpo completo; proyectil/impacto independiente no identificado | Índices2/3 son candidatos de emisión futura; índices0/1 posibles lectura de carga | No duplicar emisión en ambos por accidente; elegir evento tras revisión. No se inventó bala ni ataque2 |
| Exit/retorn |4+pose aérea / pose aérea+4 | Despegue y regreso visibles | Útiles para presentación/desplazamiento propuesto, no ataque por nombre | No hay trayectoria, destino ni daño de aterrizaje aprobado |
| Vulnerabilidad/derrota |6 /7 | Cuerpo y efectos disponibles con reservas de registro | Estados de presentación, no ofensiva | Brillo del núcleo no es por sí solo regla de daño |

No se fijaron FPS de combate, daño, vida ni duración de estados. Los14 atlas no son14 ataques. No se identificó ataque2; no se buscaron mecánicas para rellenar numeración. Los recursos del haz se combinan como efectos independientes del cuerpo de reposo; aún no hay animación de preparación corporal exclusiva.

## 13. Vulnerabilidad, retorno y recuperación

Canon conservado: GDD RF-05 permite daño solo en **Presente y con núcleo expuesto**. Vulnerable0/1 bajan,2/3/4/5 sostienen rodilla con variaciones; la luz se apaga en varias poses y reaparece en otras. La fuente representa una avería, pero no explica cuándo la lógica abre/cierra el punto débil. No convertir cada parpadeo en una ventana arbitraria; diseñar feedback legible en la fase jugable.

`retorn` empieza en el aire, aterriza y se incorpora; `exit` impulsa y despega. Se conservaron en orden visual. No se invirtió vulnerable para fabricar una recuperación inexistente, ni se afirmó que retorn fuese levantarse desde esa rodilla exacta. Hay poses para una transición de presentación propuesta, pero la continuidad anatómica y el empalme de postura deben aceptarse/revisarse. Núcleo/cañón se mueven al cambiar postura: futuras áreas deben seguir anclajes elegidos, no rectángulo completo de la imagen.

## 14. Barra de vida

[Comparativa](../assets/sprites/jefe/derived/boss_hud_comparison.png). Fuente normal1247×1261:4 estados verticales,3 segmentos. Fuente derrota1182×1330:5 estados de fisura, fractura, paneles separados, dispersión, partículas. El conteo anterior de4 omitía la quinta fila pequeña, con partículas de alfa fuerte hastaY1065. No se inventó cuadro final vacío.

Atlas UI de320×128/celda; carcasa útil normal de≈280×63px, factor280/1103. Derrota escala280/1041 para compensar distinto tamaño del marco de origen; partículas conservan dispersión dentro de celda. Centro(160,64), estado de salud independiente de la animación de destrucción. Recomendación de futura UI: inferior derecha según GDD, margen16–24px, reservar espacio con salud/Lente/diálogos y probar1024×572/1280×720. Se midió/revisó visualmente la lámina; no existe BossHUD implementado. **La barra no decide12HP**: cantidad de salud y mapeo de segmentos se aprueban después.

## 15. Prototipos entregados

Todos rotulados como diagnósticos/propuestas y con igual lienzo1672×941; no son renders de juego.

| Prototipo | Archivo | Contenido |
|---|---|---|
| A |[Presente](../assets/tiles/sala%205/derived/room5_present_preview.png) | Fondo rojo+contorno, sólidos Presente y fantasmas Pasado, distribución original reconstruida |
| B |[Pasado azul](../assets/tiles/sala%205/derived/room5_past_preview.png) | Misma geometría, gradación azul candidata, sólidos Pasado y fantasmas Presente |
| B fuente |[Pasado ámbar original](../assets/tiles/sala%205/derived/room5_past_source_preview.png) | Permite aprobar color sin confundir original con derivado |
| C |[Presente con actores](../assets/tiles/sala%205/derived/room5_present_scale_preview.png) | Player real y jefe intermedio propuesto, distribución candidata |
| D |[Pasado con actores](../assets/tiles/sala%205/derived/room5_past_scale_preview.png) | Mismos actores/posiciones, Pasado azul candidato |
| E |[Superficies candidatas](../assets/tiles/sala%205/derived/room5_platforms_reference.png) |4 Shared propuestos,1 Presente,1 Pasado; reutilización sin shapes |

Las composiciones incluyen capas modulares en origen común. Los prototipos reconstruidos no son texturas finales para meter completas en una escena: mezclarían visuales de dimensión/Shared en un solo PNG de revisión. En implementación futura se usarán capas/atlas separados, sin collider del PNG.

## 16. Decisiones pendientes para B y posteriores

1. Color Pasado: conservar ámbar/cian o aprobar gradación azul candidata. No cambiar el GDD ni originales automáticamente.
2. Distribución: original no escalable con salto actual; decidir variante con Shared segmentados frente a suelo continuo del plan. La variante nueva necesita política de caída y revisar hueco100.
3. Aspecto Shared: diferenciarlo del metal exclusivo Pasado antes de asignar físicas. No basta colorear etiqueta en un prototipo.
4. Tamaño del jefe: elegir compacta/intermedia/imponente tras ver comparativa; recomendación intermedia provisional.
5. Continuidad artística: aceptar diferencias heredadas de chasis o solicitar al autor hojas coherentes y último cañón completo; no generar correcciones sin autorización.
6. Aprobar método de limpieza alfa de cuerpos si se exige conservación exacta de halos débiles; los originales y rects permiten rehacerlo.
7. Anclajes: revisar ejes/centros candidatos de núcleo y cañón antes de F; poses aéreas no definen todavía trayectoria.
8. Cámara: el zoom actual no encuadra toda la arena; cerrar opción local en B sin tocar Player/cámara existente durante A.
9. Haz/A3: grosor y combinación de efectos por aprobar; ausencia de proyectil A3/ataque2 continúa vigente. No asignar daño/tiempos aquí.
10. Salud, etapas, guardado y Llave del Reactor siguen sin decidir dentro de A. El GDD exige esa llave antes del acceso; resolverla antes de E.

## 17. Validaciones y límites

- Originales:28/28 SHA-256 conservados. Manifiesto fuente completo en JSON y respaldoZIP.
- Atlas de plataforma:4/4 fuentes RGBA exactamente conservadas, con traslaciones registradas; sin estirar ni borrar negro.
- Derivados:28 PNG abiertos/releídos, dimensiones y canal alfa comprobados. Cuerpo640×800 por celda; HUD320×128; efectos según inventario. La transparencia de la celda vacía final se conserva.
- Recortes: conteo por componentes principales y revisión de todas las poses en contacto. Las celdas derivadas no atraviesan componentes principales del vecino; normalización cabe dentro de canvas. Última pose starting ya truncada en el original y cola derrotado alfa≤1 documentadas.
- Limpieza de cuerpo:0 píxeles retirados con alfa≥128; esto protege masa visual y sombras, pero no prueba intención de todos los halos débiles. Revisión artística pendiente.
- Fondos: resolución, origen, escala y encuadre comunes; no hubo deformación. Pasado azul difiere solo en RGB del candidato, no geometría ni alfa. Los9 apoyos de referencia conservan su clasificación por dimensión; no se declararon Shared originales.
- Anclajes: láminas de origen común, vuelo/crouch conservados y landmarks registrados. Se detectaron las discrepancias de proporción; no se escondieron igualando alturas.
- Conservación del juego:944 archivos iniciales relevantes cotejados, solo inventario modificado con autorización; diagramas y juego intactos. La lista exacta de cambios y hashes está en validación. No existe Room5.tscn ni entidad funcional nueva del jefe.
- MCP final confirmó Room4, misma escena1654334234622 y revisión10063650:0:1, detenida y sin cambios de escena pendientes (`unsaved=false`). No se salvaron recursos del editor ni se limpiaron marcas externas.
- No se ejecutó Godot validate: no cambió GDScript ni se escribió script jugable. Ninguna animación se declaró funcionando en Godot; ningún salto se declaró probado. No se usaron guardados o memorias.

## 18. Estado de cierre

**Inventario y derivados disponibles para revisión; continuidad de animaciones parcialmente resuelta por límites de la fuente.** Las28 imágenes fuente se conservan. La fase no puede certificar un jefe que cambie sin alteraciones anatómicas entre todas las hojas ni completar los20 píxeles de cañón que tocan el borde fuente sin intervención artística. Todo lo demás que podía prepararse de forma no destructiva queda entregado con trazabilidad y reservas explícitas.

Detención tras A. No se inicia B ni se aplican posiciones, escalas, físicas, IA o ataques hasta recibir la autorización correspondiente.
