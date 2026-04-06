import SwiftUI
import UIKit

// MARK: - Host Waiting Screen

struct HostWaitingView: View {
    let deviceName: String
    let onCancel: () -> Void

    @State private var dotCount: Int = 0
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    private var dots: String { String(repeating: ".", count: dotCount + 1) }

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            ZStack {
                Circle()
                    .fill(PastelPalette.accentSage.opacity(0.35))
                    .frame(width: 120, height: 120)
                Circle()
                    .stroke(PastelPalette.accentSage.opacity(0.8), lineWidth: 2)
                    .frame(width: 120, height: 120)
                Image(systemName: "wifi")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(PastelPalette.success)
            }

            VStack(spacing: 8) {
                Text("Waiting for Player 2\(dots)")
                    .font(.system(size: 28, weight: .bold))
                    .onReceive(timer) { _ in
                        dotCount = (dotCount + 1) % 3
                    }
                Text("Your device is broadcasting as:")
                    .font(.subheadline)
                    .foregroundColor(PastelPalette.textSecondary)
                Text(deviceName)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(PastelPalette.accentSage.opacity(0.35))
                    .cornerRadius(10)
            }

            VStack(alignment: .leading, spacing: 12) {
                Label("Make sure both iPads are on the same Wi-Fi", systemImage: "wifi.circle")
                Label("On the other iPad, tap \"Join Game\"", systemImage: "ipad.and.iphone")
                Label("Select \"\(deviceName)\" from the list", systemImage: "checkmark.circle")
            }
            .font(.subheadline)
            .foregroundColor(PastelPalette.textSecondary)
            .padding(20)
            .background(PastelPalette.neutralSoft.opacity(0.55))
            .cornerRadius(14)
            .frame(maxWidth: 420)

            Spacer()

            Button(action: onCancel) {
                Label("Cancel", systemImage: "xmark.circle")
                    .font(.subheadline)
                    .foregroundColor(PastelPalette.danger)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(PastelPalette.accentRose.opacity(0.35))
                    .cornerRadius(10)
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Lobby & Matchmaking

struct LobbyView: View {
    @Bindable var viewModel: GameViewModel
    let onGameStart: () -> Void

    @State private var isHosting: Bool = false

    var body: some View {
        Group {
            if isHosting {
                HostWaitingView(deviceName: UIDevice.current.name) {
                    viewModel.multipeerManager.disconnect()
                    isHosting = false
                }
            } else {
                mainLobby
            }
        }
        .onChange(of: viewModel.multipeerManager.isConnected) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onGameStart()
                }
            }
        }
    }

    private var mainLobby: some View {
        VStack(spacing: 30) {
            Text("Splendor Duel").font(.system(size: 50, weight: .heavy))

            Button("Pass & Play (Local)") {
                viewModel.isMultiplayer = false
                onGameStart()
            }
            .font(.title2).padding().frame(width: 300).background(PastelPalette.info).foregroundColor(PastelPalette.textOnDark).cornerRadius(12)

            Divider().frame(width: 300).padding(.vertical, 20)

            Button("Host Game") {
                viewModel.configureAsHost()
                viewModel.multipeerManager.startHosting()
                isHosting = true
            }
            .font(.title2).padding().frame(width: 300).background(PastelPalette.success).foregroundColor(PastelPalette.textOnDark).cornerRadius(12)

            Button("Join Game") {
                viewModel.configureAsGuest()
                viewModel.multipeerManager.startBrowsing()
            }
            .font(.title2).padding().frame(width: 300).background(PastelPalette.warning).foregroundColor(PastelPalette.textOnDark).cornerRadius(12)

            if !viewModel.multipeerManager.availablePeers.isEmpty {
                Text("Available Hosts:").font(.headline).padding(.top)
                ForEach(viewModel.multipeerManager.availablePeers, id: \.self) { peer in
                    Button("Join \(peer.displayName)") {
                        viewModel.multipeerManager.invitePeer(peer)
                    }
                    .padding().background(PastelPalette.neutralSoft).cornerRadius(8)
                }
            }
        }
    }
}
