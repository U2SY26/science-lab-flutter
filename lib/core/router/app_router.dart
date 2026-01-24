import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../animations/animations.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/home/presentation/home_screen.dart';
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

/// 앱 라우터 설정
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // 스플래시 (초기 화면)
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    // 온보딩
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => FadeSlideTransitionPage(
        key: state.pageKey,
        child: const OnboardingScreen(),
      ),
    ),
    // 홈
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => FadeSlideTransitionPage(
        key: state.pageKey,
        child: const HomeScreen(),
      ),
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
          onPressed: () => context.go('/home'),
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
