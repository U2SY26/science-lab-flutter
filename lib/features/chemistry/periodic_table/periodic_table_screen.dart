import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

/// 주기율표 탐색기 - 개선된 버전
class PeriodicTableScreen extends StatefulWidget {
  const PeriodicTableScreen({super.key});

  @override
  State<PeriodicTableScreen> createState() => _PeriodicTableScreenState();
}

class _PeriodicTableScreenState extends State<PeriodicTableScreen> {
  Element? _selectedElement;
  String _filterCategory = 'all';
  String _searchQuery = '';
  bool _showLegend = true;

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
        actions: [
          IconButton(
            icon: Icon(
              _showLegend ? Icons.info : Icons.info_outline,
              color: _showLegend ? AppColors.accent : AppColors.muted,
            ),
            onPressed: () => setState(() => _showLegend = !_showLegend),
            tooltip: '범례 보기',
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색바
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: AppColors.ink, fontSize: 14),
              decoration: InputDecoration(
                hintText: '원소 검색 (기호, 이름, 원자번호)',
                hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppColors.muted, size: 20),
                filled: true,
                fillColor: AppColors.card,
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 카테고리 필터
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(label: '전체', isSelected: _filterCategory == 'all', onTap: () => setState(() => _filterCategory = 'all')),
                _FilterChip(label: '알칼리', isSelected: _filterCategory == 'alkali', color: _categoryColors['alkali']!, onTap: () => setState(() => _filterCategory = 'alkali')),
                _FilterChip(label: '알칼리토', isSelected: _filterCategory == 'alkaline', color: _categoryColors['alkaline']!, onTap: () => setState(() => _filterCategory = 'alkaline')),
                _FilterChip(label: '전이금속', isSelected: _filterCategory == 'transition', color: _categoryColors['transition']!, onTap: () => setState(() => _filterCategory = 'transition')),
                _FilterChip(label: '전이후금속', isSelected: _filterCategory == 'post-transition', color: _categoryColors['post-transition']!, onTap: () => setState(() => _filterCategory = 'post-transition')),
                _FilterChip(label: '준금속', isSelected: _filterCategory == 'metalloid', color: _categoryColors['metalloid']!, onTap: () => setState(() => _filterCategory = 'metalloid')),
                _FilterChip(label: '비금속', isSelected: _filterCategory == 'nonmetal', color: _categoryColors['nonmetal']!, onTap: () => setState(() => _filterCategory = 'nonmetal')),
                _FilterChip(label: '할로겐', isSelected: _filterCategory == 'halogen', color: _categoryColors['halogen']!, onTap: () => setState(() => _filterCategory = 'halogen')),
                _FilterChip(label: '비활성기체', isSelected: _filterCategory == 'noble', color: _categoryColors['noble']!, onTap: () => setState(() => _filterCategory = 'noble')),
                _FilterChip(label: '란타넘족', isSelected: _filterCategory == 'lanthanide', color: _categoryColors['lanthanide']!, onTap: () => setState(() => _filterCategory = 'lanthanide')),
                _FilterChip(label: '악티늄족', isSelected: _filterCategory == 'actinide', color: _categoryColors['actinide']!, onTap: () => setState(() => _filterCategory = 'actinide')),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 범례
          if (_showLegend) _buildLegend(),

          // 주기율표
          Expanded(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              boundaryMargin: const EdgeInsets.all(100),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: _buildPeriodicTable(),
              ),
            ),
          ),

          // 선택된 원소 정보
          if (_selectedElement != null)
            _ElementDetailsPanel(
              element: _selectedElement!,
              onClose: () => setState(() => _selectedElement = null),
            ),

          // 하단 여백
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '원소 분류',
            style: TextStyle(color: AppColors.ink, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: _categoryColors.entries.map((e) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: e.value,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _categoryNames[e.key] ?? e.key,
                    style: const TextStyle(color: AppColors.muted, fontSize: 10),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodicTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 18열 + 좌우 패딩 고려
        final availableWidth = constraints.maxWidth - 16;
        final cellSize = (availableWidth / 19).clamp(18.0, 32.0);
        final gap = 1.0;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 그룹 번호 (1-18)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: cellSize), // 주기 번호 자리
                  ...List.generate(18, (i) {
                    return Container(
                      width: cellSize,
                      height: 16,
                      margin: EdgeInsets.all(gap),
                      alignment: Alignment.center,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(color: AppColors.muted, fontSize: 8),
                      ),
                    );
                  }),
                ],
              ),

              // 주기 1-7
              ...List.generate(7, (period) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 주기 번호
                    Container(
                      width: cellSize,
                      height: cellSize,
                      alignment: Alignment.center,
                      child: Text(
                        '${period + 1}',
                        style: const TextStyle(color: AppColors.muted, fontSize: 10),
                      ),
                    ),
                    // 원소 셀들
                    ...List.generate(18, (group) {
                      final element = _getElementAtPosition(period, group);
                      if (element == null) {
                        // 빈 셀 또는 란타넘/악티늄 표시
                        if (period == 5 && group == 2) {
                          return _buildSpecialCell(cellSize, gap, '57-71', _categoryColors['lanthanide']!);
                        } else if (period == 6 && group == 2) {
                          return _buildSpecialCell(cellSize, gap, '89-103', _categoryColors['actinide']!);
                        }
                        return SizedBox(width: cellSize + gap * 2, height: cellSize + gap * 2);
                      }
                      return _buildElementCell(element, cellSize, gap);
                    }),
                  ],
                );
              }),

              const SizedBox(height: 8),

              // 란타넘족 (57-71)
              _buildLanthanideActinideRow('란타넘족', 57, 71, cellSize, gap),

              // 악티늄족 (89-103)
              _buildLanthanideActinideRow('악티늄족', 89, 103, cellSize, gap),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpecialCell(double size, double gap, String label, Color color) {
    return Container(
      width: size,
      height: size,
      margin: EdgeInsets.all(gap),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(color: color, fontSize: 6, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildLanthanideActinideRow(String label, int start, int end, double cellSize, double gap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: cellSize * 2 + gap * 4,
            height: cellSize,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 8),
            ),
          ),
          ...List.generate(end - start + 1, (i) {
            final atomicNumber = start + i;
            final element = _elements.firstWhere(
              (e) => e.atomicNumber == atomicNumber,
              orElse: () => _elements[0],
            );
            if (element.atomicNumber != atomicNumber) {
              return SizedBox(width: cellSize + gap * 2, height: cellSize + gap * 2);
            }
            return _buildElementCell(element, cellSize, gap);
          }),
        ],
      ),
    );
  }

  Widget _buildElementCell(Element element, double size, double gap) {
    final isFiltered = _filterCategory == 'all' || element.category == _filterCategory;
    final matchesSearch = _searchQuery.isEmpty ||
        element.symbol.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        element.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        element.nameKorean.contains(_searchQuery) ||
        element.atomicNumber.toString() == _searchQuery;

    final isHighlighted = isFiltered && matchesSearch;
    final isSelected = _selectedElement?.atomicNumber == element.atomicNumber;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedElement = element);
      },
      child: Container(
        width: size,
        height: size,
        margin: EdgeInsets.all(gap),
        decoration: BoxDecoration(
          color: isHighlighted
              ? element.color.withValues(alpha: isSelected ? 1.0 : 0.75)
              : AppColors.card.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
          border: isSelected
              ? Border.all(color: Colors.white, width: 2)
              : Border.all(color: element.color.withValues(alpha: 0.3), width: 0.5),
          boxShadow: isSelected
              ? [BoxShadow(color: element.color.withValues(alpha: 0.5), blurRadius: 4)]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${element.atomicNumber}',
              style: TextStyle(
                fontSize: size * 0.18,
                color: isHighlighted ? Colors.white70 : AppColors.muted.withValues(alpha: 0.5),
              ),
            ),
            Text(
              element.symbol,
              style: TextStyle(
                fontSize: size * 0.32,
                fontWeight: FontWeight.bold,
                color: isHighlighted ? Colors.white : AppColors.muted.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Element? _getElementAtPosition(int period, int group) {
    // 주기율표 표준 레이아웃
    final layout = [
      // 주기 1
      [1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 2],
      // 주기 2
      [3, 4, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 5, 6, 7, 8, 9, 10],
      // 주기 3
      [11, 12, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 13, 14, 15, 16, 17, 18],
      // 주기 4
      [19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36],
      // 주기 5
      [37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54],
      // 주기 6 (란타넘족은 별도 표시)
      [55, 56, -1, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86],
      // 주기 7 (악티늄족은 별도 표시)
      [87, 88, -1, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118],
    ];

    if (period >= layout.length || group >= layout[period].length) return null;
    final atomicNum = layout[period][group];
    if (atomicNum <= 0) return null;

    return _elements.firstWhere(
      (e) => e.atomicNumber == atomicNum,
      orElse: () => _elements[0],
    );
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
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? AppColors.accent).withValues(alpha: 0.25)
              : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? (color ?? AppColors.accent) : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
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

class _ElementDetailsPanel extends StatelessWidget {
  final Element element;
  final VoidCallback onClose;

  const _ElementDetailsPanel({required this.element, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: element.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: element.color.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 원소 심볼 카드
              Container(
                width: 70,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [element.color, element.color.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: element.color.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${element.atomicNumber}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    Text(
                      element.symbol,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      element.atomicMass.toStringAsFixed(element.atomicMass < 100 ? 3 : 2),
                      style: const TextStyle(color: Colors.white70, fontSize: 9),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // 원소 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
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
                                style: const TextStyle(color: AppColors.muted, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          color: AppColors.muted,
                          onPressed: onClose,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: element.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        element.categoryName,
                        style: TextStyle(
                          color: element.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 상세 정보 그리드
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.bg.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _InfoCell(label: '전자 배치', value: element.electronConfig),
                    const SizedBox(width: 12),
                    _InfoCell(label: '상태', value: element.stateAtRoom),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _InfoCell(label: '녹는점', value: element.meltingPoint != null ? '${element.meltingPoint!.toStringAsFixed(1)} K' : '-'),
                    const SizedBox(width: 12),
                    _InfoCell(label: '끓는점', value: element.boilingPoint != null ? '${element.boilingPoint!.toStringAsFixed(1)} K' : '-'),
                  ],
                ),
                if (element.electronegativity != null || element.density != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _InfoCell(label: '전기음성도', value: element.electronegativity?.toStringAsFixed(2) ?? '-'),
                      const SizedBox(width: 12),
                      _InfoCell(label: '밀도', value: element.density != null ? '${element.density} g/cm³' : '-'),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  final String label;
  final String value;

  const _InfoCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// 카테고리 색상
const Map<String, Color> _categoryColors = {
  'alkali': Color(0xFFFF6B6B),
  'alkaline': Color(0xFFFFAA5C),
  'transition': Color(0xFFFFE66D),
  'post-transition': Color(0xFFB8B8D1),
  'metalloid': Color(0xFFA8E6CF),
  'nonmetal': Color(0xFF95E1D3),
  'halogen': Color(0xFF4ECDC4),
  'noble': Color(0xFF88D8B0),
  'lanthanide': Color(0xFFFFB5E8),
  'actinide': Color(0xFFFF9CEE),
};

const Map<String, String> _categoryNames = {
  'alkali': '알칼리금속',
  'alkaline': '알칼리토금속',
  'transition': '전이금속',
  'post-transition': '전이후금속',
  'metalloid': '준금속',
  'nonmetal': '비금속',
  'halogen': '할로겐',
  'noble': '비활성기체',
  'lanthanide': '란타넘족',
  'actinide': '악티늄족',
};

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
  final double? electronegativity;
  final String? density;
  final String stateAtRoom;

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
    this.electronegativity,
    this.density,
    this.stateAtRoom = '고체',
  });
}

/// 전체 원소 데이터 (118개)
const List<Element> _elements = [
  // 주기 1
  Element(atomicNumber: 1, symbol: 'H', name: 'Hydrogen', nameKorean: '수소', atomicMass: 1.008, electronConfig: '1s¹', category: 'nonmetal', categoryName: '비금속', color: Color(0xFF95E1D3), meltingPoint: 14.01, boilingPoint: 20.28, electronegativity: 2.20, density: '0.00009', stateAtRoom: '기체'),
  Element(atomicNumber: 2, symbol: 'He', name: 'Helium', nameKorean: '헬륨', atomicMass: 4.003, electronConfig: '1s²', category: 'noble', categoryName: '비활성기체', color: Color(0xFF88D8B0), meltingPoint: 0.95, boilingPoint: 4.22, density: '0.00018', stateAtRoom: '기체'),
  // 주기 2
  Element(atomicNumber: 3, symbol: 'Li', name: 'Lithium', nameKorean: '리튬', atomicMass: 6.941, electronConfig: '[He]2s¹', category: 'alkali', categoryName: '알칼리금속', color: Color(0xFFFF6B6B), meltingPoint: 453.69, boilingPoint: 1615, electronegativity: 0.98, density: '0.534'),
  Element(atomicNumber: 4, symbol: 'Be', name: 'Beryllium', nameKorean: '베릴륨', atomicMass: 9.012, electronConfig: '[He]2s²', category: 'alkaline', categoryName: '알칼리토금속', color: Color(0xFFFFAA5C), meltingPoint: 1560, boilingPoint: 2742, electronegativity: 1.57, density: '1.85'),
  Element(atomicNumber: 5, symbol: 'B', name: 'Boron', nameKorean: '붕소', atomicMass: 10.81, electronConfig: '[He]2s²2p¹', category: 'metalloid', categoryName: '준금속', color: Color(0xFFA8E6CF), meltingPoint: 2349, boilingPoint: 4200, electronegativity: 2.04, density: '2.34'),
  Element(atomicNumber: 6, symbol: 'C', name: 'Carbon', nameKorean: '탄소', atomicMass: 12.01, electronConfig: '[He]2s²2p²', category: 'nonmetal', categoryName: '비금속', color: Color(0xFF95E1D3), meltingPoint: 3823, boilingPoint: 4098, electronegativity: 2.55, density: '2.267'),
  Element(atomicNumber: 7, symbol: 'N', name: 'Nitrogen', nameKorean: '질소', atomicMass: 14.01, electronConfig: '[He]2s²2p³', category: 'nonmetal', categoryName: '비금속', color: Color(0xFF95E1D3), meltingPoint: 63.15, boilingPoint: 77.36, electronegativity: 3.04, density: '0.00125', stateAtRoom: '기체'),
  Element(atomicNumber: 8, symbol: 'O', name: 'Oxygen', nameKorean: '산소', atomicMass: 16.00, electronConfig: '[He]2s²2p⁴', category: 'nonmetal', categoryName: '비금속', color: Color(0xFF95E1D3), meltingPoint: 54.36, boilingPoint: 90.20, electronegativity: 3.44, density: '0.00143', stateAtRoom: '기체'),
  Element(atomicNumber: 9, symbol: 'F', name: 'Fluorine', nameKorean: '플루오린', atomicMass: 19.00, electronConfig: '[He]2s²2p⁵', category: 'halogen', categoryName: '할로겐', color: Color(0xFF4ECDC4), meltingPoint: 53.53, boilingPoint: 85.03, electronegativity: 3.98, density: '0.0017', stateAtRoom: '기체'),
  Element(atomicNumber: 10, symbol: 'Ne', name: 'Neon', nameKorean: '네온', atomicMass: 20.18, electronConfig: '[He]2s²2p⁶', category: 'noble', categoryName: '비활성기체', color: Color(0xFF88D8B0), meltingPoint: 24.56, boilingPoint: 27.07, density: '0.0009', stateAtRoom: '기체'),
  // 주기 3
  Element(atomicNumber: 11, symbol: 'Na', name: 'Sodium', nameKorean: '나트륨', atomicMass: 22.99, electronConfig: '[Ne]3s¹', category: 'alkali', categoryName: '알칼리금속', color: Color(0xFFFF6B6B), meltingPoint: 370.87, boilingPoint: 1156, electronegativity: 0.93, density: '0.971'),
  Element(atomicNumber: 12, symbol: 'Mg', name: 'Magnesium', nameKorean: '마그네슘', atomicMass: 24.31, electronConfig: '[Ne]3s²', category: 'alkaline', categoryName: '알칼리토금속', color: Color(0xFFFFAA5C), meltingPoint: 923, boilingPoint: 1363, electronegativity: 1.31, density: '1.738'),
  Element(atomicNumber: 13, symbol: 'Al', name: 'Aluminum', nameKorean: '알루미늄', atomicMass: 26.98, electronConfig: '[Ne]3s²3p¹', category: 'post-transition', categoryName: '전이후금속', color: Color(0xFFB8B8D1), meltingPoint: 933.47, boilingPoint: 2792, electronegativity: 1.61, density: '2.698'),
  Element(atomicNumber: 14, symbol: 'Si', name: 'Silicon', nameKorean: '규소', atomicMass: 28.09, electronConfig: '[Ne]3s²3p²', category: 'metalloid', categoryName: '준금속', color: Color(0xFFA8E6CF), meltingPoint: 1687, boilingPoint: 3538, electronegativity: 1.90, density: '2.3296'),
  Element(atomicNumber: 15, symbol: 'P', name: 'Phosphorus', nameKorean: '인', atomicMass: 30.97, electronConfig: '[Ne]3s²3p³', category: 'nonmetal', categoryName: '비금속', color: Color(0xFF95E1D3), meltingPoint: 317.30, boilingPoint: 550, electronegativity: 2.19, density: '1.82'),
  Element(atomicNumber: 16, symbol: 'S', name: 'Sulfur', nameKorean: '황', atomicMass: 32.07, electronConfig: '[Ne]3s²3p⁴', category: 'nonmetal', categoryName: '비금속', color: Color(0xFF95E1D3), meltingPoint: 388.36, boilingPoint: 717.87, electronegativity: 2.58, density: '2.067'),
  Element(atomicNumber: 17, symbol: 'Cl', name: 'Chlorine', nameKorean: '염소', atomicMass: 35.45, electronConfig: '[Ne]3s²3p⁵', category: 'halogen', categoryName: '할로겐', color: Color(0xFF4ECDC4), meltingPoint: 171.6, boilingPoint: 239.11, electronegativity: 3.16, density: '0.00321', stateAtRoom: '기체'),
  Element(atomicNumber: 18, symbol: 'Ar', name: 'Argon', nameKorean: '아르곤', atomicMass: 39.95, electronConfig: '[Ne]3s²3p⁶', category: 'noble', categoryName: '비활성기체', color: Color(0xFF88D8B0), meltingPoint: 83.80, boilingPoint: 87.30, density: '0.00178', stateAtRoom: '기체'),
  // 주기 4
  Element(atomicNumber: 19, symbol: 'K', name: 'Potassium', nameKorean: '칼륨', atomicMass: 39.10, electronConfig: '[Ar]4s¹', category: 'alkali', categoryName: '알칼리금속', color: Color(0xFFFF6B6B), meltingPoint: 336.53, boilingPoint: 1032, electronegativity: 0.82, density: '0.862'),
  Element(atomicNumber: 20, symbol: 'Ca', name: 'Calcium', nameKorean: '칼슘', atomicMass: 40.08, electronConfig: '[Ar]4s²', category: 'alkaline', categoryName: '알칼리토금속', color: Color(0xFFFFAA5C), meltingPoint: 1115, boilingPoint: 1757, electronegativity: 1.00, density: '1.54'),
  Element(atomicNumber: 21, symbol: 'Sc', name: 'Scandium', nameKorean: '스칸듐', atomicMass: 44.96, electronConfig: '[Ar]3d¹4s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D), meltingPoint: 1814, boilingPoint: 3109, electronegativity: 1.36, density: '2.989'),
  Element(atomicNumber: 22, symbol: 'Ti', name: 'Titanium', nameKorean: '타이타늄', atomicMass: 47.87, electronConfig: '[Ar]3d²4s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D), meltingPoint: 1941, boilingPoint: 3560, electronegativity: 1.54, density: '4.54'),
  Element(atomicNumber: 23, symbol: 'V', name: 'Vanadium', nameKorean: '바나듐', atomicMass: 50.94, electronConfig: '[Ar]3d³4s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D), meltingPoint: 2183, boilingPoint: 3680, electronegativity: 1.63, density: '6.11'),
  Element(atomicNumber: 24, symbol: 'Cr', name: 'Chromium', nameKorean: '크로뮴', atomicMass: 52.00, electronConfig: '[Ar]3d⁵4s¹', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D), meltingPoint: 2180, boilingPoint: 2944, electronegativity: 1.66, density: '7.15'),
  Element(atomicNumber: 25, symbol: 'Mn', name: 'Manganese', nameKorean: '망가니즈', atomicMass: 54.94, electronConfig: '[Ar]3d⁵4s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D), meltingPoint: 1519, boilingPoint: 2334, electronegativity: 1.55, density: '7.44'),
  Element(atomicNumber: 26, symbol: 'Fe', name: 'Iron', nameKorean: '철', atomicMass: 55.85, electronConfig: '[Ar]3d⁶4s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D), meltingPoint: 1811, boilingPoint: 3134, electronegativity: 1.83, density: '7.874'),
  Element(atomicNumber: 27, symbol: 'Co', name: 'Cobalt', nameKorean: '코발트', atomicMass: 58.93, electronConfig: '[Ar]3d⁷4s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D), meltingPoint: 1768, boilingPoint: 3200, electronegativity: 1.88, density: '8.86'),
  Element(atomicNumber: 28, symbol: 'Ni', name: 'Nickel', nameKorean: '니켈', atomicMass: 58.69, electronConfig: '[Ar]3d⁸4s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D), meltingPoint: 1728, boilingPoint: 3186, electronegativity: 1.91, density: '8.912'),
  Element(atomicNumber: 29, symbol: 'Cu', name: 'Copper', nameKorean: '구리', atomicMass: 63.55, electronConfig: '[Ar]3d¹⁰4s¹', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D), meltingPoint: 1357.77, boilingPoint: 2835, electronegativity: 1.90, density: '8.96'),
  Element(atomicNumber: 30, symbol: 'Zn', name: 'Zinc', nameKorean: '아연', atomicMass: 65.38, electronConfig: '[Ar]3d¹⁰4s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D), meltingPoint: 692.88, boilingPoint: 1180, electronegativity: 1.65, density: '7.134'),
  Element(atomicNumber: 31, symbol: 'Ga', name: 'Gallium', nameKorean: '갈륨', atomicMass: 69.72, electronConfig: '[Ar]3d¹⁰4s²4p¹', category: 'post-transition', categoryName: '전이후금속', color: Color(0xFFB8B8D1), meltingPoint: 302.91, boilingPoint: 2477, electronegativity: 1.81, density: '5.907'),
  Element(atomicNumber: 32, symbol: 'Ge', name: 'Germanium', nameKorean: '저마늄', atomicMass: 72.63, electronConfig: '[Ar]3d¹⁰4s²4p²', category: 'metalloid', categoryName: '준금속', color: Color(0xFFA8E6CF), meltingPoint: 1211.40, boilingPoint: 3106, electronegativity: 2.01, density: '5.323'),
  Element(atomicNumber: 33, symbol: 'As', name: 'Arsenic', nameKorean: '비소', atomicMass: 74.92, electronConfig: '[Ar]3d¹⁰4s²4p³', category: 'metalloid', categoryName: '준금속', color: Color(0xFFA8E6CF), meltingPoint: 1090, boilingPoint: 887, electronegativity: 2.18, density: '5.776'),
  Element(atomicNumber: 34, symbol: 'Se', name: 'Selenium', nameKorean: '셀레늄', atomicMass: 78.97, electronConfig: '[Ar]3d¹⁰4s²4p⁴', category: 'nonmetal', categoryName: '비금속', color: Color(0xFF95E1D3), meltingPoint: 494, boilingPoint: 958, electronegativity: 2.55, density: '4.809'),
  Element(atomicNumber: 35, symbol: 'Br', name: 'Bromine', nameKorean: '브로민', atomicMass: 79.90, electronConfig: '[Ar]3d¹⁰4s²4p⁵', category: 'halogen', categoryName: '할로겐', color: Color(0xFF4ECDC4), meltingPoint: 265.8, boilingPoint: 332, electronegativity: 2.96, density: '3.122', stateAtRoom: '액체'),
  Element(atomicNumber: 36, symbol: 'Kr', name: 'Krypton', nameKorean: '크립톤', atomicMass: 83.80, electronConfig: '[Ar]3d¹⁰4s²4p⁶', category: 'noble', categoryName: '비활성기체', color: Color(0xFF88D8B0), meltingPoint: 115.79, boilingPoint: 119.93, density: '0.00375', stateAtRoom: '기체'),
  // 주기 5
  Element(atomicNumber: 37, symbol: 'Rb', name: 'Rubidium', nameKorean: '루비듐', atomicMass: 85.47, electronConfig: '[Kr]5s¹', category: 'alkali', categoryName: '알칼리금속', color: Color(0xFFFF6B6B), meltingPoint: 312.46, boilingPoint: 961, electronegativity: 0.82, density: '1.532'),
  Element(atomicNumber: 38, symbol: 'Sr', name: 'Strontium', nameKorean: '스트론튬', atomicMass: 87.62, electronConfig: '[Kr]5s²', category: 'alkaline', categoryName: '알칼리토금속', color: Color(0xFFFFAA5C), meltingPoint: 1050, boilingPoint: 1655, electronegativity: 0.95, density: '2.64'),
  Element(atomicNumber: 39, symbol: 'Y', name: 'Yttrium', nameKorean: '이트륨', atomicMass: 88.91, electronConfig: '[Kr]4d¹5s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D), meltingPoint: 1799, boilingPoint: 3609, electronegativity: 1.22, density: '4.469'),
  Element(atomicNumber: 40, symbol: 'Zr', name: 'Zirconium', nameKorean: '지르코늄', atomicMass: 91.22, electronConfig: '[Kr]4d²5s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D), meltingPoint: 2128, boilingPoint: 4682, electronegativity: 1.33, density: '6.506'),
  Element(atomicNumber: 41, symbol: 'Nb', name: 'Niobium', nameKorean: '나이오븀', atomicMass: 92.91, electronConfig: '[Kr]4d⁴5s¹', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D), meltingPoint: 2750, boilingPoint: 5017, electronegativity: 1.6, density: '8.57'),
  Element(atomicNumber: 42, symbol: 'Mo', name: 'Molybdenum', nameKorean: '몰리브데넘', atomicMass: 95.95, electronConfig: '[Kr]4d⁵5s¹', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D), meltingPoint: 2896, boilingPoint: 4912, electronegativity: 2.16, density: '10.22'),
  Element(atomicNumber: 43, symbol: 'Tc', name: 'Technetium', nameKorean: '테크네튬', atomicMass: 98.00, electronConfig: '[Kr]4d⁵5s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D), meltingPoint: 2430, boilingPoint: 4538, electronegativity: 1.9, density: '11.5'),
  Element(atomicNumber: 44, symbol: 'Ru', name: 'Ruthenium', nameKorean: '루테늄', atomicMass: 101.07, electronConfig: '[Kr]4d⁷5s¹', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D), meltingPoint: 2607, boilingPoint: 4423, electronegativity: 2.2, density: '12.37'),
  Element(atomicNumber: 45, symbol: 'Rh', name: 'Rhodium', nameKorean: '로듐', atomicMass: 102.91, electronConfig: '[Kr]4d⁸5s¹', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D), meltingPoint: 2237, boilingPoint: 3968, electronegativity: 2.28, density: '12.41'),
  Element(atomicNumber: 46, symbol: 'Pd', name: 'Palladium', nameKorean: '팔라듐', atomicMass: 106.42, electronConfig: '[Kr]4d¹⁰', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D), meltingPoint: 1828.05, boilingPoint: 3236, electronegativity: 2.20, density: '12.02'),
  Element(atomicNumber: 47, symbol: 'Ag', name: 'Silver', nameKorean: '은', atomicMass: 107.87, electronConfig: '[Kr]4d¹⁰5s¹', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D), meltingPoint: 1234.93, boilingPoint: 2435, electronegativity: 1.93, density: '10.501'),
  Element(atomicNumber: 48, symbol: 'Cd', name: 'Cadmium', nameKorean: '카드뮴', atomicMass: 112.41, electronConfig: '[Kr]4d¹⁰5s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D), meltingPoint: 594.22, boilingPoint: 1040, electronegativity: 1.69, density: '8.69'),
  Element(atomicNumber: 49, symbol: 'In', name: 'Indium', nameKorean: '인듐', atomicMass: 114.82, electronConfig: '[Kr]4d¹⁰5s²5p¹', category: 'post-transition', categoryName: '전이후금속', color: Color(0xFFB8B8D1), meltingPoint: 429.75, boilingPoint: 2345, electronegativity: 1.78, density: '7.31'),
  Element(atomicNumber: 50, symbol: 'Sn', name: 'Tin', nameKorean: '주석', atomicMass: 118.71, electronConfig: '[Kr]4d¹⁰5s²5p²', category: 'post-transition', categoryName: '전이후금속', color: Color(0xFFB8B8D1), meltingPoint: 505.08, boilingPoint: 2875, electronegativity: 1.96, density: '7.287'),
  Element(atomicNumber: 51, symbol: 'Sb', name: 'Antimony', nameKorean: '안티모니', atomicMass: 121.76, electronConfig: '[Kr]4d¹⁰5s²5p³', category: 'metalloid', categoryName: '준금속', color: Color(0xFFA8E6CF), meltingPoint: 903.78, boilingPoint: 1860, electronegativity: 2.05, density: '6.685'),
  Element(atomicNumber: 52, symbol: 'Te', name: 'Tellurium', nameKorean: '텔루륨', atomicMass: 127.60, electronConfig: '[Kr]4d¹⁰5s²5p⁴', category: 'metalloid', categoryName: '준금속', color: Color(0xFFA8E6CF), meltingPoint: 722.66, boilingPoint: 1261, electronegativity: 2.1, density: '6.232'),
  Element(atomicNumber: 53, symbol: 'I', name: 'Iodine', nameKorean: '아이오딘', atomicMass: 126.90, electronConfig: '[Kr]4d¹⁰5s²5p⁵', category: 'halogen', categoryName: '할로겐', color: Color(0xFF4ECDC4), meltingPoint: 386.85, boilingPoint: 457.4, electronegativity: 2.66, density: '4.93'),
  Element(atomicNumber: 54, symbol: 'Xe', name: 'Xenon', nameKorean: '제논', atomicMass: 131.29, electronConfig: '[Kr]4d¹⁰5s²5p⁶', category: 'noble', categoryName: '비활성기체', color: Color(0xFF88D8B0), meltingPoint: 161.4, boilingPoint: 165.03, density: '0.00589', stateAtRoom: '기체'),
  // 주기 6
  Element(atomicNumber: 55, symbol: 'Cs', name: 'Cesium', nameKorean: '세슘', atomicMass: 132.91, electronConfig: '[Xe]6s¹', category: 'alkali', categoryName: '알칼리금속', color: Color(0xFFFF6B6B), meltingPoint: 301.59, boilingPoint: 944, electronegativity: 0.79, density: '1.873'),
  Element(atomicNumber: 56, symbol: 'Ba', name: 'Barium', nameKorean: '바륨', atomicMass: 137.33, electronConfig: '[Xe]6s²', category: 'alkaline', categoryName: '알칼리토금속', color: Color(0xFFFFAA5C), meltingPoint: 1000, boilingPoint: 2170, electronegativity: 0.89, density: '3.594'),
  // 란타넘족 (57-71)
  Element(atomicNumber: 57, symbol: 'La', name: 'Lanthanum', nameKorean: '란타넘', atomicMass: 138.91, electronConfig: '[Xe]5d¹6s²', category: 'lanthanide', categoryName: '란타넘족', color: Color(0xFFFFB5E8), meltingPoint: 1193, boilingPoint: 3737, electronegativity: 1.10, density: '6.145'),
  Element(atomicNumber: 58, symbol: 'Ce', name: 'Cerium', nameKorean: '세륨', atomicMass: 140.12, electronConfig: '[Xe]4f¹5d¹6s²', category: 'lanthanide', categoryName: '란타넘족', color: Color(0xFFFFB5E8), meltingPoint: 1068, boilingPoint: 3716, electronegativity: 1.12, density: '6.77'),
  Element(atomicNumber: 59, symbol: 'Pr', name: 'Praseodymium', nameKorean: '프라세오디뮴', atomicMass: 140.91, electronConfig: '[Xe]4f³6s²', category: 'lanthanide', categoryName: '란타넘족', color: Color(0xFFFFB5E8), meltingPoint: 1208, boilingPoint: 3793, electronegativity: 1.13, density: '6.773'),
  Element(atomicNumber: 60, symbol: 'Nd', name: 'Neodymium', nameKorean: '네오디뮴', atomicMass: 144.24, electronConfig: '[Xe]4f⁴6s²', category: 'lanthanide', categoryName: '란타넘족', color: Color(0xFFFFB5E8), meltingPoint: 1297, boilingPoint: 3347, electronegativity: 1.14, density: '7.007'),
  Element(atomicNumber: 61, symbol: 'Pm', name: 'Promethium', nameKorean: '프로메튬', atomicMass: 145.00, electronConfig: '[Xe]4f⁵6s²', category: 'lanthanide', categoryName: '란타넘족', color: Color(0xFFFFB5E8), meltingPoint: 1315, boilingPoint: 3273, density: '7.26'),
  Element(atomicNumber: 62, symbol: 'Sm', name: 'Samarium', nameKorean: '사마륨', atomicMass: 150.36, electronConfig: '[Xe]4f⁶6s²', category: 'lanthanide', categoryName: '란타넘족', color: Color(0xFFFFB5E8), meltingPoint: 1345, boilingPoint: 2067, electronegativity: 1.17, density: '7.52'),
  Element(atomicNumber: 63, symbol: 'Eu', name: 'Europium', nameKorean: '유로퓸', atomicMass: 151.96, electronConfig: '[Xe]4f⁷6s²', category: 'lanthanide', categoryName: '란타넘족', color: Color(0xFFFFB5E8), meltingPoint: 1099, boilingPoint: 1802, density: '5.243'),
  Element(atomicNumber: 64, symbol: 'Gd', name: 'Gadolinium', nameKorean: '가돌리늄', atomicMass: 157.25, electronConfig: '[Xe]4f⁷5d¹6s²', category: 'lanthanide', categoryName: '란타넘족', color: Color(0xFFFFB5E8), meltingPoint: 1585, boilingPoint: 3546, electronegativity: 1.20, density: '7.895'),
  Element(atomicNumber: 65, symbol: 'Tb', name: 'Terbium', nameKorean: '터븀', atomicMass: 158.93, electronConfig: '[Xe]4f⁹6s²', category: 'lanthanide', categoryName: '란타넘족', color: Color(0xFFFFB5E8), meltingPoint: 1629, boilingPoint: 3503, density: '8.229'),
  Element(atomicNumber: 66, symbol: 'Dy', name: 'Dysprosium', nameKorean: '디스프로슘', atomicMass: 162.50, electronConfig: '[Xe]4f¹⁰6s²', category: 'lanthanide', categoryName: '란타넘족', color: Color(0xFFFFB5E8), meltingPoint: 1680, boilingPoint: 2840, electronegativity: 1.22, density: '8.55'),
  Element(atomicNumber: 67, symbol: 'Ho', name: 'Holmium', nameKorean: '홀뮴', atomicMass: 164.93, electronConfig: '[Xe]4f¹¹6s²', category: 'lanthanide', categoryName: '란타넘족', color: Color(0xFFFFB5E8), meltingPoint: 1734, boilingPoint: 2993, electronegativity: 1.23, density: '8.795'),
  Element(atomicNumber: 68, symbol: 'Er', name: 'Erbium', nameKorean: '어븀', atomicMass: 167.26, electronConfig: '[Xe]4f¹²6s²', category: 'lanthanide', categoryName: '란타넘족', color: Color(0xFFFFB5E8), meltingPoint: 1802, boilingPoint: 3141, electronegativity: 1.24, density: '9.066'),
  Element(atomicNumber: 69, symbol: 'Tm', name: 'Thulium', nameKorean: '툴륨', atomicMass: 168.93, electronConfig: '[Xe]4f¹³6s²', category: 'lanthanide', categoryName: '란타넘족', color: Color(0xFFFFB5E8), meltingPoint: 1818, boilingPoint: 2223, electronegativity: 1.25, density: '9.321'),
  Element(atomicNumber: 70, symbol: 'Yb', name: 'Ytterbium', nameKorean: '이터븀', atomicMass: 173.05, electronConfig: '[Xe]4f¹⁴6s²', category: 'lanthanide', categoryName: '란타넘족', color: Color(0xFFFFB5E8), meltingPoint: 1097, boilingPoint: 1469, density: '6.965'),
  Element(atomicNumber: 71, symbol: 'Lu', name: 'Lutetium', nameKorean: '루테튬', atomicMass: 174.97, electronConfig: '[Xe]4f¹⁴5d¹6s²', category: 'lanthanide', categoryName: '란타넘족', color: Color(0xFFFFB5E8), meltingPoint: 1925, boilingPoint: 3675, electronegativity: 1.27, density: '9.84'),
  // 전이금속 (72-80)
  Element(atomicNumber: 72, symbol: 'Hf', name: 'Hafnium', nameKorean: '하프늄', atomicMass: 178.49, electronConfig: '[Xe]4f¹⁴5d²6s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D), meltingPoint: 2506, boilingPoint: 4876, electronegativity: 1.3, density: '13.31'),
  Element(atomicNumber: 73, symbol: 'Ta', name: 'Tantalum', nameKorean: '탄탈럼', atomicMass: 180.95, electronConfig: '[Xe]4f¹⁴5d³6s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D), meltingPoint: 3290, boilingPoint: 5731, electronegativity: 1.5, density: '16.654'),
  Element(atomicNumber: 74, symbol: 'W', name: 'Tungsten', nameKorean: '텅스텐', atomicMass: 183.84, electronConfig: '[Xe]4f¹⁴5d⁴6s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D), meltingPoint: 3695, boilingPoint: 5828, electronegativity: 2.36, density: '19.25'),
  Element(atomicNumber: 75, symbol: 'Re', name: 'Rhenium', nameKorean: '레늄', atomicMass: 186.21, electronConfig: '[Xe]4f¹⁴5d⁵6s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D), meltingPoint: 3459, boilingPoint: 5869, electronegativity: 1.9, density: '21.02'),
  Element(atomicNumber: 76, symbol: 'Os', name: 'Osmium', nameKorean: '오스뮴', atomicMass: 190.23, electronConfig: '[Xe]4f¹⁴5d⁶6s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D), meltingPoint: 3306, boilingPoint: 5285, electronegativity: 2.2, density: '22.59'),
  Element(atomicNumber: 77, symbol: 'Ir', name: 'Iridium', nameKorean: '이리듐', atomicMass: 192.22, electronConfig: '[Xe]4f¹⁴5d⁷6s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D), meltingPoint: 2719, boilingPoint: 4701, electronegativity: 2.20, density: '22.56'),
  Element(atomicNumber: 78, symbol: 'Pt', name: 'Platinum', nameKorean: '백금', atomicMass: 195.08, electronConfig: '[Xe]4f¹⁴5d⁹6s¹', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D), meltingPoint: 2041.4, boilingPoint: 4098, electronegativity: 2.28, density: '21.46'),
  Element(atomicNumber: 79, symbol: 'Au', name: 'Gold', nameKorean: '금', atomicMass: 196.97, electronConfig: '[Xe]4f¹⁴5d¹⁰6s¹', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D), meltingPoint: 1337.33, boilingPoint: 3129, electronegativity: 2.54, density: '19.282'),
  Element(atomicNumber: 80, symbol: 'Hg', name: 'Mercury', nameKorean: '수은', atomicMass: 200.59, electronConfig: '[Xe]4f¹⁴5d¹⁰6s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D), meltingPoint: 234.43, boilingPoint: 629.88, electronegativity: 2.00, density: '13.5336', stateAtRoom: '액체'),
  // 전이후금속 (81-84)
  Element(atomicNumber: 81, symbol: 'Tl', name: 'Thallium', nameKorean: '탈륨', atomicMass: 204.38, electronConfig: '[Xe]4f¹⁴5d¹⁰6s²6p¹', category: 'post-transition', categoryName: '전이후금속', color: Color(0xFFB8B8D1), meltingPoint: 577, boilingPoint: 1746, electronegativity: 1.62, density: '11.85'),
  Element(atomicNumber: 82, symbol: 'Pb', name: 'Lead', nameKorean: '납', atomicMass: 207.20, electronConfig: '[Xe]4f¹⁴5d¹⁰6s²6p²', category: 'post-transition', categoryName: '전이후금속', color: Color(0xFFB8B8D1), meltingPoint: 600.61, boilingPoint: 2022, electronegativity: 2.33, density: '11.342'),
  Element(atomicNumber: 83, symbol: 'Bi', name: 'Bismuth', nameKorean: '비스무트', atomicMass: 208.98, electronConfig: '[Xe]4f¹⁴5d¹⁰6s²6p³', category: 'post-transition', categoryName: '전이후금속', color: Color(0xFFB8B8D1), meltingPoint: 544.7, boilingPoint: 1837, electronegativity: 2.02, density: '9.807'),
  Element(atomicNumber: 84, symbol: 'Po', name: 'Polonium', nameKorean: '폴로늄', atomicMass: 209.00, electronConfig: '[Xe]4f¹⁴5d¹⁰6s²6p⁴', category: 'metalloid', categoryName: '준금속', color: Color(0xFFA8E6CF), meltingPoint: 527, boilingPoint: 1235, electronegativity: 2.0, density: '9.32'),
  Element(atomicNumber: 85, symbol: 'At', name: 'Astatine', nameKorean: '아스타틴', atomicMass: 210.00, electronConfig: '[Xe]4f¹⁴5d¹⁰6s²6p⁵', category: 'halogen', categoryName: '할로겐', color: Color(0xFF4ECDC4), meltingPoint: 575, boilingPoint: 610, electronegativity: 2.2, density: '7'),
  Element(atomicNumber: 86, symbol: 'Rn', name: 'Radon', nameKorean: '라돈', atomicMass: 222.00, electronConfig: '[Xe]4f¹⁴5d¹⁰6s²6p⁶', category: 'noble', categoryName: '비활성기체', color: Color(0xFF88D8B0), meltingPoint: 202, boilingPoint: 211.3, density: '0.00973', stateAtRoom: '기체'),
  // 주기 7
  Element(atomicNumber: 87, symbol: 'Fr', name: 'Francium', nameKorean: '프랑슘', atomicMass: 223.00, electronConfig: '[Rn]7s¹', category: 'alkali', categoryName: '알칼리금속', color: Color(0xFFFF6B6B), meltingPoint: 300, boilingPoint: 950, electronegativity: 0.7, density: '1.87'),
  Element(atomicNumber: 88, symbol: 'Ra', name: 'Radium', nameKorean: '라듐', atomicMass: 226.00, electronConfig: '[Rn]7s²', category: 'alkaline', categoryName: '알칼리토금속', color: Color(0xFFFFAA5C), meltingPoint: 973, boilingPoint: 2010, electronegativity: 0.9, density: '5.5'),
  // 악티늄족 (89-103)
  Element(atomicNumber: 89, symbol: 'Ac', name: 'Actinium', nameKorean: '악티늄', atomicMass: 227.00, electronConfig: '[Rn]6d¹7s²', category: 'actinide', categoryName: '악티늄족', color: Color(0xFFFF9CEE), meltingPoint: 1323, boilingPoint: 3471, electronegativity: 1.1, density: '10.07'),
  Element(atomicNumber: 90, symbol: 'Th', name: 'Thorium', nameKorean: '토륨', atomicMass: 232.04, electronConfig: '[Rn]6d²7s²', category: 'actinide', categoryName: '악티늄족', color: Color(0xFFFF9CEE), meltingPoint: 2115, boilingPoint: 5061, electronegativity: 1.3, density: '11.72'),
  Element(atomicNumber: 91, symbol: 'Pa', name: 'Protactinium', nameKorean: '프로탁티늄', atomicMass: 231.04, electronConfig: '[Rn]5f²6d¹7s²', category: 'actinide', categoryName: '악티늄족', color: Color(0xFFFF9CEE), meltingPoint: 1841, boilingPoint: 4300, electronegativity: 1.5, density: '15.37'),
  Element(atomicNumber: 92, symbol: 'U', name: 'Uranium', nameKorean: '우라늄', atomicMass: 238.03, electronConfig: '[Rn]5f³6d¹7s²', category: 'actinide', categoryName: '악티늄족', color: Color(0xFFFF9CEE), meltingPoint: 1405.3, boilingPoint: 4404, electronegativity: 1.38, density: '18.95'),
  Element(atomicNumber: 93, symbol: 'Np', name: 'Neptunium', nameKorean: '넵투늄', atomicMass: 237.00, electronConfig: '[Rn]5f⁴6d¹7s²', category: 'actinide', categoryName: '악티늄족', color: Color(0xFFFF9CEE), meltingPoint: 917, boilingPoint: 4273, electronegativity: 1.36, density: '20.25'),
  Element(atomicNumber: 94, symbol: 'Pu', name: 'Plutonium', nameKorean: '플루토늄', atomicMass: 244.00, electronConfig: '[Rn]5f⁶7s²', category: 'actinide', categoryName: '악티늄족', color: Color(0xFFFF9CEE), meltingPoint: 912.5, boilingPoint: 3501, electronegativity: 1.28, density: '19.84'),
  Element(atomicNumber: 95, symbol: 'Am', name: 'Americium', nameKorean: '아메리슘', atomicMass: 243.00, electronConfig: '[Rn]5f⁷7s²', category: 'actinide', categoryName: '악티늄족', color: Color(0xFFFF9CEE), meltingPoint: 1449, boilingPoint: 2880, electronegativity: 1.3, density: '13.69'),
  Element(atomicNumber: 96, symbol: 'Cm', name: 'Curium', nameKorean: '퀴륨', atomicMass: 247.00, electronConfig: '[Rn]5f⁷6d¹7s²', category: 'actinide', categoryName: '악티늄족', color: Color(0xFFFF9CEE), meltingPoint: 1613, boilingPoint: 3383, electronegativity: 1.3, density: '13.51'),
  Element(atomicNumber: 97, symbol: 'Bk', name: 'Berkelium', nameKorean: '버클륨', atomicMass: 247.00, electronConfig: '[Rn]5f⁹7s²', category: 'actinide', categoryName: '악티늄족', color: Color(0xFFFF9CEE), meltingPoint: 1259, boilingPoint: 2900, electronegativity: 1.3, density: '14.79'),
  Element(atomicNumber: 98, symbol: 'Cf', name: 'Californium', nameKorean: '캘리포늄', atomicMass: 251.00, electronConfig: '[Rn]5f¹⁰7s²', category: 'actinide', categoryName: '악티늄족', color: Color(0xFFFF9CEE), meltingPoint: 1173, boilingPoint: 1743, electronegativity: 1.3, density: '15.1'),
  Element(atomicNumber: 99, symbol: 'Es', name: 'Einsteinium', nameKorean: '아인슈타이늄', atomicMass: 252.00, electronConfig: '[Rn]5f¹¹7s²', category: 'actinide', categoryName: '악티늄족', color: Color(0xFFFF9CEE), meltingPoint: 1133, boilingPoint: 1269, electronegativity: 1.3, density: '8.84'),
  Element(atomicNumber: 100, symbol: 'Fm', name: 'Fermium', nameKorean: '페르뮴', atomicMass: 257.00, electronConfig: '[Rn]5f¹²7s²', category: 'actinide', categoryName: '악티늄족', color: Color(0xFFFF9CEE), meltingPoint: 1800, electronegativity: 1.3),
  Element(atomicNumber: 101, symbol: 'Md', name: 'Mendelevium', nameKorean: '멘델레븀', atomicMass: 258.00, electronConfig: '[Rn]5f¹³7s²', category: 'actinide', categoryName: '악티늄족', color: Color(0xFFFF9CEE), meltingPoint: 1100, electronegativity: 1.3),
  Element(atomicNumber: 102, symbol: 'No', name: 'Nobelium', nameKorean: '노벨륨', atomicMass: 259.00, electronConfig: '[Rn]5f¹⁴7s²', category: 'actinide', categoryName: '악티늄족', color: Color(0xFFFF9CEE), meltingPoint: 1100, electronegativity: 1.3),
  Element(atomicNumber: 103, symbol: 'Lr', name: 'Lawrencium', nameKorean: '로렌슘', atomicMass: 262.00, electronConfig: '[Rn]5f¹⁴7s²7p¹', category: 'actinide', categoryName: '악티늄족', color: Color(0xFFFF9CEE), meltingPoint: 1900, electronegativity: 1.3),
  // 전이금속 (104-112)
  Element(atomicNumber: 104, symbol: 'Rf', name: 'Rutherfordium', nameKorean: '러더포듐', atomicMass: 267.00, electronConfig: '[Rn]5f¹⁴6d²7s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 105, symbol: 'Db', name: 'Dubnium', nameKorean: '더브늄', atomicMass: 268.00, electronConfig: '[Rn]5f¹⁴6d³7s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 106, symbol: 'Sg', name: 'Seaborgium', nameKorean: '시보귬', atomicMass: 269.00, electronConfig: '[Rn]5f¹⁴6d⁴7s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 107, symbol: 'Bh', name: 'Bohrium', nameKorean: '보륨', atomicMass: 270.00, electronConfig: '[Rn]5f¹⁴6d⁵7s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 108, symbol: 'Hs', name: 'Hassium', nameKorean: '하슘', atomicMass: 277.00, electronConfig: '[Rn]5f¹⁴6d⁶7s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 109, symbol: 'Mt', name: 'Meitnerium', nameKorean: '마이트너륨', atomicMass: 278.00, electronConfig: '[Rn]5f¹⁴6d⁷7s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 110, symbol: 'Ds', name: 'Darmstadtium', nameKorean: '다름슈타튬', atomicMass: 281.00, electronConfig: '[Rn]5f¹⁴6d⁸7s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 111, symbol: 'Rg', name: 'Roentgenium', nameKorean: '뢴트게늄', atomicMass: 282.00, electronConfig: '[Rn]5f¹⁴6d⁹7s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  Element(atomicNumber: 112, symbol: 'Cn', name: 'Copernicium', nameKorean: '코페르니슘', atomicMass: 285.00, electronConfig: '[Rn]5f¹⁴6d¹⁰7s²', category: 'transition', categoryName: '전이금속', color: Color(0xFFFFE66D)),
  // 전이후금속 (113-118)
  Element(atomicNumber: 113, symbol: 'Nh', name: 'Nihonium', nameKorean: '니호늄', atomicMass: 286.00, electronConfig: '[Rn]5f¹⁴6d¹⁰7s²7p¹', category: 'post-transition', categoryName: '전이후금속', color: Color(0xFFB8B8D1)),
  Element(atomicNumber: 114, symbol: 'Fl', name: 'Flerovium', nameKorean: '플레로븀', atomicMass: 289.00, electronConfig: '[Rn]5f¹⁴6d¹⁰7s²7p²', category: 'post-transition', categoryName: '전이후금속', color: Color(0xFFB8B8D1)),
  Element(atomicNumber: 115, symbol: 'Mc', name: 'Moscovium', nameKorean: '모스코븀', atomicMass: 290.00, electronConfig: '[Rn]5f¹⁴6d¹⁰7s²7p³', category: 'post-transition', categoryName: '전이후금속', color: Color(0xFFB8B8D1)),
  Element(atomicNumber: 116, symbol: 'Lv', name: 'Livermorium', nameKorean: '리버모륨', atomicMass: 293.00, electronConfig: '[Rn]5f¹⁴6d¹⁰7s²7p⁴', category: 'post-transition', categoryName: '전이후금속', color: Color(0xFFB8B8D1)),
  Element(atomicNumber: 117, symbol: 'Ts', name: 'Tennessine', nameKorean: '테네신', atomicMass: 294.00, electronConfig: '[Rn]5f¹⁴6d¹⁰7s²7p⁵', category: 'halogen', categoryName: '할로겐', color: Color(0xFF4ECDC4)),
  Element(atomicNumber: 118, symbol: 'Og', name: 'Oganesson', nameKorean: '오가네손', atomicMass: 294.00, electronConfig: '[Rn]5f¹⁴6d¹⁰7s²7p⁶', category: 'noble', categoryName: '비활성기체', color: Color(0xFF88D8B0)),
];
