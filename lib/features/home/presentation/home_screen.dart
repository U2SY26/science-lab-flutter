import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/ad_banner.dart';
import '../../../shared/widgets/subscription_dialog.dart';
import '../../../l10n/app_localizations.dart';

/// Simulation category
enum SimCategory {
  all(Icons.apps),
  physics(Icons.speed),
  math(Icons.functions),
  chaos(Icons.grain),
  ai(Icons.psychology);

  final IconData icon;
  const SimCategory(this.icon);

  String getLabel(AppLocalizations l10n) {
    switch (this) {
      case SimCategory.all: return l10n.categoryAll;
      case SimCategory.physics: return l10n.categoryPhysics;
      case SimCategory.math: return l10n.categoryMath;
      case SimCategory.chaos: return l10n.categoryChaos;
      case SimCategory.ai: return l10n.categoryAI;
    }
  }
}

/// Simulation metadata
class SimulationInfo {
  final String simId;
  final SimCategory category;
  final int difficulty;

  const SimulationInfo({
    required this.simId,
    required this.category,
    this.difficulty = 2,
  });

  String getTitle(AppLocalizations l10n) => _getLocalizedTitle(l10n, simId);
  String getLevel(AppLocalizations l10n) => _getLocalizedLevel(l10n, simId);
  String getFormat(AppLocalizations l10n) => _getLocalizedFormat(l10n, simId);
  String getSummary(AppLocalizations l10n) => _getLocalizedSummary(l10n, simId);
}

String _getLocalizedTitle(AppLocalizations l10n, String simId) {
  switch (simId) {
    case 'pendulum': return l10n.simPendulum;
    case 'wave': return l10n.simWave;
    case 'gravity': return l10n.simGravity;
    case 'formula': return l10n.simFormula;
    case 'lorenz': return l10n.simLorenz;
    case 'double-pendulum': return l10n.simDoublePendulum;
    case 'gameoflife': return l10n.simGameOfLife;
    case 'set': return l10n.simSet;
    case 'sorting': return l10n.simSorting;
    case 'neuralnet': return l10n.simNeuralNet;
    case 'gradient': return l10n.simGradient;
    case 'mandelbrot': return l10n.simMandelbrot;
    case 'fourier': return l10n.simFourier;
    case 'quadratic': return l10n.simQuadratic;
    case 'vector': return l10n.simVector;
    case 'projectile': return l10n.simProjectile;
    case 'spring': return l10n.simSpring;
    case 'activation': return l10n.simActivation;
    case 'logistic': return l10n.simLogistic;
    case 'collision': return l10n.simCollision;
    case 'kmeans': return l10n.simKMeans;
    case 'prime': return l10n.simPrime;
    case 'threebody': return l10n.simThreeBody;
    case 'decision-tree': return l10n.simDecisionTree;
    case 'svm': return l10n.simSVM;
    case 'pca': return l10n.simPCA;
    case 'electromagnetic': return l10n.simElectromagnetic;
    case 'graph-theory': return l10n.simGraphTheory;
    default: return simId;
  }
}

String _getLocalizedLevel(AppLocalizations l10n, String simId) {
  switch (simId) {
    case 'pendulum': return l10n.simPendulumLevel;
    case 'wave': return l10n.simWaveLevel;
    case 'gravity': return l10n.simGravityLevel;
    case 'formula': return l10n.simFormulaLevel;
    case 'lorenz': return l10n.simLorenzLevel;
    case 'double-pendulum': return l10n.simDoublePendulumLevel;
    case 'gameoflife': return l10n.simGameOfLifeLevel;
    case 'set': return l10n.simSetLevel;
    case 'sorting': return l10n.simSortingLevel;
    case 'neuralnet': return l10n.simNeuralNetLevel;
    case 'gradient': return l10n.simGradientLevel;
    case 'mandelbrot': return l10n.simMandelbrotLevel;
    case 'fourier': return l10n.simFourierLevel;
    case 'quadratic': return l10n.simQuadraticLevel;
    case 'vector': return l10n.simVectorLevel;
    case 'projectile': return l10n.simProjectileLevel;
    case 'spring': return l10n.simSpringLevel;
    case 'activation': return l10n.simActivationLevel;
    case 'logistic': return l10n.simLogisticLevel;
    case 'collision': return l10n.simCollisionLevel;
    case 'kmeans': return l10n.simKMeansLevel;
    case 'prime': return l10n.simPrimeLevel;
    case 'threebody': return l10n.simThreeBodyLevel;
    case 'decision-tree': return l10n.simDecisionTreeLevel;
    case 'svm': return l10n.simSVMLevel;
    case 'pca': return l10n.simPCALevel;
    case 'electromagnetic': return l10n.simElectromagneticLevel;
    case 'graph-theory': return l10n.simGraphTheoryLevel;
    default: return '';
  }
}

