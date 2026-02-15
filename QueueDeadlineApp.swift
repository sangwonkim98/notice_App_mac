//
//  QueueDeadlineApp.swift
//  QueueDeadline
//
//  macOS 13+ Menu Bar App for Deadline Management
//

import SwiftUI

@main
struct QueueDeadlineApp: App {
    @StateObject private var taskStore = TaskStore()
    @State private var isPopoverShown = false

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(taskStore)
        } label: {
            MenuBarLabel(taskStore: taskStore)
        }
        .menuBarExtraStyle(.window)
    }
}

struct MenuBarLabel: View {
    @ObservedObject var taskStore: TaskStore

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: iconName)

            if badgeCount > 0 {
                Text("\(badgeCount)")
                    .font(.caption2)
            }
        }
    }

    private var iconName: String {
        if taskStore.overdueTasks.count > 0 {
            return "exclamationmark.circle.fill"
        } else if taskStore.dueSoonTasks.count > 0 {
            return "clock.badge.exclamationmark.fill"
        } else {
            return "checklist"
        }
    }

    // 큐 기준 뱃지 (스택은 급하지 않으니 제외)
    private var badgeCount: Int {
        taskStore.overdueTasks.count + taskStore.dueSoonTasks.count
    }
}
