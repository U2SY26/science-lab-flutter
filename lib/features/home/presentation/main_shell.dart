import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/ad_banner.dart';
import 'simulations_tab.dart';
import 'favorites_tab.dart';
import 'resources_tab.dart';
import 'settings_tab.dart';

/// 메인 쉘 - 하단 네비게이션 바 포함
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  DateTime? _lastBackPress;

  final List<Widget> _tabs = const [
    SimulationsTab(),
    FavoritesTab(),
    ResourcesTab(),
    SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

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
                    label: '시뮬레이션',
                    isSelected: _currentIndex == 0,
                    onTap: () => _selectTab(0),
                  ),
                  _NavItem(
                    icon: Icons.favorite_border,
                    activeIcon: Icons.favorite,
                    label: '즐겨찾기',
                    isSelected: _currentIndex == 1,
                    onTap: () => _selectTab(1),
                  ),
                  _NavItem(
                    icon: Icons.menu_book_outlined,
                    activeIcon: Icons.menu_book,
                    label: '자료',
                    isSelected: _currentIndex == 2,
                    onTap: () => _selectTab(2),
                  ),
                  _NavItem(
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings,
                    label: '설정',
                    isSelected: _currentIndex == 3,
                    onTap: () => _selectTab(3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectTab(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }
}

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
