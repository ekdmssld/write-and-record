# Write & Record - Social Feature Spec

목적: Write & Record의 소셜 기능을 "개인 기록을 해치지 않는 선택적 공유 공간"으로 설계한다. 기본 기록은 비공개이며, 사용자가 명시적으로 공개한 프로필/기록만 소셜 화면에 나타난다.

핵심 판단:
- 소셜은 P3 기능이지만, 데이터 모델과 공개 범위는 초기부터 안전하게 설계한다.
- Social 화면의 상단 탭은 `전체 / 친구들 / 추가` 3개다.
- `전체`는 이 앱에서 공개 설정된 모든 사용자를 볼 수 있는 영역이다.
- `친구들`은 내 친구들의 공개/친구 공개 기록과 친구 관리 진입점이다.
- `추가`는 친구 찾기, 초대, 요청 관리에 집중한 영역이다.
- 개인 기록 앱의 신뢰를 해치지 않기 위해 기본 공개 범위는 항상 `private`이다.

## 1. Product Goal

소셜 기능의 목표:
- 친구의 취향과 기록을 가볍게 발견한다.
- 내가 공개하고 싶은 기록만 선택적으로 공유한다.
- 공개/친구 공개/비공개 경계를 사용자가 쉽게 이해한다.
- 친구 초대와 찾기를 간단하게 만든다.

소셜 기능이 하지 않을 것:
- 모든 기록을 자동 공개하지 않는다.
- 팔로워 수, 인기 순위, 과한 경쟁 지표를 전면에 두지 않는다.
- 사용자의 비공개 제목/본문/사진을 서버나 피드에 노출하지 않는다.
- 친구 기능을 쓰지 않는 사용자에게 계속 사용을 압박하지 않는다.

## 2. Feature Flag and Release Mode

Feature flag:
- `enableFriendFeatures`
- `enablePublicSocialFeed`
- `enableFriendInvite`
- `enableSocialNotifications`
- `enableReportAndBlock`

초기값:
- Debug: on 가능.
- PersonalRelease: off.
- BetaRelease: limited on.
- StoreRelease: privacy/review 준비 후 on.

Release gate:
- 기록 단위 공개 범위가 구현되어야 한다.
- 차단/신고 최소 기능이 있어야 한다.
- 공개 프로필 수정/비공개 전환이 가능해야 한다.
- 개인정보 처리방침에 소셜 공개 데이터 설명이 있어야 한다.

## 3. Social Information Architecture

앱 하단 탭 또는 My Space 내부에서 Social 진입:

```text
Social
  전체
  친구들
  추가
```

### 전체

정의:
- 앱에서 프로필 공개를 켠 사용자와 그 사용자의 public 기록을 볼 수 있는 영역.

보이는 대상:
- `publicProfileEnabled == true`인 사용자.
- `visibility == public`인 기록.
- 차단한 사용자와 나를 차단한 사용자는 제외.

주요 기능:
- 공개 사용자 둘러보기.
- 공개 기록 피드 보기.
- 사용자 프로필/공간 방문.
- 공개 기록 상세 보기.
- 친구 추가 요청 보내기.
- 신고/차단.

### 친구들

정의:
- 내 친구들의 공개 또는 친구 공개 기록을 보는 영역.

보이는 대상:
- friendship 상태가 `accepted`인 사용자.
- 친구의 `visibility == friends` 또는 `visibility == public` 기록.
- 친구가 나를 차단했거나 내가 친구를 차단한 경우 제외.

주요 기능:
- 친구 피드.
- 친구 목록.
- 찾기 버튼.
- 초대하기 버튼.
- 받은 요청/보낸 요청 확인.
- 친구 공간 방문.
- 친구 삭제/차단.

필수 버튼:
- `찾기`: 앱 내 사용자 검색 화면으로 이동.
- `초대하기`: 초대 링크/공유 sheet로 이동.

### 추가

정의:
- 친구를 늘리기 위한 전용 허브.

주요 기능:
- 사용자 검색.
- 추천 사용자.
- 초대 링크 만들기.
- 연락처 기반 찾기 optional.
- QR/초대 코드 optional.
- 받은 친구 요청.
- 보낸 친구 요청.

초기 구현:
- 사용자 검색.
- 초대 링크 공유.
- 받은/보낸 요청 리스트.

P2 이후:
- 연락처 매칭.
- QR 코드.
- 추천 사용자.

## 4. Visibility Model

기록 공개 범위:
- `private`: 나만 볼 수 있음. 기본값.
- `friends`: 친구만 볼 수 있음.
- `public`: 전체 소셜에 공개.