String _getLocalizedFormat(AppLocalizations l10n, String simId) {
  switch (simId) {
    case 'pendulum': return l10n.simPendulumFormat;
    case 'wave': return l10n.simWaveFormat;
    case 'gravity': return l10n.simGravityFormat;
    case 'formula': return l10n.simFormulaFormat;
    case 'lorenz': return l10n.simLorenzFormat;
    case 'double-pendulum': return l10n.simDoublePendulumFormat;
    case 'gameoflife': return l10n.simGameOfLifeFormat;
    case 'set': return l10n.simSetFormat;
    case 'sorting': return l10n.simSortingFormat;
    case 'neuralnet': return l10n.simNeuralNetFormat;
    case 'gradient': return l10n.simGradientFormat;
    case 'mandelbrot': return l10n.simMandelbrotFormat;
    case 'fourier': return l10n.simFourierFormat;
    case 'quadratic': return l10n.simQuadraticFormat;
    case 'vector': return l10n.simVectorFormat;
    case 'projectile': return l10n.simProjectileFormat;
    case 'spring': return l10n.simSpringFormat;
    case 'activation': return l10n.simActivationFormat;
    case 'logistic': return l10n.simLogisticFormat;
    case 'collision': return l10n.simCollisionFormat;
    case 'kmeans': return l10n.simKMeansFormat;
    case 'prime': return l10n.simPrimeFormat;
    case 'threebody': return l10n.simThreeBodyFormat;
    case 'decision-tree': return l10n.simDecisionTreeFormat;
    case 'svm': return l10n.simSVMFormat;
    case 'pca': return l10n.simPCAFormat;
    case 'electromagnetic': return l10n.simElectromagneticFormat;
    case 'graph-theory': return l10n.simGraphTheoryFormat;
    default: return '';
  }
}

String _getLocalizedSummary(AppLocalizations l10n, String simId) {
  switch (simId) {
    case 'pendulum': return l10n.simPendulumSummary;
    case 'wave': return l10n.simWaveSummary;
    case 'gravity': return l10n.simGravitySummary;
    case 'formula': return l10n.simFormulaSummary;
    case 'lorenz': return l10n.simLorenzSummary;
    case 'double-pendulum': return l10n.simDoublePendulumSummary;
    case 'gameoflife': return l10n.simGameOfLifeSummary;
    case 'set': return l10n.simSetSummary;
    case 'sorting': return l10n.simSortingSummary;
    case 'neuralnet': return l10n.simNeuralNetSummary;
    case 'gradient': return l10n.simGradientSummary;
    case 'mandelbrot': return l10n.simMandelbrotSummary;
    case 'fourier': return l10n.simFourierSummary;
    case 'quadratic': return l10n.simQuadraticSummary;
    case 'vector': return l10n.simVectorSummary;
    case 'projectile': return l10n.simProjectileSummary;
    case 'spring': return l10n.simSpringSummary;
    case 'activation': return l10n.simActivationSummary;
    case 'logistic': return l10n.simLogisticSummary;
    case 'collision': return l10n.simCollisionSummary;
    case 'kmeans': return l10n.simKMeansSummary;
    case 'prime': return l10n.simPrimeSummary;
    case 'threebody': return l10n.simThreeBodySummary;
    case 'decision-tree': return l10n.simDecisionTreeSummary;
    case 'svm': return l10n.simSVMSummary;
    case 'pca': return l10n.simPCASummary;
    case 'electromagnetic': return l10n.simElectromagneticSummary;
    case 'graph-theory': return l10n.simGraphTheorySummary;
    default: return '';
  }
}

