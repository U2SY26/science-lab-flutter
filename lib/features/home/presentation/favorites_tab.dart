import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import 'simulations_tab.dart';

/// 즐겨찾기 탭
class FavoritesTab extends StatefulWidget {
  const FavoritesTab({super.key});

  @override
  State<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<FavoritesTab> {
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
    return allSimulations
        .where((sim) => _favorites.contains(sim.simId))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text(
          '즐겨찾기',
          style: TextStyle(color: AppColors.ink, fontSize: 20),
        ),
        centerTitle: false,
        actions: [
          if (_favorites.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.muted),
              onPressed: _clearAllFavorites,
              tooltip: '전체 삭제',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
              ? _buildEmptyState()
              : _buildFavoritesList(),
    );
  }

  Widget _buildEmptyState() {
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
            '즐겨찾기가 비어있습니다',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '시뮬레이션에서 하트를 눌러\n즐겨찾기에 추가하세요',
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
            label: const Text('시뮬레이션 둘러보기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
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

  Future<void> _clearAllFavorites() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('즐겨찾기 전체 삭제', style: TextStyle(color: AppColors.ink)),
        content: const Text(
          '모든 즐겨찾기를 삭제하시겠습니까?',
          style: TextStyle(color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
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
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteCard({
    required this.sim,
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
                  color: sim.category.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  sim.category.icon,
                  color: sim.category.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sim.title,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sim.category.label,
                      style: TextStyle(
                        color: sim.category.color,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.favorite, color: Colors.redAccent),
                onPressed: onRemove,
                tooltip: '즐겨찾기 해제',
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
