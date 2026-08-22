import 'package:flutter/material.dart';

import '../models/difficulty.dart';
import '../models/table_selection.dart';
import '../services/hints_repository.dart';
import '../services/streak_repository.dart';
import '../services/table_selection_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/app_background.dart';
import 'game_screen.dart';

/// Pantalla principal: elegir qué tablas se pueden usar y qué tipo de
/// cuenta practicar. Hay un solo modo de juego (sumar la mayor
/// cantidad de cuentas seguidas sin errores), con dos dificultades
/// independientes, cada una con su propio récord.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StreakRepository _streakRepository = StreakRepository();
  final TableSelectionRepository _tableRepository =
      TableSelectionRepository();
  final HintsRepository _hintsRepository = HintsRepository();
  final Map<Difficulty, int> _records = <Difficulty, int>{};

  int _maxTable = TableSelection.defaultMaxTable;
  bool _showHints = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
    _loadMaxTable();
    _loadShowHints();
  }

  Future<void> _loadRecords() async {
    final Map<Difficulty, int> loaded = <Difficulty, int>{};
    for (final Difficulty difficulty in Difficulty.values) {
      loaded[difficulty] = await _streakRepository.getRecord(difficulty);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _records
        ..clear()
        ..addAll(loaded);
    });
  }

  Future<void> _loadMaxTable() async {
    final int maxTable = await _tableRepository.getMaxTable();
    if (!mounted) {
      return;
    }
    setState(() {
      _maxTable = maxTable;
    });
  }

  void _onMaxTableChanged(int? value) {
    if (value == null) {
      return;
    }
    setState(() {
      _maxTable = value;
    });
    // Se guarda en segundo plano; no hace falta esperarlo para
    // seguir usando la pantalla.
    _tableRepository.saveMaxTable(value);
  }

  Future<void> _loadShowHints() async {
    final bool showHints = await _hintsRepository.getShowHints();
    if (!mounted) {
      return;
    }
    setState(() {
      _showHints = showHints;
    });
  }

  void _onToggleShowHints(bool? value) {
    final bool newValue = value ?? true;
    setState(() {
      _showHints = newValue;
    });
    _hintsRepository.saveShowHints(newValue);
  }

  void _onPlay(Difficulty difficulty) {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => GameScreen(
              difficulty: difficulty,
              selectedTables: TableSelection.tablesUpTo(_maxTable),
              showHints: _showHints,
            ),
          ),
        )
        .then((_) => _loadRecords());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'MULTIPLICACIONES DE DOS CIFRAS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '¿Hasta qué tabla podemos usar?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Se van a usar esa tabla y todas las anteriores',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 14),
                _MaxTableDropdown(
                  value: _maxTable,
                  onChanged: _onMaxTableChanged,
                ),
                const SizedBox(height: 26),
                const Text(
                  '¿Qué cuenta querés practicar?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                _ShowHintsCheckbox(
                  value: _showHints,
                  onChanged: _onToggleShowHints,
                ),
                const SizedBox(height: 16),
                _DifficultyCard(
                  difficulty: Difficulty.oneDigit,
                  record: _records[Difficulty.oneDigit],
                  color: AppColors.primaryBlue,
                  icon: Icons.filter_1_rounded,
                  onTap: () => _onPlay(Difficulty.oneDigit),
                ),
                const SizedBox(height: 16),
                _DifficultyCard(
                  difficulty: Difficulty.twoDigits,
                  record: _records[Difficulty.twoDigits],
                  color: AppColors.candyPink,
                  icon: Icons.filter_2_rounded,
                  onTap: () => _onPlay(Difficulty.twoDigits),
                ),
                const SizedBox(height: 20),
                const Text(
                  'By SebaLima',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Menú desplegable para elegir hasta qué tabla se puede usar (2 al
/// 10). La tabla elegida y todas las anteriores quedan habilitadas.
class _MaxTableDropdown extends StatelessWidget {
  const _MaxTableDropdown({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: value,
            isExpanded: true,
            alignment: Alignment.center,
            borderRadius: BorderRadius.circular(20),
            icon: const Icon(
              Icons.expand_more_rounded,
              color: AppColors.primaryBlue,
            ),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryBlueDark,
            ),
            items: TableSelection.options
                .map(
                  (int table) => DropdownMenuItem<int>(
                    value: table,
                    child: Text(
                      'Tabla del $table',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

/// Casillero para mostrar u ocultar las ayudas durante el juego (el
/// cartel que indica qué números tocan multiplicar o sumar en cada
/// paso). Tildado (por defecto) deja todo tal cual está ahora;
/// destildado, ese cartel no aparece mientras se resuelve la cuenta.
class _ShowHintsCheckbox extends StatelessWidget {
  const _ShowHintsCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.primaryBlue,
              ),
              const SizedBox(width: 4),
              const Flexible(
                child: Text(
                  'Mostrar ayudas (qué números tocan)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta grande para elegir una dificultad: ícono, nombre, un
/// ejemplo corto y el récord actual (o "Sin récord todavía" si nunca
/// se jugó esa dificultad).
class _DifficultyCard extends StatelessWidget {
  const _DifficultyCard({
    required this.difficulty,
    required this.record,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final Difficulty difficulty;
  final int? record;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String recordText = record == null
        ? 'Cargando récord…'
        : record == 0
            ? 'Sin récord todavía'
            : 'Récord: $record seguidas';
    final bool hasRecord = record != null && record! > 0;

    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(24),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      difficulty.displayLabel,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      difficulty.exampleLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      recordText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: hasRecord
                            ? AppColors.trophyGold
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textMuted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
