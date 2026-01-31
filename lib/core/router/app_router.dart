import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../animations/animations.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/promo_video_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/home/presentation/main_shell.dart';
import '../../features/home/presentation/category_screen.dart';
import '../../features/physics/pendulum/pendulum_screen.dart';
import '../../features/physics/double_pendulum/double_pendulum_screen.dart';
import '../../features/physics/wave_interference/wave_interference_screen.dart';
import '../../features/physics/game_of_life/game_of_life_screen.dart';
import '../../features/chaos/lorenz/lorenz_screen.dart';
import '../../features/mathematics/formula_graph/formula_graph_screen.dart';
import '../../features/mathematics/set_theory/set_theory_screen.dart';
import '../../features/mathematics/mandelbrot/mandelbrot_screen.dart';
import '../../features/mathematics/fourier/fourier_screen.dart';
import '../../features/mathematics/quadratic/quadratic_screen.dart';
import '../../features/algorithms/sorting/sorting_screen.dart';
import '../../features/deep_learning/neural_network/neural_network_screen.dart';
import '../../features/deep_learning/gradient_descent/gradient_descent_screen.dart';
import '../../features/deep_learning/activation/activation_screen.dart';
import '../../features/physics/projectile/projectile_screen.dart';
import '../../features/physics/spring/spring_screen.dart';
import '../../features/chaos/logistic/logistic_screen.dart';
import '../../features/mathematics/vector/vector_screen.dart';
import '../../features/physics/collision/collision_screen.dart';
import '../../features/machine_learning/kmeans/kmeans_screen.dart';
import '../../features/mathematics/prime/prime_screen.dart';
import '../../features/chaos/threebody/threebody_screen.dart';
import '../../features/machine_learning/decision_tree/decision_tree_screen.dart';
import '../../features/machine_learning/svm/svm_screen.dart';
import '../../features/machine_learning/pca/pca_screen.dart';
import '../../features/physics/electromagnetic/electromagnetic_screen.dart';
import '../../features/mathematics/graph_theory/graph_theory_screen.dart';
// Chemistry
import '../../features/chemistry/bohr_model/bohr_model_screen.dart';
import '../../features/chemistry/electron_config/electron_config_screen.dart';
import '../../features/chemistry/periodic_table/periodic_table_screen.dart';
import '../../features/chemistry/equation_balance/equation_balance_screen.dart';
import '../../features/chemistry/reaction_kinetics/reaction_kinetics_screen.dart';
import '../../features/chemistry/ph_scale/ph_scale_screen.dart';
import '../../features/chemistry/molecular_geometry/molecular_geometry_screen.dart';
import '../../features/chemistry/chemical_bonding/chemical_bonding_screen.dart';
import '../../features/chemistry/lewis_structure/lewis_structure_screen.dart';
import '../../features/chemistry/hydrogen_bonding/hydrogen_bonding_screen.dart';
import '../../features/chemistry/oxidation_reduction/oxidation_reduction_screen.dart';
import '../../features/chemistry/titration/titration_screen.dart';
// Physics - New
import '../../features/physics/doppler/doppler_screen.dart';
import '../../features/physics/ideal_gas/ideal_gas_screen.dart';
import '../../features/physics/snell/snell_screen.dart';
import '../../features/physics/brownian/brownian_screen.dart';
import '../../features/physics/standing_wave/standing_wave_screen.dart';
import '../../features/physics/lens/lens_screen.dart';
import '../../features/physics/centripetal/centripetal_screen.dart';
import '../../features/physics/damped_oscillator/damped_oscillator_screen.dart';
import '../../features/physics/friction/friction_screen.dart';
import '../../features/physics/atwood/atwood_screen.dart';
import '../../features/physics/resonance/resonance_screen.dart';
import '../../features/physics/beats/beats_screen.dart';
import '../../features/physics/heat_conduction/heat_conduction_screen.dart';
import '../../features/physics/roller_coaster/roller_coaster_screen.dart';
import '../../features/physics/angular_momentum/angular_momentum_screen.dart';
import '../../features/physics/pulley/pulley_screen.dart';
import '../../features/physics/elastic_ball/elastic_ball_screen.dart';
import '../../features/physics/rocket/rocket_screen.dart';
import '../../features/physics/phase_transition/phase_transition_screen.dart';
import '../../features/physics/gravity_field/gravity_field_screen.dart';
import '../../features/physics/wavelength/wavelength_screen.dart';
import '../../features/physics/ripple_wave/ripple_wave_screen.dart';
import '../../features/physics/spacetime_curvature/spacetime_curvature_screen.dart';
// AI/ML - New
import '../../features/machine_learning/linear_regression/linear_regression_screen.dart';
import '../../features/machine_learning/knn/knn_screen.dart';
import '../../features/machine_learning/perceptron/perceptron_screen.dart';
import '../../features/algorithms/astar/astar_screen.dart';
import '../../features/machine_learning/genetic/genetic_screen.dart';
import '../../features/deep_learning/dropout/dropout_screen.dart';
import '../../features/deep_learning/loss_functions/loss_functions_screen.dart';
// Math - New
import '../../features/mathematics/taylor_series/taylor_series_screen.dart';
import '../../features/mathematics/monte_carlo/monte_carlo_screen.dart';
import '../../features/mathematics/pascal_triangle/pascal_triangle_screen.dart';
import '../../features/mathematics/galton_board/galton_board_screen.dart';
import '../../features/mathematics/golden_ratio/golden_ratio_screen.dart';
import '../../features/mathematics/derivative/derivative_screen.dart';
import '../../features/mathematics/riemann_sum/riemann_sum_screen.dart';
import '../../features/mathematics/limit_explorer/limit_explorer_screen.dart';
import '../../features/mathematics/circle_theorems/circle_theorems_screen.dart';
import '../../features/mathematics/pythagorean/pythagorean_screen.dart';
import '../../features/mathematics/conic_sections/conic_sections_screen.dart';
import '../../features/mathematics/tessellation/tessellation_screen.dart';
import '../../features/mathematics/central_limit/central_limit_screen.dart';
import '../../features/mathematics/normal_distribution/normal_distribution_screen.dart';
import '../../features/mathematics/random_walk/random_walk_screen.dart';
// Millennium Problems
import '../../features/mathematics/riemann_hypothesis/riemann_hypothesis_screen.dart';
import '../../features/mathematics/p_vs_np/p_vs_np_screen.dart';
import '../../features/mathematics/navier_stokes/navier_stokes_screen.dart';
import '../../features/mathematics/poincare/poincare_screen.dart';

