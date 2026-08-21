import 'dart:math';

import 'difficulty.dart';

/// Qué representa un paso interactivo: el dígito de las unidades del
/// renglón (con llevada), el resto del renglón (decenas en adelante,
/// ya sin más llevada porque no quedan más cifras de factor1), o la
/// suma final de los dos renglones (solo existe cuando hay 2
/// renglones, en la dificultad de 2 cifras × 2 cifras).
enum StepKind { rowUnits, rowTens, finalSum }

/// Un renglón de la cuenta: multiplicar TODO factor1 (siempre de 2
/// cifras) por UNA sola cifra de factor2 (unidades o decenas de
/// factor2). Como factor1 siempre tiene 2 cifras, cada renglón se
/// resuelve en exactamente 2 pasos, igual que a mano en el papel:
///
/// 1. Unidades de factor1 × la cifra → se escribe el dígito de las
///    unidades del resultado; lo que sobra "se lleva".
/// 2. Decenas de factor1 × la cifra, más la llevada → se escribe
///    TODO el resto (puede ser de 1 o 2 dígitos), porque ya no quedan
///    más cifras de factor1 por multiplicar.
class ProblemRow {
  ProblemRow._({
    required this.factor1,
    required this.multiplierDigit,
    required this.shift,
    required this.unitsProduct,
    required this.unitsDigit,
    required this.carry,
    required this.restValue,
  });

  factory ProblemRow({
    required int factor1,
    required int multiplierDigit,
    required int shift,
  }) {
    final int unitsProduct = (factor1 % 10) * multiplierDigit;
    final int unitsDigit = unitsProduct % 10;
    final int carry = unitsProduct ~/ 10;
    final int restValue = (factor1 ~/ 10) * multiplierDigit + carry;
    return ProblemRow._(
      factor1: factor1,
      multiplierDigit: multiplierDigit,
      shift: shift,
      unitsProduct: unitsProduct,
      unitsDigit: unitsDigit,
      carry: carry,
      restValue: restValue,
    );
  }

  /// El factor de 2 cifras (siempre el mismo en toda la cuenta).
  final int factor1;

  /// La cifra de factor2 por la que se multiplica este renglón.
  final int multiplierDigit;

  /// 0 = renglón de las unidades. 1 = renglón de las decenas: va
  /// corrido un lugar hacia la izquierda, con un 0 agregado a la
  /// derecha (se completa solo, no hay que escribirlo).
  final int shift;

  /// Paso 1 de este renglón: lo que hay que escribir es el producto
  /// COMPLETO (unidades de factor1 × la cifra), por ejemplo 48 para
  /// "8 × 6". El sistema es el que separa automáticamente el dígito
  /// de las unidades (lo deja escrito en su lugar) de la llevada (la
  /// muestra en chiquito y en rojo).
  final int unitsProduct;

  /// El dígito de las unidades de [unitsProduct] (lo que efectivamente
  /// queda escrito en el renglón una vez separada la llevada).
  final int unitsDigit;

  /// Lo que "se lleva" hacia las decenas de factor1: se muestra en
  /// chiquito y en rojo, arriba de la cifra de las decenas de
  /// factor1, mientras se resuelve el paso 2 de este renglón.
  final int carry;

  /// Paso 2 de este renglón: el resto (decenas de factor1 × la
  /// cifra, más la llevada).
  final int restValue;

  /// Valor completo de este renglón, ya con el corrimiento aplicado.
  int get rowValue => (restValue * 10 + unitsDigit) * (shift == 0 ? 1 : 10);
}

/// Un paso interactivo dentro de la cuenta: hay que escribir
/// [expectedValue] para completarlo.
class ProblemStep {
  const ProblemStep({
    required this.kind,
    required this.rowIndex,
    required this.expectedValue,
  });

  final StepKind kind;

  /// A qué renglón pertenece (0 o 1). No se usa para [StepKind.finalSum].
  final int rowIndex;

  final int expectedValue;
}

/// Una cuenta de multiplicación en columna: los dos factores, sus
/// renglones, y la lista ordenada de pasos interactivos que hay que
/// completar para resolverla paso a paso, tal como se hace a mano.
class Problem {
  Problem._({
    required this.factor1,
    required this.factor2,
    required this.difficulty,
    required this.rows,
    required this.steps,
  });

  factory Problem({
    required int factor1,
    required int factor2,
    required Difficulty difficulty,
  }) {
    final List<ProblemRow> rows = _buildRows(factor1, factor2, difficulty);
    final List<ProblemStep> steps = _buildSteps(rows);
    return Problem._(
      factor1: factor1,
      factor2: factor2,
      difficulty: difficulty,
      rows: rows,
      steps: steps,
    );
  }

