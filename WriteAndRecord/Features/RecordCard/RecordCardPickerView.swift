import SwiftUI
import Photos

/// 카드 템플릿 선택 + 미리보기 + 저장/공유 (Flowchart 6).
struct RecordCardPickerView: View {
    let entryId: String

    @EnvironmentObject private var entryRepository: EntryRepository
    @EnvironmentObject private var categoryRepository: CategoryRepository
    @EnvironmentObject private var photoService: PhotoLibraryService

    @State private var selectedTemplate: RecordCardTemplate = .minimalPhoto
    @State private var coverImage: UIImage?
    @State private var shareURL: URL?
    @State private var toastMessage: String?
    @State private var isExporting = false

    private var entry: Entry? {
        entryRepository.entry(id: entryId)
    }

    private var context: RecordCardContext? {
        guard let entry else { return nil }
        return RecordCardContext(
            entry: entry,
            categoryName: categoryRepository.displayName(forEntry: entry),
            categoryColorHex: categoryRepository.colorHex(forEntry: entry),
            coverImage: coverImage
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            if let context {
                ScrollView {
                    VStack(spacing: AppLayout.largeGap) {
                        // preview pane (축소 표시)
                        RecordCardView(template: selectedTemplate, context: context)
                            .scaleEffect(0.75)
                            .frame(width: RecordCardView.baseSize.width * 0.75,
                                   height: RecordCardView.baseSize.height * 0.75)
                            .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
                            .animation(.easeInOut(duration: 0.15), value: selectedTemplate)

                        templateGrid
                    }
                    .padding(.vertical, AppLayout.mediumGap)
                }

                actionBar
            } else {
                EmptyStateView(iconName: "trash", title: "기록을 찾을 수 없어요")
            }
        }
        .background(AppColors.bg)
        .navigationTitle("기록 카드")
        .navigationBarTitleDisplayMode(.inline)
        .toast(message: $toastMessage)
        .task {
            loadCoverImage()
        }
        .sheet(isPresented: Binding(
            get: { shareURL != nil },
            set: { if !$0 { shareURL = nil } }
        )) {
            if let shareURL {
                ShareSheet(items: [shareURL]) {
                    recordCardCreated()
                }
            }
        }
    }

    private var templateGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: AppLayout.mediumGap) {
            ForEach(RecordCardTemplate.allCases) { template in
                Button {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        selectedTemplate = template
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: template.iconName)
                            .font(.system(size: 20))
                            .foregroundStyle(selectedTemplate == template ? AppColors.primary : AppColors.textMuted)
                        Text(template.displayName)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.text)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppLayout.mediumGap)
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                            .stroke(selectedTemplate == template ? AppColors.primary : AppColors.line,
                                    lineWidth: selectedTemplate == template ? 2 : 1)
                    )
                    .scaleEffect(selectedTemplate == template ? 1.0 : 0.98)
                }
                .accessibilityLabel("\(template.displayName) 템플릿\(selectedTemplate == template ? ", 선택됨" : "")")
            }
        }
        .padding(.horizontal, AppLayout.horizontalPadding)
    }

    private var actionBar: some View {
        HStack(spacing: AppLayout.mediumGap) {
            SecondaryButton(title: "이미지 저장") {
                saveToPhotos()
            }
            PrimaryButton(title: "공유") {
                share()
            }
        }
        .padding(.horizontal, AppLayout.horizontalPadding)
        .padding(.vertical, AppLayout.mediumGap)
        .background(AppColors.surface)
        .disabled(isExporting)
    }

    // MARK: - Actions

    private func loadCoverImage() {
        guard let entry,
              let cover = entryRepository.coverAsset(for: entry) else { return }
        if let localImage = cover.loadLocalImage() {
            coverImage = localImage
            return
        }
        guard let localId = cover.localIdentifier,
              let phAsset = photoService.fetchAsset(localIdentifier: localId) else { return }
        photoService.requestFullImage(for: phAsset) { image in
            DispatchQueue.main.async {
                self.coverImage = image
            }
        }
    }

    @MainActor
    private func renderCard() -> UIImage? {
        guard let context else { return nil }
        return CardRenderService.renderImage(template: selectedTemplate, context: context)
    }

    private func saveToPhotos() {
        guard let image = renderCard() else {
            toastMessage = "카드를 만들지 못했어요."
            return
        }
        isExporting = true
        Task {
            let success = await photoService.saveImageToPhotos(image)
            await MainActor.run {
                isExporting = false
                if success {
                    toastMessage = "사진 앱에 저장했어요."
                    recordCardCreated()
                } else {
                    toastMessage = "사진 저장 권한이 필요해요. 공유하기는 계속 쓸 수 있어요."
                }
            }
        }
    }

    private func share() {
        guard let image = renderCard(), let url = CardRenderService.writeTempPNG(image) else {
            toastMessage = "카드를 만들지 못했어요."
            return
        }
        shareURL = url
    }

    private func recordCardCreated() {
        guard let entry else { return }
        let card = RecordCard(
            id: UUID().uuidString,
            entryId: entry.id,
            templateId: selectedTemplate.rawValue,
            imagePath: nil,
            createdAt: Date()
        )
        entryRepository.saveCard(card)
    }
}

/// iOS share sheet wrapper.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var onComplete: (() -> Void)?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, _ in
            if completed {
                onComplete?()
            }
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
