# Write & Record - Detailed Functional Spec

목적: 실제 구현자가 화면, 상태, 데이터, 예외, 테스트 기준을 빠짐없이 만들 수 있게 하는 상세 기능 명세서.

## 1. Product Mode

초기 배포 대상:
- Primary: 본인 iPhone 실사용.
- Secondary: 친구 소수 테스트.
- App Store public release: 보류.

권장 구현 모드:
- `Debug`: mock auth, seed data reset, local logs, sample entries.
- `PersonalRelease`: 본인 실사용, 로컬 저장 안정화, debug UI 숨김.
- `BetaRelease`: 친구 테스트, TestFlight/Ad Hoc 가능, 피드백/크래시 수집.
- `StoreRelease`: App Store 심사 대응, 개인정보/약관/앱 아이콘/스크린샷 완비.

## 2. User Roles

Owner:
- 본인.
- 모든 기능 사용.
- 로컬 데이터 export/import 가능.

Tester:
- 친구 테스트 사용자.
- 온보딩, 기록 작성, 카드 공유, 피드백 제출 가능.
- 소셜 기능은 beta flag로 제한 가능.

Future Friend:
- 친구 공간 보기, 친구 초대, 공유 기록 보기.
- MVP에서는 UI/설정값만 준비.

## 3. Feature Flags

필수 feature flag:
- `enableMockAuth`
- `enableSampleData`
- `enableFriendFeatures`
- `enableCloudSync`
- `enableCardExport`
- `enableFeedback`
- `enableCrashReporting`

초기값:
- Debug: mock/sample/feedback on.
- PersonalRelease: mock off, sample off, card export on, cloud off.
- BetaRelease: mock off, feedback on, crash reporting on.

## 4. Authentication

MVP:
- Mock login: debug only.
- Apple Sign In: release-ready interface만 먼저 만들고, 실제 연결은 개발자 계정 상황에 맞춰 진행.

Functional requirements:
- 앱 시작 시 session 확인.
- session 없음 -> AuthView.
- session 있음 + onboarding incomplete -> onboarding.
- session 있음 + onboarding complete -> LibraryHome.
- 로그아웃 시 로컬 개인 데이터 처리 옵션 제공:
  - keep on device
  - delete local data

Acceptance:
- mock user로 앱 전체 플로우 테스트 가능.
- auth provider 변경이 UI 전체에 퍼지지 않음.

## 5. Onboarding

Steps:
1. Nickname
2. Profile Photo
3. Profile Theme + Space Name
4. App Intro + Social/Notification Settings

Persisted fields:
- nickname
- avatarAssetId
- themeId
- spaceName
- socialEnabled
- friendShareEnabled
- notificationEnabled
- onboardingCompletedAt

Validation:
- nickname: 1~20자.
- spaceName: 1~30자.
- 프로필 사진은 optional.
- 알림 권한은 사용자가 toggle on 했을 때만 요청.

Exit behavior:
- 중간 종료 시 현재 입력값 draft 저장.
- 재실행 시 마지막 완료 단계부터 시작.

## 6. Library

Default view: Calendar.

View switch:
- Calendar
- Timeline
- Gallery
- Places
- Collections

Shared requirements:
- 모든 뷰는 EntryRepository를 단일 source of truth로 사용.
- 저장/수정/삭제 후 즉시 반영.
- 빈 상태 제공.
- 필터 상태 유지.

Calendar:
- 월 이동.
- 오늘 표시.
- 선택 날짜 표시.
- 날짜별 기록 수 표시.
- 카테고리 색 점 최대 3개 표시.
- 날짜 탭 -> bottom sheet/list.
- bottom sheet item 탭 -> EntryDetail.
- add 탭 -> CategoryPicker.

Timeline:
- 최신순 기본.
- 월/연도 header.
- 카테고리/별점/위시 필터.
- infinite scroll 또는 lazy list.

Gallery:
- 사진 있는 기록은 cover grid.
- 사진 없는 기록은 category placeholder.
- 탭 -> EntryDetail.

Places:
- MVP는 list 우선, map은 P2.
- place 없는 Entry는 숨기거나 "장소 없음" 필터로 표시.

Collections:
- Manual collections.
- Smart collections:
  - 위시리스트
  - 별점 5
  - 최근 30일
  - 카테고리별

## 7. Category

Category types:
- Default main category.
- Default subcategory.
- Custom category.

Category fields:
- id
- name
- mainType
- parentId
- icon
- colorHex
- isDefault
- isArchived
- templateId
- createdAt
- updatedAt

Rules:
- 기본 카테고리는 삭제 불가, 숨김 가능.
- 커스텀 카테고리는 수정/삭제 가능.
- 삭제된 카테고리로 작성된 Entry는 `archivedCategoryName`을 유지.
- 카테고리 이름 중복은 같은 parent 내에서 금지.

CategoryPicker:
- main category grid.
- subcategory list.
- search.
- custom add button.
- 최근 사용 category shortcut.

## 8. Entry Editor

Required:
- title
- date
- categoryId

