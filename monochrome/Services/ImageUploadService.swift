import Foundation
import UIKit

class ImageUploadService {
    static let shared = ImageUploadService()

    private let uploadURL = "https://monochrome.tf/upload"
    private let maxFileSize = 10 * 1024 * 1024 // 10 MB

    func upload(imageData: Data, fileName: String = "image.jpg") async throws -> String {
        guard imageData.count <= maxFileSize else {
            throw UploadError.fileTooLarge
        }

        guard let url = URL(string: uploadURL) else {
            throw UploadError.invalidURL
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw UploadError.serverError
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool, success,
              let uploadedUrl = json["url"] as? String else {
            throw UploadError.invalidResponse
        }

        return uploadedUrl
    }

    func compressImage(_ image: UIImage, maxSize: Int = 5 * 1024 * 1024) -> Data? {
        var compression: CGFloat = 0.8
        var data = image.jpegData(compressionQuality: compression)
        while let d = data, d.count > maxSize, compression > 0.1 {
            compression -= 0.1
            data = image.jpegData(compressionQuality: compression)
        }
        return data
    }

    enum UploadError: LocalizedError {
        case fileTooLarge, invalidURL, serverError, invalidResponse

        var errorDescription: String? {
            switch self {
            case .fileTooLarge: return "Image exceeds 10 MB limit"
            case .invalidURL: return "Invalid upload URL"
            case .serverError: return "Upload failed — use URL instead"
            case .invalidResponse: return "Upload failed — use URL instead"
            }
        }
    }
}
