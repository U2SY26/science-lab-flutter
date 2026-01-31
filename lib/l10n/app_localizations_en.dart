// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Visual Science Lab';

  @override
  String get appSubtitle1 => 'Feel the';

  @override
  String get appSubtitle2 => 'Laws of Universe';

  @override
  String get categoryAll => 'All';

  @override
  String get categoryPhysics => 'Physics';

  @override
  String get categoryMath => 'Math';

  @override
  String get categoryChaos => 'Chaos';

  @override
  String get categoryAI => 'AI/ML';

  @override
  String get categoryChemistry => 'Chemistry';

  @override
  String get simulations => 'Simulations';

  @override
  String get completed => 'Completed';

  @override
  String get favorites => 'Favorites';

  @override
  String results(int count) {
    return '$count results';
  }

  @override
  String get searchSimulations => 'Search simulations...';

  @override
  String get settings => 'Settings';

  @override
  String get removeAds => 'Remove Ads';

  @override
  String monthlyPrice(String price) {
    return 'Monthly \$$price';
  }

  @override
  String get resetProgress => 'Reset Learning Progress';

  @override
  String get appInfo => 'App Info';

  @override
  String get start => 'Start';

  @override
  String get pressAgainToExit => 'Press again to exit';

  @override
  String get introTitle => 'Visual Science Lab';

  @override
  String get introDescription =>
      'Learn science and math principles through interactive simulations!';

  @override
  String get continuousUpdates => 'Continuous Updates';

  @override
  String get continuousUpdatesDesc =>
      'New simulations and features are continuously added.';

  @override
  String get webVersionAvailable => 'Web version available!';

  @override
  String get run => 'Run';

  @override
  String get stop => 'Stop';

  @override
  String get reset => 'Reset';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get simPendulum => 'Simple Pendulum';

  @override
  String get simPendulumLevel => 'Physics Engine';

  @override
  String get simPendulumFormat => 'Simulation';

  @override
  String get simPendulumSummary =>
      'Simulate pendulum motion based on string length and gravity.';

  @override
  String get simWave => 'Double Slit Interference';

  @override
  String get simWaveLevel => 'Physics Engine';

  @override
  String get simWaveFormat => 'Simulation';

  @override
  String get simWaveSummary =>
      'Observe interference patterns from two wave sources.';

  @override
  String get simGravity => 'Spacetime Curvature';

  @override
  String get simGravityLevel => 'General Relativity';

  @override
  String get simGravityFormat => '3D Simulation';

  @override
  String get simGravitySummary =>
      'Visualize spacetime curvature caused by mass in 3D grid.';

  @override
  String get simFormula => 'Math Graph';

  @override
  String get simFormulaLevel => 'High School';

  @override
  String get simFormulaFormat => '2D Graph';

  @override
  String get simFormulaSummary =>
      'Enter math functions to generate real-time graphs.';

  @override
  String get simLorenz => 'Lorenz Attractor';

  @override
  String get simLorenzLevel => 'Chaos Theory';

  @override
  String get simLorenzFormat => '3D Graph';

  @override
  String get simLorenzSummary =>
      'Chaos system visualizing the butterfly effect.';

  @override
  String get simDoublePendulum => 'Double Pendulum';

  @override
  String get simDoublePendulumLevel => 'Chaotic Dynamics';

  @override
  String get simDoublePendulumFormat => 'Simulation';

  @override
  String get simDoublePendulumSummary =>
      'Two connected pendulums demonstrating chaos theory.';

  @override
  String get simGameOfLife => 'Conway\'s Game of Life';

  @override
  String get simGameOfLifeLevel => 'Cellular Automata';

  @override
  String get simGameOfLifeFormat => 'Simulation';

  @override
  String get simGameOfLifeSummary =>
      'Cells evolve following rules of survival, birth, and death.';

  @override
  String get simSet => 'Set Operations';

  @override
  String get simSetLevel => 'Discrete Math';

  @override
  String get simSetFormat => 'Interactive';

  @override
  String get simSetSummary =>
      'Visualize union, intersection, difference with Venn diagrams.';

  @override
  String get simSorting => 'Sorting Algorithms';

  @override
  String get simSortingLevel => 'Algorithms';

  @override
  String get simSortingFormat => 'Animation';

  @override
  String get simSortingSummary =>
      'Compare bubble, quick, merge sort step by step.';

  @override
  String get simNeuralNet => 'Neural Network Playground';

  @override
  String get simNeuralNetLevel => 'Deep Learning';

  @override
  String get simNeuralNetFormat => 'Interactive';

  @override
  String get simNeuralNetSummary =>
      'Visualize forward propagation, backpropagation, weight learning.';

  @override
  String get simGradient => 'Gradient Descent';

  @override
  String get simGradientLevel => 'Optimization';

  @override
  String get simGradientFormat => 'Visualization';

  @override
  String get simGradientSummary =>
      'Visualize gradient descent convergence to minimize loss function.';

  @override
  String get simMandelbrot => 'Mandelbrot Set';

  @override
  String get simMandelbrotLevel => 'Fractal';

  @override
  String get simMandelbrotFormat => 'Interactive';

  @override
  String get simMandelbrotSummary =>
      'Explore fractals of infinite complexity: zₙ₊₁ = zₙ² + c';

  @override
  String get simFourier => 'Fourier Transform';

  @override
  String get simFourierLevel => 'Signal Processing';

  @override
  String get simFourierFormat => 'Visualization';

  @override
  String get simFourierSummary =>
      'Decompose complex waveforms into circular motions (epicycles).';

  @override
  String get simQuadratic => 'Quadratic Vertex';

  @override
  String get simQuadraticLevel => 'High School';

  @override
  String get simQuadraticFormat => '2D Graph';

  @override
  String get simQuadraticSummary =>
      'Adjust a, b, c and observe vertex movement.';

  @override
  String get simVector => 'Vector Dot Product Explorer';

  @override
  String get simVectorLevel => 'Linear Algebra';

  @override
  String get simVectorFormat => '2D Graph';

  @override
  String get simVectorSummary =>
      'Visualize dot product, angle, projection of vectors.';

  @override
  String get simProjectile => 'Projectile Motion';

  @override
  String get simProjectileLevel => 'Mechanics';

  @override
  String get simProjectileFormat => 'Simulation';

  @override
  String get simProjectileSummary =>
      'Simulate parabolic motion based on angle and velocity.';

  @override
  String get simSpring => 'Spring Chain';

  @override
  String get simSpringLevel => 'Mechanics';

  @override
  String get simSpringFormat => 'Simulation';

  @override
  String get simSpringSummary =>
      'Observe damped harmonic oscillation of connected springs.';

  @override
  String get simActivation => 'Activation Functions';

  @override
  String get simActivationLevel => 'Deep Learning';

  @override
  String get simActivationFormat => 'Visualization';

  @override
  String get simActivationSummary =>
      'Compare ReLU, Sigmoid, GELU and other neural network activations.';

  @override
  String get simLogistic => 'Logistic Map';

  @override
  String get simLogisticLevel => 'Chaos Theory';

  @override
  String get simLogisticFormat => 'Visualization';

  @override
  String get simLogisticSummary =>
      'Observe chaos emergence through bifurcation diagram and Feigenbaum constant.';

  @override
  String get simCollision => 'Particle Collision';

  @override
  String get simCollisionLevel => 'Mechanics';

  @override
  String get simCollisionFormat => 'Simulation';

  @override
  String get simCollisionSummary =>
      'Visualize elastic/inelastic collisions with momentum and energy conservation.';

  @override
  String get simKMeans => 'K-Means Clustering';

  @override
  String get simKMeansLevel => 'Machine Learning';

  @override
  String get simKMeansFormat => 'Interactive';

  @override
  String get simKMeansSummary =>
      'Visualize unsupervised learning clustering data into K groups.';

  @override
  String get simPrime => 'Sieve of Eratosthenes';

  @override
  String get simPrimeLevel => 'Number Theory';

  @override
  String get simPrimeFormat => 'Algorithm';

  @override
  String get simPrimeSummary =>
      'Visualize the ancient Greek prime number discovery algorithm step by step.';

  @override
  String get simThreeBody => 'Three Body Problem';

  @override
  String get simThreeBodyLevel => 'Chaotic Dynamics';

  @override
  String get simThreeBodyFormat => 'Simulation';

  @override
  String get simThreeBodySummary =>
      'Gravitational interaction of 3 bodies - chaotic system with no analytical solution.';

  @override
  String get simDecisionTree => 'Decision Tree';

  @override
  String get simDecisionTreeLevel => 'Machine Learning';

  @override
  String get simDecisionTreeFormat => 'Interactive';

  @override
  String get simDecisionTreeSummary =>
      'Classification algorithm that splits data by minimizing Gini impurity.';

  @override
  String get simSVM => 'SVM Classifier';

  @override
  String get simSVMLevel => 'Machine Learning';

  @override
  String get simSVMFormat => 'Interactive';

  @override
  String get simSVMSummary =>
      'Support Vector Machine finding maximum margin decision boundary.';

  @override
  String get simPCA => 'PCA Analysis';

  @override
  String get simPCALevel => 'Machine Learning';

  @override
  String get simPCAFormat => 'Visualization';

  @override
  String get simPCASummary =>
      'Dimensionality reduction by finding directions of maximum variance.';

  @override
  String get simElectromagnetic => 'Electric Field Visualization';

  @override
  String get simElectromagneticLevel => 'Electromagnetism';

  @override
  String get simElectromagneticFormat => 'Interactive';

  @override
  String get simElectromagneticSummary =>
      'Visualize electric field and field lines around point charges.';

  @override
  String get simGraphTheory => 'Graph Traversal';

  @override
  String get simGraphTheoryLevel => 'Graph Theory';

  @override
  String get simGraphTheoryFormat => 'Algorithm';

  @override
  String get simGraphTheorySummary =>
      'Visualize BFS and DFS graph traversal processes.';

  @override
  String get simBohrModel => 'Bohr Model';

  @override
  String get simBohrModelLevel => 'Atomic Physics';

  @override
  String get simBohrModelFormat => 'Interactive';

  @override
  String get simBohrModelSummary =>
      'Visualize electron orbits and energy levels in atoms.';

  @override
  String get simChemicalBonding => 'Chemical Bonding';

  @override
  String get simChemicalBondingLevel => 'Chemistry';

  @override
  String get simChemicalBondingFormat => 'Interactive';

  @override
  String get simChemicalBondingSummary =>
      'Explore ionic, covalent, and metallic bonds.';

  @override
  String get simElectronConfig => 'Electron Configuration';

  @override
  String get simElectronConfigLevel => 'Chemistry';

  @override
  String get simElectronConfigFormat => 'Interactive';

  @override
  String get simElectronConfigSummary =>
      'Learn electron orbital filling order and configuration.';

  @override
  String get simEquationBalance => 'Equation Balancing';

  @override
  String get simEquationBalanceLevel => 'Chemistry';

  @override
  String get simEquationBalanceFormat => 'Interactive';

  @override
  String get simEquationBalanceSummary =>
      'Practice balancing chemical equations step by step.';

  @override
  String get simHydrogenBonding => 'Hydrogen Bonding';

  @override
  String get simHydrogenBondingLevel => 'Chemistry';

  @override
  String get simHydrogenBondingFormat => 'Visualization';

  @override
  String get simHydrogenBondingSummary =>
      'Understand hydrogen bonds and their effects on properties.';

  @override
  String get simLewisStructure => 'Lewis Structure';

  @override
  String get simLewisStructureLevel => 'Chemistry';

  @override
  String get simLewisStructureFormat => 'Interactive';

  @override
  String get simLewisStructureSummary =>
      'Draw and understand Lewis dot structures of molecules.';

  @override
  String get simMolecularGeometry => 'Molecular Geometry';

  @override
  String get simMolecularGeometryLevel => 'Chemistry';

  @override
  String get simMolecularGeometryFormat => '3D Visualization';

  @override
  String get simMolecularGeometrySummary =>
      'Explore VSEPR theory and 3D molecular shapes.';

  @override
  String get simOxidationReduction => 'Oxidation-Reduction';

  @override
  String get simOxidationReductionLevel => 'Chemistry';

  @override
  String get simOxidationReductionFormat => 'Interactive';

  @override
  String get simOxidationReductionSummary =>
      'Learn electron transfer in redox reactions.';

  @override
  String get simAStar => 'A* Pathfinding';

  @override
  String get simAStarLevel => 'Algorithms';

  @override
  String get simAStarFormat => 'Interactive';

  @override
  String get simAStarSummary =>
      'Find optimal path using A* search algorithm with heuristics.';
}
