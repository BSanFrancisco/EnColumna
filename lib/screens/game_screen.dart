import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/difficulty.dart';
import '../models/problem.dart';
import '../services/streak_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/primary_button.dart';

enum _Feedback { none, correct, incorrect }

/// Pantalla de juego: modo único, sin límite de tiempo. Se resuelven
/// cuentas de multiplicación en columna, dígito a dígito y con
/// llevadas, tal como se hacen a mano en el papel. Cada cuenta
/// resuelta sin errores suma 1 a la racha actual; apenas te equivocás
/// en cualquier paso, la racha vuelve a 0 y arranca una cuenta nueva.
/// El récord (racha más larga lograda) se guarda por separado para
/// cada dificultad.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.difficulty,
    required this.selectedTables,
    required this.showHints,
  });

  final Difficulty difficulty;

  /// Las tablas que el usuario eligió practicar en la pantalla
  /// principal (ver [TableSelection]). Cada cuenta que se genera
  /// respeta esta selección, ver [Problem.random].
  final Set<int> selectedTables;

  /// Si es falso, no se muestra el cartel que indica qué números
  /// tocan multiplicar o sumar en cada paso (elegido en la pantalla
  /// principal). El progreso "Paso X de N" se sigue mostrando: no es
  /// parte de la ayuda, solo indica cuánto falta.
  final bool showHints;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const Duration _feedbackDelay = Duration(milliseconds: 650);

  final Random _random = Random();
  final StreakRepository _repository = StreakRepository();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late Problem _problem;
  int _stepIndex = 0;
  int _streak = 0;
  int _record = 0;
  _Feedback _feedback = _Feedback.none;
  String? _lastEnteredText;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    _problem = Problem.random(
      widget.difficulty,
      _random,
      selectedTables: widget.selectedTables,
    );
    _loadRecord();
    _refocus();
  }

  Future<void> _loadRecord() async {
    final int record = await _repository.getRecord(widget.difficulty);
    if (!mounted) {
      return;
    }
    setState(() {
      _record = record;
    });
  }

  void _refocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });
  }

  void _startNewProblem() {
    _problem = Problem.random(
      widget.difficulty,
      _random,
      selectedTables: widget.selectedTables,
    );
    _stepIndex = 0;
    _feedback = _Feedback.none;
    _lastEnteredText = null;
    _controller.clear();
  }

  int _maxLengthFor(StepKind kind) {
    switch (kind) {
      case StepKind.rowUnits:
        // Acá se escribe el producto COMPLETO (ej. "48" para 8 × 6),
        // no solo el dígito de las unidades: el sistema separa el
        // dígito de la llevada solo. Como mucho son 2 cifras
        // (9 × 9 = 81).
        return 2;
      case StepKind.rowTens:
        return 2;
      case StepKind.sumColumn:
        // Acá también se escribe el resultado COMPLETO de la columna
        // (ej. "12"), no solo el dígito que queda; el sistema separa
        // la llevada solo. Como mucho son 2 cifras (9 + 9 + 1 = 19).
        return 2;
    }
  }

  static const List<String> _columnNames = <String>[
    'las unidades',
    'las decenas',
    'las centenas',
    'la unidad de mil',
    'la decena de mil',
  ];

  String _columnName(int columnIndex) {
    if (columnIndex >= 0 && columnIndex < _columnNames.length) {
      return _columnNames[columnIndex];
    }
    return 'la columna ${columnIndex + 1}';
  }

  String _labelFor(ProblemStep step) {
    switch (step.kind) {
      case StepKind.rowUnits:
        final ProblemRow row = _problem.rows[step.rowIndex];
        return 'Unidades: ${_problem.factor1 % 10} × ${row.multiplierDigit}';
      case StepKind.rowTens:
        final ProblemRow row = _problem.rows[step.rowIndex];
        final String carryText = row.carry > 0 ? ' + ${row.carry}' : '';
        return 'Decenas: ${_problem.factor1 ~/ 10} × '
            '${row.multiplierDigit}$carryText';
      case StepKind.sumColumn:
        final SumColumn column = _problem.sumColumns[step.columnIndex];
        final String carryText =
            column.carryIn > 0 ? ' + ${column.carryIn} (que te llevás)' : '';
        return 'Sumá ${_columnName(column.columnIndex)}: '
            '${column.digit0} + ${column.digit1}$carryText';
    }
  }

  void _submit(String rawValue) {
    if (_locked) {
      return;
    }
    final String trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      _refocus();
      return;
    }

    final int? parsed = int.tryParse(trimmed);
    final ProblemStep step = _problem.steps[_stepIndex];
    final bool isCorrect = parsed != null && parsed == step.expectedValue;

    setState(() {
      _locked = true;
      _lastEnteredText = trimmed;
      _feedback = isCorrect ? _Feedback.correct : _Feedback.incorrect;
      if (!isCorrect) {
        // Se ve el efecto apenas se comete el error: la racha se
        // corta ahí mismo, no recién cuando arranca la cuenta nueva.
        _streak = 0;
      }
    });

    if (!isCorrect) {
      // A diferencia de un acierto, un error NO avanza solo: se
      // queda congelado mostrando en rojo dónde estuvo el error (y
      // cuál era la respuesta correcta) hasta que se toque
      // "REINICIAR" a propósito. Ver [_onRestartPressed].
      return;
    }

    Future<void>.delayed(_feedbackDelay, () {
      if (!mounted) {
        return;
      }

      final bool wasLastStep = _stepIndex + 1 >= _problem.steps.length;
      if (wasLastStep) {
        unawaited(_onProblemSolved());
      } else {
        setState(() {
          _stepIndex++;
          _feedback = _Feedback.none;
          _lastEnteredText = null;
          _locked = false;
          _controller.clear();
        });
        _refocus();
      }
    });
  }

  /// Se llama al tocar el botón "REINICIAR" que aparece después de un
  /// error: recién ahí arranca una cuenta completamente nueva.
  void _onRestartPressed() {
    setState(() {
      _startNewProblem();
      _locked = false;
    });
    _refocus();
  }

  Future<void> _onProblemSolved() async {
    final int newStreak = _streak + 1;
    setState(() {
      _streak = newStreak;
    });

    final bool isNewRecord = await _repository.tryUpdateRecord(
      difficulty: widget.difficulty,
      candidateStreak: newStreak,
    );
    if (isNewRecord && mounted) {
      setState(() {
        _record = newStreak;
      });
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _startNewProblem();
      _locked = false;
    });
    _refocus();
  }

  Future<void> _onExitPressed() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('¿Salir del juego?'),
          content: Text(
            _streak > 0
                ? 'Vas a perder tu racha actual de $_streak si salís ahora.'
                : 'Perdés la racha actual si salís ahora.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('SEGUIR JUGANDO'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'SALIR',
                style: TextStyle(color: AppColors.errorRed),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ProblemStep currentStep = _problem.steps[_stepIndex];

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: AppBackground(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // La barra de racha/récord/salir ahora va vertical, en
              // una franja angosta a la izquierda: así libera todo el
              // ancho de arriba para que la cuenta pueda subir más y
              // quede más lugar disponible cuando el teclado del
              // celular se despliega.
              _SideBar(
                streak: _streak,
                record: _record,
                onClose: _onExitPressed,
              ),
              Expanded(
                child: Column(
                  children: <Widget>[
                    // La cuenta queda SIEMPRE visible, fija arriba,
                    // fuera de la zona que se achica/desplaza cuando
                    // aparece el teclado en el celular: si estuviera
                    // adentro de esa zona, al abrirse el teclado
                    // terminaba empujada fuera de la pantalla (justo
                    // lo que reportó el usuario).
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                      child: _VerticalProblem(
                        problem: _problem,
                        stepIndex: _stepIndex,
                        feedback: _feedback,
                        enteredText: _lastEnteredText,
                      ),
                    ),
                    // Solo esta zona de abajo (cartel + input +
                    // feedback + botón) se ajusta y hace scroll cuando
                    // el teclado se despliega; como la cuenta ya no
                    // vive acá adentro, no hay riesgo de que
                    // desaparezca de la vista.
                    Expanded(
                      child: SingleChildScrollView(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                SizedBox(
                                  width: double.infinity,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      widget.showHints
                                          ? 'Paso ${_stepIndex + 1}: '
                                              '${_labelFor(currentStep)}'
                                          : 'Paso ${_stepIndex + 1}',
                                      // Nunca 2 renglones: si no entra
                                      // en uno solo, se achica el
                                      // texto (FittedBox) en vez de
                                      // pasar a la línea siguiente.
                                      maxLines: 1,
                                      softWrap: false,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: 150,
                                  child: TextField(
                                    controller: _controller,
                                    focusNode: _focusNode,
                                    autofocus: true,
                                    enabled: !_locked,
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.done,
                                    textAlign: TextAlign.center,
                                    inputFormatters: <TextInputFormatter>[
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(
                                        _maxLengthFor(currentStep.kind),
                                      ),
                                    ],
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryBlueDark,
                                    ),
                                    decoration: const InputDecoration(
                                      counterText: '',
                                      hintText: '?',
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 6,
                                        horizontal: 10,
                                      ),
                                    ),
                                    onSubmitted: _submit,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  height: 18,
                                  child: _feedback == _Feedback.none
                                      ? const SizedBox.shrink()
                                      : Text(
                                          _feedback == _Feedback.correct
                                              ? '¡Correcto! 😊'
                                              : 'Incorrecto 😅 '
                                                  '(era ${currentStep.expectedValue})',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color:
                                                _feedback == _Feedback.correct
                                                    ? AppColors.leafGreenDark
                                                    : AppColors.errorRed,
                                          ),
                                        ),
                                ),
                                if (_feedback ==
                                    _Feedback.incorrect) ...<Widget>[
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: 170,
                                    height: 40,
                                    child: Theme(
                                      data: Theme.of(context).copyWith(
                                        elevatedButtonTheme:
                                            ElevatedButtonThemeData(
                                          style: ElevatedButton.styleFrom(
                                            minimumSize: const Size(
                                              double.infinity,
                                              40,
                                            ),
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 6,
                                            ),
                                            textStyle: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.3,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            elevation: 2,
                                          ),
                                        ),
                                      ),
                                      child: PrimaryButton(
                                        label: 'REINICIAR',
                                        icon: Icons.refresh_rounded,
                                        backgroundColor: AppColors.errorRed,
                                        onPressed: _onRestartPressed,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Franja lateral izquierda, angosta: racha actual, récord de la
/// dificultad elegida, y botón para salir (con confirmación, ver
/// [GameScreen._onExitPressed]). Va vertical (en vez de una barra
/// horizontal arriba de todo) para dejarle más alto disponible a la
/// cuenta, sobre todo con el teclado del celular abierto.
class _SideBar extends StatelessWidget {
  const _SideBar({
    required this.streak,
    required this.record,
    required this.onClose,
  });

  final int streak;
  final int record;
  final VoidCallback onClose;

  static const double _width = 58;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _width,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: AppColors.primaryBlue, width: 3),
        ),
      ),
      child: Column(
        children: <Widget>[
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 24),
            color: AppColors.textMuted,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          const SizedBox(height: 14),
          _VerticalStatChip(
            icon: Icons.local_fire_department_rounded,
            label: '$streak',
            color: AppColors.emberOrange,
          ),
          const SizedBox(height: 14),
          _VerticalStatChip(
            icon: Icons.emoji_events_rounded,
            label: '$record',
            color: AppColors.trophyGold,
          ),
        ],
      ),
    );
  }
}

