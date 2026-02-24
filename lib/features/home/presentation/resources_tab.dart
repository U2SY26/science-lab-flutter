import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';

/// 관련 자료 (논문/서적) 탭
class ResourcesTab extends ConsumerWidget {
  const ResourcesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isKorean = ref.watch(isKoreanProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Text(
          isKorean ? '자료 및 참고문헌' : 'Resources & References',
          style: const TextStyle(color: AppColors.ink, fontSize: 20),
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
                    isKorean
                        ? '엄선된 자료들로 과학을 더 깊이 탐구해보세요!'
                        : 'Dive deeper into science with these curated resources!',
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
          _SectionHeader(title: isKorean ? '학술 저널' : 'Academic Journals', icon: Icons.article),
          _ResourceCard(
            title: 'Nature',
            author: 'Nature Publishing Group',
            type: isKorean ? '저널' : 'Journal',
            description: isKorean ? '세계 최고의 다학제 과학 저널' : 'Premier multidisciplinary science journal',
            url: 'https://www.nature.com/',
          ),
          _ResourceCard(
            title: 'Science',
            author: 'AAAS',
            type: isKorean ? '저널' : 'Journal',
            description: isKorean ? '최신 과학 연구 출판물' : 'Leading scientific research publication',
            url: 'https://www.science.org/',
          ),
          _ResourceCard(
            title: 'Physical Review Letters',
            author: 'APS',
            type: isKorean ? '저널' : 'Journal',
            description: isKorean ? '최고 수준의 물리학 연구 논문' : 'Top physics research letters',
            url: 'https://journals.aps.org/prl/',
          ),
          _ResourceCard(
            title: 'arXiv',
            author: 'Cornell University',
            type: isKorean ? '프리프린트' : 'Preprint',
            description: isKorean ? '물리, 수학, CS 논문 오픈 액세스' : 'Open access to physics, math, CS papers',
            url: 'https://arxiv.org/',
          ),
          const SizedBox(height: 24),

          // ============================================
          // 한국 AI 연구 섹션
          // ============================================
          _SectionHeader(title: isKorean ? '한국 AI 연구' : 'Korean AI Research', icon: Icons.flag),
          _ResourceCard(
            title: isKorean ? 'KAIST AI 대학원' : 'KAIST AI Graduate School',
            author: 'KAIST',
            type: isKorean ? '연구기관' : 'Research',
            description: isKorean ? '한국 최고의 AI 연구 기관' : 'Leading AI research institute in Korea',
            url: 'https://gsai.kaist.ac.kr/',
          ),
          _ResourceCard(
            title: isKorean ? '서울대학교 AI 연구원' : 'Seoul National University AI Institute',
            author: isKorean ? '서울대학교' : 'SNU',
            type: isKorean ? '연구기관' : 'Research',
            description: isKorean ? '한국 최고 대학의 AI 연구' : 'AI research at Korea\'s top university',
            url: 'https://aiis.snu.ac.kr/',
          ),
          _ResourceCard(
            title: isKorean ? '네이버 AI Lab' : 'NAVER AI Lab',
            author: isKorean ? '네이버' : 'NAVER',
            type: isKorean ? '기업 연구' : 'Industry',
            description: isKorean ? 'HyperCLOVA 및 한국어 NLP 연구' : 'HyperCLOVA and Korean NLP research',
            url: 'https://clova.ai/en/research/research-areas.html',
          ),
          _ResourceCard(
            title: isKorean ? '카카오브레인' : 'Kakao Brain',
            author: isKorean ? '카카오' : 'Kakao',
            type: isKorean ? '기업 연구' : 'Industry',
            description: isKorean ? '한국 멀티모달 AI 연구' : 'Korean multimodal AI research',
            url: 'https://www.kakaobrain.com/',
          ),
          _ResourceCard(
            title: isKorean ? '한국어 NLP 논문 모음' : 'Korean NLP Papers (Papers with Code)',
            author: isKorean ? '커뮤니티' : 'Community',
            type: isKorean ? '논문' : 'Papers',
            description: isKorean ? '한국어 AI 논문 모음집' : 'Collection of Korean language AI papers',
            url: 'https://paperswithcode.com/datasets?q=korean&v=lst&o=match',
          ),
          const SizedBox(height: 24),

          // ============================================
          // 물리학 섹션
          // ============================================
          _SectionHeader(title: isKorean ? '물리학' : 'Physics', icon: Icons.speed),
          _ResourceCard(
            title: isKorean ? '파인만 물리학 강의' : 'The Feynman Lectures on Physics',
            author: isKorean ? '리처드 파인만' : 'Richard Feynman',
            type: isKorean ? '교재' : 'Book',
            description: isKorean ? '기초부터 양자역학까지 완전한 물리학 과정' : 'Complete physics course from basics to quantum mechanics',
            url: 'https://www.feynmanlectures.caltech.edu/',
          ),
          _ResourceCard(
            title: isKorean ? 'QED: 빛과 물질의 이상한 이론' : 'QED: The Strange Theory of Light',
            author: isKorean ? '리처드 파인만' : 'Richard Feynman',
            type: isKorean ? '도서' : 'Book',
            description: isKorean ? '일반인을 위한 양자전기역학' : 'Quantum electrodynamics for general audience',
          ),
          _ResourceCard(
            title: isKorean ? '여섯 가지 쉬운 조각들' : 'Six Easy Pieces',
            author: isKorean ? '리처드 파인만' : 'Richard Feynman',
            type: isKorean ? '도서' : 'Book',
            description: isKorean ? '파인만 강의의 핵심 내용' : 'Essentials from the Feynman Lectures',
          ),
          _ResourceCard(
            title: isKorean ? '고전역학' : 'Classical Mechanics',
            author: isKorean ? '허버트 골드스타인' : 'Herbert Goldstein',
            type: isKorean ? '대학 교재' : 'Textbook',
            description: isKorean ? '대학원 수준 고전역학 표준 교재' : 'Standard graduate-level classical mechanics',
          ),
          _ResourceCard(
            title: isKorean ? '전자기학 입문' : 'Introduction to Electrodynamics',
            author: isKorean ? '데이비드 그리피스' : 'David Griffiths',
            type: isKorean ? '대학 교재' : 'Textbook',
            description: isKorean ? '학부생을 위한 고전 전자기학 교재' : 'Classic EM textbook for undergraduates',
          ),
          _ResourceCard(
            title: isKorean ? '과학자와 공학자를 위한 물리학' : 'Physics for Scientists and Engineers',
            author: isKorean ? '서웨이 & 주엣' : 'Serway & Jewett',
            type: isKorean ? '대학 교재' : 'Textbook',
            description: isKorean ? '종합 입문 물리학' : 'Comprehensive introductory physics',
          ),
          _ResourceCard(
            title: isKorean ? 'MIT 공개강좌 - 물리학' : 'MIT OpenCourseWare - Physics',
            author: 'MIT',
            type: isKorean ? '강좌' : 'Course',
            description: isKorean ? 'MIT 무료 물리학 강좌' : 'Free physics courses from MIT',
            url: 'https://ocw.mit.edu/courses/physics/',
          ),
          _ResourceCard(
            title: isKorean ? 'PhET 시뮬레이션' : 'PhET Simulations',
            author: isKorean ? '콜로라도 대학교' : 'University of Colorado',
            type: isKorean ? '시뮬레이션' : 'Simulation',
            description: isKorean ? '인터랙티브 물리학 시뮬레이션' : 'Interactive physics simulations',
            url: 'https://phet.colorado.edu/',
          ),
          _ResourceCard(
            title: 'VisualPDE',
            author: isKorean ? '벤자민 워커 외' : 'Benjamin Walker et al.',
            type: isKorean ? '시뮬레이션' : 'Simulation',
            description: isKorean ? '편미분방정식의 인터랙티브 시각화 도구' : 'Interactive PDE visualization tool',
            url: 'https://visualpde.com/',
          ),
          const SizedBox(height: 24),

          // ============================================
          // 양자역학 섹션
          // ============================================
          _SectionHeader(title: isKorean ? '양자역학' : 'Quantum Mechanics', icon: Icons.blur_on),
          _ResourceCard(
            title: isKorean ? '양자역학 입문' : 'Introduction to Quantum Mechanics',
            author: isKorean ? '데이비드 그리피스' : 'David Griffiths',
            type: isKorean ? '대학 교재' : 'Textbook',
            description: isKorean ? '학부 양자역학 표준 교재' : 'Standard undergraduate QM textbook',
          ),
          _ResourceCard(
            title: isKorean ? '현대 양자역학' : 'Modern Quantum Mechanics',
            author: isKorean ? 'J.J. 사쿠라이' : 'J.J. Sakurai',
            type: isKorean ? '대학 교재' : 'Textbook',
            description: isKorean ? '대학원 수준 고급 양자역학' : 'Advanced graduate-level quantum mechanics',
          ),
          _ResourceCard(
            title: isKorean ? '양자역학의 원리' : 'Principles of Quantum Mechanics',
            author: isKorean ? 'R. 샨카르' : 'R. Shankar',
            type: isKorean ? '대학 교재' : 'Textbook',
            description: isKorean ? '수학적 엄밀성을 갖춘 종합 양자역학' : 'Comprehensive QM with mathematical rigor',
          ),
          _ResourceCard(
            title: isKorean ? '데모크리토스 이후의 양자 컴퓨팅' : 'Quantum Computing Since Democritus',
            author: isKorean ? '스콧 아론슨' : 'Scott Aaronson',
            type: isKorean ? '도서' : 'Book',
            description: isKorean ? '철학적 기초부터의 양자 컴퓨팅' : 'Quantum computing from philosophical foundations',
          ),
          const SizedBox(height: 24),

          // ============================================
          // 수학 섹션
          // ============================================
          _SectionHeader(title: isKorean ? '수학' : 'Mathematics', icon: Icons.functions),
          _ResourceCard(
            title: '3Blue1Brown',
            author: isKorean ? '그랜트 샌더슨' : 'Grant Sanderson',
            type: isKorean ? '유튜브' : 'YouTube',
            description: isKorean ? '수학 개념의 시각적 설명' : 'Visual explanations of math concepts',
            url: 'https://www.youtube.com/c/3blue1brown',
          ),
          _ResourceCard(
            title: isKorean ? '쉽게 배우는 미적분학' : 'Calculus Made Easy',
            author: isKorean ? '실바누스 톰프슨' : 'Silvanus Thompson',
            type: isKorean ? '도서' : 'Book',
            description: isKorean ? '미적분학 고전 입문서 (무료 온라인)' : 'Classic intro to calculus (free online)',
            url: 'https://www.gutenberg.org/ebooks/33283',
          ),
          _ResourceCard(
            title: isKorean ? '올바른 선형대수학' : 'Linear Algebra Done Right',
            author: isKorean ? '셸던 액슬러' : 'Sheldon Axler',
            type: isKorean ? '대학 교재' : 'Textbook',
            description: isKorean ? '개념적 접근의 선형대수학' : 'Conceptual approach to linear algebra',
          ),
          _ResourceCard(
            title: isKorean ? '선형대수학의 본질' : 'Essence of Linear Algebra',
            author: '3Blue1Brown',
            type: isKorean ? '영상 시리즈' : 'Video Series',
            description: isKorean ? '선형대수학의 시각적 직관' : 'Visual intuition for linear algebra',
            url: 'https://www.youtube.com/playlist?list=PLZHQObOWTQDPD3MizzM2xVFitgF8hE_ab',
          ),
          _ResourceCard(
            title: isKorean ? '해석학 I & II' : 'Analysis I & II',
            author: isKorean ? '테렌스 타오' : 'Terence Tao',
            type: isKorean ? '대학 교재' : 'Textbook',
            description: isKorean ? '필즈 메달리스트의 엄밀한 실해석학' : 'Rigorous real analysis by Fields medalist',
          ),
          _ResourceCard(
            title: isKorean ? '프린스턴 수학 안내서' : 'Princeton Companion to Mathematics',
            author: isKorean ? '티모시 가워스 (편)' : 'Timothy Gowers (ed.)',
            type: isKorean ? '참고서' : 'Reference',
            description: isKorean ? '현대 수학의 종합 개요' : 'Comprehensive overview of modern mathematics',
          ),
          _ResourceCard(
            title: isKorean ? '칸 아카데미 - 수학' : 'Khan Academy - Math',
            author: isKorean ? '칸 아카데미' : 'Khan Academy',
            type: isKorean ? '강좌' : 'Course',
            description: isKorean ? '기초부터 미적분까지 무료 수학 강좌' : 'Free math courses from basics to calculus',
            url: 'https://www.khanacademy.org/math',
          ),
          const SizedBox(height: 24),

          // ============================================
          // AI/ML 섹션
          // ============================================
          _SectionHeader(title: isKorean ? 'AI / 머신러닝' : 'AI / Machine Learning', icon: Icons.psychology),
          _ResourceCard(
            title: isKorean ? '신경망과 딥러닝' : 'Neural Networks and Deep Learning',
            author: isKorean ? '마이클 닐슨' : 'Michael Nielsen',
            type: isKorean ? '온라인 도서' : 'Online Book',
            description: isKorean ? '무료 온라인 신경망 입문서' : 'Free online introduction to neural networks',
            url: 'http://neuralnetworksanddeeplearning.com/',
          ),
          _ResourceCard(
            title: isKorean ? '딥러닝' : 'Deep Learning',
            author: 'Goodfellow, Bengio, Courville',
            type: isKorean ? '대학 교재' : 'Textbook',
            description: isKorean ? '딥러닝의 "바이블"' : 'The "bible" of deep learning',
            url: 'https://www.deeplearningbook.org/',
          ),
          _ResourceCard(
            title: isKorean ? 'Attention Is All You Need' : 'Attention Is All You Need',
            author: 'Vaswani et al.',
            type: isKorean ? '논문' : 'Paper',
            description: isKorean ? '트랜스포머 원본 논문 (2017)' : 'Original Transformer paper (2017)',
            url: 'https://arxiv.org/abs/1706.03762',
          ),
          _ResourceCard(
            title: isKorean ? '언어 모델은 퓨샷 학습자다' : 'Language Models are Few-Shot Learners',
            author: 'Brown et al. (OpenAI)',
            type: isKorean ? '논문' : 'Paper',
            description: isKorean ? 'GPT-3 논문, 인컨텍스트 학습 소개' : 'GPT-3 paper introducing in-context learning',
            url: 'https://arxiv.org/abs/2005.14165',
          ),
          _ResourceCard(
            title: isKorean ? 'CS231n: 시각 인식을 위한 CNN' : 'CS231n: CNNs for Visual Recognition',
            author: isKorean ? '스탠포드 대학교' : 'Stanford University',
            type: isKorean ? '강좌' : 'Course',
            description: isKorean ? '컴퓨터 비전 딥러닝 강좌' : 'Computer vision deep learning course',
            url: 'http://cs231n.stanford.edu/',
          ),
          _ResourceCard(
            title: isKorean ? 'CS224n: 딥러닝 NLP' : 'CS224n: NLP with Deep Learning',
            author: isKorean ? '스탠포드 대학교' : 'Stanford University',
            type: isKorean ? '강좌' : 'Course',
            description: isKorean ? '자연어 처리 강좌' : 'Natural language processing course',
            url: 'http://web.stanford.edu/class/cs224n/',
          ),
          _ResourceCard(
            title: isKorean ? '안드레이 카르파시 블로그' : 'Andrej Karpathy Blog',
            author: isKorean ? '안드레이 카르파시' : 'Andrej Karpathy',
            type: isKorean ? '블로그' : 'Blog',
            description: isKorean ? 'AI 연구자이자 전 Tesla AI 리드의 인사이트' : 'Insights from AI researcher and Tesla AI lead',
            url: 'https://karpathy.github.io/',
          ),
          _ResourceCard(
            title: 'Distill',
            author: isKorean ? '다양한 연구자' : 'Various Researchers',
            type: isKorean ? '저널' : 'Journal',
            description: isKorean ? 'ML 연구의 명확한 설명' : 'Clear explanations of ML research',
            url: 'https://distill.pub/',
          ),
          _ResourceCard(
            title: 'Papers With Code',
            author: isKorean ? '커뮤니티' : 'Community',
            type: isKorean ? '데이터베이스' : 'Database',
            description: isKorean ? '코드 구현이 포함된 ML 논문' : 'ML papers with code implementations',
            url: 'https://paperswithcode.com/',
          ),
          const SizedBox(height: 24),

          // ============================================
          // 카오스 이론 섹션
          // ============================================
          _SectionHeader(title: isKorean ? '카오스 이론' : 'Chaos Theory', icon: Icons.grain),
          _ResourceCard(
            title: isKorean ? '카오스: 새로운 과학의 탄생' : 'Chaos: Making a New Science',
            author: isKorean ? '제임스 글릭' : 'James Gleick',
            type: isKorean ? '도서' : 'Book',
            description: isKorean ? '카오스 이론의 고전적 입문서' : 'Classic introduction to chaos theory',
          ),
          _ResourceCard(
            title: isKorean ? '비선형 동역학과 카오스' : 'Nonlinear Dynamics and Chaos',
            author: isKorean ? '스티븐 스트로가츠' : 'Steven Strogatz',
            type: isKorean ? '대학 교재' : 'Textbook',
            description: isKorean ? '비선형 동역학 표준 교재' : 'Standard textbook for nonlinear dynamics',
          ),
          _ResourceCard(
            title: isKorean ? '동기화: 떠오르는 과학' : 'Sync: The Emerging Science',
            author: isKorean ? '스티븐 스트로가츠' : 'Steven Strogatz',
            type: isKorean ? '도서' : 'Book',
            description: isKorean ? '복잡계에서의 동기화' : 'Synchronization in complex systems',
          ),
          _ResourceCard(
            title: isKorean ? '자연의 프랙탈 기하학' : 'The Fractal Geometry of Nature',
            author: isKorean ? '브누아 만델브로' : 'Benoit Mandelbrot',
            type: isKorean ? '도서' : 'Book',
            description: isKorean ? '프랙탈에 대한 기초 저서' : 'Foundational work on fractals',
          ),
          const SizedBox(height: 24),

          // ============================================
          // 화학 섹션
          // ============================================
          _SectionHeader(title: isKorean ? '화학' : 'Chemistry', icon: Icons.science),
          _ResourceCard(
            title: isKorean ? '화학: 중심과학' : 'Chemistry: The Central Science',
            author: 'Brown, LeMay, Bursten',
            type: isKorean ? '대학 교재' : 'Textbook',
            description: isKorean ? '일반화학 표준 교재' : 'Standard general chemistry textbook',
          ),
          _ResourceCard(
            title: isKorean ? '유기화학' : 'Organic Chemistry',
            author: isKorean ? '조너선 클레이든' : 'Jonathan Clayden',
            type: isKorean ? '대학 교재' : 'Textbook',
            description: isKorean ? '종합 유기화학' : 'Comprehensive organic chemistry',
          ),
          _ResourceCard(
            title: isKorean ? '물리화학' : 'Physical Chemistry',
            author: isKorean ? '앳킨스 & 드 폴라' : 'Atkins & de Paula',
            type: isKorean ? '대학 교재' : 'Textbook',
            description: isKorean ? '물리화학 표준 참고서' : 'Standard physical chemistry reference',
          ),
          const SizedBox(height: 24),

          // ============================================
          // 생물학 섹션
          // ============================================
          _SectionHeader(title: isKorean ? '생물학' : 'Biology', icon: Icons.biotech),
          _ResourceCard(
            title: isKorean ? '세포의 분자생물학' : 'Molecular Biology of the Cell',
            author: 'Alberts et al.',
            type: isKorean ? '대학 교재' : 'Textbook',
            description: isKorean ? '종합 세포생물학 교재' : 'Comprehensive cell biology textbook',
          ),
          _ResourceCard(
            title: isKorean ? '이기적 유전자' : 'The Selfish Gene',
            author: isKorean ? '리처드 도킨스' : 'Richard Dawkins',
            type: isKorean ? '도서' : 'Book',
            description: isKorean ? '유전자 중심의 진화 관점' : 'Gene-centered view of evolution',
          ),
          _ResourceCard(
            title: isKorean ? '생명이란 무엇인가?' : 'What Is Life?',
            author: isKorean ? '에르빈 슈뢰딩거' : 'Erwin Schrödinger',
            type: isKorean ? '도서' : 'Book',
            description: isKorean ? '물리학자의 생명과 유전학에 대한 시각' : 'Physicist\'s view on life and genetics',
          ),
          const SizedBox(height: 24),

          // ============================================
          // 천문학 섹션
          // ============================================
          _SectionHeader(title: isKorean ? '천문학' : 'Astronomy', icon: Icons.rocket_launch),
          _ResourceCard(
            title: isKorean ? '시간의 역사' : 'A Brief History of Time',
            author: isKorean ? '스티븐 호킹' : 'Stephen Hawking',
            type: isKorean ? '도서' : 'Book',
            description: isKorean ? '일반인을 위한 우주론' : 'Cosmology for general audience',
          ),
          _ResourceCard(
            title: isKorean ? '코스모스' : 'Cosmos',
            author: isKorean ? '칼 세이건' : 'Carl Sagan',
            type: isKorean ? '도서' : 'Book',
            description: isKorean ? '우주를 향한 여행' : 'Journey through the universe',
          ),
          _ResourceCard(
            title: isKorean ? '바쁜 사람을 위한 천체물리학' : 'Astrophysics for People in a Hurry',
            author: isKorean ? '닐 디그래스 타이슨' : 'Neil deGrasse Tyson',
            type: isKorean ? '도서' : 'Book',
            description: isKorean ? '현대 천체물리학 빠른 투어' : 'Quick tour of modern astrophysics',
          ),
          _ResourceCard(
            title: isKorean ? 'NASA 과학' : 'NASA Science',
            author: 'NASA',
            type: isKorean ? '웹사이트' : 'Website',
            description: isKorean ? '우주 과학 뉴스와 발견' : 'Space science news and discoveries',
            url: 'https://science.nasa.gov/',
          ),
          const SizedBox(height: 24),

          // ============================================
          // 온라인 강의 플랫폼
          // ============================================
          _SectionHeader(title: isKorean ? '온라인 학습 플랫폼' : 'Online Learning Platforms', icon: Icons.school),
          _ResourceCard(
            title: isKorean ? 'MIT 공개강좌' : 'MIT OpenCourseWare',
            author: 'MIT',
            type: isKorean ? '플랫폼' : 'Platform',
            description: isKorean ? 'MIT 무료 강좌' : 'Free courses from MIT',
            url: 'https://ocw.mit.edu/',
          ),
          _ResourceCard(
            title: 'Coursera',
            author: isKorean ? '다양한 대학' : 'Various Universities',
            type: isKorean ? '플랫폼' : 'Platform',
            description: isKorean ? '온라인 대학 강좌' : 'University courses online',
            url: 'https://www.coursera.org/',
          ),
          _ResourceCard(
            title: 'edX',
            author: isKorean ? '하버드, MIT 등' : 'Harvard, MIT, etc.',
            type: isKorean ? '플랫폼' : 'Platform',
            description: isKorean ? '대학 수준 강좌' : 'University-level courses',
            url: 'https://www.edx.org/',
          ),
          _ResourceCard(
            title: 'Brilliant',
            author: 'Brilliant',
            type: isKorean ? '플랫폼' : 'Platform',
            description: isKorean ? '인터랙티브 수학 및 과학 학습' : 'Interactive math and science learning',
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
                  isKorean ? '웹 버전도 있어요!' : 'Try our Web Version!',
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
                  child: Text(isKorean ? '브라우저에서 열기' : 'Open in Browser'),
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
