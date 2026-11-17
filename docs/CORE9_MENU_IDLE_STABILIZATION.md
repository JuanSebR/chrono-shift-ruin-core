# Estabilización del apoyo de C.O.R.E.-9 en el menú

Implementado el 10 de noviembre de 2026 en el menú real.

La ilustración se desplazaba dentro de los lienzos originales. Se registraron los detalles de cadera y muslo contra F007 y se contrastó el resultado con el contorno inferior real de la cadera y los ladrillos en renders del menú. El contorno de apoyo variaba aproximadamente 13 px verticales entre extremos, más que la estimación anterior de 2 px. No se utilizó el centroide de píxeles oscuros.

Se generaron 20 PNG RGBA de 1024 × 1024 en `assets/inicio/personaje_sin_fondo_estabilizado/`, mediante traslaciones enteras sin interpolación. Se copiaron exactamente los píxeles RGBA, se verificó el encuadre del canal alfa y su suma, y se comprobaron los hashes SHA-256 de los originales. No hay deformación, remuestreo, recortes ni filtros nuevos. Los movimientos relativos de cabeza, cabello, hombros y piernas son los originales. La traslación global elimina únicamente la deriva del apoyo.

## Traslaciones aplicadas

Coordenadas del PNG; X positivo a la derecha, Y positivo hacia abajo. F007 permanece idéntico.

| Frame | X (px) | Y (px) |
| --- | ---: | ---: |
| 007 | 0 | 0 |
| 008 | 0 | -2 |
| 009 | -1 | -3 |
| 010 | -2 | -5 |
| 011 | -2 | -6 |
| 012 | -2 | -7 |
| 013 | -2 | -7 |
| 014 | -2 | -7 |
| 015 | -2 | -5 |
| 016 | -1 | -4 |
| 017 | -1 | -3 |
| 018 | 0 | -2 |
| 019 | 1 | 0 |
| 020 | 1 | 2 |
| 021 | 2 | 4 |
| 022 | 2 | 5 |
| 023 | 2 | 6 |
| 024 | 2 | 6 |
| 025 | 2 | 6 |
| 026 | 2 | 6 |

El anclaje vertical se mide como la mediana del último píxel con alfa > 127 en las columnas 365–394, filas 540–589 del recurso alineado. La referencia es Y=569 px; el residual máximo es 0,5 px. La comparación de detalles de la cadera tras la corrección elige desplazamiento horizontal residual de 0 px en los 20 frames, con búsqueda de resolución entera. Son métricas locales de apoyo, no una afirmación de que toda la silueta sea idéntica. F026 y F007 tienen el mismo anclaje medido; las diferencias de pose originales permanecen.

## Integración y timing

`scenes/MainMenu.tscn` cambió exclusivamente en 20 rutas externas de textura. Se verificó la igualdad byte a byte con el respaldo después de esas sustituciones. Se conservan CharacterLayer, WindAnim, la estructura, posición (-64,52; -123,22), escala 0,915, fondo, botones, logo y opciones.

El diagnóstico previo sobre una pausa doble final no se reproduce en el estado recibido. La escena ya tenía 20 claves desde 0,0 hasta 1,9 s, separadas 0,1 s, `length=2.0`, bucle lineal y actualización discreta. Se conservó esa configuración tras comprobar el AnimationPlayer real con avances de 1 ms durante dos ciclos, antes y después de integrar las texturas: cada frame aparece entre 199 y 201 muestras en 4 s (200 ms acumulados, con tolerancia de muestreo de 1 ms); F026 tiene el mismo intervalo nominal de 100 ms por ciclo. No se añadió una clave duplicada en 2,0 s ni se alteró la velocidad.

## Resultados

| Prueba | Resultado |
| --- | --- |
| Exactamente 20 derivados, 1024 × 1024, RGBA y transparencia | PASS |
| Píxeles preservados por traslación, sin recorte del alfa | PASS |
| SHA-256 de los 20 originales | PASS, intactos |
| Desviación local del apoyo y conexión de anclaje F026 → F007 | PASS, vertical ≤ 0,5 px |
| Escena limitada a las 20 rutas de textura | PASS |
| `C:\Godot\godot.exe.exe --headless --path . --script res://tests/validate.gd` | PASS, salida 0 |
| `tests/progress_menu_test.gd` en copia `Core9_Combat_Isolated` | PASS, continuar y nueva partida |
| AnimationPlayer: 20 texturas derivadas, dos ciclos uniformes | PASS |
| Renders Godot del menú real: F007, F014, F026 y 20 posiciones del ciclo | PASS, inspección estática |
| MCP: identidad, revisión, árbol, recarga y vistas del editor | PASS; última vista parcialmente encuadrada |
| Reproducción visual interactiva y transición observada en tiempo real | PENDIENTE |

La captura interactiva de Windows falló con `FrameArrived timed out` y `window capture timed out` al recuperar y reintentar. Los renders se produjeron con Godot/OpenGL sobre la escena real; la tira y el GIF son evidencia derivada de esos renders, no sustituyen el PASS interactivo. La revisión de fluidez percibida del cambio de pose F026 → F007 permanece pendiente.

No se modificaron scripts del proyecto, Player, salas, enemigos, combate, progreso ni configuraciones. Los tests de navegación se ejecutaron en una copia con nombre de aplicación aislado para preservar la partida real. El ejecutable solicitado `C:\Godot\godot.exe.exe` informa Godot 4.7.2; la ruta alternativa de Downloads indicada en AGENTS.md es un directorio sin ejecutable.

## Respaldo y evidencia

- Directorio: `C:/Users/juans/AppData/Local/GodotMCPCodex/tests/menu-seat-stabilization-v1/`.
- Respaldo: `MainMenu.tscn.before.bak`.
- SHA-256 del respaldo: `6c0351eb60dac03ff77d215a42a7955cbae799b1e6998a5ce0fecf2b5a008331`.
- Manifiesto dentro del proyecto: `docs/CORE9_MENU_IDLE_MANIFEST.json` (hashes, offsets, medidas por frame).
- Scripts reproducibles externos: `analyze.py`, `stabilize.py`, `prepare.py`, `timing_audit.gd`, `render_menu.gd`, `run_checks.py`, `finalize.py`. Los generadores se niegan a sobrescribir sus recursos de entrada o su respaldo existente.
- Logs: `validate-real.log`, `progress-menu-isolated.log`, `timing-after.log`, `render.log`.
- Timing medido: `timing-before.json`, `timing-after.json`.
- Vistas: `menu_007.png`, `menu_014.png`, `menu_026.png`, `godot-contact-cycle.png`, `menu-stabilized-cycle.gif`.

Archivos del proyecto creados: los 20 PNG y sus 20 metadatos de importación Godot, este informe y el manifiesto. Archivos existentes modificados: MainMenu.tscn y la nota de continuidad en docs/STATE.md. Los archivos de caché de `.godot/` son gestionados por el editor.
