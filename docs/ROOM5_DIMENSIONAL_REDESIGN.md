# Sala5 — plataformas dimensionales

16/11/2026. Godot4.7.2. Referencias: `assets/tiles/sala 5/plataformas mapa 5.png` y `pasado plataformas.png`.

Se conserva la composición de tres columnas y tres niveles: Presente sólido arriba/abajo, Pasado sólido en medio y representaciones fantasma sin colisión en la dimensión opuesta. Se reutilizan los atlas y fondos existentes. No se usan las referencias completas como fondo con plataformas falsas.

Las referencias no se copian píxel por píxel: sus separaciones verticales, a escala de la sala, superan el salto real. Se comprimen los niveles a pasos de70px y se ajustan anchuras para hacerlos transitables con Player original. La cámara, fondo, contornos y contrato de llegada se conservan. Se elimina F0 y sus siete piezas, sin otro suelo continuo.

## Coordenadas reales

Centro X, superficie superior Y, anchura en unidades del mundo. Todas las formas tienen8px de grosor, centro del cuerpo en Y+4 y colisión unidireccional. Player mide24×40; su centro apoyado está20px por encima de la superficie.

| ID | Dimensión | X | Y superior | Ancho |
|---|---|---:|---:|---:|
|Entry |Compartida |155 |620 |150 |
|P1 |Presente |300 |620 |160 |
|P2 |Presente |640 |620 |160 |
|P3 |Presente |980 |620 |160 |
|P4 |Presente |300 |480 |220 |
|P5 |Presente |640 |480 |220 |
|P6 |Presente |980 |480 |220 |
|T1 |Pasado |300 |550 |220 |
|T2 |Pasado |640 |550 |220 |
|T3 |Pasado |980 |550 |220 |
|Boss |Compartida |1140 |620 |160 |
|Strike |Compartida |1095 |590 |70 |

El Guardián y su marcador lateral pasan de(1070,620) a **(1140,620)**. Strike es el apoyo junto al núcleo; permite atacar sin tener que completar un salto por golpe. No se modifica ninguna coordenada local del núcleo, hitbox ni pose. Spawn(140,600), llegada desdeRoom4(180,600), salida(100,600) y EncounterTrigger(420,360),20×520, conservan sus posiciones.

DimensionManager recibe seis formas exclusivas de Presente y tres de Pasado; las compartidas no se alternan. Las imágenes fantasma no tienen cuerpos sólidos propios. No hay plataformas exclusivas activas simultáneamente en ambas dimensiones.

## Movimiento y ruta probada

Se usa Player real: velocidad240, aceleración/frenada originales, salto de aproximadamente90px, gravedad y caída originales, cooldown Shift0,20s, protección0,16s y rechazo de destino ocupado. No se ajusta Player ni DimensionManager.

Ruta principal, con movimiento/salto/Shift reales:

`Entry → P1 → T1 → P4 → T2 → P5 → T3 → P6 → Strike`

Los ascensos son70px. Se cambia de dimensión cerca del ápice, aproximadamente al paso15 del salto. Un intento inicial al paso7 fue rechazado porque el cuerpo todavía ocupaba la superficie de destino: se conservó esa restricción y se corrigió el momento de la entrada de prueba. Los saltos diagonales entre columnas empiezan con carrera cerca del borde; no se intentan saltos imposibles entre centros separados340px.

El regreso físico probado es `Strike → T3 → P3 → T3 → T2 → P2 → T2 → T1 → P1 → Entry`. En T3/T2 se desactiva el apoyo de Pasado mediante Shift y se cae sobre P3/P2. De esta manera se alcanzan todas las plataformas. El recorrido de ida y vuelta termina con contador de recuperación0: no se utilizaron reposicionamientos para completarlo.

Entre los apoyos inferiores exclusivos hay huecos180px; la fila superior exige ascender140px desde abajo. El camino práctico requiere usar los apoyos intermedios de Pasado; se elimina el acceso andando por F0. La entrada y el lado del jefe son las únicas zonas compartidas amplias.

## Caída y combate

Room5 añade recuperación local al superar los pies Y690, siguiendo el patrón de Room4: regresa al Spawn compartido, anula velocidad y restaura Presente sin cambiar salud ni progreso del jefe. No crea un suelo invisible. Una caída preparada se prueba por separado, también después de activar Pasado. Esta recuperación es explícita; no se cuenta como desplazamiento válido de las rutas.

