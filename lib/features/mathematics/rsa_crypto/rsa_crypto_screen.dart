import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// RSA Encryption Visualization
/// RSA 암호화 시각화
class RsaCryptoScreen extends StatefulWidget {
  const RsaCryptoScreen({super.key});

  @override
  State<RsaCryptoScreen> createState() => _RsaCryptoScreenState();
}

class _RsaCryptoScreenState extends State<RsaCryptoScreen> {
  // Small primes for demonstration
  int p = 3;
  int q = 11;
  int message = 7;
  int step = 0; // 0: setup, 1: encrypt, 2: decrypt
  bool isKorean = true;

  // RSA parameters
  int get n => p * q;
  int get phi => (p - 1) * (q - 1);

  int get e {
    // Find smallest e where gcd(e, phi) = 1 and e > 1
    for (int candidate = 3; candidate < phi; candidate += 2) {
      if (_gcd(candidate, phi) == 1) return candidate;
    }
    return 3;
  }

  int get d {
    // Modular multiplicative inverse of e mod phi
    return _modInverse(e, phi);
  }

  int get encrypted => _modPow(message, e, n);
  int get decrypted => _modPow(encrypted, d, n);

  int _gcd(int a, int b) {
    while (b != 0) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a;
  }

  int _modPow(int base, int exp, int mod) {
    if (mod == 1) return 0;
    int result = 1;
    base = base % mod;
    while (exp > 0) {
      if (exp % 2 == 1) {
        result = (result * base) % mod;
      }
      exp = exp ~/ 2;
      base = (base * base) % mod;
    }
    return result;
  }

  int _modInverse(int a, int m) {
    // Extended Euclidean Algorithm
    int m0 = m, y = 0, x = 1;
    if (m == 1) return 0;
    while (a > 1) {
      int q = a ~/ m;
      int t = m;
      m = a % m;
      a = t;
      t = y;
      y = x - q * y;
      x = t;
    }
    if (x < 0) x += m0;
    return x;
  }

