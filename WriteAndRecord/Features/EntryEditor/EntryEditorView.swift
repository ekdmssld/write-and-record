import SwiftUI

struct EntryEditorView: View {
    @StateObject private var viewModel: EntryEditorViewModel

    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var entryRepository: EntryRepository
    @EnvironmentObject private var categoryRepository: CategoryRepository
    @EnvironmentObject private var router: NavigationRouter
    @Environment(\.scenePhase) private var scenePhase

    @State private var showPhotoPicker = false
    @State private var showCancelConfirm = false
    @State private var showSaveFailedAlert = false
    @State private var toastMessage: String?

    init(date: Date, categoryId: String, editingEntryId: String?) {
        _viewModel = StateObject(wrappedValue: EntryEditorViewModel(
            date: date, categoryId: categoryId, editingEntryId: editingEntryId
        ))
    }

    private var category: EntryCategory? {
        categoryRepository.category(id: viewModel.entry.categoryId)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppLayout.largeGap) {
                photoStrip
                titleSection
                dateRow
                ratingWishRow
                bodySection
                additionalSections
                metadataSection
            }
            .padding(.horizontal, AppLayout.horizontalPadding)
            .padding(.vertical, AppLayout.mediumGap)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(AppColors.bg)
        .navigationTitle(viewModel.editingEntryId == nil ? "새 기록" : "기록 수정")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("취소") {
                    if viewModel.hasChanges {
                        showCancelConfirm = true
                    } else {
                        cancelAndClose()
                    }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("저장") { save() }
                    .disabled(!viewModel.canSave)
                    .fontWeight(.semibold)
            }
        }
        .confirmationDialog("변경사항을 버릴까요?", isPresented: $showCancelConfirm, titleVisibility: .visible) {
            Button("계속 편집") { }
            Button("버리기", role: .destructive) { cancelAndClose() }
        }
        .alert("저장하지 못했어요", isPresented: $showSaveFailedAlert) {
            Button("다시 시도") { save() }
            Button("계속 편집", role: .cancel) { }
        } message: {
            Text("입력한 내용은 임시 저장되어 있어요.")
        }
        .sheet(isPresented: $showPhotoPicker) {
            DatePhotoPickerView(date: viewModel.entry.date, alreadySelected: viewModel.pendingAssets) { newAssets in
                viewModel.pendingAssets = newAssets
                viewModel.noteChanged()
            }
        }
        .toast(message: $toastMessage)
        .onAppear {
            viewModel.configure(repository: entryRepository, userId: appState.session?.userId ?? "local-user")
            if viewModel.didRestoreDraft {
                toastMessage = "임시 저장된 내용을 불러왔어요."
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            // 앱 background 진입 시 즉시 draft save (Functional Spec 8장)
            if newPhase == .background || newPhase == .inactive {
                viewModel.saveDraftNow()
            }
        }
        .onDisappear {
            viewModel.cancelAutosave()
        }
    }

    // MARK: - Sections

    private var photoStrip: some View {
        VStack(alignment: .leading, spacing: AppLayout.smallGap) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppLayout.smallGap) {
                    Button {
                        showPhotoPicker = true
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 22))
                            Text("사진")
                                .font(AppTypography.caption)
                        }
                        .foregroundStyle(AppColors.primary)
                        .frame(width: 84, height: 84)
                        .background(AppColors.surfaceAlt)
                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
                    }
                    .accessibilityLabel("사진 추가")

                    ForEach(viewModel.pendingAssets) { asset in
                        ZStack(alignment: .topTrailing) {
                            AssetThumbnailView(asset: asset)
                                .frame(width: 84, height: 84)
                                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
                            Button {
                                viewModel.pendingAssets.removeAll { $0.id == asset.id }
                                viewModel.noteChanged()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.white, Color.black.opacity(0.5))
                            }
                            .padding(4)
                            .accessibilityLabel("사진 제거")
                        }
                    }
                }
            }
        }
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField("제목 (필수)", text: $viewModel.entry.title)
                .font(AppTypography.title2)
                .onChange(of: viewModel.entry.title) { _, _ in viewModel.noteChanged() }
            if !viewModel.entry.title.isEmpty && !viewModel.isTitleValid {
                Text("제목은 1~80자로 입력해 주세요.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.danger)
            }
            Divider().overlay(AppColors.line)
        }
    }

    private var dateRow: some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundStyle(AppColors.textMuted)
            DatePicker("날짜", selection: $viewModel.entry.date, displayedComponents: .date)
                .labelsHidden()
                .onChange(of: viewModel.entry.date) { _, _ in viewModel.noteChanged() }
            Spacer()
            if let category {
                CategoryChip(category: category)
            }
        }
    }

    private var ratingWishRow: some View {
        HStack {
            RatingControl(rating: $viewModel.entry.rating)
                .onChange(of: viewModel.entry.rating) { _, _ in viewModel.noteChanged() }
            Spacer()
            WishlistToggle(isWishlist: $viewModel.entry.isWishlist)
                .onChange(of: viewModel.entry.isWishlist) { _, _ in viewModel.noteChanged() }
        }
    }

    private var bodySection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("내용")
                .font(AppTypography.headline)
                .foregroundStyle(AppColors.text)
            TextEditor(text: $viewModel.entry.body)
                .font(AppTypography.body)
                .frame(minHeight: 140)
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                        .stroke(AppColors.line, lineWidth: 1)
                )
                .onChange(of: viewModel.entry.body) { _, _ in viewModel.noteChanged() }
            if !viewModel.isBodyValid {
                Text("내용은 최대 10,000자까지 입력할 수 있어요.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.danger)
            }
        }
    }

    private var additionalSections: some View {
        VStack(alignment: .leading, spacing: AppLayout.mediumGap) {
            Text("추가 섹션")
                .font(AppTypography.headline)
                .foregroundStyle(AppColors.text)

            StringListEditor(title: "장점", systemImage: "hand.thumbsup", items: $viewModel.entry.pros) {
                viewModel.noteChanged()
            }
            StringListEditor(title: "단점", systemImage: "hand.thumbsdown", items: $viewModel.entry.cons) {
                viewModel.noteChanged()
            }
            StringListEditor(title: "팁", systemImage: "lightbulb", items: $viewModel.entry.tips) {
                viewModel.noteChanged()
            }

            countRow
            placeSection
            linksSection
        }
    }

    private var countRow: some View {
        HStack {
            Label("횟수", systemImage: "number")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.text)
            Spacer()
            TextField("예: 3", text: Binding(
                get: { viewModel.entry.count.map(String.init) ?? "" },
                set: { newValue in
                    viewModel.entry.count = Int(newValue.trimmingCharacters(in: .whitespaces))
                    viewModel.noteChanged()
                }
            ))
            .keyboardType(.numberPad)
            .multilineTextAlignment(.trailing)
            .frame(width: 100)
        }
        .padding(AppLayout.mediumGap)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .stroke(AppColors.line, lineWidth: 1)
        )
    }

    private var placeSection: some View {
        VStack(alignment: .leading, spacing: AppLayout.smallGap) {
            Label("장소", systemImage: "mappin.and.ellipse")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.text)
            TextField("장소 이름", text: Binding(
                get: { viewModel.entry.place?.name ?? "" },
                set: { newValue in
                    if newValue.isEmpty {
                        viewModel.entry.place = nil
                    } else {
                        var place = viewModel.entry.place ?? PlaceRef(name: "")
                        place.name = newValue
                        viewModel.entry.place = place
                    }
                    viewModel.noteChanged()
                }
            ))
            .font(AppTypography.body)
            if viewModel.entry.place != nil {
                TextField("주소 (선택)", text: Binding(
                    get: { viewModel.entry.place?.address ?? "" },
                    set: { newValue in
                        viewModel.entry.place?.address = newValue.isEmpty ? nil : newValue
                        viewModel.noteChanged()
                    }
                ))
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.textMuted)
            }
        }
        .padding(AppLayout.mediumGap)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .stroke(AppColors.line, lineWidth: 1)
        )
    }

    private var linksSection: some View {
        VStack(alignment: .leading, spacing: AppLayout.smallGap) {
            HStack {
                Label("링크", systemImage: "link")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.text)
                Spacer()
                Button {
                    viewModel.entry.links.append(LinkRef(title: nil, url: ""))
                    viewModel.noteChanged()
                } label: {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(AppColors.primary)
                }
                .accessibilityLabel("링크 추가")
            }
            ForEach($viewModel.entry.links) { $link in
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        TextField("https://...", text: $link.url)
                            .font(AppTypography.callout)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .onChange(of: link.url) { _, _ in viewModel.noteChanged() }
                        Button {
                            viewModel.entry.links.removeAll { $0.id == link.id }
                            viewModel.noteChanged()
                        } label: {
                            Image(systemName: "minus.circle")
                                .foregroundStyle(AppColors.danger)
                        }
                        .accessibilityLabel("링크 삭제")
                    }
                    if !link.url.isEmpty && !Validation.isValidURL(link.url) {
                        Text("올바른 URL을 입력해 주세요. (http/https)")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.danger)
                    }
                }
            }
        }
        .padding(AppLayout.mediumGap)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .stroke(AppColors.line, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var metadataSection: some View {
        let fields = MetadataField.fields(for: category?.mainType ?? .custom)
        if !fields.isEmpty {
            VStack(alignment: .leading, spacing: AppLayout.smallGap) {
                Text("\(category?.name ?? "") 상세")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.text)
                ForEach(fields) { field in
                    HStack {
                        Text(field.label)
                            .font(AppTypography.callout)
                            .foregroundStyle(AppColors.textMuted)
                            .frame(width: 130, alignment: .leading)
                        TextField("", text: Binding(
                            get: { viewModel.entry.metadata[field.key] ?? "" },
                            set: { newValue in
                                viewModel.entry.metadata[field.key] = newValue
                                viewModel.noteChanged()
                            }
                        ))
                        .font(AppTypography.body)
                        .keyboardType(field.keyboardNumeric ? .decimalPad : .default)
                    }
                    Divider().overlay(AppColors.line)
                }
            }
            .padding(AppLayout.mediumGap)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                    .stroke(AppColors.line, lineWidth: 1)
            )
        }
    }

    // MARK: - Actions

    private func save() {
        let success = viewModel.save(to: entryRepository)
        if success {
            // 저장 성공: 상세 화면 진입 시 "기록이 저장됐어요" toast 표시
            UserDefaults.standard.set(true, forKey: "pendingSaveToast")
            router.replaceTop(with: .entryDetail(entryId: viewModel.entry.id))
        } else if viewModel.saveState == .saveFailed {
            showSaveFailedAlert = true
        }
    }

    private func cancelAndClose() {
        viewModel.cancelAutosave()
        DraftStore.clear()
        router.pop()
    }
}

/// 장점/단점/팁 문자열 리스트 편집기 (각 항목 최대 120자).
struct StringListEditor: View {
    let title: String
    let systemImage: String
    @Binding var items: [String]
    var onChanged: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.smallGap) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.text)
                Spacer()
                Button {
                    items.append("")
                    onChanged()
                } label: {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(AppColors.primary)
                }
                .accessibilityLabel("\(title) 항목 추가")
            }
            ForEach(items.indices, id: \.self) { index in
                HStack {
                    TextField("\(title) 입력", text: Binding(
                        get: { index < items.count ? items[index] : "" },
                        set: { newValue in
                            if index < items.count {
                                items[index] = String(newValue.prefix(120))
                                onChanged()
                            }
                        }
                    ))
                    .font(AppTypography.callout)
                    Button {
                        if index < items.count {
                            items.remove(at: index)
                            onChanged()
                        }
                    } label: {
                        Image(systemName: "minus.circle")
                            .foregroundStyle(AppColors.danger)
                    }
                    .accessibilityLabel("\(title) 항목 삭제")
                }
            }
        }
        .padding(AppLayout.mediumGap)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .stroke(AppColors.line, lineWidth: 1)
        )
    }
}