En Strike, el centro real del Player queda aproximadamente(1118,570), y el núcleo vulnerable del jefe en(1151,566). Tres ataques reales del Player producen **6→5→4→3** en96 pasos físicos,1,6s, dentro de una ventana de2s.

Es una **prueba controlada de la ventana existente**, no una partida completa ni una validación de la futura IA: se deja terminar la apertura original y se prepara el estado vulnerable con su temporizador real de2s. No se cambia el controlador ni los tiempos de producción. La entrada a Strike sí procede de la ruta física continua.

La IA, ataques, salud6, umbral3, espada de1HP y persistencia permanecen sin cambios. No se implementan ofensiva60s, salida de pantalla, barridas, ráfagas verticales ni otro proyectil. El diseño admite esos desarrollos futuros, pero no los presenta como entregados.

## Rutas de evasión futuras

Los centros de apoyo del Player en las tres filas son460,530 y600; la separación70 deja niveles alternativos para una barrida horizontal de referencia de24px con cuerpo de40px. Las columnas300/640/980 ofrecen posiciones laterales distintas para abandonar una línea vertical. Las rutas con cambio de nivel y columna se prueban con el Player, no mediante teletransportación.

Esto es una comprobación geométrica, **no una garantía de evasión de patrones todavía indefinidos**. Anchura, dirección, seguimiento, simultaneidad, avisos y tiempos de los futuros láseres siguen pendientes. Deben probarse cuando se implementen; el aviso deberá permitir la carrera/salto/Shift necesarios. No se afirma que una combinación arbitraria de barridas sea evadible ni que exista una ofensiva real de60s validada.

## Pruebas y capturas

`tests/room5_dimensional_layout_test.gd`: PASS sin fallos en la ejecución final headless. Comprueba entrada segura, todas las plataformas, cambios durante saltos, regreso sin recuperaciones, tres golpes en2s, rechazo por ocupación, recuperación desde Pasado, salud, puertas reales Room5→Room4→Room5, llegada segura, cruce físico del trigger, introducción/ciclo único, BossHUD, bloqueo y recarga heredada tras derrota.

El recorrido geométrico utiliza modalidad manual de diagnóstico para evitar interferencia ofensiva. Después se habilita la activación de producción en la instancia de integración y se cruza el área físicamente. La derrota de esa comprobación se provoca mediante una entrada controlada de daño del Player: prueba el flujo de reintento y no se presenta como daño natural del Guardián. La nueva instancia reaparece segura con Player3 y jefe6. Los fixtures de ocupación, caída y derrota están separados de la ruta física.

Render1280×720: recorrido geométrico PASS y capturas reales revisadas. La validación general `tests/validate.gd` pasa después de los cambios. Los antiguos tests que fijan F0/R1/R2 y sus coordenadas describen el diseño anterior; no se ejecutan ni se declaran aprobados para esta nueva geometría. La regresión específica nueva cubre los contratos afectados, sin borrar las pruebas históricas.

- [Presente](../artifacts/room5_dimensional_redesign/presente.png)
- [Pasado](../artifacts/room5_dimensional_redesign/pasado.png)
- [Apoyo del núcleo](../artifacts/room5_dimensional_redesign/plataforma_jefe.png)
- [Ruta medida](../artifacts/room5_dimensional_redesign/route.json)
- [Log final](../artifacts/room5_dimensional_redesign/test.log)

Los perfiles usan APPDATA aislado bajo `C:/Users/juans/.codex/visualizations/2026/11/16/01a1e570-850c-7a83-8965-7511f3d3ed84/layout_work`. No se utilizan los guardados reales. El primer render se realizó antes de añadir las comprobaciones posteriores de puertas/reintento; estas últimas constan en el log final headless. No se afirma haber completado un combate integral con los ataques actuales sobre este nuevo layout.

## Archivos y respaldo

Modificados solamente `scenes/Room5.tscn` y `scripts/rooms/room5.gd`. Nuevos: prueba específica, este informe y evidencias. El controlador del Guardián, sus ataques/recursos, HUDs, Player, DimensionManager, GameProgress y Room4 no se editan.

Respaldo previo: `C:/Users/juans/chrono-shift-backups/room5_dimensional_20261116_212024/`, con ambos archivos originales y hashes.json. Los recursos gráficos originales se conservan. MCP recarga la escena guardada sin cambios manuales pendientes; no se modifican configuración ni servicios.
