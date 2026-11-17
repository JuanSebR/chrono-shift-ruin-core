# Exportación Windows de Chrono-Shift: Ruin Core

Preparada el 17 de noviembre de 2026 con **Godot4.7.2.stable.official.ed1daf0bf**, Windows Desktop **x86_64 Release**, PCK integrado. No se creó instalador ni se publicó o subió el juego.

## Entrega

| Archivo, bajo `build/windows/` | Tamaño |
|---|---|
| `Chrono-Shift_Ruin_Core.exe` | 159.810.864 bytes, 159,81MB / 152,41MiB |
| `Chrono-Shift_Ruin_Core_Windows_x86_64_Release.zip` | 82.712.074 bytes, 82,71MB / 78,88MiB |

El ZIP contiene una carpeta `Chrono-Shift_Ruin_Core` con el ejecutable, `LEEME.txt`, `GODOT_LICENSE.txt` y `THIRD_PARTY_NOTICES.txt`. Se validó el CRC del ZIP y que su ejecutable coincide por SHA-256 con el entregado fuera del ZIP.

El único archivo necesario para ejecutar el juego es el `.exe`; escenas, sprites, animaciones, música, efectos, shaders y recursos están dentro de él. No requiere Godot instalado, Python ni .NET. Las bibliotecas cargadas durante la prueba reubicada pertenecen a Windows y su controlador gráfico; no se encontraron dependencias de `C:\Godot`, del proyecto ni de las herramientas del desarrollador. Los textos de licencias deben acompañar la distribución, según la [documentación de licencias deGodot](https://docs.godotengine.org/en/4.7/about/complying_with_licenses.html).

SHA-256:

- EXE: `29a970ab3a8139cf4c3ee406045bbf42515f2c3c68fd2e1db7c40521f3ccda20`.
- ZIP: `a323f863ff4253739359e3a84d8d15feba725bc28276a9dfa152364d4d4c5bf1`.

## Exportación y plantilla

El arranque original se conserva en `res://scenes/MainMenu.tscn`. `export_presets.cfg` define Windows Desktop Release, arquitecturax86_64, PCK integrado, sin consola auxiliar, sin firma digital y con exportación de soporteD3D12 habilitada. Se conserva el renderer Forward+ y `rendering_device/driver.windows="d3d12"` del proyecto.

No había plantillas instaladas. Se obtuvieron los tres miembros necesarios (`version.txt`, ejecutable Release64 y su wrapper de plantilla) del [archivo oficial de plantillas4.7.2](https://godotengine.org/download/windows/), usando lecturas parciales del ZIP. No fue necesario descargar todos sus1,28GB. Cada miembro se verificó por longitud y CRC32, y se registró suSHA-256. `version.txt` declara `4.7.2.stable`; el códigoPE `.text` del ejecutable final coincide con el de la plantilla oficial Release. Se verificó PE32+ y máquinaAMD64(0x8664).

El soporte para [PCK integrado y arquitecturaWindows](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_windows.html) corresponde al exportador de esta versión. El PCK ocupa50.642.212bytes y usa formato4. Sus484 entradas se verificaron por MD5; contiene el recursoJSON de coordenadas de animación que el Guardián necesita en ejecución.

## Aislamiento y exclusiones

`tools/release/build_windows.py` construye una carpeta nueva fuera del proyecto, recopila249 archivos de ejecución y sus recursos importados, y exporta desde allí. Resuelve referencias de escenas/recursos y añade las carpetas de imágenes que se cargan mediante rutas construidas en ejecución. Se utilizan perfilesAPPDATA temporales también durante importación y exportación.

En esa copia exclusivamente:

- Se deshabilita la lista de plugins del editor, sin copiar addons.
- Se retira la rama de argumento `--room5-manual-diagnostic` que desactiva el encuentro.
- Se retira la excepción de checkpoints basada en `CHRONOSHIFT_ROOM5_PROFILE`, para que una variable de desarrollo no inhiba el guardado de un jugador.

No se altera la introducción normal del Guardián: el método interno `play_diagnostic("starting")` también se usa para esa animación y permanece disponible internamente. No constituye un acceso de práctica para el jugador.

No se copian ni empaquetan `tools/`, `tests/`, `addons/`, `.agents/`, `.codex/`, `docs/`, `backups/`, `artifacts/`, configuracionesMCP, credenciales, perfiles o partidas. Tampoco se incluye el M4A original de96min, scripts de conversión, logs o referencias gráficas ajenas a la ejecución. La músicaOGG de3min sí está dentro del paquete. El análisis directo del PCK confirmó cero rutas prohibidas y ausencia de la escena/controlador de prácticaF9.

La plantilla oficial Release bloquea overrides de escenas externas; `--script` no permite ejecutar los arneses del editor. Las herramientas de desarrollo no están disponibles para el jugador. F9 no modifica la escena ni el progreso.

El proyecto original conserva `Probar-Sala5.cmd`, su controlador y sus perfiles aislados, los scripts originales y el plugin del editor. No se modificaron mecánicas, enemigos, plataformas, geometría, física, gráficos, audio original, narrativa ni lógica de guardado del proyecto de desarrollo.

## Pruebas y alcance

El ejecutable entregado se copió a una carpeta ajena al proyecto y se inició directamente, sin editor, sin `--path` al proyecto y, en el arranque automático, con PATH limitado aWindows. Arrancó con Direct3D12/Forward+ en NVIDIA GeForce GTX1660SUPER y mostró el menú. Se revisaron los módulos cargados: solo el propio ejecutable quedaba fuera de los directorios deWindows.

Sobre el **EXE distribuible**, mediante controles de ventana y perfilesAPPDATA aislados, se comprobó:

- Enter en Nueva Partida creó el v1 inicial con checkpoint deTutorial, sin equipo ni victoria.
- F9 conservó el mismo archivo de progreso y no activó práctica.
- Tras cerrar y abrir un proceso diferente, Enter en CONTINUAR mantuvo el checkpoint y el guardado sin crear una rotación de Nueva Partida. La interacciónE con el tutorial reanudado guardó `completed_dialogues.awakening=true`, confirmando que había cargado la sala.

Windows Computer Use permitió teclado y lectura del estado de la ventana, pero la captura de imagen falló con `FrameArrived timed out` y `window capture timed out`. No se atribuye a esa herramienta una inspección visual que no pudo realizar.

Para las pruebas instrumentadas se generó **otro EXE Release de validación**, conservado exclusivamente en el respaldo. Añade un autoload de pruebas que controla inputs y observaciones; no se distribuye. Se cotejaron los archivos comunes de ambos PCK: todos los scripts, escenas y recursos del juego coinciden porSHA-256. Las únicas diferencias entre archivos comunes son `project.binary` y el registroUID por el autoload adicional. El ZIP final se auditó por separado y no contiene ese autoload ni archivosQA.

| Verificación | Resultado |
|---|---|
| Exportación e importación de producción | PASS; salida0, sin errores de exportación ni recursos faltantes |
| Arranque directo del EXE reubicado | PASS; menú, D3D12 y módulos del sistema |
| Nueva Partida, cierre y CONTINUAR por teclado en EXE distribuible | PASS; perfil aislado y diálogo del tutorial persistido |
| Suite de checkpoints sobre Release de validación | PASS128/128: siete salas, retroceso, spawn seguro, muerte, Shift, fallos de disco, v1, victoria y final |
| Continuación en frío a Sala5 | PASS; procesos distintos15432/3192, checkpoint tras transiciónRoom4→Room5, equipo conservado y jefe pasivo |
| Auditoría de ejecución Release | PASS; sin editor/debug, práctica ausente, F9 inactivo y argumento diagnóstico sin efecto |
| Música y botón CONTINUAR empaquetados | PASS; OGG a−18dB y bucle activo, textura original |
| Combate Release con movimiento/saltos/Shift reales | PASS50 comprobaciones; tres ataques, ofensiva45s, apertura vulnerable6s, 3HP y tres tajos de1HP |
| Victoria y cierre | PASS; victoria persistente, E aFinalRoom y botón de regreso al menú |
| Validación general del proyecto de desarrollo | PASS; `tests/validate.gd`, salida0 |
| Integridad del PCK y ZIP | PASS;484 entradas verificadas, cero rutas prohibidas, ZIP sin erroresCRC |

La prueba del combate utiliza fixtures de inicio para preparar el perfil y acercamiento, y después inputs normales durante el recorrido y los tres tajos. No se presenta como una partida humana completa desde el tutorial. La primera captura del arnés conservaba su menú inicial; se corrigió la preparación de la prueba y se repitió el combate y la revisión visual. Esto no modificó el ejecutable distribuible.

Capturas tomadas por el renderer del EXE Release de validación, usando los mismos recursos del juego: [menú](../artifacts/windows_release/01_menu_release.png), [sobrecalentamiento](../artifacts/windows_release/06_sobrecalentamiento.png), [final](../artifacts/windows_release/08_final.png) y [agradecimiento](../artifacts/windows_release/09_gracias.png). El resto de ataques y resultados están en `artifacts/windows_release/`.

## Guardados y seguridad

La distribución no contiene partidas. Cada jugador utiliza su propia ruta normal deGodot:

`%APPDATA%\Godot\app_userdata\ChronoShift_RuinCore\progress_v1.json`

No se activó un directorio de guardado portátil ni se cambió el nombre del proyecto. Los perfiles temporales de prueba reproducen esa estructura bajo un APPDATA aislado. Principal y `.bak` reales se compararon contra el respaldo medianteSHA-256 y permanecen intactos.

Los logs, EXEQA, perfiles, capturas y evidencias se conservaron fuera del ZIP. No se publicó el archivo ni se inició ningún instalador.

## Límites encontrados

- Solo se probó este equipo. La exportación requiere Windows10/11 de64bits, CPU conSSE4.2 y GPU/controladorD3D12 con nivel12_0. Son requisitos del renderer conservado, basados en la [documentación de requisitos deGodot4.7](https://docs.godotengine.org/en/4.7/about/system_requirements.html#desktop-or-laptop-pc-minimum); no se garantiza el rendimiento en hardware distinto.
- El ejecutable está **sin firma digital** (`NotSigned`); no se proporcionó un certificado. No se alteraron ajustes de seguridad deWindows.
- El cierre automático de la prueba de arranque con `--quit-after` mostró avisos de4 instanciasObjectDB y2 recursos todavía en uso, con salida0. Coinciden con el aviso de cierre de reproducciónOgg diagnosticado en las pruebas de audio; no fueron errores de exportación o archivos ausentes. Las pruebas con parada explícita del audio finalizaron sin esos avisos. Se conserva la lógica de audio original.
- La capturaWindows de la ventana distribuible no funcionó; la evidencia visual disponible corresponde a la validaciónRelease instrumentada, descrita arriba.

## Respaldo y reproducción de la exportación

Respaldo e información técnica: `C:\Users\juans\chrono-shift-backups\windows_release_20261117_154250`. Contiene originales conSHA verificado, inventarios, las plantillas oficiales, la copia de exportación, logs, pruebas y perfiles temporales.

Para reconstruir, utilizar una carpeta de trabajo **nueva** y fuera del proyecto:

```powershell
python tools/release/build_windows.py --work C:\Users\juans\chrono-shift-backups\windows_release_rebuild --templates C:\Users\juans\chrono-shift-backups\windows_release_20261117_154250\templates
python tools/release/audit_pck.py build/windows/Chrono-Shift_Ruin_Core.exe --report C:\ruta\pack_audit.json
```

Usar el builder conserva las exclusiones y transformaciones de Release sin tocar el desarrollo. El ZIP se arma únicamente con el EXE y los tres textos de la entrega; no comprimir la carpeta del proyecto.

Archivos añadidos al proyecto: `export_presets.cfg`, `tools/release/build_windows.py`, `tools/release/audit_pck.py`, este informe, evidencias y archivos de `build/windows/`. Se actualizó `docs/STATE.md`. Los archivos de producción existentes mantienen sus hashes anteriores.

Detalle de pruebas, inventario del paquete, hashes y perfiles de validación: [verification.json](../artifacts/windows_release/verification.json). Si se agregan recursos nuevos con rutas construidas dinámicamente, actualizar la lista `DYNAMIC` del builder y repetir la auditoría antes de distribuir otra versión.
