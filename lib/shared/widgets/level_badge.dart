import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Format a DateTime as a relative "time ago" string.
String timeAgo(DateTime dt, bool isKorean) {
  final diff = DateTime.now().difference(dt);
  if (diff.inDays > 365) {
    final y = diff.inDays ~/ 365;
    return isKorean ? '$y년 전' : '${y}y ago';
  } else if (diff.inDays > 30) {
    final m = diff.inDays ~/ 30;
    return isKorean ? '$m개월 전' : '${m}mo ago';
  } else if (diff.inDays > 0) {
    return isKorean ? '${diff.inDays}일 전' : '${diff.inDays}d ago';
  } else if (diff.inHours > 0) {
    return isKorean ? '${diff.inHours}시간 전' : '${diff.inHours}h ago';
  } else if (diff.inMinutes > 0) {
    return isKorean ? '${diff.inMinutes}분 전' : '${diff.inMinutes}m ago';
  }
  return isKorean ? '방금' : 'now';
}

// ── 레벨 티어 ──────────────────────────────────────────
class _Tier {
  final Color primary;
  final Color? secondary; // 두 번째 테두리 색
  final Color textColor;
  final bool doubleRing;  // 이중 테두리
  final bool glow;
  final bool neon;        // 50+ 네온 깜빡임
  final bool legendary;   // 100+ 레전더리

  const _Tier({
    required this.primary,
    this.secondary,
    this.textColor = Colors.white,
    this.doubleRing = false,
    this.glow = false,
    this.neon = false,
    this.legendary = false,
  });

  factory _Tier.fromLevel(int level) {
    if (level >= 100) {
      return const _Tier(
        primary: Color(0xFFFF4444), secondary: Color(0xFFFFD700),
        textColor: Color(0xFFFFD700),
        doubleRing: true, glow: true, neon: true, legendary: true,
      );
    } else if (level >= 50) {
      return const _Tier(
        primary: Color(0xFFFFD700), secondary: Color(0xFFF59E0B),
        textColor: Color(0xFF1A1A2E),
        doubleRing: true, glow: true, neon: true,
      );
    } else if (level >= 40) {
      return const _Tier(
        primary: Color(0xFFEF4444), secondary: Color(0xFFF97316),
        textColor: Colors.white,
        doubleRing: true, glow: true,
      );
    } else if (level >= 30) {
      return const _Tier(
        primary: Color(0xFFF97316), secondary: Color(0xFFFBBF24),
        textColor: Colors.white,
        doubleRing: true, glow: true,
      );
    } else if (level >= 20) {
      return const _Tier(
        primary: Color(0xFF8B5CF6), secondary: Color(0xFFA78BFA),
        doubleRing: true, glow: true,
      );
    } else if (level >= 10) {
      return const _Tier(
        primary: Color(0xFF3B82F6),
        glow: true,
      );
    } else if (level >= 5) {
      return const _Tier(primary: Color(0xFF10B981));
    }
    return const _Tier(primary: Color(0xFF6B7280));
  }
}

// ── 육각형 레벨 배지 ──────────────────────────────────
class LevelBadge extends StatelessWidget {
  final int level;
  final double size;

  const LevelBadge({super.key, required this.level, this.size = 22});

  @override
  Widget build(BuildContext context) {
    final tier = _Tier.fromLevel(level);
    // 숫자 자릿수에 따라 배지 크기 조절
    final digits = level.toString().length;
    final adjustedSize = size + (digits > 2 ? (digits - 2) * 4.0 : 0);

    Widget badge = CustomPaint(
      size: Size(adjustedSize, adjustedSize),
      painter: _HexBadgePainter(tier: tier),
      child: SizedBox(
        width: adjustedSize,
        height: adjustedSize,
        child: Center(
          child: Text(
            '$level',
            style: TextStyle(
              color: tier.textColor,
              fontSize: adjustedSize * 0.35,
              fontWeight: FontWeight.w900,
              height: 1,
              shadows: tier.glow
                  ? [Shadow(color: tier.primary.withValues(alpha: 0.6), blurRadius: 4)]
                  : null,
            ),
          ),
        ),
      ),
    );

    if (tier.glow) {
      badge = Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: tier.primary.withValues(alpha: 0.35),
              blurRadius: 8,
            ),
          ],
        ),
        child: badge,
      );
    }

    if (tier.neon) badge = _NeonWrap(color: tier.primary, child: badge);
    if (tier.legendary) badge = _LegendaryWrap(child: badge);

    return badge;
  }
}

