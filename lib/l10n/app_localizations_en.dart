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
      'Explore how pendulum period depends on string length and gravitational acceleration.';

  @override
  String get simWave => 'Double-Slit Interference';

  @override
  String get simWaveLevel => 'Wave Physics';

  @override
  String get simWaveFormat => 'Simulation';

  @override
  String get simWaveSummary =>
      'Observe constructive and destructive interference patterns from two coherent wave sources.';

  @override
  String get simGravity => 'Spacetime Curvature';

  @override
  String get simGravityLevel => 'General Relativity';

  @override
  String get simGravityFormat => '3D Simulation';

  @override
  String get simGravitySummary =>
      'Visualize how mass warps the spacetime fabric on an interactive 3D grid.';

  @override
  String get simFormula => 'Math Function Grapher';

  @override
  String get simFormulaLevel => 'High School';

  @override
  String get simFormulaFormat => '2D Graph';

  @override
  String get simFormulaSummary =>
      'Enter any mathematical function and generate its real-time graph instantly.';

  @override
  String get simLorenz => 'Lorenz Attractor';

  @override
  String get simLorenzLevel => 'Chaos Theory';

  @override
  String get simLorenzFormat => '3D Graph';

  @override
  String get simLorenzSummary =>
      'Visualize the butterfly effect through the classic Lorenz chaotic attractor.';

  @override
  String get simDoublePendulum => 'Double Pendulum';

  @override
  String get simDoublePendulumLevel => 'Chaotic Dynamics';

  @override
  String get simDoublePendulumFormat => 'Simulation';

  @override
  String get simDoublePendulumSummary =>
      'Two coupled pendulums demonstrating extreme sensitivity to initial conditions.';

  @override
  String get simGameOfLife => 'Conway\'s Game of Life';

  @override
  String get simGameOfLifeLevel => 'Cellular Automata';

  @override
  String get simGameOfLifeFormat => 'Simulation';

  @override
  String get simGameOfLifeSummary =>
      'Cells evolve following simple rules of survival, birth, and death — emergent complexity from simplicity.';

  @override
  String get simSet => 'Set Operations';

  @override
  String get simSetLevel => 'Discrete Math';

  @override
  String get simSetFormat => 'Interactive';

  @override
  String get simSetSummary =>
      'Visualize union, intersection, and difference of sets using interactive Venn diagrams.';

  @override
  String get simSorting => 'Sorting Algorithms';

  @override
  String get simSortingLevel => 'Algorithms';

  @override
  String get simSortingFormat => 'Animation';

  @override
  String get simSortingSummary =>
      'Compare bubble, quick, and merge sort step by step with animated bar charts.';

  @override
  String get simNeuralNet => 'Neural Network Playground';

  @override
  String get simNeuralNetLevel => 'Deep Learning';

  @override
  String get simNeuralNetFormat => 'Interactive';

  @override
  String get simNeuralNetSummary =>
      'Interactively train a neural network and watch forward propagation, backpropagation, and weight updates.';

  @override
  String get simGradient => 'Gradient Descent';

  @override
  String get simGradientLevel => 'Optimization';

  @override
  String get simGradientFormat => 'Visualization';

  @override
  String get simGradientSummary =>
      'Watch gradient descent navigate a loss surface to find the minimum step by step.';

  @override
  String get simMandelbrot => 'Mandelbrot Set';

  @override
  String get simMandelbrotLevel => 'Fractal';

  @override
  String get simMandelbrotFormat => 'Interactive';

  @override
  String get simMandelbrotSummary =>
      'Explore the infinitely complex boundary of the Mandelbrot set: zₙ₊₁ = zₙ² + c';

  @override
  String get simFourier => 'Fourier Transform';

  @override
  String get simFourierLevel => 'Signal Processing';

  @override
  String get simFourierFormat => 'Visualization';

  @override
  String get simFourierSummary =>
      'Decompose complex waveforms into sums of circular motions (epicycles).';

  @override
  String get simQuadratic => 'Quadratic Function Explorer';

  @override
  String get simQuadraticLevel => 'High School';

  @override
  String get simQuadraticFormat => '2D Graph';

  @override
  String get simQuadraticSummary =>
      'Adjust coefficients a, b, c and observe how the vertex and roots change.';

  @override
  String get simVector => 'Vector Dot Product Explorer';

  @override
  String get simVectorLevel => 'Linear Algebra';

  @override
  String get simVectorFormat => '2D Graph';

  @override
  String get simVectorSummary =>
      'Interactively visualize dot product, angle, and projection of 2D vectors.';

  @override
  String get simProjectile => 'Projectile Motion';

  @override
  String get simProjectileLevel => 'Mechanics';

  @override
  String get simProjectileFormat => 'Simulation';

  @override
  String get simProjectileSummary =>
      'Simulate parabolic trajectories by adjusting launch angle and initial velocity.';

  @override
  String get simSpring => 'Spring Chain';

  @override
  String get simSpringLevel => 'Mechanics';

  @override
  String get simSpringFormat => 'Simulation';

  @override
  String get simSpringSummary =>
      'Observe damped harmonic oscillation in a chain of connected springs.';

  @override
  String get simActivation => 'Activation Functions';

  @override
  String get simActivationLevel => 'Deep Learning';

  @override
  String get simActivationFormat => 'Visualization';

  @override
  String get simActivationSummary =>
      'Compare ReLU, Sigmoid, Tanh, GELU and other neural network activation functions.';

  @override
  String get simLogistic => 'Logistic Map';

  @override
  String get simLogisticLevel => 'Chaos Theory';

  @override
  String get simLogisticFormat => 'Visualization';

  @override
  String get simLogisticSummary =>
      'Observe the period-doubling route to chaos via the bifurcation diagram and Feigenbaum constant.';

  @override
  String get simCollision => 'Particle Collision';

  @override
  String get simCollisionLevel => 'Mechanics';

  @override
  String get simCollisionFormat => 'Simulation';

  @override
  String get simCollisionSummary =>
      'Visualize elastic and inelastic collisions with conservation of momentum and energy.';

  @override
  String get simKMeans => 'K-Means Clustering';

  @override
  String get simKMeansLevel => 'Machine Learning';

  @override
  String get simKMeansFormat => 'Interactive';

  @override
  String get simKMeansSummary =>
      'Watch unsupervised learning partition data into K clusters through iterative centroid updates.';

  @override
  String get simPrime => 'Sieve of Eratosthenes';

  @override
  String get simPrimeLevel => 'Number Theory';

  @override
  String get simPrimeFormat => 'Algorithm';

  @override
  String get simPrimeSummary =>
      'Visualize the ancient prime-finding algorithm eliminating multiples step by step.';

  @override
  String get simThreeBody => 'Three-Body Problem';

  @override
  String get simThreeBodyLevel => 'Chaotic Dynamics';

  @override
  String get simThreeBodyFormat => 'Simulation';

  @override
  String get simThreeBodySummary =>
      'Gravitational interaction of three bodies — a chaotic system with no closed-form solution.';

  @override
  String get simDecisionTree => 'Decision Tree';

  @override
  String get simDecisionTreeLevel => 'Machine Learning';

  @override
  String get simDecisionTreeFormat => 'Interactive';

  @override
  String get simDecisionTreeSummary =>
      'Classification algorithm that recursively splits data by minimizing Gini impurity.';

  @override
  String get simSVM => 'SVM Classifier';

  @override
  String get simSVMLevel => 'Machine Learning';

  @override
  String get simSVMFormat => 'Interactive';

  @override
  String get simSVMSummary =>
      'Support Vector Machine finding the maximum-margin decision boundary between classes.';

  @override
  String get simPCA => 'Principal Component Analysis';

  @override
  String get simPCALevel => 'Machine Learning';

  @override
  String get simPCAFormat => 'Visualization';

  @override
  String get simPCASummary =>
      'Dimensionality reduction by projecting data onto directions of maximum variance.';

  @override
  String get simElectromagnetic => 'Electric Field Visualization';

  @override
  String get simElectromagneticLevel => 'Electromagnetism';

  @override
  String get simElectromagneticFormat => 'Interactive';

  @override
  String get simElectromagneticSummary =>
      'Visualize electric field vectors and field lines around point charges.';

  @override
  String get simGraphTheory => 'Graph Traversal';

  @override
  String get simGraphTheoryLevel => 'Graph Theory';

  @override
  String get simGraphTheoryFormat => 'Algorithm';

  @override
  String get simGraphTheorySummary =>
      'Visualize breadth-first search (BFS) and depth-first search (DFS) on graphs.';

  @override
  String get simBohrModel => 'Bohr Atomic Model';

  @override
  String get simBohrModelLevel => 'Atomic Physics';

  @override
  String get simBohrModelFormat => 'Interactive';

  @override
  String get simBohrModelSummary =>
      'Visualize quantized electron orbits and energy level transitions in atoms.';

  @override
  String get simChemicalBonding => 'Chemical Bonding';

  @override
  String get simChemicalBondingLevel => 'Chemistry';

  @override
  String get simChemicalBondingFormat => 'Interactive';

  @override
  String get simChemicalBondingSummary =>
      'Explore ionic, covalent, and metallic bond types and their properties.';

  @override
  String get simElectronConfig => 'Electron Configuration';

  @override
  String get simElectronConfigLevel => 'Chemistry';

  @override
  String get simElectronConfigFormat => 'Interactive';

  @override
  String get simElectronConfigSummary =>
      'Learn the Aufbau principle and electron orbital filling order for any element.';

  @override
  String get simEquationBalance => 'Chemical Equation Balancing';

  @override
  String get simEquationBalanceLevel => 'Chemistry';

  @override
  String get simEquationBalanceFormat => 'Interactive';

  @override
  String get simEquationBalanceSummary =>
      'Practice balancing chemical equations step by step using the law of conservation of mass.';

  @override
  String get simHydrogenBonding => 'Hydrogen Bonding';

  @override
  String get simHydrogenBondingLevel => 'Chemistry';

  @override
  String get simHydrogenBondingFormat => 'Visualization';

  @override
  String get simHydrogenBondingSummary =>
      'Understand hydrogen bonds and their role in water\'s anomalous properties.';

  @override
  String get simLewisStructure => 'Lewis Dot Structures';

  @override
  String get simLewisStructureLevel => 'Chemistry';

  @override
  String get simLewisStructureFormat => 'Interactive';

  @override
  String get simLewisStructureSummary =>
      'Draw and interpret Lewis dot structures showing valence electrons in molecules.';

  @override
  String get simMolecularGeometry => 'Molecular Geometry (VSEPR)';

  @override
  String get simMolecularGeometryLevel => 'Chemistry';

  @override
  String get simMolecularGeometryFormat => '3D Visualization';

  @override
  String get simMolecularGeometrySummary =>
      'Predict 3D molecular shapes using VSEPR theory for various electron geometries.';

  @override
  String get simOxidationReduction => 'Oxidation-Reduction Reactions';

  @override
  String get simOxidationReductionLevel => 'Chemistry';

  @override
  String get simOxidationReductionFormat => 'Interactive';

  @override
  String get simOxidationReductionSummary =>
      'Track electron transfer between oxidizing and reducing agents in redox reactions.';

  @override
  String get simAStar => 'A* Pathfinding';

  @override
  String get simAStarLevel => 'Algorithms';

  @override
  String get simAStarFormat => 'Interactive';

  @override
  String get simAStarSummary =>
      'Find optimal paths using the A* search algorithm with admissible heuristics.';

  @override
  String get simSimpleHarmonic => 'Simple Harmonic Motion';

  @override
  String get simSimpleHarmonicLevel => 'Mechanics';

  @override
  String get simSimpleHarmonicFormat => 'Interactive';

  @override
  String get simSimpleHarmonicSummary =>
      'Explore oscillatory motion of a mass-spring system: position, velocity, and energy over time. x(t) = A·cos(ωt + φ)';

  @override
  String get simCoupledOscillators => 'Coupled Oscillators';

  @override
  String get simCoupledOscillatorsLevel => 'University Physics';

  @override
  String get simCoupledOscillatorsFormat => 'Interactive';

  @override
  String get simCoupledOscillatorsSummary =>
      'Visualize normal modes and energy exchange between two masses connected by springs.';

  @override
  String get simGyroscope => 'Gyroscopic Precession';

  @override
  String get simGyroscopeLevel => 'University Physics';

  @override
  String get simGyroscopeFormat => 'Interactive';

  @override
  String get simGyroscopeSummary =>
      'Observe how a spinning gyroscope precesses under gravitational torque. Ω = τ/L';

  @override
  String get simBallisticPendulum => 'Ballistic Pendulum';

  @override
  String get simBallisticPendulumLevel => 'Mechanics';

  @override
  String get simBallisticPendulumFormat => 'Interactive';

  @override
  String get simBallisticPendulumSummary =>
      'Measure projectile speed by combining conservation of momentum and energy.';

  @override
  String get simGameTheory => 'Nash Equilibrium';

  @override
  String get simGameTheoryLevel => 'Game Theory';

  @override
  String get simGameTheoryFormat => 'Interactive';

  @override
  String get simGameTheorySummary =>
      'Find Nash equilibria in two-player strategic games using payoff matrices.';

  @override
  String get simPrisonersDilemma => 'Prisoner\'s Dilemma';

  @override
  String get simPrisonersDilemmaLevel => 'Game Theory';

  @override
  String get simPrisonersDilemmaFormat => 'Interactive';

  @override
  String get simPrisonersDilemmaSummary =>
      'Simulate iterated prisoner\'s dilemma tournaments with strategies like Tit-for-Tat.';

  @override
  String get simLinearProgramming => 'Linear Programming';

  @override
  String get simLinearProgrammingLevel => 'Operations Research';

  @override
  String get simLinearProgrammingFormat => 'Interactive';

  @override
  String get simLinearProgrammingSummary =>
      'Visualize feasible regions and find optimal solutions graphically for LP problems.';

  @override
  String get simSimplexMethod => 'Simplex Algorithm';

  @override
  String get simSimplexMethodLevel => 'Operations Research';

  @override
  String get simSimplexMethodFormat => 'Interactive';

  @override
  String get simSimplexMethodSummary =>
      'Step through the simplex method tableau to solve linear programming problems.';

  @override
  String get simNaiveBayes => 'Naive Bayes Classifier';

  @override
  String get simNaiveBayesLevel => 'Machine Learning';

  @override
  String get simNaiveBayesFormat => 'Interactive';

  @override
  String get simNaiveBayesSummary =>
      'Classify data using Bayes\' theorem with the conditional independence assumption. P(C|X) ∝ P(X|C)·P(C)';

  @override
  String get simRandomForest => 'Random Forest';

  @override
  String get simRandomForestLevel => 'Machine Learning';

  @override
  String get simRandomForestFormat => 'Interactive';

  @override
  String get simRandomForestSummary =>
      'Visualize how an ensemble of decision trees votes to form a robust classifier.';

  @override
  String get simGradientBoosting => 'Gradient Boosting';

  @override
  String get simGradientBoostingLevel => 'Machine Learning';

  @override
  String get simGradientBoostingFormat => 'Interactive';

  @override
  String get simGradientBoostingSummary =>
      'Watch iterative boosting build a strong learner by correcting residuals of weak models.';

  @override
  String get simLogisticRegression => 'Logistic Regression';

  @override
  String get simLogisticRegressionLevel => 'Machine Learning';

  @override
  String get simLogisticRegressionFormat => 'Interactive';

  @override
  String get simLogisticRegressionSummary =>
      'Fit a sigmoid decision boundary for binary classification. σ(z) = 1/(1+e⁻ᶻ)';

  @override
  String get simQuantumTeleportation => 'Quantum Teleportation';

  @override
  String get simQuantumTeleportationLevel => 'Quantum Computing';

  @override
  String get simQuantumTeleportationFormat => 'Interactive';

  @override
  String get simQuantumTeleportationSummary =>
      'Simulate the quantum teleportation protocol transferring quantum states via entangled qubits.';

  @override
  String get simQuantumErrorCorrection => 'Quantum Error Correction';

  @override
  String get simQuantumErrorCorrectionLevel => 'Quantum Computing';

  @override
  String get simQuantumErrorCorrectionFormat => 'Interactive';

  @override
  String get simQuantumErrorCorrectionSummary =>
      'Explore stabilizer codes that protect quantum information from decoherence and errors.';

  @override
  String get simGroverAlgorithm => 'Grover\'s Quantum Search';

  @override
  String get simGroverAlgorithmLevel => 'Quantum Computing';

  @override
  String get simGroverAlgorithmFormat => 'Interactive';

  @override
  String get simGroverAlgorithmSummary =>
      'Visualize amplitude amplification in Grover\'s O(√N) quantum search algorithm.';

  @override
  String get simShorAlgorithm => 'Shor\'s Factoring Algorithm';

  @override
  String get simShorAlgorithmLevel => 'Quantum Computing';

  @override
  String get simShorAlgorithmFormat => 'Interactive';

  @override
  String get simShorAlgorithmSummary =>
      'Understand quantum period-finding that enables exponential speedup for integer factorization.';

  @override
  String get simGasLaws => 'Combined Gas Laws';

  @override
  String get simGasLawsLevel => 'Chemistry';

  @override
  String get simGasLawsFormat => 'Interactive';

  @override
  String get simGasLawsSummary =>
      'Explore Boyle\'s, Charles\'s, and the ideal gas law with interactive pressure-volume-temperature controls. PV = nRT';

  @override
  String get simDaltonLaw => 'Dalton\'s Law of Partial Pressures';

  @override
  String get simDaltonLawLevel => 'Chemistry';

  @override
  String get simDaltonLawFormat => 'Interactive';

  @override
  String get simDaltonLawSummary =>
      'Visualize how partial pressures of gas mixtures add up to total pressure. P_total = P₁ + P₂ + ... + Pₙ';

  @override
  String get simColligativeProperties => 'Colligative Properties';

  @override
  String get simColligativePropertiesLevel => 'Physical Chemistry';

  @override
  String get simColligativePropertiesFormat => 'Interactive';

  @override
  String get simColligativePropertiesSummary =>
      'Observe boiling point elevation and freezing point depression caused by dissolved solutes. ΔT = K·m·i';

  @override
  String get simSolubilityCurve => 'Solubility Curves';

  @override
  String get simSolubilityCurveLevel => 'Chemistry';

  @override
  String get simSolubilityCurveFormat => 'Interactive';

  @override
  String get simSolubilityCurveSummary =>
      'Explore how the solubility of different compounds changes with temperature.';

  @override
  String get simProperTime => 'Proper Time & Worldlines';

  @override
  String get simProperTimeLevel => 'Special Relativity';

  @override
  String get simProperTimeFormat => 'Interactive';

  @override
  String get simProperTimeSummary =>
      'Draw worldlines on spacetime diagrams and compute proper time intervals. dτ² = dt² - dx²/c²';

  @override
  String get simFourVectors => 'Four-Vectors';

  @override
  String get simFourVectorsLevel => 'Special Relativity';

  @override
  String get simFourVectorsFormat => 'Interactive';

  @override
  String get simFourVectorsSummary =>
      'Visualize four-momentum and four-velocity in Minkowski spacetime geometry.';

  @override
  String get simVelocityAddition => 'Relativistic Velocity Addition';

  @override
  String get simVelocityAdditionLevel => 'Special Relativity';

  @override
  String get simVelocityAdditionFormat => 'Interactive';

  @override
  String get simVelocityAdditionSummary =>
      'Compare classical Galilean addition with the relativistic formula. u\' = (u+v)/(1+uv/c²)';

  @override
  String get simBarnPoleParadox => 'Barn-Pole Paradox';

  @override
  String get simBarnPoleParadoxLevel => 'Special Relativity';

  @override
  String get simBarnPoleParadoxFormat => 'Interactive';

  @override
  String get simBarnPoleParadoxSummary =>
      'Resolve the length contraction paradox using relativity of simultaneity.';

  @override
  String get simWeatherFronts => 'Weather Fronts';

  @override
  String get simWeatherFrontsLevel => 'Meteorology';

  @override
  String get simWeatherFrontsFormat => 'Interactive';

  @override
  String get simWeatherFrontsSummary =>
      'Visualize cold, warm, stationary, and occluded fronts and their associated weather patterns.';

  @override
  String get simHurricaneFormation => 'Hurricane Formation';

  @override
  String get simHurricaneFormationLevel => 'Meteorology';

  @override
  String get simHurricaneFormationFormat => 'Interactive';

  @override
  String get simHurricaneFormationSummary =>
      'Watch warm ocean water fuel tropical cyclone intensification through evaporation and condensation.';

  @override
  String get simJetStream => 'Jet Stream';

  @override
  String get simJetStreamLevel => 'Atmospheric Science';

  @override
  String get simJetStreamFormat => 'Interactive';

  @override
  String get simJetStreamSummary =>
      'Explore how temperature gradients drive jet streams that steer global weather systems.';

  @override
  String get simOrographicRainfall => 'Orographic Rainfall';

  @override
  String get simOrographicRainfallLevel => 'Earth Science';

  @override
  String get simOrographicRainfallFormat => 'Interactive';

  @override
  String get simOrographicRainfallSummary =>
      'See how mountains force moist air upward, causing precipitation on windward slopes and rain shadows.';

  @override
  String get simBarnsleyFern => 'Barnsley Fern';

  @override
  String get simBarnsleyFernLevel => 'Fractal Geometry';

  @override
  String get simBarnsleyFernFormat => 'Interactive';

  @override
  String get simBarnsleyFernSummary =>
      'Generate a realistic fern fractal using an iterated function system (IFS) of affine transforms.';

  @override
  String get simDragonCurve => 'Dragon Curve';

  @override
  String get simDragonCurveLevel => 'Fractal Geometry';

  @override
  String get simDragonCurveFormat => 'Interactive';

  @override
  String get simDragonCurveSummary =>
      'Watch a dragon curve fractal unfold through successive recursive paper-folding iterations.';

  @override
  String get simDiffusionLimited => 'Diffusion-Limited Aggregation';

  @override
  String get simDiffusionLimitedLevel => 'Complex Systems';

  @override
  String get simDiffusionLimitedFormat => 'Interactive';

  @override
  String get simDiffusionLimitedSummary =>
      'Simulate fractal cluster growth as randomly walking particles stick to an aggregate.';

  @override
  String get simReactionDiffusion => 'Reaction-Diffusion (Turing Patterns)';

  @override
  String get simReactionDiffusionLevel => 'Complex Systems';

  @override
  String get simReactionDiffusionFormat => 'Interactive';

  @override
  String get simReactionDiffusionSummary =>
      'Generate Turing patterns (spots and stripes) through activator-inhibitor reaction-diffusion equations.';

  @override
  String get simMendelianGenetics => 'Mendelian Genetics';

  @override
  String get simMendelianGeneticsLevel => 'Biology';

  @override
  String get simMendelianGeneticsFormat => 'Interactive';

  @override
  String get simMendelianGeneticsSummary =>
      'Simulate Mendel\'s laws of segregation and independent assortment with dominant and recessive alleles.';

  @override
  String get simPunnettSquare => 'Punnett Square';

  @override
  String get simPunnettSquareLevel => 'Biology';

  @override
  String get simPunnettSquareFormat => 'Interactive';

  @override
  String get simPunnettSquareSummary =>
      'Predict offspring genotype and phenotype ratios using interactive Punnett squares.';

  @override
  String get simGeneExpression => 'Gene Expression';

  @override
  String get simGeneExpressionLevel => 'Molecular Biology';

  @override
  String get simGeneExpressionFormat => 'Interactive';

  @override
  String get simGeneExpressionSummary =>
      'Visualize transcription (DNA → mRNA) and translation (mRNA → protein) step by step.';

  @override
  String get simGeneticDrift => 'Genetic Drift';

  @override
  String get simGeneticDriftLevel => 'Population Genetics';

  @override
  String get simGeneticDriftFormat => 'Interactive';

  @override
  String get simGeneticDriftSummary =>
      'Observe random allele frequency changes in small populations — a key driver of evolution.';

  @override
  String get simHrDiagram => 'Hertzsprung-Russell Diagram';

  @override
  String get simHrDiagramLevel => 'Astrophysics';

  @override
  String get simHrDiagramFormat => 'Interactive';

  @override
  String get simHrDiagramSummary =>
      'Plot stars on the HR diagram and trace stellar evolution from main sequence to remnants.';

  @override
  String get simStellarNucleosynthesis => 'Stellar Nucleosynthesis';

  @override
  String get simStellarNucleosynthesisLevel => 'Astrophysics';

  @override
  String get simStellarNucleosynthesisFormat => 'Interactive';

  @override
  String get simStellarNucleosynthesisSummary =>
      'Trace how nuclear fusion in stellar cores forges elements from hydrogen to iron.';

  @override
  String get simChandrasekharLimit => 'Chandrasekhar Limit';

  @override
  String get simChandrasekharLimitLevel => 'Astrophysics';

  @override
  String get simChandrasekharLimitFormat => 'Interactive';

  @override
  String get simChandrasekharLimitSummary =>
      'Explore the 1.4 M☉ mass limit of white dwarfs and the fate of stars above it.';

  @override
  String get simNeutronStar => 'Neutron Star';

  @override
  String get simNeutronStarLevel => 'Astrophysics';

  @override
  String get simNeutronStarFormat => 'Interactive';

  @override
  String get simNeutronStarSummary =>
      'Visualize the extreme density, ultra-strong magnetic fields, and pulsed emission of neutron stars.';

  @override
  String get simVenturiTube => 'Venturi Effect';

  @override
  String get simVenturiTubeLevel => 'Fluid Mechanics';

  @override
  String get simVenturiTubeFormat => 'Interactive';

  @override
  String get simVenturiTubeSummary =>
      'Observe pressure drop in a constricted flow tube via the Venturi effect. P₁+½ρv₁²=P₂+½ρv₂²';

  @override
  String get simSurfaceTension => 'Surface Tension';

  @override
  String get simSurfaceTensionLevel => 'Fluid Physics';

  @override
  String get simSurfaceTensionFormat => 'Interactive';

  @override
  String get simSurfaceTensionSummary =>
      'Explore how molecular cohesion creates surface tension and enables capillary rise.';

  @override
  String get simHookeSpring => 'Springs in Series & Parallel';

  @override
  String get simHookeSpringLevel => 'Mechanics';

  @override
  String get simHookeSpringFormat => 'Interactive';

  @override
  String get simHookeSpringsSummary =>
      'Compare effective spring constants for series and parallel spring configurations. 1/k_s = 1/k₁ + 1/k₂';

  @override
  String get simWheatstoneBridge => 'Wheatstone Bridge';

  @override
  String get simWheatstoneBridgeLevel => 'Electrical Engineering';

  @override
  String get simWheatstoneBridgeFormat => 'Interactive';

  @override
  String get simWheatstoneBridgeSummary =>
      'Balance a Wheatstone bridge circuit to accurately measure an unknown resistance.';

  @override
  String get simGradientField => 'Gradient Vector Fields';

  @override
  String get simGradientFieldLevel => 'Multivariable Calculus';

  @override
  String get simGradientFieldFormat => 'Interactive';

  @override
  String get simGradientFieldSummary =>
      'Visualize gradient vector fields and equipotential level curves of scalar functions.';

  @override
  String get simDivergenceCurl => 'Divergence & Curl';

  @override
  String get simDivergenceCurlLevel => 'Vector Calculus';

  @override
  String get simDivergenceCurlFormat => 'Interactive';

  @override
  String get simDivergenceCurlSummary =>
      'Explore divergence and curl of 2D vector fields — the foundation of Maxwell\'s equations.';

  @override
  String get simLaplaceTransform => 'Laplace Transform';

  @override
  String get simLaplaceTransformLevel => 'Engineering Mathematics';

  @override
  String get simLaplaceTransformFormat => 'Interactive';

  @override
  String get simLaplaceTransformSummary =>
      'Convert time-domain signals to the s-domain and back. F(s) = ∫₀^∞ f(t)e^(-st) dt';

  @override
  String get simZTransform => 'Z-Transform';

  @override
  String get simZTransformLevel => 'Digital Signal Processing';

  @override
  String get simZTransformFormat => 'Interactive';

  @override
  String get simZTransformSummary =>
      'Transform discrete-time sequences to the z-domain for digital filter analysis.';

  @override
  String get simDbscan => 'DBSCAN Clustering';

  @override
  String get simDbscanLevel => 'Machine Learning';

  @override
  String get simDbscanFormat => 'Interactive';

  @override
  String get simDbscanSummary =>
      'Density-based spatial clustering that discovers clusters of arbitrary shape and handles noise.';

  @override
  String get simConfusionMatrix => 'Confusion Matrix & ROC Curve';

  @override
  String get simConfusionMatrixLevel => 'Machine Learning';

  @override
  String get simConfusionMatrixFormat => 'Interactive';

  @override
  String get simConfusionMatrixSummary =>
      'Visualize classification performance through confusion matrices and ROC-AUC curves.';

  @override
  String get simCrossValidation => 'Cross-Validation';

  @override
  String get simCrossValidationLevel => 'Machine Learning';

  @override
  String get simCrossValidationFormat => 'Interactive';

  @override
  String get simCrossValidationSummary =>
      'Understand k-fold cross-validation for unbiased model evaluation and hyperparameter tuning.';

  @override
  String get simBiasVariance => 'Bias-Variance Tradeoff';

  @override
  String get simBiasVarianceLevel => 'Machine Learning';

  @override
  String get simBiasVarianceFormat => 'Interactive';

  @override
  String get simBiasVarianceSummary =>
      'Explore how model complexity balances underfitting (bias) and overfitting (variance).';

  @override
  String get simQuantumFourier => 'Quantum Fourier Transform';

  @override
  String get simQuantumFourierLevel => 'Quantum Computing';

  @override
  String get simQuantumFourierFormat => 'Interactive';

  @override
  String get simQuantumFourierSummary =>
      'Visualize the QFT circuit and how it efficiently transforms quantum amplitude distributions.';

  @override
  String get simDensityMatrix => 'Density Matrix';

  @override
  String get simDensityMatrixLevel => 'Quantum Mechanics';

  @override
  String get simDensityMatrixFormat => 'Interactive';

  @override
  String get simDensityMatrixSummary =>
      'Represent pure and mixed quantum states using density matrices and Bloch sphere visualization.';

  @override
  String get simQuantumWalk => 'Quantum Random Walk';

  @override
  String get simQuantumWalkLevel => 'Quantum Computing';

  @override
  String get simQuantumWalkFormat => 'Interactive';

  @override
  String get simQuantumWalkSummary =>
      'Compare quantum and classical random walks — quadratic speedup from quantum interference.';

  @override
  String get simQuantumDecoherence => 'Quantum Decoherence';

  @override
  String get simQuantumDecoherenceLevel => 'Quantum Mechanics';

  @override
  String get simQuantumDecoherenceFormat => 'Interactive';

  @override
  String get simQuantumDecoherenceSummary =>
      'Watch quantum coherence decay as a qubit interacts with an environmental bath.';

  @override
  String get simCrystalLattice => 'Crystal Lattice Structures';

  @override
  String get simCrystalLatticeLevel => 'Materials Science';

  @override
  String get simCrystalLatticeFormat => 'Interactive';

  @override
  String get simCrystalLatticeSummary =>
      'Explore FCC, BCC, and HCP crystal structures and their packing efficiencies.';

  @override
  String get simHessLaw => 'Hess\'s Law';

  @override
  String get simHessLawLevel => 'Thermochemistry';

  @override
  String get simHessLawFormat => 'Interactive';

  @override
  String get simHessLawSummary =>
      'Calculate reaction enthalpy by combining thermochemical equations using Hess\'s law.';

  @override
  String get simEnthalpyDiagram => 'Enthalpy Diagram';

  @override
  String get simEnthalpyDiagramLevel => 'Thermochemistry';

  @override
  String get simEnthalpyDiagramFormat => 'Interactive';

  @override
  String get simEnthalpyDiagramSummary =>
      'Visualize exothermic and endothermic reaction energy profiles with activation energy barriers.';

  @override
  String get simLeChatelier => 'Le Chatelier\'s Principle';

  @override
  String get simLeChatelierLevel => 'Chemical Equilibrium';

  @override
  String get simLeChatelierFormat => 'Interactive';

  @override
  String get simLeChatelierSummary =>
      'Observe how equilibrium shifts in response to changes in concentration, pressure, or temperature.';

  @override
  String get simRelativisticEnergy => 'Relativistic Kinetic Energy';

  @override
  String get simRelativisticEnergyLevel => 'Special Relativity';

  @override
  String get simRelativisticEnergyFormat => 'Interactive';

  @override
  String get simRelativisticEnergySummary =>
      'Compare classical and relativistic kinetic energy — divergence grows near the speed of light. K = (γ-1)mc²';

  @override
  String get simLightCone => 'Light Cone Diagram';

  @override
  String get simLightConeLevel => 'Special Relativity';

  @override
  String get simLightConeFormat => 'Interactive';

  @override
  String get simLightConeSummary =>
      'Visualize causal structure of spacetime: past, future, and spacelike separated events.';

  @override
  String get simEquivalencePrinciple => 'Equivalence Principle';

  @override
  String get simEquivalencePrincipleLevel => 'General Relativity';

  @override
  String get simEquivalencePrincipleFormat => 'Interactive';

  @override
  String get simEquivalencePrincipleSummary =>
      'Demonstrate Einstein\'s equivalence principle: gravitational and inertial mass are indistinguishable.';

  @override
  String get simMetricTensor => 'Metric Tensor Visualization';

  @override
  String get simMetricTensorLevel => 'General Relativity';

  @override
  String get simMetricTensorFormat => 'Interactive';

  @override
  String get simMetricTensorSummary =>
      'Visualize how the metric tensor encodes the geometry of curved spacetime.';

  @override
  String get simSoilLayers => 'Soil Horizons';

  @override
  String get simSoilLayersLevel => 'Earth Science';

  @override
  String get simSoilLayersFormat => 'Interactive';

  @override
  String get simSoilLayersSummary =>
      'Explore soil horizon profiles — O, A, B, C layers — and their composition and formation processes.';

  @override
  String get simVolcanoTypes => 'Volcano Types & Eruptions';

  @override
  String get simVolcanoTypesLevel => 'Geology';

  @override
  String get simVolcanoTypesFormat => 'Interactive';

  @override
  String get simVolcanoTypesSummary =>
      'Compare shield, stratovolcano, and cinder cone volcanoes with their eruptive styles.';

  @override
  String get simMineralIdentification => 'Mineral Identification';

  @override
  String get simMineralIdentificationLevel => 'Mineralogy';

  @override
  String get simMineralIdentificationFormat => 'Interactive';

  @override
  String get simMineralIdentificationSummary =>
      'Identify minerals using diagnostic properties: hardness (Mohs scale), luster, and streak.';

  @override
  String get simErosionDeposition => 'Erosion & Deposition';

  @override
  String get simErosionDepositionLevel => 'Earth Science';

  @override
  String get simErosionDepositionFormat => 'Interactive';

  @override
  String get simErosionDepositionSummary =>
      'Simulate how water and wind erode, transport, and deposit sediment to shape landscapes.';

  @override
  String get simFlocking => 'Boids Flocking Simulation';

  @override
  String get simFlockingLevel => 'Emergence';

  @override
  String get simFlockingFormat => 'Interactive';

  @override
  String get simFlockingSummary =>
      'Emergent flocking behavior from three simple rules: separation, alignment, and cohesion.';

  @override
  String get simAntColony => 'Ant Colony Optimization';

  @override
  String get simAntColonyLevel => 'Swarm Intelligence';

  @override
  String get simAntColonyFormat => 'Interactive';

  @override
  String get simAntColonySummary =>
      'Watch ants discover optimal paths through pheromone-guided stigmergic communication.';

  @override
  String get simForestFire => 'Forest Fire Model';

  @override
  String get simForestFireLevel => 'Complex Systems';

  @override
  String get simForestFireFormat => 'Interactive';

  @override
  String get simForestFireSummary =>
      'Model fire spreading through forests using percolation theory — a self-organized criticality example.';

  @override
  String get simNetworkCascade => 'Network Cascade';

  @override
  String get simNetworkCascadeLevel => 'Network Science';

  @override
  String get simNetworkCascadeFormat => 'Interactive';

  @override
  String get simNetworkCascadeSummary =>
      'Simulate information, disease, or failure cascading through complex networks.';

  @override
  String get simSpeciation => 'Speciation';

  @override
  String get simSpeciationLevel => 'Evolutionary Biology';

  @override
  String get simSpeciationFormat => 'Interactive';

  @override
  String get simSpeciationSummary =>
      'Simulate allopatric and sympatric speciation driven by geographic isolation and natural selection.';

  @override
  String get simPhylogeneticTree => 'Phylogenetic Tree';

  @override
  String get simPhylogeneticTreeLevel => 'Evolutionary Biology';

  @override
  String get simPhylogeneticTreeFormat => 'Interactive';

  @override
  String get simPhylogeneticTreeSummary =>
      'Build and explore evolutionary trees of life — cladograms showing common ancestry.';

  @override
  String get simFoodWeb => 'Food Web Dynamics';

  @override
  String get simFoodWebLevel => 'Ecology';

  @override
  String get simFoodWebFormat => 'Interactive';

  @override
  String get simFoodWebSummary =>
      'Explore trophic energy flow through food webs and the consequences of species removal.';

  @override
  String get simEcologicalSuccession => 'Ecological Succession';

  @override
  String get simEcologicalSuccessionLevel => 'Ecology';

  @override
  String get simEcologicalSuccessionFormat => 'Interactive';

  @override
  String get simEcologicalSuccessionSummary =>
      'Watch ecosystems develop from pioneer species on bare rock to a stable climax community.';

  @override
  String get simSupernova => 'Supernova Types';

  @override
  String get simSupernovaLevel => 'Astrophysics';

  @override
  String get simSupernovaFormat => 'Interactive';

  @override
  String get simSupernovaSummary =>
      'Compare Type Ia thermonuclear supernovae and core-collapse supernovae from massive stars.';

  @override
  String get simBinaryStar => 'Binary Star System';

  @override
  String get simBinaryStarLevel => 'Astrophysics';

  @override
  String get simBinaryStarFormat => 'Interactive';

  @override
  String get simBinaryStarSummary =>
      'Simulate orbital dynamics of binary stars and observe light curve variations.';

  @override
  String get simExoplanetTransit => 'Exoplanet Transit Detection';

  @override
  String get simExoplanetTransitLevel => 'Astrophysics';

  @override
  String get simExoplanetTransitFormat => 'Interactive';

  @override
  String get simExoplanetTransitSummary =>
      'Detect exoplanets by analyzing stellar brightness dips during planetary transits.';

  @override
  String get simParallax => 'Stellar Parallax';

  @override
  String get simParallaxLevel => 'Observational Astronomy';

  @override
  String get simParallaxFormat => 'Interactive';

  @override
  String get simParallaxSummary =>
      'Measure stellar distances using annual parallax angle shifts. d = 1/p (parsecs)';

  @override
  String get simMagneticInduction => 'Mutual Induction';

  @override
  String get simMagneticInductionLevel => 'Electromagnetism';

  @override
  String get simMagneticInductionFormat => 'Interactive';

  @override
  String get simMagneticInductionSummary =>
      'Explore how changing current in one coil induces voltage in a nearby coupled coil.';

  @override
  String get simAcCircuits => 'AC Circuit Analysis';

  @override
  String get simAcCircuitsLevel => 'Electrical Engineering';

  @override
  String get simAcCircuitsFormat => 'Interactive';

  @override
  String get simAcCircuitsSummary =>
      'Analyze impedance, phase relationships, and resonance in RLC AC circuits.';

  @override
  String get simPhotodiode => 'Photodiode Operation';

  @override
  String get simPhotodiodeLevel => 'Semiconductor Physics';

  @override
  String get simPhotodiodeFormat => 'Interactive';

  @override
  String get simPhotodiodeSummary =>
      'Visualize how photodiodes convert incident photons to electrical current via the photoelectric effect.';

  @override
  String get simHallEffect => 'Hall Effect';

  @override
  String get simHallEffectLevel => 'Solid-State Physics';

  @override
  String get simHallEffectFormat => 'Interactive';

  @override
  String get simHallEffectSummary =>
      'Observe the transverse Hall voltage generated in a current-carrying conductor under a magnetic field.';

  @override
  String get simConvolution => 'Convolution';

  @override
  String get simConvolutionLevel => 'Signal Processing';

  @override
  String get simConvolutionFormat => 'Interactive';

  @override
  String get simConvolutionSummary =>
      'Visualize convolution of two functions as a sliding overlap integral — fundamental to filtering.';

  @override
  String get simFibonacciSequence => 'Fibonacci Sequence & Golden Spiral';

  @override
  String get simFibonacciSequenceLevel => 'Number Theory';

  @override
  String get simFibonacciSequenceFormat => 'Interactive';

  @override
  String get simFibonacciSequenceSummary =>
      'Watch the golden spiral emerge from Fibonacci numbers — nature\'s most common growth pattern.';

  @override
  String get simEulerPath => 'Euler & Hamiltonian Paths';

  @override
  String get simEulerPathLevel => 'Graph Theory';

  @override
  String get simEulerPathFormat => 'Interactive';

  @override
  String get simEulerPathSummary =>
      'Find Euler paths (traversing every edge) and Hamiltonian paths (visiting every vertex) in graphs.';

  @override
  String get simMinimumSpanningTree => 'Minimum Spanning Tree';

  @override
  String get simMinimumSpanningTreeLevel => 'Graph Theory';

  @override
  String get simMinimumSpanningTreeFormat => 'Interactive';

  @override
  String get simMinimumSpanningTreeSummary =>
      'Build minimum spanning trees using Kruskal\'s and Prim\'s greedy algorithms.';

  @override
  String get simBatchNorm => 'Batch Normalization';

  @override
  String get simBatchNormLevel => 'Deep Learning';

  @override
  String get simBatchNormFormat => 'Interactive';

  @override
  String get simBatchNormSummary =>
      'Visualize how batch normalization stabilizes training by normalizing layer activations.';

  @override
  String get simLearningRate => 'Learning Rate Scheduling';

  @override
  String get simLearningRateLevel => 'Deep Learning';

  @override
  String get simLearningRateFormat => 'Interactive';

  @override
  String get simLearningRateSummary =>
      'Compare constant, step decay, cosine annealing, and warm restart learning rate schedules.';

  @override
  String get simBackpropagation => 'Backpropagation';

  @override
  String get simBackpropagationLevel => 'Deep Learning';

  @override
  String get simBackpropagationFormat => 'Interactive';

  @override
  String get simBackpropagationSummary =>
      'Step through backpropagation in a simple network — computing gradients via the chain rule.';

  @override
  String get simVae => 'Variational Autoencoder (VAE)';

  @override
  String get simVaeLevel => 'Generative AI';

  @override
  String get simVaeFormat => 'Interactive';

  @override
  String get simVaeSummary =>
      'Explore the latent space of a VAE — encoding, sampling the reparameterization trick, and decoding.';

  @override
  String get simQuantumZeno => 'Quantum Zeno Effect';

  @override
  String get simQuantumZenoLevel => 'Quantum Mechanics';

  @override
  String get simQuantumZenoFormat => 'Interactive';

  @override
  String get simQuantumZenoSummary =>
      'Frequent measurement freezes quantum state evolution — the quantum watched pot never boils.';

  @override
  String get simAharonovBohm => 'Aharonov-Bohm Effect';

  @override
  String get simAharonovBohmLevel => 'Quantum Mechanics';

  @override
  String get simAharonovBohmFormat => 'Interactive';

  @override
  String get simAharonovBohmSummary =>
      'Observe phase shifts from a magnetic flux enclosed by electron paths — topology in quantum physics.';

  @override
  String get simQuantumKeyDist => 'BB84 Quantum Key Distribution';

  @override
  String get simQuantumKeyDistLevel => 'Quantum Cryptography';

  @override
  String get simQuantumKeyDistFormat => 'Interactive';

  @override
  String get simQuantumKeyDistSummary =>
      'Simulate the BB84 protocol for unconditionally secure quantum key distribution.';

  @override
  String get simFranckHertz => 'Franck-Hertz Experiment';

  @override
  String get simFranckHertzLevel => 'Atomic Physics';

  @override
  String get simFranckHertzFormat => 'Interactive';

  @override
  String get simFranckHertzSummary =>
      'Demonstrate discrete energy levels in atoms through electron collision spectroscopy.';

  @override
  String get simEquilibriumConstant => 'Equilibrium Constant';

  @override
  String get simEquilibriumConstantLevel => 'Chemical Equilibrium';

  @override
  String get simEquilibriumConstantFormat => 'Interactive';

  @override
  String get simEquilibriumConstantSummary =>
      'Calculate Kc and Kp for reactions and visualize how concentration ratios reach equilibrium.';

  @override
  String get simBufferSolution => 'Buffer Solutions';

  @override
  String get simBufferSolutionLevel => 'Acid-Base Chemistry';

  @override
  String get simBufferSolutionFormat => 'Interactive';

  @override
  String get simBufferSolutionSummary =>
      'Explore how weak acid-conjugate base buffers resist pH changes upon acid or base addition.';

  @override
  String get simRadioactiveDecay => 'Radioactive Decay';

  @override
  String get simRadioactiveDecayLevel => 'Nuclear Chemistry';

  @override
  String get simRadioactiveDecayFormat => 'Interactive';

  @override
  String get simRadioactiveDecaySummary =>
      'Simulate alpha, beta, and gamma decay with half-life and decay constant. N = N₀e^(-λt)';

  @override
  String get simNuclearFissionFusion => 'Nuclear Fission & Fusion';

  @override
  String get simNuclearFissionFusionLevel => 'Nuclear Physics';

  @override
  String get simNuclearFissionFusionFormat => 'Interactive';

  @override
  String get simNuclearFissionFusionSummary =>
      'Compare energy release from uranium fission and hydrogen fusion via binding energy per nucleon.';

  @override
  String get simFrameDragging => 'Frame Dragging (Lense-Thirring)';

  @override
  String get simFrameDraggingLevel => 'General Relativity';

  @override
  String get simFrameDraggingFormat => 'Interactive';

  @override
  String get simFrameDraggingSummary =>
      'Visualize how a rotating mass drags the surrounding spacetime fabric.';

  @override
  String get simPenroseDiagram => 'Penrose Conformal Diagram';

  @override
  String get simPenroseDiagramLevel => 'General Relativity';

  @override
  String get simPenroseDiagramFormat => 'Interactive';

  @override
  String get simPenroseDiagramSummary =>
      'Map the infinite structure of spacetime onto a compact finite diagram for black holes and cosmology.';

  @override
  String get simFriedmannEquations => 'Friedmann Equations';

  @override
  String get simFriedmannEquationsLevel => 'Cosmology';

  @override
  String get simFriedmannEquationsFormat => 'Interactive';

  @override
  String get simFriedmannEquationsSummary =>
      'Explore the Friedmann equations governing the expansion history of the universe.';

  @override
  String get simHubbleExpansion => 'Hubble Expansion';

  @override
  String get simHubbleExpansionLevel => 'Cosmology';

  @override
  String get simHubbleExpansionFormat => 'Interactive';

  @override
  String get simHubbleExpansionSummary =>
      'Visualize the expanding universe — every galaxy receding with velocity v = H₀d.';

  @override
  String get simOceanTides => 'Tidal Patterns';

  @override
  String get simOceanTidesLevel => 'Oceanography';

  @override
  String get simOceanTidesFormat => 'Interactive';

  @override
  String get simOceanTidesSummary =>
      'Model spring and neap tidal patterns from gravitational pull of the Moon and Sun.';

  @override
  String get simThermohaline => 'Thermohaline Circulation';

  @override
  String get simThermohalineLevel => 'Oceanography';

  @override
  String get simThermohalineFormat => 'Interactive';

  @override
  String get simThermohalineSummary =>
      'Simulate the global ocean conveyor belt driven by temperature and salinity gradients.';

  @override
  String get simElNino => 'El Niño & La Niña';

  @override
  String get simElNinoLevel => 'Climate Science';

  @override
  String get simElNinoFormat => 'Interactive';

  @override
  String get simElNinoSummary =>
      'Explore how ENSO cycles alter Pacific sea surface temperatures and global weather patterns.';

  @override
  String get simIceAges => 'Ice Age Cycles';

  @override
  String get simIceAgesLevel => 'Paleoclimatology';

  @override
  String get simIceAgesFormat => 'Interactive';

  @override
  String get simIceAgesSummary =>
      'Simulate Milankovitch orbital cycles (eccentricity, obliquity, precession) driving glacial-interglacial cycles.';

  @override
  String get simSmallWorld => 'Small-World Network';

  @override
  String get simSmallWorldLevel => 'Network Science';

  @override
  String get simSmallWorldFormat => 'Interactive';

  @override
  String get simSmallWorldSummary =>
      'Build and analyze Watts-Strogatz small-world networks with high clustering and short path lengths.';

  @override
  String get simScaleFreeNetwork => 'Scale-Free Network';

  @override
  String get simScaleFreeNetworkLevel => 'Network Science';

  @override
  String get simScaleFreeNetworkFormat => 'Interactive';

  @override
  String get simScaleFreeNetworkSummary =>
      'Generate Barabasi-Albert scale-free networks through preferential attachment — power-law degree distribution.';

  @override
  String get simStrangeAttractor => 'Strange Attractor Explorer';

  @override
  String get simStrangeAttractorLevel => 'Chaos Theory';

  @override
  String get simStrangeAttractorFormat => 'Interactive';

  @override
  String get simStrangeAttractorSummary =>
      'Explore Lorenz, Rössler, and Halvorsen strange attractors — chaos on fractal manifolds.';

  @override
  String get simFeigenbaum => 'Feigenbaum Constants';

  @override
  String get simFeigenbaumLevel => 'Chaos Theory';

  @override
  String get simFeigenbaumFormat => 'Interactive';

  @override
  String get simFeigenbaumSummary =>
      'Discover the universal Feigenbaum constant δ ≈ 4.6692 in period-doubling bifurcation cascades.';

  @override
  String get simCarbonFixation => 'Carbon Fixation (Calvin Cycle)';

  @override
  String get simCarbonFixationLevel => 'Biochemistry';

  @override
  String get simCarbonFixationFormat => 'Interactive';

  @override
  String get simCarbonFixationSummary =>
      'Animate the Calvin cycle — how plants fix atmospheric CO₂ into organic carbon using ATP and NADPH.';

  @override
  String get simKrebsCycle => 'Krebs Cycle (TCA Cycle)';

  @override
  String get simKrebsCycleLevel => 'Biochemistry';

  @override
  String get simKrebsCycleFormat => 'Interactive';

  @override
  String get simKrebsCycleSummary =>
      'Step through the citric acid cycle — the central hub of cellular energy metabolism.';

  @override
  String get simOsmosis => 'Osmosis & Diffusion';

  @override
  String get simOsmosisLevel => 'Cell Biology';

  @override
  String get simOsmosisFormat => 'Interactive';

  @override
  String get simOsmosisSummary =>
      'Visualize osmotic water flow across semipermeable membranes driven by solute concentration gradients.';

  @override
  String get simActionPotentialSynapse => 'Synaptic Transmission';

  @override
  String get simActionPotentialSynapseLevel => 'Neuroscience';

  @override
  String get simActionPotentialSynapseFormat => 'Interactive';

  @override
  String get simActionPotentialSynapseSummary =>
      'Animate neurotransmitter release, receptor binding, and postsynaptic potential at chemical synapses.';

  @override
  String get simRedshiftMeasurement => 'Spectroscopic Redshift';

  @override
  String get simRedshiftMeasurementLevel => 'Observational Astronomy';

  @override
  String get simRedshiftMeasurementFormat => 'Interactive';

  @override
  String get simRedshiftMeasurementSummary =>
      'Measure galaxy recession velocities and distances by analyzing spectral redshift z = Δλ/λ.';

  @override
  String get simPlanetFormation => 'Planet Formation';

  @override
  String get simPlanetFormationLevel => 'Planetary Science';

  @override
  String get simPlanetFormationFormat => 'Interactive';

  @override
  String get simPlanetFormationSummary =>
      'Simulate protoplanetary disk evolution and planet formation through accretion.';

  @override
  String get simRocheLimit => 'Roche Limit';

  @override
  String get simRocheLimitLevel => 'Astrophysics';

  @override
  String get simRocheLimitFormat => 'Interactive';

  @override
  String get simRocheLimitSummary =>
      'Visualize tidal disruption of a satellite within its planet\'s Roche limit — the origin of ring systems.';

  @override
  String get simLagrangePoints => 'Lagrange Points';

  @override
  String get simLagrangePointsLevel => 'Orbital Mechanics';

  @override
  String get simLagrangePointsFormat => 'Interactive';

  @override
  String get simLagrangePointsSummary =>
      'Find the five Lagrange equilibrium points where gravitational and centrifugal forces balance.';

  @override
  String get simEddyCurrents => 'Eddy Currents';

  @override
  String get simEddyCurrentsLevel => 'Electromagnetism';

  @override
  String get simEddyCurrentsFormat => 'Interactive';

  @override
  String get simEddyCurrentsSummary =>
      'Visualize induced eddy currents in conductors and their braking effect via Lenz\'s law.';

  @override
  String get simPascalHydraulic => 'Pascal\'s Hydraulic Press';

  @override
  String get simPascalHydraulicLevel => 'Fluid Mechanics';

  @override
  String get simPascalHydraulicFormat => 'Interactive';

  @override
  String get simPascalHydraulicSummary =>
      'Demonstrate hydraulic force multiplication via Pascal\'s principle. F₁/A₁ = F₂/A₂';

  @override
  String get simSpecificHeat => 'Specific Heat Capacity';

  @override
  String get simSpecificHeatLevel => 'Thermodynamics';

  @override
  String get simSpecificHeatFormat => 'Interactive';

  @override
  String get simSpecificHeatSummary =>
      'Compare how different materials absorb and store heat energy. Q = mcΔT';

  @override
  String get simStefanBoltzmann => 'Stefan-Boltzmann Radiation';

  @override
  String get simStefanBoltzmannLevel => 'Thermodynamics';

  @override
  String get simStefanBoltzmannFormat => 'Interactive';

  @override
  String get simStefanBoltzmannSummary =>
      'Explore how blackbody thermal radiation power scales with temperature to the fourth power. P = σAT⁴';

  @override
  String get simDijkstra => 'Dijkstra\'s Shortest Path';

  @override
  String get simDijkstraLevel => 'Algorithms';

  @override
  String get simDijkstraFormat => 'Interactive';

  @override
  String get simDijkstraSummary =>
      'Find shortest paths in weighted graphs using Dijkstra\'s greedy algorithm with a priority queue.';

  @override
  String get simVoronoi => 'Voronoi Diagram';

  @override
  String get simVoronoiLevel => 'Computational Geometry';

  @override
  String get simVoronoiFormat => 'Interactive';

  @override
  String get simVoronoiSummary =>
      'Generate Voronoi tessellations — each cell contains all points nearest to its seed point.';

  @override
  String get simDelaunay => 'Delaunay Triangulation';

  @override
  String get simDelaunayLevel => 'Computational Geometry';

  @override
  String get simDelaunayFormat => 'Interactive';

  @override
  String get simDelaunaySummary =>
      'Build Delaunay triangulations — the dual of Voronoi diagrams maximizing minimum triangle angles.';

  @override
  String get simBezierCurves => 'Bézier Curves';

  @override
  String get simBezierCurvesLevel => 'Computer Graphics';

  @override
  String get simBezierCurvesFormat => 'Interactive';

  @override
  String get simBezierCurvesSummary =>
      'Control and visualize Bézier curve construction using de Casteljau\'s recursive algorithm.';

  @override
  String get simDiffusionModel => 'Diffusion Model';

  @override
  String get simDiffusionModelLevel => 'Generative AI';

  @override
  String get simDiffusionModelFormat => 'Interactive';

  @override
  String get simDiffusionModelSummary =>
      'Visualize the forward noise diffusion and reverse denoising process in diffusion generative models.';

  @override
  String get simTokenizer => 'Tokenizer & Byte-Pair Encoding';

  @override
  String get simTokenizerLevel => 'NLP';

  @override
  String get simTokenizerFormat => 'Interactive';

  @override
  String get simTokenizerSummary =>
      'Explore how BPE tokenization splits text into subword tokens for language model training.';

  @override
  String get simBeamSearch => 'Beam Search Decoding';

  @override
  String get simBeamSearchLevel => 'NLP';

  @override
  String get simBeamSearchFormat => 'Interactive';

  @override
  String get simBeamSearchSummary =>
      'Visualize beam search maintaining top-k hypotheses during autoregressive sequence decoding.';

  @override
  String get simFeatureImportance => 'Feature Importance (SHAP)';

  @override
  String get simFeatureImportanceLevel => 'Explainable AI';

  @override
  String get simFeatureImportanceFormat => 'Interactive';

  @override
  String get simFeatureImportanceSummary =>
      'Explain model predictions using SHAP (Shapley Additive Explanations) values.';

  @override
  String get simZeemanEffect => 'Zeeman Effect';

  @override
  String get simZeemanEffectLevel => 'Atomic Physics';

  @override
  String get simZeemanEffectFormat => 'Interactive';

  @override
  String get simZeemanEffectSummary =>
      'Observe spectral line splitting when atoms are placed in an external magnetic field.';

  @override
  String get simQuantumWell => 'Quantum Well';

  @override
  String get simQuantumWellLevel => 'Semiconductor Physics';

  @override
  String get simQuantumWellFormat => 'Interactive';

  @override
  String get simQuantumWellSummary =>
      'Explore quantized bound states and wavefunctions in a finite quantum well potential.';

  @override
  String get simBandStructure => 'Electronic Band Structure';

  @override
  String get simBandStructureLevel => 'Solid-State Physics';

  @override
  String get simBandStructureFormat => 'Interactive';

  @override
  String get simBandStructureSummary =>
      'Visualize energy band structure in crystals — the basis for metals, semiconductors, and insulators.';

  @override
  String get simBoseEinstein => 'Bose-Einstein Condensation';

  @override
  String get simBoseEinsteinLevel => 'Quantum Physics';

  @override
  String get simBoseEinsteinFormat => 'Interactive';

  @override
  String get simBoseEinsteinSummary =>
      'Simulate the BEC phase transition where bosons macroscopically occupy the ground state.';

  @override
  String get simOrganicFunctionalGroups => 'Organic Functional Groups';

  @override
  String get simOrganicFunctionalGroupsLevel => 'Organic Chemistry';

  @override
  String get simOrganicFunctionalGroupsFormat => 'Interactive';

  @override
  String get simOrganicFunctionalGroupsSummary =>
      'Explore hydroxyl, carbonyl, carboxyl, amino, and other organic functional groups and their reactivity.';

  @override
  String get simIsomers => 'Structural & Geometric Isomers';

  @override
  String get simIsomersLevel => 'Organic Chemistry';

  @override
  String get simIsomersFormat => 'Interactive';

  @override
  String get simIsomersSummary =>
      'Compare constitutional isomers and geometric (cis-trans) isomers with 3D molecular visualization.';

  @override
  String get simPolymerization => 'Polymerization';

  @override
  String get simPolymerizationLevel => 'Polymer Chemistry';

  @override
  String get simPolymerizationFormat => 'Interactive';

  @override
  String get simPolymerizationSummary =>
      'Animate addition and condensation polymerization — building macromolecules from monomers.';

  @override
  String get simElectrolysis => 'Electrolysis';

  @override
  String get simElectrolysisLevel => 'Electrochemistry';

  @override
  String get simElectrolysisFormat => 'Interactive';

  @override
  String get simElectrolysisSummary =>
      'Simulate electrolysis of water and aqueous salt solutions — splitting molecules with electric current.';

  @override
  String get simCosmicMicrowaveBg => 'Cosmic Microwave Background';

  @override
  String get simCosmicMicrowaveBgLevel => 'Cosmology';

  @override
  String get simCosmicMicrowaveBgFormat => 'Interactive';

  @override
  String get simCosmicMicrowaveBgSummary =>
      'Explore CMB temperature anisotropies — the oldest light in the universe as evidence for the Big Bang.';

  @override
  String get simKerrBlackHole => 'Kerr Black Hole';

  @override
  String get simKerrBlackHoleLevel => 'General Relativity';

  @override
  String get simKerrBlackHoleFormat => 'Interactive';

  @override
  String get simKerrBlackHoleSummary =>
      'Visualize the ergosphere and frame dragging effects of a rotating Kerr black hole.';

  @override
  String get simShapiroDelay => 'Shapiro Time Delay';

  @override
  String get simShapiroDelayLevel => 'General Relativity';

  @override
  String get simShapiroDelayFormat => 'Interactive';

  @override
  String get simShapiroDelaySummary =>
      'Measure the gravitational time delay of radar signals passing near massive bodies — a GR test.';

  @override
  String get simGravitationalTime => 'Gravitational Time Dilation';

  @override
  String get simGravitationalTimeLevel => 'General Relativity';

  @override
  String get simGravitationalTimeFormat => 'Interactive';

  @override
  String get simGravitationalTimeSummary =>
      'Compare clock rates at different gravitational potentials — clocks deeper in a gravity well run slower.';

  @override
  String get simOzoneLayer => 'Ozone Layer Depletion';

  @override
  String get simOzoneLayerLevel => 'Atmospheric Chemistry';

  @override
  String get simOzoneLayerFormat => 'Interactive';

  @override
  String get simOzoneLayerSummary =>
      'Simulate CFC-catalyzed ozone destruction in the stratosphere and the Antarctic ozone hole.';

  @override
  String get simRadiationBudget => 'Earth\'s Radiation Budget';

  @override
  String get simRadiationBudgetLevel => 'Climate Science';

  @override
  String get simRadiationBudgetFormat => 'Interactive';

  @override
  String get simRadiationBudgetSummary =>
      'Balance incoming solar shortwave and outgoing terrestrial longwave radiation fluxes.';

  @override
  String get simNitrogenCycle => 'Nitrogen Cycle';

  @override
  String get simNitrogenCycleLevel => 'Biogeochemistry';

  @override
  String get simNitrogenCycleFormat => 'Interactive';

  @override
  String get simNitrogenCycleSummary =>
      'Trace nitrogen through fixation, nitrification, denitrification, and assimilation in ecosystems.';

  @override
  String get simFossilFormation => 'Fossil Formation';

  @override
  String get simFossilFormationLevel => 'Paleontology';

  @override
  String get simFossilFormationFormat => 'Interactive';

  @override
  String get simFossilFormationSummary =>
      'Animate the step-by-step process of organism preservation and fossil formation in sedimentary rock.';

  @override
  String get simLyapunovExponent => 'Lyapunov Exponent';

  @override
  String get simLyapunovExponentLevel => 'Chaos Theory';

  @override
  String get simLyapunovExponentFormat => 'Interactive';

  @override
  String get simLyapunovExponentSummary =>
      'Calculate Lyapunov exponents to quantify the rate of trajectory divergence in chaotic systems.';

  @override
  String get simTentMap => 'Tent Map';

  @override
  String get simTentMapLevel => 'Chaos Theory';

  @override
  String get simTentMapFormat => 'Interactive';

  @override
  String get simTentMapSummary =>
      'Explore chaotic behavior of the tent map — a piecewise-linear analog of the logistic map.';

  @override
  String get simSierpinskiCarpet => 'Sierpinski Carpet';

  @override
  String get simSierpinskiCarpetLevel => 'Fractal Geometry';

  @override
  String get simSierpinskiCarpetFormat => 'Interactive';

  @override
  String get simSierpinskiCarpetSummary =>
      'Generate the Sierpinski carpet fractal through recursive square subdivision.';

  @override
  String get simChaosGame => 'Chaos Game';

  @override
  String get simChaosGameLevel => 'Fractal Geometry';

  @override
  String get simChaosGameFormat => 'Interactive';

  @override
  String get simChaosGameSummary =>
      'Generate Sierpinski triangle and other fractals using the chaos game random iteration algorithm.';

  @override
  String get simImmuneResponse => 'Immune Response';

  @override
  String get simImmuneResponseLevel => 'Immunology';

  @override
  String get simImmuneResponseFormat => 'Interactive';

  @override
  String get simImmuneResponseSummary =>
      'Simulate innate and adaptive immune responses — from antigen detection to antibody production.';

  @override
  String get simMuscleContraction => 'Muscle Contraction';

  @override
  String get simMuscleContractionLevel => 'Physiology';

  @override
  String get simMuscleContractionFormat => 'Interactive';

  @override
  String get simMuscleContractionSummary =>
      'Animate the sliding filament mechanism — myosin cross-bridges pulling actin filaments.';

  @override
  String get simHeartConduction => 'Cardiac Electrical Conduction';

  @override
  String get simHeartConductionLevel => 'Physiology';

  @override
  String get simHeartConductionFormat => 'Interactive';

  @override
  String get simHeartConductionSummary =>
      'Visualize the heart\'s electrical conduction pathway: SA node → AV node → Bundle of His → Purkinje fibers.';

  @override
  String get simBloodCirculation => 'Blood Circulation';

  @override
  String get simBloodCirculationLevel => 'Physiology';

  @override
  String get simBloodCirculationFormat => 'Interactive';

  @override
  String get simBloodCirculationSummary =>
      'Trace blood flow through pulmonary and systemic circuits of the cardiovascular system.';

  @override
  String get simOrbitalTransfer => 'Hohmann Transfer Orbit';

  @override
  String get simOrbitalTransferLevel => 'Orbital Mechanics';

  @override
  String get simOrbitalTransferFormat => 'Interactive';

  @override
  String get simOrbitalTransferSummary =>
      'Calculate and visualize the two-burn Hohmann transfer between circular orbits — most fuel-efficient transfer.';

  @override
  String get simEscapeVelocity => 'Escape Velocity';

  @override
  String get simEscapeVelocityLevel => 'Orbital Mechanics';

  @override
  String get simEscapeVelocityFormat => 'Interactive';

  @override
  String get simEscapeVelocitySummary =>
      'Calculate escape velocity for planets and stars. v_e = √(2GM/r)';

  @override
  String get simCelestialSphere => 'Celestial Sphere';

  @override
  String get simCelestialSphereLevel => 'Observational Astronomy';

  @override
  String get simCelestialSphereFormat => 'Interactive';

  @override
  String get simCelestialSphereSummary =>
      'Navigate the celestial sphere — right ascension, declination, and seasonal constellation visibility.';

  @override
  String get simGalaxyRotation => 'Galaxy Rotation Curves';

  @override
  String get simGalaxyRotationLevel => 'Astrophysics';

  @override
  String get simGalaxyRotationFormat => 'Interactive';

  @override
  String get simGalaxyRotationSummary =>
      'Explore flat galaxy rotation curves as observational evidence for dark matter halos.';

  @override
  String get simWavePacket => 'Wave Packet & Group Velocity';

  @override
  String get simWavePacketLevel => 'Wave Physics';

  @override
  String get simWavePacketFormat => 'Interactive';

  @override
  String get simWavePacketSummary =>
      'Visualize phase velocity vs. group velocity in wave packets — key to quantum mechanics and optics.';

  @override
  String get simLissajous => 'Lissajous Figures';

  @override
  String get simLissajousLevel => 'Wave Physics';

  @override
  String get simLissajousFormat => 'Interactive';

  @override
  String get simLissajousSummary =>
      'Create Lissajous figures from two perpendicular sinusoidal oscillations — beautiful and diagnostic.';

  @override
  String get simDopplerRadar => 'Doppler Radar';

  @override
  String get simDopplerRadarLevel => 'Applied Physics';

  @override
  String get simDopplerRadarFormat => 'Interactive';

  @override
  String get simDopplerRadarSummary =>
      'Measure target velocity using Doppler frequency shifts — the principle behind weather radar and speed guns.';

  @override
  String get simCavendish => 'Cavendish Experiment';

  @override
  String get simCavendishLevel => 'Gravitation';

  @override
  String get simCavendishFormat => 'Interactive';

  @override
  String get simCavendishSummary =>
      'Measure the gravitational constant G with a torsion balance — replicating Cavendish\'s 1798 experiment. G = 6.674×10⁻¹¹';

  @override
  String get simPolarCoordinates => 'Polar Coordinates & Rose Curves';

  @override
  String get simPolarCoordinatesLevel => 'Precalculus';

  @override
  String get simPolarCoordinatesFormat => 'Interactive';

  @override
  String get simPolarCoordinatesSummary =>
      'Plot polar curves including rose, limaçon, and Archimedean spiral patterns interactively.';

  @override
  String get simParametricCurves => 'Parametric Curves';

  @override
  String get simParametricCurvesLevel => 'Calculus';

  @override
  String get simParametricCurvesFormat => 'Interactive';

  @override
  String get simParametricCurvesSummary =>
      'Explore parametric curves — cycloids, epicycloids, hypocycloids — by controlling x(t) and y(t).';

  @override
  String get simBinomialDistribution => 'Binomial Distribution';

  @override
  String get simBinomialDistributionLevel => 'Probability';

  @override
  String get simBinomialDistributionFormat => 'Interactive';

  @override
  String get simBinomialDistributionSummary =>
      'Visualize binomial probability distributions and the normal approximation for large n.';

  @override
  String get simPoissonDistribution => 'Poisson Distribution';

  @override
  String get simPoissonDistributionLevel => 'Probability';

  @override
  String get simPoissonDistributionFormat => 'Interactive';

  @override
  String get simPoissonDistributionSummary =>
      'Model rare events with the Poisson distribution. P(k) = λ^k · e^(-λ) / k!';

  @override
  String get simDimensionalityReduction => 't-SNE Dimensionality Reduction';

  @override
  String get simDimensionalityReductionLevel => 'Machine Learning';

  @override
  String get simDimensionalityReductionFormat => 'Interactive';

  @override
  String get simDimensionalityReductionSummary =>
      'Reduce high-dimensional data to 2D with t-SNE, preserving local neighborhood structure.';

  @override
  String get simNeuralStyle => 'Neural Style Transfer';

  @override
  String get simNeuralStyleLevel => 'Computer Vision';

  @override
  String get simNeuralStyleFormat => 'Interactive';

  @override
  String get simNeuralStyleSummary =>
      'Visualize content and style feature separation in convolutional neural networks.';

  @override
  String get simMazeRl => 'Maze Solving with Reinforcement Learning';

  @override
  String get simMazeRlLevel => 'Reinforcement Learning';

  @override
  String get simMazeRlFormat => 'Interactive';

  @override
  String get simMazeRlSummary =>
      'Watch a Q-learning agent explore and learn to navigate a maze through trial and error.';

  @override
  String get simMinimax => 'Minimax Game Tree';

  @override
  String get simMinimaxLevel => 'Game AI';

  @override
  String get simMinimaxFormat => 'Interactive';

  @override
  String get simMinimaxSummary =>
      'Explore minimax decision-making with alpha-beta pruning for two-player zero-sum games.';

  @override
  String get simFermiDirac => 'Fermi-Dirac Distribution';

  @override
  String get simFermiDiracLevel => 'Statistical Mechanics';

  @override
  String get simFermiDiracFormat => 'Interactive';

  @override
  String get simFermiDiracSummary =>
      'Visualize the Fermi-Dirac occupation probability at different temperatures — the basis of semiconductor physics.';

  @override
  String get simWignerFunction => 'Wigner Quasi-Probability Function';

  @override
  String get simWignerFunctionLevel => 'Quantum Optics';

  @override
  String get simWignerFunctionFormat => 'Interactive';

  @override
  String get simWignerFunctionSummary =>
      'Explore the Wigner function as a quantum phase-space representation — negative values signal non-classicality.';

  @override
  String get simQuantumOscillator2d => '2D Quantum Harmonic Oscillator';

  @override
  String get simQuantumOscillator2dLevel => 'Quantum Mechanics';

  @override
  String get simQuantumOscillator2dFormat => 'Interactive';

  @override
  String get simQuantumOscillator2dSummary =>
      'Visualize wavefunctions and energy eigenvalues of the 2D isotropic quantum harmonic oscillator.';

  @override
  String get simSpinChain => 'Quantum Spin Chain';

  @override
  String get simSpinChainLevel => 'Quantum Many-Body';

  @override
  String get simSpinChainFormat => 'Interactive';

  @override
  String get simSpinChainSummary =>
      'Explore quantum correlations and entanglement in spin-1/2 Heisenberg spin chains.';

  @override
  String get simIdealSolution => 'Raoult\'s Law & Ideal Solutions';

  @override
  String get simIdealSolutionLevel => 'Physical Chemistry';

  @override
  String get simIdealSolutionFormat => 'Interactive';

  @override
  String get simIdealSolutionSummary =>
      'Explore vapor pressure lowering and activity coefficients in ideal and non-ideal solutions.';

  @override
  String get simChromatography => 'Chromatography';

  @override
  String get simChromatographyLevel => 'Analytical Chemistry';

  @override
  String get simChromatographyFormat => 'Interactive';

  @override
  String get simChromatographySummary =>
      'Separate mixture components by differential migration through stationary and mobile phases.';

  @override
  String get simCalorimetry => 'Calorimetry';

  @override
  String get simCalorimetryLevel => 'Thermochemistry';

  @override
  String get simCalorimetryFormat => 'Interactive';

  @override
  String get simCalorimetrySummary =>
      'Measure heat transfer in constant-pressure and constant-volume calorimeters. q = mcΔT';

  @override
  String get simActivationEnergy => 'Activation Energy & Catalysts';

  @override
  String get simActivationEnergyLevel => 'Kinetics';

  @override
  String get simActivationEnergyFormat => 'Interactive';

  @override
  String get simActivationEnergySummary =>
      'Visualize how catalysts lower the activation energy barrier — Arrhenius equation and transition state theory.';

  @override
  String get simRelativistAberration => 'Relativistic Aberration';

  @override
  String get simRelativistAberrationLevel => 'Special Relativity';

  @override
  String get simRelativistAberrationFormat => 'Interactive';

  @override
  String get simRelativistAberrationSummary =>
      'See how stellar positions appear to shift as your velocity approaches c — the headlight effect.';

  @override
  String get simRelativisticBeaming => 'Relativistic Beaming';

  @override
  String get simRelativisticBeamingLevel => 'Special Relativity';

  @override
  String get simRelativisticBeamingFormat => 'Interactive';

  @override
  String get simRelativisticBeamingSummary =>
      'Observe the concentration of emitted radiation in the forward direction at relativistic speeds.';

  @override
  String get simCosmologicalRedshift => 'Cosmological Redshift';

  @override
  String get simCosmologicalRedshiftLevel => 'Cosmology';

  @override
  String get simCosmologicalRedshiftFormat => 'Interactive';

  @override
  String get simCosmologicalRedshiftSummary =>
      'Distinguish cosmological redshift from Doppler redshift — stretched wavelengths from expanding space.';

  @override
  String get simDarkEnergy => 'Dark Energy & Accelerating Expansion';

  @override
  String get simDarkEnergyLevel => 'Cosmology';

  @override
  String get simDarkEnergyFormat => 'Interactive';

  @override
  String get simDarkEnergySummary =>
      'Explore how dark energy (Λ) drives the accelerating expansion of the universe.';

  @override
  String get simMagneticReversal => 'Geomagnetic Field Reversal';

  @override
  String get simMagneticReversalLevel => 'Geophysics';

  @override
  String get simMagneticReversalFormat => 'Interactive';

  @override
  String get simMagneticReversalSummary =>
      'Visualize Earth\'s magnetic field reversals recorded in paleomagnetic data over geological time.';

  @override
  String get simSeismograph => 'Seismograph Interpretation';

  @override
  String get simSeismographLevel => 'Geophysics';

  @override
  String get simSeismographFormat => 'Interactive';

  @override
  String get simSeismographSummary =>
      'Read seismograph P-wave and S-wave arrivals to determine earthquake epicenter and magnitude.';

  @override
  String get simContinentalDrift => 'Continental Drift Evidence';

  @override
  String get simContinentalDriftLevel => 'Geology';

  @override
  String get simContinentalDriftFormat => 'Interactive';

  @override
  String get simContinentalDriftSummary =>
      'Explore fossil, geological, and paleomagnetic evidence for continental drift and Pangaea.';

  @override
  String get simGreenhouseGases => 'Greenhouse Gas Comparison';

  @override
  String get simGreenhouseGasesLevel => 'Climate Science';

  @override
  String get simGreenhouseGasesFormat => 'Interactive';

  @override
  String get simGreenhouseGasesSummary =>
      'Compare the radiative forcing and global warming potential of CO₂, CH₄, N₂O, and other greenhouse gases.';

  @override
  String get simRule110 => 'Rule 110 Cellular Automaton';

  @override
  String get simRule110Level => 'Computation Theory';

  @override
  String get simRule110Format => 'Interactive';

  @override
  String get simRule110Summary =>
      'Explore Rule 110 — a Turing-complete one-dimensional cellular automaton with complex emergent patterns.';

  @override
  String get simSchellingSegregation => 'Schelling Segregation Model';

  @override
  String get simSchellingSegregationLevel => 'Agent-Based Modeling';

  @override
  String get simSchellingSegregationFormat => 'Interactive';

  @override
  String get simSchellingSegregationSummary =>
      'Model how mild individual preferences can lead to strong residential segregation.';

  @override
  String get simDuffingOscillator => 'Duffing Oscillator';

  @override
  String get simDuffingOscillatorLevel => 'Chaos Theory';

  @override
  String get simDuffingOscillatorFormat => 'Interactive';

  @override
  String get simDuffingOscillatorSummary =>
      'Explore chaos in the periodically-forced nonlinear Duffing oscillator with double-well potential.';

  @override
  String get simBelousovZhabotinsky => 'Belousov-Zhabotinsky Reaction';

  @override
  String get simBelousovZhabotinskyLevel => 'Chemical Oscillation';

  @override
  String get simBelousovZhabotinskyFormat => 'Interactive';

  @override
  String get simBelousovZhabotinskySummary =>
      'Simulate the oscillating BZ reaction — a chemical clock producing self-organizing spiral waves.';

  @override
  String get simCellularRespiration => 'Cellular Respiration';

  @override
  String get simCellularRespirationLevel => 'Biochemistry';

  @override
  String get simCellularRespirationFormat => 'Interactive';

  @override
  String get simCellularRespirationSummary =>
      'Trace ATP production through glycolysis, pyruvate oxidation, Krebs cycle, and electron transport chain.';

  @override
  String get simLogisticGrowth => 'Logistic Population Growth';

  @override
  String get simLogisticGrowthLevel => 'Population Ecology';

  @override
  String get simLogisticGrowthFormat => 'Interactive';

  @override
  String get simLogisticGrowthSummary =>
      'Model S-shaped logistic growth with carrying capacity K. dN/dt = rN(1-N/K)';

  @override
  String get simCompetitiveExclusion => 'Competitive Exclusion Principle';

  @override
  String get simCompetitiveExclusionLevel => 'Ecology';

  @override
  String get simCompetitiveExclusionFormat => 'Interactive';

  @override
  String get simCompetitiveExclusionSummary =>
      'Simulate two species competing for the same ecological niche — Gause\'s competitive exclusion principle.';

  @override
  String get simCrispr => 'CRISPR Gene Editing';

  @override
  String get simCrisprLevel => 'Biotechnology';

  @override
  String get simCrisprFormat => 'Interactive';

  @override
  String get simCrisprSummary =>
      'Animate the CRISPR-Cas9 mechanism: guide RNA targeting, DNA cleavage, and repair outcomes.';

  @override
  String get simDarkMatter => 'Dark Matter Evidence';

  @override
  String get simDarkMatterLevel => 'Astrophysics';

  @override
  String get simDarkMatterFormat => 'Interactive';

  @override
  String get simDarkMatterSummary =>
      'Explore observational evidence for dark matter: rotation curves, gravitational lensing, and CMB.';

  @override
  String get simPulsar => 'Pulsar Timing';

  @override
  String get simPulsarLevel => 'Astrophysics';

  @override
  String get simPulsarFormat => 'Interactive';

  @override
  String get simPulsarSummary =>
      'Analyze millisecond pulsar timing — natural cosmic clocks used to detect gravitational waves.';

  @override
  String get simAsteroidBelt => 'Asteroid Belt & Kirkwood Gaps';

  @override
  String get simAsteroidBeltLevel => 'Planetary Science';

  @override
  String get simAsteroidBeltFormat => 'Interactive';

  @override
  String get simAsteroidBeltSummary =>
      'Visualize asteroid belt orbital resonance gaps created by Jupiter\'s gravitational influence.';

  @override
  String get simCosmicDistanceLadder => 'Cosmic Distance Ladder';

  @override
  String get simCosmicDistanceLadderLevel => 'Observational Astronomy';

  @override
  String get simCosmicDistanceLadderFormat => 'Interactive';

  @override
  String get simCosmicDistanceLadderSummary =>
      'Explore the chain of distance measurement methods: parallax → Cepheids → supernovae → Hubble\'s law.';

  @override
  String get updateRequired => 'Update Required';

  @override
  String get updateDescription =>
      'A new version of Visual Science Lab is available. Please update to continue using the app.';

  @override
  String get updateNow => 'Update Now';

  @override
  String get updateLater => 'Later';

  @override
  String get currentVersionLabel => 'Current version';

  @override
  String get requiredVersionLabel => 'Required version';

  @override
  String get updateBenefits =>
      'New simulations, bug fixes, and performance improvements!';
}
