import Foundation

final class UserDefaultsRecentSearchPreference: RecentSearchPreferenceStore {
    private let defaults: UserDefaults
    private let key = "recentSearchQuery"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var recentSearchQuery: String? {
        get { defaults.string(forKey: key) }
        set { defaults.set(newValue, forKey: key) }
    }
}
