# Música de fondo global

> **Nota de distribución pública:** la pista global y su fuente no se incluyen en el repositorio público porque su autoría o licencia no pudieron verificarse. Este documento conserva el registro técnico local; no concede derechos de redistribución sobre el audio.

Implementada el 17 de noviembre de 2026 con Godot 4.7.2. Una sola pista acompaña menú, salas y cierre del juego, sin reiniciarse en transiciones, reintentos ni F9.

## Original y fragmento

Se encontró el archivo proporcionado en `assets/Sonidos/Cancion/videoplayback.m4a`: AAC estéreo, 44.100Hz, 5787,434376s (96min27s), 93.663.968 bytes. El original se conserva intacto, con SHA-256 `dbbd1562f2a8e2dcb6d64c69238edf467cd8f82dfffa1e6ed2f4e226a895da1b`.

El recurso utilizado es `assets/Sonidos/Cancion/derived/global_background_loop.ogg`, de **180s exactos**, estéreo a44.100Hz, Vorbis calidad5, 2.968.622 bytes. Se emplean los segundos60–248 del original, cruzando los ocho segundos finales con los ocho iniciales mediante un fundido de potencia constante. El fragmento central enlaza con esa mezcla y vuelve a su inicio mediante muestras contiguas. No hay silencios añadidos ni un fade-out a silencio en cada vuelta.

Se aplicó una ganancia global de0,951 para mantener margen de pico durante la mezcla; no se añadió compresión dinámica ni se alteró el original. Después de codificar y decodificar el OGG: 7.938.000 muestras por canal, pico0,906613, sin clipping ni segundos silenciosos. La diferencia de muestras en la unión es0,010188, por debajo del percentil99,9 de las diferencias normales de la propia señal(0,242282).

`tools/audio/build_global_music.py` permite reproducir la conversión con el FFmpeg y NumPy ya disponibles. No instala paquetes y no es una dependencia del juego en ejecución:

```powershell
python tools/audio/build_global_music.py --report C:\ruta\audio_build.json
```

## Integración y volumen

Se añadió `BackgroundMusic="*res://scripts/audio/background_music.gd"` al autoload existente del proyecto. Su nodo es un `AudioStreamPlayer` en la raíz, fuera de las escenas que se reemplazan. Configura `loop=true`, `loop_offset=0`, `max_polyphony=1`, `process_mode=ALWAYS` y **`volume_db=-18.0`**, y llama a `play()` una sola vez en `_ready()`.

El grupo `core9_global_music` impide que una instancia accidental adicional llegue a reproducir audio. No hay temporizadores ni llamadas de reproducción al cambiar de sala. El estado de la canción no se guarda en disco; al abrir un proceso nuevo empieza normalmente desde el principio.

Se retiró únicamente `MainMenu/MenuMusic` y su referencia de escena a `login_ambient.ogg`; el archivo antiguo permanece intacto. No se modificó el controlador visual del menú ni sus botones. El árbol de cambio se limitó al nuevo autoload y a eliminar el reproductor local.

Ya existían los buses `Music` y `SFX`, ambos a0dB con salida a `Master`. Se reutilizan sin modificar `default_bus_layout.tres`. La música utiliza `Music`; los efectos del Player utilizan `SFX`. Sala2.2 sobrescribía sus tres asignaciones de pasos, aterrizaje y espada a `Master`: ahora esas tres propiedades apuntan a `SFX`, sin cambiar sus streams, niveles, tiempos ni nodos físicos. El control de volumen general existente sigue actuando sobre `Master`.

## Pruebas

Se ejecutó `tests/global_music_test.gd` tanto headless/Dummy como con ventana1280×720 y dispositivo de audio real **WASAPI**: **114 comprobaciones PASS, 0 fallos en cada ejecución**. Se reutilizan los helpers de transición/input del test de checkpoints, con un `run()` propio y perfiles aislados.

Se verificó:

