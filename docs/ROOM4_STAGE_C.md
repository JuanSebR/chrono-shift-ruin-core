# Room4 · Fase C

La ejecución interrumpida dejó guardadas la ampliación de DimensionManager y su instancia configurada en Room4. El MCP confirmó Room4 abierta, detenida y sin cambios pendientes. Se respaldó el estado recuperado y se conservó la implementación comprobada.

Room4 usa la acción dimension_shift del InputMap y consulta la Lente en GameProgress. GameManager conserva la entrada anterior de Room1 y la llamada histórica protegida por has_method. El modo TileMapLayer sigue funcionando.

| Grupo | Presente | Pasado |
|---|---|---|
| Tres apoyos compartidos | Activos | Activos |
| Dos metálicas | Activas | Fantasma |
| Dos escalones | Fantasma | Activos |
| Suelo industrial inferior | Decoración | Decoración |

El gestor encola la solicitud y la resuelve en física con prioridad −10, antes del Player. Consulta directamente las formas de destino aunque estén desactivadas, usando el rectángulo del Player con un ajuste de 0,05 px por borde para separar contacto y penetración. Al aceptar desactiva primero las formas salientes, activa las entrantes y cambia el grupo visible antes de emitir dimension_changed. El rechazo emite dimension_change_rejected y conserva el estado. El gestor no escribe posición ni velocidad. Solo un cambio aceptado inicia la recarga de 0,20 s.

La Fase D puede leer active_dimension, switch_cooldown_remaining y can_request_switch y escuchar las dos señales. La protección de 0,16 s aún requiere implementación propia.

Godot 4.7.2: room4_base_test.gd, room4_dimension_test.gd y validate.gd pasaron. La prueba dimensional incluye regresión TileMapLayer en Room1, Shift con y sin Lente, cambio sobre repisa, rechazo, cooldown, ascenso con aterrizaje en PastLeft y cambio en caída. El salto se ejecuta con entradas reales desde un punto inicial preparado sobre MetalLeft. No certifica la ruta completa ni aísla el fotograma exacto del ápice. Las ejecuciones gráficas usan un APPDATA temporal y producen capturas en artifacts/room4_stage_c.
