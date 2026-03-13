import Foundation

enum LibraryFilter: String, CaseIterable, Codable, Hashable {
    case all = "All"
    case myPlaylists = "My Playlists"
    case tracks = "Tracks"
    case albums = "Albums"
    case artists = "Artists"
    case playlists = "Playlists"
    case mixes = "Mixes"
}
