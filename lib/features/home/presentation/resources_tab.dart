import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';

/// 관련 자료 (논문/서적) 탭
class ResourcesTab extends StatelessWidget {
  const ResourcesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text(
          '관련 자료',
          style: TextStyle(color: AppColors.ink, fontSize: 20),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 소개 텍스트
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: AppColors.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '더 깊이 배우고 싶다면 이 자료들을 참고하세요!',
                    style: TextStyle(color: AppColors.ink, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 물리학 섹션
          _SectionHeader(title: '물리학', icon: Icons.speed),
          _ResourceCard(
            title: 'The Feynman Lectures on Physics',
            author: 'Richard Feynman',
            type: '서적',
            description: '물리학의 기초부터 양자역학까지 다루는 명강의',
            url: 'https://www.feynmanlectures.caltech.edu/',
          ),
          _ResourceCard(
            title: 'Classical Mechanics',
            author: 'Herbert Goldstein',
            type: '서적',
            description: '고전역학의 표준 교재',
          ),
          _ResourceCard(
            title: 'Physics for Scientists and Engineers',
            author: 'Serway & Jewett',
            type: '서적',
            description: '공학도를 위한 물리학 입문서',
          ),
          const SizedBox(height: 24),

          // 수학 섹션
          _SectionHeader(title: '수학', icon: Icons.functions),
          _ResourceCard(
            title: '3Blue1Brown',
            author: 'Grant Sanderson',
            type: 'YouTube',
            description: '수학 개념을 시각적으로 설명하는 유튜브 채널',
            url: 'https://www.youtube.com/c/3blue1brown',
          ),
          _ResourceCard(
            title: 'Calculus Made Easy',
            author: 'Silvanus Thompson',
            type: '서적',
            description: '미적분학을 쉽게 설명한 고전',
            url: 'https://www.gutenberg.org/ebooks/33283',
          ),
          _ResourceCard(
            title: 'Linear Algebra Done Right',
            author: 'Sheldon Axler',
            type: '서적',
            description: '선형대수학의 개념적 이해',
          ),
          const SizedBox(height: 24),

          // AI/ML 섹션
          _SectionHeader(title: 'AI/머신러닝', icon: Icons.psychology),
          _ResourceCard(
            title: 'Neural Networks and Deep Learning',
            author: 'Michael Nielsen',
            type: '온라인 서적',
            description: '신경망의 기초를 다루는 무료 온라인 교재',
            url: 'http://neuralnetworksanddeeplearning.com/',
          ),
          _ResourceCard(
            title: 'Deep Learning',
            author: 'Goodfellow, Bengio, Courville',
            type: '서적',
            description: '딥러닝의 바이블이라 불리는 교재',
            url: 'https://www.deeplearningbook.org/',
          ),
          _ResourceCard(
            title: 'CS231n: CNN for Visual Recognition',
            author: 'Stanford University',
            type: '강의',
            description: '이미지 인식을 위한 CNN 강의',
            url: 'http://cs231n.stanford.edu/',
          ),
          _ResourceCard(
            title: 'Andrej Karpathy의 블로그',
            author: 'Andrej Karpathy',
            type: '블로그',
            description: 'AI 연구자의 인사이트',
            url: 'https://karpathy.github.io/',
          ),
          const SizedBox(height: 24),

          // 카오스 섹션
          _SectionHeader(title: '카오스 이론', icon: Icons.grain),
          _ResourceCard(
            title: 'Chaos: Making a New Science',
            author: 'James Gleick',
            type: '서적',
            description: '카오스 이론의 역사와 개념을 다룬 명저',
          ),
          _ResourceCard(
            title: 'Nonlinear Dynamics and Chaos',
            author: 'Steven Strogatz',
            type: '서적',
            description: '비선형 동역학의 표준 교재',
          ),
          const SizedBox(height: 24),

          // 화학 섹션
          _SectionHeader(title: '화학', icon: Icons.science),
          _ResourceCard(
            title: 'Chemistry: The Central Science',
            author: 'Brown, LeMay, Bursten',
            type: '서적',
            description: '일반 화학의 표준 교재',
          ),
          _ResourceCard(
            title: 'Organic Chemistry',
            author: 'Jonathan Clayden',
            type: '서적',
            description: '유기화학 입문서',
          ),
          const SizedBox(height: 32),

          // 웹 버전 안내
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                Icon(Icons.language, color: AppColors.accent2, size: 32),
                const SizedBox(height: 8),
                Text(
                  '웹 버전도 있어요!',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'https://3dweb-rust.vercel.app',
                  style: TextStyle(color: AppColors.accent2, fontSize: 13),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _launchUrl('https://3dweb-rust.vercel.app'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent2,
                    side: BorderSide(color: AppColors.accent2),
                  ),
                  child: const Text('웹에서 열기'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final String title;
  final String author;
  final String type;
  final String description;
  final String? url;

  const _ResourceCard({
    required this.title,
    required this.author,
    required this.type,
    required this.description,
    this.url,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: url != null ? () => _launchUrl(url!) : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        author,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: AppColors.ink.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (url != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.open_in_new,
                    color: AppColors.muted,
                    size: 18,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    HapticFeedback.lightImpact();
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
