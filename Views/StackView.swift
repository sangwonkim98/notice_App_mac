//
//  StackView.swift
//  QueueDeadline
//

import SwiftUI

struct StackView: View {
    @EnvironmentObject var taskStore: TaskStore
    @Binding var editingTask: QDTask?
    @State private var showingDeadlinePicker = false
    @State private var taskToMoveToQueue: QDTask? = nil
    @State private var selectedDeadline = Date().addingTimeInterval(3600)

    var body: some View {
        ZStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    if taskStore.stackTasks.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(taskStore.stackTasks) { task in
                            TaskRowView(task: task, onEdit: { editingTask = $0 })
                            Divider()
                                .padding(.leading)
                        }
                    }
                }
            }

            // 큐로 이동 시 마감일 입력 오버레이
            if showingDeadlinePicker {
                deadlinePickerOverlay
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 40))
                .foregroundColor(.purple)

            Text("스택이 비었습니다")
                .font(.headline)

            Text("아이디어나 나중에 할 작업을 추가하세요")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
    }

    private var deadlinePickerOverlay: some View {
        VStack(spacing: 16) {
            Text("큐로 이동")
                .font(.headline)

            Text("마감일을 설정하세요")
                .font(.caption)
                .foregroundColor(.secondary)

            DatePicker(
                "마감일시",
                selection: $selectedDeadline,
                in: Date()...,
                displayedComponents: [.date, .hourAndMinute]
            )
            .labelsHidden()

            HStack(spacing: 12) {
                Button("취소") {
                    showingDeadlinePicker = false
                    taskToMoveToQueue = nil
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)

                Button("이동") {
                    if let task = taskToMoveToQueue {
                        taskStore.moveToQueue(task, deadline: selectedDeadline)
                    }
                    showingDeadlinePicker = false
                    taskToMoveToQueue = nil
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
                .fontWeight(.semibold)
            }
        }
        .padding(20)
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 8)
        .padding(20)
    }

    func requestMoveToQueue(_ task: QDTask) {
        if task.deadline != nil {
            // 이미 마감일이 있으면 바로 이동
            taskStore.moveToQueue(task, deadline: task.deadline!)
        } else {
            // 마감일 없으면 입력 요구
            taskToMoveToQueue = task
            selectedDeadline = Date().addingTimeInterval(3600)
            showingDeadlinePicker = true
        }
    }
}

#Preview {
    StackView(editingTask: .constant(nil))
        .environmentObject(TaskStore())
}
