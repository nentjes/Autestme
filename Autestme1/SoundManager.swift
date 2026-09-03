import AVFoundation
import AudioToolbox

@MainActor
final class SoundManager {
    static let shared = SoundManager()

    var isSoundEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "isSoundEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "isSoundEnabled") }
    }

    private struct PlayerPool {
        var players: [AVAudioPlayer]
        var nextIndex: Int = 0

        mutating func nextPlayer() -> AVAudioPlayer? {
            guard !players.isEmpty else { return nil }
            let player = players[nextIndex]
            nextIndex = (nextIndex + 1) % players.count
            return player
        }
    }

    private var players: [String: PlayerPool] = [:]
    private let fallbackSystemSoundID: SystemSoundID = 1104
    private let playerPoolSize = 3

    private init() {
        configureAudioSession()
        preloadPlayers()
    }

    func playShape(_ shape: ShapeType) {
        playSound(named: shape.soundFileName)
    }

    func playLetter() {
        playSound(named: "letter")
    }

    func playNumber() {
        playSound(named: "cijfer")
    }

    func playClick() {
        playSound(named: "click")
    }

    func playResult(success: Bool) {
        playSound(named: success ? "beep1" : "click")
    }

    private func configureAudioSession() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
        #endif
    }

    private func preloadPlayers() {
        let soundNames = ShapeType.allCases.map(\.soundFileName) + ["letter", "cijfer", "click", "beep1"]

        for soundName in soundNames {
            guard players[soundName] == nil else { continue }
            guard let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") else {
                print("Missing sound asset '\(soundName).mp3'")
                continue
            }

            do {
                var poolPlayers: [AVAudioPlayer] = []
                for _ in 0..<playerPoolSize {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.volume = 1.0
                    player.prepareToPlay()
                    poolPlayers.append(player)
                }
                players[soundName] = PlayerPool(players: poolPlayers)
            } catch {
                print("Failed to preload sound '\(soundName).mp3': \(error.localizedDescription)")
            }
        }
    }

    private func playSound(named name: String) {
        guard isSoundEnabled else { return }

        if var pool = players[name], let player = pool.nextPlayer() {
            players[name] = pool
            player.currentTime = 0
            player.play()
            return
        }

        AudioServicesPlaySystemSound(fallbackSystemSoundID)
    }
}
