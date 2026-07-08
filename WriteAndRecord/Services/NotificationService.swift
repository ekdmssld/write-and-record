import Foundation
import UserNotifications

/// 매일 기록 리마인더 (docs/05 13장, docs/13 백로그 P1).
/// - 알림은 사용자가 켠 경우에만 권한을 요청한다.
/// - 알림을 끄면 예약된 알림을 모두 제거한다.
enum NotificationService {
    private static let dailyReminderId = "dailyRecordReminder"

    /// 기본 리마인더 시각: 21:00.
    static var defaultReminderTime: Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 21
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    static func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
    }

    /// 프로필 설정에 맞춰 알림 스케줄을 동기화한다. 앱 시작/설정 변경 시 호출.
    static func sync(with profile: UserProfile?) {
        guard let profile, profile.notificationEnabled else {
            cancelDailyReminder()
            return
        }
        scheduleDailyReminder(at: profile.reminderTime ?? defaultReminderTime)
    }

    static func scheduleDailyReminder(at time: Date) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [dailyReminderId])

        let content = UNMutableNotificationContent()
        content.title = "오늘의 기록을 남겨볼까요?"
        content.body = "짧은 문장 하나만 남겨도 괜찮아요."
        content.sound = .default

        var components = Calendar.current.dateComponents([.hour, .minute], from: time)
        components.second = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(identifier: dailyReminderId, content: content, trigger: trigger)
        center.add(request)
    }

    static func cancelDailyReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [dailyReminderId])
    }
}
