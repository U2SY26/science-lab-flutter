import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Electrochemistry Simulation
class ElectrochemistryScreen extends ConsumerStatefulWidget {
  const ElectrochemistryScreen({super.key});

  @override
  ConsumerState<ElectrochemistryScreen> createState() => _ElectrochemistryScreenState();
}

class _ElectrochemistryScreenState extends ConsumerState<ElectrochemistryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final math.Random _random = math.Random();

  // Cell type
  String _cellType = 'galvanic'; // 'galvanic' or 'electrolytic'

  // Electrode materials
  String _anode = 'Zn';
  String _cathode = 'Cu';

  // Parameters
  double _voltage = 1.1; // Cell potential
  double _current = 0.5; // Current in A
  bool _isRunning = false;

  // Animation particles
  List<_Particle> _electrons = [];
  List<_Particle> _cations = [];
  List<_Particle> _anions = [];

  // Standard reduction potentials (V)
  final Map<String, double> _reductionPotentials = {
    'Li': -3.04,
    'K': -2.93,
    'Ca': -2.87,
    'Na': -2.71,
    'Mg': -2.37,
    'Al': -1.66,
    'Zn': -0.76,
    'Fe': -0.44,
    'Ni': -0.26,
    'Sn': -0.14,
    'Pb': -0.13,
    'H': 0.00,
    'Cu': 0.34,
    'Ag': 0.80,
    'Au': 1.50,
  };

  @override
  void initState() {
    super.initState();
    _calculateCellPotential();
    _initializeParticles();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(_updateAnimation);
  }

  void _calculateCellPotential() {
    final cathodeP = _reductionPotentials[_cathode] ?? 0;
    final anodeP = _reductionPotentials[_anode] ?? 0;

    if (_cellType == 'galvanic') {
      _voltage = cathodeP - anodeP;
    } else {
      _voltage = (cathodeP - anodeP).abs() + 0.5; // Required voltage for electrolysis
    }
  }

  void _initializeParticles() {
    _electrons = [];
    _cations = [];
    _anions = [];
  }

  void _updateAnimation() {
    if (!_isRunning) return;

    setState(() {
      // Generate new particles
      if (_random.nextDouble() < _current * 0.3) {
        // Electron from anode to cathode (through wire)
        _electrons.add(_Particle(
          x: 0.15,
          y: 0.1,
          vx: 0.02,
          vy: 0,
          type: 'electron',
        ));

        // Cation from anode to solution
        if (_cellType == 'galvanic') {
          _cations.add(_Particle(
            x: 0.15,
            y: 0.5,
            vx: 0.01,
            vy: (_random.nextDouble() - 0.5) * 0.01,
            type: 'cation',
          ));
        }
      }

      // Update electron positions (through wire)
      for (final e in _electrons) {
        if (e.x < 0.5) {
          e.x += e.vx;
          e.y = 0.1;
        } else if (e.x < 0.85) {
          e.x += e.vx;
          e.y = 0.1 + (e.x - 0.5) * 1.14; // Move down to cathode
        } else {
          e.y += 0.02; // Enter cathode
        }
      }

      // Update cation positions
      for (final c in _cations) {
        c.x += c.vx;
        c.y += c.vy;
      }

      // Update anion positions
      for (final a in _anions) {
        a.x += a.vx;
        a.y += a.vy;
      }

      // Remove particles that are out of bounds
      _electrons.removeWhere((e) => e.y > 0.9 || e.x > 1);
      _cations.removeWhere((c) => c.x > 0.85 || c.x < 0 || c.y > 1 || c.y < 0);
      _anions.removeWhere((a) => a.x > 1 || a.x < 0);

      // Limit particles
      if (_electrons.length > 50) _electrons.removeAt(0);
      if (_cations.length > 30) _cations.removeAt(0);
    });
  }

  void _toggleRunning() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isRunning = false;
      _controller.stop();
      _initializeParticles();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKorean = ref.watch(isKoreanProvider);

    final anodeP = _reductionPotentials[_anode] ?? 0;
    final cathodeP = _reductionPotentials[_cathode] ?? 0;

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
              isKorean ? '화학' : 'CHEMISTRY',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '전기화학' : 'Electrochemistry',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '화학' : 'Chemistry',
          title: isKorean ? '전기화학' : 'Electrochemistry',
          formula: 'E cell = E cathode - E anode',
          formulaDescription: isKorean
              ? '전기화학 전지에서 전자는 산화(양극)에서 환원(음극)으로 이동합니다.'
              : 'In electrochemical cells, electrons flow from oxidation (anode) to reduction (cathode).',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _ElectrochemistryPainter(
                cellType: _cellType,
                anode: _anode,
                cathode: _cathode,
                electrons: _electrons,
                cations: _cations,
                isRunning: _isRunning,
                isKorean: isKorean,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cell info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoItem(
                          label: isKorean ? '전지 유형' : 'Cell Type',
                          value: _cellType == 'galvanic'
                              ? (isKorean ? '갈바니' : 'Galvanic')
                              : (isKorean ? '전해' : 'Electrolytic'),
                          color: _cellType == 'galvanic' ? Colors.green : Colors.orange,
                        ),
                        _InfoItem(
                          label: isKorean ? '전위 (V)' : 'E cell (V)',
                          value: _voltage.toStringAsFixed(2),
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoItem(
                          label: '$_anode (${isKorean ? '양극' : 'Anode'})',
                          value: '${anodeP.toStringAsFixed(2)} V',
                          color: Colors.red,
                        ),
                        _InfoItem(
                          label: '$_cathode (${isKorean ? '음극' : 'Cathode'})',
                          value: '${cathodeP.toStringAsFixed(2)} V',
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Cell type selection
              PresetGroup(
                label: isKorean ? '전지 유형' : 'Cell Type',
                presets: [
                  PresetButton(
                    label: isKorean ? '갈바니 전지' : 'Galvanic',
                    isSelected: _cellType == 'galvanic',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _cellType = 'galvanic';
                        _calculateCellPotential();
                        _reset();
                      });
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '전해 전지' : 'Electrolytic',
                    isSelected: _cellType == 'electrolytic',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _cellType = 'electrolytic';
                        _calculateCellPotential();
                        _reset();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Electrode selection
              PresetGroup(
                label: isKorean ? '전극 조합' : 'Electrode Pair',
                presets: [
                  PresetButton(
                    label: 'Zn-Cu',
                    isSelected: _anode == 'Zn' && _cathode == 'Cu',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _anode = 'Zn';
                        _cathode = 'Cu';
                        _calculateCellPotential();
                        _reset();
                      });
                    },
                  ),
                  PresetButton(
                    label: 'Fe-Cu',
                    isSelected: _anode == 'Fe' && _cathode == 'Cu',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _anode = 'Fe';
                        _cathode = 'Cu';
                        _calculateCellPotential();
                        _reset();
                      });
                    },
                  ),
                  PresetButton(
                    label: 'Zn-Ag',
                    isSelected: _anode == 'Zn' && _cathode == 'Ag',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _anode = 'Zn';
                        _cathode = 'Ag';
                        _calculateCellPotential();
                        _reset();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Current control
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '전류 (A)' : 'Current (A)',
                  value: _current,
                  min: 0.1,
                  max: 2.0,
                  defaultValue: 0.5,
                  formatValue: (v) => '${v.toStringAsFixed(1)} A',
                  onChanged: (v) => setState(() => _current = v),
                ),
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: _isRunning
                    ? (isKorean ? '일시정지' : 'Pause')
                    : (isKorean ? '시작' : 'Start'),
                icon: _isRunning ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: _toggleRunning,
              ),
              SimButton(
                label: isKorean ? '리셋' : 'Reset',
                icon: Icons.refresh,
                onPressed: _reset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  String type;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.type,
  });
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ElectrochemistryPainter extends CustomPainter {
  final String cellType;
  final String anode;
  final String cathode;
  final List<_Particle> electrons;
  final List<_Particle> cations;
  final bool isRunning;
  final bool isKorean;

  _ElectrochemistryPainter({
    required this.cellType,
    required this.anode,
    required this.cathode,
    required this.electrons,
    required this.cations,
    required this.isRunning,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final anodeX = size.width * 0.15;
    final cathodeX = size.width * 0.85;
    final electrodeTop = size.height * 0.3;
    final electrodeBottom = size.height * 0.85;
    final solutionTop = size.height * 0.5;

    // Solution background
    canvas.drawRect(
      Rect.fromLTRB(0, solutionTop, size.width, size.height),
      Paint()..color = Colors.blue.withValues(alpha: 0.1),
    );

    // Salt bridge or membrane
    canvas.drawRect(
      Rect.fromLTRB(size.width * 0.45, solutionTop - 20, size.width * 0.55, solutionTop + 30),
      Paint()..color = Colors.grey[400]!,
    );
    _drawText(canvas, isKorean ? '염다리' : 'Salt Bridge',
        Offset(size.width * 0.38, solutionTop - 35), AppColors.muted, 10);

    // Wire
    canvas.drawPath(
      Path()
        ..moveTo(anodeX, electrodeTop)
        ..lineTo(anodeX, size.height * 0.1)
        ..lineTo(cathodeX, size.height * 0.1)
        ..lineTo(cathodeX, electrodeTop),
      Paint()
        ..color = Colors.grey[600]!
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );

    // Voltmeter
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.1),
      20,
      Paint()..color = Colors.grey[800]!,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.1),
      18,
      Paint()..color = Colors.white,
    );
    _drawText(canvas, 'V', Offset(size.width * 0.5 - 5, size.height * 0.1 - 8), Colors.black, 14,
        fontWeight: FontWeight.bold);

    // Anode (oxidation)
    canvas.drawRect(
      Rect.fromLTRB(anodeX - 15, electrodeTop, anodeX + 15, electrodeBottom),
      Paint()..color = Colors.grey[600]!,
    );
    _drawText(canvas, anode, Offset(anodeX - 10, electrodeTop - 20), Colors.red, 14,
        fontWeight: FontWeight.bold);
    _drawText(canvas, isKorean ? '(양극)' : '(Anode)', Offset(anodeX - 20, electrodeTop - 5), Colors.red, 10);
    _drawText(canvas, isKorean ? '산화' : 'Oxidation', Offset(anodeX - 25, electrodeBottom + 5), Colors.red, 10);

    // Cathode (reduction)
    canvas.drawRect(
      Rect.fromLTRB(cathodeX - 15, electrodeTop, cathodeX + 15, electrodeBottom),
      Paint()..color = Colors.orange[700]!,
    );
    _drawText(canvas, cathode, Offset(cathodeX - 10, electrodeTop - 20), Colors.blue, 14,
        fontWeight: FontWeight.bold);
    _drawText(canvas, isKorean ? '(음극)' : '(Cathode)', Offset(cathodeX - 25, electrodeTop - 5), Colors.blue, 10);
    _drawText(canvas, isKorean ? '환원' : 'Reduction', Offset(cathodeX - 25, electrodeBottom + 5), Colors.blue, 10);

    // Draw electrons in wire
    for (final e in electrons) {
      double x, y;
      if (e.x < 0.5) {
        x = anodeX + (e.x - 0.15) * size.width;
        y = size.height * 0.1;
      } else if (e.x < 0.85) {
        x = anodeX + (e.x - 0.15) * size.width;
        y = size.height * 0.1 + (e.x - 0.5) * size.height * 0.57;
      } else {
        x = cathodeX;
        y = electrodeTop + e.y * (electrodeBottom - electrodeTop);
      }

      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()..color = Colors.yellow,
      );
    }

    // Draw cations in solution
    for (final c in cations) {
      final x = c.x * size.width;
      final y = solutionTop + c.y * (size.height - solutionTop) * 0.8;

      canvas.drawCircle(
        Offset(x, y),
        5,
        Paint()..color = Colors.red.withValues(alpha: 0.7),
      );
      _drawText(canvas, '+', Offset(x - 3, y - 5), Colors.white, 8);
    }

    // Electron flow arrow
    if (isRunning) {
      _drawArrow(canvas, Offset(anodeX + 50, size.height * 0.08),
          Offset(cathodeX - 50, size.height * 0.08), Colors.yellow);
      _drawText(canvas, 'e-', Offset(size.width * 0.5 - 8, size.height * 0.03), Colors.yellow, 12,
          fontWeight: FontWeight.bold);
    }

    // Cell type indicator
    final cellLabel = cellType == 'galvanic'
        ? (isKorean ? '갈바니 전지 (자발적)' : 'Galvanic Cell (Spontaneous)')
        : (isKorean ? '전해 전지 (비자발적)' : 'Electrolytic Cell (Non-spontaneous)');
    _drawText(canvas, cellLabel, Offset(10, size.height - 20),
        cellType == 'galvanic' ? Colors.green : Colors.orange, 11, fontWeight: FontWeight.bold);
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Color color) {
    canvas.drawLine(start, end, Paint()
      ..color = color
      ..strokeWidth = 2);

    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    final arrowSize = 8.0;

    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - arrowSize * math.cos(angle - 0.5),
        end.dy - arrowSize * math.sin(angle - 0.5),
      )
      ..lineTo(
        end.dx - arrowSize * math.cos(angle + 0.5),
        end.dy - arrowSize * math.sin(angle + 0.5),
      )
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize,
      {FontWeight fontWeight = FontWeight.normal}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: fontWeight),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _ElectrochemistryPainter oldDelegate) => true;
}
