import SwiftUI

enum Tab: Hashable {
    case home
}

@Observable
final class RouteManager {
    var selectedTab: Tab = .home
    var homePath = NavigationPath()

    func resetToRoot(tab: Tab) {
        switch tab {
        case .home:
            homePath = NavigationPath()
        }
    }
}
