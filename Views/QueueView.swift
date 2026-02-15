//
//  QueueView.swift
//  QueueDeadline
//

import SwiftUI

struct QueueView: View {
    @EnvironmentObject var taskStore: TaskStore
    @Binding var editingTask: QDTask?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // 지연된 작업
                if !taskStore.queueOverdueTasks.isEmpty {
                    Section {
                        ForEach(taskStore.queueOverdueTasks) { task in
                            TaskRowView(task: task, onEdit: { editingTask = $0 })
                            Divider()
                                .padding(.leading)
                        }
                    } header: {
                        SectionHeader(title: "지연됨", color: .red, count: taskStore.queueOverdueTasks.count)
                    }
                }

                // 마감 예정 작업
                if !taskStore.queueUpcomingTasks.isEmpty {
                    Section {
                        ForEach(taskStore.queueUpcomingTasks) { task in
                            TaskRowView(task: task, onEdit: { editingTask = $0 })
                            Divider()
                                .padding(.leading)
                        }
                    } header: {
                        SectionHeader(title: "마감 예정", color: .orange, count: taskStore.queueUpcomingTasks.count)
                    }
                }

                // 빈 상태
                if taskStore.queueTasks.isEmpty {
                    emptyStateView
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.right.circle")
                .font(.system(size: 40))
                .foregroundColor(.blue)

            Text("큐가 비었습니다")
                .font(.headline)

            Text("마감이 있는 급한 작업을 추가하세요")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
    }
}

#Preview {
    QueueView(editingTask: .constant(nil))
        .environmentObject(TaskStore())
}
