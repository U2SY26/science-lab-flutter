import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import '../../core/models/rive_character_mode.dart';
import 'rive_character_fallback.dart';
import 'rive_file_cache.dart';

/// Rive 애니메이션 AI 튜터 캐릭터 위젯.
///
/// .riv 파일이 있으면 Rive로 렌더링 (첫 번째 Artboard + 첫 번째 State Machine 자동 감지),
/// 없으면 [RiveCharacterFallback] (Flutter 네이티브 애니메이션) 자동 전환.
///
/// 커스텀 .riv 파일이 "TutorStateMachine"과 mode/emotion 입력을 가지면
/// 모드/감정 동기화가 자동으로 활성화됨.
/// State Machine 이름 탐색 순서
const _smNamesToTry = [
  'TutorStateMachine',
  'State Machine 1',
  'State Machine',
  'avatar2',
  'avatar',
  'avatar3',
];

class RiveCharacter extends StatefulWidget {
  final String personaId;
  final RiveCharacterMode mode;
  final double emotion;
  final double size;
  final bool visible;

  const RiveCharacter({
    super.key,
    required this.personaId,
    this.mode = RiveCharacterMode.idle,
    this.emotion = 0.0,
    this.size = 48.0,
    this.visible = true,
  });

  @override
  State<RiveCharacter> createState() => _RiveCharacterState();
}

class _RiveCharacterState extends State<RiveCharacter> {
  bool _useFallback = true;
  bool _loading = true;
  Artboard? _artboard;
  StateMachineController? _smController;
  SMINumber? _modeInput;
  SMINumber? _emotionInput;
  SMITrigger? _trigDisappear;

  @override
  void initState() {
    super.initState();
    _loadRiveFile();
  }

  @override
  void didUpdateWidget(RiveCharacter old) {
    super.didUpdateWidget(old);

    if (old.personaId != widget.personaId) {
      _disposeRive();
      _loadRiveFile();
      return;
    }

    if (old.mode != widget.mode) {
      _modeInput?.value = widget.mode.index.toDouble();
    }
    if (old.emotion != widget.emotion) {
      _emotionInput?.value = widget.emotion;
    }
    if (old.visible && !widget.visible) {
      _trigDisappear?.fire();
    }
  }

  @override
  void dispose() {
    _disposeRive();
    super.dispose();
  }

  void _disposeRive() {
    _smController?.dispose();
    _smController = null;
    _artboard = null;
    _modeInput = null;
    _emotionInput = null;
    _trigDisappear = null;
  }

  Future<void> _loadRiveFile() async {
    setState(() => _loading = true);

    final file = await RiveFileCache.load(widget.personaId);
    if (file == null || !mounted) {
      if (mounted) setState(() { _useFallback = true; _loading = false; });
      return;
    }

    try {
      final artboard = file.mainArtboard.instance();

      // 커스텀 → 기본 이름 순서로 State Machine 탐색
      StateMachineController? controller;
      for (final name in _smNamesToTry) {
        controller = StateMachineController.fromArtboard(artboard, name);
        if (controller != null) break;
      }

      if (controller == null) {
        // SM 없으면 SimpleAnimation 시도
        try {
          artboard.addController(SimpleAnimation('idle'));
        } catch (_) {
          try {
            artboard.addController(SimpleAnimation('Idle'));
          } catch (_) {
            // 아무 애니메이션도 없으면 정적 artboard 표시
          }
        }
        if (mounted) {
          setState(() {
            _artboard = artboard;
            _useFallback = false;
            _loading = false;
          });
        }
        return;
      }

      artboard.addController(controller);

      if (mounted) {
        setState(() {
          _artboard = artboard;
          _smController = controller;
          // 커스텀 입력이 있으면 연결 (없으면 null — 기본 애니메이션만 재생)
          _modeInput = controller!.findInput<double>('mode') as SMINumber?;
          _emotionInput = controller.findInput<double>('emotion') as SMINumber?;
          _trigDisappear = controller.findInput<bool>('trigDisappear') as SMITrigger?;
          _useFallback = false;
          _loading = false;
        });

        _modeInput?.value = widget.mode.index.toDouble();
        _emotionInput?.value = widget.emotion;
      }
    } catch (e) {
      debugPrint('[RiveCharacter] Error loading ${widget.personaId}: $e');
      if (mounted) setState(() { _useFallback = true; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _useFallback) {
      return RiveCharacterFallback(
        personaId: widget.personaId,
        mode: widget.mode,
        size: widget.size,
        visible: widget.visible,
      );
    }

    return AnimatedOpacity(
      opacity: widget.visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: _artboard != null
            ? ClipOval(child: Rive(artboard: _artboard!, fit: BoxFit.cover))
            : const SizedBox.shrink(),
      ),
    );
  }
}
