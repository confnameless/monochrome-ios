import SwiftUI

struct Theme {
    static let background = Color(hex: "#0a0a0a")
    static let foreground = Color(hex: "#f5f5f5")
    
    static let card = Color(hex: "#141414")
    static let cardForeground = Color(hex: "#f5f5f5")
    
    static let primary = Color(hex: "#f5f5f5")
    static let primaryForeground = Color(hex: "#0a0a0a")
    
    static let secondary = Color(hex: "#1f1f1f")
    static let secondaryForeground = Color(hex: "#e0e0e0")
    
    static let muted = Color(hex: "#1f1f1f")
    static let mutedForeground = Color(hex: "#a0a0a0")
    
    static let border = Color(hex: "#2a2a2a")
    static let input = Color(hex: "#1f1f1f")
    static let highlight = Color(hex: "#f5f5f5")
    
    static let radiusSm: CGFloat = 4.0
    static let radiusMd: CGFloat = 8.0
    static let radiusLg: CGFloat = 12.0
    static let radiusXl: CGFloat = 16.0
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
