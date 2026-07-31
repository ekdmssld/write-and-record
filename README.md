# Write & Record

날짜별로 일상을 기록하고 카테고리·사진·별점·카드로 다시 꺼내보는 개인 기록 iOS 앱입니다.
서버 없이 완전히 기기 로컬(local-first)로 동작하며, `docs/` 폴더의 스펙 문서를 기반으로 구현된 SwiftUI 앱입니다.

## 실행 방법 (본인 iPhone / 시뮬레이터)

1. Mac App Store에서 **Xcode 16 이상** 설치. (이 프로젝트는 Xcode 16의 폴더 동기화 프로젝트 형식을 사용합니다.)
2. `WriteAndRecord.xcodeproj` 열기.
3. Signing & Capabilities에서:
   - Team: 본인 Apple Account의 Personal Team 선택.
   - Bundle Identifier를 고유값으로 변경 (기본: `com.daeun.writeandrecord`).
4. Run destination을 시뮬레이터 또는 연결된 iPhone으로 선택 후 Run.
5. Debug 빌드에서는 "개발용 mock 로그인" 버튼으로 전체 플로우를 바로 테스트할 수 있습니다.

무료 Apple Account로 설치한 앱은 provisioning이 약 7일 후 만료되어 재빌드가 필요할 수 있습니다.
앱 삭제 시 로컬 데이터가 사라지므로 **내 공간 → 데이터 내보내기(JSON)** 로 주기적으로 백업하세요.

## 빌드 설정 (docs/05 3장, docs/04 지시 11~12)

| Configuration | 용도 | mock 로그인 | 샘플 데이터 | 소셜 | 피드백 |
|---|---|---|---|---|---|
| Debug | 개발 | ✅ | ✅ | ✅ | ✅ |
| PersonalRelease | 본인 실사용 | ❌ | ❌ | ❌ | ❌ |
| BetaRelease | 친구 테스트 (TestFlight/Ad Hoc) | ❌ | ❌ | ✅ | ✅ (mailto) |
| Release (StoreRelease) | App Store 후보 | ❌ | ❌ | ✅ | ❌ |

PersonalRelease로 기기에 설치하려면: **Product → Scheme → Edit Scheme → Run → Build Configuration**을 `PersonalRelease`로 변경 후 Run. 플래그 동작은 `WriteAndRecord/Release/FeatureFlags.swift` 참고.

소셜 탭은 서버 없이 로컬 mock으로 동작합니다 — Debug 빌드에서만 다른 사용자(mock 3명)가 보이고,
BetaRelease/StoreRelease에서는 화면과 설정은 노출되지만 실제 다중 사용자 간 친구 검색·요청 전달은
아직 동작하지 않습니다 (서버 연동은 `docs/13` 백로그 참고).

## 구조

```
WriteAndRecord/
  App/            진입점, 루트 라우팅(AppRouter), 앱 상태, 네비게이션 라우터
  Models/         UserProfile, EntryCategory, Entry, MediaAsset, EntryCollection,
                  RecordCard, SocialModels(공개범위/친구/좋아요/댓글/초대)
  Services/       JSON 저장소, Auth(mock→Apple 교체 가능), Entry/Category 리포지토리,
                  SocialRepository(친구·차단·신고·초대·좋아요·댓글, 로컬 mock),
                  사진 라이브러리 격리 서비스, 카드 렌더링, draft autosave,
                  JSON export, 알림(일일 리마인더·친구 요청)
  Features/       Auth / Onboarding(4단계) / Library(캘린더·타임라인·갤러리·장소·컬렉션) /
                  CategoryPicker / EntryEditor / PhotoPicker(날짜별) / EntryDetail /
                  RecordCard(템플릿 7종) / Search / Settings / Social(전체·친구들·추가 탭,
                  친구 목록·차단 관리·내가 공유한 기록·공개 프로필·소셜 설정)
  DesignSystem/   색상·타이포 토큰, 버튼/칩/별점/카드/토스트 컴포넌트
  Utilities/      날짜 유틸, 입력 검증, QR 코드 생성(CoreImage)
  Release/        BuildConfiguration, FeatureFlags
```

## 구현된 범위

- **P0**: mock 로그인, 온보딩 4단계(중간 종료 draft 복원), 기본 카테고리 seed,
  캘린더(기록 수/카테고리 색 점) → 카테고리 선택 → 기록 작성/저장 → 상세,
  앱 재실행 시 데이터 유지(Codable JSON + schemaVersion), 저장 실패 시 draft 보존,
  JSON export, Debug UI는 Debug 빌드에서만 노출.
- **P1**: 날짜별 사진 선택기("이 날짜"/"전체", denied/limited/authorized 대응),
  타임라인(월 헤더+필터), 갤러리, 커스텀 카테고리 생성(순서 변경/숨김/복원 포함), 검색/필터(정렬·날짜 범위),
  일일 기록 리마인더 알림, JSON 백업 import/restore, 프로필 편집(아바타/닉네임/공간 이름/테마).
- **P2**: 장소 리스트·지도 뷰, 스마트 컬렉션(위시/별점5/최근30일/카테고리별) + 수동 컬렉션,
  기록 카드 템플릿 7종(1080×1350 렌더링, 사진 저장/공유 시트), 월간 이미지 캘린더 export,
  위시리스트 분류, 인용구 컬렉션, 앱 내 정보 검색(영화/책/음악), 인앱 피드백 폼(mailto).
- **소셜** (`docs/10`, `docs/11` 기준, 서버 없는 로컬 mock): 전체/친구들/추가 탭, 기록 단위 공개범위
  (나만 보기/친구 공개/전체 공개), 친구 요청·수락·거절·삭제, 차단·신고, 초대 링크(복사/공유/QR 코드),
  좋아요·댓글, 친구 목록·차단 사용자 관리·내가 공유한 기록·공개 프로필 보기, 소셜 알림.
  실제 서버 연동, 딥링크로 초대 수락, 추천 사용자, 공개 컬렉션은 아직 없음.
- **미구현**: 클라우드 동기화, AI 기능, 소셜 백엔드(현재는 `SocialRepository` 내부만 교체하면
  서버로 전환 가능하도록 설계됨).

전체 스펙과 남은 백로그는 `docs/` 폴더, 특히 `docs/10_SOCIAL_FEATURE_SPEC.md`(소셜 스펙)와
`docs/13_FEEDBACK_FLOW_AND_BACKLOG.md`(남은 작업 우선순위)를 참고하세요.

주의: 에디터의 draft autosave는 5초 debounce + 백그라운드 진입 시 즉시 저장으로 동작합니다.
사진은 PHAsset 참조(localIdentifier)로 저장되며 원본 복사는 하지 않습니다(스펙 9장).
