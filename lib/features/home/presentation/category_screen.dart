import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../shared/widgets/ad_banner.dart' show BottomAdBanner, NativeAdWidget;
import 'simulations_tab.dart';

/// 카테고리별 시뮬레이션 목록 화면
class CategoryScreen extends ConsumerStatefulWidget {
  final String categoryId;

  const CategoryScreen({super.key, required this.categoryId});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  Set<String> _favorites = {};
  Set<String> _completed = {};
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favorites = prefs.getStringList('favorites')?.toSet() ?? {};
      _completed = prefs.getStringList('completedSims')?.toSet() ?? {};
    });
  }

  Future<void> _toggleFavorite(String simId) async {
    HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favorites.contains(simId)) {
        _favorites.remove(simId);
      } else {
        _favorites.add(simId);
      }
    });
    await prefs.setStringList('favorites', _favorites.toList());
  }

  SimCategory? get _category {
    if (widget.categoryId == 'all') return null;
    try {
      return SimCategory.values.firstWhere(
        (c) => c.name == widget.categoryId,
      );
    } catch (e) {
      return null;
    }
  }

  List<SimulationInfo> get _filteredSimulations {
    var result = getSimulations();

    // 카테고리 필터
    if (_category != null) {
      result = result.where((s) => s.category == _category).toList();
    }

    // 검색 필터
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      final isKorean = ref.read(isKoreanProvider);
      result = result.where((s) =>
        s.getTitle(isKorean).toLowerCase().contains(query) ||
        s.getSummary(isKorean).toLowerCase().contains(query) ||
        s.getLevel(isKorean).toLowerCase().contains(query) ||
        s.title.toLowerCase().contains(query) ||
        s.summary.toLowerCase().contains(query)
      ).toList();
    }

    return result;
  }

  String _getTitle(bool isKorean) {
    if (_category != null) {
      return _category!.getLabel(isKorean);
    }
    return isKorean ? '전체 시뮬레이션' : 'All Simulations';
  }

  Color get _categoryColor {
    return _category != null ? getCategoryColor(_category!) : AppColors.accent;
  }

  @override
  Widget build(BuildContext context) {
    final simulations = _filteredSimulations;
    final isKorean = ref.watch(isKoreanProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg.withValues(alpha: 0.95),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            if (_category != null) ...[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _categoryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _category!.icon,
                  color: _categoryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Text(
              _getTitle(isKorean),
              style: const TextStyle(color: AppColors.ink, fontSize: 18),
            ),
          ],
        ),
      ),
      body: BottomAdBanner(
        child: Column(
          children: [
            // 검색 바
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(color: AppColors.ink, fontSize: 14),
              decoration: InputDecoration(
                hintText: isKorean ? '시뮬레이션 검색...' : 'Search simulations...',
                hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppColors.muted, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.muted, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
                filled: true,
                fillColor: AppColors.card,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _categoryColor),
                ),
              ),
            ),
          ),

          // 결과 수
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  isKorean ? '${simulations.length}개의 시뮬레이션' : '${simulations.length} simulations',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const Spacer(),
                if (_category != null)
                  Text(
                    getCategoryDescription(_category!, isKorean: isKorean),
                    style: TextStyle(color: _categoryColor, fontSize: 12),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 시뮬레이션 목록 (네이티브 광고 포함)
          Expanded(
            child: simulations.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: simulations.length + (simulations.length ~/ 5),
                    itemBuilder: (context, index) {
                      // 매 6번째 아이템(index 5, 11, 17...)에 네이티브 광고 삽입
                      final adCount = index ~/ 6;
                      final isAd = index > 0 && (index + 1) % 6 == 0;
                      if (isAd) {
                        return const NativeAdWidget();
                      }
                      final simIndex = index - adCount;
                      if (simIndex >= simulations.length) return const SizedBox.shrink();
                      final sim = simulations[simIndex];
                      return _SimulationCard(
                        sim: sim,
                        isKorean: isKorean,
                        isFavorite: _favorites.contains(sim.simId),
                        isCompleted: _completed.contains(sim.simId),
                        categoryColor: _categoryColor,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.push('/simulation/${sim.simId}');
                        },
                        onFavoriteToggle: () => _toggleFavorite(sim.simId),
                      );
                    },
                  ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isKorean = ref.watch(isKoreanProvider);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.muted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            isKorean ? '검색 결과가 없습니다' : 'No results found',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isKorean ? '다른 검색어를 시도해보세요' : 'Try a different search term',
            style: TextStyle(color: AppColors.muted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _SimulationCard extends StatelessWidget {
  final SimulationInfo sim;
  final bool isKorean;
  final bool isFavorite;
  final bool isCompleted;
  final Color categoryColor;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const _SimulationCard({
    required this.sim,
    required this.isKorean,
    required this.isFavorite,
    required this.isCompleted,
    required this.categoryColor,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                // 카테고리 아이콘
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: getCategoryColor(sim.category).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    sim.category.icon,
                    color: getCategoryColor(sim.category),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                // 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isCompleted)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.green,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              sim.getTitle(isKorean),
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sim.getSummary(isKorean),
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              sim.getLevel(isKorean),
                              style: TextStyle(
                                color: categoryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 난이도 표시
                          _DifficultyDots(level: sim.difficulty),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 즐겨찾기 & 화살표
                Column(
                  children: [
                    GestureDetector(
                      onTap: onFavoriteToggle,
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 22,
                        color: isFavorite ? Colors.redAccent : AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DifficultyDots extends StatelessWidget {
  final int level;

  const _DifficultyDots({required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final isActive = index < level;
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(right: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? AppColors.accent
                : AppColors.muted.withValues(alpha: 0.3),
          ),
        );
      }),
    );
  }
}
