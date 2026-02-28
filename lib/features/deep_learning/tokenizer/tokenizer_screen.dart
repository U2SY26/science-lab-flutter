import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class TokenizerScreen extends StatefulWidget {
  const TokenizerScreen({super.key});
  @override
  State<TokenizerScreen> createState() => _TokenizerScreenState();
}

class _TokenizerScreenState extends State<TokenizerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _vocabSize = 1000;
  
  double _compression = 3.5, _merges = 0;

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
      _merges = _vocabSize - 256;
      _compression = 1 + math.log(_vocabSize / 256) / math.ln2;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _vocabSize = 1000.0;
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
          Text('AI/ML 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('토크나이저', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: 'AI/ML 시뮬레이션',
          title: '토크나이저',
          formula: 'BPE merge operations',
          formulaDescription: 'BPE 토크나이저의 병합 과정을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _TokenizerScreenPainter(
                time: _time,
                vocabSize: _vocabSize,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '어휘 크기',
                value: _vocabSize,
                min: 100,
                max: 50000,
                step: 100,
                defaultValue: 1000,
                formatValue: (v) => v.toInt().toString(),
                onChanged: (v) => setState(() => _vocabSize = v),
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
          _V('압축비', '${_compression.toStringAsFixed(2)}x'),
          _V('병합', _merges.toStringAsFixed(0)),
          _V('어휘', _vocabSize.toInt().toString()),
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

class _TokenizerScreenPainter extends CustomPainter {
  final double time;
  final double vocabSize;

  _TokenizerScreenPainter({
    required this.time,
    required this.vocabSize,
  });

  static const _cyan = Color(0xFF00D4FF);
  static const _orange = Color(0xFFFF6B35);
  static const _simBg = Color(0xFF0D1A20);
  static const _ink = Color(0xFFE0F4FF);
  static const _muted = Color(0xFF5A8A9A);
  static const _grid = Color(0xFF1A3040);

  // Token colors — each token type gets a distinct color
  static const List<Color> _tokenColors = [
    Color(0xFF00D4FF), // cyan
    Color(0xFFFF6B35), // orange
    Color(0xFF64FF8C), // green
    Color(0xFFFFD700), // yellow
    Color(0xFFBB86FC), // purple
    Color(0xFFFF4560), // red
    Color(0xFF26C6DA), // teal
    Color(0xFFFFAB40), // amber
  ];

  // BPE tokens for a sample sentence broken progressively
  // Phase 0: characters, Phase 1: subwords, Phase 2: words
  static const List<List<String>> _phases = [
    // Characters
    ['H','e','l','l','o',' ','W','o','r','l','d'],
    // Partial merges
    ['He','ll','o',' ','Wo','rl','d'],
    // Word-level
    ['Hello', ' ', 'World'],
  ];

  // Top token frequency data (relative frequencies)
  static const List<(String, double)> _topTokens = [
    ('the', 1.0), ('##ing', 0.82), ('##ed', 0.74), ('is', 0.66),
    ('##s', 0.60), ('and', 0.54), ('of', 0.47), ('##ly', 0.40),
    ('to', 0.35), ('in', 0.29),
  ];

  void _drawLabel(Canvas canvas, String text, Offset offset,
      {Color color = _ink, double fontSize = 10, FontWeight weight = FontWeight.w600}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: weight)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = _simBg);

    // Subtle dot grid
    final dotPaint = Paint()..color = _grid.withValues(alpha: 0.6);
    for (double x = 8; x < size.width; x += 24) {
      for (double y = 8; y < size.height; y += 24) {
        canvas.drawCircle(Offset(x, y), 0.8, dotPaint);
      }
    }

    final double pad = 12.0;
    final double w = size.width - pad * 2;

    // --- Section 1: Tokenization display (top ~32%) ---
    final double tokSecTop = 28.0;
    final double tokSecH = size.height * 0.30;

    // Phase cycling based on vocabSize and time
    final int phaseIdx = ((time * 0.5).floor() % 3);
    final List<String> tokens = _phases[phaseIdx];

    // Section label
    _drawLabel(canvas, 'BPE 토크나이저', Offset(pad, 8),
        color: _cyan, fontSize: 11);
    _drawLabel(canvas, 'phase ${phaseIdx + 1}/3',
        Offset(size.width - 56, 8), color: _muted, fontSize: 9);

    // Draw tokens as colored pills
    double tokenX = pad;
    final double tokenY = tokSecTop + 8;
    final double pillH = 26.0;
    for (int i = 0; i < tokens.length; i++) {
      final String tok = tokens[i];
      final Color tc = _tokenColors[i % _tokenColors.length];

      // Measure text
      final tp = TextPainter(
        text: TextSpan(
            text: tok == ' ' ? '⎵' : tok,
            style: TextStyle(color: _simBg, fontSize: 11, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();

      final double pillW = tp.width + 14;
      if (tokenX + pillW > size.width - pad) { break; }

      // Animated entrance: stagger
      final double entranceDelay = i * 0.08;
      final double entranceT = ((time * 0.5 - (phaseIdx * 0.8) - entranceDelay)).clamp(0.0, 1.0);
      final double alpha = entranceT;
      final double offsetY = (1.0 - entranceT) * 10;

      // Pill background with glow
      final Rect pillRect = Rect.fromLTWH(tokenX, tokenY + offsetY, pillW, pillH);
      canvas.drawRRect(
        RRect.fromRectAndRadius(pillRect, const Radius.circular(6)),
        Paint()..color = tc.withValues(alpha: alpha * 0.18),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(pillRect, const Radius.circular(6)),
        Paint()
          ..color = tc.withValues(alpha: alpha * 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      tp.paint(canvas,
          Offset(tokenX + 7, tokenY + offsetY + (pillH - tp.height) / 2));

      // Token index subscript
      _drawLabel(canvas, '$i',
          Offset(tokenX + pillW - 9, tokenY + offsetY + pillH - 11),
          color: tc.withValues(alpha: alpha * 0.6), fontSize: 7);

      tokenX += pillW + 5;
    }

    // Merge arrow animation between phase 1 and 2
    if (phaseIdx > 0) {
      final double arrowY2 = tokenY + pillH + 6;
      final double pulse = 0.5 + 0.5 * math.sin(time * 4);
      _drawLabel(canvas, '⟹ BPE 병합',
          Offset(pad, arrowY2), color: _orange.withValues(alpha: 0.6 + pulse * 0.4), fontSize: 9);
    }

    // --- Section 2: Vocab size bar (middle ~18%) ---
    final double vocabSecTop = tokSecTop + tokSecH;
    final double vocabBarW = w * (math.log(vocabSize / 256 + 1) / math.log(200)).clamp(0.0, 1.0);
    final double vocabBarH = 14.0;
    final double vocabBarY = vocabSecTop + 10;

    _drawLabel(canvas, '어휘 크기: ${vocabSize.toInt()}',
        Offset(pad, vocabSecTop), color: _muted, fontSize: 9);

    // Track background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(pad, vocabBarY, w, vocabBarH), const Radius.circular(4)),
      Paint()..color = _grid,
    );
    // Fill with gradient
    final Shader vocabShader = LinearGradient(
      colors: [_cyan.withValues(alpha: 0.6), _orange.withValues(alpha: 0.8)],
    ).createShader(Rect.fromLTWH(pad, vocabBarY, w, vocabBarH));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(pad, vocabBarY, vocabBarW, vocabBarH), const Radius.circular(4)),
      Paint()..shader = vocabShader,
    );
    // 256 (byte-level) marker
    final double byteMarkerX = pad + 0.0;
    canvas.drawLine(
      Offset(byteMarkerX, vocabBarY - 2), Offset(byteMarkerX, vocabBarY + vocabBarH + 2),
      Paint()..color = _muted.withValues(alpha: 0.5)..strokeWidth = 1,
    );
    _drawLabel(canvas, '256', Offset(byteMarkerX + 1, vocabBarY + vocabBarH + 3),
        color: _muted, fontSize: 7);

    // --- Section 3: Token frequency histogram (bottom ~42%) ---
    final double histTop = vocabSecTop + vocabBarH + 36;
    final double histH = size.height - histTop - 10;
    final double histLeft = pad + 22;
    final double histRight = size.width - pad;
    final double histBottom = histTop + histH;
    final double barAreaW = histRight - histLeft;
    final int n = _topTokens.length;
    final double bw = barAreaW / n - 3;

    _drawLabel(canvas, '상위 토큰 빈도', Offset(pad, histTop - 14),
        color: _muted, fontSize: 9);

    // Y axis
    canvas.drawLine(Offset(histLeft - 2, histTop), Offset(histLeft - 2, histBottom),
        Paint()..color = _muted.withValues(alpha: 0.3)..strokeWidth = 0.8);
    canvas.drawLine(Offset(histLeft - 2, histBottom), Offset(histRight, histBottom),
        Paint()..color = _muted.withValues(alpha: 0.3)..strokeWidth = 0.8);

    for (int i = 0; i < n; i++) {
      final (label, freq) = _topTokens[i];
      final Color bc = _tokenColors[i % _tokenColors.length];
      // Animate bars growing with a wave
      final double animFreq = freq * (0.7 + 0.3 * math.sin(time * 1.5 + i * 0.4));
      final double bh = animFreq * (histH - 16);
      final double bx = histLeft + i * (bw + 3);
      final double by = histBottom - bh;

      // Glow
      canvas.drawRect(
        Rect.fromLTWH(bx, by, bw, bh),
        Paint()..color = bc.withValues(alpha: 0.12),
      );
      // Bar gradient
      final Shader barShader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [bc, bc.withValues(alpha: 0.4)],
      ).createShader(Rect.fromLTWH(bx, by, bw, bh));
      canvas.drawRect(
        Rect.fromLTWH(bx, by, bw, bh),
        Paint()..shader = barShader,
      );

      // Token label below axis
      final tp2 = TextPainter(
        text: TextSpan(text: label, style: TextStyle(color: bc.withValues(alpha: 0.9), fontSize: 7)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp2.paint(canvas, Offset(bx + (bw - tp2.width) / 2, histBottom + 2));
    }

    // Compression ratio badge
    final double compression = 1 + math.log(vocabSize / 256) / math.ln2;
    _drawLabel(canvas, '압축비: ${compression.toStringAsFixed(1)}x',
        Offset(size.width - 80, 8), color: _orange, fontSize: 9);
  }

  @override
  bool shouldRepaint(covariant _TokenizerScreenPainter oldDelegate) => true;
}
