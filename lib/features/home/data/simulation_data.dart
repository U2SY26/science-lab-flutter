import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// Simulation category with icon
enum SimCategory {
  all(Icons.apps),
  physics(Icons.speed),
  math(Icons.functions),
  chaos(Icons.grain),
  ai(Icons.psychology),
  chemistry(Icons.science);

  final IconData icon;
  const SimCategory(this.icon);

  String getLabel(AppLocalizations l10n) {
    switch (this) {
      case SimCategory.all:
        return l10n.categoryAll;
      case SimCategory.physics:
        return l10n.categoryPhysics;
      case SimCategory.math:
        return l10n.categoryMath;
      case SimCategory.chaos:
        return l10n.categoryChaos;
      case SimCategory.ai:
        return l10n.categoryAI;
      case SimCategory.chemistry:
        return l10n.categoryChemistry;
    }
  }
}

/// Simulation metadata
class SimulationInfo {
  final String simId;
  final SimCategory category;
  final int difficulty;
  final String Function(AppLocalizations) getTitle;
  final String Function(AppLocalizations) getLevel;
  final String Function(AppLocalizations) getFormat;
  final String Function(AppLocalizations) getSummary;

  const SimulationInfo({
    required this.simId,
    required this.category,
    required this.getTitle,
    required this.getLevel,
    required this.getFormat,
    required this.getSummary,
    this.difficulty = 2,
  });
}