class _VerticalStatChip extends StatelessWidget {
  const _VerticalStatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Una celda individual de la grilla: un carácter (o vacío) con su
/// propio color, para poder pintar cada dígito por separado (algunos
/// ya confirmados en verde, otro recién escrito en rojo, etc, todo
/// dentro del mismo renglón).
class _Cell {
  const _Cell(this.char, this.color);
  final String char;
  final Color color;

  static _Cell blank() => const _Cell('', Colors.transparent);
}

/// Muestra la cuenta en formato de multiplicación en columna, dígito
/// a dígito, igual que a mano en el papel: los dos factores arriba,
/// la llevada en chiquito y en rojo cuando corresponde, una línea, y
/// abajo cada renglón (que se va completando de a un paso: primero el
/// dígito de las unidades, después el resto). En la dificultad de 2
/// cifras × 2 cifras hay un segundo renglón corrido un lugar (con un
/// 0 que se completa solo apenas se llega a ese renglón) y, después
/// de una segunda línea, la suma total.
class _VerticalProblem extends StatelessWidget {
  const _VerticalProblem({
    required this.problem,
    required this.stepIndex,
    required this.feedback,
    required this.enteredText,
  });

  final Problem problem;
  final int stepIndex;
  final _Feedback feedback;
  final String? enteredText;

