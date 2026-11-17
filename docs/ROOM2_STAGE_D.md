# Room2 — Etapa D

Player instanciado una vez desde scenes/Player.tscn, posición (100,560). EntryMarkers/Spawn coincide; colisión 24×40 apoyada sobre Y=580. Sin controlador adicional: la inicialización declarativa es suficiente en esta etapa.

Cámara interna: zoom 1,14 y suavizado heredados; solo la instancia local amplía límites a 1672×941. No se añadió otra cámara. Diez capturas reales OpenGL (cinco puntos en 1024×572 y 1280×720) en C:/Users/juans/AppData/Local/GodotMCPCodex/tests/room2_stage_d/.

Pruebas físicas: las seis plataformas elevadas y el tramo X=1520 sostienen al Player. LeftLedge tiene poco espacio libre debido al muro: apoyo comprobado en X=15; no se declara ruta alcanzable. Recorrido continuo desde X=100 hasta X=1538 y retorno hasta X≈20, ambos sobre suelo; salto y aterrizaje PASS. Validación de sintaxis PASS. El render carga sin errores tras corregir la codificación de la ruta del PNG.

Cambios físicos locales: cierres LowerLeftBoundary (X=0–8,Y=395–610) y LowerRightBoundary (X=1550–1570,Y=477–735) para impedir salir del recorrido inferior manteniendo entrada. Las pendientes anteriores permanecen simplificaciones de los escalones del arte; su ajuste estético fino sigue sujeto a revisión visual. No se modificaron físicas del Player.

Respaldo: C:/Users/juans/AppData/Local/GodotMCPCodex/tests/room2_stage_d/Room2.before.tscn; SHA256 68F4998D73AB84364FFF019C1B7C87D463CBDB9880B5BB68042FDD732754789C.

Pendiente para Etapa E: conexión bidireccional, marcadores definitivos y aplicación del estado de llegada. No hay transiciones, HUD añadido, narrativa, enemigos ni zonas de muerte. Los ensayos de plataformas comprobaron apoyo; el desplazamiento individual por toda su longitud queda pendiente. No se modificaron Player, otras salas ni sistemas globales.
