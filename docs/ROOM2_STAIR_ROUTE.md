# Room2 — Escalera de mantenimiento del Presente

Implementada el 11 de noviembre de 2026. La ruta permite subir desde la pendiente inferior derecha hasta `Upper` con el movimiento y salto existentes de C.O.R.E.-9.

## Geometría final

| Plataforma | Superficie | Tamaño físico |
|---|---:|---:|
| P1 | X=1330–1410, Y=600 | 80×20 |
| P2 | X=1170–1250, Y=540 | 80×20 |
| P3 | X=1100–1180, Y=480 | 80×20 |
| P4 | X=740–825, Y=380 | 85×20 |
| P5 | X=900–985, Y=325 | 85×20 |
| P6 | X=930–1020, Y=265 | 90×20 |
| P7 | X=1085–1170, Y=205 | 85×20 |
| P8 | X=1100–1195, Y=145 | 95×20 |
| P9 | X=1280–1370, Y=98 | 90×20 |

Las nueve colisiones son `StaticBody2D` independientes con `CollisionShape2D` rectangular y `one_way_collision`. Esto permite saltar desde abajo y utiliza el soporte de descenso atravesable que ya existía en Player, sin modificar sus físicas. Los visuales están a escala 1:1, filtrado nearest, detrás del Player y alineados con la superficie física.

## Recursos

Los nueve PNG de `assets/tiles/sala 2.1/derived/` se extraen de `plataformas s2.1.png` mediante `tools/build_room2_stair_assets.gd`. Conservan transparencia real y no alteran los originales. P1–P3 usan cornisas bajas; P4–P7 alternan ménsulas; P8–P9 usan remates deteriorados.

## Validación física

`tests/room2_stair_route_test.gd` recorre el suelo desde el spawn y realiza, sin teletransporte, las trece conexiones del ascenso: pendiente → P1 → P2 → P3 → Step1 → P4 → P5 → Step2 → P6 → P7 → Step3 → P8 → P9 → Upper. Después realiza el descenso completo con entradas reales. Step1 → P4 utiliza carrera sobre Step1. En descenso, Step3 → P7 y Step2 → P5 usan pulsación corta para evitar los apoyos superiores; P2 → P1 usa carrera y pulsación corta para evitar `RightShelf`.

La colocación inicial de P2 fue descartada porque quedaba bajo `RightShelf` y cancelaba el salto. La posición definitiva deja libre la cabeza. P5 conserva su posición de planificación porque las plataformas nuevas son atravesables y P6 ya no encajona al Player.

## Progresión

La escalera representa una ruta de mantenimiento deteriorada del Presente y permite llegar a `Upper` antes de obtener la Lente Temporal. No abre Sala 3, no activa rutas dimensionales y no modifica el GDD. Queda pendiente revisar la función narrativa de los accesos elevados cuando se diseñen Sala 3 y la Lente.
