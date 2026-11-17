# Guardián — vertical_burst

16/11/2026 · Godot4.7.2. Implementado únicamente el ataque vertical. El controlador60s/6s,3HP, geometría, Player y persistencia no se modifican. Horizontal y proyectil directo siguen pendientes.

## Recursos y dibujo

Se usan los cuatro PNG RGBA originales de `assets/sprites/jefe`:

| Archivo | Tamaño | Uso |
|---|---|---|
|laser_vertical_fijo_64x360.png |64×360 |Advertencia4px, sin daño |
|laser_vertical_expansion_6_frames_384x360.png |384×360 |Seis celdas horizontales64×360 |
|laser_vertical_maximo_64x360.png |64×360 |Haz máximo32px visibles |
|laser_vertical_contraccion_6_frames_384x360.png |384×360 |Seis celdas64×360, última transparente |

Cada celda se dibuja en64×360 unidades, dos veces en vertical (Y0/360) para cubrir el mundo720px. No se estira, rota, deforma, redibuja ni recolorea la imagen. La escala de cámara/ventana existente se mantiene. Las dos copias comparten un solo control de daño por columna; no producen impactos dobles en su unión.

## Secuencia y selección

Advertencia1,4s → expansión0,6s (0,10s/cuadro) → máximo0,75s → contracción0,6s (0,10s/cuadro) → desaparición → descanso1,2s. La primera parte fina de la expansión y la cola fina de contracción siguen siendo inocuas. El primer peligro aparece aproximadamente1,6s después de iniciar la advertencia.

Las ráfagas alternan una y dos columnas entre **X300/640/980**. Se elige la más cercana al Player y, en las ráfagas dobles, una segunda distinta con alternancia determinista. Se fijan al comenzar el aviso; no persiguen al jugador después. Nunca se seleccionan tres columnas. No se inicia una nueva ráfaga si su secuencia completa excedería el regreso del jefe a los57s.

La línea original marca exactamente el eje futuro y se acompaña con TutorialHints existente: «LÁSER VERTICAL — sal de las columnas marcadas.». La segunda dimensión no borra el aviso ni retrasa el ataque.

## Colisiones y evasión

El ataque daña en **ambas dimensiones**. Cambiar a Pasado no convierte el rayo en inocuo; Shift permite usar el apoyo de la otra dimensión durante la evasión y conserva la protección temporal original de0,16s. Esta regla queda limitada al vertical y no modifica otros ataques.

El peligro ocupa únicamente la banda luminosa gruesa, no los64px completos de la celda ni una plataforma entera. La hitbox se calcula por cuadro a partir de los límites alfa originales:

- Expansión, inicio/ancho:31/1,31/2,29/6,22/20,18/28,16/32.
- Contracción:16/32,22/20,28/8,30/3,31/1,0/0.
- Máximo:16/32. Los cuadros de anchura inferior a6px no dañan.

La consulta física usa el mismo intervalo X que el dibujo opaco y altura720. Solo afecta al Player real, por1HP y como máximo una vez por ráfaga. La invulnerabilidad y protección del Player no se alteran. Si la protección rechaza un impacto, ese rechazo no consume el daño de la ráfaga.

Se evade lateralmente durante el aviso; no se puede saltar por encima de un haz que cubre toda la altura. Una ruta probada es P1(300,620) → salto con desplazamiento a X≈373 → Shift cerca del ápice → T1(373,550). El rayo queda en300 y el Player conserva3/3. También quedan márgenes de las plataformas fuera de cada banda y al menos una columna no atacada. La geometría permite rutas, pero este ataque aislado no pretende cubrir todos los puntos seguros del escenario; los otros dos ataques se diseñarán por separado.

Los tiempos son una primera configuración comprobada con inputs físicos. No se declara cerrado el balance de dificultad para jugadores humanos.

## Integración y cancelación

