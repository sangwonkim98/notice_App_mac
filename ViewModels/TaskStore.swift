//
//  TaskStore.swift
//  QueueDeadline
//

import Foundation
import Combine

@MainActor
class TaskStore: ObservableObject {
    @Published var tasks: [QDTask] = []
    @Published var searchText: String = ""
    @Published var selectedFilter: TaskFilter = .all

    private let dataManager = DataManager.shared
    private let notificationManager = NotificationManager.shared
    private var cancellables = Set<AnyCancellable>()

    enum TaskFilter: String, CaseIterable {
        case all = "전체"
        case active = "진행중"
        case completed = "완료"
        case overdue = "지연"
    }

    init() {
        loadTasks()
        setupAutoSave()
    }

    // MARK: - Queue/Stack Computed Properties

    var queueTasks: [QDTask] {
        tasks
            .filter { $0.taskType == .queue && !$0.isCompleted }
            .sorted { t1, t2 in
                // 마감 빠른 순 (FIFO)
                guard let d1 = t1.deadline else { return false }
                guard let d2 = t2.deadline else { return true }
                return d1 < d2
            }
    }

    var stackTasks: [QDTask] {
        tasks
            .filter { $0.taskType == .stack && !$0.isCompleted }
            .sorted { $0.createdAt > $1.createdAt } // LIFO - 최신순
    }

    var completedTasks: [QDTask] {
        tasks
            .filter { $0.isCompleted }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var dueSoonTasks: [QDTask] {
        tasks
            .filter { $0.taskType == .queue && !$0.isCompleted && ($0.timeRemaining ?? Double.infinity) > 0 && ($0.timeRemaining ?? Double.infinity) < 86400 }
            .sorted { ($0.deadline ?? .distantFuture) < ($1.deadline ?? .distantFuture) }
    }

    var overdueTasks: [QDTask] {
        tasks
            .filter { $0.taskType == .queue && !$0.isCompleted && ($0.timeRemaining ?? Double.infinity) < 0 }
            .sorted { ($0.deadline ?? .distantFuture) < ($1.deadline ?? .distantFuture) }
    }

    // Queue tasks split by section
    var queueOverdueTasks: [QDTask] {
        queueTasks.filter { ($0.timeRemaining ?? Double.infinity) < 0 }
    }

    var queueUpcomingTasks: [QDTask] {
        queueTasks.filter { ($0.timeRemaining ?? Double.infinity) >= 0 }
    }

    var filteredTasks: [QDTask] {
        var result = tasks

        switch selectedFilter {
        case .all:
            break
        case .active:
            result = result.filter { !$0.isCompleted }
        case .completed:
            result = result.filter { $0.isCompleted }
        case .overdue:
            result = result.filter { !$0.isCompleted && ($0.timeRemaining ?? Double.infinity) < 0 }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    var taskCountByStatus: (active: Int, completed: Int, overdue: Int) {
        let active = tasks.filter { !$0.isCompleted && ($0.timeRemaining ?? Double.infinity) >= 0 }.count
        let completed = tasks.filter { $0.isCompleted }.count
        let overdue = tasks.filter { !$0.isCompleted && ($0.timeRemaining ?? Double.infinity) < 0 }.count
        return (active, completed, overdue)
    }

    // MARK: - Move Operations

    func moveToQueue(_ task: QDTask, deadline: Date) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].taskType = .queue
            tasks[index].deadline = deadline
            scheduleNotification(for: tasks[index])
            saveTasks()
        }
    }

    func moveToStack(_ task: QDTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].taskType = .stack
            // 마감일은 유지 (optional이므로 그대로)
            notificationManager.cancelNotification(for: task.id)
            saveTasks()
        }
    }

    // MARK: - CRUD Operations

    func addTask(_ task: QDTask) {
        tasks.append(task)
        if task.deadline != nil {
            scheduleNotification(for: task)
        }
        saveTasks()
    }

    func updateTask(_ task: QDTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            let oldTask = tasks[index]
            tasks[index] = task

            if oldTask.deadline != task.deadline {
                notificationManager.cancelNotification(for: oldTask.id)
                if task.deadline != nil {
                    scheduleNotification(for: task)
                }
            }

            saveTasks()
        }
    }

    func deleteTask(_ task: QDTask) {
        notificationManager.cancelNotification(for: task.id)
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }

    func deleteTasks(at offsets: IndexSet) {
        let tasksToDelete = offsets.map { filteredTasks[$0] }
        for task in tasksToDelete {
            notificationManager.cancelNotification(for: task.id)
        }
        tasks.removeAll { task in
            tasksToDelete.contains { $0.id == task.id }
        }
        saveTasks()
    }

    func toggleComplete(_ task: QDTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()

            if tasks[index].isCompleted {
                notificationManager.cancelNotification(for: task.id)
            } else if tasks[index].deadline != nil {
                scheduleNotification(for: tasks[index])
            }

            saveTasks()
        }
    }

    // MARK: - Persistence

    private func loadTasks() {
        tasks = dataManager.loadTasks()
    }

    private func saveTasks() {
        dataManager.saveTasks(tasks)
    }

    private func setupAutoSave() {
        $tasks
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveTasks()
            }
            .store(in: &cancellables)
    }

    // MARK: - Notifications

    private func scheduleNotification(for task: QDTask) {
        guard !task.isCompleted, task.deadline != nil else { return }

        Task {
            await notificationManager.scheduleNotification(for: task)
        }
    }

    func refreshNotifications() {
        Task {
            for task in tasks where !task.isCompleted && task.deadline != nil {
                await notificationManager.scheduleNotification(for: task)
            }
        }
    }
}
