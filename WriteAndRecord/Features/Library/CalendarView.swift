import SwiftUI

/// 라이브러리 기본 홈: 월 캘린더 + 선택 날짜의 기록 목록.
/// 캘린더 블록(헤더+요일+그리드)이 화면의 75%를 차지하고,
/// 사진이 있는 날짜는 셀 전체가 사진 타일로 표시된다.
struct CalendarView: View {
    @EnvironmentObject private var entryRepository: EntryRepository
    @EnvironmentObject private var categoryRepository: CategoryRepository
    @EnvironmentObject private var router: NavigationRouter

    @State private var displayedMonth = Date()
    @State private var selectedDate = Date()

    private var calendar: Calendar { .current }

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: AppLayout.mediumGap) {
                    calendarBlock(totalHeight: geo.size.height)
                    Divider().overlay(AppColors.line)
                    selectedDateSection
                }
                .padding(.horizontal, AppLayout.horizontalPadding)
                .padding(.top, AppLayout.smallGap)
                .padding(.bottom, AppLayout.largeGap)
            }
        }
    }

    // MARK: - Calendar block (화면 75%)

    private func calendarBlock(totalHeight: CGFloat) -> some View {
        let weeks = DateUtils.monthGrid(for: displayedMonth)
        let blockHeight = totalHeight * 0.75
        let headerHeight: CGFloat = 44
        let weekdayHeight: CGFloat = 22
        let sectionSpacing = AppLayout.mediumGap * 2
        let rowSpacing: CGFloat = 4
        let rowCount = max(weeks.count, 1)
        let gridHeight = max(blockHeight - headerHeight - weekdayHeight - sectionSpacing, 260)
        let cellHeight = (gridHeight - rowSpacing * CGFloat(rowCount - 1)) / CGFloat(rowCount)
        let entriesByDay = entryRepository.entryCountsByDay(in: displayedMonth)

        return VStack(spacing: AppLayout.mediumGap) {
            monthHeader
                .frame(height: headerHeight)
            weekdayRow
                .frame(height: weekdayHeight)
            VStack(spacing: rowSpacing) {
                ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                    HStack(spacing: 3) {
                        ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                            if let day {
                                dayCell(
                                    day,
                                    entries: entriesByDay[calendar.component(.day, from: day)] ?? [],
                                    height: cellHeight
                                )
                            } else {
                                Color.clear
                                    .frame(maxWidth: .infinity)
                                    .frame(height: cellHeight)
                            }
                        }
                    }
                }
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            IconButton(systemName: "chevron.left", accessibilityLabel: "이전 달") {
                withAnimation { moveMonth(-1) }
            }
            Spacer()
            Text(DateUtils.monthTitle(displayedMonth))
                .font(AppTypography.headline)
                .foregroundStyle(AppColors.text)
            Spacer()
            IconButton(systemName: "chevron.right", accessibilityLabel: "다음 달") {
                withAnimation { moveMonth(1) }
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

    // MARK: - Day cell

    private func dayCell(_ day: Date, entries: [Entry], height: CGFloat) -> some View {
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(day)
        // 카테고리 색 점 최대 3개 (Functional Spec 6장)
        let dotColors: [String] = Array(
            entries.map { categoryRepository.colorHex(forEntry: $0) }
                .reduce(into: [String]()) { acc, hex in
                    if !acc.contains(hex) { acc.append(hex) }
                }
                .prefix(3)
        )
        // 그날 기록 중 첫 번째 사진을 셀 전체에 보여준다.
        let coverAsset = entries.compactMap { entryRepository.coverAsset(for: $0) }.first

        return Button {
            selectedDate = day
            // 기록이 없는 날짜는 탭이 곧 "기록 추가"로 이어진다 (기록 있는 날짜는 목록 표시).
            if entries.isEmpty {
                router.push(.categoryPicker(date: day))
            }
        } label: {
            Group {
                if let coverAsset {
                    photoCell(day, coverAsset: coverAsset, dotColors: dotColors, isSelected: isSelected, isToday: isToday)
                } else {
                    numberCell(day, dotColors: dotColors, isSelected: isSelected, isToday: isToday)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
        }
        .accessibilityLabel(dayCellLabel(day, entryCount: entries.count, isToday: isToday, isSelected: isSelected))
    }

    /// 사진이 있는 날: 셀 전체가 사진 타일.
    private func photoCell(_ day: Date, coverAsset: MediaAsset, dotColors: [String], isSelected: Bool, isToday: Bool) -> some View {
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
                .stroke(
                    isSelected ? AppColors.primary : (isToday ? AppColors.primary.opacity(0.6) : .clear),
                    lineWidth: isSelected ? 2.5 : 1.5
                )
        )
    }

    /// 사진이 없는 날: 숫자 + 카테고리 점.
    private func numberCell(_ day: Date, dotColors: [String], isSelected: Bool, isToday: Bool) -> some View {
        VStack(spacing: 4) {
            Text("\(calendar.component(.day, from: day))")
                .font(AppTypography.callout)
                .foregroundStyle(isSelected ? AppColors.primaryText : AppColors.text)
                .frame(width: 34, height: 34)
                .background(
                    ZStack {
                        if isSelected {
                            Circle().fill(AppColors.primary)
                        } else if isToday {
                            Circle().stroke(AppColors.primary, lineWidth: 1.5)
                        }
                    }
                )
            HStack(spacing: 3) {
                ForEach(Array(dotColors.enumerated()), id: \.offset) { _, hex in
                    Circle()
                        .fill(AppColors.category(hex))
                        .frame(width: 5, height: 5)
                }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func dayCellLabel(_ day: Date, entryCount: Int, isToday: Bool, isSelected: Bool) -> String {
        var parts = [DateUtils.display(day)]
        if isToday { parts.append("오늘") }
        if entryCount > 0 { parts.append("기록 \(entryCount)개") }
        if isSelected { parts.append("선택됨") }
        return parts.joined(separator: ", ")
    }

    // MARK: - Selected date section

    private var selectedDateSection: some View {
        let entries = entryRepository.entries(on: selectedDate)
        return VStack(alignment: .leading, spacing: AppLayout.mediumGap) {
            HStack {
                Text(DateUtils.display(selectedDate))
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.text)
                Spacer()
                Button {
                    router.push(.categoryPicker(date: selectedDate))
                } label: {
                    Label("기록 추가", systemImage: "plus")
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.primary)
                }
                .accessibilityLabel("\(DateUtils.display(selectedDate))에 기록 추가")
            }

            if entries.isEmpty {
                EmptyStateView(
                    iconName: "square.and.pencil",
                    title: "이 날의 기록이 비어 있어요",
                    subtitle: "짧은 문장 하나만 남겨도 괜찮아요.",
                    actionTitle: "이 날 기록하기"
                ) {
                    router.push(.categoryPicker(date: selectedDate))
                }
            } else {
                ForEach(entries) { entry in
                    Button {
                        router.push(.entryDetail(entryId: entry.id))
                    } label: {
                        EntryCardView(entry: entry)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func moveMonth(_ offset: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: offset, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }
}
