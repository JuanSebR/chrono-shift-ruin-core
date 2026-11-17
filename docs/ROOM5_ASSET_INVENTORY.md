# Sala 5 — Inventario de recursos, Fase A

16 de noviembre de 2026. **Fase A autorizada: inventario medido, atlas derivados y prototipos para revisión.** Los 28 PNG originales permanecen intactos. Se prepararon 14 atlas del jefe/efectos/UI (63 celdas, una vacía intencional), un atlas de las cuatro plataformas transparentes y comparaciones visuales. No se crearon SpriteFrames, escenas ni lógica. Los anclajes son propuestas medibles; las diferencias anatómicas del arte y un cañón truncado de origen impiden certificar todavía transiciones perfectas. Informe: [ROOM5_STAGE_A.md](ROOM5_STAGE_A.md).

## Método y evidencia

Pillow13 y NumPy ya instalados: formato/resolución/modo, histograma alfa, componentes de masa visual y SHA-256. Las tablas de resolución/alfa originales siguientes siguen vigentes. `room5_diagnostics/frame_candidates.json` conserva el diagnóstico HISTÓRICO de celdas uniformes: **no utilizarlo para cortar**. El manifiesto actual `assets/sprites/jefe/derived/room5_stage_a_manifest.json` lo sustituye para recortes: límites irregulares verificados con componentes y revisión visual, anclajes por pose, factores uniformes por hoja y centros estimados de núcleo/cañón. Rects fuente usan [izquierda,arriba,derecha,abajo) y rects de atlas [x,y,ancho,alto].

Contactos: [arena](room5_diagnostics/arena_contact.png), [jefe](room5_diagnostics/boss_contact.png). Métricas: [JSON](room5_diagnostics/asset_metrics.json), [candidatos de recorte](room5_diagnostics/frame_candidates.json).

## Escenario —13 PNG, nombres exactos

Todos los nombres de la lista del pedido con sufijos `(1)`/`(2)` difieren del disco: aquí figuran sin esos sufijos. Escala de referencia para todas las composiciones:1 px de imagen; mapa candidato en MASTER_PLAN transforma fondos uniformemente a1280/1672. Los sprites512×256 son piezas independientes, no están ya colocados en el mismo espacio de mundo.

