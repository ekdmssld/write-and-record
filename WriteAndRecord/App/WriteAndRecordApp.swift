import SwiftUI

@main
struct WriteAndRecordApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var entryRepository = EntryRepository()
    @StateObject private var categoryRepository = CategoryRepository()
    @StateObject private var photoService = PhotoLibraryService()
    @StateObject private var socialRepository = SocialRepository()

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
