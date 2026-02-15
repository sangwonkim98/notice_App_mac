//
//  DataManager.swift
//  QueueDeadline
//

import Foundation

class DataManager {
    static let shared = DataManager()

    private let fileManager = FileManager.default
    private let fileName = "tasks.json"

    private var documentsURL: URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("QueueDeadline", isDirectory: true)
    }

    private var tasksFileURL: URL {
        documentsURL.appendingPathComponent(fileName)
    }

    private init() {
        createDirectoryIfNeeded()
    }

    private func createDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: documentsURL.path) {
            do {
                try fileManager.createDirectory(
                    at: documentsURL,
                    withIntermediateDirectories: true
                )
            } catch {
                print("디렉토리 생성 실패: \(error)")
            }
        }
    }

    func saveTasks(_ tasks: [QDTask]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted

            let data = try encoder.encode(tasks)
            try data.write(to: tasksFileURL)
        } catch {
            print("작업 저장 실패: \(error)")
        }
    }

    func loadTasks() -> [QDTask] {
        guard fileManager.fileExists(atPath: tasksFileURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: tasksFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            return try decoder.decode([QDTask].self, from: data)
        } catch {
            print("작업 로드 실패: \(error)")
            return []
        }
    }

    func exportTasks(_ tasks: [QDTask], to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted

        let data = try encoder.encode(tasks)
        try data.write(to: url)
    }

    func importTasks(from url: URL) throws -> [QDTask] {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode([QDTask].self, from: data)
    }

    func clearAllData() {
        do {
            if fileManager.fileExists(atPath: tasksFileURL.path) {
                try fileManager.removeItem(at: tasksFileURL)
            }
        } catch {
            print("데이터 삭제 실패: \(error)")
        }
    }
}
