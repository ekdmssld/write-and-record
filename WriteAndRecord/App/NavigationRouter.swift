import SwiftUI

enum AppRoute: Hashable {
    case categoryPicker(date: Date)
    case entryEditor(date: Date, categoryId: String, entryId: String?)
    case entryDetail(entryId: String)
    case recordCardPicker(entryId: String)
}

/// NavigationStack path 관리. 저장 후 "에디터 -> 상세로 교체" 같은 전환에 사용.
final class NavigationRouter: ObservableObject {
    @Published var path: [AppRoute] = []

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func replaceTop(with route: AppRoute) {
        if !path.isEmpty {
            path.removeLast()
        }
        path.append(route)
    }

    func popToRoot() {
        path.removeAll()
    }
}

struct AppRouteDestinations: ViewModifier {
    func body(content: Content) -> some View {
        content.navigationDestination(for: AppRoute.self) { route in
            switch route {
            case .categoryPicker(let date):
                CategoryPickerView(date: date)
            case .entryEditor(let date, let categoryId, let entryId):
                EntryEditorView(date: date, categoryId: categoryId, editingEntryId: entryId)
            case .entryDetail(let entryId):
                EntryDetailView(entryId: entryId)
            case .recordCardPicker(let entryId):
                RecordCardPickerView(entryId: entryId)
            }
        }
    }
}

extension View {
    func withAppRoutes() -> some View {
        modifier(AppRouteDestinations())
    }
}