프로필 공개 범위:
- `profileVisibility == private`: 검색/전체에 노출되지 않음.
- `profileVisibility == friendsOnly`: 친구에게만 프로필 표시.
- `profileVisibility == public`: 전체에 프로필 표시.

중요 규칙:
- 새 기록의 기본값은 `private`.
- 사용자가 이전에 선택한 공개 범위를 자동 재사용하지 않는다. 자동 재사용은 P2에서 별도 설정으로만 허용한다.
- 친구 공개 기록은 친구 관계가 끊기면 더 이상 보이지 않는다.
- public 기록은 사용자가 언제든 private으로 되돌릴 수 있다.
- 기록을 삭제하면 모든 소셜 피드에서도 사라진다.
- 공개 범위를 바꿀 때 변경 결과를 명확히 안내한다.

공개 전 확인 문구:
- public: "이 기록은 전체 사용자가 볼 수 있어요."
- friends: "이 기록은 친구들만 볼 수 있어요."
- private: "이 기록은 나만 볼 수 있어요."

## 5. User Roles

Owner:
- 내 기록 공개 범위 설정.
- 내 공개 프로필 관리.
- 친구 요청 수락/거절.
- 차단/신고.

Public Viewer:
- 전체 탭에서 public 프로필과 public 기록을 볼 수 있음.
- 친구 요청을 보낼 수 있음.
- private/friends 기록은 볼 수 없음.

Friend:
- 친구 공개 기록을 볼 수 있음.
- 친구 목록에 표시됨.
- 친구 관계 삭제 가능.

Blocked User:
- 서로의 프로필/기록/요청을 볼 수 없음.
- 검색 결과에서 제외.

## 6. Data Model

### UserPublicProfile

- id: String
- userId: String
- nickname: String
- avatarAssetId: String?
- spaceName: String
- bio: String?
- themeId: String
- profileVisibility: private/friendsOnly/public
- publicProfileEnabled: Bool
- recordCountPublic: Int
- friendCountVisible: Bool
- createdAt: Date
- updatedAt: Date

### EntryVisibility

Entry에 추가:
- visibility: private/friends/public
- sharedAt: Date?
- unsharedAt: Date?
- shareCaption: String?
- allowFriendReactions: Bool
- allowPublicReactions: Bool

### Friendship

- id: String
- requesterId: String
- addresseeId: String
- status: pending/accepted/declined/canceled/removed/blocked
- requestedAt: Date
- respondedAt: Date?
- updatedAt: Date

규칙:
- 같은 두 사용자 사이 accepted friendship은 하나만 존재.
- 내가 보낸 pending 요청과 받은 pending 요청을 구분해서 표시.
- block은 friendship보다 우선한다.

### SocialInvite

- id: String
- inviterId: String
- inviteCode: String
- inviteUrl: String
- status: active/used/expired/revoked
- maxUses: Int?
- usedCount: Int
- expiresAt: Date?
- createdAt: Date

### SocialReaction

초기 optional:
- id: String
- entryId: String
- userId: String
- type: like/bookmark
- createdAt: Date

P0 Social에서는 reaction 없이도 가능.

### Report

- id: String
- reporterId: String
- targetType: user/entry
- targetId: String
- reason: spam/harassment/privacy/inappropriate/other
- message: String?
- createdAt: Date

### Block

- id: String
- blockerId: String
- blockedUserId: String
- createdAt: Date

## 7. Repository and Service Interfaces

권장 protocol:

```text
SocialFeedRepository
  fetchPublicUsers()
  fetchPublicFeed()
  fetchFriendFeed()
  fetchUserPublicProfile(userId)

FriendRepository
  fetchFriends()
  searchUsers(query)
  sendFriendRequest(userId)
  acceptRequest(requestId)
  declineRequest(requestId)
  removeFriend(userId)

InviteService
  createInviteLink()
  revokeInvite(inviteId)
  resolveInvite(code)

PrivacyService
  updateProfileVisibility()
  updateEntryVisibility()

ModerationService
  reportUser()
  reportEntry()
  blockUser()
  unblockUser()
```

구현 원칙:
- View에서 직접 네트워크 호출하지 않는다.
- 공개 범위 필터는 클라이언트와 서버 양쪽에서 적용한다.
- 서버가 없는 초기 mock 단계에서도 같은 protocol을 유지한다.

## 8. Feed Rules

전체 피드:
- public 기록만 표시.
- 최신순 기본.
- 내 기록도 public이면 표시 가능.
- 차단 관계 제외.
- 삭제/비공개 전환 즉시 제거.

친구 피드:
- 친구의 friends/public 기록 표시.
- 최신순 기본.
- 친구별 필터 P1.
- 기록 없는 친구는 친구 목록에는 보이되 feed에는 표시하지 않는다.

