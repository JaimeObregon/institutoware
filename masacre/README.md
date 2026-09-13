# Conservación de Masacre en el instituto

La copia local D es la base más completa: contiene los 110 ficheros de B,
idénticos byte a byte, y otros 15. Sus ejecutables y los 23 ficheros de la
distribución son idénticos a los que ya estaban publicados aquí.

Se han incorporado los fuentes `MASACRE.PAS`, `JUEGO.PAS`, sus unidades e
inclusiones, así como gráficos de trabajo, sonidos, música, documentación,
demostraciones y auxiliares de desarrollo. Se conservan los bytes originales,
incluida la codificación de MS-DOS. Los ejecutables publicados no cambian.

## Copias anteriores y duplicados

- C contiene los mismos 121 ficheros compartidos con D y una carpeta
  `backup/a/` de 72 ficheros. Se comprobó que esos 72 ficheros son exactamente
  los contenidos en `backup/A.ARJ`, que se conserva como respaldo original.
  C no aporta una versión posterior del juego.
- `backup/A.ARJ` conserva versiones anteriores de `JUEGO.PAS`, `JUEGO.EXE`,
  `MASACRE.EXE`, `MASACRE.TXT`, `SPRITES1.VGA` y `TIEMPOS.PRG`, entre otros
  auxiliares. No deben sustituir a los ficheros principales.
- A es una copia parcial de 1998. Sus siete ficheros con contenido único
  se conservan en `_archive/1998/`; el resto ya está en este directorio o
  en el respaldo. Esa carpeta de siete variantes no es una distribución
  autónoma del juego.
- La subcarpeta local `game/` repetía nueve ficheros ya conservados aquí.
  Los 17 ficheros de `intro/INTRO.ARJ` y los 23 de `helios/ELIOSGAY.ARJ`
  también coincidían exactamente con la distribución publicada. Se omiten
  esas copias redundantes. Se conserva la nota original `helios/LEEME.YA!`.

## Fechas y alcance

Las fechas uniformes de B (2005) y C (2006) corresponden a copias: su
contenido compartido es idéntico al de D, que conserva fechas anteriores.
Para los nuevos ficheros se usa la fecha más antigua encontrada entre
ejemplares de contenido idéntico, incluidos los originales dentro de ARJ.
Existen desfases horarios entre copias; estas fechas no acreditan por sí
solas el momento exacto de programación.

La comparación verificó contenidos mediante SHA-256 y la extracción íntegra
de los ARJ. No se ha recompilado el fuente ni se afirma que genere
exactamente los ejecutables conservados. Las fechas de `JUEGO.PAS` y de
`JUEGO.EXE` son distintas, por lo que el fuente recuperado es el más reciente
encontrado, pero no demuestra ser el utilizado para esa compilación.