// ── 육각형 페인터 ──────────────────────────────────────
class _HexBadgePainter extends CustomPainter {
  final _Tier tier;
  const _HexBadgePainter({required this.tier});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 1.5;

    Path hexPath(double radius) {
      final path = Path();
      for (int i = 0; i < 6; i++) {
        final angle = (math.pi / 3) * i - math.pi / 2;
        final x = cx + radius * math.cos(angle);
        final y = cy + radius * math.sin(angle);
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      path.close();
      return path;
    }

    // 배경 채우기
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          tier.primary.withValues(alpha: 0.25),
          (tier.secondary ?? tier.primary).withValues(alpha: 0.15),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(hexPath(r), bgPaint);

    // 이중 테두리 (20+)
    if (tier.doubleRing && tier.secondary != null) {
      final outerPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = tier.secondary!.withValues(alpha: 0.5);
      canvas.drawPath(hexPath(r), outerPaint);

      final innerPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = tier.primary.withValues(alpha: 0.7);
      canvas.drawPath(hexPath(r - 2.5), innerPaint);
    } else {
      // 단일 테두리
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = tier.primary.withValues(alpha: 0.7);
      canvas.drawPath(hexPath(r), borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HexBadgePainter old) => old.tier.primary != tier.primary;
}

// ── 네온 깜빡임 (50+) ────────────────────────────────
class _NeonWrap extends StatefulWidget {
  final Color color;
  final Widget child;
  const _NeonWrap({required this.color, required this.child});
  @override
  State<_NeonWrap> createState() => _NeonWrapState();
}

class _NeonWrapState extends State<_NeonWrap> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _ctrl.repeat(reverse: true); });
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: _ctrl.value * 0.5),
              blurRadius: 6 + _ctrl.value * 6,
            ),
          ],
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

// ── 레전더리 (100+) — 무지개 회전 글로우 ───────────────
class _LegendaryWrap extends StatefulWidget {
  final Widget child;
  const _LegendaryWrap({required this.child});
  @override
  State<_LegendaryWrap> createState() => _LegendaryWrapState();
}

class _LegendaryWrapState extends State<_LegendaryWrap> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _ctrl.repeat(); });
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final hue = _ctrl.value * 360;
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: HSLColor.fromAHSL(0.5, hue, 1, 0.5).toColor(),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ── 50+ 닉네임 꾸밈 ──────────────────────────────────
class DecoratedNickname extends StatelessWidget {
  final String nickname;
  final int level;
  final double fontSize;

  const DecoratedNickname({
    super.key,
    required this.nickname,
    required this.level,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    if (level < 50) {
      return Text(
        nickname,
        style: TextStyle(color: const Color(0xFFE2E8F0), fontSize: fontSize, fontWeight: FontWeight.w600),
        overflow: TextOverflow.ellipsis,
      );
    }

    final tier = _Tier.fromLevel(level);
    final colors = level >= 100
        ? [const Color(0xFFFF6B6B), const Color(0xFFFFD700), const Color(0xFF00D4FF), const Color(0xFFFF6B6B)]
        : [tier.primary, const Color(0xFFFFD700), tier.primary];

    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(colors: colors).createShader(bounds),
      child: Text(
        nickname,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          shadows: [Shadow(color: tier.primary.withValues(alpha: 0.5), blurRadius: 6)],
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
