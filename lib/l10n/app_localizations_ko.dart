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
  String get simPendulumSummary => '줄 길이와 중력에 따른 진자 운동을 시뮬레이션합니다.';

  @override
  String get simWave => '이중 슬릿 간섭';

  @override
  String get simWaveLevel => '물리 엔진';

  @override
  String get simWaveFormat => '시뮬레이션';

  @override
  String get simWaveSummary => '두 파원의 간섭 패턴을 관찰합니다.';

  @override
  String get simGravity => '시공간 곡률';

  @override
  String get simGravityLevel => '일반상대성이론';

  @override
  String get simGravityFormat => '3D 시뮬레이션';

  @override
  String get simGravitySummary => '질량에 의한 시공간 휨을 3D 그리드로 시각화합니다.';

  @override
  String get simFormula => '수식 그래프';

  @override
  String get simFormulaLevel => '고등';

  @override
  String get simFormulaFormat => '2D 그래프';

  @override
  String get simFormulaSummary => '수학 함수를 입력하면 실시간 그래프를 생성합니다.';

  @override
  String get simLorenz => '로렌츠 어트랙터';

  @override
  String get simLorenzLevel => '혼돈 이론';

  @override
  String get simLorenzFormat => '3D 그래프';

  @override
  String get simLorenzSummary => '나비 효과를 시각화하는 혼돈 시스템.';

  @override
  String get simDoublePendulum => '이중 진자';

  @override
  String get simDoublePendulumLevel => '혼돈 역학';

  @override
  String get simDoublePendulumFormat => '시뮬레이션';

  @override
  String get simDoublePendulumSummary => '카오스 이론을 보여주는 두 개의 연결된 진자.';

  @override
  String get simGameOfLife => '콘웨이의 생명 게임';

  @override
  String get simGameOfLifeLevel => '셀룰러 오토마타';

  @override
  String get simGameOfLifeFormat => '시뮬레이션';

  @override
  String get simGameOfLifeSummary => '세포가 생존, 탄생, 죽음의 규칙에 따라 진화합니다.';

  @override
  String get simSet => '집합 연산';

  @override
  String get simSetLevel => '이산수학';

  @override
  String get simSetFormat => '인터랙티브';

  @override
  String get simSetSummary => '합집합, 교집합, 차집합을 벤다이어그램으로 시각화합니다.';

  @override
  String get simSorting => '정렬 알고리즘';

  @override
  String get simSortingLevel => '알고리즘';

  @override
  String get simSortingFormat => '애니메이션';

  @override
  String get simSortingSummary => '버블, 퀵, 병합 정렬의 동작 과정을 단계별로 비교합니다.';

  @override
  String get simNeuralNet => '신경망 플레이그라운드';

  @override
  String get simNeuralNetLevel => '딥러닝';

  @override
  String get simNeuralNetFormat => '인터랙티브';

  @override
  String get simNeuralNetSummary => '신경망의 순전파와 역전파, 가중치 학습 과정을 시각화합니다.';

  @override
  String get simGradient => '경사 하강법';

  @override
  String get simGradientLevel => '최적화';

  @override
  String get simGradientFormat => '시각화';

  @override
  String get simGradientSummary => '손실 함수를 최소화하는 경사 하강법의 수렴 과정을 시각화합니다.';

  @override
  String get simMandelbrot => 'Mandelbrot 집합';

  @override
  String get simMandelbrotLevel => '프랙탈';

  @override
  String get simMandelbrotFormat => '인터랙티브';

  @override
  String get simMandelbrotSummary => 'zₙ₊₁ = zₙ² + c. 무한한 복잡성의 프랙탈을 탐험합니다.';

  @override
  String get simFourier => '푸리에 변환';

  @override
  String get simFourierLevel => '신호처리';

  @override
  String get simFourierFormat => '시각화';

  @override
  String get simFourierSummary => '복잡한 파형을 원운동(에피사이클)으로 분해합니다.';

  @override
  String get simQuadratic => '이차함수 꼭짓점';

  @override
  String get simQuadraticLevel => '고등';

  @override
  String get simQuadraticFormat => '2D 그래프';

  @override
  String get simQuadraticSummary => 'a, b, c를 조정하고 꼭짓점 이동을 관찰합니다.';

  @override
  String get simVector => '벡터 내적 탐색기';

  @override
  String get simVectorLevel => '선형대수학';

  @override
  String get simVectorFormat => '2D 그래프';

  @override
  String get simVectorSummary => '벡터의 내적, 각도, 투영을 시각화합니다.';

  @override
  String get simProjectile => '발사체 운동';

  @override
  String get simProjectileLevel => '역학';

  @override
  String get simProjectileFormat => '시뮬레이션';

  @override
  String get simProjectileSummary => '각도와 속도에 따른 포물선 운동을 시뮬레이션합니다.';

  @override
  String get simSpring => '스프링 체인';

  @override
  String get simSpringLevel => '역학';

  @override
  String get simSpringFormat => '시뮬레이션';

  @override
  String get simSpringSummary => '연결된 스프링의 감쇠 조화 진동을 관찰합니다.';

  @override
  String get simActivation => '활성화 함수';

  @override
  String get simActivationLevel => '딥러닝';

  @override
  String get simActivationFormat => '시각화';

  @override
  String get simActivationSummary => 'ReLU, Sigmoid, GELU 등 신경망 활성화 함수를 비교합니다.';

  @override
  String get simLogistic => '로지스틱 맵';

  @override
  String get simLogisticLevel => '혼돈 이론';

  @override
  String get simLogisticFormat => '시각화';

  @override
  String get simLogisticSummary => '분기 다이어그램과 페이겐바움 상수를 통해 카오스의 시작을 관찰합니다.';

  @override
  String get simCollision => '입자 충돌';

  @override
  String get simCollisionLevel => '역학';

  @override
  String get simCollisionFormat => '시뮬레이션';

  @override
  String get simCollisionSummary => '운동량과 에너지 보존 법칙을 통한 탄성/비탄성 충돌을 시각화합니다.';

  @override
  String get simKMeans => 'K-Means 클러스터링';

  @override
  String get simKMeansLevel => '머신러닝';

  @override
  String get simKMeansFormat => '인터랙티브';

  @override
  String get simKMeansSummary => '비지도 학습으로 데이터를 K개 군집으로 분류하는 과정을 시각화합니다.';

  @override
  String get simPrime => '에라토스테네스의 체';

  @override
  String get simPrimeLevel => '정수론';

  @override
  String get simPrimeFormat => '알고리즘';

  @override
  String get simPrimeSummary => '고대 그리스의 소수 발견 알고리즘을 단계별로 시각화합니다.';

  @override
  String get simThreeBody => '3체 문제';

  @override
  String get simThreeBodyLevel => '혼돈 역학';

  @override
  String get simThreeBodyFormat => '시뮬레이션';

  @override
  String get simThreeBodySummary => '3개 천체의 중력 상호작용 - 해석적 해가 없는 혼돈 시스템.';

  @override
  String get simDecisionTree => '결정 트리';

  @override
  String get simDecisionTreeLevel => '머신러닝';

  @override
  String get simDecisionTreeFormat => '인터랙티브';

  @override
  String get simDecisionTreeSummary => '지니 불순도를 최소화하며 데이터를 분할하는 분류 알고리즘.';

  @override
  String get simSVM => 'SVM 분류기';

  @override
  String get simSVMLevel => '머신러닝';

  @override
  String get simSVMFormat => '인터랙티브';

  @override
  String get simSVMSummary => '최대 마진을 갖는 결정 경계를 찾는 서포트 벡터 머신.';

  @override
  String get simPCA => 'PCA 주성분 분석';

  @override
  String get simPCALevel => '머신러닝';

  @override
  String get simPCAFormat => '시각화';

  @override
  String get simPCASummary => '분산을 최대화하는 방향을 찾아 차원을 축소하는 기법.';

  @override
  String get simElectromagnetic => '전기장 시각화';

  @override
  String get simElectromagneticLevel => '전자기학';

  @override
  String get simElectromagneticFormat => '인터랙티브';

  @override
  String get simElectromagneticSummary => '점전하 주변의 전기장과 전기력선을 시각화합니다.';

  @override
  String get simGraphTheory => '그래프 탐색';

  @override
  String get simGraphTheoryLevel => '그래프 이론';

  @override
  String get simGraphTheoryFormat => '알고리즘';

  @override
  String get simGraphTheorySummary => 'BFS와 DFS로 그래프를 탐색하는 과정을 시각화합니다.';

  @override
  String get simBohrModel => '보어 모형';

  @override
  String get simBohrModelLevel => '원자 물리';

  @override
  String get simBohrModelFormat => '인터랙티브';

  @override
  String get simBohrModelSummary => '원자의 전자 궤도와 에너지 준위를 시각화합니다.';

  @override
  String get simChemicalBonding => '화학 결합';

  @override
  String get simChemicalBondingLevel => '화학';

  @override
  String get simChemicalBondingFormat => '인터랙티브';

  @override
  String get simChemicalBondingSummary => '이온 결합, 공유 결합, 금속 결합을 탐구합니다.';

  @override
  String get simElectronConfig => '전자 배치';

  @override
  String get simElectronConfigLevel => '화학';

  @override
  String get simElectronConfigFormat => '인터랙티브';

  @override
  String get simElectronConfigSummary => '전자 오비탈 채움 순서와 전자 배치를 학습합니다.';

  @override
  String get simEquationBalance => '화학식 균형';

  @override
  String get simEquationBalanceLevel => '화학';

  @override
  String get simEquationBalanceFormat => '인터랙티브';

  @override
  String get simEquationBalanceSummary => '화학 반응식 균형 맞추기를 단계별로 연습합니다.';

  @override
  String get simHydrogenBonding => '수소 결합';

  @override
  String get simHydrogenBondingLevel => '화학';

  @override
  String get simHydrogenBondingFormat => '시각화';

  @override
  String get simHydrogenBondingSummary => '수소 결합과 물질의 성질에 미치는 영향을 이해합니다.';

  @override
  String get simLewisStructure => '루이스 구조';

  @override
  String get simLewisStructureLevel => '화학';

  @override
  String get simLewisStructureFormat => '인터랙티브';

  @override
  String get simLewisStructureSummary => '분자의 루이스 점 구조를 그리고 이해합니다.';

  @override
  String get simMolecularGeometry => '분자 기하학';

  @override
  String get simMolecularGeometryLevel => '화학';

  @override
  String get simMolecularGeometryFormat => '3D 시각화';

  @override
  String get simMolecularGeometrySummary => 'VSEPR 이론과 3D 분자 모양을 탐구합니다.';

  @override
  String get simOxidationReduction => '산화-환원';

  @override
  String get simOxidationReductionLevel => '화학';

  @override
  String get simOxidationReductionFormat => '인터랙티브';

  @override
  String get simOxidationReductionSummary => '산화환원 반응에서 전자 이동을 학습합니다.';

  @override
  String get simAStar => 'A* 경로 탐색';

  @override
  String get simAStarLevel => '알고리즘';

  @override
  String get simAStarFormat => '인터랙티브';

  @override
  String get simAStarSummary => '휴리스틱을 사용한 A* 알고리즘으로 최적 경로를 찾습니다.';
}
