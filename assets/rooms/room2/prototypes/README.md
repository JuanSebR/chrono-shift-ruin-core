# Sala 2 — Etapa A

Diagnósticos a 1672 × 941; originales intactos, hashes en manifest.json.

A_original_v1.png y A_original_v2.png superponen fondo, midOverlay y plataformas sin transformaciones.
B_reference_approximation.png usa cinco recortes de plataformas trasladados sin deformación; coordenadas en manifest.json. Es un estudio, no una composición aprobada: quedan uniones duras y diferencias de arquitectura. No debe usarse como textura final.

Discrepancias: el montaje tiene una luna más centrada, engranaje lejano en otra posición, techo y pared derecha distintos, puente con proporciones y apoyos distintos, y suelos derechos escalonados que no existen así en las capas. Una transformación global no puede resolverlos. El overlay añade una cornisa horizontal y maquinaria diferentes. No se han inventado estructuras.

Recomendación: conservar V1 como candidato por su cielo abierto, sin repetirlo. V2 añade una torre dominante ausente de la referencia. Ambos requieren revisar cobertura de cámara; a escala 1:1 cubren 1672 × 941, sin margen adicional para parallax fuera de esos límites. La continuidad cromática es compatible con la atmósfera industrial, pero la continuidad jugada entre salas no está validada.

surfaces_reference.png marca candidatos sobre la referencia (cian: recorrido inicial; ámbar: alturas futuras). El desnivel puente/suelo y las uniones deben resolverse antes de colisiones. No son formas físicas definitivas.
player_scale_1to1.png muestra cajas de colisión 24 × 40 sobre A; no representa el contorno del sprite. La escala da protagonismo a la arquitectura y deja al personaje relativamente pequeño; aprobar visualmente antes de fijarla.

Para máxima fidelidad, hacen falta capas fuente del propio montaje o aprobar una adaptación: A es más consistente con los recursos actuales; B evidencia los límites de recomponerlos sin redibujar. No se recomienda construir colisiones sobre B todavía.

Sin cambios en escenas, scripts, cámara, Player, HUD, combate, transiciones o mecánicas. No se crearon colisiones ni Room2.tscn.
