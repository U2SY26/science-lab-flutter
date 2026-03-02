// XR 3D 뷰어를 지원하는 시뮬레이션 ID 레지스트리
// 웹 data/xrSimMap.ts와 동기화 (36 native3d + 10 hybrid = 46 total)

const String kXrBaseUrl = 'https://3dweb-rust.vercel.app/xr-test?sim=';

/// XR 지원 simId 목록
const Set<String> kXrSimIds = {
  // Native 3D (36)
  'double-pendulum',
  'lorenz',
  'solar-system',
  'bloch-sphere',
  'wave-interference-3d',
  'bohr-model-3d',
  'neural-network-3d',
  'spacetime-curvature',
  'cell-division-3d',
  'math-3d-graph',
  'rossler-attractor',
  'three-body',
  'henon-attractor',
  'magnetic-field',
  'lorentz-force',
  'electromagnetic-wave',
  'em-spectrum',
  'heat-equation',
  'navier-stokes',
  'schrodinger-equation',
  'n-body-gravity',
  'kepler-orbits',
  'gravitational-lensing',
  'gravitational-waves',
  'molecular-geometry',
  'crystal-structure',
  'dna-replication',
  'protein-folding',
  'hydrogen-orbital',
  'kinetic-theory',
  'ideal-gas',
  'quantum-tunneling',
  'klein-bottle',
  'mobius-strip',
  'mandelbrot-3d',
  'julia-set-3d',
  // Hybrid (10)
  'pendulum',
  'wave',
  'gravity',
  'mandelbrot',
  'fourier',
  'electromagnetic',
  'projectile',
  'brownian-motion',
  'damped-oscillator',
  'bohr-model',
};

/// simId가 XR 3D 뷰어를 지원하는지 확인
bool hasXrSupport(String simId) => kXrSimIds.contains(simId);

/// simId에 대한 XR 뷰어 URL 생성
String getXrViewerUrl(String simId) => '$kXrBaseUrl$simId';
