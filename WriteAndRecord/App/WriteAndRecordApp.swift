import SwiftUI

@main
struct WriteAndRecordApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var entryRepository = EntryRepository()
    @StateObject private var categoryRepository = CategoryRepository()
    @StateObject private var photoService = PhotoLibraryService()

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environmentObject(appState)
                .environmentObject(entryRepository)
                .environmentObject(categoryRepository)
                .environmentObject(photoService)
                .tint(AppColors.primary)
        }
    }
}
