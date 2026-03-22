import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/language_provider.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------
const int _gridW = 60;
const int _gridH = 60;
const int _particleCount = _gridW * _gridH; // 3,600
const double _particleSize = 1.5;
const double _damping = 0.96;
const double _waveSpeed = 0.25;
const int _maxPlayers = 10;
const int _botCount = 3;
const Duration _longPressWaveDuration = Duration(seconds: 10);

// ---------------------------------------------------------------------------
// Wave mode
// ---------------------------------------------------------------------------
enum WaveMode {
  waveEquation,
  ripple,
  spiral,
  radialBurst,
  freeMode,
}

extension WaveModeLabel on WaveMode {
  String label(bool isKorean) {
    switch (this) {
      case WaveMode.waveEquation:
        return isKorean ? '파동 방정식' : 'Wave Equation';
      case WaveMode.ripple:
        return isKorean ? '물결 패턴' : 'Ripple';
      case WaveMode.spiral:
        return isKorean ? '나선 소용돌이' : 'Spiral';
      case WaveMode.radialBurst:
        return isKorean ? '별 폭발' : 'Radial Burst';
      case WaveMode.freeMode:
        return isKorean ? '자유 모드' : 'Free Mode';
    }
  }
}

// ---------------------------------------------------------------------------
// Neon color palette
// ---------------------------------------------------------------------------
const List<Color> _neonPalette = [
  Color(0xFFFF2D78), // pink
  Color(0xFF00D4FF), // cyan
  Color(0xFFBB44FF), // purple
  Color(0xFF64FF8C), // green
  Color(0xFFFFD700), // gold
  Color(0xFFFF6B35), // orange
];

// ---------------------------------------------------------------------------
// Player
// ---------------------------------------------------------------------------
class _Player {
  _Player({
    required this.id,
    required this.name,
    required this.color,
    this.isBot = false,
  });
  final String id;
  final String name;
  final Color color;
  final bool isBot;
}

// ---------------------------------------------------------------------------
// Wave source
// ---------------------------------------------------------------------------
class _WaveSource {
  _WaveSource({
    required this.x,
    required this.y,
    required this.strength,
    required this.color,
    required this.createdAt,
    this.duration = const Duration(milliseconds: 800),
    this.continuous = false,
  });
  final double x;
  final double y;
  final double strength;
  final Color color;
  final DateTime createdAt;
  final Duration duration;
  final bool continuous;

  bool get isExpired =>
      !continuous && DateTime.now().difference(createdAt) > duration;
}

// ---------------------------------------------------------------------------
// ParticleWaveScreen
// ---------------------------------------------------------------------------
class ParticleWaveScreen extends ConsumerStatefulWidget {
  const ParticleWaveScreen({super.key});

  @override
  ConsumerState<ParticleWaveScreen> createState() => _ParticleWaveScreenState();
}

