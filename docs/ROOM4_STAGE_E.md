# Room4 · Fase E

Tres idas y vueltas completadas desde instancias nuevas. El Player aparece en su marcador y toda la navegación posterior usa las acciones de movimiento, salto y cambio de dimensión. Cada apoyo se identifica por la colisión de suelo o por una consulta física bajo el collider cuando ya está apoyado.

| Ida | Estado al aterrizar | Hueco / subida (px) | Vuelo de referencia (s, aprox.) | Margen del collider (px, referencia) |
|---|---|---:|---:|---:|
| Entrada → MetalLeft | Presente | 86 / −12 | 0,70 | 22,5 |
| MetalLeft → PastLeft | Pasado | 114 / 24 | 0,63 | 21,2 |
| PastLeft → CentralRest | Pasado | 68 / −58 | 0,75 | 23,4 |
| CentralRest → MetalRight | Presente | 70 / 52 | 0,58 | 25,8 |
| MetalRight → PastRight | Pasado | 82 / 66 | 0,55 | 24,2 |
| PastRight → repisa final | Pasado | 60 / 60 | 0,57 | 22,8 |

La ida usa tres cambios: en vuelo hacia PastLeft, sobre CentralRest y en vuelo hacia PastRight. Se puede caminar hasta X≥1210 sobre la repisa final. El regreso pasa por PastRight, MetalRight, CentralRest, PastLeft, MetalLeft y la entrada. Sus tres cambios ocurren en los saltos hacia MetalRight, PastLeft y MetalLeft. La repisa de entrada es el aterrizaje inverso con menos margen, aproximadamente 6 px para el collider completo.

Se probaron despegues con umbrales a 5, 9 y 13 px del borde, salto sostenido aproximadamente 24–41 fotogramas y solicitud de cambio en los fotogramas de vuelo 16, 21 y 25 (índice desde cero). El primer despegue también pasó con 213 px/s. Los dos cambios de referencia se confirmaron cerca del ápice, con Vy≈0,107 px/s. El test compara posición y velocidad con la muestra anterior o con el avance normal de un paso físico debido a la cola de entrada. El salto alto MetalRight → PastRight mantuvo más de 22 px de margen en los casos probados. Estos casos no representan todas las combinaciones posibles ni sustituyen una sesión con jugadores.

**Atajos, análisis geométrico:** en Presente, MetalLeft → CentralRest deja 276 px de hueco. En Pasado, entrada → PastLeft deja 320 px. El menor hueco que omite un apoyo es 236 px. Incluso concediendo 100 px de ascenso, la máxima bajada de toda la ruta (178 px), 0,37 s de subida, velocidad máxima y los 24 px del collider, el alcance entre bordes queda por debajo de 236 px. La comprobación de atajos es analítica y corresponde al recorrido superior. La decoración inferior carece de apoyo jugable.

Se comprobó cámara activa y HUD visible al llegar a la derecha. Se renderizaron hitos de la ida y el regreso a 1024 × 572 y 1280 × 720 en artifacts/room4_stage_e. Pruebas con perfil temporal: room4_route_test, room4_base_test, room4_dimension_test, temporal_lens_hud_dynamic_test y validate finalizaron con código 0 en la corrida secuencial a reloj fijo para las pruebas sin ventana. La primera ejecución concurrente produjo un fallo temporal en la regresión del HUD y avisos de caché de shaders. También se observaron avisos de liberación de recursos al salir en pruebas sin ventana.

La fase añade únicamente el test de ruta, esta documentación y capturas. Los márgenes no justifican un cambio de geometría. Para F queda definir la recuperación al perder el apoyo o caer al vacío.
