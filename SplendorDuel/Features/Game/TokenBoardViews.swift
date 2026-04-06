import SwiftUI

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
            } else {
                Circle()
                    .fill(colorFor(type))
                    .overlay(
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.white.opacity(0.5), .clear],
                                    center: .topLeading,
                                    startRadius: 2,
                                    endRadius: 18
                                )
                            )
                    )
                    .shadow(color: .black.opacity(isSelected ? 0.28 : 0.16), radius: isSelected ? 6 : 3, x: 0, y: 2)

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
        .frame(width: 44, height: 44)
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
        VStack(spacing: 7) {
            ForEach(0..<5, id: \.self) { row in
                HStack(spacing: 7) {
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
        .padding(10)
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
        .shadow(color: PastelPalette.cardShadow, radius: 6, x: 0, y: 3)
    }
}
