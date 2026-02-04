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
import '../../features/physics/inclined_plane/inclined_plane_screen.dart';
import '../../features/physics/buoyancy/buoyancy_screen.dart';
import '../../features/physics/lever/lever_screen.dart';
// AI/ML - New
import '../../features/machine_learning/linear_regression/linear_regression_screen.dart';
import '../../features/machine_learning/knn/knn_screen.dart';
import '../../features/machine_learning/perceptron/perceptron_screen.dart';
import '../../features/algorithms/astar/astar_screen.dart';
import '../../features/machine_learning/genetic/genetic_screen.dart';
import '../../features/deep_learning/dropout/dropout_screen.dart';
import '../../features/deep_learning/loss_functions/loss_functions_screen.dart';
import '../../features/deep_learning/cnn/cnn_screen.dart';
import '../../features/deep_learning/rnn_lstm/rnn_lstm_screen.dart';
import '../../features/deep_learning/transformer/transformer_screen.dart';
import '../../features/deep_learning/attention/attention_screen.dart';
import '../../features/deep_learning/autoencoder/autoencoder_screen.dart';
import '../../features/deep_learning/gan/gan_screen.dart';
import '../../features/machine_learning/word_embedding/word_embedding_screen.dart';
import '../../features/machine_learning/q_learning/q_learning_screen.dart';
import '../../features/machine_learning/policy_gradient/policy_gradient_screen.dart';
import '../../features/machine_learning/multi_armed_bandit/multi_armed_bandit_screen.dart';
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
// Mathematics - New (24 simulations)
import '../../features/mathematics/integral/integral_screen.dart';
import '../../features/mathematics/matrix_transform/matrix_transform_screen.dart';
import '../../features/mathematics/eigenvalues/eigenvalues_screen.dart';
import '../../features/mathematics/svd/svd_screen.dart';
import '../../features/mathematics/determinant/determinant_screen.dart';
import '../../features/mathematics/euler_formula/euler_formula_screen.dart';
import '../../features/mathematics/complex_plane/complex_plane_screen.dart';
import '../../features/mathematics/bayes_theorem/bayes_theorem_screen.dart';
import '../../features/mathematics/markov_chain/markov_chain_screen.dart';
import '../../features/mathematics/prime_spiral/prime_spiral_screen.dart';
import '../../features/mathematics/modular_arithmetic/modular_arithmetic_screen.dart';
import '../../features/mathematics/rsa_crypto/rsa_crypto_screen.dart';
import '../../features/mathematics/mobius_strip/mobius_strip_screen.dart';
import '../../features/mathematics/klein_bottle/klein_bottle_screen.dart';
import '../../features/mathematics/hyperbolic_geometry/hyperbolic_geometry_screen.dart';
import '../../features/mathematics/julia_set/julia_set_screen.dart';
import '../../features/mathematics/sierpinski/sierpinski_screen.dart';
import '../../features/mathematics/koch_snowflake/koch_snowflake_screen.dart';
import '../../features/mathematics/combinatorics/combinatorics_screen.dart';
import '../../features/mathematics/boolean_algebra/boolean_algebra_screen.dart';
import '../../features/mathematics/logic_gates/logic_gates_screen.dart';
import '../../features/mathematics/ode_solver/ode_solver_screen.dart';
import '../../features/mathematics/heat_equation/heat_equation_screen.dart';
import '../../features/mathematics/wave_equation/wave_equation_screen.dart';
// Millennium Problems
import '../../features/mathematics/riemann_hypothesis/riemann_hypothesis_screen.dart';
import '../../features/mathematics/p_vs_np/p_vs_np_screen.dart';
import '../../features/mathematics/navier_stokes/navier_stokes_screen.dart';
import '../../features/mathematics/poincare/poincare_screen.dart';
// Quantum
import '../../features/quantum/double_slit/double_slit_screen.dart';
import '../../features/quantum/quantum_tunneling/quantum_tunneling_screen.dart';
import '../../features/quantum/photoelectric/photoelectric_screen.dart';
import '../../features/quantum/schrodinger/schrodinger_screen.dart';
import '../../features/quantum/heisenberg/heisenberg_screen.dart';
import '../../features/quantum/quantum_spin/quantum_spin_screen.dart';
import '../../features/quantum/entanglement/entanglement_screen.dart';
import '../../features/quantum/blackbody/blackbody_screen.dart';
import '../../features/quantum/de_broglie/de_broglie_screen.dart';
import '../../features/quantum/compton/compton_screen.dart';
import '../../features/quantum/hydrogen_atom/hydrogen_atom_screen.dart';
import '../../features/quantum/stern_gerlach/stern_gerlach_screen.dart';
import '../../features/quantum/particle_in_box/particle_in_box_screen.dart';
import '../../features/quantum/quantum_harmonic/quantum_harmonic_screen.dart';
import '../../features/quantum/pauli_exclusion/pauli_exclusion_screen.dart';
import '../../features/quantum/superposition/superposition_screen.dart';
import '../../features/quantum/wave_collapse/wave_collapse_screen.dart';
import '../../features/quantum/bell_inequality/bell_inequality_screen.dart';
import '../../features/quantum/quantum_gates/quantum_gates_screen.dart';
import '../../features/quantum/bloch_sphere/bloch_sphere_screen.dart';
// Physics - Additional (44 new simulations)
import '../../features/physics/work_energy/work_energy_screen.dart';
import '../../features/physics/power/power_screen.dart';
import '../../features/physics/impulse/impulse_screen.dart';
import '../../features/physics/torque/torque_screen.dart';
import '../../features/physics/moment_inertia/moment_inertia_screen.dart';
import '../../features/physics/wave_superposition/wave_superposition_screen.dart';
import '../../features/physics/sound_waves/sound_waves_screen.dart';
import '../../features/physics/wave_reflection/wave_reflection_screen.dart';
import '../../features/physics/kinetic_theory/kinetic_theory_screen.dart';
import '../../features/physics/first_law/first_law_screen.dart';
import '../../features/physics/carnot_cycle/carnot_cycle_screen.dart';
import '../../features/physics/entropy/entropy_screen.dart';
import '../../features/physics/heat_engine/heat_engine_screen.dart';
import '../../features/physics/heat_transfer/heat_transfer_screen.dart';
import '../../features/physics/maxwell_boltzmann/maxwell_boltzmann_screen.dart';
import '../../features/physics/coulomb_law/coulomb_law_screen.dart';
import '../../features/physics/electric_potential/electric_potential_screen.dart';
import '../../features/physics/capacitor/capacitor_screen.dart';
import '../../features/physics/magnetic_field/magnetic_field_screen.dart';
import '../../features/physics/lorentz_force/lorentz_force_screen.dart';
import '../../features/physics/faraday_law/faraday_law_screen.dart';
import '../../features/physics/lenz_law/lenz_law_screen.dart';
import '../../features/physics/ohm_law/ohm_law_screen.dart';
import '../../features/physics/series_parallel/series_parallel_screen.dart';
import '../../features/physics/kirchhoff/kirchhoff_screen.dart';
import '../../features/physics/lc_circuit/lc_circuit_screen.dart';
import '../../features/physics/rlc_circuit/rlc_circuit_screen.dart';
import '../../features/physics/em_wave/em_wave_screen.dart';
import '../../features/physics/transformer/transformer_screen.dart' as physics_transformer;
import '../../features/physics/motor_generator/motor_generator_screen.dart';
import '../../features/physics/refraction/refraction_screen.dart';
import '../../features/physics/reflection/reflection_screen.dart';
import '../../features/physics/total_internal/total_internal_screen.dart';
import '../../features/physics/thin_lens/thin_lens_screen.dart';
import '../../features/physics/mirror/mirror_screen.dart';
import '../../features/physics/diffraction/diffraction_screen.dart';
import '../../features/physics/double_slit/double_slit_screen.dart';
import '../../features/physics/polarization/polarization_screen.dart';
import '../../features/physics/prism/prism_screen.dart';
import '../../features/physics/bernoulli/bernoulli_screen.dart';
import '../../features/physics/viscosity/viscosity_screen.dart';
import '../../features/physics/reynolds/reynolds_screen.dart';
import '../../features/physics/continuity/continuity_screen.dart';
import '../../features/physics/pressure_depth/pressure_depth_screen.dart';
// Relativity
import '../../features/physics/time_dilation/time_dilation_screen.dart';
import '../../features/physics/length_contraction/length_contraction_screen.dart';
import '../../features/physics/twin_paradox/twin_paradox_screen.dart';
// Earth Science
import '../../features/earth_science/moon_phases/moon_phases_screen.dart';
import '../../features/earth_science/seasons/seasons_screen.dart';
import '../../features/earth_science/greenhouse_effect/greenhouse_effect_screen.dart';
// Biology
import '../../features/biology/dna_replication/dna_replication_screen.dart';
import '../../features/biology/protein_folding/protein_folding_screen.dart';
import '../../features/biology/predator_prey/predator_prey_screen.dart';
import '../../features/biology/epidemic_sir/epidemic_sir_screen.dart';
import '../../features/biology/natural_selection/natural_selection_screen.dart';
import '../../features/biology/neural_action_potential/neural_action_potential_screen.dart';
import '../../features/biology/population_genetics/population_genetics_screen.dart';
import '../../features/biology/enzyme_kinetics/enzyme_kinetics_screen.dart';
import '../../features/biology/cell_division/cell_division_screen.dart';
import '../../features/biology/photosynthesis/photosynthesis_screen.dart';
// Chaos - Additional
import '../../features/chaos/henon_attractor/henon_attractor_screen.dart';
import '../../features/chaos/rossler_attractor/rossler_attractor_screen.dart';
import '../../features/chaos/bifurcation/bifurcation_screen.dart';
import '../../features/chaos/cellular_automata/cellular_automata_screen.dart';
import '../../features/chaos/langton_ant/langton_ant_screen.dart';
import '../../features/chaos/percolation/percolation_screen.dart';
import '../../features/chaos/sandpile/sandpile_screen.dart';
// Chemistry - Additional
import '../../features/chemistry/electrochemistry/electrochemistry_screen.dart';
import '../../features/chemistry/emission_spectrum/emission_spectrum_screen.dart';
import '../../features/chemistry/phase_diagram/phase_diagram_screen.dart';
// Astronomy
import '../../features/astronomy/kepler_orbits/kepler_orbits_screen.dart';
import '../../features/astronomy/solar_system/solar_system_screen.dart';
import '../../features/astronomy/gravitational_lensing/gravitational_lensing_screen.dart';
import '../../features/astronomy/black_hole/black_hole_screen.dart';
import '../../features/astronomy/stellar_evolution/stellar_evolution_screen.dart';
import '../../features/astronomy/cosmic_expansion/cosmic_expansion_screen.dart';
import '../../features/astronomy/tidal_forces/tidal_forces_screen.dart';
import '../../features/astronomy/n_body/n_body_screen.dart';
// Relativity - Additional
import '../../features/relativity/lorentz_transformation/lorentz_transformation_screen.dart';
import '../../features/relativity/relativistic_momentum/relativistic_momentum_screen.dart';
import '../../features/relativity/mass_energy/mass_energy_screen.dart';
import '../../features/relativity/minkowski_diagram/minkowski_diagram_screen.dart';
import '../../features/relativity/relativistic_doppler/relativistic_doppler_screen.dart';
import '../../features/relativity/gravity/gravity_screen.dart';
import '../../features/relativity/gravitational_redshift/gravitational_redshift_screen.dart';
import '../../features/relativity/geodesics/geodesics_screen.dart';
import '../../features/relativity/schwarzschild/schwarzschild_screen.dart';
import '../../features/relativity/gravitational_waves/gravitational_waves_screen.dart';
// Earth Science - Additional
import '../../features/earth_science/plate_tectonics/plate_tectonics_screen.dart';
import '../../features/earth_science/earthquake_waves/earthquake_waves_screen.dart';
import '../../features/earth_science/rock_cycle/rock_cycle_screen.dart';
import '../../features/earth_science/water_cycle/water_cycle_screen.dart';
import '../../features/earth_science/atmosphere_layers/atmosphere_layers_screen.dart';
import '../../features/earth_science/coriolis_effect/coriolis_effect_screen.dart';
import '../../features/earth_science/eclipses/eclipses_screen.dart';
import '../../features/earth_science/carbon_cycle/carbon_cycle_screen.dart';
import '../../features/earth_science/ocean_currents/ocean_currents_screen.dart';

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
    case 'inclined-plane':
      return const InclinedPlaneScreen();
    case 'buoyancy':
      return const BuoyancyScreen();
    case 'lever':
      return const LeverScreen();
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
    case 'cnn':
      return const CnnScreen();
    case 'rnn-lstm':
      return const RnnLstmScreen();
    case 'transformer':
      return const TransformerScreen();
    case 'attention':
      return const AttentionScreen();
    case 'autoencoder':
      return const AutoencoderScreen();
    case 'gan':
      return const GanScreen();
    case 'word-embedding':
      return const WordEmbeddingScreen();
    case 'q-learning':
      return const QLearningScreen();
    case 'policy-gradient':
      return const PolicyGradientScreen();
    case 'multi-armed-bandit':
      return const MultiArmedBanditScreen();
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
    // Mathematics - New (24 simulations)
    case 'integral':
      return const IntegralScreen();
    case 'matrix-transform':
      return const MatrixTransformScreen();
    case 'eigenvalues':
      return const EigenvaluesScreen();
    case 'svd':
      return const SvdScreen();
    case 'determinant':
      return const DeterminantScreen();
    case 'euler-formula':
      return const EulerFormulaScreen();
    case 'complex-plane':
      return const ComplexPlaneScreen();
    case 'bayes-theorem':
      return const BayesTheoremScreen();
    case 'markov-chain':
      return const MarkovChainScreen();
    case 'prime-spiral':
      return const PrimeSpiralScreen();
    case 'modular-arithmetic':
      return const ModularArithmeticScreen();
    case 'rsa-crypto':
      return const RsaCryptoScreen();
    case 'mobius-strip':
      return const MobiusStripScreen();
    case 'klein-bottle':
      return const KleinBottleScreen();
    case 'hyperbolic-geometry':
      return const HyperbolicGeometryScreen();
    case 'julia-set':
      return const JuliaSetScreen();
    case 'sierpinski':
      return const SierpinskiScreen();
    case 'koch-snowflake':
      return const KochSnowflakeScreen();
    case 'combinatorics':
      return const CombinatoricsScreen();
    case 'boolean-algebra':
      return const BooleanAlgebraScreen();
    case 'logic-gates':
      return const LogicGatesScreen();
    case 'ode-solver':
      return const OdeSolverScreen();
    case 'heat-equation':
      return const HeatEquationScreen();
    case 'wave-equation':
      return const WaveEquationScreen();
    // Millennium Problems
    case 'riemann-hypothesis':
      return const RiemannHypothesisScreen();
    case 'p-vs-np':
      return const PVsNpScreen();
    case 'navier-stokes':
      return const NavierStokesScreen();
    case 'poincare':
      return const PoincareScreen();
    // Relativity
    case 'time-dilation':
      return const TimeDilationScreen();
    case 'length-contraction':
      return const LengthContractionScreen();
    case 'twin-paradox':
      return const TwinParadoxScreen();
    // Quantum
    case 'double-slit-quantum':
      return const DoubleSlitScreen();
    case 'quantum-tunneling':
      return const QuantumTunnelingScreen();
    case 'photoelectric':
      return const PhotoelectricScreen();
    case 'schrodinger':
      return const SchrodingerScreen();
    case 'heisenberg':
      return const HeisenbergScreen();
    case 'quantum-spin':
      return const QuantumSpinScreen();
    case 'entanglement':
      return const EntanglementScreen();
    case 'blackbody':
      return const BlackbodyScreen();
    case 'de-broglie':
      return const DeBroglieScreen();
    case 'compton':
      return const ComptonScreen();
    case 'hydrogen-atom':
      return const HydrogenAtomScreen();
    case 'stern-gerlach':
      return const SternGerlachScreen();
    case 'particle-in-box':
      return const ParticleInBoxScreen();
    case 'quantum-harmonic':
      return const QuantumHarmonicScreen();
    case 'pauli-exclusion':
      return const PauliExclusionScreen();
    case 'superposition':
      return const SuperpositionScreen();
    case 'wave-collapse':
      return const WaveCollapseScreen();
    case 'bell-inequality':
      return const BellInequalityScreen();
    case 'quantum-gates':
      return const QuantumGatesScreen();
    case 'bloch-sphere':
      return const BlochSphereScreen();
    // Earth Science
    case 'moon-phases':
      return const MoonPhasesScreen();
    case 'seasons':
      return const SeasonsScreen();
    case 'greenhouse-effect':
      return const GreenhouseEffectScreen();
    // Biology
    case 'dna-replication':
      return const DnaReplicationScreen();
    case 'protein-folding':
      return const ProteinFoldingScreen();
    case 'predator-prey':
      return const PredatorPreyScreen();
    case 'epidemic-sir':
      return const EpidemicSirScreen();
    case 'natural-selection':
      return const NaturalSelectionScreen();
    case 'neural-action-potential':
      return const NeuralActionPotentialScreen();
    case 'population-genetics':
      return const PopulationGeneticsScreen();
    case 'enzyme-kinetics':
      return const EnzymeKineticsScreen();
    case 'cell-division':
      return const CellDivisionScreen();
    case 'photosynthesis':
      return const PhotosynthesisScreen();
    // Chaos - Additional
    case 'henon-attractor':
      return const HenonAttractorScreen();
    case 'rossler-attractor':
      return const RosslerAttractorScreen();
    case 'bifurcation':
      return const BifurcationScreen();
    case 'cellular-automata':
      return const CellularAutomataScreen();
    case 'langton-ant':
      return const LangtonAntScreen();
    case 'percolation':
      return const PercolationScreen();
    case 'sandpile':
      return const SandpileScreen();
    // Chemistry - Additional
    case 'electrochemistry':
      return const ElectrochemistryScreen();
    case 'emission-spectrum':
      return const EmissionSpectrumScreen();
    case 'phase-diagram':
      return const PhaseDiagramScreen();
    // Physics - Additional (44 new simulations)
    case 'work-energy':
      return const WorkEnergyScreen();
    case 'power':
      return const PowerScreen();
    case 'impulse':
      return const ImpulseScreen();
    case 'torque':
      return const TorqueScreen();
    case 'moment-inertia':
      return const MomentInertiaScreen();
    case 'wave-superposition':
      return const WaveSuperpositionScreen();
    case 'sound-waves':
      return const SoundWavesScreen();
    case 'wave-reflection':
      return const WaveReflectionScreen();
    case 'kinetic-theory':
      return const KineticTheoryScreen();
    case 'first-law':
      return const FirstLawScreen();
    case 'carnot-cycle':
      return const CarnotCycleScreen();
    case 'entropy':
      return const EntropyScreen();
    case 'heat-engine':
      return const HeatEngineScreen();
    case 'heat-transfer':
      return const HeatTransferScreen();
    case 'maxwell-boltzmann':
      return const MaxwellBoltzmannScreen();
    case 'coulomb-law':
      return const CoulombLawScreen();
    case 'electric-potential':
      return const ElectricPotentialScreen();
    case 'capacitor':
      return const CapacitorScreen();
    case 'magnetic-field':
      return const MagneticFieldScreen();
    case 'lorentz-force':
      return const LorentzForceScreen();
    case 'faraday-law':
      return const FaradayLawScreen();
    case 'lenz-law':
      return const LenzLawScreen();
    case 'ohm-law':
      return const OhmLawScreen();
    case 'series-parallel':
      return const SeriesParallelScreen();
    case 'kirchhoff':
      return const KirchhoffScreen();
    case 'lc-circuit':
      return const LcCircuitScreen();
    case 'rlc-circuit':
      return const RlcCircuitScreen();
    case 'em-wave':
      return const EmWaveScreen();
    case 'transformer-physics':
      return const physics_transformer.TransformerScreen();
    case 'motor-generator':
      return const MotorGeneratorScreen();
    case 'refraction':
      return const RefractionScreen();
    case 'reflection':
      return const ReflectionScreen();
    case 'total-internal':
      return const TotalInternalScreen();
    case 'thin-lens':
      return const ThinLensScreen();
    case 'mirror':
      return const MirrorScreen();
    case 'diffraction':
      return const DiffractionScreen();
    case 'double-slit-physics':
      return const DoubleSlitPhysicsScreen();
    case 'polarization':
      return const PolarizationScreen();
    case 'prism':
      return const PrismScreen();
    case 'bernoulli':
      return const BernoulliScreen();
    case 'viscosity':
      return const ViscosityScreen();
    case 'reynolds':
      return const ReynoldsScreen();
    case 'continuity':
      return const ContinuityScreen();
    case 'pressure-depth':
      return const PressureDepthScreen();
    // Astronomy
    case 'kepler-orbits':
      return const KeplerOrbitsScreen();
    case 'solar-system':
      return const SolarSystemScreen();
    case 'gravitational-lensing':
      return const GravitationalLensingScreen();
    case 'black-hole':
      return const BlackHoleScreen();
    case 'stellar-evolution':
      return const StellarEvolutionScreen();
    case 'cosmic-expansion':
      return const CosmicExpansionScreen();
    case 'tidal-forces':
      return const TidalForcesScreen();
    case 'n-body':
      return const NBodyScreen();
    // Relativity - Additional
    case 'lorentz-transformation':
      return const LorentzTransformationScreen();
    case 'relativistic-momentum':
      return const RelativisticMomentumScreen();
    case 'mass-energy':
      return const MassEnergyScreen();
    case 'minkowski-diagram':
      return const MinkowskiDiagramScreen();
    case 'relativistic-doppler':
      return const RelativisticDopplerScreen();
    case 'general-relativity':
      return const GravityRelativityScreen();
    case 'gravitational-redshift':
      return const GravitationalRedshiftScreen();
    case 'geodesics':
      return const GeodesicsScreen();
    case 'schwarzschild':
      return const SchwarzschildScreen();
    case 'gravitational-waves':
      return const GravitationalWavesScreen();
    // Earth Science - Additional
    case 'plate-tectonics':
      return const PlateTectonicsScreen();
    case 'earthquake-waves':
      return const EarthquakeWavesScreen();
    case 'rock-cycle':
      return const RockCycleScreen();
    case 'water-cycle':
      return const WaterCycleScreen();
    case 'atmosphere-layers':
      return const AtmosphereLayersScreen();
    case 'coriolis-effect':
      return const CoriolisEffectScreen();
    case 'eclipses':
      return const EclipsesScreen(isKorean: false);
    case 'carbon-cycle':
      return const CarbonCycleScreen(isKorean: false);
    case 'ocean-currents':
      return const OceanCurrentsScreen(isKorean: false);
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
