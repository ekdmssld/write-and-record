# Write & Record - Social UX Spec

목적: Social 화면의 탭 구조, 화면 흐름, 버튼, 상태, 문구를 정의한다. 이 문서는 `10_SOCIAL_FEATURE_SPEC.md`의 UX 구현 기준이다.

핵심 UX:
- 상단에는 `전체 / 친구들 / 추가` 세그먼트가 있다.
- `전체`는 공개 설정된 모든 사용자와 공개 기록을 둘러보는 곳이다.
- `친구들`은 내 친구들의 기록을 확인하고, 바로 찾기/초대하기로 이어지는 곳이다.
- `추가`는 친구 찾기와 초대 관리를 위한 전용 화면이다.
- 소셜을 켜지 않은 사용자는 먼저 안전한 opt-in 안내를 본다.

## 1. Social Entry

진입 위치:
- 하단 탭에 `소셜`을 둘 수 있다.
- 또는 `내 공간` 안의 `친구/공유`에서 진입할 수 있다.

초기 추천:
- P0에서는 `내 공간 -> 친구/공유` 진입.
- Social 기능이 안정되면 하단 탭 독립 승격 검토.

첫 진입:
- socialEnabled가 false면 SocialIntroView를 보여준다.
- 설명은 짧고, 기본 비공개 원칙을 먼저 말한다.

Intro copy:

```text
친구와 기록을 나눠볼까요?
기본적으로 내 기록은 나만 볼 수 있어요.
공개하거나 친구에게 보여주기로 선택한 기록만 소셜에 나타나요.
```

Primary CTA:
- "소셜 기능 켜기"

Secondary:
- "나중에 할게요"

## 2. Top Segmented Tabs

탭:
- 전체
- 친구들
- 추가

Interaction:
- 탭은 상단에 고정.
- 선택된 탭은 filled pill.
- 탭 전환 시 scroll position은 탭별로 유지.
- badge가 필요한 경우 친구들/추가에만 표시.

Badge 예:
- 친구들: 새 친구 기록 수 optional.
- 추가: 받은 요청 수.

Accessibility:
- "전체 탭, 선택됨"
- "친구들 탭, 받은 요청 2개"
- "추가 탭"

## 3. 전체 Tab

목표:
- 공개된 사용자와 공개 기록을 조용히 발견한다.
- 인기 경쟁보다 취향 탐색 느낌을 준다.

Top area:
- title: "전체"
- subtitle: "공개된 기록 공간을 둘러봐요."
- optional search field: "사용자나 기록 검색"

Content sections:
1. 공개 사용자
2. 공개 기록

### Public User Card

요소:
- avatar.
- nickname.
- spaceName.
- public record count.
- 최근 기록 preview optional.
- 상태 버튼:
  - "친구 추가"
  - "요청됨"
  - "친구"

Card action:
- 카드 탭 -> PublicProfileView.
- 친구 추가 버튼 -> request confirmation 또는 즉시 요청.

### Public Entry Card

요소:
- author avatar/nickname.
- date.
- category chip.
- title.
- body preview max 2 lines.
- cover image optional.
- visibility badge: "전체 공개" optional.

Action:
- tap -> SocialEntryDetailView.
- overflow -> 신고/차단.

Empty state:

```text
아직 공개된 기록이 많지 않아요
내 기록은 공개로 바꾸기 전까지 여기 보이지 않아요.
```

Error state:

```text
공개 기록을 불러오지 못했어요
다시 시도
```

## 4. 친구들 Tab

목표:
- 친구들의 최근 기록을 보고, 친구가 없으면 바로 찾기/초대하기로 이어진다.

Top area:
- title: "친구들"
- subtitle:
  - 친구 있음: "친구들이 공유한 기록이에요."
  - 친구 없음: "함께 기록을 나눌 친구를 찾아볼까요?"

필수 quick actions:
- `찾기`
- `초대하기`

권장 배치:
- title/subtitle 아래에 2-column action row.
- 찾기: 앱 내 사용자 검색.
- 초대하기: iOS share sheet or invite link screen.

### Friend Action Buttons

찾기:
- icon: magnifyingglass
- label: "찾기"
- helper: "닉네임으로 친구 찾기"
- destination: SocialUserSearchView

