# Write & Record - AI Input Pack

이 폴더는 iOS 앱 생성 전 구현 AI에게 넣을 압축 문서 세트다.

권장 입력 순서:
1. `01_PRODUCT_SPEC.md`
2. `02_DESIGN_SPEC.md`
3. `03_FLOWCHARTS.md`
4. `04_AI_BUILD_PROMPT.md`
5. `05_FUNCTIONAL_SPEC.md`
6. `06_DISTRIBUTION_AND_RELEASE_PLAN.md`
7. `07_CORE_STRUCTURE_DATA_PRIVACY_BACKUP.md`
8. `08_QA_BETA_TEST_PLAN.md`
9. `09_VISUAL_DIRECTION_AND_UI_CONCEPT.md`
10. `10_SOCIAL_FEATURE_SPEC.md`
11. `11_SOCIAL_UX_SPEC.md`
12. `12_REPOV_REFERENCE_FEATURE_IDEAS.md`

최소 입력:
- 시간이 없으면 `04_AI_BUILD_PROMPT.md`를 먼저 넣고, 이어서 1, 3, 7번 문서를 첨부한다.
- 화면 감성까지 맞추려면 2번과 9번을 추가한다.
- 소셜/친구 기능을 구현할 때는 10번과 11번을 추가한다.
- Repov 모티브에서 추가 기능 후보를 검토할 때는 12번을 참고한다.
- 실제 배포/테스트까지 고려하면 5, 6, 8번 문서도 반드시 넣는다.

구현 목표:
- Repov 스타일의 "일상 블로그형 기록 앱"을 그대로 베끼는 것이 아니라, 날짜/카테고리/사진/카드/라이브러리 구조를 가진 독립 앱 "Write & Record"의 MVP를 만든다.

중요 우선순위:
- P0: 매일 기록 루프. 온보딩, 캘린더, 날짜 선택, 카테고리 선택, 기록 작성/저장/상세/수정/삭제, 로컬 데이터 유지, draft, JSON export.
- P1: 다시 보기 강화. 타임라인/갤러리, 날짜별 사진 필터, 커스텀 카테고리, 검색.
- P2: 표현/공유. 장소/컬렉션, 기록 카드, 이미지 저장/공유.
- P3: 소셜, 동기화, AI 기능. 소셜은 `전체 / 친구들 / 추가` 탭과 명시적 공개 범위를 전제로 한다.

절대 놓치면 안 되는 결정:
- 홈은 캘린더다.
- 한 화면의 primary CTA는 하나만 둔다.
- 초기 앱은 로컬 우선 개인 기록장이다.
- 기록은 `Entry` 단일 모델 중심.
- 카테고리는 enum 고정이 아니라 데이터로 관리.
- 사진 권한이 없어도 기록 저장 가능.
- 기본 공개 범위는 private.
- 소셜 공개는 기록 단위로 `private / friends / public`를 명확히 구분한다.
- 저장 실패 시 draft를 잃지 않음.
- P0에서 JSON export를 제공한다.
- 친구 테스트는 TestFlight 전환 가능성을 고려해 BetaRelease 설정을 분리한다.
