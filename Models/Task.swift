//
//  Task.swift
//  QueueDeadline
//
//  macOS 13+ SwiftUI Menu Bar App
//

import Foundation

struct QDTask: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var description: String
    var deadline: Date?
    var priority: Priority
    var isCompleted: Bool
    var createdAt: Date
    var notificationScheduled: Bool
    var taskType: TaskType

    enum TaskType: String, Codable, CaseIterable {
        case queue = "queue"
        case stack = "stack"

        var displayName: String {
            switch self {
            case .queue: return "큐 (마감)"
            case .stack: return "스택 (아이디어)"
            }
        }

        var iconName: String {
            switch self {
            case .queue: return "arrow.right.circle"
            case .stack: return "square.stack.3d.up"
            }
        }
    }

    enum Priority: Int, Codable, CaseIterable, Comparable {
        case low = 0
        case medium = 1
        case high = 2
        case urgent = 3

        var displayName: String {
            switch self {
            case .low: return "낮음"
            case .medium: return "보통"
            case .high: return "높음"
            case .urgent: return "긴급"
            }
        }

        var color: String {
            switch self {
            case .low: return "green"
            case .medium: return "blue"
            case .high: return "orange"
            case .urgent: return "red"
            }
        }

        static func < (lhs: Priority, rhs: Priority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        deadline: Date? = nil,
        priority: Priority = .medium,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        notificationScheduled: Bool = false,
        taskType: TaskType = .queue
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.deadline = deadline
        self.priority = priority
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.notificationScheduled = notificationScheduled
        self.taskType = taskType
    }

    // 마감까지 남은 시간 (nil if no deadline)
    var timeRemaining: TimeInterval? {
        guard let deadline = deadline else { return nil }
        return deadline.timeIntervalSince(Date())
    }

    // 마감 상태
    var deadlineStatus: DeadlineStatus {
        guard let remaining = timeRemaining else {
            return .normal
        }
        if remaining < 0 {
            return .overdue
        } else if remaining < 3600 {
            return .imminent
        } else if remaining < 86400 {
            return .soon
        } else {
            return .normal
        }
    }

    enum DeadlineStatus {
        case overdue
        case imminent
        case soon
        case normal

        var statusText: String {
            switch self {
            case .overdue: return "마감 지남"
            case .imminent: return "곧 마감"
            case .soon: return "오늘 마감"
            case .normal: return "여유 있음"
            }
        }
    }

    // 남은 시간 포맷팅
    var formattedTimeRemaining: String {
        guard let remaining = timeRemaining else {
            return "마감 없음"
        }

        if remaining < 0 {
            let overdue = abs(remaining)
            if overdue < 3600 {
                return "\(Int(overdue / 60))분 지남"
            } else if overdue < 86400 {
                return "\(Int(overdue / 3600))시간 지남"
            } else {
                return "\(Int(overdue / 86400))일 지남"
            }
        }

        if remaining < 60 {
            return "1분 미만"
        } else if remaining < 3600 {
            return "\(Int(remaining / 60))분 남음"
        } else if remaining < 86400 {
            let hours = Int(remaining / 3600)
            let minutes = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(hours)시간 \(minutes)분 남음"
        } else {
            let days = Int(remaining / 86400)
            let hours = Int((remaining.truncatingRemainder(dividingBy: 86400)) / 3600)
            return "\(days)일 \(hours)시간 남음"
        }
    }

    // 추가 날짜 포맷팅 (스택용)
    var formattedCreatedAt: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}
