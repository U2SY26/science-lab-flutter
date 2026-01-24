import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 에라토스테네스의 체 시각화 화면
class PrimeScreen extends StatefulWidget {
  const PrimeScreen({super.key});

  @override
  State<PrimeScreen> createState() => _PrimeScreenState();
}

class _PrimeScreenState extends State<PrimeScreen> {
  final int _maxN = 100;

  // 상태: 0=미확인, 1=소수, 2=합성수
  List<int> _status = [];
  int _currentPrime = 2;
  int _currentMultiple = 0;
  bool _isRunning = false;
  bool _isComplete = false;
  Timer? _timer;

  // 발견된 소수 목록
  List<int> _primes = [];

  // 속도
  int _speedMs = 100;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _status = List.filled(_maxN + 1, 0);
      _status[0] = 2; // 0은 소수가 아님
      _status[1] = 2; // 1은 소수가 아님
      _currentPrime = 2;
      _currentMultiple = 0;
      _isRunning = false;
      _isComplete = false;
      _primes = [];
    });
  }

  void _step() {
    if (_isComplete) return;
    HapticFeedback.lightImpact();

    setState(() {
      // 현재 위치가 합성수면 다음 소수 찾기
      while (_currentPrime <= math.sqrt(_maxN).toInt() && _status[_currentPrime] == 2) {
        _currentPrime++;
      }

      if (_currentPrime > math.sqrt(_maxN).toInt()) {
        // 완료: 남은 미확인 숫자들을 소수로 표시
        for (int i = 2; i <= _maxN; i++) {
          if (_status[i] == 0) {
            _status[i] = 1;
            _primes.add(i);
          }
        }
        _isComplete = true;
        _isRunning = false;
        _timer?.cancel();
        HapticFeedback.heavyImpact();
        return;
      }

      // 현재 소수 표시
      if (_status[_currentPrime] == 0) {
        _status[_currentPrime] = 1;
        _primes.add(_currentPrime);
      }

      // 배수 제거
      if (_currentMultiple == 0) {
        _currentMultiple = _currentPrime * 2;
      }

      if (_currentMultiple <= _maxN) {
        _status[_currentMultiple] = 2;
        _currentMultiple += _currentPrime;
      } else {
        // 다음 소수로 이동
        _currentPrime++;
        _currentMultiple = 0;
      }
    });
  }

  void _toggleRun() {
    HapticFeedback.mediumImpact();
    if (_isComplete) return;

    setState(() {
      _isRunning = !_isRunning;
    });

    if (_isRunning) {
      _timer = Timer.periodic(Duration(milliseconds: _speedMs), (_) {
        if (!_isComplete && _isRunning) {
          _step();
        } else {
          _timer?.cancel();
        }
      });
    } else {
      _timer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg.withValues(alpha: 0.9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '수학',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '에라토스테네스의 체',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학',
          title: '에라토스테네스의 체',
          formula: '소수 p의 배수 2p, 3p, 4p, ... 제거',
          formulaDescription: '고대 그리스의 소수 발견 알고리즘',
          simulation: SizedBox(
            height: 340,
            child: Column(
              children: [
                // 그리드
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.simBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 10,
                        crossAxisSpacing: 3,
                        mainAxisSpacing: 3,
                      ),
                      itemCount: _maxN,
                      itemBuilder: (context, index) {
                        final n = index + 1;
                        return _NumberCell(
                          number: n,
                          status: _status[n],
                          isCurrentPrime: n == _currentPrime && !_isComplete,
                          isCurrentMultiple: n == _currentMultiple && n != _currentPrime,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // 발견된 소수
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.simBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.stars, size: 14, color: AppColors.accent),
                          const SizedBox(width: 6),
                          Text(
                            '발견된 소수: ${_primes.length}개',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _primes.isEmpty ? '시작하면 소수가 표시됩니다' : _primes.join(', '),
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          controls: Column(
            children: [
              // 상태 정보
              _StatusInfo(
                currentPrime: _currentPrime,
                primeCount: _primes.length,
                isComplete: _isComplete,
              ),
              const SizedBox(height: 16),
              ControlGroup(
                primaryControl: SimSlider(
                  label: '속도',
                  value: (200 - _speedMs).toDouble(),
                  min: 0,
                  max: 180,
                  defaultValue: 100,
                  formatValue: (v) => v > 150 ? '빠름' : v > 50 ? '보통' : '느림',
                  onChanged: (v) {
                    setState(() {
                      _speedMs = 200 - v.toInt();
                      if (_isRunning) {
                        _timer?.cancel();
                        _timer = Timer.periodic(Duration(milliseconds: _speedMs), (_) {
                          if (!_isComplete && _isRunning) {
                            _step();
                          } else {
                            _timer?.cancel();
                          }
                        });
                      }
                    });
                  },
                ),
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: '1단계',
                icon: Icons.skip_next,
                onPressed: _isComplete ? null : _step,
              ),
              SimButton(
                label: _isRunning ? '일시정지' : '자동 실행',
                icon: _isRunning ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: _isComplete ? null : _toggleRun,
              ),
              SimButton(
                label: '초기화',
                icon: Icons.refresh,
                onPressed: _reset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberCell extends StatelessWidget {
  final int number;
  final int status; // 0=미확인, 1=소수, 2=합성수
  final bool isCurrentPrime;
  final bool isCurrentMultiple;

  const _NumberCell({
    required this.number,
    required this.status,
    this.isCurrentPrime = false,
    this.isCurrentMultiple = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    if (isCurrentPrime) {
      bgColor = AppColors.accent;
      textColor = Colors.black;
    } else if (isCurrentMultiple) {
      bgColor = Colors.red.withValues(alpha: 0.7);
      textColor = Colors.white;
    } else if (status == 1) {
      bgColor = AppColors.accent.withValues(alpha: 0.3);
      textColor = AppColors.accent;
    } else if (status == 2) {
      bgColor = AppColors.muted.withValues(alpha: 0.2);
      textColor = AppColors.muted.withValues(alpha: 0.5);
    } else {
      bgColor = AppColors.card;
      textColor = AppColors.ink;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        boxShadow: isCurrentPrime
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.5),
                  blurRadius: 8,
                )
              ]
            : null,
      ),
      child: Center(
        child: Text(
          '$number',
          style: TextStyle(
            color: textColor,
            fontSize: 10,
            fontWeight: isCurrentPrime ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}

class _StatusInfo extends StatelessWidget {
  final int currentPrime;
  final int primeCount;
  final bool isComplete;

  const _StatusInfo({
    required this.currentPrime,
    required this.primeCount,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.simBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isComplete ? Colors.green.withValues(alpha: 0.5) : AppColors.cardBorder,
        ),
      ),
      child: Column(
        children: [
          if (isComplete)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                  SizedBox(width: 4),
                  Text(
                    '체 완료!',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _InfoChip(
                label: '현재 소수',
                value: isComplete ? '-' : '$currentPrime',
                icon: Icons.filter_1,
                color: AppColors.accent,
              ),
              _InfoChip(
                label: '소수 개수',
                value: '$primeCount',
                icon: Icons.stars,
                color: AppColors.accent2,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
