import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';

/// S-020~S-023: 개선된 슬라이더 컨트롤 위젯
class SimSlider extends StatefulWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final double? step;
  final double? defaultValue;
  final String Function(double) formatValue;
  final ValueChanged<double> onChanged;
  final bool showInput;
  final bool showReset;

  const SimSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.step,
    this.defaultValue,
    required this.formatValue,
    required this.onChanged,
    this.showInput = false,
    this.showReset = true,
  });

  @override
  State<SimSlider> createState() => _SimSliderState();
}

class _SimSliderState extends State<SimSlider> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.formatValue(widget.value));
  }

  @override
  void didUpdateWidget(SimSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && oldWidget.value != widget.value) {
      _controller.text = widget.formatValue(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleInputSubmit(String text) {
    final parsed = double.tryParse(text.replaceAll(RegExp(r'[^0-9.-]'), ''));
    if (parsed != null) {
      final clamped = parsed.clamp(widget.min, widget.max);
      widget.onChanged(clamped);
    }
    setState(() => _isEditing = false);
    _controller.text = widget.formatValue(widget.value);
  }

  void _resetToDefault() {
    if (widget.defaultValue != null) {
      widget.onChanged(widget.defaultValue!);
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasChanged = widget.defaultValue != null &&
        (widget.value - widget.defaultValue!).abs() > 0.001;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 라벨 행
        Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // S-022: 숫자 직접 입력
            if (widget.showInput)
              SizedBox(
                width: 60,
                height: 24,
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: AppColors.accent,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: AppColors.accent),
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onTap: () => setState(() => _isEditing = true),
                  onSubmitted: _handleInputSubmit,
                  onEditingComplete: () => _handleInputSubmit(_controller.text),
                ),
              )
            else
              Text(
                widget.formatValue(widget.value),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            // S-023: 개별 리셋 버튼
            if (widget.showReset && hasChanged) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: _resetToDefault,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.refresh,
                    size: 14,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        // S-020, S-021: 커스텀 슬라이더
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 6, // S-020
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 10, // S-021: 20px diameter
              elevation: 2,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            activeTrackColor: AppColors.accent,
            inactiveTrackColor: AppColors.cardBorder,
            thumbColor: AppColors.accent,
            overlayColor: AppColors.accent.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: widget.value,
            min: widget.min,
            max: widget.max,
            divisions: widget.step != null
                ? ((widget.max - widget.min) / widget.step!).round()
                : null,
            onChanged: widget.onChanged,
          ),
        ),
      ],
    );
  }
}

/// S-025~S-030: 개선된 시뮬레이션 버튼 위젯
class SimButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isActive;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const SimButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isPrimary = false,
    this.isActive = false,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        else if (icon != null)
          Icon(icon, size: 16),
        if ((icon != null || isLoading) && label.isNotEmpty)
          const SizedBox(width: 6),
        if (label.isNotEmpty)
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );

    final buttonStyle = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size(width ?? 0, 40), // S-026: 최소 높이 40px
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );

    if (isPrimary || isActive) {
      return ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle.copyWith(
          backgroundColor: WidgetStatePropertyAll(
            isDisabled
                ? AppColors.accent.withValues(alpha: 0.5)
                : AppColors.accent,
          ),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
        ),
        child: content,
      );
    }

    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: buttonStyle.copyWith(
        side: WidgetStatePropertyAll(
          BorderSide(
            color: isDisabled
                ? AppColors.cardBorder
                : AppColors.accent.withValues(alpha: 0.5),
          ),
        ),
        foregroundColor: WidgetStatePropertyAll(
          isDisabled ? AppColors.muted : AppColors.ink,
        ),
      ),
      child: content,
    );
  }
}

/// S-024: 프리셋 버튼 위젯
class PresetButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const PresetButton({
    super.key,
    required this.label,
    this.isSelected = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onPressed();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent
              : AppColors.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.accent
                : AppColors.accent.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.accent,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// S-024: 프리셋 그룹 위젯
class PresetGroup extends StatelessWidget {
  final String? label;
  final List<PresetButton> presets;

  const PresetGroup({
    super.key,
    this.label,
    required this.presets,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: presets,
        ),
      ],
    );
  }
}

/// 개선된 버튼 그룹 위젯
class SimButtonGroup extends StatelessWidget {
  final List<Widget> buttons;
  final MainAxisAlignment alignment;
  final bool expanded;

  const SimButtonGroup({
    super.key,
    required this.buttons,
    this.alignment = MainAxisAlignment.start,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    if (expanded) {
      return Row(
        mainAxisAlignment: alignment,
        children: buttons.map((button) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: button,
            ),
          );
        }).toList(),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.start,
      children: buttons,
    );
  }
}

/// S-018, S-019: 고급 설정 아코디언을 포함한 컨트롤 그룹
class ControlGroup extends StatefulWidget {
  final Widget primaryControl;
  final List<Widget>? advancedControls;
  final String advancedLabel;
  final bool initiallyExpanded;

  const ControlGroup({
    super.key,
    required this.primaryControl,
    this.advancedControls,
    this.advancedLabel = '고급 설정',
    this.initiallyExpanded = false,
  });

  @override
  State<ControlGroup> createState() => _ControlGroupState();
}

class _ControlGroupState extends State<ControlGroup>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // S-018: 핵심 컨트롤만 기본 표시
        widget.primaryControl,

        // S-019: 고급 설정 아코디언
        if (widget.advancedControls != null && widget.advancedControls!.isNotEmpty) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _toggle,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tune,
                    size: 16,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.advancedLabel,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Column(
              children: [
                const SizedBox(height: 12),
                ...widget.advancedControls!.map((control) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: control,
                )),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// 개선된 컨트롤 그리드 위젯
class ControlGrid extends StatelessWidget {
  final List<Widget> controls;
  final int columns;
  final double spacing;
  final double runSpacing;

  const ControlGrid({
    super.key,
    required this.controls,
    this.columns = 2,
    this.spacing = 16,
    this.runSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - (columns - 1) * spacing) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: controls.map((control) {
            return SizedBox(
              width: itemWidth.clamp(100.0, double.infinity),
              child: control,
            );
          }).toList(),
        );
      },
    );
  }
}

/// 토글 스위치 위젯
class SimToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? description;

  const SimToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (description != null)
                Text(
                  description!,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: (v) {
            HapticFeedback.selectionClick();
            onChanged(v);
          },
          activeTrackColor: AppColors.accent,
          activeThumbColor: Colors.white,
        ),
      ],
    );
  }
}

/// 세그먼트 선택 위젯
class SimSegment<T> extends StatelessWidget {
  final String? label;
  final Map<T, String> options;
  final T selected;
  final ValueChanged<T> onChanged;

  const SimSegment({
    super.key,
    this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: options.entries.map((entry) {
              final isSelected = entry.key == selected;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onChanged(entry.key);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accent
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      entry.value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
