import Foundation
import Observation

@Observable
class MonochromeAPI {
    // We default to the public instance from the Web app
    var baseURL = "https://api.monochrome.tf"
    private var urlSession = URLSession.shared
    
    func searchTracks(query: String) async throws -> [Track] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/search/?s=\(encodedQuery)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Monochrome-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let apiResponse = try JSONDecoder().decode(SearchResponse.self, from: data)
        return apiResponse.data?.items ?? []
    }
    
    func fetchStreamUrl(trackId: Int) async throws -> String? {
        // The API returns the stream URL or manifest. For now we use QUALITY=HIGH.
        guard let url = URL(string: "\(baseURL)/stream/?id=\(trackId)&quality=HIGH") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Monochrome-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        let (data, _) = try await urlSession.data(for: request)
        
        // Attempt to decode as JSON which usually contains { "url": "..." } or similar
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let stringUrl = json["url"] as? String {
                return stringUrl
            }
            if let streamUrl = json["streamUrl"] as? String {
                return streamUrl
            }
        }
        
        // If the API returns a raw string (or plain text)
        if let plainString = String(data: data, encoding: .utf8), plainString.hasPrefix("http") {
            return plainString
        }
        
        return nil
    }
    
    func getImageUrl(id: String?) -> URL? {
        guard let id = id, !id.isEmpty else { return nil }
        if id.hasPrefix("http") {
            return URL(string: id)
        }
        return URL(string: "\(baseURL)/image/?id=\(id)")
    }
}
