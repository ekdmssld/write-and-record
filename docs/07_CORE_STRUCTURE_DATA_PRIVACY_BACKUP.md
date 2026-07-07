# Write & Record - Core Structure, Data, Privacy, Backup Plan

목적: 세부 기능을 늘리기 전에, 사용자가 하루하루를 안정적으로 기록하고 다시 확인할 수 있는 앱 구조를 고정한다.

핵심 판단:
- 초기 앱은 "로컬 우선 개인 기록장"으로 만든다.
- 홈은 캘린더다.
- 기록 저장/수정/삭제/재실행 후 유지가 모든 기능보다 우선이다.
- 사진, 소셜, 카드, AI는 기록 흐름을 방해하지 않을 때만 붙인다.

## 1. North Star

가장 중요한 질문:
- 사용자가 오늘의 기록을 1분 안에 남길 수 있는가?
- 어제/지난달 기록을 쉽게 다시 확인할 수 있는가?
- 앱을 껐다 켜도 기록이 사라지지 않는가?
- 사진 권한을 거부해도 텍스트 기록은 가능한가?
- 개인 기록을 내보내거나 백업할 최소 수단이 있는가?

MVP 성공 기준:
- 신규 사용자가 온보딩 후 첫 기록을 저장한다.
- 캘린더에서 기록 있는 날짜를 바로 알아본다.
- 날짜를 탭하면 그날 기록 목록을 본다.
- 기록 상세에서 내용을 다시 읽고 수정한다.
- 앱 재실행 후 같은 데이터가 유지된다.

## 2. Product Scope Lock

P0에 반드시 포함:
- mock/local auth 또는 owner profile 생성.
- 온보딩.
- 캘린더 홈.
- 날짜 선택.
- 카테고리 선택.
- 기록 작성.
- 기록 저장.
- 기록 상세 보기.
- 기록 수정/삭제.
- 로컬 데이터 유지.
- draft autosave.
- JSON export.
- 사진 권한 없이 기록 저장.

P0에서 욕심내지 않을 것:
- 친구 피드.
- 클라우드 동기화.
- AI 요약/태그.
- 지도 기반 탐색.
- 복잡한 카드 템플릿.
- 완전한 App Store 출시 준비.

P1 이후:
- 타임라인.
- 갤러리.
- 검색/필터.
- 커스텀 카테고리.
- 날짜별 사진 필터.
- 기본 카드 export.

## 3. Recommended Technical Choices

### Persistence

최선의 초기 선택:
- SwiftData를 기본 로컬 저장소로 사용한다.
- 모든 저장/조회는 Repository protocol 뒤에 둔다.
- SwiftData가 막히거나 migration 이슈가 크면 Codable JSON repository로 대체할 수 있게 경계를 둔다.

이유:
- iOS 개인 앱에서 로컬 데이터 모델을 빠르게 만들기 좋다.
- 캘린더/타임라인/검색용 쿼리를 구조화하기 쉽다.
- 앱이 커져도 repository 계층이 있으면 저장소 교체 비용이 낮다.

금지:
- 화면 View 안에서 직접 파일 저장 로직을 처리하지 않는다.
- 임시 배열/state만으로 저장된 것처럼 보이게 만들지 않는다.
- 카테고리를 enum만으로 고정하지 않는다.

### Photos

P0 선택:
- 사진은 필수가 아니다.
- 선택된 사진은 `PHAsset.localIdentifier` 중심으로 참조 저장한다.
- 썸네일 캐시는 앱 내부에 둘 수 있지만 원본 복사는 P0에서 필수로 하지 않는다.

P1/P2 선택:
- export report에 "이 기록은 어떤 사진 참조를 가진다"를 포함한다.
- 장기 백업이 필요해지면 JSON + copied media zip export를 추가한다.

주의:
- 사용자가 사진 앱에서 원본을 삭제하면 참조가 깨질 수 있다.
- iCloud 사진이 기기에 내려받아지지 않은 상태를 처리해야 한다.
- limited photo library 변경 후 기존 참조가 접근 불가할 수 있다.