초대하기:
- icon: paperplane or link
- label: "초대하기"
- helper: "링크로 친구 초대"
- destination: InviteFriendView/share sheet

### Friend Feed

요소:
- 친구가 공유한 friends/public 기록.
- 최신순.
- 같은 친구 기록이 연속될 때 author header 반복 최소화 optional.

Entry card:
- friend avatar.
- friend nickname.
- category/date.
- title.
- short preview.
- photo thumbnail optional.

### Friend List Preview

친구 피드 위 또는 아래:
- "내 친구"
- horizontal friend avatars.
- "전체 보기"

친구 없음 empty:

```text
아직 친구가 없어요
닉네임으로 찾거나 초대 링크를 보내보세요.
```

Primary actions:
- "친구 찾기"
- "초대 링크 보내기"

친구는 있지만 기록 없음:

```text
친구들이 아직 공유한 기록이 없어요
친구 공개 기록이 생기면 여기에 모여요.
```

받은 요청 banner:

```text
받은 친구 요청 2개
확인하기
```

## 5. 추가 Tab

목표:
- 친구 추가 관련 작업을 한 곳에서 처리한다.

Top area:
- title: "추가"
- subtitle: "친구를 찾고 초대할 수 있어요."

Sections:
1. 검색
2. 초대 링크
3. 받은 요청
4. 보낸 요청
5. 추천 optional

### Search Section

Search field:
- placeholder: "닉네임 또는 공간 이름 검색"

Search result card:
- avatar.
- nickname.
- spaceName.
- mutual info optional.
- button:
  - "추가"
  - "요청됨"
  - "수락"
  - "친구"

검색 결과 없음:

```text
찾는 사용자가 없어요
닉네임을 다시 확인하거나 초대 링크를 보내보세요.
```

### Invite Section

Card:
- title: "초대 링크 만들기"
- body: "앱을 쓰지 않는 친구에게도 보낼 수 있어요."
- primary: "링크 공유"
- secondary: "링크 복사"

After created:
- invite preview.
- copy button.
- share button.
- revoke optional.

### Requests Section

받은 요청:
- requester card.
- "수락"
- "거절"

보낸 요청:
- target card.
- status "요청됨"
- "취소" optional.

## 6. Public Profile View

목표:
- 공개된 사용자의 기록 공간을 가볍게 둘러본다.

Header:
- avatar.
- nickname.
- spaceName.
- bio optional.
- public record count.
- friend status button.
- overflow: 신고/차단.

Tabs:
- 공개 기록.
- 공개 컬렉션 P2.

Visibility:
- public profile만 전체에서 진입 가능.
- friendsOnly profile은 친구에게만 진입 가능.

Empty:

```text
아직 공개한 기록이 없어요
```

## 7. Social Entry Detail

목표:
- 친구/공개 기록을 읽되, 내 개인 기록 상세와 혼동하지 않는다.

Header:
- author.
- visibility badge.
- date/category.

Content:
- title.
- body.
- photos.
- metadata if public-safe.

Actions:
- 친구 추가.
- 신고.
- 차단.
- 좋아요(♡/♥ + 개수) — 구현됨.
- 댓글(목록 + 입력창, 1~300자) — 구현됨. 본인 댓글만 삭제 가능, 타인 댓글은 신고 가능.

금지:
- private editor action 노출.
- 내 기록이 아닌데 edit/delete 표시.
- 다른 사용자 기록의 전체 body 노출 — 상세에서도 bodyPreview까지만 보여준다. 내 기록일 때만 전체 본문/사진을 보여준다.

댓글 empty state:

```text
아직 댓글이 없어요. 첫 댓글을 남겨보세요.
```

## 8. Share Visibility UX

기록 저장/수정 시 공개 범위 선택:
- 기본: 나만 보기.
- options:
  - 나만 보기
  - 친구에게 공개
  - 전체 공개

권장 UI:
- bottom sheet.
- 짧은 설명.
- 현재 선택 상태 checkmark.

Copy:

```text
나만 보기
내 공간에만 저장돼요.

친구에게 공개
친구들이 소셜에서 볼 수 있어요.

전체 공개
공개된 모든 사용자가 볼 수 있어요.
```

전체 공개 confirm:

```text
전체 공개로 바꿀까요?
이 기록은 공개 사용자에게 보일 수 있어요.
```

