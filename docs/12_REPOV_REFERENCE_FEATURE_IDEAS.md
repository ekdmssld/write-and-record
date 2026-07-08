# Write & Record - Repov Reference Feature Ideas

목적: Repov를 모티브로 삼되, 그대로 복제하지 않고 Write & Record에 맞게 가져올 수 있는 기능을 정리한다. 기준은 "하루하루 기록하고 다시 확인하는 핵심 경험을 강화하는가"이다.

참고한 출처:
- Repov 기능 소개 페이지: https://page.repov.me/ndvwx72834911m3z6jpg
- Repov 공식 소개 페이지: https://page.repov.me/
- Repov App Store 페이지: https://apps.apple.com/kr/app/id6502975294

중요 원칙:
- Repov의 기능을 그대로 베끼지 않는다.
- Write & Record는 캘린더 중심의 개인 기록 앱이다.
- 기능 추가는 기록 작성/확인/보존을 방해하지 않아야 한다.
- 소셜 기능은 명시적 opt-in과 공개 범위 제어가 먼저다.

## 1. Reference Summary

Repov에서 관찰한 핵심 축:
- 미니 블로그형 개인 공간.
- 일상, 영화, 책, 음악, 맛집, 장소 등 다양한 카테고리 기록.
- 앱 안에서 영화/책/음악/장소 정보 검색 및 포스터/표지/이미지 삽입.
- 이미지, 인용문, 팁, 장점/단점, URL을 담을 수 있는 기록 템플릿.
- 캘린더, 평점, 지도, 타임라인, 갤러리로 기록을 다시 보기.
- 친구와 기록 공유.
- 친구 기록 홈 화면 위젯.
- 공개/친구/친한 친구/비공개 공개 범위.
- 좋아요, 댓글, 비밀 댓글.
- 메인 피드 카테고리 필터.
- 인용구 위젯.
- 월간 이미지 캘린더.
- 위시리스트.
- 여러 기기 동기화.

Write & Record에 맞는 해석:
- 기능의 양보다 "내 기록이 잘 쌓이고 다시 보이는 구조"를 먼저 가져온다.
- 소셜/위젯/댓글은 매력적이지만, 데이터 안정성과 공개 범위가 선행되어야 한다.
- 검색 기반 빠른 기록과 기록 재정리는 Write & Record와 궁합이 좋다.

## 2. Feature Ideas To Adopt

### A. 앱 안 정보 검색으로 빠른 기록

Repov reference:
- 영화/책/음악/장소 정보를 앱 안에서 검색하고 포스터, 표지, 이미지를 삽입한다.

Write & Record adaptation:
- EntryEditor에서 카테고리에 따라 "정보 검색" 버튼을 제공한다.
- 영화/TV: 제목, 포스터, 감독, 출연진, 플랫폼.
- 책: 제목, 표지, 작가, 출판사.
- 음악: 곡/앨범, 아티스트, 커버.
- 장소/음식: 장소명, 주소, 대표 이미지 optional.

우선순위:
- P1.5 또는 P2.

이유:
- 직접 타이핑 부담을 줄여 첫 기록 완성률을 높인다.
- 기록이 카드/갤러리에서 더 예쁘게 보인다.

주의:
- API 비용과 저작권/이미지 사용 정책 확인 필요.
- 검색 실패 시 수동 입력이 가능해야 한다.

### B. 카테고리별 세부 템플릿 강화

Repov reference:
- 이미지, 인용문, 팁, 장점/단점, URL 등 다양한 기록 템플릿 제공.

Write & Record adaptation:
- 기존 Entry 단일 모델은 유지한다.
- `metadata`를 사용해 카테고리별 입력 블록을 제공한다.

추천 템플릿:
- 일상: 오늘의 한 줄, 기분, 기억할 순간.
- 영화/TV: 별점, 감상, 기억나는 장면, 스포일러 여부.
- 책: 인용문, 감상, 페이지, 읽은 상태.
- 음악: 들은 순간, 무드, favorite line short.
- 음식/장소: 장점, 단점, 팁, 재방문 의사, URL.
- 덕질: 대상, 콘텐츠 타입, 이벤트, 굿즈.

