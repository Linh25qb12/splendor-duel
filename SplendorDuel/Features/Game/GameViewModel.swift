import SwiftUI

@Observable
class GameViewModel {
    
    // MARK: - Game State
    var historyLog: [LogEntry] = []
    var isShowingHistory: Bool = false
    var isShowingRules: Bool = false
    
    var multipeerManager = MultipeerManager()
    var isMultiplayer: Bool = false
    
    // FIX 3: myPlayerNumber is now private(set) so only this class can assign it.
    // External code (LobbyView) sets it via the dedicated methods below.
    private(set) var myPlayerNumber: Int = 1
    
    // FIX 4: playerNumberConfirmed gates isMyTurn so a race-condition between
    // connection callback and player-number assignment can't produce a wrong lock.
    private var playerNumberConfirmed: Bool = false
    
    var player1: Player
    var player2: Player
    var availableRoyals: [RoyalCard] = []
    var isSelectingRoyal: Bool = false
    var isPlayer1Turn: Bool = true
    var isSelectingGoldToken: Bool = false
    var isTakingMatchingToken: Bool = false
    var matchingTokenColor: TokenType? = nil
    var getsAnotherTurn: Bool = false
    var isStealingToken: Bool = false
    var winnerName: String? = nil
    var board: GameBoard
    var availablePrivileges: Int = 3
    var tableCardsLevel1: [Card] = []
    var tableCardsLevel2: [Card] = []
    var tableCardsLevel3: [Card] = []
    var deckLevel1: [Card] = []
    var deckLevel2: [Card] = []
    var deckLevel3: [Card] = []
    var selectedPositions: [(row: Int, col: Int)] = []
    var isDiscardingTokens: Bool = false
    var isSelectingOverlapColor: Bool = false
    var pendingOverlapCard: Card? = nil
    
    var tokensToDiscard: Int {
        max(0, currentPlayer.totalTokenCount - 10)
    }

    private var canProcessTurnAction: Bool {
        !isMultiplayer || isMyTurn
    }
    private let audio = AudioManager.shared
    
    // MARK: - Initialization
    init() {
        self.player1 = Player(name: "Player 1")
        self.player2 = Player(name: "Player 2", privileges: 1)
        self.board = GameBoard()
        self.availablePrivileges = 2
        setupGame()
        
        // FIX 5: The closure is bound once here and never needs re-binding,
        // because multipeerManager is a let-equivalent (same instance for the
        // lifetime of this GameViewModel).
        multipeerManager.onDataReceived = { [weak self] data in
            self?.receiveRemoteSnapshot(data: data)
        }
    }
    
    // MARK: - Multiplayer Setup Helpers
    
    /// Call this before startHosting() — sets us as Player 1 with confirmation gate open
    func configureAsHost() {
        myPlayerNumber = 1
        playerNumberConfirmed = true
        isMultiplayer = true
    }
    
    /// Call this before startBrowsing() — sets us as Player 2 with confirmation gate open
    func configureAsGuest() {
        myPlayerNumber = 2
        playerNumberConfirmed = true
        isMultiplayer = true
    }
    
    // MARK: - Computed Properties
    
    var isMyTurn: Bool {
        if !isMultiplayer { return true }
        // FIX 4 cont.: Don't allow interaction until player number is confirmed
        guard playerNumberConfirmed else { return false }
        return (isPlayer1Turn && myPlayerNumber == 1) ||
        (!isPlayer1Turn && myPlayerNumber == 2)
    }
    
    var currentPlayer: Player {
        get { isPlayer1Turn ? player1 : player2 }
        set {
            if isPlayer1Turn { player1 = newValue }
            else { player2 = newValue }
        }
    }
    
    var opponent: Player {
        get { isPlayer1Turn ? player2 : player1 }
        set {
            if isPlayer1Turn { player2 = newValue }
            else { player1 = newValue }
        }
    }
    
    // MARK: - Setup
    private func setupGame() {
        generateFullDecks()
        setupTokenBag()
        initialBoardFill()
    }
    
    // MARK: - History Log
    func logAction(_ message: String) {
        let snapshot = GameSnapshot(
            player1: player1, player2: player2, board: board,
            isPlayer1Turn: isPlayer1Turn,
            tableCardsLevel1: tableCardsLevel1, tableCardsLevel2: tableCardsLevel2, tableCardsLevel3: tableCardsLevel3,
            deckLevel1: deckLevel1, deckLevel2: deckLevel2, deckLevel3: deckLevel3,
            availableRoyals: availableRoyals, availablePrivileges: availablePrivileges,
            winnerName: winnerName
        )
        historyLog.insert(LogEntry(message: message, snapshot: snapshot), at: 0)
    }
    