| Archivo | Resolución / formato | Alfa / regiones transparentes | Dimensión / tipo | Superficies o decoración / composición | Derivado propuesto |
|---|---|---|---|---|---|
| `contorno s5.png` | 1672×941 PNG | RGBA; A=[0, 255]; 80.53% A=0; 19.4% parcial; bbox=[0, 0, 1672, 941] | Presente; Marco decorativo | Composición 1672×941; no hay suelo inferior completo | Candidato sobre fondo; revisar alfa residual |
| `contornoPast correcion s5.png` | 1672×941 PNG | RGBA; A=[0, 255]; 79.15% A=0; 20.8% parcial; bbox=[0, 0, 1672, 941] | Pasado; Marco decorativo | Composición 1672×941; adornos de pared no son apoyos | Candidato sobre fondo; revisar alfa residual |
| `diseño s5.png` | 1672×941 PNG | RGB sin canal alfa; 0% transparente, lienzo íntegro opaco | Presente; Referencia compuesta fondo+marco | No representa un mapa físico con plataformas | No apilar con fondo+contorno; referencia |
| `fondo s5.png` | 1672×941 PNG | RGB sin canal alfa; 0% transparente, lienzo íntegro opaco | Presente; Fondo completo | Engranajes/tuberías decorativos; sin superficies jugables | No requiere quitar fondo negro: es fondo real |
| `fondoPast s5.png` | 1672×941 PNG | RGB sin canal alfa; 0% transparente, lienzo íntegro opaco | Pasado; Fondo completo | Reactor/tuberías/engranajes decorativos | Conservar como fondo, no hacer collider de su arte |
| `plataforma_pasado.png` | 512×256 PNG | RGBA; A=[0, 255]; 73.95% A=0; 1.96% parcial; bbox=[48, 73, 464, 183] | Pasado; Plataforma individual sólida | BBox alfa (48,73)-(464,183); cara central superior≈Y73–85 | Sí: registrar cara/pivote; fuente preferida para recomposición |
| `plataforma_pasado_translucida.png` | 512×256 PNG | RGBA; A=[0, 255]; 50.72% A=0; 49.28% parcial; bbox=[37, 49, 475, 206] | Pasado inactivo; Plataforma individual fantasma | Halo bbox (37,49)-(475,206); cara física se toma de sólido | Sí: mismo anclaje que sólido, no alinear por halo |
| `plataforma_presente.png` | 512×256 PNG | RGBA; A=[0, 255]; 71.57% A=0; 2.94% parcial; bbox=[22, 67, 490, 189] | Presente; Plataforma individual sólida | BBox alfa (22,67)-(490,189); cara central superior≈Y67–78 | Sí: registrar cara/pivote, conservar negro interior |
| `plataforma_presente_translucida.png` | 512×256 PNG | RGBA; A=[0, 254]; 50.2% A=0; 49.8% parcial; bbox=[15, 46, 497, 209] | Presente inactivo; Plataforma individual fantasma | Halo bbox (15,46)-(497,209); cara física se toma de sólido | Sí: mismo anclaje que sólido, no colisión |
| `plataformasPast.png` | 1672×941 PNG | RGB sin canal alfa; 0% transparente, lienzo íntegro opaco | Pasado; Montaje de tres plataformas | Fila Y420–525; X62–475,629–1043,1196–1610 | Sí: RGB negro opaco; preferir individuales en lugar de recorte por negro |
| `plataformasPastTransLucid.png` | 1672×941 PNG | RGBA; A=[0, 255]; 77.29% A=0; 22.71% parcial; bbox=[0, 3, 1672, 941] | Pasado inactivo; Montaje de tres fantasmas | Mismas zonas generales que Past, halo y residuos ocupan más lienzo | Sí: alfa no implica ausencia de píxeles residuales; registrar sólido-fantasma |
| `plataformasPresent.png` | 1671×941 PNG | RGB sin canal alfa; 0% transparente, lienzo íntegro opaco | Presente; Montaje de seis plataformas | Dos filas: Y144–268 / Y683–793; X46–506,611–1061,1166–1627 aprox. | Sí: RGB opaco; fuente mide1671 de ancho, no estirar para igualar |
| `plataformasPresentTransLucid.png` | 1672×941 PNG | RGBA; A=[0, 254]; 70.24% A=0; 29.76% parcial; bbox=[0, 0, 1672, 941] | Presente inactivo; Montaje de seis fantasmas | Dos filas; extremos alfa incluyen ruido; no cara física | Sí: revisar offset frente a sólido1671 y usar individuales |

Los valores Y de montajes son extremos de regiones luminosas (`RGB>50`, mínimo50px de ancho), **no caras definitivas de apoyo**. Hay que trazar el labio superior de metal dentro de cada región y cotejar las variantes con landmarks, no por tamaño de lienzo. Los bbox de piezas individuales tampoco sustituyen cara superior ni collider. Fondos/contornos no tienen superficies físicas asignadas: N/A, no coordenadas inventadas. Shared es una decisión nueva de diseño visual/físico, no un atributo deducible del PNG.

### Alfa y composición

`plataformasPast.png` tiene93,60% de píxeles visibles casi negros; Present86,44%. Son hojas RGB que taparían el fondo. Los PNG RGBA también contienen abundantes valores alfa intermedios y algunos residuos lejos del cuerpo; un lienzo con canal alfa no es automáticamente un atlas limpio. La eliminación global de negro mutilaría contornos/sombras. Preferencia: individuales limpios, originales intactos, comparaciones registradas en A.

Presente: fondo → contorno correspondiente → ghosts de Pasado → sólidos Presente (Shared aparte). Pasado: fondoPast → contornoPast corregido → ghosts de Presente → sólidos Pasado (Shared aparte). Ajustar contorno adelante/atrás solo si no tapa personaje/avisos. No usar diseño s5 más el mismo marco duplicado. Diferencia1671/1672 requiere comparar anclajes; no hay evidencia suficiente para asegurar pixel-perfect alignment entre todos los montajes. El pasado suministrado es industrial ámbar/cian, no azul puro de Room4; conservar arte aprobado y validar claridad con etiquetas.