우선순위:
- P1.

이유:
- 기록이 단순 메모가 아니라 "나중에 다시 읽기 좋은 구조"가 된다.

주의:
- 입력 화면이 무거워지지 않도록 세부 블록은 접힌 상태로 둔다.

### C. 월간 이미지 캘린더

Repov reference:
- 한 달치 기록을 이미지 캘린더로 만들어 간직할 수 있다.

Write & Record adaptation:
- 월별 캘린더를 이미지로 export한다.
- 날짜별 대표 기록, 카테고리 색, 대표 사진 thumbnail을 넣는다.
- 초기에는 "기록 개수 + 카테고리 점"만 있는 simple export로 시작한다.

우선순위:
- P2.

이유:
- 공유보다 개인 보관 가치가 크다.
- 기록 앱의 성취감을 만든다.

출력:
- 1080x1350 portrait.
- 1080x1080 square optional.
- 저장/공유 sheet.

### D. 친구 기록 위젯

Repov reference:
- 홈 화면 위젯에서 친구의 일상/영화/책/음악 기록을 보고 좋아요/댓글을 남길 수 있다.
- 팔로워 기록 위젯과 친한 친구 기록 위젯이 분리되어 있다.
- 비공개 기록은 위젯에 표시되지 않는다고 안내한다.

Write & Record adaptation:
- iOS WidgetKit 기반 "친구 기록 위젯"을 P3 이후 검토한다.
- 위젯에는 친구 공개 또는 친한 친구 공개 기록만 표시한다.
- 위젯에서 직접 댓글 입력은 초기에는 하지 않는다.
- tap하면 앱의 SocialEntryDetail로 이동한다.

우선순위:
- P3.

위젯 종류:
- 내 오늘 기록 위젯: P2 추천.
- 친구 기록 위젯: P3 추천.
- 인용구 위젯: P2 추천.

주의:
- 공개 범위 검증이 최우선.
- Widget timeline에 민감한 본문을 오래 캐시하지 않도록 주의.

### E. 인용구 위젯

Repov reference:
- 소중한 인용구를 홈 화면에서 매일 확인하는 위젯이 출시됨.

Write & Record adaptation:
- 책/영화/일상 기록에서 `quote` 또는 "기억할 문장"을 따로 저장한다.
- 위젯은 내가 저장한 문장만 보여준다.
- 소셜보다 먼저 만들 수 있는 안전한 개인화 기능이다.

우선순위:
- P2.

이유:
- 개인 기록 앱의 감성에 잘 맞는다.
- privacy risk가 낮다.

### F. 메인 피드 카테고리 필터

Repov reference:
- 메인 피드에서 원하는 카테고리만 골라 볼 수 있다.

Write & Record adaptation:
- Social 전체/친구들 피드에 카테고리 필터를 제공한다.
- Library 타임라인에도 동일한 필터 UX를 재사용한다.

우선순위:
- Library: P1.
- Social: P3.

필터:
- 전체.
- 일상.
- 음식/장소.
- 영화/TV.
- 책.
- 음악.
- 덕질.
- 커스텀.

### G. 친한 친구 공개 범위

Repov reference:
- 전체 공개, 친구 공개, 친한 친구 공개, 비공개 총 4개 공개 범위를 지원한다.

Write & Record adaptation:
- 기존 문서의 `private / friends / public`을 기본으로 유지한다.
- P3 이후 `closeFriends`를 추가 검토한다.

추천 공개 범위 단계:
1. P0/P1: private only.
2. P3 Social v1: private / friends / public.
3. Social v2: private / closeFriends / friends / public.

이유:
- 처음부터 4단계 공개 범위를 넣으면 사용자가 헷갈릴 수 있다.
- 하지만 친구 위젯과 친밀한 공유를 생각하면 closeFriends는 장기적으로 유용하다.