    func revert(to entry: LogEntry) {
        let snap = entry.snapshot
        player1 = snap.player1
        player2 = snap.player2
        board = snap.board
        isPlayer1Turn = snap.isPlayer1Turn
        tableCardsLevel1 = snap.tableCardsLevel1
        tableCardsLevel2 = snap.tableCardsLevel2
        tableCardsLevel3 = snap.tableCardsLevel3
        deckLevel1 = snap.deckLevel1
        deckLevel2 = snap.deckLevel2
        deckLevel3 = snap.deckLevel3
        availableRoyals = snap.availableRoyals
        availablePrivileges = snap.availablePrivileges
        winnerName = snap.winnerName
        clearTransientState()
        if let index = historyLog.firstIndex(where: { $0.id == entry.id }) {
            historyLog.removeSubrange(0..<index)
        }
        isShowingHistory = false
    }
    
    // MARK: - Networking
    
    func broadcastGameState() {
        guard isMultiplayer, multipeerManager.isConnected else { return }
        let snapshot = GameSnapshot(
            player1: player1, player2: player2, board: board,
            isPlayer1Turn: isPlayer1Turn,
            tableCardsLevel1: tableCardsLevel1, tableCardsLevel2: tableCardsLevel2, tableCardsLevel3: tableCardsLevel3,
            deckLevel1: deckLevel1, deckLevel2: deckLevel2, deckLevel3: deckLevel3,
            availableRoyals: availableRoyals, availablePrivileges: availablePrivileges,
            winnerName: winnerName
        )
        if let encodedData = try? JSONEncoder().encode(snapshot) {
            multipeerManager.send(data: encodedData)
        }
    }
    
    private func receiveRemoteSnapshot(data: Data) {
        guard let snap = try? JSONDecoder().decode(GameSnapshot.self, from: data) else { return }
        player1 = snap.player1
        player2 = snap.player2
        board = snap.board
        isPlayer1Turn = snap.isPlayer1Turn
        tableCardsLevel1 = snap.tableCardsLevel1
        tableCardsLevel2 = snap.tableCardsLevel2
        tableCardsLevel3 = snap.tableCardsLevel3
        deckLevel1 = snap.deckLevel1
        deckLevel2 = snap.deckLevel2
        deckLevel3 = snap.deckLevel3
        availableRoyals = snap.availableRoyals
        availablePrivileges = snap.availablePrivileges
        winnerName = snap.winnerName
        clearTransientState()
    }
    
    // FIX 1 (ViewModel side): Called by AppRootView's onReset closure
    // before creating a new GameViewModel, so the old session is cleanly closed.
    func prepareForReset() {
        multipeerManager.disconnect()
    }
    
    // MARK: - Token Actions
    
    func takeTokens(at positions: [(row: Int, col: Int)]) {
        guard canProcessTurnAction else { return }
        guard isValidTokenSelection(positions) else { return }
        for pos in positions {
            if let token = board.grid[pos.row][pos.col] {
                currentPlayer.tokens[token, default: 0] += 1
                board.grid[pos.row][pos.col] = nil
            }
        }
        endTurn()
    }
    
    func handleTokenTap(row: Int, col: Int) {
        guard canProcessTurnAction else { return }
        if isTakingMatchingToken {
            if let token = board.grid[row][col], token == matchingTokenColor {
                audio.playSFX(.gemPick)
                currentPlayer.tokens[token, default: 0] += 1
                board.grid[row][col] = nil
                isTakingMatchingToken = false
                matchingTokenColor = nil
                endTurn()
            }
            return
        }
        
        if isSelectingGoldToken {
            if let token = board.grid[row][col], token == .gold {
                audio.playSFX(.gemPick)
                currentPlayer.tokens[.gold, default: 0] += 1
                board.grid[row][col] = nil
                isSelectingGoldToken = false
                endTurn()
            }
            return
        }
        
        if let index = selectedPositions.firstIndex(where: { $0.row == row && $0.col == col }) {
            selectedPositions.remove(at: index)
            audio.playSFX(.gemDrop)
            return
        }
        
        guard let token = board.grid[row][col], token != .gold else { return }
        guard selectedPositions.count < 3 else { return }
        selectedPositions.append((row, col))
        audio.playSFX(.gemPick)
    }
    
