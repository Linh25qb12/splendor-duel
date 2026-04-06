import SwiftUI

// MARK: - Royal Card Button

struct RoyalCardButton: View {
    let royal: RoyalCard
    let onClaim: () -> Void

    var body: some View {
        Button(action: onClaim) {
            ZStack(alignment: .bottom) {
                Image(royal.catalogImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: CardChrome.width, height: CardChrome.totalHeight)
                    .clipped()
                LinearGradient(
                    colors: [.clear, .black.opacity(0.48)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(width: CardChrome.width, height: CardChrome.totalHeight)
                VStack(spacing: 4) {
                     if royal.ability == .playAgain {
                        Text("Play Again").font(.caption)
                    }
                    if royal.ability == .stealToken {
                        Text("Steal").font(.caption)
                    }
                    if royal.ability == .privilege {
                        Text("+1 Scroll").font(.caption)
                    }
                    Text("\(royal.prestigePoints) Pts")
                        .font(.headline.bold())
                   
                }
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.85), radius: 2, x: 0, y: 1)
                .padding(.bottom, 10)
            }
            .frame(width: CardChrome.width, height: CardChrome.totalHeight)
            .clipShape(RoundedRectangle(cornerRadius: CardChrome.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CardChrome.cornerRadius, style: .continuous)
                    .stroke(PastelPalette.royalStroke, lineWidth: 2.5)
            )
            .tableLiftCardShadow()
        }
    }
}

// MARK: - Overlap Color Button

struct OverlapColorButton: View {
    let color: TokenType
    let bonusCount: Int
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            ZStack {
                Circle()
                    .fill(color.color)
                    .frame(width: 60, height: 60)
                    .shadow(radius: 4)
                Circle()
                    .stroke(PastelPalette.cardStroke, lineWidth: 2)
                    .frame(width: 60, height: 60)
                Text("x\(bonusCount)")
                    .font(.caption)
                    .bold()
                    .foregroundColor(color == .white ? PastelPalette.textPrimary : PastelPalette.textOnDark)
                    .offset(y: 20)
            }
        }
    }
}