## Guardián —15 PNG

Escala de referencia: píxeles originales, **no** tamaño final de mundo. Todos son PNG RGBA con transparencia real; la tabla registra bbox de todo el material y porcentaje de vacío. Dimensión de arte: jefe común a ambas; el escudo de Pasado/punto débil de Presente es regla GDD y aún no tiene hojas específicas identificadas. Todos requieren registro/recorte no destructivo en A; no son elementos de escenario ni colliders.

| Nombre exacto | Resolución | Alfa (mín–máx); vacío/parcial | Bbox contenido A>0 |
|---|---|---|---|
| `attacking 1 haz GuardianNucleo.png` | 64×64 | [0, 255]; 50.0% / 0.0% | [0, 16, 64, 48] |
| `attacking 3 GuardianNucleo.png` | 2172×724 | [0, 255]; 70.86% / 29.03% | [22, 37, 2144, 690] |
| `barra de vida GuardianNucleo.png` | 1247×1261 | [0, 255]; 41.22% / 58.57% | [0, 4, 1233, 1261] |
| `defeated barraDeVida GuardianNucleo.png` | 1182×1330 | [0, 255]; 59.56% / 40.38% | [0, 37, 1172, 1304] |
| `defeated GuardianNucleo.png` | 2172×724 | [0, 255]; 82.17% / 17.79% | [0, 51, 2104, 700] |
| `Diseño GuardianDelNucleo.png` | 1262×1246 | [0, 255]; 48.35% / 51.49% | [0, 21, 1235, 1246] |
| `exit GuardianNucleo.png` | 2172×724 | [0, 255]; 63.24% / 36.7% | [0, 15, 2172, 724] |
| `exit Repose GuardianNucleo.png` | 493×619 | [0, 254]; 59.18% / 40.82% | [8, 8, 493, 611] |
| `finishing atack 1 GuardianNucleo.png` | 384×64 | [0, 255]; 83.33% / 0.0% | [0, 16, 320, 48] |
| `repose GuadianNucleo.png` | 2172×724 | [0, 255]; 56.27% / 43.56% | [18, 25, 2171, 700] |
| `retorn GuardianNucleo.png` | 2172×724 | [0, 255]; 60.36% / 39.51% | [36, 8, 2172, 700] |
| `retorn Repose GuardianNucleo.png` | 478×561 | [0, 255]; 53.48% / 46.52% | [0, 0, 478, 561] |
| `starting atack 1 GuardianNucleo.png` | 2172×724 | [0, 255]; 89.64% / 10.31% | [10, 51, 2172, 658] |
| `starting GuardianNucleo.png` | 2172×724 | [0, 255]; 72.79% / 27.15% | [0, 19, 2172, 646] |
| `vulnerable GuardianNucleo.png` | 2172×724 | [0, 255]; 70.95% / 29.0% | [14, 47, 2160, 698] |

### Animaciones: conteos confirmados y límites de uso