Actions:
- "전체 공개"
- "취소"

## 9. Notification UX

알림 유형:
- 친구 요청 도착.
- 친구 요청 수락.
- 친구의 새 공개 기록 optional.
- 초대 링크로 가입 optional.

Notification settings:
- 친구 요청 알림.
- 친구 기록 알림.
- 초대 알림.

기본:
- 소셜 알림은 사용자가 켠 경우에만 요청.

## 10. Moderation UX

Overflow menu:
- 신고하기.
- 차단하기.
- 이 사용자 숨기기 optional.

신고 이유:
- 스팸.
- 불쾌하거나 부적절함.
- 개인정보 침해.
- 괴롭힘.
- 기타.

차단 confirm:

```text
이 사용자를 차단할까요?
서로의 프로필과 기록을 볼 수 없고, 친구 요청도 받을 수 없어요.
```

차단 후:
- 피드에서 즉시 제거.
- Settings -> Blocked users에서 해제 가능.

## 11. Screen State Matrix

전체:
- loading.
- loaded public users.
- loaded public feed.
- empty.
- error.
- blocked content removed.

친구들:
- no friends.
- friends but no shared entries.
- friend feed loaded.
- request banner.
- error.

추가:
- idle search.
- typing search.
- no result.
- result loaded.
- invite created.
- request accepted.
- request declined.
- error.

## 12. Copy Tone

톤:
- 안전하고 부드럽게.
- 공개 범위를 과장하지 않고 정확히.
- 친구 수를 경쟁처럼 보이게 하지 않는다.

좋은 문구:
- "공개한 기록만 보여요."
- "친구들이 공유한 기록이에요."
- "닉네임으로 친구를 찾아볼까요?"
- "초대 링크를 보내보세요."
- "이 기록은 나만 볼 수 있어요."

피할 문구:
- "인기 있는 사용자"
- "팔로워를 늘려보세요"
- "모두에게 공유하세요"
- "친구들이 기다리고 있어요"

## 13. Visual Direction

Social은 Library보다 조금 더 사람 중심이지만, 여전히 기록 앱의 차분함을 유지한다.

UI 원칙:
- 공개 범위 badge는 명확하게.
- friend action buttons는 secondary surface 위에 둔다.
- public feed card는 기록 카드와 비슷하지만 author 영역을 추가한다.
- CTA 색은 primary 하나만 강하게 사용한다.
- 전체/친구들/추가 탭은 상단에서 항상 이해 가능해야 한다.

권장 card density:
- 전체: 사용자 card + 기록 card 혼합, 너무 빽빽하지 않게.
- 친구들: action buttons를 먼저, feed는 그 아래.
- 추가: form/list 중심으로 실용적으로.

## 14. Acceptance Criteria

UX P0:
- Social 화면 진입 시 `전체 / 친구들 / 추가`가 보인다.
- 전체 탭에서 공개 사용자/공개 기록의 의미가 명확하다.
- 친구들 탭에 `찾기`, `초대하기` 버튼이 있다.
- 친구 없음 상태에서 찾기/초대하기로 바로 이동 가능하다.
- 추가 탭에서 검색과 초대가 가능해 보인다.
- 공개 범위가 사용자에게 명확히 설명된다.
- 신고/차단 진입점이 있다.

UX P1 (구현 완료):
- 받은 요청 badge (친구들 탭 배너 + 추가 탭 목록).
- 친구 목록 preview + 전체보기 화면(검색/삭제).
- PublicProfileView.
- SocialEntryDetail (좋아요/댓글 포함).
- 공개 범위 변경 bottom sheet.
- 내가 공유한 기록 화면, 차단한 사용자 관리 화면, 소셜 설정(프로필 공개범위/알림).

UX P2:
- QR invite (구현됨) — 초대 시트에 QR 이미지를 함께 보여준다.

남은 항목:
- 추천 사용자.
- 공개 컬렉션.

reaction/댓글은 원래 P2였으나 이번에 P1과 함께 구현했다 (docs/10 15장 결정 변경).

## 15. Final UX Rule

소셜 화면은 "더 많이 공유하게 만드는 곳"이 아니라, "내가 선택한 만큼만 안전하게 나누는 곳"이어야 한다.
