import AVFoundation
import Observation

@Observable
class AudioManager {
    static let shared = AudioManager()

    private var bgmPlayer: AVAudioPlayer?
    private(set) var isBGMPlaying = false
    var bgmVolume: Float = 0.3 {
        didSet { bgmPlayer?.volume = bgmVolume }
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
}
