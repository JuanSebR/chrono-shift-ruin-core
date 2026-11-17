# Guardián: ajustes finales

17/11/2026 · Godot4.7.2. Ajuste limitado al reloj ofensivo y los anchos de los dos láseres.

| Intervalo | Comportamiento |
|---|---|
|0–1s|Salida original animada|
|1–40s|Fuera de pantalla; vertical y horizontal con la cadencia y avisos existentes|
|40–41s|Regreso original animado|
|41–41,5s|Aterrizaje|
|41,5–44,25s|Proyectil900unidades/s; aviso0,6s, vuelo máximo1,8s y recuperación terminada antes de44s|
|44,25–45s|Apertura protegida|
|45–51s|Cuerpo completo vulnerable a espada en Presente|
|Tras51s si sigue vivo|Cierre protegido0,75s y nuevo ciclo de45s|

Vertical: los cuatro PNG originales se dibujan con nearest y escalaX2,5, altura nativa360 repetida dos veces. Los32px de banda visible pasan a80px; dibujo y consulta física comparten el mismo factor. Sigue marcando como máximo dos columnas entre X300/640/980.

Horizontal: beam_hold/beam_finish usan escala uniforme1; la banda visible máxima y su colisión miden32px. La expansión beam_start usa escala uniforme1/6; advertencia, preparación, barrida y contracción conservan sus tiempos. Las colas físicas siguen el alfa32/20/8/3/1/0. No hay peligro horizontal mientras el vertical grueso daña.

Sin cambios a sprites fuente, Player, físicas, geometría, plataforma lateral,3HP, espada1HP, rectángulo corporal vulnerable, BossHUD, progreso persistente o controlador/lanzador F9. El guardado real y su `.bak` se verifican por SHA256.

Pruebas afectadas: `guardian_three_attacks_test.gd`, `guardian_vertical_burst_test.gd`, `room5_practice_test.gd` y `guardian_body_hurtbox_test.gd`. El recorrido combinado usa inputs del Player real, salto y Shift, sin teletransportar ni extender ventanas. Tras el último proyectil cruza directamente entre los apoyos de Pasado si ya está en esa dimensión, llega a Strike y conecta tres tajos distintos. Los casos corporales conservan pruebas de cabeza/torso/piernas desde ambos lados.

Resultados y respaldo: `artifacts/guardian_final_tuning/verification.json`. Las capturas se obtienen de Godot renderizado a1280×720; la prueba automatizada no sustituye la valoración humana del balance.

Resultado: recorrido combinado headless y renderizado PASS; Player3/3, jefe0/3 y victoria aislada confirmada. La prueba F9 registra exactamente2700 fotogramas ofensivos y360 vulnerables a60Hz. Vertical aislado, seis casos corporales, relectura de victoria en otro proceso y validate PASS. Los bordes ampliados producen1HP y las posiciones inmediatamente exteriores no reciben daño. Se conservaron los hashes del guardado real, su respaldo y todos los sprites fuente.

La suite corporal acelerada conserva avisos de liberación de audio al cerrar (AudioStreamWAV/AudioStreamPlaybackWAV de Sword_slash y landing); no tiene fallos funcionales ni errores GDScript. Se incluyen sus logs completos y no se modifica el audio del juego como parte de este ajuste.
