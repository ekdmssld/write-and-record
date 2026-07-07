# Write & Record - iPhone Test/Distribution/Release Plan

기준일: 2026-07-07. Apple 정책은 바뀔 수 있으므로 실제 배포 직전 공식 문서 재확인 필요.

## 1. 결론

지금 상황:
- Mac 있음.
- iPhone 사용자.
- Apple Developer Program 유료 계정 없음.
- 일단 본인만 사용 예정.
- 친구 테스트 가능성 있음.

추천 순서:
1. 무료 Apple Account + Xcode로 본인 iPhone에 직접 설치.
2. 1~2주 실사용하면서 데이터 저장/사진 권한/카드 공유 안정화.
3. 친구 테스트가 필요해지면 Apple Developer Program 가입 후 TestFlight 사용.
4. App Store 배포는 개인정보 처리/디자인/QA가 충분히 안정된 뒤 결정.

## 2. 가능한 배포 방식 비교

### A. 무료 Apple Account + Xcode 직접 설치

가능 여부:
- 가능. Apple은 Apple Account만으로 Xcode와 실제 기기 테스트가 가능하다고 안내한다.

장점:
- 비용 없음.
- 내 iPhone에서 바로 테스트 가능.
- App Store 심사 불필요.

단점:
- Personal Team 제한이 있음.
- App ID와 기기 등록이 제한되고, provisioning profile이 7일 후 만료될 수 있어 재빌드/재설치가 필요할 수 있음.
- 친구에게 편하게 배포하는 방식은 아님.

용도:
- 본인 실사용 초기.
- 기능 개발/디버깅.
- App Store 전 개인 앱 검증.

필요:
- Mac.
- Xcode.
- Apple Account.
- iPhone USB 연결 또는 Wi-Fi debugging.

### B. Apple Developer Program + TestFlight

가능 여부:
- 유료 Apple Developer Program 필요.

장점:
- 친구들에게 링크/이메일로 beta 앱 배포 가능.
- 외부 테스터 최대 10,000명, 내부 테스터 최대 100명까지 가능.
- TestFlight 앱에서 설치/업데이트/피드백 수집 가능.
- 빌드는 최대 90일 테스트 가능.

단점:
- 연 99 USD 또는 지역 가격.
- 외부 테스터 첫 빌드는 Beta App Review가 필요할 수 있음.
- App Store Connect 설정 필요.

용도:
- 친구 테스트.
- 공개 출시 전 베타.
- 앱 설치를 쉽게 공유하고 싶을 때.

### C. Apple Developer Program + Ad Hoc

가능 여부:
- 유료 Apple Developer Program 필요.
- 테스트 기기를 등록하고 provisioning profile에 포함해야 함.

장점:
- App Store/TestFlight 없이 특정 등록 기기에 설치 가능.
- 내부 테스트용으로 쓸 수 있음.

단점:
- 친구 iPhone UDID 수집/등록 필요.
- 기기 추가/프로파일 갱신이 번거로움.
- TestFlight보다 사용자 경험이 나쁨.

용도:
- 아주 소수의 정해진 기기 테스트.
- TestFlight를 쓰기 전 임시 배포.

### D. App Store 정식 배포

가능 여부:
- 유료 Apple Developer Program 필요.
- App Review 통과 필요.

장점:
- 누구나 설치 가능.
- 업데이트/리뷰/검색/결제 등 공식 배포 경로.

단점:
- 앱 심사, 개인정보 영양성분표, 스크린샷, 설명, 지원 URL 등 필요.
- 개인 기록/사진/위치 기능은 권한 문구와 개인정보 정책을 꼼꼼히 준비해야 함.

용도:
- 불특정 다수 공개.
- 장기 서비스.

### E. Apple Developer Enterprise Program

현재 상황에서는 비추천.

이유:
- 대규모 조직의 직원용 내부 앱 배포 프로그램.
- Apple은 100명 이상 직원 등 조직 요건과 내부 사용 제한을 둔다.
- 비용도 일반 Developer Program보다 높다.

