import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

/// 시뮬레이션 카테고리
enum SimCategory {
  physics('물리학', Icons.speed, '역학, 파동, 전자기학', Color(0xFF4ECDC4)),
  math('수학', Icons.functions, '대수, 기하, 해석학', Color(0xFFFFE66D)),
  chemistry('화학', Icons.science, '원자, 분자, 반응', Color(0xFFFF6B6B)),
  ai('AI/ML', Icons.psychology, '머신러닝, 딥러닝', Color(0xFF95E1D3)),
  chaos('카오스', Icons.grain, '혼돈 이론, 프랙탈', Color(0xFFA8E6CF));

  final String label;
  final IconData icon;
  final String description;
  final Color color;
  const SimCategory(this.label, this.icon, this.description, this.color);
}

/// 시뮬레이션 메타데이터
class SimulationInfo {
  final String title;
  final String level;
  final String format;
  final String summary;
  final String simId;
  final SimCategory category;
  final int difficulty;

  const SimulationInfo({
    required this.title,
    required this.level,
    required this.format,
    required this.summary,
    required this.simId,
    required this.category,
    this.difficulty = 2,
  });
}

/// 시뮬레이션 목록
const List<SimulationInfo> allSimulations = [
  // 물리학
  SimulationInfo(
    title: "단진자 운동",
    level: "물리 엔진",
    format: "시뮬레이션",
    summary: "줄 길이와 중력에 따른 진자 운동을 시뮬레이션합니다.",
    simId: "pendulum",
    category: SimCategory.physics,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "이중 슬릿 간섭",
    level: "파동",
    format: "시뮬레이션",
    summary: "두 파원의 간섭 패턴을 관찰합니다.",
    simId: "wave",
    category: SimCategory.physics,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "이중 진자",
    level: "혼돈 역학",
    format: "시뮬레이션",
    summary: "카오스 이론을 보여주는 두 개의 연결된 진자.",
    simId: "double-pendulum",
    category: SimCategory.physics,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "발사체 운동",
    level: "역학",
    format: "시뮬레이션",
    summary: "각도와 속도에 따른 포물선 운동을 시뮬레이션합니다.",
    simId: "projectile",
    category: SimCategory.physics,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "스프링 체인",
    level: "역학",
    format: "시뮬레이션",
    summary: "연결된 스프링의 감쇠 조화 진동을 관찰합니다.",
    simId: "spring",
    category: SimCategory.physics,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "입자 충돌",
    level: "역학",
    format: "시뮬레이션",
    summary: "운동량과 에너지 보존 법칙을 통한 탄성/비탄성 충돌을 시각화합니다.",
    simId: "collision",
    category: SimCategory.physics,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "전기장 시각화",
    level: "전자기학",
    format: "인터랙티브",
    summary: "점전하 주변의 전기장과 전기력선을 시각화합니다.",
    simId: "electromagnetic",
    category: SimCategory.physics,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "콘웨이의 생명 게임",
    level: "셀룰러 오토마타",
    format: "시뮬레이션",
    summary: "세포가 생존, 탄생, 죽음의 규칙에 따라 진화합니다.",
    simId: "gameoflife",
    category: SimCategory.physics,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "도플러 효과",
    level: "파동",
    format: "시뮬레이션",
    summary: "음원의 이동에 따른 파장과 주파수 변화를 시각화합니다.",
    simId: "doppler",
    category: SimCategory.physics,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "이상기체 법칙",
    level: "열역학",
    format: "시뮬레이션",
    summary: "PV=nRT. 압력, 부피, 온도의 관계를 입자 시뮬레이션으로 탐구합니다.",
    simId: "ideal-gas",
    category: SimCategory.physics,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "스넬의 법칙",
    level: "광학",
    format: "시뮬레이션",
    summary: "굴절과 전반사를 시각화합니다. n₁sinθ₁ = n₂sinθ₂",
    simId: "snell",
    category: SimCategory.physics,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "브라운 운동",
    level: "열역학",
    format: "시뮬레이션",
    summary: "유체 분자의 무작위 충돌에 의한 입자의 불규칙 운동을 관찰합니다.",
    simId: "brownian",
    category: SimCategory.physics,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "정상파",
    level: "파동",
    format: "시뮬레이션",
    summary: "현의 고정단에서 반사되어 형성되는 정상파와 하모닉스를 시각화합니다.",
    simId: "standing-wave",
    category: SimCategory.physics,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "렌즈 광선 추적",
    level: "광학",
    format: "시뮬레이션",
    summary: "볼록/오목 렌즈를 통과하는 빛의 굴절과 상 형성을 시각화합니다.",
    simId: "lens",
    category: SimCategory.physics,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "구심력",
    level: "역학",
    format: "시뮬레이션",
    summary: "원운동하는 물체에 작용하는 구심력과 속도 벡터를 시각화합니다.",
    simId: "centripetal",
    category: SimCategory.physics,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "감쇠 진동자",
    level: "역학",
    format: "시뮬레이션",
    summary: "과소감쇠, 임계감쇠, 과대감쇠의 진동 특성을 비교합니다.",
    simId: "damped-oscillator",
    category: SimCategory.physics,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "마찰과 경사면",
    level: "역학",
    format: "시뮬레이션",
    summary: "경사면에서 마찰력과 중력의 상호작용을 시각화합니다.",
    simId: "friction",
    category: SimCategory.physics,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "Atwood 기계",
    level: "역학",
    format: "시뮬레이션",
    summary: "도르래에 연결된 두 질량의 가속도 운동을 탐구합니다.",
    simId: "atwood",
    category: SimCategory.physics,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "공명",
    level: "파동",
    format: "시뮬레이션",
    summary: "외력의 진동수가 고유 진동수와 같을 때 진폭이 최대가 되는 현상.",
    simId: "resonance",
    category: SimCategory.physics,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "소리 맥놀이",
    level: "파동",
    format: "시뮬레이션",
    summary: "비슷한 진동수의 두 음파 간섭으로 생기는 진폭 변화를 시각화합니다.",
    simId: "beats",
    category: SimCategory.physics,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "열전도",
    level: "열역학",
    format: "시뮬레이션",
    summary: "푸리에 법칙에 따른 열 전달과 온도 분포 변화를 시각화합니다.",
    simId: "heat-conduction",
    category: SimCategory.physics,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "롤러코스터",
    level: "역학",
    format: "시뮬레이션",
    summary: "역학적 에너지 보존: 위치 에너지 ↔ 운동 에너지 변환을 관찰합니다.",
    simId: "roller-coaster",
    category: SimCategory.physics,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "각운동량 보존",
    level: "역학",
    format: "시뮬레이션",
    summary: "피겨 스케이터가 팔을 오므리면 빠르게 회전하는 원리를 탐구합니다.",
    simId: "angular-momentum",
    category: SimCategory.physics,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "도르래 시스템",
    level: "역학",
    format: "시뮬레이션",
    summary: "도르래를 사용한 기계적 이점과 힘/거리 트레이드오프를 시각화합니다.",
    simId: "pulley",
    category: SimCategory.physics,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "탄성 충돌",
    level: "역학",
    format: "시뮬레이션",
    summary: "반발 계수에 따른 공의 튕김과 에너지 손실을 관찰합니다.",
    simId: "elastic-ball",
    category: SimCategory.physics,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "로켓 추진",
    level: "역학",
    format: "시뮬레이션",
    summary: "치올콥스키 방정식으로 로켓의 속도 변화를 시뮬레이션합니다.",
    simId: "rocket",
    category: SimCategory.physics,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "상전이",
    level: "열역학",
    format: "시뮬레이션",
    summary: "온도에 따른 물질의 상태 변화(고체/액체/기체)를 시각화합니다.",
    simId: "phase-transition",
    category: SimCategory.physics,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "중력장",
    level: "중력",
    format: "시뮬레이션",
    summary: "질량이 주변 공간에 만드는 중력장과 등전위선을 시각화합니다.",
    simId: "gravity-field",
    category: SimCategory.physics,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "파장과 스펙트럼",
    level: "파동",
    format: "시뮬레이션",
    summary: "전자기파 스펙트럼과 파장-주파수-에너지 관계를 탐구합니다.",
    simId: "wavelength",
    category: SimCategory.physics,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "물결파 간섭",
    level: "파동",
    format: "인터랙티브",
    summary: "터치하여 물결파를 생성하고 파동 간섭 현상을 관찰합니다.",
    simId: "ripple-wave",
    category: SimCategory.physics,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "시공간 곡률",
    level: "일반상대론",
    format: "시뮬레이션",
    summary: "아인슈타인 장방정식 Rμν - ½gμνR = 8πG/c⁴ Tμν을 시각화합니다.",
    simId: "spacetime-curvature",
    category: SimCategory.physics,
    difficulty: 3,
  ),

  // 수학
  SimulationInfo(
    title: "수식 그래프",
    level: "고등",
    format: "2D 그래프",
    summary: "수학 함수를 입력하면 실시간 그래프를 생성합니다.",
    simId: "formula",
    category: SimCategory.math,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "집합 연산",
    level: "이산수학",
    format: "인터랙티브",
    summary: "합집합, 교집합, 차집합을 벤다이어그램으로 시각화합니다.",
    simId: "set",
    category: SimCategory.math,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "Mandelbrot 집합",
    level: "프랙탈",
    format: "인터랙티브",
    summary: "zₙ₊₁ = zₙ² + c. 무한한 복잡성의 프랙탈을 탐험합니다.",
    simId: "mandelbrot",
    category: SimCategory.math,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "푸리에 변환",
    level: "신호처리",
    format: "시각화",
    summary: "복잡한 파형을 원운동(에피사이클)으로 분해합니다.",
    simId: "fourier",
    category: SimCategory.math,
    difficulty: 3,
  ),
  SimulationInfo(
    title: "이차함수 꼭짓점",
    level: "고등",
    format: "2D 그래프",
    summary: "a, b, c를 조정하고 꼭짓점 이동을 관찰합니다.",
    simId: "quadratic",
    category: SimCategory.math,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "벡터 내적 탐색기",
    level: "선형대수학",
    format: "2D 그래프",
    summary: "벡터의 내적, 각도, 투영을 시각화합니다.",
    simId: "vector",
    category: SimCategory.math,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "에라토스테네스의 체",
    level: "정수론",
    format: "알고리즘",
    summary: "고대 그리스의 소수 발견 알고리즘을 단계별로 시각화합니다.",
    simId: "prime",
    category: SimCategory.math,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "그래프 탐색",
    level: "그래프 이론",
    format: "알고리즘",
    summary: "BFS와 DFS로 그래프를 탐색하는 과정을 시각화합니다.",
    simId: "graph-theory",
    category: SimCategory.math,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "테일러 급수",
    level: "해석학",
    format: "시각화",
    summary: "함수를 무한 다항식으로 근사하는 테일러 전개를 시각화합니다.",
    simId: "taylor-series",
    category: SimCategory.math,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "몬테카를로 Pi",
    level: "확률",
    format: "시뮬레이션",
    summary: "무작위 점을 던져 원주율을 추정하는 확률적 방법을 체험합니다.",
    simId: "monte-carlo",
    category: SimCategory.math,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "파스칼 삼각형",
    level: "조합론",
    format: "시각화",
    summary: "이항계수와 조합의 패턴을 피라미드 형태로 시각화합니다.",
    simId: "pascal-triangle",
    category: SimCategory.math,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "갈톤 보드",
    level: "확률",
    format: "시뮬레이션",
    summary: "공이 핀 사이로 떨어지며 이항분포를 형성하는 과정을 관찰합니다.",
    simId: "galton-board",
    category: SimCategory.math,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "황금비",
    level: "기하학",
    format: "시각화",
    summary: "자연과 예술에서 발견되는 가장 아름다운 비율 φ를 탐구합니다.",
    simId: "golden-ratio",
    category: SimCategory.math,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "미분 시각화",
    level: "해석학",
    format: "시각화",
    summary: "할선이 접선으로 수렴하는 과정으로 미분의 개념을 이해합니다.",
    simId: "derivative",
    category: SimCategory.math,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "리만 합",
    level: "해석학",
    format: "시각화",
    summary: "사각형 넓이의 합으로 정적분을 근사하는 과정을 시각화합니다.",
    simId: "riemann-sum",
    category: SimCategory.math,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "극한 탐색기",
    level: "해석학",
    format: "인터랙티브",
    summary: "유명한 극한값들의 수렴 과정을 탐구합니다.",
    simId: "limit-explorer",
    category: SimCategory.math,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "원 정리",
    level: "기하학",
    format: "인터랙티브",
    summary: "원주각, 중심각, 접선 등 원에 관한 정리들을 시각화합니다.",
    simId: "circle-theorems",
    category: SimCategory.math,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "피타고라스 정리",
    level: "기하학",
    format: "시각화",
    summary: "직각삼각형의 세 변 관계를 다양한 증명법으로 보여줍니다.",
    simId: "pythagorean",
    category: SimCategory.math,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "원뿔 곡선",
    level: "기하학",
    format: "인터랙티브",
    summary: "원, 타원, 포물선, 쌍곡선의 특성과 이심률을 탐구합니다.",
    simId: "conic-sections",
    category: SimCategory.math,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "테셀레이션",
    level: "기하학",
    format: "시각화",
    summary: "정다각형으로 평면을 빈틈없이 채우는 패턴을 탐구합니다.",
    simId: "tessellation",
    category: SimCategory.math,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "중심극한정리",
    level: "확률",
    format: "시뮬레이션",
    summary: "표본평균이 정규분포로 수렴하는 중심극한정리를 체험합니다.",
    simId: "central-limit",
    category: SimCategory.math,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "정규분포",
    level: "확률",
    format: "시각화",
    summary: "가우시안 분포와 68-95-99.7 법칙을 시각화합니다.",
    simId: "normal-distribution",
    category: SimCategory.math,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "랜덤 워크",
    level: "확률",
    format: "시뮬레이션",
    summary: "무작위 걸음의 기대 거리와 확률적 특성을 탐구합니다.",
    simId: "random-walk",
    category: SimCategory.math,
    difficulty: 1,
  ),

  // 밀레니엄 난제
  SimulationInfo(
    title: "리만 가설",
    level: "밀레니엄",
    format: "시뮬레이션",
    summary: "리만 제타 함수의 비자명 영점이 모두 Re(s)=½ 위에 존재한다는 가설.",
    simId: "riemann-hypothesis",
    category: SimCategory.math,
    difficulty: 3,
  ),
  SimulationInfo(
    title: "P vs NP",
    level: "밀레니엄",
    format: "인터랙티브",
    summary: "다항 시간에 검증 가능한 문제가 다항 시간에 풀 수 있는가?",
    simId: "p-vs-np",
    category: SimCategory.math,
    difficulty: 3,
  ),
  SimulationInfo(
    title: "나비에-스토크스",
    level: "밀레니엄",
    format: "시뮬레이션",
    summary: "유체 역학의 근본 방정식. 해의 존재성과 매끄러움 문제.",
    simId: "navier-stokes",
    category: SimCategory.math,
    difficulty: 3,
  ),
  SimulationInfo(
    title: "푸앵카레 추측",
    level: "밀레니엄",
    format: "시뮬레이션",
    summary: "단순 연결된 3차원 다양체는 3차원 구와 위상동형. (2003년 해결)",
    simId: "poincare",
    category: SimCategory.math,
    difficulty: 3,
  ),

  // 카오스
  SimulationInfo(
    title: "로렌츠 어트랙터",
    level: "혼돈 이론",
    format: "3D 그래프",
    summary: "나비 효과를 시각화하는 혼돈 시스템.",
    simId: "lorenz",
    category: SimCategory.chaos,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "로지스틱 맵",
    level: "혼돈 이론",
    format: "시각화",
    summary: "분기 다이어그램과 페이겐바움 상수를 통해 카오스의 시작을 관찰합니다.",
    simId: "logistic",
    category: SimCategory.chaos,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "3체 문제",
    level: "혼돈 역학",
    format: "시뮬레이션",
    summary: "3개 천체의 중력 상호작용 - 해석적 해가 없는 혼돈 시스템.",
    simId: "threebody",
    category: SimCategory.chaos,
    difficulty: 3,
  ),

  // AI/ML
  SimulationInfo(
    title: "정렬 알고리즘",
    level: "알고리즘",
    format: "애니메이션",
    summary: "버블, 퀵, 병합 정렬의 동작 과정을 단계별로 비교합니다.",
    simId: "sorting",
    category: SimCategory.ai,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "신경망 플레이그라운드",
    level: "딥러닝",
    format: "인터랙티브",
    summary: "신경망의 순전파와 역전파, 가중치 학습 과정을 시각화합니다.",
    simId: "neuralnet",
    category: SimCategory.ai,
    difficulty: 3,
  ),
  SimulationInfo(
    title: "경사 하강법",
    level: "최적화",
    format: "시각화",
    summary: "손실 함수를 최소화하는 경사 하강법의 수렴 과정을 시각화합니다.",
    simId: "gradient",
    category: SimCategory.ai,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "활성화 함수",
    level: "딥러닝",
    format: "시각화",
    summary: "ReLU, Sigmoid, GELU 등 신경망 활성화 함수를 비교합니다.",
    simId: "activation",
    category: SimCategory.ai,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "K-Means 클러스터링",
    level: "머신러닝",
    format: "인터랙티브",
    summary: "비지도 학습으로 데이터를 K개 군집으로 분류하는 과정을 시각화합니다.",
    simId: "kmeans",
    category: SimCategory.ai,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "결정 트리",
    level: "머신러닝",
    format: "인터랙티브",
    summary: "지니 불순도를 최소화하며 데이터를 분할하는 분류 알고리즘.",
    simId: "decision-tree",
    category: SimCategory.ai,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "SVM 분류기",
    level: "머신러닝",
    format: "인터랙티브",
    summary: "최대 마진을 갖는 결정 경계를 찾는 서포트 벡터 머신.",
    simId: "svm",
    category: SimCategory.ai,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "PCA 주성분 분석",
    level: "머신러닝",
    format: "시각화",
    summary: "분산을 최대화하는 방향을 찾아 차원을 축소하는 기법.",
    simId: "pca",
    category: SimCategory.ai,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "선형 회귀",
    level: "머신러닝",
    format: "인터랙티브",
    summary: "경사 하강법으로 데이터에 가장 잘 맞는 직선을 찾습니다.",
    simId: "linear-regression",
    category: SimCategory.ai,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "K-최근접 이웃",
    level: "머신러닝",
    format: "인터랙티브",
    summary: "가장 가까운 K개의 이웃으로 새 데이터를 분류합니다.",
    simId: "knn",
    category: SimCategory.ai,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "퍼셉트론",
    level: "딥러닝",
    format: "인터랙티브",
    summary: "가장 간단한 인공 신경망의 기본 단위를 학습시킵니다.",
    simId: "perceptron",
    category: SimCategory.ai,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "A* 경로 탐색",
    level: "알고리즘",
    format: "인터랙티브",
    summary: "휴리스틱을 사용한 최적 경로 탐색 알고리즘을 시각화합니다.",
    simId: "astar",
    category: SimCategory.ai,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "유전 알고리즘",
    level: "최적화",
    format: "시뮬레이션",
    summary: "자연선택과 돌연변이로 최적해를 찾는 진화 알고리즘.",
    simId: "genetic",
    category: SimCategory.ai,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "드롭아웃",
    level: "딥러닝",
    format: "시각화",
    summary: "과적합 방지를 위해 학습 시 뉴런을 랜덤하게 비활성화합니다.",
    simId: "dropout",
    category: SimCategory.ai,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "손실 함수 비교",
    level: "딥러닝",
    format: "시각화",
    summary: "MSE, MAE, Cross-Entropy 등 다양한 손실 함수를 비교합니다.",
    simId: "loss-functions",
    category: SimCategory.ai,
    difficulty: 2,
  ),

  // 화학
  SimulationInfo(
    title: "보어 원자 모델",
    level: "원자 구조",
    format: "시뮬레이션",
    summary: "전자가 특정 에너지 준위에서만 존재하는 보어의 원자 모델을 시각화합니다.",
    simId: "bohr-model",
    category: SimCategory.chemistry,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "전자 배치",
    level: "원자 구조",
    format: "인터랙티브",
    summary: "Aufbau 원리에 따른 전자 오비탈 채움과 전자 배치를 시각화합니다.",
    simId: "electron-config",
    category: SimCategory.chemistry,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "주기율표 탐색기",
    level: "원소",
    format: "인터랙티브",
    summary: "118개 원소의 특성, 전자배치, 물리적 성질을 탐색합니다.",
    simId: "periodic-table",
    category: SimCategory.chemistry,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "화학 반응식 균형",
    level: "화학량론",
    format: "게임",
    summary: "질량 보존 법칙에 따라 화학 반응식의 계수를 맞추는 연습입니다.",
    simId: "equation-balance",
    category: SimCategory.chemistry,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "반응 속도론",
    level: "동역학",
    format: "시뮬레이션",
    summary: "Arrhenius 방정식과 반응 차수에 따른 농도 변화를 시각화합니다.",
    simId: "reaction-kinetics",
    category: SimCategory.chemistry,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "pH 스케일",
    level: "산-염기",
    format: "인터랙티브",
    summary: "pH와 수소이온 농도의 관계를 다양한 용액으로 탐구합니다.",
    simId: "ph-scale",
    category: SimCategory.chemistry,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "분자 기하학 (VSEPR)",
    level: "결합",
    format: "3D 시각화",
    summary: "전자쌍 반발 이론에 따른 분자 구조를 3D로 시각화합니다.",
    simId: "molecular-geometry",
    category: SimCategory.chemistry,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "화학 결합",
    level: "결합",
    format: "시뮬레이션",
    summary: "이온 결합과 공유 결합의 형성 과정을 애니메이션으로 보여줍니다.",
    simId: "chemical-bonding",
    category: SimCategory.chemistry,
    difficulty: 1,
  ),
  SimulationInfo(
    title: "루이스 구조",
    level: "결합",
    format: "인터랙티브",
    summary: "원자가 전자와 공유 결합을 점으로 표시하는 분자 표현법입니다.",
    simId: "lewis-structure",
    category: SimCategory.chemistry,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "수소 결합",
    level: "분자간 힘",
    format: "시뮬레이션",
    summary: "물 분자, DNA, 단백질에서의 수소 결합을 시각화합니다.",
    simId: "hydrogen-bonding",
    category: SimCategory.chemistry,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "산화-환원 반응",
    level: "전기화학",
    format: "시뮬레이션",
    summary: "전자 이동과 산화수 변화를 다양한 예시로 시각화합니다.",
    simId: "oxidation-reduction",
    category: SimCategory.chemistry,
    difficulty: 2,
  ),
  SimulationInfo(
    title: "적정 곡선",
    level: "산-염기",
    format: "시뮬레이션",
    summary: "산-염기 적정의 pH 변화와 당량점을 시각화합니다.",
    simId: "titration",
    category: SimCategory.chemistry,
    difficulty: 2,
  ),
];

