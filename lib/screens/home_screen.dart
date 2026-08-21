import 'package:flutter/material.dart';

import '../models/difficulty.dart';
import '../models/table_selection.dart';
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
  final Map<Difficulty, int> _records = <Difficulty, int>{};

  Set<int> _selectedTables = TableSelection.defaultSelected();

  @override
  void initState() {
    super.initState();
    _loadRecords();
    _loadSelectedTables();
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

  Future<void> _loadSelectedTables() async {
    final Set<int> selected = await _tableRepository.getSelected();
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedTables = selected;
    });
  }

  void _onToggleTable(int table) {
    setState(() {
      if (_selectedTables.contains(table)) {
        // Siempre tiene que quedar al menos una tabla elegida: si es
        // la última, no se puede destildar.
        if (_selectedTables.length > 1) {
          _selectedTables.remove(table);
        }
      } else {
        _selectedTables.add(table);
      }
    });
    // Se guarda en segundo plano; no hace falta esperarlo para
    // seguir usando la pantalla.
    _tableRepository.saveSelected(_selectedTables);
  }

  void _onPlay(Difficulty difficulty) {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => GameScreen(
              difficulty: difficulty,
              selectedTables: _selectedTables,
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
                  'MULTIPLICACIONES\nEN COLUMNA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '¿Qué tablas podemos usar?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Las cuentas solo van a usar estas tablas',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 14),
                _TablesGrid(
                  selected: _selectedTables,
                  onToggle: _onToggleTable,
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

/// Grilla de 3 columnas con las tablas del 2 al 10, cada una como un
/// botón que se puede tildar o destildar, igual que en Tablas de
/// Multiplicar.
class _TablesGrid extends StatelessWidget {
  const _TablesGrid({required this.selected, required this.onToggle});

  final Set<int> selected;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: TableSelection.all
          .map(
            (int table) => _TableToggle(
              table: table,
              isSelected: selected.contains(table),
              onTap: () => onToggle(table),
            ),
          )
          .toList(),
    );
  }
}

class _TableToggle extends StatelessWidget {
  const _TableToggle({
    required this.table,
    required this.isSelected,
    required this.onTap,
  });

  final int table;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppColors.cardWhite
          : AppColors.textMuted.withOpacity(0.12),
      borderRadius: BorderRadius.circular(18),
      elevation: isSelected ? 2 : 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryBlue
                  : Colors.transparent,
              width: 3,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$table',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: isSelected ? AppColors.primaryBlueDark : AppColors.textMuted,
            ),
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
