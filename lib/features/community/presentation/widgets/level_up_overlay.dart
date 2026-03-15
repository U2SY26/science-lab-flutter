import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import '../../../../core/constants/app_colors.dart';

/// 레벨업 전체화면 Rive 애니메이션 오버레이
class LevelUpOverlay extends StatefulWidget {
  final int newLevel;
  final int currentXp;
  final int nextLevelXp;
  final VoidCallback onDismiss;

  const LevelUpOverlay({
    super.key,
    required this.newLevel,
    this.currentXp = 0,
    this.nextLevelXp = 0,
    required this.onDismiss,
  });

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();

  /// 오버레이 표시 헬퍼
  static void show(BuildContext context, int newLevel, {int currentXp = 0, int nextLevelXp = 0}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => LevelUpOverlay(
        newLevel: newLevel,
        currentXp: currentXp,
        nextLevelXp: nextLevelXp,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _LevelUpOverlayState extends State<LevelUpOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  Timer? _autoClose;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    // 4초 후 자동 닫기
    _autoClose = Timer(const Duration(seconds: 4), _dismiss);
  }

  void _dismiss() {
    _autoClose?.cancel();
    _fadeController.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _autoClose?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKorean = Localizations.localeOf(context).languageCode == 'ko';
    return FadeTransition(
      opacity: _fadeController,
      child: Material(
        color: Colors.black87,
        child: GestureDetector(
          onTap: _dismiss,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rive 애니메이션 (레벨/XP 값 전달)
              Positioned.fill(
                child: _RiveLevelUp(
                  level: widget.newLevel,
                  currentXp: widget.currentXp,
                  nextLevelXp: widget.nextLevelXp,
                ),
              ),

              // 레벨 텍스트
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 100),
                  Text(
                    isKorean ? '레벨 업!' : 'LEVEL UP!',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      shadows: [
                        Shadow(
                          color: AppColors.accent.withValues(alpha: 0.6),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      'Level ${widget.newLevel}',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isKorean ? '탭하여 계속' : 'Tap to continue',
                    style: TextStyle(
                      color: AppColors.muted.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              // 닫기 버튼
              Positioned(
                top: 60,
                right: 20,
                child: GestureDetector(
                  onTap: _dismiss,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.card.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: AppColors.muted, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rive 레벨업 애니메이션 위젯 (State Machine Input 연동)
class _RiveLevelUp extends StatefulWidget {
  final int level;
  final int currentXp;
  final int nextLevelXp;

  const _RiveLevelUp({
    required this.level,
    required this.currentXp,
    required this.nextLevelXp,
  });

  @override
  State<_RiveLevelUp> createState() => _RiveLevelUpState();
}

class _RiveLevelUpState extends State<_RiveLevelUp> {
  Artboard? _artboard;

  @override
  void initState() {
    super.initState();
    _loadRive();
  }

  Future<void> _loadRive() async {
    try {
      debugPrint('[LevelUp] Loading Rive file...');
      final data = await RiveFile.asset('assets/rive/level_up.riv');
      final artboard = data.mainArtboard;

      // State Machine 연결 + 입력값 설정
      bool connected = false;
      final names = ['State Machine 1', 'State Machine', 'Level Up'];
      for (final name in names) {
        try {
          final ctrl = StateMachineController.fromArtboard(artboard, name);
          if (ctrl == null) continue;
          artboard.addController(ctrl);
          debugPrint('[LevelUp] Connected to State Machine: $name');

          for (final input in ctrl.inputs) {
            debugPrint('[LevelUp] Input: ${input.name} (${input.runtimeType})');
            switch (input.name) {
              case 'Level':
                (input as SMINumber).value = widget.level.toDouble();
              case 'currentXP':
                (input as SMINumber).value = widget.currentXp.toDouble();
              case 'nextlvlXP':
                (input as SMINumber).value = widget.nextLevelXp.toDouble();
              case 'Replay':
                (input as SMITrigger).fire();
            }
          }
          connected = true;
          break;
        } catch (e) {
          debugPrint('[LevelUp] Failed with SM "$name": $e');
        }
      }

      // State Machine 없으면 SimpleAnimation 폴백
      if (!connected) {
        debugPrint('[LevelUp] No State Machine found, using SimpleAnimation');
        artboard.addController(SimpleAnimation('Timeline 1'));
      }

      if (mounted) setState(() => _artboard = artboard);
    } catch (e) {
      debugPrint('[LevelUp] Rive load failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_artboard == null) return const SizedBox.shrink();
    return Rive(artboard: _artboard!, fit: BoxFit.cover);
  }
}
