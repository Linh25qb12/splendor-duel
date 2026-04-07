import SwiftUI

// MARK: - Poker chip disk (Canvas — single draw call, no GeometryReader)

/// Chip tròn vẽ bằng Canvas: vành 8 vạch vuông, mặt giữa lõm.
private struct PokerChipDisk: View {
    let baseColor: Color
    let rimDashColor: Color

    var body: some View {
        Canvas { ctx, size in
            let side = min(size.width, size.height)
            let outerR = side / 2
            let innerR = outerR * 0.74
            let dashRingR = (outerR + innerR) / 2
            let dashW = max(6, outerR * 0.22)
            let dashH = (outerR - innerR) * 0.55
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let outerRect = CGRect(
                x: c.x - outerR, y: c.y - outerR,
                width: side, height: side
            )
            let innerDiam = innerR * 2
            let innerRect = CGRect(
                x: c.x - innerR, y: c.y - innerR,
                width: innerDiam, height: innerDiam
            )

            // Outer disc
            ctx.fill(Circle().path(in: outerRect), with: .color(baseColor))
            ctx.stroke(
                Circle().path(in: outerRect),
                with: .color(.black.opacity(0.12)), lineWidth: 0.75
            )

            // Inner disc (base)
            ctx.fill(Circle().path(in: innerRect), with: .color(baseColor))

            // Shadow top-left (recessed look)
            ctx.drawLayer { inner in
                inner.clip(to: Circle().path(in: innerRect))
                let shadowGrad = Gradient(colors: [
                    .black.opacity(0.18), .black.opacity(0.06), .clear
                ])
                inner.fill(
                    Circle().path(in: innerRect),
                    with: .linearGradient(
                        shadowGrad,
                        startPoint: innerRect.origin,
                        endPoint: c
                    )
                )
            }

            // Highlight bottom-right (recessed look)
            ctx.drawLayer { inner in
                inner.clip(to: Circle().path(in: innerRect))
                let hlGrad = Gradient(colors: [.clear, .white.opacity(0.22)])
                inner.fill(
                    Circle().path(in: innerRect),
                    with: .linearGradient(
                        hlGrad,
                        startPoint: c,
                        endPoint: CGPoint(
                            x: innerRect.maxX,
                            y: innerRect.maxY
                        )
                    )
                )
            }

            // Bevel stroke around inner circle
            ctx.stroke(
                Circle().path(in: innerRect.insetBy(dx: 0.6, dy: 0.6)),
                with: .linearGradient(
                    Gradient(colors: [
                        .black.opacity(0.15), .clear, .white.opacity(0.28)
                    ]),
                    startPoint: innerRect.origin,
                    endPoint: CGPoint(x: innerRect.maxX, y: innerRect.maxY)
                ),
                lineWidth: 1.2
            )

            // 8 rim dashes
            for i in 0..<8 {
                let angle = Double(i) * .pi / 4 - .pi / 2
                let dx = CGFloat(cos(angle)) * dashRingR
                let dy = CGFloat(sin(angle)) * dashRingR
                let dashCenter = CGPoint(x: c.x + dx, y: c.y + dy)
                var dashCtx = ctx
                dashCtx.translateBy(x: dashCenter.x, y: dashCenter.y)
                dashCtx.rotate(by: .radians(angle + .pi / 2))
                let rect = CGRect(
                    x: -dashW / 2, y: -dashH / 2,
                    width: dashW, height: dashH
                )
                dashCtx.fill(Rectangle().path(in: rect), with: .color(rimDashColor))
            }
        }
    }
}

// MARK: - Token View

struct TokenView: View {
    let type: TokenType?
    var isSelected: Bool = false

    // Drives the bounce when selection state changes
    @State private var bounceScale: CGFloat = 1.0
    // Drives the ring pulse on selection
    @State private var ringScale: CGFloat = 1.0
    @State private var ringOpacity: Double = 0.0

