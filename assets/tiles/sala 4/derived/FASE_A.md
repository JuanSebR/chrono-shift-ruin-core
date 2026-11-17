# Sala 4 · Composición provisional

Los prototipos usan un lienzo común de 1280 × 720. Para cada punto del montaje de 640 × 360 se aplica (2x, 2y), con origen (0, 0) y nearest. Cada fondo se ajusta proporcionalmente por altura (720/941), con redondeo a píxeles enteros. El azul ocupa 1279 px y el rojo 1279 px. Se completa la última columna con el borde correspondiente. A escala nativa sobran aproximadamente 392 × 221 px frente al lienzo de referencia.

El Presente usa el fondo rojo y la arquitectura de `plataformas v2 s4.png`. Se eliminan del montaje únicamente las dos copias horneadas de los escalones rojos. El Pasado usa el fondo industrial azul y las tres superficies compartidas extraídas del montaje rojo, como representación provisional para conservar las caras de apoyo. La pasarela y el suelo industrial inferior del fondo azul requieren decisión visual antes de asignarles colisiones. Las parejas Solid/TransLucid se alternan sin aplicar una segunda opacidad. Dentro de cada pareja coinciden las dimensiones, el ancla y la máscara de píxeles con alfa distinto de cero. El máximo de alfa de los fantasmas es 204/255 en Presente y 198/255 en Pasado.

| Apoyo | Dimensión | X en 2× | Y | Ancho visible aproximado | Anterior → siguiente | Hueco al siguiente / subida |
|---|---|---:|---:|---:|---|---:|
| 1 Repisa izquierda | Ambas | 38–92 | 416 | 54 | Entrada → 2 | 86 / −12 |
| 2 Metálica izquierda | Presente | 178–298 | 428 | 120 | 1 → 3 | 114 / 24 |
| 3 Escalón izquierdo | Pasado | 412–506 | 404 | 94 | 2 → 4 | 68 / −58 |
| 4 Descanso | Ambas | 574–718 | 462 | 144 | 3 → 5 | 70 / 40 |
| 5 Metálica derecha | Presente | 788–872 | 422 | 84 | 4 → 6 | 82 / 78 |
| 6 Escalón derecho | Pasado | 954–1076 | 344 | 122 | 5 → 7 | 60 / 60 |
| 7 Repisa final | Ambas | 1136–1240 | 284 | 104 | 6 → salida | — |

Y crece hacia abajo. Subida negativa significa descenso. Las cotas describen el arte y todavía requieren verificar el ancho útil tras descontar biseles y márgenes de aterrizaje. La entrada candidata coloca el centro del collider en (64, 396). La llegada final candidata es (1188, 264). El esquema usa el collider real de 24 × 40 px como silueta de referencia.

Los tramos 2→3, 5→6 y 6→7 tienen alcances horizontales teóricos con carrera de aproximadamente 141, 104 y 119 px respectivamente. El hueco de 114 px del tramo izquierdo deja poco margen al sumar un aterrizaje centrado. El salto derecho de 78 px consume casi toda la altura teórica de 90 px. La variante del panel sube el apoyo 5 de Y=422 a Y=410. La subida 5→6 baja a 66 px y 4→5 aumenta de 40 a 52 px. El montaje base conserva ambas posiciones originales.

La escala 2× mantiene píxeles enteros y reduce las distancias respecto de 2,61×. La viabilidad queda pendiente de prueba con el Player real, entradas normales, espacio de cabeza y márgenes de despegue y aterrizaje. Aprobar la escala, la variante del apoyo 5 y el tratamiento del suelo inferior antes de construir la escena.

Regeneración con Python y Pillow: ejecutar `prepare_room4.py`. El generador verifica SHA-256 de los 19 PNG de entrada antes y después de producir los cuatro paneles.
