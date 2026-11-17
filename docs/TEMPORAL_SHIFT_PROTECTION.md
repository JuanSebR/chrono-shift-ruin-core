# Protección temporal después de Shift

Room4 activa la protección solo en la rama confirmada de `DimensionManager._physics_process()`, después de actualizar dimensión, colisiones y recarga, y antes de emitir `dimension_changed`. El método histórico `toggle_dimension()` de Room1 permanece igual. Los cambios rechazados o sin Lente no alcanzan esta rama.

`Player` posee un `Timer` independiente de 0,16 s. Expone `is_temporally_protected()`, `get_temporal_protection_remaining()` y las señales `temporal_protection_started(duration)` y `temporal_protection_ended`. El temporizador se detiene al vencer, al emitirse `defeated` y al recuperar el checkpoint de Room4. Una nueva instancia empieza sin protección. La protección no se guarda.

`take_damage()` descarta golpes normales mientras el temporizador está activo, antes de alterar salud, animación, HUD o el contador normal de invulnerabilidad. Los proyectiles de `EnemyProjectile` utilizan ese mismo método y se consumen al impactar. Los 60 pasos físicos de invulnerabilidad por daño y la recarga de Shift de 0,20 s siguen independientes.

## Presentación en el HUD circular

`skill invulneravity.png` contiene cinco poses en 2172×724, con fondo cuadriculado opaco y efectos que se solapan entre celdas. `assets/ui/hud/temporal_lens/build_protection_frames.py` recorta una región centrada de 420×420 por pose, elimina solo los píxeles casi blancos y neutros de la cuadrícula fuera del núcleo luminoso y genera `protection_00.png` a `protection_04.png` de 526×528 con transparencia real y escalado nearest. Los rayos exteriores que invadían las celdas vecinas quedan recortados; no se modificó el original.

`TemporalLensHUD` reutiliza `LensIcon`, sin añadir nodos ni duplicar el indicador. Escucha `temporal_protection_started` y `temporal_protection_ended` del Player controlado por el gestor. Mientras `is_temporally_protected()` es verdadero, elige una de las cinco poses a partir de `get_temporal_protection_remaining()` y la duración real de 0,16 s. No tiene temporizador visual propio. Cuando termina, vuelve inmediatamente a la textura de recarga ya avanzada; esta continúa hasta 0,20 s y después vuelve a Presente o Pasado disponible. Rechazos, falta de Lente, invulnerabilidad por daño, caídas, derrota y nuevas escenas no muestran el efecto.

Las caídas usan rutas locales distintas: Room4 reposiciona y cancela protección y recarga; Room2.2 establece la derrota directamente. No se modificaron sus penalizaciones.

## Validación

PASS: `temporal_shift_protection_test`, `room4_dimension_test`, `room4_route_test`, `room4_fall_recovery_test`, `temporal_lens_hud_dynamic_test`, `room2_health_test`, `room22_void_death_test` y `validate`. Se ejecutaron de forma secuencial con `APPDATA` aislado y Godot 4.7.2. El test de protección usa el Player y el gestor reales de Room4, instancia el proyectil real, comprueba rechazo y aceptación de daño, coexistencia de protecciones, cooldown, caída real y recuperación, derrota y escena nueva. El test dimensional también verifica la ruta histórica de Room1.

PASS: `temporal_lens_protection_visual_test` a 1024×572 y 1280×720, con capturas reales en `artifacts/temporal_protection_visual/`. Verifica el efecto frente al estado real del Player y la recarga, así como rechazo, caída, derrota y cambio de escena. También volvieron a pasar secuencialmente `temporal_shift_protection_test`, `temporal_lens_hud_dynamic_test`, `room4_dimension_test`, `room4_fall_recovery_test` y `validate`.

`combat_test` no se ejecutó: exige además `application/config/name = Core9_Combat_Isolated` para permitir `new_game()`; el perfil de guardado aislado por sí solo no satisface esa precondición. `room4_fall_recovery_test` terminó con código 0 y todas sus aserciones aprobadas, aunque Godot reportó cuatro recursos aún en uso al salir en la última corrida. Los rayos exteriores de la fuente original no caben completos en cada celda separada; las cinco poses integradas conservan el chasis y el destello central sin contaminación de poses vecinas. No se realizó verificación auditiva ni una sesión larga interactiva.
