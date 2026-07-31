import SwiftUI

@main
struct WriteAndRecordApp: App {
    @StateObject private var appState: AppState
    @StateObject private var entryRepository = EntryRepository()
    @StateObject private var categoryRepository = CategoryRepository()
    @StateObject private var photoService = PhotoLibraryService()
    @StateObject private var socialRepository: SocialRepository

    init() {
        // SocialRepository의 mock 시드(친구 요청)가 init 내부에서 바로 실행되므로,
        // 알림 훅은 생성자 인자로 미리 주입해야 시드된 요청도 알림이 울린다
        // (뒤늦게 .onAppear에서 연결하면 시드가 이미 끝난 뒤라 훅이 동작하지 않는다).
        let appState = AppState()
        _appState = StateObject(wrappedValue: appState)
        _socialRepository = StateObject(wrappedValue: SocialRepository(onIncomingRequest: { [weak appState] nickname in
            let enabled = appState?.profile?.effectiveSocialNotificationEnabled ?? false
            NotificationService.notifyFriendRequestReceived(nickname: nickname, enabled: enabled)
        }))
    }

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environmentObject(appState)
                .environmentObject(entryRepository)
                .environmentObject(categoryRepository)
                .environmentObject(photoService)
                .environmentObject(socialRepository)
                .tint(AppColors.primary)
                // 색 토큰이 라이트 전용이라 시스템 다크 모드에서 시트/리스트 배경이
                // 어긋나는 것을 막는다. 다크 토큰 세트를 만들면 이 고정을 푼다 (docs/02).
                .preferredColorScheme(.light)
        }
    }
}