    func isSelectionValid() -> Bool {
        let count = selectedPositions.count
        guard count > 0 && count <= 3 else { return false }
        if count == 1 { return true }
        let sorted = selectedPositions.sorted {
            if $0.row == $1.row { return $0.col < $1.col }
            return $0.row < $1.row
        }
        let p1 = sorted[0], p2 = sorted[1]
        let dr = p2.row - p1.row, dc = p2.col - p1.col
        if abs(dr) > 1 || abs(dc) > 1 { return false }
        if count == 2 { return true }
        let p3 = sorted[2]
        return (p3.row - p2.row == dr) && (p3.col - p2.col == dc)
    }
    
    func confirmTokenSelection() {
        guard canProcessTurnAction else { return }
        guard isSelectionValid() else { return }
        var takenTokens: [TokenType] = []
        for pos in selectedPositions {
            if let token = board.grid[pos.row][pos.col] {
                currentPlayer.tokens[token, default: 0] += 1
                takenTokens.append(token)
                board.grid[pos.row][pos.col] = nil
            }
        }
        let pearlsTaken = takenTokens.filter { $0 == .pearl }.count
        let counts = Dictionary(grouping: takenTokens, by: { $0 }).mapValues { $0.count }
        let hasThreeIdentical = counts.values.contains(3)
        if hasThreeIdentical || pearlsTaken == 2 {
            if availablePrivileges > 0 {
                availablePrivileges -= 1
                opponent.privileges += 1
            } else if currentPlayer.privileges > 0 {
                currentPlayer.privileges -= 1
                opponent.privileges += 1
            }
        }
        selectedPositions.removeAll()
        audio.playSFX(.gemPick)
        logAction("\(currentPlayer.name) took \(takenTokens.count) token(s).")
        endTurn()
    }
    
    // MARK: - Privilege
    
    func canUsePrivilege() -> Bool {
        guard currentPlayer.privileges > 0 else { return false }
        guard selectedPositions.count == 1 else { return false }
        let pos = selectedPositions[0]
        guard let token = board.grid[pos.row][pos.col], token != .gold else { return false }
        return true
    }
    
    func usePrivilege() {
        guard canProcessTurnAction else { return }
        guard canUsePrivilege() else { return }
        let pos = selectedPositions[0]
        if let token = board.grid[pos.row][pos.col] {
            currentPlayer.tokens[token, default: 0] += 1
            board.grid[pos.row][pos.col] = nil
        }
        currentPlayer.privileges -= 1
        availablePrivileges += 1
        selectedPositions.removeAll()
        audio.playSFX(.privilegeUse)
        logAction("\(currentPlayer.name) used a Privilege Scroll.")
        // FIX 6: Broadcast AFTER usePrivilege so opponent immediately sees the
        // token leave the board. Previously this was called here explicitly but
        // endTurn() wasn't, so the snapshot was stale mid-turn.
        broadcastGameState()
    }
    
    // MARK: - Reserve
    
    func canReserveAny() -> Bool {
        guard !isSelectingGoldToken else { return false }
        let hasRoom = currentPlayer.reservedCards.count < 3
        let goldExists = board.grid.joined().contains(.gold)
        return hasRoom && goldExists
    }
    
    func canReserve(card: Card) -> Bool {
        return canReserveAny()
    }
    
    func reserveCard(_ card: Card) {
        guard canProcessTurnAction else { return }
        guard canReserve(card: card) else { return }
        audio.playSFX(.reserveCard)
        currentPlayer.reservedCards.append(card)
        if let index = tableCardsLevel1.firstIndex(where: { $0.id == card.id }) {
            tableCardsLevel1.remove(at: index)
        } else if let index = tableCardsLevel2.firstIndex(where: { $0.id == card.id }) {
            tableCardsLevel2.remove(at: index)
        } else if let index = tableCardsLevel3.firstIndex(where: { $0.id == card.id }) {
            tableCardsLevel3.remove(at: index)
        }
        replenishTable(forLevel: card.level)
        selectedPositions.removeAll()
        isSelectingGoldToken = true
    }
    
    func reserveCardFromDeck(level: Int) {
        guard canProcessTurnAction else { return }
        guard canReserveAny() else { return }
        var drawnCard: Card? = nil
        switch level {
        case 1: drawnCard = deckLevel1.popLast()
        case 2: drawnCard = deckLevel2.popLast()
        case 3: drawnCard = deckLevel3.popLast()
        default: break
        }
        guard let card = drawnCard else { return }
        audio.playSFX(.reserveCard)
        currentPlayer.reservedCards.append(card)
        selectedPositions.removeAll()
        isSelectingGoldToken = true
    }
    
