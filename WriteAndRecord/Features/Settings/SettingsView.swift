import SwiftUI

/// My Space 탭: 프로필, 통계, 데이터 export, 소셜/알림 설정, 로그아웃, (debug 전용) 개발 도구.
struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var entryRepository: EntryRepository
    @EnvironmentObject private var categoryRepository: CategoryRepository

    @StateObject private var router = NavigationRouter()
    @State private var exportURL: URL?
    @State private var showSignOutDialog = false
    @State private var showFeedbackForm = false
    @State private var toastMessage: String?

    var body: some View {
        NavigationStack(path: $router.path) {
            List {
                profileSection
                statsSection
                preferencesSection
                dataSection
                if FeatureFlags.enableFeedback {
                    feedbackSection
                }
                accountSection
                if FeatureFlags.showDebugTools {
                    debugSection
                }
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.bg)
            .navigationTitle("내 공간")
            .withAppRoutes()
            .toast(message: $toastMessage)
            .sheet(isPresented: Binding(
                get: { exportURL != nil },
                set: { if !$0 { exportURL = nil } }
            )) {
                if let exportURL {
                    ShareSheet(items: [exportURL])
                }
            }
            .sheet(isPresented: $showFeedbackForm) {
                FeedbackView()
            }
            .confirmationDialog("로그아웃할까요?", isPresented: $showSignOutDialog, titleVisibility: .visible) {
                Button("기기에 데이터 남기고 로그아웃") {
                    appState.signOut(deleteLocalData: false, entryRepository: entryRepository, categoryRepository: categoryRepository)
                }
                Button("데이터 삭제하고 로그아웃", role: .destructive) {
                    appState.signOut(deleteLocalData: true, entryRepository: entryRepository, categoryRepository: categoryRepository)
                }
                Button("취소", role: .cancel) { }
            }
        }
        .environmentObject(router)
    }

    private var profileSection: some View {
        Section {
            HStack(spacing: AppLayout.mediumGap) {
                if let avatar = appState.loadAvatarImage(assetId: appState.profile?.avatarAssetId) {
                    Image(uiImage: avatar)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                } else {
                    ZStack {
                        Circle()
                            .fill(Color(hex: ProfileTheme.theme(for: appState.profile?.themeId ?? "").primaryColorHex).opacity(0.2))
                        Image(systemName: "person.fill")
                            .foregroundStyle(AppColors.textMuted)
                    }
                    .frame(width: 56, height: 56)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(appState.profile?.nickname ?? "-")
                        .font(AppTypography.headline)
                    Text(appState.profile?.spaceName ?? "-")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textMuted)
                }
            }
        }
    }

    private var statsSection: some View {
        Section("기록 통계") {
            statsLink(kind: .allEntries, count: entryRepository.activeEntries.count)
            statsLink(kind: .wishlist, count: entryRepository.wishlistEntries.count)
            statsLink(kind: .fiveStar, count: entryRepository.fiveStarEntries.count)
            statsLink(kind: .recordCards, count: entryRepository.recordCards.count)
        }
    }

    private var preferencesSection: some View {
        Section("설정") {
            NavigationLink {
                CategoryOrderView()
            } label: {
                Label("카테고리 순서 변경", systemImage: "line.3.horizontal")
            }
            Toggle("친구에게 기록 공유 허용", isOn: profileBinding(\.friendShareEnabled))
            Toggle("기록 알림", isOn: notificationBinding)
            if appState.profile?.notificationEnabled == true {
                DatePicker(
                    "알림 시간",
                    selection: reminderTimeBinding,
                    displayedComponents: .hourAndMinute
                )
            }
        }
    }

    /// 알림 토글: 켜는 순간에만 권한을 요청하고, 끄면 예약을 제거한다 (docs/05 13장).
    private var notificationBinding: Binding<Bool> {
        Binding(
            get: { appState.profile?.notificationEnabled ?? false },
            set: { enabled in
                guard var profile = appState.profile else { return }
                profile.notificationEnabled = enabled
                appState.saveProfile(profile)
                if enabled {
                    Task {
                        let granted = await NotificationService.requestPermission()
                        await MainActor.run {
                            if granted {
                                NotificationService.sync(with: appState.profile)
                                toastMessage = "매일 알림을 보내드릴게요."
                            } else {
                                toastMessage = "설정에서 알림 권한을 허용해 주세요."
                            }
                        }
                    }
                } else {
                    NotificationService.cancelDailyReminder()
                }
            }
        )
    }

    private var reminderTimeBinding: Binding<Date> {
        Binding(
            get: { appState.profile?.reminderTime ?? NotificationService.defaultReminderTime },
            set: { newTime in
                guard var profile = appState.profile else { return }
                profile.reminderTime = newTime
                appState.saveProfile(profile)
                NotificationService.sync(with: appState.profile)
            }
        )
    }

    private var dataSection: some View {
        Section {
            Button {
                exportData()
            } label: {
                Label("데이터 내보내기 (JSON)", systemImage: "square.and.arrow.up")
            }
        } header: {
            Text("데이터")
        } footer: {
            Text("앱을 삭제하면 기록이 사라질 수 있어요. 주기적으로 내보내기로 백업해 주세요.")
        }
    }

    private var feedbackSection: some View {
        Section("베타 테스트") {
            Button {
                showFeedbackForm = true
            } label: {
                Label("피드백 보내기", systemImage: "envelope")
            }
        }
    }

    private var accountSection: some View {
        Section("계정") {
            Button(role: .destructive) {
                showSignOutDialog = true
            } label: {
                Label("로그아웃", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
    }

    private var debugSection: some View {
        Section("개발 도구 (Debug 전용)") {
            Button("샘플 기록 만들기") {
                seedSampleData()
            }
            Button("모든 기록 삭제", role: .destructive) {
                entryRepository.resetAllData()
                toastMessage = "모든 기록을 삭제했어요."
            }
            Button("카테고리 초기화", role: .destructive) {
                categoryRepository.resetToDefaults()
                toastMessage = "카테고리를 초기화했어요."
            }
        }
    }

    private var aboutSection: some View {
        Section("정보") {
            LabeledContent("버전", value: BuildConfiguration.appVersionString)
            LabeledContent("빌드 모드", value: BuildConfiguration.current.rawValue)
        }
    }

    // MARK: - Helpers

    private func statsLink(kind: SettingsStatKind, count: Int) -> some View {
        NavigationLink {
            SettingsStatDetailView(kind: kind)
        } label: {
            HStack(spacing: AppLayout.smallGap) {
                Image(systemName: kind.iconName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColors.category(kind.colorHex))
                    .frame(width: 24)
                Text(kind.title)
                    .foregroundStyle(AppColors.text)
                Spacer()
                Text("\(count)개")
                    .foregroundStyle(AppColors.textMuted)
            }
        }
        .accessibilityLabel("\(kind.title) \(count)개 보기")
    }

    private func profileBinding(_ keyPath: WritableKeyPath<UserProfile, Bool>) -> Binding<Bool> {
        Binding(
            get: { appState.profile?[keyPath: keyPath] ?? false },
            set: { newValue in
                guard var profile = appState.profile else { return }
                profile[keyPath: keyPath] = newValue
                appState.saveProfile(profile)
            }
        )
    }

    private func exportData() {
        let url = ExportService.makeExportFile(
            profile: appState.profile,
            categories: categoryRepository.categories,
            entries: entryRepository.entries,
            mediaAssets: entryRepository.mediaAssets,
            collections: entryRepository.collections,
            recordCards: entryRepository.recordCards
        )
        if let url {
            exportURL = url
        } else {
            toastMessage = "내보내기에 실패했어요."
        }
    }

    private func seedSampleData() {
        guard FeatureFlags.enableSampleData else { return }
        let userId = appState.session?.userId ?? "local-user"
        let calendar = Calendar.current
        let samples: [(daysAgo: Int, categoryId: String, title: String, body: String, rating: Int?, wish: Bool)] = [
            (0, "default-food-sub0", "회사 앞 새 파스타집", "크림 파스타가 진했다. 웨이팅 20분.", 4, false),
            (1, "default-movieTv-sub0", "듄 다시 보기", "역시 큰 화면으로 봐야 하는 영화.", 5, false),
            (2, "default-daily-sub0", "한강 산책", "날씨가 좋아서 30분 걸었다.", nil, false),
            (3, "default-book-sub1", "읽고 싶은 에세이", "서점에서 발견. 다음에 사기.", nil, true),
            (5, "default-exercise-sub1", "5km 러닝", "페이스 6:30. 무릎 괜찮았음.", 3, false)
        ]
        for sample in samples {
            var entry = Entry.new(
                userId: userId,
                date: calendar.date(byAdding: .day, value: -sample.daysAgo, to: Date()) ?? Date(),
                categoryId: sample.categoryId
            )
            entry.title = sample.title
            entry.body = sample.body
            entry.rating = sample.rating
            entry.isWishlist = sample.wish
            entryRepository.save(entry)
        }
        toastMessage = "샘플 기록 5개를 만들었어요."
    }
}
