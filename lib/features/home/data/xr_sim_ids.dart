// XR 3D 뷰어를 지원하는 시뮬레이션 ID 레지스트리
// 웹 data/xrSimMap.ts와 동기화
// 86 native3d (36 base + 12 premium + 50 wave3) + 10 hybrid = 108 total

const String kXrBaseUrl = 'https://3dweb-rust.vercel.app/xr-test?sim=';

/// XR 지원 simId 목록
const Set<String> kXrSimIds = {
  // ── Base Native 3D (36) ──
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

  // ── Hybrid (10) ──
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

  // ── Pro XR Wave 1 (6) ──
  'solar-system-pro',
  'black-hole-pro',
  'lorenz-pro',
  'hydrogen-orbital-pro',
  'dna-helix-pro',
  'electric-field-pro',

  // ── Pro XR Wave 2 (6) ──
  'gravitational-waves-pro',
  'quantum-tunneling-pro',
  'neural-network-pro',
  'wave-interference-pro',
  'crystal-structure-pro',
  'plate-tectonics-pro',

  // ── Wave 3 Expansion: Astronomy (8) ── ★ 화려한 우주 시각화
  'asteroid-belt',
  'binary-star',
  'comet-orbit',        // XR전용
  'exoplanet-transit',
  'galaxy',             // XR전용 — 나선 은하 파티클
  'stellar-evolution',
  'neutron-star',
  'supernova',          // Flutter simId (웹: supernova-dynamics)

  // ── Wave 3 Expansion: Earth Science (8) ──
  'atmosphere-layers',
  'earthquake-waves',
  'glacier-dynamics',   // XR전용
  'mantle-convection',  // XR전용
  'ocean-currents',
  'plate-tectonics',
  'volcano-types',
  'magnetic-field-earth', // XR전용

  // ── Wave 3 Expansion: Relativity (6) ── ★ 시공간 왜곡 시각화
  'black-hole',
  'frame-dragging',
  'light-cone',
  'schwarzschild',
  'twin-paradox',
  'wormhole',           // XR전용 — 시공간 터널

  // ── Wave 3 Expansion: Physics (10) ──
  'angular-momentum',
  'coulomb-law',
  'dipole-field',       // XR전용
  'electric-field-lines', // XR전용
  'fluid-flow',         // XR전용
  'gyroscope',
  'pendulum-wave',      // XR전용
  'roller-coaster',
  'sound-waves',
  'standing-wave',

  // ── Wave 3 Expansion: Quantum (8) ── ★ 양자 확률 구름
  'electron-cloud',     // XR전용 — 전자 확률 분포
  'entanglement',       // Flutter simId (웹: quantum-entanglement)
  'particle-in-box',
  'quantum-dot',        // XR전용
  'quantum-harmonic',
  'spin-visualization', // XR전용
  'stern-gerlach',
  'zeeman-effect',

  // ── Wave 3 Expansion: Chemistry+Bio (8) ── ★ 분자/생명 구조
  'chemical-bonding',
  'crystal-field-theory', // XR전용
  'ionic-crystal',      // XR전용
  'molecular-orbital',  // XR전용
  'water-molecule',     // XR전용 — H₂O 결합 구조
  'cell-structure',     // XR전용
  'virus-structure',    // XR전용 — 바이러스 캡시드
  'torus-knot',         // XR전용 — 수학적 매듭
  'hyperbolic-geometry',
  'tidal-forces',
};

/// simId가 XR 3D 뷰어를 지원하는지 확인
bool hasXrSupport(String simId) => kXrSimIds.contains(simId);

/// simId에 대한 XR 뷰어 URL 생성
/// &screenshot=true → XRViewerModeProvider 사용 (100vh 캔버스, HUD/광고 없음)
/// 모바일 WebView에서 캔버스 높이 오류 및 스크립트 간섭 방지
String getXrViewerUrl(String simId) => '$kXrBaseUrl$simId&screenshot=true';
