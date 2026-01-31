import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/ad_banner.dart';
import '../../../shared/widgets/subscription_dialog.dart';

/// 시뮬레이션 카테고리
enum SimCategory {
  all('전체', Icons.apps),
  physics('물리', Icons.speed),
  math('수학', Icons.functions),
  chaos('혼돈', Icons.grain),
  ai('AI/ML', Icons.psychology);

  final String label;
  final IconData icon;
  const SimCategory(this.label, this.icon);
}

/// 시뮬레이션 메타데이터
class SimulationInfo {
  final String title;
  final String level;
  final String format;
  final String summary;
  final String simId;
  final SimCategory category;
  final int difficulty; // 1-3

  const SimulationInfo({
    required this.title,
    required this.level,
    required this.format,
    required this.summary,
    required this.simId,
    required this.category,
    this.difficulty = 2,
  });
}

/// 시뮬레이션 목록
const List<SimulationInfo> simulations = [
  SimulationInfo(
    title: "단진자 운동",
    level: "물리 엔진",
    format: "시뮬레이션",
    summary: "줄 길이와 중력에 따른 진자 운동을 시뮬레이션합니다.",
    simId: "pendulum",
    category: SimCategory.physics,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "이중 슬릿 간섭",
    level: "물리 엔진",
    format: "시뮬레이션",
    summary: "두 파원의 간섭 패턴을 관찰합니다.",
    simId: "wave",
    category: SimCategory.physics,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "시공간 곡률",
    level: "일반상대성이론",
    format: "3D 시뮬레이션",
    summary: "질량에 의한 시공간 휨을 3D 그리드로 시각화합니다.",
    simId: "gravity",
    category: SimCategory.physics,
    difficulty: 3,
  ),
  SimulationInfo(
    title: "수식 그래프",
    level: "고등",
    format: "2D 그래프",
    summary: "수학 함수를 입력하면 실시간 그래프를 생성합니다.",
    simId: "formula",
    category: SimCategory.math,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "로렌츠 어트랙터",
    level: "혼돈 이론",
    format: "3D 그래프",
    summary: "나비 효과를 시각화하는 혼돈 시스템.",
    simId: "lorenz",
    category: SimCategory.chaos,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "이중 진자",
    level: "혼돈 역학",
    format: "시뮬레이션",
    summary: "카오스 이론을 보여주는 두 개의 연결된 진자.",
    simId: "double-pendulum",
    category: SimCategory.chaos,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "콘웨이의 생명 게임",
    level: "셀룰러 오토마타",
    format: "시뮬레이션",
    summary: "세포가 생존, 탄생, 죽음의 규칙에 따라 진화합니다.",
    simId: "gameoflife",
    category: SimCategory.math,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "집합 연산",
    level: "이산수학",
    format: "인터랙티브",
    summary: "합집합, 교집합, 차집합을 벤다이어그램으로 시각화합니다.",
    simId: "set",
    category: SimCategory.math,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "정렬 알고리즘",
    level: "알고리즘",
    format: "애니메이션",
    summary: "버블, 퀵, 병합 정렬의 동작 과정을 단계별로 비교합니다.",
    simId: "sorting",
    category: SimCategory.ai,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "신경망 플레이그라운드",
    level: "딥러닝",
    format: "인터랙티브",
    summary: "신경망의 순전파와 역전파, 가중치 학습 과정을 시각화합니다.",
    simId: "neuralnet",
    category: SimCategory.ai,
    difficulty: 3,
  ),
  SimulationInfo(
    title: "경사 하강법",
    level: "최적화",
    format: "시각화",
    summary: "손실 함수를 최소화하는 경사 하강법의 수렴 과정을 시각화합니다.",
    simId: "gradient",
    category: SimCategory.ai,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "Mandelbrot 집합",
    level: "프랙탈",
    format: "인터랙티브",
    summary: "zₙ₊₁ = zₙ² + c. 무한한 복잡성의 프랙탈을 탐험합니다.",
    simId: "mandelbrot",
    category: SimCategory.math,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "푸리에 변환",
    level: "신호처리",
    format: "시각화",
    summary: "복잡한 파형을 원운동(에피사이클)으로 분해합니다.",
    simId: "fourier",
    category: SimCategory.math,
    difficulty: 3,
  ),
  SimulationInfo(
    title: "이차함수 꼭짓점",
    level: "고등",
    format: "2D 그래프",
    summary: "a, b, c를 조정하고 꼭짓점 이동을 관찰합니다.",
    simId: "quadratic",
    category: SimCategory.math,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "벡터 내적 탐색기",
    level: "선형대수학",
    format: "2D 그래프",
    summary: "벡터의 내적, 각도, 투영을 시각화합니다.",
    simId: "vector",
    category: SimCategory.math,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "발사체 운동",
    level: "역학",
    format: "시뮬레이션",
    summary: "각도와 속도에 따른 포물선 운동을 시뮬레이션합니다.",
    simId: "projectile",
    category: SimCategory.physics,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "스프링 체인",
    level: "역학",
    format: "시뮬레이션",
    summary: "연결된 스프링의 감쇠 조화 진동을 관찰합니다.",
    simId: "spring",
    category: SimCategory.physics,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "활성화 함수",
    level: "딥러닝",
    format: "시각화",
    summary: "ReLU, Sigmoid, GELU 등 신경망 활성화 함수를 비교합니다.",
    simId: "activation",
    category: SimCategory.ai,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "로지스틱 맵",
    level: "혼돈 이론",
    format: "시각화",
    summary: "분기 다이어그램과 페이겐바움 상수를 통해 카오스의 시작을 관찰합니다.",
    simId: "logistic",
    category: SimCategory.chaos,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "입자 충돌",
    level: "역학",
    format: "시뮬레이션",
    summary: "운동량과 에너지 보존 법칙을 통한 탄성/비탄성 충돌을 시각화합니다.",
    simId: "collision",
    category: SimCategory.physics,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "K-Means 클러스터링",
    level: "머신러닝",
    format: "인터랙티브",
    summary: "비지도 학습으로 데이터를 K개 군집으로 분류하는 과정을 시각화합니다.",
    simId: "kmeans",
    category: SimCategory.ai,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "에라토스테네스의 체",
    level: "정수론",
    format: "알고리즘",
    summary: "고대 그리스의 소수 발견 알고리즘을 단계별로 시각화합니다.",
    simId: "prime",
    category: SimCategory.math,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "3체 문제",
    level: "혼돈 역학",
    format: "시뮬레이션",
    summary: "3개 천체의 중력 상호작용 - 해석적 해가 없는 혼돈 시스템.",
    simId: "threebody",
    category: SimCategory.chaos,
    difficulty: 3,
  ),
  SimulationInfo(
    title: "결정 트리",
    level: "머신러닝",
    format: "인터랙티브",
    summary: "지니 불순도를 최소화하며 데이터를 분할하는 분류 알고리즘.",
    simId: "decision-tree",
    category: SimCategory.ai,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "SVM 분류기",
    level: "머신러닝",
    format: "인터랙티브",
    summary: "최대 마진을 갖는 결정 경계를 찾는 서포트 벡터 머신.",
    simId: "svm",
    category: SimCategory.ai,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "PCA 주성분 분석",
    level: "머신러닝",
    format: "시각화",
    summary: "분산을 최대화하는 방향을 찾아 차원을 축소하는 기법.",
    simId: "pca",
    category: SimCategory.ai,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "전기장 시각화",
    level: "전자기학",
    format: "인터랙티브",
    summary: "점전하 주변의 전기장과 전기력선을 시각화합니다.",
    simId: "electromagnetic",
    category: SimCategory.physics,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "그래프 탐색",
    level: "그래프 이론",
    format: "알고리즘",
    summary: "BFS와 DFS로 그래프를 탐색하는 과정을 시각화합니다.",
    simId: "graph-theory",
    category: SimCategory.math,
    difficulty: 2,
  ),
];

