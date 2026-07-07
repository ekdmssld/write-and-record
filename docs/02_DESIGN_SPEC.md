# Write & Record iOS App - Design Spec

목표: 개인 블로그/다이어리 감성, 하지만 기록 입력은 빠르고 명확한 생산성 앱처럼 동작.

## 1. 디자인 방향

키워드:
- personal, editorial, calm, collectible, warm, organized

피해야 할 것:
- 과한 장식, 긴 설명문, 입력 중 방해되는 애니메이션, 낮은 대비, 카드 과밀.

화면 밀도:
- 온보딩: 여백 넓게, 한 화면 한 결정.
- 라이브러리: 스캔 가능하게 조밀.
- 에디터: 섹션형, 키보드 대응, 저장 버튼 항상 접근 가능.

## 2. 색상 토큰

Light:
- bg: #FBFAF7
- surface: #FFFFFF
- surfaceAlt: #F3F0EA
- text: #1F1F1F
- textMuted: #73706A
- line: #E7E1D8
- primary: #5B6CFF
- primaryText: #FFFFFF
- danger: #D94A4A
- success: #2E8B57

Category:
- daily: #F4A7B9
- food: #F2A65A
- fandom: #B794F4
- exercise: #59B88D
- movieTv: #6AA9FF
- book: #B68B5E
- music: #FF7AA2
- place: #50B9B0
- customDefault: #9A9A9A

Dark optional:
- bg: #121212
- surface: #1B1B1D
- surfaceAlt: #252529
- text: #F4F4F4
- textMuted: #A6A6A6
- line: #333338

## 3. Typography

iOS system font 사용.
- LargeTitle: 34 semibold
- Title1: 28 semibold
- Title2: 22 semibold
- Headline: 17 semibold
- Body: 16 regular
- Callout: 15 regular
- Caption: 12 regular

규칙:
- 본문 최소 15pt.
- 날짜/메타는 Caption 또는 Callout.
- 입력 필드는 Body.

## 4. Layout

Global:
- horizontal padding: 20
- small gap: 8
- medium gap: 12
- large gap: 20
- card radius: 8
- button radius: 10
- toolbar height: 48~56

Navigation:
- iOS NavigationStack.
- 주요 CTA는 bottom safe area 고정.
- 긴 입력 화면은 keyboard-aware scroll.

## 5. Components

PrimaryButton:
- height 52
- bg primary
- text primaryText
- disabled opacity 0.35

SecondaryButton:
- height 48
- bg surfaceAlt
- border line optional

IconButton:
- 44x44
- SF Symbols
- VoiceOver label required

SegmentedViewSwitch:
- 캘린더/타임라인/갤러리/장소/컬렉션
- active bg text, inactive muted

CategoryChip:
- icon + name
- selected border 2 primary
- bg category color 15% tint

EntryCard:
- cover image 72x72 or full-width variant
- title, date, category, rating/wish
- empty image placeholder uses category tint

RatingControl:
- 5 stars
- tap/drag 가능
- no rating 상태 지원

WishlistToggle:
- bookmark icon + "위시"
- selected filled

SectionInput:
- title label
- optional helper/error
- content field/list

PhotoGrid:
- 3 columns
- 4px gap
- selected checkmark overlay

RecordCardTemplateTile:
- preview thumbnail
- template name
- selected outline

## 6. Screen Specs

### AuthView

Purpose: 로그인 시작.
Elements:
- app name: Write & Record
- subtitle: "하루를 고르고, 좋아한 것을 기록해요."
- Apple login button
- Email login button
- dev/mock mode button only debug build
States:
- loading, authError

### OnboardingNicknameView

Elements:
- title: "어떻게 불러드릴까요?"
- nickname text field
- next button
Validation:
- 1~20자, 공백-only 불가.

### OnboardingPhotoView

Elements:
- avatar preview circle
- photo picker button
- skip button

### OnboardingThemeView

Elements:
- profile card preview
- theme grid
- space name text field
Validation:
- space name 1~30자.

### OnboardingIntroSocialView

Elements:
- 3 short feature cards:
  - "기록 카드로 공유"
  - "친구와 취향 발견"
  - "알림으로 기록 습관 만들기"
- friend share toggle
- notification toggle
- start button

### LibraryHomeView

Default: Calendar.
Top:
- profile/space name
- search icon
- add button
Switch:
- Calendar, Timeline, Gallery, Places, Collections
Empty:
- "아직 기록이 없어요" + CTA

### CalendarView

Elements:
- month header, previous/next
- weekday row
- date grid
- date cell: day number, today ring, selected fill, entry dots
- selected date bottom sheet/list
Interactions:
- tap date selects.
- tap add opens CategoryPicker for selected date.

### CategoryPickerView

Elements:
- date summary
- search category
- main category grid
- subcategory list after main selected
- custom category add
Interactions:
- choosing final category opens EntryEditor.

### EntryEditorView

Layout:
- top nav: cancel, title, save
- cover/photo strip
- title input
- date row
- rating + wishlist row
- body text editor
- expandable additional sections:
  - images
  - pros
  - cons
  - tips
  - count
  - place
  - links
- category-specific metadata sections
Behavior:
- autosave draft every 5 seconds after change.
- save disabled until title/date/category valid.
- unsaved changes confirm on cancel.

### DatePhotoPickerView

Top:
- segmented "이 날짜" / "전체"
- permission banner if needed
Content:
- photo grid
- selected count bottom bar
Empty:
- date tab: "이 날짜에 찍은 사진이 없어요."

### EntryDetailView

Elements:
- cover
- category/date/rating/wish metadata
- title
- body
- media gallery
- pros/cons/tips
- place/link sections
- edit/delete menu
- make card CTA

### RecordCardPickerView

Elements:
- template grid
- preview pane
- next/share button
Templates:
- Minimal Photo
- Blog Snippet
- Rating Review
- Wishlist
- Place Memory
- Text Diary

### RecordCardPreviewView

Elements:
- rendered card
- save image
- share
- change template

## 7. Record Card Templates

Minimal Photo:
- full photo, small date/category overlay, title.

Blog Snippet:
- title, body excerpt 120자, date, category color line.

Rating Review:
- photo, title, star rating, pros/cons top 2.

Wishlist:
- title, bookmark badge, image optional, note excerpt.

Place Memory:
- photo, place name, date, map-pin visual, tip.

Text Diary:
- no photo optimized, large title, body excerpt, subtle pattern.

## 8. Motion

- 화면 전환: native navigation.
- 저장 성공: 1.5초 toast.
- 카드 선택: scale 0.98 -> 1.0.
- 사진 선택: checkmark fade.
- 캘린더 월 변경: horizontal slide.

## 9. Accessibility

- 모든 icon-only 버튼 label.
- Star rating: "별점 3점" 식으로 읽기.
- 색 점에는 category name text 대체 제공.
- Dynamic Type에서 버튼/필드 잘림 없어야 함.
- Touch target 최소 44x44.

## 10. Design QA

- iPhone SE, 15, 15 Pro Max에서 주요 화면 확인.
- 라이트 모드 우선, 다크 모드 optional.
- 키보드 표시 시 저장 버튼/입력 중인 필드가 가려지지 않음.
- 긴 제목/긴 카테고리명/사진 없음/기록 없음 상태 확인.

