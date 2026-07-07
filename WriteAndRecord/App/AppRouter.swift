import SwiftUI

/// 루트 라우팅: 세션 없음 -> Auth, 온보딩 미완료 -> Onboarding, 완료 -> Main tabs.
struct AppRouter: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        switch appState.route {
        case .auth:
            AuthView()
        case .onboarding:
            OnboardingFlowView()
        case .main:
            MainTabView()
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView {
            LibraryHomeView()
                .tabItem {
                    Label("라이브러리", systemImage: "books.vertical")
                }

            QuickCreateView()
                .tabItem {
                    Label("기록", systemImage: "plus.circle")
                }

            SearchView()
                .tabItem {
                    Label("검색", systemImage: "magnifyingglass")
                }

            SettingsView()
                .tabItem {
                    Label("내 공간", systemImage: "person.crop.circle")
                }
        }
    }
}

/// Create 탭: 오늘 날짜 기준 빠른 기록 생성.
struct QuickCreateView: View {
    @StateObject private var router = NavigationRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            CategoryPickerView(date: Date())
                .withAppRoutes()
        }
        .environmentObject(router)
    }
}
