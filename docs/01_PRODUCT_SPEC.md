# Write & Record iOS App - Product/Build Spec

목표: 사용자가 일상을 블로그처럼 날짜별로 기록하고, 카테고리/사진/평가/장소/컬렉션/공유 카드로 다시 볼 수 있는 개인 기록 iOS 앱.

원칙:
- MVP는 iOS SwiftUI 앱 기준. 오프라인 우선 로컬 저장 + 추후 클라우드 동기화 가능 구조.
- 모든 기록은 `Entry` 하나로 통합하고, 카테고리별 추가 필드는 `metadata`로 확장.
- 사용자는 가입 직후 3분 안에 첫 기록을 저장할 수 있어야 함.
- 기본 개인정보는 비공개. 소셜/친구 공유/알림은 명시적 opt-in.

## 1. MVP 범위

필수:
- 로그인/가입: Apple 로그인 우선, 이메일 로그인 옵션.
- 온보딩: 닉네임, 프로필 사진, 프로필 디자인, 내 공간 이름, 앱 소개, 소셜 알림 설정.
- 라이브러리 홈: 캘린더 기본 뷰, 타임라인/갤러리/장소/컬렉션 전환.
- 기록 생성: 날짜 선택, 카테고리 선택, 사진 첨부, 제목, 날짜, 별점 또는 위시리스트, 내용, 추가 섹션 저장.
- 사진 선택: 선택 날짜의 사진 우선 표시 + 전체 사진첩 접근.
- 기록 카드 생성: 저장된 기록으로 카드 템플릿 선택, 이미지 저장/공유.
- 검색/필터: 날짜, 카테고리, 별점, 위시, 텍스트.
- 커스텀 카테고리 생성/수정/삭제.

후순위:
- 친구 피드, 친구 공간 방문, 공동 컬렉션.
- iCloud/Supabase/Firebase 동기화.
- 웹 공유 페이지.
- 자동 태그/AI 요약/감정 분석.

## 2. 핵심 용어

- User: 앱 사용자.
- Space: 사용자의 기록 공간. 예: "다은의 기록방".
- ProfileTheme: 프로필/공간 디자인 테마.
- Entry: 날짜에 귀속되는 하나의 기록.
- Category: 기록의 주제. 기본/세부/커스텀 포함.
- Collection: 사용자가 묶은 기록 모음. 예: "2026 맛집", "올해 본 영화".
- RecordCard: 기록을 이미지 카드로 렌더링한 결과.
- Wishlist: 아직 하지 않았거나 먹지 않았거나 보고 싶은 항목.

## 3. 사용자 시나리오

1. 신규 사용자는 Apple로 로그인한다.
2. 닉네임, 프로필 사진, 테마, 공간 이름을 정한다.
3. 소셜 기능 설명을 보고 친구 공유/알림을 켜거나 끈다.
4. 홈 캘린더에서 오늘 또는 특정 날짜를 탭한다.
5. "무엇을 기록할까요?" 화면에서 카테고리를 고른다.
6. 해당 날짜 사진이 먼저 보이는 선택기에서 사진을 고른다.
7. 제목, 별점/위시, 내용, 장점/단점/팁/장소/링크 등을 입력한다.
8. 저장 후 기록 상세와 카드 만들기 CTA를 본다.
9. 라이브러리에서 캘린더/타임라인/갤러리/장소/컬렉션으로 기록을 다시 본다.

## 4. 정보 구조

탭:
- Library: 캘린더/타임라인/갤러리/장소/컬렉션.
- Create: 빠른 기록 생성.
- Search: 검색/필터.
- My Space: 프로필, 통계, 카드, 친구/공유 설정.

주요 화면:
- AuthView
- OnboardingNicknameView
- OnboardingPhotoView
- OnboardingThemeView
- OnboardingIntroSocialView
- LibraryHomeView
- CalendarView
- TimelineView
- GalleryView
- PlacesView
- CollectionsView
- CategoryPickerView
- EntryEditorView
- DatePhotoPickerView
- EntryDetailView
- RecordCardPickerView
- RecordCardPreviewView
- SettingsView

## 5. 기본 카테고리

기본 메인 카테고리:
- 일상
- 음식/메뉴
- 덕질
- 운동
- 영화/TV
- 책
- 음악
- 장소

