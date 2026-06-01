import Foundation
import UserNotifications

/// Handles permission requests and the long-running-timer reminder.
enum NotificationManager {
    static let longTimerIdentifier = "long-running-timer-reminder"

    /// Request authorization (called after the first timer start).
    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    /// Schedule a reminder that fires after a number of hours if a timer is still running.
    static func scheduleLongTimerReminder(afterHours hours: Double = 8) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized ||
                  settings.authorizationStatus == .provisional else { return }

            let content = UNMutableNotificationContent()
            content.title = String(localized: "notif.longTimer.title")
            content.body = String(localized: "notif.longTimer.body")
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: max(60, hours * 3600),
                repeats: false)
            let request = UNNotificationRequest(identifier: longTimerIdentifier,
                                                content: content,
                                                trigger: trigger)
            center.add(request)
        }
    }

    static func cancelLongTimerReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [longTimerIdentifier])
    }
}
