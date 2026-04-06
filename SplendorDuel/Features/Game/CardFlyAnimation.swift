import SwiftUI

// MARK: - Card Fly Animation System

/// Describes one card currently flying across the screen
struct FlyingCard: Identifiable {
    let id = UUID()
    let card: Card
    let startFrame: CGRect   // in global screen coordinates
    let isBuy: Bool
    let isPlayer1Turn: Bool  // snapshot of whose turn it was — routes to correct dashboard
    let order: Int
}

/// Observable state bag — injected via @Environment so CardView and ContentView
/// can both talk to it without prop-drilling
@Observable
class CardFlyAnimator {
    var flyingCards: [FlyingCard] = []
    private var launchSequence: Int = 0
    private let baseResponse: TimeInterval = 0.55
    private let stagger: TimeInterval = 0.04

    // Dashboard center anchors (fallback)
    var player1Anchor: CGPoint = .zero
    var player2Anchor: CGPoint = .zero
    // Destination anchors (exact target zones)
    var player1PurchasedAnchor: CGPoint = .zero
    var player2PurchasedAnchor: CGPoint = .zero
    var player1ReservedAnchor: CGPoint = .zero
    var player2ReservedAnchor: CGPoint = .zero
    // Fine-grained targets
    var player1ReservedInsertAnchor: CGPoint = .zero
    var player2ReservedInsertAnchor: CGPoint = .zero
    var player1BonusAnchors: [TokenType: CGPoint] = [:]
    var player2BonusAnchors: [TokenType: CGPoint] = [:]

    @discardableResult
    func launch(card: Card, from frame: CGRect, isBuy: Bool, isPlayer1Turn: Bool) -> TimeInterval {
        let order = launchSequence
        launchSequence += 1
        let fc = FlyingCard(
            card: card,
            startFrame: frame,
            isBuy: isBuy,
            isPlayer1Turn: isPlayer1Turn,
            order: order
        )
        flyingCards.append(fc)
        let totalDuration = baseResponse + (Double(order) * stagger)
        // Remove ghost almost immediately when movement finishes.
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration + 0.01) {
            self.flyingCards.removeAll { $0.id == fc.id }
        }
        return totalDuration
    }
}

/// One card that animates from source to destination dashboard.
/// `startLocal` / `targetLocal` must be in the **same** coordinate space as the overlay
/// (typically the local space of the root `GeometryReader` that wraps the game).
struct FlyingCardView: View {
    let card: Card
    let startLocal: CGPoint
    let targetLocal: CGPoint
    let order: Int

    @State private var phase: CGFloat = 0  // 0 = at source, 1 = at destination
    private let baseResponse: TimeInterval = 0.55
    private let stagger: TimeInterval = 0.04

    var body: some View {
        CardView(
            card: card,
            canAfford: false,
            canReserve: false,
            onPurchase: {},
            onReserve: {}
        )
            .scaleEffect(1 - phase * 0.4)
            .shadow(radius: CGFloat(9) * (1 - phase * 0.25))
            .opacity(Double(1 - phase * 0.45))
            .position(
                x: startLocal.x + (targetLocal.x - startLocal.x) * phase,
                y: startLocal.y + (targetLocal.y - startLocal.y) * phase
            )
            .zIndex(Double(order))
            .allowsHitTesting(false)
            .onAppear {
                let delay = Double(order) * 0.04
                withAnimation(.spring(response: baseResponse, dampingFraction: 0.72).delay(delay)) {
                    phase = 1
                }
            }
    }
}
