import SwiftUI
import PhotosUI
import UserNotifications

// MARK: - Step 1: Nickname

struct OnboardingNicknameView: View {
    @Binding var profile: UserProfile
    let onNext: () -> Void

    private let nicknameChecker: NicknameChecking = LocalNicknameChecker()

    @State private var checkedNickname: String?
    @State private var checkResult: NicknameCheckResult?
    @State private var isChecking = false

    /// 다음 단계는 중복 확인을 통과한 닉네임만 허용.
    private var isCheckedAndAvailable: Bool {
        checkResult == .available
            && checkedNickname == profile.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(spacing: 0) {
            OnboardingStepContainer(title: "어떻게 불러드릴까요?", subtitle: "닉네임은 나중에 바꿀 수 있어요.") {
                VStack(alignment: .leading, spacing: AppLayout.smallGap) {
                    HStack(spacing: AppLayout.smallGap) {
                        TextField("닉네임 (1~20자)", text: $profile.nickname)
                            .font(AppTypography.body)
                            .padding(14)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppLayout.buttonRadius)
                                    .stroke(AppColors.line, lineWidth: 1)
                            )
                            .submitLabel(.done)

                        Button {
                            runCheck()
                        } label: {
                            if isChecking {
                                ProgressView()
                                    .frame(width: 74, height: 48)
                            } else {
                                Text("중복 확인")
                                    .font(AppTypography.callout)
                                    .frame(width: 74, height: 48)
                            }
                        }
                        .background(AppColors.surfaceAlt)
                        .foregroundStyle(AppColors.text)
                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
                        .disabled(isChecking || profile.nickname.trimmingCharacters(in: .whitespaces).isEmpty)
                        .accessibilityLabel("닉네임 중복 확인")
                    }

                    checkResultMessage
                }
            }

            PrimaryButton(title: "다음", isEnabled: isCheckedAndAvailable) {
                profile.nickname = profile.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
                onNext()
            }
            .padding(.horizontal, AppLayout.horizontalPadding)
            .padding(.bottom, AppLayout.largeGap)
        }
        .onAppear {
            // 뒤로가기/draft 복원으로 돌아온 경우, 저장돼 있던 닉네임은 확인된 것으로 간주.
            let existing = profile.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
            if !existing.isEmpty && Validation.isValidNickname(existing) && checkResult == nil {
                checkedNickname = existing
                checkResult = .available
            }
        }
        .onChange(of: profile.nickname) { _, newValue in
            // 닉네임이 바뀌면 다시 확인해야 함
            if checkedNickname != newValue.trimmingCharacters(in: .whitespacesAndNewlines) {
                checkResult = nil
            }
        }
    }

    @ViewBuilder
    private var checkResultMessage: some View {
        switch checkResult {
        case .available:
            Label("사용할 수 있는 닉네임이에요.", systemImage: "checkmark.circle.fill")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.success)
        case .taken:
            Label("사용할 수 없는 닉네임이에요.", systemImage: "xmark.circle.fill")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.danger)
        case .invalid(let message):
            Label(message, systemImage: "exclamationmark.circle.fill")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.danger)
        case nil:
            Text("중복 확인을 눌러 사용 가능 여부를 확인해 주세요.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textMuted)
        }
    }

    private func runCheck() {
        let candidate = profile.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        isChecking = true
        Task {
            let result = await nicknameChecker.check(candidate)
            await MainActor.run {
                checkResult = result
                checkedNickname = candidate
                isChecking = false
            }
        }
    }
}

// MARK: - Step 2: Profile Photo

struct OnboardingPhotoView: View {
    @Binding var profile: UserProfile
    let onNext: () -> Void

    @EnvironmentObject private var appState: AppState
    @State private var selectedItem: PhotosPickerItem?
    @State private var avatarImage: UIImage?