세부 카테고리 예시:
- 일상: 하루 기록, 감정, 일기, 쇼핑, 공부, 업무, 기념일, 여행, 취미
- 음식/메뉴: 맛집, 카페, 배달, 집밥, 디저트, 술, 레시피, 재방문
- 덕질: 아이돌, 배우, 애니, 게임, 굿즈, 공연, 팬미팅, 콘텐츠
- 운동: 헬스, 러닝, 요가, 필라테스, 수영, 등산, 홈트, 기록 측정
- 영화/TV: 영화, 드라마, 예능, 다큐, 애니, 시리즈 정주행
- 책: 소설, 에세이, 자기계발, 만화, 시집, 논픽션, 인용문
- 음악: 곡, 앨범, 플레이리스트, 공연, 아티스트, 노래방
- 장소: 여행지, 동네, 전시, 숙소, 산책, 매장, 포토스팟

커스텀 카테고리:
- 필드: 이름, 이모지/아이콘, 색상, 부모 카테고리 optional, 입력 템플릿 optional.
- 삭제 시 기존 기록은 `archivedCategoryName`을 유지.

## 6. 데이터 모델

UserProfile:
- id: UUID/String
- authProvider: apple/email
- nickname: String
- avatarAssetId: String?
- spaceName: String
- themeId: String
- socialEnabled: Bool
- friendShareEnabled: Bool
- notificationEnabled: Bool
- createdAt, updatedAt: Date

ProfileTheme:
- id: String
- name: String
- primaryColorHex: String
- backgroundStyle: solid/gradient/pattern
- fontStyle: calm/cute/editorial/minimal

Category:
- id: UUID/String
- name: String
- mainType: daily/food/fandom/exercise/movieTv/book/music/place/custom
- parentId: String?
- icon: String
- colorHex: String
- isDefault: Bool
- isArchived: Bool
- templateId: String?

Entry:
- id: UUID/String
- userId: String
- date: Date
- categoryId: String
- archivedCategoryName: String?
- title: String
- body: String
- rating: Int? // 1...5
- isWishlist: Bool
- coverAssetId: String?
- assetIds: [String]
- pros: [String]
- cons: [String]
- tips: [String]
- count: Int?
- place: PlaceRef?
- links: [LinkRef]
- metadata: JSON/String dictionary
- collectionIds: [String]
- createdAt, updatedAt, deletedAt: Date?

PlaceRef:
- name: String
- address: String?
- latitude: Double?
- longitude: Double?
- externalId: String?

LinkRef:
- title: String?
- url: String

MediaAsset:
- id: UUID/String
- localIdentifier: String? // PHAsset id
- type: photo/video
- dateTaken: Date?
- width, height: Int
- thumbnailPath: String?
- localPath: String?
- remoteUrl: String?
- createdAt: Date

Collection:
- id: UUID/String
- name: String
- description: String?
- coverAssetId: String?
- entryIds: [String]
- sortOrder: Int
- createdAt, updatedAt: Date

RecordCard:
- id: UUID/String
- entryId: String
- templateId: String
- imagePath: String?
- createdAt: Date

## 7. 카테고리별 metadata 예시

음식:
- menuName, price, restaurantName, visitType, repurchaseIntent, spiceLevel

운동:
- workoutType, durationMin, distanceKm, weightKg, reps, sets, calories

영화/TV:
- originalTitle, platform, watchedStatus, watchedEpisode, director, cast

책:
- author, publisher, pagesRead, totalPages, quote, readingStatus

음악:
- artist, album, track, mood, listenedOn, favoriteLyricShort

장소:
- visitPurpose, weather, crowdLevel, transportation, revisitIntent

덕질:
- fandomTarget, eventName, contentType, merch, episode

## 8. Entry Editor 규칙

공통 필드:
- 사진: 0개 이상. 첫 사진은 cover 후보.
- 제목: required, 1~80자.
- 날짜: required.
- 별점/위시: 둘 중 하나 또는 둘 다 가능. 별점은 1~5.
- 내용: optional, 최대 10,000자.
- 이미지: 추가 첨부 가능.
- 장점/단점/팁: 각 0개 이상 리스트.
- 횟수: optional positive int.
- 장소: optional.
- 링크: URL validation.
- 저장: required field 유효성 통과 시 enabled.

