import 'package:flutter/material.dart';

import '../models/difficulty.dart';
import '../services/streak_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/app_background.dart';
import 'game_screen.dart';

/// Pantalla principal: elegir qué tipo de cuenta practicar. Hay un
/// solo modo de juego (sumar la mayor cantidad de cuentas seguidas
/// sin errores), con dos dificultades independientes, cada una con
/// su propio récord.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StreakRepository _repository = StreakRepository();
  final Map<Difficulty, int> _records = <Difficulty, int>{};

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final Map<Difficulty, int> loaded = <Difficulty, int>{};
    for (final Difficulty difficulty in Difficulty.values) {
      loaded[difficulty] = await _repository.getRecord(difficulty);
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

  void _onPlay(Difficulty difficulty) {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => GameScreen(difficulty: difficulty),
          ),
        )
        .then((_) => _loadRecords());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Text(
                    'MULTIPLICACIONES\nEN COLUMNA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '¿Qué cuenta querés practicar?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 16),
            const Text(
              'By SebaLima',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
          ],
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
