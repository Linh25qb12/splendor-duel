import SwiftUI

// MARK: - Player Dashboard

struct PlayerDashboardView: View {
    var player: Player
    var isCurrentTurn: Bool
    var canAffordCard: (Card) -> Bool
    var onPurchaseReservedCard: (Card) -> Void
    // true for the dashboard at the top of the screen (Player 2)
    var isTopPlayer: Bool = false

    @Environment(CardFlyAnimator.self) private var flyAnimator
    private enum AnchorZone { case center, purchased, reserved, reservedInsert }
    private let bonusAnchorTypes: [TokenType] = [.white, .blue, .green, .red, .black]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            headerRow
            tokenRow
            purchasedBonusesRow
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear { publishAnchor(geo, zone: .purchased) }
                        .onChange(of: geo.frame(in: .global)) { _, _ in publishAnchor(geo, zone: .purchased) }
                }
            )
            reservedRoyalRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(isCurrentTurn ? Color(red: 0.88, green: 0.94, blue: 1.0) : Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isCurrentTurn ? PastelPalette.info : Color.clear, lineWidth: 2)
        )
        // Measure and publish this dashboard's vertical centre as the fly target (update when layout changes).
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { publishAnchor(geo, zone: .center) }
                    .onChange(of: geo.frame(in: .global)) { _, _ in
                        publishAnchor(geo, zone: .center)
                    }
            }
        )
    }

    private var reservedRoyalRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider()
            HStack(alignment: .top, spacing: 10) {
                sectionTitle("Reserved")
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { index in
                        reservedSlot(at: index)
                    }
                }

                Rectangle()
                    .fill(PastelPalette.divider)
                    .frame(width: 1, height: 74)
                    .padding(.horizontal, 2)

                VStack(spacing: 6) {
                    if player.royalCards.isEmpty {
                        Image(systemName: "crown")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 42, height: 34)
                            .background(PastelPalette.lily.opacity(0.35), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    } else {
                        ForEach(player.royalCards) { royal in
                            royalMiniThumb(royal)
                        }
                    }
                }
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { publishAnchor(geo, zone: .reserved) }
                    .onChange(of: geo.frame(in: .global)) { _, _ in publishAnchor(geo, zone: .reserved) }
            }
        )
    }

    @ViewBuilder
    private func reservedSlot(at index: Int) -> some View {
        if index < player.reservedCards.count {
            let card = player.reservedCards[index]
            CardView( 
                card: card,
                canAfford: isCurrentTurn && canAffordCard(card),
                canReserve: false,
                onPurchase: { onPurchaseReservedCard(card) },
                onReserve: {},
                isReservedSlot: true
            )
            .scaleEffect(0.46)
            .frame(width: 66, height: 74)
            .clipped()
            .background(anchorPublisher(for: index))
        } else {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(PastelPalette.lily.opacity(0.45))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(PastelPalette.cardStroke.opacity(0.85), lineWidth: 1)
                )
                .frame(width: 66, height: 74)
                .background(anchorPublisher(for: index))
        }
    }

    private func anchorPublisher(for index: Int) -> some View {
        GeometryReader { geo in
            Color.clear
                .onAppear {
                    if index == min(player.reservedCards.count, 2) {
                        publishAnchor(geo, zone: .reservedInsert)
                    }
                }
                .onChange(of: geo.frame(in: .global)) { _, _ in
                    if index == min(player.reservedCards.count, 2) {
                        publishAnchor(geo, zone: .reservedInsert)
                    }
                }
        }
    }

    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(player.name).font(.headline).fontWeight(.semibold)
            Spacer(minLength: 6)
            statItem(title: "Points", value: "\(player.totalPrestigePoints)", icon: "star.fill")
            statItem(value: "\(player.totalCrowns)", icon: "crown.fill")
            statItem(value: "\(player.privileges)", icon: "scroll.fill")
            statItem(value: "\(player.reservedCards.count)/3", icon: "lock.fill")
        }
    }

    private var tokenRow: some View {
        HStack(spacing: 8) {
            sectionTitle("Tokens")
            if !hasAnyToken {
                Text("-").font(.caption).foregroundStyle(.secondary)
            } else {
                HStack(spacing: 6) { tokenChips }
            }
        }
    }

    private var hasAnyToken: Bool {
        TokenType.allCases.contains { (player.tokens[$0] ?? 0) > 0 }
    }

    private var purchasedBonusesRow: some View {
        HStack(spacing: 8) {
            sectionTitle("Cards")
            ForEach(bonusAnchorTypes, id: \.self) { tokenType in
                let count = player.bonuses[tokenType] ?? 0
                ZStack {
                    if count > 0 {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(colorFor(tokenType))
                                .frame(width: 22, height: 30)
                                .shadow(radius: 1)
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(PastelPalette.textSecondary.opacity(0.55), lineWidth: 1)
                                .frame(width: 22, height: 30)
                            Text("\(count)")
                                .font(.caption2).bold()
                                .foregroundColor(tokenType == .white ? PastelPalette.textPrimary : PastelPalette.textOnDark)
                        }
                    } else {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.clear)
                            .frame(width: 22, height: 30)
                    }
                }
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear { publishBonusAnchor(geo, tokenType: tokenType) }
                            .onChange(of: geo.frame(in: .global)) { _, _ in
                                publishBonusAnchor(geo, tokenType: tokenType)
                            }
                    }
                )
            }
        }
    }

    private static let tokenDisplayOrder: [TokenType] = [
        .white, .blue, .green, .red, .black, .pearl, .gold
    ]

    @ViewBuilder
    private var tokenChips: some View {
        ForEach(Self.tokenDisplayOrder, id: \.self) { tokenType in
            let count = player.tokens[tokenType] ?? 0
            HStack(spacing: 3) {
                Circle()
                    .fill(colorFor(tokenType))
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle().stroke(Color.black.opacity(0.12), lineWidth: 0.5)
                    )
                Text("\(count)")
                    .font(.caption)
                    .foregroundStyle(count > 0 ? .primary : .secondary)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                PastelPalette.lily.opacity(count > 0 ? 0.55 : 0.25),
                in: Capsule()
            )
            .opacity(count > 0 ? 1 : 0.5)
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text("\(text):")
            .font(.caption)
            .foregroundColor(PastelPalette.textSecondary)
            .frame(width: 82, alignment: .leading)
    }

    private func publishAnchor(_ geo: GeometryProxy, zone: AnchorZone) {
        let frame = geo.frame(in: .global)
        let anchor = CGPoint(x: frame.midX, y: frame.midY)
        if isTopPlayer {
            switch zone {
            case .center: flyAnimator.player2Anchor = anchor
            case .purchased: flyAnimator.player2PurchasedAnchor = anchor
            case .reserved: flyAnimator.player2ReservedAnchor = anchor
            case .reservedInsert: flyAnimator.player2ReservedInsertAnchor = anchor
            }
        } else {
            switch zone {
            case .center: flyAnimator.player1Anchor = anchor
            case .purchased: flyAnimator.player1PurchasedAnchor = anchor
            case .reserved: flyAnimator.player1ReservedAnchor = anchor
            case .reservedInsert: flyAnimator.player1ReservedInsertAnchor = anchor
            }
        }
    }

    private func publishBonusAnchor(_ geo: GeometryProxy, tokenType: TokenType) {
        let frame = geo.frame(in: .global)
        let anchor = CGPoint(x: frame.midX, y: frame.midY)
        if isTopPlayer {
            flyAnimator.player2BonusAnchors[tokenType] = anchor
        } else {
            flyAnimator.player1BonusAnchors[tokenType] = anchor
        }
    }

    private func colorFor(_ type: TokenType) -> Color {
        switch type {
        case .white: return PastelPalette.gemWhite
        case .blue: return PastelPalette.gemBlue
        case .green: return PastelPalette.gemGreen
        case .red: return PastelPalette.gemRed
        case .black: return PastelPalette.gemBlack
        case .pearl: return PastelPalette.gemPearl
        case .gold: return PastelPalette.gemGold
        }
    }

    private func statItem(title: String? = nil, value: String, icon: String) -> some View {
        HStack(spacing: 4) {
            if let title {
                Text("\(title):")
                    .fontWeight(.bold)
                    .minimumScaleFactor(0.5)
            }
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(PastelPalette.buttonLabelOnPastel)
            Text(value)
                .fontWeight(.semibold)
        }
    }

    private func royalMiniThumb(_ royal: RoyalCard) -> some View {
        ZStack(alignment: .bottomTrailing) {
            Image(royal.catalogImageName)
                .resizable()
                .scaledToFill()
                .frame(width: 42, height: 34)
                .clipped()
            HStack(spacing: 1) {
                Image(systemName: "star.fill")
                    .font(.system(size: 6, weight: .bold))
                Text("\(royal.prestigePoints)")
                    .font(.system(size: 8, weight: .bold))
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.8), radius: 0.5, x: 0, y: 0.5)
            .padding(.horizontal, 3)
            .padding(.vertical, 1.5)
            .background(PastelPalette.chipDark, in: Capsule())
            .offset(x: 2, y: 2)
        }
        .frame(width: 42, height: 34)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(PastelPalette.royalStroke, lineWidth: 1.5)
        )
    }

    private func royalAbilityText(_ ability: CardAbility) -> String {
        switch ability {
        case .privilege: return "Scroll"
        case .stealToken: return "Steal"
        case .playAgain: return "Turn"
        default: return "None"
        }
    }

    private func royalAbilityIcon(_ ability: CardAbility) -> String {
        switch ability {
        case .privilege: return "scroll.fill"
        case .stealToken: return "hand.raised.fill"
        case .playAgain: return "arrow.clockwise"
        default: return "circle.slash"
        }
    }
}
