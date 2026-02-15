//
//  AddTaskView.swift
//  QueueDeadline
//

import SwiftUI

struct AddTaskView: View {
    @EnvironmentObject var taskStore: TaskStore
    @Binding var isPresented: Bool

    @State private var title = ""
    @State private var description = ""
    @State private var deadline = Date().addingTimeInterval(3600)
    @State private var priority: QDTask.Priority = .medium
    @State private var taskType: QDTask.TaskType = .queue
    @State private var hasDeadline = true

    // 빠른 마감 옵션
    private let quickDeadlines: [(String, TimeInterval)] = [
        ("1시간", 3600),
        ("3시간", 10800),
        ("오늘", 86400),
        ("내일", 172800),
        ("이번 주", 604800)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                Button("취소") { isPresented = false }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)

                Spacer()

                Text("새 작업")
                    .font(.headline)

                Spacer()

                Button("추가") { addTask() }
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
                    // 큐/스택 선택
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
                                hasDeadline = false
                            }
                        }
                    }

                    // 제목
                    VStack(alignment: .leading, spacing: 4) {
                        Text("제목")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextField("작업 제목을 입력하세요", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }

                    // 설명
                    VStack(alignment: .leading, spacing: 4) {
                        Text("설명 (선택)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextField("상세 설명", text: $description, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...5)
                    }

                    // 마감일 섹션 (큐이면 필수, 스택이면 선택)
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
                        // 빠른 마감 설정
                        VStack(alignment: .leading, spacing: 8) {
                            Text("빠른 마감")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack(spacing: 6) {
                                ForEach(quickDeadlines, id: \.0) { name, interval in
                                    QuickDeadlineButton(title: name) {
                                        deadline = Date().addingTimeInterval(interval)
                                    }
                                }
                            }
                        }

                        // 마감일
                        VStack(alignment: .leading, spacing: 4) {
                            Text("마감일시")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            DatePicker(
                                "",
                                selection: $deadline,
                                in: Date()...,
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
        .frame(width: 320, height: 420)
    }

    private func addTask() {
        let task = QDTask(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            deadline: hasDeadline ? deadline : nil,
            priority: priority,
            taskType: taskType
        )
        taskStore.addTask(task)
        isPresented = false
    }
}

struct TaskTypeButton: View {
    let type: QDTask.TaskType
    let isSelected: Bool
    let action: () -> Void

    private var color: Color {
        switch type {
        case .queue: return .blue
        case .stack: return .purple
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: type.iconName)
                    .font(.caption)
                Text(type.displayName)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? color : Color(nsColor: .controlBackgroundColor))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color, lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct QuickDeadlineButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

struct PriorityButton: View {
    let priority: QDTask.Priority
    let isSelected: Bool
    let action: () -> Void

    private var color: Color {
        switch priority {
        case .low: return .green
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }

    var body: some View {
        Button(action: action) {
            Text(priority.displayName)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : Color(nsColor: .controlBackgroundColor))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color, lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AddTaskView(isPresented: .constant(true))
        .environmentObject(TaskStore())
}
