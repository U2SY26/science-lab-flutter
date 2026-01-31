import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 주기율표 탐색기
class PeriodicTableScreen extends StatefulWidget {
  const PeriodicTableScreen({super.key});

  @override
  State<PeriodicTableScreen> createState() => _PeriodicTableScreenState();
}

class _PeriodicTableScreenState extends State<PeriodicTableScreen> {
  Element? _selectedElement;
  String _filterCategory = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg.withValues(alpha: 0.9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '화학',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '주기율표 탐색기',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '화학',
          title: '주기율표 탐색기',
          formula: '원소 = 양성자 수에 의해 결정',
          formulaDescription: '멘델레예프의 주기율표 - 118개 원소의 체계적 분류',
          simulation: SizedBox(
            height: 400,
            child: Column(
              children: [
                // 카테고리 필터
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: '전체',
                        isSelected: _filterCategory == 'all',
                        onTap: () => setState(() => _filterCategory = 'all'),
                      ),
                      _FilterChip(
                        label: '알칼리금속',
                        isSelected: _filterCategory == 'alkali',
                        color: const Color(0xFFFF6B6B),
                        onTap: () => setState(() => _filterCategory = 'alkali'),
                      ),
                      _FilterChip(
                        label: '할로겐',
                        isSelected: _filterCategory == 'halogen',
                        color: const Color(0xFF4ECDC4),
                        onTap: () => setState(() => _filterCategory = 'halogen'),
                      ),
                      _FilterChip(
                        label: '비활성기체',
                        isSelected: _filterCategory == 'noble',
                        color: const Color(0xFF95E1D3),
                        onTap: () => setState(() => _filterCategory = 'noble'),
                      ),
                      _FilterChip(
                        label: '전이금속',
                        isSelected: _filterCategory == 'transition',
                        color: const Color(0xFFFFE66D),
                        onTap: () => setState(() => _filterCategory = 'transition'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 주기율표
                Expanded(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: _buildPeriodicTable(),
                  ),
                ),
              ],
            ),
          ),
          controls: _selectedElement != null
              ? _ElementDetails(element: _selectedElement!)
              : const Center(
                  child: Text(
                    '원소를 탭하여 자세한 정보를 확인하세요',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: 'H (수소)',
                icon: Icons.filter_1,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedElement = _elements[0]);
                },
              ),
              SimButton(
                label: 'C (탄소)',
                icon: Icons.filter_6,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedElement = _elements[5]);
                },
              ),
              SimButton(
                label: 'Au (금)',
                icon: Icons.monetization_on,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedElement = _elements.firstWhere((e) => e.symbol == 'Au'));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodicTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = (constraints.maxWidth - 32) / 18;

        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.simBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(7, (row) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(18, (col) {
                  final element = _getElementAt(row, col);
                  if (element == null) {
                    return SizedBox(width: cellSize, height: cellSize);
                  }

                  final isFiltered = _filterCategory == 'all' ||
                      element.category == _filterCategory;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedElement = element);
                    },
                    child: Container(
                      width: cellSize,
                      height: cellSize,
                      margin: const EdgeInsets.all(0.5),
                      decoration: BoxDecoration(
                        color: isFiltered
                            ? element.color.withValues(alpha: _selectedElement == element ? 1.0 : 0.7)
                            : AppColors.card.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                        border: _selectedElement == element
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.all(1),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${element.atomicNumber}',
                                style: TextStyle(
                                  fontSize: 6,
                                  color: isFiltered ? Colors.white70 : AppColors.muted,
                                ),
                              ),
                              Text(
                                element.symbol,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isFiltered ? Colors.white : AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            }),
          ),
        );
      },
    );
  }

  Element? _getElementAt(int row, int col) {
    // 주기율표 레이아웃 매핑
    final layout = [
      [1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 2],
      [3, 4, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 5, 6, 7, 8, 9, 10],
      [11, 12, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 13, 14, 15, 16, 17, 18],
      [19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36],
      [37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54],
      [55, 56, -1, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86],
      [87, 88, -1, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118],
    ];

    if (row >= layout.length || col >= layout[row].length) return null;
    final atomicNum = layout[row][col];
    if (atomicNum <= 0 || atomicNum > _elements.length) return null;
    return _elements[atomicNum - 1];
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? AppColors.accent).withValues(alpha: 0.3)
              : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? (color ?? AppColors.accent) : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? (color ?? AppColors.accent) : AppColors.muted,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ElementDetails extends StatelessWidget {
  final Element element;

  const _ElementDetails({required this.element});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: element.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: element.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: element.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${element.atomicNumber}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      element.symbol,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      element.name,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      element.nameKorean,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailRow(label: '원자량', value: '${element.atomicMass} u'),
          _DetailRow(label: '전자배치', value: element.electronConfig),
          _DetailRow(label: '분류', value: element.categoryName),
          if (element.meltingPoint != null)
            _DetailRow(label: '녹는점', value: '${element.meltingPoint} K'),
          if (element.boilingPoint != null)
            _DetailRow(label: '끓는점', value: '${element.boilingPoint} K'),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 원소 데이터 클래스
class Element {
  final int atomicNumber;
  final String symbol;
  final String name;
  final String nameKorean;
  final double atomicMass;
  final String electronConfig;
  final String category;
  final String categoryName;
  final Color color;
  final double? meltingPoint;
  final double? boilingPoint;

  const Element({
    required this.atomicNumber,
    required this.symbol,
    required this.name,
    required this.nameKorean,
    required this.atomicMass,
    required this.electronConfig,
    required this.category,
    required this.categoryName,
    required this.color,
    this.meltingPoint,
    this.boilingPoint,
  });
}

/// 주요 원소 데이터
const List<Element> _elements = [
  Element(atomicNumber: 1, symbol: 'H', name: 'Hydrogen', nameKorean: '수소', atomicMass: 1.008, electronConfig: '1s¹', category: 'nonmetal', categoryName: '비금속', color: Color(0xFF95E1D3), meltingPoint: 14.01, boilingPoint: 20.28),
  Element(atomicNumber: 2, symbol: 'He', name: 'Helium', nameKorean: '헬륨', atomicMass: 4.003, electronConfig: '1s²', category: 'noble', categoryName: '비활성기체', color: Color(0xFF95E1D3), meltingPoint: 0.95, boilingPoint: 4.22),
  Element(atomicNumber: 3, symbol: 'Li', name: 'Lithium', nameKorean: '리튬', atomicMass: 6.941, electronConfig: '[He]2s¹', category: 'alkali', categoryName: '알칼리금속', color: Color(0xFFFF6B6B), meltingPoint: 453.69, boilingPoint: 1615),
  Element(atomicNumber: 4, symbol: 'Be', name: 'Beryllium', nameKorean: '베릴륨', atomicMass: 9.012, electronConfig: '[He]2s²', category: 'alkaline', categoryName: '알칼리토금속', color: Color(0xFFFFAA5C), meltingPoint: 1560, boilingPoint: 2742),
  Element(atomicNumber: 5, symbol: 'B', name: 'Boron', nameKorean: '붕소', atomicMass: 10.81, electronConfig: '[He]2s²2p¹', category: 'metalloid', categoryName: '준금속', color: Color(0xFFA8E6CF), meltingPoint: 2349, boilingPoint: 4200),
  Element(atomicNumber: 6, symbol: 'C', name: 'Carbon', nameKorean: '탄소', atomicMass: 12.01, electronConfig: '[He]2s²2p²', category: 'nonmetal', categoryName: '비금속', color: Color(0xFF95E1D3), meltingPoint: 3823, boilingPoint: 4098),
  Element(atomicNumber: 7, symbol: 'N', name: 'Nitrogen', nameKorean: '질소', atomicMass: 14.01, electronConfig: '[He]2s²2p³', category: 'nonmetal', categoryName: '비금속', color: Color(0xFF95E1D3), meltingPoint: 63.15, boilingPoint: 77.36),
  Element(atomicNumber: 8, symbol: 'O', name: 'Oxygen', nameKorean: '산소', atomicMass: 16.00, electronConfig: '[He]2s²2p⁴', category: 'nonmetal', categoryName: '비금속', color: Color(0xFF95E1D3), meltingPoint: 54.36, boilingPoint: 90.20),
  Element(atomicNumber: 9, symbol: 'F', name: 'Fluorine', nameKorean: '플루오린', atomicMass: 19.00, electronConfig: '[He]2s²2p⁵', category: 'halogen', categoryName: '할로겐', color: Color(0xFF4ECDC4), meltingPoint: 53.53, boilingPoint: 85.03),
  Element(atomicNumber: 10, symbol: 'Ne', name: 'Neon', nameKorean: '네온', atomicMass: 20.18, electronConfig: '[He]2s²2p⁶', category: 'noble', categoryName: '비활성기체', color: Color(0xFF95E1D3), meltingPoint: 24.56, boilingPoint: 27.07),
  Element(atomicNumber: 11, symbol: 'Na', name: 'Sodium', nameKorean: '나트륨', atomicMass: 22.99, electronConfig: '[Ne]3s¹', category: 'alkali', categoryName: '알칼리금속', color: Color(0xFFFF6B6B), meltingPoint: 370.87, boilingPoint: 1156),
  Element(atomicNumber: 12, symbol: 'Mg', name: 'Magnesium', nameKorean: '마그네슘', atomicMass: 24.31, electronConfig: '[Ne]3s²', category: 'alkaline', categoryName: '알칼리토금속', color: Color(0xFFFFAA5C), meltingPoint: 923, boilingPoint: 1363),
  Element(atomicNumber: 13, symbol: 'Al', name: 'Aluminum', nameKorean: '알루미늄', atomicMass: 26.98, electronConfig: '[Ne]3s²3p¹', category: 'post-transition', categoryName: '전이후금속', color: Color(0xFFB8B8D1), meltingPoint: 933.47, boilingPoint: 2792),
  Element(atomicNumber: 14, symbol: 'Si', name: 'Silicon', nameKorean: '규소', atomicMass: 28.09, electronConfig: '[Ne]3s²3p²', category: 'metalloid', categoryName: '준금속', color: Color(0xFFA8E6CF), meltingPoint: 1687, boilingPoint: 3538),
  Element(atomicNumber: 15, symbol: 'P', name: 'Phosphorus', nameKorean: '인', atomicMass: 30.97, electronConfig: '[Ne]3s²3p³', category: 'nonmetal', categoryName: '비금속', color: Color(0xFF95E1D3), meltingPoint: 317.30, boilingPoint: 550),
  Element(atomicNumber: 16, symbol: 'S', name: 'Sulfur', nameKorean: '황', atomicMass: 32.07, electronConfig: '[Ne]3s²3p⁴', category: 'nonmetal', categoryName: '비금속', color: Color(0xFF95E1D3), meltingPoint: 388.36, boilingPoint: 717.87),
  Element(atomicNumber: 17, symbol: 'Cl', name: 'Chlorine', nameKorean: '염소', atomicMass: 35.45, electronConfig: '[Ne]3s²3p⁵', category: 'halogen', categoryName: '할로겐', color: Color(0xFF4ECDC4), meltingPoint: 171.6, boilingPoint: 239.11),
  Element(atomicNumber: 18, symbol: 'Ar', name: 'Argon', nameKorean: '아르곤', atomicMass: 39.95, electronConfig: '[Ne]3s²3p⁶', category: 'noble', categoryName: '비활성기체', color: Color(0xFF95E1D3), meltingPoint: 83.80, boilingPoint: 87.30),
  // 4주기
  Element(atomicNumber: 19, symbol: 'K', name: 'Potassium', nameKorean: '칼륨', atomicMass: 39.10, electronConfig: '[Ar]4s¹', category: 'alkali', categoryName: '알칼리금속', color: Color(0xFFFF6B6B)),
  Element(atomicNumber: 20, symbol: 'Ca', name: 'Calcium', nameKorean: '칼슘', atomicMass: 40.08, electronConfig: '[Ar]4s²', category: 'alkaline', categoryName: '알칼리토금속', color: Color(0xFFFFAA5C)),
  Element(atomicNumber: 21, symbol: 'Sc', name: 'Scandium', nameKorean: '스칸듐', atomicMass: 44.96, electronConfig: '[Ar]3d¹4s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 22, symbol: 'Ti', name: 'Titanium', nameKorean: '타이타늄', atomicMass: 47.87, electronConfig: '[Ar]3d²4s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 23, symbol: 'V', name: 'Vanadium', nameKorean: '바나듐', atomicMass: 50.94, electronConfig: '[Ar]3d³4s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 24, symbol: 'Cr', name: 'Chromium', nameKorean: '크로뮴', atomicMass: 52.00, electronConfig: '[Ar]3d⁵4s¹', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 25, symbol: 'Mn', name: 'Manganese', nameKorean: '망가니즈', atomicMass: 54.94, electronConfig: '[Ar]3d⁵4s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 26, symbol: 'Fe', name: 'Iron', nameKorean: '철', atomicMass: 55.85, electronConfig: '[Ar]3d⁶4s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 27, symbol: 'Co', name: 'Cobalt', nameKorean: '코발트', atomicMass: 58.93, electronConfig: '[Ar]3d⁷4s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 28, symbol: 'Ni', name: 'Nickel', nameKorean: '니켈', atomicMass: 58.69, electronConfig: '[Ar]3d⁸4s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 29, symbol: 'Cu', name: 'Copper', nameKorean: '구리', atomicMass: 63.55, electronConfig: '[Ar]3d¹⁰4s¹', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 30, symbol: 'Zn', name: 'Zinc', nameKorean: '아연', atomicMass: 65.38, electronConfig: '[Ar]3d¹⁰4s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 31, symbol: 'Ga', name: 'Gallium', nameKorean: '갈륨', atomicMass: 69.72, electronConfig: '[Ar]3d¹⁰4s²4p¹', category: 'post-transition', categoryName: '전이후금속', color: Color(0xFFB8B8D1)),
  Element(atomicNumber: 32, symbol: 'Ge', name: 'Germanium', nameKorean: '저마늄', atomicMass: 72.63, electronConfig: '[Ar]3d¹⁰4s²4p²', category: 'metalloid', categoryName: '준금속', color: Color(0xFFA8E6CF)),
  Element(atomicNumber: 33, symbol: 'As', name: 'Arsenic', nameKorean: '비소', atomicMass: 74.92, electronConfig: '[Ar]3d¹⁰4s²4p³', category: 'metalloid', categoryName: '준금속', color: Color(0xFFA8E6CF)),
  Element(atomicNumber: 34, symbol: 'Se', name: 'Selenium', nameKorean: '셀레늄', atomicMass: 78.97, electronConfig: '[Ar]3d¹⁰4s²4p⁴', category: 'nonmetal', categoryName: '비금속', color: Color(0xFF95E1D3)),
  Element(atomicNumber: 35, symbol: 'Br', name: 'Bromine', nameKorean: '브로민', atomicMass: 79.90, electronConfig: '[Ar]3d¹⁰4s²4p⁵', category: 'halogen', categoryName: '할로겐', color: Color(0xFF4ECDC4)),
  Element(atomicNumber: 36, symbol: 'Kr', name: 'Krypton', nameKorean: '크립톤', atomicMass: 83.80, electronConfig: '[Ar]3d¹⁰4s²4p⁶', category: 'noble', categoryName: '비활성기체', color: Color(0xFF95E1D3)),
  // 5주기
  Element(atomicNumber: 37, symbol: 'Rb', name: 'Rubidium', nameKorean: '루비듐', atomicMass: 85.47, electronConfig: '[Kr]5s¹', category: 'alkali', categoryName: '알칼리금속', color: Color(0xFFFF6B6B)),
  Element(atomicNumber: 38, symbol: 'Sr', name: 'Strontium', nameKorean: '스트론튬', atomicMass: 87.62, electronConfig: '[Kr]5s²', category: 'alkaline', categoryName: '알칼리토금속', color: Color(0xFFFFAA5C)),
  Element(atomicNumber: 39, symbol: 'Y', name: 'Yttrium', nameKorean: '이트륨', atomicMass: 88.91, electronConfig: '[Kr]4d¹5s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 40, symbol: 'Zr', name: 'Zirconium', nameKorean: '지르코늄', atomicMass: 91.22, electronConfig: '[Kr]4d²5s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 41, symbol: 'Nb', name: 'Niobium', nameKorean: '나이오븀', atomicMass: 92.91, electronConfig: '[Kr]4d⁴5s¹', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 42, symbol: 'Mo', name: 'Molybdenum', nameKorean: '몰리브데넘', atomicMass: 95.95, electronConfig: '[Kr]4d⁵5s¹', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 43, symbol: 'Tc', name: 'Technetium', nameKorean: '테크네튬', atomicMass: 98.00, electronConfig: '[Kr]4d⁵5s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 44, symbol: 'Ru', name: 'Ruthenium', nameKorean: '루테늄', atomicMass: 101.07, electronConfig: '[Kr]4d⁷5s¹', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 45, symbol: 'Rh', name: 'Rhodium', nameKorean: '로듐', atomicMass: 102.91, electronConfig: '[Kr]4d⁸5s¹', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 46, symbol: 'Pd', name: 'Palladium', nameKorean: '팔라듐', atomicMass: 106.42, electronConfig: '[Kr]4d¹⁰', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 47, symbol: 'Ag', name: 'Silver', nameKorean: '은', atomicMass: 107.87, electronConfig: '[Kr]4d¹⁰5s¹', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 48, symbol: 'Cd', name: 'Cadmium', nameKorean: '카드뮴', atomicMass: 112.41, electronConfig: '[Kr]4d¹⁰5s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 49, symbol: 'In', name: 'Indium', nameKorean: '인듐', atomicMass: 114.82, electronConfig: '[Kr]4d¹⁰5s²5p¹', category: 'post-transition', categoryName: '전이후금속', color: Color(0xFFB8B8D1)),
  Element(atomicNumber: 50, symbol: 'Sn', name: 'Tin', nameKorean: '주석', atomicMass: 118.71, electronConfig: '[Kr]4d¹⁰5s²5p²', category: 'post-transition', categoryName: '전이후금속', color: Color(0xFFB8B8D1)),
  Element(atomicNumber: 51, symbol: 'Sb', name: 'Antimony', nameKorean: '안티모니', atomicMass: 121.76, electronConfig: '[Kr]4d¹⁰5s²5p³', category: 'metalloid', categoryName: '준금속', color: Color(0xFFA8E6CF)),
  Element(atomicNumber: 52, symbol: 'Te', name: 'Tellurium', nameKorean: '텔루륨', atomicMass: 127.60, electronConfig: '[Kr]4d¹⁰5s²5p⁴', category: 'metalloid', categoryName: '준금속', color: Color(0xFFA8E6CF)),
  Element(atomicNumber: 53, symbol: 'I', name: 'Iodine', nameKorean: '아이오딘', atomicMass: 126.90, electronConfig: '[Kr]4d¹⁰5s²5p⁵', category: 'halogen', categoryName: '할로겐', color: Color(0xFF4ECDC4)),
  Element(atomicNumber: 54, symbol: 'Xe', name: 'Xenon', nameKorean: '제논', atomicMass: 131.29, electronConfig: '[Kr]4d¹⁰5s²5p⁶', category: 'noble', categoryName: '비활성기체', color: Color(0xFF95E1D3)),
  // 6주기 (일부)
  Element(atomicNumber: 55, symbol: 'Cs', name: 'Cesium', nameKorean: '세슘', atomicMass: 132.91, electronConfig: '[Xe]6s¹', category: 'alkali', categoryName: '알칼리금속', color: Color(0xFFFF6B6B)),
  Element(atomicNumber: 56, symbol: 'Ba', name: 'Barium', nameKorean: '바륨', atomicMass: 137.33, electronConfig: '[Xe]6s²', category: 'alkaline', categoryName: '알칼리토금속', color: Color(0xFFFFAA5C)),
  // 전이금속 (6주기)
  Element(atomicNumber: 72, symbol: 'Hf', name: 'Hafnium', nameKorean: '하프늄', atomicMass: 178.49, electronConfig: '[Xe]4f¹⁴5d²6s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 73, symbol: 'Ta', name: 'Tantalum', nameKorean: '탄탈럼', atomicMass: 180.95, electronConfig: '[Xe]4f¹⁴5d³6s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 74, symbol: 'W', name: 'Tungsten', nameKorean: '텅스텐', atomicMass: 183.84, electronConfig: '[Xe]4f¹⁴5d⁴6s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 75, symbol: 'Re', name: 'Rhenium', nameKorean: '레늄', atomicMass: 186.21, electronConfig: '[Xe]4f¹⁴5d⁵6s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 76, symbol: 'Os', name: 'Osmium', nameKorean: '오스뮴', atomicMass: 190.23, electronConfig: '[Xe]4f¹⁴5d⁶6s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 77, symbol: 'Ir', name: 'Iridium', nameKorean: '이리듐', atomicMass: 192.22, electronConfig: '[Xe]4f¹⁴5d⁷6s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 78, symbol: 'Pt', name: 'Platinum', nameKorean: '백금', atomicMass: 195.08, electronConfig: '[Xe]4f¹⁴5d⁹6s¹', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 79, symbol: 'Au', name: 'Gold', nameKorean: '금', atomicMass: 196.97, electronConfig: '[Xe]4f¹⁴5d¹⁰6s¹', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 80, symbol: 'Hg', name: 'Mercury', nameKorean: '수은', atomicMass: 200.59, electronConfig: '[Xe]4f¹⁴5d¹⁰6s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 81, symbol: 'Tl', name: 'Thallium', nameKorean: '탈륨', atomicMass: 204.38, electronConfig: '[Xe]4f¹⁴5d¹⁰6s²6p¹', category: 'post-transition', categoryName: '전이후금속', color: Color(0xFFB8B8D1)),
  Element(atomicNumber: 82, symbol: 'Pb', name: 'Lead', nameKorean: '납', atomicMass: 207.20, electronConfig: '[Xe]4f¹⁴5d¹⁰6s²6p²', category: 'post-transition', categoryName: '전이후금속', color: Color(0xFFB8B8D1)),
  Element(atomicNumber: 83, symbol: 'Bi', name: 'Bismuth', nameKorean: '비스무트', atomicMass: 208.98, electronConfig: '[Xe]4f¹⁴5d¹⁰6s²6p³', category: 'post-transition', categoryName: '전이후금속', color: Color(0xFFB8B8D1)),
  Element(atomicNumber: 84, symbol: 'Po', name: 'Polonium', nameKorean: '폴로늄', atomicMass: 209.00, electronConfig: '[Xe]4f¹⁴5d¹⁰6s²6p⁴', category: 'metalloid', categoryName: '준금속', color: Color(0xFFA8E6CF)),
  Element(atomicNumber: 85, symbol: 'At', name: 'Astatine', nameKorean: '아스타틴', atomicMass: 210.00, electronConfig: '[Xe]4f¹⁴5d¹⁰6s²6p⁵', category: 'halogen', categoryName: '할로겐', color: Color(0xFF4ECDC4)),
  Element(atomicNumber: 86, symbol: 'Rn', name: 'Radon', nameKorean: '라돈', atomicMass: 222.00, electronConfig: '[Xe]4f¹⁴5d¹⁰6s²6p⁶', category: 'noble', categoryName: '비활성기체', color: Color(0xFF95E1D3)),
  // 7주기 (일부)
  Element(atomicNumber: 87, symbol: 'Fr', name: 'Francium', nameKorean: '프랑슘', atomicMass: 223.00, electronConfig: '[Rn]7s¹', category: 'alkali', categoryName: '알칼리금속', color: Color(0xFFFF6B6B)),
  Element(atomicNumber: 88, symbol: 'Ra', name: 'Radium', nameKorean: '라듐', atomicMass: 226.00, electronConfig: '[Rn]7s²', category: 'alkaline', categoryName: '알칼리토금속', color: Color(0xFFFFAA5C)),
  // 초우라늄 원소들 (간략화)
  Element(atomicNumber: 104, symbol: 'Rf', name: 'Rutherfordium', nameKorean: '러더포듐', atomicMass: 267.00, electronConfig: '[Rn]5f¹⁴6d²7s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 105, symbol: 'Db', name: 'Dubnium', nameKorean: '더브늄', atomicMass: 268.00, electronConfig: '[Rn]5f¹⁴6d³7s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 106, symbol: 'Sg', name: 'Seaborgium', nameKorean: '시보귬', atomicMass: 269.00, electronConfig: '[Rn]5f¹⁴6d⁴7s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 107, symbol: 'Bh', name: 'Bohrium', nameKorean: '보륨', atomicMass: 270.00, electronConfig: '[Rn]5f¹⁴6d⁵7s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 108, symbol: 'Hs', name: 'Hassium', nameKorean: '하슘', atomicMass: 277.00, electronConfig: '[Rn]5f¹⁴6d⁶7s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 109, symbol: 'Mt', name: 'Meitnerium', nameKorean: '마이트너륨', atomicMass: 278.00, electronConfig: '[Rn]5f¹⁴6d⁷7s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 110, symbol: 'Ds', name: 'Darmstadtium', nameKorean: '다름슈타튬', atomicMass: 281.00, electronConfig: '[Rn]5f¹⁴6d⁸7s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 111, symbol: 'Rg', name: 'Roentgenium', nameKorean: '뢴트게늄', atomicMass: 282.00, electronConfig: '[Rn]5f¹⁴6d⁹7s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 112, symbol: 'Cn', name: 'Copernicium', nameKorean: '코페르니슘', atomicMass: 285.00, electronConfig: '[Rn]5f¹⁴6d¹⁰7s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 113, symbol: 'Nh', name: 'Nihonium', nameKorean: '니호늄', atomicMass: 286.00, electronConfig: '[Rn]5f¹⁴6d¹⁰7s²7p¹', category: 'post-transition', categoryName: '전이후금속', color: Color(0xFFB8B8D1)),
  Element(atomicNumber: 114, symbol: 'Fl', name: 'Flerovium', nameKorean: '플레로븀', atomicMass: 289.00, electronConfig: '[Rn]5f¹⁴6d¹⁰7s²7p²', category: 'post-transition', categoryName: '전이후금속', color: Color(0xFFB8B8D1)),
  Element(atomicNumber: 115, symbol: 'Mc', name: 'Moscovium', nameKorean: '모스코븀', atomicMass: 290.00, electronConfig: '[Rn]5f¹⁴6d¹⁰7s²7p³', category: 'post-transition', categoryName: '전이후금속', color: Color(0xFFB8B8D1)),
  Element(atomicNumber: 116, symbol: 'Lv', name: 'Livermorium', nameKorean: '리버모륨', atomicMass: 293.00, electronConfig: '[Rn]5f¹⁴6d¹⁰7s²7p⁴', category: 'post-transition', categoryName: '전이후금속', color: Color(0xFFB8B8D1)),
  Element(atomicNumber: 117, symbol: 'Ts', name: 'Tennessine', nameKorean: '테네신', atomicMass: 294.00, electronConfig: '[Rn]5f¹⁴6d¹⁰7s²7p⁵', category: 'halogen', categoryName: '할로겐', color: Color(0xFF4ECDC4)),
  Element(atomicNumber: 118, symbol: 'Og', name: 'Oganesson', nameKorean: '오가네손', atomicMass: 294.00, electronConfig: '[Rn]5f¹⁴6d¹⁰7s²7p⁶', category: 'noble', categoryName: '비활성기체', color: Color(0xFF95E1D3)),
];
