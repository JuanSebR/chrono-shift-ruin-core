# Guardián — vertical80, horizontal32 y proyectil directo

Actualizado17/11/2026 · Godot4.7.2. Los tres ataques usan ahora el ciclo45s/6s, conservando3HP, cuerpo completo vulnerable, geometría y GameProgress. Ajustes y verificación actual: `GUARDIAN_FINAL_TUNING.md`.

## Vertical ampliado

Se conserva la secuencia, advertencia1,4s, selección de una/dos columnas y daño1HP por ráfaga. Los cuatro PNG originales se dibujan con escala horizontal2,5× y filtro nearest explícito: celda de160×360 a partir de64×360; la banda visible máxima mide **80px**. La misma escala se aplica al aviso, expansión, máximo y contracción. No se sobrescriben sprites ni atlas. La altura permanece360 y se repite dos veces para cubrir720.

Cada hitbox aplica exactamente el mismo factor2,5 a inicio/ancho alfa del cuadro. No se aumenta solo la colisión. Las franjas transparentes siguen sin dañar, y las reglas de expansión/cola fina permanecen iguales. La ruta física de evasión a X≈373 sigue quedando fuera de la banda centrada en300, incluso con la hitbox24px del Player.

## Horizontal

Nuevo `HorizontalLaser`, conectado a attack_slot_ready(horizontal_laser,cycle_id). El Guardián sigue fuera con su pose aérea. Usa beam_start, beam_hold y beam_finish originales; dibuja tiras del efecto, sin formas genéricas ni cambios en archivos fuente.

La altura se fija al anunciarse, eligiendo la más próxima al Player entre **Y460/530/600**. Hay una sola banda horizontal peligrosa, de32px al máximo. La barrida entra desde X1280 hacia0 durante0,5s; la hitbox crece solo hasta el frente visible. El aviso muestra todo el carril antes de que cause daño. Las otras alturas permanecen disponibles.

Coordinación sin modificar el ataque vertical: cuando este entra en activo, comienza el aviso horizontal de0,75s. Durante la contracción vertical se reproducen0,6s de preparación/expansión horizontal inocua. Al entrar el vertical en su descanso, se produce la barrida de0,5s y la disipación de0,6s. El ciclo horizontal termina antes de la siguiente advertencia vertical. Se verifica además que ninguna hitbox horizontal opere mientras la banda vertical gruesa sea peligrosa.

El haz máximo usa beam_hold a escala uniforme1: sus32px de alfa producen32px visibles. La preparación usa escala uniforme1/6 y la disipación alturas32/20/8/3/1/0 según los seis cuadros originales; solo bandas de6px o más dañan. Advertencia y preparación no dañan. Máximo1HP por ejecución, respetando protección e invulnerabilidad originales del Player.

Evasión probada: desde T1 en Pasado, salto y Shift a P4 en Presente; en la siguiente advertencia, salto y Shift de vuelta a T1. Los centros del Player cambian entre530 y460; la banda anterior queda fuera del cuerpo. No se pretende que Pasado sea un modo invulnerable: ambos láseres afectan a ambas dimensiones.

## Proyectil directo

`DirectProjectile`, conectado exclusivamente al slot direct_projectile del regreso. Encaja en el intervalo41,5–44,25s. Véase `GUARDIAN_PROJECTILE_900.md`:

- Preparación0,6s con aviso y línea de apuntado del arte existente.
- Se muestrea la posición del Player **una vez al disparar** y se fija dirección/orientación. No hay seguimiento posterior.
- Velocidad900 unidades/s y máximo1,8s en vuelo. El extremo veloz se comprueba con subpasos de hasta4px, evitando atravesar al Player entre frames.
- Recuperación visual del paquete con beam_finish, hasta0,1s. Control completo cerrado como máximo a los2,5s del slot, antes de la apertura y del sobrecalentamiento45s.

El proyectil reutiliza el recurso energético ya disponible beam_hold, a escala uniforme0,5: su parte opaca mide32×16 y la consulta rectangular rotada coincide con ella. No se dibuja un proyectil genérico nuevo. Daño1HP; el contacto consume el proyectil aunque el escudo temporal haya rechazado el daño. La orientación sigue la dirección fijada al emitir, sin corregirse durante el vuelo.

### Attack3 y cuadros recortados

Se revisó el atlas original de seis celdas640×800. Las celdas4/5 (índices desde0) tienen recortes del cañón; no se pintan ni reconstruyen píxeles faltantes. La integración evita mostrarlas y utiliza la secuencia de cuadros originales **0→1→2→3→1→0**, con poses0/1 durante los0,6s de preparación y2/3/1/0 a pasos de0,125s tras emitir. Se mantiene la escala corporal existente0,375 y se calcula la boca desde los landmarks del cuadro de emisión2, con espejo según el lado del Player.

Es una corrección de integración, no una restauración de las fuentes. Siguen faltando cuadros de recuperación4/5 completos si se desea reproducir exactamente toda la secuencia dibujada originalmente. La solución actual reutiliza poses existentes; no modifica el diseño ni inventa una animación nueva. Al cancelar se restauran los SpriteFrames base antes de que el controlador abra el núcleo.

