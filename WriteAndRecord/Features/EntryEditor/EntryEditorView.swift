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
    @State private var showCategoryChange = false
    @State private var showVisibilitySheet = false
    @State private var showPlaceSearch = false
    @State private var toastMessage: String?
    /// 현재 펼쳐진 추가 섹션 (한 번에 하나).
    @State private var activeSection: EditorSection?

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
                wishlistTypeRow
                visibilityRow
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
        .sheet(isPresented: $showPlaceSearch) {
            PlaceSearchSheet(initialQuery: viewModel.entry.place?.name ?? "") { selectedPlace in
                viewModel.entry.place = selectedPlace
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
            // 스와이프 뒤로가기 등으로 이탈해도 입력을 잃지 않도록 draft를 남긴다.
            // (정상 저장/취소 경로에서는 이미 draft가 정리된 뒤라 no-op)
            if viewModel.saveState != .saved {
                viewModel.saveDraftNow()
            }
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
            // 카테고리는 작성 중에도 변경 가능 (고정 아님)
            Button {
                showCategoryChange = true
            } label: {
                HStack(spacing: 4) {
                    if let category {
                        CategoryChip(category: category)
                    } else {
                        Text("카테고리 선택")
                            .font(AppTypography.callout)
                            .foregroundStyle(AppColors.primary)
                    }
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppColors.textMuted)
                }
            }
            .accessibilityLabel("카테고리 변경, 현재 \(category?.name ?? "없음")")
        }
        .sheet(isPresented: $showCategoryChange) {
            CategoryChangeSheet(currentCategoryId: viewModel.entry.categoryId) { newCategory in
                viewModel.entry.categoryId = newCategory.id
                viewModel.noteChanged()
            }
        }
    }

    private var ratingWishRow: some View {
        HStack {
            RatingControl(rating: $viewModel.entry.rating)
                .onChange(of: viewModel.entry.rating) { _, _ in viewModel.noteChanged() }
            Spacer()
            WishlistToggle(isWishlist: $viewModel.entry.isWishlist)
                .onChange(of: viewModel.entry.isWishlist) { _, newValue in
                    if !newValue {
                        viewModel.entry.wishlistType = nil
                    }
                    viewModel.noteChanged()
                }
        }
    }

    /// 위시 분류 선택 (docs/12 J). 위시가 켜졌을 때만 노출.
    @ViewBuilder
    private var wishlistTypeRow: some View {
        if viewModel.entry.isWishlist {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppLayout.smallGap) {
                    ForEach(WishlistType.allCases) { type in
                        let isSelected = viewModel.entry.wishlistType == type
                        Button {
                            viewModel.entry.wishlistType = isSelected ? nil : type
                            viewModel.noteChanged()
                        } label: {
                            Label(type.displayName, systemImage: type.iconName)
                                .font(AppTypography.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(isSelected ? AppColors.primary.opacity(0.12) : AppColors.surfaceAlt)
                                .foregroundStyle(isSelected ? AppColors.primary : AppColors.textMuted)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(isSelected ? AppColors.primary : .clear, lineWidth: 1)
                                )
                        }
                        .accessibilityLabel("위시 분류 \(type.displayName)\(isSelected ? ", 선택됨" : "")")
                    }
                }
            }
        }
    }

    /// 공개 범위 선택 (docs/11 8장). 기본은 나만 보기.
    @ViewBuilder
    private var visibilityRow: some View {
        if FeatureFlags.enableFriendFeatures {
            let current = viewModel.entry.effectiveVisibility
            Button {
                showVisibilitySheet = true
            } label: {
                HStack(spacing: AppLayout.smallGap) {
                    Image(systemName: current.iconName)
                        .foregroundStyle(AppColors.textMuted)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(current.displayName)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.text)
                        Text(current.explanation)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textMuted)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.textMuted)
                }
                .padding(AppLayout.mediumGap)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                        .stroke(AppColors.line, lineWidth: 1)
                )
            }
            .accessibilityLabel("공개 범위, 현재 \(current.displayName)")
            .sheet(isPresented: $showVisibilitySheet) {
                VisibilityPickerSheet(current: current) { newValue in
                    viewModel.entry.visibility = newValue
                    viewModel.noteChanged()
                }
            }
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

    /// 추가 섹션 종류. 3개씩 두 줄(장점/단점/팁, 횟수/장소/링크)로 배치된다.
    enum EditorSection: String, CaseIterable, Identifiable {
        case pros, cons, tips, count, place, links

        var id: String { rawValue }

        var title: String {
            switch self {
            case .pros: return "장점"
            case .cons: return "단점"
            case .tips: return "팁"
            case .count: return "횟수"
            case .place: return "장소"
            case .links: return "링크"
            }
        }

        var systemImage: String {
            switch self {
            case .pros: return "hand.thumbsup"
            case .cons: return "hand.thumbsdown"
            case .tips: return "lightbulb"
            case .count: return "number"
            case .place: return "mappin.and.ellipse"
            case .links: return "link"
            }
        }
    }

    private var additionalSections: some View {
        VStack(alignment: .leading, spacing: AppLayout.smallGap) {
            Text("추가 섹션")
                .font(AppTypography.headline)
                .foregroundStyle(AppColors.text)

            // 장점/단점/팁 한 줄, 횟수/장소/링크 한 줄
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: AppLayout.smallGap) {
                ForEach(EditorSection.allCases) { section in
                    sectionChip(section)
                }
            }

            if let activeSection {
                sectionContent(activeSection)
                    .padding(AppLayout.smallGap)
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                            .stroke(AppColors.primary.opacity(0.4), lineWidth: 1)
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func sectionChip(_ section: EditorSection) -> some View {
        let isActive = activeSection == section
        let summary = sectionSummary(section)
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if isActive {
                    activeSection = nil
                } else {
                    prepareSectionForEditing(section)
                    activeSection = section
                }
            }
        } label: {
            VStack(spacing: summary == nil ? 2 : 3) {
                Image(systemName: section.systemImage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isActive ? AppColors.primary : AppColors.textMuted)
                Text(section.title)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.text)
                if let summary {
                    Text(summary)
                        .font(.system(size: 10))
                        .foregroundStyle(AppColors.primary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: summary == nil ? 46 : 58)
            .padding(.vertical, summary == nil ? 4 : 6)
            .background(isActive ? AppColors.primary.opacity(0.10) : AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                    .stroke(isActive ? AppColors.primary : AppColors.line, lineWidth: isActive ? 1.5 : 1)
            )
        }
        .accessibilityLabel("\(section.title) 섹션\(summary.map { ", \($0)" } ?? "")\(isActive ? ", 펼쳐짐" : "")")
    }

    private func sectionSummary(_ section: EditorSection) -> String? {
        switch section {
        case .pros, .cons, .tips:
            return nil
        case .count: return viewModel.entry.count.map { "\($0)회" }
        case .place: return viewModel.entry.place?.name
        case .links:
            let filledLinkCount = viewModel.entry.links.filter { !$0.url.trimmingCharacters(in: .whitespaces).isEmpty }.count
            return filledLinkCount == 0 ? nil : "\(filledLinkCount)개"
        }
    }

    private func prepareSectionForEditing(_ section: EditorSection) {
        switch section {
        case .pros:
            if viewModel.entry.pros.isEmpty { viewModel.entry.pros.append("") }
        case .cons:
            if viewModel.entry.cons.isEmpty { viewModel.entry.cons.append("") }
        case .tips:
            if viewModel.entry.tips.isEmpty { viewModel.entry.tips.append("") }
        default:
            break
        }
    }

    @ViewBuilder
    private func sectionContent(_ section: EditorSection) -> some View {
        switch section {
        case .pros:
            StringListEditor(title: "장점", items: $viewModel.entry.pros) {
                viewModel.noteChanged()
            }
        case .cons:
            StringListEditor(title: "단점", items: $viewModel.entry.cons) {
                viewModel.noteChanged()
            }
        case .tips:
            StringListEditor(title: "팁", items: $viewModel.entry.tips) {
                viewModel.noteChanged()
            }
        case .count:
            countField
        case .place:
            placeFields
        case .links:
            linksContent
        }
    }

    private var countField: some View {
        TextField("예: 3", text: Binding(
            get: { viewModel.entry.count.map(String.init) ?? "" },
            set: { newValue in
                viewModel.entry.count = Int(newValue.trimmingCharacters(in: .whitespaces))
                viewModel.noteChanged()
            }
        ))
        .keyboardType(.numberPad)
        .font(AppTypography.body)
        .padding(10)
        .background(AppColors.surfaceAlt)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
    }

    private var placeFields: some View {
        VStack(alignment: .leading, spacing: AppLayout.smallGap) {
            if let place = viewModel.entry.place {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: AppLayout.smallGap) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(AppColors.primary)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(place.name)
                                .font(AppTypography.headline)
                                .foregroundStyle(AppColors.text)
                                .lineLimit(2)
                            if let address = place.address, !address.isEmpty {
                                Text(address)
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColors.textMuted)
                                    .lineLimit(2)
                            }
                            if place.latitude != nil && place.longitude != nil {
                                Label("지도에 표시돼요", systemImage: "map")
                                    .font(.system(size: 11))
                                    .foregroundStyle(AppColors.primary)
                            }
                        }
                        Spacer()
                    }

                    HStack(spacing: AppLayout.smallGap) {
                        Button {
                            showPlaceSearch = true
                        } label: {
                            Label("다시 선택", systemImage: "magnifyingglass")
                                .font(AppTypography.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(AppColors.surfaceAlt)
                                .clipShape(Capsule())
                        }

                        Button(role: .destructive) {
                            viewModel.entry.place = nil
                            viewModel.noteChanged()
                        } label: {
                            Label("삭제", systemImage: "xmark.circle")
                                .font(AppTypography.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(AppColors.surfaceAlt)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(AppLayout.smallGap)
                .background(AppColors.surfaceAlt)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
            } else {
                Button {
                    showPlaceSearch = true
                } label: {
                    HStack(spacing: AppLayout.smallGap) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppColors.primary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("지역/랜드마크 검색")
                                .font(AppTypography.callout)
                                .foregroundStyle(AppColors.text)
                            Text("성수동, 롯데월드몰처럼 검색해서 지도 위치를 저장해요.")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textMuted)
                                .lineLimit(2)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppColors.textMuted)
                    }
                    .padding(AppLayout.mediumGap)
                    .background(AppColors.surfaceAlt)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var linksContent: some View {
        VStack(alignment: .leading, spacing: AppLayout.smallGap) {
            ForEach($viewModel.entry.links) { $link in
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .top) {
                        GrowingTextField(placeholder: "https://...", text: $link.url, lineRange: 1...3)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .onChange(of: link.url) { _, _ in viewModel.noteChanged() }
                        Button {
                            viewModel.entry.links.removeAll { $0.id == link.id }
                            viewModel.noteChanged()
                        } label: {
                            Image(systemName: "minus.circle")
                                .foregroundStyle(AppColors.danger)
                                .frame(width: 32, height: 40)
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
            Button {
                viewModel.entry.links.append(LinkRef(title: nil, url: ""))
                viewModel.noteChanged()
            } label: {
                Label("링크 추가", systemImage: "plus.circle")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.primary)
            }
        }
    }

    @ViewBuilder
    private var metadataSection: some View {
        let fields = MetadataField.fields(for: category?.mainType ?? .custom)
        if !fields.isEmpty {
            let filledCount = fields.filter { !(viewModel.entry.metadata[$0.key] ?? "").isEmpty }.count
            ExpandableSection(
                title: "\(category?.name ?? "") 상세",
                systemImage: "list.bullet.rectangle",
                summary: filledCount > 0 ? "\(filledCount)개 입력됨" : nil
            ) {
                VStack(alignment: .leading, spacing: AppLayout.mediumGap) {
                    ForEach(fields) { field in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(field.label)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textMuted)
                            GrowingTextField(placeholder: field.label, text: Binding(
                                get: { viewModel.entry.metadata[field.key] ?? "" },
                                set: { newValue in
                                    viewModel.entry.metadata[field.key] = newValue
                                    viewModel.noteChanged()
                                }
                            ), lineRange: 1...3)
                            .keyboardType(field.keyboardNumeric ? .decimalPad : .default)
                        }
                    }
                }
            }
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
        // 명시적으로 버린 경우에는 onDisappear의 draft 저장이 다시 살리지 않도록 초기화
        viewModel.hasChanges = false
        DraftStore.clear()
        router.pop()
    }
}

/// 장점/단점/팁 문자열 리스트 편집기 (각 항목 최대 120자).
struct StringListEditor: View {
    let title: String
    @Binding var items: [String]
    var onChanged: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.smallGap) {
            ForEach(items.indices, id: \.self) { index in
                HStack(alignment: .top) {
                    GrowingTextField(placeholder: "\(title) 입력", text: Binding(
                        get: { index < items.count ? items[index] : "" },
                        set: { newValue in
                            if index < items.count {
                                items[index] = String(newValue.prefix(120))
                                onChanged()
                            }
                        }
                    ), lineRange: 1...4)
                    Button {
                        if index < items.count {
                            if items.count == 1 {
                                items[index] = ""
                            } else {
                                items.remove(at: index)
                            }
                            onChanged()
                        }
                    } label: {
                        Image(systemName: "minus.circle")
                            .foregroundStyle(AppColors.danger)
                            .frame(width: 32, height: 40)
                    }
                    .accessibilityLabel("\(title) 항목 삭제")
                }
            }
        }
        .onAppear {
            if items.isEmpty {
                items.append("")
            }
        }
    }
}
