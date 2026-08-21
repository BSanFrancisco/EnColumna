import 'dart:math';

/// Los dos tipos de cuenta que se pueden practicar: multiplicar un
/// número de 2 cifras por un número de 1 cifra, o por otro número de
/// 2 cifras. Cada una tiene su propio récord guardado por separado.
enum Difficulty {
  oneDigit,
  twoDigits;

  /// Texto para mostrar en la pantalla principal.
  String get displayLabel {
    switch (this) {
      case Difficulty.oneDigit:
        return '2 cifras × 1 cifra';
      case Difficulty.twoDigits:
        return '2 cifras × 2 cifras';
    }
  }

  /// Ejemplo corto para mostrar debajo del título, ej. "Ej: 23 × 6".
  String get exampleLabel {
    switch (this) {
      case Difficulty.oneDigit:
        return 'Ej: 23 × 6';
      case Difficulty.twoDigits:
        return 'Ej: 23 × 15';
    }
  }

  /// Clave estable usada para guardar el récord en SharedPreferences.
  /// No cambiar estos valores una vez publicada la app: son la
  /// referencia con la que se busca el récord guardado.
  String get storageKey {
    switch (this) {
      case Difficulty.oneDigit:
        return 'one_digit';
      case Difficulty.twoDigits:
        return 'two_digits';
    }
  }

  /// Genera el segundo factor al azar según la dificultad: un solo
  /// dígito (2 a 9) o un número de 2 cifras (10 a 99). El primer
  /// factor siempre es de 2 cifras (10 a 99), ver [Problem.random].
  int randomSecondFactor(Random random) {
    switch (this) {
      case Difficulty.oneDigit:
        return 2 + random.nextInt(8); // 2..9
      case Difficulty.twoDigits:
        return 10 + random.nextInt(90); // 10..99
    }
  }
}
