# Write & Record - AI Input Pack

이 폴더는 iOS 앱 생성 전 구현 AI에게 넣을 압축 문서 세트다.

권장 입력 순서:
1. `01_PRODUCT_SPEC.md`
2. `02_DESIGN_SPEC.md`
3. `03_FLOWCHARTS.md`
4. `04_AI_BUILD_PROMPT.md`
5. `05_FUNCTIONAL_SPEC.md`
6. `06_DISTRIBUTION_AND_RELEASE_PLAN.md`

최소 입력:
- 시간이 없으면 `04_AI_BUILD_PROMPT.md`를 먼저 넣고, 이어서 1~3번 문서를 첨부한다.
- 실제 배포/테스트까지 고려하면 5~6번 문서도 반드시 넣는다.

구현 목표:
- Repov 스타일의 "일상 블로그형 기록 앱"을 그대로 베끼는 것이 아니라, 날짜/카테고리/사진/카드/라이브러리 구조를 가진 독립 앱 "Write & Record"의 MVP를 만든다.

중요 우선순위:
- P0: 온보딩, 캘린더, 카테고리 선택, 기록 작성/저장/상세, 로컬 데이터 유지.
- P1: 날짜별 사진 필터, 타임라인/갤러리, 커스텀 카테고리, 검색.
- P2: 장소/컬렉션, 기록 카드, 공유.
- P3: 소셜, 동기화, AI 기능.

절대 놓치면 안 되는 결정:
- 기록은 `Entry` 단일 모델 중심.
- 카테고리는 enum 고정이 아니라 데이터로 관리.
- 사진 권한이 없어도 기록 저장 가능.
- 기본 공개 범위는 private.
- 저장 실패 시 draft를 잃지 않음.
- 개인 실사용 전 데이터 export/backup 전략을 마련한다.
- 친구 테스트는 TestFlight 전환 가능성을 고려해 BetaRelease 설정을 분리한다.
