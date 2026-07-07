import SwiftUI

/// 라이브러리 기본 홈: 월 캘린더 + 선택 날짜의 기록 목록.
struct CalendarView: View {
    @EnvironmentObject private var entryRepository: EntryRepository
    @EnvironmentObject private var categoryRepository: CategoryRepository
    @EnvironmentObject private var router: NavigationRouter

    @State private var displayedMonth = Date()
    @State private var selectedDate = Date()

    private var calendar: Calendar { .current }

    var body: some View {
        ScrollView {
            VStack(spacing: AppLayout.mediumGap) {
                monthHeader
                weekdayRow
                monthGrid
                Divider().overlay(AppColors.line)
                selectedDateSection
            }
            .padding(.horizontal, AppLayout.horizontalPadding)
            .padding(.top, AppLayout.smallGap)
            .padding(.bottom, AppLayout.largeGap)
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
        HStack(spacing: 0) {
            ForEach(DateUtils.weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var monthGrid: some View {
        let weeks = DateUtils.monthGrid(for: displayedMonth)
        let entriesByDay = entryRepository.entryCountsByDay(in: displayedMonth)

        return VStack(spacing: 4) {
            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                HStack(spacing: 0) {
                    ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                        if let day {
                            dayCell(day, entries: entriesByDay[calendar.component(.day, from: day)] ?? [])
                        } else {
                            Color.clear.frame(maxWidth: .infinity, minHeight: 52)
                        }
                    }
                }
            }
        }
    }

    private func dayCell(_ day: Date, entries: [Entry]) -> some View {
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

        return Button {
            selectedDate = day
        } label: {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: day))")
                    .font(AppTypography.callout)
                    .foregroundStyle(isSelected ? AppColors.primaryText : AppColors.text)
                    .frame(width: 32, height: 32)
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
            .frame(maxWidth: .infinity, minHeight: 52)
        }
        .accessibilityLabel(dayCellLabel(day, entryCount: entries.count, isToday: isToday, isSelected: isSelected))
    }

    private func dayCellLabel(_ day: Date, entryCount: Int, isToday: Bool, isSelected: Bool) -> String {
        var parts = [DateUtils.display(day)]
        if isToday { parts.append("오늘") }
        if entryCount > 0 { parts.append("기록 \(entryCount)개") }
        if isSelected { parts.append("선택됨") }
        return parts.joined(separator: ", ")
    }

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
                    title: "아직 기록이 없어요",
                    subtitle: "이 날의 첫 기록을 남겨볼까요?",
                    actionTitle: "첫 기록 남기기"
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
