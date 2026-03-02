import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../shared/widgets/ad_banner.dart';
import 'simulations_tab.dart';
import 'favorites_tab.dart';
import 'resources_tab.dart';
import 'settings_tab.dart';

/// 메인 쉘 - 하단 네비게이션 바 포함 (portrait/landscape 반응형)
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;
  DateTime? _lastBackPress;
  bool _settingsPanelOpen = false;

  final List<Widget> _tabs = const [
    SimulationsTab(),
    FavoritesTab(),
    ResourcesTab(),
    SettingsTab(),
  ];

  /// 태블릿 감지: shortestSide >= 600dp
  bool _isTablet(BuildContext context) =>
      MediaQuery.of(context).size.shortestSide >= 600;

  @override
  Widget build(BuildContext context) {
    final isKorean = ref.watch(isKoreanProvider);
    final orientation = MediaQuery.of(context).orientation;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // 설정 패널이 열려있으면 닫기
        if (_settingsPanelOpen && orientation == Orientation.landscape) {
          setState(() => _settingsPanelOpen = false);
          return;
        }

        // 시뮬레이션 탭이 아니면 시뮬레이션 탭으로 이동
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return;
        }

        // 두 번 눌러 종료
        final now = DateTime.now();
        if (_lastBackPress == null ||
            now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isKorean ? '한 번 더 누르면 앱을 종료합니다' : 'Press back again to exit'),
              duration: const Duration(seconds: 2),
              backgroundColor: AppColors.card,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: orientation == Orientation.landscape
          ? _buildLandscapeLayout(isKorean, _isTablet(context))
          : _buildPortraitLayout(isKorean),
    );
  }

  /// Portrait 모드: 기존 하단 네비게이션 바 레이아웃
  Widget _buildPortraitLayout(bool isKorean) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: BottomAdBanner(
        child: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border(
            top: BorderSide(color: AppColors.cardBorder, width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.science_outlined,
                  activeIcon: Icons.science,
                  label: isKorean ? '시뮬레이션' : 'Simulations',
                  isSelected: _currentIndex == 0,
                  onTap: () => _selectTab(0),
                ),
                _NavItem(
                  icon: Icons.favorite_border,
                  activeIcon: Icons.favorite,
                  label: isKorean ? '즐겨찾기' : 'Favorites',
                  isSelected: _currentIndex == 1,
                  onTap: () => _selectTab(1),
                ),
                _NavItem(
                  icon: Icons.menu_book_outlined,
                  activeIcon: Icons.menu_book,
                  label: isKorean ? '자료' : 'Resources',
                  isSelected: _currentIndex == 2,
                  onTap: () => _selectTab(2),
                ),
                _NavItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: isKorean ? '설정' : 'Settings',
                  isSelected: _currentIndex == 3,
                  onTap: () => _selectTab(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Landscape 모드: NavigationRail 왼쪽 + 콘텐츠 가운데 + 설정 패널 오른쪽
  Widget _buildLandscapeLayout(bool isKorean, bool isTablet) {
    final railIndex = _currentIndex.clamp(0, 2);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Row(
          children: [
            _LandscapeNavigationRail(
              selectedIndex: railIndex,
              isSettingsOpen: _settingsPanelOpen,
              isKorean: isKorean,
              isTablet: isTablet,
              onTabSelected: (index) {
                HapticFeedback.selectionClick();
                setState(() {
                  _currentIndex = index;
                });
              },
              onSettingsToggle: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _settingsPanelOpen = !_settingsPanelOpen;
                });
              },
            ),
            Expanded(
              child: BottomAdBanner(
                child: IndexedStack(
                  index: railIndex,
                  children: const [
                    SimulationsTab(),
                    FavoritesTab(),
                    ResourcesTab(),
                  ],
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: _settingsPanelOpen ? (isTablet ? 380 : 320) : 0,
              child: _settingsPanelOpen
                  ? _LandscapeSettingsPanel(
                      onClose: () {
                        setState(() => _settingsPanelOpen = false);
                      },
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  void _selectTab(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }
}

/// Landscape용 NavigationRail
class _LandscapeNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final bool isSettingsOpen;
  final bool isKorean;
  final bool isTablet;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onSettingsToggle;

  const _LandscapeNavigationRail({
    required this.selectedIndex,
    required this.isSettingsOpen,
    required this.isKorean,
    this.isTablet = false,
    required this.onTabSelected,
    required this.onSettingsToggle,
  });

  @override
  Widget build(BuildContext context) {
    final railWidth = isTablet ? 88.0 : 72.0;
    return Container(
      width: railWidth,
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(
          right: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // 앱 아이콘
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.science,
              color: AppColors.accent,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          // 메인 탭들
          _RailItem(
            icon: Icons.science_outlined,
            activeIcon: Icons.science,
            label: isKorean ? '시뮬레이션' : 'Sims',
            isSelected: selectedIndex == 0,
            isTablet: isTablet,
            onTap: () => onTabSelected(0),
          ),
          _RailItem(
            icon: Icons.favorite_border,
            activeIcon: Icons.favorite,
            label: isKorean ? '즐겨찾기' : 'Favs',
            isSelected: selectedIndex == 1,
            isTablet: isTablet,
            onTap: () => onTabSelected(1),
          ),
          _RailItem(
            icon: Icons.menu_book_outlined,
            activeIcon: Icons.menu_book,
            label: isKorean ? '자료' : 'Resources',
            isSelected: selectedIndex == 2,
            isTablet: isTablet,
            onTap: () => onTabSelected(2),
          ),
          const Spacer(),
          // 설정 토글 버튼 (하단 고정)
          _RailItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            label: isKorean ? '설정' : 'Settings',
            isSelected: isSettingsOpen,
            isTablet: isTablet,
            onTap: onSettingsToggle,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// NavigationRail의 개별 아이템
class _RailItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final bool isTablet;
  final VoidCallback onTap;

  const _RailItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    this.isTablet = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final itemWidth = isTablet ? 72.0 : 56.0;
    final iconSize = isTablet ? 26.0 : 22.0;
    final fontSize = isTablet ? 11.0 : 9.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: itemWidth,
          padding: EdgeInsets.symmetric(vertical: isTablet ? 10 : 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accent.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? AppColors.accent : AppColors.muted,
                size: iconSize,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.accent : AppColors.muted,
                  fontSize: fontSize,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
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

/// Landscape용 설정 사이드 패널 - SettingsTab을 래핑
class _LandscapeSettingsPanel extends StatelessWidget {
  final VoidCallback onClose;

  const _LandscapeSettingsPanel({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final panelWidth = MediaQuery.of(context).size.shortestSide >= 600 ? 380.0 : 320.0;
    return ClipRect(
      child: Container(
        width: panelWidth,
        decoration: BoxDecoration(
          color: AppColors.bg,
          border: Border(
            left: BorderSide(color: AppColors.cardBorder, width: 1),
          ),
        ),
        child: Column(
          children: [
            // 패널 헤더 (닫기 버튼 포함)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border(
                  bottom: BorderSide(color: AppColors.cardBorder, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.settings, color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onClose,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.close,
                        color: AppColors.muted,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // SettingsTab 콘텐츠 (AppBar 없이 body 부분만 재사용)
            const Expanded(
              child: _SettingsPanelContent(),
            ),
          ],
        ),
      ),
    );
  }
}

/// 설정 패널 콘텐츠 - SettingsTab의 embedded 모드 사용
/// (Scaffold/AppBar 없이 ListView만 반환)
class _SettingsPanelContent extends StatelessWidget {
  const _SettingsPanelContent();

  @override
  Widget build(BuildContext context) {
    return const SettingsTab(embedded: true);
  }
}

/// Portrait 모드의 하단 네비게이션 아이템
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.accent : AppColors.muted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.accent : AppColors.muted,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
