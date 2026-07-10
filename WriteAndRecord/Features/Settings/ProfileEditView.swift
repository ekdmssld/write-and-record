import SwiftUI
import PhotosUI

/// 프로필 수정: 프로필 사진, 닉네임(중복 확인), 공간 이름, 테마.
/// 온보딩과 같은 검증 규칙을 쓴다 (닉네임 1~20자, 공간 이름 1~30자).
struct ProfileEditView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    private let nicknameChecker: NicknameChecking = LocalNicknameChecker()

    @State private var nickname = ""
    @State private var spaceName = ""
    @State private var themeId = ProfileTheme.defaultThemes[0].id
    @State private var avatarImage: UIImage?
    @State private var newAvatarAssetId: String?
    @State private var selectedItem: PhotosPickerItem?

    @State private var checkedNickname: String?
    @State private var checkResult: NicknameCheckResult?
    @State private var isChecking = false

    private let themeColumns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    /// 닉네임을 바꿨다면 중복 확인을 다시 통과해야 저장 가능.
    private var isNicknameOk: Bool {
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Validation.isValidNickname(trimmed) else { return false }
        if trimmed == appState.profile?.nickname { return true }
        return checkResult == .available && checkedNickname == trimmed
    }

    private var canSave: Bool {
        isNicknameOk && Validation.isValidSpaceName(spaceName)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppLayout.largeGap) {
                    avatarSection
                    nicknameSection
                    spaceNameSection
                    themeSection
                }
                .padding(AppLayout.horizontalPadding)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(AppColors.bg)
            .navigationTitle("프로필 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: load)
            .onChange(of: selectedItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            avatarImage = image
                            newAvatarAssetId = appState.saveAvatarImage(image)
                        }
                    }
                }
            }
            .onChange(of: nickname) { _, newValue in
                if checkedNickname != newValue.trimmingCharacters(in: .whitespacesAndNewlines) {
                    checkResult = nil
                }
            }
        }
    }

    // MARK: - Sections

    private var avatarSection: some View {
        VStack(spacing: AppLayout.mediumGap) {
            ZStack {
                Circle()
                    .fill(Color(hex: ProfileTheme.theme(for: themeId).primaryColorHex).opacity(0.2))
                    .frame(width: 120, height: 120)
                if let avatarImage {
                    Image(uiImage: avatarImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(AppColors.textMuted)
                }
            }
            .accessibilityLabel(avatarImage == nil ? "프로필 사진 없음" : "프로필 사진")

            HStack(spacing: AppLayout.largeGap) {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Text("사진 변경")
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.primary)
                }
                if avatarImage != nil {
                    Button("사진 삭제") {
                        avatarImage = nil
                        newAvatarAssetId = nil
                        selectedItem = nil
                    }
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.danger)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var nicknameSection: some View {
        VStack(alignment: .leading, spacing: AppLayout.smallGap) {
            Text("닉네임")
                .font(AppTypography.headline)
            HStack(spacing: AppLayout.smallGap) {
                TextField("닉네임 (1~20자)", text: $nickname)
                    .font(AppTypography.body)
                    .padding(12)
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppLayout.buttonRadius)
                            .stroke(AppColors.line, lineWidth: 1)
                    )

                Button {
                    runCheck()
                } label: {
                    if isChecking {
                        ProgressView()
                            .frame(width: 74, height: 44)
                    } else {
                        Text("중복 확인")
                            .font(AppTypography.callout)
                            .frame(width: 74, height: 44)
                    }
                }
                .background(AppColors.surfaceAlt)
                .foregroundStyle(AppColors.text)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
                .disabled(isChecking || nickname.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityLabel("닉네임 중복 확인")
            }
            nicknameMessage
        }
    }

    @ViewBuilder
    private var nicknameMessage: some View {
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed == appState.profile?.nickname {
            Text("현재 사용 중인 닉네임이에요.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textMuted)
        } else {
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
                Text("닉네임을 바꾸면 중복 확인이 필요해요.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
            }
        }
    }

    private var spaceNameSection: some View {
        VStack(alignment: .leading, spacing: AppLayout.smallGap) {
            Text("내 공간 이름")
                .font(AppTypography.headline)
            TextField("예: 다은의 기록방 (1~30자)", text: $spaceName)
                .font(AppTypography.body)
                .padding(12)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.buttonRadius)
                        .stroke(AppColors.line, lineWidth: 1)
                )
        }
    }

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: AppLayout.smallGap) {
            Text("테마")
                .font(AppTypography.headline)
            LazyVGrid(columns: themeColumns, spacing: AppLayout.mediumGap) {
                ForEach(ProfileTheme.defaultThemes) { theme in
                    Button {
                        themeId = theme.id
                    } label: {
                        VStack(spacing: 6) {
                            Circle()
                                .fill(Color(hex: theme.primaryColorHex))
                                .frame(width: 32, height: 32)
                                .overlay(Circle().stroke(AppColors.line, lineWidth: 1))
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
                                .stroke(themeId == theme.id ? AppColors.primary : AppColors.line,
                                        lineWidth: themeId == theme.id ? 2 : 1)
                        )
                    }
                    .accessibilityLabel("테마 \(theme.name)\(themeId == theme.id ? ", 선택됨" : "")")
                }
            }
        }
    }

    // MARK: - Actions

    private func load() {
        guard let profile = appState.profile else { return }
        nickname = profile.nickname
        spaceName = profile.spaceName
        themeId = profile.themeId
        avatarImage = appState.loadAvatarImage(assetId: profile.avatarAssetId)
        newAvatarAssetId = profile.avatarAssetId
    }

    private func runCheck() {
        let candidate = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
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

    private func save() {
        guard var profile = appState.profile else { return }
        profile.nickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.spaceName = spaceName.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.themeId = themeId
        profile.avatarAssetId = avatarImage == nil ? nil : newAvatarAssetId
        appState.saveProfile(profile)
        dismiss()
    }
}