  static const double _cellWidth = 24.3;
  static const double _operatorSlotWidth = 24.3;
  static const double _fontSize = 24.3;
  static const double _carryFontSize = 13.5;

  int get _totalWidth {
    int width = 2; // factor1 siempre tiene 2 cifras.
    width = max(width, problem.factor2.toString().length);
    for (final ProblemRow row in problem.rows) {
      final int contentLen = row.restValue.toString().length + 1;
      width = max(width, contentLen + row.shift);
    }
    if (problem.rows.length > 1) {
      width = max(width, problem.finalAnswer.toString().length);
    }
    return width + 1;
  }

  List<_Cell> _emptyCells(int width) =>
      List<_Cell>.generate(width, (_) => _Cell.blank());

  /// Ubica [content] alineado a la derecha, terminando en la columna
  /// [rightmostIndex] (incluida), pintado del color [color].
  void _placeRightAligned(
    List<_Cell> cells,
    String content,
    int rightmostIndex,
    Color color,
  ) {
    int idx = rightmostIndex;
    for (int i = content.length - 1; i >= 0 && idx >= 0; i--) {
      cells[idx] = _Cell(content[i], color);
      idx--;
    }
  }

  List<_Cell> _numberCells(int width, String content, Color color) {
    final List<_Cell> cells = _emptyCells(width);
    _placeRightAligned(cells, content, width - 1, color);
    return cells;
  }

