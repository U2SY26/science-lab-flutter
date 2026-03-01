import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../animations/animations.dart';
import '../../shared/widgets/ad_banner.dart';
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
// Phase 1 - New Simulations (40)
// Physics
import '../../features/physics/simple_harmonic/simple_harmonic_screen.dart';
import '../../features/physics/coupled_oscillators/coupled_oscillators_screen.dart';
import '../../features/physics/gyroscope/gyroscope_screen.dart';
import '../../features/physics/ballistic_pendulum/ballistic_pendulum_screen.dart';
// Math
import '../../features/mathematics/game_theory/game_theory_screen.dart';
import '../../features/mathematics/prisoners_dilemma/prisoners_dilemma_screen.dart';
import '../../features/mathematics/linear_programming/linear_programming_screen.dart';
import '../../features/mathematics/simplex_method/simplex_method_screen.dart';
// AI/ML
import '../../features/deep_learning/naive_bayes/naive_bayes_screen.dart';
import '../../features/machine_learning/random_forest/random_forest_screen.dart';
import '../../features/deep_learning/gradient_boosting/gradient_boosting_screen.dart';
import '../../features/machine_learning/logistic_regression/logistic_regression_screen.dart';
// Quantum
import '../../features/quantum/quantum_teleportation/quantum_teleportation_screen.dart';
import '../../features/quantum/quantum_error_correction/quantum_error_correction_screen.dart';
import '../../features/quantum/grover_algorithm/grover_algorithm_screen.dart';
import '../../features/quantum/shor_algorithm/shor_algorithm_screen.dart';
// Chemistry
import '../../features/chemistry/gas_laws/gas_laws_screen.dart';
import '../../features/chemistry/dalton_law/dalton_law_screen.dart';
import '../../features/chemistry/colligative_properties/colligative_properties_screen.dart';
import '../../features/chemistry/solubility_curve/solubility_curve_screen.dart';
// Relativity
import '../../features/relativity/proper_time/proper_time_screen.dart';
import '../../features/relativity/four_vectors/four_vectors_screen.dart';
import '../../features/relativity/velocity_addition/velocity_addition_screen.dart';
import '../../features/relativity/barn_pole_paradox/barn_pole_paradox_screen.dart';
// Earth Science
import '../../features/earth_science/weather_fronts/weather_fronts_screen.dart';
import '../../features/earth_science/hurricane_formation/hurricane_formation_screen.dart';
import '../../features/earth_science/jet_stream/jet_stream_screen.dart';
import '../../features/earth_science/orographic_rainfall/orographic_rainfall_screen.dart';
// Chaos
import '../../features/chaos/barnsley_fern/barnsley_fern_screen.dart';
import '../../features/chaos/dragon_curve/dragon_curve_screen.dart';
import '../../features/chaos/diffusion_limited/diffusion_limited_screen.dart';
import '../../features/chaos/reaction_diffusion/reaction_diffusion_screen.dart';
// Biology
import '../../features/biology/mendelian_genetics/mendelian_genetics_screen.dart';
import '../../features/biology/punnett_square/punnett_square_screen.dart';
import '../../features/biology/gene_expression/gene_expression_screen.dart';
import '../../features/biology/genetic_drift/genetic_drift_screen.dart';
// Astronomy
import '../../features/astronomy/hr_diagram/hr_diagram_screen.dart';
import '../../features/astronomy/stellar_nucleosynthesis/stellar_nucleosynthesis_screen.dart';
import '../../features/astronomy/chandrasekhar_limit/chandrasekhar_limit_screen.dart';
import '../../features/astronomy/neutron_star/neutron_star_screen.dart';
// Phase 2 imports
import '../../features/physics/venturi_tube/venturi_tube_screen.dart';
import '../../features/physics/surface_tension/surface_tension_screen.dart';
import '../../features/physics/hooke_spring_series/hooke_spring_series_screen.dart';
import '../../features/physics/wheatstone_bridge/wheatstone_bridge_screen.dart';
import '../../features/mathematics/gradient_field/gradient_field_screen.dart';
import '../../features/mathematics/divergence_curl/divergence_curl_screen.dart';
import '../../features/mathematics/laplace_transform/laplace_transform_screen.dart';
import '../../features/mathematics/z_transform/z_transform_screen.dart';
import '../../features/machine_learning/dbscan/dbscan_screen.dart';
import '../../features/machine_learning/confusion_matrix/confusion_matrix_screen.dart';
import '../../features/machine_learning/cross_validation/cross_validation_screen.dart';
import '../../features/deep_learning/bias_variance/bias_variance_screen.dart';
import '../../features/quantum/quantum_fourier/quantum_fourier_screen.dart';
import '../../features/quantum/density_matrix/density_matrix_screen.dart';
import '../../features/quantum/quantum_walk/quantum_walk_screen.dart';
import '../../features/quantum/quantum_decoherence/quantum_decoherence_screen.dart';
import '../../features/chemistry/crystal_lattice/crystal_lattice_screen.dart';
import '../../features/chemistry/hess_law/hess_law_screen.dart';
import '../../features/chemistry/enthalpy_diagram/enthalpy_diagram_screen.dart';
import '../../features/chemistry/le_chatelier/le_chatelier_screen.dart';
import '../../features/relativity/relativistic_energy/relativistic_energy_screen.dart';
import '../../features/relativity/light_cone/light_cone_screen.dart';
import '../../features/relativity/equivalence_principle/equivalence_principle_screen.dart';
import '../../features/relativity/metric_tensor/metric_tensor_screen.dart';
import '../../features/earth_science/soil_layers/soil_layers_screen.dart';
import '../../features/earth_science/volcano_types/volcano_types_screen.dart';
import '../../features/earth_science/mineral_identification/mineral_identification_screen.dart';
import '../../features/earth_science/erosion_deposition/erosion_deposition_screen.dart';
import '../../features/chaos/flocking/flocking_screen.dart';
import '../../features/chaos/ant_colony/ant_colony_screen.dart';
import '../../features/chaos/forest_fire/forest_fire_screen.dart';
import '../../features/chaos/network_cascade/network_cascade_screen.dart';
import '../../features/biology/speciation/speciation_screen.dart';
import '../../features/biology/phylogenetic_tree/phylogenetic_tree_screen.dart';
import '../../features/biology/food_web/food_web_screen.dart';
import '../../features/biology/ecological_succession/ecological_succession_screen.dart';
import '../../features/astronomy/supernova/supernova_screen.dart';
import '../../features/astronomy/binary_star/binary_star_screen.dart';
import '../../features/astronomy/exoplanet_transit/exoplanet_transit_screen.dart';
import '../../features/astronomy/parallax/parallax_screen.dart';
// Phase 3 imports
import '../../features/physics/magnetic_induction/magnetic_induction_screen.dart';
import '../../features/physics/ac_circuits/ac_circuits_screen.dart';
import '../../features/physics/photodiode/photodiode_screen.dart';
import '../../features/physics/hall_effect/hall_effect_screen.dart';
import '../../features/mathematics/convolution/convolution_screen.dart';
import '../../features/mathematics/fibonacci_sequence/fibonacci_sequence_screen.dart';
import '../../features/mathematics/euler_path/euler_path_screen.dart';
import '../../features/mathematics/minimum_spanning_tree/minimum_spanning_tree_screen.dart';
import '../../features/deep_learning/batch_norm/batch_norm_screen.dart';
import '../../features/deep_learning/learning_rate/learning_rate_screen.dart';
import '../../features/deep_learning/backpropagation/backpropagation_screen.dart';
import '../../features/deep_learning/vae/vae_screen.dart';
import '../../features/quantum/quantum_zeno/quantum_zeno_screen.dart';
import '../../features/quantum/aharonov_bohm/aharonov_bohm_screen.dart';
import '../../features/quantum/quantum_key_dist/quantum_key_dist_screen.dart';
import '../../features/quantum/franck_hertz/franck_hertz_screen.dart';
import '../../features/chemistry/equilibrium_constant/equilibrium_constant_screen.dart';
import '../../features/chemistry/buffer_solution/buffer_solution_screen.dart';
import '../../features/chemistry/radioactive_decay/radioactive_decay_screen.dart';
import '../../features/chemistry/nuclear_fission_fusion/nuclear_fission_fusion_screen.dart';
import '../../features/relativity/frame_dragging/frame_dragging_screen.dart';
import '../../features/relativity/penrose_diagram/penrose_diagram_screen.dart';
import '../../features/relativity/friedmann_equations/friedmann_equations_screen.dart';
import '../../features/relativity/hubble_expansion/hubble_expansion_screen.dart';
import '../../features/earth_science/ocean_tides/ocean_tides_screen.dart';
import '../../features/earth_science/thermohaline/thermohaline_screen.dart';
import '../../features/earth_science/el_nino/el_nino_screen.dart';
import '../../features/earth_science/ice_ages/ice_ages_screen.dart';
import '../../features/chaos/small_world/small_world_screen.dart';
import '../../features/chaos/scale_free_network/scale_free_network_screen.dart';
import '../../features/chaos/strange_attractor_explorer/strange_attractor_explorer_screen.dart';
import '../../features/chaos/feigenbaum/feigenbaum_screen.dart';
import '../../features/biology/carbon_fixation/carbon_fixation_screen.dart';
import '../../features/biology/krebs_cycle/krebs_cycle_screen.dart';
import '../../features/biology/osmosis/osmosis_screen.dart';
import '../../features/biology/action_potential_synapse/action_potential_synapse_screen.dart';
import '../../features/astronomy/redshift_measurement/redshift_measurement_screen.dart';
import '../../features/astronomy/planet_formation/planet_formation_screen.dart';
import '../../features/astronomy/roche_limit/roche_limit_screen.dart';
import '../../features/astronomy/lagrange_points/lagrange_points_screen.dart';
// Phase 4 imports
import '../../features/physics/eddy_currents/eddy_currents_screen.dart';
import '../../features/physics/pascal_hydraulic/pascal_hydraulic_screen.dart';
import '../../features/physics/specific_heat/specific_heat_screen.dart';
import '../../features/physics/stefan_boltzmann/stefan_boltzmann_screen.dart';
import '../../features/mathematics/dijkstra/dijkstra_screen.dart';
import '../../features/mathematics/voronoi/voronoi_screen.dart';
import '../../features/mathematics/delaunay/delaunay_screen.dart';
import '../../features/mathematics/bezier_curves/bezier_curves_screen.dart';
import '../../features/deep_learning/diffusion_model/diffusion_model_screen.dart';
import '../../features/deep_learning/tokenizer/tokenizer_screen.dart';
import '../../features/deep_learning/beam_search/beam_search_screen.dart';
import '../../features/machine_learning/feature_importance/feature_importance_screen.dart';
import '../../features/quantum/zeeman_effect/zeeman_effect_screen.dart';
import '../../features/quantum/quantum_well/quantum_well_screen.dart';
import '../../features/quantum/band_structure/band_structure_screen.dart';
import '../../features/quantum/bose_einstein/bose_einstein_screen.dart';
import '../../features/chemistry/organic_functional_groups/organic_functional_groups_screen.dart';
import '../../features/chemistry/isomers/isomers_screen.dart';
import '../../features/chemistry/polymerization/polymerization_screen.dart';
import '../../features/chemistry/electrolysis/electrolysis_screen.dart';
import '../../features/relativity/cosmic_microwave_bg/cosmic_microwave_bg_screen.dart';
import '../../features/relativity/kerr_black_hole/kerr_black_hole_screen.dart';
import '../../features/relativity/shapiro_delay/shapiro_delay_screen.dart';
import '../../features/relativity/gravitational_time/gravitational_time_screen.dart';
import '../../features/earth_science/ozone_layer/ozone_layer_screen.dart';
import '../../features/earth_science/radiation_budget/radiation_budget_screen.dart';
import '../../features/earth_science/nitrogen_cycle/nitrogen_cycle_screen.dart';
import '../../features/earth_science/fossil_formation/fossil_formation_screen.dart';
import '../../features/chaos/lyapunov_exponent/lyapunov_exponent_screen.dart';
import '../../features/chaos/tent_map/tent_map_screen.dart';
import '../../features/chaos/sierpinski_carpet/sierpinski_carpet_screen.dart';
import '../../features/chaos/chaos_game/chaos_game_screen.dart';
import '../../features/biology/immune_response/immune_response_screen.dart';
import '../../features/biology/muscle_contraction/muscle_contraction_screen.dart';
import '../../features/biology/heart_conduction/heart_conduction_screen.dart';
import '../../features/biology/blood_circulation/blood_circulation_screen.dart';
import '../../features/astronomy/orbital_transfer/orbital_transfer_screen.dart';
import '../../features/astronomy/escape_velocity/escape_velocity_screen.dart';
import '../../features/astronomy/celestial_sphere/celestial_sphere_screen.dart';
import '../../features/astronomy/galaxy_rotation/galaxy_rotation_screen.dart';
// Phase 5 imports
import '../../features/physics/wave_packet/wave_packet_screen.dart';
import '../../features/physics/lissajous/lissajous_screen.dart';
import '../../features/physics/doppler_radar/doppler_radar_screen.dart';
import '../../features/physics/cavendish/cavendish_screen.dart';
import '../../features/mathematics/polar_coordinates/polar_coordinates_screen.dart';
import '../../features/mathematics/parametric_curves/parametric_curves_screen.dart';
import '../../features/mathematics/binomial_distribution/binomial_distribution_screen.dart';
import '../../features/mathematics/poisson_distribution/poisson_distribution_screen.dart';
import '../../features/machine_learning/dimensionality_reduction/dimensionality_reduction_screen.dart';
import '../../features/deep_learning/neural_style/neural_style_screen.dart';
import '../../features/machine_learning/maze_rl/maze_rl_screen.dart';
import '../../features/machine_learning/minimax/minimax_screen.dart';
import '../../features/quantum/fermi_dirac/fermi_dirac_screen.dart';
import '../../features/quantum/wigner_function/wigner_function_screen.dart';
import '../../features/quantum/quantum_oscillator_2d/quantum_oscillator_2d_screen.dart';
import '../../features/quantum/spin_chain/spin_chain_screen.dart';
import '../../features/chemistry/ideal_solution/ideal_solution_screen.dart';
import '../../features/chemistry/chromatography/chromatography_screen.dart';
import '../../features/chemistry/calorimetry/calorimetry_screen.dart';
import '../../features/chemistry/activation_energy/activation_energy_screen.dart';
import '../../features/relativity/relativistic_aberration/relativistic_aberration_screen.dart';
import '../../features/relativity/relativistic_beaming/relativistic_beaming_screen.dart';
import '../../features/relativity/cosmological_redshift/cosmological_redshift_screen.dart';
import '../../features/relativity/dark_energy/dark_energy_screen.dart';
import '../../features/earth_science/magnetic_reversal/magnetic_reversal_screen.dart';
import '../../features/earth_science/seismograph/seismograph_screen.dart';
import '../../features/earth_science/continental_drift/continental_drift_screen.dart';
import '../../features/earth_science/greenhouse_gases/greenhouse_gases_screen.dart';
import '../../features/chaos/rule_110/rule_110_screen.dart';
import '../../features/chaos/schelling_segregation/schelling_segregation_screen.dart';
import '../../features/chaos/duffing_oscillator/duffing_oscillator_screen.dart';
import '../../features/chaos/belousov_zhabotinsky/belousov_zhabotinsky_screen.dart';
import '../../features/biology/cellular_respiration/cellular_respiration_screen.dart';
import '../../features/biology/logistic_growth/logistic_growth_screen.dart';
import '../../features/biology/competitive_exclusion/competitive_exclusion_screen.dart';
import '../../features/biology/crispr/crispr_screen.dart';
import '../../features/astronomy/dark_matter/dark_matter_screen.dart';
import '../../features/astronomy/pulsar/pulsar_screen.dart';
import '../../features/astronomy/asteroid_belt/asteroid_belt_screen.dart';
import '../../features/astronomy/cosmic_distance_ladder/cosmic_distance_ladder_screen.dart';

