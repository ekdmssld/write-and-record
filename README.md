# Write & Record

날짜별로 일상을 기록하고 카테고리/사진/별점/카드로 다시 보는 개인 기록 iOS 앱.
`docs/` 폴더의 스펙 문서를 기반으로 구현된 SwiftUI MVP입니다.

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

| Configuration | 용도 | mock 로그인 | 샘플 데이터 | 피드백 |
|---|---|---|---|---|
| Debug | 개발 | ✅ | ✅ | ✅ |
| PersonalRelease | 본인 실사용 | ❌ | ❌ | ❌ |
| BetaRelease | 친구 테스트 (TestFlight/Ad Hoc) | ❌ | ❌ | ✅ (mailto) |
| Release | App Store 후보 | ❌ | ❌ | ❌ |

PersonalRelease로 기기에 설치하려면: **Product → Scheme → Edit Scheme → Run → Build Configuration**을 `PersonalRelease`로 변경 후 Run. 플래그 동작은 `WriteAndRecord/Release/FeatureFlags.swift` 참고.

## 구조

```
WriteAndRecord/
  App/            진입점, 루트 라우팅(AppRouter), 앱 상태, 네비게이션 라우터
  Models/         UserProfile, EntryCategory, Entry, MediaAsset, EntryCollection, RecordCard
  Services/       JSON 저장소, Auth(mock→Apple 교체 가능), Entry/Category 리포지토리,
                  사진 라이브러리 격리 서비스, 카드 렌더링, draft autosave, JSON export
  Features/       Auth / Onboarding(4단계) / Library(캘린더·타임라인·갤러리·장소·컬렉션) /
                  CategoryPicker / EntryEditor / PhotoPicker(날짜별) / EntryDetail /
                  RecordCard(템플릿 6종) / Search / Settings
  DesignSystem/   색상·타이포 토큰, 버튼/칩/별점/카드/토스트 컴포넌트
  Utilities/      날짜 유틸, 입력 검증
  Release/        BuildConfiguration, FeatureFlags
```

## 구현된 범위

- **P0**: mock 로그인, 온보딩 4단계(중간 종료 draft 복원), 기본 카테고리 seed,
  캘린더(기록 수/카테고리 색 점) → 카테고리 선택 → 기록 작성/저장 → 상세,
  앱 재실행 시 데이터 유지(Codable JSON + schemaVersion), 저장 실패 시 draft 보존,
  JSON export, Debug UI는 Debug 빌드에서만 노출.
- **P1**: 날짜별 사진 선택기("이 날짜"/"전체", denied/limited/authorized 대응),
  타임라인(월 헤더+필터), 갤러리, 커스텀 카테고리 생성, 검색/필터.
- **P2**: 장소 리스트 뷰, 스마트 컬렉션(위시/별점5/최근30일/카테고리별),
  기록 카드 템플릿 6종(1080×1350 렌더링, 사진 저장/공유 시트).
- **P3 (미구현)**: 소셜/친구, 클라우드 동기화, AI 기능 — 온보딩 설정값만 저장.

주의: 에디터의 draft autosave는 5초 debounce + 백그라운드 진입 시 즉시 저장으로 동작합니다.
사진은 PHAsset 참조(localIdentifier)로 저장되며 원본 복사는 하지 않습니다(스펙 9장).
