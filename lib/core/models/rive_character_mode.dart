/// Rive 캐릭터 애니메이션 모드
///
/// State Machine의 'mode' Number input에 매핑:
/// idle=0, listening=1, thinking=2, speaking=3
enum RiveCharacterMode {
  idle, // 0 — 대기: 부드러운 호흡/흔들림 루프
  listening, // 1 — 듣기: 앞으로 살짝 기울임
  thinking, // 2 — 생각: 위/옆 바라보기, 점 애니메이션
  speaking, // 3 — 말하기: 리드미컬 동작 (립싱크 없음)
}