### H. 좋아요/댓글/비밀 댓글

Repov reference:
- 친구 기록에 좋아요와 댓글을 남길 수 있고, 비밀 댓글 기능도 있음.

Write & Record adaptation:
- 초기 Social에서는 댓글을 미룬다.
- reaction은 P3 Social v2에서 "공감" 정도로 가볍게 시작한다.
- 비밀 댓글은 관계/알림/신고 UX가 복잡하므로 후순위.

우선순위:
- 좋아요/공감: P3.
- 댓글: P4.
- 비밀 댓글: P4 또는 보류.

이유:
- 댓글은 사용자 생성 콘텐츠 moderation 부담이 크다.
- 개인 기록 앱의 차분한 분위기를 해칠 수 있다.

### I. 지도 보기 강화

Repov reference:
- 지도 보기로 기록을 정리할 수 있다.

Write & Record adaptation:
- 장소가 있는 기록만 지도에 표시한다.
- 내 기록 지도부터 만든다.
- 친구/전체 지도는 공개 범위가 안정된 뒤 검토한다.

우선순위:
- 내 지도: P2.
- 소셜 지도: 보류.

주의:
- 위치 권한 없이도 수동 장소 입력 가능해야 한다.
- 정확한 위치 공개는 위험하므로 소셜에서는 장소명 중심으로 축약한다.

### J. 위시리스트 독립 화면

Repov reference:
- 해보고 싶은 것들을 위시리스트에서 확인할 수 있다.

Write & Record adaptation:
- 기존 `isWishlist`를 적극 활용한다.
- Search 또는 Library 안에 Wishlist smart collection을 둔다.

우선순위:
- P1.

Wishlist 분류:
- 보고 싶은 영화/TV.
- 읽고 싶은 책.
- 가고 싶은 장소/맛집.
- 사고 싶은 것.
- 하고 싶은 일.

### K. 공개 리뷰/평점 탐색

Repov reference:
- 다른 사람들의 평가를 보고 선택에 도움을 받을 수 있다.

Write & Record adaptation:
- Social 전체 탭에서 public 기록을 category별로 탐색한다.
- 영화/책/장소는 별점과 짧은 감상 중심으로 보여준다.
- 추천 알고리즘보다 최신/카테고리 필터부터 시작한다.

우선순위:
- P3.

주의:
- Write & Record의 중심은 리뷰 플랫폼이 아니라 개인 기록장이다.
- 리뷰 탐색이 홈의 중심을 빼앗지 않게 한다.

### L. 여러 기기 동기화

Repov reference:
- 로그인 기능과 여러 기기 동기화가 제공된다.

Write & Record adaptation:
- P0는 local-first.
- P2 이후 iCloud 또는 Supabase/Firebase sync 검토.
- sync보다 export/import가 먼저다.

우선순위:
- Export: P0.
- Import: P1/P2.
- Cloud sync: P3.

이유:
- 개인 기록 앱은 데이터 유실이 치명적이다.
- sync는 편하지만 충돌/비용/계정/보안 이슈가 크다.

### M. Mac/iPad 입력 경험

Repov App Store 리뷰에서 얻은 힌트:
- 긴 기록은 컴퓨터나 큰 화면에서 쓰고 싶어 하는 사용자가 있다.

Write & Record adaptation:
- iPad layout을 먼저 대응한다.
- Mac Catalyst 또는 웹 companion은 장기 검토.
- 최소한 export/import와 keyboard-friendly editor는 고려한다.

우선순위:
- iPad responsive: P2.
- Mac/web companion: P4.

## 3. Recommended Priority For Write & Record

### Must Not Distract From P0

P0에는 넣지 않는다:
- 친구 위젯.
- 댓글.
- 공개 피드.
- cloud sync.
- 외부 정보 검색 API.
- 월간 이미지 캘린더.

