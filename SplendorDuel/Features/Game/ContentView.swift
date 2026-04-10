import SwiftUI

// MARK: - Main Game Screen

struct ContentView: View {
    @Bindable var viewModel: GameViewModel
    let onReset: () -> Void

    // Owns the fly animator — passed down via @Environment
    @State private var flyAnimator = CardFlyAnimator()
    @State private var showResetConfirmation = false
    @State private var overlayPeeking = false
    @State private var inspectedCard: Card? = nil
    @State private var isDebugMode = false
    @State private var isDebugCollapsed = true
    @State private var debugPlayerIndex = 0

    var availableOverlapColors: [TokenType] {
        Array(Set(viewModel.currentPlayer.purchasedCards.compactMap { $0.bonus }))
    }

    private var hasActiveOverlay: Bool {
        viewModel.isDiscardingTokens
        || viewModel.isStealingToken
        || viewModel.isSelectingRoyal
        || viewModel.isSelectingOverlapColor
    }

    var body: some View {
        ZStack {
            // Full-bleed table art (GeometryReader is safe-area sized; sizing image from geo
            // leaves the home-indicator strip uncovered).
            Image("table_background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            GeometryReader { geo in
                ZStack {
                    mainGameLayout
                    overlays
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .overlay {
                    flyingCardLayer(geo: geo)
                        .allowsHitTesting(false)
                }
            }
        }
        .environment(flyAnimator)
        .sheet(isPresented: $viewModel.isShowingRules) { RuleBookView() }
        .sheet(isPresented: $viewModel.isShowingHistory) { HistoryView(viewModel: viewModel) }
        .overlay {
            if let card = inspectedCard {
                cardCostOverlay(card: card)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if isDebugMode { debugBar }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: inspectedCard?.id)
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
        GeometryReader { outer in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    dashboardsRow
                    cardPyramidSection
                    royalTokenRow
                    statusMessages
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.vertical, 10)
                .frame(minHeight: outer.size.height)
            }
            .scrollContentBackground(.hidden)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .disabled(!viewModel.isMyTurn || hasActiveOverlay)
        .blur(radius: viewModel.winnerName != nil ? 5 : 0)
    }

    // MARK: - Top: Two dashboards side by side

    private var dashboardsRow: some View {
        HStack(alignment: .top, spacing: 12) {
            PlayerDashboardView(
                player: viewModel.player1,
                isCurrentTurn: viewModel.isPlayer1Turn,
                canAffordCard: { viewModel.canAfford(card: $0) },
                onPurchaseReservedCard: { viewModel.purchaseCard($0) }
            )
            .frame(maxWidth: .infinity)

            PlayerDashboardView(
                player: viewModel.player2,
                isCurrentTurn: !viewModel.isPlayer1Turn,
                canAffordCard: { viewModel.canAfford(card: $0) },
                onPurchaseReservedCard: { viewModel.purchaseCard($0) },
                isTopPlayer: true
            )
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Card Pyramid (full width, auto-scaled to fit)

    private var cardPyramidSection: some View {
        let maxItems: CGFloat = 6
        let spacing: CGFloat = 8
        let naturalW = maxItems * CardChrome.totalWidth + (maxItems - 1) * spacing
        let naturalH = 3 * CardChrome.totalHeight + 2 * 5

         return GeometryReader { geo in
            let scale = min(1.0, geo.size.width / naturalW)
            CardPyramidView(viewModel: viewModel) { card in
                    inspectedCard = card
                }
                .scaleEffect(scale, anchor: .topLeading)
                .frame(width: naturalW, height: naturalH, alignment: .topLeading)
        }
        .aspectRatio(naturalW / naturalH, contentMode: .fit)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Token board (left) + Royal grid 2x2 (right)

    private var royalTokenRow: some View {
        HStack(alignment: .top, spacing: 14) {
            gameControlsLeft
            tokenBagColumn
            BoardView(board: viewModel.board, selectedPositions: viewModel.selectedPositions) { r, c in
                viewModel.handleTokenTap(row: r, col: c)
            }

            let columns = [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ]
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(viewModel.availableRoyals) { royal in
                    royalThumb(royal)
                }
            }
            .frame(maxWidth: 250)

            menuControlsRight
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
    }

    private func royalThumb(_ royal: RoyalCard) -> some View {
        let thumbW: CGFloat = 115
        let thumbH = thumbW * CardChrome.totalHeight / CardChrome.width
        return ZStack(alignment: .bottom) {
            Image(royal.catalogImageName)
                .resizable()
                .scaledToFill()
                .frame(width: thumbW, height: thumbH)
                .clipped()
            VStack(spacing: 2) {
                if royal.ability != .none {
                    Label(royalAbilityText(royal.ability), systemImage: royalAbilityIcon(royal.ability))
                        .font(.system(size: 9, weight: .semibold))
                }
                Label("\(royal.prestigePoints)", systemImage: "star.fill")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.85), radius: 1, x: 0, y: 0)
            .padding(.horizontal, 5)
            .padding(.vertical, 4)
            .background(PastelPalette.chipDark.opacity(0.95), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .padding(.bottom, 4)
        }
        .frame(width: thumbW, height: thumbH)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(PastelPalette.royalStroke, lineWidth: 2)
        )
        .tableLiftCardShadow()
    }

    // MARK: - Status messages (matching token / gold select)

    private var statusMessages: some View {
        Group {
            if viewModel.isTakingMatchingToken, let color = viewModel.matchingTokenColor {
                Text("Ability: Tap a \(color.rawValue.capitalized) token!")
                    .font(.subheadline).bold()
                    .foregroundColor(color == .white ? PastelPalette.textPrimary : PastelPalette.textOnDark)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(highlightColor(for: color))
                    .cornerRadius(8)
            } else if viewModel.isSelectingGoldToken {
                Text("Tap a Gold token to finish!")
                    .font(.headline)
                    .foregroundColor(PastelPalette.textOnDark)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(PastelPalette.warning)
                    .cornerRadius(10)
            } else {
                Color.clear
            }
        }
        .frame(height: 36)
    }

    // MARK: - Token Bag preview

    private static let bagDisplayOrder: [TokenType] = [
        .white, .blue, .green, .red, .black, .pearl, .gold
    ]

    private var tokenBagColumn: some View {
        let counts = Dictionary(
            viewModel.board.tokenBag.map { ($0, 1) },
            uniquingKeysWith: +
        )
        return VStack(spacing: 4) {
            ForEach(Self.bagDisplayOrder, id: \.self) { t in
                let c = counts[t] ?? 0
                ZStack {
                    TokenView(type: t)
                        .frame(width: 54, height: 54)
                        .scaleEffect(0.58)
                        .frame(width: 32, height: 32)
                    Text("\(c)")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(
                            t == .white || t == .gold ? .black : .white
                        )
                        .shadow(color: .black.opacity(0.5), radius: 0.5, y: 0.5)
                }
                .opacity(c > 0 ? 1 : 0.2)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PastelPalette.cardStroke.opacity(0.5), lineWidth: 1)
        )
    }

    // MARK: - Game controls (left of token board): Refill, Privilege, Take

    private var gameControlsLeft: some View {
        VStack(spacing: 10) {
            labelBtn("Fill", icon: "arrow.triangle.2.circlepath", bg: PastelPalette.lily) {
                withAnimation { viewModel.refillBoard() }
            }
            .disabled(viewModel.board.tokenBag.isEmpty)

            labelBtn(
                "Scroll", icon: "scroll.fill",
                bg: viewModel.canUsePrivilege() ? PastelPalette.accentSage : PastelPalette.buyDisabled
            ) {
                withAnimation { viewModel.usePrivilege() }
            }
            .disabled(!viewModel.canUsePrivilege())

            labelBtn(
                "Take", icon: "hand.tap.fill",
                bg: viewModel.isSelectionValid() ? PastelPalette.accentSky : PastelPalette.buyDisabled
            ) {
                withAnimation { viewModel.confirmTokenSelection() }
            }
            .disabled(!viewModel.isSelectionValid())
        }
    }

    // MARK: - Menu controls (right of royal cards): Rules, History, Reset

    private var menuControlsRight: some View {
        VStack(spacing: 10) {
            labelBtn("Rule", icon: "book.closed.fill", bg: PastelPalette.accentSky) {
                viewModel.isShowingRules = true
            }
            labelBtn("Log", icon: "clock.fill", bg: PastelPalette.lavender) {
                viewModel.isShowingHistory = true
            }
            labelBtn("Reset", icon: "arrow.counterclockwise", bg: PastelPalette.accentRose) {
                showResetConfirmation = true
            }
            .alert("Reset Game?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) { onReset() }
            } message: {
                Text("All progress will be lost.")
            }
            labelBtn(
                "Debug", icon: "ladybug.fill",
                bg: isDebugMode ? .orange : .gray
            ) {
                withAnimation(.spring(response: 0.3)) { isDebugMode.toggle() }
            }
            .disabled(viewModel.isMultiplayer)
        }
    }

    private func labelBtn(
        _ title: String, icon: String, bg: Color, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(PastelPalette.buttonLabelOnPastel)
                    .frame(width: 36, height: 36)
                    .background(bg)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.7), radius: 1, y: 1)
            }
        }
    }

    // MARK: - Debug Bar

    private var debugPlayer: Binding<Player> {
        debugPlayerIndex == 0
            ? Binding(get: { viewModel.player1 }, set: { viewModel.player1 = $0 })
            : Binding(get: { viewModel.player2 }, set: { viewModel.player2 = $0 })
    }

    @ViewBuilder
    private var debugBar: some View {
        if isDebugCollapsed {
            Button {
                withAnimation(.spring(response: 0.25)) { isDebugCollapsed = false }
            } label: {
                Label("Debug", systemImage: "ladybug.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.orange, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .shadow(color: .black.opacity(0.3), radius: 6, y: 2)
            }
            .padding(.trailing, 16)
            .padding(.bottom, 20)
            .transition(.scale.combined(with: .opacity))
        } else {
            VStack(spacing: 0) {
                debugHeader
                Divider()
                debugContent
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.orange.opacity(0.5), lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.3), radius: 10, y: -4)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var debugHeader: some View {
        HStack {
            Image(systemName: "ladybug.fill")
                .foregroundStyle(.orange)
                .font(.system(size: 12))
            Text("Debug")
                .font(.system(size: 12, weight: .bold))

            Spacer()

            Picker("Player", selection: $debugPlayerIndex) {
                Text("P1").tag(0)
                Text("P2").tag(1)
            }
            .pickerStyle(.segmented)
            .frame(width: 100)

            Button {
                withAnimation(.spring(response: 0.25)) { isDebugCollapsed = true }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(.quaternary, in: Circle())
            }

            Button {
                withAnimation(.spring(response: 0.25)) {
                    isDebugMode = false
                    isDebugCollapsed = true
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(.quaternary, in: Circle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var debugContent: some View {
        let tokenTypes: [TokenType] = [.white, .blue, .green, .red, .black, .pearl, .gold]
        let cols3 = Array(repeating: GridItem(.flexible()), count: 3)

        return VStack(spacing: 6) {
            LazyVGrid(columns: cols3, spacing: 4) {
                ForEach(tokenTypes, id: \.self) { t in
                    debugTokenRow(t)
                }
            }

            Divider()

            LazyVGrid(columns: cols3, spacing: 4) {
                debugStatRow("star.fill", label: "Pts",
                             value: debugPlayer.wrappedValue.debugPrestigeBonus) { v in
                    debugPlayer.wrappedValue.debugPrestigeBonus = v
                }
                debugStatRow("crown.fill", label: "Crown",
                             value: debugPlayer.wrappedValue.debugCrownBonus) { v in
                    debugPlayer.wrappedValue.debugCrownBonus = v
                }
                debugStatRow("scroll.fill", label: "Scroll",
                             value: debugPlayer.wrappedValue.privileges,
                             maxVal: 3) { v in
                    debugPlayer.wrappedValue.privileges = v
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func debugTokenRow(_ t: TokenType) -> some View {
        let current = debugPlayer.wrappedValue.tokens[t] ?? 0
        return HStack(spacing: 6) {
            Circle().fill(t.color)
                .overlay(Circle().stroke(.black.opacity(0.15), lineWidth: 0.5))
                .frame(width: 16, height: 16)
            Text("\(current)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .frame(width: 20)
            Stepper("", value: Binding(
                get: { debugPlayer.wrappedValue.tokens[t] ?? 0 },
                set: { debugPlayer.wrappedValue.tokens[t] = max(0, min(10, $0)) }
            ), in: 0...10)
            .labelsHidden()
        }
    }

    private func debugStatRow(
        _ icon: String, label: String, value: Int,
        maxVal: Int = 30, onChange: @escaping (Int) -> Void
    ) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .frame(width: 16)
            Text("\(value)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .frame(width: 20)
            Stepper("", value: Binding(
                get: { value },
                set: { onChange(max(0, min(maxVal, $0))) }
            ), in: 0...maxVal)
            .labelsHidden()
        }
    }

    private var overlays: some View {
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

            if hasActiveOverlay && !overlayPeeking {
                if viewModel.isDiscardingTokens { discardOverlay }
                if viewModel.isStealingToken { stealOverlay }
                if viewModel.isSelectingRoyal { royalOverlay }
                if viewModel.isSelectingOverlapColor { overlapOverlay }
            }

            if hasActiveOverlay && overlayPeeking {
                peekResumeButton
            }

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
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: overlayPeeking)
        .onChange(of: hasActiveOverlay) { _, active in
            if !active { overlayPeeking = false }
        }
    }

    private var peekResumeButton: some View {
        VStack {
            Spacer()
            Button(action: { withAnimation { overlayPeeking = false } }) {
                Label("Continue", systemImage: "arrow.up.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(PastelPalette.info, in: Capsule())
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var peekButton: some View {
        Button(action: { withAnimation { overlayPeeking = true } }) {
            Label("View Board", systemImage: "eye")
                .font(.caption).bold()
                .foregroundStyle(PastelPalette.buttonLabelOnPastel)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(PastelPalette.neutralSoft, in: Capsule())
        }
    }

    private var discardOverlay: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                peekButton
            }
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
            HStack {
                Spacer()
                peekButton
            }
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
            HStack {
                Spacer()
                peekButton
            }
            Label("Royal Audience", systemImage: "crown.fill")
                .font(.largeTitle).bold()
            Text("You reached a Crown milestone!\nSelect a Royal Card to claim.")
                .multilineTextAlignment(.center)
            HStack(spacing: 16) {
                ForEach(viewModel.availableRoyals) { royal in
                    RoyalCardButton(royal: royal) {
                        withAnimation { viewModel.claimRoyal(royal) }
                    }
                }
            }
            .padding(12)
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
            HStack {
                Spacer()
                peekButton
            }
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

    // MARK: - Card Cost Breakdown Overlay

    private func cardCostOverlay(card: Card) -> some View {
        let player = viewModel.currentPlayer
        let missing: [(TokenType, Int)] = card.cost.compactMap { token, required in
            let bonus = player.bonuses[token] ?? 0
            let owned = player.tokens[token] ?? 0
            let deficit = max(0, max(0, required - bonus) - owned)
            return deficit > 0 ? (token, deficit) : nil
        }.sorted { $0.0.rawValue < $1.0.rawValue }

        return ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { withAnimation { inspectedCard = nil } }

            Group {
                if missing.isEmpty {
                    Label("Affordable", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                } else {
                    HStack(spacing: 8) {
                        Text("Need")
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.85))
                        ForEach(missing, id: \.0) { token, count in
                            HStack(spacing: 3) {
                                Circle()
                                    .fill(token.color)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                                    .frame(width: 24, height: 24)
                                Text("×\(count)")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .background(Color.black.opacity(0.75), in: Capsule())
            .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        }
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
