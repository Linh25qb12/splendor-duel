import SwiftUI

// MARK: - Main Game Screen

struct ContentView: View {
    @Bindable var viewModel: GameViewModel
    let onReset: () -> Void

    // Owns the fly animator — passed down via @Environment
    @State private var flyAnimator = CardFlyAnimator()

    var availableOverlapColors: [TokenType] {
        Array(Set(viewModel.currentPlayer.purchasedCards.compactMap { $0.bonus }))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                mainGameLayout
                overlays
            }
            // GeometryReader aligns its child to top-leading by default; without this, the ZStack
            // shrink-wraps to content width and the whole board sits left with empty space on the right.
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            // Overlay keeps layout stable (flying ghosts don't participate in ZStack sizing).
            .overlay {
                flyingCardLayer(geo: geo)
                    .allowsHitTesting(false)
            }
        }
        .environment(flyAnimator)
        .sheet(isPresented: $viewModel.isShowingRules) { RuleBookView() }
        .sheet(isPresented: $viewModel.isShowingHistory) { HistoryView(viewModel: viewModel) }
    }

    /// Converts global frames (from `CardView` / dashboards) into this `GeometryReader`'s local space
    /// so `.position` matches SwiftUI's coordinate system (fixes invisible / off-screen ghosts).
    @ViewBuilder
    private func flyingCardLayer(geo: GeometryProxy) -> some View {
        let containerGlobal = geo.frame(in: .global)
        ForEach(flyAnimator.flyingCards) { fc in
            let targetGlobal: CGPoint = {
                if fc.isPlayer1Turn {
                    if fc.isBuy {
                        if let b = fc.card.bonus, let p = flyAnimator.player1BonusAnchors[b] { return p }
                        return flyAnimator.player1PurchasedAnchor
                    } else {
                        return flyAnimator.player1ReservedInsertAnchor
                    }
                } else {
                    if fc.isBuy {
                        if let b = fc.card.bonus, let p = flyAnimator.player2BonusAnchors[b] { return p }
                        return flyAnimator.player2PurchasedAnchor
                    } else {
                        return flyAnimator.player2ReservedInsertAnchor
                    }
                }
            }()
            let fallbackGlobal: CGPoint = {
                if fc.isPlayer1Turn {
                    return fc.isBuy ? flyAnimator.player1PurchasedAnchor : flyAnimator.player1ReservedAnchor
                } else {
                    return fc.isBuy ? flyAnimator.player2PurchasedAnchor : flyAnimator.player2ReservedAnchor
                }
            }()
            let startLocal = CGPoint(
                x: fc.startFrame.midX - containerGlobal.minX,
                y: fc.startFrame.midY - containerGlobal.minY
            )
            // Fly to purchased/reserved anchor; fallback to dashboard center if section anchor not ready.
            let resolvedTarget = (targetGlobal.x > 1 && targetGlobal.y > 1) ? targetGlobal : fallbackGlobal
            let validTargetX = resolvedTarget.x > 1 ? resolvedTarget.x : fc.startFrame.midX
            let validTargetY = resolvedTarget.y > 1 ? resolvedTarget.y : fc.startFrame.midY
            let targetLocal = CGPoint(
                x: validTargetX - containerGlobal.minX,
                y: validTargetY - containerGlobal.minY
            )
            FlyingCardView(
                card: fc.card,
                startLocal: startLocal,
                targetLocal: targetLocal,
                order: fc.order
            )
        }
    }

    // MARK: - Body Subviews

    private var mainGameLayout: some View {
        VStack(spacing: 12) {
            PlayerDashboardView(
                player: viewModel.player2,
                isCurrentTurn: !viewModel.isPlayer1Turn,
                canAffordCard: { viewModel.canAfford(card: $0) },
                onPurchaseReservedCard: { viewModel.purchaseCard($0) },
                isTopPlayer: true
            )

            middleRow
            controlsRow
            actionsRow

            PlayerDashboardView(
                player: viewModel.player1,
                isCurrentTurn: viewModel.isPlayer1Turn,
                canAffordCard: { viewModel.canAfford(card: $0) },
                onPurchaseReservedCard: { viewModel.purchaseCard($0) }
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .disabled(!viewModel.isMyTurn)
        .blur(radius: viewModel.winnerName != nil ? 5 : 0)
    }

    private var middleRow: some View {
        HStack(alignment: .center, spacing: 15) {
            Spacer(minLength: 0)
            CardPyramidView(viewModel: viewModel)
                .scaleEffect(0.82)
                .frame(width: 550, height: 340)

            VStack(spacing: 10) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.availableRoyals) { royal in
                            let thumbW: CGFloat = 72
                            let thumbH = thumbW * CardChrome.totalHeight / CardChrome.width
                            ZStack(alignment: .bottom) {
                                Image(royal.catalogImageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: thumbW, height: thumbH)
                                    .clipped()
                                VStack(spacing: 2) {
                                    if royal.ability != .none {
                                        Label(royalAbilityText(royal.ability), systemImage: royalAbilityIcon(royal.ability))
                                            .font(.system(size: 8, weight: .semibold))
                                    }
                                    Text("\(royal.prestigePoints)")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.85), radius: 1, x: 0, y: 0)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 3)
                                .background(PastelPalette.chipDark.opacity(0.95), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                                .padding(.bottom, 3)
                            }
                            .frame(width: thumbW, height: thumbH)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(PastelPalette.royalStroke, lineWidth: 2)
                            )
                            .shadow(color: PastelPalette.cardShadow, radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(maxWidth: .infinity)

                BoardView(board: viewModel.board, selectedPositions: viewModel.selectedPositions) { r, c in
                    viewModel.handleTokenTap(row: r, col: c)
                }

                if viewModel.isTakingMatchingToken, let color = viewModel.matchingTokenColor {
                    Text("Ability: Tap a \(color.rawValue.capitalized) token!")
                        .font(.subheadline).bold()
                        .foregroundColor(color == .white ? PastelPalette.textPrimary : PastelPalette.textOnDark)
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(highlightColor(for: color))
                        .cornerRadius(8)
                }
                if viewModel.isSelectingGoldToken {
                    Text("Tap a Gold token to finish!")
                        .font(.headline)
                        .foregroundColor(PastelPalette.textOnDark)
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(PastelPalette.warning)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }
            .scaleEffect(0.82)
            .frame(width: 230, height: 340)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }

    private var controlsRow: some View {
        HStack(spacing: 12) {
            Button(action: { viewModel.isShowingRules = true }) {
                Label("Rules", systemImage: "book.closed.fill")
            }
            .font(.subheadline)
            .padding(8)
            .background(PastelPalette.accentSky.opacity(0.55))
            .foregroundStyle(PastelPalette.buttonLabelOnPastel)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Button(action: { viewModel.isShowingHistory = true }) {
                Label("History", systemImage: "clock.fill")
            }
            .font(.subheadline)
            .padding(8)
            .background(PastelPalette.lavender.opacity(0.5))
            .foregroundStyle(PastelPalette.buttonLabelOnPastel)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Spacer()

            Button(action: { onReset() }) {
                Label("Reset", systemImage: "arrow.counterclockwise")
            }
            .font(.subheadline)
            .foregroundStyle(PastelPalette.buttonLabelOnPastel)
            .padding(8)
            .background(PastelPalette.accentRose.opacity(0.45))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Button(action: { withAnimation { viewModel.refillBoard() } }) {
                Label("Refill Board", systemImage: "scroll.fill")
                    .font(.subheadline)
                    .foregroundStyle(PastelPalette.buttonLabelOnPastel)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(PastelPalette.lily.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(PastelPalette.cardStroke, lineWidth: 1)
                    )
            }
            .disabled(viewModel.board.tokenBag.isEmpty)
        }
        .padding(.horizontal)
    }

    private var actionsRow: some View {
        HStack(spacing: 15) {
            Button(action: { withAnimation { viewModel.usePrivilege() } }) {
                Label("Use Privilege", systemImage: "scroll.fill")
                    .font(.subheadline).bold()
                    .foregroundStyle(PastelPalette.buttonLabelOnPastel)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(viewModel.canUsePrivilege() ? PastelPalette.accentSage : PastelPalette.buyDisabled)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(!viewModel.canUsePrivilege())

            Button(action: { withAnimation { viewModel.confirmTokenSelection() } }) {
                Text("Take Tokens")
                    .font(.subheadline).bold()
                    .foregroundStyle(PastelPalette.buttonLabelOnPastel)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(viewModel.isSelectionValid() ? PastelPalette.accentSky : PastelPalette.buyDisabled)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(!viewModel.isSelectionValid())
        }
        .padding(.horizontal)
    }

    private var overlays: some View {
        // animation(.spring) here ensures all overlay insert/remove transitions
        // use the spring curve automatically
        Group {
            if let winner = viewModel.winnerName {
                VStack(spacing: 20) {
                    Label("Game Over!", systemImage: "party.popper.fill")
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                    Text("\(winner) Wins!").font(.title).foregroundColor(PastelPalette.success)
                    Button("Play Again") { onReset() }
                        .font(.headline).padding().background(PastelPalette.info).foregroundColor(PastelPalette.textOnDark).cornerRadius(10)
                }
                .padding(40)
                .background(PastelPalette.cream)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: PastelPalette.cardShadow, radius: CardChrome.shadowRadius, x: 0, y: CardChrome.shadowY)
                .overlayCard()
            }

            if viewModel.isDiscardingTokens { discardOverlay }
            if viewModel.isStealingToken { stealOverlay }
            if viewModel.isSelectingRoyal { royalOverlay }
            if viewModel.isSelectingOverlapColor { overlapOverlay }

            if viewModel.isMultiplayer && !viewModel.isMyTurn {
                ZStack {
                    PastelPalette.overlayDark.ignoresSafeArea()
                    VStack {
                        ProgressView().scaleEffect(2).padding(.bottom)
                        Text("Waiting for opponent...").font(.title).bold().foregroundColor(PastelPalette.textOnDark)
                    }
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.isDiscardingTokens)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.isStealingToken)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.isSelectingRoyal)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.isSelectingOverlapColor)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.winnerName != nil)
    }

    private var discardOverlay: some View {
        VStack(spacing: 20) {
            Text("Token Limit Exceeded!").font(.title2).bold().foregroundColor(PastelPalette.danger)
            Text("You have \(viewModel.currentPlayer.totalTokenCount) tokens.\nPlease discard \(viewModel.tokensToDiscard).")
                .multilineTextAlignment(.center)
            HStack(spacing: 15) {
                ForEach(TokenType.allCases, id: \.self) { tokenType in
                    if let count = viewModel.currentPlayer.tokens[tokenType], count > 0 {
                        Button(action: { withAnimation { viewModel.discardToken(tokenType) } }) {
                            ZStack {
                                Circle().fill(tokenType.color).frame(width: 50, height: 50).shadow(radius: 3)
                                Circle().stroke(PastelPalette.textSecondary.opacity(0.45), lineWidth: 1)
                                Text("\(count)").font(.headline)
                                    .foregroundColor(tokenType == .white || tokenType == .gold ? PastelPalette.textPrimary : PastelPalette.textOnDark)
                            }
                        }
                    }
                }
            }
        }
        .padding(30)
        .background(PastelPalette.cream)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: PastelPalette.cardShadow, radius: CardChrome.shadowRadius, x: 0, y: CardChrome.shadowY)
        .overlayCard()
    }

    private var stealOverlay: some View {
        VStack(spacing: 20) {
            Label("Thief!", systemImage: "hand.raised.fill")
                .font(.largeTitle).bold()
            Text("Select one of \(viewModel.opponent.name)'s tokens to steal.")
            HStack(spacing: 15) {
                ForEach(TokenType.allCases, id: \.self) { tokenType in
                    if tokenType != .gold, let count = viewModel.opponent.tokens[tokenType], count > 0 {
                        Button(action: { withAnimation { viewModel.executeSteal(token: tokenType) } }) {
                            ZStack {
                                Circle().fill(tokenType.color).frame(width: 50, height: 50).shadow(radius: 3)
                                Circle().stroke(PastelPalette.textSecondary.opacity(0.45), lineWidth: 1)
                                Text("\(count)").font(.headline)
                                    .foregroundColor(tokenType == .white ? PastelPalette.textPrimary : PastelPalette.textOnDark)
                            }
                        }
                    }
                }
            }
            if !TokenType.allCases.contains(where: { $0 != .gold && (viewModel.opponent.tokens[$0] ?? 0) > 0 }) {
                Text("\(viewModel.opponent.name) has no tokens to steal!").foregroundColor(PastelPalette.danger)
                Button("Skip") {
                    viewModel.isStealingToken = false
                    viewModel.endTurn()
                }
                .padding().background(PastelPalette.neutralMid).foregroundColor(PastelPalette.textOnDark).cornerRadius(8)
            }
        }
        .padding(30)
        .background(PastelPalette.cream)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: PastelPalette.cardShadow, radius: CardChrome.shadowRadius, x: 0, y: CardChrome.shadowY)
        .overlayCard()
    }

    private var royalOverlay: some View {
        VStack(spacing: 20) {
            Label("Royal Audience", systemImage: "crown.fill")
                .font(.largeTitle).bold()
            Text("You reached a Crown milestone!\nSelect a Royal Card to claim.")
                .multilineTextAlignment(.center)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.availableRoyals) { royal in
                        RoyalCardButton(royal: royal) {
                            withAnimation { viewModel.claimRoyal(royal) }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(30)
        .background(PastelPalette.cream)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: PastelPalette.cardShadow, radius: CardChrome.shadowRadius, x: 0, y: CardChrome.shadowY)
        .overlayCard()
    }

    private var overlapOverlay: some View {
        VStack(spacing: 20) {
            Label("Overlap Bonus", systemImage: "link")
                .font(.title).bold()
            Text("Choose an existing bonus color to copy.").multilineTextAlignment(.center)
            HStack(spacing: 20) {
                ForEach(availableOverlapColors, id: \.self) { color in
                    OverlapColorButton(
                        color: color,
                        bonusCount: viewModel.currentPlayer.bonuses[color] ?? 0
                    ) {
                        withAnimation { viewModel.selectOverlapColor(color: color) }
                    }
                }
            }
            if availableOverlapColors.isEmpty {
                Text("No bonuses to overlap!").foregroundColor(PastelPalette.danger)
                Button("Skip") {
                    viewModel.isSelectingOverlapColor = false
                    viewModel.endTurn()
                }
            }
        }
        .padding(30)
        .background(PastelPalette.cream)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: PastelPalette.cardShadow, radius: CardChrome.shadowRadius, x: 0, y: CardChrome.shadowY)
        .overlayCard()
    }

    private func highlightColor(for color: TokenType) -> Color {
        return color == .white ? PastelPalette.neutralMid.opacity(0.6) : color.color
    }

    private func royalAbilityText(_ ability: CardAbility) -> String {
        switch ability {
        case .privilege: return "Scroll"
        case .stealToken: return "Steal"
        case .playAgain: return "Turn"
        default: return ""
        }
    }

    private func royalAbilityIcon(_ ability: CardAbility) -> String {
        switch ability {
        case .privilege: return "scroll.fill"
        case .stealToken: return "hand.raised.fill"
        case .playAgain: return "arrow.clockwise"
        default: return "circle"
        }
    }
}

// MARK: - Slide-Up Overlay Modifier

extension View {
    /// Wraps any overlay content in a dimmed fullscreen backdrop
    /// and slides the card up from the bottom with a spring.
    func overlayCard() -> some View {
        self.modifier(OverlayCardModifier())
    }
}

struct OverlayCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            PastelPalette.overlayDark
                .ignoresSafeArea()
                .transition(.opacity)
            content
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    )
                )
        }
    }
}

// MARK: - App Root

struct AppRootView: View {
    @State private var viewModel = GameViewModel()
    @State private var isGameStarted: Bool = false

    var body: some View {
        if isGameStarted {
            ContentView(viewModel: viewModel) {
                // FIX: Cleanly disconnect before wiping the ViewModel
                viewModel.prepareForReset()
                viewModel = GameViewModel()
                isGameStarted = false
            }
        } else {
            LobbyView(viewModel: viewModel) {
                withAnimation {
                    isGameStarted = true
                }
            }
        }
    }
}

#Preview {
    AppRootView()
}
