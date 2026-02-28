import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class PlanetFormationScreen extends StatefulWidget {
  const PlanetFormationScreen({super.key});
  @override
  State<PlanetFormationScreen> createState() => _PlanetFormationScreenState();
}

class _PlanetFormationScreenState extends State<PlanetFormationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _diskMass = 100;
  
  double _planetMass = 0.01, _accretionRate = 0;

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
      _accretionRate = 0.001 * math.pow(_planetMass, 2/3).toDouble() * _diskMass / 100;
      _planetMass += _accretionRate * 0.016;
      if (_planetMass > _diskMass) _planetMass = _diskMass;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _diskMass = 100.0; _planetMass = 0.01;
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
          Text('천문학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('행성 형성 (강착)', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '천문학 시뮬레이션',
          title: '행성 형성 (강착)',
          formula: 'dM/dt ∝ M^(2/3)',
          formulaDescription: '원시행성 원반에서의 행성 형성 과정을 시뮬레이션합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _PlanetFormationScreenPainter(
                time: _time,
                diskMass: _diskMass,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '원반 질량 (M⊕)',
                value: _diskMass,
                min: 10,
                max: 1000,
                step: 10,
                defaultValue: 100,
                formatValue: (v) => v.toStringAsFixed(0) + ' M⊕',
                onChanged: (v) => setState(() => _diskMass = v),
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
          _V('행성 질량', _planetMass.toStringAsFixed(2) + ' M⊕'),
          _V('강착률', _accretionRate.toStringAsFixed(4)),
          _V('원반', _diskMass.toStringAsFixed(0) + ' M⊕'),
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

class _PlanetFormationScreenPainter extends CustomPainter {
  final double time;
  final double diskMass;

  _PlanetFormationScreenPainter({
    required this.time,
    required this.diskMass,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final cx = size.width / 2;
    final cy = size.height * 0.46;
    final maxDiskR = math.min(size.width, size.height) * 0.44;

    // Disk mass fraction (0..1)
    final diskFrac = (diskMass / 1000.0).clamp(0.0, 1.0);
    // Planet mass grows with time (simulate accretion)
    final tMyr = (time * 0.3) % 10.0; // 0..10 Myr cycle
    final planetFrac = (1 - math.exp(-tMyr * 0.4)).clamp(0.0, 1.0);
    final planetR = 4.0 + 14.0 * planetFrac * diskFrac;

    // --- Draw disk rings with gradient opacity ---
    // Outer glow of disk
    for (int ring = 12; ring >= 1; ring--) {
      final r = maxDiskR * ring / 12.0;
      final alpha = (0.04 + 0.06 * (12 - ring) / 12.0) * diskFrac;
      // Color: warm inner, cold outer
      final warmFrac = 1.0 - ring / 12.0;
      final col = Color.fromARGB(
        (alpha * 255).round().clamp(0, 255),
        (180 * warmFrac + 40 * (1 - warmFrac)).round(),
        (100 * warmFrac + 80 * (1 - warmFrac)).round(),
        (20 * warmFrac + 60 * (1 - warmFrac)).round(),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 0.55),
        Paint()..color = col,
      );
    }

    // Snowline (dashed circle at ~40% radius)
    final snowlineR = maxDiskR * 0.42;
    final snowPaint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const dashLen = 6.0;
    final circumference = 2 * math.pi * snowlineR * 0.28; // ellipse approx
    final totalDashes = (circumference / dashLen / 2).round().clamp(8, 40);
    for (int i = 0; i < totalDashes; i++) {
      final a1 = 2 * math.pi * i / totalDashes;
      final a2 = 2 * math.pi * (i + 0.5) / totalDashes;
      canvas.drawLine(
        Offset(cx + snowlineR * math.cos(a1), cy + snowlineR * 0.275 * math.sin(a1)),
        Offset(cx + snowlineR * math.cos(a2), cy + snowlineR * 0.275 * math.sin(a2)),
        snowPaint,
      );
    }
    // Snowline label
    final sltp = TextPainter(
      text: const TextSpan(
        text: '강설선',
        style: TextStyle(color: Color(0xFF00D4FF), fontSize: 8),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    sltp.paint(canvas, Offset(cx + snowlineR + 3, cy - sltp.height / 2));

    // --- Planetesimals (small dots orbiting) ---
    final rng2 = math.Random(7);
    for (int i = 0; i < 28; i++) {
      final baseAngle = rng2.nextDouble() * 2 * math.pi;
      final orbitFrac = 0.18 + rng2.nextDouble() * 0.78;
      final orbitR = maxDiskR * orbitFrac;
      final speed = 0.3 + (1.0 - orbitFrac) * 0.9;
      final angle = baseAngle + time * speed;
      final x = cx + orbitR * math.cos(angle);
      final y = cy + orbitR * 0.275 * math.sin(angle);
      final pSize = 1.2 + rng2.nextDouble() * 1.6;
      final alpha = diskFrac * (0.4 + rng2.nextDouble() * 0.5);
      canvas.drawCircle(
        Offset(x, y),
        pSize,
        Paint()
          ..color = const Color(0xFFFF6B35).withValues(alpha: alpha.clamp(0, 1)),
      );
    }

    // --- Rocky (inner) and Gas giant (outer) zones ---
    // Rocky zone label (< snowline)
    final rztp = TextPainter(
      text: const TextSpan(
        text: '지구형',
        style: TextStyle(color: Color(0xFFFF6B35), fontSize: 8),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    rztp.paint(canvas, Offset(cx - snowlineR * 0.5 - rztp.width / 2, cy - 8));

    final gztp = TextPainter(
      text: const TextSpan(
        text: '목성형',
        style: TextStyle(color: Color(0xFF64FF8C), fontSize: 8),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    gztp.paint(canvas, Offset(cx + snowlineR * 1.1, cy - 8));

    // --- Planet embryo at ~25% radius ---
    final embryoAngle = time * 0.25;
    final embryoR = maxDiskR * 0.26;
    final embryoX = cx + embryoR * math.cos(embryoAngle);
    final embryoY = cy + embryoR * 0.275 * math.sin(embryoAngle);
    // Accretion glow
    canvas.drawCircle(
      Offset(embryoX, embryoY),
      planetR + 4,
      Paint()
        ..color = const Color(0xFFFF6B35).withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(
      Offset(embryoX, embryoY),
      planetR,
      Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.9),
    );
    canvas.drawCircle(
      Offset(embryoX, embryoY),
      planetR,
      Paint()
        ..color = const Color(0xFFFFAA66)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // --- Central star ---
    canvas.drawCircle(
      Offset(cx, cy),
      10,
      Paint()
        ..color = const Color(0xFFFFDD44).withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(Offset(cx, cy), 7, Paint()..color = const Color(0xFFFFEE88));
    canvas.drawCircle(
      Offset(cx, cy),
      7,
      Paint()
        ..color = const Color(0xFFFFDD44)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // --- Info panel top ---
    final tMyrStr = tMyr.toStringAsFixed(1);
    void drawLabel(String text, Offset pos, Color col, double fs) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: TextStyle(color: col, fontSize: fs)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos);
    }

    drawLabel('시간: $tMyrStr Myr', const Offset(8, 8), const Color(0xFF5A8A9A), 10);
    drawLabel(
      '행성 배아: ${planetR.toStringAsFixed(1)} km×100',
      Offset(8, 22),
      const Color(0xFFFF6B35),
      9,
    );

    // --- Disk dissipation indicator (top right) ---
    final dissipFrac = planetFrac;
    drawLabel('원반 소산', Offset(size.width - 60, 8), const Color(0xFF5A8A9A), 9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - 60, 21, 52, 7),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF1A3040),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - 60, 21, 52 * (1 - dissipFrac * diskFrac), 7),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.7),
    );

    // --- Bottom comparison: current vs finished solar system ---
    final compY = size.height * 0.88;
    drawLabel('현재 태양계: ☀ ○ ○ ○ ○ ● ● ● ●', Offset(8, compY),
        const Color(0xFF5A8A9A), 8);
  }

  @override
  bool shouldRepaint(covariant _PlanetFormationScreenPainter oldDelegate) => true;
}