/// 시뮬레이션 탭 - 카테고리 그리드 + 검색
class SimulationsTab extends StatefulWidget {
  const SimulationsTab({super.key});

  @override
  State<SimulationsTab> createState() => _SimulationsTabState();
}

class _SimulationsTabState extends State<SimulationsTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // 헤더
        SliverAppBar(
          expandedHeight: 160,
          floating: false,
          pinned: true,
          backgroundColor: AppColors.bg.withValues(alpha: 0.95),
          flexibleSpace: FlexibleSpaceBar(
            title: const Text(
              '3DWeb Science Lab',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            background: Stack(
              children: [
                AnimatedBuilder(
                  animation: _particleController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _ParticlePainter(
                        animation: _particleController.value,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.accent.withValues(alpha: 0.05),
                        AppColors.bg,
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        '손끝으로 느끼는',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '우주의 법칙',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 통계
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatCard(
                  number: '${allSimulations.length}+',
                  label: '시뮬레이션',
                  icon: Icons.science,
                ),
                _StatCard(
                  number: '${SimCategory.values.length}',
                  label: '카테고리',
                  icon: Icons.category,
                ),
                _StatCard(
                  number: '무료',
                  label: '모두 무료',
                  icon: Icons.card_giftcard,
                ),
              ],
            ),
          ),
        ),

        // 섹션 타이틀
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              '카테고리 선택',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // 카테고리 그리드
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final category = SimCategory.values[index];
                final count = allSimulations
                    .where((s) => s.category == category)
                    .length;
                return _CategoryCard(
                  category: category,
                  simulationCount: count,
                  onTap: () => _openCategory(context, category),
                );
              },
              childCount: SimCategory.values.length,
            ),
          ),
        ),

        // 전체 보기 버튼
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () => _openAllSimulations(context),
              icon: const Icon(Icons.list),
              label: const Text('전체 시뮬레이션 보기'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: BorderSide(color: AppColors.accent),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  void _openCategory(BuildContext context, SimCategory category) {
    HapticFeedback.lightImpact();
    context.push('/category/${category.name}');
  }

  void _openAllSimulations(BuildContext context) {
    HapticFeedback.lightImpact();
    context.push('/category/all');
  }
}

class _StatCard extends StatelessWidget {
  final String number;
  final String label;
  final IconData icon;

  const _StatCard({
    required this.number,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accent, size: 20),
          const SizedBox(height: 4),
          Text(
            number,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final SimCategory category;
  final int simulationCount;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.simulationCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      category.icon,
                      color: category.color,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$simulationCount개',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                category.label,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                category.description,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                ),
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

class _ParticlePainter extends CustomPainter {
  final double animation;

  _ParticlePainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(42);

    for (int i = 0; i < 30; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final speed = 0.2 + random.nextDouble() * 0.3;
      final radius = 1.0 + random.nextDouble() * 2;

      final y = (baseY - animation * size.height * speed) % size.height;
      final opacity = 0.1 + 0.1 * math.sin(animation * math.pi * 2 + i);
      paint.color = AppColors.accent.withValues(alpha: opacity);

      canvas.drawCircle(Offset(baseX, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
