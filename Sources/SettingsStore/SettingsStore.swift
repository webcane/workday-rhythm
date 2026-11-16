import Foundation
import Program

/// Единственная граница будущего доступа к UserDefaults; пока ничего не сохраняет.
@MainActor
public final class SettingsStore {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
}
