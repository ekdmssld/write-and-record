import SwiftUI
import Photos

/// 월간 이미지 캘린더 export (docs/12 C항목).
/// 한 달의 기록을 1080x1350 이미지로 만들어 저장/공유한다.
struct MonthlyCalendarExportView: View {
    let month: Date

    @EnvironmentObject private var entryRepository: EntryRepository
    @EnvironmentObject private var categoryRepository: CategoryRepository
    @EnvironmentObject private var photoService: PhotoLibraryService
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var cellData: [Int: MonthCardDayData] = [:]
    @State private var isLoading = true
    @State private var isExporting = false
    @State private var shareURL: URL?
    @State private var toastMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView("사진을 모으고 있어요")
                        .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        MonthCalendarCardView(
                            month: month,
                            spaceName: appState.profile?.spaceName ?? "Write & Record",
                            cellData: cellData
                        )
                        .scaleEffect(0.8)
                        .frame(width: MonthCalendarCardView.baseSize.width * 0.8,
                               height: MonthCalendarCardView.baseSize.height * 0.8)
                        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
                        .padding(.vertical, AppLayout.largeGap)
                        .frame(maxWidth: .infinity)
                    }

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
            }
            .background(AppColors.bg)
            .navigationTitle("\(DateUtils.monthTitle(month)) 캘린더")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
            .toast(message: $toastMessage)
            .sheet(isPresented: Binding(
                get: { shareURL != nil },
                set: { if !$0 { shareURL = nil } }
            )) {
                if let shareURL {
                    ShareSheet(items: [shareURL])
                }
            }
            .task {
                await loadCellData()
            }
        }
    }

    // MARK: - Data

    /// 날짜별 대표 사진/카테고리 점/기록 수를 모은다.
    private func loadCellData() async {
        let entriesByDay = entryRepository.entryCountsByDay(in: month)
        var result: [Int: MonthCardDayData] = [:]

        for (day, entries) in entriesByDay {
            let dotColors: [String] = Array(
                entries.map { categoryRepository.colorHex(forEntry: $0) }
                    .reduce(into: [String]()) { acc, hex in
                        if !acc.contains(hex) { acc.append(hex) }
                    }
                    .prefix(3)
            )
            var image: UIImage?
            if let cover = entryRepository.assets(for: entries[0]).first
                ?? entries.compactMap({ entryRepository.coverAsset(for: $0) }).first {
                image = await loadThumbnail(for: cover)
            }
            result[day] = MonthCardDayData(image: image, dotColors: dotColors, entryCount: entries.count)
        }

        await MainActor.run {
            cellData = result
            isLoading = false
        }
    }

    private func loadThumbnail(for asset: MediaAsset) async -> UIImage? {
        if let localImage = asset.loadLocalImage() {
            return localImage
        }
        guard let localId = asset.localIdentifier,
              let phAsset = photoService.fetchAsset(localIdentifier: localId) else { return nil }
        return await withCheckedContinuation { continuation in
            photoService.requestThumbnail(for: phAsset, size: CGSize(width: 240, height: 240)) { image in
                continuation.resume(returning: image)
            }
        }
    }

    // MARK: - Export

    @MainActor
    private func renderImage() -> UIImage? {
        CardRenderService.render(
            MonthCalendarCardView(
                month: month,
                spaceName: appState.profile?.spaceName ?? "Write & Record",
                cellData: cellData
            ),
            baseSize: MonthCalendarCardView.baseSize
        )
    }

    private func saveToPhotos() {
        guard let image = renderImage() else {
            toastMessage = "이미지를 만들지 못했어요."
            return
        }
        isExporting = true
        Task {
            let success = await photoService.saveImageToPhotos(image)
            await MainActor.run {
                isExporting = false
                toastMessage = success ? "사진 앱에 저장했어요." : "사진 저장 권한이 필요해요. 공유하기는 계속 쓸 수 있어요."
            }
        }
    }

    private func share() {
        guard let image = renderImage(), let url = CardRenderService.writeTempPNG(image) else {
            toastMessage = "이미지를 만들지 못했어요."
            return
        }
        shareURL = url
    }
}

struct MonthCardDayData {
    var image: UIImage?
    var dotColors: [String]
    var entryCount: Int
}

/// export용 월간 캘린더 카드 (360x450 기준, 3배 렌더링 = 1080x1350).
struct MonthCalendarCardView: View {
    let month: Date
    let spaceName: String
    let cellData: [Int: MonthCardDayData]

    static let baseSize = CGSize(width: 360, height: 450)

    private var calendar: Calendar { .current }

    var body: some View {
        let weeks = DateUtils.monthGrid(for: month)

        VStack(alignment: .leading, spacing: 10) {
            // header
            VStack(alignment: .leading, spacing: 2) {
                Text(DateUtils.monthTitle(month))
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(AppColors.text)
                Text(spaceName)
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textMuted)
            }

            // weekday row
            HStack(spacing: 3) {
                ForEach(DateUtils.weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 10))
                        .foregroundStyle(AppColors.textMuted)
                        .frame(maxWidth: .infinity)
                }
            }

            // grid
            VStack(spacing: 3) {
                ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                    HStack(spacing: 3) {
                        ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                            if let day {
                                dayCell(day)
                            } else {
                                Color.clear
                                    .frame(maxWidth: .infinity)
                                    .aspectRatio(0.85, contentMode: .fit)
                            }
                        }
                    }
                }
            }

            Spacer(minLength: 0)

            // footer
            HStack {
                let total = cellData.values.reduce(0) { $0 + $1.entryCount }
                Text("이 달의 기록 \(total)개")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.textMuted)
                Spacer()
                Text("Write & Record")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(AppColors.textMuted)
            }
        }
        .padding(18)
        .frame(width: Self.baseSize.width, height: Self.baseSize.height)
        .background(AppColors.bg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func dayCell(_ day: Date) -> some View {
        let dayNumber = calendar.component(.day, from: day)
        let data = cellData[dayNumber]

        ZStack(alignment: .topLeading) {
            if let image = data?.image {
                Color.clear
                    .overlay(
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    )
                    .overlay(Color.black.opacity(0.18))
                Text("\(dayNumber)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 1)
                    .padding(3)
            } else if let data {
                AppColors.category(data.dotColors.first ?? "#B3A0A2").opacity(0.18)
                VStack(spacing: 2) {
                    Text("\(dayNumber)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(AppColors.text)
                    HStack(spacing: 2) {
                        ForEach(Array(data.dotColors.enumerated()), id: \.offset) { _, hex in
                            Circle()
                                .fill(AppColors.category(hex))
                                .frame(width: 3.5, height: 3.5)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                AppColors.surface
                Text("\(dayNumber)")
                    .font(.system(size: 10))
                    .foregroundStyle(AppColors.textMuted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(0.85, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