  /// Arma la grilla de celdas de un renglón (unidades + decenas de
  /// factor2, con el corrimiento si corresponde), según cuánto se
  /// lleva completado hasta ahora.
  List<_Cell> _rowCells(int width, int rowIndex, ProblemRow row) {
    final List<_Cell> cells = _emptyCells(width);
    final int unitsGlobalIndex = rowIndex * 2;
    final int tensGlobalIndex = rowIndex * 2 + 1;
    final bool reached = stepIndex >= unitsGlobalIndex;
    if (!reached) {
      return cells;
    }

    final int unitsCol = width - 1 - row.shift;
    final int tensRightmostCol = width - 2 - row.shift;

    // El 0 del corrimiento se completa solo, apenas se llega a este
    // renglón (no hace falta escribirlo).
    if (row.shift > 0) {
      cells[width - 1] = const _Cell('0', AppColors.leafGreenDark);
    }

    // Paso 1 de este renglón (unidades): se ingresa el producto
    // COMPLETO (ej. "48"), pero acá solo se muestra el dígito de las
    // unidades ya separado — la llevada se muestra aparte, arriba de
    // factor1 (ver _carryCells en build()).
    final bool unitsConfirmedOrJustCorrect = stepIndex > unitsGlobalIndex ||
        (stepIndex == unitsGlobalIndex && feedback == _Feedback.correct);
    if (unitsConfirmedOrJustCorrect) {
      cells[unitsCol] = _Cell('${row.unitsDigit}', AppColors.leafGreenDark);
    }
    // Si la respuesta fue incorrecta, no sabemos qué "dígito" separar
    // de un cálculo mal hecho, así que la celda queda vacía; el
    // cartel de abajo ya explica cuál era el producto correcto.

    // Paso 2 de este renglón (decenas + llevada).
    if (stepIndex > tensGlobalIndex) {
      _placeRightAligned(
        cells,
        '${row.restValue}',
        tensRightmostCol,
        AppColors.leafGreenDark,
      );
    } else if (stepIndex == tensGlobalIndex && feedback != _Feedback.none) {
      final Color color = feedback == _Feedback.correct
          ? AppColors.leafGreenDark
          : AppColors.errorRed;
      _placeRightAligned(cells, enteredText ?? '', tensRightmostCol, color);
    }

    return cells;
  }

  /// Arma la grilla de celdas de la fila de la suma final, columna
  /// por columna (unidades, decenas, centenas, ...), según cuánto se
  /// lleva completado hasta ahora. El mismo mecanismo que
  /// [_rowCells]: se ingresa el resultado COMPLETO de cada columna,
  /// pero acá solo se muestra el dígito ya separado de la llevada.
  List<_Cell> _sumRowCells(int width) {
    final List<_Cell> cells = _emptyCells(width);
    if (problem.sumColumns.isEmpty) {
      return cells;
    }
    final int sumStartIndex = problem.steps.length - problem.sumColumns.length;
    for (int i = 0; i < problem.sumColumns.length; i++) {
      final int globalIndex = sumStartIndex + i;
      final int col = width - 1 - i;
      if (col < 0) {
        continue;
      }
      final bool confirmedOrJustCorrect = stepIndex > globalIndex ||
          (stepIndex == globalIndex && feedback == _Feedback.correct);
      if (confirmedOrJustCorrect) {
        final int digit = problem.sumColumns[i].writtenDigit;
        cells[col] = _Cell('$digit', AppColors.leafGreenDark);
      }
      // Si la respuesta fue incorrecta, no sabemos qué dígito separar
      // de un cálculo mal hecho: la celda queda vacía, y el cartel de
      // abajo ya explica cuál era la suma correcta de esa columna.
    }
    return cells;
  }

