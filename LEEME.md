# Multiplicaciones en Columna

App nueva, separada de "Tablas de Multiplicar", con el mismo estilo visual
(colores, tipografía, fondo con degradado). Practica multiplicar un número
de 2 cifras por otro de 1 o de 2 cifras, resolviendo paso a paso como se
hace a mano en el papel.

## Cómo se juega

Hay un solo modo de juego. En la pantalla principal elegís una de las dos
dificultades. La cuenta se resuelve dígito a dígito, con llevadas, igual
que se hace a mano — por ejemplo, con 84 × 38:

- **Renglón de las unidades (× 8):** primero 4 × 8 = 32 → escribís el 2,
  y el 3 se muestra solo, en chiquito y en rojo, arriba del 8 de "84"
  (la llevada). Después 8 × 8 + 3 (la llevada) = 67 → escribís "67".
  Ese renglón queda en 672.
- **Renglón de las decenas (× 3), corrido un lugar:** el 0 de la derecha
  se completa solo. Primero 4 × 3 = 12 → escribís el 2 (se lleva 1,
  se muestra en rojo arriba del 8). Después 8 × 3 + 1 = 25 → escribís
  "25". Ese renglón queda en 2520.
- **Suma total:** 672 + 2520 → escribís 3192.

En **2 cifras × 1 cifra** es el mismo mecanismo pero con un solo renglón
(sin corrimiento ni suma final): por ejemplo con 23 × 6, primero 3 × 6 =
18 → escribís el 8 (se lleva 1), después 2 × 6 + 1 = 13 → escribís "13",
y queda 138.

La llevada (el numerito rojo arriba del factor) aparece solo mientras
hace falta tenerla en cuenta, y desaparece apenas se completa ese paso.

Cada cuenta resuelta sin ningún error suma 1 a la racha actual. Si te
equivocás en cualquier paso, la racha vuelve a 0 en el momento (se ve el
número bajar a 0 ahí mismo) y arranca una cuenta nueva. El récord (la
racha más larga que lograste) se guarda por separado para cada
dificultad, en el celular, sin necesidad de conexión ni de cuenta.

Arriba de la pantalla de juego hay dos indicadores: la racha actual (🔥) y
el récord de esa dificultad (🏆), más un botón para salir (con
confirmación, para no perder la racha sin querer).

## Supuestos que tomé (avisame si querés otra cosa)

- **Rango de números**: el primer factor siempre es de 2 cifras (10 a
  99). En el modo de 1 cifra, el segundo factor va de 2 a 9 (no incluí el
  1 ni el 0 porque son triviales). En el modo de 2 cifras, el segundo
  factor va de 10 a 99 (cualquier combinación, incluso con un 0 en las
  unidades).
- **Qué pasa al equivocarse**: se pierde la racha y arranca una cuenta
  completamente nueva (no se repite la misma), en cualquier paso en el
  que te equivoques (no solo al final). Se muestra brevemente cuál era
  la respuesta correcta de ese paso puntual.
- **Debajo del tablero hay un cartel que dice qué cuenta chiquita hay
  que hacer** (por ejemplo "Decenas: 8 × 3 + 1"), para que quede claro
  qué corresponde escribir en cada paso — no hace falta adivinar cuál
  cifra tocaba.
- **Sin límite de tiempo**: es un modo de precisión ("cuántas seguidas
  puedo hacer bien"), no de velocidad.

## Cómo armar el proyecto

Esta carpeta trae **todos los archivos de código** (`lib/`, la
configuración de Android, `pubspec.yaml`), pero no los archivos que
genera automáticamente `flutter create` (iconos por defecto, carpetas de
iOS/Linux/Windows si las quisieras, etc.). Para dejarlo andando:

1. Creá una carpeta nueva y vacía en tu PC, por ejemplo
   `C:\multiplicaciones_columna`.

2. Adentro de esa carpeta, corré (esto genera el "esqueleto" del
   proyecto Flutter, con el nombre de paquete correcto):

```
flutter create --org com.sebalima --project-name multiplicaciones_columna .
```

3. Ahora **pegá/reemplazá** todos los archivos y carpetas de este zip
   (`lib/`, `android/`, `pubspec.yaml`, `test/`) adentro de esa misma
   carpeta, sobrescribiendo lo que `flutter create` generó por defecto en
   esas rutas.

4. Compilá y probá:

```
flutter pub get
flutter run
```

(Si te pide activar el Modo de programador de Windows, es lo mismo de
siempre: `start ms-settings:developers`, activarlo, cerrar y abrir de
nuevo la terminal).

La configuración de Android (`android/`) ya viene con exactamente los
mismos ajustes que le hicimos funcionar a Tablas de Multiplicar (AGP
8.13, Gradle 8.14.5, Kotlin clásico, Impeller desactivado), así que no
debería hacer falta repetir ninguno de esos arreglos.

## Para más adelante (cuando quieras publicarla)

- Todavía no tiene ícono personalizado ni `key.properties`/keystore de
  firma — son los mismos pasos que hicimos con Tablas de Multiplicar
  (generar un `.jks` nuevo, o si querés lo vemos juntos).
- El paquete quedó como `com.sebalima.multiplicacionescolumna` — es un
  identificador nuevo y distinto al de Tablas de Multiplicar, así que en
  Play Console va a ser una ficha de app completamente aparte.
- No tiene versión web todavía; si la querés, es el mismo procedimiento
  que ya hicimos (`flutter build web`, GitHub Pages).

## Archivos incluidos

```
lib/
  main.dart
  app.dart
  models/
    difficulty.dart      (las 2 dificultades y sus reglas)
    problem.dart          (genera cada cuenta y sus pasos)
  services/
    streak_repository.dart (guarda los récords en el celular)
  screens/
    home_screen.dart       (elegir dificultad)
    game_screen.dart        (el juego en sí, con el formato en columna)
  theme/
    app_colors.dart         (misma paleta que Tablas de Multiplicar)
    app_theme.dart
  widgets/
    app_background.dart
    primary_button.dart
android/
  (configuración completa, lista para compilar)
pubspec.yaml
test/widget_test.dart
```
