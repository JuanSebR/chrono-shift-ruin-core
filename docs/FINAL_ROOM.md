# Sala final — corrección visual

17/11/2026 · Godot4.7.2. Estado vigente: acceso invisible y sala final sin puertas. Sustituye la presentación inicial con puertas animadas.

## Acceso desde Sala5

`FinalAccessDoor.tscn` conserva únicamente el Area2D de interacción en(1190,620), su Shape80×110 y un Label. No tiene Sprite2D, AnimatedSprite2D, textura de puerta ni animación. La geometría, las plataformas, la cámara y la salida existente aRoom4 permanecen intactas.

Se mantiene el requisito de victoria persistida y la finalización de la presentación de derrota del jefe. Al acercarse aparece únicamente **E · SALIR**. E carga `FinalRoom.tscn` mediante cambio diferido de escena, sin esperar una animación y sin congelar la física del Player. Antes de la victoria no aparece el texto ni funciona E. La carga directa de FinalRoom sin victoria sigue devolviendo aRoom5.

## Personaje y superficie

Se eliminó `Stage/Door` de FinalRoom y todas las referencias a animaciones de entrada/cierre. El personaje es visible desde el inicio.

El fondo conserva su encuadre de1280×720. En X1000, la superficie superior del balcón está entre la barandilla y el canto frontal; Y500 correspondía a la cara vertical del canto. El anclaje pasa a **(1000,463)**, dentro de la superficie superior de ambos fondos. Se conserva la escala uniforme **0,27**, el offset **(-137,-422)** y las ocho poses originales de reposo a8FPS.

El borde inferior opaco de cada pose está enY562 de la hoja original, equivalente aY422 de la ventana recortada desdeY140. Ese borde coincide con el punto de apoyo en las ocho poses. No se redibujan pies ni se modifica el PNG. Stage sigue ajustándose proporcionalmente al viewport; el fondo y el personaje reciben la misma transformación. La prueba mide el anclaje usando los píxeles opacos de cada fotograma, además de inspeccionar el render.

## Secuencia sin puerta

| Tiempo | Presentación |
|---|---|
|0–1,25s|Personaje ya apoyado en el balcón del Presente|
|1,25–4s|Transición visual al Pasado y de vuelta al Presente|
|4–6,5s|Agradecimiento alternativo y transición al principal|
|Desde6,5s|Botón VOLVER AL INICIO disponible por clic o Enter|

Se elimina la espera inicial de0,75s asociada a la puerta. Se conservan los dos fondos originales, los dos agradecimientos, el botón y la vista Pasado/Presente mediante Shift al terminar. El botón vuelve aMainMenu. F9 conserva su comportamiento incluso desde FinalRoom; Nueva Partida y Continuar no cambian.

## Recursos

Inventario de los nueve archivos originales: `artifacts/final_room/asset_inventory.json`, generado durante la integración inicial. Las descripciones antiguas de uso de las puertas en ese inventario son históricas: **Door End, entrance Door End y exit Door End permanecen en assets pero ya no se cargan ni dibujan**. Se quitó la función de construcción de sus SpriteFrames.

`final_assets.gd` conserva los recortes AtlasTexture de los agradecimientos y botón, y los SpriteFrames del personaje con las mismas ocho regiones y pies alineados. Los fondos, imágenes y filtros nearest se conservan. Ningún sprite original fue sobrescrito.

## Verificación y capturas

- `guardian_three_attacks_test.gd -- --verify-ending-access`: combate45s, tres tajos de1HP, victoria legítima y E al final de ese mismo encuentro; transición directa sin puerta.
- `final_room_test.gd`: acceso bloqueado sin victoria, acceso desde victoria cargada, recorrido físico de saltos/Shift hasta el área, texto exacto E · SALIR, ausencia de puertas, transición inmediata, ocho poses con suelas alineadas, ambos agradecimientos, botón por clic/Enter, Continuar, Nueva Partida y F9.
- Renders independientes a **1024×572** y **1280×720**, en perfiles aislados. Capturas de Presente, Pasado y cierre en cada resolución.
- `tests/validate.gd`: validación de scripts y carga de ambas escenas.

Evidencia actual: `artifacts/ending_visual_fix/verification.json`. Capturas dentro de `artifacts/ending_visual_fix/1024x572/` y `artifacts/ending_visual_fix/1280x720/`:

- `02_solo_E_SALIR.png`: plataforma lateral sin puerta y texto de salida.
- `03_final_presente.png` y `04_final_pasado.png`: posición del personaje sin rótulos encima.
- `06_gracias_y_boton.png` y `07_final_pasado_con_boton.png`: cierre y botón conservados.

Respaldo previo: `C:/Users/juans/chrono-shift-backups/ending_visual_fix_20261117_140416`. Comparación SHA256 de los archivos protegidos y del guardado real con su .bak. Las pruebas usan inputs del motor y renderizado de Godot; no se presentan como una sesión humana.