    // MARK: - Purchase
    
    func canAfford(card: Card) -> Bool {
        guard !isSelectingGoldToken else { return false }
        var totalMissingTokens = 0
        for (tokenType, costAmount) in card.cost {
            let playerTokens = currentPlayer.tokens[tokenType] ?? 0
            let playerBonus = currentPlayer.bonuses[tokenType] ?? 0
            let deficit = costAmount - (playerTokens + playerBonus)
            if deficit > 0 { totalMissingTokens += deficit }
        }
        let playerGold = currentPlayer.tokens[.gold] ?? 0
        return playerGold >= totalMissingTokens
    }
    
    func purchaseCard(_ card: Card) {
        guard canProcessTurnAction else { return }
        guard canAfford(card: card) else { return }
        audio.playSFX(.buyCard)
        for (tokenType, costAmount) in card.cost {
            let playerBonus = currentPlayer.bonuses[tokenType] ?? 0
            var remainingCost = max(0, costAmount - playerBonus)
            while remainingCost > 0 {
                if let available = currentPlayer.tokens[tokenType], available > 0 {
                    currentPlayer.tokens[tokenType]! -= 1
                    board.tokenBag.append(tokenType)
                } else {
                    currentPlayer.tokens[.gold]! -= 1
                    board.tokenBag.append(.gold)
                }
                remainingCost -= 1
            }
        }
        board.tokenBag.shuffle()
        currentPlayer.purchasedCards.append(card)
        let colorName = card.bonus?.rawValue.capitalized ?? "Neutral"
        logAction("\(currentPlayer.name) bought a Level \(card.level) \(colorName) card.")
        var wasOnTable = false
        if let index = tableCardsLevel1.firstIndex(where: { $0.id == card.id }) {
            tableCardsLevel1.remove(at: index); wasOnTable = true
        } else if let index = tableCardsLevel2.firstIndex(where: { $0.id == card.id }) {
            tableCardsLevel2.remove(at: index); wasOnTable = true
        } else if let index = tableCardsLevel3.firstIndex(where: { $0.id == card.id }) {
            tableCardsLevel3.remove(at: index); wasOnTable = true
        } else {
            currentPlayer.reservedCards.removeAll { $0.id == card.id }
        }
        if wasOnTable { replenishTable(forLevel: card.level) }
        handleCardAbility(card.ability, for: card)
    }
    
    // MARK: - Board
    
    private let refillPath: [(row: Int, col: Int)] = [
        (2,2),(2,1),(1,1),(1,2),(1,3),(2,3),(3,3),(3,2),(3,1),
        (4,1),(4,2),(4,3),(4,4),(3,4),(2,4),(1,4),(0,4),(0,3),
        (0,2),(0,1),(0,0),(1,0),(2,0),(3,0),(4,0)
    ]
    
    func setupTokenBag() {
        var initialBag: [TokenType] = []
        let standardColors: [TokenType] = [.white, .blue, .green, .red, .black]
        for color in standardColors { initialBag.append(contentsOf: Array(repeating: color, count: 4)) }
        initialBag.append(contentsOf: [.pearl, .pearl, .gold, .gold, .gold])
        board.tokenBag = initialBag.shuffled()
    }
    
    func initialBoardFill() {
        for pos in refillPath {
            if board.grid[pos.row][pos.col] == nil {
                if let nextToken = board.tokenBag.popLast() {
                    board.grid[pos.row][pos.col] = nextToken
                }
            }
        }
    }
    
    func refillBoard() {
        guard canProcessTurnAction else { return }
        audio.playSFX(.refill)
        logAction("\(currentPlayer.name) refilled the board.")
        if availablePrivileges > 0 {
            availablePrivileges -= 1
            opponent.privileges += 1
        }
        for pos in refillPath {
            if board.grid[pos.row][pos.col] == nil {
                if let nextToken = board.tokenBag.popLast() {
                    board.grid[pos.row][pos.col] = nextToken
                }
            }
        }
    }
    
    private func replenishTable(forLevel level: Int) {
        if level == 1 {
            if let c = deckLevel1.popLast() { tableCardsLevel1.append(c) }
        } else if level == 2 {
            if let c = deckLevel2.popLast() { tableCardsLevel2.append(c) }
        } else if level == 3 {
            if let c = deckLevel3.popLast() { tableCardsLevel3.append(c) }
        }
    }
    
