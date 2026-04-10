import SwiftUI

// MARK: - Tokens
enum TokenType: String, Codable, CaseIterable {
    case white, blue, green, red, black, pearl, gold
    
    var color: Color {
        switch self {
        case .white: return PastelPalette.gemWhite
        case .blue: return PastelPalette.gemBlue
        case .green: return PastelPalette.gemGreen
        case .red: return PastelPalette.gemRed
        case .black: return PastelPalette.gemBlack
        case .pearl: return PastelPalette.gemPearl
        case .gold: return PastelPalette.gemGold
        }
    }
}

// MARK: - Abilities
enum CardAbility: Codable, Equatable {
    case playAgain, takeToken, stealToken, privilege, overlap, overlapPlayAgain, none
}


// MARK: - History Log & Time Travel
struct GameSnapshot: Codable {
    let player1: Player
    let player2: Player
    let board: GameBoard
    let isPlayer1Turn: Bool
    let tableCardsLevel1: [Card]
    let tableCardsLevel2: [Card]
    let tableCardsLevel3: [Card]
    let deckLevel1: [Card]
    let deckLevel2: [Card]
    let deckLevel3: [Card]
    let availableRoyals: [RoyalCard]
    let availablePrivileges: Int
    let winnerName: String?
}

struct LogEntry: Identifiable {
    let id = UUID()
    let message: String
    let snapshot: GameSnapshot // NEW: Every log now holds a backup of the game!
}

// MARK: - Cards
struct Card: Identifiable, Codable {
    let id: UUID = UUID()
    let level: Int
    let cost: [TokenType: Int]
    var bonus: TokenType?
    var bonusCount: Int = 1
    let prestigePoints: Int
    let crowns: Int
    let ability: CardAbility
}

struct RoyalCard: Identifiable, Codable {
    let id: UUID = UUID()
    let prestigePoints: Int
    let ability: CardAbility
}

// MARK: - Player
struct Player: Identifiable, Codable {
    let id: UUID = UUID()
    var name: String
    var tokens: [TokenType: Int] = [:]
    var purchasedCards: [Card] = []
    var reservedCards: [Card] = []
    var royalCards: [RoyalCard] = []
    var privileges: Int = 0
    var debugPrestigeBonus: Int = 0
    var debugCrownBonus: Int = 0

    var totalTokenCount: Int { tokens.values.reduce(0, +) }

    var totalCrowns: Int {
        purchasedCards.reduce(0) { $0 + $1.crowns } + debugCrownBonus
    }

    var totalPrestigePoints: Int {
        let cardPoints = purchasedCards.reduce(0) { $0 + $1.prestigePoints }
        let royalPoints = royalCards.reduce(0) { $0 + $1.prestigePoints }
        return cardPoints + royalPoints + debugPrestigeBonus
    }
    
    var bonuses: [TokenType: Int] {
        var counts: [TokenType: Int] = [:]
        for card in purchasedCards {
            if let b = card.bonus {
                // UPDATED: Now we add the bonusCount instead of just +1
                counts[b, default: 0] += card.bonusCount
            }
        }
        return counts
    }
    
    var highestPointsInSingleColor: Int {
        var pointsByColor: [TokenType: Int] = [.white: 0, .blue: 0, .green: 0, .red: 0, .black: 0]
        for card in purchasedCards {
            if let bonusColor = card.bonus {
                pointsByColor[bonusColor, default: 0] += card.prestigePoints
            }
        }
        return pointsByColor.values.max() ?? 0
    }
}

struct GameBoard: Codable { // <-- ADDED Codable
    var grid: [[TokenType?]] = Array(repeating: Array(repeating: nil, count: 5), count: 5)
    var tokenBag: [TokenType] = []
}
