import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class QuantumKeyDistScreen extends StatefulWidget {
  const QuantumKeyDistScreen({super.key});
  @override
  State<QuantumKeyDistScreen> createState() => _QuantumKeyDistScreenState();
}

class _QuantumKeyDistScreenState extends State<QuantumKeyDistScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _eavesdrop = 0;
  
  double _qber = 0, _keyRate = 1.0; bool _secure = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..addListener(_update);
    _controller.repeat();
  }

  void _update() {
    if (!_isRunning) return;
    setState(() {
      _time += 0.016;
      _qber = _eavesdrop * 0.25;
      _secure = _qber < 11;
      _keyRate = _secure ? (1 - _qber / 100) : 0;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _eavesdrop = 0.0;
    });
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg.withValues(alpha: 0.9),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('양자역학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('BB84 양자 키 분배', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '양자역학 시뮬레이션',
          title: 'BB84 양자 키 분배',
          formula: 'QBER < 11%',
          formulaDescription: 'BB84 양자 키 분배 프로토콜을 시뮬레이션합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _QuantumKeyDistScreenPainter(
                time: _time,
                eavesdrop: _eavesdrop,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '도청률 (%)',
                value: _eavesdrop,
                min: 0,
                max: 50,
                step: 1,
                defaultValue: 0,
                formatValue: (v) => '${v.toStringAsFixed(0)}%',
                onChanged: (v) => setState(() => _eavesdrop = v),
              ),
              
            ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(children: [
          _V('QBER', '${_qber.toStringAsFixed(1)}%'),
          _V('보안', _secure ? '안전' : '위험'),
          _V('키 율', '${(_keyRate * 100).toStringAsFixed(1)}%'),
                ]),
              ),
            ],
          ),
          buttons: SimButtonGroup(expanded: true, buttons: [
            SimButton(
              label: _isRunning ? '정지' : '재생',
              icon: _isRunning ? Icons.pause : Icons.play_arrow,
              isPrimary: true,
              onPressed: () { HapticFeedback.selectionClick(); setState(() => _isRunning = !_isRunning); },
            ),
            SimButton(label: '리셋', icon: Icons.refresh, onPressed: _reset),
          ]),
        ),
      ),
    );
  }
}

class _V extends StatelessWidget {
  final String label, value;
  const _V(this.label, this.value);
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
    const SizedBox(height: 2),
    Text(value, style: const TextStyle(color: AppColors.accent, fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
  ]));
}

class _QuantumKeyDistScreenPainter extends CustomPainter {
  final double time;
  final double eavesdrop;

  _QuantumKeyDistScreenPainter({
    required this.time,
    required this.eavesdrop,
  });

  void _drawText(Canvas canvas, String text, Offset offset,
      {double fontSize = 10, Color color = const Color(0xFFE0F4FF), bool bold = false, TextAlign align = TextAlign.left}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();
    double dx = offset.dx;
    if (align == TextAlign.center) dx -= tp.width / 2;
    tp.paint(canvas, Offset(dx, offset.dy));
  }

  // Draw a polarization symbol inside a circle
  void _drawPhoton(Canvas canvas, Offset center, double r, int polarType, bool isMatch) {
    // polarType: 0=H(↔), 1=V(↕), 2=D(↗), 3=A(↖)
    final circlePaint = Paint()
      ..color = isMatch
          ? const Color(0xFF64FF8C).withValues(alpha: 0.3)
          : const Color(0xFF1A3040)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, r, circlePaint);
    canvas.drawCircle(center, r,
        Paint()..color = isMatch ? const Color(0xFF64FF8C) : const Color(0xFF5A8A9A)..style = PaintingStyle.stroke..strokeWidth = 1);