    // MARK: - Turn End
    
    func endTurn() {
        if currentPlayer.totalTokenCount > 10 {
            isDiscardingTokens = true
            return
        }
        let crowns = currentPlayer.totalCrowns
        let royalsCount = currentPlayer.royalCards.count
        if (crowns >= 3 && royalsCount == 0) || (crowns >= 6 && royalsCount == 1) {
            isSelectingRoyal = true
            return
        }
        checkWinCondition()
        if winnerName == nil {
            if getsAnotherTurn {
                getsAnotherTurn = false
            } else {
                isPlayer1Turn.toggle()
                audio.playSFX(.turnChange)
            }
        }
        broadcastGameState()
    }
    
    // MARK: - Discard
    
    func discardToken(_ token: TokenType) {
        guard canProcessTurnAction else { return }
        guard isDiscardingTokens else { return }
        guard let count = currentPlayer.tokens[token], count > 0 else { return }
        audio.playSFX(.gemDrop)
        currentPlayer.tokens[token]! -= 1
        board.tokenBag.append(token)
        board.tokenBag.shuffle()
        if currentPlayer.totalTokenCount <= 10 {
            isDiscardingTokens = false
            endTurn()
        }
    }
    
    // MARK: - Abilities
    
    private func handleCardAbility(_ ability: CardAbility, for card: Card?) {
        switch ability {
        case .overlapPlayAgain:
            getsAnotherTurn = true
            if let card = card, !currentPlayer.purchasedCards.filter({ $0.bonus != nil }).isEmpty {
                pendingOverlapCard = card
                isSelectingOverlapColor = true
                return
            }
            endTurn()
        case .overlap:
            if let card = card, !currentPlayer.purchasedCards.filter({ $0.bonus != nil }).isEmpty {
                pendingOverlapCard = card
                isSelectingOverlapColor = true
                return
            }
            endTurn()
        case .playAgain:
            getsAnotherTurn = true
            endTurn()
        case .privilege:
            if availablePrivileges > 0 {
                availablePrivileges -= 1
                currentPlayer.privileges += 1
            } else if opponent.privileges > 0 {
                opponent.privileges -= 1
                currentPlayer.privileges += 1
            }
            endTurn()
        case .stealToken:
            isStealingToken = true
        case .takeToken:
            if let color = card?.bonus {
                let boardHasColor = board.grid.joined().contains(color)
                if boardHasColor {
                    matchingTokenColor = color
                    isTakingMatchingToken = true
                    selectedPositions.removeAll()
                    return
                }
            }
            endTurn()
        case .none:
            endTurn()
        }
    }
    
    func executeSteal(token: TokenType) {
        guard canProcessTurnAction else { return }
        guard isStealingToken else { return }
        guard let count = opponent.tokens[token], count > 0 else { return }
        audio.playSFX(.gemPick)
        opponent.tokens[token]! -= 1
        currentPlayer.tokens[token, default: 0] += 1
        isStealingToken = false
        endTurn()
    }
    
    func selectOverlapColor(color: TokenType) {
        guard canProcessTurnAction else { return }
        if let index = currentPlayer.purchasedCards.firstIndex(where: { $0.id == pendingOverlapCard?.id }) {
            currentPlayer.purchasedCards[index].bonus = color
        }
        isSelectingOverlapColor = false
        pendingOverlapCard = nil
        endTurn()
    }
    
    // MARK: - Royals
    
    func claimRoyal(_ card: RoyalCard) {
        guard canProcessTurnAction else { return }
        guard isSelectingRoyal else { return }
        audio.playSFX(.royalAchieve)
        currentPlayer.royalCards.append(card)
        availableRoyals.removeAll { $0.id == card.id }
        isSelectingRoyal = false
        handleCardAbility(card.ability, for: nil)
    }
    
    // MARK: - Win Condition
    
    private func checkWinCondition() {
        let alreadyHadWinner = winnerName != nil
        if currentPlayer.totalPrestigePoints >= 20 ||
            currentPlayer.totalCrowns >= 10 ||
            currentPlayer.highestPointsInSingleColor >= 10 {
            winnerName = currentPlayer.name
            if !alreadyHadWinner {
                audio.playSFX(.gameEnd)
            }
        }
    }
    
    // MARK: - Helpers
    
