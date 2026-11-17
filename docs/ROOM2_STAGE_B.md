# Sala 2 — Núcleo de Enlace: etapa B

Escena visual: `scenes/Room2.tscn`. Imagen original 1672 × 941, escala (1,1), origen (0,0), Sprite2D sin centrado y filtro nearest. No tiene scripts, cámara, Player, colisiones ni transiciones activas.

Se conservan las zonas negras opacas del montaje. BackgroundVisual tiene z=-20 y ForegroundVisual z=10. WorldCollision contiene cinco Node2D vacíos: LowerFloor, CentralBridge, SteppedPlatforms, Walls y FutureElevatedRoutes.

Validación: carga, dimensiones, escala, origen y ausencia de formas físicas PASS. tests/validate.gd PASS. Hashes de ROOM1, ROOM1.5, Player.gd, project.godot y PNG original idénticos antes/después.

Capturas reales Godot OpenGL en `C:/Users/juans/AppData/Local/GodotMCPCodex/tests/room2_stage_b/render_0.png` a `render_3.png`: superior izquierda, superior derecha, inferior izquierda e inferior derecha. SubViewport de prueba 1024 × 572 con transformación equivalente al zoom 1,14 del Player; cobertura aproximada 898,25 × 501,75 unidades. Son renders del motor, sin alterar la cámara real. La cámara futura deberá limitar su cobertura al rectángulo del arte; la escena visual todavía no impone límites de cámara. Las vistas inferiores contienen negro deliberado del original, no huecos de transparencia.

Profundidad futura: candidatos a máscaras derivadas son columnas laterales, pilares del puente y cables superiores. Antes de separar una región, definir su relación con la ruta del Player y revisar si ocultaría su cuerpo o el borde de una plataforma. Las paredes y máquinas derechas deben permanecer detrás salvo aprobación concreta. No se generaron máscaras en esta etapa.

Reversión: retirar solamente Room2.tscn y este documento; las escenas anteriores no tienen referencias a Room2.
