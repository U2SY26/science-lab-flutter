import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Visual Science Lab'**
  String get appTitle;

  /// No description provided for @appSubtitle1.
  ///
  /// In en, this message translates to:
  /// **'Feel the'**
  String get appSubtitle1;

  /// No description provided for @appSubtitle2.
  ///
  /// In en, this message translates to:
  /// **'Laws of Universe'**
  String get appSubtitle2;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @categoryPhysics.
  ///
  /// In en, this message translates to:
  /// **'Physics'**
  String get categoryPhysics;

  /// No description provided for @categoryMath.
  ///
  /// In en, this message translates to:
  /// **'Math'**
  String get categoryMath;

  /// No description provided for @categoryChaos.
  ///
  /// In en, this message translates to:
  /// **'Chaos'**
  String get categoryChaos;

  /// No description provided for @categoryAI.
  ///
  /// In en, this message translates to:
  /// **'AI/ML'**
  String get categoryAI;

  /// No description provided for @categoryChemistry.
  ///
  /// In en, this message translates to:
  /// **'Chemistry'**
  String get categoryChemistry;

  /// No description provided for @simulations.
  ///
  /// In en, this message translates to:
  /// **'Simulations'**
  String get simulations;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @results.
  ///
  /// In en, this message translates to:
  /// **'{count} results'**
  String results(int count);

  /// No description provided for @searchSimulations.
  ///
  /// In en, this message translates to:
  /// **'Search simulations...'**
  String get searchSimulations;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @removeAds.
  ///
  /// In en, this message translates to:
  /// **'Remove Ads'**
  String get removeAds;

  /// No description provided for @monthlyPrice.
  ///
  /// In en, this message translates to:
  /// **'Monthly \${price}'**
  String monthlyPrice(String price);

  /// No description provided for @resetProgress.
  ///
  /// In en, this message translates to:
  /// **'Reset Learning Progress'**
  String get resetProgress;

  /// No description provided for @appInfo.
  ///
  /// In en, this message translates to:
  /// **'App Info'**
  String get appInfo;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @pressAgainToExit.
  ///
  /// In en, this message translates to:
  /// **'Press again to exit'**
  String get pressAgainToExit;

  /// No description provided for @introTitle.
  ///
  /// In en, this message translates to:
  /// **'Visual Science Lab'**
  String get introTitle;

  /// No description provided for @introDescription.
  ///
  /// In en, this message translates to:
  /// **'Learn science and math principles through interactive simulations!'**
  String get introDescription;

  /// No description provided for @continuousUpdates.
  ///
  /// In en, this message translates to:
  /// **'Continuous Updates'**
  String get continuousUpdates;

  /// No description provided for @continuousUpdatesDesc.
  ///
  /// In en, this message translates to:
  /// **'New simulations and features are continuously added.'**
  String get continuousUpdatesDesc;

  /// No description provided for @webVersionAvailable.
  ///
  /// In en, this message translates to:
  /// **'Web version available!'**
  String get webVersionAvailable;

  /// No description provided for @run.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get run;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @simPendulum.
  ///
  /// In en, this message translates to:
  /// **'Simple Pendulum'**
  String get simPendulum;

  /// No description provided for @simPendulumLevel.
  ///
  /// In en, this message translates to:
  /// **'Physics Engine'**
  String get simPendulumLevel;

  /// No description provided for @simPendulumFormat.
  ///
  /// In en, this message translates to:
  /// **'Simulation'**
  String get simPendulumFormat;

  /// No description provided for @simPendulumSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore how pendulum period depends on string length and gravitational acceleration.'**
  String get simPendulumSummary;

  /// No description provided for @simWave.
  ///
  /// In en, this message translates to:
  /// **'Double-Slit Interference'**
  String get simWave;

  /// No description provided for @simWaveLevel.
  ///
  /// In en, this message translates to:
  /// **'Wave Physics'**
  String get simWaveLevel;

  /// No description provided for @simWaveFormat.
  ///
  /// In en, this message translates to:
  /// **'Simulation'**
  String get simWaveFormat;

  /// No description provided for @simWaveSummary.
  ///
  /// In en, this message translates to:
  /// **'Observe constructive and destructive interference patterns from two coherent wave sources.'**
  String get simWaveSummary;

  /// No description provided for @simGravity.
  ///
  /// In en, this message translates to:
  /// **'Spacetime Curvature'**
  String get simGravity;

  /// No description provided for @simGravityLevel.
  ///
  /// In en, this message translates to:
  /// **'General Relativity'**
  String get simGravityLevel;

  /// No description provided for @simGravityFormat.
  ///
  /// In en, this message translates to:
  /// **'3D Simulation'**
  String get simGravityFormat;

  /// No description provided for @simGravitySummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize how mass warps the spacetime fabric on an interactive 3D grid.'**
  String get simGravitySummary;

  /// No description provided for @simFormula.
  ///
  /// In en, this message translates to:
  /// **'Math Function Grapher'**
  String get simFormula;

  /// No description provided for @simFormulaLevel.
  ///
  /// In en, this message translates to:
  /// **'High School'**
  String get simFormulaLevel;

  /// No description provided for @simFormulaFormat.
  ///
  /// In en, this message translates to:
  /// **'2D Graph'**
  String get simFormulaFormat;

  /// No description provided for @simFormulaSummary.
  ///
  /// In en, this message translates to:
  /// **'Enter any mathematical function and generate its real-time graph instantly.'**
  String get simFormulaSummary;

  /// No description provided for @simLorenz.
  ///
  /// In en, this message translates to:
  /// **'Lorenz Attractor'**
  String get simLorenz;

  /// No description provided for @simLorenzLevel.
  ///
  /// In en, this message translates to:
  /// **'Chaos Theory'**
  String get simLorenzLevel;

  /// No description provided for @simLorenzFormat.
  ///
  /// In en, this message translates to:
  /// **'3D Graph'**
  String get simLorenzFormat;

  /// No description provided for @simLorenzSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize the butterfly effect through the classic Lorenz chaotic attractor.'**
  String get simLorenzSummary;

  /// No description provided for @simDoublePendulum.
  ///
  /// In en, this message translates to:
  /// **'Double Pendulum'**
  String get simDoublePendulum;

  /// No description provided for @simDoublePendulumLevel.
  ///
  /// In en, this message translates to:
  /// **'Chaotic Dynamics'**
  String get simDoublePendulumLevel;

  /// No description provided for @simDoublePendulumFormat.
  ///
  /// In en, this message translates to:
  /// **'Simulation'**
  String get simDoublePendulumFormat;

  /// No description provided for @simDoublePendulumSummary.
  ///
  /// In en, this message translates to:
  /// **'Two coupled pendulums demonstrating extreme sensitivity to initial conditions.'**
  String get simDoublePendulumSummary;

  /// No description provided for @simGameOfLife.
  ///
  /// In en, this message translates to:
  /// **'Conway\'s Game of Life'**
  String get simGameOfLife;

  /// No description provided for @simGameOfLifeLevel.
  ///
  /// In en, this message translates to:
  /// **'Cellular Automata'**
  String get simGameOfLifeLevel;

  /// No description provided for @simGameOfLifeFormat.
  ///
  /// In en, this message translates to:
  /// **'Simulation'**
  String get simGameOfLifeFormat;

  /// No description provided for @simGameOfLifeSummary.
  ///
  /// In en, this message translates to:
  /// **'Cells evolve following simple rules of survival, birth, and death — emergent complexity from simplicity.'**
  String get simGameOfLifeSummary;

  /// No description provided for @simSet.
  ///
  /// In en, this message translates to:
  /// **'Set Operations'**
  String get simSet;

  /// No description provided for @simSetLevel.
  ///
  /// In en, this message translates to:
  /// **'Discrete Math'**
  String get simSetLevel;

  /// No description provided for @simSetFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simSetFormat;

  /// No description provided for @simSetSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize union, intersection, and difference of sets using interactive Venn diagrams.'**
  String get simSetSummary;

  /// No description provided for @simSorting.
  ///
  /// In en, this message translates to:
  /// **'Sorting Algorithms'**
  String get simSorting;

  /// No description provided for @simSortingLevel.
  ///
  /// In en, this message translates to:
  /// **'Algorithms'**
  String get simSortingLevel;

  /// No description provided for @simSortingFormat.
  ///
  /// In en, this message translates to:
  /// **'Animation'**
  String get simSortingFormat;

  /// No description provided for @simSortingSummary.
  ///
  /// In en, this message translates to:
  /// **'Compare bubble, quick, and merge sort step by step with animated bar charts.'**
  String get simSortingSummary;

  /// No description provided for @simNeuralNet.
  ///
  /// In en, this message translates to:
  /// **'Neural Network Playground'**
  String get simNeuralNet;

  /// No description provided for @simNeuralNetLevel.
  ///
  /// In en, this message translates to:
  /// **'Deep Learning'**
  String get simNeuralNetLevel;

  /// No description provided for @simNeuralNetFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simNeuralNetFormat;

  /// No description provided for @simNeuralNetSummary.
  ///
  /// In en, this message translates to:
  /// **'Interactively train a neural network and watch forward propagation, backpropagation, and weight updates.'**
  String get simNeuralNetSummary;

  /// No description provided for @simGradient.
  ///
  /// In en, this message translates to:
  /// **'Gradient Descent'**
  String get simGradient;

  /// No description provided for @simGradientLevel.
  ///
  /// In en, this message translates to:
  /// **'Optimization'**
  String get simGradientLevel;

  /// No description provided for @simGradientFormat.
  ///
  /// In en, this message translates to:
  /// **'Visualization'**
  String get simGradientFormat;

  /// No description provided for @simGradientSummary.
  ///
  /// In en, this message translates to:
  /// **'Watch gradient descent navigate a loss surface to find the minimum step by step.'**
  String get simGradientSummary;

  /// No description provided for @simMandelbrot.
  ///
  /// In en, this message translates to:
  /// **'Mandelbrot Set'**
  String get simMandelbrot;

  /// No description provided for @simMandelbrotLevel.
  ///
  /// In en, this message translates to:
  /// **'Fractal'**
  String get simMandelbrotLevel;

  /// No description provided for @simMandelbrotFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simMandelbrotFormat;

  /// No description provided for @simMandelbrotSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore the infinitely complex boundary of the Mandelbrot set: zₙ₊₁ = zₙ² + c'**
  String get simMandelbrotSummary;

  /// No description provided for @simFourier.
  ///
  /// In en, this message translates to:
  /// **'Fourier Transform'**
  String get simFourier;

  /// No description provided for @simFourierLevel.
  ///
  /// In en, this message translates to:
  /// **'Signal Processing'**
  String get simFourierLevel;

  /// No description provided for @simFourierFormat.
  ///
  /// In en, this message translates to:
  /// **'Visualization'**
  String get simFourierFormat;

  /// No description provided for @simFourierSummary.
  ///
  /// In en, this message translates to:
  /// **'Decompose complex waveforms into sums of circular motions (epicycles).'**
  String get simFourierSummary;

  /// No description provided for @simQuadratic.
  ///
  /// In en, this message translates to:
  /// **'Quadratic Function Explorer'**
  String get simQuadratic;

  /// No description provided for @simQuadraticLevel.
  ///
  /// In en, this message translates to:
  /// **'High School'**
  String get simQuadraticLevel;

  /// No description provided for @simQuadraticFormat.
  ///
  /// In en, this message translates to:
  /// **'2D Graph'**
  String get simQuadraticFormat;

  /// No description provided for @simQuadraticSummary.
  ///
  /// In en, this message translates to:
  /// **'Adjust coefficients a, b, c and observe how the vertex and roots change.'**
  String get simQuadraticSummary;

  /// No description provided for @simVector.
  ///
  /// In en, this message translates to:
  /// **'Vector Dot Product Explorer'**
  String get simVector;

  /// No description provided for @simVectorLevel.
  ///
  /// In en, this message translates to:
  /// **'Linear Algebra'**
  String get simVectorLevel;

  /// No description provided for @simVectorFormat.
  ///
  /// In en, this message translates to:
  /// **'2D Graph'**
  String get simVectorFormat;

  /// No description provided for @simVectorSummary.
  ///
  /// In en, this message translates to:
  /// **'Interactively visualize dot product, angle, and projection of 2D vectors.'**
  String get simVectorSummary;

  /// No description provided for @simProjectile.
  ///
  /// In en, this message translates to:
  /// **'Projectile Motion'**
  String get simProjectile;

  /// No description provided for @simProjectileLevel.
  ///
  /// In en, this message translates to:
  /// **'Mechanics'**
  String get simProjectileLevel;

  /// No description provided for @simProjectileFormat.
  ///
  /// In en, this message translates to:
  /// **'Simulation'**
  String get simProjectileFormat;

  /// No description provided for @simProjectileSummary.
  ///
  /// In en, this message translates to:
  /// **'Simulate parabolic trajectories by adjusting launch angle and initial velocity.'**
  String get simProjectileSummary;

  /// No description provided for @simSpring.
  ///
  /// In en, this message translates to:
  /// **'Spring Chain'**
  String get simSpring;

  /// No description provided for @simSpringLevel.
  ///
  /// In en, this message translates to:
  /// **'Mechanics'**
  String get simSpringLevel;

  /// No description provided for @simSpringFormat.
  ///
  /// In en, this message translates to:
  /// **'Simulation'**
  String get simSpringFormat;

  /// No description provided for @simSpringSummary.
  ///
  /// In en, this message translates to:
  /// **'Observe damped harmonic oscillation in a chain of connected springs.'**
  String get simSpringSummary;

  /// No description provided for @simActivation.
  ///
  /// In en, this message translates to:
  /// **'Activation Functions'**
  String get simActivation;

  /// No description provided for @simActivationLevel.
  ///
  /// In en, this message translates to:
  /// **'Deep Learning'**
  String get simActivationLevel;

  /// No description provided for @simActivationFormat.
  ///
  /// In en, this message translates to:
  /// **'Visualization'**
  String get simActivationFormat;

  /// No description provided for @simActivationSummary.
  ///
  /// In en, this message translates to:
  /// **'Compare ReLU, Sigmoid, Tanh, GELU and other neural network activation functions.'**
  String get simActivationSummary;

  /// No description provided for @simLogistic.
  ///
  /// In en, this message translates to:
  /// **'Logistic Map'**
  String get simLogistic;

  /// No description provided for @simLogisticLevel.
  ///
  /// In en, this message translates to:
  /// **'Chaos Theory'**
  String get simLogisticLevel;

  /// No description provided for @simLogisticFormat.
  ///
  /// In en, this message translates to:
  /// **'Visualization'**
  String get simLogisticFormat;

  /// No description provided for @simLogisticSummary.
  ///
  /// In en, this message translates to:
  /// **'Observe the period-doubling route to chaos via the bifurcation diagram and Feigenbaum constant.'**
  String get simLogisticSummary;

  /// No description provided for @simCollision.
  ///
  /// In en, this message translates to:
  /// **'Particle Collision'**
  String get simCollision;

  /// No description provided for @simCollisionLevel.
  ///
  /// In en, this message translates to:
  /// **'Mechanics'**
  String get simCollisionLevel;

  /// No description provided for @simCollisionFormat.
  ///
  /// In en, this message translates to:
  /// **'Simulation'**
  String get simCollisionFormat;

  /// No description provided for @simCollisionSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize elastic and inelastic collisions with conservation of momentum and energy.'**
  String get simCollisionSummary;

  /// No description provided for @simKMeans.
  ///
  /// In en, this message translates to:
  /// **'K-Means Clustering'**
  String get simKMeans;

  /// No description provided for @simKMeansLevel.
  ///
  /// In en, this message translates to:
  /// **'Machine Learning'**
  String get simKMeansLevel;

  /// No description provided for @simKMeansFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simKMeansFormat;

  /// No description provided for @simKMeansSummary.
  ///
  /// In en, this message translates to:
  /// **'Watch unsupervised learning partition data into K clusters through iterative centroid updates.'**
  String get simKMeansSummary;

  /// No description provided for @simPrime.
  ///
  /// In en, this message translates to:
  /// **'Sieve of Eratosthenes'**
  String get simPrime;

  /// No description provided for @simPrimeLevel.
  ///
  /// In en, this message translates to:
  /// **'Number Theory'**
  String get simPrimeLevel;

  /// No description provided for @simPrimeFormat.
  ///
  /// In en, this message translates to:
  /// **'Algorithm'**
  String get simPrimeFormat;

  /// No description provided for @simPrimeSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize the ancient prime-finding algorithm eliminating multiples step by step.'**
  String get simPrimeSummary;

  /// No description provided for @simThreeBody.
  ///
  /// In en, this message translates to:
  /// **'Three-Body Problem'**
  String get simThreeBody;

  /// No description provided for @simThreeBodyLevel.
  ///
  /// In en, this message translates to:
  /// **'Chaotic Dynamics'**
  String get simThreeBodyLevel;

  /// No description provided for @simThreeBodyFormat.
  ///
  /// In en, this message translates to:
  /// **'Simulation'**
  String get simThreeBodyFormat;

  /// No description provided for @simThreeBodySummary.
  ///
  /// In en, this message translates to:
  /// **'Gravitational interaction of three bodies — a chaotic system with no closed-form solution.'**
  String get simThreeBodySummary;

  /// No description provided for @simDecisionTree.
  ///
  /// In en, this message translates to:
  /// **'Decision Tree'**
  String get simDecisionTree;

  /// No description provided for @simDecisionTreeLevel.
  ///
  /// In en, this message translates to:
  /// **'Machine Learning'**
  String get simDecisionTreeLevel;

  /// No description provided for @simDecisionTreeFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simDecisionTreeFormat;

  /// No description provided for @simDecisionTreeSummary.
  ///
  /// In en, this message translates to:
  /// **'Classification algorithm that recursively splits data by minimizing Gini impurity.'**
  String get simDecisionTreeSummary;

  /// No description provided for @simSVM.
  ///
  /// In en, this message translates to:
  /// **'SVM Classifier'**
  String get simSVM;

  /// No description provided for @simSVMLevel.
  ///
  /// In en, this message translates to:
  /// **'Machine Learning'**
  String get simSVMLevel;

  /// No description provided for @simSVMFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simSVMFormat;

  /// No description provided for @simSVMSummary.
  ///
  /// In en, this message translates to:
  /// **'Support Vector Machine finding the maximum-margin decision boundary between classes.'**
  String get simSVMSummary;

  /// No description provided for @simPCA.
  ///
  /// In en, this message translates to:
  /// **'Principal Component Analysis'**
  String get simPCA;

  /// No description provided for @simPCALevel.
  ///
  /// In en, this message translates to:
  /// **'Machine Learning'**
  String get simPCALevel;

  /// No description provided for @simPCAFormat.
  ///
  /// In en, this message translates to:
  /// **'Visualization'**
  String get simPCAFormat;

  /// No description provided for @simPCASummary.
  ///
  /// In en, this message translates to:
  /// **'Dimensionality reduction by projecting data onto directions of maximum variance.'**
  String get simPCASummary;

  /// No description provided for @simElectromagnetic.
  ///
  /// In en, this message translates to:
  /// **'Electric Field Visualization'**
  String get simElectromagnetic;

  /// No description provided for @simElectromagneticLevel.
  ///
  /// In en, this message translates to:
  /// **'Electromagnetism'**
  String get simElectromagneticLevel;

  /// No description provided for @simElectromagneticFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simElectromagneticFormat;

  /// No description provided for @simElectromagneticSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize electric field vectors and field lines around point charges.'**
  String get simElectromagneticSummary;

  /// No description provided for @simGraphTheory.
  ///
  /// In en, this message translates to:
  /// **'Graph Traversal'**
  String get simGraphTheory;

  /// No description provided for @simGraphTheoryLevel.
  ///
  /// In en, this message translates to:
  /// **'Graph Theory'**
  String get simGraphTheoryLevel;

  /// No description provided for @simGraphTheoryFormat.
  ///
  /// In en, this message translates to:
  /// **'Algorithm'**
  String get simGraphTheoryFormat;

  /// No description provided for @simGraphTheorySummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize breadth-first search (BFS) and depth-first search (DFS) on graphs.'**
  String get simGraphTheorySummary;

  /// No description provided for @simBohrModel.
  ///
  /// In en, this message translates to:
  /// **'Bohr Atomic Model'**
  String get simBohrModel;

  /// No description provided for @simBohrModelLevel.
  ///
  /// In en, this message translates to:
  /// **'Atomic Physics'**
  String get simBohrModelLevel;

  /// No description provided for @simBohrModelFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simBohrModelFormat;

  /// No description provided for @simBohrModelSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize quantized electron orbits and energy level transitions in atoms.'**
  String get simBohrModelSummary;

  /// No description provided for @simChemicalBonding.
  ///
  /// In en, this message translates to:
  /// **'Chemical Bonding'**
  String get simChemicalBonding;

  /// No description provided for @simChemicalBondingLevel.
  ///
  /// In en, this message translates to:
  /// **'Chemistry'**
  String get simChemicalBondingLevel;

  /// No description provided for @simChemicalBondingFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simChemicalBondingFormat;

  /// No description provided for @simChemicalBondingSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore ionic, covalent, and metallic bond types and their properties.'**
  String get simChemicalBondingSummary;

  /// No description provided for @simElectronConfig.
  ///
  /// In en, this message translates to:
  /// **'Electron Configuration'**
  String get simElectronConfig;

  /// No description provided for @simElectronConfigLevel.
  ///
  /// In en, this message translates to:
  /// **'Chemistry'**
  String get simElectronConfigLevel;

  /// No description provided for @simElectronConfigFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simElectronConfigFormat;

  /// No description provided for @simElectronConfigSummary.
  ///
  /// In en, this message translates to:
  /// **'Learn the Aufbau principle and electron orbital filling order for any element.'**
  String get simElectronConfigSummary;

  /// No description provided for @simEquationBalance.
  ///
  /// In en, this message translates to:
  /// **'Chemical Equation Balancing'**
  String get simEquationBalance;

  /// No description provided for @simEquationBalanceLevel.
  ///
  /// In en, this message translates to:
  /// **'Chemistry'**
  String get simEquationBalanceLevel;

  /// No description provided for @simEquationBalanceFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simEquationBalanceFormat;

  /// No description provided for @simEquationBalanceSummary.
  ///
  /// In en, this message translates to:
  /// **'Practice balancing chemical equations step by step using the law of conservation of mass.'**
  String get simEquationBalanceSummary;

  /// No description provided for @simHydrogenBonding.
  ///
  /// In en, this message translates to:
  /// **'Hydrogen Bonding'**
  String get simHydrogenBonding;

  /// No description provided for @simHydrogenBondingLevel.
  ///
  /// In en, this message translates to:
  /// **'Chemistry'**
  String get simHydrogenBondingLevel;

  /// No description provided for @simHydrogenBondingFormat.
  ///
  /// In en, this message translates to:
  /// **'Visualization'**
  String get simHydrogenBondingFormat;

  /// No description provided for @simHydrogenBondingSummary.
  ///
  /// In en, this message translates to:
  /// **'Understand hydrogen bonds and their role in water\'s anomalous properties.'**
  String get simHydrogenBondingSummary;

  /// No description provided for @simLewisStructure.
  ///
  /// In en, this message translates to:
  /// **'Lewis Dot Structures'**
  String get simLewisStructure;

  /// No description provided for @simLewisStructureLevel.
  ///
  /// In en, this message translates to:
  /// **'Chemistry'**
  String get simLewisStructureLevel;

  /// No description provided for @simLewisStructureFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simLewisStructureFormat;

  /// No description provided for @simLewisStructureSummary.
  ///
  /// In en, this message translates to:
  /// **'Draw and interpret Lewis dot structures showing valence electrons in molecules.'**
  String get simLewisStructureSummary;

  /// No description provided for @simMolecularGeometry.
  ///
  /// In en, this message translates to:
  /// **'Molecular Geometry (VSEPR)'**
  String get simMolecularGeometry;

  /// No description provided for @simMolecularGeometryLevel.
  ///
  /// In en, this message translates to:
  /// **'Chemistry'**
  String get simMolecularGeometryLevel;

  /// No description provided for @simMolecularGeometryFormat.
  ///
  /// In en, this message translates to:
  /// **'3D Visualization'**
  String get simMolecularGeometryFormat;

  /// No description provided for @simMolecularGeometrySummary.
  ///
  /// In en, this message translates to:
  /// **'Predict 3D molecular shapes using VSEPR theory for various electron geometries.'**
  String get simMolecularGeometrySummary;

  /// No description provided for @simOxidationReduction.
  ///
  /// In en, this message translates to:
  /// **'Oxidation-Reduction Reactions'**
  String get simOxidationReduction;

  /// No description provided for @simOxidationReductionLevel.
  ///
  /// In en, this message translates to:
  /// **'Chemistry'**
  String get simOxidationReductionLevel;

  /// No description provided for @simOxidationReductionFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simOxidationReductionFormat;

  /// No description provided for @simOxidationReductionSummary.
  ///
  /// In en, this message translates to:
  /// **'Track electron transfer between oxidizing and reducing agents in redox reactions.'**
  String get simOxidationReductionSummary;

  /// No description provided for @simAStar.
  ///
  /// In en, this message translates to:
  /// **'A* Pathfinding'**
  String get simAStar;

  /// No description provided for @simAStarLevel.
  ///
  /// In en, this message translates to:
  /// **'Algorithms'**
  String get simAStarLevel;

  /// No description provided for @simAStarFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simAStarFormat;

  /// No description provided for @simAStarSummary.
  ///
  /// In en, this message translates to:
  /// **'Find optimal paths using the A* search algorithm with admissible heuristics.'**
  String get simAStarSummary;

  /// No description provided for @simSimpleHarmonic.
  ///
  /// In en, this message translates to:
  /// **'Simple Harmonic Motion'**
  String get simSimpleHarmonic;

  /// No description provided for @simSimpleHarmonicLevel.
  ///
  /// In en, this message translates to:
  /// **'Mechanics'**
  String get simSimpleHarmonicLevel;

  /// No description provided for @simSimpleHarmonicFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simSimpleHarmonicFormat;

  /// No description provided for @simSimpleHarmonicSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore oscillatory motion of a mass-spring system: position, velocity, and energy over time. x(t) = A·cos(ωt + φ)'**
  String get simSimpleHarmonicSummary;

  /// No description provided for @simCoupledOscillators.
  ///
  /// In en, this message translates to:
  /// **'Coupled Oscillators'**
  String get simCoupledOscillators;

  /// No description provided for @simCoupledOscillatorsLevel.
  ///
  /// In en, this message translates to:
  /// **'University Physics'**
  String get simCoupledOscillatorsLevel;

  /// No description provided for @simCoupledOscillatorsFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simCoupledOscillatorsFormat;

  /// No description provided for @simCoupledOscillatorsSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize normal modes and energy exchange between two masses connected by springs.'**
  String get simCoupledOscillatorsSummary;

  /// No description provided for @simGyroscope.
  ///
  /// In en, this message translates to:
  /// **'Gyroscopic Precession'**
  String get simGyroscope;

  /// No description provided for @simGyroscopeLevel.
  ///
  /// In en, this message translates to:
  /// **'University Physics'**
  String get simGyroscopeLevel;

  /// No description provided for @simGyroscopeFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simGyroscopeFormat;

  /// No description provided for @simGyroscopeSummary.
  ///
  /// In en, this message translates to:
  /// **'Observe how a spinning gyroscope precesses under gravitational torque. Ω = τ/L'**
  String get simGyroscopeSummary;

  /// No description provided for @simBallisticPendulum.
  ///
  /// In en, this message translates to:
  /// **'Ballistic Pendulum'**
  String get simBallisticPendulum;

  /// No description provided for @simBallisticPendulumLevel.
  ///
  /// In en, this message translates to:
  /// **'Mechanics'**
  String get simBallisticPendulumLevel;

  /// No description provided for @simBallisticPendulumFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simBallisticPendulumFormat;

  /// No description provided for @simBallisticPendulumSummary.
  ///
  /// In en, this message translates to:
  /// **'Measure projectile speed by combining conservation of momentum and energy.'**
  String get simBallisticPendulumSummary;

  /// No description provided for @simGameTheory.
  ///
  /// In en, this message translates to:
  /// **'Nash Equilibrium'**
  String get simGameTheory;

  /// No description provided for @simGameTheoryLevel.
  ///
  /// In en, this message translates to:
  /// **'Game Theory'**
  String get simGameTheoryLevel;

  /// No description provided for @simGameTheoryFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simGameTheoryFormat;

  /// No description provided for @simGameTheorySummary.
  ///
  /// In en, this message translates to:
  /// **'Find Nash equilibria in two-player strategic games using payoff matrices.'**
  String get simGameTheorySummary;

  /// No description provided for @simPrisonersDilemma.
  ///
  /// In en, this message translates to:
  /// **'Prisoner\'s Dilemma'**
  String get simPrisonersDilemma;

  /// No description provided for @simPrisonersDilemmaLevel.
  ///
  /// In en, this message translates to:
  /// **'Game Theory'**
  String get simPrisonersDilemmaLevel;

  /// No description provided for @simPrisonersDilemmaFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simPrisonersDilemmaFormat;

  /// No description provided for @simPrisonersDilemmaSummary.
  ///
  /// In en, this message translates to:
  /// **'Simulate iterated prisoner\'s dilemma tournaments with strategies like Tit-for-Tat.'**
  String get simPrisonersDilemmaSummary;

  /// No description provided for @simLinearProgramming.
  ///
  /// In en, this message translates to:
  /// **'Linear Programming'**
  String get simLinearProgramming;

  /// No description provided for @simLinearProgrammingLevel.
  ///
  /// In en, this message translates to:
  /// **'Operations Research'**
  String get simLinearProgrammingLevel;

  /// No description provided for @simLinearProgrammingFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simLinearProgrammingFormat;

  /// No description provided for @simLinearProgrammingSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize feasible regions and find optimal solutions graphically for LP problems.'**
  String get simLinearProgrammingSummary;

  /// No description provided for @simSimplexMethod.
  ///
  /// In en, this message translates to:
  /// **'Simplex Algorithm'**
  String get simSimplexMethod;

  /// No description provided for @simSimplexMethodLevel.
  ///
  /// In en, this message translates to:
  /// **'Operations Research'**
  String get simSimplexMethodLevel;

  /// No description provided for @simSimplexMethodFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simSimplexMethodFormat;

  /// No description provided for @simSimplexMethodSummary.
  ///
  /// In en, this message translates to:
  /// **'Step through the simplex method tableau to solve linear programming problems.'**
  String get simSimplexMethodSummary;

  /// No description provided for @simNaiveBayes.
  ///
  /// In en, this message translates to:
  /// **'Naive Bayes Classifier'**
  String get simNaiveBayes;

  /// No description provided for @simNaiveBayesLevel.
  ///
  /// In en, this message translates to:
  /// **'Machine Learning'**
  String get simNaiveBayesLevel;

  /// No description provided for @simNaiveBayesFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simNaiveBayesFormat;

  /// No description provided for @simNaiveBayesSummary.
  ///
  /// In en, this message translates to:
  /// **'Classify data using Bayes\' theorem with the conditional independence assumption. P(C|X) ∝ P(X|C)·P(C)'**
  String get simNaiveBayesSummary;

  /// No description provided for @simRandomForest.
  ///
  /// In en, this message translates to:
  /// **'Random Forest'**
  String get simRandomForest;

  /// No description provided for @simRandomForestLevel.
  ///
  /// In en, this message translates to:
  /// **'Machine Learning'**
  String get simRandomForestLevel;

  /// No description provided for @simRandomForestFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simRandomForestFormat;

  /// No description provided for @simRandomForestSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize how an ensemble of decision trees votes to form a robust classifier.'**
  String get simRandomForestSummary;

  /// No description provided for @simGradientBoosting.
  ///
  /// In en, this message translates to:
  /// **'Gradient Boosting'**
  String get simGradientBoosting;

  /// No description provided for @simGradientBoostingLevel.
  ///
  /// In en, this message translates to:
  /// **'Machine Learning'**
  String get simGradientBoostingLevel;

  /// No description provided for @simGradientBoostingFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simGradientBoostingFormat;

  /// No description provided for @simGradientBoostingSummary.
  ///
  /// In en, this message translates to:
  /// **'Watch iterative boosting build a strong learner by correcting residuals of weak models.'**
  String get simGradientBoostingSummary;

  /// No description provided for @simLogisticRegression.
  ///
  /// In en, this message translates to:
  /// **'Logistic Regression'**
  String get simLogisticRegression;

  /// No description provided for @simLogisticRegressionLevel.
  ///
  /// In en, this message translates to:
  /// **'Machine Learning'**
  String get simLogisticRegressionLevel;

  /// No description provided for @simLogisticRegressionFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simLogisticRegressionFormat;

  /// No description provided for @simLogisticRegressionSummary.
  ///
  /// In en, this message translates to:
  /// **'Fit a sigmoid decision boundary for binary classification. σ(z) = 1/(1+e⁻ᶻ)'**
  String get simLogisticRegressionSummary;

  /// No description provided for @simQuantumTeleportation.
  ///
  /// In en, this message translates to:
  /// **'Quantum Teleportation'**
  String get simQuantumTeleportation;

  /// No description provided for @simQuantumTeleportationLevel.
  ///
  /// In en, this message translates to:
  /// **'Quantum Computing'**
  String get simQuantumTeleportationLevel;

  /// No description provided for @simQuantumTeleportationFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simQuantumTeleportationFormat;

  /// No description provided for @simQuantumTeleportationSummary.
  ///
  /// In en, this message translates to:
  /// **'Simulate the quantum teleportation protocol transferring quantum states via entangled qubits.'**
  String get simQuantumTeleportationSummary;

  /// No description provided for @simQuantumErrorCorrection.
  ///
  /// In en, this message translates to:
  /// **'Quantum Error Correction'**
  String get simQuantumErrorCorrection;

  /// No description provided for @simQuantumErrorCorrectionLevel.
  ///
  /// In en, this message translates to:
  /// **'Quantum Computing'**
  String get simQuantumErrorCorrectionLevel;

  /// No description provided for @simQuantumErrorCorrectionFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simQuantumErrorCorrectionFormat;

  /// No description provided for @simQuantumErrorCorrectionSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore stabilizer codes that protect quantum information from decoherence and errors.'**
  String get simQuantumErrorCorrectionSummary;

  /// No description provided for @simGroverAlgorithm.
  ///
  /// In en, this message translates to:
  /// **'Grover\'s Quantum Search'**
  String get simGroverAlgorithm;

  /// No description provided for @simGroverAlgorithmLevel.
  ///
  /// In en, this message translates to:
  /// **'Quantum Computing'**
  String get simGroverAlgorithmLevel;

  /// No description provided for @simGroverAlgorithmFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simGroverAlgorithmFormat;

  /// No description provided for @simGroverAlgorithmSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize amplitude amplification in Grover\'s O(√N) quantum search algorithm.'**
  String get simGroverAlgorithmSummary;

  /// No description provided for @simShorAlgorithm.
  ///
  /// In en, this message translates to:
  /// **'Shor\'s Factoring Algorithm'**
  String get simShorAlgorithm;

  /// No description provided for @simShorAlgorithmLevel.
  ///
  /// In en, this message translates to:
  /// **'Quantum Computing'**
  String get simShorAlgorithmLevel;

  /// No description provided for @simShorAlgorithmFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simShorAlgorithmFormat;

  /// No description provided for @simShorAlgorithmSummary.
  ///
  /// In en, this message translates to:
  /// **'Understand quantum period-finding that enables exponential speedup for integer factorization.'**
  String get simShorAlgorithmSummary;

  /// No description provided for @simGasLaws.
  ///
  /// In en, this message translates to:
  /// **'Combined Gas Laws'**
  String get simGasLaws;

  /// No description provided for @simGasLawsLevel.
  ///
  /// In en, this message translates to:
  /// **'Chemistry'**
  String get simGasLawsLevel;

  /// No description provided for @simGasLawsFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simGasLawsFormat;

  /// No description provided for @simGasLawsSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore Boyle\'s, Charles\'s, and the ideal gas law with interactive pressure-volume-temperature controls. PV = nRT'**
  String get simGasLawsSummary;

  /// No description provided for @simDaltonLaw.
  ///
  /// In en, this message translates to:
  /// **'Dalton\'s Law of Partial Pressures'**
  String get simDaltonLaw;

  /// No description provided for @simDaltonLawLevel.
  ///
  /// In en, this message translates to:
  /// **'Chemistry'**
  String get simDaltonLawLevel;

  /// No description provided for @simDaltonLawFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simDaltonLawFormat;

  /// No description provided for @simDaltonLawSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize how partial pressures of gas mixtures add up to total pressure. P_total = P₁ + P₂ + ... + Pₙ'**
  String get simDaltonLawSummary;

  /// No description provided for @simColligativeProperties.
  ///
  /// In en, this message translates to:
  /// **'Colligative Properties'**
  String get simColligativeProperties;

  /// No description provided for @simColligativePropertiesLevel.
  ///
  /// In en, this message translates to:
  /// **'Physical Chemistry'**
  String get simColligativePropertiesLevel;

  /// No description provided for @simColligativePropertiesFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simColligativePropertiesFormat;

  /// No description provided for @simColligativePropertiesSummary.
  ///
  /// In en, this message translates to:
  /// **'Observe boiling point elevation and freezing point depression caused by dissolved solutes. ΔT = K·m·i'**
  String get simColligativePropertiesSummary;

  /// No description provided for @simSolubilityCurve.
  ///
  /// In en, this message translates to:
  /// **'Solubility Curves'**
  String get simSolubilityCurve;

  /// No description provided for @simSolubilityCurveLevel.
  ///
  /// In en, this message translates to:
  /// **'Chemistry'**
  String get simSolubilityCurveLevel;

  /// No description provided for @simSolubilityCurveFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simSolubilityCurveFormat;

  /// No description provided for @simSolubilityCurveSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore how the solubility of different compounds changes with temperature.'**
  String get simSolubilityCurveSummary;

  /// No description provided for @simProperTime.
  ///
  /// In en, this message translates to:
  /// **'Proper Time & Worldlines'**
  String get simProperTime;

  /// No description provided for @simProperTimeLevel.
  ///
  /// In en, this message translates to:
  /// **'Special Relativity'**
  String get simProperTimeLevel;

  /// No description provided for @simProperTimeFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simProperTimeFormat;

  /// No description provided for @simProperTimeSummary.
  ///
  /// In en, this message translates to:
  /// **'Draw worldlines on spacetime diagrams and compute proper time intervals. dτ² = dt² - dx²/c²'**
  String get simProperTimeSummary;

  /// No description provided for @simFourVectors.
  ///
  /// In en, this message translates to:
  /// **'Four-Vectors'**
  String get simFourVectors;

  /// No description provided for @simFourVectorsLevel.
  ///
  /// In en, this message translates to:
  /// **'Special Relativity'**
  String get simFourVectorsLevel;

  /// No description provided for @simFourVectorsFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simFourVectorsFormat;

  /// No description provided for @simFourVectorsSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize four-momentum and four-velocity in Minkowski spacetime geometry.'**
  String get simFourVectorsSummary;

  /// No description provided for @simVelocityAddition.
  ///
  /// In en, this message translates to:
  /// **'Relativistic Velocity Addition'**
  String get simVelocityAddition;

  /// No description provided for @simVelocityAdditionLevel.
  ///
  /// In en, this message translates to:
  /// **'Special Relativity'**
  String get simVelocityAdditionLevel;

  /// No description provided for @simVelocityAdditionFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simVelocityAdditionFormat;

  /// No description provided for @simVelocityAdditionSummary.
  ///
  /// In en, this message translates to:
  /// **'Compare classical Galilean addition with the relativistic formula. u\' = (u+v)/(1+uv/c²)'**
  String get simVelocityAdditionSummary;

  /// No description provided for @simBarnPoleParadox.
  ///
  /// In en, this message translates to:
  /// **'Barn-Pole Paradox'**
  String get simBarnPoleParadox;

  /// No description provided for @simBarnPoleParadoxLevel.
  ///
  /// In en, this message translates to:
  /// **'Special Relativity'**
  String get simBarnPoleParadoxLevel;

  /// No description provided for @simBarnPoleParadoxFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simBarnPoleParadoxFormat;

  /// No description provided for @simBarnPoleParadoxSummary.
  ///
  /// In en, this message translates to:
  /// **'Resolve the length contraction paradox using relativity of simultaneity.'**
  String get simBarnPoleParadoxSummary;

  /// No description provided for @simWeatherFronts.
  ///
  /// In en, this message translates to:
  /// **'Weather Fronts'**
  String get simWeatherFronts;

  /// No description provided for @simWeatherFrontsLevel.
  ///
  /// In en, this message translates to:
  /// **'Meteorology'**
  String get simWeatherFrontsLevel;

  /// No description provided for @simWeatherFrontsFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simWeatherFrontsFormat;

  /// No description provided for @simWeatherFrontsSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize cold, warm, stationary, and occluded fronts and their associated weather patterns.'**
  String get simWeatherFrontsSummary;

  /// No description provided for @simHurricaneFormation.
  ///
  /// In en, this message translates to:
  /// **'Hurricane Formation'**
  String get simHurricaneFormation;

  /// No description provided for @simHurricaneFormationLevel.
  ///
  /// In en, this message translates to:
  /// **'Meteorology'**
  String get simHurricaneFormationLevel;

  /// No description provided for @simHurricaneFormationFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simHurricaneFormationFormat;

  /// No description provided for @simHurricaneFormationSummary.
  ///
  /// In en, this message translates to:
  /// **'Watch warm ocean water fuel tropical cyclone intensification through evaporation and condensation.'**
  String get simHurricaneFormationSummary;

  /// No description provided for @simJetStream.
  ///
  /// In en, this message translates to:
  /// **'Jet Stream'**
  String get simJetStream;

  /// No description provided for @simJetStreamLevel.
  ///
  /// In en, this message translates to:
  /// **'Atmospheric Science'**
  String get simJetStreamLevel;

  /// No description provided for @simJetStreamFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simJetStreamFormat;

  /// No description provided for @simJetStreamSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore how temperature gradients drive jet streams that steer global weather systems.'**
  String get simJetStreamSummary;

  /// No description provided for @simOrographicRainfall.
  ///
  /// In en, this message translates to:
  /// **'Orographic Rainfall'**
  String get simOrographicRainfall;

  /// No description provided for @simOrographicRainfallLevel.
  ///
  /// In en, this message translates to:
  /// **'Earth Science'**
  String get simOrographicRainfallLevel;

  /// No description provided for @simOrographicRainfallFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simOrographicRainfallFormat;

  /// No description provided for @simOrographicRainfallSummary.
  ///
  /// In en, this message translates to:
  /// **'See how mountains force moist air upward, causing precipitation on windward slopes and rain shadows.'**
  String get simOrographicRainfallSummary;

  /// No description provided for @simBarnsleyFern.
  ///
  /// In en, this message translates to:
  /// **'Barnsley Fern'**
  String get simBarnsleyFern;

  /// No description provided for @simBarnsleyFernLevel.
  ///
  /// In en, this message translates to:
  /// **'Fractal Geometry'**
  String get simBarnsleyFernLevel;

  /// No description provided for @simBarnsleyFernFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simBarnsleyFernFormat;

  /// No description provided for @simBarnsleyFernSummary.
  ///
  /// In en, this message translates to:
  /// **'Generate a realistic fern fractal using an iterated function system (IFS) of affine transforms.'**
  String get simBarnsleyFernSummary;

  /// No description provided for @simDragonCurve.
  ///
  /// In en, this message translates to:
  /// **'Dragon Curve'**
  String get simDragonCurve;

  /// No description provided for @simDragonCurveLevel.
  ///
  /// In en, this message translates to:
  /// **'Fractal Geometry'**
  String get simDragonCurveLevel;

  /// No description provided for @simDragonCurveFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simDragonCurveFormat;

  /// No description provided for @simDragonCurveSummary.
  ///
  /// In en, this message translates to:
  /// **'Watch a dragon curve fractal unfold through successive recursive paper-folding iterations.'**
  String get simDragonCurveSummary;

  /// No description provided for @simDiffusionLimited.
  ///
  /// In en, this message translates to:
  /// **'Diffusion-Limited Aggregation'**
  String get simDiffusionLimited;

  /// No description provided for @simDiffusionLimitedLevel.
  ///
  /// In en, this message translates to:
  /// **'Complex Systems'**
  String get simDiffusionLimitedLevel;

  /// No description provided for @simDiffusionLimitedFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simDiffusionLimitedFormat;

  /// No description provided for @simDiffusionLimitedSummary.
  ///
  /// In en, this message translates to:
  /// **'Simulate fractal cluster growth as randomly walking particles stick to an aggregate.'**
  String get simDiffusionLimitedSummary;

  /// No description provided for @simReactionDiffusion.
  ///
  /// In en, this message translates to:
  /// **'Reaction-Diffusion (Turing Patterns)'**
  String get simReactionDiffusion;

  /// No description provided for @simReactionDiffusionLevel.
  ///
  /// In en, this message translates to:
  /// **'Complex Systems'**
  String get simReactionDiffusionLevel;

  /// No description provided for @simReactionDiffusionFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simReactionDiffusionFormat;

  /// No description provided for @simReactionDiffusionSummary.
  ///
  /// In en, this message translates to:
  /// **'Generate Turing patterns (spots and stripes) through activator-inhibitor reaction-diffusion equations.'**
  String get simReactionDiffusionSummary;

  /// No description provided for @simMendelianGenetics.
  ///
  /// In en, this message translates to:
  /// **'Mendelian Genetics'**
  String get simMendelianGenetics;

  /// No description provided for @simMendelianGeneticsLevel.
  ///
  /// In en, this message translates to:
  /// **'Biology'**
  String get simMendelianGeneticsLevel;

  /// No description provided for @simMendelianGeneticsFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simMendelianGeneticsFormat;

  /// No description provided for @simMendelianGeneticsSummary.
  ///
  /// In en, this message translates to:
  /// **'Simulate Mendel\'s laws of segregation and independent assortment with dominant and recessive alleles.'**
  String get simMendelianGeneticsSummary;

  /// No description provided for @simPunnettSquare.
  ///
  /// In en, this message translates to:
  /// **'Punnett Square'**
  String get simPunnettSquare;

  /// No description provided for @simPunnettSquareLevel.
  ///
  /// In en, this message translates to:
  /// **'Biology'**
  String get simPunnettSquareLevel;

  /// No description provided for @simPunnettSquareFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simPunnettSquareFormat;

  /// No description provided for @simPunnettSquareSummary.
  ///
  /// In en, this message translates to:
  /// **'Predict offspring genotype and phenotype ratios using interactive Punnett squares.'**
  String get simPunnettSquareSummary;

  /// No description provided for @simGeneExpression.
  ///
  /// In en, this message translates to:
  /// **'Gene Expression'**
  String get simGeneExpression;

  /// No description provided for @simGeneExpressionLevel.
  ///
  /// In en, this message translates to:
  /// **'Molecular Biology'**
  String get simGeneExpressionLevel;

  /// No description provided for @simGeneExpressionFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simGeneExpressionFormat;

  /// No description provided for @simGeneExpressionSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize transcription (DNA → mRNA) and translation (mRNA → protein) step by step.'**
  String get simGeneExpressionSummary;

  /// No description provided for @simGeneticDrift.
  ///
  /// In en, this message translates to:
  /// **'Genetic Drift'**
  String get simGeneticDrift;

  /// No description provided for @simGeneticDriftLevel.
  ///
  /// In en, this message translates to:
  /// **'Population Genetics'**
  String get simGeneticDriftLevel;

  /// No description provided for @simGeneticDriftFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simGeneticDriftFormat;

  /// No description provided for @simGeneticDriftSummary.
  ///
  /// In en, this message translates to:
  /// **'Observe random allele frequency changes in small populations — a key driver of evolution.'**
  String get simGeneticDriftSummary;

  /// No description provided for @simHrDiagram.
  ///
  /// In en, this message translates to:
  /// **'Hertzsprung-Russell Diagram'**
  String get simHrDiagram;

  /// No description provided for @simHrDiagramLevel.
  ///
  /// In en, this message translates to:
  /// **'Astrophysics'**
  String get simHrDiagramLevel;

  /// No description provided for @simHrDiagramFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simHrDiagramFormat;

  /// No description provided for @simHrDiagramSummary.
  ///
  /// In en, this message translates to:
  /// **'Plot stars on the HR diagram and trace stellar evolution from main sequence to remnants.'**
  String get simHrDiagramSummary;

  /// No description provided for @simStellarNucleosynthesis.
  ///
  /// In en, this message translates to:
  /// **'Stellar Nucleosynthesis'**
  String get simStellarNucleosynthesis;

  /// No description provided for @simStellarNucleosynthesisLevel.
  ///
  /// In en, this message translates to:
  /// **'Astrophysics'**
  String get simStellarNucleosynthesisLevel;

  /// No description provided for @simStellarNucleosynthesisFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simStellarNucleosynthesisFormat;

  /// No description provided for @simStellarNucleosynthesisSummary.
  ///
  /// In en, this message translates to:
  /// **'Trace how nuclear fusion in stellar cores forges elements from hydrogen to iron.'**
  String get simStellarNucleosynthesisSummary;

  /// No description provided for @simChandrasekharLimit.
  ///
  /// In en, this message translates to:
  /// **'Chandrasekhar Limit'**
  String get simChandrasekharLimit;

  /// No description provided for @simChandrasekharLimitLevel.
  ///
  /// In en, this message translates to:
  /// **'Astrophysics'**
  String get simChandrasekharLimitLevel;

  /// No description provided for @simChandrasekharLimitFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simChandrasekharLimitFormat;

  /// No description provided for @simChandrasekharLimitSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore the 1.4 M☉ mass limit of white dwarfs and the fate of stars above it.'**
  String get simChandrasekharLimitSummary;

  /// No description provided for @simNeutronStar.
  ///
  /// In en, this message translates to:
  /// **'Neutron Star'**
  String get simNeutronStar;

  /// No description provided for @simNeutronStarLevel.
  ///
  /// In en, this message translates to:
  /// **'Astrophysics'**
  String get simNeutronStarLevel;

  /// No description provided for @simNeutronStarFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simNeutronStarFormat;

  /// No description provided for @simNeutronStarSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize the extreme density, ultra-strong magnetic fields, and pulsed emission of neutron stars.'**
  String get simNeutronStarSummary;

  /// No description provided for @simVenturiTube.
  ///
  /// In en, this message translates to:
  /// **'Venturi Effect'**
  String get simVenturiTube;

  /// No description provided for @simVenturiTubeLevel.
  ///
  /// In en, this message translates to:
  /// **'Fluid Mechanics'**
  String get simVenturiTubeLevel;

  /// No description provided for @simVenturiTubeFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simVenturiTubeFormat;

  /// No description provided for @simVenturiTubeSummary.
  ///
  /// In en, this message translates to:
  /// **'Observe pressure drop in a constricted flow tube via the Venturi effect. P₁+½ρv₁²=P₂+½ρv₂²'**
  String get simVenturiTubeSummary;

  /// No description provided for @simSurfaceTension.
  ///
  /// In en, this message translates to:
  /// **'Surface Tension'**
  String get simSurfaceTension;

  /// No description provided for @simSurfaceTensionLevel.
  ///
  /// In en, this message translates to:
  /// **'Fluid Physics'**
  String get simSurfaceTensionLevel;

  /// No description provided for @simSurfaceTensionFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simSurfaceTensionFormat;

  /// No description provided for @simSurfaceTensionSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore how molecular cohesion creates surface tension and enables capillary rise.'**
  String get simSurfaceTensionSummary;

  /// No description provided for @simHookeSpring.
  ///
  /// In en, this message translates to:
  /// **'Springs in Series & Parallel'**
  String get simHookeSpring;

  /// No description provided for @simHookeSpringLevel.
  ///
  /// In en, this message translates to:
  /// **'Mechanics'**
  String get simHookeSpringLevel;

  /// No description provided for @simHookeSpringFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simHookeSpringFormat;

  /// No description provided for @simHookeSpringsSummary.
  ///
  /// In en, this message translates to:
  /// **'Compare effective spring constants for series and parallel spring configurations. 1/k_s = 1/k₁ + 1/k₂'**
  String get simHookeSpringsSummary;

  /// No description provided for @simWheatstoneBridge.
  ///
  /// In en, this message translates to:
  /// **'Wheatstone Bridge'**
  String get simWheatstoneBridge;

  /// No description provided for @simWheatstoneBridgeLevel.
  ///
  /// In en, this message translates to:
  /// **'Electrical Engineering'**
  String get simWheatstoneBridgeLevel;

  /// No description provided for @simWheatstoneBridgeFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simWheatstoneBridgeFormat;

  /// No description provided for @simWheatstoneBridgeSummary.
  ///
  /// In en, this message translates to:
  /// **'Balance a Wheatstone bridge circuit to accurately measure an unknown resistance.'**
  String get simWheatstoneBridgeSummary;

  /// No description provided for @simGradientField.
  ///
  /// In en, this message translates to:
  /// **'Gradient Vector Fields'**
  String get simGradientField;

  /// No description provided for @simGradientFieldLevel.
  ///
  /// In en, this message translates to:
  /// **'Multivariable Calculus'**
  String get simGradientFieldLevel;

  /// No description provided for @simGradientFieldFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simGradientFieldFormat;

  /// No description provided for @simGradientFieldSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize gradient vector fields and equipotential level curves of scalar functions.'**
  String get simGradientFieldSummary;

  /// No description provided for @simDivergenceCurl.
  ///
  /// In en, this message translates to:
  /// **'Divergence & Curl'**
  String get simDivergenceCurl;

  /// No description provided for @simDivergenceCurlLevel.
  ///
  /// In en, this message translates to:
  /// **'Vector Calculus'**
  String get simDivergenceCurlLevel;

  /// No description provided for @simDivergenceCurlFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simDivergenceCurlFormat;

  /// No description provided for @simDivergenceCurlSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore divergence and curl of 2D vector fields — the foundation of Maxwell\'s equations.'**
  String get simDivergenceCurlSummary;

  /// No description provided for @simLaplaceTransform.
  ///
  /// In en, this message translates to:
  /// **'Laplace Transform'**
  String get simLaplaceTransform;

  /// No description provided for @simLaplaceTransformLevel.
  ///
  /// In en, this message translates to:
  /// **'Engineering Mathematics'**
  String get simLaplaceTransformLevel;

  /// No description provided for @simLaplaceTransformFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simLaplaceTransformFormat;

  /// No description provided for @simLaplaceTransformSummary.
  ///
  /// In en, this message translates to:
  /// **'Convert time-domain signals to the s-domain and back. F(s) = ∫₀^∞ f(t)e^(-st) dt'**
  String get simLaplaceTransformSummary;

  /// No description provided for @simZTransform.
  ///
  /// In en, this message translates to:
  /// **'Z-Transform'**
  String get simZTransform;

  /// No description provided for @simZTransformLevel.
  ///
  /// In en, this message translates to:
  /// **'Digital Signal Processing'**
  String get simZTransformLevel;

  /// No description provided for @simZTransformFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simZTransformFormat;

  /// No description provided for @simZTransformSummary.
  ///
  /// In en, this message translates to:
  /// **'Transform discrete-time sequences to the z-domain for digital filter analysis.'**
  String get simZTransformSummary;

  /// No description provided for @simDbscan.
  ///
  /// In en, this message translates to:
  /// **'DBSCAN Clustering'**
  String get simDbscan;

  /// No description provided for @simDbscanLevel.
  ///
  /// In en, this message translates to:
  /// **'Machine Learning'**
  String get simDbscanLevel;

  /// No description provided for @simDbscanFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simDbscanFormat;

  /// No description provided for @simDbscanSummary.
  ///
  /// In en, this message translates to:
  /// **'Density-based spatial clustering that discovers clusters of arbitrary shape and handles noise.'**
  String get simDbscanSummary;

  /// No description provided for @simConfusionMatrix.
  ///
  /// In en, this message translates to:
  /// **'Confusion Matrix & ROC Curve'**
  String get simConfusionMatrix;

  /// No description provided for @simConfusionMatrixLevel.
  ///
  /// In en, this message translates to:
  /// **'Machine Learning'**
  String get simConfusionMatrixLevel;

  /// No description provided for @simConfusionMatrixFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simConfusionMatrixFormat;

  /// No description provided for @simConfusionMatrixSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize classification performance through confusion matrices and ROC-AUC curves.'**
  String get simConfusionMatrixSummary;

  /// No description provided for @simCrossValidation.
  ///
  /// In en, this message translates to:
  /// **'Cross-Validation'**
  String get simCrossValidation;

  /// No description provided for @simCrossValidationLevel.
  ///
  /// In en, this message translates to:
  /// **'Machine Learning'**
  String get simCrossValidationLevel;

  /// No description provided for @simCrossValidationFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simCrossValidationFormat;

  /// No description provided for @simCrossValidationSummary.
  ///
  /// In en, this message translates to:
  /// **'Understand k-fold cross-validation for unbiased model evaluation and hyperparameter tuning.'**
  String get simCrossValidationSummary;

  /// No description provided for @simBiasVariance.
  ///
  /// In en, this message translates to:
  /// **'Bias-Variance Tradeoff'**
  String get simBiasVariance;

  /// No description provided for @simBiasVarianceLevel.
  ///
  /// In en, this message translates to:
  /// **'Machine Learning'**
  String get simBiasVarianceLevel;

  /// No description provided for @simBiasVarianceFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simBiasVarianceFormat;

  /// No description provided for @simBiasVarianceSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore how model complexity balances underfitting (bias) and overfitting (variance).'**
  String get simBiasVarianceSummary;

  /// No description provided for @simQuantumFourier.
  ///
  /// In en, this message translates to:
  /// **'Quantum Fourier Transform'**
  String get simQuantumFourier;

  /// No description provided for @simQuantumFourierLevel.
  ///
  /// In en, this message translates to:
  /// **'Quantum Computing'**
  String get simQuantumFourierLevel;

  /// No description provided for @simQuantumFourierFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simQuantumFourierFormat;

  /// No description provided for @simQuantumFourierSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize the QFT circuit and how it efficiently transforms quantum amplitude distributions.'**
  String get simQuantumFourierSummary;

  /// No description provided for @simDensityMatrix.
  ///
  /// In en, this message translates to:
  /// **'Density Matrix'**
  String get simDensityMatrix;

  /// No description provided for @simDensityMatrixLevel.
  ///
  /// In en, this message translates to:
  /// **'Quantum Mechanics'**
  String get simDensityMatrixLevel;

  /// No description provided for @simDensityMatrixFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simDensityMatrixFormat;

  /// No description provided for @simDensityMatrixSummary.
  ///
  /// In en, this message translates to:
  /// **'Represent pure and mixed quantum states using density matrices and Bloch sphere visualization.'**
  String get simDensityMatrixSummary;

  /// No description provided for @simQuantumWalk.
  ///
  /// In en, this message translates to:
  /// **'Quantum Random Walk'**
  String get simQuantumWalk;

  /// No description provided for @simQuantumWalkLevel.
  ///
  /// In en, this message translates to:
  /// **'Quantum Computing'**
  String get simQuantumWalkLevel;

  /// No description provided for @simQuantumWalkFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simQuantumWalkFormat;

  /// No description provided for @simQuantumWalkSummary.
  ///
  /// In en, this message translates to:
  /// **'Compare quantum and classical random walks — quadratic speedup from quantum interference.'**
  String get simQuantumWalkSummary;

  /// No description provided for @simQuantumDecoherence.
  ///
  /// In en, this message translates to:
  /// **'Quantum Decoherence'**
  String get simQuantumDecoherence;

  /// No description provided for @simQuantumDecoherenceLevel.
  ///
  /// In en, this message translates to:
  /// **'Quantum Mechanics'**
  String get simQuantumDecoherenceLevel;

  /// No description provided for @simQuantumDecoherenceFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simQuantumDecoherenceFormat;

  /// No description provided for @simQuantumDecoherenceSummary.
  ///
  /// In en, this message translates to:
  /// **'Watch quantum coherence decay as a qubit interacts with an environmental bath.'**
  String get simQuantumDecoherenceSummary;

  /// No description provided for @simCrystalLattice.
  ///
  /// In en, this message translates to:
  /// **'Crystal Lattice Structures'**
  String get simCrystalLattice;

  /// No description provided for @simCrystalLatticeLevel.
  ///
  /// In en, this message translates to:
  /// **'Materials Science'**
  String get simCrystalLatticeLevel;

  /// No description provided for @simCrystalLatticeFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simCrystalLatticeFormat;

  /// No description provided for @simCrystalLatticeSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore FCC, BCC, and HCP crystal structures and their packing efficiencies.'**
  String get simCrystalLatticeSummary;

  /// No description provided for @simHessLaw.
  ///
  /// In en, this message translates to:
  /// **'Hess\'s Law'**
  String get simHessLaw;

  /// No description provided for @simHessLawLevel.
  ///
  /// In en, this message translates to:
  /// **'Thermochemistry'**
  String get simHessLawLevel;

  /// No description provided for @simHessLawFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simHessLawFormat;

  /// No description provided for @simHessLawSummary.
  ///
  /// In en, this message translates to:
  /// **'Calculate reaction enthalpy by combining thermochemical equations using Hess\'s law.'**
  String get simHessLawSummary;

  /// No description provided for @simEnthalpyDiagram.
  ///
  /// In en, this message translates to:
  /// **'Enthalpy Diagram'**
  String get simEnthalpyDiagram;

  /// No description provided for @simEnthalpyDiagramLevel.
  ///
  /// In en, this message translates to:
  /// **'Thermochemistry'**
  String get simEnthalpyDiagramLevel;

  /// No description provided for @simEnthalpyDiagramFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simEnthalpyDiagramFormat;

  /// No description provided for @simEnthalpyDiagramSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize exothermic and endothermic reaction energy profiles with activation energy barriers.'**
  String get simEnthalpyDiagramSummary;

  /// No description provided for @simLeChatelier.
  ///
  /// In en, this message translates to:
  /// **'Le Chatelier\'s Principle'**
  String get simLeChatelier;

  /// No description provided for @simLeChatelierLevel.
  ///
  /// In en, this message translates to:
  /// **'Chemical Equilibrium'**
  String get simLeChatelierLevel;

  /// No description provided for @simLeChatelierFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simLeChatelierFormat;

  /// No description provided for @simLeChatelierSummary.
  ///
  /// In en, this message translates to:
  /// **'Observe how equilibrium shifts in response to changes in concentration, pressure, or temperature.'**
  String get simLeChatelierSummary;

  /// No description provided for @simRelativisticEnergy.
  ///
  /// In en, this message translates to:
  /// **'Relativistic Kinetic Energy'**
  String get simRelativisticEnergy;

  /// No description provided for @simRelativisticEnergyLevel.
  ///
  /// In en, this message translates to:
  /// **'Special Relativity'**
  String get simRelativisticEnergyLevel;

  /// No description provided for @simRelativisticEnergyFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simRelativisticEnergyFormat;

  /// No description provided for @simRelativisticEnergySummary.
  ///
  /// In en, this message translates to:
  /// **'Compare classical and relativistic kinetic energy — divergence grows near the speed of light. K = (γ-1)mc²'**
  String get simRelativisticEnergySummary;

  /// No description provided for @simLightCone.
  ///
  /// In en, this message translates to:
  /// **'Light Cone Diagram'**
  String get simLightCone;

  /// No description provided for @simLightConeLevel.
  ///
  /// In en, this message translates to:
  /// **'Special Relativity'**
  String get simLightConeLevel;

  /// No description provided for @simLightConeFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simLightConeFormat;

  /// No description provided for @simLightConeSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize causal structure of spacetime: past, future, and spacelike separated events.'**
  String get simLightConeSummary;

  /// No description provided for @simEquivalencePrinciple.
  ///
  /// In en, this message translates to:
  /// **'Equivalence Principle'**
  String get simEquivalencePrinciple;

  /// No description provided for @simEquivalencePrincipleLevel.
  ///
  /// In en, this message translates to:
  /// **'General Relativity'**
  String get simEquivalencePrincipleLevel;

  /// No description provided for @simEquivalencePrincipleFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simEquivalencePrincipleFormat;

  /// No description provided for @simEquivalencePrincipleSummary.
  ///
  /// In en, this message translates to:
  /// **'Demonstrate Einstein\'s equivalence principle: gravitational and inertial mass are indistinguishable.'**
  String get simEquivalencePrincipleSummary;

  /// No description provided for @simMetricTensor.
  ///
  /// In en, this message translates to:
  /// **'Metric Tensor Visualization'**
  String get simMetricTensor;

  /// No description provided for @simMetricTensorLevel.
  ///
  /// In en, this message translates to:
  /// **'General Relativity'**
  String get simMetricTensorLevel;

  /// No description provided for @simMetricTensorFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simMetricTensorFormat;

  /// No description provided for @simMetricTensorSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize how the metric tensor encodes the geometry of curved spacetime.'**
  String get simMetricTensorSummary;

  /// No description provided for @simSoilLayers.
  ///
  /// In en, this message translates to:
  /// **'Soil Horizons'**
  String get simSoilLayers;

  /// No description provided for @simSoilLayersLevel.
  ///
  /// In en, this message translates to:
  /// **'Earth Science'**
  String get simSoilLayersLevel;

  /// No description provided for @simSoilLayersFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simSoilLayersFormat;

  /// No description provided for @simSoilLayersSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore soil horizon profiles — O, A, B, C layers — and their composition and formation processes.'**
  String get simSoilLayersSummary;

  /// No description provided for @simVolcanoTypes.
  ///
  /// In en, this message translates to:
  /// **'Volcano Types & Eruptions'**
  String get simVolcanoTypes;

  /// No description provided for @simVolcanoTypesLevel.
  ///
  /// In en, this message translates to:
  /// **'Geology'**
  String get simVolcanoTypesLevel;

  /// No description provided for @simVolcanoTypesFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simVolcanoTypesFormat;

  /// No description provided for @simVolcanoTypesSummary.
  ///
  /// In en, this message translates to:
  /// **'Compare shield, stratovolcano, and cinder cone volcanoes with their eruptive styles.'**
  String get simVolcanoTypesSummary;

  /// No description provided for @simMineralIdentification.
  ///
  /// In en, this message translates to:
  /// **'Mineral Identification'**
  String get simMineralIdentification;

  /// No description provided for @simMineralIdentificationLevel.
  ///
  /// In en, this message translates to:
  /// **'Mineralogy'**
  String get simMineralIdentificationLevel;

  /// No description provided for @simMineralIdentificationFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simMineralIdentificationFormat;

  /// No description provided for @simMineralIdentificationSummary.
  ///
  /// In en, this message translates to:
  /// **'Identify minerals using diagnostic properties: hardness (Mohs scale), luster, and streak.'**
  String get simMineralIdentificationSummary;

  /// No description provided for @simErosionDeposition.
  ///
  /// In en, this message translates to:
  /// **'Erosion & Deposition'**
  String get simErosionDeposition;

  /// No description provided for @simErosionDepositionLevel.
  ///
  /// In en, this message translates to:
  /// **'Earth Science'**
  String get simErosionDepositionLevel;

  /// No description provided for @simErosionDepositionFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simErosionDepositionFormat;

  /// No description provided for @simErosionDepositionSummary.
  ///
  /// In en, this message translates to:
  /// **'Simulate how water and wind erode, transport, and deposit sediment to shape landscapes.'**
  String get simErosionDepositionSummary;

  /// No description provided for @simFlocking.
  ///
  /// In en, this message translates to:
  /// **'Boids Flocking Simulation'**
  String get simFlocking;

  /// No description provided for @simFlockingLevel.
  ///
  /// In en, this message translates to:
  /// **'Emergence'**
  String get simFlockingLevel;

  /// No description provided for @simFlockingFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simFlockingFormat;

  /// No description provided for @simFlockingSummary.
  ///
  /// In en, this message translates to:
  /// **'Emergent flocking behavior from three simple rules: separation, alignment, and cohesion.'**
  String get simFlockingSummary;

  /// No description provided for @simAntColony.
  ///
  /// In en, this message translates to:
  /// **'Ant Colony Optimization'**
  String get simAntColony;

  /// No description provided for @simAntColonyLevel.
  ///
  /// In en, this message translates to:
  /// **'Swarm Intelligence'**
  String get simAntColonyLevel;

  /// No description provided for @simAntColonyFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simAntColonyFormat;

  /// No description provided for @simAntColonySummary.
  ///
  /// In en, this message translates to:
  /// **'Watch ants discover optimal paths through pheromone-guided stigmergic communication.'**
  String get simAntColonySummary;

  /// No description provided for @simForestFire.
  ///
  /// In en, this message translates to:
  /// **'Forest Fire Model'**
  String get simForestFire;

  /// No description provided for @simForestFireLevel.
  ///
  /// In en, this message translates to:
  /// **'Complex Systems'**
  String get simForestFireLevel;

  /// No description provided for @simForestFireFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simForestFireFormat;

  /// No description provided for @simForestFireSummary.
  ///
  /// In en, this message translates to:
  /// **'Model fire spreading through forests using percolation theory — a self-organized criticality example.'**
  String get simForestFireSummary;

  /// No description provided for @simNetworkCascade.
  ///
  /// In en, this message translates to:
  /// **'Network Cascade'**
  String get simNetworkCascade;

  /// No description provided for @simNetworkCascadeLevel.
  ///
  /// In en, this message translates to:
  /// **'Network Science'**
  String get simNetworkCascadeLevel;

  /// No description provided for @simNetworkCascadeFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simNetworkCascadeFormat;

  /// No description provided for @simNetworkCascadeSummary.
  ///
  /// In en, this message translates to:
  /// **'Simulate information, disease, or failure cascading through complex networks.'**
  String get simNetworkCascadeSummary;

  /// No description provided for @simSpeciation.
  ///
  /// In en, this message translates to:
  /// **'Speciation'**
  String get simSpeciation;

  /// No description provided for @simSpeciationLevel.
  ///
  /// In en, this message translates to:
  /// **'Evolutionary Biology'**
  String get simSpeciationLevel;

  /// No description provided for @simSpeciationFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simSpeciationFormat;

  /// No description provided for @simSpeciationSummary.
  ///
  /// In en, this message translates to:
  /// **'Simulate allopatric and sympatric speciation driven by geographic isolation and natural selection.'**
  String get simSpeciationSummary;

  /// No description provided for @simPhylogeneticTree.
  ///
  /// In en, this message translates to:
  /// **'Phylogenetic Tree'**
  String get simPhylogeneticTree;

  /// No description provided for @simPhylogeneticTreeLevel.
  ///
  /// In en, this message translates to:
  /// **'Evolutionary Biology'**
  String get simPhylogeneticTreeLevel;

  /// No description provided for @simPhylogeneticTreeFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simPhylogeneticTreeFormat;

  /// No description provided for @simPhylogeneticTreeSummary.
  ///
  /// In en, this message translates to:
  /// **'Build and explore evolutionary trees of life — cladograms showing common ancestry.'**
  String get simPhylogeneticTreeSummary;

  /// No description provided for @simFoodWeb.
  ///
  /// In en, this message translates to:
  /// **'Food Web Dynamics'**
  String get simFoodWeb;

  /// No description provided for @simFoodWebLevel.
  ///
  /// In en, this message translates to:
  /// **'Ecology'**
  String get simFoodWebLevel;

  /// No description provided for @simFoodWebFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simFoodWebFormat;

  /// No description provided for @simFoodWebSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore trophic energy flow through food webs and the consequences of species removal.'**
  String get simFoodWebSummary;

  /// No description provided for @simEcologicalSuccession.
  ///
  /// In en, this message translates to:
  /// **'Ecological Succession'**
  String get simEcologicalSuccession;

  /// No description provided for @simEcologicalSuccessionLevel.
  ///
  /// In en, this message translates to:
  /// **'Ecology'**
  String get simEcologicalSuccessionLevel;

  /// No description provided for @simEcologicalSuccessionFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simEcologicalSuccessionFormat;

  /// No description provided for @simEcologicalSuccessionSummary.
  ///
  /// In en, this message translates to:
  /// **'Watch ecosystems develop from pioneer species on bare rock to a stable climax community.'**
  String get simEcologicalSuccessionSummary;

  /// No description provided for @simSupernova.
  ///
  /// In en, this message translates to:
  /// **'Supernova Types'**
  String get simSupernova;

  /// No description provided for @simSupernovaLevel.
  ///
  /// In en, this message translates to:
  /// **'Astrophysics'**
  String get simSupernovaLevel;

  /// No description provided for @simSupernovaFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simSupernovaFormat;

  /// No description provided for @simSupernovaSummary.
  ///
  /// In en, this message translates to:
  /// **'Compare Type Ia thermonuclear supernovae and core-collapse supernovae from massive stars.'**
  String get simSupernovaSummary;

  /// No description provided for @simBinaryStar.
  ///
  /// In en, this message translates to:
  /// **'Binary Star System'**
  String get simBinaryStar;

  /// No description provided for @simBinaryStarLevel.
  ///
  /// In en, this message translates to:
  /// **'Astrophysics'**
  String get simBinaryStarLevel;

  /// No description provided for @simBinaryStarFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simBinaryStarFormat;

  /// No description provided for @simBinaryStarSummary.
  ///
  /// In en, this message translates to:
  /// **'Simulate orbital dynamics of binary stars and observe light curve variations.'**
  String get simBinaryStarSummary;

  /// No description provided for @simExoplanetTransit.
  ///
  /// In en, this message translates to:
  /// **'Exoplanet Transit Detection'**
  String get simExoplanetTransit;

  /// No description provided for @simExoplanetTransitLevel.
  ///
  /// In en, this message translates to:
  /// **'Astrophysics'**
  String get simExoplanetTransitLevel;

  /// No description provided for @simExoplanetTransitFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simExoplanetTransitFormat;

  /// No description provided for @simExoplanetTransitSummary.
  ///
  /// In en, this message translates to:
  /// **'Detect exoplanets by analyzing stellar brightness dips during planetary transits.'**
  String get simExoplanetTransitSummary;

  /// No description provided for @simParallax.
  ///
  /// In en, this message translates to:
  /// **'Stellar Parallax'**
  String get simParallax;

  /// No description provided for @simParallaxLevel.
  ///
  /// In en, this message translates to:
  /// **'Observational Astronomy'**
  String get simParallaxLevel;

  /// No description provided for @simParallaxFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simParallaxFormat;

  /// No description provided for @simParallaxSummary.
  ///
  /// In en, this message translates to:
  /// **'Measure stellar distances using annual parallax angle shifts. d = 1/p (parsecs)'**
  String get simParallaxSummary;

  /// No description provided for @simMagneticInduction.
  ///
  /// In en, this message translates to:
  /// **'Mutual Induction'**
  String get simMagneticInduction;

  /// No description provided for @simMagneticInductionLevel.
  ///
  /// In en, this message translates to:
  /// **'Electromagnetism'**
  String get simMagneticInductionLevel;

  /// No description provided for @simMagneticInductionFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simMagneticInductionFormat;

  /// No description provided for @simMagneticInductionSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore how changing current in one coil induces voltage in a nearby coupled coil.'**
  String get simMagneticInductionSummary;

  /// No description provided for @simAcCircuits.
  ///
  /// In en, this message translates to:
  /// **'AC Circuit Analysis'**
  String get simAcCircuits;

  /// No description provided for @simAcCircuitsLevel.
  ///
  /// In en, this message translates to:
  /// **'Electrical Engineering'**
  String get simAcCircuitsLevel;

  /// No description provided for @simAcCircuitsFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simAcCircuitsFormat;

  /// No description provided for @simAcCircuitsSummary.
  ///
  /// In en, this message translates to:
  /// **'Analyze impedance, phase relationships, and resonance in RLC AC circuits.'**
  String get simAcCircuitsSummary;

  /// No description provided for @simPhotodiode.
  ///
  /// In en, this message translates to:
  /// **'Photodiode Operation'**
  String get simPhotodiode;

  /// No description provided for @simPhotodiodeLevel.
  ///
  /// In en, this message translates to:
  /// **'Semiconductor Physics'**
  String get simPhotodiodeLevel;

  /// No description provided for @simPhotodiodeFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simPhotodiodeFormat;

  /// No description provided for @simPhotodiodeSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize how photodiodes convert incident photons to electrical current via the photoelectric effect.'**
  String get simPhotodiodeSummary;

  /// No description provided for @simHallEffect.
  ///
  /// In en, this message translates to:
  /// **'Hall Effect'**
  String get simHallEffect;

  /// No description provided for @simHallEffectLevel.
  ///
  /// In en, this message translates to:
  /// **'Solid-State Physics'**
  String get simHallEffectLevel;

  /// No description provided for @simHallEffectFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simHallEffectFormat;

  /// No description provided for @simHallEffectSummary.
  ///
  /// In en, this message translates to:
  /// **'Observe the transverse Hall voltage generated in a current-carrying conductor under a magnetic field.'**
  String get simHallEffectSummary;

  /// No description provided for @simConvolution.
  ///
  /// In en, this message translates to:
  /// **'Convolution'**
  String get simConvolution;

  /// No description provided for @simConvolutionLevel.
  ///
  /// In en, this message translates to:
  /// **'Signal Processing'**
  String get simConvolutionLevel;

  /// No description provided for @simConvolutionFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simConvolutionFormat;

  /// No description provided for @simConvolutionSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize convolution of two functions as a sliding overlap integral — fundamental to filtering.'**
  String get simConvolutionSummary;

  /// No description provided for @simFibonacciSequence.
  ///
  /// In en, this message translates to:
  /// **'Fibonacci Sequence & Golden Spiral'**
  String get simFibonacciSequence;

  /// No description provided for @simFibonacciSequenceLevel.
  ///
  /// In en, this message translates to:
  /// **'Number Theory'**
  String get simFibonacciSequenceLevel;

  /// No description provided for @simFibonacciSequenceFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simFibonacciSequenceFormat;

  /// No description provided for @simFibonacciSequenceSummary.
  ///
  /// In en, this message translates to:
  /// **'Watch the golden spiral emerge from Fibonacci numbers — nature\'s most common growth pattern.'**
  String get simFibonacciSequenceSummary;

  /// No description provided for @simEulerPath.
  ///
  /// In en, this message translates to:
  /// **'Euler & Hamiltonian Paths'**
  String get simEulerPath;

  /// No description provided for @simEulerPathLevel.
  ///
  /// In en, this message translates to:
  /// **'Graph Theory'**
  String get simEulerPathLevel;

  /// No description provided for @simEulerPathFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simEulerPathFormat;

  /// No description provided for @simEulerPathSummary.
  ///
  /// In en, this message translates to:
  /// **'Find Euler paths (traversing every edge) and Hamiltonian paths (visiting every vertex) in graphs.'**
  String get simEulerPathSummary;

  /// No description provided for @simMinimumSpanningTree.
  ///
  /// In en, this message translates to:
  /// **'Minimum Spanning Tree'**
  String get simMinimumSpanningTree;

  /// No description provided for @simMinimumSpanningTreeLevel.
  ///
  /// In en, this message translates to:
  /// **'Graph Theory'**
  String get simMinimumSpanningTreeLevel;

  /// No description provided for @simMinimumSpanningTreeFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simMinimumSpanningTreeFormat;

  /// No description provided for @simMinimumSpanningTreeSummary.
  ///
  /// In en, this message translates to:
  /// **'Build minimum spanning trees using Kruskal\'s and Prim\'s greedy algorithms.'**
  String get simMinimumSpanningTreeSummary;

  /// No description provided for @simBatchNorm.
  ///
  /// In en, this message translates to:
  /// **'Batch Normalization'**
  String get simBatchNorm;

  /// No description provided for @simBatchNormLevel.
  ///
  /// In en, this message translates to:
  /// **'Deep Learning'**
  String get simBatchNormLevel;

  /// No description provided for @simBatchNormFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simBatchNormFormat;

  /// No description provided for @simBatchNormSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize how batch normalization stabilizes training by normalizing layer activations.'**
  String get simBatchNormSummary;

  /// No description provided for @simLearningRate.
  ///
  /// In en, this message translates to:
  /// **'Learning Rate Scheduling'**
  String get simLearningRate;

  /// No description provided for @simLearningRateLevel.
  ///
  /// In en, this message translates to:
  /// **'Deep Learning'**
  String get simLearningRateLevel;

  /// No description provided for @simLearningRateFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simLearningRateFormat;

  /// No description provided for @simLearningRateSummary.
  ///
  /// In en, this message translates to:
  /// **'Compare constant, step decay, cosine annealing, and warm restart learning rate schedules.'**
  String get simLearningRateSummary;

  /// No description provided for @simBackpropagation.
  ///
  /// In en, this message translates to:
  /// **'Backpropagation'**
  String get simBackpropagation;

  /// No description provided for @simBackpropagationLevel.
  ///
  /// In en, this message translates to:
  /// **'Deep Learning'**
  String get simBackpropagationLevel;

  /// No description provided for @simBackpropagationFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simBackpropagationFormat;

  /// No description provided for @simBackpropagationSummary.
  ///
  /// In en, this message translates to:
  /// **'Step through backpropagation in a simple network — computing gradients via the chain rule.'**
  String get simBackpropagationSummary;

  /// No description provided for @simVae.
  ///
  /// In en, this message translates to:
  /// **'Variational Autoencoder (VAE)'**
  String get simVae;

  /// No description provided for @simVaeLevel.
  ///
  /// In en, this message translates to:
  /// **'Generative AI'**
  String get simVaeLevel;

  /// No description provided for @simVaeFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simVaeFormat;

  /// No description provided for @simVaeSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore the latent space of a VAE — encoding, sampling the reparameterization trick, and decoding.'**
  String get simVaeSummary;

  /// No description provided for @simQuantumZeno.
  ///
  /// In en, this message translates to:
  /// **'Quantum Zeno Effect'**
  String get simQuantumZeno;

  /// No description provided for @simQuantumZenoLevel.
  ///
  /// In en, this message translates to:
  /// **'Quantum Mechanics'**
  String get simQuantumZenoLevel;

  /// No description provided for @simQuantumZenoFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simQuantumZenoFormat;

  /// No description provided for @simQuantumZenoSummary.
  ///
  /// In en, this message translates to:
  /// **'Frequent measurement freezes quantum state evolution — the quantum watched pot never boils.'**
  String get simQuantumZenoSummary;

  /// No description provided for @simAharonovBohm.
  ///
  /// In en, this message translates to:
  /// **'Aharonov-Bohm Effect'**
  String get simAharonovBohm;

  /// No description provided for @simAharonovBohmLevel.
  ///
  /// In en, this message translates to:
  /// **'Quantum Mechanics'**
  String get simAharonovBohmLevel;

  /// No description provided for @simAharonovBohmFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simAharonovBohmFormat;

  /// No description provided for @simAharonovBohmSummary.
  ///
  /// In en, this message translates to:
  /// **'Observe phase shifts from a magnetic flux enclosed by electron paths — topology in quantum physics.'**
  String get simAharonovBohmSummary;

  /// No description provided for @simQuantumKeyDist.
  ///
  /// In en, this message translates to:
  /// **'BB84 Quantum Key Distribution'**
  String get simQuantumKeyDist;

  /// No description provided for @simQuantumKeyDistLevel.
  ///
  /// In en, this message translates to:
  /// **'Quantum Cryptography'**
  String get simQuantumKeyDistLevel;

  /// No description provided for @simQuantumKeyDistFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simQuantumKeyDistFormat;

  /// No description provided for @simQuantumKeyDistSummary.
  ///
  /// In en, this message translates to:
  /// **'Simulate the BB84 protocol for unconditionally secure quantum key distribution.'**
  String get simQuantumKeyDistSummary;

  /// No description provided for @simFranckHertz.
  ///
  /// In en, this message translates to:
  /// **'Franck-Hertz Experiment'**
  String get simFranckHertz;

  /// No description provided for @simFranckHertzLevel.
  ///
  /// In en, this message translates to:
  /// **'Atomic Physics'**
  String get simFranckHertzLevel;

  /// No description provided for @simFranckHertzFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simFranckHertzFormat;

  /// No description provided for @simFranckHertzSummary.
  ///
  /// In en, this message translates to:
  /// **'Demonstrate discrete energy levels in atoms through electron collision spectroscopy.'**
  String get simFranckHertzSummary;

  /// No description provided for @simEquilibriumConstant.
  ///
  /// In en, this message translates to:
  /// **'Equilibrium Constant'**
  String get simEquilibriumConstant;

  /// No description provided for @simEquilibriumConstantLevel.
  ///
  /// In en, this message translates to:
  /// **'Chemical Equilibrium'**
  String get simEquilibriumConstantLevel;

  /// No description provided for @simEquilibriumConstantFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simEquilibriumConstantFormat;

  /// No description provided for @simEquilibriumConstantSummary.
  ///
  /// In en, this message translates to:
  /// **'Calculate Kc and Kp for reactions and visualize how concentration ratios reach equilibrium.'**
  String get simEquilibriumConstantSummary;

  /// No description provided for @simBufferSolution.
  ///
  /// In en, this message translates to:
  /// **'Buffer Solutions'**
  String get simBufferSolution;

  /// No description provided for @simBufferSolutionLevel.
  ///
  /// In en, this message translates to:
  /// **'Acid-Base Chemistry'**
  String get simBufferSolutionLevel;

  /// No description provided for @simBufferSolutionFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simBufferSolutionFormat;

  /// No description provided for @simBufferSolutionSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore how weak acid-conjugate base buffers resist pH changes upon acid or base addition.'**
  String get simBufferSolutionSummary;

  /// No description provided for @simRadioactiveDecay.
  ///
  /// In en, this message translates to:
  /// **'Radioactive Decay'**
  String get simRadioactiveDecay;

  /// No description provided for @simRadioactiveDecayLevel.
  ///
  /// In en, this message translates to:
  /// **'Nuclear Chemistry'**
  String get simRadioactiveDecayLevel;

  /// No description provided for @simRadioactiveDecayFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simRadioactiveDecayFormat;

  /// No description provided for @simRadioactiveDecaySummary.
  ///
  /// In en, this message translates to:
  /// **'Simulate alpha, beta, and gamma decay with half-life and decay constant. N = N₀e^(-λt)'**
  String get simRadioactiveDecaySummary;

  /// No description provided for @simNuclearFissionFusion.
  ///
  /// In en, this message translates to:
  /// **'Nuclear Fission & Fusion'**
  String get simNuclearFissionFusion;

  /// No description provided for @simNuclearFissionFusionLevel.
  ///
  /// In en, this message translates to:
  /// **'Nuclear Physics'**
  String get simNuclearFissionFusionLevel;

  /// No description provided for @simNuclearFissionFusionFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simNuclearFissionFusionFormat;

  /// No description provided for @simNuclearFissionFusionSummary.
  ///
  /// In en, this message translates to:
  /// **'Compare energy release from uranium fission and hydrogen fusion via binding energy per nucleon.'**
  String get simNuclearFissionFusionSummary;

  /// No description provided for @simFrameDragging.
  ///
  /// In en, this message translates to:
  /// **'Frame Dragging (Lense-Thirring)'**
  String get simFrameDragging;

  /// No description provided for @simFrameDraggingLevel.
  ///
  /// In en, this message translates to:
  /// **'General Relativity'**
  String get simFrameDraggingLevel;

  /// No description provided for @simFrameDraggingFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simFrameDraggingFormat;

  /// No description provided for @simFrameDraggingSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize how a rotating mass drags the surrounding spacetime fabric.'**
  String get simFrameDraggingSummary;

  /// No description provided for @simPenroseDiagram.
  ///
  /// In en, this message translates to:
  /// **'Penrose Conformal Diagram'**
  String get simPenroseDiagram;

  /// No description provided for @simPenroseDiagramLevel.
  ///
  /// In en, this message translates to:
  /// **'General Relativity'**
  String get simPenroseDiagramLevel;

  /// No description provided for @simPenroseDiagramFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simPenroseDiagramFormat;

  /// No description provided for @simPenroseDiagramSummary.
  ///
  /// In en, this message translates to:
  /// **'Map the infinite structure of spacetime onto a compact finite diagram for black holes and cosmology.'**
  String get simPenroseDiagramSummary;

  /// No description provided for @simFriedmannEquations.
  ///
  /// In en, this message translates to:
  /// **'Friedmann Equations'**
  String get simFriedmannEquations;

  /// No description provided for @simFriedmannEquationsLevel.
  ///
  /// In en, this message translates to:
  /// **'Cosmology'**
  String get simFriedmannEquationsLevel;

  /// No description provided for @simFriedmannEquationsFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simFriedmannEquationsFormat;

  /// No description provided for @simFriedmannEquationsSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore the Friedmann equations governing the expansion history of the universe.'**
  String get simFriedmannEquationsSummary;

  /// No description provided for @simHubbleExpansion.
  ///
  /// In en, this message translates to:
  /// **'Hubble Expansion'**
  String get simHubbleExpansion;

  /// No description provided for @simHubbleExpansionLevel.
  ///
  /// In en, this message translates to:
  /// **'Cosmology'**
  String get simHubbleExpansionLevel;

  /// No description provided for @simHubbleExpansionFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simHubbleExpansionFormat;

  /// No description provided for @simHubbleExpansionSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize the expanding universe — every galaxy receding with velocity v = H₀d.'**
  String get simHubbleExpansionSummary;

  /// No description provided for @simOceanTides.
  ///
  /// In en, this message translates to:
  /// **'Tidal Patterns'**
  String get simOceanTides;

  /// No description provided for @simOceanTidesLevel.
  ///
  /// In en, this message translates to:
  /// **'Oceanography'**
  String get simOceanTidesLevel;

  /// No description provided for @simOceanTidesFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simOceanTidesFormat;

  /// No description provided for @simOceanTidesSummary.
  ///
  /// In en, this message translates to:
  /// **'Model spring and neap tidal patterns from gravitational pull of the Moon and Sun.'**
  String get simOceanTidesSummary;

  /// No description provided for @simThermohaline.
  ///
  /// In en, this message translates to:
  /// **'Thermohaline Circulation'**
  String get simThermohaline;

  /// No description provided for @simThermohalineLevel.
  ///
  /// In en, this message translates to:
  /// **'Oceanography'**
  String get simThermohalineLevel;

  /// No description provided for @simThermohalineFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simThermohalineFormat;

  /// No description provided for @simThermohalineSummary.
  ///
  /// In en, this message translates to:
  /// **'Simulate the global ocean conveyor belt driven by temperature and salinity gradients.'**
  String get simThermohalineSummary;

  /// No description provided for @simElNino.
  ///
  /// In en, this message translates to:
  /// **'El Niño & La Niña'**
  String get simElNino;

  /// No description provided for @simElNinoLevel.
  ///
  /// In en, this message translates to:
  /// **'Climate Science'**
  String get simElNinoLevel;

  /// No description provided for @simElNinoFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simElNinoFormat;

  /// No description provided for @simElNinoSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore how ENSO cycles alter Pacific sea surface temperatures and global weather patterns.'**
  String get simElNinoSummary;

  /// No description provided for @simIceAges.
  ///
  /// In en, this message translates to:
  /// **'Ice Age Cycles'**
  String get simIceAges;

  /// No description provided for @simIceAgesLevel.
  ///
  /// In en, this message translates to:
  /// **'Paleoclimatology'**
  String get simIceAgesLevel;

  /// No description provided for @simIceAgesFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simIceAgesFormat;

  /// No description provided for @simIceAgesSummary.
  ///
  /// In en, this message translates to:
  /// **'Simulate Milankovitch orbital cycles (eccentricity, obliquity, precession) driving glacial-interglacial cycles.'**
  String get simIceAgesSummary;

  /// No description provided for @simSmallWorld.
  ///
  /// In en, this message translates to:
  /// **'Small-World Network'**
  String get simSmallWorld;

  /// No description provided for @simSmallWorldLevel.
  ///
  /// In en, this message translates to:
  /// **'Network Science'**
  String get simSmallWorldLevel;

  /// No description provided for @simSmallWorldFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simSmallWorldFormat;

  /// No description provided for @simSmallWorldSummary.
  ///
  /// In en, this message translates to:
  /// **'Build and analyze Watts-Strogatz small-world networks with high clustering and short path lengths.'**
  String get simSmallWorldSummary;

  /// No description provided for @simScaleFreeNetwork.
  ///
  /// In en, this message translates to:
  /// **'Scale-Free Network'**
  String get simScaleFreeNetwork;

  /// No description provided for @simScaleFreeNetworkLevel.
  ///
  /// In en, this message translates to:
  /// **'Network Science'**
  String get simScaleFreeNetworkLevel;

  /// No description provided for @simScaleFreeNetworkFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simScaleFreeNetworkFormat;

  /// No description provided for @simScaleFreeNetworkSummary.
  ///
  /// In en, this message translates to:
  /// **'Generate Barabasi-Albert scale-free networks through preferential attachment — power-law degree distribution.'**
  String get simScaleFreeNetworkSummary;

  /// No description provided for @simStrangeAttractor.
  ///
  /// In en, this message translates to:
  /// **'Strange Attractor Explorer'**
  String get simStrangeAttractor;

  /// No description provided for @simStrangeAttractorLevel.
  ///
  /// In en, this message translates to:
  /// **'Chaos Theory'**
  String get simStrangeAttractorLevel;

  /// No description provided for @simStrangeAttractorFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simStrangeAttractorFormat;

  /// No description provided for @simStrangeAttractorSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore Lorenz, Rössler, and Halvorsen strange attractors — chaos on fractal manifolds.'**
  String get simStrangeAttractorSummary;

  /// No description provided for @simFeigenbaum.
  ///
  /// In en, this message translates to:
  /// **'Feigenbaum Constants'**
  String get simFeigenbaum;

  /// No description provided for @simFeigenbaumLevel.
  ///
  /// In en, this message translates to:
  /// **'Chaos Theory'**
  String get simFeigenbaumLevel;

  /// No description provided for @simFeigenbaumFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simFeigenbaumFormat;

  /// No description provided for @simFeigenbaumSummary.
  ///
  /// In en, this message translates to:
  /// **'Discover the universal Feigenbaum constant δ ≈ 4.6692 in period-doubling bifurcation cascades.'**
  String get simFeigenbaumSummary;

  /// No description provided for @simCarbonFixation.
  ///
  /// In en, this message translates to:
  /// **'Carbon Fixation (Calvin Cycle)'**
  String get simCarbonFixation;

  /// No description provided for @simCarbonFixationLevel.
  ///
  /// In en, this message translates to:
  /// **'Biochemistry'**
  String get simCarbonFixationLevel;

  /// No description provided for @simCarbonFixationFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simCarbonFixationFormat;

  /// No description provided for @simCarbonFixationSummary.
  ///
  /// In en, this message translates to:
  /// **'Animate the Calvin cycle — how plants fix atmospheric CO₂ into organic carbon using ATP and NADPH.'**
  String get simCarbonFixationSummary;

  /// No description provided for @simKrebsCycle.
  ///
  /// In en, this message translates to:
  /// **'Krebs Cycle (TCA Cycle)'**
  String get simKrebsCycle;

  /// No description provided for @simKrebsCycleLevel.
  ///
  /// In en, this message translates to:
  /// **'Biochemistry'**
  String get simKrebsCycleLevel;

  /// No description provided for @simKrebsCycleFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simKrebsCycleFormat;

  /// No description provided for @simKrebsCycleSummary.
  ///
  /// In en, this message translates to:
  /// **'Step through the citric acid cycle — the central hub of cellular energy metabolism.'**
  String get simKrebsCycleSummary;

  /// No description provided for @simOsmosis.
  ///
  /// In en, this message translates to:
  /// **'Osmosis & Diffusion'**
  String get simOsmosis;

  /// No description provided for @simOsmosisLevel.
  ///
  /// In en, this message translates to:
  /// **'Cell Biology'**
  String get simOsmosisLevel;

  /// No description provided for @simOsmosisFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simOsmosisFormat;

  /// No description provided for @simOsmosisSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize osmotic water flow across semipermeable membranes driven by solute concentration gradients.'**
  String get simOsmosisSummary;

  /// No description provided for @simActionPotentialSynapse.
  ///
  /// In en, this message translates to:
  /// **'Synaptic Transmission'**
  String get simActionPotentialSynapse;

  /// No description provided for @simActionPotentialSynapseLevel.
  ///
  /// In en, this message translates to:
  /// **'Neuroscience'**
  String get simActionPotentialSynapseLevel;

  /// No description provided for @simActionPotentialSynapseFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simActionPotentialSynapseFormat;

  /// No description provided for @simActionPotentialSynapseSummary.
  ///
  /// In en, this message translates to:
  /// **'Animate neurotransmitter release, receptor binding, and postsynaptic potential at chemical synapses.'**
  String get simActionPotentialSynapseSummary;

  /// No description provided for @simRedshiftMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Spectroscopic Redshift'**
  String get simRedshiftMeasurement;

  /// No description provided for @simRedshiftMeasurementLevel.
  ///
  /// In en, this message translates to:
  /// **'Observational Astronomy'**
  String get simRedshiftMeasurementLevel;

  /// No description provided for @simRedshiftMeasurementFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simRedshiftMeasurementFormat;

  /// No description provided for @simRedshiftMeasurementSummary.
  ///
  /// In en, this message translates to:
  /// **'Measure galaxy recession velocities and distances by analyzing spectral redshift z = Δλ/λ.'**
  String get simRedshiftMeasurementSummary;

  /// No description provided for @simPlanetFormation.
  ///
  /// In en, this message translates to:
  /// **'Planet Formation'**
  String get simPlanetFormation;

  /// No description provided for @simPlanetFormationLevel.
  ///
  /// In en, this message translates to:
  /// **'Planetary Science'**
  String get simPlanetFormationLevel;

  /// No description provided for @simPlanetFormationFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simPlanetFormationFormat;

  /// No description provided for @simPlanetFormationSummary.
  ///
  /// In en, this message translates to:
  /// **'Simulate protoplanetary disk evolution and planet formation through accretion.'**
  String get simPlanetFormationSummary;

  /// No description provided for @simRocheLimit.
  ///
  /// In en, this message translates to:
  /// **'Roche Limit'**
  String get simRocheLimit;

  /// No description provided for @simRocheLimitLevel.
  ///
  /// In en, this message translates to:
  /// **'Astrophysics'**
  String get simRocheLimitLevel;

  /// No description provided for @simRocheLimitFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simRocheLimitFormat;

  /// No description provided for @simRocheLimitSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize tidal disruption of a satellite within its planet\'s Roche limit — the origin of ring systems.'**
  String get simRocheLimitSummary;

  /// No description provided for @simLagrangePoints.
  ///
  /// In en, this message translates to:
  /// **'Lagrange Points'**
  String get simLagrangePoints;

  /// No description provided for @simLagrangePointsLevel.
  ///
  /// In en, this message translates to:
  /// **'Orbital Mechanics'**
  String get simLagrangePointsLevel;

  /// No description provided for @simLagrangePointsFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simLagrangePointsFormat;

  /// No description provided for @simLagrangePointsSummary.
  ///
  /// In en, this message translates to:
  /// **'Find the five Lagrange equilibrium points where gravitational and centrifugal forces balance.'**
  String get simLagrangePointsSummary;

  /// No description provided for @simEddyCurrents.
  ///
  /// In en, this message translates to:
  /// **'Eddy Currents'**
  String get simEddyCurrents;

  /// No description provided for @simEddyCurrentsLevel.
  ///
  /// In en, this message translates to:
  /// **'Electromagnetism'**
  String get simEddyCurrentsLevel;

  /// No description provided for @simEddyCurrentsFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simEddyCurrentsFormat;

  /// No description provided for @simEddyCurrentsSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize induced eddy currents in conductors and their braking effect via Lenz\'s law.'**
  String get simEddyCurrentsSummary;

  /// No description provided for @simPascalHydraulic.
  ///
  /// In en, this message translates to:
  /// **'Pascal\'s Hydraulic Press'**
  String get simPascalHydraulic;

  /// No description provided for @simPascalHydraulicLevel.
  ///
  /// In en, this message translates to:
  /// **'Fluid Mechanics'**
  String get simPascalHydraulicLevel;

  /// No description provided for @simPascalHydraulicFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simPascalHydraulicFormat;

  /// No description provided for @simPascalHydraulicSummary.
  ///
  /// In en, this message translates to:
  /// **'Demonstrate hydraulic force multiplication via Pascal\'s principle. F₁/A₁ = F₂/A₂'**
  String get simPascalHydraulicSummary;

  /// No description provided for @simSpecificHeat.
  ///
  /// In en, this message translates to:
  /// **'Specific Heat Capacity'**
  String get simSpecificHeat;

  /// No description provided for @simSpecificHeatLevel.
  ///
  /// In en, this message translates to:
  /// **'Thermodynamics'**
  String get simSpecificHeatLevel;

  /// No description provided for @simSpecificHeatFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simSpecificHeatFormat;

  /// No description provided for @simSpecificHeatSummary.
  ///
  /// In en, this message translates to:
  /// **'Compare how different materials absorb and store heat energy. Q = mcΔT'**
  String get simSpecificHeatSummary;

  /// No description provided for @simStefanBoltzmann.
  ///
  /// In en, this message translates to:
  /// **'Stefan-Boltzmann Radiation'**
  String get simStefanBoltzmann;

  /// No description provided for @simStefanBoltzmannLevel.
  ///
  /// In en, this message translates to:
  /// **'Thermodynamics'**
  String get simStefanBoltzmannLevel;

  /// No description provided for @simStefanBoltzmannFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simStefanBoltzmannFormat;

  /// No description provided for @simStefanBoltzmannSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore how blackbody thermal radiation power scales with temperature to the fourth power. P = σAT⁴'**
  String get simStefanBoltzmannSummary;

  /// No description provided for @simDijkstra.
  ///
  /// In en, this message translates to:
  /// **'Dijkstra\'s Shortest Path'**
  String get simDijkstra;

  /// No description provided for @simDijkstraLevel.
  ///
  /// In en, this message translates to:
  /// **'Algorithms'**
  String get simDijkstraLevel;

  /// No description provided for @simDijkstraFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simDijkstraFormat;

  /// No description provided for @simDijkstraSummary.
  ///
  /// In en, this message translates to:
  /// **'Find shortest paths in weighted graphs using Dijkstra\'s greedy algorithm with a priority queue.'**
  String get simDijkstraSummary;

  /// No description provided for @simVoronoi.
  ///
  /// In en, this message translates to:
  /// **'Voronoi Diagram'**
  String get simVoronoi;

  /// No description provided for @simVoronoiLevel.
  ///
  /// In en, this message translates to:
  /// **'Computational Geometry'**
  String get simVoronoiLevel;

  /// No description provided for @simVoronoiFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simVoronoiFormat;

  /// No description provided for @simVoronoiSummary.
  ///
  /// In en, this message translates to:
  /// **'Generate Voronoi tessellations — each cell contains all points nearest to its seed point.'**
  String get simVoronoiSummary;

  /// No description provided for @simDelaunay.
  ///
  /// In en, this message translates to:
  /// **'Delaunay Triangulation'**
  String get simDelaunay;

  /// No description provided for @simDelaunayLevel.
  ///
  /// In en, this message translates to:
  /// **'Computational Geometry'**
  String get simDelaunayLevel;

  /// No description provided for @simDelaunayFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simDelaunayFormat;

  /// No description provided for @simDelaunaySummary.
  ///
  /// In en, this message translates to:
  /// **'Build Delaunay triangulations — the dual of Voronoi diagrams maximizing minimum triangle angles.'**
  String get simDelaunaySummary;

  /// No description provided for @simBezierCurves.
  ///
  /// In en, this message translates to:
  /// **'Bézier Curves'**
  String get simBezierCurves;

  /// No description provided for @simBezierCurvesLevel.
  ///
  /// In en, this message translates to:
  /// **'Computer Graphics'**
  String get simBezierCurvesLevel;

  /// No description provided for @simBezierCurvesFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simBezierCurvesFormat;

  /// No description provided for @simBezierCurvesSummary.
  ///
  /// In en, this message translates to:
  /// **'Control and visualize Bézier curve construction using de Casteljau\'s recursive algorithm.'**
  String get simBezierCurvesSummary;

  /// No description provided for @simDiffusionModel.
  ///
  /// In en, this message translates to:
  /// **'Diffusion Model'**
  String get simDiffusionModel;

  /// No description provided for @simDiffusionModelLevel.
  ///
  /// In en, this message translates to:
  /// **'Generative AI'**
  String get simDiffusionModelLevel;

  /// No description provided for @simDiffusionModelFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simDiffusionModelFormat;

  /// No description provided for @simDiffusionModelSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize the forward noise diffusion and reverse denoising process in diffusion generative models.'**
  String get simDiffusionModelSummary;

  /// No description provided for @simTokenizer.
  ///
  /// In en, this message translates to:
  /// **'Tokenizer & Byte-Pair Encoding'**
  String get simTokenizer;

  /// No description provided for @simTokenizerLevel.
  ///
  /// In en, this message translates to:
  /// **'NLP'**
  String get simTokenizerLevel;

  /// No description provided for @simTokenizerFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simTokenizerFormat;

  /// No description provided for @simTokenizerSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore how BPE tokenization splits text into subword tokens for language model training.'**
  String get simTokenizerSummary;

  /// No description provided for @simBeamSearch.
  ///
  /// In en, this message translates to:
  /// **'Beam Search Decoding'**
  String get simBeamSearch;

  /// No description provided for @simBeamSearchLevel.
  ///
  /// In en, this message translates to:
  /// **'NLP'**
  String get simBeamSearchLevel;

  /// No description provided for @simBeamSearchFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simBeamSearchFormat;

  /// No description provided for @simBeamSearchSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize beam search maintaining top-k hypotheses during autoregressive sequence decoding.'**
  String get simBeamSearchSummary;

  /// No description provided for @simFeatureImportance.
  ///
  /// In en, this message translates to:
  /// **'Feature Importance (SHAP)'**
  String get simFeatureImportance;

  /// No description provided for @simFeatureImportanceLevel.
  ///
  /// In en, this message translates to:
  /// **'Explainable AI'**
  String get simFeatureImportanceLevel;

  /// No description provided for @simFeatureImportanceFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simFeatureImportanceFormat;

  /// No description provided for @simFeatureImportanceSummary.
  ///
  /// In en, this message translates to:
  /// **'Explain model predictions using SHAP (Shapley Additive Explanations) values.'**
  String get simFeatureImportanceSummary;

  /// No description provided for @simZeemanEffect.
  ///
  /// In en, this message translates to:
  /// **'Zeeman Effect'**
  String get simZeemanEffect;

  /// No description provided for @simZeemanEffectLevel.
  ///
  /// In en, this message translates to:
  /// **'Atomic Physics'**
  String get simZeemanEffectLevel;

  /// No description provided for @simZeemanEffectFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simZeemanEffectFormat;

  /// No description provided for @simZeemanEffectSummary.
  ///
  /// In en, this message translates to:
  /// **'Observe spectral line splitting when atoms are placed in an external magnetic field.'**
  String get simZeemanEffectSummary;

  /// No description provided for @simQuantumWell.
  ///
  /// In en, this message translates to:
  /// **'Quantum Well'**
  String get simQuantumWell;

  /// No description provided for @simQuantumWellLevel.
  ///
  /// In en, this message translates to:
  /// **'Semiconductor Physics'**
  String get simQuantumWellLevel;

  /// No description provided for @simQuantumWellFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simQuantumWellFormat;

  /// No description provided for @simQuantumWellSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore quantized bound states and wavefunctions in a finite quantum well potential.'**
  String get simQuantumWellSummary;

  /// No description provided for @simBandStructure.
  ///
  /// In en, this message translates to:
  /// **'Electronic Band Structure'**
  String get simBandStructure;

  /// No description provided for @simBandStructureLevel.
  ///
  /// In en, this message translates to:
  /// **'Solid-State Physics'**
  String get simBandStructureLevel;

  /// No description provided for @simBandStructureFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simBandStructureFormat;

  /// No description provided for @simBandStructureSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize energy band structure in crystals — the basis for metals, semiconductors, and insulators.'**
  String get simBandStructureSummary;

  /// No description provided for @simBoseEinstein.
  ///
  /// In en, this message translates to:
  /// **'Bose-Einstein Condensation'**
  String get simBoseEinstein;

  /// No description provided for @simBoseEinsteinLevel.
  ///
  /// In en, this message translates to:
  /// **'Quantum Physics'**
  String get simBoseEinsteinLevel;

  /// No description provided for @simBoseEinsteinFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simBoseEinsteinFormat;

  /// No description provided for @simBoseEinsteinSummary.
  ///
  /// In en, this message translates to:
  /// **'Simulate the BEC phase transition where bosons macroscopically occupy the ground state.'**
  String get simBoseEinsteinSummary;

  /// No description provided for @simOrganicFunctionalGroups.
  ///
  /// In en, this message translates to:
  /// **'Organic Functional Groups'**
  String get simOrganicFunctionalGroups;

  /// No description provided for @simOrganicFunctionalGroupsLevel.
  ///
  /// In en, this message translates to:
  /// **'Organic Chemistry'**
  String get simOrganicFunctionalGroupsLevel;

  /// No description provided for @simOrganicFunctionalGroupsFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simOrganicFunctionalGroupsFormat;

  /// No description provided for @simOrganicFunctionalGroupsSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore hydroxyl, carbonyl, carboxyl, amino, and other organic functional groups and their reactivity.'**
  String get simOrganicFunctionalGroupsSummary;

  /// No description provided for @simIsomers.
  ///
  /// In en, this message translates to:
  /// **'Structural & Geometric Isomers'**
  String get simIsomers;

  /// No description provided for @simIsomersLevel.
  ///
  /// In en, this message translates to:
  /// **'Organic Chemistry'**
  String get simIsomersLevel;

  /// No description provided for @simIsomersFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simIsomersFormat;

  /// No description provided for @simIsomersSummary.
  ///
  /// In en, this message translates to:
  /// **'Compare constitutional isomers and geometric (cis-trans) isomers with 3D molecular visualization.'**
  String get simIsomersSummary;

  /// No description provided for @simPolymerization.
  ///
  /// In en, this message translates to:
  /// **'Polymerization'**
  String get simPolymerization;

  /// No description provided for @simPolymerizationLevel.
  ///
  /// In en, this message translates to:
  /// **'Polymer Chemistry'**
  String get simPolymerizationLevel;

  /// No description provided for @simPolymerizationFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simPolymerizationFormat;

  /// No description provided for @simPolymerizationSummary.
  ///
  /// In en, this message translates to:
  /// **'Animate addition and condensation polymerization — building macromolecules from monomers.'**
  String get simPolymerizationSummary;

  /// No description provided for @simElectrolysis.
  ///
  /// In en, this message translates to:
  /// **'Electrolysis'**
  String get simElectrolysis;

  /// No description provided for @simElectrolysisLevel.
  ///
  /// In en, this message translates to:
  /// **'Electrochemistry'**
  String get simElectrolysisLevel;

  /// No description provided for @simElectrolysisFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simElectrolysisFormat;

  /// No description provided for @simElectrolysisSummary.
  ///
  /// In en, this message translates to:
  /// **'Simulate electrolysis of water and aqueous salt solutions — splitting molecules with electric current.'**
  String get simElectrolysisSummary;

  /// No description provided for @simCosmicMicrowaveBg.
  ///
  /// In en, this message translates to:
  /// **'Cosmic Microwave Background'**
  String get simCosmicMicrowaveBg;

  /// No description provided for @simCosmicMicrowaveBgLevel.
  ///
  /// In en, this message translates to:
  /// **'Cosmology'**
  String get simCosmicMicrowaveBgLevel;

  /// No description provided for @simCosmicMicrowaveBgFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simCosmicMicrowaveBgFormat;

  /// No description provided for @simCosmicMicrowaveBgSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore CMB temperature anisotropies — the oldest light in the universe as evidence for the Big Bang.'**
  String get simCosmicMicrowaveBgSummary;

  /// No description provided for @simKerrBlackHole.
  ///
  /// In en, this message translates to:
  /// **'Kerr Black Hole'**
  String get simKerrBlackHole;

  /// No description provided for @simKerrBlackHoleLevel.
  ///
  /// In en, this message translates to:
  /// **'General Relativity'**
  String get simKerrBlackHoleLevel;

  /// No description provided for @simKerrBlackHoleFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simKerrBlackHoleFormat;

  /// No description provided for @simKerrBlackHoleSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize the ergosphere and frame dragging effects of a rotating Kerr black hole.'**
  String get simKerrBlackHoleSummary;

  /// No description provided for @simShapiroDelay.
  ///
  /// In en, this message translates to:
  /// **'Shapiro Time Delay'**
  String get simShapiroDelay;

  /// No description provided for @simShapiroDelayLevel.
  ///
  /// In en, this message translates to:
  /// **'General Relativity'**
  String get simShapiroDelayLevel;

  /// No description provided for @simShapiroDelayFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simShapiroDelayFormat;

  /// No description provided for @simShapiroDelaySummary.
  ///
  /// In en, this message translates to:
  /// **'Measure the gravitational time delay of radar signals passing near massive bodies — a GR test.'**
  String get simShapiroDelaySummary;

  /// No description provided for @simGravitationalTime.
  ///
  /// In en, this message translates to:
  /// **'Gravitational Time Dilation'**
  String get simGravitationalTime;

  /// No description provided for @simGravitationalTimeLevel.
  ///
  /// In en, this message translates to:
  /// **'General Relativity'**
  String get simGravitationalTimeLevel;

  /// No description provided for @simGravitationalTimeFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simGravitationalTimeFormat;

  /// No description provided for @simGravitationalTimeSummary.
  ///
  /// In en, this message translates to:
  /// **'Compare clock rates at different gravitational potentials — clocks deeper in a gravity well run slower.'**
  String get simGravitationalTimeSummary;

  /// No description provided for @simOzoneLayer.
  ///
  /// In en, this message translates to:
  /// **'Ozone Layer Depletion'**
  String get simOzoneLayer;

  /// No description provided for @simOzoneLayerLevel.
  ///
  /// In en, this message translates to:
  /// **'Atmospheric Chemistry'**
  String get simOzoneLayerLevel;

  /// No description provided for @simOzoneLayerFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simOzoneLayerFormat;

  /// No description provided for @simOzoneLayerSummary.
  ///
  /// In en, this message translates to:
  /// **'Simulate CFC-catalyzed ozone destruction in the stratosphere and the Antarctic ozone hole.'**
  String get simOzoneLayerSummary;

  /// No description provided for @simRadiationBudget.
  ///
  /// In en, this message translates to:
  /// **'Earth\'s Radiation Budget'**
  String get simRadiationBudget;

  /// No description provided for @simRadiationBudgetLevel.
  ///
  /// In en, this message translates to:
  /// **'Climate Science'**
  String get simRadiationBudgetLevel;

  /// No description provided for @simRadiationBudgetFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simRadiationBudgetFormat;

  /// No description provided for @simRadiationBudgetSummary.
  ///
  /// In en, this message translates to:
  /// **'Balance incoming solar shortwave and outgoing terrestrial longwave radiation fluxes.'**
  String get simRadiationBudgetSummary;

  /// No description provided for @simNitrogenCycle.
  ///
  /// In en, this message translates to:
  /// **'Nitrogen Cycle'**
  String get simNitrogenCycle;

  /// No description provided for @simNitrogenCycleLevel.
  ///
  /// In en, this message translates to:
  /// **'Biogeochemistry'**
  String get simNitrogenCycleLevel;

  /// No description provided for @simNitrogenCycleFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simNitrogenCycleFormat;

  /// No description provided for @simNitrogenCycleSummary.
  ///
  /// In en, this message translates to:
  /// **'Trace nitrogen through fixation, nitrification, denitrification, and assimilation in ecosystems.'**
  String get simNitrogenCycleSummary;

  /// No description provided for @simFossilFormation.
  ///
  /// In en, this message translates to:
  /// **'Fossil Formation'**
  String get simFossilFormation;

  /// No description provided for @simFossilFormationLevel.
  ///
  /// In en, this message translates to:
  /// **'Paleontology'**
  String get simFossilFormationLevel;

  /// No description provided for @simFossilFormationFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simFossilFormationFormat;

  /// No description provided for @simFossilFormationSummary.
  ///
  /// In en, this message translates to:
  /// **'Animate the step-by-step process of organism preservation and fossil formation in sedimentary rock.'**
  String get simFossilFormationSummary;

  /// No description provided for @simLyapunovExponent.
  ///
  /// In en, this message translates to:
  /// **'Lyapunov Exponent'**
  String get simLyapunovExponent;

  /// No description provided for @simLyapunovExponentLevel.
  ///
  /// In en, this message translates to:
  /// **'Chaos Theory'**
  String get simLyapunovExponentLevel;

  /// No description provided for @simLyapunovExponentFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simLyapunovExponentFormat;

  /// No description provided for @simLyapunovExponentSummary.
  ///
  /// In en, this message translates to:
  /// **'Calculate Lyapunov exponents to quantify the rate of trajectory divergence in chaotic systems.'**
  String get simLyapunovExponentSummary;

  /// No description provided for @simTentMap.
  ///
  /// In en, this message translates to:
  /// **'Tent Map'**
  String get simTentMap;

  /// No description provided for @simTentMapLevel.
  ///
  /// In en, this message translates to:
  /// **'Chaos Theory'**
  String get simTentMapLevel;

  /// No description provided for @simTentMapFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simTentMapFormat;

  /// No description provided for @simTentMapSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore chaotic behavior of the tent map — a piecewise-linear analog of the logistic map.'**
  String get simTentMapSummary;

  /// No description provided for @simSierpinskiCarpet.
  ///
  /// In en, this message translates to:
  /// **'Sierpinski Carpet'**
  String get simSierpinskiCarpet;

  /// No description provided for @simSierpinskiCarpetLevel.
  ///
  /// In en, this message translates to:
  /// **'Fractal Geometry'**
  String get simSierpinskiCarpetLevel;

  /// No description provided for @simSierpinskiCarpetFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simSierpinskiCarpetFormat;

  /// No description provided for @simSierpinskiCarpetSummary.
  ///
  /// In en, this message translates to:
  /// **'Generate the Sierpinski carpet fractal through recursive square subdivision.'**
  String get simSierpinskiCarpetSummary;

  /// No description provided for @simChaosGame.
  ///
  /// In en, this message translates to:
  /// **'Chaos Game'**
  String get simChaosGame;

  /// No description provided for @simChaosGameLevel.
  ///
  /// In en, this message translates to:
  /// **'Fractal Geometry'**
  String get simChaosGameLevel;

  /// No description provided for @simChaosGameFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simChaosGameFormat;

  /// No description provided for @simChaosGameSummary.
  ///
  /// In en, this message translates to:
  /// **'Generate Sierpinski triangle and other fractals using the chaos game random iteration algorithm.'**
  String get simChaosGameSummary;

  /// No description provided for @simImmuneResponse.
  ///
  /// In en, this message translates to:
  /// **'Immune Response'**
  String get simImmuneResponse;

  /// No description provided for @simImmuneResponseLevel.
  ///
  /// In en, this message translates to:
  /// **'Immunology'**
  String get simImmuneResponseLevel;

  /// No description provided for @simImmuneResponseFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simImmuneResponseFormat;

  /// No description provided for @simImmuneResponseSummary.
  ///
  /// In en, this message translates to:
  /// **'Simulate innate and adaptive immune responses — from antigen detection to antibody production.'**
  String get simImmuneResponseSummary;

  /// No description provided for @simMuscleContraction.
  ///
  /// In en, this message translates to:
  /// **'Muscle Contraction'**
  String get simMuscleContraction;

  /// No description provided for @simMuscleContractionLevel.
  ///
  /// In en, this message translates to:
  /// **'Physiology'**
  String get simMuscleContractionLevel;

  /// No description provided for @simMuscleContractionFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simMuscleContractionFormat;

  /// No description provided for @simMuscleContractionSummary.
  ///
  /// In en, this message translates to:
  /// **'Animate the sliding filament mechanism — myosin cross-bridges pulling actin filaments.'**
  String get simMuscleContractionSummary;

  /// No description provided for @simHeartConduction.
  ///
  /// In en, this message translates to:
  /// **'Cardiac Electrical Conduction'**
  String get simHeartConduction;

  /// No description provided for @simHeartConductionLevel.
  ///
  /// In en, this message translates to:
  /// **'Physiology'**
  String get simHeartConductionLevel;

  /// No description provided for @simHeartConductionFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simHeartConductionFormat;

  /// No description provided for @simHeartConductionSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize the heart\'s electrical conduction pathway: SA node → AV node → Bundle of His → Purkinje fibers.'**
  String get simHeartConductionSummary;

  /// No description provided for @simBloodCirculation.
  ///
  /// In en, this message translates to:
  /// **'Blood Circulation'**
  String get simBloodCirculation;

  /// No description provided for @simBloodCirculationLevel.
  ///
  /// In en, this message translates to:
  /// **'Physiology'**
  String get simBloodCirculationLevel;

  /// No description provided for @simBloodCirculationFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simBloodCirculationFormat;

  /// No description provided for @simBloodCirculationSummary.
  ///
  /// In en, this message translates to:
  /// **'Trace blood flow through pulmonary and systemic circuits of the cardiovascular system.'**
  String get simBloodCirculationSummary;

  /// No description provided for @simOrbitalTransfer.
  ///
  /// In en, this message translates to:
  /// **'Hohmann Transfer Orbit'**
  String get simOrbitalTransfer;

  /// No description provided for @simOrbitalTransferLevel.
  ///
  /// In en, this message translates to:
  /// **'Orbital Mechanics'**
  String get simOrbitalTransferLevel;

  /// No description provided for @simOrbitalTransferFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simOrbitalTransferFormat;

  /// No description provided for @simOrbitalTransferSummary.
  ///
  /// In en, this message translates to:
  /// **'Calculate and visualize the two-burn Hohmann transfer between circular orbits — most fuel-efficient transfer.'**
  String get simOrbitalTransferSummary;

  /// No description provided for @simEscapeVelocity.
  ///
  /// In en, this message translates to:
  /// **'Escape Velocity'**
  String get simEscapeVelocity;

  /// No description provided for @simEscapeVelocityLevel.
  ///
  /// In en, this message translates to:
  /// **'Orbital Mechanics'**
  String get simEscapeVelocityLevel;

  /// No description provided for @simEscapeVelocityFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simEscapeVelocityFormat;

  /// No description provided for @simEscapeVelocitySummary.
  ///
  /// In en, this message translates to:
  /// **'Calculate escape velocity for planets and stars. v_e = √(2GM/r)'**
  String get simEscapeVelocitySummary;

  /// No description provided for @simCelestialSphere.
  ///
  /// In en, this message translates to:
  /// **'Celestial Sphere'**
  String get simCelestialSphere;

  /// No description provided for @simCelestialSphereLevel.
  ///
  /// In en, this message translates to:
  /// **'Observational Astronomy'**
  String get simCelestialSphereLevel;

  /// No description provided for @simCelestialSphereFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simCelestialSphereFormat;

  /// No description provided for @simCelestialSphereSummary.
  ///
  /// In en, this message translates to:
  /// **'Navigate the celestial sphere — right ascension, declination, and seasonal constellation visibility.'**
  String get simCelestialSphereSummary;

  /// No description provided for @simGalaxyRotation.
  ///
  /// In en, this message translates to:
  /// **'Galaxy Rotation Curves'**
  String get simGalaxyRotation;

  /// No description provided for @simGalaxyRotationLevel.
  ///
  /// In en, this message translates to:
  /// **'Astrophysics'**
  String get simGalaxyRotationLevel;

  /// No description provided for @simGalaxyRotationFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simGalaxyRotationFormat;

  /// No description provided for @simGalaxyRotationSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore flat galaxy rotation curves as observational evidence for dark matter halos.'**
  String get simGalaxyRotationSummary;

  /// No description provided for @simWavePacket.
  ///
  /// In en, this message translates to:
  /// **'Wave Packet & Group Velocity'**
  String get simWavePacket;

  /// No description provided for @simWavePacketLevel.
  ///
  /// In en, this message translates to:
  /// **'Wave Physics'**
  String get simWavePacketLevel;

  /// No description provided for @simWavePacketFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simWavePacketFormat;

  /// No description provided for @simWavePacketSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize phase velocity vs. group velocity in wave packets — key to quantum mechanics and optics.'**
  String get simWavePacketSummary;

  /// No description provided for @simLissajous.
  ///
  /// In en, this message translates to:
  /// **'Lissajous Figures'**
  String get simLissajous;

  /// No description provided for @simLissajousLevel.
  ///
  /// In en, this message translates to:
  /// **'Wave Physics'**
  String get simLissajousLevel;

  /// No description provided for @simLissajousFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simLissajousFormat;

  /// No description provided for @simLissajousSummary.
  ///
  /// In en, this message translates to:
  /// **'Create Lissajous figures from two perpendicular sinusoidal oscillations — beautiful and diagnostic.'**
  String get simLissajousSummary;

  /// No description provided for @simDopplerRadar.
  ///
  /// In en, this message translates to:
  /// **'Doppler Radar'**
  String get simDopplerRadar;

  /// No description provided for @simDopplerRadarLevel.
  ///
  /// In en, this message translates to:
  /// **'Applied Physics'**
  String get simDopplerRadarLevel;

  /// No description provided for @simDopplerRadarFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simDopplerRadarFormat;

  /// No description provided for @simDopplerRadarSummary.
  ///
  /// In en, this message translates to:
  /// **'Measure target velocity using Doppler frequency shifts — the principle behind weather radar and speed guns.'**
  String get simDopplerRadarSummary;

  /// No description provided for @simCavendish.
  ///
  /// In en, this message translates to:
  /// **'Cavendish Experiment'**
  String get simCavendish;

  /// No description provided for @simCavendishLevel.
  ///
  /// In en, this message translates to:
  /// **'Gravitation'**
  String get simCavendishLevel;

  /// No description provided for @simCavendishFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simCavendishFormat;

  /// No description provided for @simCavendishSummary.
  ///
  /// In en, this message translates to:
  /// **'Measure the gravitational constant G with a torsion balance — replicating Cavendish\'s 1798 experiment. G = 6.674×10⁻¹¹'**
  String get simCavendishSummary;

  /// No description provided for @simPolarCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Polar Coordinates & Rose Curves'**
  String get simPolarCoordinates;

  /// No description provided for @simPolarCoordinatesLevel.
  ///
  /// In en, this message translates to:
  /// **'Precalculus'**
  String get simPolarCoordinatesLevel;

  /// No description provided for @simPolarCoordinatesFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simPolarCoordinatesFormat;

  /// No description provided for @simPolarCoordinatesSummary.
  ///
  /// In en, this message translates to:
  /// **'Plot polar curves including rose, limaçon, and Archimedean spiral patterns interactively.'**
  String get simPolarCoordinatesSummary;

  /// No description provided for @simParametricCurves.
  ///
  /// In en, this message translates to:
  /// **'Parametric Curves'**
  String get simParametricCurves;

  /// No description provided for @simParametricCurvesLevel.
  ///
  /// In en, this message translates to:
  /// **'Calculus'**
  String get simParametricCurvesLevel;

  /// No description provided for @simParametricCurvesFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simParametricCurvesFormat;

  /// No description provided for @simParametricCurvesSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore parametric curves — cycloids, epicycloids, hypocycloids — by controlling x(t) and y(t).'**
  String get simParametricCurvesSummary;

  /// No description provided for @simBinomialDistribution.
  ///
  /// In en, this message translates to:
  /// **'Binomial Distribution'**
  String get simBinomialDistribution;

  /// No description provided for @simBinomialDistributionLevel.
  ///
  /// In en, this message translates to:
  /// **'Probability'**
  String get simBinomialDistributionLevel;

  /// No description provided for @simBinomialDistributionFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simBinomialDistributionFormat;

  /// No description provided for @simBinomialDistributionSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize binomial probability distributions and the normal approximation for large n.'**
  String get simBinomialDistributionSummary;

  /// No description provided for @simPoissonDistribution.
  ///
  /// In en, this message translates to:
  /// **'Poisson Distribution'**
  String get simPoissonDistribution;

  /// No description provided for @simPoissonDistributionLevel.
  ///
  /// In en, this message translates to:
  /// **'Probability'**
  String get simPoissonDistributionLevel;

  /// No description provided for @simPoissonDistributionFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simPoissonDistributionFormat;

  /// No description provided for @simPoissonDistributionSummary.
  ///
  /// In en, this message translates to:
  /// **'Model rare events with the Poisson distribution. P(k) = λ^k · e^(-λ) / k!'**
  String get simPoissonDistributionSummary;

  /// No description provided for @simDimensionalityReduction.
  ///
  /// In en, this message translates to:
  /// **'t-SNE Dimensionality Reduction'**
  String get simDimensionalityReduction;

  /// No description provided for @simDimensionalityReductionLevel.
  ///
  /// In en, this message translates to:
  /// **'Machine Learning'**
  String get simDimensionalityReductionLevel;

  /// No description provided for @simDimensionalityReductionFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simDimensionalityReductionFormat;

  /// No description provided for @simDimensionalityReductionSummary.
  ///
  /// In en, this message translates to:
  /// **'Reduce high-dimensional data to 2D with t-SNE, preserving local neighborhood structure.'**
  String get simDimensionalityReductionSummary;

  /// No description provided for @simNeuralStyle.
  ///
  /// In en, this message translates to:
  /// **'Neural Style Transfer'**
  String get simNeuralStyle;

  /// No description provided for @simNeuralStyleLevel.
  ///
  /// In en, this message translates to:
  /// **'Computer Vision'**
  String get simNeuralStyleLevel;

  /// No description provided for @simNeuralStyleFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simNeuralStyleFormat;

  /// No description provided for @simNeuralStyleSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize content and style feature separation in convolutional neural networks.'**
  String get simNeuralStyleSummary;

  /// No description provided for @simMazeRl.
  ///
  /// In en, this message translates to:
  /// **'Maze Solving with Reinforcement Learning'**
  String get simMazeRl;

  /// No description provided for @simMazeRlLevel.
  ///
  /// In en, this message translates to:
  /// **'Reinforcement Learning'**
  String get simMazeRlLevel;

  /// No description provided for @simMazeRlFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simMazeRlFormat;

  /// No description provided for @simMazeRlSummary.
  ///
  /// In en, this message translates to:
  /// **'Watch a Q-learning agent explore and learn to navigate a maze through trial and error.'**
  String get simMazeRlSummary;

  /// No description provided for @simMinimax.
  ///
  /// In en, this message translates to:
  /// **'Minimax Game Tree'**
  String get simMinimax;

  /// No description provided for @simMinimaxLevel.
  ///
  /// In en, this message translates to:
  /// **'Game AI'**
  String get simMinimaxLevel;

  /// No description provided for @simMinimaxFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simMinimaxFormat;

  /// No description provided for @simMinimaxSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore minimax decision-making with alpha-beta pruning for two-player zero-sum games.'**
  String get simMinimaxSummary;

  /// No description provided for @simFermiDirac.
  ///
  /// In en, this message translates to:
  /// **'Fermi-Dirac Distribution'**
  String get simFermiDirac;

  /// No description provided for @simFermiDiracLevel.
  ///
  /// In en, this message translates to:
  /// **'Statistical Mechanics'**
  String get simFermiDiracLevel;

  /// No description provided for @simFermiDiracFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simFermiDiracFormat;

  /// No description provided for @simFermiDiracSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize the Fermi-Dirac occupation probability at different temperatures — the basis of semiconductor physics.'**
  String get simFermiDiracSummary;

  /// No description provided for @simWignerFunction.
  ///
  /// In en, this message translates to:
  /// **'Wigner Quasi-Probability Function'**
  String get simWignerFunction;

  /// No description provided for @simWignerFunctionLevel.
  ///
  /// In en, this message translates to:
  /// **'Quantum Optics'**
  String get simWignerFunctionLevel;

  /// No description provided for @simWignerFunctionFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simWignerFunctionFormat;

  /// No description provided for @simWignerFunctionSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore the Wigner function as a quantum phase-space representation — negative values signal non-classicality.'**
  String get simWignerFunctionSummary;

  /// No description provided for @simQuantumOscillator2d.
  ///
  /// In en, this message translates to:
  /// **'2D Quantum Harmonic Oscillator'**
  String get simQuantumOscillator2d;

  /// No description provided for @simQuantumOscillator2dLevel.
  ///
  /// In en, this message translates to:
  /// **'Quantum Mechanics'**
  String get simQuantumOscillator2dLevel;

  /// No description provided for @simQuantumOscillator2dFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simQuantumOscillator2dFormat;

  /// No description provided for @simQuantumOscillator2dSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize wavefunctions and energy eigenvalues of the 2D isotropic quantum harmonic oscillator.'**
  String get simQuantumOscillator2dSummary;

  /// No description provided for @simSpinChain.
  ///
  /// In en, this message translates to:
  /// **'Quantum Spin Chain'**
  String get simSpinChain;

  /// No description provided for @simSpinChainLevel.
  ///
  /// In en, this message translates to:
  /// **'Quantum Many-Body'**
  String get simSpinChainLevel;

  /// No description provided for @simSpinChainFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simSpinChainFormat;

  /// No description provided for @simSpinChainSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore quantum correlations and entanglement in spin-1/2 Heisenberg spin chains.'**
  String get simSpinChainSummary;

  /// No description provided for @simIdealSolution.
  ///
  /// In en, this message translates to:
  /// **'Raoult\'s Law & Ideal Solutions'**
  String get simIdealSolution;

  /// No description provided for @simIdealSolutionLevel.
  ///
  /// In en, this message translates to:
  /// **'Physical Chemistry'**
  String get simIdealSolutionLevel;

  /// No description provided for @simIdealSolutionFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simIdealSolutionFormat;

  /// No description provided for @simIdealSolutionSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore vapor pressure lowering and activity coefficients in ideal and non-ideal solutions.'**
  String get simIdealSolutionSummary;

  /// No description provided for @simChromatography.
  ///
  /// In en, this message translates to:
  /// **'Chromatography'**
  String get simChromatography;

  /// No description provided for @simChromatographyLevel.
  ///
  /// In en, this message translates to:
  /// **'Analytical Chemistry'**
  String get simChromatographyLevel;

  /// No description provided for @simChromatographyFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simChromatographyFormat;

  /// No description provided for @simChromatographySummary.
  ///
  /// In en, this message translates to:
  /// **'Separate mixture components by differential migration through stationary and mobile phases.'**
  String get simChromatographySummary;

  /// No description provided for @simCalorimetry.
  ///
  /// In en, this message translates to:
  /// **'Calorimetry'**
  String get simCalorimetry;

  /// No description provided for @simCalorimetryLevel.
  ///
  /// In en, this message translates to:
  /// **'Thermochemistry'**
  String get simCalorimetryLevel;

  /// No description provided for @simCalorimetryFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simCalorimetryFormat;

  /// No description provided for @simCalorimetrySummary.
  ///
  /// In en, this message translates to:
  /// **'Measure heat transfer in constant-pressure and constant-volume calorimeters. q = mcΔT'**
  String get simCalorimetrySummary;

  /// No description provided for @simActivationEnergy.
  ///
  /// In en, this message translates to:
  /// **'Activation Energy & Catalysts'**
  String get simActivationEnergy;

  /// No description provided for @simActivationEnergyLevel.
  ///
  /// In en, this message translates to:
  /// **'Kinetics'**
  String get simActivationEnergyLevel;

  /// No description provided for @simActivationEnergyFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simActivationEnergyFormat;

  /// No description provided for @simActivationEnergySummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize how catalysts lower the activation energy barrier — Arrhenius equation and transition state theory.'**
  String get simActivationEnergySummary;

  /// No description provided for @simRelativistAberration.
  ///
  /// In en, this message translates to:
  /// **'Relativistic Aberration'**
  String get simRelativistAberration;

  /// No description provided for @simRelativistAberrationLevel.
  ///
  /// In en, this message translates to:
  /// **'Special Relativity'**
  String get simRelativistAberrationLevel;

  /// No description provided for @simRelativistAberrationFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simRelativistAberrationFormat;

  /// No description provided for @simRelativistAberrationSummary.
  ///
  /// In en, this message translates to:
  /// **'See how stellar positions appear to shift as your velocity approaches c — the headlight effect.'**
  String get simRelativistAberrationSummary;

  /// No description provided for @simRelativisticBeaming.
  ///
  /// In en, this message translates to:
  /// **'Relativistic Beaming'**
  String get simRelativisticBeaming;

  /// No description provided for @simRelativisticBeamingLevel.
  ///
  /// In en, this message translates to:
  /// **'Special Relativity'**
  String get simRelativisticBeamingLevel;

  /// No description provided for @simRelativisticBeamingFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simRelativisticBeamingFormat;

  /// No description provided for @simRelativisticBeamingSummary.
  ///
  /// In en, this message translates to:
  /// **'Observe the concentration of emitted radiation in the forward direction at relativistic speeds.'**
  String get simRelativisticBeamingSummary;

  /// No description provided for @simCosmologicalRedshift.
  ///
  /// In en, this message translates to:
  /// **'Cosmological Redshift'**
  String get simCosmologicalRedshift;

  /// No description provided for @simCosmologicalRedshiftLevel.
  ///
  /// In en, this message translates to:
  /// **'Cosmology'**
  String get simCosmologicalRedshiftLevel;

  /// No description provided for @simCosmologicalRedshiftFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simCosmologicalRedshiftFormat;

  /// No description provided for @simCosmologicalRedshiftSummary.
  ///
  /// In en, this message translates to:
  /// **'Distinguish cosmological redshift from Doppler redshift — stretched wavelengths from expanding space.'**
  String get simCosmologicalRedshiftSummary;

  /// No description provided for @simDarkEnergy.
  ///
  /// In en, this message translates to:
  /// **'Dark Energy & Accelerating Expansion'**
  String get simDarkEnergy;

  /// No description provided for @simDarkEnergyLevel.
  ///
  /// In en, this message translates to:
  /// **'Cosmology'**
  String get simDarkEnergyLevel;

  /// No description provided for @simDarkEnergyFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simDarkEnergyFormat;

  /// No description provided for @simDarkEnergySummary.
  ///
  /// In en, this message translates to:
  /// **'Explore how dark energy (Λ) drives the accelerating expansion of the universe.'**
  String get simDarkEnergySummary;

  /// No description provided for @simMagneticReversal.
  ///
  /// In en, this message translates to:
  /// **'Geomagnetic Field Reversal'**
  String get simMagneticReversal;

  /// No description provided for @simMagneticReversalLevel.
  ///
  /// In en, this message translates to:
  /// **'Geophysics'**
  String get simMagneticReversalLevel;

  /// No description provided for @simMagneticReversalFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simMagneticReversalFormat;

  /// No description provided for @simMagneticReversalSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize Earth\'s magnetic field reversals recorded in paleomagnetic data over geological time.'**
  String get simMagneticReversalSummary;

  /// No description provided for @simSeismograph.
  ///
  /// In en, this message translates to:
  /// **'Seismograph Interpretation'**
  String get simSeismograph;

  /// No description provided for @simSeismographLevel.
  ///
  /// In en, this message translates to:
  /// **'Geophysics'**
  String get simSeismographLevel;

  /// No description provided for @simSeismographFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simSeismographFormat;

  /// No description provided for @simSeismographSummary.
  ///
  /// In en, this message translates to:
  /// **'Read seismograph P-wave and S-wave arrivals to determine earthquake epicenter and magnitude.'**
  String get simSeismographSummary;

  /// No description provided for @simContinentalDrift.
  ///
  /// In en, this message translates to:
  /// **'Continental Drift Evidence'**
  String get simContinentalDrift;

  /// No description provided for @simContinentalDriftLevel.
  ///
  /// In en, this message translates to:
  /// **'Geology'**
  String get simContinentalDriftLevel;

  /// No description provided for @simContinentalDriftFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simContinentalDriftFormat;

  /// No description provided for @simContinentalDriftSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore fossil, geological, and paleomagnetic evidence for continental drift and Pangaea.'**
  String get simContinentalDriftSummary;

  /// No description provided for @simGreenhouseGases.
  ///
  /// In en, this message translates to:
  /// **'Greenhouse Gas Comparison'**
  String get simGreenhouseGases;

  /// No description provided for @simGreenhouseGasesLevel.
  ///
  /// In en, this message translates to:
  /// **'Climate Science'**
  String get simGreenhouseGasesLevel;

  /// No description provided for @simGreenhouseGasesFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simGreenhouseGasesFormat;

  /// No description provided for @simGreenhouseGasesSummary.
  ///
  /// In en, this message translates to:
  /// **'Compare the radiative forcing and global warming potential of CO₂, CH₄, N₂O, and other greenhouse gases.'**
  String get simGreenhouseGasesSummary;

  /// No description provided for @simRule110.
  ///
  /// In en, this message translates to:
  /// **'Rule 110 Cellular Automaton'**
  String get simRule110;

  /// No description provided for @simRule110Level.
  ///
  /// In en, this message translates to:
  /// **'Computation Theory'**
  String get simRule110Level;

  /// No description provided for @simRule110Format.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simRule110Format;

  /// No description provided for @simRule110Summary.
  ///
  /// In en, this message translates to:
  /// **'Explore Rule 110 — a Turing-complete one-dimensional cellular automaton with complex emergent patterns.'**
  String get simRule110Summary;

  /// No description provided for @simSchellingSegregation.
  ///
  /// In en, this message translates to:
  /// **'Schelling Segregation Model'**
  String get simSchellingSegregation;

  /// No description provided for @simSchellingSegregationLevel.
  ///
  /// In en, this message translates to:
  /// **'Agent-Based Modeling'**
  String get simSchellingSegregationLevel;

  /// No description provided for @simSchellingSegregationFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simSchellingSegregationFormat;

  /// No description provided for @simSchellingSegregationSummary.
  ///
  /// In en, this message translates to:
  /// **'Model how mild individual preferences can lead to strong residential segregation.'**
  String get simSchellingSegregationSummary;

  /// No description provided for @simDuffingOscillator.
  ///
  /// In en, this message translates to:
  /// **'Duffing Oscillator'**
  String get simDuffingOscillator;

  /// No description provided for @simDuffingOscillatorLevel.
  ///
  /// In en, this message translates to:
  /// **'Chaos Theory'**
  String get simDuffingOscillatorLevel;

  /// No description provided for @simDuffingOscillatorFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simDuffingOscillatorFormat;

  /// No description provided for @simDuffingOscillatorSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore chaos in the periodically-forced nonlinear Duffing oscillator with double-well potential.'**
  String get simDuffingOscillatorSummary;

  /// No description provided for @simBelousovZhabotinsky.
  ///
  /// In en, this message translates to:
  /// **'Belousov-Zhabotinsky Reaction'**
  String get simBelousovZhabotinsky;

  /// No description provided for @simBelousovZhabotinskyLevel.
  ///
  /// In en, this message translates to:
  /// **'Chemical Oscillation'**
  String get simBelousovZhabotinskyLevel;

  /// No description provided for @simBelousovZhabotinskyFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simBelousovZhabotinskyFormat;

  /// No description provided for @simBelousovZhabotinskySummary.
  ///
  /// In en, this message translates to:
  /// **'Simulate the oscillating BZ reaction — a chemical clock producing self-organizing spiral waves.'**
  String get simBelousovZhabotinskySummary;

  /// No description provided for @simCellularRespiration.
  ///
  /// In en, this message translates to:
  /// **'Cellular Respiration'**
  String get simCellularRespiration;

  /// No description provided for @simCellularRespirationLevel.
  ///
  /// In en, this message translates to:
  /// **'Biochemistry'**
  String get simCellularRespirationLevel;

  /// No description provided for @simCellularRespirationFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simCellularRespirationFormat;

  /// No description provided for @simCellularRespirationSummary.
  ///
  /// In en, this message translates to:
  /// **'Trace ATP production through glycolysis, pyruvate oxidation, Krebs cycle, and electron transport chain.'**
  String get simCellularRespirationSummary;

  /// No description provided for @simLogisticGrowth.
  ///
  /// In en, this message translates to:
  /// **'Logistic Population Growth'**
  String get simLogisticGrowth;

  /// No description provided for @simLogisticGrowthLevel.
  ///
  /// In en, this message translates to:
  /// **'Population Ecology'**
  String get simLogisticGrowthLevel;

  /// No description provided for @simLogisticGrowthFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simLogisticGrowthFormat;

  /// No description provided for @simLogisticGrowthSummary.
  ///
  /// In en, this message translates to:
  /// **'Model S-shaped logistic growth with carrying capacity K. dN/dt = rN(1-N/K)'**
  String get simLogisticGrowthSummary;

  /// No description provided for @simCompetitiveExclusion.
  ///
  /// In en, this message translates to:
  /// **'Competitive Exclusion Principle'**
  String get simCompetitiveExclusion;

  /// No description provided for @simCompetitiveExclusionLevel.
  ///
  /// In en, this message translates to:
  /// **'Ecology'**
  String get simCompetitiveExclusionLevel;

  /// No description provided for @simCompetitiveExclusionFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simCompetitiveExclusionFormat;

  /// No description provided for @simCompetitiveExclusionSummary.
  ///
  /// In en, this message translates to:
  /// **'Simulate two species competing for the same ecological niche — Gause\'s competitive exclusion principle.'**
  String get simCompetitiveExclusionSummary;

  /// No description provided for @simCrispr.
  ///
  /// In en, this message translates to:
  /// **'CRISPR Gene Editing'**
  String get simCrispr;

  /// No description provided for @simCrisprLevel.
  ///
  /// In en, this message translates to:
  /// **'Biotechnology'**
  String get simCrisprLevel;

  /// No description provided for @simCrisprFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simCrisprFormat;

  /// No description provided for @simCrisprSummary.
  ///
  /// In en, this message translates to:
  /// **'Animate the CRISPR-Cas9 mechanism: guide RNA targeting, DNA cleavage, and repair outcomes.'**
  String get simCrisprSummary;

  /// No description provided for @simDarkMatter.
  ///
  /// In en, this message translates to:
  /// **'Dark Matter Evidence'**
  String get simDarkMatter;

  /// No description provided for @simDarkMatterLevel.
  ///
  /// In en, this message translates to:
  /// **'Astrophysics'**
  String get simDarkMatterLevel;

  /// No description provided for @simDarkMatterFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simDarkMatterFormat;

  /// No description provided for @simDarkMatterSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore observational evidence for dark matter: rotation curves, gravitational lensing, and CMB.'**
  String get simDarkMatterSummary;

  /// No description provided for @simPulsar.
  ///
  /// In en, this message translates to:
  /// **'Pulsar Timing'**
  String get simPulsar;

  /// No description provided for @simPulsarLevel.
  ///
  /// In en, this message translates to:
  /// **'Astrophysics'**
  String get simPulsarLevel;

  /// No description provided for @simPulsarFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simPulsarFormat;

  /// No description provided for @simPulsarSummary.
  ///
  /// In en, this message translates to:
  /// **'Analyze millisecond pulsar timing — natural cosmic clocks used to detect gravitational waves.'**
  String get simPulsarSummary;

  /// No description provided for @simAsteroidBelt.
  ///
  /// In en, this message translates to:
  /// **'Asteroid Belt & Kirkwood Gaps'**
  String get simAsteroidBelt;

  /// No description provided for @simAsteroidBeltLevel.
  ///
  /// In en, this message translates to:
  /// **'Planetary Science'**
  String get simAsteroidBeltLevel;

  /// No description provided for @simAsteroidBeltFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simAsteroidBeltFormat;

  /// No description provided for @simAsteroidBeltSummary.
  ///
  /// In en, this message translates to:
  /// **'Visualize asteroid belt orbital resonance gaps created by Jupiter\'s gravitational influence.'**
  String get simAsteroidBeltSummary;

  /// No description provided for @simCosmicDistanceLadder.
  ///
  /// In en, this message translates to:
  /// **'Cosmic Distance Ladder'**
  String get simCosmicDistanceLadder;

  /// No description provided for @simCosmicDistanceLadderLevel.
  ///
  /// In en, this message translates to:
  /// **'Observational Astronomy'**
  String get simCosmicDistanceLadderLevel;

  /// No description provided for @simCosmicDistanceLadderFormat.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get simCosmicDistanceLadderFormat;

  /// No description provided for @simCosmicDistanceLadderSummary.
  ///
  /// In en, this message translates to:
  /// **'Explore the chain of distance measurement methods: parallax → Cepheids → supernovae → Hubble\'s law.'**
  String get simCosmicDistanceLadderSummary;

  /// No description provided for @updateRequired.
  ///
  /// In en, this message translates to:
  /// **'Update Required'**
  String get updateRequired;

  /// No description provided for @updateDescription.
  ///
  /// In en, this message translates to:
  /// **'A new version of Visual Science Lab is available. Please update to continue using the app.'**
  String get updateDescription;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get updateNow;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @currentVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Current version'**
  String get currentVersionLabel;

  /// No description provided for @requiredVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Required version'**
  String get requiredVersionLabel;

  /// No description provided for @updateBenefits.
  ///
  /// In en, this message translates to:
  /// **'New simulations, bug fixes, and performance improvements!'**
  String get updateBenefits;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