### Auth

P0 선택:
- 실제 계정 시스템보다 owner profile을 먼저 안정화한다.
- Debug에서는 mock auth를 허용한다.
- Apple Sign In은 `AuthService` protocol로 교체 가능한 형태만 먼저 둔다.

이유:
- 이 앱의 첫 가치는 로그인보다 기록 저장이다.
- Apple Developer Program 가입 전에도 본인 iPhone 실사용이 가능해야 한다.

## 4. Core App Structure

권장 구조:

```text
WriteAndRecord/
  App/
    WriteAndRecordApp.swift
    AppRouter.swift
    AppEnvironment.swift
  Models/
    UserProfile.swift
    Category.swift
    Entry.swift
    EntryDraft.swift
    MediaAsset.swift
    ExportManifest.swift
  Repositories/
    EntryRepository.swift
    CategoryRepository.swift
    DraftRepository.swift
    ExportRepository.swift
  Services/
    AuthService.swift
    PhotoLibraryService.swift
    ExportService.swift
    AppConfiguration.swift
  Features/
    Onboarding/
    Library/
    CategoryPicker/
    EntryEditor/
    EntryDetail/
    Settings/
  DesignSystem/
    AppColors.swift
    Components/
  Utilities/
    DateKey.swift
    Validation.swift
```

구조 원칙:
- Feature는 화면과 ViewModel을 가진다.
- Repository는 저장/조회만 담당한다.
- Service는 권한, export, auth처럼 외부 시스템과 만나는 책임을 가진다.
- Model은 화면 표현보다 데이터 안정성을 우선한다.
- 날짜 grouping은 `DateKey` 같은 명확한 유틸로 통일한다.

## 5. Minimum Data Model

P0에서 충분한 모델:

### UserProfile

- id
- nickname
- spaceName
- themeId
- onboardingCompletedAt
- createdAt
- updatedAt

### Category

- id
- name
- mainType
- parentId
- icon
- colorHex
- isDefault
- isArchived
- sortOrder
- createdAt
- updatedAt

### Entry

- id
- date
- dateKey
- categoryId
- archivedCategoryName
- title
- body
- rating
- isWishlist
- coverAssetId
- assetIds
- metadata
- createdAt
- updatedAt
- deletedAt

### EntryDraft

- id
- sourceEntryId optional
- date
- dateKey
- categoryId
- title
- body
- assetIds
- metadata
- lastEditedAt

### MediaAsset

- id
- phLocalIdentifier
- type
- dateTaken
- thumbnailPath optional
- width
- height
- createdAt

### ExportManifest

- schemaVersion
- appVersion
- exportedAt
- userProfile
- categories
- entries
- mediaAssets
- warnings

## 6. Date Handling

핵심 규칙:
- 사용자가 보는 날짜는 device current timezone 기준이다.
- Entry는 실제 `date`와 grouping용 `dateKey`를 함께 가진다.
- `dateKey`는 `yyyy-MM-dd` 형태로 저장한다.
- 캘린더는 `dateKey` 기준으로 기록을 묶는다.

이유:
- 자정 근처 작성, 여행, timezone 변경 상황에서도 캘린더 표시를 안정적으로 유지하기 위해서다.

필수 테스트:
- 오늘 기록.
- 어제 날짜로 기록.
- 같은 날짜 여러 개 기록.
- 월말/월초 기록.
- 앱 재실행 후 같은 날짜에 표시.

## 7. Daily Record UX Contract

사용자 핵심 루프:

```text
앱 실행
-> 캘린더 홈
-> 날짜 선택
-> 그날 기록 목록 확인
-> 기록 추가
-> 카테고리 선택
-> 제목/본문 작성
-> 저장
-> 상세 보기
-> 캘린더로 돌아와 기록 점 확인
```

