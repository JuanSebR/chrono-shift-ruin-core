# Room4 · Fase F

Room4 detecta el vacío con un único umbral local. Recupera cuando los pies del collider alcanzan Y=680, equivalente a Y=660 para el centro del collider de 24 × 40 px. El apoyo más bajo está en Y=462 y los pies siguen dentro del mundo de 720 px al cruzar el umbral. El suelo industrial inferior sigue siendo decorativo.

| Checkpoint | Centro del Player | Cara de apoyo | Activación |
|---|---|---|---|
| Spawn | (64, 396) | EntryLedge, Y=416 | Al cargar |
| CentralCheckpoint | (646, 442) | CentralRest, Y=462 | Player vivo, en suelo, con contacto físico cuyo normal apunta hacia arriba |

Room4 comprueba el contacto del paso de física anterior, una vez resuelto el aterrizaje. El checkpoint central queda activo durante la instancia. No existe un checkpoint permanente ni se escribe GameProgress.

La recuperación ocurre con prioridad física −20, antes del gestor (−10) y del Player. Reubica al Player en el marcador, establece velocidad cero y orientación derecha. El gestor cancela la solicitud pendiente, activa Presente, pone el cooldown a cero y emite el estado resultante. El HUD existente limpia el rechazo o la recarga y muestra Presente disponible. La cámara reinicia su suavizado local y actualiza el encuadre. Salud, espada, Lente y guardados conservan sus valores.

PASS en Godot 4.7.2 con perfiles aislados: room4_fall_recovery_test, room4_route_test, room4_dimension_test, temporal_lens_hud_dynamic_test, room4_base_test y validate. Se probó un salto y caída con entradas reales desde MetalLeft, una caída en Pasado tras aterrizar en el centro, caída con recarga y caída después de un rechazo. Se verificaron salud 3/3, 2/3 y 1/3, ausencia de derrotas y bucles, y control tras recuperar. Las regresiones de ruta y base repitieron los avisos de recursos al cerrar observados en Fase E.

Capturas reales en artifacts/room4_stage_f a 1024 × 572 y 1280 × 720. La integración con las futuras transiciones de Room3 queda pendiente de Fase G. Room2.2 conserva su controlador independiente de derrota.
