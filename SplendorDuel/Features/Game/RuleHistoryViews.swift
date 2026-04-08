import SwiftUI

// MARK: - History View

struct HistoryView: View {
    @Environment(\.dismiss) var dismiss
    var viewModel: GameViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    if viewModel.historyLog.isEmpty {
                        Text("No actions yet. Start playing!")
                            .foregroundColor(PastelPalette.textSecondary)
                            .padding(.top, 60)
                    } else {
                        ForEach(viewModel.historyLog) { entry in
                            HStack {
                                Text(entry.message)
                                    .font(.body)
                                Spacer()
                                Button("Revert Here") {
                                    withAnimation { viewModel.revert(to: entry) }
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                                .font(.caption)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            Divider().padding(.leading, 16)
                        }
                    }
                }
            }
            .navigationTitle("Game History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Close") { dismiss() }
            }
        }
    }
}

// MARK: - Rule Book View

struct RuleBookView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ruleSection(
                        "Win Conditions", icon: "flag.checkered",
                        items: [
                            .text("The game ends **immediately** when a player reaches:"),
                            .label("20 Total Prestige Points", icon: "star.fill"),
                            .label("10 Total Crowns", icon: "crown.fill"),
                            .label("10 Points in a single color", icon: "paintpalette.fill")
                        ]
                    )
                    ruleSection(
                        "Setup", icon: "gamecontroller",
                        items: [
                            .text("• Player 1 starts the game."),
                            .label("Player 2 starts with 1 Privilege Scroll.", icon: "scroll.fill"),
                            .text("• The board is filled in a **Spiral** from the center.")
                        ]
                    )
                    ruleSection(
                        "Optional Actions", icon: "hand.tap",
                        items: [
                            .label("Use Privilege: Spend 1+ scrolls to take 1 non-gold token per scroll.", icon: "scroll.fill"),
                            .text("**Replenish Board:** Fill empty spaces from the bag (Spiral). Opponent **instantly takes 1 Privilege**.")
                        ]
                    )
                    ruleSection(
                        "Mandatory Action (Choose One)", icon: "exclamationmark.circle",
                        items: [
                            .text("**Take Tokens:** Up to 3 adjacent tokens in a line (H/V/D). No Gold."),
                            .label("Taking 3 of a color or 2 Pearls gives opponent 1 Privilege.", icon: "scroll.fill"),
                            .text("**Reserve Card:** Take 1 Gold token + 1 Card (table or deck). Max 3 in hand."),
                            .text("**Purchase Card:** Pay cost minus bonuses. Gold is a Wildcard.")
                        ]
                    )
                    ruleSection(
                        "Card Bonuses", icon: "sparkles",
                        items: [
                            .text("Gems on a card's top-right give a **permanent −1 discount** of that color for all future purchases.")
                        ]
                    )
                    ruleSection(
                        "Special Abilities", icon: "bolt.fill",
                        items: [
                            .label("Play Again: Take another full turn.", icon: "arrow.clockwise.circle.fill"),
                            .label("Privilege: Take 1 scroll.", icon: "scroll.fill"),
                            .label("Thief: Steal 1 Gem/Pearl from opponent.", icon: "hand.raised.fill"),
                            .label("Overlap: Copy a bonus color you already own.", icon: "link"),
                            .label("Take Token: Take 1 matching gem from board.", icon: "plus.circle.fill")
                        ]
                    )
                    ruleSection(
                        "Royal Cards", icon: "crown.fill",
                        items: [
                            .text("Claimed automatically at **3 Crowns** and **6 Crowns**. Does not cost an action.")
                        ]
                    )
                    ruleSection(
                        "Limits", icon: "exclamationmark.triangle",
                        items: [
                            .text("At end of turn, discard down to **10 tokens total**. Discarded tokens return to the bag."),
                            .label("If you need a scroll but none are on board, steal from opponent. Max 3 scrolls.", icon: "scroll.fill")
                        ]
                    )
                }
                .padding(16)
            }
            .navigationTitle("Rulebook")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private enum RuleItem {
        case text(String)
        case label(String, icon: String)
    }

    private func ruleSection(_ title: String, icon: String, items: [RuleItem]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(PastelPalette.textPrimary)
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    switch item {
                    case .text(let s):
                        Text(.init(s)).font(.callout)
                    case .label(let s, let ic):
                        Label(s, systemImage: ic).font(.callout)
                    }
                }
            }
            .padding(.leading, 4)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
