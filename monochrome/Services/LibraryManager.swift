import Foundation
import Observation

@Observable
class LibraryManager {
    static let shared = LibraryManager()
    
    var favoriteTracks: [Track] = []
    var favoriteAlbums: [Album] = []
    
    private let tracksKey = "monochrome_favorite_tracks"
    private let albumsKey = "monochrome_favorite_albums"
    
    init() {
        loadFavorites()
    }
    
    func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: tracksKey),
           let tracks = try? JSONDecoder().decode([Track].self, from: data) {
            self.favoriteTracks = tracks
        }
        
        if let data = UserDefaults.standard.data(forKey: albumsKey),
           let albums = try? JSONDecoder().decode([Album].self, from: data) {
            self.favoriteAlbums = albums
        }
    }
    
    func saveTracks() {
        if let data = try? JSONEncoder().encode(favoriteTracks) {
            UserDefaults.standard.set(data, forKey: tracksKey)
        }
    }
    
    func saveAlbums() {
        if let data = try? JSONEncoder().encode(favoriteAlbums) {
            UserDefaults.standard.set(data, forKey: albumsKey)
        }
    }
    
    func toggleFavorite(track: Track) {
        if let index = favoriteTracks.firstIndex(where: { $0.id == track.id }) {
            favoriteTracks.remove(at: index)
        } else {
            favoriteTracks.insert(track, at: 0)
        }
        saveTracks()
    }
    
    func isFavorite(trackId: Int) -> Bool {
        return favoriteTracks.contains(where: { $0.id == trackId })
    }
    
    func toggleFavorite(album: Album) {
        if let index = favoriteAlbums.firstIndex(where: { $0.id == album.id }) {
            favoriteAlbums.remove(at: index)
        } else {
            favoriteAlbums.insert(album, at: 0)
        }
        saveAlbums()
    }
    
    func isFavorite(albumId: Int) -> Bool {
        return favoriteAlbums.contains(where: { $0.id == albumId })
    }
}
