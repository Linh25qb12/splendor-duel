import Foundation

/// Maps each canonical `Card` / `RoyalCard` to an asset in `Assets.xcassets/CardArt` (namespace `CardArt`).
/// Fingerprints match `GameViewModel.generateFullDecks()` definitions.
enum CardArtRegistry {
    private static let namespace = "CardArt"

    static func catalogImageName(for card: Card) -> String {
        let stem = lookup[fingerprint(card)] ?? "t1-black-normal"
        return "\(namespace)/\(stem)"
    }

    private static func fingerprint(_ card: Card) -> String {
        let b = card.bonus?.rawValue ?? "_"
        return "\(card.level)|\(b)|\(card.bonusCount)|\(card.prestigePoints)|\(card.crowns)|\(abilityKey(card.ability))|\(costKey(card.cost))"
    }

    private static func costKey(_ cost: [TokenType: Int]) -> String {
        cost.keys.sorted(by: { $0.rawValue < $1.rawValue })
            .map { "\($0.rawValue):\(cost[$0]!)" }
            .joined(separator: ",")
    }

    private static func abilityKey(_ a: CardAbility) -> String {
        switch a {
        case .none: return "none"
        case .playAgain: return "playAgain"
        case .takeToken: return "takeToken"
        case .stealToken: return "stealToken"
        case .privilege: return "privilege"
        case .overlap: return "overlap"
        case .overlapPlayAgain: return "overlapPlayAgain"
        }
    }