/// 앱 라우터 설정
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
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
    // 시뮬레이션 (배너 광고 포함)
    GoRoute(
      path: '/simulation/:simId',
      pageBuilder: (context, state) {
        final simId = state.pathParameters['simId']!;
        return ScaleFadeTransitionPage(
          key: state.pageKey,
          child: _SimulationAdWrapper(child: _getSimulationScreen(simId)),
        );
      },
    ),
  ],
);

/// 시뮬레이션 화면을 배너 광고와 함께 표시하는 래퍼
class _SimulationAdWrapper extends StatelessWidget {
  final Widget child;
  const _SimulationAdWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: child),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 4),
          child: const AdBannerWidget(),
        ),
      ],
    );
  }
}

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
    // Phase 1 - New Simulations
    case 'simple-harmonic':
      return const SimpleHarmonicScreen();
    case 'coupled-oscillators':
      return const CoupledOscillatorsScreen();
    case 'gyroscope':
      return const GyroscopeScreen();
    case 'ballistic-pendulum':
      return const BallisticPendulumScreen();
    case 'game-theory':
      return const GameTheoryScreen();
    case 'prisoners-dilemma':
      return const PrisonersDilemmaScreen();
    case 'linear-programming':
      return const LinearProgrammingScreen();
    case 'simplex-method':
      return const SimplexMethodScreen();
    case 'naive-bayes':
      return const NaiveBayesScreen();
    case 'random-forest':
      return const RandomForestScreen();
    case 'gradient-boosting':
      return const GradientBoostingScreen();
    case 'logistic-regression':
      return const LogisticRegressionScreen();
    case 'quantum-teleportation':
      return const QuantumTeleportationScreen();
    case 'quantum-error-correction':
      return const QuantumErrorCorrectionScreen();
    case 'grover-algorithm':
      return const GroverAlgorithmScreen();
    case 'shor-algorithm':
      return const ShorAlgorithmScreen();
    case 'gas-laws':
      return const GasLawsScreen();
    case 'dalton-law':
      return const DaltonLawScreen();
    case 'colligative-properties':
      return const ColligativePropertiesScreen();
    case 'solubility-curve':
      return const SolubilityCurveScreen();
    case 'proper-time':
      return const ProperTimeScreen();
    case 'four-vectors':
      return const FourVectorsScreen();
    case 'velocity-addition':
      return const VelocityAdditionScreen();
    case 'barn-pole-paradox':
      return const BarnPoleParadoxScreen();
    case 'weather-fronts':
      return const WeatherFrontsScreen();
    case 'hurricane-formation':
      return const HurricaneFormationScreen();
    case 'jet-stream':
      return const JetStreamScreen();
    case 'orographic-rainfall':
      return const OrographicRainfallScreen();
    case 'barnsley-fern':
      return const BarnsleyFernScreen();
    case 'dragon-curve':
      return const DragonCurveScreen();
    case 'diffusion-limited':
      return const DiffusionLimitedScreen();
    case 'reaction-diffusion':
      return const ReactionDiffusionScreen();
    case 'mendelian-genetics':
      return const MendelianGeneticsScreen();
    case 'punnett-square':
      return const PunnettSquareScreen();
    case 'gene-expression':
      return const GeneExpressionScreen();
    case 'genetic-drift':
      return const GeneticDriftScreen();
    case 'hr-diagram':
      return const HrDiagramScreen();
    case 'stellar-nucleosynthesis':
      return const StellarNucleosynthesisScreen();
    case 'chandrasekhar-limit':
      return const ChandrasekharLimitScreen();
    case 'neutron-star':
      return const NeutronStarScreen();
    // Phase 2 cases
    case 'venturi-tube':
      return const VenturiTubeScreen();
    case 'surface-tension':
      return const SurfaceTensionScreen();
    case 'hooke-spring-series':
      return const HookeSpringScreen();
    case 'wheatstone-bridge':
      return const WheatstoneBridgeScreen();
    case 'gradient-field':
      return const GradientFieldScreen();
    case 'divergence-curl':
      return const DivergenceCurlScreen();
    case 'laplace-transform':
      return const LaplaceTransformScreen();
    case 'z-transform':
      return const ZTransformScreen();
    case 'dbscan':
      return const DbscanScreen();
    case 'confusion-matrix':
      return const ConfusionMatrixScreen();
    case 'cross-validation':
      return const CrossValidationScreen();
    case 'bias-variance':
      return const BiasVarianceScreen();
    case 'quantum-fourier':
      return const QuantumFourierScreen();
    case 'density-matrix':
      return const DensityMatrixScreen();
    case 'quantum-walk':
      return const QuantumWalkScreen();
    case 'quantum-decoherence':
      return const QuantumDecoherenceScreen();
    case 'crystal-lattice':
      return const CrystalLatticeScreen();
    case 'hess-law':
      return const HessLawScreen();
    case 'enthalpy-diagram':
      return const EnthalpyDiagramScreen();
    case 'le-chatelier':
      return const LeChatelierScreen();
    case 'relativistic-energy':
      return const RelativisticEnergyScreen();
    case 'light-cone':
      return const LightConeScreen();
    case 'equivalence-principle':
      return const EquivalencePrincipleScreen();
    case 'metric-tensor':
      return const MetricTensorScreen();
    case 'soil-layers':
      return const SoilLayersScreen();
    case 'volcano-types':
      return const VolcanoTypesScreen();
    case 'mineral-identification':
      return const MineralIdentificationScreen();
    case 'erosion-deposition':
      return const ErosionDepositionScreen();
    case 'flocking':
      return const FlockingScreen();
    case 'ant-colony':
      return const AntColonyScreen();
    case 'forest-fire':
      return const ForestFireScreen();
    case 'network-cascade':
      return const NetworkCascadeScreen();
    case 'speciation':
      return const SpeciationScreen();
    case 'phylogenetic-tree':
      return const PhylogeneticTreeScreen();
    case 'food-web':
      return const FoodWebScreen();
    case 'ecological-succession':
      return const EcologicalSuccessionScreen();
    case 'supernova':
      return const SupernovaScreen();
    case 'binary-star':
      return const BinaryStarScreen();
    case 'exoplanet-transit':
      return const ExoplanetTransitScreen();
    case 'parallax':
      return const ParallaxScreen();
    // Phase 3 cases
    case 'magnetic-induction': return const MagneticInductionScreen();
    case 'ac-circuits': return const AcCircuitsScreen();
    case 'photodiode': return const PhotodiodeScreen();
    case 'hall-effect': return const HallEffectScreen();
    case 'convolution': return const ConvolutionScreen();
    case 'fibonacci-sequence': return const FibonacciSequenceScreen();
    case 'euler-path': return const EulerPathScreen();
    case 'minimum-spanning-tree': return const MinimumSpanningTreeScreen();
    case 'batch-norm': return const BatchNormScreen();
    case 'learning-rate': return const LearningRateScreen();
    case 'backpropagation': return const BackpropagationScreen();
    case 'vae': return const VaeScreen();
    case 'quantum-zeno': return const QuantumZenoScreen();
    case 'aharonov-bohm': return const AharonovBohmScreen();
    case 'quantum-key-dist': return const QuantumKeyDistScreen();
    case 'franck-hertz': return const FranckHertzScreen();
    case 'equilibrium-constant': return const EquilibriumConstantScreen();
    case 'buffer-solution': return const BufferSolutionScreen();
    case 'radioactive-decay': return const RadioactiveDecayScreen();
    case 'nuclear-fission-fusion': return const NuclearFissionFusionScreen();
    case 'frame-dragging': return const FrameDraggingScreen();
    case 'penrose-diagram': return const PenroseDiagramScreen();
    case 'friedmann-equations': return const FriedmannEquationsScreen();
    case 'hubble-expansion': return const HubbleExpansionScreen();
    case 'ocean-tides': return const OceanTidesScreen();
    case 'thermohaline': return const ThermohalineScreen();
    case 'el-nino': return const ElNinoScreen();
    case 'ice-ages': return const IceAgesScreen();
    case 'small-world': return const SmallWorldScreen();
    case 'scale-free-network': return const ScaleFreeNetworkScreen();
    case 'strange-attractor-explorer': return const StrangeAttractorExplorerScreen();
    case 'feigenbaum': return const FeigenbaumScreen();
    case 'carbon-fixation': return const CarbonFixationScreen();
    case 'krebs-cycle': return const KrebsCycleScreen();
    case 'osmosis': return const OsmosisScreen();
    case 'action-potential-synapse': return const ActionPotentialSynapseScreen();
    case 'redshift-measurement': return const RedshiftMeasurementScreen();
    case 'planet-formation': return const PlanetFormationScreen();
    case 'roche-limit': return const RocheLimitScreen();
    case 'lagrange-points': return const LagrangePointsScreen();
    // Phase 4 cases
    case 'eddy-currents': return const EddyCurrentsScreen();
    case 'pascal-hydraulic': return const PascalHydraulicScreen();
    case 'specific-heat': return const SpecificHeatScreen();
    case 'stefan-boltzmann': return const StefanBoltzmannScreen();
    case 'dijkstra': return const DijkstraScreen();
    case 'voronoi': return const VoronoiScreen();
    case 'delaunay': return const DelaunayScreen();
    case 'bezier-curves': return const BezierCurvesScreen();
    case 'diffusion-model': return const DiffusionModelScreen();
    case 'tokenizer': return const TokenizerScreen();
    case 'beam-search': return const BeamSearchScreen();
    case 'feature-importance': return const FeatureImportanceScreen();
    case 'zeeman-effect': return const ZeemanEffectScreen();
    case 'quantum-well': return const QuantumWellScreen();
    case 'band-structure': return const BandStructureScreen();
    case 'bose-einstein': return const BoseEinsteinScreen();
    case 'organic-functional-groups': return const OrganicFunctionalGroupsScreen();
    case 'isomers': return const IsomersScreen();
    case 'polymerization': return const PolymerizationScreen();
    case 'electrolysis': return const ElectrolysisScreen();
    case 'cosmic-microwave-bg': return const CosmicMicrowaveBgScreen();
    case 'kerr-black-hole': return const KerrBlackHoleScreen();
    case 'shapiro-delay': return const ShapiroDelayScreen();
    case 'gravitational-time': return const GravitationalTimeScreen();
    case 'ozone-layer': return const OzoneLayerScreen();
    case 'radiation-budget': return const RadiationBudgetScreen();
    case 'nitrogen-cycle': return const NitrogenCycleScreen();
    case 'fossil-formation': return const FossilFormationScreen();
    case 'lyapunov-exponent': return const LyapunovExponentScreen();
    case 'tent-map': return const TentMapScreen();
    case 'sierpinski-carpet': return const SierpinskiCarpetScreen();
    case 'chaos-game': return const ChaosGameScreen();
    case 'immune-response': return const ImmuneResponseScreen();
    case 'muscle-contraction': return const MuscleContractionScreen();
    case 'heart-conduction': return const HeartConductionScreen();
    case 'blood-circulation': return const BloodCirculationScreen();
    case 'orbital-transfer': return const OrbitalTransferScreen();
    case 'escape-velocity': return const EscapeVelocityScreen();
    case 'celestial-sphere': return const CelestialSphereScreen();
    case 'galaxy-rotation': return const GalaxyRotationScreen();
    // Phase 5 cases
    case 'wave-packet': return const WavePacketScreen();
    case 'lissajous': return const LissajousScreen();
    case 'doppler-radar': return const DopplerRadarScreen();
    case 'cavendish': return const CavendishScreen();
    case 'polar-coordinates': return const PolarCoordinatesScreen();
    case 'parametric-curves': return const ParametricCurvesScreen();
    case 'binomial-distribution': return const BinomialDistributionScreen();
    case 'poisson-distribution': return const PoissonDistributionScreen();
    case 'dimensionality-reduction': return const DimensionalityReductionScreen();
    case 'neural-style': return const NeuralStyleScreen();
    case 'maze-rl': return const MazeRlScreen();
    case 'minimax': return const MinimaxScreen();
    case 'fermi-dirac': return const FermiDiracScreen();
    case 'wigner-function': return const WignerFunctionScreen();
    case 'quantum-oscillator-2d': return const QuantumOscillator2dScreen();
    case 'spin-chain': return const SpinChainScreen();
    case 'ideal-solution': return const IdealSolutionScreen();
    case 'chromatography': return const ChromatographyScreen();
    case 'calorimetry': return const CalorimetryScreen();
    case 'activation-energy': return const ActivationEnergyScreen();
    case 'relativistic-aberration': return const RelativisticAberrationScreen();
    case 'relativistic-beaming': return const RelativisticBeamingScreen();
    case 'cosmological-redshift': return const CosmologicalRedshiftScreen();
    case 'dark-energy': return const DarkEnergyScreen();
    case 'magnetic-reversal': return const MagneticReversalScreen();
    case 'seismograph': return const SeismographScreen();
    case 'continental-drift': return const ContinentalDriftScreen();
    case 'greenhouse-gases': return const GreenhouseGasesScreen();
    case 'rule-110': return const Rule110Screen();
    case 'schelling-segregation': return const SchellingSegregationScreen();
    case 'duffing-oscillator': return const DuffingOscillatorScreen();
    case 'belousov-zhabotinsky': return const BelousovZhabotinskyScreen();
    case 'cellular-respiration': return const CellularRespirationScreen();
    case 'logistic-growth': return const LogisticGrowthScreen();
    case 'competitive-exclusion': return const CompetitiveExclusionScreen();
    case 'crispr': return const CrisprScreen();
    case 'dark-matter': return const DarkMatterScreen();
    case 'pulsar': return const PulsarScreen();
    case 'asteroid-belt': return const AsteroidBeltScreen();
    case 'cosmic-distance-ladder': return const CosmicDistanceLadderScreen();
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
