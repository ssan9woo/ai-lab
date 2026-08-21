# Flutter 자연어 UI 검증 CLI

## 이게 뭔가

Kane CLI(자연어로 브라우저 플로우를 검증하는 도구)의 문제의식 — "AI가 코드는 빨리 짜는데 검증은 여전히 수동"이라는 갭 — 을 Flutter/모바일에 옮겨서 작게 실험한다. 자연어 지시를 받아 Flutter 위젯 트리를 assert하는 로컬 미니 CLI를 만들고, 이 구조가 실제로 동작하는지 직접 손으로 확인하는 것이 1차 목적. 제품화가 목표가 아니라 "자연어 → 검증 가능한 액션"이라는 파이프라인을 체득하는 것.

**1차 실험 스코프**: 정확한 지시(로그인 → 메인화면 진입, 메인화면 내 기능 하나) 검증까지만. 애매하거나 모호한 표현("그 초록 버튼 눌러줘" 같은 자유도 높은 지시)에 대한 견고성 실험은 **1차 실험이 끝난 뒤 별도로 진행** (아래 Out of Scope 참고).

## 진행 상황

- [x] 테스트 대상 Flutter 앱 스캐폴딩 — 로그인 화면(하드코딩 계정 + 모킹 API + accessToken/refreshToken) + 메인 화면(할 일 리스트, 체크박스로 완료 상태 토글)
- [x] `integration_test` 패키지 세팅 확인 (실기기/에뮬레이터에서 구동)
- [x] 고정 action DSL(JSON 스키마) 정의 — `enterText`/`tap`/`expectVisible`/`expectChecked`/`expectUnchecked`/`expectText` 6개 액션 타입, Dart 모델(`lib/verify/action.dart`) + JSON Schema(`docs/action_dsl.schema.json`) 확정
- [x] "자연어 문장 → action DSL JSON" 파싱 구현 — 별도 API 키 없이 로그인된 **Claude Code CLI(`claude -p --json-schema`)를 shell-out**해서 구조화된 출력 강제 (`lib/verify/schema.dart`, `lib/verify/nl_parser.dart`, `bin/parse_action_plan.dart`)
- [x] DSL을 실제로 실행하는 Dart 러너 작성 — `runActionPlan()`(`lib/verify/runner.dart`)이 액션 타입별로 `tester.tap()`/`tester.enterText()`/위젯 상태 확인으로 매핑, 스텝별 pass/fail 격리 기록. iOS 시뮬레이터에서 로그인+체크박스 토글 플랜, 존재하지 않는 타겟 실패 플랜 모두 검증
- [ ] 결과 출력 — 터미널 요약(pass/fail, 소요시간) + 로컬 evidence 폴더(스텝별 스크린샷, 실행 액션 로그)
- [ ] 로그인 플로우 + 메인 기능 플로우, 각각 다른 문장 표현(같은 의도, 다른 어휘)으로 여러 번 테스트 — 동일 DSL로 수렴하는지 확인
- [ ] 일부러 틀린/실패해야 하는 지시로 fail 케이스도 확인

## Notes

### 왜 이 구조로 하는가

Kane CLI 등 상용 도구의 "개떡같이 말해도 찰떡같이 알아듣는" 능력은 마법이 아니라 **자연어 → 액션 매핑 레이어에 얼마나 많은 엔지니어링(다단계 요소 해석, self-healing, 상태 추적, 축적된 로그 기반 튜닝)을 쌓았는지**의 문제로 파악됨. 이 실험은 그 레이어를 의도적으로 얇게(1회 결정론적 매핑) 만들어서 최소 구조로 시작한다.

- **입력**: Kane과 동일하게 자유 형식 자연어 그대로 받음 (제약 없음)
- **출력(LLM 산출물)**: 고정된 소수의 action 타입(JSON)으로만 강제 — 파싱 유연성과 실행 신뢰성을 분리
- **위젯 트리 접근**: Flutter는 `flutter_test`/`integration_test`의 `find.text()`, `find.byKey()` 등으로 위젯 트리에 타입 안전하게 접근 가능 — 웹 DOM/모바일 accessibility tree보다 selector 불안정성 문제를 상당 부분 우회할 수 있는 지점. NLP-to-vision(스크린샷 기반 인식) 같은 무거운 방식은 필요 없음.

### 비교 대상 도구 (참고용, 직접 재사용 아님)

- **Kane CLI** (LambdaTest/TestMu AI) — 웹 브라우저 대상, 로컬 CLI + 클라우드 대시보드 구독 모델. 로컬 실행도 계정 인증 필수.
- **Maestro** — 모바일 CLI, YAML 기반(자연어 아님)이지만 accessibility tree를 직접 읽어 selector 없이 동작 — 구조적으로 가장 가까운 오픈소스 비교 대상.
- **Panto AI / Autify Aximo / testRigor** — 자연어 기반 모바일 테스팅 SaaS. 대부분 클라우드/실기기 팜 전제, 로컬 CLI 성격 아님.

### 파이프라인

```
[자유 형식 자연어] → LLM 파싱(구조화 출력) → [고정 action DSL JSON] → Dart 러너 실행(integration_test) → [pass/fail 요약 + evidence]
```

## Out of Scope (1차 실험에서 하지 않음)

- 클라우드/계정/대시보드 연동
- Vision 기반(스크린샷) 요소 인식
- 애매한/모호한 표현에 대한 견고성 — **2차 실험으로 `IMPROVE.md`에 별도 작성 예정**
- Self-healing, 다단계 에이전트 루프(재시도, 상태 추적)
- 액션 타입/스키마의 폭 확장 (넓히는 건 1차 완료 후 필요성 확인하고 진행)
