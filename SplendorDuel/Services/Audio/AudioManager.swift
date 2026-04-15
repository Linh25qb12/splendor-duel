import AVFoundation
import Observation

@Observable
class AudioManager {
    enum SFX: String, CaseIterable {
        case buyCard = "buy-card"
        case reserveCard = "reserve-card"
        case privilegeUse = "privilege-use"
        case refill = "refill"
        case gemPick = "gem-pick"
        case clickButton = "click-button"
        case royalAchieve = "royal-achieve"
        case gameEnd = "game-end"
        case gemDrop = "gem-drop"
        case turnChange = "turn-change"
    }

    static let shared = AudioManager()

    private var bgmPlayer: AVAudioPlayer?
    private var sfxPlayers: [SFX: AVAudioPlayer] = [:]
    private(set) var isBGMPlaying = false
    var bgmVolume: Float = 0.3 {
        didSet { bgmPlayer?.volume = bgmVolume }
    }
    var sfxVolume: Float = 0.85 {
        didSet {
            for player in sfxPlayers.values {
                player.volume = sfxVolume
            }
        }
    }

    private init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AudioSession config failed: \(error)")
        }
    }

    // MARK: - Background Music

    func playBGM(_ filename: String = "background_music", ext: String = "flac") {
        guard bgmPlayer == nil || !bgmPlayer!.isPlaying else { return }
        guard let url = Bundle.main.url(forResource: filename, withExtension: ext) else {
            print("BGM file not found: \(filename).\(ext)")
            return
        }
        do {
            bgmPlayer = try AVAudioPlayer(contentsOf: url)
            bgmPlayer?.numberOfLoops = -1
            bgmPlayer?.volume = bgmVolume
            bgmPlayer?.prepareToPlay()
            bgmPlayer?.play()
            isBGMPlaying = true
        } catch {
            print("BGM playback failed: \(error)")
        }
    }

    func stopBGM() {
        bgmPlayer?.stop()
        bgmPlayer = nil
        isBGMPlaying = false
    }

    func pauseBGM() {
        bgmPlayer?.pause()
        isBGMPlaying = false
    }

    func resumeBGM() {
        bgmPlayer?.play()
        isBGMPlaying = true
    }

    func toggleBGM() {
        if isBGMPlaying {
            pauseBGM()
        } else if bgmPlayer != nil {
            resumeBGM()
        } else {
            playBGM()
        }
    }

    // MARK: - Sound Effects

    func playSFX(_ effect: SFX) {
        let player = sfxPlayer(for: effect)
        player?.currentTime = 0
        player?.play()
    }

    private func sfxPlayer(for effect: SFX) -> AVAudioPlayer? {
        if let cached = sfxPlayers[effect] {
            return cached
        }
        guard let url = sfxURL(for: effect) else {
            print("SFX file not found for effect: \(effect.rawValue)")
            return nil
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = sfxVolume
            player.prepareToPlay()
            sfxPlayers[effect] = player
            return player
        } catch {
            print("SFX playback failed for \(effect.rawValue): \(error)")
            return nil
        }
    }

    private func sfxURL(for effect: SFX) -> URL? {
        // `game-end` uses a dedicated file when available.
        // Fallback keeps compatibility with existing `royal-achieve.wav`.
        let candidates: [String] = {
            switch effect {
            case .gameEnd:
                return ["game-end", "royal-achieve"]
            default:
                return [effect.rawValue]
            }
        }()
        for name in candidates {
            if let url = Bundle.main.url(forResource: name, withExtension: "wav") {
                return url
            }
        }
        return nil
    }
}
