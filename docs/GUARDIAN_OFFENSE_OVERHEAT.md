# Guardián — ciclo ofensivo y sobrecalentamiento

Actualizado17/11/2026. Godot4.7.2. Sustituye al selector arco/haz y las dos etapas anteriores. Salud3, espada1HP por golpe, sin cambio de geometría, física o guardado. Ciclo actual45s/6s y anchos80px/32px: `GUARDIAN_FINAL_TUNING.md`.

## Ciclo actual

EncounterTrigger e introducción originales llaman una vez a start_combat_cycle. El jefe tiene un solo reloj físico para la ofensiva, sin umbral de salud ni fase2. La secuencia es:

| Tiempo desde inicio ofensivo | Acción |
|---|---|
|0–0,5s |Despegue con exit original, mirando hacia la derecha |
|0,5–1s |Pose aérea exit_repose; desplazamiento hasta quedar completamente fuera del viewport |
|1–40s |Fuera de pantalla, invulnerable; horizontal_laser/vertical_burst |
|40–41s |Regreso con retorn_repose, mirando a la izquierda |
|41–41,5s |Aterrizaje retorn original en plataforma lateral |
|41,5–44,25s |Proyectil directo900, aviso0,6s, vuelo máximo1,8s |
|44,25–45s |Apertura vulnerable original, todavía protegida |
|45–51s |Sobrecalentamiento: última pose original inmóvil, cuerpo expuesto solo en Presente |
|Tras51s, si sigue vivo |Cierre protegido con los seis cuadros originales de vulnerable en orden inverso,0,75s; siguiente ofensiva de45s |
|Salud0 |Derrota existente, sin otro ciclo; HUD, guardado y desbloqueo de Room5 |

El cierre de0,75s es recuperación visual protegida, adicional a los45s ofensivos y6s vulnerables. Se deriva del número de cuadros/FPS original; no prolonga la vulnerabilidad. No se usa retorn para levantarse: es una secuencia de aterrizaje y provocaba un cambio de postura inapropiado al salir del sobrecalentamiento.

El nodo raíz del jefe permanece en(1140,620). Solo VisualRoot recorre una curva suave entre offset(0,0) y(360,−120). No se mueven plataforma, colliders de escenario ni cámara. Al cancelar fuera de pantalla regresa suavemente durante1s, protegido; no se reposiciona bruscamente en su plataforma. La muerte del Player detiene el ciclo y conserva el reintento heredado.

## Preparación original de los ataques (histórico de16/11)

Esta sección conserva la preparación anterior a integrar los tres drivers. La implementación actual se describe en `GUARDIAN_THREE_ATTACKS.md` y `GUARDIAN_FINAL_TUNING.md`.

Se emite attack_slot_ready(kind,cycle_id) para los identificadores horizontal_laser, vertical_burst y direct_projectile. attack_slot_available comprueba el estado compatible. offensive_attacks_cancelled se emite al iniciar ciclo, abandonar el sector externo, abrir núcleo, detener ciclo, morir o liberar al jefe. Un futuro controlador deberá cancelar sus avisos, proyectiles y áreas al recibir esa señal, y comprobar ciclo/estado antes de causar daño.

**Ahora no se disparan láseres ni proyectiles.** Los nodos ofensivos anteriores permanecen estructuralmente en CoreGuardian.tscn, detenidos. No se reutilizan sus patrones como sustitución provisional ni se concede daño sin aviso. Las ventanas de conexión describen esta base; cuando se diseñe el proyectil habrá que evaluar si preparación, disparo y viaje caben antes del sobrecalentamiento. No se ha validado un patrón futuro dentro de ese intervalo.

## Recursos revisados y limitaciones exactas

Se mantienen fuentes y atlas originales, sin reconstruir arte ni cambiar proporciones:

- quieto_guardian.png: PNG RGBA1254×1254; representación de reposo adaptada al lienzo640×800 como en la integración anterior.
- starting:8 cuadros a8FPS, presentación de1s.
- exit:4 cuadros de impulso/despegue; exit_repose:1 pose aérea para continuar el desplazamiento.
- retorn_repose:1 pose aérea; retorn:4 cuadros de aterrizaje. No falta un recurso genérico de salida o regreso: existen estos recursos y se usan.
- vulnerable:6 cuadros a8FPS. La última pose representa el sobrecalentamiento y queda pausada6s. No se inventa una animación de calor o humo inexistente.
- defeated:7 cuadros originales; BossHUD conserva sus cinco cuadros de destrucción y tres segmentos de energía.
- Attack3:6 cuadros existentes; los cuadros finales4/5 (índices desde0) presentan recortes del cañón. No se usan ni se retocan aquí para afirmar que el nuevo proyectil directo está terminado. Su integración deberá resolver o aceptar explícitamente esa limitación.
- beam_start6 /beam_hold1 /beam_finish6: hay gráficos existentes del efecto horizontal. **No se identificó una secuencia corporal específica de disparo vertical ni un conjunto dedicado de ráfaga vertical.** Tampoco una secuencia independiente etiquetada como el nuevo proyectil directo distinto del Attack3 existente. No se simula su existencia ni se rota/deforma automáticamente arte para suplirlo.

La inspección visual conserva las diferencias anatómicas entre poses originales; no se promete una restauración artística. El movimiento continuo de VisualRoot no elimina esas diferencias de la fuente. Cada ataque futuro deberá tener su prueba de aviso→emisión→peligro→recuperación antes de habilitar daño. Esa sincronización no puede declararse probada para ataques que aún no están implementados.

## Núcleo y HUD

