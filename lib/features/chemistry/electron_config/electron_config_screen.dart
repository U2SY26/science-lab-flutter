import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 전자 배치 시뮬레이션
class ElectronConfigScreen extends StatefulWidget {
  const ElectronConfigScreen({super.key});

  @override
  State<ElectronConfigScreen> createState() => _ElectronConfigScreenState();
}

class _ElectronConfigScreenState extends State<ElectronConfigScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  int _atomicNumber = 11; // 나트륨
  bool _showOrbitalDiagram = true;

  // 오비탈 채움 순서 (aufbau principle)
  static const List<String> _orbitalOrder = [
    '1s', '2s', '2p', '3s', '3p', '4s', '3d', '4p', '5s', '4d',
    '5p', '6s', '4f', '5d', '6p', '7s', '5f', '6d', '7p'
  ];

  static const Map<String, int> _orbitalCapacity = {
    's': 2,
    'p': 6,
    'd': 10,
    'f': 14,
  };

  // 원소 기호
  static const List<String> _symbols = [
    '', 'H', 'He', 'Li', 'Be', 'B', 'C', 'N', 'O', 'F', 'Ne',
    'Na', 'Mg', 'Al', 'Si', 'P', 'S', 'Cl', 'Ar', 'K', 'Ca',
    'Sc', 'Ti', 'V', 'Cr', 'Mn', 'Fe', 'Co', 'Ni', 'Cu', 'Zn',
    'Ga', 'Ge', 'As', 'Se', 'Br', 'Kr'
  ];

  List<MapEntry<String, int>> get _electronConfiguration {
    List<MapEntry<String, int>> config = [];
    int remaining = _atomicNumber;

    for (final orbital in _orbitalOrder) {
      if (remaining <= 0) break;

      final type = orbital[orbital.length - 1];
      final capacity = _orbitalCapacity[type]!;
      final electrons = remaining > capacity ? capacity : remaining;

      config.add(MapEntry(orbital, electrons));
      remaining -= electrons;
    }

    return config;
  }

  String get _configNotation {
    return _electronConfiguration.map((e) => '${e.key}${_toSuperscript(e.value)}').join(' ');
  }

  String get _nobleGasNotation {
    // 간략한 표기법 (예: [Ne] 3s¹)
    final configs = _electronConfiguration;
    if (configs.isEmpty) return '';

    // 비활성 기체 코어 찾기
    final nobleGases = [2, 10, 18, 36]; // He, Ne, Ar, Kr
    int coreEnd = 0;
    String coreSymbol = '';

    for (final ng in nobleGases) {
      if (ng < _atomicNumber) {
        coreEnd = ng;
        coreSymbol = '[${_symbols[ng]}]';
      }
    }

    if (coreEnd == 0) return _configNotation;

    int electronCount = 0;
    List<MapEntry<String, int>> valenceConfigs = [];

    for (final config in configs) {
      electronCount += config.value;
      if (electronCount > coreEnd) {
        final remaining = electronCount - coreEnd;
        if (remaining < config.value) {
          valenceConfigs.add(MapEntry(config.key, remaining));
        } else {
          valenceConfigs.add(config);
        }
      }
    }

    final valence = valenceConfigs.map((e) => '${e.key}${_toSuperscript(e.value)}').join(' ');
    return '$coreSymbol $valence';
  }

  String _toSuperscript(int n) {
    const superscripts = '⁰¹²³⁴⁵⁶⁷⁸⁹';
    return n.toString().split('').map((d) => superscripts[int.parse(d)]).join();
  }

  int get _valenceElectrons {
    final config = _electronConfiguration;
    if (config.isEmpty) return 0;

    // 마지막 주껍질의 전자 수
    final lastShell = config.last.key[0];
    int valence = 0;

    for (final c in config) {
      if (c.key[0] == lastShell) {
        valence += c.value;
      }
    }

    return valence;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              '전자 배치',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '화학',
          title: '전자 배치',
          formula: '1s² 2s² 2p⁶ ...',
          formulaDescription: 'Aufbau 원리에 따른 전자 오비탈 채움',
          simulation: SizedBox(
            height: 350,
            child: _showOrbitalDiagram
                ? _buildOrbitalDiagram()
                : AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _ElectronShellPainter(
                          atomicNumber: _atomicNumber,
                          animation: _controller.value,
                        ),
                        size: Size.infinite,
                      );
                    },
                  ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 전자 배치 정보
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$_atomicNumber',
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                _atomicNumber < _symbols.length ? _symbols[_atomicNumber] : '?',
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '전자 배치',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                _configNotation,
                                style: const TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _nobleGasNotation,
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoItem(label: '총 전자', value: '$_atomicNumber'),
                        _InfoItem(label: '원자가 전자', value: '$_valenceElectrons'),
                        _InfoItem(
                          label: '주기',
                          value: _electronConfiguration.isNotEmpty
                              ? _electronConfiguration.last.key[0]
                              : '-',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 보기 모드 토글
              Row(
                children: [
                  Expanded(
                    child: _ViewModeButton(
                      label: '오비탈 다이어그램',
                      isSelected: _showOrbitalDiagram,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _showOrbitalDiagram = true);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ViewModeButton(
                      label: '껍질 모델',
                      isSelected: !_showOrbitalDiagram,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _showOrbitalDiagram = false);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 원자 번호 슬라이더
              ControlGroup(
                primaryControl: SimSlider(
                  label: '원자 번호',
                  value: _atomicNumber.toDouble(),
                  min: 1,
                  max: 36,
                  defaultValue: 11,
                  formatValue: (v) => '${v.toInt()} (${v.toInt() < _symbols.length ? _symbols[v.toInt()] : "?"})',
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    setState(() => _atomicNumber = v.toInt());
                  },
                ),
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: 'Na (11)',
                icon: Icons.filter_1,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _atomicNumber = 11);
                },
              ),
              SimButton(
                label: 'Fe (26)',
                icon: Icons.filter_2,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _atomicNumber = 26);
                },
              ),
              SimButton(
                label: 'Kr (36)',
                icon: Icons.filter_3,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _atomicNumber = 36);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrbitalDiagram() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.simBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final config in _electronConfiguration)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _OrbitalRow(
                  orbital: config.key,
                  electrons: config.value,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 10),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _ViewModeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewModeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.2) : AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.cardBorder,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.accent : AppColors.muted,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbitalRow extends StatelessWidget {
  final String orbital;
  final int electrons;

  const _OrbitalRow({required this.orbital, required this.electrons});

  int get _maxElectrons {
    final type = orbital[orbital.length - 1];
    switch (type) {
      case 's': return 2;
      case 'p': return 6;
      case 'd': return 10;
      case 'f': return 14;
      default: return 2;
    }
  }

  int get _boxCount => _maxElectrons ~/ 2;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            orbital,
            style: const TextStyle(
              color: AppColors.ink,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        for (int i = 0; i < _boxCount; i++)
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (electrons > i * 2)
                  const Text(
                    '↑',
                    style: TextStyle(color: AppColors.accent, fontSize: 16),
                  ),
                if (electrons > i * 2 + 1)
                  const Text(
                    '↓',
                    style: TextStyle(color: AppColors.accent2, fontSize: 16),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ElectronShellPainter extends CustomPainter {
  final int atomicNumber;
  final double animation;

  _ElectronShellPainter({
    required this.atomicNumber,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2 - 30;

    // 전자 껍질 배치
    List<int> shells = _getShellConfiguration();

    // 핵
    canvas.drawCircle(
      center,
      18,
      Paint()..color = AppColors.accent,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: '$atomicNumber',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );

    // 껍질과 전자
    for (int shell = 0; shell < shells.length; shell++) {
      final radius = 40 + shell * (maxRadius - 40) / shells.length;
      final electronCount = shells[shell];

      // 껍질 궤도
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );

      // 전자
      for (int e = 0; e < electronCount; e++) {
        final baseAngle = 2 * math.pi * e / electronCount;
        final rotationSpeed = 1.0 / (shell + 1);
        final angle = baseAngle + animation * 2 * math.pi * rotationSpeed;

        final electronPos = Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        );

        canvas.drawCircle(
          electronPos,
          6,
          Paint()..color = AppColors.accent.withValues(alpha: 0.3),
        );
        canvas.drawCircle(
          electronPos,
          4,
          Paint()..color = AppColors.accent,
        );
      }

      // 껍질 이름
      final shellNames = ['K', 'L', 'M', 'N', 'O', 'P', 'Q'];
      if (shell < shellNames.length) {
        final labelPainter = TextPainter(
          text: TextSpan(
            text: '${shellNames[shell]} (${shells[shell]})',
            style: TextStyle(
              color: AppColors.muted.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        labelPainter.layout();
        labelPainter.paint(
          canvas,
          Offset(center.dx + radius + 5, center.dy - labelPainter.height / 2),
        );
      }
    }
  }

  List<int> _getShellConfiguration() {
    int remaining = atomicNumber;
    List<int> shells = [];
    List<int> maxPerShell = [2, 8, 18, 32, 32, 18, 8];

    for (int max in maxPerShell) {
      if (remaining <= 0) break;
      int electrons = remaining > max ? max : remaining;
      shells.add(electrons);
      remaining -= electrons;
    }

    return shells;
  }

  @override
  bool shouldRepaint(covariant _ElectronShellPainter oldDelegate) {
    return oldDelegate.animation != animation || oldDelegate.atomicNumber != atomicNumber;
  }
}
