import AppKit

/// Маршрут команд меню с подставляемыми системными действиями.
@MainActor
final class MenuCommands: NSObject {
    private let settingsHandler: () -> Void
    private let quitHandler: () -> Void
    private let startDayHandler: () -> Void
    private let pauseHandler: () -> Void
    private let resumeHandler: () -> Void
    private let continueAfterRestHandler: () -> Void

    init(
        showSettings: @escaping () -> Void,
        quit: @escaping () -> Void,
        startDay: @escaping () -> Void = {},
        pause: @escaping () -> Void = {},
        resume: @escaping () -> Void = {},
        continueAfterRest: @escaping () -> Void = {}
    ) {
        settingsHandler = showSettings
        quitHandler = quit
        startDayHandler = startDay
        pauseHandler = pause
        resumeHandler = resume
        continueAfterRestHandler = continueAfterRest
        super.init()
    }

    @objc func showSettings() {
        settingsHandler()
    }

    @objc func quit() {
        quitHandler()
    }

    @objc func startDay() {
        startDayHandler()
    }

    @objc func pause() {
        pauseHandler()
    }

    @objc func resume() {
        resumeHandler()
    }

    @objc func continueAfterRest() {
        continueAfterRestHandler()
    }
}