/// Simulation list
const List<SimulationInfo> simulations = [
  SimulationInfo(simId: "pendulum", category: SimCategory.physics, difficulty: 1),
  SimulationInfo(simId: "wave", category: SimCategory.physics, difficulty: 2),
  SimulationInfo(simId: "gravity", category: SimCategory.physics, difficulty: 3),
  SimulationInfo(simId: "formula", category: SimCategory.math, difficulty: 1),
  SimulationInfo(simId: "lorenz", category: SimCategory.chaos, difficulty: 2),
  SimulationInfo(simId: "double-pendulum", category: SimCategory.chaos, difficulty: 2),
  SimulationInfo(simId: "gameoflife", category: SimCategory.math, difficulty: 1),
  SimulationInfo(simId: "set", category: SimCategory.math, difficulty: 1),
  SimulationInfo(simId: "sorting", category: SimCategory.ai, difficulty: 2),
  SimulationInfo(simId: "neuralnet", category: SimCategory.ai, difficulty: 3),
  SimulationInfo(simId: "gradient", category: SimCategory.ai, difficulty: 2),
  SimulationInfo(simId: "mandelbrot", category: SimCategory.math, difficulty: 2),
  SimulationInfo(simId: "fourier", category: SimCategory.math, difficulty: 3),
  SimulationInfo(simId: "quadratic", category: SimCategory.math, difficulty: 1),
  SimulationInfo(simId: "vector", category: SimCategory.math, difficulty: 2),
  SimulationInfo(simId: "projectile", category: SimCategory.physics, difficulty: 1),
  SimulationInfo(simId: "spring", category: SimCategory.physics, difficulty: 2),
  SimulationInfo(simId: "activation", category: SimCategory.ai, difficulty: 2),
  SimulationInfo(simId: "logistic", category: SimCategory.chaos, difficulty: 2),
  SimulationInfo(simId: "collision", category: SimCategory.physics, difficulty: 2),
  SimulationInfo(simId: "kmeans", category: SimCategory.ai, difficulty: 2),
  SimulationInfo(simId: "prime", category: SimCategory.math, difficulty: 1),
  SimulationInfo(simId: "threebody", category: SimCategory.chaos, difficulty: 3),
  SimulationInfo(simId: "decision-tree", category: SimCategory.ai, difficulty: 2),
  SimulationInfo(simId: "svm", category: SimCategory.ai, difficulty: 2),
  SimulationInfo(simId: "pca", category: SimCategory.ai, difficulty: 2),
  SimulationInfo(simId: "electromagnetic", category: SimCategory.physics, difficulty: 2),
  SimulationInfo(simId: "graph-theory", category: SimCategory.math, difficulty: 2),
];

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

  @override
  void initState() {
    super.initState();
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

  List<SimulationInfo> _getFilteredSimulations(AppLocalizations l10n) {
    var result = simulations.toList();
    if (_selectedCategory != SimCategory.all) {
      result = result.where((s) => s.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((s) =>
        s.getTitle(l10n).toLowerCase().contains(query) ||
        s.getSummary(l10n).toLowerCase().contains(query) ||
        s.getLevel(l10n).toLowerCase().contains(query)
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
    final filteredSimulations = _getFilteredSimulations(l10n);

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
                    onPressed: () => _showSearchDialog(context, l10n),
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
                          _AnimatedStatCard(number: (62 * _countAnimation.value).toInt(), suffix: '+', label: l10n.simulations),
                          _ProgressStatCard(completed: _completedSims.length, total: simulations.length, label: l10n.completed),
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
                          label: Text(category.getLabel(l10n)),
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
                          l10n: l10n,
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

  void _showSearchDialog(BuildContext context, AppLocalizations l10n) {
    showSearch(context: context, delegate: SimulationSearchDelegate(simulations, l10n));
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
              subtitle: const Text('v1.3.0', style: TextStyle(color: AppColors.muted)),
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
  final AppLocalizations l10n;
  final bool isFavorite;
  final bool isCompleted;
  final VoidCallback onFavoriteToggle;

  const _CompactSimulationCard({required this.sim, required this.l10n, required this.isFavorite, required this.isCompleted, required this.onFavoriteToggle});

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
                          Expanded(child: Text(sim.getTitle(l10n), style: const TextStyle(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(sim.getLevel(l10n), style: const TextStyle(color: AppColors.muted, fontSize: 11)),
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
  final AppLocalizations l10n;

  SimulationSearchDelegate(this.simulations, this.l10n);

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
        s.getTitle(l10n).toLowerCase().contains(query.toLowerCase()) ||
        s.getSummary(l10n).toLowerCase().contains(query.toLowerCase()) ||
        s.getLevel(l10n).toLowerCase().contains(query.toLowerCase())
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
              child: const Icon(Icons.science, color: AppColors.accent),
            ),
            title: Text(sim.getTitle(l10n), style: const TextStyle(color: AppColors.ink)),
            subtitle: Text(sim.getLevel(l10n), style: const TextStyle(color: AppColors.muted)),
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
