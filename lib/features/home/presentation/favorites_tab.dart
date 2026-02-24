import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import 'simulations_tab.dart';

/// 즐겨찾기 탭
class FavoritesTab extends ConsumerStatefulWidget {
  const FavoritesTab({super.key});

  @override
  ConsumerState<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends ConsumerState<FavoritesTab> {
  Set<String> _favorites = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favorites = prefs.getStringList('favorites')?.toSet() ?? {};
      _isLoading = false;
    });
  }

  Future<void> _removeFavorite(String simId) async {
    HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favorites.remove(simId);
    });
    await prefs.setStringList('favorites', _favorites.toList());
  }

  List<SimulationInfo> get _favoriteSimulations {
    return getSimulations()
        .where((sim) => _favorites.contains(sim.simId))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isKorean = ref.watch(isKoreanProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Text(
          isKorean ? '즐겨찾기' : 'Favorites',
          style: const TextStyle(color: AppColors.ink, fontSize: 20),
        ),
        centerTitle: false,
        actions: [
          if (_favorites.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.muted),
              onPressed: () => _clearAllFavorites(isKorean),
              tooltip: isKorean ? '전체 삭제' : 'Clear all',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
              ? _buildEmptyState(isKorean)
              : _buildFavoritesList(isKorean),
    );
  }

  Widget _buildEmptyState(bool isKorean) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: AppColors.muted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            isKorean ? '즐겨찾기가 비어있습니다' : 'No favorites yet',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isKorean
                ? '시뮬레이션에서 하트를 눌러\n즐겨찾기에 추가하세요'
                : 'Tap the heart icon on simulations\nto add them to favorites',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // 시뮬레이션 탭으로 이동 (부모 위젯에서 처리)
            },
            icon: const Icon(Icons.science),
            label: Text(isKorean ? '시뮬레이션 둘러보기' : 'Browse Simulations'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList(bool isKorean) {
    final favorites = _favoriteSimulations;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final sim = favorites[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _FavoriteCard(
            sim: sim,
            isKorean: isKorean,
            onTap: () {
              HapticFeedback.lightImpact();
              context.push('/simulation/${sim.simId}');
            },
            onRemove: () => _removeFavorite(sim.simId),
          ),
        );
      },
    );
  }

  Future<void> _clearAllFavorites(bool isKorean) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          isKorean ? '즐겨찾기 전체 삭제' : 'Clear All Favorites',
          style: const TextStyle(color: AppColors.ink),
        ),
        content: Text(
          isKorean ? '모든 즐겨찾기를 삭제하시겠습니까?' : 'Delete all favorites?',
          style: const TextStyle(color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isKorean ? '취소' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isKorean ? '삭제' : 'Delete', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.mediumImpact();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('favorites');
      setState(() => _favorites = {});
    }
  }
}

class _FavoriteCard extends StatelessWidget {
  final SimulationInfo sim;
  final bool isKorean;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteCard({
    required this.sim,
    required this.isKorean,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: getCategoryColor(sim.category).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  sim.category.icon,
                  color: getCategoryColor(sim.category),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sim.getTitle(isKorean),
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sim.category.getLabel(isKorean),
                      style: TextStyle(
                        color: getCategoryColor(sim.category),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.favorite, color: Colors.redAccent),
                onPressed: onRemove,
                tooltip: isKorean ? '즐겨찾기 해제' : 'Remove from favorites',
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