La evasión del disparo se prueba reaccionando cerca de la emisión: el salto y Shift cambian la altura después de la mayor parte del apuntado. Saltar demasiado pronto permite que el jefe apunte al salto; una primera ejecución recibió daño por esa causa. No se redujo el daño ni se otorgó inmunidad artificial para corregirla.

## Cancelación y seguridad

Los dos controladores nuevos comprueban ciclo/slot válido en cada paso y rechazan slots duplicados del mismo ciclo. offensive_attacks_cancelled limpia avisos, hitboxes y paquete, y restaura la animación si el driver la estaba usando. No quedan efectos al abrir núcleo, morir, salir o reconstruir Room5.

Las pruebas incluyen muerte del Player mientras hay un paquete real en vuelo, seguida por la recarga heredada. El daño letal de esa comprobación es una entrada controlada de daño, separada de las pruebas de impacto real1HP. No se cambia Player ni su flujo de derrota.

## Pruebas actuales

`guardian_vertical_burst_test.gd`: prueba aislada del vertical ampliado; deshabilita el procesamiento de los dos controladores nuevos solo en su fixture. Conserva comprobaciones de alfa, aviso, cuadros, daño, evasión y limpieza. No se deshabilitan ataques en producción para obtener esos resultados.

`guardian_three_attacks_test.gd`: nueva integración con Player real, movimiento, saltos y Shift. El trigger se cruza físicamente. Se esquivan los tres ataques, sin caídas ni teletransportaciones durante el recorrido; se aprovechan los últimos momentos de regreso/apertura para acercarse y se conectan tres golpes dentro de la ventana original. La victoria se confirma por GameProgress y los efectos terminan antes del sobrecalentamiento/derrota.

También incluye fixtures separados: aviso horizontal sin daño, impacto horizontal1HP, impacto directo1HP, dirección fija, recuperación antes de abrir núcleo, ventana vacía de6s, segundo ciclo45s, cancelación durante vuelo y reintento limpio. Los bordes de80px/32px se prueban con consultas físicas, y las seis colas horizontales se comparan con su alfa original. Las posiciones del recorrido principal no se reasignan para alcanzar el jefe.

El archivo `core_guardian_offense_overheat_test.gd` pasa a ser la entrada de esta suite actual: el anterior esperaba un mundo sin los tres ataques y un actor inmóvil. Su respaldo conserva la versión anterior; las comprobaciones de ciclo vacío/reinicio se trasladan a la nueva suite. No se declara que un test antiguo que no evade deba sobrevivir a ataques reales.

Las pruebas usan APPDATA aislado. Los fallos iniciales de la automatización —trigger sin armar, reacción temprana al disparo y aproximación demasiado tardía— se corrigieron en la preparación/ruta de prueba, sin cambiar ciclo, daño, geometría o guardado. Las capturas no deben alterar el momento de las pulsaciones: el controlador espera apoyo firme y sincroniza la pulsación antes de saltar.

`tests/validate.gd` comprueba sintaxis. Los resultados finales, logs y hashes se conservan en `artifacts/guardian_three_attacks/`. La evaluación automatizada demuestra rutas concretas; el balance de dificultad y la legibilidad definitiva requieren revisión humana.

Resultado final: prueba vertical aislada PASS, suite combinada headless PASS, render1280×720 PASS y validate PASS. En la partida principal de ambas ejecuciones: Player3/3, jefe0/3, victoria persistente confirmada, una emisión directa, dirección fija y ninguna coincidencia de bandas peligrosas de ambos láseres. Se verificó visualmente la ampliación, la barrida, preparación/disparo y derrota. Una comprobación visual complementaria ejecuta una sola ráfaga real y captura la barrida completa, sin preparar artificialmente la fase del láser.

Capturas:

- [Vertical80](../artifacts/guardian_three_attacks/01_vertical64.png)
- [Aviso horizontal](../artifacts/guardian_three_attacks/02_horizontal_aviso.png)
- [Frente de barrida](../artifacts/guardian_three_attacks/03_horizontal_activo.png)
- [Barrida completa — captura histórica anterior al ajuste de17/11](../artifacts/guardian_three_attacks/03b_horizontal_barrida_completa.png)
- [Preparación Attack3](../artifacts/guardian_three_attacks/04_disparo_preparacion.png)
- [Proyectil en vuelo](../artifacts/guardian_three_attacks/05_proyectil.png)
- [Sobrecalentamiento](../artifacts/guardian_three_attacks/06_sobrecalentamiento.png)
- [Derrota](../artifacts/guardian_three_attacks/07_derrota.png)

## Cambios y respaldo

Este bloque conserva el respaldo de la integración inicial de16/11. El cambio de17/11 a45s y80px/32px, con su respaldo y resultados, está en `GUARDIAN_FINAL_TUNING.md`.

Respaldo: `C:/Users/juans/chrono-shift-backups/guardian_three_attacks_20261116_221603/`, con hashes.json/protected.json.

Modificados: controlador vertical (solo dibujo/ancho/hitbox/filtro), CoreGuardian.tscn (dos nodos y referencias), pruebas afectadas y STATE. Nuevos: controladores horizontal/directo, prueba combinada, este informe y evidencias. No se editan sprites originales, controlador60s/6s, geometría de Room5, Player, DimensionManager ni sistema de guardado.
