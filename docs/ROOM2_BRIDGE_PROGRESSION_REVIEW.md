# Sala 2: puente y acceso futuro (11 de noviembre de 2026)

## Puente

La colisión del suelo izquierdo, `CentralBridge/Deck` y suelo derecho mantiene la superficie en Y=580. En una prueba real de Godot, el Player quieto en X=530 quedó en (530, 559.9807), con velocidad cero y `is_on_floor() == true`; su collider de 24 × 40 termina en Y≈580. No se detectó flotación física.

La composición de 1672 × 941 sitúa la coronación de la barandilla cerca de Y=548. El Player se dibuja delante de ella y sus botas aparecen sobre los huecos. Se generó un prototipo no destructivo con los píxeles cálidos de los balaustres y la moldura inferior (X=355–714, Y=568–610), conservando transparentes los huecos magenta. El prototipo y los renders A/B obtenidos en Godot están en `C:/Users/juans/AppData/Local/GodotMCPCodex/tests/room2_bridge_20261111/`.

El prototipo no tapa la cabeza ni el torso, pero tampoco corrige el centro del puente: allí no hay barandilla sólida detrás de las botas que se pueda traer al primer plano. Se comprobó quietud en X=390, carrera de X=390 a X=454 (velocidad 240) y salto hacia X≈498; la máscara no altera el movimiento, pero el hueco visual persiste durante la carrera. Una máscara que incluya la coronación alta oculta el torso; una que incluya el fondo introduce rectángulos ajenos al puente. Por ello se descarta su integración. El PNG original, la escena y las colisiones quedan intactos. La corrección visual requerirá diseñar una superficie de paso visible en Y≈580 o recomponer localmente el puente conservando su escala y el contacto físico.

## Continuación hacia Sala 3

El GDD v1.2 sitúa los accesos elevados de Sala 2 tras plataformas del Pasado y la obtención de la Lente Temporal en Sala 3. Por tanto, la ruta previa a Sala 3 debe evitar esas plataformas. El GDD no especifica una puerta ni coordenadas para esa conexión; el acceso inferior es compatible con la secuencia, pero su ubicación es una propuesta de diseño, no un dato confirmado.

El candidato es `EntryMarkers/FutureRoom3Access` (Marker2D) en (1500, 620), cerca del tramo inferior derecho: el suelo interpolado allí está en Y≈640, deja al Player de 40 px apoyado con centro Y≈620 y se encuentra antes del muro X=1550. Queda por debajo de `RightShelf` (Y=454) y no requiere la Lente. Antes de colocarlo hay que aprobar la dirección de salida y el punto de entrada de Sala 3. Después se podría añadir una `Area2D` separada bajo `RoomTransitions`, con `LevelTransition.gd`, destino y marcador de llegada propios. No se creó ese nodo ni se activó ninguna transición.

La escena guardada ya no contiene los límites locales de cámara 1672 × 941 documentados en la Etapa D. Los renders comparativos del puente usaron esos límites solo en la instancia temporal para mostrarlo completo. Este cambio previo de la escena requiere una revisión separada; no se modificó la cámara en esta tarea.
