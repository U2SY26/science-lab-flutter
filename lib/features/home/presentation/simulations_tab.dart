import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rive/rive.dart' hide LinearGradient, RadialGradient;
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/ai_chat_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/providers/user_profile_provider.dart';
import '../../../shared/widgets/ad_banner.dart';
import '../../../shared/widgets/level_badge.dart';
import '../../../shared/widgets/xr_webview_viewer.dart';
import '../data/simulation_data.dart';
import '../data/xr_sim_ids.dart';

// Re-export for other files that import from here
export '../data/simulation_data.dart';

/// 시뮬레이션 탭 — 카테고리 그리드 + XR 3D 서브탭
class SimulationsTab extends ConsumerStatefulWidget {
  const SimulationsTab({super.key});

  @override
  ConsumerState<SimulationsTab> createState() => _SimulationsTabState();
}

class _SimulationsTabState extends ConsumerState<SimulationsTab>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _particleController;
  late List<SimulationInfo> _allSimulations;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _allSimulations = getSimulations();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKorean = ref.watch(isKoreanProvider);

    return Stack(
      children: [
      NestedScrollView(
      physics: const BouncingScrollPhysics(),
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          expandedHeight: 325,
          floating: false,
          pinned: true,
          forceElevated: innerBoxIsScrolled,
          backgroundColor: Colors.black,
          flexibleSpace: Container(color: Colors.black),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.accent,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.muted,
            tabs: [
              Tab(text: isKorean ? '카테고리' : 'Categories'),
              const Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.view_in_ar, size: 16),
                    SizedBox(width: 4),
                    Text('XR 3D'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryView(isKorean),
          _buildXrView(isKorean),
        ],
      ),
    ),
      // Rive 히어로 오버레이 — 터치 가능, SliverAppBar 위에 겹침
      Positioned(
        left: 0, right: 0,
        top: MediaQuery.of(context).padding.top + 23,
        height: 260,
        child: IgnorePointer(
          ignoring: false, // 터치 전달
          child: const _RiveHeroMotion(),
        ),
      ),
      ],
    );
  }

  // ── 카테고리 탭 ────────────────────────────────────────────────
  Widget _buildCategoryView(bool isKorean) {
    final categories =
        SimCategory.values.where((c) => c != SimCategory.all).toList();

    return CustomScrollView(
      key: const PageStorageKey('categories'),
      physics: const BouncingScrollPhysics(),
      slivers: [
        // 레벨 프로필 바
        SliverToBoxAdapter(
          child: Consumer(builder: (context, ref, _) {
            final profile = ref.watch(userProfileProvider).profile;
            if (profile == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF7C3AED).withValues(alpha: 0.12),
                      const Color(0xFF8B5CF6).withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    LevelBadge(level: profile.level, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              DecoratedNickname(nickname: profile.nickname, level: profile.level, fontSize: 13),
                              const Spacer(),
                              Text(
                                '${profile.xp} XP',
                                style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: profile.levelProgress,
                              backgroundColor: AppColors.cardBorder,
                              valueColor: const AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
                              minHeight: 4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isKorean
                                ? '다음 레벨까지 ${profile.xpToNextLevel} XP'
                                : '${profile.xpToNextLevel} XP to next level',
                            style: TextStyle(color: AppColors.muted.withValues(alpha: 0.6), fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),

        // 통계
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatCard(
                  number: '${_allSimulations.length}+',
                  label: isKorean ? '시뮬레이션' : 'Simulations',
                  icon: Icons.science,
                ),
                _StatCard(
                  number: '${categories.length}',
                  label: isKorean ? '카테고리' : 'Categories',
                  icon: Icons.category,
                ),
                _StatCard(
                  number: isKorean ? '무료' : 'Free',
                  label: isKorean ? '전부 무료' : 'All Free',
                  icon: Icons.card_giftcard,
                ),
              ],
            ),
          ),
        ),

        // 오늘의 시뮬레이션
        SliverToBoxAdapter(
          child: _TodaySimCard(
            allSimulations: _allSimulations,
            isKorean: isKorean,
          ),
        ),

        // 섹션 타이틀
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              isKorean ? '카테고리 선택' : 'Select Category',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // 카테고리 그리드 (10인치+: 4열, 7인치+: 3열, 폰: 2열)
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: () {
                final s = MediaQuery.of(context).size.shortestSide;
                if (s >= 800) return 4;
                if (s >= 600) return 3;
                return 2;
              }(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final category = categories[index];
                final count =
                    _allSimulations.where((s) => s.category == category).length;
                return _CategoryCard(
                  category: category,
                  simulationCount: count,
                  isKorean: isKorean,
                  onTap: () => _openCategory(context, category),
                );
              },
              childCount: categories.length,
            ),
          ),
        ),

        // 네이티브 광고
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: NativeAdWidget(),
          ),
        ),

        // 전체 보기 버튼
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () => _openAllSimulations(context),
              icon: const Icon(Icons.list),
              label: Text(isKorean ? '전체 시뮬레이션 보기' : 'View All Simulations'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: BorderSide(color: AppColors.accent),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        // 하단 패딩
        const SliverToBoxAdapter(child: SizedBox(height: 70)),
      ],
    );
  }

  // ── XR 3D 탭 ──────────────────────────────────────────────────
  Widget _buildXrView(bool isKorean) {
    final xrSims = _allSimulations
        .where((s) => kXrSimIds.contains(s.simId))
        .toList()
      ..sort((a, b) {
        final cmp = a.category.index.compareTo(b.category.index);
        if (cmp != 0) return cmp;
        return a.getTitle(isKorean).compareTo(b.getTitle(isKorean));
      });

    return ListView.builder(
      key: const PageStorageKey('xr3d'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: xrSims.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const Icon(Icons.view_in_ar, color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                Text(
                  isKorean
                      ? '${xrSims.length}개 XR 시뮬레이션'
                      : '${xrSims.length} XR Simulations',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }
        final sim = xrSims[index - 1];
        return _XrSimCard(sim: sim, isKorean: isKorean);
      },
    );
  }

  void _openCategory(BuildContext context, SimCategory category) {
    HapticFeedback.lightImpact();
    context.push('/category/${category.name}');
  }

  void _openAllSimulations(BuildContext context) {
    HapticFeedback.lightImpact();
    context.push('/category/all');
  }
}

