//
//  CompletedView.swift
//  QueueDeadline
//

import SwiftUI

struct CompletedView: View {
    @EnvironmentObject var taskStore: TaskStore
    @Binding var editingTask: QDTask?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if taskStore.completedTasks.isEmpty {
                    emptyStateView
                } else {
                    ForEach(taskStore.completedTasks) { task in
                        TaskRowView(task: task, onEdit: { editingTask = $0 })
                        Divider()
                            .padding(.leading)
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40))
                .foregroundColor(.green)

            Text("완료된 작업 없음")
                .font(.headline)

            Text("작업을 완료하면 여기에 표시됩니다")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
    }
}

#Preview {
    CompletedView(editingTask: .constant(nil))
        .environmentObject(TaskStore())
}
