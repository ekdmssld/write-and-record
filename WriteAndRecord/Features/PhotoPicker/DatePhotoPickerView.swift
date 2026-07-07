import SwiftUI
import Photos

/// 선택 날짜의 사진을 우선 노출하는 사진 선택기 (Flowchart 3).
/// 기본 그리드는 항상 "이 날짜" 사진이고, 상단의 카메라/전체 사진 버튼으로
/// 촬영하거나 전체 사진첩에서 고를 수 있다.
/// 권한 거부 시에도 기록 저장은 계속 가능하다.
struct DatePhotoPickerView: View {
    let date: Date
    var alreadySelected: [MediaAsset] = []
    let onDone: ([MediaAsset]) -> Void

    @EnvironmentObject private var photoService: PhotoLibraryService
    @Environment(\.dismiss) private var dismiss

    enum Tab {
        case thisDate
        case all
    }

    @State private var tab: Tab = .thisDate
    @State private var dateAssets: [PHAsset] = []
    @State private var allAssets: [PHAsset] = []
    @State private var selectedIds: [String] = []
    /// 카메라로 촬영했거나 이전에 첨부한 앱 내부 저장 사진 (PHAsset 아님).
    @State private var capturedAssets: [MediaAsset] = []
    @State private var isLoading = true
    @State private var showCamera = false
    @State private var toastMessage: String?

    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]

    private var selectedCount: Int {
        selectedIds.count + capturedAssets.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                sourceButtons
                content
                bottomBar
            }
            .background(AppColors.bg)
            .navigationTitle("사진 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
            .toast(message: $toastMessage)
            .fullScreenCover(isPresented: $showCamera) {
                CameraCaptureView { image in
                    if let asset = photoService.saveCapturedImage(image) {
                        capturedAssets.append(asset)
                    } else {
                        toastMessage = "사진을 저장하지 못했어요."
                    }
                }
                .ignoresSafeArea()
            }
            .task {
                await loadIfNeeded()
            }
        }
    }

    /// 상단 소스 버튼: 카메라 촬영 / 전체 사진 전환.
    private var sourceButtons: some View {
        HStack(spacing: AppLayout.smallGap) {
            Button {
                if CameraCaptureView.isCameraAvailable {
                    showCamera = true
                } else {
                    toastMessage = "이 기기에서는 카메라를 쓸 수 없어요."
                }
            } label: {
                Label("카메라", systemImage: "camera")
                    .font(AppTypography.callout)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(AppColors.surfaceAlt)
                    .foregroundStyle(AppColors.text)
                    .clipShape(Capsule())
            }
            .accessibilityLabel("카메라로 촬영")

            Button {
                withAnimation { tab = tab == .all ? .thisDate : .all }
            } label: {
                Label(tab == .all ? "이 날짜 사진" : "전체 사진", systemImage: "photo.on.rectangle")
                    .font(AppTypography.callout)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(tab == .all ? AppColors.primary.opacity(0.12) : AppColors.surfaceAlt)
                    .foregroundStyle(tab == .all ? AppColors.primary : AppColors.text)
                    .clipShape(Capsule())
            }
            .accessibilityLabel(tab == .all ? "이 날짜 사진만 보기" : "전체 사진에서 선택")

            Spacer()
        }
        .padding(.horizontal, AppLayout.horizontalPadding)
        .padding(.vertical, AppLayout.smallGap)
    }

    @ViewBuilder
    private var content: some View {
        switch photoService.permission {
        case .denied:
            deniedState
        case .notDetermined:
            VStack(spacing: AppLayout.mediumGap) {
                EmptyStateView(
                    iconName: "photo.on.rectangle",
                    title: "사진 접근 권한이 필요해요",
                    subtitle: "선택한 날짜의 사진을 기록에 첨부하기 위해 사진 접근이 필요해요.",
                    actionTitle: "사진 접근 허용"
                ) {
                    Task {
                        await photoService.requestPermission()
                        await loadAssets()
                    }
                }
            }
            .frame(maxHeight: .infinity)
        case .authorized, .limited:
            VStack(spacing: 0) {
                if photoService.permission == .limited {
                    limitedBanner
                }
                photoGrid
            }
        }
    }

    private var deniedState: some View {
        VStack {
            if !capturedAssets.isEmpty {
                capturedStrip
            }
            EmptyStateView(
                iconName: "photo.on.rectangle.angled",
                title: "사진 접근이 꺼져 있어요",
                subtitle: "설정에서 권한을 허용하거나, 카메라 촬영 또는 사진 없이 기록을 계속할 수 있어요.",
                actionTitle: "설정 열기"
            ) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("사진 없이 계속하기") { dismiss() }
                .font(AppTypography.headline)
                .foregroundStyle(AppColors.primary)
        }
        .frame(maxHeight: .infinity)
    }

    private var limitedBanner: some View {
        HStack(spacing: AppLayout.smallGap) {
            Image(systemName: "info.circle")
            Text("선택된 사진만 표시돼요.")
                .font(AppTypography.caption)
            Spacer()
            Button("권한 관리") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(AppTypography.caption)
        }
        .foregroundStyle(AppColors.textMuted)
        .padding(.horizontal, AppLayout.horizontalPadding)
        .padding(.vertical, 6)
        .background(AppColors.surfaceAlt)
    }

    /// 촬영한 사진 미리보기 (자동 선택 상태).
    private var capturedStrip: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("촬영한 사진")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textMuted)
                .padding(.horizontal, AppLayout.horizontalPadding)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppLayout.smallGap) {
                    ForEach(capturedAssets) { asset in
                        ZStack(alignment: .topTrailing) {
                            AssetThumbnailView(asset: asset)
                                .frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            Button {
                                capturedAssets.removeAll { $0.id == asset.id }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.white, Color.black.opacity(0.5))
                            }
                            .padding(2)
                            .accessibilityLabel("촬영한 사진 제거")
                        }
                    }
                }
                .padding(.horizontal, AppLayout.horizontalPadding)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var photoGrid: some View {
        let assets = tab == .thisDate ? dateAssets : allAssets
        VStack(spacing: 0) {
            if !capturedAssets.isEmpty {
                capturedStrip
            }
            if isLoading {
                ProgressView().frame(maxHeight: .infinity)
            } else if assets.isEmpty {
                VStack {
                    EmptyStateView(
                        iconName: "photo",
                        title: tab == .thisDate ? "이 날짜에 찍은 사진이 없어요" : "표시할 사진이 없어요",
                        subtitle: tab == .thisDate ? "카메라로 찍거나 전체 사진에서 골라보세요." : nil,
                        actionTitle: tab == .thisDate ? "전체 사진 보기" : nil
                    ) {
                        withAnimation { tab = .all }
                    }
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppLayout.smallGap) {
                        Text(tab == .thisDate ? "\(DateUtils.short(date))에 찍은 사진" : "전체 사진")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textMuted)
                            .padding(.horizontal, AppLayout.horizontalPadding)
                        LazyVGrid(columns: columns, spacing: 4) {
                            ForEach(assets, id: \.localIdentifier) { asset in
                                PhotoGridCell(
                                    asset: asset,
                                    isSelected: selectedIds.contains(asset.localIdentifier),
                                    selectionIndex: selectedIds.firstIndex(of: asset.localIdentifier).map { $0 + 1 }
                                ) {
                                    toggleSelection(asset)
                                }
                            }
                        }
                        .padding(.horizontal, AppLayout.horizontalPadding)
                    }
                    .padding(.vertical, AppLayout.smallGap)
                }
            }
        }
    }

    private var bottomBar: some View {
        HStack {
            Text(selectedCount == 0 ? "사진을 선택하세요" : "\(selectedCount)장 선택됨")
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.textMuted)
            Spacer()
            Button("추가") { finish() }
                .font(AppTypography.headline)
                .foregroundStyle(selectedCount == 0 && alreadySelected.isEmpty ? AppColors.textMuted : AppColors.primary)
                .disabled(selectedCount == 0 && alreadySelected.isEmpty)
        }
        .padding(.horizontal, AppLayout.horizontalPadding)
        .padding(.vertical, AppLayout.mediumGap)
        .background(AppColors.surface)
    }

    // MARK: - Logic

    private func loadIfNeeded() async {
        photoService.refreshPermission()
        selectedIds = alreadySelected.compactMap { $0.localIdentifier }
        capturedAssets = alreadySelected.filter { $0.localIdentifier == nil }
        if photoService.permission == .notDetermined {
            await photoService.requestPermission()
        }
        await loadAssets()
    }

    private func loadAssets() async {
        guard photoService.permission == .authorized || photoService.permission == .limited else {
            isLoading = false
            return
        }
        isLoading = true
        let service = photoService
        let targetDate = date
        let (dated, all) = await Task.detached(priority: .userInitiated) {
            (service.fetchAssets(on: targetDate), service.fetchAssets(on: nil))
        }.value
        await MainActor.run {
            dateAssets = dated
            allAssets = all
            isLoading = false
        }
    }

    private func toggleSelection(_ asset: PHAsset) {
        if let index = selectedIds.firstIndex(of: asset.localIdentifier) {
            selectedIds.remove(at: index)
        } else {
            selectedIds.append(asset.localIdentifier)
        }
    }

    private func finish() {
        // 촬영 사진 + 사진첩 선택. 이미 MediaAsset으로 저장된 사진은 재사용한다.
        var result: [MediaAsset] = capturedAssets
        for localId in selectedIds {
            if let existing = alreadySelected.first(where: { $0.localIdentifier == localId }) {
                result.append(existing)
            } else if let phAsset = photoService.fetchAsset(localIdentifier: localId) {
                result.append(photoService.makeMediaAsset(from: phAsset))
            }
        }
        onDone(result)
        dismiss()
    }
}

struct PhotoGridCell: View {
    let asset: PHAsset
    let isSelected: Bool
    var selectionIndex: Int?
    let onTap: () -> Void

    @EnvironmentObject private var photoService: PhotoLibraryService
    @State private var image: UIImage?

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                Group {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        AppColors.surfaceAlt
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isSelected ? AppColors.primary : .clear, lineWidth: 3)
                )

                if isSelected {
                    ZStack {
                        Circle().fill(AppColors.primary)
                        if let selectionIndex {
                            Text("\(selectionIndex)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        } else {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: 22, height: 22)
                    .padding(6)
                    .transition(.opacity)
                }
            }
        }
        .accessibilityLabel("사진\(isSelected ? ", 선택됨" : "")")
        .onAppear {
            if image == nil {
                photoService.requestThumbnail(for: asset, size: CGSize(width: 300, height: 300)) { loaded in
                    DispatchQueue.main.async {
                        self.image = loaded
                    }
                }
            }
        }
    }
}
