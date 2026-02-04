import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../data/simulation_data.dart';

// Re-export for other files that import from here
export '../data/simulation_data.dart';

/// 시뮬레이션 탭 - 카테고리 그리드 + 검색
class SimulationsTab extends ConsumerStatefulWidget {
  const SimulationsTab({super.key});

  @override
  ConsumerState<SimulationsTab> createState() => _SimulationsTabState();
}

class _SimulationsTabState extends ConsumerState<SimulationsTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _particleController;
  late List<SimulationInfo> _allSimulations;

  @override
  void initState() {
    super.initState();
    _allSimulations = getSimulations();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKorean = ref.watch(languageProvider.notifier).isKorean;
    // Filter out 'all' category for display
    final categories = SimCategory.values.where((c) => c != SimCategory.all).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // 헤더
        SliverAppBar(
          expandedHeight: 160,
          floating: false,
          pinned: true,
          backgroundColor: AppColors.bg.withValues(alpha: 0.95),
          flexibleSpace: FlexibleSpaceBar(
            title: const Text(
              '3DWeb Science Lab',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            background: Stack(
              children: [
                AnimatedBuilder(
                  animation: _particleController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _ParticlePainter(
                        animation: _particleController.value,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.accent.withValues(alpha: 0.05),
                        AppColors.bg,
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        isKorean ? '인터랙티브 과학' : 'Interactive Science',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isKorean ? '시뮬레이션' : 'Simulations',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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

        // 카테고리 그리드
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final category = categories[index];
                final count = _allSimulations
                    .where((s) => s.category == category)
                    .length;
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

        // 하단 패딩: 광고 배너 높이(50) + 여유 공간
        const SliverToBoxAdapter(child: SizedBox(height: 70)),
      ],
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
