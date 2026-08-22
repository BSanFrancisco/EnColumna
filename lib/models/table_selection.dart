/// La selección de tablas ahora es un solo número: "hasta qué tabla"
/// se puede usar (2 a 10). Se pueden usar esa tabla y todas las
/// inferiores — por ejemplo, elegir "hasta la tabla del 5" habilita
/// las tablas del 2, 3, 4 y 5.
class TableSelection {
  TableSelection._();

  /// Las opciones que aparecen en el menú desplegable.
  static const List<int> options = <int>[2, 3, 4, 5, 6, 7, 8, 9, 10];

  /// Por defecto no hay restricción: hasta la tabla del 10 (todas).
  static const int defaultMaxTable = 10;

  /// Las tablas efectivamente habilitadas: [maxTable] y todas las
  /// inferiores, empezando en 2. En esta app nunca hace falta que la
  /// tabla del 10 coincida con ninguna cifra (las cifras que se
  /// multiplican al resolver una cuenta en columna siempre van de 0 a
  /// 9), así que elegir "hasta la tabla del 10" es lo mismo que no
  /// tener ninguna restricción.
  static Set<int> tablesUpTo(int maxTable) {
    return <int>{for (int t = 2; t <= maxTable; t++) t};
  }
}
