import Foundation
import Program

/// Единственная граница доступа к сохранённым настройкам приложения.
@MainActor
public final class SettingsStore {
    public enum StorageError: Error {
        case encodingFailed
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private enum Key {
        static let program = "dailyProgram"
        static let lastStartPromptDate = "lastStartPromptDate"
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func loadProgram() -> DailyProgram {
        guard let data = defaults.data(forKey: Key.program),
            let program = try? decoder.decode(DailyProgram.self, from: data)
        else {
            return .initial
        }
        return program
    }

    public func saveProgram(_ program: DailyProgram) throws {
        guard let data = try? encoder.encode(program) else {
            throw StorageError.encodingFailed
        }
        defaults.set(data, forKey: Key.program)
    }

    public func lastStartPromptDate() -> Date? {
        defaults.object(forKey: Key.lastStartPromptDate) as? Date
    }

    public func saveLastStartPromptDate(_ date: Date) {
        defaults.set(date, forKey: Key.lastStartPromptDate)
    }
}
