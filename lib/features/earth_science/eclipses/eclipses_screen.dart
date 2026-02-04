import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class EclipsesScreen extends StatefulWidget {
  final bool isKorean;

  const EclipsesScreen({super.key, required this.isKorean});

  @override
  State<EclipsesScreen> createState() => _EclipsesScreenState();
}

class _EclipsesScreenState extends State<EclipsesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _moonOrbitRadius = 0.6;
  double _moonSize = 0.15;
  bool _isSolarEclipse = true;
  double _animationSpeed = 1.0;
  double _time = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updateAnimation);
    _controller.repeat();
  }

  void _updateAnimation() {
    setState(() {
      _time += 0.005 * _animationSpeed;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _moonOrbitRadius = 0.6;
      _moonSize = 0.15;
      _isSolarEclipse = true;
      _animationSpeed = 1.0;
      _time = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SimulationContainer(
      category: widget.isKorean ? '지구과학' : 'Earth Science',
      title: widget.isKorean ? '일식과 월식' : 'Solar & Lunar Eclipses',
      formula: widget.isKorean
          ? '일식: 달이 태양을 가림\n월식: 지구 그림자가 달을 가림'
          : 'Solar: Moon blocks Sun\nLunar: Earth shadow on Moon',
      simulation: CustomPaint(
        painter: EclipsesPainter(
          time: _time,
          moonOrbitRadius: _moonOrbitRadius,
          moonSize: _moonSize,
          isSolarEclipse: _isSolarEclipse,
        ),
        size: Size.infinite,
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ControlGroup(
            primaryControl: SimToggle(
              label: widget.isKorean ? '일식 / 월식' : 'Solar / Lunar Eclipse',
              value: _isSolarEclipse,
              onChanged: (v) => setState(() => _isSolarEclipse = v),
            ),
          ),
          const SizedBox(height: 16),
          ControlGroup(
            primaryControl: SimSlider(
              label: widget.isKorean ? '달 궤도 반경' : 'Moon Orbit Radius',
              value: _moonOrbitRadius,
              min: 0.4,
              max: 0.8,
              formatValue: (v) => v.toStringAsFixed(2),
              onChanged: (v) => setState(() => _moonOrbitRadius = v),
            ),
            advancedControls: [
              SimSlider(
                label: widget.isKorean ? '달 크기' : 'Moon Size',
                value: _moonSize,
                min: 0.1,
                max: 0.25,
                formatValue: (v) => v.toStringAsFixed(2),
                onChanged: (v) => setState(() => _moonSize = v),
              ),
              SimSlider(
                label: widget.isKorean ? '애니메이션 속도' : 'Animation Speed',
                value: _animationSpeed,
                min: 0.1,
                max: 3.0,
                formatValue: (v) => '${v.toStringAsFixed(1)}x',
                onChanged: (v) => setState(() => _animationSpeed = v),
              ),
            ],
            advancedLabel: widget.isKorean ? '고급 설정' : 'Advanced Settings',
          ),
          const SizedBox(height: 16),
          PresetGroup(
            label: widget.isKorean ? '프리셋' : 'Presets',
            presets: [
              PresetButton(
                label: widget.isKorean ? '개기 일식' : 'Total Solar',
                onPressed: () => setState(() {
                  _isSolarEclipse = true;
                  _moonSize = 0.18;
                  _moonOrbitRadius = 0.5;
                }),
              ),
              PresetButton(
                label: widget.isKorean ? '금환 일식' : 'Annular',
                onPressed: () => setState(() {
                  _isSolarEclipse = true;
                  _moonSize = 0.12;
                  _moonOrbitRadius = 0.7;
                }),
              ),
              PresetButton(
                label: widget.isKorean ? '개기 월식' : 'Total Lunar',
                onPressed: () => setState(() {
                  _isSolarEclipse = false;
                  _moonSize = 0.15;
                  _moonOrbitRadius = 0.6;
                }),
              ),
            ],
          ),
        ],
      ),
      buttons: SimButtonGroup(
        buttons: [
          SimButton(
            label: widget.isKorean ? '초기화' : 'Reset',
            icon: Icons.refresh,
            onPressed: _reset,
          ),
        ],
      ),
    );
  }
}

class EclipsesPainter extends CustomPainter {
  final double time;
  final double moonOrbitRadius;
  final double moonSize;
  final bool isSolarEclipse;

  EclipsesPainter({
    required this.time,
    required this.moonOrbitRadius,
    required this.moonSize,
    required this.isSolarEclipse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scale = math.min(size.width, size.height) / 2;

    // Background - space
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0a0a20),
    );