반드시 지킬 것:
- 기록이 없어도 날짜 선택 경험은 자연스러워야 한다.
- 저장 버튼은 항상 접근 가능해야 한다.
- 저장 실패 시 draft는 남아야 한다.
- 사진이 없어도 기록 카드는 성립해야 한다.
- 긴 본문은 읽기 좋게 보여야 한다.
- 삭제는 soft delete를 기본으로 한다.

## 8. Backup and Export

P0 필수:
- Settings에서 JSON export 제공.
- export 파일에는 schemaVersion을 포함한다.
- entries/categories/profile/media references를 포함한다.
- export 완료 후 공유 sheet로 파일을 보낼 수 있게 한다.

P0 export에 포함할 것:
- 앱 버전.
- export 생성 시각.
- 기록 개수.
- 카테고리 개수.
- 사진 참조 개수.
- 접근 불가한 사진 참조 warning.

P1:
- JSON import/restore.
- import 전 현재 데이터 백업 권장.
- 중복 id 처리 정책.

P2:
- JSON + media copy zip backup.
- iCloud Drive 저장 옵션.
- 자동 백업 알림.

중요 원칙:
- 개인 기록 앱에서 데이터 유실은 가장 큰 실패다.
- 카드 공유보다 export가 먼저다.
- 소셜 기능보다 backup이 먼저다.

## 9. Privacy Rules

기본값:
- 모든 기록은 private.
- 서버 전송 없음.
- analytics 없음 또는 최소화.
- debug log에 title/body/location/link를 출력하지 않음.

권한 요청 원칙:
- 사진 권한은 사용자가 사진 추가를 시도할 때 요청한다.
- 알림 권한은 사용자가 알림을 켤 때 요청한다.
- 위치 권한은 사용자가 현재 위치 불러오기를 시도할 때 요청한다.
- 권한 거부는 앱 사용 차단 사유가 아니다.

금지:
- 사용자가 작성한 본문을 crash log custom field로 보내기.
- 사진 파일을 사용자 동의 없이 업로드하기.
- 위치를 자동으로 계속 추적하기.
- 친구 기능을 기본 공개로 시작하기.

## 10. Core Quality Gates

P0 완료 전 반드시 통과:
- 신규 설치 후 첫 기록 저장 가능.
- 사진 권한 거부 후 기록 저장 가능.
- 앱 강제 종료 후 draft 복구.
- 앱 재실행 후 기록 유지.
- 같은 날짜 여러 기록 표시.
- 기록 수정 후 캘린더/상세 동시 반영.
- 기록 삭제 후 목록에서 사라짐.
- JSON export 생성 가능.
- 긴 제목/긴 본문에서 화면 깨짐 없음.
- PersonalRelease에서 mock/debug UI 숨김.

P0가 불안정하면 미루는 것:
- 카드 템플릿 추가.
- 커스텀 통계.
- 친구 초대.
- 클라우드 동기화.
- AI 기능.

## 11. Implementation Order

1. App shell
   - AppRouter.
   - AppEnvironment.
   - Design tokens.
   - BuildConfiguration.

2. Local data foundation
   - SwiftData models.
   - Repository protocols.
   - Seed default categories.
   - DateKey utility.

3. Daily record loop
   - Onboarding.
   - Calendar home.
   - Category picker.
   - Entry editor.
   - Entry detail.
   - Edit/delete.

4. Data safety
   - Draft autosave.
   - JSON export.
   - Data reset with confirmation.
   - No sensitive logs check.

5. Review views
   - Timeline.
   - Gallery.
   - Search.

6. Beta readiness
   - Feedback mail/share sheet.
   - Crash reporting hook.
   - TestFlight metadata.

## 12. Decision Summary

최선의 MVP 선택:
- SwiftUI + SwiftData.
- Repository layer 필수.
- Calendar-first navigation.
- Entry 단일 중심 모델.
- Photos optional.
- Local-only by default.
- JSON export in P0.
- Cloud/social/AI deferred.

제품 기준:
- "멋진 기능이 많은 앱"보다 "매일 믿고 쓰는 기록 앱"이 먼저다.
