import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../core/models/ai_persona.dart';
import '../../core/models/rive_character_mode.dart';

/// 페르소나별 Lottie 파일 매핑
const _personaLottieMap = <String, String>{
  'tutor': 'Professor Einton',
  'einstein': 'Professor Einton',
  'feynman': 'Scientist',
  'curie': 'Girl giving thumbs up',
  'tyson': 'Robot says hello',
  'musk': 'Robot says hello',
  'socrates': 'Scientist',
};

/// Lottie 기반 AI 튜터 캐릭터 위젯
///
/// - idle: 일반 속도 루프
/// - speaking: 2x 속도 (입모양 시뮬레이션)
/// - thinking: 0.5x 속도 + 회전 흔들림
/// - listening: 일시정지 + 미세 펄스
class LottieCharacter extends StatefulWidget {
  final String personaId;
  final RiveCharacterMode mode;
  final double emotion;
  final double size;
  final bool visible;

  const LottieCharacter({
    super.key,
    required this.personaId,
    this.mode = RiveCharacterMode.idle,
    this.emotion = 0.0,
    this.size = 48.0,
    this.visible = true,
  });

  @override
  State<LottieCharacter> createState() => _LottieCharacterState();
}

class _LottieCharacterState extends State<LottieCharacter>
    with TickerProviderStateMixin {
  late AnimationController _lottieController;
  late AnimationController _effectController;
  bool _hasLottie = false;
  String? _currentAsset;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    _effectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _updateAsset(fromInitState: true);
    // 첫 프레임 이후 애니메이션 시작 (빌드 중 리빌드 방지)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _effectController.repeat(reverse: true);
    });
  }

  @override
  void didUpdateWidget(LottieCharacter old) {
    super.didUpdateWidget(old);
    if (old.personaId != widget.personaId) _updateAsset();
    if (old.mode != widget.mode) _updateAnimSpeed();
  }

  @override
  void dispose() {
    _lottieController.dispose();
    _effectController.dispose();
    super.dispose();
  }

  void _updateAsset({bool fromInitState = false}) {
    final lottieFile = _personaLottieMap[widget.personaId];
    if (lottieFile != null) {
      _currentAsset = 'assets/lottie/$lottieFile.json';
      _hasLottie = true;
    } else {
      _hasLottie = false;
    }
    // initState 중에는 setState 불필요 (첫 build에서 반영됨)
    if (!fromInitState && mounted) setState(() {});
  }

  void _updateAnimSpeed() {
    if (!_lottieController.isAnimating && _hasLottie) return;

    switch (widget.mode) {
      case RiveCharacterMode.idle:
        _lottieController.duration = _lottieController.duration;
        if (!_lottieController.isAnimating) {
          _lottieController.repeat();
        }
      case RiveCharacterMode.speaking:
        // 2x speed for lip-sync simulation
        if (_lottieController.duration != null) {
          final halfDuration = Duration(
            milliseconds: (_lottieController.duration!.inMilliseconds * 0.5).round(),
          );
          _lottieController.duration = halfDuration;
          _lottieController.repeat();
        }
      case RiveCharacterMode.thinking:
        // 0.5x speed
        if (_lottieController.duration != null) {
          final slowDuration = Duration(
            milliseconds: (_lottieController.duration!.inMilliseconds * 2).round(),
          );
          _lottieController.duration = slowDuration;
          _lottieController.repeat();
        }
      case RiveCharacterMode.listening:
        _lottieController.stop();
    }
  }

  void _onLottieLoaded(LottieComposition composition) {
    _lottieController.duration = composition.duration;
    _lottieController.repeat();
    _updateAnimSpeed();
  }

  /// 감정에 따른 테두리 색상
  Color _emotionBorderColor(Color base) {
    final e = widget.emotion;
    if (e > 0.5) return Color.lerp(base, const Color(0xFFFFD700), 0.5)!;
    if (e > 0.2) return Color.lerp(base, const Color(0xFF10B981), 0.3)!;
    if (e < -0.3) return Color.lerp(base, const Color(0xFFF59E0B), 0.4)!;
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final persona = getPersonaById(widget.personaId);
    final borderColor = _emotionBorderColor(persona.color);

    // Lottie 파일 없으면 emoji fallback
    if (!_hasLottie || _currentAsset == null) {
      return _EmojiCharacter(
        persona: persona,
        mode: widget.mode,
        emotion: widget.emotion,
        size: widget.size,
        visible: widget.visible,
        effectController: _effectController,
      );
    }

    return AnimatedOpacity(
      opacity: widget.visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      child: AnimatedScale(
        scale: widget.visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInBack,
        child: AnimatedBuilder(
          animation: _effectController,
          builder: (context, child) {
            // Speaking 모드: Y축 바운스로 입모양 느낌
            double yOffset = 0;
            double scaleEffect = 1.0;
            if (widget.mode == RiveCharacterMode.speaking) {
              yOffset = _effectController.value * -3.0;
              scaleEffect = 1.0 + _effectController.value * 0.05;
            } else if (widget.mode == RiveCharacterMode.thinking) {
              scaleEffect = 0.95 + _effectController.value * 0.05;
            }

            return Transform.translate(
              offset: Offset(0, yOffset),
              child: Transform.scale(
                scale: scaleEffect,
                child: child,
              ),
            );
          },
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: borderColor.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: borderColor.withValues(alpha: 0.2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: ClipOval(
              child: Lottie.asset(
                _currentAsset!,
                controller: _lottieController,
                onLoaded: _onLottieLoaded,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _EmojiCharacter(
                    persona: persona,
                    mode: widget.mode,
                    emotion: widget.emotion,
                    size: widget.size,
                    visible: widget.visible,
                    effectController: _effectController,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Emoji fallback 캐릭터 (Lottie 파일 없을 때)
class _EmojiCharacter extends StatelessWidget {
  final AiPersona persona;
  final RiveCharacterMode mode;
  final double emotion;
  final double size;
  final bool visible;
  final AnimationController effectController;

  const _EmojiCharacter({
    required this.persona,
    required this.mode,
    required this.emotion,
    required this.size,
    required this.visible,
    required this.effectController,
  });

  Color _emotionColor(Color base) {
    if (emotion > 0.5) return Color.lerp(base, const Color(0xFFFFD700), 0.5)!;
    if (emotion > 0.2) return Color.lerp(base, const Color(0xFF10B981), 0.3)!;
    if (emotion < -0.3) return Color.lerp(base, const Color(0xFFF59E0B), 0.4)!;
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _emotionColor(persona.color);

    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      child: AnimatedBuilder(
        animation: effectController,
        builder: (context, child) {
          final s = mode == RiveCharacterMode.speaking
              ? 1.0 + effectController.value * 0.08
              : 0.95 + effectController.value * 0.05;
          return Transform.scale(scale: s, child: child);
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: borderColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Icon(persona.icon, size: size * 0.55, color: borderColor),
          ),
        ),
      ),
    );
  }
}
