import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/ad_banner.dart';
import '../../../shared/widgets/subscription_dialog.dart';
import '../../../l10n/app_localizations.dart';
import '../data/simulation_data.dart';

/// Home Screen
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  SimCategory _selectedCategory = SimCategory.all;
  Set<String> _completedSims = {};
  Set<String> _favorites = {};
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _countController;
  late Animation<double> _countAnimation;
  late AnimationController _particleController;
  DateTime? _lastBackPress;
  late List<SimulationInfo> _allSimulations;

  @override
  void initState() {
    super.initState();
    _allSimulations = getSimulations();
    _countController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _countAnimation = CurvedAnimation(
      parent: _countController,
      curve: Curves.easeOutCubic,
    );
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _loadPreferences();
    _countController.forward();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenIntro = prefs.getBool('hasSeenIntro') ?? false;
    if (!hasSeenIntro && mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) _showIntroDialog();
      await prefs.setBool('hasSeenIntro', true);
    }
  }

  void _showIntroDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.science, color: AppColors.accent),
            const SizedBox(width: 8),
            Text(l10n.introTitle, style: const TextStyle(color: AppColors.ink, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.introDescription, style: const TextStyle(color: AppColors.ink, fontSize: 14)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.update, color: AppColors.accent, size: 18),
                      const SizedBox(width: 8),
                      Text(l10n.continuousUpdates, style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(l10n.continuousUpdatesDesc, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent2.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.language, color: AppColors.accent2, size: 18),
                      const SizedBox(width: 8),
                      Text(l10n.webVersionAvailable, style: const TextStyle(color: AppColors.accent2, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('https://3dweb-rust.vercel.app', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.start, style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _completedSims = prefs.getStringList('completedSims')?.toSet() ?? {};
      _favorites = prefs.getStringList('favorites')?.toSet() ?? {};
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

  List<SimulationInfo> _getFilteredSimulations() {
    var result = _allSimulations.toList();
    if (_selectedCategory != SimCategory.all) {
      result = result.where((s) => s.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((s) =>
        s.title.toLowerCase().contains(query) ||
        s.summary.toLowerCase().contains(query) ||
        s.level.toLowerCase().contains(query)
      ).toList();
    }
    return result;
  }

  @override
  void dispose() {
    _countController.dispose();
    _particleController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filteredSimulations = _getFilteredSimulations();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPress == null || now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.pressAgainToExit),
              duration: const Duration(seconds: 2),
              backgroundColor: AppColors.card,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: BottomAdBanner(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 180,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.bg.withValues(alpha: 0.95),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search, color: AppColors.muted),
                    onPressed: () => _showSearchDialog(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: AppColors.muted),
                    onPressed: () => _showSettingsDialog(context, l10n),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    '3DWeb Science Lab',
                    style: TextStyle(color: AppColors.accent, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  background: Stack(
                    children: [
                      AnimatedBuilder(
                        animation: _particleController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: ParticleBackgroundPainter(animation: _particleController.value),
                            size: Size.infinite,
                          );
                        },
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [AppColors.accent.withValues(alpha: 0.05), AppColors.bg],
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 30),
                            Text(l10n.appSubtitle1, style: const TextStyle(color: AppColors.ink, fontSize: 22, fontWeight: FontWeight.bold)),
                            Text(l10n.appSubtitle2, style: const TextStyle(color: AppColors.accent, fontSize: 26, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AnimatedBuilder(
                    animation: _countAnimation,
                    builder: (context, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _AnimatedStatCard(number: (_allSimulations.length * _countAnimation.value).toInt(), suffix: '+', label: l10n.simulations),
                          _ProgressStatCard(completed: _completedSims.length, total: _allSimulations.length, label: l10n.completed),
                          _AnimatedStatCard(number: (_favorites.length * _countAnimation.value).toInt(), suffix: '', label: l10n.favorites, icon: Icons.favorite),
                        ],
                      );
                    },
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: const TextStyle(color: AppColors.ink, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: l10n.searchSimulations,
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.cardBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.cardBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.accent)),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: SimCategory.values.length,
                    itemBuilder: (context, index) {
                      final category = SimCategory.values[index];
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: FilterChip(
                          selected: isSelected,
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedCategory = category);
                          },
                          avatar: Icon(category.icon, size: 14, color: isSelected ? Colors.black : AppColors.muted),
                          label: Text(category.getLabel(_isKorean)),
                          labelStyle: TextStyle(color: isSelected ? Colors.black : AppColors.muted, fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
                          backgroundColor: AppColors.card,
                          selectedColor: AppColors.accent,
                          side: BorderSide(color: isSelected ? AppColors.accent : AppColors.cardBorder),
                          showCheckmark: false,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              if (_searchQuery.isNotEmpty || _selectedCategory != SimCategory.all)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(l10n.results(filteredSimulations.length), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  ),
                ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final sim = filteredSimulations[index];
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: 200 + index * 30),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(offset: Offset(0, 10 * (1 - value)), child: child),
                          );
                        },
                        child: _CompactSimulationCard(
                          sim: sim,
                          isFavorite: _favorites.contains(sim.simId),
                          isCompleted: _completedSims.contains(sim.simId),
                          onFavoriteToggle: () => _toggleFavorite(sim.simId),
                        ),
                      );
                    },
                    childCount: filteredSimulations.length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showSearch(context: context, delegate: SimulationSearchDelegate(_allSimulations));
  }

  void _showSettingsDialog(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.settings, style: const TextStyle(color: AppColors.ink, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.block, color: AppColors.accent),
              title: Text(l10n.removeAds, style: const TextStyle(color: AppColors.ink)),
              subtitle: Text(l10n.monthlyPrice('\$0.99'), style: const TextStyle(color: AppColors.muted)),
              onTap: () {
                Navigator.pop(context);
                SubscriptionDialog.show(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh, color: AppColors.accent),
              title: Text(l10n.resetProgress, style: const TextStyle(color: AppColors.ink)),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('completedSims');
                await prefs.remove('favorites');
                setState(() {
                  _completedSims = {};
                  _favorites = {};
                });
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: AppColors.accent),
              title: Text(l10n.appInfo, style: const TextStyle(color: AppColors.ink)),
              subtitle: const Text('v1.8.0', style: TextStyle(color: AppColors.muted)),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedStatCard extends StatelessWidget {
  final int number;
  final String suffix;
  final String label;
  final IconData? icon;

  const _AnimatedStatCard({required this.number, required this.suffix, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.cardBorder)),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, color: AppColors.accent, size: 16), const SizedBox(width: 4)],
              Text('$number$suffix', style: const TextStyle(fontFamily: 'monospace', fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.accent)),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _ProgressStatCard extends StatelessWidget {
  final int completed;
  final int total;
  final String label;

  const _ProgressStatCard({required this.completed, required this.total, required this.label});

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? completed / total : 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.cardBorder)),
      child: Column(
        children: [
          Text('$completed/$total', style: const TextStyle(fontFamily: 'monospace', fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.accent)),
          const SizedBox(height: 6),
          SizedBox(
            width: 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(value: progress, backgroundColor: AppColors.muted.withValues(alpha: 0.2), valueColor: const AlwaysStoppedAnimation(AppColors.accent), minHeight: 4),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _CompactSimulationCard extends StatelessWidget {
  final SimulationInfo sim;
  final bool isFavorite;
  final bool isCompleted;
  final VoidCallback onFavoriteToggle;

  const _CompactSimulationCard({required this.sim, required this.isFavorite, required this.isCompleted, required this.onFavoriteToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.lightImpact();
            context.go('/simulation/${sim.simId}');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(sim.category.icon, color: AppColors.accent, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isCompleted) Padding(padding: const EdgeInsets.only(right: 4), child: Icon(Icons.check_circle, size: 14, color: Colors.green)),
                          Expanded(child: Text(sim.title, style: const TextStyle(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(sim.level, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                    ],
                  ),
                ),
                _DifficultyIndicator(level: sim.difficulty),
                const SizedBox(width: 8),
                GestureDetector(onTap: onFavoriteToggle, child: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, size: 18, color: isFavorite ? Colors.redAccent : AppColors.muted)),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DifficultyIndicator extends StatelessWidget {
  final int level;
  const _DifficultyIndicator({required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final isActive = index < level;
        return Container(width: 5, height: 5, margin: const EdgeInsets.only(left: 2), decoration: BoxDecoration(shape: BoxShape.circle, color: isActive ? AppColors.accent : AppColors.muted.withValues(alpha: 0.3)));
      }),
    );
  }
}

class ParticleBackgroundPainter extends CustomPainter {
  final double animation;
  ParticleBackgroundPainter({required this.animation});

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
  bool shouldRepaint(covariant ParticleBackgroundPainter oldDelegate) => oldDelegate.animation != animation;
}

class SimulationSearchDelegate extends SearchDelegate<SimulationInfo?> {
  final List<SimulationInfo> simulations;

  SimulationSearchDelegate(this.simulations);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(backgroundColor: AppColors.bg, iconTheme: IconThemeData(color: AppColors.muted)),
      inputDecorationTheme: const InputDecorationTheme(hintStyle: TextStyle(color: AppColors.muted)),
      textTheme: const TextTheme(titleLarge: TextStyle(color: AppColors.ink)),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  Widget _buildSearchResults() {
    final results = simulations.where((s) =>
        s.title.toLowerCase().contains(query.toLowerCase()) ||
        s.summary.toLowerCase().contains(query.toLowerCase()) ||
        s.level.toLowerCase().contains(query.toLowerCase())
    ).toList();

    return Container(
      color: AppColors.bg,
      child: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final sim = results[index];
          return ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(sim.category.icon, color: AppColors.accent),
            ),
            title: Text(sim.title, style: const TextStyle(color: AppColors.ink)),
            subtitle: Text(sim.level, style: const TextStyle(color: AppColors.muted)),
            onTap: () {
              close(context, sim);
              GoRouter.of(context).go('/simulation/${sim.simId}');
            },
          );
        },
      ),
    );
  }
}