  void _nextStep() {
    HapticFeedback.selectionClick();
    setState(() {
      step = (step + 1) % 3;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      p = 3;
      q = 11;
      message = 7;
      step = 0;
    });
  }

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
              isKorean ? '암호학' : 'CRYPTOGRAPHY',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? 'RSA 암호화' : 'RSA Encryption',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => setState(() => isKorean = !isKorean),
            tooltip: isKorean ? 'English' : '한국어',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '암호학' : 'CRYPTOGRAPHY',
          title: isKorean ? 'RSA 암호화' : 'RSA Encryption',
          formula: 'c = m^e mod n, m = c^d mod n',
          formulaDescription: isKorean
              ? 'RSA는 두 큰 소수의 곱을 인수분해하기 어렵다는 것에 기반한 공개키 암호화 방식입니다.'
              : 'RSA is a public-key cryptosystem based on the difficulty of factoring the product of two large primes.',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: RsaCryptoPainter(
                p: p,
                q: q,
                n: n,
                e: e,
                d: d,
                message: message,
                encrypted: encrypted,
                decrypted: decrypted,
                step: step,
                isKorean: isKorean,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Key information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _KeyInfo(
                          label: isKorean ? '공개키' : 'Public Key',
                          value: '(e=$e, n=$n)',
                          color: Colors.green,
                          icon: Icons.lock_open,
                        ),
                        _KeyInfo(
                          label: isKorean ? '개인키' : 'Private Key',
                          value: '(d=$d, n=$n)',
                          color: Colors.red,
                          icon: Icons.lock,
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      children: [
                        _InfoItem(label: 'p', value: '$p'),
                        _InfoItem(label: 'q', value: '$q'),
                        _InfoItem(label: 'n=p×q', value: '$n'),
                        _InfoItem(label: 'φ(n)', value: '$phi'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Encryption/Decryption result
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: step == 1
                      ? Colors.green.withValues(alpha: 0.1)
                      : step == 2
                          ? Colors.blue.withValues(alpha: 0.1)
                          : AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: step == 1 ? Colors.green : step == 2 ? Colors.blue : AppColors.cardBorder,
                  ),
                ),
                child: Column(
                  children: [
                    if (step == 0) ...[
                      Text(
                        isKorean ? '메시지 (평문)' : 'Message (Plaintext)',
                        style: const TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                      Text(
                        'm = $message',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                    if (step == 1) ...[
                      Text(
                        isKorean ? '암호화: c = m^e mod n' : 'Encrypt: c = m^e mod n',
                        style: const TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                      Text(
                        '$message^$e mod $n = $encrypted',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isKorean ? '암호문: c = $encrypted' : 'Ciphertext: c = $encrypted',
                        style: const TextStyle(color: Colors.green, fontSize: 14),
                      ),
                    ],
                    if (step == 2) ...[
                      Text(
                        isKorean ? '복호화: m = c^d mod n' : 'Decrypt: m = c^d mod n',
                        style: const TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                      Text(
                        '$encrypted^$d mod $n = $decrypted',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isKorean ? '복호화된 메시지: $decrypted' : 'Decrypted: $decrypted',
                            style: const TextStyle(color: Colors.blue, fontSize: 14),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            decrypted == message ? Icons.check_circle : Icons.error,
                            color: decrypted == message ? Colors.green : Colors.red,
                            size: 18,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Step selection
              PresetGroup(
                label: isKorean ? '단계' : 'Step',
                presets: [
                  PresetButton(
                    label: isKorean ? '설정' : 'Setup',
                    isSelected: step == 0,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => step = 0);
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '암호화' : 'Encrypt',
                    isSelected: step == 1,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => step = 1);
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '복호화' : 'Decrypt',
                    isSelected: step == 2,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => step = 2);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Controls
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '메시지 (m)' : 'Message (m)',
                  value: message.toDouble(),
                  min: 2,
                  max: (n - 1).toDouble(),
                  defaultValue: 7,
                  formatValue: (v) => '${v.toInt()}',
                  onChanged: (v) => setState(() => message = v.toInt()),
                ),
                advancedControls: [
                  Row(
                    children: [
                      Expanded(
                        child: SimSlider(
                          label: isKorean ? '소수 p' : 'Prime p',
                          value: p.toDouble(),
                          min: 3,
                          max: 13,
                          step: 2,
                          defaultValue: 3,
                          formatValue: (v) => '${v.toInt()}',
                          onChanged: (v) {
                            final newP = _findPrime(v.toInt());
                            if (newP != q) {
                              setState(() {
                                p = newP;
                                if (message >= n) message = n - 1;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SimSlider(
                          label: isKorean ? '소수 q' : 'Prime q',
                          value: q.toDouble(),
                          min: 5,
                          max: 17,
                          step: 2,
                          defaultValue: 11,
                          formatValue: (v) => '${v.toInt()}',
                          onChanged: (v) {
                            final newQ = _findPrime(v.toInt());
                            if (newQ != p) {
                              setState(() {
                                q = newQ;
                                if (message >= n) message = n - 1;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: isKorean ? '다음 단계' : 'Next Step',
                icon: Icons.arrow_forward,
                isPrimary: true,
                onPressed: _nextStep,
              ),
              SimButton(
                label: isKorean ? '리셋' : 'Reset',
                icon: Icons.refresh,
                onPressed: _reset,
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _findPrime(int n) {
    final primes = [2, 3, 5, 7, 11, 13, 17, 19, 23];
    for (final prime in primes) {
      if (prime >= n) return prime;
    }
    return primes.last;
  }
}

class _KeyInfo extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _KeyInfo({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: color, fontSize: 10)),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class RsaCryptoPainter extends CustomPainter {
  final int p, q, n, e, d, message, encrypted, decrypted, step;
  final bool isKorean;

  RsaCryptoPainter({
    required this.p,
    required this.q,
    required this.n,
    required this.e,
    required this.d,
    required this.message,
    required this.encrypted,
    required this.decrypted,
    required this.step,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;

    // Draw Alice (sender)
    _drawPerson(canvas, Offset(60, size.height / 2), isKorean ? '앨리스' : 'Alice', Colors.blue);

    // Draw Bob (receiver)
    _drawPerson(canvas, Offset(size.width - 60, size.height / 2), isKorean ? '밥' : 'Bob', Colors.green);

    // Draw message flow
    if (step >= 0) {
      // Original message
      _drawMessageBox(
        canvas,
        Offset(100, size.height / 2 - 60),
        'm = $message',
        isKorean ? '평문' : 'Plain',
        Colors.blue.withValues(alpha: 0.2),
        Colors.blue,
      );
    }

    if (step >= 1) {
      // Encryption arrow
      _drawArrow(
        canvas,
        Offset(180, size.height / 2 - 35),
        Offset(centerX - 40, size.height / 2 - 35),
        Colors.green,
      );
      _drawText(canvas, 'c = m^e mod n', Offset(centerX - 70, size.height / 2 - 55), Colors.green, fontSize: 10);

      // Encrypted message
      _drawMessageBox(
        canvas,
        Offset(centerX - 40, size.height / 2 - 60),
        'c = $encrypted',
        isKorean ? '암호문' : 'Cipher',
        Colors.red.withValues(alpha: 0.2),
        Colors.red,
      );
    }

    if (step >= 2) {
      // Decryption arrow
      _drawArrow(
        canvas,
        Offset(centerX + 40, size.height / 2 - 35),
        Offset(size.width - 180, size.height / 2 - 35),
        Colors.blue,
      );
      _drawText(canvas, 'm = c^d mod n', Offset(centerX + 50, size.height / 2 - 55), Colors.blue, fontSize: 10);

      // Decrypted message
      _drawMessageBox(
        canvas,
        Offset(size.width - 180, size.height / 2 - 60),
        'm = $decrypted',
        isKorean ? '복호문' : 'Decrypted',
        Colors.green.withValues(alpha: 0.2),
        Colors.green,
      );
    }

    // Draw key exchange info
    final keyY = size.height * 0.75;

    // Public key (can be shared)
    _drawText(
      canvas,
      isKorean ? '공개키 (e, n) 공유' : 'Public key (e, n) shared',
      Offset(centerX, keyY),
      Colors.green,
      fontSize: 11,
    );

    // Private key (kept secret)
    _drawText(
      canvas,
      isKorean ? '개인키 (d) 비밀 유지' : 'Private key (d) kept secret',
      Offset(size.width - 100, keyY + 20),
      Colors.red,
      fontSize: 10,
    );
  }

  void _drawPerson(Canvas canvas, Offset pos, String name, Color color) {
    // Head
    canvas.drawCircle(pos - const Offset(0, 25), 15, Paint()..color = color.withValues(alpha: 0.3));
    canvas.drawCircle(
      pos - const Offset(0, 25),
      15,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Body
    canvas.drawLine(
      pos - const Offset(0, 10),
      pos + const Offset(0, 20),
      Paint()
        ..color = color
        ..strokeWidth = 2,
    );

    // Name
    _drawText(canvas, name, pos + const Offset(0, 35), color, fontSize: 12);
  }

  void _drawMessageBox(Canvas canvas, Offset pos, String text, String label, Color fill, Color border) {
    final rect = Rect.fromLTWH(pos.dx, pos.dy, 80, 50);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()..color = fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    _drawText(canvas, text, Offset(pos.dx + 40, pos.dy + 20), border, fontSize: 12);
    _drawText(canvas, label, Offset(pos.dx + 40, pos.dy + 38), border.withValues(alpha: 0.7), fontSize: 9);
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Color color) {
    canvas.drawLine(
      from,
      to,
      Paint()
        ..color = color
        ..strokeWidth = 2,
    );

    final direction = (to - from);
    final unit = direction / direction.distance;
    final normal = Offset(-unit.dy, unit.dx);
    final arrowSize = 8.0;

    final path = Path();
    path.moveTo(to.dx, to.dy);
    path.lineTo(to.dx - unit.dx * arrowSize + normal.dx * arrowSize / 2,
        to.dy - unit.dy * arrowSize + normal.dy * arrowSize / 2);
    path.lineTo(to.dx - unit.dx * arrowSize - normal.dx * arrowSize / 2,
        to.dy - unit.dy * arrowSize - normal.dy * arrowSize / 2);
    path.close();

    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 12}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant RsaCryptoPainter oldDelegate) =>
      step != oldDelegate.step ||
      message != oldDelegate.message ||
      encrypted != oldDelegate.encrypted;
}