    // Draw stars
    final starPaint = Paint()..color = Colors.white;
    final random = math.Random(42);
    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.5 + 0.5;
      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }

    if (isSolarEclipse) {
      _drawSolarEclipse(canvas, centerX, centerY, scale);
    } else {
      _drawLunarEclipse(canvas, centerX, centerY, scale);
    }

    // Draw labels
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
    );
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Phase label
    String phaseLabel = isSolarEclipse ? 'Solar Eclipse' : 'Lunar Eclipse';
    textPainter.text = TextSpan(text: phaseLabel, style: textStyle);
    textPainter.layout();
    textPainter.paint(canvas, Offset(20, 20));
  }

  void _drawSolarEclipse(Canvas canvas, double cx, double cy, double scale) {
    // Sun
    final sunRadius = scale * 0.2;
    final sunPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.yellow[100]!, Colors.yellow, Colors.orange],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: sunRadius));
    canvas.drawCircle(Offset(cx, cy), sunRadius, sunPaint);

    // Sun corona
    final coronaPaint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(Offset(cx, cy), sunRadius * 1.5, coronaPaint);

    // Moon position - oscillates back and forth across sun
    final moonAngle = math.sin(time) * 0.5;
    final moonX = cx + moonAngle * scale * moonOrbitRadius;
    final moonY = cy;

    // Moon (dark body)
    final moonRadius = scale * moonSize;
    final moonPaint = Paint()..color = const Color(0xFF1a1a1a);
    canvas.drawCircle(Offset(moonX, moonY), moonRadius, moonPaint);

    // Moon edge highlight
    final edgePaint = Paint()
      ..color = Colors.grey[600]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(moonX, moonY), moonRadius, edgePaint);

    // Shadow cone on Earth (below)
    if ((moonX - cx).abs() < sunRadius) {
      final shadowPath = Path();
      final earthY = cy + scale * 0.8;
      shadowPath.moveTo(moonX - moonRadius * 0.3, moonY + moonRadius);
      shadowPath.lineTo(moonX - 30, earthY);
      shadowPath.lineTo(moonX + 30, earthY);
      shadowPath.lineTo(moonX + moonRadius * 0.3, moonY + moonRadius);
      shadowPath.close();

      final shadowPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.black.withValues(alpha: 0.1),
          ],
        ).createShader(Rect.fromLTWH(moonX - 30, moonY, 60, earthY - moonY));
      canvas.drawPath(shadowPath, shadowPaint);
    }

    // Earth below
    final earthY = cy + scale * 0.8;
    final earthRadius = scale * 0.1;
    _drawEarth(canvas, cx, earthY, earthRadius);
  }

  void _drawLunarEclipse(Canvas canvas, double cx, double cy, double scale) {
    // Sun on the left
    final sunX = cx - scale * 0.7;
    final sunRadius = scale * 0.15;
    final sunPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.yellow[100]!, Colors.yellow, Colors.orange],
      ).createShader(Rect.fromCircle(center: Offset(sunX, cy), radius: sunRadius));
    canvas.drawCircle(Offset(sunX, cy), sunRadius, sunPaint);

    // Sun glow
    final glowPaint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(Offset(sunX, cy), sunRadius * 1.3, glowPaint);

    // Earth in center
    final earthRadius = scale * 0.12;
    _drawEarth(canvas, cx, cy, earthRadius);

    // Earth's shadow (umbra and penumbra)
    final shadowPath = Path();
    final shadowEndX = cx + scale * 0.9;
    shadowPath.moveTo(cx + earthRadius, cy - earthRadius * 0.8);
    shadowPath.lineTo(shadowEndX, cy - earthRadius * 0.3);
    shadowPath.lineTo(shadowEndX, cy + earthRadius * 0.3);
    shadowPath.lineTo(cx + earthRadius, cy + earthRadius * 0.8);
    shadowPath.close();

    final shadowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.black.withValues(alpha: 0.8),
          Colors.black.withValues(alpha: 0.3),
        ],
      ).createShader(Rect.fromLTWH(cx, cy - earthRadius, shadowEndX - cx, earthRadius * 2));
    canvas.drawPath(shadowPath, shadowPaint);

    // Moon position - oscillates through shadow
    final moonPhase = math.sin(time) * 0.5 + 0.5;
    final moonX = cx + scale * (0.3 + moonPhase * 0.4);
    final moonRadius = scale * moonSize * 0.6;

    // Check if moon is in shadow
    final inShadow = moonX > cx + earthRadius && moonX < shadowEndX;

    // Moon
    Color moonColor = Colors.grey[300]!;
    if (inShadow) {
      // Red tint during lunar eclipse
      final shadowDepth = 1.0 - (moonX - cx - earthRadius) / (shadowEndX - cx - earthRadius);
      moonColor = Color.lerp(Colors.grey[300]!, Colors.red[900]!, shadowDepth * 0.7)!;
    }

    final moonPaint = Paint()..color = moonColor;
    canvas.drawCircle(Offset(moonX, cy), moonRadius, moonPaint);

    // Moon craters
    final craterPaint = Paint()..color = moonColor.withValues(alpha: 0.7);
    canvas.drawCircle(Offset(moonX - 3, cy - 2), moonRadius * 0.2, craterPaint);
    canvas.drawCircle(Offset(moonX + 4, cy + 3), moonRadius * 0.15, craterPaint);
  }

  void _drawEarth(Canvas canvas, double x, double y, double radius) {
    // Ocean
    final oceanPaint = Paint()..color = const Color(0xFF1565C0);
    canvas.drawCircle(Offset(x, y), radius, oceanPaint);

    // Continents
    final landPaint = Paint()..color = const Color(0xFF2E7D32);

    // Simple continent shapes
    final continentPath = Path();
    continentPath.addOval(Rect.fromCenter(
      center: Offset(x - radius * 0.3, y - radius * 0.2),
      width: radius * 0.5,
      height: radius * 0.4,
    ));
    continentPath.addOval(Rect.fromCenter(
      center: Offset(x + radius * 0.2, y + radius * 0.3),
      width: radius * 0.4,
      height: radius * 0.3,
    ));
    canvas.drawPath(continentPath, landPaint);

    // Atmosphere glow
    final atmoPaint = Paint()
      ..color = Colors.lightBlue.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(x, y), radius + 2, atmoPaint);
  }

  @override
  bool shouldRepaint(covariant EclipsesPainter oldDelegate) {
    return oldDelegate.time != time ||
           oldDelegate.moonOrbitRadius != moonOrbitRadius ||
           oldDelegate.moonSize != moonSize ||
           oldDelegate.isSolarEclipse != isSolarEclipse;
  }
}