  /// Genera una cuenta nueva al azar. El primer factor siempre es de
  /// 2 cifras (10 a 99); el segundo depende de la dificultad elegida.
  ///
  /// [selectedTables] son las tablas que el usuario eligió practicar
  /// (ver pantalla principal): la cuenta generada garantiza que TODAS
  /// las multiplicaciones de un solo dígito que van a aparecer al
  /// resolverla paso a paso (cada cifra de factor1 por cada cifra de
  /// factor2) tengan al menos una de las dos cifras dentro de
  /// [selectedTables]. Así el usuario nunca se topa, en medio de una
  /// cuenta, con un cálculo chico de una tabla que no eligió
  /// practicar.
  factory Problem.random(
    Difficulty difficulty,
    Random random, {
    required Set<int> selectedTables,
  }) {
    // Encontrar una combinación válida es aritmética simple y
    // normalmente se logra en pocos intentos, pero por las dudas hay
    // un límite: si la selección de tablas hiciera imposible cumplir
    // la restricción (por ejemplo, si quedó seleccionada solo la
    // tabla del 10, que nunca coincide con ninguna cifra de 0 a 9),
    // se usa igual la última combinación generada, para no trabar el
    // juego esperando algo que nunca va a pasar.
    const int maxAttempts = 3000;
    int factor1 = 10 + random.nextInt(90);
    int factor2 = difficulty.randomSecondFactor(random);
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      if (_isAllowedByTables(factor1, factor2, difficulty, selectedTables)) {
        break;
      }
      factor1 = 10 + random.nextInt(90); // 10..99
      factor2 = difficulty.randomSecondFactor(random);
    }
    return Problem(factor1: factor1, factor2: factor2, difficulty: difficulty);
  }

  /// Verdadero si, al resolver esta cuenta, cada multiplicación de un
  /// solo dígito que hay que hacer (una cifra de [factor1] por una
  /// cifra de [factor2]) tiene al menos una de las dos cifras dentro
  /// de [selectedTables] — exactamente lo mismo que evalúa a mano
  /// alguien decidiendo si "sabe" ese cálculo chico.
  static bool _isAllowedByTables(
    int factor1,
    int factor2,
    Difficulty difficulty,
    Set<int> selectedTables,
  ) {
    final int tensDigit = factor1 ~/ 10;
    final int unitsDigit = factor1 % 10;
    final List<int> multiplierDigits = difficulty == Difficulty.oneDigit
        ? <int>[factor2]
        : <int>[factor2 % 10, factor2 ~/ 10];
    for (final int d in multiplierDigits) {
      final bool unitsOk =
          selectedTables.contains(unitsDigit) || selectedTables.contains(d);
      final bool tensOk =
          selectedTables.contains(tensDigit) || selectedTables.contains(d);
      if (!unitsOk || !tensOk) {
        return false;
      }
    }
    return true;
  }

  final int factor1;
  final int factor2;
  final Difficulty difficulty;
  final List<ProblemRow> rows;
  final List<ProblemStep> steps;

  int get finalAnswer =>
      rows.fold<int>(0, (int sum, ProblemRow row) => sum + row.rowValue);

  static List<ProblemRow> _buildRows(
    int factor1,
    int factor2,
    Difficulty difficulty,
  ) {
    if (difficulty == Difficulty.oneDigit) {
      return <ProblemRow>[
        ProblemRow(factor1: factor1, multiplierDigit: factor2, shift: 0),
      ];
    }
    final int unitsDigit = factor2 % 10;
    final int tensDigit = factor2 ~/ 10;
    return <ProblemRow>[
      ProblemRow(factor1: factor1, multiplierDigit: unitsDigit, shift: 0),
      ProblemRow(factor1: factor1, multiplierDigit: tensDigit, shift: 1),
    ];
  }

  static List<ProblemStep> _buildSteps(List<ProblemRow> rows) {
    final List<ProblemStep> steps = <ProblemStep>[];
    for (int i = 0; i < rows.length; i++) {
      steps.add(
        ProblemStep(
          kind: StepKind.rowUnits,
          rowIndex: i,
          expectedValue: rows[i].unitsProduct,
        ),
      );
      steps.add(
        ProblemStep(
          kind: StepKind.rowTens,
          rowIndex: i,
          expectedValue: rows[i].restValue,
        ),
      );
    }
    if (rows.length > 1) {
      final int total =
          rows.fold<int>(0, (int sum, ProblemRow r) => sum + r.rowValue);
      steps.add(
        ProblemStep(kind: StepKind.finalSum, rowIndex: -1, expectedValue: total),
      );
    }
    return steps;
  }
}
