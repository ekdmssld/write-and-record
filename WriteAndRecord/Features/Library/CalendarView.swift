import SwiftUI

/// 라이브러리 기본 홈: 화면 전체를 채우는 월 캘린더.
/// - 오늘 칸에는 + 버튼이 표시된다 (기록이 없을 때).
/// - 기록 없는 날짜 탭 -> 카테고리 선택으로 바로 이동.
/// - 기록 있는 날짜 탭 -> 하단에서 30% 시트가 올라와 그날의 기록을 보여준다.
struct CalendarView: View {
    @EnvironmentObject private var entryRepository: EntryRepository
    @EnvironmentObject private var categoryRepository: CategoryRepository
    @EnvironmentObject private var router: NavigationRouter

    @State private var displayedMonth = Date()
    @State private var daySheet: DaySheetItem?
    @State private var showMonthlyExport = false

    private var calendar: Calendar { .current }

    struct DaySheetItem: Identifiable {
        let date: Date
        var id: Date { date }
    }

    var body: some View {
        VStack(spacing: AppLayout.smallGap) {
            monthHeader
                .frame(height: 44)
            weekdayRow
                .frame(height: 22)
            monthGrid
        }
        .padding(.horizontal, AppLayout.horizontalPadding)
        .padding(.top, AppLayout.smallGap)
        .padding(.bottom, AppLayout.smallGap)
        .sheet(item: $daySheet) { item in
            DayEntriesSheet(
                date: item.date,
                onAdd: {
                    daySheet = nil
                    DispatchQueue.main.async {
                        router.push(.categoryPicker(date: item.date))
                    }
                },
                onOpenEntry: { entryId in
                    daySheet = nil
                    DispatchQueue.main.async {
                        router.push(.entryDetail(entryId: entryId))
                    }
                }
            )
            .presentationDetents([.fraction(0.32), .medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showMonthlyExport) {
            MonthlyCalendarExportView(month: displayedMonth)
        }
    }

    private var monthHeader: some View {
        ZStack {
            Text(DateUtils.monthTitle(displayedMonth))
                .font(AppTypography.headline)
                .foregroundStyle(AppColors.text)
            HStack(spacing: 0) {
                IconButton(systemName: "chevron.left", accessibilityLabel: "이전 달") {
                    withAnimation { moveMonth(-1) }
                }
                Spacer()
                IconButton(systemName: "square.and.arrow.up", accessibilityLabel: "이 달을 이미지로 내보내기") {
                    showMonthlyExport = true
                }
                IconButton(systemName: "chevron.right", accessibilityLabel: "다음 달") {
                    withAnimation { moveMonth(1) }
                }
            }
        }
    }

    private var weekdayRow: some View {
        HStack(spacing: 3) {
            ForEach(DateUtils.weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    /// 남은 화면 전체를 채우는 날짜 그리드. 주 행이 균등하게 늘어난다.
    private var monthGrid: some View {
        let weeks = DateUtils.monthGrid(for: displayedMonth)
        let entriesByDay = entryRepository.entryCountsByDay(in: displayedMonth)

        return VStack(spacing: 4) {
            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                HStack(spacing: 3) {
                    ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                        if let day {
                            dayCell(day, entries: entriesByDay[calendar.component(.day, from: day)] ?? [])
                        } else {
                            Color.clear
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Day cell

    private func dayCell(_ day: Date, entries: [Entry]) -> some View {
        let isToday = calendar.isDateInToday(day)
        let dotColors: [String] = Array(
            entries.map { categoryRepository.colorHex(forEntry: $0) }
                .reduce(into: [String]()) { acc, hex in
                    if !acc.contains(hex) { acc.append(hex) }
                }
                .prefix(3)
        )
        let coverAsset = entries.compactMap { entryRepository.coverAsset(for: $0) }.first

        return Button {
            if entries.isEmpty {
                // 기록 없는 날: 탭이 곧 기록 추가
                router.push(.categoryPicker(date: day))
            } else {
                // 기록 있는 날: 하단 시트로 그날 기록 보기
                daySheet = DaySheetItem(date: day)
            }
        } label: {
            Group {
                if let coverAsset {
                    photoCell(day, coverAsset: coverAsset, dotColors: dotColors, isToday: isToday)
                } else {
                    numberCell(day, dotColors: dotColors, isToday: isToday, showPlus: isToday)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityLabel(dayCellLabel(day, entryCount: entries.count, isToday: isToday))
    }

    /// 사진이 있는 날: 셀 전체가 사진 타일.
    private func photoCell(_ day: Date, coverAsset: MediaAsset, dotColors: [String], isToday: Bool) -> some View {
        ZStack(alignment: .topLeading) {
            AssetThumbnailView(asset: coverAsset)
            LinearGradient(
                colors: [.black.opacity(0.35), .clear],
                startPoint: .top,
                endPoint: .center
            )
            Text("\(calendar.component(.day, from: day))")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.5), radius: 1)
                .padding(5)
        }
        .overlay(alignment: .bottomTrailing) {
            HStack(spacing: 2) {
                ForEach(Array(dotColors.enumerated()), id: \.offset) { _, hex in
                    Circle()
                        .fill(AppColors.category(hex))
                        .frame(width: 5, height: 5)
                }
            }
            .padding(4)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isToday ? AppColors.primary : .clear, lineWidth: 1.5)
        )
    }

    /// 사진이 없는 날: 숫자 + 카테고리 점. 오늘은 + 버튼 표시.
    private func numberCell(_ day: Date, dotColors: [String], isToday: Bool, showPlus: Bool) -> some View {
        VStack(spacing: 4) {
            Text("\(calendar.component(.day, from: day))")
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.text)
            if showPlus {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(AppColors.primary))
            } else {
                HStack(spacing: 3) {
                    ForEach(Array(dotColors.enumerated()), id: \.offset) { _, hex in
                        Circle()
                            .fill(AppColors.category(hex))
                            .frame(width: 5, height: 5)
                    }
                }
                .frame(height: 6)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isToday ? AppColors.primary : .clear, lineWidth: 1.5)
        )
    }

    private func dayCellLabel(_ day: Date, entryCount: Int, isToday: Bool) -> String {
        var parts = [DateUtils.display(day)]
        if isToday { parts.append("오늘") }
        if entryCount > 0 {
            parts.append("기록 \(entryCount)개, 탭하면 기록 보기")
        } else {
            parts.append("탭하면 기록 추가")
        }
        return parts.joined(separator: ", ")
    }

    private func moveMonth(_ offset: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: offset, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }
}

/// 날짜 탭 시 하단에서 올라오는 그날의 기록 시트.
/// 상단: 날짜(중앙) + 우측 + 버튼. 행: 왼쪽 사진, 오른쪽 제목/카테고리·별점/세부내용.
struct DayEntriesSheet: View {
    let date: Date
    let onAdd: () -> Void
    let onOpenEntry: (String) -> Void

    @EnvironmentObject private var entryRepository: EntryRepository
    @EnvironmentObject private var categoryRepository: CategoryRepository

    var body: some View {
        VStack(spacing: 0) {
            // header: 날짜 중앙 정렬 + 우측 추가 버튼
            ZStack {
                Text(DateUtils.display(date))
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.text)
                HStack {
                    Spacer()
                    IconButton(systemName: "plus", accessibilityLabel: "이 날 기록 추가") {
                        onAdd()
                    }
                }
            }
            .padding(.horizontal, AppLayout.mediumGap)
            .padding(.top, AppLayout.smallGap)

            ScrollView {
                VStack(spacing: AppLayout.smallGap) {
                    ForEach(entryRepository.entries(on: date)) { entry in
                        Button {
                            onOpenEntry(entry.id)
                        } label: {
                            entryRow(entry)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppLayout.horizontalPadding)
                .padding(.vertical, AppLayout.smallGap)
            }
        }
        .background(AppColors.bg)
    }

    private func entryRow(_ entry: Entry) -> some View {
        let colorHex = categoryRepository.colorHex(forEntry: entry)
        return HStack(spacing: AppLayout.mediumGap) {
            // 왼편 사진
            Group {
                if let cover = entryRepository.coverAsset(for: entry) {
                    AssetThumbnailView(asset: cover, placeholderColorHex: colorHex)
                } else {
                    ZStack {
                        AppColors.category(colorHex).opacity(0.15)
                        Image(systemName: categoryRepository.category(id: entry.categoryId)?.icon ?? "tag")
                            .foregroundStyle(AppColors.category(colorHex))
                    }
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))

            // 오른편 3행: 제목 / 카테고리+별점 / 세부내용
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.title)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.text)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Circle()
                        .fill(AppColors.category(colorHex))
                        .frame(width: 7, height: 7)
                    Text(categoryRepository.displayName(forEntry: entry))
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textMuted)
                    if let rating = entry.rating {
                        RatingDisplay(rating: rating)
                    }
                    if entry.isWishlist {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(AppColors.primary)
                    }
                }
                Text(entry.body.isEmpty ? "내용 없음" : entry.body)
                    .font(AppTypography.caption)
                    .foregroundStyle(entry.body.isEmpty ? AppColors.textMuted.opacity(0.6) : AppColors.textMuted)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(AppLayout.smallGap)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .stroke(AppColors.line, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}