  Widget _rowWidget(
    List<_Cell> cells, {
    String operatorText = '',
    double? fontSize,
  }) {
    final double size = fontSize ?? _fontSize;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: _operatorSlotWidth,
            child: Text(
              operatorText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ),
          ...cells.map(
            (_Cell cell) => SizedBox(
              width: _cellWidth,
              child: Text(
                cell.char,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: size,
                  fontWeight: FontWeight.w800,
                  color: cell.color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1.8,
      margin: const EdgeInsets.symmetric(vertical: 3.6),
      color: AppColors.textDark,
    );
  }

  @override
  Widget build(BuildContext context) {
    final int width = _totalWidth;
    final bool isTwoDigits = problem.difficulty == Difficulty.twoDigits;
    final ProblemStep current = problem.steps[stepIndex];

    // La llevada activa (si hay una) va justo arriba de la cifra de
    // las decenas de factor1, que siempre está en la columna
    // width - 2 (factor1 siempre tiene 2 cifras). Aparece apenas se
    // contesta bien el paso de unidades de un renglón (aunque todavía
    // no haya avanzado el paso, para que se vea al toque junto con el
    // dígito separado) y sigue mostrándose durante el paso de las
    // decenas de ese mismo renglón.
    int? carryRowIndex;
    if (current.kind == StepKind.rowTens) {
      carryRowIndex = current.rowIndex;
    } else if (current.kind == StepKind.rowUnits &&
        feedback == _Feedback.correct) {
      carryRowIndex = current.rowIndex;
    }
    final List<_Cell> carryCells = _emptyCells(width);
    if (carryRowIndex != null) {
      final int carry = problem.rows[carryRowIndex].carry;
      if (carry > 0) {
        carryCells[width - 2] = _Cell('$carry', AppColors.errorRed);
      }
    }

    final List<Widget> rows = <Widget>[
      _rowWidget(carryCells, fontSize: _carryFontSize),
      _rowWidget(
        _numberCells(width, '${problem.factor1}', AppColors.textDark),
      ),
      _rowWidget(
        _numberCells(width, '${problem.factor2}', AppColors.textDark),
        operatorText: '×',
      ),
      _divider(),
    ];

    for (int i = 0; i < problem.rows.length; i++) {
      if (isTwoDigits && i == problem.rows.length - 1) {
        rows.add(_divider());
      }
      rows.add(_rowWidget(_rowCells(width, i, problem.rows[i])));
    }

    if (isTwoDigits) {
      // La llevada de la suma final se muestra arriba de la columna
      // donde "aterriza", con el mismo criterio que la llevada de la
      // multiplicación: aparece apenas se contesta bien esa columna
      // (para verse al toque junto con el dígito separado) y sigue
      // mostrándose mientras se resuelve la columna siguiente.
      int? sumCarryColumnIndex;
      int sumCarryValue = 0;
      if (current.kind == StepKind.sumColumn) {
        final SumColumn column = problem.sumColumns[current.columnIndex];
        if (feedback == _Feedback.correct) {
          if (column.carryOut > 0) {
            sumCarryColumnIndex = column.columnIndex + 1;
            sumCarryValue = column.carryOut;
          }
        } else if (column.carryIn > 0) {
          sumCarryColumnIndex = column.columnIndex;
          sumCarryValue = column.carryIn;
        }
      }
      final List<_Cell> sumCarryCells = _emptyCells(width);
      if (sumCarryColumnIndex != null) {
        final int carryCol = width - 1 - sumCarryColumnIndex;
        if (carryCol >= 0) {
          sumCarryCells[carryCol] = _Cell('$sumCarryValue', AppColors.errorRed);
        }
      }

      rows.add(_divider());
      rows.add(_rowWidget(sumCarryCells, fontSize: _carryFontSize));
      rows.add(_rowWidget(_sumRowCells(width)));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9.9, vertical: 8.1),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16.2),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 7.2,
            offset: Offset(0, 2.7),
          ),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}
