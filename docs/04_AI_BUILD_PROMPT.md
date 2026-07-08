# AI Build Prompt

다음 문서를 먼저 읽고 앱을 구현하라:
- `docs/01_PRODUCT_SPEC.md`
- `docs/02_DESIGN_SPEC.md`
- `docs/03_FLOWCHARTS.md`
- `docs/05_FUNCTIONAL_SPEC.md`
- `docs/06_DISTRIBUTION_AND_RELEASE_PLAN.md`
- `docs/07_CORE_STRUCTURE_DATA_PRIVACY_BACKUP.md`
- `docs/08_QA_BETA_TEST_PLAN.md`
- `docs/09_VISUAL_DIRECTION_AND_UI_CONCEPT.md`
- `docs/10_SOCIAL_FEATURE_SPEC.md`
- `docs/11_SOCIAL_UX_SPEC.md`

## 역할

너는 senior iOS engineer + product designer다. SwiftUI로 "Write & Record" 앱의 MVP를 만든다. 목표는 버그가 적고 확장 가능한 기본 틀이다.

제품의 최우선 목표:
- 사용자가 하루하루를 실제로 기록하고 다시 확인할 수 있어야 한다.
- 캘린더 중심의 기록 루프가 카드/소셜/AI보다 먼저다.
- 데이터 유실 방지와 JSON export는 MVP의 일부다.
- 화면은 "조용히 쌓이는 개인 블로그"처럼 느껴져야 하며, 한 화면의 primary CTA는 하나만 둔다.
- 소셜 기능을 구현할 때는 `전체 / 친구들 / 추가` 상단 탭과 `private / friends / public` 공개 범위를 지킨다.

## 구현 지시

1. SwiftUI iOS 앱을 생성한다.
2. MVVM 또는 Observable architecture를 사용한다. 한 화면에 비즈니스 로직을 과하게 넣지 않는다.
3. 데이터 모델은 Product Spec의 모델을 따른다.
4. 초기 저장소는 로컬 persistence를 사용한다. SwiftData 가능하면 SwiftData, 아니면 Codable JSON repository.
5. 로그인은 MVP에서 mock/dev auth를 허용하되, Apple 로그인으로 교체 가능한 `AuthService` 프로토콜을 둔다.
6. Photos 접근은 별도 `PhotoLibraryService`로 격리한다.
7. 카테고리 기본값은 seed data로 앱 첫 실행 시 생성한다.
8. 온보딩 완료 여부를 저장하고 다음 실행부터 LibraryHome으로 진입한다.
9. 캘린더 날짜 선택 -> 카테고리 선택 -> 기록 작성 -> 저장 -> 상세 화면 플로우를 먼저 완성한다.
10. 그다음 타임라인, 갤러리, 커스텀 카테고리, 카드 생성 순서로 구현한다.
11. 본인 iPhone 실사용을 전제로 `PersonalRelease` 빌드 설정을 분리한다.
12. 친구 테스트 전환을 위해 `BetaRelease` 빌드 설정, feedback hook, crash-reporting hook을 둘 수 있게 설계한다.

## 파일 구조 권장

```text
WriteAndRecord/
  App/
    WriteAndRecordApp.swift
    AppRouter.swift
  Models/
    UserProfile.swift
    Category.swift
    Entry.swift
    MediaAsset.swift
    Collection.swift
    RecordCard.swift
  Services/
    AuthService.swift
    EntryRepository.swift
    CategoryRepository.swift
    PhotoLibraryService.swift
    CardRenderService.swift
  Features/
    Auth/
    Onboarding/
    Library/
    CategoryPicker/
    EntryEditor/
    PhotoPicker/
    EntryDetail/
    RecordCard/
    Settings/
  DesignSystem/
    AppColors.swift
    AppTypography.swift
    Components/
  Utilities/
    DateUtils.swift
    Validation.swift
  Release/
    BuildConfiguration.swift
    FeatureFlags.swift
```

## P0 완료 조건

- 앱 실행 가능.
- mock login 가능.
- 온보딩 4단계 완료 가능.
- 기본 카테고리 표시.
- 캘린더가 기본 홈으로 표시.
- 캘린더에서 날짜 선택 가능.
- 기록 작성/저장/상세 보기 가능.
- 기록 수정/삭제 가능.
- 앱 재실행 후 기록 유지.
- 작성 중 앱 종료 후 draft 복구.
- 사진 권한 거부 상태에서도 저장 가능.
- 빈 상태/에러 상태가 깨지지 않음.
- 개인 데이터 export JSON 기능의 최소 버전이 있음.
- Debug UI가 PersonalRelease에서 보이지 않음.

## 구현 중 금지

- UI만 만들고 저장 로직 생략 금지.
- 사진 권한 필수로 강제 금지.
- 카테고리를 enum에만 고정하여 커스텀 카테고리 불가능하게 만들기 금지.
- 모든 화면을 한 파일에 몰아넣기 금지.
- 사용자의 기록 본문/제목을 debug log로 출력 금지.
- 배포 설정과 debug/mock 설정을 한 target/config에 섞기 금지.
- 앱 삭제 시 데이터가 사라질 수 있음을 무시하고 backup/export 없이 실사용 유도 금지.
- 카드/소셜/AI를 캘린더 기록 루프보다 먼저 구현 금지.

## 테스트 체크리스트

- 신규 설치 첫 실행.
- 온보딩 중 앱 종료 후 재실행.
- 제목 빈 값 저장 시도.
- 긴 제목/긴 본문 저장.
- 사진 권한 denied/limited/authorized.
- 같은 날짜에 여러 카테고리 기록.
- 커스텀 카테고리 생성 후 기록.
- 기록 수정/삭제.
- 캘린더/타임라인/갤러리 반영.
- 앱 재실행 후 데이터 유지.
- PersonalRelease build에서 mock login/debug sample reset 버튼 숨김.
- 실제 iPhone 설치 후 사진/알림 권한 동작.
- 7일 개인 사용 테스트에서 데이터 유실 없음.
