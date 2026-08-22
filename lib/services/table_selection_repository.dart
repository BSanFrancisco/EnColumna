import 'package:shared_preferences/shared_preferences.dart';

import '../models/table_selection.dart';

/// Guarda y lee, local en el dispositivo, hasta qué tabla eligió
/// practicar el usuario (ver [TableSelection]). Por defecto no hay
/// restricción: hasta la tabla del 10.
class TableSelectionRepository {
  static const String _key = 'multiplicaciones_columna.selected_max_table';

  Future<int> getMaxTable() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? stored = prefs.getInt(_key);
    if (stored == null ||
        stored < TableSelection.options.first ||
        stored > TableSelection.options.last) {
      return TableSelection.defaultMaxTable;
    }
    return stored;
  }

  Future<void> saveMaxTable(int maxTable) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, maxTable);
  }
}