Optional:
- body
- rating
- isWishlist
- coverAssetId
- assetIds
- pros
- cons
- tips
- count
- place
- links
- metadata
- collectionIds

Validation:
- title: 1~80자.
- body: max 10,000자.
- rating: nil or 1~5.
- count: nil or 1 이상.
- link: valid URL.
- pros/cons/tips item: max 120자.

Draft:
- edit 시작 후 5초 debounce autosave.
- 앱 background 진입 시 즉시 draft save.
- 저장 성공 시 draft 삭제.
- cancel 시 변경사항 있으면 confirm.

Save:
- save button은 validation 통과 시 enabled.
- 저장 중 중복 탭 방지.
- 실패 시 draft 유지, retry 제공.
- 성공 시 EntryDetail로 이동.

Edit existing entry:
- EntryDetail -> edit.
- 기존 asset/category/date 유지.
- 수정 저장 후 Detail refresh.

Delete:
- soft delete.
- confirm sheet.
- 삭제 후 이전 Library view로 복귀.

## 9. Photo Library

Permissions:
- notDetermined: 요청 가능.
- authorized: 날짜별/전체 사진 로드.
- limited: 허용된 사진만 로드 + 권한 관리 안내.
- denied/restricted: 사진 없이 계속 가능.

Date filtering:
- selected date local 00:00~23:59.
- timezone은 device current timezone.
- metadata date가 없는 사진은 전체 탭에만 표시.

Picker UI:
- segmented: 이 날짜 / 전체.
- 3-column grid.
- multi-select.
- selected overlay.
- selected count bottom bar.

Data handling:
- PHAsset localIdentifier 저장.
- 썸네일 캐시.
- 원본 복사는 사용자 export/backup 요구가 생기면 추가.

Edge cases:
- iCloud photo not downloaded.
- video selected.
- limited library 변경.
- permission revoked after save.

## 10. Record Card

Purpose:
- 기록을 이미지 카드로 저장/공유.

Templates:
- Minimal Photo
- Blog Snippet
- Rating Review
- Wishlist
- Place Memory
- Text Diary

Render requirements:
- 1080x1350 portrait default.
- safe padding.
- 긴 title/body truncation.
- 사진 없음 fallback.
- category color 적용.

Export:
- save to Photos if permission allowed.
- share sheet.
- local RecordCard row 생성.

Acceptance:
- 카드 미리보기와 export 결과가 큰 차이 없음.
- 사진 권한이 없어도 share sheet export는 가능해야 함.

## 11. Search and Filter

Search fields:
- title
- body
- category name
- place name
- link title/url

Filters:
- date range
- category
- rating
- wishlist
- has photo
- has place
- collection

Sorting:
- date desc default.
- date asc.
- created desc.
- rating desc.

## 12. Data Export/Backup

Personal-use 필수 권장:
- JSON export.
- media reference export report.
- app data reset.

P2:
- zip backup with JSON + copied media.
- import/restore.

Reason:
- App Store 전이라도 개인 기록 앱은 데이터 유실이 가장 큰 리스크.

## 13. Notifications

MVP:
- onboarding에서 알림 사용 여부 저장.
- 실제 local notification은 P1.

P1:
- daily reminder time.
- missed days reminder.
- weekly recap prompt.

Rules:
- permission은 사용자가 켠 경우에만 요청.
- 알림 off 시 scheduled notifications 제거.

## 14. Feedback for Testers

BetaRelease:
- Settings -> Send Feedback.
- feedback fields:
  - category: bug/request/confusing/other
  - message
  - optional screenshot
  - app version/build
  - iOS version/device model

No backend option:
- mailto link or share sheet with prefilled diagnostic text.

Backend option:
- Supabase/Firebase table.
- personal data redaction before upload.

## 15. Privacy

Sensitive data:
- diary text
- photos
- locations
- links
- friend graph future

Rules:
- default private.
- no analytics with title/body/photo/location unless explicit.
- logs must not include Entry body/title/url.
- crash reports should avoid custom user content.
- export clearly user-initiated.

Required app permission copy:
- Photos read: "선택한 날짜의 사진을 기록에 첨부하기 위해 사진 접근이 필요해요."
- Photos add: "만든 기록 카드를 사진 앱에 저장하기 위해 필요해요."
- Notifications: "기록을 잊지 않도록 원하는 시간에 알림을 보내드려요."
- Location: "장소 기록을 저장할 때 현재 위치를 불러오기 위해 사용해요."

## 16. Quality Gates

P0 must pass:
- cold launch under 2s on target iPhone.
- save entry without photo.
- save entry with 10 photos.
- deny Photos permission and continue.
- app kill during edit -> draft restored.
- long text does not break layout.
- app restart preserves data.

P1 must pass:
- limited photo library works.
- custom category persists.
- search returns expected records.
- timeline/gallery update after edit/delete.

Release candidate:
- no debug/mock UI.
- no sensitive logs.
- privacy strings present.
- icon/launch screen present.
- device test on real iPhone.

