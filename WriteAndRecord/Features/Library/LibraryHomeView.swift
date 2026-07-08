import SwiftUI

enum LibraryViewMode: String, CaseIterable, Identifiable {
    case calendar
    case timeline
    case gallery
    case places
    case collections

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .calendar: return "캘린더"
        case .timeline: return "타임라인"
        case .gallery: return "갤러리"
        case .places: return "장소"
        case .collections: return "컬렉션"
        }
    }
}

struct LibraryHomeView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var entryRepository: EntryRepository
    @EnvironmentObject private var photoService: PhotoLibraryService

    @StateObject private var router = NavigationRouter()
    @State private var viewMode: LibraryViewMode = .calendar

    /// 로그인/온보딩 완료 후 첫 진입 시 한 번만 사진 권한을 요청한다.
    @AppStorage("didRequestPhotoPermission") private var didRequestPhotoPermission = false

    var body: some View {
        NavigationStack(path: $router.path) {
            VStack(spacing: 0) {
                topBar
                viewSwitch
                Divider().overlay(AppColors.line)

                Group {
                    switch viewMode {
                    case .calendar:
                        CalendarView()
                    case .timeline:
                        TimelineView()
                    case .gallery:
                        GalleryView()
                    case .places:
                        PlacesView()
                    case .collections:
                        CollectionsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(AppColors.bg)
            .toolbar(.hidden, for: .navigationBar)
            .withAppRoutes()
        }
        .environmentObject(router)
        .task {
            await requestPhotoPermissionIfNeeded()
        }
    }

    private func requestPhotoPermissionIfNeeded() async {
        guard !didRequestPhotoPermission else { return }
        didRequestPhotoPermission = true
        photoService.refreshPermission()
        if photoService.permission == .notDetermined {
            await photoService.requestPermission()
        }
    }

    private var topBar: some View {
        HStack(spacing: AppLayout.smallGap) {
            VStack(alignment: .leading, spacing: 0) {
                Text(appState.profile?.spaceName ?? "내 공간")
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.text)
                    .lineLimit(1)
                Text(appState.profile?.nickname ?? "")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
            }
            Spacer()
            IconButton(systemName: "magnifyingglass", accessibilityLabel: "기록 검색") {
                router.push(.search)
            }
        }
        .padding(.horizontal, AppLayout.horizontalPadding)
        .padding(.vertical, AppLayout.smallGap)
    }

    private var viewSwitch: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppLayout.smallGap) {
                ForEach(LibraryViewMode.allCases) { mode in
                    Button {
                        viewMode = mode
                    } label: {
                        Text(mode.displayName)
                            .font(AppTypography.callout)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(viewMode == mode ? AppColors.text : AppColors.surfaceAlt)
                            .foregroundStyle(viewMode == mode ? AppColors.surface : AppColors.textMuted)
                            .clipShape(Capsule())
                    }
                    .accessibilityLabel("\(mode.displayName) 보기\(viewMode == mode ? ", 선택됨" : "")")
                }
            }
            .padding(.horizontal, AppLayout.horizontalPadding)
            .padding(.vertical, AppLayout.smallGap)
        }
    }
}
