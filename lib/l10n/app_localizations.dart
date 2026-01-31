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
  /// **'Simulate pendulum motion based on string length and gravity.'**
  String get simPendulumSummary;

  /// No description provided for @simWave.
  ///
  /// In en, this message translates to:
  /// **'Double Slit Interference'**
  String get simWave;

  /// No description provided for @simWaveLevel.
  ///
  /// In en, this message translates to:
  /// **'Physics Engine'**
  String get simWaveLevel;

  /// No description provided for @simWaveFormat.
  ///
  /// In en, this message translates to:
  /// **'Simulation'**
  String get simWaveFormat;

  /// No description provided for @simWaveSummary.
  ///
  /// In en, this message translates to:
  /// **'Observe interference patterns from two wave sources.'**
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
  /// **'Visualize spacetime curvature caused by mass in 3D grid.'**
  String get simGravitySummary;

  /// No description provided for @simFormula.
  ///
  /// In en, this message translates to:
  /// **'Math Graph'**
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
  /// **'Enter math functions to generate real-time graphs.'**
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
  /// **'Chaos system visualizing the butterfly effect.'**
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
  /// **'Two connected pendulums demonstrating chaos theory.'**
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
  /// **'Cells evolve following rules of survival, birth, and death.'**
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
  /// **'Visualize union, intersection, difference with Venn diagrams.'**
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
  /// **'Compare bubble, quick, merge sort step by step.'**
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
  /// **'Visualize forward propagation, backpropagation, weight learning.'**
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
  /// **'Visualize gradient descent convergence to minimize loss function.'**
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
  /// **'Explore fractals of infinite complexity: zₙ₊₁ = zₙ² + c'**
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
  /// **'Decompose complex waveforms into circular motions (epicycles).'**
  String get simFourierSummary;

  /// No description provided for @simQuadratic.
  ///
  /// In en, this message translates to:
  /// **'Quadratic Vertex'**
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
  /// **'Adjust a, b, c and observe vertex movement.'**
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
  /// **'Visualize dot product, angle, projection of vectors.'**
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
  /// **'Simulate parabolic motion based on angle and velocity.'**
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
  /// **'Observe damped harmonic oscillation of connected springs.'**
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
  /// **'Compare ReLU, Sigmoid, GELU and other neural network activations.'**
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
  /// **'Observe chaos emergence through bifurcation diagram and Feigenbaum constant.'**
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
  /// **'Visualize elastic/inelastic collisions with momentum and energy conservation.'**
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
  /// **'Visualize unsupervised learning clustering data into K groups.'**
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
  /// **'Visualize the ancient Greek prime number discovery algorithm step by step.'**
  String get simPrimeSummary;

  /// No description provided for @simThreeBody.
  ///
  /// In en, this message translates to:
  /// **'Three Body Problem'**
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
  /// **'Gravitational interaction of 3 bodies - chaotic system with no analytical solution.'**
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
  /// **'Classification algorithm that splits data by minimizing Gini impurity.'**
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
  /// **'Support Vector Machine finding maximum margin decision boundary.'**
  String get simSVMSummary;

  /// No description provided for @simPCA.
  ///
  /// In en, this message translates to:
  /// **'PCA Analysis'**
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
  /// **'Dimensionality reduction by finding directions of maximum variance.'**
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
  /// **'Visualize electric field and field lines around point charges.'**
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
  /// **'Visualize BFS and DFS graph traversal processes.'**
  String get simGraphTheorySummary;

  /// No description provided for @simBohrModel.
  ///
  /// In en, this message translates to:
  /// **'Bohr Model'**
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
  /// **'Visualize electron orbits and energy levels in atoms.'**
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
  /// **'Explore ionic, covalent, and metallic bonds.'**
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
  /// **'Learn electron orbital filling order and configuration.'**
  String get simElectronConfigSummary;

  /// No description provided for @simEquationBalance.
  ///
  /// In en, this message translates to:
  /// **'Equation Balancing'**
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
  /// **'Practice balancing chemical equations step by step.'**
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
  /// **'Understand hydrogen bonds and their effects on properties.'**
  String get simHydrogenBondingSummary;

  /// No description provided for @simLewisStructure.
  ///
  /// In en, this message translates to:
  /// **'Lewis Structure'**
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
  /// **'Draw and understand Lewis dot structures of molecules.'**
  String get simLewisStructureSummary;

  /// No description provided for @simMolecularGeometry.
  ///
  /// In en, this message translates to:
  /// **'Molecular Geometry'**
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
  /// **'Explore VSEPR theory and 3D molecular shapes.'**
  String get simMolecularGeometrySummary;

  /// No description provided for @simOxidationReduction.
  ///
  /// In en, this message translates to:
  /// **'Oxidation-Reduction'**
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
  /// **'Learn electron transfer in redox reactions.'**
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
  /// **'Find optimal path using A* search algorithm with heuristics.'**
  String get simAStarSummary;
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
