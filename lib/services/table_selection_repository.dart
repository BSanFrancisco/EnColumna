import 'package:shared_preferences/shared_preferences.dart';

import '../models/table_selection.dart';

/// Guarda y lee, local en el dispositivo, qué tablas eligió practicar
/// el usuario (ver [TableSelection]). Por defecto están todas
/// seleccionadas, es decir sin ninguna restricción.
class TableSelectionRepository {
  static const String _key = 'multiplicaciones_columna.selected_tables';

  Future<Set<int>> getSelected() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? stored = prefs.getStringList(_key);
    if (stored == null || stored.isEmpty) {
      return TableSelection.defaultSelected();
    }
    final Set<int> parsed = stored.map(int.parse).toSet();
    // Por las dudas quedó guardada alguna vez una selección vacía:
    // nunca se juega sin ninguna tabla elegida.
    return parsed.isEmpty ? TableSelection.defaultSelected() : parsed;
  }

  Future<void> saveSelected(Set<int> selected) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      selected.map((int t) => t.toString()).toList(),
    );
  }
}