class _ParticleWaveScreenState extends ConsumerState<ParticleWaveScreen>
    with SingleTickerProviderStateMixin {
  late Float32List _heights;
  late Float32List _velocities;
  late Float32List _prevHeights;

  String _roomCode = '';
  bool _inRoom = false;
  WaveMode _mode = WaveMode.freeMode;
  final List<_Player> _players = [];
  final List<_WaveSource> _waveSources = [];

  int _selectedColorIdx = 1;
  bool _isDragging = false;
  _WaveSource? _longPressWave;

  late Ticker _ticker;
  double _elapsed = 0;
  final math.Random _rng = math.Random();
  double _nextBotAction = 0;

  @override
  void initState() {
    super.initState();
    _heights = Float32List(_particleCount);
    _velocities = Float32List(_particleCount);
    _prevHeights = Float32List(_particleCount);
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // -- Room management --

  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(4, (_) => chars[_rng.nextInt(chars.length)]).join();
  }

  void _createRoom() {
    setState(() {
      _roomCode = _generateRoomCode();
      _inRoom = true;
      _players
        ..clear()
        ..add(_Player(
            id: 'me',
            name: 'You',
            color: _neonPalette[_selectedColorIdx]));
      for (int i = 0; i < _botCount; i++) {
        _players.add(_Player(
          id: 'bot_$i',
          name: 'Bot ${i + 1}',
          color: _neonPalette[(i + 2) % _neonPalette.length],
          isBot: true,
        ));
      }
    });
  }

  void _joinRoom(String code) {
    setState(() {
      _roomCode = code.toUpperCase();
      _inRoom = true;
      _players
        ..clear()
        ..add(_Player(
            id: 'me',
            name: 'You',
            color: _neonPalette[_selectedColorIdx]));
      for (int i = 0; i < _botCount; i++) {
        _players.add(_Player(
          id: 'bot_$i',
          name: 'Bot ${i + 1}',
          color: _neonPalette[(i + 2) % _neonPalette.length],
          isBot: true,
        ));
      }
    });
  }

  void _leaveRoom() {
    setState(() {
      _inRoom = false;
      _roomCode = '';
      _players.clear();
      _waveSources.clear();
      _heights.fillRange(0, _particleCount, 0);
      _velocities.fillRange(0, _particleCount, 0);
      _prevHeights.fillRange(0, _particleCount, 0);
    });
  }

  // -- Tick / Physics --

  void _onTick(Duration elapsed) {
    final dt = elapsed.inMicroseconds / 1e6;
    _elapsed = dt;
    if (!_inRoom) return;
    _tickBots(dt);
    _waveSources.removeWhere((s) => s.isExpired);
    _applyWaveSources();
    _propagate();
  }

  void _tickBots(double time) {
    if (time < _nextBotAction) return;
    _nextBotAction = time + 0.8 + _rng.nextDouble() * 2.0;
    for (final p in _players) {
      if (!p.isBot) continue;
      if (_rng.nextDouble() > 0.5) continue;
      _waveSources.add(_WaveSource(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        strength: 0.6 + _rng.nextDouble() * 0.4,
        color: p.color,
        createdAt: DateTime.now(),
        duration: const Duration(milliseconds: 1200),
      ));
    }
  }

  void _applyWaveSources() {
    for (final src in _waveSources) {
      final gx = (src.x * _gridW).clamp(0, _gridW - 1).toInt();
      final gy = (src.y * _gridH).clamp(0, _gridH - 1).toInt();
      const radius = 3;
      for (int dy = -radius; dy <= radius; dy++) {
        for (int dx = -radius; dx <= radius; dx++) {
          final nx = gx + dx;
          final ny = gy + dy;
          if (nx < 0 || nx >= _gridW || ny < 0 || ny >= _gridH) continue;
          final dist = math.sqrt(dx * dx + dy * dy);
          if (dist > radius) continue;
          final falloff = 1.0 - dist / (radius + 1);
          final idx = ny * _gridW + nx;
          _heights[idx] += src.strength * falloff * 0.3;
        }
      }
    }
  }

  void _propagate() {
    final tmp = Float32List(_particleCount);
    for (int y = 1; y < _gridH - 1; y++) {
      for (int x = 1; x < _gridW - 1; x++) {
        final i = y * _gridW + x;
        final laplacian = _heights[i - 1] +
            _heights[i + 1] +
            _heights[i - _gridW] +
            _heights[i + _gridW] -
            4.0 * _heights[i];
        _velocities[i] += laplacian * _waveSpeed;
        _velocities[i] *= _damping;
        tmp[i] = _heights[i] + _velocities[i];
      }
    }
    for (int i = 0; i < _particleCount; i++) {
      _prevHeights[i] = _heights[i];
      _heights[i] = tmp[i];
    }
  }

  // -- Interaction --

  void _addWaveAt(Offset local, Size canvasSize,
      {double strength = 1.0,
      bool continuous = false,
      Duration duration = const Duration(milliseconds: 800)}) {
    if (!_inRoom) return;
    _waveSources.add(_WaveSource(
      x: (local.dx / canvasSize.width).clamp(0.0, 1.0),
      y: (local.dy / canvasSize.height).clamp(0.0, 1.0),
      strength: strength,
      color: _neonPalette[_selectedColorIdx],
      createdAt: DateTime.now(),
      duration: duration,
      continuous: continuous,
    ));
  }

  // -- Mode offset --

  Offset _modeOffset(int gx, int gy, double h, double cellW, double cellH) {
    final baseX = gx * cellW + cellW * 0.5;
    final baseY = gy * cellH + cellH * 0.5;

    switch (_mode) {
      case WaveMode.waveEquation:
      case WaveMode.freeMode:
        return Offset(baseX, baseY + h * 8.0);

      case WaveMode.ripple:
        final angle = math.atan2(gy - _gridH / 2, gx - _gridW / 2);
        return Offset(
          baseX + math.cos(angle) * h * 4.0,
          baseY + math.sin(angle) * h * 4.0,
        );

      case WaveMode.spiral:
        final angle =
            math.atan2(gy - _gridH / 2, gx - _gridW / 2) + h * 2.0;
        final dist = math.sqrt(
            math.pow(gx - _gridW / 2, 2) + math.pow(gy - _gridH / 2, 2));
        final spiralR = dist * cellW * 0.15 + h.abs() * 6.0;
        return Offset(
          baseX + math.cos(angle) * spiralR * 0.3,
          baseY + math.sin(angle) * spiralR * 0.3,
        );

      case WaveMode.radialBurst:
        final angle = math.atan2(gy - _gridH / 2, gx - _gridW / 2);
        final push = h * 12.0;
        return Offset(
          baseX + math.cos(angle) * push,
          baseY + math.sin(angle) * push,
        );
    }
  }

  // -- Build --

  @override
  Widget build(BuildContext context) {
    final isKorean = ref.watch(isKoreanProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar:
          _inRoom ? _buildRoomAppBar(isKorean) : _buildLobbyAppBar(isKorean),
      body: _inRoom ? _buildSimulation(isKorean) : _buildLobby(isKorean),
    );
  }

  PreferredSizeWidget _buildLobbyAppBar(bool isKorean) {
    return AppBar(
      backgroundColor: Colors.black,
      title: Text(
        isKorean ? '파티클 파동 플레이그라운드' : 'Particle Wave Playground',
        style: const TextStyle(color: AppColors.accent, fontSize: 18),
      ),
      centerTitle: true,
      iconTheme: const IconThemeData(color: AppColors.accent),
    );
  }

  Widget _buildLobby(bool isKorean) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.waves,
                size: 80,
                color: AppColors.accent.withValues(alpha: 0.6)),
            const SizedBox(height: 24),
            Text(
              isKorean ? '멀티 파동 시뮬레이션' : 'Multi Wave Simulation',
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isKorean
                  ? '방을 만들거나 코드를 입력하세요'
                  : 'Create a room or enter a code',
              style: const TextStyle(color: AppColors.muted, fontSize: 14),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _createRoom,
                icon: const Icon(Icons.add_circle_outline),
                label: Text(isKorean ? '방 생성' : 'Create Room'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _JoinRoomField(isKorean: isKorean, onJoin: _joinRoom),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildRoomAppBar(bool isKorean) {
    return AppBar(
      backgroundColor: Colors.black,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.accent),
        onPressed: _leaveRoom,
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.accent, width: 1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _roomCode,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _mode.label(isKorean),
            style: const TextStyle(color: AppColors.ink, fontSize: 14),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.people, size: 16, color: AppColors.muted),
          const SizedBox(width: 4),
          Text(
            '${_players.length}/$_maxPlayers',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        PopupMenuButton<WaveMode>(
          icon: const Icon(Icons.tune, color: AppColors.accent),
          color: AppColors.card,
          onSelected: (m) => setState(() => _mode = m),
          itemBuilder: (_) => WaveMode.values
              .map((m) => PopupMenuItem(
                    value: m,
                    child: Text(
                      m.label(ref.read(isKoreanProvider)),
                      style: TextStyle(
                        color:
                            _mode == m ? AppColors.accent : AppColors.ink,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSimulation(bool isKorean) {
    return Column(
      children: [
        Expanded(
          child: RepaintBoundary(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final canvasSize =
                    Size(constraints.maxWidth, constraints.maxHeight);
                return GestureDetector(
                  onTapDown: (d) => _addWaveAt(d.localPosition, canvasSize,
                      strength: 1.0),
                  onPanStart: (d) {
                    _isDragging = true;
                    _addWaveAt(d.localPosition, canvasSize, strength: 0.6);
                  },
                  onPanUpdate: (d) {
                    if (_isDragging) {
                      _addWaveAt(d.localPosition, canvasSize,
                          strength: 0.4);
                    }
                  },
                  onPanEnd: (_) => _isDragging = false,
                  onLongPressStart: (d) {
                    _longPressWave = _WaveSource(
                      x: (d.localPosition.dx / canvasSize.width)
                          .clamp(0, 1),
                      y: (d.localPosition.dy / canvasSize.height)
                          .clamp(0, 1),
                      strength: 1.5,
                      color: _neonPalette[_selectedColorIdx],
                      createdAt: DateTime.now(),
                      duration: _longPressWaveDuration,
                      continuous: true,
                    );
                    _waveSources.add(_longPressWave!);
                  },
                  onLongPressEnd: (_) {
                    if (_longPressWave != null) {
                      _waveSources.remove(_longPressWave);
                      _waveSources.add(_WaveSource(
                        x: _longPressWave!.x,
                        y: _longPressWave!.y,
                        strength: 1.2,
                        color: _longPressWave!.color,
                        createdAt: DateTime.now(),
                        duration: _longPressWaveDuration,
                      ));
                      _longPressWave = null;
                    }
                  },
                  child: CustomPaint(
                    size: canvasSize,
                    painter: _ParticleWavePainter(
                      heights: _heights,
                      mode: _mode,
                      baseColor: _neonPalette[_selectedColorIdx],
                      elapsed: _elapsed,
                      modeOffset: _modeOffset,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        _buildColorPalette(),
      ],
    );
  }

  Widget _buildColorPalette() {
    return Container(
      height: 56,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_neonPalette.length, (i) {
          final selected = i == _selectedColorIdx;
          return GestureDetector(
            onTap: () => setState(() => _selectedColorIdx = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: selected ? 40 : 32,
              height: selected ? 40 : 32,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: _neonPalette[i],
                shape: BoxShape.circle,
                border: selected
                    ? Border.all(color: Colors.white, width: 2.5)
                    : null,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color:
                              _neonPalette[i].withValues(alpha: 0.6),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Join room field
// ---------------------------------------------------------------------------
class _JoinRoomField extends StatefulWidget {
  const _JoinRoomField({required this.isKorean, required this.onJoin});
  final bool isKorean;
  final void Function(String) onJoin;

  @override
  State<_JoinRoomField> createState() => _JoinRoomFieldState();
}

class _JoinRoomFieldState extends State<_JoinRoomField> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            maxLength: 4,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              letterSpacing: 4,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              counterText: '',
              hintText: widget.isKorean ? '코드 입력' : 'Enter code',
              hintStyle: const TextStyle(color: AppColors.muted),
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppColors.accent, width: 2),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              if (_ctrl.text.length == 4) widget.onJoin(_ctrl.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.card,
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(widget.isKorean ? '입장' : 'Join'),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// CustomPainter - Canvas.drawPoints batch rendering
// ---------------------------------------------------------------------------
class _ParticleWavePainter extends CustomPainter {
  _ParticleWavePainter({
    required this.heights,
    required this.mode,
    required this.baseColor,
    required this.elapsed,
    required this.modeOffset,
  });

  final Float32List heights;
  final WaveMode mode;
  final Color baseColor;
  final double elapsed;
  final Offset Function(
          int gx, int gy, double h, double cellW, double cellH)
      modeOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / _gridW;
    final cellH = size.height / _gridH;

    const bandCount = 5;
    final bands = List.generate(bandCount, (_) => <Offset>[]);

    for (int y = 0; y < _gridH; y++) {
      for (int x = 0; x < _gridW; x++) {
        final i = y * _gridW + x;
        final h = heights[i];
        final pos = modeOffset(x, y, h, cellW, cellH);
        final t = h.abs().clamp(0.0, 1.0);
        final band =
            (t * (bandCount - 1)).round().clamp(0, bandCount - 1);
        bands[band].add(pos);
      }
    }

    for (int b = 0; b < bandCount; b++) {
      if (bands[b].isEmpty) continue;
      final t = b / (bandCount - 1);
      final color = Color.lerp(
        baseColor.withValues(alpha: 0.12),
        baseColor,
        t,
      )!;
      final paint = Paint()
        ..color = color
        ..strokeWidth = _particleSize + t * 1.0
        ..strokeCap = StrokeCap.round;

      canvas.drawPoints(ui.PointMode.points, bands[b], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleWavePainter oldDelegate) => true;
}
