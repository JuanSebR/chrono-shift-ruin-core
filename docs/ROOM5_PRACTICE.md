# Sala 5: acceso de pruebas local

## Abrir en Windows

1. Abre `C:\Users\juans\chrono-shift-ruin-core` en el Explorador.
2. Haz doble clic en **Probar-Sala5.cmd**.
3. Se abre una ventana independiente de Godot, titulada **SALA 5 DE PRUEBAS**.
4. Juega con los controles habituales: A/D o flechas, Espacio para saltar, Shift para cambiar de dimensión y J/clic izquierdo para atacar.
5. Pulsa **F9** para empezar otro encuentro desde la entrada, incluso después de ganar. También puedes cerrar la ventana y volver a abrir el lanzador.

Alternativa desde PowerShell:

```powershell
& 'C:\Users\juans\chrono-shift-ruin-core\tools\Start-Room5Practice.ps1'
```

Usa `C:\Godot\godot.exe.exe` (Godot 4.7.2). Si la instalación cambia, el script admite `-GodotPath 'C:\ruta\Godot.exe'`.

No requiere cerrar ni reconfigurar el editor. F5/F6 habituales siguen usando el perfil normal: el acceso aislado se inicia con este lanzador. Abrir directamente `tools/dev/Room5Practice.tscn` sin su entorno aislado cancela el acceso antes de escribir progreso.

## Estado inicial y reinicio

El acceso carga la escena de producción `Room5.tscn`, con su Player en el punto de entrada normal `(140, 600)`, 3 HP y Presente. Espada, Lente y Llave están desbloqueadas; los tutoriales están completados y `core_guardian_defeated=false`.

El Guardián espera quieto. Hay que cruzar EncounterTrigger mediante el movimiento normal para activar la introducción y el combate. El acceso no inicia la IA directamente ni cambia ataques, plataformas, HP o tiempos.

F9 guarda el estado inicial en el perfil de pruebas y vuelve a cargar la escena original. El reintento por muerte conserva su funcionamiento normal. La victoria se guarda mediante K.2 en este perfil, hasta pulsar F9 o iniciar otra sesión.

## Aislamiento del guardado

Cada apertura crea una carpeta nueva:

```text
%LOCALAPPDATA%\ChronoShiftDev\Room5\<identificador de sesión>\
  godot.log
  Roaming\Godot\app_userdata\ChronoShift_RuinCore\
    progress_v1.json
    progress_v1.json.bak
```

El lanzador configura APPDATA únicamente en el proceso hijo de Godot; no cambia variables del usuario, editor ni sistema. El controlador comprueba que `OS.get_user_data_dir()` coincide con el perfil declarado y está dentro de la carpeta de desarrollo, antes de iniciar y de cada reinicio. Si no coincide, termina con código 2 sin escribir progreso.

El guardado normal sigue en `%APPDATA%\Godot\app_userdata\ChronoShift_RuinCore`. No se copia, borra ni reemplaza. Todas las escrituras de progreso y rotaciones de `.bak` usan el `user://` aislado, a través de `GameProgress` sin modificaciones. Dos sesiones simultáneas tienen perfiles distintos. Las carpetas de pruebas se conservan para revisar logs; el acceso no elimina carpetas automáticamente.

## Verificación

`tests/room5_practice_test.gd` instancia el mismo acceso, pulsa F9 mediante eventos de entrada y recorre el combate con movimiento, salto y Shift del Player real. Comprueba la escritura de una victoria de prueba y su `.bak`, el reinicio posterior, la activación natural, los tres ataques, el ciclo actual45s/6s y otro reinicio durante la ofensiva. La comprobación de17/11/2026 exige2700 fotogramas ofensivos y360 vulnerables a60Hz; véase `GUARDIAN_FINAL_TUNING.md`.

Resultado del 16 de noviembre de 2026: **PASS**, tanto headless como renderizado a 1280×720 con Godot 4.7.2. El recorrido usa inputs del Player, sin iniciar la IA por API, teletransportar al jugador ni alterar tiempos. Los dos reinicios F9 pasan: tras una victoria guardada de prueba y durante la ofensiva siguiente. La prueba automatizada con renderizado no sustituye la valoración humana del combate.

Evidencia local en `artifacts/room5_practice/`:

- `result.json` y `test.log`: cero fallos, 3600 fotogramas de ofensiva y 360 de vulnerabilidad a 60 Hz; tres inicializaciones del acceso.
- `01_entrada.png` y `07_reinicio_F9.png`: escena renderizada antes y después de reiniciar.
- `validate.log`: validación de scripts PASS; se utilizó el ejecutable disponible `C:\Godot\godot.exe.exe`, pues la ruta de Downloads indicada en AGENTS es una carpeta.
- `guard.err` y `outside.err`: rechazos deliberados del arranque sin aislamiento, código 2; ninguna escritura de progreso en esos casos.
- `integrity.json`: SHA256 sin cambios de los archivos de producción revisados, del guardado real y de su `.bak`.

Respaldo previo: `C:\Users\juans\chrono-shift-backups\room5_practice_20261116_225532`. Solo se añadió el acceso de desarrollo, su prueba y documentación; `docs/STATE.md` tiene una nueva referencia al acceso.
