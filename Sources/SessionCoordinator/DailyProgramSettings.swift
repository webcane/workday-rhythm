import Foundation
import Program

/// Редактируемые значения программы на границе между формой и координатором.
public struct DailyProgramSettings: Equatable, Sendable {
    public let startMinutes: Int
    public let dayHours: Int
    public let focusMinutes: Int
    public let restMinutes: Int
    public let longBreakMinutes: Int
    public let longBreakAfter: Int?

    public init(
        startMinutes: Int,
        dayHours: Int,
        focusMinutes: Int,
        restMinutes: Int,
        longBreakMinutes: Int,
        longBreakAfter: Int?
    ) {
        self.startMinutes = startMinutes
        self.dayHours = dayHours
        self.focusMinutes = focusMinutes
        self.restMinutes = restMinutes
        self.longBreakMinutes = longBreakMinutes
        self.longBreakAfter = longBreakAfter
    }

    init(program: DailyProgram) {
        startMinutes = program.startMinutes
        dayHours = program.dayHours
        focusMinutes = program.duration(for: .focus)
        restMinutes = program.duration(for: .rest)
        longBreakMinutes = program.restDurationOverrides.first?.durationMinutes ?? 60
        longBreakAfter = program.restDurationOverrides.first?.afterFocusNumber
    }

    func makeProgram() throws -> DailyProgram {
        try DailyProgram(
            startMinutes: startMinutes,
            dayHours: dayHours,
            defaults: [
                .init(kind: .focus, durationMinutes: focusMinutes),
                .init(kind: .rest, durationMinutes: restMinutes),
            ],
            restDurationOverrides: longBreakAfter.map {
                [.init(afterFocusNumber: $0, durationMinutes: longBreakMinutes)]
            } ?? []
        )
    }
}
