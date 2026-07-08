import Foundation

enum DateUtils {
    static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일 (E)"
        return formatter
    }()

    static let shortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        return formatter
    }()

    static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter
    }()

    static func display(_ date: Date) -> String {
        displayFormatter.string(from: date)
    }

    static func short(_ date: Date) -> String {
        shortFormatter.string(from: date)
    }

    static func monthTitle(_ date: Date) -> String {
        monthFormatter.string(from: date)
    }

    /// 캘린더 그리드용: 해당 월을 주 단위(일요일 시작)로 자른 날짜 배열. 빈 칸은 nil.
    static func monthGrid(for month: Date, calendar: Calendar = .current) -> [[Date?]] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else { return [] }
        let firstDay = monthInterval.start
        let dayCount = calendar.range(of: .day, in: .month, for: month)?.count ?? 30
        let firstWeekday = calendar.component(.weekday, from: firstDay) // 1 = Sunday

        var cells: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        for day in 0..<dayCount {
            cells.append(calendar.date(byAdding: .day, value: day, to: firstDay))
        }
        while cells.count % 7 != 0 {
            cells.append(nil)
        }
        return stride(from: 0, to: cells.count, by: 7).map { Array(cells[$0..<$0 + 7]) }
    }

    static let weekdaySymbols = ["일", "월", "화", "수", "목", "금", "토"]
}