/// Get all simulations with localized strings
List<SimulationInfo> getSimulations() => [
  SimulationInfo(
    simId: "pendulum",
    category: SimCategory.physics,
    difficulty: 1,
    getTitle: (l) => l.simPendulum,
    getLevel: (l) => l.simPendulumLevel,
    getFormat: (l) => l.simPendulumFormat,
    getSummary: (l) => l.simPendulumSummary,
  ),
  SimulationInfo(
    simId: "wave",
    category: SimCategory.physics,
    difficulty: 2,
    getTitle: (l) => l.simWave,
    getLevel: (l) => l.simWaveLevel,
    getFormat: (l) => l.simWaveFormat,
    getSummary: (l) => l.simWaveSummary,
  ),
  SimulationInfo(
    simId: "gravity",
    category: SimCategory.physics,
    difficulty: 3,
    getTitle: (l) => l.simGravity,
    getLevel: (l) => l.simGravityLevel,
    getFormat: (l) => l.simGravityFormat,
    getSummary: (l) => l.simGravitySummary,
  ),
  SimulationInfo(
    simId: "formula",
    category: SimCategory.math,
    difficulty: 1,
    getTitle: (l) => l.simFormula,
    getLevel: (l) => l.simFormulaLevel,
    getFormat: (l) => l.simFormulaFormat,
    getSummary: (l) => l.simFormulaSummary,
  ),
  SimulationInfo(
    simId: "lorenz",
    category: SimCategory.chaos,
    difficulty: 2,
    getTitle: (l) => l.simLorenz,
    getLevel: (l) => l.simLorenzLevel,
    getFormat: (l) => l.simLorenzFormat,
    getSummary: (l) => l.simLorenzSummary,
  ),
  SimulationInfo(
    simId: "double-pendulum",
    category: SimCategory.chaos,
    difficulty: 2,
    getTitle: (l) => l.simDoublePendulum,
    getLevel: (l) => l.simDoublePendulumLevel,
    getFormat: (l) => l.simDoublePendulumFormat,
    getSummary: (l) => l.simDoublePendulumSummary,
  ),
  SimulationInfo(
    simId: "gameoflife",
    category: SimCategory.math,
    difficulty: 1,
    getTitle: (l) => l.simGameOfLife,
    getLevel: (l) => l.simGameOfLifeLevel,
    getFormat: (l) => l.simGameOfLifeFormat,
    getSummary: (l) => l.simGameOfLifeSummary,
  ),
  SimulationInfo(
    simId: "set",
    category: SimCategory.math,
    difficulty: 1,
    getTitle: (l) => l.simSet,
    getLevel: (l) => l.simSetLevel,
    getFormat: (l) => l.simSetFormat,
    getSummary: (l) => l.simSetSummary,
  ),
  SimulationInfo(
    simId: "sorting",
    category: SimCategory.ai,
    difficulty: 2,
    getTitle: (l) => l.simSorting,
    getLevel: (l) => l.simSortingLevel,
    getFormat: (l) => l.simSortingFormat,
    getSummary: (l) => l.simSortingSummary,
  ),
  SimulationInfo(
    simId: "neuralnet",
    category: SimCategory.ai,
    difficulty: 3,
    getTitle: (l) => l.simNeuralNet,
    getLevel: (l) => l.simNeuralNetLevel,
    getFormat: (l) => l.simNeuralNetFormat,
    getSummary: (l) => l.simNeuralNetSummary,
  ),
  SimulationInfo(
    simId: "gradient",
    category: SimCategory.ai,
    difficulty: 2,
    getTitle: (l) => l.simGradient,
    getLevel: (l) => l.simGradientLevel,
    getFormat: (l) => l.simGradientFormat,
    getSummary: (l) => l.simGradientSummary,
  ),
  SimulationInfo(
    simId: "mandelbrot",
    category: SimCategory.math,
    difficulty: 2,
    getTitle: (l) => l.simMandelbrot,
    getLevel: (l) => l.simMandelbrotLevel,
    getFormat: (l) => l.simMandelbrotFormat,
    getSummary: (l) => l.simMandelbrotSummary,
  ),
  SimulationInfo(
    simId: "fourier",
    category: SimCategory.math,
    difficulty: 3,
    getTitle: (l) => l.simFourier,
    getLevel: (l) => l.simFourierLevel,
    getFormat: (l) => l.simFourierFormat,
    getSummary: (l) => l.simFourierSummary,
  ),
  SimulationInfo(
    simId: "quadratic",
    category: SimCategory.math,
    difficulty: 1,
    getTitle: (l) => l.simQuadratic,
    getLevel: (l) => l.simQuadraticLevel,
    getFormat: (l) => l.simQuadraticFormat,
    getSummary: (l) => l.simQuadraticSummary,
  ),
  SimulationInfo(
    simId: "vector",
    category: SimCategory.math,
    difficulty: 2,
    getTitle: (l) => l.simVector,
    getLevel: (l) => l.simVectorLevel,
    getFormat: (l) => l.simVectorFormat,
    getSummary: (l) => l.simVectorSummary,
  ),
  SimulationInfo(
    simId: "projectile",
    category: SimCategory.physics,
    difficulty: 1,
    getTitle: (l) => l.simProjectile,
    getLevel: (l) => l.simProjectileLevel,
    getFormat: (l) => l.simProjectileFormat,
    getSummary: (l) => l.simProjectileSummary,
  ),
  SimulationInfo(
    simId: "spring",
    category: SimCategory.physics,
    difficulty: 2,
    getTitle: (l) => l.simSpring,
    getLevel: (l) => l.simSpringLevel,
    getFormat: (l) => l.simSpringFormat,
    getSummary: (l) => l.simSpringSummary,
  ),
  SimulationInfo(
    simId: "activation",
    category: SimCategory.ai,
    difficulty: 2,
    getTitle: (l) => l.simActivation,
    getLevel: (l) => l.simActivationLevel,
    getFormat: (l) => l.simActivationFormat,
    getSummary: (l) => l.simActivationSummary,
  ),
  SimulationInfo(
    simId: "logistic",
    category: SimCategory.chaos,
    difficulty: 2,
    getTitle: (l) => l.simLogistic,
    getLevel: (l) => l.simLogisticLevel,
    getFormat: (l) => l.simLogisticFormat,
    getSummary: (l) => l.simLogisticSummary,
  ),
  SimulationInfo(
    simId: "collision",
    category: SimCategory.physics,
    difficulty: 2,
    getTitle: (l) => l.simCollision,
    getLevel: (l) => l.simCollisionLevel,
    getFormat: (l) => l.simCollisionFormat,
    getSummary: (l) => l.simCollisionSummary,
  ),
  SimulationInfo(
    simId: "kmeans",
    category: SimCategory.ai,
    difficulty: 2,
    getTitle: (l) => l.simKMeans,
    getLevel: (l) => l.simKMeansLevel,
    getFormat: (l) => l.simKMeansFormat,
    getSummary: (l) => l.simKMeansSummary,
  ),
  SimulationInfo(
    simId: "prime",
    category: SimCategory.math,
    difficulty: 1,
    getTitle: (l) => l.simPrime,
    getLevel: (l) => l.simPrimeLevel,
    getFormat: (l) => l.simPrimeFormat,
    getSummary: (l) => l.simPrimeSummary,
  ),
  SimulationInfo(
    simId: "threebody",
    category: SimCategory.chaos,
    difficulty: 3,
    getTitle: (l) => l.simThreeBody,
    getLevel: (l) => l.simThreeBodyLevel,
    getFormat: (l) => l.simThreeBodyFormat,
    getSummary: (l) => l.simThreeBodySummary,
  ),
  SimulationInfo(
    simId: "decision-tree",
    category: SimCategory.ai,
    difficulty: 2,
    getTitle: (l) => l.simDecisionTree,
    getLevel: (l) => l.simDecisionTreeLevel,
    getFormat: (l) => l.simDecisionTreeFormat,
    getSummary: (l) => l.simDecisionTreeSummary,
  ),
  SimulationInfo(
    simId: "svm",
    category: SimCategory.ai,
    difficulty: 2,
    getTitle: (l) => l.simSVM,
    getLevel: (l) => l.simSVMLevel,
    getFormat: (l) => l.simSVMFormat,
    getSummary: (l) => l.simSVMSummary,
  ),
  SimulationInfo(
    simId: "pca",
    category: SimCategory.ai,
    difficulty: 2,
    getTitle: (l) => l.simPCA,
    getLevel: (l) => l.simPCALevel,
    getFormat: (l) => l.simPCAFormat,
    getSummary: (l) => l.simPCASummary,
  ),
  SimulationInfo(
    simId: "electromagnetic",
    category: SimCategory.physics,
    difficulty: 2,
    getTitle: (l) => l.simElectromagnetic,
    getLevel: (l) => l.simElectromagneticLevel,
    getFormat: (l) => l.simElectromagneticFormat,
    getSummary: (l) => l.simElectromagneticSummary,
  ),
  SimulationInfo(
    simId: "graph-theory",
    category: SimCategory.math,
    difficulty: 2,
    getTitle: (l) => l.simGraphTheory,
    getLevel: (l) => l.simGraphTheoryLevel,
    getFormat: (l) => l.simGraphTheoryFormat,
    getSummary: (l) => l.simGraphTheorySummary,
  ),
];
