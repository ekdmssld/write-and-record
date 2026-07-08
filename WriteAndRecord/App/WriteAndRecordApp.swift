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
        }
    }
}