    // Clears all transient UI state — used by revert and receiveRemoteSnapshot
    private func clearTransientState() {
        isDiscardingTokens = false
        isStealingToken = false
        isSelectingRoyal = false
        isSelectingOverlapColor = false
        isTakingMatchingToken = false
        isSelectingGoldToken = false
        selectedPositions.removeAll()
    }
    
    private func isValidTokenSelection(_ positions: [(row: Int, col: Int)]) -> Bool {
        return true
    }
    
    // MARK: - Deck Generation
    
    func generateFullDecks() {
        deckLevel1 = [
            Card(level: 1, cost: [.red: 1, .green: 1, .blue: 1, .white: 1], bonus: .black, bonusCount: 1, prestigePoints: 0, crowns: 0, ability: .none),
            Card(level: 1, cost: [.pearl: 1, .blue: 2, .white: 2], bonus: .black, bonusCount: 1, prestigePoints: 0, crowns: 0, ability: .playAgain),
            Card(level: 1, cost: [.red: 2, .green: 2], bonus: .black, bonusCount: 1, prestigePoints: 0, crowns: 0, ability: .takeToken),
            Card(level: 1, cost: [.green: 3, .blue: 2], bonus: .black, bonusCount: 1, prestigePoints: 1, crowns: 0, ability: .none),
            Card(level: 1, cost: [.white: 3], bonus: .black, bonusCount: 1, prestigePoints: 0, crowns: 1, ability: .none),
            Card(level: 1, cost: [.black: 1, .green: 1, .blue: 1, .white: 1], bonus: .red, bonusCount: 1, prestigePoints: 0, crowns: 0, ability: .none),
            Card(level: 1, cost: [.pearl: 1, .black: 2, .white: 2], bonus: .red, bonusCount: 1, prestigePoints: 0, crowns: 0, ability: .playAgain),
            Card(level: 1, cost: [.green: 2, .blue: 2], bonus: .red, bonusCount: 1, prestigePoints: 0, crowns: 0, ability: .takeToken),
            Card(level: 1, cost: [.blue: 3, .white: 2], bonus: .red, bonusCount: 1, prestigePoints: 1, crowns: 0, ability: .none),
            Card(level: 1, cost: [.black: 3], bonus: .red, bonusCount: 1, prestigePoints: 0, crowns: 1, ability: .none),
            Card(level: 1, cost: [.black: 1, .red: 1, .blue: 1, .white: 1], bonus: .green, bonusCount: 1, prestigePoints: 0, crowns: 0, ability: .none),
            Card(level: 1, cost: [.pearl: 1, .black: 2, .red: 2], bonus: .green, bonusCount: 1, prestigePoints: 0, crowns: 0, ability: .playAgain),
            Card(level: 1, cost: [.blue: 2, .white: 2], bonus: .green, bonusCount: 1, prestigePoints: 0, crowns: 0, ability: .takeToken),
            Card(level: 1, cost: [.black: 2, .white: 3], bonus: .green, bonusCount: 1, prestigePoints: 1, crowns: 0, ability: .none),
            Card(level: 1, cost: [.red: 3], bonus: .green, bonusCount: 1, prestigePoints: 0, crowns: 1, ability: .none),
            Card(level: 1, cost: [.black: 1, .red: 1, .green: 1, .white: 1], bonus: .blue, bonusCount: 1, prestigePoints: 0, crowns: 0, ability: .none),
            Card(level: 1, cost: [.pearl: 1, .red: 2, .green: 2], bonus: .blue, bonusCount: 1, prestigePoints: 0, crowns: 0, ability: .playAgain),
            Card(level: 1, cost: [.black: 2, .white: 2], bonus: .blue, bonusCount: 1, prestigePoints: 0, crowns: 0, ability: .takeToken),
            Card(level: 1, cost: [.black: 3, .red: 2], bonus: .blue, bonusCount: 1, prestigePoints: 1, crowns: 0, ability: .none),
            Card(level: 1, cost: [.green: 3], bonus: .blue, bonusCount: 1, prestigePoints: 0, crowns: 1, ability: .none),
            Card(level: 1, cost: [.black: 1, .red: 1, .green: 1, .blue: 1], bonus: .white, bonusCount: 1, prestigePoints: 0, crowns: 0, ability: .none),
            Card(level: 1, cost: [.pearl: 1, .green: 2, .blue: 2], bonus: .white, bonusCount: 1, prestigePoints: 0, crowns: 0, ability: .playAgain),
            Card(level: 1, cost: [.black: 2, .red: 2], bonus: .white, bonusCount: 1, prestigePoints: 0, crowns: 0, ability: .takeToken),
            Card(level: 1, cost: [.red: 3, .green: 2], bonus: .white, bonusCount: 1, prestigePoints: 1, crowns: 0, ability: .none),
            Card(level: 1, cost: [.blue: 3], bonus: .white, bonusCount: 1, prestigePoints: 0, crowns: 1, ability: .none),
            Card(level: 1, cost: [.pearl: 1, .red: 4], bonus: nil, bonusCount: 0, prestigePoints: 3, crowns: 0, ability: .none),
            Card(level: 1, cost: [.pearl: 1, .black: 4], bonus: nil, bonusCount: 1, prestigePoints: 1, crowns: 0, ability: .overlap),
            Card(level: 1, cost: [.pearl: 1, .white: 4], bonus: nil, bonusCount: 1, prestigePoints: 0, crowns: 1, ability: .overlap),
            Card(level: 1, cost: [.pearl: 1, .black: 1, .green: 2, .white: 2], bonus: nil, bonusCount: 1, prestigePoints: 1, crowns: 0, ability: .overlap),
            Card(level: 1, cost: [.pearl: 1, .black: 1, .red: 2, .blue: 2], bonus: nil, bonusCount: 1, prestigePoints: 1, crowns: 0, ability: .overlap)
        ].shuffled()
        
        deckLevel2 = [
            Card(level: 2, cost: [.green: 3, .white: 4], bonus: .black, bonusCount: 1, prestigePoints: 1, crowns: 0, ability: .stealToken),
            Card(level: 2, cost: [.blue: 2, .white: 5], bonus: .black, bonusCount: 2, prestigePoints: 1, crowns: 0, ability: .none),
            Card(level: 2, cost: [.pearl: 1, .red: 2, .green: 2, .blue: 2], bonus: .black, bonusCount: 1, prestigePoints: 2, crowns: 1, ability: .none),
            Card(level: 2, cost: [.pearl: 1, .black: 4, .red: 2], bonus: .black, bonusCount: 1, prestigePoints: 2, crowns: 0, ability: .privilege),
            Card(level: 2, cost: [.black: 4, .blue: 3], bonus: .red, bonusCount: 1, prestigePoints: 1, crowns: 0, ability: .stealToken),
            Card(level: 2, cost: [.black: 5, .white: 2], bonus: .red, bonusCount: 2, prestigePoints: 1, crowns: 0, ability: .none),
            Card(level: 2, cost: [.pearl: 1, .green: 2, .blue: 2, .white: 2], bonus: .red, bonusCount: 1, prestigePoints: 2, crowns: 1, ability: .none),
            Card(level: 2, cost: [.pearl: 1, .red: 4, .green: 2], bonus: .red, bonusCount: 1, prestigePoints: 2, crowns: 0, ability: .privilege),
            Card(level: 2, cost: [.red: 4, .white: 3], bonus: .green, bonusCount: 1, prestigePoints: 1, crowns: 0, ability: .stealToken),
            Card(level: 2, cost: [.black: 2, .red: 5], bonus: .green, bonusCount: 2, prestigePoints: 1, crowns: 0, ability: .none),
            Card(level: 2, cost: [.pearl: 1, .black: 2, .blue: 2, .white: 2], bonus: .green, bonusCount: 1, prestigePoints: 2, crowns: 1, ability: .none),
            Card(level: 2, cost: [.pearl: 1, .green: 4, .blue: 2], bonus: .green, bonusCount: 1, prestigePoints: 2, crowns: 0, ability: .privilege),
            Card(level: 2, cost: [.black: 3, .green: 4], bonus: .blue, bonusCount: 1, prestigePoints: 1, crowns: 0, ability: .stealToken),
            Card(level: 2, cost: [.red: 2, .green: 5], bonus: .blue, bonusCount: 2, prestigePoints: 1, crowns: 0, ability: .none),
            Card(level: 2, cost: [.pearl: 1, .black: 2, .red: 2, .white: 2], bonus: .blue, bonusCount: 1, prestigePoints: 2, crowns: 1, ability: .none),
            Card(level: 2, cost: [.pearl: 1, .blue: 4, .white: 2], bonus: .blue, bonusCount: 1, prestigePoints: 2, crowns: 0, ability: .privilege),
            Card(level: 2, cost: [.red: 3, .blue: 4], bonus: .white, bonusCount: 1, prestigePoints: 1, crowns: 0, ability: .stealToken),
            Card(level: 2, cost: [.green: 2, .blue: 5], bonus: .white, bonusCount: 2, prestigePoints: 1, crowns: 0, ability: .none),
            Card(level: 2, cost: [.pearl: 1, .black: 2, .red: 2, .green: 2], bonus: .white, bonusCount: 1, prestigePoints: 2, crowns: 1, ability: .none),
            Card(level: 2, cost: [.pearl: 1, .black: 2, .white: 4], bonus: .white, bonusCount: 1, prestigePoints: 2, crowns: 0, ability: .privilege),
            Card(level: 2, cost: [.pearl: 1, .blue: 6], bonus: nil, bonusCount: 0, prestigePoints: 5, crowns: 0, ability: .none),
            Card(level: 2, cost: [.pearl: 1, .green: 6], bonus: nil, bonusCount: 1, prestigePoints: 2, crowns: 0, ability: .overlap),
            Card(level: 2, cost: [.pearl: 1, .green: 6], bonus: nil, bonusCount: 1, prestigePoints: 0, crowns: 2, ability: .overlap),
            Card(level: 2, cost: [.pearl: 1, .blue: 6], bonus: nil, bonusCount: 1, prestigePoints: 0, crowns: 2, ability: .overlap)
        ].shuffled()
        
        deckLevel3 = [
            Card(level: 3, cost: [.pearl: 1, .red: 3, .green: 5, .white: 3], bonus: .black, bonusCount: 1, prestigePoints: 3, crowns: 2, ability: .none),
            Card(level: 3, cost: [.black: 6, .red: 2, .white: 2], bonus: .black, bonusCount: 1, prestigePoints: 4, crowns: 0, ability: .none),
            Card(level: 3, cost: [.pearl: 1, .black: 3, .green: 3, .blue: 5], bonus: .red, bonusCount: 1, prestigePoints: 3, crowns: 2, ability: .none),
            Card(level: 3, cost: [.black: 2, .red: 6, .green: 2], bonus: .red, bonusCount: 1, prestigePoints: 4, crowns: 0, ability: .none),
            Card(level: 3, cost: [.pearl: 1, .red: 3, .blue: 3, .white: 5], bonus: .green, bonusCount: 1, prestigePoints: 3, crowns: 2, ability: .none),
            Card(level: 3, cost: [.red: 2, .green: 6, .blue: 2], bonus: .green, bonusCount: 1, prestigePoints: 4, crowns: 0, ability: .none),
            Card(level: 3, cost: [.pearl: 1, .black: 5, .green: 3, .white: 3], bonus: .blue, bonusCount: 1, prestigePoints: 3, crowns: 2, ability: .none),
            Card(level: 3, cost: [.green: 2, .blue: 6, .white: 2], bonus: .blue, bonusCount: 1, prestigePoints: 4, crowns: 0, ability: .none),
            Card(level: 3, cost: [.pearl: 1, .black: 3, .red: 5, .blue: 3], bonus: .white, bonusCount: 1, prestigePoints: 3, crowns: 2, ability: .none),
            Card(level: 3, cost: [.black: 2, .blue: 2, .white: 6], bonus: .white, bonusCount: 1, prestigePoints: 4, crowns: 0, ability: .none),
            Card(level: 3, cost: [.white: 8], bonus: nil, bonusCount: 0, prestigePoints: 6, crowns: 0, ability: .none),
            Card(level: 3, cost: [.black: 8], bonus: nil, bonusCount: 1, prestigePoints: 0, crowns: 3, ability: .overlap),
            Card(level: 3, cost: [.red: 8], bonus: nil, bonusCount: 1, prestigePoints: 3, crowns: 0, ability: .overlapPlayAgain)
        ].shuffled()
        
        availableRoyals = [
            RoyalCard(prestigePoints: 2, ability: .privilege),
            RoyalCard(prestigePoints: 3, ability: .none),
            RoyalCard(prestigePoints: 2, ability: .stealToken),
            RoyalCard(prestigePoints: 2, ability: .playAgain)
        ]
        
        for _ in 0..<5 { if let c = deckLevel1.popLast() { tableCardsLevel1.append(c) } }
        for _ in 0..<4 { if let c = deckLevel2.popLast() { tableCardsLevel2.append(c) } }
        for _ in 0..<3 { if let c = deckLevel3.popLast() { tableCardsLevel3.append(c) } }
    }
}
