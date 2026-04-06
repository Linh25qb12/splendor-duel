import SwiftUI

// MARK: - History View

struct HistoryView: View {
    @Environment(\.dismiss) var dismiss
    var viewModel: GameViewModel

    var body: some View {
        NavigationStack {
            List(viewModel.historyLog) { entry in
                HStack {
                    Text(entry.message)
                        .font(.body)
                        .padding(.vertical, 4)

                    Spacer()

                    Button("Revert Here") {
                        withAnimation {
                            viewModel.revert(to: entry)
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .font(.caption)
                }
            }
            .navigationTitle("Game History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Close") { dismiss() }
            }
            .overlay {
                if viewModel.historyLog.isEmpty {
                    Text("No actions yet. Start playing!")
                        .foregroundColor(PastelPalette.textSecondary)
                }
            }
        }
    }
}

// MARK: - Rule Book View

struct RuleBookView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            TabView {
                // PAGE 1: OBJECTIVE & SETUP
                List {
                    Section("The Three Ways to Win") {
                        Text("The game ends **immediately** when a player reaches:")
                        Label("20 Total Prestige Points", systemImage: "star.fill")
                        Label("10 Total Crowns", systemImage: "crown.fill")
                        Label("10 Points in a single color", systemImage: "paintpalette.fill")
                    }
                    Section("Setup") {
                        Text("• Player 1 starts the game.")
                        Label("Player 2 starts with 1 Privilege Scroll.", systemImage: "scroll.fill")
                        Text("• The board is filled in a **Spiral** starting from the center.")
                    }
                }
                .tabItem { Label("Goal", systemImage: "flag.checkered") }

                // PAGE 2: ACTIONS
                List {
                    Section("Optional Actions (Before Mandatory)") {
                        Label("Use Privilege: Spend 1+ scrolls to take 1 non-gold token from the board for each scroll spent.", systemImage: "scroll.fill")
                        Text("**2. Replenish Board:** Fill empty spaces from the bag (Spiral). Your opponent **instantly takes 1 Privilege**.")
                    }
                    Section("The Mandatory Action (Choose One)") {
                        Text("**Take Tokens:** Take up to 3 adjacent tokens in a line (Horiz/Vert/Diag). No Gold.")
                        Label("Rule: Taking 3 of a color or 2 Pearls gives opponent 1 Privilege.", systemImage: "scroll.fill")
                        Divider()
                        Text("**Reserve Card:** Take 1 Gold token + 1 Card (from table or deck). Max 3 in hand.")
                        Divider()
                        Text("**Purchase Card:** Pay the cost minus your bonuses. Gold is a Wildcard.")
                    }
                }
                .tabItem { Label("Actions", systemImage: "hand.tap") }

                // PAGE 3: ABILITIES & BONUSES
                List {
                    Section("Card Bonuses") {
                        Text("Gems on the top right of cards provide a **permanent discount** of 1 token of that color for all future purchases.")
                    }
                    Section("Special Icons") {
                        Label("Play Again: Take another full turn.", systemImage: "arrow.clockwise")
                        Label("Privilege: Take 1 scroll from board (or opponent).", systemImage: "scroll.fill")
                        Label("Thief: Steal 1 Gem/Pearl from opponent.", systemImage: "person.badge.minus")
                        Label("Overlap: Copy a bonus color you already own.", systemImage: "link")
                        Label("Take Token: Take 1 matching gem from board.", systemImage: "plus.circle")
                    }
                    Section("Royal Cards") {
                        Text("Claimed automatically at **3 Crowns** and **6 Crowns**. These do not cost an action.")
                    }
                }
                .tabItem { Label("Abilities", systemImage: "sparkles") }

                // PAGE 4: LIMITS
                List {
                    Section("The 10-Token Limit") {
                        Text("At the end of your turn, you must discard down to **10 tokens total**.")
                        Text("Discarded tokens go back into the bag.")
                    }
                    Section("Privilege Limit") {
                        Label("If you need to take a scroll but none are on the board, steal one from your opponent.", systemImage: "scroll.fill")
                        Text("If you already have all 3, nothing happens.")
                    }
                }
                .tabItem { Label("Limits", systemImage: "exclamationmark.triangle") }
            }
            .navigationTitle("Official Rulebook")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
