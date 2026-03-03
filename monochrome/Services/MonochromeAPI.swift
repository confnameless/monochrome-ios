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

    // MARK: - Artist (two parallel calls, same as web app)
    // Call 1: /artist/?id={id}  -> { artist: { id, name, picture, popularity, ... }, cover: {...} }
    // Call 2: /artist/?f={id}   -> { albums: { items: [...] }, tracks: [...] }

    func fetchArtist(id: Int) async throws -> ArtistDetail {
        guard let metaUrl = URL(string: "\(baseURL)/artist/?id=\(id)"),
              let contentUrl = URL(string: "\(baseURL)/artist/?f=\(id)") else {
            throw URLError(.badURL)
        }

        async let metaTask = urlSession.data(for: request(for: metaUrl))
        async let contentTask = urlSession.data(for: request(for: contentUrl))

        // Parse artist metadata
        let (metaData, metaResp) = try await metaTask
        guard (metaResp as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }

        let metaJson = try JSONSerialization.jsonObject(with: metaData) as? [String: Any]
        let artistObj = metaJson?["artist"] as? [String: Any] ?? [:]

        let name = artistObj["name"] as? String ?? "Unknown"
        let picture = artistObj["picture"] as? String
        let popularity = artistObj["popularity"] as? Int

        // Parse content (tracks + albums)
        var topTracks: [Track] = []
        var albums: [Album] = []
        var eps: [Album] = []

        if let (contentData, contentResp) = try? await contentTask,
           (contentResp as? HTTPURLResponse)?.statusCode == 200 {

            let contentJson = try? JSONSerialization.jsonObject(with: contentData) as? [String: Any]

            // Tracks: top-level "tracks" array
            if let tracksArray = contentJson?["tracks"] as? [[String: Any]],
               let tracksData = try? JSONSerialization.data(withJSONObject: tracksArray),
               let decoded = try? JSONDecoder().decode([Track].self, from: tracksData) {
                topTracks = decoded
                    .sorted { ($0.popularity ?? 0) > ($1.popularity ?? 0) }
                    .prefix(15)
                    .map { $0 }
            }

            // Albums: "albums" -> "items"
            if let albumsObj = contentJson?["albums"] as? [String: Any],
               let albumItems = albumsObj["items"] as? [[String: Any]],
               let albumsData = try? JSONSerialization.data(withJSONObject: albumItems),
               let decoded = try? JSONDecoder().decode([Album].self, from: albumsData) {
                let sorted = decoded.sorted { ($0.releaseDate ?? "") > ($1.releaseDate ?? "") }
                for a in sorted {
                    let t = a.type?.uppercased() ?? ""
                    if t == "EP" || t == "SINGLE" {
                        eps.append(a)
                    } else {
                        albums.append(a)
                    }
                }
            }
        }

        return ArtistDetail(
            id: id, name: name, picture: picture, popularity: popularity,
            topTracks: topTracks, albums: albums, eps: eps
        )
    }

    // MARK: - Artist Biography (Tidal API with X-Tidal-Token)

    func fetchArtistBio(id: Int) async -> String? {
        guard let url = URL(string: "https://api.tidal.com/v1/artists/\(id)/bio?locale=en_US&countryCode=GB") else { return nil }

        var req = URLRequest(url: url)
        req.setValue("Monochrome-iOS/1.0", forHTTPHeaderField: "User-Agent")
        req.setValue("txNoH4kkV41MfH25", forHTTPHeaderField: "X-Tidal-Token")

        guard let (data, response) = try? await urlSession.data(for: req),
              (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }

        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["text"] as? String
    }

    // MARK: - Similar Artists (response: { artists: [...] })

    func fetchSimilarArtists(id: Int) async -> [Artist] {
        guard let url = URL(string: "\(baseURL)/artist/similar/?id=\(id)") else { return [] }

        guard let (data, response) = try? await urlSession.data(for: request(for: url)),
              (response as? HTTPURLResponse)?.statusCode == 200 else { return [] }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [] }

        let artistsRaw = json["artists"] as? [[String: Any]]
            ?? json["items"] as? [[String: Any]]
            ?? []

        guard !artistsRaw.isEmpty,
              let arrData = try? JSONSerialization.data(withJSONObject: artistsRaw),
              let decoded = try? JSONDecoder().decode([Artist].self, from: arrData) else { return [] }

        return decoded
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
    let eps: [Album]
}