    final linePaint = Paint()
      ..color = isMatch ? const Color(0xFF64FF8C) : const Color(0xFFE0F4FF)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    switch (polarType) {
      case 0: // H ↔
        canvas.drawLine(Offset(center.dx - r * 0.7, center.dy), Offset(center.dx + r * 0.7, center.dy), linePaint);
      case 1: // V ↕
        canvas.drawLine(Offset(center.dx, center.dy - r * 0.7), Offset(center.dx, center.dy + r * 0.7), linePaint);
      case 2: // D ↗
        canvas.drawLine(Offset(center.dx - r * 0.5, center.dy + r * 0.5), Offset(center.dx + r * 0.5, center.dy - r * 0.5), linePaint);
      case 3: // A ↖
        canvas.drawLine(Offset(center.dx - r * 0.5, center.dy - r * 0.5), Offset(center.dx + r * 0.5, center.dy + r * 0.5), linePaint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;
    final hasEve = eavesdrop > 5;
    final qber = eavesdrop * 0.25;
    final isSecure = qber < 11;

    // --- Layout ---
    // Row 1: Alice | Channel | (Eve) | Bob  ~top 30%
    // Row 2: Bit table (8 bits)           ~middle 40%
    // Row 3: Secret key + QBER            ~bottom 30%

    final row1Y = h * 0.20;
    final row2Top = h * 0.35;
    const nBits = 8;

    // Deterministic bit values from seed
    final rng = math.Random(42);
    final aliceBits = List.generate(nBits, (_) => rng.nextInt(2));
    final aliceBases = List.generate(nBits, (_) => rng.nextInt(2)); // 0=+, 1=×
    final bobBases = List.generate(nBits, (_) => rng.nextInt(2));
    final basisMatch = List.generate(nBits, (i) => aliceBases[i] == bobBases[i]);
    // Bit = Alice's bit if bases match, else random (and Eve causes 25% error)
    final bobBits = List.generate(nBits, (i) {
      if (!basisMatch[i]) { return -1; } // discard
      if (hasEve && rng.nextDouble() < eavesdrop / 200) { return 1 - aliceBits[i]; } // error
      return aliceBits[i];
    });

    // Animate: photon traveling (current bit index)
    final currentBit = (time * 0.8).toInt() % nBits;

    // ===== Row 1: Alice - Channel - Bob =====
    final aliceX = 26.0;
    final bobX = w - 26.0;
    final eveX = w / 2;

    // Alice box
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(aliceX, row1Y), width: 38, height: 22), const Radius.circular(4)),
      Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.15)..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(aliceX, row1Y), width: 38, height: 22), const Radius.circular(4)),
      Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 1,
    );
    _drawText(canvas, 'Alice', Offset(aliceX, row1Y - 5), fontSize: 9, color: const Color(0xFF00D4FF), bold: true, align: TextAlign.center);

    // Bob box
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(bobX, row1Y), width: 38, height: 22), const Radius.circular(4)),
      Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.15)..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(bobX, row1Y), width: 38, height: 22), const Radius.circular(4)),
      Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 1,
    );
    _drawText(canvas, 'Bob', Offset(bobX, row1Y - 5), fontSize: 9, color: const Color(0xFF64FF8C), bold: true, align: TextAlign.center);

    // Quantum channel line
    canvas.drawLine(Offset(aliceX + 20, row1Y), Offset(bobX - 20, row1Y),
        Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.4)..strokeWidth = 1);

    // Eve (if eavesdropping)
    if (hasEve) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(eveX, row1Y - 22), width: 36, height: 18), const Radius.circular(4)),
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.2)..style = PaintingStyle.fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(eveX, row1Y - 22), width: 36, height: 18), const Radius.circular(4)),
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.6)..style = PaintingStyle.stroke..strokeWidth = 1,
      );
      _drawText(canvas, 'Eve', Offset(eveX, row1Y - 27), fontSize: 8, color: const Color(0xFFFF6B35), bold: true, align: TextAlign.center);
      // Eve tap lines
      canvas.drawLine(Offset(eveX, row1Y), Offset(eveX, row1Y - 12),
          Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.6)..strokeWidth = 1);
    }

    // Traveling photon
    final phFrac = (time * 0.8) % 1.0;
    final phX = aliceX + 20 + (bobX - 20 - aliceX - 20) * phFrac;
    final polarType = (aliceBits[currentBit] * 2 + aliceBases[currentBit]) % 4;
    _drawPhoton(canvas, Offset(phX, row1Y), 8, polarType, false);

    // ===== Row 2: Bit table =====
    final colW = (w - 16) / nBits;
    final rowH = (h - row2Top - 44) / 5.5;

    final rowLabels = ['Alice 비트', 'Alice 기저', 'Bob 기저', '기저 일치', 'Bob 비트'];
    final rowColors = [
      const Color(0xFF00D4FF),
      const Color(0xFF00D4FF).withValues(alpha: 0.7),
      const Color(0xFF64FF8C).withValues(alpha: 0.7),
      const Color(0xFFE0F4FF),
      const Color(0xFF64FF8C),
    ];

    for (int row = 0; row < 5; row++) {
      final ry = row2Top + row * rowH;
      _drawText(canvas, rowLabels[row], Offset(4, ry + rowH * 0.2),
          fontSize: 7, color: rowColors[row]);

      for (int col = 0; col < nBits; col++) {
        final cx2 = 8 + colW * col + colW * 0.5;
        final isActive = col == currentBit;
        String cellText = '';
        Color cellColor = const Color(0xFF5A8A9A);

        switch (row) {
          case 0: cellText = '${aliceBits[col]}'; cellColor = const Color(0xFF00D4FF);
          case 1: cellText = aliceBases[col] == 0 ? '+' : '×'; cellColor = const Color(0xFF00D4FF).withValues(alpha: 0.8);
          case 2: cellText = bobBases[col] == 0 ? '+' : '×'; cellColor = const Color(0xFF64FF8C).withValues(alpha: 0.8);
          case 3:
            cellText = basisMatch[col] ? '✓' : '✗';
            cellColor = basisMatch[col] ? const Color(0xFF64FF8C) : const Color(0xFFFF6B35);
          case 4:
            if (!basisMatch[col]) {
              cellText = '-'; cellColor = const Color(0xFF5A8A9A).withValues(alpha: 0.4);
            } else {
              cellText = '${bobBits[col]}';
              cellColor = bobBits[col] == aliceBits[col]
                  ? const Color(0xFF64FF8C)
                  : const Color(0xFFFF4444);
            }
        }

        if (isActive) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(8 + colW * col, ry, colW - 2, rowH - 1),
                const Radius.circular(2)),
            Paint()..color = const Color(0xFF1A3040),
          );
        }
        _drawText(canvas, cellText, Offset(cx2, ry + rowH * 0.15),
            fontSize: 8, color: isActive ? const Color(0xFFFFFFFF) : cellColor, align: TextAlign.center);
      }
    }

    // ===== Row 3: Key + Status =====
    final keyY = h - 34.0;
    _drawText(canvas, '비밀 키: ', Offset(8, keyY), fontSize: 8, color: const Color(0xFF5A8A9A));
    double kx = 56.0;
    for (int i = 0; i < nBits; i++) {
      if (!basisMatch[i]) { continue; }
      final bit = bobBits[i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(kx, keyY - 1, 14, 13), const Radius.circular(2)),
        Paint()..color = isSecure
            ? const Color(0xFF64FF8C).withValues(alpha: 0.2)
            : const Color(0xFFFF6B35).withValues(alpha: 0.2),
      );
      _drawText(canvas, '$bit', Offset(kx + 7, keyY),
          fontSize: 8,
          color: bit == aliceBits[i]
              ? (isSecure ? const Color(0xFF64FF8C) : const Color(0xFFFF6B35))
              : const Color(0xFFFF4444),
          align: TextAlign.center);
      kx += 16;
    }

    _drawText(canvas, 'QBER=${qber.toStringAsFixed(1)}%',
        Offset(w * 0.72, keyY), fontSize: 8,
        color: isSecure ? const Color(0xFF64FF8C) : const Color(0xFFFF4444));
    _drawText(canvas, isSecure ? '보안' : '도청감지!',
        Offset(w - 6, keyY), fontSize: 9, bold: true,
        color: isSecure ? const Color(0xFF64FF8C) : const Color(0xFFFF4444), align: TextAlign.right);

    // Threshold note
    _drawText(canvas, 'QBER < 11% → 안전', Offset(w / 2, h - 16),
        fontSize: 7, color: const Color(0xFF5A8A9A), align: TextAlign.center);
  }

  @override
  bool shouldRepaint(covariant _QuantumKeyDistScreenPainter oldDelegate) => true;
}
