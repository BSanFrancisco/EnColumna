import 'package:shared_preferences/shared_preferences.dart';

/// Guarda y lee, local en el dispositivo, si el usuario quiere ver
/// las ayudas (el cartel que indica qué números tocan multiplicar o
/// sumar en cada paso). Por defecto están activadas.
class HintsRepository {
  static const String _key = 'multiplicaciones_columna.show_hints';

  Future<bool> getShowHints() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? true;
  }

  Future<void> saveShowHints(bool showHints) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, showHints);
  }
}
