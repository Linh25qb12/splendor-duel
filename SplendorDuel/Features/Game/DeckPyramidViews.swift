import SwiftUI

// MARK: - Card Pyramid

struct CardPyramidView: View {
    var viewModel: GameViewModel
    var onInspect: ((Card) -> Void)? = nil

    var body: some View {
        VStack(alignment: .center, spacing: 5) {
            HStack(spacing: 8) {
                DeckView(
                    level: 3, count: viewModel.deckLevel3.count,
                    canReserve: viewModel.canReserveAny()
                ) { viewModel.reserveCardFromDeck(level: 3) }
                ForEach(viewModel.tableCardsLevel3) { card in cardCell(card) }
            }
            HStack(spacing: 8) {
                DeckView(
                    level: 2, count: viewModel.deckLevel2.count,
                    canReserve: viewModel.canReserveAny()
                ) { viewModel.reserveCardFromDeck(level: 2) }
                ForEach(viewModel.tableCardsLevel2) { card in cardCell(card) }
            }
            HStack(spacing: 8) {
                DeckView(
                    level: 1, count: viewModel.deckLevel1.count,
                    canReserve: viewModel.canReserveAny()
                ) { viewModel.reserveCardFromDeck(level: 1) }
                ForEach(viewModel.tableCardsLevel1) { card in cardCell(card) }
            }
        }
    }

    private func cardCell(_ card: Card) -> some View {
        CardView(
            card: card,
            canAfford: viewModel.canAfford(card: card),
            canReserve: viewModel.canReserve(card: card),
            onPurchase: { viewModel.purchaseCard(card) },
            onReserve: { viewModel.reserveCard(card) },
            onInspect: onInspect,
            isPlayer1Turn: viewModel.isPlayer1Turn
        )
    }
}

// MARK: - Deck View (Facedown Cards)

struct DeckView: View {
    let level: Int
    let count: Int
    let canReserve: Bool
    let onReserve: () -> Void

    private var isEmpty: Bool { count == 0 }

    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                PastelPalette.neutralSoft.opacity(0.7)
                VStack(spacing: 6) {
                    Image(systemName: "rectangle.portrait.on.rectangle.portrait.fill")
                        .font(.title)
                        .foregroundColor(PastelPalette.textSecondary)
                    Text("Level \(level)")
                        .font(.caption)
                        .bold()
                        .foregroundColor(PastelPalette.textSecondary)
                    Text("\(count)")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(count > 0 ? PastelPalette.textPrimary : PastelPalette.textSecondary)
                }
            }
            .frame(width: CardChrome.width, height: CardChrome.artHeight)
            .background(PastelPalette.cream)

            Button(action: onReserve) {
                Text(isEmpty ? "—" : "Res")
                    .font(.caption2).bold()
                    .rotationEffect(.degrees(90))
                    .fixedSize()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(canReserve && !isEmpty ? PastelPalette.reserveEnabled : PastelPalette.reserveDisabled)
                    .foregroundStyle(PastelPalette.buttonLabelOnPastel)
            }
            .disabled(!canReserve || isEmpty)
            .frame(width: CardChrome.actionColumnWidth)
        }
        .frame(width: CardChrome.totalWidth, height: CardChrome.totalHeight)
        .clipShape(RoundedRectangle(cornerRadius: CardChrome.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CardChrome.cornerRadius, style: .continuous)
                .stroke(PastelPalette.cardStroke, lineWidth: 1)
        )
        .tableLiftCardShadow()
        .opacity(isEmpty ? 0.5 : 1.0)
    }
}
