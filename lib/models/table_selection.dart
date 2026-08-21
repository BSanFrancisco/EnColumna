/// Las "tablas" que se pueden elegir para practicar, igual que en la
/// pantalla de selección de Tablas de Multiplicar: del 2 al 10. La
/// tabla del 10 queda incluida por mantener la misma pantalla, pero
/// en esta app nunca hace falta para que una cuenta sea válida: las
/// cifras que efectivamente se multiplican al resolver una cuenta en
/// columna siempre van de 0 a 9 (son dígitos), así que "10" nunca
/// puede coincidir con ninguna de ellas.
class TableSelection {
  TableSelection._();

  static const List<int> all = <int>[2, 3, 4, 5, 6, 7, 8, 9, 10];

  /// Selección por defecto: todas las tablas (sin ninguna
  /// restricción), igual que se comportaba la app antes de que
  /// existiera esta pantalla.
  static Set<int> defaultSelected() => Set<int>.from(all);
}