/// 앱 라우터 설정
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // 스플래시 (초기 화면)
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    // 프로모 영상 (최초 실행 시)
    GoRoute(
      path: '/promo',
      builder: (context, state) => const PromoVideoScreen(),
    ),
    // 온보딩
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => FadeSlideTransitionPage(
        key: state.pageKey,
        child: const OnboardingScreen(),
      ),
    ),
    // 메인 (하단 네비게이션 포함)
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => FadeSlideTransitionPage(
        key: state.pageKey,
        child: const MainShell(),
      ),
    ),
    // 카테고리별 시뮬레이션 목록
    GoRoute(
      path: '/category/:categoryId',
      pageBuilder: (context, state) {
        final categoryId = state.pathParameters['categoryId']!;
        return ScaleFadeTransitionPage(
          key: state.pageKey,
          child: CategoryScreen(categoryId: categoryId),
        );
      },
    ),
    // 시뮬레이션
    GoRoute(
      path: '/simulation/:simId',
      pageBuilder: (context, state) {
        final simId = state.pathParameters['simId']!;
        return ScaleFadeTransitionPage(
          key: state.pageKey,
          child: _getSimulationScreen(simId),
        );
      },
    ),
  ],
);

Widget _getSimulationScreen(String simId) {
  switch (simId) {
    case 'pendulum':
      return const PendulumScreen();
    case 'double-pendulum':
      return const DoublePendulumScreen();
    case 'wave':
      return const WaveInterferenceScreen();
    case 'gameoflife':
      return const GameOfLifeScreen();
    case 'lorenz':
      return const LorenzScreen();
    case 'formula':
      return const FormulaGraphScreen();
    case 'set':
      return const SetTheoryScreen();
    case 'mandelbrot':
      return const MandelbrotScreen();
    case 'fourier':
      return const FourierScreen();
    case 'quadratic':
      return const QuadraticScreen();
    case 'sorting':
      return const SortingScreen();
    case 'neuralnet':
      return const NeuralNetworkScreen();
    case 'gradient':
      return const GradientDescentScreen();
    case 'activation':
      return const ActivationScreen();
    case 'projectile':
      return const ProjectileScreen();
    case 'spring':
      return const SpringScreen();
    case 'logistic':
      return const LogisticScreen();
    case 'vector':
      return const VectorScreen();
    case 'collision':
      return const CollisionScreen();
    case 'kmeans':
      return const KMeansScreen();
    case 'prime':
      return const PrimeScreen();
    case 'threebody':
      return const ThreeBodyScreen();
    case 'decision-tree':
      return const DecisionTreeScreen();
    case 'svm':
      return const SvmScreen();
    case 'pca':
      return const PcaScreen();
    case 'electromagnetic':
      return const ElectromagneticScreen();
    case 'graph-theory':
      return const GraphTheoryScreen();
    // Chemistry
    case 'bohr-model':
      return const BohrModelScreen();
    case 'electron-config':
      return const ElectronConfigScreen();
    case 'periodic-table':
      return const PeriodicTableScreen();
    case 'equation-balance':
      return const EquationBalanceScreen();
    case 'reaction-kinetics':
      return const ReactionKineticsScreen();
    case 'ph-scale':
      return const PhScaleScreen();
    case 'molecular-geometry':
      return const MolecularGeometryScreen();
    case 'chemical-bonding':
      return const ChemicalBondingScreen();
    case 'lewis-structure':
      return const LewisStructureScreen();
    case 'hydrogen-bonding':
      return const HydrogenBondingScreen();
    case 'oxidation-reduction':
      return const OxidationReductionScreen();
    case 'titration':
      return const TitrationScreen();
    // Physics - New
    case 'doppler':
      return const DopplerScreen();
    case 'ideal-gas':
      return const IdealGasScreen();
    case 'snell':
      return const SnellScreen();
    case 'brownian':
      return const BrownianScreen();
    case 'standing-wave':
      return const StandingWaveScreen();
    case 'lens':
      return const LensScreen();
    case 'centripetal':
      return const CentripetalScreen();
    case 'damped-oscillator':
      return const DampedOscillatorScreen();
    case 'friction':
      return const FrictionScreen();
    case 'atwood':
      return const AtwoodScreen();
    case 'resonance':
      return const ResonanceScreen();
    case 'beats':
      return const BeatsScreen();
    case 'heat-conduction':
      return const HeatConductionScreen();
    case 'roller-coaster':
      return const RollerCoasterScreen();
    case 'angular-momentum':
      return const AngularMomentumScreen();
    case 'pulley':
      return const PulleyScreen();
    case 'elastic-ball':
      return const ElasticBallScreen();
    case 'rocket':
      return const RocketScreen();
    case 'phase-transition':
      return const PhaseTransitionScreen();
    case 'gravity-field':
      return const GravityFieldScreen();
    case 'wavelength':
      return const WavelengthScreen();
    case 'ripple-wave':
      return const RippleWaveScreen();
    case 'spacetime-curvature':
      return const SpacetimeCurvatureScreen();
    // AI/ML - New
    case 'linear-regression':
      return const LinearRegressionScreen();
    case 'knn':
      return const KnnScreen();
    case 'perceptron':
      return const PerceptronScreen();
    case 'astar':
      return const AstarScreen();
    case 'genetic':
      return const GeneticScreen();
    case 'dropout':
      return const DropoutScreen();
    case 'loss-functions':
      return const LossFunctionsScreen();
    // Math - New
    case 'taylor-series':
      return const TaylorSeriesScreen();
    case 'monte-carlo':
      return const MonteCarloScreen();
    case 'pascal-triangle':
      return const PascalTriangleScreen();
    case 'galton-board':
      return const GaltonBoardScreen();
    case 'golden-ratio':
      return const GoldenRatioScreen();
    case 'derivative':
      return const DerivativeScreen();
    case 'riemann-sum':
      return const RiemannSumScreen();
    case 'limit-explorer':
      return const LimitExplorerScreen();
    case 'circle-theorems':
      return const CircleTheoremsScreen();
    case 'pythagorean':
      return const PythagoreanScreen();
    case 'conic-sections':
      return const ConicSectionsScreen();
    case 'tessellation':
      return const TessellationScreen();
    case 'central-limit':
      return const CentralLimitScreen();
    case 'normal-distribution':
      return const NormalDistributionScreen();
    case 'random-walk':
      return const RandomWalkScreen();
    // Millennium Problems
    case 'riemann-hypothesis':
      return const RiemannHypothesisScreen();
    case 'p-vs-np':
      return const PVsNpScreen();
    case 'navier-stokes':
      return const NavierStokesScreen();
    case 'poincare':
      return const PoincareScreen();
    default:
      return _ComingSoonScreen(simId: simId);
  }
}

class _ComingSoonScreen extends StatelessWidget {
  final String simId;

  const _ComingSoonScreen({required this.simId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(simId),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '준비 중입니다',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '이 시뮬레이션은 곧 추가될 예정입니다.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