El área vulnerable es un rectángulo que abarca todo el cuerpo visible de la pose final de sobrecalentamiento, sin el margen transparente del atlas. Se duplica por instancia y se transforma con la escala y orientación del sprite: tamaño146,25×114px; mirando a la izquierda, centro(1161,375;566,375) y límites(1088,25;509,375)–(1234,5;623,375). El rectángulo se refleja cuando cambia la orientación del sprite. Cualquier parte del cuerpo recibe1HP por tajo en Presente durante los6s. Durante ofensiva, apertura, cierre y movimiento se deshabilita la forma y se rechaza daño por lógica. Se conserva el mismo objetivo, capa8 y deduplicación por tajo de la espada. No hay cuerpo sólido del jefe fuera de pantalla.

El apoyo Strike existente permite situarse alrededor de(1119,570) mediante saltos/Shift reales. Su espada tiene centro aproximado(1147,566), dentro del núcleo sin exigir un único píxel. No se cambia posición/forma de la espada ni daño. BossHUD lee máximo3 y conserva sus tres cámaras: cada golpe vacía una. Indicadores OFENSIVA/VULNERABLE; el texto completo de sobrecalentamiento se muestra en GuardianHint para evitar recorte del indicador pequeño.

## Pruebas realizadas

Nueva `tests/core_guardian_offense_overheat_test.gd`, ejecutada con APPDATA aislado y reloj60Hz:

- Progresión preparada solo antes de entrar; aproximación por movimiento/jump/Shift y trigger físico, sin arranque manual ni teletransportar durante la ruta.
- Llegada al apoyo Strike con cero recuperaciones; intro y BossHUD3/3.
- Rechazo de daño durante ofensiva/fuera de pantalla; forma vulnerable desactivada.
- Inicio de sobrecalentamiento a60s, posición de regreso exacta y pose estática; rectángulo alineado con el cuerpo completo.
- Pasado rechaza daño y la ventana termina a los360 pasos físicos,6s.
- Ventana completa sin golpes: escudos, cierre original y segundo ciclo60s, con salud3 intacta.
- Tres conexiones futuras notificadas una vez por ciclo y ausencia de efectos/hitboxes activos sin implementación.
- Segunda ventana: tres golpes reales desde el apoyo alcanzado físicamente, contador3→2→1→0 y victoria persistente v1 confirmada en disco.
- Derrota y destrucción únicas, salida libre; ningún reinicio tras0HP.
- Desplazamiento máximo medido de VisualRoot≈9,483px por paso físico, sin saltos de posición en el recorrido normal.

La prueba actualizada `room5_dimensional_layout_test.gd` también pasa: sustituye su fixture privado de la ventana antigua por un ciclo real60s/6s, conserva el recorrido de todas las plataformas, puertas Room4↔Room5, rechazo por ocupación, recuperación, activación y reinicio heredado con jefe3. El daño letal del Player en ese caso es una entrada controlada para comprobar reintento, no un ataque futuro simulado. validate.gd pasa.

`core_guardian_cycle_resume_test.gd` arranca otro proceso con el guardado de la victoria real anterior: confirma sala superada sin jefe visible, BossHUD ni trigger activo y con salida libre. Nueva Partida existente restablece la victoria y una instancia preparada de Room5 vuelve con3HP y trigger disponible. PASS; no se presenta ese fixture como recorrido de las primeras salas.

Los tests históricos H–K.2 de selector, etapas y tiempos antiguos son archivos de referencia del sistema retirado; no se presentan como una suite actual aprobada ni se borran para ocultar esas diferencias. La cobertura actual de este contrato son las dos pruebas anteriores. No se ejecutan ataques inexistentes para obtener un PASS artificial.

Se realiza además el recorrido completo con render1280×720, sin acelerar los relojes. Se revisan salida, regreso, postura vulnerable, cierre y derrota reales. La primera revisión detectó un indicador largo que salía de su caja; se sustituyó por VULNERABLE y se repitió el render. La ejecución headless puede conservar avisos ObjectDB/recursos al cerrar; se separan de errores de script/aserciones y no se declara corregida su causa.

La revisión de eventos también detectó que la entrada de aterrizaje se reiniciaba cada frame. Se corrigió la condición para entrar una sola vez en la animación y se añadió una aserción de avance por sus cuadros a58,4s, además de la captura03b_aterrizaje. Se repitieron la prueba headless y el render completo: ambos terminan con failures0/exit0. Los hashes y resultados finales constan en `artifacts/guardian_cycle60/verification.json`; las escenas y sistemas protegidos coinciden con los hashes previos.

Capturas en `artifacts/guardian_cycle60/`:01_pasivo,01b_salida_animada,02_fuera_de_pantalla,03_regreso,04_sobrecalentamiento,04b_cierre,05_golpe_1/2/3 y06_destruccion. Son estados de la prueba continua, incluida la primera ventana sin golpes y la segunda con victoria. Los eventos headless se conservan en events_headless.json y su log; las imágenes no son dibujos ni montajes.

## Integridad y entrega

Respaldo previo: `C:/Users/juans/chrono-shift-backups/guardian_cycle60_20261116_213646/`, con SHA-256. Se respaldan controlador, cableado Room5, HUD, escena HUD, prueba de layout y STATE antes de editarlos. Los originales del arte permanecen intactos. No se modifica Room5.tscn, Player, DimensionManager, LevelTransition ni GameProgress.

Se retiran las referencias de Room5 y HUD a señales/indicadores de segunda etapa. EncounterTrigger, intro, victoria K.2 y reintento conservan sus APIs. STATE señala el nuevo contrato. No se implementan el final narrativo ni los tres ataques; serán trabajos separados.
