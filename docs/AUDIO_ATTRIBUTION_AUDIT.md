# Auditoría de atribuciones de audio

Fecha de revisión: 17 de noviembre de 2026.

## Resultado

Se contrastaron siete fuentes candidatas de Freesound con los archivos locales mediante nombre, formato, duración, tamaño, frecuencia de muestreo, canales y comparación de forma de onda. Las previsualizaciones oficiales se decodificaron a PCM mono de 8 kHz para calcular correlación normalizada; este proceso tolera la compresión MP3 de la previsualización sin confundirla con una igualdad de archivos binarios.

| ID | Fuente | Autor | Licencia verificada | Correspondencia local | Resultado |
|---:|---|---|---|---|---|
| [878451](https://freesound.org/people/zenosounds/sounds/878451/) | Retro Laser Blaster | zenosounds | CC BY 4.0 | Ninguna | No coincide por duración, formato ni huella de audio. |
| [615812](https://freesound.org/people/flyingsaucerinvasion/sounds/615812/) | sci-fi-laser-blaster-shot-6 | flyingsaucerinvasion | CC BY 3.0 | Ninguna | No coincide con los efectos locales de jugabilidad. |
| [514022](https://freesound.org/people/newlocknew/sounds/514022/) | blaster hit 1(Sytrus,rsmpl,multiprcsng)single.wav | newlocknew | CC BY 4.0 | Ninguna | No coincide con los efectos locales de jugabilidad. |
| [458358](https://freesound.org/people/DWOBoyle/sounds/458358/) | Footsteps-Tile-Stomp-08.wav | DWOBoyle | CC BY 4.0 | `landing.wav` | Confirmada: mismos parámetros y correlación 0,999999. |
| [676817](https://freesound.org/people/CogFireStudios/sounds/676817/) | glitchy arcade sfx tense | CogFireStudios | CC0 1.0 | `Enemy1_Sound.wav` | Confirmada: mismos parámetros y correlación 0,999896. El runtime actual no referencia el archivo. |
| [446383](https://freesound.org/people/HadaHector/sounds/446383/) | electric woosh | HadaHector | CC BY 4.0 | `Sword_slash.wav` | Confirmada: mismos parámetros y correlación 0,999999. |
| [816018](https://freesound.org/people/qubodup/sounds/816018/) | Footsteps w Clothes Loop | qubodup | CC0 1.0 | `FootSteps_MainC.wav` y `step_1/2/3.wav` | Confirmada: correlación 0,999984 con la fuente completa; los tres recortes superan 0,9984. |

Los candidatos 878451 y 676817 fueron comprobados directamente en sus páginas actuales: 878451 declara Attribution 4.0 y 676817 Creative Commons 0.

## Correspondencias y modificaciones

### Espada cronal

- Archivo: `assets/Sonidos/Efectos de sonido/Sword_slash.wav`.
- SHA-256: `5a62161b756024c1543612ba1755ad9c4c449d523a2a6a1191467f280b49bbda`.
- Fuente: “electric woosh” de HadaHector, CC BY 4.0.
- Parámetros coincidentes: 1,278 s, WAV PCM de 16 bits, mono y 48 kHz.
- Modificación local observada: cambio de nombre. No se detectó alteración del contenido de audio.
- La descripción de HadaHector declara que la obra remezcla sonidos CC0 e incorpora [“WOOSH WOBBLE.wav” de SkyernAklea](https://freesound.org/people/SkyernAklea/sounds/439941/), también CC BY 4.0. Ambos autores deben conservarse en la atribución.

### Aterrizaje

- Archivo: `assets/Sonidos/Efectos de sonido/landing.wav`.
- SHA-256: `1433ae68ac194ff4b4f1e91ae422f7ab60dce55573c70aeaeae89332ee92a6b0`.
- Fuente: “Footsteps-Tile-Stomp-08.wav” de DWOBoyle, CC BY 4.0.
- Parámetros coincidentes: 0,292 s, WAV PCM de 16 bits, mono y 96 kHz.
- Modificación local observada: cambio de nombre. No se detectó alteración del contenido de audio.
- Modificación declarada por el autor: normalización y eliminación de la mayor parte del ruido de fondo, sin otro procesamiento.

### Pasos

- Fuente local completa: `assets/Sonidos/Efectos de sonido/FootSteps_MainC.wav`.
- Fuente: “Footsteps w Clothes Loop” de qubodup, CC0 1.0.
- qubodup declara que editó en Audacity “Footsteps on Tile” de jtnewlin13, también CC0, y añadió movimiento de ropa/cuerpo.
- Modificaciones locales: cambio de nombre y extracción de tres fragmentos mono PCM:
  - `step_1.wav`: 1,34–1,62 s.
  - `step_2.wav`: 1,66–1,92 s.
  - `step_3.wav`: 2,00–2,29 s.
- La comparación no detectó un cambio material de ganancia.

### Fuente de enemigo no utilizada

- Archivo: `assets/Sonidos/Efectos de sonido/Enemy1_Sound.wav`.
- Fuente: “glitchy arcade sfx tense” de CogFireStudios, CC0 1.0.
- Parámetros coincidentes: 1,364 s, WAV PCM de 24 bits, estéreo y 48 kHz.
- Modificación local observada: cambio de nombre; no se detectaron cambios materiales de contenido.
- Ninguna escena o script de producción referencia actualmente este archivo y no se incorpora al PCK de Windows.

## Obligaciones para distribución

- Mantener las atribuciones a HadaHector, SkyernAklea y DWOBoyle junto con enlaces a las obras y a CC BY 4.0.
- Indicar los cambios de nombre, los recortes de pasos y las modificaciones declaradas por los autores.
- CC0 no exige atribución, pero se conservan créditos a qubodup, jtnewlin13 y CogFireStudios para trazabilidad académica.
- La música global y el ambiente anterior del menú continúan excluidos porque esta auditoría no verificó sus derechos.

Los avisos correspondientes están reflejados en `build/windows/AUDIO_CREDITS.txt`, `build/windows/THIRD_PARTY_NOTICES.txt` y el `README.md`.