    private static let lookup: [String: String] = [
        "1|black|1|0|0|none|blue:1,green:1,red:1,white:1": "t1-black-normal",
        "1|black|1|0|0|playAgain|blue:2,pearl:1,white:2": "t1-black-turn",
        "1|black|1|0|0|takeToken|green:2,red:2": "t1-black-bonus",
        "1|black|1|1|0|none|blue:2,green:3": "t1-black-point",
        "1|black|1|0|1|none|white:3": "t1-black-crown",
        "1|red|1|0|0|none|black:1,blue:1,green:1,white:1": "t1-red-normal",
        "1|red|1|0|0|playAgain|black:2,pearl:1,white:2": "t1-red-turn",
        "1|red|1|0|0|takeToken|blue:2,green:2": "t1-red-bonus",
        "1|red|1|1|0|none|blue:3,white:2": "t1-red-point",
        "1|red|1|0|1|none|black:3": "t1-red-crown",
        "1|green|1|0|0|none|black:1,blue:1,red:1,white:1": "t1-green-normal",
        "1|green|1|0|0|playAgain|black:2,pearl:1,red:2": "t1-green-turn",
        "1|green|1|0|0|takeToken|blue:2,white:2": "t1-green-bonus",
        "1|green|1|1|0|none|black:2,white:3": "t1-green-point",
        "1|green|1|0|1|none|red:3": "t1-green-crown",
        "1|blue|1|0|0|none|black:1,green:1,red:1,white:1": "t1-blue-normal",
        "1|blue|1|0|0|playAgain|green:2,pearl:1,red:2": "t1-blue-turn",
        "1|blue|1|0|0|takeToken|black:2,white:2": "t1-blue-bonus",
        "1|blue|1|1|0|none|black:3,red:2": "t1-blue-point",
        "1|blue|1|0|1|none|green:3": "t1-blue-crown",
        "1|white|1|0|0|none|black:1,blue:1,green:1,red:1": "t1-white-normal",
        "1|white|1|0|0|playAgain|blue:2,green:2,pearl:1": "t1-white-turn",
        "1|white|1|0|0|takeToken|black:2,red:2": "t1-white-bonus",
        "1|white|1|1|0|none|green:2,red:3": "t1-white-point",
        "1|white|1|0|1|none|blue:3": "t1-white-crown",
        "1|_|0|3|0|none|pearl:1,red:4": "t1-point",
        "1|_|1|1|0|overlap|black:4,pearl:1": "t1-joker-1",
        "1|_|1|0|1|overlap|pearl:1,white:4": "t1-joker-2",
        "1|_|1|1|0|overlap|black:1,green:2,pearl:1,white:2": "t1-joker-3",
        "1|_|1|1|0|overlap|black:1,blue:2,pearl:1,red:2": "t1-joker-4",
        "2|black|1|1|0|stealToken|green:3,white:4": "t2-black-steal",
        "2|black|2|1|0|none|blue:2,white:5": "t2-black-normal",
        "2|black|1|2|1|none|blue:2,green:2,pearl:1,red:2": "t2-black-crown",
        "2|black|1|2|0|privilege|black:4,pearl:1,red:2": "t2-black-privilege",
        "2|red|1|1|0|stealToken|black:4,blue:3": "t2-red-steal",
        "2|red|2|1|0|none|black:5,white:2": "t2-red-normal",
        "2|red|1|2|1|none|blue:2,green:2,pearl:1,white:2": "t2-red-crown",
        "2|red|1|2|0|privilege|green:2,pearl:1,red:4": "t2-red-privilege",
        "2|green|1|1|0|stealToken|red:4,white:3": "t2-green-steal",
        "2|green|2|1|0|none|black:2,red:5": "t2-green-normal",
        "2|green|1|2|1|none|black:2,blue:2,pearl:1,white:2": "t2-green-crown",
        "2|green|1|2|0|privilege|blue:2,green:4,pearl:1": "t2-green-privilege",
        "2|blue|1|1|0|stealToken|black:3,green:4": "t2-blue-steal",
        "2|blue|2|1|0|none|green:5,red:2": "t2-blue-normal",
        "2|blue|1|2|1|none|black:2,pearl:1,red:2,white:2": "t2-blue-crown",
        "2|blue|1|2|0|privilege|blue:4,pearl:1,white:2": "t2-blue-privilege",
        "2|white|1|1|0|stealToken|blue:4,red:3": "t2-white-steal",
        "2|white|2|1|0|none|blue:5,green:2": "t2-white-normal",
        "2|white|1|2|1|none|black:2,green:2,pearl:1,red:2": "t2-white-crown",
        "2|white|1|2|0|privilege|black:2,pearl:1,white:4": "t2-white-privilege",
        "2|_|0|5|0|none|blue:6,pearl:1": "t2-point",
        "2|_|1|2|0|overlap|green:6,pearl:1": "t2-joker-1",
        "2|_|1|0|2|overlap|green:6,pearl:1": "t2-joker-2",
        "2|_|1|0|2|overlap|blue:6,pearl:1": "t2-joker-3",
        "3|black|1|3|2|none|green:5,pearl:1,red:3,white:3": "t3-black-crown",
        "3|black|1|4|0|none|black:6,red:2,white:2": "t3-black-point",
        "3|red|1|3|2|none|black:3,blue:5,green:3,pearl:1": "t3-red-crown",
        "3|red|1|4|0|none|black:2,green:2,red:6": "t3-red-point",
        "3|green|1|3|2|none|blue:3,pearl:1,red:3,white:5": "t3-green-crown",
        "3|green|1|4|0|none|blue:2,green:6,red:2": "t3-green-point",
        "3|blue|1|3|2|none|black:5,green:3,pearl:1,white:3": "t3-blue-crown",
        "3|blue|1|4|0|none|blue:6,green:2,white:2": "t3-blue-point",
        "3|white|1|3|2|none|black:3,blue:3,pearl:1,red:5": "t3-white-crown",
        "3|white|1|4|0|none|black:2,blue:2,white:6": "t3-white-point",
        "3|_|0|6|0|none|white:8": "t3-point",
        "3|_|1|0|3|overlap|black:8": "t3-joker-1",
        "3|_|1|3|0|overlapPlayAgain|red:8": "t3-joker-2"
    ]
}

extension RoyalCard {
    /// Matches order in `GameViewModel.availableRoyals`: crown-1…4.
    var catalogImageName: String {
        switch (prestigePoints, ability) {
        case (2, .privilege): return "CardArt/crown-1"
        case (3, .none): return "CardArt/crown-2"
        case (2, .stealToken): return "CardArt/crown-3"
        case (2, .playAgain): return "CardArt/crown-4"
        default: return "CardArt/crown-1"
        }
    }
}