## 3. 본인 iPhone 설치 절차

1. Mac App Store에서 Xcode 설치.
2. Xcode 실행.
3. Xcode Settings -> Accounts에서 Apple Account 로그인.
4. iPhone을 Mac에 연결.
5. iPhone에서 "이 컴퓨터를 신뢰" 선택.
6. Xcode project 열기.
7. Signing & Capabilities:
   - Team: Personal Team 선택.
   - Bundle Identifier: 고유값 설정. 예: `com.yourname.writeandrecord`.
   - Automatically manage signing on.
8. Run destination을 내 iPhone으로 선택.
9. Run.
10. iPhone 설정에서 개발자 앱 신뢰가 필요하면 안내에 따라 신뢰.

주의:
- 무료 계정 설치 앱은 일정 기간 후 다시 빌드/설치가 필요할 수 있음.
- 앱 삭제 시 로컬 데이터가 사라질 수 있으므로 export/backup 기능이 중요.

## 4. 친구 테스트 가능 여부

짧은 답:
- 무료 계정만으로는 친구들에게 편하게 앱 공유하기 어렵다.
- 친구 테스트를 제대로 하려면 TestFlight가 가장 현실적이고, TestFlight에는 Apple Developer Program이 필요하다.

선택지:
- 아주 가까운 친구 1명: 친구 iPhone을 내 Mac에 직접 연결해서 개발 빌드 설치는 가능할 수 있으나 번거롭고 지속 업데이트가 어렵다.
- 몇 명에게 링크로 테스트: Developer Program 가입 후 TestFlight.
- UDID 등록 방식: Developer Program 가입 후 Ad Hoc.

권장:
- 혼자 쓰는 동안은 무료 Xcode 설치.
- 친구 3명 이상에게 테스트시키고 싶어지는 순간 TestFlight로 전환.

## 5. TestFlight 준비 체크리스트

필수:
- Apple Developer Program enrollment.
- App Store Connect app record.
- Bundle ID.
- App icon.
- Version/build number.
- Beta app description.
- Beta test information.
- Privacy nutrition labels 초안.
- Export compliance 답변.
- Test account, 로그인 필요한 경우.

Beta tester 준비:
- 친구 이메일 목록 또는 public link.
- 테스트 요청 문서:
  - 설치 가능 여부
  - 온보딩 완료 여부
  - 기록 저장/수정/삭제
  - 사진 권한 denied/limited/authorized
  - 카드 저장/공유
  - 앱 재실행 후 데이터 유지

## 6. App Store 출시 전 준비

Product:
- 앱 이름 확정.
- 앱 아이콘.
- launch screen.
- onboarding polish.
- 개인정보 처리방침 URL.
- 지원 URL.
- 앱 설명/키워드.
- 스크린샷.

Engineering:
- crash-free target.
- migration test.
- offline behavior.
- backup/export.
- sensitive log 제거.
- permission strings.
- accessibility.

Legal/privacy:
- 수집 데이터 정의.
- 위치/사진/알림 사용 목적.
- 계정 삭제 정책, 서버 계정이 생길 경우.
- third-party SDK 목록.

## 7. Release Roadmap

Milestone 0: Prototype
- mock auth.
- local JSON/SwiftData.
- calendar -> create -> detail.

Milestone 1: Personal Daily Use
- real device install.
- photo picker.
- draft recovery.
- export JSON.
- no data loss for 2 weeks.

Milestone 2: Friend Beta
- Developer Program decision.
- TestFlight or Ad Hoc.
- feedback channel.
- crash reporting.

Milestone 3: Store Candidate
- privacy policy.
- screenshots.
- app review compliance.
- final QA.

## 8. Official Apple References

- Apple Membership 비교: https://developer.apple.com/support/compare-memberships/
- TestFlight overview: https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/
- Ad Hoc provisioning: https://developer.apple.com/help/account/provisioning-profiles/create-an-ad-hoc-provisioning-profile/
- Apple Developer Enterprise Program: https://developer.apple.com/programs/enterprise/

