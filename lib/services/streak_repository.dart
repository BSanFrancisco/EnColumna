import 'package:shared_preferences/shared_preferences.dart';

import '../models/difficulty.dart';

/// Guarda y lee, de forma local en el dispositivo con
/// [SharedPreferences], el récord de cada dificultad: la mayor
/// cantidad de cuentas resueltas seguidas y sin ningún error.
class StreakRepository {
  static const String _keyPrefix = 'multiplicaciones_columna.streak_record.';

  String _keyFor(Difficulty difficulty) =>
      '$_keyPrefix${difficulty.storageKey}';

  /// Devuelve el récord guardado para [difficulty], o 0 si todavía no
  /// se jugó ninguna cuenta en esa dificultad.
  Future<int> getRecord(Difficulty difficulty) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyFor(difficulty)) ?? 0;
  }

  /// Intenta guardar [candidateStreak] como nuevo récord de
  /// [difficulty]. Solo lo guarda si es mayor al existente. Devuelve
  /// true si se estableció un nuevo récord.
  Future<bool> tryUpdateRecord({
    required Difficulty difficulty,
    required int candidateStreak,
  }) async {
    final int existing = await getRecord(difficulty);
    if (candidateStreak <= existing) {
      return false;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyFor(difficulty), candidateStreak);
    return true;
  }

  /// Borra los récords de ambas dificultades. No se puede deshacer.
  Future<void> clearAll() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    for (final Difficulty difficulty in Difficulty.values) {
      await prefs.remove(_keyFor(difficulty));
    }
  }
}
