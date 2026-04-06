import SwiftUI

// MARK: - Pastel palette (UI chrome & surfaces)

/// Bảng màu pastel dùng cho toàn app — có thể mở rộng (nền màn, nút, highlight).
enum PastelPalette {
    // Nền / bề mặt
    static let cream = Color(red: 0.99, green: 0.97, blue: 0.94)
    static let lily = Color(red: 0.94, green: 0.96, blue: 0.99)
    static let mintSurface = Color(red: 0.90, green: 0.97, blue: 0.93)
    static let peach = Color(red: 1.0, green: 0.93, blue: 0.90)
    static let lavender = Color(red: 0.91, green: 0.89, blue: 0.98)
    static let butter = Color(red: 0.99, green: 0.96, blue: 0.86)

    // Accent (chip, viền phụ)
    static let accentRose = Color(red: 0.94, green: 0.78, blue: 0.86)
    static let accentSky = Color(red: 0.78, green: 0.88, blue: 0.98)
    static let accentSage = Color(red: 0.76, green: 0.90, blue: 0.82)
    static let accentApricot = Color(red: 1.0, green: 0.88, blue: 0.76)

    /// Viền & bóng thẻ (mềm, không gắt)
    static let cardStroke = Color(red: 0.88, green: 0.90, blue: 0.94)
    static let cardShadow = Color(red: 0.2, green: 0.22, blue: 0.28).opacity(0.14)

    /// Bóng sát đế + bóng lan — lá bài / deck như vật nằm trên mặt bàn (ánh sáng góc trên-trái).
    static let tableShadowContact = Color(red: 0.07, green: 0.06, blue: 0.05).opacity(0.58)
    static let tableShadowAmbient = Color(red: 0.11, green: 0.10, blue: 0.12).opacity(0.34)

    /// Bóng khay token (khối lớn, gần mặt phẳng).
    static let boardShadowContact = Color(red: 0.07, green: 0.06, blue: 0.05).opacity(0.44)
    static let boardShadowAmbient = Color(red: 0.10, green: 0.09, blue: 0.11).opacity(0.40)

    static let royalStroke = Color(red: 0.96, green: 0.86, blue: 0.58)

    /// Nút Buy / Res (pastel)
    static let buyEnabled = Color(red: 0.58, green: 0.84, blue: 0.72)
    static let buyDisabled = Color(red: 0.82, green: 0.84, blue: 0.87)
    static let reserveEnabled = Color(red: 1.0, green: 0.82, blue: 0.62)
    static let reserveDisabled = Color(red: 0.82, green: 0.84, blue: 0.87)

    static let buttonLabelOnPastel = Color(red: 0.25, green: 0.28, blue: 0.32)

    // Text / icon
    static let textPrimary = Color(red: 0.22, green: 0.24, blue: 0.28)
    static let textSecondary = Color(red: 0.50, green: 0.53, blue: 0.58)
    static let textOnDark = Color(red: 0.98, green: 0.98, blue: 0.99)

    // Neutral surfaces / overlays
    static let neutralSoft = Color(red: 0.92, green: 0.92, blue: 0.94)
    static let neutralMid = Color(red: 0.78, green: 0.80, blue: 0.84)
    static let divider = Color(red: 0.78, green: 0.80, blue: 0.84).opacity(0.55)
    static let overlayDark = Color(red: 0.08, green: 0.10, blue: 0.14).opacity(0.56)
    static let chipDark = Color(red: 0.09, green: 0.11, blue: 0.14).opacity(0.42)

    // Status
    static let success = Color(red: 0.39, green: 0.73, blue: 0.54)
    static let warning = Color(red: 0.95, green: 0.64, blue: 0.39)
    static let danger = Color(red: 0.87, green: 0.40, blue: 0.46)
    static let info = Color(red: 0.47, green: 0.66, blue: 0.90)

    // Gem colors (pastel-tuned)
    static let gemWhite = Color(red: 0.95, green: 0.96, blue: 0.98)
    static let gemBlue = Color(red: 0.45, green: 0.66, blue: 0.93)
    static let gemGreen = Color(red: 0.49, green: 0.79, blue: 0.60)
    static let gemRed = Color(red: 0.91, green: 0.49, blue: 0.53)
    static let gemBlack = Color(red: 0.28, green: 0.30, blue: 0.35)
    static let gemPearl = Color(red: 0.71, green: 0.60, blue: 0.92)
    static let gemGold = Color(red: 0.93, green: 0.78, blue: 0.40)
}

// MARK: - Kích thước thẻ (development + royal cùng footprint)

enum CardChrome {
    static let width: CGFloat = 110
    static let artHeight: CGFloat = 155
    static let actionColumnWidth: CGFloat = 32
    static var totalWidth: CGFloat { width + actionColumnWidth }
    static var totalHeight: CGFloat { artHeight }

    static let cornerRadius: CGFloat = 12
    static let shadowRadius: CGFloat = 8
    static let shadowY: CGFloat = 4
}

// MARK: - Bóng vật thể trên bàn

extension View {
    /// Hai lớp bóng: viền tối sát đế + vùng sáng mờ phía dưới-phải.
    func tableLiftCardShadow() -> some View {
        shadow(color: PastelPalette.tableShadowContact, radius: 2.5, x: 2, y: 3)
            .shadow(color: PastelPalette.tableShadowAmbient, radius: 18, x: 0, y: 11)
    }

    func tableLiftBoardShadow() -> some View {
        shadow(color: PastelPalette.boardShadowContact, radius: 4, x: 1, y: 5)
            .shadow(color: PastelPalette.boardShadowAmbient, radius: 24, x: 0, y: 14)
    }
}