사용자 카드:
- avatar.
- nickname.
- spaceName.
- public record count.
- 최근 public 기록 preview optional.
- 친구 추가/요청됨/친구 상태.

기록 카드:
- 작성자.
- 날짜.
- 카테고리.
- 제목.
- body preview.
- cover image optional.
- visibility badge optional.

## 9. Friend Request Rules

상태:
- Not friends.
- Request sent.
- Request received.
- Friends.
- Blocked.

규칙:
- 이미 요청을 보낸 사용자에게 중복 요청 불가.
- 받은 요청이 있으면 "수락"과 "거절" 표시.
- 친구가 되면 친구 피드에 표시.
- 친구 삭제 시 상대에게 알림을 보내지 않는다.
- 차단 시 기존 friendship/request는 숨김 또는 blocked 상태로 전환한다.

알림:
- 친구 요청 도착.
- 친구 요청 수락.
- 초대 가입 완료 optional.

## 10. Invite Rules

초대하기 목적:
- 친구가 앱에 없거나 검색하기 어려울 때 공유 링크로 초대한다.

초대 링크 동작:
- 앱 설치됨: 앱 열기 -> 초대 수락 화면.
- 앱 미설치: App Store 또는 안내 페이지.
- 로그인 전: 로그인/가입 후 초대 요청 이어가기.

초대 링크 정보:
- inviter nickname.
- inviter spaceName.
- inviteCode.
- expiration optional.

공유 문구 예:

```text
Write & Record에서 나랑 기록을 공유해볼래?
내 기록 공간으로 초대할게.
```

## 11. Privacy and Safety

필수:
- 기본 공개 범위 private.
- 공개 전 확인.
- 공개 범위 변경 가능.
- 친구 삭제.
- 차단.
- 신고.
- public profile off.
- 내 public 기록 한 번에 보기.

금지:
- 비공개 기록을 추천/검색/전체 피드에 노출.
- 친구 요청 수락 전 friends 기록 노출.
- 차단한 사용자에게 내 프로필 노출.
- 개인 기록 본문을 analytics/log에 전송.
- 연락처 업로드를 기본 on으로 두기.

연락처 찾기:
- P2 이후.
- 명시적 opt-in.
- 연락처 원문 저장 금지.
- 해시 매칭 등 최소화 설계 필요.

## 12. Settings

Social settings:
- socialEnabled.
- profileVisibility.
- defaultEntryVisibility: 기본은 private, 변경은 고급 설정.
- allowFriendRequests.
- blockedUsers.
- publicEntries.
- inviteLinks.

Settings copy:
- "기본적으로 모든 기록은 나만 볼 수 있어요."
- "공개한 기록만 전체/친구 피드에 보여요."
- "언제든 공개 범위를 바꿀 수 있어요."

## 13. Empty and Error States

전체:
- 공개 사용자가 없음.
- public feed 로딩 실패.
- 차단/신고 후 피드 갱신.

친구들:
- 친구 없음.
- 친구는 있지만 공개 기록 없음.
- 받은 요청 있음.
- 네트워크 오류.

추가:
- 검색 결과 없음.
- 이미 친구.
- 이미 요청 보냄.
- 초대 링크 생성 실패.

## 14. Acceptance Criteria

P0 Social:
- Social 화면에서 `전체 / 친구들 / 추가` 탭 전환 가능.
- 전체 탭은 public 사용자/기록만 표시.
- 친구들 탭은 친구 피드와 `찾기`, `초대하기` 버튼 표시.
- 추가 탭에서 사용자 검색과 초대 링크 진입 가능.
- 기록 공개 범위는 private/friends/public 중 선택 가능.
- 기본값은 private.
- 친구 요청 보내기/수락/거절 가능.
- 차단하면 서로 보이지 않음.
- 신고 진입점 존재.

P1 Social:
- 친구 목록.
- 받은/보낸 요청 화면.
- public profile 편집.
- 내 공개 기록 목록.
- social notification.

P2 Social:
- reaction.
- 추천 사용자.
- QR/초대 코드.
- 연락처 기반 찾기.
- 공개 컬렉션.

## 15. Open Decisions

추후 결정:
- 친구 관계를 mutual friend로만 둘지, follow 모델도 둘지.
- public feed에 기록 중심과 사용자 중심 중 무엇을 우선할지.
- reaction을 허용할지.
- 댓글을 만들지. 초기에는 댓글 비추천.
- 공개 컬렉션을 언제 열지.

현재 추천:
- 초기에는 mutual friend만 사용한다.
- 댓글은 만들지 않는다.
- reaction도 P1 이후로 미룬다.
- 전체는 사용자 발견 + public 기록 preview 중심으로 시작한다.