- Inicio automático de una única voz, OGG de180s, −18dB, busMusic y reproducción durante pausa.
- Rechazo de una instancia duplicada antes de reproducir.
- Identidad del mismo nodo y playback al abrir opciones, cambiar seis salas hacia adelante y seis hacia atrás, recargar la sala, entrar al final, volver al menú e iniciar/reiniciar F9.
- Las tres salidas SFX del Player en todas las salas recorridas, incluida Sala2.2.
- Audio no silencioso en la mezcla real. Con SFX silenciado, la música sigue presente; con Music silenciado, el soundtrack desaparece deMaster.
- Cruce real del final del OGG con aumento del contador de bucles, sin detener la canción. Para no esperar tres minutos, el test hace un `seek()` previo cerca del final. Ese seek recrea el playback según el funcionamiento deGodot; el test toma su nueva referencia y después vuelve a verificar la continuidad. Las transiciones ordinarias no utilizan seek ni recrean la voz.

La captura WASAPI del cruce dura2,784s a48.000Hz (frecuencia del mezclador deWindows), con pico0,074646, RMS mínimo en ventanas de20ms de0,004980, **cero ventanas silenciosas y cero muestras consecutivas de silencio exacto**. El RMS inicial medido enMaster fue0,012700; al silenciarMusic fue0; al silenciarSFX, Music conservó RMS0,014539.

La captura está disponible en [loop_seam_wasapi.wav](../artifacts/global_music/loop_seam_wasapi.wav). Es audio tomado del mezclador del juego a su nivel real, no una simulación del resultado. La continuidad se verificó mediante captura y análisis de señal; no se atribuye una valoración auditiva humana a estas pruebas.

Regresiones ejecutadas con APPDATA aislado:

| Prueba | Resultado |
|---|---|
| `tests/global_music_test.gd`, WASAPI y headless | PASS114/114 cada una |
| `tests/progress_menu_test.gd` | PASS: música global, opciones, continuación v1 y Nueva Partida |
| `tests/room_checkpoint_test.gd` | PASS128/128; conserva guardados, final y F9 |
| `tests/validate.gd` | PASS: validación de sintaxis, salida0 |

El test del menú se adaptó para esperar música persistente y en bucle. La validación general ahora se difiere hasta que los autoloads están listos y detiene el audio antes de su salida headless inmediata, dejando100ms para liberar la vozOgg. No se modifica la lógica de compilación ni el audio de producción. Los errores de disco/marcador/destino del test de checkpoints son inyecciones negativas esperadas.

Para la importación del nuevo OGG se utilizó `--headless --editor --import --recovery-mode`, con APPDATA aislado; el modo de recuperación evita ejecutar plugins durante esa importación y no cambia su configuración. Para validar se utilizó `C:\Godot\godot.exe.exe`; la ruta deDownloads indicada enAGENTS corresponde a una carpeta, no a un ejecutable.

## Archivos y respaldo

Respaldo previo verificado por SHA-256: `C:\Users\juans\chrono-shift-backups\global_music_20261117_152453`. Incluye originales, `backup_manifest.json`, inventarioSHA de fuentes y guardados reales, audio de trabajo, informe de conversión, perfiles/logs y `Run-Audio.ps1` para repetir las pruebas con perfiles nuevos aislados.

Archivos de producción modificados: `project.godot` (un autoload), `scenes/MainMenu.tscn` (solo el reproductor local) y `scenes/Room2_2.tscn` (tres propiedades de bus).

Archivos nuevos: `scripts/audio/background_music.gd`, `tools/audio/build_global_music.py`, `tests/global_music_test.gd`, el OGG derivado y su importación, este informe y `artifacts/global_music/` con pruebas/captura. Se actualizaron `tests/progress_menu_test.gd`, `tests/validate.gd` y `docs/STATE.md`.

No se modificaron Player, GameProgress, transiciones, combate, física, plataformas, geometría, fondos, sprites, final ni el modo de prácticas. El cotejo deSHA-256 conserva el M4A, los efectos originales, el audio anterior del menú y el layout de buses. Los guardados reales principal y `.bak` mantienen sus hashes anteriores. El editor se comprobó sin cambios pendientes antes del respaldo.

Resultados y hashes: [verification.json](../artifacts/global_music/verification.json). No quedan fallos funcionales encontrados dentro de este alcance.
