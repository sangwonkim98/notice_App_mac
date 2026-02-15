//
//  TaskRowView.swift
//  QueueDeadline
//

import SwiftUI

struct TaskRowView: View {
    @EnvironmentObject var taskStore: TaskStore
    let task: QDTask
    var onEdit: ((QDTask) -> Void)? = nil

    @State private var isHovering = false
    @State private var showingDeadlinePicker = false
    @State private var selectedDeadline = Date().addingTimeInterval(3600)

    private var priorityColor: Color {
        switch task.priority {
        case .low: return .green
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }

    private var statusColor: Color {
        if task.isCompleted {
            return .gray
        }
        switch task.deadlineStatus {
        case .overdue: return .red
        case .imminent: return .orange
        case .soon: return .yellow
        case .normal: return .green
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                // 완료 체크박스
                Button(action: { taskStore.toggleComplete(task) }) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(task.isCompleted ? .green : .secondary)
                }
                .buttonStyle(.plain)

                // 우선순위 표시
                Circle()
                    .fill(priorityColor)
                    .frame(width: 8, height: 8)

                // 작업 정보
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.system(.body, design: .default))
                        .fontWeight(.medium)
                        .strikethrough(task.isCompleted)
                        .foregroundColor(task.isCompleted ? .secondary : .primary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        if task.taskType == .queue || task.deadline != nil {
                            // 마감 시간
                            HStack(spacing: 2) {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                Text(task.formattedTimeRemaining)
                                    .font(.caption)
                            }
                            .foregroundColor(statusColor)
                        } else {
                            // 스택: 추가 날짜 표시
                            HStack(spacing: 2) {
                                Image(systemName: "calendar")
                                    .font(.caption2)
                                Text(task.formattedCreatedAt)
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }

                        // 유형 뱃지
                        Text(task.taskType == .queue ? "큐" : "스택")
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(task.taskType == .queue ? Color.blue.opacity(0.2) : Color.purple.opacity(0.2))
                            .foregroundColor(task.taskType == .queue ? .blue : .purple)
                            .cornerRadius(3)

                        // 우선순위 텍스트
                        if task.priority == .urgent || task.priority == .high {
                            Text(task.priority.displayName)
                                .font(.caption2)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(priorityColor.opacity(0.2))
                                .foregroundColor(priorityColor)
                                .cornerRadius(3)
                        }
                    }
                }

                Spacer()

                // 호버 시 액션 버튼
                if isHovering && !task.isCompleted {
                    HStack(spacing: 4) {
                        // 큐↔스택 전환 버튼
                        if task.taskType == .queue {
                            Button(action: { taskStore.moveToStack(task) }) {
                                Image(systemName: "square.stack.3d.up")
                                    .font(.caption)
                                    .foregroundColor(.purple)
                            }
                            .buttonStyle(.plain)
                            .help("스택으로 이동")
                        } else {
                            Button(action: { requestMoveToQueue() }) {
                                Image(systemName: "arrow.right.circle")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                            .help("큐로 이동")
                        }

                        Button(action: { onEdit?(task) }) {
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)

                        Button(action: { taskStore.deleteTask(task) }) {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(isHovering ? Color(nsColor: .controlBackgroundColor) : Color.clear)
            .onHover { hovering in
                isHovering = hovering
            }
            .contextMenu {
                Button(task.isCompleted ? "미완료로 표시" : "완료로 표시") {
                    taskStore.toggleComplete(task)
                }

                if !task.isCompleted {
                    Divider()
                    if task.taskType == .queue {
                        Button("스택으로 이동") {
                            taskStore.moveToStack(task)
                        }
                    } else {
                        Button("큐로 이동") {
                            requestMoveToQueue()
                        }
                    }
                }

                Button("수정") {
                    onEdit?(task)
                }
                Divider()
                Button("삭제", role: .destructive) {
                    taskStore.deleteTask(task)
                }
            }

            // 큐로 이동 시 마감일 입력 인라인
            if showingDeadlinePicker {
                VStack(spacing: 8) {
                    HStack {
                        Text("마감일 설정")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }

                    DatePicker(
                        "",
                        selection: $selectedDeadline,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()

                    HStack(spacing: 12) {
                        Button("취소") {
                            showingDeadlinePicker = false
                        }
                        .buttonStyle(.plain)
                        .font(.caption)
                        .foregroundColor(.secondary)

                        Button("큐로 이동") {
                            taskStore.moveToQueue(task, deadline: selectedDeadline)
                            showingDeadlinePicker = false
                        }
                        .buttonStyle(.plain)
                        .font(.caption)
                        .foregroundColor(.accentColor)
                        .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                .background(Color(nsColor: .controlBackgroundColor))
            }
        }
    }

    private func requestMoveToQueue() {
        if let deadline = task.deadline {
            taskStore.moveToQueue(task, deadline: deadline)
        } else {
            selectedDeadline = Date().addingTimeInterval(3600)
            showingDeadlinePicker = true
        }
    }
}

struct EditTaskView: View {
    @EnvironmentObject var taskStore: TaskStore

    let task: QDTask
    var onDismiss: () -> Void

    @State private var title: String
    @State private var description: String
    @State private var deadline: Date
    @State private var priority: QDTask.Priority
    @State private var taskType: QDTask.TaskType
    @State private var hasDeadline: Bool

    init(task: QDTask, onDismiss: @escaping () -> Void) {
        self.task = task
        self.onDismiss = onDismiss
        _title = State(initialValue: task.title)
        _description = State(initialValue: task.description)
        _deadline = State(initialValue: task.deadline ?? Date().addingTimeInterval(3600))
        _priority = State(initialValue: task.priority)
        _taskType = State(initialValue: task.taskType)
        _hasDeadline = State(initialValue: task.deadline != nil)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                Button("취소") { onDismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)

                Spacer()

                Text("작업 수정")
                    .font(.headline)

                Spacer()

                Button("저장") { saveTask() }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
            }
            .padding()

            Divider()

            // 폼
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 유형 선택
                    VStack(alignment: .leading, spacing: 8) {
                        Text("유형")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            TaskTypeButton(
                                type: .queue,
                                isSelected: taskType == .queue
                            ) {
                                taskType = .queue
                                hasDeadline = true
                            }

                            TaskTypeButton(
                                type: .stack,
                                isSelected: taskType == .stack
                            ) {
                                taskType = .stack
                            }
                        }
                    }

                    // 제목
                    VStack(alignment: .leading, spacing: 4) {
                        Text("제목")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextField("작업 제목", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }

                    // 설명
                    VStack(alignment: .leading, spacing: 4) {
                        Text("설명")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextField("상세 설명", text: $description, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...5)
                    }

                    // 마감일 토글 (스택일 때만)
                    if taskType == .stack {
                        HStack {
                            Text("마감일 설정")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Toggle("", isOn: $hasDeadline)
                                .toggleStyle(.switch)
                                .controlSize(.small)
                        }
                    }

                    if hasDeadline {
                        // 마감일
                        VStack(alignment: .leading, spacing: 4) {
                            Text("마감일시")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            DatePicker(
                                "",
                                selection: $deadline,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .labelsHidden()
                        }
                    }

                    // 우선순위
                    VStack(alignment: .leading, spacing: 8) {
                        Text("우선순위")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            ForEach(QDTask.Priority.allCases, id: \.self) { p in
                                PriorityButton(
                                    priority: p,
                                    isSelected: priority == p
                                ) {
                                    priority = p
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 320, height: 400)
    }

    private func saveTask() {
        var updatedTask = task
        updatedTask.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedTask.description = description.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedTask.deadline = hasDeadline ? deadline : nil
        updatedTask.priority = priority
        updatedTask.taskType = taskType

        taskStore.updateTask(updatedTask)
        onDismiss()
    }
}

#Preview {
    TaskRowView(
        task: QDTask(
            title: "테스트 작업",
            description: "설명입니다",
            deadline: Date().addingTimeInterval(3600),
            priority: .high,
            taskType: .queue
        ),
        onEdit: { _ in }
    )
    .environmentObject(TaskStore())
}
