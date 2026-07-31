import SwiftUI

/// 소셜 설정 (docs/10 12장): 프로필 공개 범위, 친구 요청 수신, 소셜 알림, 그리고
/// 친구 목록/내가 공유한 기록/차단한 사용자로 이어지는 관리 화면 진입점.
struct SocialSettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var socialRepository: SocialRepository
    @EnvironmentObject private var entryRepository: EntryRepository

    @State private var toastMessage: String?

    var body: some View {
        List {
            Section {
                Toggle("소셜 기능 사용", isOn: socialEnabledBinding)
            } footer: {
                Text("기본적으로 모든 기록은 나만 볼 수 있어요. 공개한 기록만 전체/친구 피드에 보여요.")
            }

            Section {
                Picker("프로필 공개 범위", selection: profileVisibilityBinding) {
                    ForEach(ProfileVisibility.allCases) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                Toggle("친구 요청 받기", isOn: allowFriendRequestsBinding)
            } header: {
                Text("프로필")
            } footer: {
                Text(profileVisibilityFooter)
            }

            Section {
                Toggle("소셜 알림", isOn: socialNotificationBinding)
            } footer: {
                Text("친구 요청이 도착하면 알림을 보내드려요.")
            }

            Section {
                NavigationLink {
                    FriendListView()
                } label: {
                    Label("친구 목록", systemImage: "person.2")
                }
                NavigationLink {
                    MySharedEntriesView()
                } label: {
                    Label("내가 공유한 기록", systemImage: "square.and.arrow.up")
                }
                NavigationLink {
                    BlockedUsersView()
                } label: {
                    Label("차단한 사용자", systemImage: "hand.raised")
                }
            } header: {
                Text("관리")
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppColors.bg)
        .navigationTitle("소셜 설정")
        .navigationBarTitleDisplayMode(.inline)
        .toast(message: $toastMessage)
    }

    private var profileVisibilityFooter: String {
        switch appState.profile?.effectiveProfileVisibility ?? .privateOnly {
        case .privateOnly: return "검색이나 전체 탭에 표시되지 않아요."
        case .friendsOnly: return "친구에게만 프로필이 보여요."
        case .publicAll: return "전체 탭에서 누구나 프로필을 볼 수 있어요."
        }
    }

    private var socialEnabledBinding: Binding<Bool> {
        Binding(
            get: { appState.profile?.socialEnabled ?? false },
            set: { newValue in
                guard var profile = appState.profile else { return }
                profile.socialEnabled = newValue
                appState.saveProfile(profile)
            }
        )
    }

    private var profileVisibilityBinding: Binding<ProfileVisibility> {
        Binding(
            get: { appState.profile?.effectiveProfileVisibility ?? .privateOnly },
            set: { newValue in
                guard var profile = appState.profile else { return }
                profile.profileVisibility = newValue
                appState.saveProfile(profile)
            }
        )
    }

    private var allowFriendRequestsBinding: Binding<Bool> {
        Binding(
            get: { appState.profile?.effectiveAllowFriendRequests ?? true },
            set: { newValue in
                guard var profile = appState.profile else { return }
                profile.allowFriendRequests = newValue
                appState.saveProfile(profile)
            }
        )
    }

    /// 알림 토글: 켜는 순간에만 권한을 요청한다 (SettingsView의 notificationBinding과 동일한 패턴).
    private var socialNotificationBinding: Binding<Bool> {
        Binding(
            get: { appState.profile?.effectiveSocialNotificationEnabled ?? false },
            set: { enabled in
                guard var profile = appState.profile else { return }
                profile.socialNotificationEnabled = enabled
                appState.saveProfile(profile)
                if enabled {
                    Task {
                        let granted = await NotificationService.requestPermission()
                        await MainActor.run {
                            toastMessage = granted ? "소셜 알림을 보내드릴게요." : "설정에서 알림 권한을 허용해 주세요."
                        }
                    }
                }
            }
        )
    }
}
