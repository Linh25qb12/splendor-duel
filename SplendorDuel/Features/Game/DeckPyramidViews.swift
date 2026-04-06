import SwiftUI

// MARK: - Card Pyramid

struct CardPyramidView: View {
    var viewModel: GameViewModel

    var body: some View {
        VStack(alignment: .center, spacing: 5) {
            // Level 3
            HStack(spacing: 8) {
                DeckView(level: 3, isEmpty: viewModel.deckLevel3.isEmpty, canReserve: viewModel.canReserveAny()) {
                    viewModel.reserveCardFromDeck(level: 3)
                }
                ForEach(viewModel.tableCardsLevel3) { card in
                    CardView(card: card, canAfford: viewModel.canAfford(card: card), canReserve: viewModel.canReserve(card: card), onPurchase: { viewModel.purchaseCard(card) }, onReserve: { viewModel.reserveCard(card) }, isPlayer1Turn: viewModel.isPlayer1Turn)
                }
            }
            // Level 2
            HStack(spacing: 8) {
                DeckView(level: 2, isEmpty: viewModel.deckLevel2.isEmpty, canReserve: viewModel.canReserveAny()) {
                    viewModel.reserveCardFromDeck(level: 2)
                }
                ForEach(viewModel.tableCardsLevel2) { card in
                    CardView(card: card, canAfford: viewModel.canAfford(card: card), canReserve: viewModel.canReserve(card: card), onPurchase: { viewModel.purchaseCard(card) }, onReserve: { viewModel.reserveCard(card) }, isPlayer1Turn: viewModel.isPlayer1Turn)
                }
            }
            // Level 1
            HStack(spacing: 8) {
                DeckView(level: 1, isEmpty: viewModel.deckLevel1.isEmpty, canReserve: viewModel.canReserveAny()) {
                    viewModel.reserveCardFromDeck(level: 1)
                }
                ForEach(viewModel.tableCardsLevel1) { card in
                    CardView(card: card, canAfford: viewModel.canAfford(card: card), canReserve: viewModel.canReserve(card: card), onPurchase: { viewModel.purchaseCard(card) }, onReserve: { viewModel.reserveCard(card) }, isPlayer1Turn: viewModel.isPlayer1Turn)
                }
            }
        }
    }
}

// MARK: - Deck View (Facedown Cards)

struct DeckView: View {
    let level: Int
    let isEmpty: Bool
    let canReserve: Bool
    let onReserve: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // --- TOP HALF: Card Back Design ---
            ZStack {
                PastelPalette.neutralSoft.opacity(0.7)
                VStack(spacing: 8) {
                    Image(systemName: "rectangle.portrait.on.rectangle.portrait.fill")
                        .font(.title)
                        .foregroundColor(PastelPalette.textSecondary)
                    Text("Level \(level)")
                        .font(.caption)
                        .bold()
                        .foregroundColor(PastelPalette.textSecondary)
                }
            }
            .frame(width: CardChrome.width, height: CardChrome.artHeight)
            .background(PastelPalette.cream)

            // --- BOTTOM HALF: Reserve Button ---
            Button(action: onReserve) {
                Text(isEmpty ? "Empty" : "Res Deck")
                    .font(.caption2).bold()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(canReserve && !isEmpty ? PastelPalette.reserveEnabled : PastelPalette.reserveDisabled)
                    .foregroundStyle(PastelPalette.buttonLabelOnPastel)
            }
            .disabled(!canReserve || isEmpty)
            .frame(height: CardChrome.actionRowHeight)
        }
        .frame(width: CardChrome.width, height: CardChrome.totalHeight)
        .clipShape(RoundedRectangle(cornerRadius: CardChrome.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CardChrome.cornerRadius, style: .continuous)
                .stroke(PastelPalette.cardStroke, lineWidth: 1)
        )
        .shadow(color: PastelPalette.cardShadow, radius: CardChrome.shadowRadius, x: 0, y: CardChrome.shadowY)
        .opacity(isEmpty ? 0.5 : 1.0)
    }
}
