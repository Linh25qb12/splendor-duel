import Foundation
import MultipeerConnectivity
import Observation

@Observable
class MultipeerManager: NSObject {
    
    private let serviceType = "splendor-duel"
    
    private var myPeerID: MCPeerID
    private var session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser
    private var browser: MCNearbyServiceBrowser
    
    // MARK: - Public UI States
    var isConnected: Bool = false
    var availablePeers: [MCPeerID] = []
    var receivedData: Data? = nil
    var onDataReceived: ((Data) -> Void)?
    
    override init() {
        let localPeerID = MCPeerID(displayName: UIDevice.current.name)
        self.myPeerID = localPeerID
        self.session = MCSession(peer: localPeerID, securityIdentity: nil, encryptionPreference: .required)
        self.advertiser = MCNearbyServiceAdvertiser(peer: localPeerID, discoveryInfo: nil, serviceType: serviceType)
        self.browser = MCNearbyServiceBrowser(peer: localPeerID, serviceType: serviceType)
        super.init()
        self.session.delegate = self
        self.advertiser.delegate = self
        self.browser.delegate = self
    }
    
    // MARK: - Actions
    
    func startHosting() {
        advertiser.startAdvertisingPeer()
    }
    
    func startBrowsing() {
        browser.startBrowsingForPeers()
        availablePeers.removeAll()
    }
    
    func invitePeer(_ peer: MCPeerID) {
        browser.invitePeer(peer, to: session, withContext: nil, timeout: 10)
    }
    
    func send(data: Data) {
        guard !session.connectedPeers.isEmpty else { return }
        do {
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            print("Error sending data: \(error.localizedDescription)")
        }
    }
    
    // FIX 1: Properly tears down the session so a reset doesn't orphan the old connection
    func disconnect() {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        session.disconnect()
        isConnected = false
        availablePeers.removeAll()
        onDataReceived = nil
    }
}

// MARK: - Session Delegate
extension MultipeerManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                self.isConnected = true
                self.advertiser.stopAdvertisingPeer()
                self.browser.stopBrowsingForPeers()
            case .notConnected:
                // FIX 2: Only mark disconnected if ALL peers have dropped,
                // not just any single peer event firing
                self.isConnected = !self.session.connectedPeers.isEmpty
            default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.receivedData = data
            self.onDataReceived?(data)

        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - Advertiser Delegate
extension MultipeerManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, self.session)
    }
}

// MARK: - Browser Delegate
extension MultipeerManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        DispatchQueue.main.async {
            if !self.availablePeers.contains(peerID) {
                self.availablePeers.append(peerID)
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.availablePeers.removeAll { $0 == peerID }
        }
    }
}
