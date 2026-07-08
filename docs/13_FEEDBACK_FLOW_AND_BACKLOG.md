# Write & Record - Feedback Flow and Backlog

목적: "피드백 보내기"를 눌렀을 때의 동작을 확정하고, 현재까지 구현을 기준으로 남은 작업을 우선순위와 함께 정리한다.

기준일: 2026-07-08. 작성: 구현 AI (docs/05 14장, docs/06, docs/12 기반).

## 1. 피드백 플로우 결정

### 결정 요약

- 백엔드가 없는 현재 단계에서는 **인앱 피드백 폼 -> 메일 앱(mailto)** 을 기본 경로로 한다 (docs/05 14장의 "No backend option").
- 메일 앱이 설정되지 않은 기기를 위해 **공유 시트 fallback**을 함께 제공한다.
- Supabase/Firebase 테이블 수집은 친구 베타 규모가 커지면 도입한다 (P2).

### 왜 mailto인가

- 서버/개인정보 처리방침 없이 바로 쓸 수 있다.
- 피드백이 개발자 개인 메일함에 도착하므로 소수 친구 테스트 규모에 충분하다.
- 진단 정보를 본문에 미리 채워 재현에 필요한 정보를 놓치지 않는다.

### 플로우

```text
설정(내 공간) -> 피드백 보내기
-> FeedbackView (bottom sheet)
   - 유형 선택: 버그 / 요청 / 헷갈림 / 기타
   - 내용 입력 (필수)
   - 진단 정보 포함 토글 (기본 on, 내용 미리보기 제공)
-> "메일로 보내기" (mailto: 수신자/제목/본문 자동 구성)
-> 메일 앱이 없으면 "공유하기로 보내기" 안내 (share sheet)
```

### 진단 정보 payload

포함:
- 앱 버전/빌드, 빌드 모드 (Debug/PersonalRelease/BetaRelease)
- iOS 버전, 기기 모델
- 피드백 유형

포함 금지 (docs/05 15장 privacy):
- 기록 제목/본문/사진/장소/링크
- 사용자 식별 정보(이메일 자동 수집 금지 — 회신용 메일은 사용자가 메일 앱에서 직접 보냄)

### 수신 주소

- `FeedbackConfig.recipient` 상수로 분리 (`Features/Settings/FeedbackView.swift`).
- 기본값은 개발자 메일. 배포 전 전용 주소(예: writeandrecord.feedback@...) 개설 권장.

### 노출 조건

- FeatureFlags.enableFeedback: Debug, BetaRelease에서만 on (기존 정책 유지).
- StoreRelease에서는 App Store 리뷰/지원 URL로 대체 예정.

## 2. 남은 작업 백로그

### 즉시 (이번 사이클에서 처리)

- [x] 인앱 피드백 폼 (유형/내용/진단 토글/mailto/share fallback) — 이 브랜치에서 구현.
- [x] 월간 이미지 캘린더 export — `feat/monthly-calendar-export`.
- [x] 초대 링크 복사/공유 시트 — `feat/invite-share-options`.

### P1 (실사용 안정화)

- [x] 알림 실제 구현: daily reminder 시간 설정 + local notification 스케줄 — `feat/daily-reminder`.
- [x] JSON import/restore — `feat/data-import`.
- [ ] draft 복원 시나리오 QA: 앱 강제 종료 후 재실행 테스트 (docs/08 체크리스트). 실기기에서 수동 확인 필요.
- [x] 위시리스트 분류 (docs/12 J) — `feat/wishlist-types` (보고/읽고/가고/먹고/사고/하고 싶은).
- [x] 스와이프 뒤로가기 전 화면 적용 — `feat/swipe-back-gesture`.

### P2 (표현/편의)

- [x] 인용구(quote) 저장 강화 + 인용구 컬렉션 — `feat/quote-collection` (책 인용문/가사/기억나는 대사 → 인용구 모아보기).
- [ ] 인용구 위젯 / 내 오늘 기록 위젯 (docs/12 D·E): **WidgetKit extension 타깃 + App Group 서명 설정이 필요해 Xcode GUI에서 생성 권장.** 데이터 소스(quoteEntries)는 준비됨.
- [x] 앱 안 정보 검색 (docs/12 A) — `feat/info-search`. 키가 필요 없는 iTunes Search API로 영화/책/음악. 한국 도서 커버리지가 부족하면 알라딘/카카오책 API로 교체 검토.
- [x] 장소 지도 보기 (docs/12 I) — 직접 구현 완료 (codex/place-search-selection).
- [ ] iPad layout 대응 (docs/12 M): 실기기/시뮬레이터 검증 없이 진행 시 회귀 위험이 있어 Xcode 확보 후 진행.
- [ ] 카카오톡 전용 초대 버튼: KakaoTalk SDK + 앱 키 필요. 현재는 시스템 공유 시트로 카카오톡 선택 가능. universal link 도메인도 함께 필요.
- [ ] 초대 링크 실동작: universal link 도메인 + 초대 수락 화면 (현재 URL은 placeholder).

### P3 (소셜/동기화 — 서버 필요)

- [ ] 소셜 백엔드 연동: SocialRepository 내부를 Supabase/Firebase 구현으로 교체 (protocol 유지).
- [ ] 공개 프로필 편집, 내 공개 기록 목록 (docs/10 P1).
- [ ] 소셜 알림 (친구 요청/수락).
- [ ] iCloud 또는 서버 동기화 (docs/12 L — export/import가 먼저).
- [ ] 피드백 백엔드 수집 전환 (Supabase 테이블 + 개인정보 redaction).

### 출시 준비 (docs/06)

- [x] 앱 아이콘: 세이지·린넨 팔레트의 기록 카드 아이콘 생성 — `feat/app-icon`. (마음에 안 들면 교체: `Assets.xcassets/AppIcon.appiconset/icon-1024.png`)
- [ ] TestFlight 전환 시: Apple Developer Program 가입, App Store Connect 레코드, 개인정보 영양성분표 초안.
- [ ] 개인정보 처리방침 URL (소셜 공개 데이터 설명 포함 — docs/10 2장 release gate).
- [ ] crash reporting hook (BetaRelease, FeatureFlags.enableCrashReporting 게이트 이미 존재).

## 3. 이번 구현에서 확인된 기술 부채

- 소셜 mock 데이터가 Debug 전용 seed라 BetaRelease에서 소셜 탭이 빈 상태다. 서버 연동 전 베타에 소셜을 열려면 flag를 끄거나 서버를 붙여야 한다.
- Entry.visibility는 optional로 추가되어 기존 데이터와 호환되지만, export JSON schemaVersion은 아직 1이다. import 구현 시 버전 분기를 넣을 것.
- 캘린더가 세로 100%를 차지하므로 iPhone SE에서 셀 높이가 작아질 수 있다. 실기기 확인 필요 (docs/09 11장 체크 항목).
