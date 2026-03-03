import Foundation
import Observation

@Observable
class MonochromeAPI {
    var baseURL = "https://api.monochrome.tf"
    private var urlSession = URLSession.shared

    private func request(for url: URL) -> URLRequest {
        var req = URLRequest(url: url)
        req.setValue("Monochrome-iOS/1.0", forHTTPHeaderField: "User-Agent")
        return req
    }

    // MARK: - Search

    func searchTracks(query: String) async throws -> [Track] {
        guard let q = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/search/?s=\(q)") else { throw URLError(.badURL) }

        let (data, response) = try await urlSession.data(for: request(for: url))
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        return try JSONDecoder().decode(SearchResponse.self, from: data).data?.items ?? []
    }

    // MARK: - Editor Picks

    func fetchEditorsPicks() async throws -> [EditorPick] {
        guard let url = URL(string: "https://monochrome.tf/editors-picks.json") else { throw URLError(.badURL) }

        let (data, response) = try await urlSession.data(for: request(for: url))
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        return try JSONDecoder().decode([EditorPick].self, from: data)
    }

    // MARK: - Artist

    func fetchArtist(id: Int) async throws -> ArtistDetail {
        guard let url = URL(string: "\(baseURL)/artist/?id=\(id)") else { throw URLError(.badURL) }

        let (data, response) = try await urlSession.data(for: request(for: url))
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }

        // The API returns a nested structure - try to parse flexibly
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let artistData = json?["data"] as? [String: Any]

        let name = artistData?["name"] as? String ?? "Unknown"
        let picture = artistData?["picture"] as? String
        let popularity = artistData?["popularity"] as? Int

        // Parse top tracks
        var topTracks: [Track] = []
        if let tracksArray = artistData?["top_tracks"] as? [[String: Any]] {
            if let tracksData = try? JSONSerialization.data(withJSONObject: tracksArray),
               let decoded = try? JSONDecoder().decode([Track].self, from: tracksData) {
                topTracks = decoded
            }
        }
        // Fallback: tracks might be under "tracks"
        if topTracks.isEmpty, let tracksArray = artistData?["tracks"] as? [[String: Any]] {
            if let tracksData = try? JSONSerialization.data(withJSONObject: tracksArray),
               let decoded = try? JSONDecoder().decode([Track].self, from: tracksData) {
                topTracks = decoded
            }
        }

        // Parse albums
        var albums: [Album] = []
        if let albumsArray = artistData?["albums"] as? [[String: Any]] {
            if let albumsData = try? JSONSerialization.data(withJSONObject: albumsArray),
               let decoded = try? JSONDecoder().decode([Album].self, from: albumsData) {
                albums = decoded
            }
        }

        return ArtistDetail(
            id: id, name: name, picture: picture, popularity: popularity,
            topTracks: topTracks, albums: albums
        )
    }

    // MARK: - Stream URL

    struct TrackResponse: Codable {
        let version: String?
        let data: TrackData?
    }

    struct TrackData: Codable {
        let trackId: Int
        let manifest: String?
    }

    struct ManifestData: Codable {
        let urls: [String]
    }

    func fetchStreamUrl(trackId: Int) async throws -> String? {
        guard let url = URL(string: "\(baseURL)/track/?id=\(trackId)&quality=HIGH") else { throw URLError(.badURL) }

        let (data, response) = try await urlSession.data(for: request(for: url))
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }

        let apiResponse = try JSONDecoder().decode(TrackResponse.self, from: data)
        guard let manifestBase64 = apiResponse.data?.manifest,
              let manifestData = Data(base64Encoded: manifestBase64),
              let manifest = try? JSONDecoder().decode(ManifestData.self, from: manifestData) else {
            return nil
        }
        return manifest.urls.first
    }

    // MARK: - Images

    func getImageUrl(id: String?, size: Int = 320) -> URL? {
        guard let id = id, !id.isEmpty else { return nil }
        if id.hasPrefix("http") { return URL(string: id) }
        let formattedId = id.replacingOccurrences(of: "-", with: "/")
        return URL(string: "https://resources.tidal.com/images/\(formattedId)/\(size)x\(size).jpg")
    }
}

// MARK: - Artist Detail Model

struct ArtistDetail {
    let id: Int
    let name: String
    let picture: String?
    let popularity: Int?
    let topTracks: [Track]
    let albums: [Album]
}
