//
//  NotificationManager.swift
//  QueueDeadline
//

import Foundation
import UserNotifications

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized: Bool = false

    private init() {
        checkAuthorization()
    }

    func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            print("알림 권한 요청 실패: \(error)")
            return false
        }
    }

    func scheduleNotification(for task: QDTask) async {
        guard let deadline = task.deadline else { return }

        guard isAuthorized else {
            let granted = await requestAuthorization()
            guard granted else { return }
        }

        // 기존 알림 취소
        cancelNotification(for: task.id)

        let timeRemaining = deadline.timeIntervalSince(Date())

        // 마감 전 알림 시점들 (30분, 1시간, 24시간 전)
        let notificationTimes: [(TimeInterval, String)] = [
            (1800, "30분"),      // 30분 전
            (3600, "1시간"),     // 1시간 전
            (86400, "24시간")    // 24시간 전
        ]

        for (offset, timeString) in notificationTimes {
            let triggerTime = timeRemaining - offset

            if triggerTime > 0 {
                let content = UNMutableNotificationContent()
                content.title = "마감 임박: \(task.title)"
                content.body = "\(timeString) 후 마감됩니다."
                content.sound = .default
                content.categoryIdentifier = "TASK_REMINDER"
                content.userInfo = ["taskId": task.id.uuidString]

                // 우선순위에 따른 인터럽트 레벨
                if #available(macOS 12.0, *) {
                    switch task.priority {
                    case .urgent:
                        content.interruptionLevel = .critical
                    case .high:
                        content.interruptionLevel = .timeSensitive
                    default:
                        content.interruptionLevel = .active
                    }
                }

                let trigger = UNTimeIntervalNotificationTrigger(
                    timeInterval: triggerTime,
                    repeats: false
                )

                let identifier = "\(task.id.uuidString)-\(Int(offset))"
                let request = UNNotificationRequest(
                    identifier: identifier,
                    content: content,
                    trigger: trigger
                )

                do {
                    try await UNUserNotificationCenter.current().add(request)
                } catch {
                    print("알림 스케줄 실패: \(error)")
                }
            }
        }
    }

    func cancelNotification(for taskId: UUID) {
        let identifiers = [
            "\(taskId.uuidString)-1800",
            "\(taskId.uuidString)-3600",
            "\(taskId.uuidString)-86400"
        ]
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