| Recurso | Contenido visible verificado | Celdas candidatas / separación y orden | Límite antes de producción |
|---|---|---|---|
| Diseño GuardianDelNucleo |1 ilustración de diseño |1262×1246; no secuencia | Recortar referencia, no usar lienzo completo como hurtbox |
| starting |8 poses de incorporación, izquierda→derecha | Cortes X:0,274,540,796,1073,1343,1607,1884,2172 | Última pose toca el borde derecho original:20 píxeles A≥128; cañón incompleto de origen. No reconstruido ni inventado |
| repose GuadianNucleo |4 poses de reposo | Cortes X:0,548,1092,1636,2172; base principal A≥128 enY616 para las4 | Masa cuerpo primera≈507×518; atlas registrado. Pulso del núcleo preservado, no duplicados exactos |
| starting atack1 |6 fases de expansión de haz horizontal |362×724 candidatas, orden fino→grueso, eje≈Y361 | No es cuerpo preparando ataque; bbox núcleo luminoso sube de8 a150px de grosor; residuos fuera del haz |
| attacking1 haz |1 segmento de haz blanco con bordes magenta |64×64, región visible [0,16,64,48) | Tile/efecto extensible, no bala autónoma demostrada; grosor visible32, collider menor |
| finishing atack1 |5 poses visibles de reducción +1 celda vacía |6×64×64; Y16–48,22–42,28–36,30–33,31–32, luego vacío | Última vacía verificada; frame0 coincide exactamente píxel a píxel RGBA con haz64; se puede compartir la textura, conservando funciones de animación distintas |
| attacking3 |6 poses de cañón; descarga visible central | Cortes X:0,367,711,1059,1410,1781,2172 | Atlas registrado; efecto/proyectil independiente ausente. Mantener crouch y recoil, no igualar altura a repose |
| vulnerable |6 poses;2 bajada y4 arrodilladas con variaciones de núcleo/visor | Cortes X:0,386,723,1080,1444,1803,2172; baseY554 | Variantes no idénticas. Núcleo luminoso en inicio y pose3; oscuro en otras: exposición jugable requiere feedback futuro |
| exit |4 poses de despegue | Cortes X:0,565,1104,1646,2172; referencia de sueloY650 | Movimiento vertical conservado: no reanclar cada pose por su pie más bajo |
| exit Repose |1 pose aérea aislada |493×619; referencia candidataY612; factor48/62 | Atlas aislado; empalme temporal con exit pendiente de aceptación visual |
| retorn |4 poses aéreo→aterrizaje→incorporación | Cortes X:0,537,1083,1620,2172; referencia de sueloY658 | Vuelo/aterrizaje conservados. No es evidencia de marcha o traslación lateral |
| retorn Repose |1 pose aérea aislada |478×561; referencia candidataY589; factor48/57,5 | Atlas aislado, no secuencia completa |
| defeated |7 poses significativas de colapso/explosión/residuos | Cortes X:0,288,554,823,1098,1378,1668,1900; referenciaY513 | CORRECCIÓN: colaX1900–2172 tiene alfa máximo1/255; no es un octavo cuadro certificado. Se conserva en original/respaldo |
| barra de vida |4 barras verticales:3,2,1,0 segmentos |1247×1261; filas irregulares, no grilla horizontal | Estados de salud, no vaciado por tiempo; alinear marco antes de recortar |
| defeated barraDeVida |5 estados: fisura, fractura, paneles separados, dispersión y partículas finales | Cortes Y:0,267,505,736,950,1100; cola inferior sin pose significativa | CORRECCIÓN de4 a5; atlas UI separado, anclado por centro de carcasa |

En los nuevos atlas las celdas uniformes son un **resultado del empaquetado**, no una suposición sobre el PNG original. Las9 hojas corporales usan celdas640×800 y ancla(320,720); beam_start384×192, beam_hold/finish64×64; HUD320×128. El orden izquierda→derecha/arriba→abajo se confirma por progresión visual, sin metadata original de FPS/eventos. No se fijaron tiempos de combate ni animaciones en Godot. Se conserva una celda vacía final en finishing: es parte comprobable de ese recurso. Revisión visual de todas las63 celdas en `boss_animation_contact_sheet.png`; no se eliminaron variantes corporales como si fueran repetidas.

### Ambigüedades y recursos ausentes

- No hay hoja llamada ataque2 detectada en assets mediante búsqueda de nombres; no diseñar un tercer ataque por numeración.
- No hay marcha del jefe identificada, ni escudo dedicado, ni transición de etapa, ni hurt separada, ni efecto de pulso independiente atribuido con certeza. Representación de escudo/aviso/etapa requiere aprobar UI/efecto local o limitar repertorio.
- No hay preparatoria corporal exclusiva del A1: usar reposo más aviso si se aprueba; no inventar poses.
- No hay tiempos/FPS ni archivo de animaciones del artista. Hace falta validar offsets entre hojas, anclaje de núcleo/cañón, espejo, orden de retoma y límites compartidos de recorte.
- Hojas grandes no implican tres o cuatro cuadros; aquí hay4,6 y8 poses candidatas y assets verticales de UI.
- Partículas y alfa residual invaden celdas: no prometer extracción sin pérdida en la fase de planificación.

