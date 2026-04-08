import SwiftUI

// MARK: - Card View

struct CardView: View {
    let card: Card
    let canAfford: Bool
    let canReserve: Bool
    let onPurchase: () -> Void
    let onReserve: () -> Void

    /// Chỉ dùng cho thẻ trong slot Reserved — chỉ hiện nút Buy, không Res.
    var isReservedSlot: Bool = false
    var onInspect: ((Card) -> Void)? = nil

    var isPlayer1Turn: Bool = true
    @Environment(CardFlyAnimator.self) private var flyAnimator
    @State private var cardFrame: CGRect = .zero
    private let commitSafetyOffset: TimeInterval = 0.06

    var body: some View {
        HStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                Image(CardArtRegistry.catalogImageName(for: card))
                    .resizable()
                    .scaledToFill()
                    .frame(width: CardChrome.width, height: CardChrome.artHeight)
                    .clipped()

                VStack(alignment: .leading, spacing: 4) {
                    headerRow
                    Spacer(minLength: 2)
                    costRow
                }
                .padding(6)
                .frame(width: CardChrome.width, height: CardChrome.artHeight, alignment: .topLeading)

                if card.ability != .none {
                    VStack {
                        Spacer(minLength: 0)
                        HStack {
                            Spacer(minLength: 0)
                            abilityBadge(for: card.ability)
                                .padding(.trailing, 5)
                                .padding(.bottom, 5)
                        }
                    }
                    .frame(width: CardChrome.width, height: CardChrome.artHeight)
                }
            }
            .frame(width: CardChrome.width, height: CardChrome.artHeight)
            .clipped()
            .contentShape(Rectangle())
            .onTapGesture { onInspect?(card) }

            Group {
                if isReservedSlot {
                    Button(action: {
                        let duration = flyAnimator.launch(
                            card: card,
                            from: cardFrame,
                            isBuy: true,
                            isPlayer1Turn: isPlayer1Turn
                        )
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration + commitSafetyOffset) {
                            onPurchase()
                        }
                    }) {
                        Text("Buy")
                            .font(.caption2).bold()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(canAfford ? PastelPalette.buyEnabled : PastelPalette.buyDisabled)
                            .foregroundStyle(PastelPalette.buttonLabelOnPastel)
                    }
                    .disabled(!canAfford)
                } else {
                    VStack(spacing: 0) {
                        Button(action: {
                            let duration = flyAnimator.launch(
                                card: card,
                                from: cardFrame,
                                isBuy: true,
                                isPlayer1Turn: isPlayer1Turn
                            )
                            DispatchQueue.main.asyncAfter(deadline: .now() + duration + commitSafetyOffset) {
                                onPurchase()
                            }
                        }) {
                            Text("Buy")
                                .font(.caption2).bold()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(canAfford ? PastelPalette.buyEnabled : PastelPalette.buyDisabled)
                                .foregroundStyle(PastelPalette.buttonLabelOnPastel)
                        }
                        .disabled(!canAfford)

                        Button(action: {
                            let duration = flyAnimator.launch(
                                card: card,
                                from: cardFrame,
                                isBuy: false,
                                isPlayer1Turn: isPlayer1Turn
                            )
                            DispatchQueue.main.asyncAfter(deadline: .now() + duration + commitSafetyOffset) {
                                onReserve()
                            }
                        }) {
                            Text("Res")
                                .font(.caption2).bold()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(canReserve ? PastelPalette.reserveEnabled : PastelPalette.reserveDisabled)
                                .foregroundStyle(PastelPalette.buttonLabelOnPastel)
                        }
                        .disabled(!canReserve)
                    }
                }
            }
            .frame(width: CardChrome.actionColumnWidth)
        }
        .frame(width: CardChrome.totalWidth, height: CardChrome.totalHeight)
        .clipShape(RoundedRectangle(cornerRadius: CardChrome.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CardChrome.cornerRadius, style: .continuous)
                .stroke(PastelPalette.cardStroke, lineWidth: 1)
        )
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { cardFrame = geo.frame(in: .global) }
                    .onChange(of: geo.frame(in: .global)) { _, f in
                        cardFrame = f
                    }
            }
        )
        .tableLiftCardShadow()
    }

    private var headerRow: some View {
        HStack(alignment: .top, spacing: 4) {
            if card.prestigePoints > 0 {
                topChip("\(card.prestigePoints)", system: "star.fill")
            }
            if card.crowns > 0 {
                topChip("\(card.crowns)", system: "crown.fill")
            }

            Spacer(minLength: 0)

            if let bonus = card.bonus {
                HStack(spacing: 2) {
                    ForEach(0..<card.bonusCount, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(gemColor(for: bonus))
                            .frame(width: 13, height: 13)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .stroke(Color.black, lineWidth: 1.25)
                            )
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.88))
                )
            }
        }
    }

    private var costRow: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(card.cost.keys.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { token in
                if let amount = card.cost[token] {
                    gemCostChip(token: token, amount: amount)
                }
            }
        }
        .padding(.horizontal, 3)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Color.white.opacity(0.88))
        )
    }

    private func gemCostChip(token: TokenType, amount: Int) -> some View {
        ZStack {
            Circle()
                .fill(gemColor(for: token))
                .overlay(Circle().stroke(Color.black, lineWidth: 1.25))
                .frame(width: 15, height: 15)
            Text("\(amount)")
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(token == .white || token == .gold ? .black : .white)
                .shadow(color: .black.opacity(0.7), radius: 0.5, x: 0, y: 0.5)
        }
    }

    private func topChip(_ value: String, system: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: system).font(.system(size: 8, weight: .bold))
            Text(value).font(.system(size: 10, weight: .heavy))
        }
        .foregroundStyle(PastelPalette.textPrimary)
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.88))
        )
    }

    private func gemColor(for type: TokenType) -> Color {
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

    @ViewBuilder
    private func abilityBadge(for ability: CardAbility) -> some View {
        HStack(spacing: 3) {
            switch ability {
            case .playAgain:
                Image(systemName: "arrow.clockwise.circle.fill").foregroundColor(PastelPalette.info)
                Text("Turn")
            case .takeToken:
                Image(systemName: "plus.circle.fill").foregroundColor(PastelPalette.success)
                Text("+1")
            case .stealToken:
                Image(systemName: "hand.raised.fill").foregroundColor(PastelPalette.danger)
                Text("Steal")
            case .privilege:
                Image(systemName: "scroll.fill").foregroundColor(PastelPalette.warning)
                Text("+Scroll")
            case .overlap:
                Image(systemName: "link").foregroundColor(PastelPalette.textSecondary)
                Text("Copy")
            case .overlapPlayAgain:
                Image(systemName: "link").foregroundColor(PastelPalette.textSecondary)
                Text("+")
                Image(systemName: "arrow.clockwise").foregroundColor(PastelPalette.info)
            case .none:
                EmptyView()
            }
        }
        .font(.system(size: 8, weight: .bold))
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .foregroundStyle(PastelPalette.textPrimary)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.9))
        )
    }
}
