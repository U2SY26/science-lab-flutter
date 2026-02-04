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
          'Resources & References',
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
                    'Dive deeper into science with these curated resources!',
                    style: TextStyle(color: AppColors.ink, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ============================================
          // 학술 저널 섹션
          // ============================================
          _SectionHeader(title: 'Academic Journals', icon: Icons.article),
          _ResourceCard(
            title: 'Nature',
            author: 'Nature Publishing Group',
            type: 'Journal',
            description: 'Premier multidisciplinary science journal',
            url: 'https://www.nature.com/',
          ),
          _ResourceCard(
            title: 'Science',
            author: 'AAAS',
            type: 'Journal',
            description: 'Leading scientific research publication',
            url: 'https://www.science.org/',
          ),
          _ResourceCard(
            title: 'Physical Review Letters',
            author: 'APS',
            type: 'Journal',
            description: 'Top physics research letters',
            url: 'https://journals.aps.org/prl/',
          ),
          _ResourceCard(
            title: 'arXiv',
            author: 'Cornell University',
            type: 'Preprint',
            description: 'Open access to physics, math, CS papers',
            url: 'https://arxiv.org/',
          ),
          const SizedBox(height: 24),

          // ============================================
          // 한국 AI 연구 섹션
          // ============================================
          _SectionHeader(title: 'Korean AI Research', icon: Icons.flag),
          _ResourceCard(
            title: 'KAIST AI Graduate School',
            author: 'KAIST',
            type: 'Research',
            description: 'Leading AI research institute in Korea',
            url: 'https://gsai.kaist.ac.kr/',
          ),
          _ResourceCard(
            title: 'Seoul National University AI Institute',
            author: 'SNU',
            type: 'Research',
            description: 'AI research at Korea\'s top university',
            url: 'https://aiis.snu.ac.kr/',
          ),
          _ResourceCard(
            title: 'NAVER AI Lab',
            author: 'NAVER',
            type: 'Industry',
            description: 'HyperCLOVA and Korean NLP research',
            url: 'https://clova.ai/en/research/research-areas.html',
          ),
          _ResourceCard(
            title: 'Kakao Brain',
            author: 'Kakao',
            type: 'Industry',
            description: 'Korean multimodal AI research',
            url: 'https://www.kakaobrain.com/',
          ),
          _ResourceCard(
            title: 'Korean NLP Papers (Papers with Code)',
            author: 'Community',
            type: 'Papers',
            description: 'Collection of Korean language AI papers',
            url: 'https://paperswithcode.com/datasets?q=korean&v=lst&o=match',
          ),
          const SizedBox(height: 24),

          // ============================================
          // 물리학 섹션
          // ============================================
          _SectionHeader(title: 'Physics', icon: Icons.speed),
          _ResourceCard(
            title: 'The Feynman Lectures on Physics',
            author: 'Richard Feynman',
            type: 'Book',
            description: 'Complete physics course from basics to quantum mechanics',
            url: 'https://www.feynmanlectures.caltech.edu/',
          ),
          _ResourceCard(
            title: 'QED: The Strange Theory of Light',
            author: 'Richard Feynman',
            type: 'Book',
            description: 'Quantum electrodynamics for general audience',
          ),
          _ResourceCard(
            title: 'Six Easy Pieces',
            author: 'Richard Feynman',
            type: 'Book',
            description: 'Essentials from the Feynman Lectures',
          ),
          _ResourceCard(
            title: 'Classical Mechanics',
            author: 'Herbert Goldstein',
            type: 'Textbook',
            description: 'Standard graduate-level classical mechanics',
          ),
          _ResourceCard(
            title: 'Introduction to Electrodynamics',
            author: 'David Griffiths',
            type: 'Textbook',
            description: 'Classic EM textbook for undergraduates',
          ),
          _ResourceCard(
            title: 'Physics for Scientists and Engineers',
            author: 'Serway & Jewett',
            type: 'Textbook',
            description: 'Comprehensive introductory physics',
          ),
          _ResourceCard(
            title: 'MIT OpenCourseWare - Physics',
            author: 'MIT',
            type: 'Course',
            description: 'Free physics courses from MIT',
            url: 'https://ocw.mit.edu/courses/physics/',
          ),
          _ResourceCard(
            title: 'PhET Simulations',
            author: 'University of Colorado',
            type: 'Simulation',
            description: 'Interactive physics simulations',
            url: 'https://phet.colorado.edu/',
          ),
          const SizedBox(height: 24),

          // ============================================
          // 양자역학 섹션
          // ============================================
          _SectionHeader(title: 'Quantum Mechanics', icon: Icons.blur_on),
          _ResourceCard(
            title: 'Introduction to Quantum Mechanics',
            author: 'David Griffiths',
            type: 'Textbook',
            description: 'Standard undergraduate QM textbook',
          ),
          _ResourceCard(
            title: 'Modern Quantum Mechanics',
            author: 'J.J. Sakurai',
            type: 'Textbook',
            description: 'Advanced graduate-level quantum mechanics',
          ),
          _ResourceCard(
            title: 'Principles of Quantum Mechanics',
            author: 'R. Shankar',
            type: 'Textbook',
            description: 'Comprehensive QM with mathematical rigor',
          ),
          _ResourceCard(
            title: 'Quantum Computing Since Democritus',
            author: 'Scott Aaronson',
            type: 'Book',
            description: 'Quantum computing from philosophical foundations',
          ),
          const SizedBox(height: 24),

          // ============================================
          // 수학 섹션
          // ============================================
          _SectionHeader(title: 'Mathematics', icon: Icons.functions),
          _ResourceCard(
            title: '3Blue1Brown',
            author: 'Grant Sanderson',
            type: 'YouTube',
            description: 'Visual explanations of math concepts',
            url: 'https://www.youtube.com/c/3blue1brown',
          ),
          _ResourceCard(
            title: 'Calculus Made Easy',
            author: 'Silvanus Thompson',
            type: 'Book',
            description: 'Classic intro to calculus (free online)',
            url: 'https://www.gutenberg.org/ebooks/33283',
          ),
          _ResourceCard(
            title: 'Linear Algebra Done Right',
            author: 'Sheldon Axler',
            type: 'Textbook',
            description: 'Conceptual approach to linear algebra',
          ),
          _ResourceCard(
            title: 'Essence of Linear Algebra',
            author: '3Blue1Brown',
            type: 'Video Series',
            description: 'Visual intuition for linear algebra',
            url: 'https://www.youtube.com/playlist?list=PLZHQObOWTQDPD3MizzM2xVFitgF8hE_ab',
          ),
          _ResourceCard(
            title: 'Analysis I & II',
            author: 'Terence Tao',
            type: 'Textbook',
            description: 'Rigorous real analysis by Fields medalist',
          ),
          _ResourceCard(
            title: 'Princeton Companion to Mathematics',
            author: 'Timothy Gowers (ed.)',
            type: 'Reference',
            description: 'Comprehensive overview of modern mathematics',
          ),
          _ResourceCard(
            title: 'Khan Academy - Math',
            author: 'Khan Academy',
            type: 'Course',
            description: 'Free math courses from basics to calculus',
            url: 'https://www.khanacademy.org/math',
          ),
          const SizedBox(height: 24),

          // ============================================
          // AI/ML 섹션
          // ============================================
          _SectionHeader(title: 'AI / Machine Learning', icon: Icons.psychology),
          _ResourceCard(
            title: 'Neural Networks and Deep Learning',
            author: 'Michael Nielsen',
            type: 'Online Book',
            description: 'Free online introduction to neural networks',
            url: 'http://neuralnetworksanddeeplearning.com/',
          ),
          _ResourceCard(
            title: 'Deep Learning',
            author: 'Goodfellow, Bengio, Courville',
            type: 'Textbook',
            description: 'The "bible" of deep learning',
            url: 'https://www.deeplearningbook.org/',
          ),
          _ResourceCard(
            title: 'Attention Is All You Need',
            author: 'Vaswani et al.',
            type: 'Paper',
            description: 'Original Transformer paper (2017)',
            url: 'https://arxiv.org/abs/1706.03762',
          ),
          _ResourceCard(
            title: 'Language Models are Few-Shot Learners',
            author: 'Brown et al. (OpenAI)',
            type: 'Paper',
            description: 'GPT-3 paper introducing in-context learning',
            url: 'https://arxiv.org/abs/2005.14165',
          ),
          _ResourceCard(
            title: 'CS231n: CNNs for Visual Recognition',
            author: 'Stanford University',
            type: 'Course',
            description: 'Computer vision deep learning course',
            url: 'http://cs231n.stanford.edu/',
          ),
          _ResourceCard(
            title: 'CS224n: NLP with Deep Learning',
            author: 'Stanford University',
            type: 'Course',
            description: 'Natural language processing course',
            url: 'http://web.stanford.edu/class/cs224n/',
          ),
          _ResourceCard(
            title: 'Andrej Karpathy Blog',
            author: 'Andrej Karpathy',
            type: 'Blog',
            description: 'Insights from AI researcher and Tesla AI lead',
            url: 'https://karpathy.github.io/',
          ),
          _ResourceCard(
            title: 'Distill',
            author: 'Various Researchers',
            type: 'Journal',
            description: 'Clear explanations of ML research',
            url: 'https://distill.pub/',
          ),
          _ResourceCard(
            title: 'Papers With Code',
            author: 'Community',
            type: 'Database',
            description: 'ML papers with code implementations',
            url: 'https://paperswithcode.com/',
          ),
          const SizedBox(height: 24),

          // ============================================
          // 카오스 이론 섹션
          // ============================================
          _SectionHeader(title: 'Chaos Theory', icon: Icons.grain),
          _ResourceCard(
            title: 'Chaos: Making a New Science',
            author: 'James Gleick',
            type: 'Book',
            description: 'Classic introduction to chaos theory',
          ),
          _ResourceCard(
            title: 'Nonlinear Dynamics and Chaos',
            author: 'Steven Strogatz',
            type: 'Textbook',
            description: 'Standard textbook for nonlinear dynamics',
          ),
          _ResourceCard(
            title: 'Sync: The Emerging Science',
            author: 'Steven Strogatz',
            type: 'Book',
            description: 'Synchronization in complex systems',
          ),
          _ResourceCard(
            title: 'The Fractal Geometry of Nature',
            author: 'Benoit Mandelbrot',
            type: 'Book',
            description: 'Foundational work on fractals',
          ),
          const SizedBox(height: 24),

          // ============================================
          // 화학 섹션
          // ============================================
          _SectionHeader(title: 'Chemistry', icon: Icons.science),
          _ResourceCard(
            title: 'Chemistry: The Central Science',
            author: 'Brown, LeMay, Bursten',
            type: 'Textbook',
            description: 'Standard general chemistry textbook',
          ),
          _ResourceCard(
            title: 'Organic Chemistry',
            author: 'Jonathan Clayden',
            type: 'Textbook',
            description: 'Comprehensive organic chemistry',
          ),
          _ResourceCard(
            title: 'Physical Chemistry',
            author: 'Atkins & de Paula',
            type: 'Textbook',
            description: 'Standard physical chemistry reference',
          ),
          const SizedBox(height: 24),

          // ============================================
          // 생물학 섹션
          // ============================================
          _SectionHeader(title: 'Biology', icon: Icons.biotech),
          _ResourceCard(
            title: 'Molecular Biology of the Cell',
            author: 'Alberts et al.',
            type: 'Textbook',
            description: 'Comprehensive cell biology textbook',
          ),
          _ResourceCard(
            title: 'The Selfish Gene',
            author: 'Richard Dawkins',
            type: 'Book',
            description: 'Gene-centered view of evolution',
          ),
          _ResourceCard(
            title: 'What Is Life?',
            author: 'Erwin Schrödinger',
            type: 'Book',
            description: 'Physicist\'s view on life and genetics',
          ),
          const SizedBox(height: 24),

          // ============================================
          // 천문학 섹션
          // ============================================
          _SectionHeader(title: 'Astronomy', icon: Icons.rocket_launch),
          _ResourceCard(
            title: 'A Brief History of Time',
            author: 'Stephen Hawking',
            type: 'Book',
            description: 'Cosmology for general audience',
          ),
          _ResourceCard(
            title: 'Cosmos',
            author: 'Carl Sagan',
            type: 'Book',
            description: 'Journey through the universe',
          ),
          _ResourceCard(
            title: 'Astrophysics for People in a Hurry',
            author: 'Neil deGrasse Tyson',
            type: 'Book',
            description: 'Quick tour of modern astrophysics',
          ),
          _ResourceCard(
            title: 'NASA Science',
            author: 'NASA',
            type: 'Website',
            description: 'Space science news and discoveries',
            url: 'https://science.nasa.gov/',
          ),
          const SizedBox(height: 24),

          // ============================================
          // 온라인 강의 플랫폼
          // ============================================
          _SectionHeader(title: 'Online Learning Platforms', icon: Icons.school),
          _ResourceCard(
            title: 'MIT OpenCourseWare',
            author: 'MIT',
            type: 'Platform',
            description: 'Free courses from MIT',
            url: 'https://ocw.mit.edu/',
          ),
          _ResourceCard(
            title: 'Coursera',
            author: 'Various Universities',
            type: 'Platform',
            description: 'University courses online',
            url: 'https://www.coursera.org/',
          ),
          _ResourceCard(
            title: 'edX',
            author: 'Harvard, MIT, etc.',
            type: 'Platform',
            description: 'University-level courses',
            url: 'https://www.edx.org/',
          ),
          _ResourceCard(
            title: 'Brilliant',
            author: 'Brilliant',
            type: 'Platform',
            description: 'Interactive math and science learning',
            url: 'https://brilliant.org/',
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
                  'Try our Web Version!',
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
                  child: const Text('Open in Browser'),
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
