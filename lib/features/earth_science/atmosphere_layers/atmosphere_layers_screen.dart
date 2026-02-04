import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Atmospheric Layers Simulation
class AtmosphereLayersScreen extends StatefulWidget {
  const AtmosphereLayersScreen({super.key});

  @override
  State<AtmosphereLayersScreen> createState() => _AtmosphereLayersScreenState();
}

class _AtmosphereLayersScreenState extends State<AtmosphereLayersScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _time = 0.0;
  double _altitude = 0.0; // km
  bool _isAnimating = true;
  int _selectedLayer = -1;
  bool _showTemperature = true;
  bool _isKorean = true;

  // Layer data: [name, nameKr, minAlt, maxAlt, color, avgTemp]
  static const List<Map<String, dynamic>> _layers = [
    {'name': 'Troposphere', 'nameKr': '대류권', 'minAlt': 0, 'maxAlt': 12, 'color': 0xFF87CEEB, 'temp': '15 to -56'},
    {'name': 'Stratosphere', 'nameKr': '성층권', 'minAlt': 12, 'maxAlt': 50, 'color': 0xFF4169E1, 'temp': '-56 to -2'},
    {'name': 'Mesosphere', 'nameKr': '중간권', 'minAlt': 50, 'maxAlt': 80, 'color': 0xFF191970, 'temp': '-2 to -92'},
    {'name': 'Thermosphere', 'nameKr': '열권', 'minAlt': 80, 'maxAlt': 700, 'color': 0xFF0D0D2B, 'temp': '-92 to 1200'},
    {'name': 'Exosphere', 'nameKr': '외기권', 'minAlt': 700, 'maxAlt': 10000, 'color': 0xFF000010, 'temp': '~1200'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateAnimation);
    _controller.repeat();
  }

  void _updateAnimation() {
    if (!_isAnimating) return;
    setState(() {
      _time += 0.02;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _altitude = 0;
      _selectedLayer = -1;
      _isAnimating = true;
    });
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
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isKorean ? '지구과학 시뮬레이션' : 'EARTH SCIENCE SIMULATION',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              _isKorean ? '대기층' : 'Atmospheric Layers',
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => setState(() => _isKorean = !_isKorean),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: _isKorean ? '지구과학 시뮬레이션' : 'EARTH SCIENCE SIMULATION',
          title: _isKorean ? '대기층' : 'Atmospheric Layers',
          formula: 'P = P₀ × e^(-h/H)',
          formulaDescription: _isKorean
              ? '대기압은 고도에 따라 지수적으로 감소합니다. 대기는 온도 변화에 따라 5개 층으로 나뉩니다: 대류권, 성층권, 중간권, 열권, 외기권.'
              : 'Atmospheric pressure decreases exponentially with altitude. The atmosphere has 5 layers based on temperature: Troposphere, Stratosphere, Mesosphere, Thermosphere, Exosphere.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: AtmosphereLayersPainter(
                time: _time,
                altitude: _altitude,
                selectedLayer: _selectedLayer,
                showTemperature: _showTemperature,
                isKorean: _isKorean,
                layers: _layers,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PresetGroup(
                label: _isKorean ? '대기층 선택' : 'Select Layer',
                presets: List.generate(_layers.length, (index) {
                  return PresetButton(
                    label: _isKorean ? _layers[index]['nameKr'] : _layers[index]['name'],
                    isSelected: _selectedLayer == index,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedLayer = _selectedLayer == index ? -1 : index;
                        if (_selectedLayer >= 0) {
                          _altitude = (_layers[index]['minAlt'] + _layers[index]['maxAlt']) / 2.0;
                        }
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              ControlGroup(
                primaryControl: SimSlider(
                  label: _isKorean ? '고도' : 'Altitude',
                  value: _altitude,
                  min: 0,
                  max: 500,
                  defaultValue: 0,
                  formatValue: (v) => '${v.toStringAsFixed(0)} km',
                  onChanged: (v) => setState(() => _altitude = v),
                ),
                advancedControls: [
                  SimToggle(
                    label: _isKorean ? '온도 프로파일' : 'Temperature Profile',
                    value: _showTemperature,
                    onChanged: (v) => setState(() => _showTemperature = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(altitude: _altitude, selectedLayer: _selectedLayer, layers: _layers, isKorean: _isKorean),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: _isAnimating
                    ? (_isKorean ? '정지' : 'Pause')
                    : (_isKorean ? '재생' : 'Play'),
                icon: _isAnimating ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isAnimating = !_isAnimating);
                },
              ),
              SimButton(
                label: _isKorean ? '리셋' : 'Reset',
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

class _InfoCard extends StatelessWidget {
  final double altitude;
  final int selectedLayer;
  final List<Map<String, dynamic>> layers;
  final bool isKorean;

  const _InfoCard({
    required this.altitude,
    required this.selectedLayer,
    required this.layers,
    required this.isKorean,
  });

  int _getLayerAtAltitude(double alt) {
    for (int i = 0; i < layers.length; i++) {
      if (alt >= layers[i]['minAlt'] && alt < layers[i]['maxAlt']) {
        return i;
      }
    }
    return layers.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    final currentLayer = selectedLayer >= 0 ? selectedLayer : _getLayerAtAltitude(altitude);
    final layer = layers[currentLayer];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.simBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(layer['color']).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Color(layer['color']),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isKorean ? layer['nameKr'] : layer['name'],
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isKorean
                ? '고도: ${layer['minAlt']}-${layer['maxAlt']} km'
                : 'Altitude: ${layer['minAlt']}-${layer['maxAlt']} km',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            isKorean ? '온도 범위: ${layer['temp']}°C' : 'Temperature: ${layer['temp']}°C',
            style: TextStyle(color: AppColors.accent, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class AtmosphereLayersPainter extends CustomPainter {
  final double time;
  final double altitude;
  final int selectedLayer;
  final bool showTemperature;
  final bool isKorean;
  final List<Map<String, dynamic>> layers;

  AtmosphereLayersPainter({
    required this.time,
    required this.altitude,
    required this.selectedLayer,
    required this.showTemperature,
    required this.isKorean,
    required this.layers,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw atmosphere layers
    _drawLayers(canvas, size);

    // Draw Earth at bottom
    _drawEarth(canvas, size);

    // Draw temperature profile
    if (showTemperature) {
      _drawTemperatureProfile(canvas, size);
    }

    // Draw altitude indicator
    _drawAltitudeIndicator(canvas, size);

    // Draw objects at various altitudes
    _drawAtmosphericObjects(canvas, size);

    // Draw layer labels
    _drawLabels(canvas, size);
  }

  void _drawLayers(Canvas canvas, Size size) {
    final totalHeight = size.height * 0.85;
    final earthHeight = size.height * 0.15;

    // Logarithmic scale for altitude display
    double altToY(double alt) {
      if (alt <= 0) return size.height - earthHeight;
      final logAlt = math.log(alt + 1) / math.log(501); // Log scale to 500km
      return size.height - earthHeight - logAlt * totalHeight;
    }

    for (int i = layers.length - 1; i >= 0; i--) {
      final layer = layers[i];
      final minY = altToY(math.min(layer['maxAlt'].toDouble(), 500.0));
      final maxY = altToY(layer['minAlt'].toDouble());

      final isSelected = selectedLayer == i;

      final layerPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(layer['color']).withValues(alpha: isSelected ? 1.0 : 0.7),
            Color(layer['color']).withValues(alpha: isSelected ? 0.8 : 0.5),
          ],
        ).createShader(Rect.fromLTRB(0, minY, size.width, maxY));

      canvas.drawRect(
        Rect.fromLTRB(0, minY, size.width * 0.7, maxY),
        layerPaint,
      );

      // Layer boundary line
      if (i > 0) {
        canvas.drawLine(
          Offset(0, maxY),
          Offset(size.width * 0.7, maxY),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.3)
            ..strokeWidth = 1,
        );
      }
    }
  }

  void _drawEarth(Canvas canvas, Size size) {
    final earthTop = size.height * 0.85;

    // Earth surface
    canvas.drawRect(
      Rect.fromLTWH(0, earthTop, size.width * 0.7, size.height * 0.15),
      Paint()..color = const Color(0xFF228B22),
    );

    // Ocean
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.3, earthTop, size.width * 0.2, size.height * 0.15),
      Paint()..color = const Color(0xFF1E90FF),
    );
  }

  void _drawTemperatureProfile(Canvas canvas, Size size) {
    final graphLeft = size.width * 0.75;
    final graphRight = size.width - 10;
    final graphTop = size.height * 0.05;
    final graphBottom = size.height * 0.85;

    // Temperature axis
    canvas.drawLine(
      Offset(graphLeft, graphTop),
      Offset(graphLeft, graphBottom),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..strokeWidth = 1,
    );

    // Temperature profile curve
    final tempPath = Path();

    // Simplified temperature profile
    final tempPoints = [
      [0.0, 15.0],      // Surface
      [12.0, -56.0],    // Tropopause
      [50.0, -2.0],     // Stratopause
      [80.0, -92.0],    // Mesopause
      [200.0, 500.0],   // Thermosphere
      [500.0, 1000.0],  // Upper thermosphere
    ];

    bool first = true;
    for (final point in tempPoints) {
      final alt = point[0];
      final temp = point[1];

      // Convert altitude to Y (log scale)
      double y;
      if (alt <= 0) {
        y = graphBottom;
      } else {
        final logAlt = math.log(alt + 1) / math.log(501);
        y = graphBottom - logAlt * (graphBottom - graphTop);
      }

      // Convert temperature to X (-100 to 100 range mapped to graph width)
      final x = graphLeft + (temp + 100) / 200 * (graphRight - graphLeft - 10);

      if (first) {
        tempPath.moveTo(x.clamp(graphLeft, graphRight), y);
        first = false;
      } else {
        tempPath.lineTo(x.clamp(graphLeft, graphRight), y);
      }
    }

    canvas.drawPath(
      tempPath,
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Temperature label
    final textPainter = TextPainter(
      text: TextSpan(
        text: isKorean ? '온도' : 'Temp',
        style: const TextStyle(color: Colors.red, fontSize: 9),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(graphLeft + 5, graphTop - 15));
  }

  void _drawAltitudeIndicator(Canvas canvas, Size size) {
    final totalHeight = size.height * 0.85;
    final earthHeight = size.height * 0.15;

    // Convert altitude to Y position
    double y;
    if (altitude <= 0) {
      y = size.height - earthHeight;
    } else {
      final logAlt = math.log(altitude + 1) / math.log(501);
      y = size.height - earthHeight - logAlt * totalHeight;
    }

    // Horizontal indicator line
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width * 0.7, y),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2,
    );

    // Altitude label
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${altitude.toStringAsFixed(0)} km',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(5, y - 15));
  }

  void _drawAtmosphericObjects(Canvas canvas, Size size) {
    final totalHeight = size.height * 0.85;
    final earthHeight = size.height * 0.15;

    double altToY(double alt) {
      if (alt <= 0) return size.height - earthHeight;
      final logAlt = math.log(alt + 1) / math.log(501);
      return size.height - earthHeight - logAlt * totalHeight;
    }

    // Airplane (10 km)
    final planeY = altToY(10);
    _drawPlane(canvas, size.width * 0.3 + math.sin(time) * 20, planeY);

    // Weather balloon (30 km)
    final balloonY = altToY(30);
    canvas.drawCircle(
      Offset(size.width * 0.5, balloonY),
      8,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );

    // Meteor (80 km)
    if ((time * 10).toInt() % 30 < 10) {
      final meteorY = altToY(80);
      canvas.drawLine(
        Offset(size.width * 0.4, meteorY),
        Offset(size.width * 0.45, meteorY + 15),
        Paint()
          ..color = const Color(0xFFFFD700)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }

    // Satellite (400 km)
    final satelliteY = altToY(400);
    final satelliteX = size.width * 0.4 + math.sin(time * 0.5) * 30;
    _drawSatellite(canvas, satelliteX, satelliteY);

    // Aurora (100 km)
    final auroraY = altToY(100);
    _drawAurora(canvas, size, auroraY);
  }

  void _drawPlane(Canvas canvas, double x, double y) {
    final planePath = Path()
      ..moveTo(x - 15, y)
      ..lineTo(x + 15, y)
      ..lineTo(x + 10, y - 3)
      ..lineTo(x - 5, y - 3)
      ..close();

    canvas.drawPath(planePath, Paint()..color = Colors.white);

    // Wings
    canvas.drawLine(
      Offset(x - 5, y),
      Offset(x - 5, y + 10),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(x + 5, y),
      Offset(x + 5, y + 10),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2,
    );
  }

  void _drawSatellite(Canvas canvas, double x, double y) {
    // Body
    canvas.drawRect(
      Rect.fromCenter(center: Offset(x, y), width: 8, height: 6),
      Paint()..color = Colors.grey,
    );

    // Solar panels
    canvas.drawRect(
      Rect.fromCenter(center: Offset(x - 12, y), width: 10, height: 4),
      Paint()..color = const Color(0xFF1E90FF),
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(x + 12, y), width: 10, height: 4),
      Paint()..color = const Color(0xFF1E90FF),
    );
  }

  void _drawAurora(Canvas canvas, Size size, double y) {
    for (int i = 0; i < 5; i++) {
      final x = size.width * 0.1 + i * size.width * 0.12;
      final height = 20 + math.sin(time + i) * 10;

      final auroraGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.green.withValues(alpha: 0.0),
          Colors.green.withValues(alpha: 0.5),
          Colors.cyan.withValues(alpha: 0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(x, y - height, 15, height * 2));

      canvas.drawRect(
        Rect.fromLTWH(x, y - height, 15, height * 2),
        Paint()..shader = auroraGradient,
      );
    }
  }

  void _drawLabels(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final totalHeight = size.height * 0.85;
    final earthHeight = size.height * 0.15;

    double altToY(double alt) {
      if (alt <= 0) return size.height - earthHeight;
      final logAlt = math.log(alt + 1) / math.log(501);
      return size.height - earthHeight - logAlt * totalHeight;
    }

    // Layer names on the right
    for (int i = 0; i < layers.length; i++) {
      final layer = layers[i];
      final midAlt = (layer['minAlt'] + math.min(layer['maxAlt'], 400)) / 2.0;
      final y = altToY(midAlt);

      textPainter.text = TextSpan(
        text: isKorean ? layer['nameKr'] : layer['name'],
        style: TextStyle(
          color: selectedLayer == i ? Colors.white : Colors.white70,
          fontSize: selectedLayer == i ? 11 : 9,
          fontWeight: selectedLayer == i ? FontWeight.bold : FontWeight.normal,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width * 0.72 - textPainter.width, y - 5));
    }
  }

  @override
  bool shouldRepaint(covariant AtmosphereLayersPainter oldDelegate) {
    return time != oldDelegate.time ||
        altitude != oldDelegate.altitude ||
        selectedLayer != oldDelegate.selectedLayer ||
        showTemperature != oldDelegate.showTemperature;
  }
}
