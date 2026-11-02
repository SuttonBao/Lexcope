import Foundation
import UserNotifications
import LexcopeCore

@MainActor
enum ReminderService {
    static let identifier = "lexcope.daily-review"

    /// Authorization is requested only when the user saves an enabled reminder.
    static func sync(_ settings: Settings, requestPermission: Bool) async throws {
        let center = UNUserNotificationCenter.current()
        guard settings.reminderEnabled else {
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
            return
        }
        var authorization = await center.notificationSettings().authorizationStatus
        if authorization == .notDetermined && requestPermission {
            _ = try await center.requestAuthorization(options: [.alert, .sound])
            authorization = await center.notificationSettings().authorizationStatus
        }
        guard authorization == .authorized || authorization == .provisional else {
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
            throw ReminderError.notAuthorized
        }
        let content = UNMutableNotificationContent()
        content.title = "给记忆留一点时间"
        content.body = "打开 Lexcope，完成今天的词汇学习与复习。"
        content.sound = .default
        var time = DateComponents()
        time.hour = settings.reminderHour; time.minute = settings.reminderMinute
        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        try await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    enum ReminderError: Error, LocalizedError {
        case notAuthorized
        var errorDescription: String? { "通知权限未开启。请在系统设置中允许 Lexcope 发送通知，或关闭复习提醒后保存。" }
    }
}
