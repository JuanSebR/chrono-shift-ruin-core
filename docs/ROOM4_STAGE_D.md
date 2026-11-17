# Room4 · Fase D

TemporalLensHUD se mantiene como componente único de CombatHUD. Detecta el gestor configurado para el Player en la jerarquía de la sala y se suscribe a dimension_changed y dimension_change_rejected. Room1 conserva su ruta TileMapLayer y muestra el dispositivo neutral. Room1.5, Room2, Room2.2 y Room3 muestran LENTE INSTALADA si hay posesión. Sin posesión, el componente queda oculto.

El Presente usa la pose cian y el Pasado la magenta de skill.png. El extractor corta las dos poses y retira el fondo conectado a sus esquinas. skill recharging.png aporta seis poses alineadas en recharge_atlas.png. El HUD conserva filtrado nearest. Los tres originales miden 2172 × 724. Solo la hoja de recarga tiene alfa real. La hoja de invulnerabilidad queda reservada para una futura protección efectiva.

La confirmación muestra la dimensión destino y CAMBIO durante el primer tramo de la recarga real. Cada fotograma se deriva de 1 − tiempo restante / duración del gestor. Al alcanzar cero se restaura la pose disponible y se detiene el procesamiento. El rechazo conserva el icono y añade un aviso de 0,65 s, independiente de la recarga. GameManager retira la llamada histórica al cooldown del HUD y conserva su actualización del tema de salud.

Archivos existentes modificados: GameManager.gd y scripts/ui/temporal_lens_hud.gd. Nuevos: build_dynamic_lens.py, ready_present.png, ready_past.png, recharge_atlas.png y tests/temporal_lens_hud_dynamic_test.gd.

PASS en Godot 4.7.2: temporal_lens_hud_test, temporal_lens_hud_dynamic_test, room4_dimension_test (incluye Room1), room4_base_test y validate. El test usa posesión en memoria con APPDATA aislado. Verifica reingreso neutral, pero no ejecuta una derrota, el menú Continuar ni la secuencia completa de adquisición.

Los catorce renders de Godot están en artifacts/room4_stage_d, con siete estados en cada resolución (1024 × 572 y 1280 × 720).