저장 후:
- EntryDetail로 이동.
- Toast: "기록이 저장됐어요."
- CTA: "기록 카드 만들기".

## 9. 사진 권한/선택 정책

권한:
- iOS Photos 권한은 add/read 요청을 명확히 분리.
- 제한된 접근 권한(Limited Library)을 지원.
- 권한 거부 시 전체 사진 기능 대신 수동 이미지 추가 안내.

날짜별 사진:
- 기준 날짜의 00:00~23:59 로컬 타임존 사진을 우선 노출.
- 상단 segmented control: "이 날짜" / "전체".
- 사진 메타데이터 날짜가 없으면 전체 탭에만 노출.
- 선택한 사진은 앱 내부 MediaAsset으로 참조 저장. 원본 복사는 옵션.

## 10. 라이브러리 뷰

Calendar:
- 기본 홈.
- 날짜 셀에 기록 수/대표 카테고리 색 점 표시.
- 날짜 탭 시 해당 날짜 Entry 목록 + 새 기록 버튼.

Timeline:
- 최신순.
- 월/연도 sticky header.
- 카드: 사진, 제목, 날짜, 카테고리, 별점/위시.

Gallery:
- 사진 중심 masonry/grid.
- 사진 없는 기록은 텍스트 카드 placeholder.

Places:
- 지도 또는 리스트.
- 위치 없는 기록 제외 또는 "장소 없음" 필터 제공.

Collections:
- 사용자가 만든 모음.
- 자동 컬렉션: 별점 5, 위시리스트, 최근 저장, 카테고리별.

## 11. 소셜/공유

MVP:
- RecordCard 이미지 저장/share sheet.
- 친구 기능은 온보딩에서 소개만 하고 설정값 저장.

추후:
- 친구 초대 링크.
- 공개 범위: 나만 보기/친구 공개/링크 공개.
- 댓글/반응/알림.

## 12. 비기능 요구사항

성능:
- Library 첫 화면 1초 내 표시.
- 사진 썸네일 lazy loading.
- Entry 목록 pagination.

신뢰성:
- 저장 중 앱 종료 대비 draft autosave.
- 모든 삭제는 soft delete 우선.
- 마이그레이션 가능한 schema version 관리.

접근성:
- Dynamic Type 대응.
- VoiceOver label.
- 색상만으로 상태 구분 금지.

보안/개인정보:
- 기록 기본값 private.
- 사진 위치정보 사용 시 명시.
- 로그에 제목/본문/URL 등 민감 데이터 남기지 않음.

## 13. 오류/빈 상태

- 로그인 실패: 재시도 + 다른 로그인 방식.
- 사진 권한 없음: 권한 설정 버튼 + 기록은 사진 없이 가능.
- 해당 날짜 사진 없음: "이 날짜 사진이 없어요" + 전체 사진 보기.
- 기록 없음: 캘린더 유지 + "첫 기록 남기기".
- 저장 실패: 로컬 draft 보존 + 재시도.
- 링크 invalid: 필드 하단 에러.

## 14. 구현 우선순위

P0:
- 프로젝트 생성, 데이터 모델, 로컬 저장, 온보딩, 캘린더, 카테고리 선택, 기록 작성/저장/상세.

P1:
- 사진 날짜 필터, 타임라인/갤러리, 커스텀 카테고리, 검색/필터.

P2:
- 장소/컬렉션, 기록 카드 템플릿, 공유.

P3:
- 소셜, 동기화, AI 기능.

## 15. Acceptance Criteria

- 신규 설치 후 로그인 없이도 mock/dev mode로 온보딩과 기록 저장 테스트 가능.
- 온보딩 완료 상태가 저장되고 다음 실행 시 Library로 진입.
- 캘린더에서 날짜 선택 후 카테고리를 고르면 EntryEditor가 열린다.
- Entry required 필드 검증이 작동한다.
- 저장한 기록이 캘린더/타임라인/상세에 즉시 반영된다.
- 사진 권한이 없어도 기록 저장이 가능하다.
- 커스텀 카테고리로 기록 저장 후 필터링 가능하다.
- 앱 재실행 후 저장 데이터가 유지된다.