    var body: some View {
        VStack(spacing: 0) {
            OnboardingStepContainer(title: "프로필 사진을 골라볼까요?", subtitle: "건너뛰어도 괜찮아요.") {
                VStack(spacing: AppLayout.largeGap) {
                    ZStack {
                        Circle()
                            .fill(AppColors.surfaceAlt)
                            .frame(width: 140, height: 140)
                        if let avatarImage {
                            Image(uiImage: avatarImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 140, height: 140)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(AppColors.textMuted)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel(avatarImage == nil ? "프로필 사진 없음" : "선택된 프로필 사진")

                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Text("사진 선택")
                            .font(AppTypography.headline)
                            .foregroundStyle(AppColors.primary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            VStack(spacing: AppLayout.smallGap) {
                PrimaryButton(title: "다음") { onNext() }
                Button("건너뛰기") { onNext() }
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textMuted)
            }
            .padding(.horizontal, AppLayout.horizontalPadding)
            .padding(.bottom, AppLayout.largeGap)
        }
        .onAppear {
            avatarImage = appState.loadAvatarImage(assetId: profile.avatarAssetId)
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        avatarImage = image
                        if let assetId = appState.saveAvatarImage(image) {
                            profile.avatarAssetId = assetId
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Step 3: Theme + Space Name

struct OnboardingThemeView: View {
    @Binding var profile: UserProfile
    let onNext: () -> Void

    /// 테마를 고르기 전에는 공간 이름 입력을 숨기고,
    /// 테마 선택 순간 위에서 슬라이드로 나타난다.
    @State private var hasPickedTheme = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                OnboardingStepContainer(title: "내 공간을 꾸며볼까요?", subtitle: "마음에 드는 테마를 골라주세요.") {
                    VStack(alignment: .leading, spacing: AppLayout.largeGap) {
                        if hasPickedTheme {
                            spaceNameSection
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // profile card preview
                        HStack(spacing: AppLayout.mediumGap) {
                            Circle()
                                .fill(Color(hex: ProfileTheme.theme(for: profile.themeId).primaryColorHex))
                                .frame(width: 44, height: 44)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.nickname.isEmpty ? "닉네임" : profile.nickname)
                                    .font(AppTypography.headline)
                                Text(profile.spaceName.isEmpty ? "내 공간 이름" : profile.spaceName)
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColors.textMuted)
                            }
                            Spacer()
                        }
                        .padding(AppLayout.mediumGap)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                                .stroke(Color(hex: ProfileTheme.theme(for: profile.themeId).primaryColorHex), lineWidth: 2)
                        )

                        LazyVGrid(columns: columns, spacing: AppLayout.mediumGap) {
                            ForEach(ProfileTheme.defaultThemes) { theme in
                                Button {
                                    profile.themeId = theme.id
                                    withAnimation(.spring(duration: 0.35)) {
                                        hasPickedTheme = true
                                    }
                                } label: {
                                    VStack(spacing: 6) {
                                        Circle()
                                            .fill(Color(hex: theme.primaryColorHex))
                                            .frame(width: 36, height: 36)
                                        Text(theme.name)
                                            .font(AppTypography.caption)
                                            .foregroundStyle(AppColors.text)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, AppLayout.mediumGap)
                                    .background(AppColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                                            .stroke(profile.themeId == theme.id ? AppColors.primary : AppColors.line,
                                                    lineWidth: profile.themeId == theme.id ? 2 : 1)
                                    )
                                }
                                .accessibilityLabel("테마 \(theme.name)\(profile.themeId == theme.id ? ", 선택됨" : "")")
                            }
                        }
                    }
                }
            }

            PrimaryButton(title: "다음", isEnabled: hasPickedTheme && Validation.isValidSpaceName(profile.spaceName)) {
                profile.spaceName = profile.spaceName.trimmingCharacters(in: .whitespacesAndNewlines)
                onNext()
            }
            .padding(.horizontal, AppLayout.horizontalPadding)
            .padding(.bottom, AppLayout.largeGap)
        }
        .onAppear {
            // 뒤로가기/draft 복원으로 이미 공간 이름이 있으면 입력 필드를 바로 보여준다.
            if !profile.spaceName.isEmpty {
                hasPickedTheme = true
            }
        }
    }

    private var spaceNameSection: some View {
        VStack(alignment: .leading, spacing: AppLayout.smallGap) {
            Text("내 공간 이름")
                .font(AppTypography.headline)
            TextField("예: 다은의 기록방 (1~30자)", text: $profile.spaceName)
                .font(AppTypography.body)
                .padding(14)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.buttonRadius)
                        .stroke(AppColors.line, lineWidth: 1)
                )
        }
    }
}

// MARK: - Step 4: Intro + Social Settings

struct OnboardingIntroSocialView: View {
    @Binding var profile: UserProfile
    let onStart: () -> Void

    private let features: [(icon: String, title: String)] = [
        ("square.and.arrow.up", "기록 카드로 공유"),
        ("person.2", "친구와 취향 발견"),
        ("bell", "알림으로 기록 습관 만들기")
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                OnboardingStepContainer(title: "이런 것들을 할 수 있어요", subtitle: "소셜 기능은 나중에 켜고 끌 수 있어요.") {
                    VStack(spacing: AppLayout.mediumGap) {
                        ForEach(features, id: \.title) { feature in
                            HStack(spacing: AppLayout.mediumGap) {
                                Image(systemName: feature.icon)
                                    .font(.system(size: 20))
                                    .foregroundStyle(AppColors.primary)
                                    .frame(width: 32)
                                Text(feature.title)
                                    .font(AppTypography.headline)
                                Spacer()
                            }
                            .padding(AppLayout.mediumGap)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                                    .stroke(AppColors.line, lineWidth: 1)
                            )
                        }

                        VStack(spacing: 0) {
                            Toggle("친구에게 기록 공유 허용", isOn: $profile.friendShareEnabled)
                                .font(AppTypography.body)
                                .padding(AppLayout.mediumGap)
                            Divider()
                            Toggle("기록 알림 받기", isOn: $profile.notificationEnabled)
                                .font(AppTypography.body)
                                .padding(AppLayout.mediumGap)
                        }
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                                .stroke(AppColors.line, lineWidth: 1)
                        )
                        .padding(.top, AppLayout.smallGap)
                    }
                }
            }

            PrimaryButton(title: "시작하기") {
                profile.socialEnabled = profile.friendShareEnabled
                onStart()
            }
            .padding(.horizontal, AppLayout.horizontalPadding)
            .padding(.bottom, AppLayout.largeGap)
        }
        .onChange(of: profile.notificationEnabled) { _, enabled in
            // 알림 권한은 사용자가 toggle on 했을 때만 요청 (Functional Spec 5장).
            if enabled {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
            }
        }
    }
}
