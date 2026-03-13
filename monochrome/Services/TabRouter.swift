import Observation

@Observable
class TabRouter {
    var selectedTab: Int = 0
    var pendingLibraryFilter: LibraryFilter? = nil
}