`VerticalBurst` es un Node2D hijo local de CoreGuardian, con el nuevo controlador `guardian_vertical_burst.gd`. Dibuja en coordenadas del mundo mediante top_level; no hereda el desplazamiento aéreo ni la escala del cuerpo. El jefe mantiene su pose aérea original fuera de pantalla.

Se suscribe a `attack_slot_ready("vertical_burst",cycle_id)` y comprueba `attack_slot_available` y la identidad del ciclo. Los otros identificadores se ignoran. Un slot de otro ciclo se rechaza. No se cambia el controlador principal.

`offensive_attacks_cancelled` deshabilita la secuencia, borra columnas, oculta dibujo/aviso y cancela futuros pasos inmediatamente. Cada paso físico vuelve a verificar el estado y ciclo del jefe. El daño itera una copia de columnas y comprueba cancelación para soportar una muerte letal que dispare limpieza dentro de la consulta, sin continuar dañando. La salida del árbol desconecta observadores; la sala nueva no hereda temporizadores ni efectos.

## Pruebas y capturas

`tests/guardian_vertical_burst_test.gd`: PASS headless y con render1280×720. Comprueba:

- Tamaño de las hojas y coincidencia de las hitboxes con el alfa de los doce cuadros originales.
- Slot del ciclo real y jefe fuera de pantalla con exit_repose.
- Advertencia sin daño incluso permaneciendo dentro de la línea.
- Evasión con salto, movimiento y Shift reales de P1 a T1, sin teletransportar ni recuperar por caída.
- Expansión, activo, seis cuadros de contracción y desaparición.
- Dos columnas como máximo y una libre; objetivos fijados durante la advertencia.
- Daño real1HP en Pasado y máximo un impacto por ráfaga.
- Cancelación durante peligro activo y ausencia de daño residual.
- Rechazo de slot obsoleto; sobrecalentamiento sin láseres.
- Muerte y reconstrucción de sala sin efectos anteriores. Esa comprobación terminal utiliza daño controlado al Player, separado de los impactos reales del láser.

La prueba del ciclo completo también pasa con vertical habilitado: conserva60s/6s, tres golpes reales, derrota y victoria persistente en disco. Se actualizan sus comprobaciones de cancelación al sobrecalentar y morir. validate.gd pasa. Los perfiles APPDATA son aislados; no se usan guardados reales.

El render fue revisado visualmente. Las comprobaciones adicionales de límites alfa se añadieron después al test headless; no cambian el dibujo ni los tiempos de la ejecución renderizada. Persisten avisos ObjectDB/recursos al cerrar la suite integrada heredada; se registran aparte, sin errores de script ni fallos de aserciones. La prueba específica final termina con exit0.

Capturas reales:

- [Advertencia](../artifacts/guardian_vertical_burst/01_advertencia.png)
- [Expansión](../artifacts/guardian_vertical_burst/02_expansion.png)
- [Evasión en Pasado](../artifacts/guardian_vertical_burst/03_activo_evadido.png)
- [Contracción](../artifacts/guardian_vertical_burst/04_contraccion.png)
- [Dos columnas](../artifacts/guardian_vertical_burst/05_dos_columnas.png)
- [Impacto real](../artifacts/guardian_vertical_burst/06_impacto_real.png)

## Archivos y respaldo

Modificados: `scenes/bosses/CoreGuardian.tscn` (únicamente recurso/nodo del vertical), test de ciclo y STATE. Nuevos: controlador vertical, prueba específica, este informe y evidencias. No se modifica la geometría, el controlador60s/6s, los otros ataques,3HP ni GameProgress.

Respaldo previo: `C:/Users/juans/chrono-shift-backups/vertical_burst_20261116_220018/`, con hashes.json. protected.json registra hashes previos del controlador principal, guardado, Room5, Player, DimensionManager y room5.gd; la comprobación final exige que coincidan. Los PNG originales se conservan.

El trabajo termina con vertical_burst. No se implementan horizontal ni proyectil directo.