## Escala y anclajes propuestos en Fase A

Comparación real: Player idle0 se obtiene del AtlasTexture existente, región(42,264,130,226), escala0,33 → visible42,9×74,58px; collider24×40. Candidatos de reposo del jefe:155,4px (factor0,30),194,25px (0,375),233,1px (0,45), proporciones visuales2,08/2,60/3,13 veces el alto del Player. Recomendación provisional intermedia; **ninguna escala aprobada**. Comparación con cámara actual zoom1,14 y viewport1024×572 en `boss_scale_comparison.png`; es raster diagnóstico, no captura de Godot. La vista no abarca el mundo entero: eso sigue siendo decisión de B.

CORRECCIÓN de método frente al plan: no multiplicar attack3 por0,6 para igualar sus339px de altura a repose. Núcleos luminosos de primera pose miden49×48 y48×46px respectivamente; la postura/proporción cambia, no toda la anatomía en una razón1,5. Atlas de comparación normaliza una referencia de núcleo48px por hoja, factor constante (no por frame): repose1; starting/defeated1,23077; attack3 1,02128; vulnerable1,11628; retorn0,77419; exit0,76190; retorn_repose0,83478; exit_repose0,77419. No se deformó ancho/alto por separado. Aun así, las proporciones de piernas/chasis varían en los originales; ningún escalado uniforme garantiza continuidad perfecta. Necesita revisión artística antes de F.

El manifiesto registra por frame rect fuente, rect atlas, ancla local, escala, bbox fuerte, estimaciones visuales de centro de núcleo/cañón y su transformación. No son hitboxes. Registro horizontal por apoyo inferior estimado; baseY fija por secuencia conserva crouch/vuelo. ReposeY616, starting527, attack3 532, vulnerable554, retorn658, exit650, defeated513. Isoladas aéreas: registro candidato, no contrato de root motion. Para HUD centro(160,64); para efectos eje central, sin causa de daño asignada.

## Derivados y reservas

Los14 atlas y comparaciones del jefe están en `assets/sprites/jefe/derived/`; composiciones y atlas de plataformas en `assets/tiles/sala 5/derived/`. Se retiraron residuos remotos de alfa débil mediante una envolvente geométrica de8px alrededor de la masaA≥128; se conservan RGB y alfa originales dentro de ella antes de escala nearest. No se hizo chroma-key del negro. Todas las muestras retiradas de hojas corporales tienen alfa<128; esto es limpieza documentada para revisión, no una afirmación de reconstrucción exacta de halos. Los4 individuales de plataforma están copiados al atlas sin cambiar ningún píxel RGBA, incluida transparencia. Last starting sigue incompleto de origen. La normalización es una propuesta reversible con originales intactos.

Fondos/contornos:1672×941 a escala1, origen0. Composición general `diseño s5.png` no es idéntica al bake fondo+contorno: MAE RGB4,7197/255, píxeles exactamente iguales0,0024%; son variantes artísticas, no capas redundantes garantizadas. No forzar coincidencia con deformación. Present sólido1671×941 se conserva como referencia; la recomposición usa individuales transparentes en posiciones medidas, no se estira a1672. Pasado azul es una gradación candidata separada; fuente ámbar/cian preservada. Ver informe A para fórmula, plano de superficies y limitaciones.

Estado: inventario y preparación diagnóstica terminados, aprobación visual pendiente. Las animaciones no se cargaron ni ejecutaron en Godot. Persisten reservas de origen/continuidad; no se certifica que todos los atlas estén listos para integrar sin revisión. Fase B no iniciada.

Conservación actual: respaldo previo en `C:/Users/juans/chrono-shift-backups/room5_stage_a_20261116/`, con ZIP de28 PNG, copia del inventario anterior y manifiesto SHA-256 de944 archivos existentes. Solo este inventario tiene modificación autorizada entre los archivos previos. Los3 diagramas, juego y PNG originales se cotejan al cierre en `room5_stage_a_validation.json`. No incluye caches del editor ni acredita todos los recursos externos en memoria.