/// H-001~H-028: 개선된 홈 화면
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // H-025~H-028: 카테고리 필터
  SimCategory _selectedCategory = SimCategory.all;

  // H-010: 학습 진행률
  Set<String> _completedSims = {};

  // H-022: 즐겨찾기
  Set<String> _favorites = {};

  // 검색어
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // H-007: 카운트업 애니메이션
  late AnimationController _countController;
  late Animation<double> _countAnimation;

  // H-004: 배경 파티클 애니메이션
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.science, color: AppColors.accent),
            const SizedBox(width: 8),
            const Text(
              '눈으로 보는 과학',
              style: TextStyle(color: AppColors.ink, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '과학과 수학의 원리를 인터랙티브 시뮬레이션으로 배워보세요!',
              style: TextStyle(color: AppColors.ink, fontSize: 14),
            ),
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
                      const Text(
                        '지속적인 업데이트',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '새로운 시뮬레이션과 기능이 계속 추가됩니다.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
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
                      const Text(
                        '웹 버전도 있어요!',
                        style: TextStyle(
                          color: AppColors.accent2,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'https://3dweb-rust.vercel.app',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '시작하기',
              style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
            ),
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

  List<SimulationInfo> get _filteredSimulations {
    var result = simulations.toList();

    // 카테고리 필터
    if (_selectedCategory != SimCategory.all) {
      result = result.where((s) => s.category == _selectedCategory).toList();
    }

    // 검색어 필터
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        final now = DateTime.now();
        if (_lastBackPress == null ||
            now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('한 번 더 누르면 앱을 종료합니다'),
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
        // H-015: 물리 스크롤
        physics: const BouncingScrollPhysics(),
        slivers: [
          // H-001~H-006: 개선된 앱바
          SliverAppBar(
            expandedHeight: 180, // H-003
            floating: false,
            pinned: true,
            backgroundColor: AppColors.bg.withValues(alpha: 0.95),
            // H-005, H-006: 검색/설정 아이콘
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: AppColors.muted),
                onPressed: () => _showSearchDialog(context),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: AppColors.muted),
                onPressed: () => _showSettingsDialog(context),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              // H-001: 타이틀 폰트 크기
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
                  // H-004: 파티클 배경
                  AnimatedBuilder(
                    animation: _particleController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: ParticleBackgroundPainter(
                          animation: _particleController.value,
                        ),
                        size: Size.infinite,
                      );
                    },
                  ),
                  // 그라데이션 오버레이
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
                  // H-002: 새로운 서브타이틀
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 30),
                        Text(
                          '손끝으로 느끼는',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '우주의 법칙',
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

          // H-007~H-010: 개선된 통계
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AnimatedBuilder(
                animation: _countAnimation,
                builder: (context, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // H-007: 카운트업 애니메이션
                      _AnimatedStatCard(
                        number: (62 * _countAnimation.value).toInt(),
                        suffix: '+',
                        label: '시뮬레이션',
                      ),
                      // H-010: 학습 진행률
                      _ProgressStatCard(
                        completed: _completedSims.length,
                        total: simulations.length,
                        label: '완료',
                      ),
                      // 즐겨찾기 수
                      _AnimatedStatCard(
                        number: (_favorites.length * _countAnimation.value).toInt(),
                        suffix: '',
                        label: '즐겨찾기',
                        icon: Icons.favorite,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // 검색 바
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: const TextStyle(color: AppColors.ink, fontSize: 14),
                decoration: InputDecoration(
                  hintText: '시뮬레이션 검색...',
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
                    borderSide: BorderSide(color: AppColors.accent),
                  ),
                ),
              ),
            ),
          ),

          // H-025~H-028: 카테고리 필터
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
                      avatar: Icon(
                        category.icon,
                        size: 14,
                        color: isSelected ? Colors.black : AppColors.muted,
                      ),
                      label: Text(category.label),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : AppColors.muted,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      backgroundColor: AppColors.card,
                      selectedColor: AppColors.accent,
                      side: BorderSide(
                        color: isSelected ? AppColors.accent : AppColors.cardBorder,
                      ),
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

          // 검색 결과 수
          if (_searchQuery.isNotEmpty || _selectedCategory != SimCategory.all)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  '${_filteredSimulations.length}개 결과',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
            ),

          // 콤팩트 리스트 뷰
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final sim = _filteredSimulations[index];
                  // Staggered animation
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 200 + index * 30),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 10 * (1 - value)),
                          child: child,
                        ),
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
                childCount: _filteredSimulations.length,
              ),
            ),
          ),

          // 하단 여백
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
      ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showSearch(
      context: context,
      delegate: SimulationSearchDelegate(simulations),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '설정',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.block, color: AppColors.accent),
              title: const Text('광고 제거', style: TextStyle(color: AppColors.ink)),
              subtitle: const Text('월 ₩990', style: TextStyle(color: AppColors.muted)),
              onTap: () {
                Navigator.pop(context);
                SubscriptionDialog.show(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh, color: AppColors.accent),
              title: const Text('학습 기록 초기화', style: TextStyle(color: AppColors.ink)),
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
              title: const Text('앱 정보', style: TextStyle(color: AppColors.ink)),
              subtitle: const Text('v1.0.0', style: TextStyle(color: AppColors.muted)),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

/// H-007: 애니메이션 통계 카드
class _AnimatedStatCard extends StatelessWidget {
  final int number;
  final String suffix;
  final String label;
  final IconData? icon;

  const _AnimatedStatCard({
    required this.number,
    required this.suffix,
    required this.label,
    this.icon,
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.accent, size: 16),
                const SizedBox(width: 4),
              ],
              Text(
                '$number$suffix',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

/// H-010: 진행률 통계 카드
class _ProgressStatCard extends StatelessWidget {
  final int completed;
  final int total;
  final String label;

  const _ProgressStatCard({
    required this.completed,
    required this.total,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? completed / total : 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Text(
            '$completed/$total',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.muted.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                minHeight: 4,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

/// H-017~H-024: 개선된 시뮬레이션 카드
class _ImprovedSimulationCard extends StatefulWidget {
  final SimulationInfo sim;
  final bool isFavorite;
  final bool isCompleted;
  final VoidCallback onFavoriteToggle;

  const _ImprovedSimulationCard({
    required this.sim,
    required this.isFavorite,
    required this.isCompleted,
    required this.onFavoriteToggle,
  });

  @override
  State<_ImprovedSimulationCard> createState() => _ImprovedSimulationCardState();
}

class _ImprovedSimulationCardState extends State<_ImprovedSimulationCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        context.go('/simulation/${widget.sim.simId}');
      },
      // H-008: 터치 피드백
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: _isPressed
                    ? AppColors.accent.withValues(alpha: 0.2)
                    : AppColors.accent.withValues(alpha: 0.08),
                blurRadius: _isPressed ? 24 : 16,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 행: 배지, 완료, 즐겨찾기
              Row(
                children: [
                  // H-023: 완료 표시
                  if (widget.isCompleted)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 12,
                        color: Colors.green,
                      ),
                    ),
                  // 배지
                  _Badge(text: widget.sim.level, isAlt: true),
                  const Spacer(),
                  // H-024: 난이도 인디케이터
                  _DifficultyIndicator(level: widget.sim.difficulty),
                  const SizedBox(width: 8),
                  // H-022: 즐겨찾기 버튼
                  GestureDetector(
                    onTap: widget.onFavoriteToggle,
                    child: Icon(
                      widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color: widget.isFavorite ? Colors.redAccent : AppColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // H-018: 제목
              Text(
                widget.sim.title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              // H-019: 설명 (2줄)
              Expanded(
                child: Text(
                  widget.sim.summary,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 포맷 배지
              _Badge(text: widget.sim.format),
            ],
          ),
        ),
      ),
    );
  }
}

/// 콤팩트 시뮬레이션 카드 (리스트 뷰용)
class _CompactSimulationCard extends StatelessWidget {
  final SimulationInfo sim;
  final bool isFavorite;
  final bool isCompleted;
  final VoidCallback onFavoriteToggle;

  const _CompactSimulationCard({
    required this.sim,
    required this.isFavorite,
    required this.isCompleted,
    required this.onFavoriteToggle,
  });

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
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // 카테고리 아이콘
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    sim.category.icon,
                    color: AppColors.accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                // 제목 및 설명
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isCompleted)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.check_circle,
                                size: 14,
                                color: Colors.green,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              sim.title,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sim.level,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // 난이도
                _DifficultyIndicator(level: sim.difficulty),
                const SizedBox(width: 8),
                // 즐겨찾기
                GestureDetector(
                  onTap: onFavoriteToggle,
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    size: 18,
                    color: isFavorite ? Colors.redAccent : AppColors.muted,
                  ),
                ),
                const SizedBox(width: 4),
                // 화살표
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// H-024: 난이도 인디케이터
class _DifficultyIndicator extends StatelessWidget {
  final int level;

  const _DifficultyIndicator({required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final isActive = index < level;
        return Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.accent : AppColors.muted.withValues(alpha: 0.3),
          ),
        );
      }),
    );
  }
}

