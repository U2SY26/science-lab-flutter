// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '눈으로 보는 과학';

  @override
  String get appSubtitle1 => '손끝으로 느끼는';

  @override
  String get appSubtitle2 => '우주의 법칙';

  @override
  String get categoryAll => '전체';

  @override
  String get categoryPhysics => '물리';

  @override
  String get categoryMath => '수학';

  @override
  String get categoryChaos => '혼돈';

  @override
  String get categoryAI => 'AI/ML';

  @override
  String get categoryChemistry => '화학';

  @override
  String get simulations => '시뮬레이션';

  @override
  String get completed => '완료';

  @override
  String get favorites => '즐겨찾기';

  @override
  String results(int count) {
    return '$count개 결과';
  }

  @override
  String get searchSimulations => '시뮬레이션 검색...';

  @override
  String get settings => '설정';

  @override
  String get removeAds => '광고 제거';

  @override
  String monthlyPrice(String price) {
    return '월 $price';
  }

  @override
  String get resetProgress => '학습 기록 초기화';

  @override
  String get appInfo => '앱 정보';

  @override
  String get start => '시작하기';

  @override
  String get pressAgainToExit => '한 번 더 누르면 앱을 종료합니다';

  @override
  String get introTitle => '눈으로 보는 과학';

  @override
  String get introDescription => '과학과 수학의 원리를 인터랙티브 시뮬레이션으로 배워보세요!';

  @override
  String get continuousUpdates => '지속적인 업데이트';

  @override
  String get continuousUpdatesDesc => '새로운 시뮬레이션과 기능이 계속 추가됩니다.';

  @override
  String get webVersionAvailable => '웹 버전도 있어요!';

  @override
  String get run => '실행';

  @override
  String get stop => '정지';

  @override
  String get reset => '초기화';

  @override
  String get pause => '일시정지';

  @override
  String get resume => '재개';

  @override
  String get simPendulum => '단진자 운동';

  @override
  String get simPendulumLevel => '물리 엔진';

  @override
  String get simPendulumFormat => '시뮬레이션';

  @override
  String get simPendulumSummary => '줄 길이와 중력 가속도에 따른 진자 주기의 관계를 탐구합니다.';

  @override
  String get simWave => '이중 슬릿 간섭';

  @override
  String get simWaveLevel => '파동 물리';

  @override
  String get simWaveFormat => '시뮬레이션';

  @override
  String get simWaveSummary => '두 개의 결맞는 파원에서 발생하는 보강·상쇄 간섭 패턴을 관찰합니다.';

  @override
  String get simGravity => '시공간 곡률';

  @override
  String get simGravityLevel => '일반상대성이론';

  @override
  String get simGravityFormat => '3D 시뮬레이션';

  @override
  String get simGravitySummary => '질량에 의한 시공간 휨을 인터랙티브 3D 그리드로 시각화합니다.';

  @override
  String get simFormula => '수식 그래프';

  @override
  String get simFormulaLevel => '고등';

  @override
  String get simFormulaFormat => '2D 그래프';

  @override
  String get simFormulaSummary => '수학 함수를 입력하면 실시간 그래프를 즉시 생성합니다.';

  @override
  String get simLorenz => '로렌츠 어트랙터';

  @override
  String get simLorenzLevel => '혼돈 이론';

  @override
  String get simLorenzFormat => '3D 그래프';

  @override
  String get simLorenzSummary => '나비 효과를 시각화하는 고전적인 로렌츠 혼돈 끌개입니다.';

  @override
  String get simDoublePendulum => '이중 진자';

  @override
  String get simDoublePendulumLevel => '혼돈 역학';

  @override
  String get simDoublePendulumFormat => '시뮬레이션';

  @override
  String get simDoublePendulumSummary => '초기 조건에 극도로 민감한 두 개의 연결된 진자입니다.';

  @override
  String get simGameOfLife => '콘웨이의 생명 게임';

  @override
  String get simGameOfLifeLevel => '셀룰러 오토마타';

  @override
  String get simGameOfLifeFormat => '시뮬레이션';

  @override
  String get simGameOfLifeSummary => '단순한 규칙에서 복잡한 창발 행동이 나타나는 세포 자동자입니다.';

  @override
  String get simSet => '집합 연산';

  @override
  String get simSetLevel => '이산수학';

  @override
  String get simSetFormat => '인터랙티브';

  @override
  String get simSetSummary => '인터랙티브 벤 다이어그램으로 합집합, 교집합, 차집합을 시각화합니다.';

  @override
  String get simSorting => '정렬 알고리즘';

  @override
  String get simSortingLevel => '알고리즘';

  @override
  String get simSortingFormat => '애니메이션';

  @override
  String get simSortingSummary => '버블, 퀵, 병합 정렬을 막대 애니메이션으로 단계별 비교합니다.';

  @override
  String get simNeuralNet => '신경망 플레이그라운드';

  @override
  String get simNeuralNetLevel => '딥러닝';

  @override
  String get simNeuralNetFormat => '인터랙티브';

  @override
  String get simNeuralNetSummary => '신경망을 직접 훈련하며 순전파, 역전파, 가중치 업데이트를 관찰합니다.';

  @override
  String get simGradient => '경사 하강법';

  @override
  String get simGradientLevel => '최적화';

  @override
  String get simGradientFormat => '시각화';

  @override
  String get simGradientSummary =>
      '손실 함수의 지형을 탐색하여 최솟값을 찾는 경사 하강법을 단계별로 관찰합니다.';

  @override
  String get simMandelbrot => '만델브로트 집합';

  @override
  String get simMandelbrotLevel => '프랙탈';

  @override
  String get simMandelbrotFormat => '인터랙티브';

  @override
  String get simMandelbrotSummary =>
      '무한한 복잡성의 만델브로트 집합 경계를 탐험합니다: zₙ₊₁ = zₙ² + c';

  @override
  String get simFourier => '푸리에 변환';

  @override
  String get simFourierLevel => '신호처리';

  @override
  String get simFourierFormat => '시각화';

  @override
  String get simFourierSummary => '복잡한 파형을 원운동(에피사이클)의 합으로 분해합니다.';

  @override
  String get simQuadratic => '이차함수 탐색기';

  @override
  String get simQuadraticLevel => '고등';

  @override
  String get simQuadraticFormat => '2D 그래프';

  @override
  String get simQuadraticSummary => '계수 a, b, c를 조정하며 꼭짓점과 근이 변하는 것을 관찰합니다.';

  @override
  String get simVector => '벡터 내적 탐색기';

  @override
  String get simVectorLevel => '선형대수학';

  @override
  String get simVectorFormat => '2D 그래프';

  @override
  String get simVectorSummary => '2D 벡터의 내적, 각도, 투영을 인터랙티브하게 시각화합니다.';

  @override
  String get simProjectile => '발사체 운동';

  @override
  String get simProjectileLevel => '역학';

  @override
  String get simProjectileFormat => '시뮬레이션';

  @override
  String get simProjectileSummary => '발사 각도와 초기 속도를 조정하여 포물선 궤적을 시뮬레이션합니다.';

  @override
  String get simSpring => '스프링 체인';

  @override
  String get simSpringLevel => '역학';

  @override
  String get simSpringFormat => '시뮬레이션';

  @override
  String get simSpringSummary => '연결된 스프링들의 감쇠 조화 진동을 관찰합니다.';

  @override
  String get simActivation => '활성화 함수';

  @override
  String get simActivationLevel => '딥러닝';

  @override
  String get simActivationFormat => '시각화';

  @override
  String get simActivationSummary =>
      'ReLU, Sigmoid, Tanh, GELU 등 다양한 신경망 활성화 함수를 비교합니다.';

  @override
  String get simLogistic => '로지스틱 맵';

  @override
  String get simLogisticLevel => '혼돈 이론';

  @override
  String get simLogisticFormat => '시각화';

  @override
  String get simLogisticSummary =>
      '분기 다이어그램과 페이겐바움 상수를 통해 주기 배가를 거쳐 카오스로 가는 경로를 관찰합니다.';

  @override
  String get simCollision => '입자 충돌';

  @override
  String get simCollisionLevel => '역학';

  @override
  String get simCollisionFormat => '시뮬레이션';

  @override
  String get simCollisionSummary => '운동량과 에너지 보존 법칙에 따른 탄성·비탄성 충돌을 시각화합니다.';

  @override
  String get simKMeans => 'K-Means 클러스터링';

  @override
  String get simKMeansLevel => '머신러닝';

  @override
  String get simKMeansFormat => '인터랙티브';

  @override
  String get simKMeansSummary =>
      '비지도 학습이 반복적인 중심점 업데이트로 데이터를 K개 군집으로 분류하는 과정을 관찰합니다.';

  @override
  String get simPrime => '에라토스테네스의 체';

  @override
  String get simPrimeLevel => '정수론';

  @override
  String get simPrimeFormat => '알고리즘';

  @override
  String get simPrimeSummary => '배수를 단계별로 제거하는 고대 소수 탐색 알고리즘을 시각화합니다.';

  @override
  String get simThreeBody => '3체 문제';

  @override
  String get simThreeBodyLevel => '혼돈 역학';

  @override
  String get simThreeBodyFormat => '시뮬레이션';

  @override
  String get simThreeBodySummary => '세 천체의 중력 상호작용 — 닫힌 형식의 해가 없는 혼돈 시스템입니다.';

  @override
  String get simDecisionTree => '결정 트리';

  @override
  String get simDecisionTreeLevel => '머신러닝';

  @override
  String get simDecisionTreeFormat => '인터랙티브';

  @override
  String get simDecisionTreeSummary =>
      '지니 불순도를 최소화하며 데이터를 재귀적으로 분할하는 분류 알고리즘입니다.';

  @override
  String get simSVM => 'SVM 분류기';

  @override
  String get simSVMLevel => '머신러닝';

  @override
  String get simSVMFormat => '인터랙티브';

  @override
  String get simSVMSummary => '클래스 사이에 최대 마진 결정 경계를 찾는 서포트 벡터 머신입니다.';

  @override
  String get simPCA => '주성분 분석 (PCA)';

  @override
  String get simPCALevel => '머신러닝';

  @override
  String get simPCAFormat => '시각화';

  @override
  String get simPCASummary => '최대 분산 방향으로 데이터를 투영하여 차원을 축소합니다.';

  @override
  String get simElectromagnetic => '전기장 시각화';

  @override
  String get simElectromagneticLevel => '전자기학';

  @override
  String get simElectromagneticFormat => '인터랙티브';

  @override
  String get simElectromagneticSummary => '점전하 주변의 전기장 벡터와 전기력선을 시각화합니다.';

  @override
  String get simGraphTheory => '그래프 탐색';

  @override
  String get simGraphTheoryLevel => '그래프 이론';

  @override
  String get simGraphTheoryFormat => '알고리즘';

  @override
  String get simGraphTheorySummary =>
      '너비 우선 탐색(BFS)과 깊이 우선 탐색(DFS)을 그래프에서 시각화합니다.';

  @override
  String get simBohrModel => '보어 원자 모형';

  @override
  String get simBohrModelLevel => '원자 물리';

  @override
  String get simBohrModelFormat => '인터랙티브';

  @override
  String get simBohrModelSummary => '원자에서 양자화된 전자 궤도와 에너지 준위 전이를 시각화합니다.';

  @override
  String get simChemicalBonding => '화학 결합';

  @override
  String get simChemicalBondingLevel => '화학';

  @override
  String get simChemicalBondingFormat => '인터랙티브';

  @override
  String get simChemicalBondingSummary => '이온 결합, 공유 결합, 금속 결합의 종류와 특성을 탐구합니다.';

  @override
  String get simElectronConfig => '전자 배치';

  @override
  String get simElectronConfigLevel => '화학';

  @override
  String get simElectronConfigFormat => '인터랙티브';

  @override
  String get simElectronConfigSummary =>
      '쌓음 원리에 따른 전자 오비탈 채움 순서와 원소별 전자 배치를 학습합니다.';

  @override
  String get simEquationBalance => '화학 반응식 균형 맞추기';

  @override
  String get simEquationBalanceLevel => '화학';

  @override
  String get simEquationBalanceFormat => '인터랙티브';

  @override
  String get simEquationBalanceSummary =>
      '질량 보존 법칙을 이용하여 화학 반응식 균형 맞추기를 단계별로 연습합니다.';

  @override
  String get simHydrogenBonding => '수소 결합';

  @override
  String get simHydrogenBondingLevel => '화학';

  @override
  String get simHydrogenBondingFormat => '시각화';

  @override
  String get simHydrogenBondingSummary => '수소 결합과 물의 이상 특성에 미치는 역할을 이해합니다.';

  @override
  String get simLewisStructure => '루이스 점 구조';

  @override
  String get simLewisStructureLevel => '화학';

  @override
  String get simLewisStructureFormat => '인터랙티브';

  @override
  String get simLewisStructureSummary =>
      '분자의 원자가 전자를 나타내는 루이스 점 구조를 그리고 해석합니다.';

  @override
  String get simMolecularGeometry => '분자 기하학 (VSEPR)';

  @override
  String get simMolecularGeometryLevel => '화학';

  @override
  String get simMolecularGeometryFormat => '3D 시각화';

  @override
  String get simMolecularGeometrySummary =>
      '다양한 전자쌍 기하에 대해 VSEPR 이론으로 3D 분자 모양을 예측합니다.';

  @override
  String get simOxidationReduction => '산화-환원 반응';

  @override
  String get simOxidationReductionLevel => '화학';

  @override
  String get simOxidationReductionFormat => '인터랙티브';

  @override
  String get simOxidationReductionSummary =>
      '산화환원 반응에서 산화제와 환원제 사이의 전자 이동을 추적합니다.';

  @override
  String get simAStar => 'A* 경로 탐색';

  @override
  String get simAStarLevel => '알고리즘';

  @override
  String get simAStarFormat => '인터랙티브';

  @override
  String get simAStarSummary => '허용 가능한 휴리스틱을 사용한 A* 탐색 알고리즘으로 최적 경로를 찾습니다.';

  @override
  String get simSimpleHarmonic => '단순 조화 운동';

  @override
  String get simSimpleHarmonicLevel => '역학';

  @override
  String get simSimpleHarmonicFormat => '인터랙티브';

  @override
  String get simSimpleHarmonicSummary =>
      '질량-용수철 시스템의 진동 운동: 시간에 따른 위치, 속도, 에너지를 탐구합니다. x(t) = A·cos(ωt + φ)';

  @override
  String get simCoupledOscillators => '결합 진동자';

  @override
  String get simCoupledOscillatorsLevel => '대학 물리';

  @override
  String get simCoupledOscillatorsFormat => '인터랙티브';

  @override
  String get simCoupledOscillatorsSummary =>
      '스프링으로 연결된 두 질량 사이의 정규 모드와 에너지 교환을 시각화합니다.';

  @override
  String get simGyroscope => '자이로스코프 세차 운동';

  @override
  String get simGyroscopeLevel => '대학 물리';

  @override
  String get simGyroscopeFormat => '인터랙티브';

  @override
  String get simGyroscopeSummary =>
      '중력 토크 아래에서 회전하는 자이로스코프의 세차 운동을 관찰합니다. Ω = τ/L';

  @override
  String get simBallisticPendulum => '탄도 진자';

  @override
  String get simBallisticPendulumLevel => '역학';

  @override
  String get simBallisticPendulumFormat => '인터랙티브';

  @override
  String get simBallisticPendulumSummary =>
      '운동량 보존과 에너지 보존을 결합하여 발사체의 속도를 측정합니다.';

  @override
  String get simGameTheory => '내시 균형';

  @override
  String get simGameTheoryLevel => '게임 이론';

  @override
  String get simGameTheoryFormat => '인터랙티브';

  @override
  String get simGameTheorySummary => '보수 행렬을 이용한 2인 전략 게임에서 내시 균형을 찾습니다.';

  @override
  String get simPrisonersDilemma => '죄수의 딜레마';

  @override
  String get simPrisonersDilemmaLevel => '게임 이론';

  @override
  String get simPrisonersDilemmaFormat => '인터랙티브';

  @override
  String get simPrisonersDilemmaSummary =>
      '팃포탯(Tit-for-Tat) 등 다양한 전략으로 반복 죄수의 딜레마 토너먼트를 시뮬레이션합니다.';

  @override
  String get simLinearProgramming => '선형 계획법';

  @override
  String get simLinearProgrammingLevel => '경영과학';

  @override
  String get simLinearProgrammingFormat => '인터랙티브';

  @override
  String get simLinearProgrammingSummary =>
      '선형 계획 문제의 실행 가능 영역을 시각화하고 그래프로 최적해를 찾습니다.';

  @override
  String get simSimplexMethod => '심플렉스 알고리즘';

  @override
  String get simSimplexMethodLevel => '경영과학';

  @override
  String get simSimplexMethodFormat => '인터랙티브';

  @override
  String get simSimplexMethodSummary => '심플렉스 방법 태블로를 단계별로 실행하여 선형 계획 문제를 풉니다.';

  @override
  String get simNaiveBayes => '나이브 베이즈 분류기';

  @override
  String get simNaiveBayesLevel => '머신러닝';

  @override
  String get simNaiveBayesFormat => '인터랙티브';

  @override
  String get simNaiveBayesSummary =>
      '조건부 독립 가정과 베이즈 정리를 이용하여 데이터를 분류합니다. P(C|X) ∝ P(X|C)·P(C)';

  @override
  String get simRandomForest => '랜덤 포레스트';

  @override
  String get simRandomForestLevel => '머신러닝';

  @override
  String get simRandomForestFormat => '인터랙티브';

  @override
  String get simRandomForestSummary =>
      '여러 결정 트리의 앙상블 투표로 강건한 분류기를 구성하는 과정을 시각화합니다.';

  @override
  String get simGradientBoosting => '그래디언트 부스팅';

  @override
  String get simGradientBoostingLevel => '머신러닝';

  @override
  String get simGradientBoostingFormat => '인터랙티브';

  @override
  String get simGradientBoostingSummary =>
      '약한 모델의 잔차를 반복적으로 수정하여 강한 학습기를 구축하는 부스팅 과정을 관찰합니다.';

  @override
  String get simLogisticRegression => '로지스틱 회귀';

  @override
  String get simLogisticRegressionLevel => '머신러닝';

  @override
  String get simLogisticRegressionFormat => '인터랙티브';

  @override
  String get simLogisticRegressionSummary =>
      '이진 분류를 위한 시그모이드 결정 경계를 학습합니다. σ(z) = 1/(1+e⁻ᶻ)';

  @override
  String get simQuantumTeleportation => '양자 텔레포테이션';

  @override
  String get simQuantumTeleportationLevel => '양자 컴퓨팅';

  @override
  String get simQuantumTeleportationFormat => '인터랙티브';

  @override
  String get simQuantumTeleportationSummary =>
      '얽힌 큐비트를 통해 양자 상태를 전송하는 양자 텔레포테이션 프로토콜을 시뮬레이션합니다.';

  @override
  String get simQuantumErrorCorrection => '양자 오류 정정';

  @override
  String get simQuantumErrorCorrectionLevel => '양자 컴퓨팅';

  @override
  String get simQuantumErrorCorrectionFormat => '인터랙티브';

  @override
  String get simQuantumErrorCorrectionSummary =>
      '결어긋남과 오류로부터 양자 정보를 보호하는 안정화 코드를 탐구합니다.';

  @override
  String get simGroverAlgorithm => '그로버 양자 탐색';

  @override
  String get simGroverAlgorithmLevel => '양자 컴퓨팅';

  @override
  String get simGroverAlgorithmFormat => '인터랙티브';

  @override
  String get simGroverAlgorithmSummary =>
      '그로버의 O(√N) 양자 탐색 알고리즘에서 진폭 증폭을 시각화합니다.';

  @override
  String get simShorAlgorithm => '쇼어 소인수분해 알고리즘';

  @override
  String get simShorAlgorithmLevel => '양자 컴퓨팅';

  @override
  String get simShorAlgorithmFormat => '인터랙티브';

  @override
  String get simShorAlgorithmSummary =>
      '정수 소인수분해의 지수적 가속을 가능하게 하는 양자 주기 탐색을 이해합니다.';

  @override
  String get simGasLaws => '기체 법칙';

  @override
  String get simGasLawsLevel => '화학';

  @override
  String get simGasLawsFormat => '인터랙티브';

  @override
  String get simGasLawsSummary =>
      '인터랙티브 PVT 제어로 보일 법칙, 샤를 법칙, 이상기체 법칙을 탐구합니다. PV = nRT';

  @override
  String get simDaltonLaw => '달턴의 분압 법칙';

  @override
  String get simDaltonLawLevel => '화학';

  @override
  String get simDaltonLawFormat => '인터랙티브';

  @override
  String get simDaltonLawSummary =>
      '기체 혼합물의 분압이 전체 압력으로 합산되는 과정을 시각화합니다. P_총 = P₁ + P₂ + ... + Pₙ';

  @override
  String get simColligativeProperties => '총괄성';

  @override
  String get simColligativePropertiesLevel => '물리화학';

  @override
  String get simColligativePropertiesFormat => '인터랙티브';

  @override
  String get simColligativePropertiesSummary =>
      '용질 입자가 용액의 끓는점 오름과 어는점 내림을 일으키는 현상을 관찰합니다. ΔT = K·m·i';

  @override
  String get simSolubilityCurve => '용해도 곡선';

  @override
  String get simSolubilityCurveLevel => '화학';

  @override
  String get simSolubilityCurveFormat => '인터랙티브';

  @override
  String get simSolubilityCurveSummary => '다양한 물질의 용해도가 온도에 따라 변하는 것을 탐구합니다.';

  @override
  String get simProperTime => '고유 시간과 세계선';

  @override
  String get simProperTimeLevel => '특수 상대성이론';

  @override
  String get simProperTimeFormat => '인터랙티브';

  @override
  String get simProperTimeSummary =>
      '시공간 다이어그램에 세계선을 그리고 고유 시간 간격을 계산합니다. dτ² = dt² - dx²/c²';

  @override
  String get simFourVectors => '4-벡터';

  @override
  String get simFourVectorsLevel => '특수 상대성이론';

  @override
  String get simFourVectorsFormat => '인터랙티브';

  @override
  String get simFourVectorsSummary => '민코프스키 시공간에서 4-운동량과 4-속도를 시각화합니다.';

  @override
  String get simVelocityAddition => '상대론적 속도 합성';

  @override
  String get simVelocityAdditionLevel => '특수 상대성이론';

  @override
  String get simVelocityAdditionFormat => '인터랙티브';

  @override
  String get simVelocityAdditionSummary =>
      '갈릴레이 속도 합성과 상대론적 공식을 비교합니다. u\' = (u+v)/(1+uv/c²)';

  @override
  String get simBarnPoleParadox => '헛간-막대 역설';

  @override
  String get simBarnPoleParadoxLevel => '특수 상대성이론';

  @override
  String get simBarnPoleParadoxFormat => '인터랙티브';

  @override
  String get simBarnPoleParadoxSummary => '동시성의 상대성을 이용하여 길이 수축 역설을 해결합니다.';

  @override
  String get simWeatherFronts => '기상 전선';

  @override
  String get simWeatherFrontsLevel => '기상학';

  @override
  String get simWeatherFrontsFormat => '인터랙티브';

  @override
  String get simWeatherFrontsSummary =>
      '한랭, 온난, 정체, 폐색 전선과 그에 관련된 기상 패턴을 시각화합니다.';

  @override
  String get simHurricaneFormation => '허리케인 형성';

  @override
  String get simHurricaneFormationLevel => '기상학';

  @override
  String get simHurricaneFormationFormat => '인터랙티브';

  @override
  String get simHurricaneFormationSummary =>
      '따뜻한 해수의 증발과 응결을 통해 열대 저기압이 강화되는 과정을 관찰합니다.';

  @override
  String get simJetStream => '제트 기류';

  @override
  String get simJetStreamLevel => '대기과학';

  @override
  String get simJetStreamFormat => '인터랙티브';

  @override
  String get simJetStreamSummary =>
      '온도 기울기가 전 세계 기상 시스템을 조종하는 제트 기류를 어떻게 만드는지 탐구합니다.';

  @override
  String get simOrographicRainfall => '지형성 강수';

  @override
  String get simOrographicRainfallLevel => '지구과학';

  @override
  String get simOrographicRainfallFormat => '인터랙티브';

  @override
  String get simOrographicRainfallSummary =>
      '산이 습한 공기를 상승시켜 바람이 부는 사면에 강수를 일으키고 비 그늘을 만드는 과정을 봅니다.';

  @override
  String get simBarnsleyFern => '반슬리 양치류';

  @override
  String get simBarnsleyFernLevel => '프랙탈 기하학';

  @override
  String get simBarnsleyFernFormat => '인터랙티브';

  @override
  String get simBarnsleyFernSummary =>
      '어파인 변환의 반복 함수 시스템(IFS)으로 사실적인 양치류 프랙탈을 생성합니다.';

  @override
  String get simDragonCurve => '드래곤 커브';

  @override
  String get simDragonCurveLevel => '프랙탈 기하학';

  @override
  String get simDragonCurveFormat => '인터랙티브';

  @override
  String get simDragonCurveSummary =>
      '재귀적 종이 접기를 통해 드래곤 커브 프랙탈이 펼쳐지는 것을 관찰합니다.';

  @override
  String get simDiffusionLimited => '확산 제한 응집';

  @override
  String get simDiffusionLimitedLevel => '복잡계';

  @override
  String get simDiffusionLimitedFormat => '인터랙티브';

  @override
  String get simDiffusionLimitedSummary =>
      '무작위 보행 입자가 응집체에 붙으며 만드는 프랙탈 클러스터 성장을 시뮬레이션합니다.';

  @override
  String get simReactionDiffusion => '반응-확산 (튜링 패턴)';

  @override
  String get simReactionDiffusionLevel => '복잡계';

  @override
  String get simReactionDiffusionFormat => '인터랙티브';

  @override
  String get simReactionDiffusionSummary =>
      '활성-억제 반응-확산 방정식을 통해 튜링 패턴(점무늬·줄무늬)을 생성합니다.';

  @override
  String get simMendelianGenetics => '멘델 유전학';

  @override
  String get simMendelianGeneticsLevel => '생물학';

  @override
  String get simMendelianGeneticsFormat => '인터랙티브';

  @override
  String get simMendelianGeneticsSummary =>
      '우성과 열성 대립유전자로 멘델의 분리 법칙과 독립 법칙을 시뮬레이션합니다.';

  @override
  String get simPunnettSquare => '펀넷 사각형';

  @override
  String get simPunnettSquareLevel => '생물학';

  @override
  String get simPunnettSquareFormat => '인터랙티브';

  @override
  String get simPunnettSquareSummary =>
      '인터랙티브 펀넷 사각형으로 자손의 유전자형·표현형 비율을 예측합니다.';

  @override
  String get simGeneExpression => '유전자 발현';

  @override
  String get simGeneExpressionLevel => '분자생물학';

  @override
  String get simGeneExpressionFormat => '인터랙티브';

  @override
  String get simGeneExpressionSummary =>
      '전사(DNA→mRNA)와 번역(mRNA→단백질) 과정을 단계별로 시각화합니다.';

  @override
  String get simGeneticDrift => '유전적 부동';

  @override
  String get simGeneticDriftLevel => '집단유전학';

  @override
  String get simGeneticDriftFormat => '인터랙티브';

  @override
  String get simGeneticDriftSummary =>
      '소규모 개체군에서 세대를 거치며 나타나는 무작위 대립유전자 빈도 변화를 관찰합니다.';

  @override
  String get simHrDiagram => '헤르츠스프룽-러셀 도표';

  @override
  String get simHrDiagramLevel => '천체물리학';

  @override
  String get simHrDiagramFormat => '인터랙티브';

  @override
  String get simHrDiagramSummary => 'HR 도표에 별을 표시하고 주계열에서 잔재까지 항성 진화를 추적합니다.';

  @override
  String get simStellarNucleosynthesis => '항성 핵합성';

  @override
  String get simStellarNucleosynthesisLevel => '천체물리학';

  @override
  String get simStellarNucleosynthesisFormat => '인터랙티브';

  @override
  String get simStellarNucleosynthesisSummary =>
      '항성 핵의 핵융합을 통해 수소에서 철까지 원소가 형성되는 과정을 추적합니다.';

  @override
  String get simChandrasekharLimit => '찬드라세카르 한계';

  @override
  String get simChandrasekharLimitLevel => '천체물리학';

  @override
  String get simChandrasekharLimitFormat => '인터랙티브';

  @override
  String get simChandrasekharLimitSummary =>
      '백색왜성의 1.4 M☉ 질량 한계와 이를 초과하는 별의 운명을 탐구합니다.';

  @override
  String get simNeutronStar => '중성자별';

  @override
  String get simNeutronStarLevel => '천체물리학';

  @override
  String get simNeutronStarFormat => '인터랙티브';

  @override
  String get simNeutronStarSummary => '중성자별의 극한 밀도, 초강력 자기장, 펄스 방출을 시각화합니다.';

  @override
  String get simVenturiTube => '벤투리 효과';

  @override
  String get simVenturiTubeLevel => '유체역학';

  @override
  String get simVenturiTubeFormat => '인터랙티브';

  @override
  String get simVenturiTubeSummary =>
      '좁아지는 관에서의 압력 감소를 벤투리 효과로 관찰합니다. P₁+½ρv₁²=P₂+½ρv₂²';

  @override
  String get simSurfaceTension => '표면 장력';

  @override
  String get simSurfaceTensionLevel => '유체 물리';

  @override
  String get simSurfaceTensionFormat => '인터랙티브';

  @override
  String get simSurfaceTensionSummary =>
      '분자 응집력이 표면 장력을 만들고 모세관 상승을 가능하게 하는 원리를 탐구합니다.';

  @override
  String get simHookeSpring => '직렬·병렬 용수철';

  @override
  String get simHookeSpringLevel => '역학';

  @override
  String get simHookeSpringFormat => '인터랙티브';

  @override
  String get simHookeSpringsSummary =>
      '직렬과 병렬 용수철 배열의 등가 용수철 상수를 비교합니다. 1/k_s = 1/k₁ + 1/k₂';

  @override
  String get simWheatstoneBridge => '휘트스톤 브리지';

  @override
  String get simWheatstoneBridgeLevel => '전기공학';

  @override
  String get simWheatstoneBridgeFormat => '인터랙티브';

  @override
  String get simWheatstoneBridgeSummary =>
      '휘트스톤 브리지 회로를 균형하여 미지의 저항을 정밀하게 측정합니다.';

  @override
  String get simGradientField => '기울기 벡터장';

  @override
  String get simGradientFieldLevel => '다변수 미적분';

  @override
  String get simGradientFieldFormat => '인터랙티브';

  @override
  String get simGradientFieldSummary => '스칼라 함수의 기울기 벡터장과 등전위 등고선을 시각화합니다.';

  @override
  String get simDivergenceCurl => '발산과 회전';

  @override
  String get simDivergenceCurlLevel => '벡터 미적분';

  @override
  String get simDivergenceCurlFormat => '인터랙티브';

  @override
  String get simDivergenceCurlSummary =>
      '2D 벡터장의 발산과 회전을 탐구합니다 — 맥스웰 방정식의 기초입니다.';

  @override
  String get simLaplaceTransform => '라플라스 변환';

  @override
  String get simLaplaceTransformLevel => '공학수학';

  @override
  String get simLaplaceTransformFormat => '인터랙티브';

  @override
  String get simLaplaceTransformSummary =>
      '시간 영역 신호를 s-영역으로 변환합니다. F(s) = ∫₀^∞ f(t)e^(-st) dt';

  @override
  String get simZTransform => 'Z-변환';

  @override
  String get simZTransformLevel => '디지털 신호처리';

  @override
  String get simZTransformFormat => '인터랙티브';

  @override
  String get simZTransformSummary => '디지털 필터 분석을 위해 이산 시간 수열을 z-영역으로 변환합니다.';

  @override
  String get simDbscan => 'DBSCAN 클러스터링';

  @override
  String get simDbscanLevel => '머신러닝';

  @override
  String get simDbscanFormat => '인터랙티브';

  @override
  String get simDbscanSummary =>
      '임의 형태의 클러스터를 발견하고 이상값을 처리하는 밀도 기반 공간 클러스터링입니다.';

  @override
  String get simConfusionMatrix => '혼동 행렬과 ROC 곡선';

  @override
  String get simConfusionMatrixLevel => '머신러닝';

  @override
  String get simConfusionMatrixFormat => '인터랙티브';

  @override
  String get simConfusionMatrixSummary => '혼동 행렬과 ROC-AUC 곡선으로 분류 성능을 시각화합니다.';

  @override
  String get simCrossValidation => '교차 검증';

  @override
  String get simCrossValidationLevel => '머신러닝';

  @override
  String get simCrossValidationFormat => '인터랙티브';

  @override
  String get simCrossValidationSummary =>
      '편향 없는 모델 평가와 하이퍼파라미터 튜닝을 위한 k-겹 교차 검증을 이해합니다.';

  @override
  String get simBiasVariance => '편향-분산 트레이드오프';

  @override
  String get simBiasVarianceLevel => '머신러닝';

  @override
  String get simBiasVarianceFormat => '인터랙티브';

  @override
  String get simBiasVarianceSummary =>
      '모델 복잡도가 과소적합(편향)과 과적합(분산) 사이의 균형을 어떻게 조절하는지 탐구합니다.';

  @override
  String get simQuantumFourier => '양자 푸리에 변환';

  @override
  String get simQuantumFourierLevel => '양자 컴퓨팅';

  @override
  String get simQuantumFourierFormat => '인터랙티브';

  @override
  String get simQuantumFourierSummary =>
      'QFT 회로가 양자 진폭 분포를 효율적으로 변환하는 방법을 시각화합니다.';

  @override
  String get simDensityMatrix => '밀도 행렬';

  @override
  String get simDensityMatrixLevel => '양자역학';

  @override
  String get simDensityMatrixFormat => '인터랙티브';

  @override
  String get simDensityMatrixSummary =>
      '밀도 행렬과 블로흐 구 시각화로 순수 및 혼합 양자 상태를 표현합니다.';

  @override
  String get simQuantumWalk => '양자 랜덤 워크';

  @override
  String get simQuantumWalkLevel => '양자 컴퓨팅';

  @override
  String get simQuantumWalkFormat => '인터랙티브';

  @override
  String get simQuantumWalkSummary =>
      '양자와 고전적 랜덤 워크를 비교합니다 — 양자 간섭에 의한 이차적 가속입니다.';

  @override
  String get simQuantumDecoherence => '양자 결어긋남';

  @override
  String get simQuantumDecoherenceLevel => '양자역학';

  @override
  String get simQuantumDecoherenceFormat => '인터랙티브';

  @override
  String get simQuantumDecoherenceSummary =>
      '큐비트가 환경 욕조와 상호작용하면서 양자 결맞음이 붕괴되는 것을 관찰합니다.';

  @override
  String get simCrystalLattice => '결정 격자 구조';

  @override
  String get simCrystalLatticeLevel => '재료과학';

  @override
  String get simCrystalLatticeFormat => '인터랙티브';

  @override
  String get simCrystalLatticeSummary => 'FCC, BCC, HCP 결정 구조와 그 충전 효율을 탐구합니다.';

  @override
  String get simHessLaw => '헤스 법칙';

  @override
  String get simHessLawLevel => '열화학';

  @override
  String get simHessLawFormat => '인터랙티브';

  @override
  String get simHessLawSummary => '헤스 법칙을 이용하여 열화학 방정식을 결합하고 반응 엔탈피를 계산합니다.';

  @override
  String get simEnthalpyDiagram => '엔탈피 다이어그램';

  @override
  String get simEnthalpyDiagramLevel => '열화학';

  @override
  String get simEnthalpyDiagramFormat => '인터랙티브';

  @override
  String get simEnthalpyDiagramSummary =>
      '활성화 에너지 장벽이 포함된 발열·흡열 반응의 에너지 프로파일을 시각화합니다.';

  @override
  String get simLeChatelier => '르 샤틀리에 원리';

  @override
  String get simLeChatelierLevel => '화학 평형';

  @override
  String get simLeChatelierFormat => '인터랙티브';

  @override
  String get simLeChatelierSummary => '농도, 압력, 온도 변화에 대한 평형 이동을 관찰합니다.';

  @override
  String get simRelativisticEnergy => '상대론적 운동 에너지';

  @override
  String get simRelativisticEnergyLevel => '특수 상대성이론';

  @override
  String get simRelativisticEnergyFormat => '인터랙티브';

  @override
  String get simRelativisticEnergySummary =>
      '고전 역학과 상대론적 운동 에너지를 비교합니다 — 광속에 가까워질수록 차이가 커집니다. K = (γ-1)mc²';

  @override
  String get simLightCone => '빛 원뿔 다이어그램';

  @override
  String get simLightConeLevel => '특수 상대성이론';

  @override
  String get simLightConeFormat => '인터랙티브';

  @override
  String get simLightConeSummary => '시공간의 인과 구조를 시각화합니다: 과거, 미래, 공간형 분리 사건.';

  @override
  String get simEquivalencePrinciple => '등가 원리';

  @override
  String get simEquivalencePrincipleLevel => '일반상대성이론';

  @override
  String get simEquivalencePrincipleFormat => '인터랙티브';

  @override
  String get simEquivalencePrincipleSummary =>
      '아인슈타인의 등가 원리를 증명합니다: 중력 질량과 관성 질량은 구별 불가능합니다.';

  @override
  String get simMetricTensor => '계량 텐서 시각화';

  @override
  String get simMetricTensorLevel => '일반상대성이론';

  @override
  String get simMetricTensorFormat => '인터랙티브';

  @override
  String get simMetricTensorSummary => '계량 텐서가 곡선 시공간의 기하를 어떻게 기술하는지 시각화합니다.';

  @override
  String get simSoilLayers => '토양층';

  @override
  String get simSoilLayersLevel => '지구과학';

  @override
  String get simSoilLayersFormat => '인터랙티브';

  @override
  String get simSoilLayersSummary =>
      '토양 단면의 O, A, B, C 층위와 그 구성 및 형성 과정을 탐구합니다.';

  @override
  String get simVolcanoTypes => '화산 유형과 분출';

  @override
  String get simVolcanoTypesLevel => '지질학';

  @override
  String get simVolcanoTypesFormat => '인터랙티브';

  @override
  String get simVolcanoTypesSummary => '순상화산, 성층화산, 분석구를 분출 양식과 함께 비교합니다.';

  @override
  String get simMineralIdentification => '광물 감정';

  @override
  String get simMineralIdentificationLevel => '광물학';

  @override
  String get simMineralIdentificationFormat => '인터랙티브';

  @override
  String get simMineralIdentificationSummary =>
      '경도(모스 경도계), 광택, 조흔색을 이용하여 광물을 감정합니다.';

  @override
  String get simErosionDeposition => '침식과 퇴적';

  @override
  String get simErosionDepositionLevel => '지구과학';

  @override
  String get simErosionDepositionFormat => '인터랙티브';

  @override
  String get simErosionDepositionSummary =>
      '물과 바람이 지형을 침식, 운반, 퇴적하는 과정을 시뮬레이션합니다.';

  @override
  String get simFlocking => '보이드 떼짓기 시뮬레이션';

  @override
  String get simFlockingLevel => '창발';

  @override
  String get simFlockingFormat => '인터랙티브';

  @override
  String get simFlockingSummary => '분리, 정렬, 응집의 세 가지 단순 규칙에서 창발하는 떼짓기 행동입니다.';

  @override
  String get simAntColony => '개미 군체 최적화';

  @override
  String get simAntColonyLevel => '집단 지능';

  @override
  String get simAntColonyFormat => '인터랙티브';

  @override
  String get simAntColonySummary => '페로몬 기반 오명 소통으로 개미가 최적 경로를 발견하는 과정을 관찰합니다.';

  @override
  String get simForestFire => '산불 모델';

  @override
  String get simForestFireLevel => '복잡계';

  @override
  String get simForestFireFormat => '인터랙티브';

  @override
  String get simForestFireSummary => '침투 이론을 이용한 산불 확산 모델 — 자기 조직화 임계성의 예입니다.';

  @override
  String get simNetworkCascade => '네트워크 연쇄 전파';

  @override
  String get simNetworkCascadeLevel => '네트워크 과학';

  @override
  String get simNetworkCascadeFormat => '인터랙티브';

  @override
  String get simNetworkCascadeSummary =>
      '복잡한 네트워크를 통해 정보, 질병, 장애가 연쇄적으로 전파되는 것을 시뮬레이션합니다.';

  @override
  String get simSpeciation => '종 분화';

  @override
  String get simSpeciationLevel => '진화생물학';

  @override
  String get simSpeciationFormat => '인터랙티브';

  @override
  String get simSpeciationSummary => '지리적 격리와 자연선택에 의한 이소적·동소적 종 분화를 시뮬레이션합니다.';

  @override
  String get simPhylogeneticTree => '계통수';

  @override
  String get simPhylogeneticTreeLevel => '진화생물학';

  @override
  String get simPhylogeneticTreeFormat => '인터랙티브';

  @override
  String get simPhylogeneticTreeSummary =>
      '생명의 진화 계통수를 구축하고 탐구합니다 — 공통 조상을 보여주는 분기도입니다.';

  @override
  String get simFoodWeb => '먹이 그물 역학';

  @override
  String get simFoodWebLevel => '생태학';

  @override
  String get simFoodWebFormat => '인터랙티브';

  @override
  String get simFoodWebSummary => '먹이 그물을 통한 영양 에너지 흐름과 종 제거의 결과를 탐구합니다.';

  @override
  String get simEcologicalSuccession => '생태 천이';

  @override
  String get simEcologicalSuccessionLevel => '생태학';

  @override
  String get simEcologicalSuccessionFormat => '인터랙티브';

  @override
  String get simEcologicalSuccessionSummary =>
      '나지의 개척 종에서 안정된 극상 군집까지 생태계가 발전하는 것을 관찰합니다.';

  @override
  String get simSupernova => '초신성 유형';

  @override
  String get simSupernovaLevel => '천체물리학';

  @override
  String get simSupernovaFormat => '인터랙티브';

  @override
  String get simSupernovaSummary => 'Ia형 열핵 초신성과 무거운 별의 핵 붕괴 초신성을 비교합니다.';

  @override
  String get simBinaryStar => '쌍성계';

  @override
  String get simBinaryStarLevel => '천체물리학';

  @override
  String get simBinaryStarFormat => '인터랙티브';

  @override
  String get simBinaryStarSummary => '쌍성계의 궤도 역학을 시뮬레이션하고 광도 곡선 변화를 관찰합니다.';

  @override
  String get simExoplanetTransit => '외계행성 통과법';

  @override
  String get simExoplanetTransitLevel => '천체물리학';

  @override
  String get simExoplanetTransitFormat => '인터랙티브';

  @override
  String get simExoplanetTransitSummary =>
      '행성 통과 중 항성 밝기 감소를 분석하여 외계행성을 탐지합니다.';

  @override
  String get simParallax => '항성 시차';

  @override
  String get simParallaxLevel => '관측 천문학';

  @override
  String get simParallaxFormat => '인터랙티브';

  @override
  String get simParallaxSummary => '연주 시차각 이동으로 항성 거리를 측정합니다. d = 1/p (파섹)';

  @override
  String get simMagneticInduction => '상호 유도';

  @override
  String get simMagneticInductionLevel => '전자기학';

  @override
  String get simMagneticInductionFormat => '인터랙티브';

  @override
  String get simMagneticInductionSummary =>
      '한 코일의 변화하는 전류가 근처 결합된 코일에 전압을 유도하는 과정을 탐구합니다.';

  @override
  String get simAcCircuits => '교류 회로 분석';

  @override
  String get simAcCircuitsLevel => '전기공학';

  @override
  String get simAcCircuitsFormat => '인터랙티브';

  @override
  String get simAcCircuitsSummary => 'RLC 교류 회로의 임피던스, 위상 관계, 공진을 분석합니다.';

  @override
  String get simPhotodiode => '포토다이오드 동작';

  @override
  String get simPhotodiodeLevel => '반도체 물리';

  @override
  String get simPhotodiodeFormat => '인터랙티브';

  @override
  String get simPhotodiodeSummary =>
      '포토다이오드가 광전 효과를 통해 입사 광자를 전기 전류로 변환하는 과정을 시각화합니다.';

  @override
  String get simHallEffect => '홀 효과';

  @override
  String get simHallEffectLevel => '고체물리학';

  @override
  String get simHallEffectFormat => '인터랙티브';

  @override
  String get simHallEffectSummary =>
      '자기장 하에서 전류가 흐르는 도체에 발생하는 횡방향 홀 전압을 관찰합니다.';

  @override
  String get simConvolution => '합성곱';

  @override
  String get simConvolutionLevel => '신호처리';

  @override
  String get simConvolutionFormat => '인터랙티브';

  @override
  String get simConvolutionSummary =>
      '두 함수의 합성곱을 미끄러지는 겹침 적분으로 시각화합니다 — 필터링의 기본입니다.';

  @override
  String get simFibonacciSequence => '피보나치 수열과 황금 나선';

  @override
  String get simFibonacciSequenceLevel => '정수론';

  @override
  String get simFibonacciSequenceFormat => '인터랙티브';

  @override
  String get simFibonacciSequenceSummary =>
      '피보나치 수에서 황금 나선이 나타나는 것을 관찰합니다 — 자연에서 가장 흔한 성장 패턴입니다.';

  @override
  String get simEulerPath => '오일러 경로와 해밀턴 경로';

  @override
  String get simEulerPathLevel => '그래프 이론';

  @override
  String get simEulerPathFormat => '인터랙티브';

  @override
  String get simEulerPathSummary =>
      '그래프에서 오일러 경로(모든 간선 통과)와 해밀턴 경로(모든 꼭짓점 방문)를 찾습니다.';

  @override
  String get simMinimumSpanningTree => '최소 신장 트리';

  @override
  String get simMinimumSpanningTreeLevel => '그래프 이론';

  @override
  String get simMinimumSpanningTreeFormat => '인터랙티브';

  @override
  String get simMinimumSpanningTreeSummary =>
      '크루스칼과 프림의 탐욕 알고리즘으로 최소 신장 트리를 구축합니다.';

  @override
  String get simBatchNorm => '배치 정규화';

  @override
  String get simBatchNormLevel => '딥러닝';

  @override
  String get simBatchNormFormat => '인터랙티브';

  @override
  String get simBatchNormSummary =>
      '배치 정규화가 층 활성화를 정규화하여 훈련을 안정시키는 방법을 시각화합니다.';

  @override
  String get simLearningRate => '학습률 스케줄링';

  @override
  String get simLearningRateLevel => '딥러닝';

  @override
  String get simLearningRateFormat => '인터랙티브';

  @override
  String get simLearningRateSummary =>
      '일정 학습률, 단계 감소, 코사인 어닐링, 웜 리스타트 스케줄을 비교합니다.';

  @override
  String get simBackpropagation => '역전파';

  @override
  String get simBackpropagationLevel => '딥러닝';

  @override
  String get simBackpropagationFormat => '인터랙티브';

  @override
  String get simBackpropagationSummary =>
      '단순 신경망에서 연쇄 법칙으로 기울기를 계산하는 역전파를 단계별로 실행합니다.';

  @override
  String get simVae => '변분 오토인코더 (VAE)';

  @override
  String get simVaeLevel => '생성형 AI';

  @override
  String get simVaeFormat => '인터랙티브';

  @override
  String get simVaeSummary => 'VAE의 잠재 공간을 탐구합니다 — 인코딩, 재매개변수화 트릭 샘플링, 디코딩.';

  @override
  String get simQuantumZeno => '양자 제논 효과';

  @override
  String get simQuantumZenoLevel => '양자역학';

  @override
  String get simQuantumZenoFormat => '인터랙티브';

  @override
  String get simQuantumZenoSummary =>
      '빈번한 측정이 양자 상태의 진화를 동결시킵니다 — 관측된 양자 냄비는 결코 끓지 않습니다.';

  @override
  String get simAharonovBohm => '아하로노프-봄 효과';

  @override
  String get simAharonovBohmLevel => '양자역학';

  @override
  String get simAharonovBohmFormat => '인터랙티브';

  @override
  String get simAharonovBohmSummary =>
      '전자 경로가 둘러싼 자기 선속에 의한 위상 이동을 관찰합니다 — 양자 물리에서의 위상 기하학입니다.';

  @override
  String get simQuantumKeyDist => 'BB84 양자 키 분배';

  @override
  String get simQuantumKeyDistLevel => '양자 암호';

  @override
  String get simQuantumKeyDistFormat => '인터랙티브';

  @override
  String get simQuantumKeyDistSummary =>
      '무조건적으로 안전한 양자 키 분배를 위한 BB84 프로토콜을 시뮬레이션합니다.';

  @override
  String get simFranckHertz => '프랑크-헤르츠 실험';

  @override
  String get simFranckHertzLevel => '원자 물리';

  @override
  String get simFranckHertzFormat => '인터랙티브';

  @override
  String get simFranckHertzSummary => '전자 충돌 분광법으로 원자의 이산 에너지 준위를 증명합니다.';

  @override
  String get simEquilibriumConstant => '평형 상수';

  @override
  String get simEquilibriumConstantLevel => '화학 평형';

  @override
  String get simEquilibriumConstantFormat => '인터랙티브';

  @override
  String get simEquilibriumConstantSummary =>
      '반응의 Kc와 Kp를 계산하고 농도 비율이 평형에 도달하는 것을 시각화합니다.';

  @override
  String get simBufferSolution => '완충 용액';

  @override
  String get simBufferSolutionLevel => '산-염기 화학';

  @override
  String get simBufferSolutionFormat => '인터랙티브';

  @override
  String get simBufferSolutionSummary =>
      '약산-짝염기 완충 용액이 산이나 염기 첨가 시 pH 변화에 저항하는 방법을 탐구합니다.';

  @override
  String get simRadioactiveDecay => '방사성 붕괴';

  @override
  String get simRadioactiveDecayLevel => '핵화학';

  @override
  String get simRadioactiveDecayFormat => '인터랙티브';

  @override
  String get simRadioactiveDecaySummary =>
      '알파, 베타, 감마 붕괴를 반감기와 붕괴 상수로 시뮬레이션합니다. N = N₀e^(-λt)';

  @override
  String get simNuclearFissionFusion => '핵분열과 핵융합';

  @override
  String get simNuclearFissionFusionLevel => '핵물리학';

  @override
  String get simNuclearFissionFusionFormat => '인터랙티브';

  @override
  String get simNuclearFissionFusionSummary =>
      '핵자당 결합 에너지를 통해 우라늄 핵분열과 수소 핵융합의 에너지 방출을 비교합니다.';

  @override
  String get simFrameDragging => '프레임 끌림 (렌세-티링)';

  @override
  String get simFrameDraggingLevel => '일반상대성이론';

  @override
  String get simFrameDraggingFormat => '인터랙티브';

  @override
  String get simFrameDraggingSummary => '회전하는 질량이 주변 시공간을 끌어당기는 방법을 시각화합니다.';

  @override
  String get simPenroseDiagram => '펜로즈 등각 다이어그램';

  @override
  String get simPenroseDiagramLevel => '일반상대성이론';

  @override
  String get simPenroseDiagramFormat => '인터랙티브';

  @override
  String get simPenroseDiagramSummary =>
      '블랙홀과 우주론에서 무한한 시공간 구조를 유한한 컴팩트 다이어그램에 매핑합니다.';

  @override
  String get simFriedmannEquations => '프리드만 방정식';

  @override
  String get simFriedmannEquationsLevel => '우주론';

  @override
  String get simFriedmannEquationsFormat => '인터랙티브';

  @override
  String get simFriedmannEquationsSummary => '우주의 팽창 역사를 지배하는 프리드만 방정식을 탐구합니다.';

  @override
  String get simHubbleExpansion => '허블 팽창';

  @override
  String get simHubbleExpansionLevel => '우주론';

  @override
  String get simHubbleExpansionFormat => '인터랙티브';

  @override
  String get simHubbleExpansionSummary =>
      '팽창하는 우주를 시각화합니다 — 모든 은하가 v = H₀d의 속도로 멀어집니다.';

  @override
  String get simOceanTides => '조석 패턴';

  @override
  String get simOceanTidesLevel => '해양학';

  @override
  String get simOceanTidesFormat => '인터랙티브';

  @override
  String get simOceanTidesSummary => '달과 태양의 중력 인력으로부터 사리와 조금 조석 패턴을 모델링합니다.';

  @override
  String get simThermohaline => '열염순환';

  @override
  String get simThermohalineLevel => '해양학';

  @override
  String get simThermohalineFormat => '인터랙티브';

  @override
  String get simThermohalineSummary =>
      '온도와 염분 기울기에 의해 구동되는 전 지구적 해양 컨베이어 벨트를 시뮬레이션합니다.';

  @override
  String get simElNino => '엘니뇨와 라니냐';

  @override
  String get simElNinoLevel => '기후과학';

  @override
  String get simElNinoFormat => '인터랙티브';

  @override
  String get simElNinoSummary =>
      'ENSO 주기가 태평양 해수면 온도와 전 지구 기상 패턴을 어떻게 변화시키는지 탐구합니다.';

  @override
  String get simIceAges => '빙하기 주기';

  @override
  String get simIceAgesLevel => '고기후학';

  @override
  String get simIceAgesFormat => '인터랙티브';

  @override
  String get simIceAgesSummary =>
      '이심률, 경사각, 세차운동 등 밀란코비치 궤도 주기에 의한 빙하-간빙기 순환을 시뮬레이션합니다.';

  @override
  String get simSmallWorld => '좁은 세상 네트워크';

  @override
  String get simSmallWorldLevel => '네트워크 과학';

  @override
  String get simSmallWorldFormat => '인터랙티브';

  @override
  String get simSmallWorldSummary =>
      '높은 클러스터링과 짧은 경로 길이를 가진 와츠-스트로가츠 좁은 세상 네트워크를 구축하고 분석합니다.';

  @override
  String get simScaleFreeNetwork => '척도 없는 네트워크';

  @override
  String get simScaleFreeNetworkLevel => '네트워크 과학';

  @override
  String get simScaleFreeNetworkFormat => '인터랙티브';

  @override
  String get simScaleFreeNetworkSummary =>
      '우선 연결을 통해 바라바시-알버트 척도 없는 네트워크를 생성합니다 — 거듭제곱 법칙 차수 분포.';

  @override
  String get simStrangeAttractor => '이상 끌개 탐색기';

  @override
  String get simStrangeAttractorLevel => '혼돈 이론';

  @override
  String get simStrangeAttractorFormat => '인터랙티브';

  @override
  String get simStrangeAttractorSummary =>
      '로렌츠, 뢰슬러, 할보르센 이상 끌개를 탐구합니다 — 프랙탈 다양체 위의 혼돈.';

  @override
  String get simFeigenbaum => '파이겐바움 상수';

  @override
  String get simFeigenbaumLevel => '혼돈 이론';

  @override
  String get simFeigenbaumFormat => '인터랙티브';

  @override
  String get simFeigenbaumSummary =>
      '주기 배가 분기 연쇄에서 보편 파이겐바움 상수 δ ≈ 4.6692를 발견합니다.';

  @override
  String get simCarbonFixation => '탄소 고정 (캘빈 회로)';

  @override
  String get simCarbonFixationLevel => '생화학';

  @override
  String get simCarbonFixationFormat => '인터랙티브';

  @override
  String get simCarbonFixationSummary =>
      '캘빈 회로를 애니메이션합니다 — 식물이 ATP와 NADPH를 이용하여 대기 CO₂를 유기 탄소로 고정하는 과정.';

  @override
  String get simKrebsCycle => '크렙스 회로 (TCA 회로)';

  @override
  String get simKrebsCycleLevel => '생화학';

  @override
  String get simKrebsCycleFormat => '인터랙티브';

  @override
  String get simKrebsCycleSummary => '세포 에너지 대사의 중심 허브인 시트르산 회로를 단계별로 진행합니다.';

  @override
  String get simOsmosis => '삼투와 확산';

  @override
  String get simOsmosisLevel => '세포생물학';

  @override
  String get simOsmosisFormat => '인터랙티브';

  @override
  String get simOsmosisSummary =>
      '용질 농도 기울기에 의해 반투막을 통해 삼투압으로 물이 이동하는 것을 시각화합니다.';

  @override
  String get simActionPotentialSynapse => '시냅스 전달';

  @override
  String get simActionPotentialSynapseLevel => '신경과학';

  @override
  String get simActionPotentialSynapseFormat => '인터랙티브';

  @override
  String get simActionPotentialSynapseSummary =>
      '화학 시냅스에서 신경전달물질 방출, 수용체 결합, 시냅스후 전위를 애니메이션합니다.';

  @override
  String get simRedshiftMeasurement => '분광 적색편이 측정';

  @override
  String get simRedshiftMeasurementLevel => '관측 천문학';

  @override
  String get simRedshiftMeasurementFormat => '인터랙티브';

  @override
  String get simRedshiftMeasurementSummary =>
      '스펙트럼 적색편이 z = Δλ/λ를 분석하여 은하의 후퇴 속도와 거리를 측정합니다.';

  @override
  String get simPlanetFormation => '행성 형성';

  @override
  String get simPlanetFormationLevel => '행성과학';

  @override
  String get simPlanetFormationFormat => '인터랙티브';

  @override
  String get simPlanetFormationSummary => '원시행성 원반 진화와 강착을 통한 행성 형성을 시뮬레이션합니다.';

  @override
  String get simRocheLimit => '로슈 한계';

  @override
  String get simRocheLimitLevel => '천체물리학';

  @override
  String get simRocheLimitFormat => '인터랙티브';

  @override
  String get simRocheLimitSummary =>
      '행성의 로슈 한계 내에서 위성의 조석 파괴를 시각화합니다 — 고리 시스템의 기원.';

  @override
  String get simLagrangePoints => '라그랑주 점';

  @override
  String get simLagrangePointsLevel => '궤도역학';

  @override
  String get simLagrangePointsFormat => '인터랙티브';

  @override
  String get simLagrangePointsSummary => '중력과 원심력이 균형을 이루는 5개의 라그랑주 평형점을 찾습니다.';

  @override
  String get simEddyCurrents => '와전류';

  @override
  String get simEddyCurrentsLevel => '전자기학';

  @override
  String get simEddyCurrentsFormat => '인터랙티브';

  @override
  String get simEddyCurrentsSummary =>
      '도체에서 유도되는 와전류와 렌츠 법칙에 의한 제동 효과를 시각화합니다.';

  @override
  String get simPascalHydraulic => '파스칼 유압기';

  @override
  String get simPascalHydraulicLevel => '유체역학';

  @override
  String get simPascalHydraulicFormat => '인터랙티브';

  @override
  String get simPascalHydraulicSummary =>
      '파스칼 원리를 통한 유압 시스템의 힘 배율을 증명합니다. F₁/A₁ = F₂/A₂';

  @override
  String get simSpecificHeat => '비열 용량';

  @override
  String get simSpecificHeatLevel => '열역학';

  @override
  String get simSpecificHeatFormat => '인터랙티브';

  @override
  String get simSpecificHeatSummary =>
      '다른 물질이 열 에너지를 흡수하고 저장하는 방식을 비교합니다. Q = mcΔT';

  @override
  String get simStefanBoltzmann => '슈테판-볼츠만 복사';

  @override
  String get simStefanBoltzmannLevel => '열역학';

  @override
  String get simStefanBoltzmannFormat => '인터랙티브';

  @override
  String get simStefanBoltzmannSummary =>
      '흑체 열복사 출력이 온도의 4제곱에 비례하는 것을 탐구합니다. P = σAT⁴';

  @override
  String get simDijkstra => '다익스트라 최단 경로';

  @override
  String get simDijkstraLevel => '알고리즘';

  @override
  String get simDijkstraFormat => '인터랙티브';

  @override
  String get simDijkstraSummary =>
      '우선순위 큐를 이용한 다익스트라의 탐욕 알고리즘으로 가중 그래프의 최단 경로를 찾습니다.';

  @override
  String get simVoronoi => '보로노이 다이어그램';

  @override
  String get simVoronoiLevel => '전산 기하학';

  @override
  String get simVoronoiFormat => '인터랙티브';

  @override
  String get simVoronoiSummary =>
      '보로노이 분할을 생성합니다 — 각 셀은 해당 씨앗 점에 가장 가까운 모든 점을 포함합니다.';

  @override
  String get simDelaunay => '들로네 삼각분할';

  @override
  String get simDelaunayLevel => '전산 기하학';

  @override
  String get simDelaunayFormat => '인터랙티브';

  @override
  String get simDelaunaySummary =>
      '들로네 삼각분할을 구축합니다 — 보로노이 다이어그램의 쌍대로 최소 삼각형 각도를 최대화합니다.';

  @override
  String get simBezierCurves => '베지에 곡선';

  @override
  String get simBezierCurvesLevel => '컴퓨터 그래픽스';

  @override
  String get simBezierCurvesFormat => '인터랙티브';

  @override
  String get simBezierCurvesSummary =>
      '드 카스텔조의 재귀 알고리즘을 이용한 베지에 곡선 구성을 제어하고 시각화합니다.';

  @override
  String get simDiffusionModel => '확산 모델';

  @override
  String get simDiffusionModelLevel => '생성형 AI';

  @override
  String get simDiffusionModelFormat => '인터랙티브';

  @override
  String get simDiffusionModelSummary =>
      '확산 생성 모델의 순방향 노이즈 확산과 역방향 노이즈 제거 과정을 시각화합니다.';

  @override
  String get simTokenizer => '토크나이저와 바이트 쌍 인코딩';

  @override
  String get simTokenizerLevel => '자연어처리';

  @override
  String get simTokenizerFormat => '인터랙티브';

  @override
  String get simTokenizerSummary =>
      'BPE 토큰화가 텍스트를 언어 모델 훈련을 위한 서브워드 토큰으로 분할하는 방법을 탐구합니다.';

  @override
  String get simBeamSearch => '빔 서치 디코딩';

  @override
  String get simBeamSearchLevel => '자연어처리';

  @override
  String get simBeamSearchFormat => '인터랙티브';

  @override
  String get simBeamSearchSummary =>
      '자기회귀 시퀀스 디코딩 중 상위 k개 가설을 유지하는 빔 서치를 시각화합니다.';

  @override
  String get simFeatureImportance => '특성 중요도 (SHAP)';

  @override
  String get simFeatureImportanceLevel => '설명 가능한 AI';

  @override
  String get simFeatureImportanceFormat => '인터랙티브';

  @override
  String get simFeatureImportanceSummary => 'SHAP(샤플리 부가 설명) 값으로 모델 예측을 설명합니다.';

  @override
  String get simZeemanEffect => '제만 효과';

  @override
  String get simZeemanEffectLevel => '원자 물리';

  @override
  String get simZeemanEffectFormat => '인터랙티브';

  @override
  String get simZeemanEffectSummary => '외부 자기장에 놓인 원자에서 스펙트럼 선이 분리되는 것을 관찰합니다.';

  @override
  String get simQuantumWell => '양자 우물';

  @override
  String get simQuantumWellLevel => '반도체 물리';

  @override
  String get simQuantumWellFormat => '인터랙티브';

  @override
  String get simQuantumWellSummary => '유한 양자 우물 퍼텐셜에서 양자화된 속박 상태와 파동함수를 탐구합니다.';

  @override
  String get simBandStructure => '전자 띠 구조';

  @override
  String get simBandStructureLevel => '고체물리학';

  @override
  String get simBandStructureFormat => '인터랙티브';

  @override
  String get simBandStructureSummary =>
      '결정에서 에너지 띠 구조를 시각화합니다 — 금속, 반도체, 절연체의 기반입니다.';

  @override
  String get simBoseEinstein => '보즈-아인슈타인 응축';

  @override
  String get simBoseEinsteinLevel => '양자 물리학';

  @override
  String get simBoseEinsteinFormat => '인터랙티브';

  @override
  String get simBoseEinsteinSummary =>
      '보존이 거시적으로 바닥 상태를 점유하는 BEC 상전이를 시뮬레이션합니다.';

  @override
  String get simOrganicFunctionalGroups => '유기 작용기';

  @override
  String get simOrganicFunctionalGroupsLevel => '유기화학';

  @override
  String get simOrganicFunctionalGroupsFormat => '인터랙티브';

  @override
  String get simOrganicFunctionalGroupsSummary =>
      '수산기, 카르보닐기, 카르복실기, 아미노기 등 유기 작용기와 그 반응성을 탐구합니다.';

  @override
  String get simIsomers => '구조 및 기하 이성질체';

  @override
  String get simIsomersLevel => '유기화학';

  @override
  String get simIsomersFormat => '인터랙티브';

  @override
  String get simIsomersSummary => '3D 분자 시각화로 구조 이성질체와 기하(시스-트랜스) 이성질체를 비교합니다.';

  @override
  String get simPolymerization => '중합 반응';

  @override
  String get simPolymerizationLevel => '고분자 화학';

  @override
  String get simPolymerizationFormat => '인터랙티브';

  @override
  String get simPolymerizationSummary =>
      '단량체에서 고분자를 구축하는 첨가 중합과 축합 중합을 애니메이션합니다.';

  @override
  String get simElectrolysis => '전기분해';

  @override
  String get simElectrolysisLevel => '전기화학';

  @override
  String get simElectrolysisFormat => '인터랙티브';

  @override
  String get simElectrolysisSummary => '전기 전류로 물과 염수 용액을 분해하는 전기분해를 시뮬레이션합니다.';

  @override
  String get simCosmicMicrowaveBg => '우주 마이크로파 배경';

  @override
  String get simCosmicMicrowaveBgLevel => '우주론';

  @override
  String get simCosmicMicrowaveBgFormat => '인터랙티브';

  @override
  String get simCosmicMicrowaveBgSummary =>
      '빅뱅의 증거인 CMB 온도 이방성을 탐구합니다 — 우주에서 가장 오래된 빛.';

  @override
  String get simKerrBlackHole => '커 블랙홀';

  @override
  String get simKerrBlackHoleLevel => '일반상대성이론';

  @override
  String get simKerrBlackHoleFormat => '인터랙티브';

  @override
  String get simKerrBlackHoleSummary => '회전 커 블랙홀의 에르고 구면과 프레임 끌림 효과를 시각화합니다.';

  @override
  String get simShapiroDelay => '샤피로 시간 지연';

  @override
  String get simShapiroDelayLevel => '일반상대성이론';

  @override
  String get simShapiroDelayFormat => '인터랙티브';

  @override
  String get simShapiroDelaySummary =>
      '무거운 천체 근처를 지나는 레이더 신호의 중력 시간 지연을 측정합니다 — 일반상대성이론 검증.';

  @override
  String get simGravitationalTime => '중력 시간 팽창';

  @override
  String get simGravitationalTimeLevel => '일반상대성이론';

  @override
  String get simGravitationalTimeFormat => '인터랙티브';

  @override
  String get simGravitationalTimeSummary =>
      '다른 중력 퍼텐셜에서의 시계 속도를 비교합니다 — 중력 우물 깊이 있는 시계는 더 느리게 갑니다.';

  @override
  String get simOzoneLayer => '오존층 파괴';

  @override
  String get simOzoneLayerLevel => '대기화학';

  @override
  String get simOzoneLayerFormat => '인터랙티브';

  @override
  String get simOzoneLayerSummary =>
      '성층권에서 CFC 촉매에 의한 오존 파괴와 남극 오존 구멍을 시뮬레이션합니다.';

  @override
  String get simRadiationBudget => '지구 복사 수지';

  @override
  String get simRadiationBudgetLevel => '기후과학';

  @override
  String get simRadiationBudgetFormat => '인터랙티브';

  @override
  String get simRadiationBudgetSummary =>
      '들어오는 태양 단파 복사와 나가는 지구 장파 복사 플럭스의 균형을 맞춥니다.';

  @override
  String get simNitrogenCycle => '질소 순환';

  @override
  String get simNitrogenCycleLevel => '생지화학';

  @override
  String get simNitrogenCycleFormat => '인터랙티브';

  @override
  String get simNitrogenCycleSummary =>
      '생태계에서 고정, 질화, 탈질화, 동화 과정을 통한 질소의 이동을 추적합니다.';

  @override
  String get simFossilFormation => '화석 형성';

  @override
  String get simFossilFormationLevel => '고생물학';

  @override
  String get simFossilFormationFormat => '인터랙티브';

  @override
  String get simFossilFormationSummary =>
      '퇴적암에서 생물이 보존되어 화석이 형성되는 단계별 과정을 애니메이션합니다.';

  @override
  String get simLyapunovExponent => '리아푸노프 지수';

  @override
  String get simLyapunovExponentLevel => '혼돈 이론';

  @override
  String get simLyapunovExponentFormat => '인터랙티브';

  @override
  String get simLyapunovExponentSummary =>
      '혼돈 시스템에서 궤적 발산 속도를 정량화하기 위한 리아푸노프 지수를 계산합니다.';

  @override
  String get simTentMap => '텐트 사상';

  @override
  String get simTentMapLevel => '혼돈 이론';

  @override
  String get simTentMapFormat => '인터랙티브';

  @override
  String get simTentMapSummary =>
      '텐트 사상의 카오스적 행동을 탐구합니다 — 로지스틱 맵의 구간별 선형 유사체입니다.';

  @override
  String get simSierpinskiCarpet => '시어핀스키 카펫';

  @override
  String get simSierpinskiCarpetLevel => '프랙탈 기하학';

  @override
  String get simSierpinskiCarpetFormat => '인터랙티브';

  @override
  String get simSierpinskiCarpetSummary =>
      '재귀적 정사각형 세분을 통해 시어핀스키 카펫 프랙탈을 생성합니다.';

  @override
  String get simChaosGame => '카오스 게임';

  @override
  String get simChaosGameLevel => '프랙탈 기하학';

  @override
  String get simChaosGameFormat => '인터랙티브';

  @override
  String get simChaosGameSummary =>
      '카오스 게임 무작위 반복 알고리즘으로 시어핀스키 삼각형과 다른 프랙탈을 생성합니다.';

  @override
  String get simImmuneResponse => '면역 반응';

  @override
  String get simImmuneResponseLevel => '면역학';

  @override
  String get simImmuneResponseFormat => '인터랙티브';

  @override
  String get simImmuneResponseSummary =>
      '항원 감지부터 항체 생산까지 선천 면역과 적응 면역 반응을 시뮬레이션합니다.';

  @override
  String get simMuscleContraction => '근육 수축';

  @override
  String get simMuscleContractionLevel => '생리학';

  @override
  String get simMuscleContractionFormat => '인터랙티브';

  @override
  String get simMuscleContractionSummary =>
      '마이오신 크로스브리지가 액틴 필라멘트를 당기는 활주 세사 메커니즘을 애니메이션합니다.';

  @override
  String get simHeartConduction => '심장 전기 전도';

  @override
  String get simHeartConductionLevel => '생리학';

  @override
  String get simHeartConductionFormat => '인터랙티브';

  @override
  String get simHeartConductionSummary =>
      '심장의 전기 전도 경로를 시각화합니다: 동방결절 → 방실결절 → 히스 다발 → 푸르키네 섬유.';

  @override
  String get simBloodCirculation => '혈액 순환';

  @override
  String get simBloodCirculationLevel => '생리학';

  @override
  String get simBloodCirculationFormat => '인터랙티브';

  @override
  String get simBloodCirculationSummary => '심혈관계의 폐순환과 체순환을 통한 혈액 흐름을 추적합니다.';

  @override
  String get simOrbitalTransfer => '호만 전이 궤도';

  @override
  String get simOrbitalTransferLevel => '궤도역학';

  @override
  String get simOrbitalTransferFormat => '인터랙티브';

  @override
  String get simOrbitalTransferSummary =>
      '원형 궤도 사이의 2번 점화 호만 전이를 계산하고 시각화합니다 — 가장 연료 효율적인 전이.';

  @override
  String get simEscapeVelocity => '탈출 속도';

  @override
  String get simEscapeVelocityLevel => '궤도역학';

  @override
  String get simEscapeVelocityFormat => '인터랙티브';

  @override
  String get simEscapeVelocitySummary => '행성과 별의 탈출 속도를 계산합니다. v_e = √(2GM/r)';

  @override
  String get simCelestialSphere => '천구';

  @override
  String get simCelestialSphereLevel => '관측 천문학';

  @override
  String get simCelestialSphereFormat => '인터랙티브';

  @override
  String get simCelestialSphereSummary => '천구를 탐색합니다 — 적경, 적위, 계절별 별자리 가시성.';

  @override
  String get simGalaxyRotation => '은하 회전 곡선';

  @override
  String get simGalaxyRotationLevel => '천체물리학';

  @override
  String get simGalaxyRotationFormat => '인터랙티브';

  @override
  String get simGalaxyRotationSummary =>
      '평탄한 은하 회전 곡선을 암흑 물질 헤일로의 관측 증거로 탐구합니다.';

  @override
  String get simWavePacket => '파동 패킷과 군 속도';

  @override
  String get simWavePacketLevel => '파동 물리';

  @override
  String get simWavePacketFormat => '인터랙티브';

  @override
  String get simWavePacketSummary =>
      '파동 패킷의 위상 속도와 군 속도를 시각화합니다 — 양자역학과 광학의 핵심 개념.';

  @override
  String get simLissajous => '리사주 도형';

  @override
  String get simLissajousLevel => '파동 물리';

  @override
  String get simLissajousFormat => '인터랙티브';

  @override
  String get simLissajousSummary =>
      '두 개의 수직 정현파 진동에서 리사주 도형을 생성합니다 — 아름답고 진단적입니다.';

  @override
  String get simDopplerRadar => '도플러 레이더';

  @override
  String get simDopplerRadarLevel => '응용 물리';

  @override
  String get simDopplerRadarFormat => '인터랙티브';

  @override
  String get simDopplerRadarSummary =>
      '도플러 주파수 이동으로 표적 속도를 측정합니다 — 기상 레이더와 속도 측정기의 원리.';

  @override
  String get simCavendish => '캐번디시 실험';

  @override
  String get simCavendishLevel => '중력';

  @override
  String get simCavendishFormat => '인터랙티브';

  @override
  String get simCavendishSummary =>
      '비틀림 저울로 중력 상수 G를 측정합니다 — 캐번디시의 1798년 실험을 재현합니다. G = 6.674×10⁻¹¹';

  @override
  String get simPolarCoordinates => '극좌표와 장미 곡선';

  @override
  String get simPolarCoordinatesLevel => '고등 수학';

  @override
  String get simPolarCoordinatesFormat => '인터랙티브';

  @override
  String get simPolarCoordinatesSummary =>
      '장미, 리마송, 아르키메데스 나선 패턴을 포함한 극좌표 곡선을 인터랙티브하게 그립니다.';

  @override
  String get simParametricCurves => '매개변수 곡선';

  @override
  String get simParametricCurvesLevel => '미적분학';

  @override
  String get simParametricCurvesFormat => '인터랙티브';

  @override
  String get simParametricCurvesSummary =>
      'x(t)와 y(t)를 제어하며 사이클로이드, 에피사이클로이드, 하이포사이클로이드 같은 매개변수 곡선을 탐구합니다.';

  @override
  String get simBinomialDistribution => '이항 분포';

  @override
  String get simBinomialDistributionLevel => '확률';

  @override
  String get simBinomialDistributionFormat => '인터랙티브';

  @override
  String get simBinomialDistributionSummary =>
      '이항 확률 분포와 큰 n에 대한 정규 근사를 시각화합니다.';

  @override
  String get simPoissonDistribution => '포아송 분포';

  @override
  String get simPoissonDistributionLevel => '확률';

  @override
  String get simPoissonDistributionFormat => '인터랙티브';

  @override
  String get simPoissonDistributionSummary =>
      '포아송 분포로 드문 사건을 모델링합니다. P(k) = λ^k · e^(-λ) / k!';

  @override
  String get simDimensionalityReduction => 't-SNE 차원 축소';

  @override
  String get simDimensionalityReductionLevel => '머신러닝';

  @override
  String get simDimensionalityReductionFormat => '인터랙티브';

  @override
  String get simDimensionalityReductionSummary =>
      't-SNE로 고차원 데이터를 2차원으로 축소하여 지역 이웃 구조를 보존합니다.';

  @override
  String get simNeuralStyle => '신경 스타일 전이';

  @override
  String get simNeuralStyleLevel => '컴퓨터 비전';

  @override
  String get simNeuralStyleFormat => '인터랙티브';

  @override
  String get simNeuralStyleSummary => '합성곱 신경망에서 콘텐츠와 스타일 특성 분리를 시각화합니다.';

  @override
  String get simMazeRl => '미로 강화학습';

  @override
  String get simMazeRlLevel => '강화학습';

  @override
  String get simMazeRlFormat => '인터랙티브';

  @override
  String get simMazeRlSummary =>
      'Q-러닝 에이전트가 시행착오를 통해 미로를 탐색하고 해결하는 법을 배우는 것을 관찰합니다.';

  @override
  String get simMinimax => '미니맥스 게임 트리';

  @override
  String get simMinimaxLevel => '게임 AI';

  @override
  String get simMinimaxFormat => '인터랙티브';

  @override
  String get simMinimaxSummary =>
      '알파-베타 가지치기를 이용한 2인 제로섬 게임의 미니맥스 의사결정을 탐구합니다.';

  @override
  String get simFermiDirac => '페르미-디랙 분포';

  @override
  String get simFermiDiracLevel => '통계역학';

  @override
  String get simFermiDiracFormat => '인터랙티브';

  @override
  String get simFermiDiracSummary =>
      '다른 온도에서 페르미-디랙 점유 확률을 시각화합니다 — 반도체 물리학의 기반.';

  @override
  String get simWignerFunction => '위그너 준확률 함수';

  @override
  String get simWignerFunctionLevel => '양자 광학';

  @override
  String get simWignerFunctionFormat => '인터랙티브';

  @override
  String get simWignerFunctionSummary =>
      '위그너 함수를 양자 위상 공간 표현으로 탐구합니다 — 음수 값은 비고전성을 나타냅니다.';

  @override
  String get simQuantumOscillator2d => '2차원 양자 조화 진동자';

  @override
  String get simQuantumOscillator2dLevel => '양자역학';

  @override
  String get simQuantumOscillator2dFormat => '인터랙티브';

  @override
  String get simQuantumOscillator2dSummary =>
      '2차원 등방성 양자 조화 진동자의 파동함수와 에너지 고유값을 시각화합니다.';

  @override
  String get simSpinChain => '양자 스핀 체인';

  @override
  String get simSpinChainLevel => '양자 다체';

  @override
  String get simSpinChainFormat => '인터랙티브';

  @override
  String get simSpinChainSummary => '스핀-1/2 하이젠베르크 스핀 체인에서 양자 상관관계와 얽힘을 탐구합니다.';

  @override
  String get simIdealSolution => '라울 법칙과 이상 용액';

  @override
  String get simIdealSolutionLevel => '물리화학';

  @override
  String get simIdealSolutionFormat => '인터랙티브';

  @override
  String get simIdealSolutionSummary =>
      '이상 및 비이상 용액에서 라울 법칙을 이용한 증기압 내림과 활동도 계수를 탐구합니다.';

  @override
  String get simChromatography => '크로마토그래피';

  @override
  String get simChromatographyLevel => '분석화학';

  @override
  String get simChromatographyFormat => '인터랙티브';

  @override
  String get simChromatographySummary => '정지상과 이동상을 통한 차등 이동으로 혼합물 성분을 분리합니다.';

  @override
  String get simCalorimetry => '열량 측정';

  @override
  String get simCalorimetryLevel => '열화학';

  @override
  String get simCalorimetryFormat => '인터랙티브';

  @override
  String get simCalorimetrySummary => '등압 및 등적 열량계를 이용하여 열 전달을 측정합니다. q = mcΔT';

  @override
  String get simActivationEnergy => '활성화 에너지와 촉매';

  @override
  String get simActivationEnergyLevel => '화학 반응속도론';

  @override
  String get simActivationEnergyFormat => '인터랙티브';

  @override
  String get simActivationEnergySummary =>
      '촉매가 활성화 에너지 장벽을 낮추는 방법을 시각화합니다 — 아레니우스 방정식과 전이 상태 이론.';

  @override
  String get simRelativistAberration => '상대론적 광행차';

  @override
  String get simRelativistAberrationLevel => '특수 상대성이론';

  @override
  String get simRelativistAberrationFormat => '인터랙티브';

  @override
  String get simRelativistAberrationSummary =>
      '속도가 광속에 가까워질수록 별의 위치가 이동하는 것을 봅니다 — 헤드라이트 효과.';

  @override
  String get simRelativisticBeaming => '상대론적 빔 집중';

  @override
  String get simRelativisticBeamingLevel => '특수 상대성이론';

  @override
  String get simRelativisticBeamingFormat => '인터랙티브';

  @override
  String get simRelativisticBeamingSummary =>
      '상대론적 속도에서 방출된 복사가 운동 방향으로 집중되는 것을 관찰합니다.';

  @override
  String get simCosmologicalRedshift => '우주론적 적색편이';

  @override
  String get simCosmologicalRedshiftLevel => '우주론';

  @override
  String get simCosmologicalRedshiftFormat => '인터랙티브';

  @override
  String get simCosmologicalRedshiftSummary =>
      '우주론적 적색편이와 도플러 적색편이를 구별합니다 — 팽창하는 공간에 의해 파장이 늘어납니다.';

  @override
  String get simDarkEnergy => '암흑 에너지와 가속 팽창';

  @override
  String get simDarkEnergyLevel => '우주론';

  @override
  String get simDarkEnergyFormat => '인터랙티브';

  @override
  String get simDarkEnergySummary => '암흑 에너지(Λ)가 우주의 가속 팽창을 어떻게 이끄는지 탐구합니다.';

  @override
  String get simMagneticReversal => '지자기장 역전';

  @override
  String get simMagneticReversalLevel => '지구물리학';

  @override
  String get simMagneticReversalFormat => '인터랙티브';

  @override
  String get simMagneticReversalSummary =>
      '지질학적 시간에 걸쳐 고지자기 데이터에 기록된 지구 자기장 역전을 시각화합니다.';

  @override
  String get simSeismograph => '지진계 판독';

  @override
  String get simSeismographLevel => '지구물리학';

  @override
  String get simSeismographFormat => '인터랙티브';

  @override
  String get simSeismographSummary =>
      '지진계의 P파와 S파 도달 시간을 읽어 지진 진원지와 규모를 결정합니다.';

  @override
  String get simContinentalDrift => '대륙 이동 증거';

  @override
  String get simContinentalDriftLevel => '지질학';

  @override
  String get simContinentalDriftFormat => '인터랙티브';

  @override
  String get simContinentalDriftSummary =>
      '대륙 이동과 판게아를 뒷받침하는 화석, 지질, 고지자기 증거를 탐구합니다.';

  @override
  String get simGreenhouseGases => '온실 기체 비교';

  @override
  String get simGreenhouseGasesLevel => '기후과학';

  @override
  String get simGreenhouseGasesFormat => '인터랙티브';

  @override
  String get simGreenhouseGasesSummary =>
      'CO₂, CH₄, N₂O 등 온실 기체의 복사 강제력과 지구 온난화 잠재력을 비교합니다.';

  @override
  String get simRule110 => '규칙 110 셀룰러 오토마타';

  @override
  String get simRule110Level => '계산 이론';

  @override
  String get simRule110Format => '인터랙티브';

  @override
  String get simRule110Summary =>
      '복잡한 창발 패턴을 가진 튜링 완전한 1차원 셀룰러 오토마타인 규칙 110을 탐구합니다.';

  @override
  String get simSchellingSegregation => '셸링 분리 모델';

  @override
  String get simSchellingSegregationLevel => '에이전트 기반 모델링';

  @override
  String get simSchellingSegregationFormat => '인터랙티브';

  @override
  String get simSchellingSegregationSummary =>
      '온건한 개인 선호에서 강한 주거 분리가 발생하는 것을 모델링합니다.';

  @override
  String get simDuffingOscillator => '더핑 진동자';

  @override
  String get simDuffingOscillatorLevel => '혼돈 이론';

  @override
  String get simDuffingOscillatorFormat => '인터랙티브';

  @override
  String get simDuffingOscillatorSummary =>
      '이중 우물 퍼텐셜을 가진 주기적으로 강제되는 비선형 더핑 진동자에서 카오스를 탐구합니다.';

  @override
  String get simBelousovZhabotinsky => '벨루소프-자보틴스키 반응';

  @override
  String get simBelousovZhabotinskyLevel => '화학 진동';

  @override
  String get simBelousovZhabotinskyFormat => '인터랙티브';

  @override
  String get simBelousovZhabotinskySummary =>
      '자기 조직화 나선파를 생성하는 화학 시계인 진동 BZ 반응을 시뮬레이션합니다.';

  @override
  String get simCellularRespiration => '세포 호흡';

  @override
  String get simCellularRespirationLevel => '생화학';

  @override
  String get simCellularRespirationFormat => '인터랙티브';

  @override
  String get simCellularRespirationSummary =>
      '해당과정, 피루브산 산화, 크렙스 회로, 전자전달계를 통한 ATP 생산을 추적합니다.';

  @override
  String get simLogisticGrowth => '로지스틱 개체군 성장';

  @override
  String get simLogisticGrowthLevel => '개체군 생태학';

  @override
  String get simLogisticGrowthFormat => '인터랙티브';

  @override
  String get simLogisticGrowthSummary =>
      '환경 수용력 K를 가진 S자형 로지스틱 성장을 모델링합니다. dN/dt = rN(1-N/K)';

  @override
  String get simCompetitiveExclusion => '경쟁 배타 원리';

  @override
  String get simCompetitiveExclusionLevel => '생태학';

  @override
  String get simCompetitiveExclusionFormat => '인터랙티브';

  @override
  String get simCompetitiveExclusionSummary =>
      '같은 생태적 지위를 놓고 경쟁하는 두 종을 시뮬레이션합니다 — 가우제의 경쟁 배타 원리.';

  @override
  String get simCrispr => '크리스퍼 유전자 편집';

  @override
  String get simCrisprLevel => '생명공학';

  @override
  String get simCrisprFormat => '인터랙티브';

  @override
  String get simCrisprSummary =>
      'CRISPR-Cas9 메커니즘을 애니메이션합니다: 가이드 RNA 표적화, DNA 절단, 복구 결과.';

  @override
  String get simDarkMatter => '암흑 물질 증거';

  @override
  String get simDarkMatterLevel => '천체물리학';

  @override
  String get simDarkMatterFormat => '인터랙티브';

  @override
  String get simDarkMatterSummary => '암흑 물질의 관측 증거를 탐구합니다: 회전 곡선, 중력 렌즈, CMB.';

  @override
  String get simPulsar => '펄서 타이밍';

  @override
  String get simPulsarLevel => '천체물리학';

  @override
  String get simPulsarFormat => '인터랙티브';

  @override
  String get simPulsarSummary => '밀리초 펄서 타이밍을 분석합니다 — 중력파 검출에 사용되는 자연의 우주 시계.';

  @override
  String get simAsteroidBelt => '소행성대와 커크우드 간극';

  @override
  String get simAsteroidBeltLevel => '행성과학';

  @override
  String get simAsteroidBeltFormat => '인터랙티브';

  @override
  String get simAsteroidBeltSummary => '목성의 중력 영향으로 생성된 소행성대 궤도 공명 간극을 시각화합니다.';

  @override
  String get simCosmicDistanceLadder => '우주 거리 사다리';

  @override
  String get simCosmicDistanceLadderLevel => '관측 천문학';

  @override
  String get simCosmicDistanceLadderFormat => '인터랙티브';

  @override
  String get simCosmicDistanceLadderSummary =>
      '거리 측정 방법의 연쇄를 탐구합니다: 시차 → 세페이드 변광성 → 초신성 → 허블 법칙.';

  @override
  String get updateRequired => '업데이트 필요';

  @override
  String get updateDescription =>
      '눈으로 보는 과학의 새 버전이 출시되었습니다. 계속 사용하려면 업데이트해 주세요.';

  @override
  String get updateNow => '지금 업데이트';

  @override
  String get updateLater => '나중에';

  @override
  String get currentVersionLabel => '현재 버전';

  @override
  String get requiredVersionLabel => '최소 버전';

  @override
  String get updateBenefits => '새로운 시뮬레이션, 버그 수정, 성능 개선이 포함되어 있습니다!';
}
