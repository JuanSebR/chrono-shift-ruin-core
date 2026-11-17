# Proyectil directo: velocidad y aviso

17/11/2026 · Godot4.7.2. Ajuste limitado al proyectil y al intervalo necesario para ejecutarlo.

- Velocidad900 unidades/s, antes3000.
- Preparación visible0,6s, antes0,25. El aviso conserva su texto y utiliza segmentos12×4 del sprite original para hacer visible la línea de apuntado.
- El Player se apunta durante la preparación; posición, orientación y dirección se muestrean al emitir. Después no hay seguimiento.
- Vuelo máximo1,8s:1620 unidades, suficiente para recorrer la arena incluso en diagonal. Se disipa antes si sale de la arena o toca al Player.
- Sprite, escala0,5, hitbox rotada32×16 y daño1HP intactos. Barrido con subpasos máximos4px para evitar atravesar al Player entre cuadros.
- Disipación del paquete0,1s. Recuperación corporal con los cuadros originales2→3→1→0, a0,125s por pose, después de las poses de apuntado0→1. Se excluyen los cuadros recortados4/5 como antes. El ataque termina cuando han acabado tanto el paquete como la recuperación corporal; desaparece el corte incondicional anterior a0,73s.

## Encaje en el ciclo45s/6s

El anterior intervalo43,5–44,25s solo tenía0,75s, insuficiente para0,6s de aviso y un proyectil que recorra la arena. Se anticipa el regreso2s, conservando las duraciones originales del regreso, aterrizaje, apertura y vulnerabilidad.

| Intervalo | Acción |
|---|---|
|1–40s|Fuera de pantalla; láseres con su lógica, anchos, daño, avisos y cadencia originales|
|40–41s|Regreso|
|41–41,5s|Aterrizaje|
|41,5–42,1s|Apuntado visible|
|42,1–43,9s como máximo|Vuelo de dirección fija|
|Hasta44s como máximo|Disipación y recuperación terminadas|
|44,25–45s|Apertura protegida original|
|45–51s|Cuerpo completo vulnerable;3HP, espada1HP|

La fase externa más corta permite ocho ráfagas completas en vez de nueve. Los scripts de ambos láseres permanecen sin modificaciones. Su comprobación existente de presupuesto impide iniciar otra ráfaga que no termine antes del regreso; no se corta un láser peligroso para habilitar este disparo.

## Pruebas

`guardian_projectile900_test.gd` ejecuta el reloj real con los láseres deshabilitados solo en sus fixtures, para aislar la evasión del proyectil. Tras la ubicación inicial, el Player usa inputs normales; no se teletransporta, no se alteran físicas ni se concede invulnerabilidad.

| Inicio | Reacción tras ver el aviso | Evasión comprobada |
|---|---|---|
|P4, X210|0,25s|Caminar a la entrada compartida y bajar de altura|
|P5, X640|0,30s|Salto sobre el apoyo original|
|P5, X640|0,40s|Shift aT2, caída hasta el apoyo del Pasado|
|P6, X980|0,55s|Salto antes de emitir|

En los cuatro casos el Player conserva3HP, no hay recuperación por caída y el paquete pasa de largo. La protección temporal ya ha expirado cuando el paquete se acerca; además se comprueba que pasa al otro lado del Player sin consumirse por contacto. Un Shift tardío sin salto desdeP6 recibió daño en la exploración: cambiar dimensión no convierte al Player en inmune ni garantiza la evasión desde cualquier posición. En ese apoyo se valida el salto; enP5 se valida Shift sin salto.

También se prueba un desplazamiento sintético de0,65s que atraviesa la posición del Player: el barrido detecta el contacto y causa exactamente1HP. F9 se pulsa con un paquete real en vuelo y debe eliminarlo. La suite combinada conserva los tres ataques,45s/6s, tres tajos, derrota y victoria persistente; su evasión reacciona al disparo tras el aviso completo, aprovechando el menor ritmo de vuelo.

Resultados, logs, capturas y respaldo: `artifacts/guardian_projectile900/verification.json`. Las pruebas con inputs y renderizado de Godot son automatizadas; no se presentan como una sesión humana.