/// 배지 위젯
class _Badge extends StatelessWidget {
  final String text;
  final bool isAlt;

  const _Badge({required this.text, this.isAlt = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isAlt
            ? AppColors.accent.withValues(alpha: 0.12)
            : AppColors.accent2.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isAlt ? AppColors.accent : AppColors.accent2,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// H-004: 파티클 배경 페인터
class ParticleBackgroundPainter extends CustomPainter {
  final double animation;

  ParticleBackgroundPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final random = math.Random(42); // 고정 시드로 일관된 파티클

    for (int i = 0; i < 30; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final speed = 0.2 + random.nextDouble() * 0.3;
      final radius = 1.0 + random.nextDouble() * 2;

      // 천천히 위로 이동
      final y = (baseY - animation * size.height * speed) % size.height;

      final opacity = 0.1 + 0.1 * math.sin(animation * math.pi * 2 + i);
      paint.color = AppColors.accent.withValues(alpha: opacity);

      canvas.drawCircle(Offset(baseX, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticleBackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

/// H-005: 검색 델리게이트
class SimulationSearchDelegate extends SearchDelegate<SimulationInfo?> {
  final List<SimulationInfo> simulations;

  SimulationSearchDelegate(this.simulations);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        iconTheme: IconThemeData(color: AppColors.muted),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: AppColors.muted),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: AppColors.ink),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = simulations
        .where((s) =>
            s.title.toLowerCase().contains(query.toLowerCase()) ||
            s.summary.toLowerCase().contains(query.toLowerCase()) ||
            s.level.toLowerCase().contains(query.toLowerCase()))
        .toList();

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
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.science, color: AppColors.accent),
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
