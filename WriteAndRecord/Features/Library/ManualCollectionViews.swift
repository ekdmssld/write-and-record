import SwiftUI

/// 수동 컬렉션 만들기/이름 변경 폼 (docs/01 P2 — 예: "2026 맛집").
struct CollectionFormView: View {
    /// nil이면 새 컬렉션 생성, 값이 있으면 수정.
    var editing: EntryCollection?
    var onDone: ((EntryCollection) -> Void)?

    @EnvironmentObject private var entryRepository: EntryRepository
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var descriptionText = ""

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && name.trimmingCharacters(in: .whitespaces).count <= 30
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppLayout.largeGap) {
                    VStack(alignment: .leading, spacing: AppLayout.smallGap) {
                        Text("이름")
                            .font(AppTypography.headline)
                        TextField("예: 2026 맛집 (1~30자)", text: $name)
                            .font(AppTypography.body)
                            .padding(12)
                            .background(AppColors.surfaceAlt)
                            .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
                    }
                    VStack(alignment: .leading, spacing: AppLayout.smallGap) {
                        Text("설명 (선택)")
                            .font(AppTypography.headline)
                        GrowingTextField(placeholder: "이 모음에 대한 짧은 설명", text: $descriptionText, lineRange: 1...3)
                    }
                }
                .padding(AppLayout.horizontalPadding)
            }
            .background(AppColors.bg)
            .navigationTitle(editing == nil ? "컬렉션 만들기" : "컬렉션 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(editing == nil ? "만들기" : "저장") { save() }
                        .disabled(!isValid)
                }
            }
            .onAppear {
                if let editing {
                    name = editing.name
                    descriptionText = editing.description ?? ""
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func save() {
        let trimmedDescription = descriptionText.trimmingCharacters(in: .whitespaces)
        if var editing {
            editing.name = name.trimmingCharacters(in: .whitespaces)
            editing.description = trimmedDescription.isEmpty ? nil : trimmedDescription
            entryRepository.updateCollection(editing)
            dismiss()
            onDone?(editing)
        } else {
            let created = entryRepository.createCollection(
                name: name,
                description: trimmedDescription.isEmpty ? nil : trimmedDescription
            )
            dismiss()
            onDone?(created)
        }
    }
}

/// 수동 컬렉션 상세: 담긴 기록 목록 + 이름 변경/삭제/기록 빼기.
struct ManualCollectionDetailView: View {
    let collectionId: String

    @EnvironmentObject private var entryRepository: EntryRepository
    @EnvironmentObject private var router: NavigationRouter
    @Environment(\.dismiss) private var dismiss

    @State private var showEditForm = false
    @State private var showDeleteConfirm = false

    private var collection: EntryCollection? {
        entryRepository.collection(id: collectionId)
    }

    var body: some View {
        Group {
            if let collection {
                content(collection)
            } else {
                EmptyStateView(iconName: "square.stack", title: "컬렉션을 찾을 수 없어요")
            }
        }
        .background(AppColors.bg)
        .navigationTitle(collection?.name ?? "컬렉션")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if collection != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showEditForm = true
                        } label: {
                            Label("이름/설명 수정", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("컬렉션 삭제", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("컬렉션 메뉴")
                }
            }
        }
        .sheet(isPresented: $showEditForm) {
            CollectionFormView(editing: collection)
        }
        .confirmationDialog("이 컬렉션을 삭제할까요?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("삭제", role: .destructive) {
                if let collection {
                    entryRepository.deleteCollection(collection)
                    dismiss()
                }
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("컬렉션만 삭제되고 담긴 기록은 그대로 남아요.")
        }
    }

    private func content(_ collection: EntryCollection) -> some View {
        let entries = entryRepository.entries(in: collection)
        return ScrollView {
            VStack(alignment: .leading, spacing: AppLayout.mediumGap) {
                if let description = collection.description, !description.isEmpty {
                    Text(description)
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.textMuted)
                        .padding(.horizontal, AppLayout.horizontalPadding)
                }

                if entries.isEmpty {
                    EmptyStateView(
                        iconName: "square.stack",
                        title: "아직 담긴 기록이 없어요",
                        subtitle: "기록 상세의 메뉴에서 '컬렉션에 담기'로 추가할 수 있어요."
                    )
                } else {
                    ForEach(entries) { entry in
                        Button {
                            router.push(.entryDetail(entryId: entry.id))
                        } label: {
                            EntryCardView(entry: entry)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, AppLayout.horizontalPadding)
                        .contextMenu {
                            Button(role: .destructive) {
                                entryRepository.toggleEntry(entry, in: collection)
                            } label: {
                                Label("컬렉션에서 빼기", systemImage: "minus.circle")
                            }
                        }
                    }
                }
            }
            .padding(.vertical, AppLayout.mediumGap)
        }
    }
}

/// 기록 상세에서 여는 "컬렉션에 담기" 시트.
/// 체크로 담기/빼기를 토글하고, 새 컬렉션도 바로 만들 수 있다.
struct CollectionMembershipSheet: View {
    let entry: Entry

    @EnvironmentObject private var entryRepository: EntryRepository
    @Environment(\.dismiss) private var dismiss

    @State private var showCreateForm = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(entryRepository.manualCollections) { collection in
                    let isMember = entryRepository.isEntry(entry, in: collection)
                    Button {
                        entryRepository.toggleEntry(entry, in: collection)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(collection.name)
                                    .font(AppTypography.body)
                                    .foregroundStyle(AppColors.text)
                                Text("기록 \(collection.entryIds.count)개")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColors.textMuted)
                            }
                            Spacer()
                            Image(systemName: isMember ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(isMember ? AppColors.primary : AppColors.line)
                        }
                    }
                    .accessibilityLabel("\(collection.name)\(isMember ? ", 담김" : "")")
                }

                Button {
                    showCreateForm = true
                } label: {
                    Label("새 컬렉션 만들기", systemImage: "plus.circle")
                        .foregroundStyle(AppColors.primary)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppColors.bg)
            .navigationTitle("컬렉션에 담기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") { dismiss() }
                }
            }
            .overlay {
                if entryRepository.manualCollections.isEmpty {
                    EmptyStateView(
                        iconName: "square.stack",
                        title: "아직 컬렉션이 없어요",
                        subtitle: "첫 컬렉션을 만들어 기록을 모아보세요.",
                        actionTitle: "새 컬렉션 만들기"
                    ) {
                        showCreateForm = true
                    }
                }
            }
            .sheet(isPresented: $showCreateForm) {
                CollectionFormView { created in
                    entryRepository.toggleEntry(entry, in: created)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
