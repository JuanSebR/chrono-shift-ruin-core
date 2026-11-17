# Room4 · Fase B

Mundo 1280 × 720, filtrado nearest. Presente visible al cargar.

```text
Room4
├─ Visuals
│  ├─ Present → Background, Ghosts, Solid
│  └─ Past → Background, Ghosts, Solid
├─ WorldCollision
│  ├─ SharedCollision → EntryLedge, CentralRest, ExitLedge
│  ├─ PresentCollision → MetalLeft, MetalRight
│  └─ PastCollision → PastLeft, PastRight
├─ EntryMarkers → Spawn, FromRoom3, FutureExit
├─ RoomTransitions
├─ Player → Camera2D
└─ CombatHUD
```

Cada apoyo tiene un StaticBody2D y un rectángulo unidireccional propio de 8 px de grosor. Las coordenadas indican el borde superior.

| Apoyo | Grupo | X | Y |
|---|---|---|---:|
| EntryLedge | Compartido | 38–92 | 416 |
| MetalLeft | Presente | 178–298 | 428 |
| PastLeft | Pasado | 412–506 | 404 |
| CentralRest | Compartido | 574–718 | 462 |
| MetalRight | Presente | 788–872 | 410 |
| PastRight | Pasado | 954–1076 | 344 |
| ExitLedge | Compartido | 1136–1240 | 284 |

La metálica derecha sube 12 px en ambas variantes visuales y en su forma. Los apoyos compartidos y del Presente empiezan activos. Los del Pasado empiezan desactivados. El suelo inferior es decorativo.

Los seis PNG room4_* son derivados nuevos reproducibles con build_room4_layers.py. Los fondos incluyen la decoración y los apoyos compartidos. Los sólidos y fantasmas exclusivos son capas separadas a 2×. El generador comprueba SHA-256 de los 19 originales.

Player aparece en (64,396), con la cámara de su escena y límites locales (0,0)–(1280,720). Conserva zoom 1,14 y suavizado. Se reutiliza el controlador de Room2 para salud y derrota y una instancia del HUD compartido. FutureExit está en (1188,264).

Pruebas ejecutadas con Godot 4.7.2: room4_base_test.gd y validate.gd pasaron. La primera verificó aparición, salto real hasta MetalLeft y apoyo individual en Presente. room4_render.gd genera capturas diagnósticas en artifacts/room4_stage_b.

Para la fase C, el gestor deberá recibir los nodos Visuals/Present y Visuals/Past, las formas exclusivas y el collider del Player. El recorrido continuo requiere cambio funcional. La zona inferior queda pendiente de recuperación. Las escenas, scripts y derivados de esta fase se crearon como archivos nuevos.