// ── XR 시뮬레이션 카드 ────────────────────────────────────────────
class _XrSimCard extends ConsumerWidget {
  final SimulationInfo sim;
  final bool isKorean;

  const _XrSimCard({required this.sim, required this.isKorean});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = getCategoryColor(sim.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(sim.category.icon, color: color, size: 20),
        ),
        title: Text(
          sim.getTitle(isKorean),
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          sim.category.getLabel(isKorean),
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        trailing: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => XrWebViewViewer(simId: sim.simId),
              ),
            ).then((_) {
              // XR 종료 시 AI 튜터 오버레이 복원
              if (context.mounted) {
                ref.read(showAiOverlayProvider.notifier).state = true;
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF00D4FF), width: 1),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.view_in_ar, color: Color(0xFF00D4FF), size: 16),
                SizedBox(width: 4),
                Text(
                  '3D',
                  style: TextStyle(
                    color: Color(0xFF00D4FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        onTap: () => context.push('/simulation/${sim.simId}'),
      ),
    );
  }
}

// ── 통계 카드 ──────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String number;
  final String label;
  final IconData icon;

  const _StatCard({
    required this.number,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accent, size: 20),
          const SizedBox(height: 4),
          Text(
            number,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Category color mapping
Color getCategoryColor(SimCategory category) {
  switch (category) {
    case SimCategory.physics:
      return const Color(0xFF4ECDC4);
    case SimCategory.math:
      return const Color(0xFFFFE66D);
    case SimCategory.chemistry:
      return const Color(0xFFFF6B6B);
    case SimCategory.ai:
      return const Color(0xFF95E1D3);
    case SimCategory.chaos:
      return const Color(0xFFA8E6CF);
    case SimCategory.biology:
      return const Color(0xFF98D8C8);
    case SimCategory.quantum:
      return const Color(0xFF7B68EE);
    case SimCategory.astronomy:
      return const Color(0xFFFFB347);
    case SimCategory.relativity:
      return const Color(0xFF87CEEB);
    case SimCategory.earth:
      return const Color(0xFF8FBC8F);
    case SimCategory.all:
      return AppColors.accent;
  }
}

/// Category description mapping
String getCategoryDescription(SimCategory category, {bool isKorean = false}) {
  if (isKorean) {
    switch (category) {
      case SimCategory.physics:
        return '역학, 파동, 전자기';
      case SimCategory.math:
        return '대수, 기하, 미적분';
      case SimCategory.chemistry:
        return '원자, 분자, 반응';
      case SimCategory.ai:
        return '머신러닝, 딥러닝';
      case SimCategory.chaos:
        return '카오스 이론, 프랙탈';
      case SimCategory.biology:
        return '세포, 유전, 진화';
      case SimCategory.quantum:
        return '파동함수, 불확정성';
      case SimCategory.astronomy:
        return '별, 행성, 은하';
      case SimCategory.relativity:
        return '특수 및 일반 상대성';
      case SimCategory.earth:
        return '지질, 기후, 대기';
      case SimCategory.all:
        return '전체 시뮬레이션';
    }
  }
  switch (category) {
    case SimCategory.physics:
      return 'Mechanics, Waves, E&M';
    case SimCategory.math:
      return 'Algebra, Geometry, Calculus';
    case SimCategory.chemistry:
      return 'Atoms, Molecules, Reactions';
    case SimCategory.ai:
      return 'Machine Learning, Deep Learning';
    case SimCategory.chaos:
      return 'Chaos Theory, Fractals';
    case SimCategory.biology:
      return 'Cells, Genetics, Evolution';
    case SimCategory.quantum:
      return 'Wave Functions, Uncertainty';
    case SimCategory.astronomy:
      return 'Stars, Planets, Galaxies';
    case SimCategory.relativity:
      return 'Special & General Relativity';
    case SimCategory.earth:
      return 'Geology, Climate, Atmosphere';
    case SimCategory.all:
      return 'All Simulations';
  }
}

class _CategoryCard extends StatelessWidget {
  final SimCategory category;
  final int simulationCount;
  final bool isKorean;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.simulationCount,
    required this.isKorean,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = getCategoryColor(category);
    final description = getCategoryDescription(category, isKorean: isKorean);

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      category.icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$simulationCount',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                category.getLabel(isKorean),
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 메인 히어로 — 매번 랜덤 이펙트 (쿵 찍기, 물결, 글리치, 타이핑 등)
class _AnimatedHeroTitle extends StatefulWidget {
  final bool isKorean;
  const _AnimatedHeroTitle({required this.isKorean});

  @override
  State<_AnimatedHeroTitle> createState() => _AnimatedHeroTitleState();
}

class _AnimatedHeroTitleState extends State<_AnimatedHeroTitle>
    with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late AnimationController _loopCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late int _effectIndex;

  // 이펙트 종류: 0=쿵찍기, 1=글자별등장, 2=글리치, 3=바운스
  static final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _effectIndex = _rng.nextInt(4);

    _mainCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _loopCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3));

    // 쿵 찍기: 크게 → 원래 크기 + 흔들림
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 3.0, end: 0.95), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.05), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 0.98), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.98, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _mainCtrl, curve: Curves.easeOut));

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _mainCtrl, curve: const Interval(0, 0.3)),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _mainCtrl.forward();
        _loopCtrl.repeat();
      }
    });
  }

  @override
  void dispose() { _mainCtrl.dispose(); _loopCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final title = widget.isKorean ? '눈으로 보는 과학' : 'Visual Science';

    return AnimatedBuilder(
      animation: Listenable.merge([_mainCtrl, _loopCtrl]),
      builder: (context, _) {
        Widget titleWidget;

        switch (_effectIndex) {
          case 0: // 쿵 찍기 + 지진 흔들림
            final shake = _mainCtrl.value < 0.5
                ? math.sin(_mainCtrl.value * math.pi * 12) * (1 - _mainCtrl.value * 2) * 4
                : 0.0;
            titleWidget = Transform.translate(
              offset: Offset(shake, 0),
              child: Transform.scale(
                scale: _scaleAnim.value,
                child: Opacity(
                  opacity: _fadeAnim.value,
                  child: _buildTitle(title),
                ),
              ),
            );
          case 1: // 글자별 순차 등장
            titleWidget = Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(title.length, (i) {
                final charDelay = i / title.length;
                final progress = ((_mainCtrl.value - charDelay * 0.6) / 0.4).clamp(0.0, 1.0);
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - Curves.elasticOut.transform(progress))),
                  child: Opacity(
                    opacity: progress,
                    child: _buildChar(title[i]),
                  ),
                );
              }),
            );
          case 2: // 글리치 효과
            final glitch = _mainCtrl.value < 0.7;
            final offset1 = glitch ? (_rng.nextDouble() - 0.5) * 6 * (1 - _mainCtrl.value) : 0.0;
            final offset2 = glitch ? (_rng.nextDouble() - 0.5) * 6 * (1 - _mainCtrl.value) : 0.0;
            titleWidget = Opacity(
              opacity: _fadeAnim.value,
              child: Stack(
                children: [
                  if (glitch) Transform.translate(
                    offset: Offset(offset1, offset2),
                    child: _buildTitle(title, color: const Color(0xFFFF0040).withValues(alpha: 0.6)),
                  ),
                  if (glitch) Transform.translate(
                    offset: Offset(-offset1, -offset2),
                    child: _buildTitle(title, color: const Color(0xFF00D4FF).withValues(alpha: 0.6)),
                  ),
                  _buildTitle(title),
                ],
              ),
            );
          default: // 바운스 드롭
            final bounce = Curves.bounceOut.transform(_mainCtrl.value);
            titleWidget = Transform.translate(
              offset: Offset(0, -80 * (1 - bounce)),
              child: Opacity(
                opacity: _mainCtrl.value.clamp(0.0, 1.0),
                child: _buildTitle(title),
              ),
            );
        }

        // 루프 쉬머 그라디언트 오버레이
        return ShaderMask(
          shaderCallback: (bounds) {
            final offset = _loopCtrl.value * 2 - 0.5;
            return LinearGradient(
              begin: Alignment(offset - 0.3, 0),
              end: Alignment(offset + 0.3, 0),
              colors: const [
                Color(0xFFE2E8F0),
                Color(0xFF00D4FF),
                Color(0xFFFFD700),
                Color(0xFF00D4FF),
                Color(0xFFE2E8F0),
              ],
              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
            ).createShader(bounds);
          },
          child: titleWidget,
        );
      },
    );
  }

  Widget _buildTitle(String text, {Color? color}) {
    return Text(
      text,
      style: TextStyle(
        color: color ?? Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildChar(String ch) {
    return Text(
      ch,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double animation;

  _ParticlePainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(42);

    for (int i = 0; i < 30; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final speed = 0.2 + random.nextDouble() * 0.3;
      final radius = 1.0 + random.nextDouble() * 2;

      final y = (baseY - animation * size.height * speed) % size.height;
      final opacity = 0.1 + 0.1 * math.sin(animation * math.pi * 2 + i);
      paint.color = AppColors.accent.withValues(alpha: opacity);

      canvas.drawCircle(Offset(baseX, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

/// 오늘의 시뮬레이션 — 매일 다른 시뮬레이션 추천
class _TodaySimCard extends StatelessWidget {
  final List<SimulationInfo> allSimulations;
  final bool isKorean;

  const _TodaySimCard({required this.allSimulations, required this.isKorean});

  SimulationInfo _todaySim() {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return allSimulations[dayOfYear % allSimulations.length];
  }

  @override
  Widget build(BuildContext context) {
    final sim = _todaySim();
    final color = getCategoryColor(sim.category);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GestureDetector(
        onTap: () => context.push('/simulation/${sim.simId}'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.15),
                const Color(0xFF7C3AED).withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              // 아이콘
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(sim.category.icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              // 텍스트
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isKorean ? '⭐ 오늘의 추천' : '⭐ Today\'s Pick',
                            style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          sim.category.getLabel(isKorean),
                          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sim.getTitle(isKorean),
                      style: const TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sim.getSummary(isKorean),
                      style: TextStyle(color: AppColors.muted.withValues(alpha: 0.7), fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, color: color.withValues(alpha: 0.5), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// 히어로 헤더 — Rive 모션 캐릭터 (터치 인터랙션 지원)
class _RiveHeroMotion extends StatelessWidget {
  const _RiveHeroMotion();

  @override
  Widget build(BuildContext context) {
    return const RiveAnimation.asset(
      'assets/rive/hero_motion.riv',
      fit: BoxFit.contain,
      stateMachines: ['State Machine 1'],
    );
  }
}
