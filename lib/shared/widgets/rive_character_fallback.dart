import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/models/ai_persona.dart';
import '../../core/models/rive_character_mode.dart';

/// .riv 파일 없을 때 사용하는 Flutter 네이티브 애니메이션 폴백.
/// 페르소나의 아이콘+컬러를 사용하여 모드별 애니메이션 제공.
class RiveCharacterFallback extends StatefulWidget {
  final String personaId;
  final RiveCharacterMode mode;
  final double size;
  final bool visible;

  const RiveCharacterFallback({
    super.key,
    required this.personaId,
    this.mode = RiveCharacterMode.idle,
    this.size = 48.0,
    this.visible = true,
  });

  @override
  State<RiveCharacterFallback> createState() => _RiveCharacterFallbackState();
}

class _RiveCharacterFallbackState extends State<RiveCharacterFallback>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: _durationForMode(widget.mode),
      vsync: this,
    )..repeat(reverse: _shouldReverse(widget.mode));
  }

  @override
  void didUpdateWidget(RiveCharacterFallback old) {
    super.didUpdateWidget(old);
    if (old.mode != widget.mode || old.visible != widget.visible) {
      _controller.duration = _durationForMode(widget.mode);
      if (!widget.visible) {
        _controller.stop();
      } else {
        _controller.repeat(reverse: _shouldReverse(widget.mode));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Duration _durationForMode(RiveCharacterMode mode) {
    switch (mode) {
      case RiveCharacterMode.idle:
        return const Duration(milliseconds: 2000);
      case RiveCharacterMode.listening:
        return const Duration(milliseconds: 1500);
      case RiveCharacterMode.thinking:
        return const Duration(milliseconds: 1200);
      case RiveCharacterMode.speaking:
        return const Duration(milliseconds: 600);
    }
  }

  bool _shouldReverse(RiveCharacterMode mode) {
    return mode != RiveCharacterMode.speaking;
  }

  @override
  Widget build(BuildContext context) {
    final persona = getPersonaById(widget.personaId);
    final iconSize = widget.size * 0.55;

    return AnimatedOpacity(
      opacity: widget.visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      child: AnimatedScale(
        scale: widget.visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInBack,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform(
              alignment: Alignment.center,
              transform: _transformForMode(widget.mode, _controller.value),
              child: child,
            );
          },
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: persona.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: persona.color.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Icon(persona.icon, size: iconSize, color: persona.color),
          ),
        ),
      ),
    );
  }

  Matrix4 _transformForMode(RiveCharacterMode mode, double t) {
    switch (mode) {
      case RiveCharacterMode.idle:
        // 부드러운 scale 펄스 (0.95 ↔ 1.0)
        final s = 0.95 + t * 0.05;
        return Matrix4.diagonal3Values(s, s, 1.0);

      case RiveCharacterMode.listening:
        // 약간 기울어지는 움직임
        final tilt = math.sin(t * math.pi) * 0.05;
        return Matrix4.identity()..rotateZ(tilt);

      case RiveCharacterMode.thinking:
        // 회전 흔들림 + scale
        final rotate = math.sin(t * math.pi * 2) * 0.08;
        final s = 0.95 + math.sin(t * math.pi) * 0.05;
        return Matrix4.diagonal3Values(s, s, 1.0)..rotateZ(rotate);

      case RiveCharacterMode.speaking:
        // 리드미컬 y-bounce
        final y = math.sin(t * math.pi * 2) * -2.0;
        final s = 1.0 + math.sin(t * math.pi * 2) * 0.05;
        return Matrix4.diagonal3Values(s, s, 1.0)
          ..setTranslationRaw(0.0, y, 0.0);
    }
  }
}
