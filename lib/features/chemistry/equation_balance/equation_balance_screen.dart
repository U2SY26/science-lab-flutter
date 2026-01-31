import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 화학 반응식 균형 맞추기 시뮬레이션
class EquationBalanceScreen extends StatefulWidget {
  const EquationBalanceScreen({super.key});

  @override
  State<EquationBalanceScreen> createState() => _EquationBalanceScreenState();
}

class _EquationBalanceScreenState extends State<EquationBalanceScreen> {
  ChemicalEquation _selectedEquation = _equations[0];
  List<int> _userCoefficients = [];
  bool _showHint = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _resetEquation();
  }

  void _resetEquation() {
    setState(() {
      _userCoefficients = List.filled(_selectedEquation.compounds.length, 1);
      _isCorrect = false;
      _showHint = false;
    });
  }

  void _checkBalance() {
    HapticFeedback.mediumImpact();
    final balanced = _isBalanced();
    setState(() {
      _isCorrect = balanced;
    });

    if (balanced) {
      HapticFeedback.heavyImpact();
    }
  }

  bool _isBalanced() {
    Map<String, int> leftElements = {};
    Map<String, int> rightElements = {};

    for (int i = 0; i < _selectedEquation.compounds.length; i++) {
      final compound = _selectedEquation.compounds[i];
      final coeff = _userCoefficients[i];
      final isProduct = _selectedEquation.productStartIndex <= i;

      for (var entry in compound.elements.entries) {
        final count = entry.value * coeff;
        if (isProduct) {
          rightElements[entry.key] = (rightElements[entry.key] ?? 0) + count;
        } else {
          leftElements[entry.key] = (leftElements[entry.key] ?? 0) + count;
        }
      }
    }

    if (leftElements.length != rightElements.length) return false;

    for (var entry in leftElements.entries) {
      if (rightElements[entry.key] != entry.value) return false;
    }

    return true;
  }

  Map<String, int> _getElementCounts(bool isProduct) {
    Map<String, int> counts = {};

    for (int i = 0; i < _selectedEquation.compounds.length; i++) {
      final compound = _selectedEquation.compounds[i];
      final coeff = _userCoefficients[i];
      final compIsProduct = _selectedEquation.productStartIndex <= i;

      if (compIsProduct == isProduct) {
        for (var entry in compound.elements.entries) {
          counts[entry.key] = (counts[entry.key] ?? 0) + entry.value * coeff;
        }
      }
    }

    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final leftCounts = _getElementCounts(false);
    final rightCounts = _getElementCounts(true);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg.withValues(alpha: 0.9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '화학',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '화학 반응식 균형',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showHint ? Icons.lightbulb : Icons.lightbulb_outline,
              color: _showHint ? Colors.yellow : AppColors.muted,
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _showHint = !_showHint);
            },
            tooltip: '힌트',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '화학',
          title: '화학 반응식 균형',
          formula: '반응물 → 생성물',
          formulaDescription: '질량 보존의 법칙: 반응 전후 원자 수가 같아야 합니다',
          simulation: Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.simBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 반응식 표시
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < _selectedEquation.compounds.length; i++) ...[
                        if (i == _selectedEquation.productStartIndex)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(
                              Icons.arrow_forward,
                              color: AppColors.accent,
                              size: 28,
                            ),
                          )
                        else if (i > 0 && i < _selectedEquation.productStartIndex)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '+',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 24,
                              ),
                            ),
                          )
                        else if (i > _selectedEquation.productStartIndex)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '+',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 24,
                              ),
                            ),
                          ),
                        _CompoundWidget(
                          compound: _selectedEquation.compounds[i],
                          coefficient: _userCoefficients[i],
                          onIncrement: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              if (_userCoefficients[i] < 10) {
                                _userCoefficients[i]++;
                                _isCorrect = false;
                              }
                            });
                          },
                          onDecrement: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              if (_userCoefficients[i] > 1) {
                                _userCoefficients[i]--;
                                _isCorrect = false;
                              }
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 원소 카운트 비교
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ElementCountBox(
                      label: '반응물',
                      counts: leftCounts,
                      compareCounts: rightCounts,
                    ),
                    _ElementCountBox(
                      label: '생성물',
                      counts: rightCounts,
                      compareCounts: leftCounts,
                    ),
                  ],
                ),
              ],
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 정답 표시
              if (_isCorrect)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        '정답! 반응식이 균형을 이룹니다.',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

              // 힌트
              if (_showHint)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.yellow.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.yellow.shade700),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.yellow.shade700, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '힌트',
                            style: TextStyle(
                              color: Colors.yellow.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedEquation.hint,
                        style: TextStyle(color: Colors.yellow.shade800, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '정답: ${_selectedEquation.answer}',
                        style: TextStyle(
                          color: Colors.yellow.shade700,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),

              // 반응식 선택
              const Text(
                '반응식 선택',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _equations.map((eq) {
                  final isSelected = _selectedEquation == eq;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedEquation = eq;
                        _resetEquation();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent.withValues(alpha: 0.2)
                            : AppColors.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.accent : AppColors.cardBorder,
                        ),
                      ),
                      child: Text(
                        eq.name,
                        style: TextStyle(
                          color: isSelected ? AppColors.accent : AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: '확인',
                icon: Icons.check,
                isPrimary: true,
                onPressed: _checkBalance,
              ),
              SimButton(
                label: '리셋',
                icon: Icons.refresh,
                onPressed: _resetEquation,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompoundWidget extends StatelessWidget {
  final Compound compound;
  final int coefficient;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _CompoundWidget({
    required this.compound,
    required this.coefficient,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 증가 버튼
        GestureDetector(
          onTap: onIncrement,
          child: Container(
            width: 30,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
            child: const Icon(Icons.add, size: 16, color: AppColors.accent),
          ),
        ),
        // 계수 + 화합물
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                coefficient > 1 ? '$coefficient' : '',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (coefficient > 1) const SizedBox(width: 2),
              Text(
                compound.formula,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // 감소 버튼
        GestureDetector(
          onTap: onDecrement,
          child: Container(
            width: 30,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
            ),
            child: const Icon(Icons.remove, size: 16, color: AppColors.accent),
          ),
        ),
      ],
    );
  }
}

class _ElementCountBox extends StatelessWidget {
  final String label;
  final Map<String, int> counts;
  final Map<String, int> compareCounts;

  const _ElementCountBox({
    required this.label,
    required this.counts,
    required this.compareCounts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: counts.entries.map((entry) {
              final isBalanced = compareCounts[entry.key] == entry.value;
              return Text(
                '${entry.key}: ${entry.value}',
                style: TextStyle(
                  color: isBalanced ? Colors.green : Colors.red,
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class Compound {
  final String formula;
  final Map<String, int> elements;

  const Compound(this.formula, this.elements);
}

class ChemicalEquation {
  final String name;
  final List<Compound> compounds;
  final int productStartIndex;
  final String hint;
  final String answer;

  const ChemicalEquation({
    required this.name,
    required this.compounds,
    required this.productStartIndex,
    required this.hint,
    required this.answer,
  });
}

const List<ChemicalEquation> _equations = [
  ChemicalEquation(
    name: '물의 생성',
    compounds: [
      Compound('H₂', {'H': 2}),
      Compound('O₂', {'O': 2}),
      Compound('H₂O', {'H': 2, 'O': 1}),
    ],
    productStartIndex: 2,
    hint: '산소 원자 수를 먼저 맞추세요.',
    answer: '2H₂ + O₂ → 2H₂O',
  ),
  ChemicalEquation(
    name: '메탄 연소',
    compounds: [
      Compound('CH₄', {'C': 1, 'H': 4}),
      Compound('O₂', {'O': 2}),
      Compound('CO₂', {'C': 1, 'O': 2}),
      Compound('H₂O', {'H': 2, 'O': 1}),
    ],
    productStartIndex: 2,
    hint: '탄소 → 수소 → 산소 순으로 맞추세요.',
    answer: 'CH₄ + 2O₂ → CO₂ + 2H₂O',
  ),
  ChemicalEquation(
    name: '암모니아 합성',
    compounds: [
      Compound('N₂', {'N': 2}),
      Compound('H₂', {'H': 2}),
      Compound('NH₃', {'N': 1, 'H': 3}),
    ],
    productStartIndex: 2,
    hint: '질소 원자 수를 먼저 맞추고, 수소를 조절하세요.',
    answer: 'N₂ + 3H₂ → 2NH₃',
  ),
  ChemicalEquation(
    name: '철의 산화',
    compounds: [
      Compound('Fe', {'Fe': 1}),
      Compound('O₂', {'O': 2}),
      Compound('Fe₂O₃', {'Fe': 2, 'O': 3}),
    ],
    productStartIndex: 2,
    hint: '철과 산소의 최소공배수를 생각하세요.',
    answer: '4Fe + 3O₂ → 2Fe₂O₃',
  ),
  ChemicalEquation(
    name: '광합성',
    compounds: [
      Compound('CO₂', {'C': 1, 'O': 2}),
      Compound('H₂O', {'H': 2, 'O': 1}),
      Compound('C₆H₁₂O₆', {'C': 6, 'H': 12, 'O': 6}),
      Compound('O₂', {'O': 2}),
    ],
    productStartIndex: 2,
    hint: '탄소 6개가 필요합니다.',
    answer: '6CO₂ + 6H₂O → C₆H₁₂O₆ + 6O₂',
  ),
];