    var body: some View {
        ZStack {
            if type == nil {
                Circle()
                    .fill(PastelPalette.lily.opacity(0.55))
                Circle()
                    .stroke(PastelPalette.cardStroke.opacity(0.9), lineWidth: 1.5)
            } else if let t = type {
                PokerChipDisk(baseColor: colorFor(t), rimDashColor: rimDashColor(for: t))
                    .shadow(
                        color: .black.opacity(isSelected ? 0.34 : 0.22),
                        radius: isSelected ? 7 : 5,
                        x: -2,
                        y: isSelected ? 5 : 4
                    )

                // Permanent selection ring
                if isSelected {
                    Circle()
                        .stroke(PastelPalette.accentSky, lineWidth: 3)
                        .padding(-3)
                }

                // Pulse ring that bursts outward on selection
                Circle()
                    .stroke(PastelPalette.accentSky.opacity(ringOpacity), lineWidth: 3)
                    .scaleEffect(ringScale)
                    .padding(-3)
            }
        }
        .frame(width: 54, height: 54)
        // Token lifts up when selected, drops back when deselected
        .scaleEffect(bounceScale)
        .offset(y: isSelected ? -4 : 0)
        .onChange(of: isSelected) { _, selected in
            if selected {
                // Bounce up
                withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) {
                    bounceScale = 1.18
                }
                withAnimation(.spring(response: 0.25, dampingFraction: 0.4).delay(0.05)) {
                    bounceScale = 1.0
                }
                // Ring pulse outward and fade
                ringScale = 1.0
                ringOpacity = 0.6
                withAnimation(.easeOut(duration: 0.45)) {
                    ringScale = 1.7
                    ringOpacity = 0.0
                }
            } else {
                // Snap back down
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    bounceScale = 1.0
                }
            }
        }
    }

    private func colorFor(_ type: TokenType?) -> Color {
        switch type {
        case .white: return PastelPalette.gemWhite
        case .blue: return PastelPalette.gemBlue
        case .green: return PastelPalette.gemGreen
        case .red: return PastelPalette.gemRed
        case .black: return PastelPalette.gemBlack
        case .pearl: return PastelPalette.gemPearl
        case .gold: return PastelPalette.gemGold
        case .none: return .clear
        }
    }

    /// Vạch vành: kem trên gem tối; xám nhẹ trên gem sáng để vẫn thấy được.
    private func rimDashColor(for type: TokenType) -> Color {
        switch type {
        case .white, .pearl, .gold:
            return Color(red: 0.42, green: 0.44, blue: 0.48)
        case .black:
            return Color(red: 0.93, green: 0.92, blue: 0.91)
        default:
            return Color(red: 0.98, green: 0.96, blue: 0.94)
        }
    }
}

// MARK: - Board Cell

struct BoardCellView: View {
    let type: TokenType?
    let isSelected: Bool
    let onTap: () -> Void

    @State private var pickedUp: Bool = false
    // Watch the token disappear (nil means it was just taken)
    private var wasToken: Bool { type != nil || pickedUp }

    var body: some View {
        TokenView(type: type, isSelected: isSelected)
            .onTapGesture { onTap() }
            // When token disappears from board (taken), play a scale-out burst
            .onChange(of: type) { _, newVal in
                if newVal == nil {
                    pickedUp = true
                    withAnimation(.easeIn(duration: 0.15)) {
                        pickedUp = false
                    }
                }
            }
    }
}

// MARK: - Game Board

struct BoardView: View {
    var board: GameBoard
    var selectedPositions: [(row: Int, col: Int)]
    let onTokenTap: (Int, Int) -> Void

    var body: some View {
        VStack(spacing: 9) {
            ForEach(0..<5, id: \.self) { row in
                HStack(spacing: 9) {
                    ForEach(0..<5, id: \.self) { col in
                        let isSelected = selectedPositions.contains(where: { $0.row == row && $0.col == col })
                        BoardCellView(
                            type: board.grid[row][col],
                            isSelected: isSelected,
                            onTap: { onTokenTap(row, col) }
                        )
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [PastelPalette.cream, PastelPalette.peach],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(PastelPalette.cardStroke, lineWidth: 1.2)
        )
        .tableLiftBoardShadow()
    }
}
