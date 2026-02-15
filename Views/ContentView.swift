//
//  ContentView.swift
//  QueueDeadline
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var taskStore: TaskStore
    @State private var selectedTab = 0
    @State private var showingAddTask = false
    @State private var editingTask: QDTask? = nil

    var body: some View {
        VStack(spacing: 0) {
            if showingAddTask {
                AddTaskView(isPresented: $showingAddTask)
            } else if let task = editingTask {
                EditTaskView(task: task, onDismiss: { editingTask = nil })
            } else {
                // 헤더
                headerView

                Divider()

                // 탭 뷰
                TabView(selection: $selectedTab) {
                    QueueView(editingTask: $editingTask)
                        .tag(0)
                        .tabItem {
                            Label("큐", systemImage: "arrow.right.circle")
                        }

                    StackView(editingTask: $editingTask)
                        .tag(1)
                        .tabItem {
                            Label("스택", systemImage: "square.stack.3d.up")
                        }

                    CompletedView(editingTask: $editingTask)
                        .tag(2)
                        .tabItem {
                            Label("완료", systemImage: "checkmark.circle")
                        }
                }
                .frame(minHeight: 300)

                Divider()

                // 푸터
                footerView
            }
        }
        .frame(width: 350, height: 450)
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("QueueDeadline")
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: { showingAddTask = true }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .help("새 작업 추가")
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private var footerView: some View {
        HStack {
            // 통계
            HStack(spacing: 12) {
                StatBadge(
                    count: taskStore.queueTasks.count,
                    label: "큐",
                    color: .blue
                )
                StatBadge(
                    count: taskStore.stackTasks.count,
                    label: "스택",
                    color: .purple
                )
                StatBadge(
                    count: taskStore.overdueTasks.count,
                    label: "지연",
                    color: .red
                )
            }

            Spacer()

            // 설정 메뉴
            Menu {
                Button("알림 설정 확인") {
                    NSWorkspace.shared.open(
                        URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!
                    )
                }
                Divider()
                Button("종료") {
                    NSApplication.shared.terminate(nil)
                }
            } label: {
                Image(systemName: "gearshape")
                    .foregroundColor(.secondary)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 24)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var statusText: String {
        let overdue = taskStore.overdueTasks.count
        let queueCount = taskStore.queueTasks.count
        let stackCount = taskStore.stackTasks.count

        if overdue > 0 {
            return "\(overdue)개 지연됨!"
        } else if queueCount > 0 {
            return "큐 \(queueCount)개 · 스택 \(stackCount)개"
        } else {
            return "모든 작업 여유있음"
        }
    }
}

struct StatBadge: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text("\(count)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(TaskStore())
}