P0에 영향만 줄 것:
- Entry 모델에 향후 `visibility` 확장 여지를 둔다.
- metadata 구조를 템플릿에 맞게 열어둔다.
- 위시리스트와 quote 필드를 metadata로 담을 수 있게 한다.

### P1 추천

- 카테고리별 세부 템플릿.
- Library 카테고리 필터.
- Wishlist smart collection.
- 검색/필터 개선.
- 빠른 날짜 추가 UX.

### P2 추천

- 월간 이미지 캘린더 export.
- 인용구/문장 저장.
- 내 기록 위젯.
- 지도 보기.
- record card 개선.
- iPad layout.

### P3 추천

- Social 전체/친구들/추가.
- public/friends visibility.
- 친구 요청/초대.
- 메인 피드 카테고리 필터.
- 친구 기록 위젯.
- public profile.
- cloud sync.

### P4 또는 보류

- 댓글.
- 비밀 댓글.
- 추천 알고리즘.
- 연락처 기반 친구 찾기.
- 소셜 지도.
- Mac/web companion.

## 4. Design/UX Takeaways

좋은 점으로 가져올 것:
- "내 손 안의 미니 블로그" 감성.
- 카테고리별 기록의 재미.
- 기록을 여러 방식으로 다시 보는 구조.
- 위젯으로 기록을 생활 속에 꺼내두는 아이디어.
- 월간 이미지/카드처럼 기록을 소장품으로 만드는 방식.

조심할 점:
- 기능이 많아지면 매일 기록 앱이 무거워진다.
- 소셜은 사용자에 따라 매력보다 부담일 수 있다.
- 공개 범위가 복잡하면 신뢰가 떨어진다.
- 댓글/비밀 댓글은 moderation과 알림 피로를 만든다.
- 외부 정보 검색은 API와 데이터 품질 관리가 필요하다.

## 5. Product Decisions To Carry Forward

결정:
- Write & Record는 처음부터 소셜 네트워크로 가지 않는다.
- 핵심은 개인 기록, 소셜은 선택 기능이다.
- Repov의 기능 중 즉시 가져올 것은 "기록 템플릿/정리/위시리스트" 계열이다.
- "친구 위젯/댓글/공개 피드"는 공개 범위와 safety가 준비된 뒤에 가져온다.
- closeFriends는 유용하지만 Social v2로 미룬다.

기능 후보 중 가장 추천:
1. 카테고리별 세부 템플릿.
2. Wishlist smart collection.
3. 월간 이미지 캘린더.
4. 인용구/문장 위젯.
5. 앱 안 정보 검색.
6. Social 피드 카테고리 필터.
7. 친구 기록 위젯.

## 6. Implementation Notes

Model extension ideas:

```text
Entry
  visibility: private/friends/public
  quote: String? or metadata.quote
  wishlistType: movie/book/place/food/item/activity
  sourceInfoId: String?
  externalPosterUrl: String?

UserProfile
  publicProfileEnabled: Bool
  closeFriendEnabled: Bool later

Collection
  type: manual/smart
  smartRule: wishlist/rating5/recent/category/quotes
```

Service ideas:

```text
ExternalSearchService
  searchMovie()
  searchBook()
  searchMusic()
  searchPlace()

MonthlyCalendarExportService
  renderMonthImage()

QuoteWidgetProvider
  fetchDailyQuote()

SocialFeedRepository
  fetchPublicFeed(categoryFilter)
  fetchFriendFeed(categoryFilter)
```

## 7. Source Notes

Repov feature intro page specifically highlights the friend home-screen widget, follower vs close-friend widget types, likes/comments, and reassurance that private logs are not shown.

Repov official page highlights multi-category recording, in-app search for movie/book/music/place data, templates with images/quotes/tips/pros/cons/URL, friend sharing, other users' reviews/ratings, calendar/rating/map/timeline/gallery views, record cards, and wishlist.

Repov App Store page additionally mentions 40+ categories, photo cards, monthly image calendar, 4 visibility levels, multi-device sync, main feed category filters, quote widget, secret comments, and privacy/data considerations.
