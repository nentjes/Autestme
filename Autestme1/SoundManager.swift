import AVFoundation

class SoundManager {
    static let shared = SoundManager()

    var isSoundEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "isSoundEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "isSoundEnabled") }
    }

    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode!

    // Gedeeld tussen main-thread (schrijven) en audio-thread (lezen).
    // Op arm64 zijn aligned Double/Bool reads/writes atomisch genoeg voor game-audio.
    private var targetFrequency: Double = 440.0
    private var isNoteOn: Bool = false

    // Interne audio-thread toestand
    private var phase: Double = 0
    private var vibratoPhase: Double = 0
    private var envelope: Double = 0

    private let sampleRate: Double = 44100
    private let attackRate: Double  // gain-stap per sample (attack)
    private let releaseRate: Double // gain-stap per sample (release)

    private init() {
        // 80 ms attack, 300 ms release — geeft zachte "choir" karakter
        attackRate  = 1.0 / (44100 * 0.08)
        releaseRate = 1.0 / (44100 * 0.30)

        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif

        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        sourceNode = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, audioBufferList in
            guard let self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            guard let buf = ablPointer[0].mData?.bindMemory(to: Float.self, capacity: Int(frameCount)) else {
                return noErr
            }

            let freq   = self.targetFrequency
            let noteOn = self.isNoteOn

            for i in 0..<Int(frameCount) {
                // ADSR envelope (attack / release)
                if noteOn {
                    self.envelope = min(1.0, self.envelope + self.attackRate)
                } else {
                    self.envelope = max(0.0, self.envelope - self.releaseRate)
                }

                // Vibrato LFO: 5 Hz, ±0.5% — geeft "levend" koor-gevoel
                let vibrato = 1.0 + 0.005 * sin(self.vibratoPhase)
                self.vibratoPhase += 2.0 * .pi * 5.0 / self.sampleRate
                if self.vibratoPhase > 2.0 * .pi { self.vibratoPhase -= 2.0 * .pi }

                // Additive synthese: grondtoon + harmonischen (zachte stringsklank)
                self.phase += 2.0 * .pi * freq * vibrato / self.sampleRate
                if self.phase > 2.0 * .pi { self.phase -= 2.0 * .pi }

                let sample = sin(self.phase)          * 0.60  // grondtoon
                           + sin(self.phase * 2.0)    * 0.25  // octaaf
                           + sin(self.phase * 3.0)    * 0.10  // kwint
                           + sin(self.phase * 4.0)    * 0.05  // 2e octaaf

                buf[i] = Float(sample * self.envelope * 0.35)
            }
            return noErr
        }

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: format)
        try? engine.start()
    }

    func playNote(_ midiNote: UInt8, duration: TimeInterval = 0.5) {
        guard isSoundEnabled else { return }
        // MIDI-noot naar frequentie: A4 = 69 = 440 Hz
        targetFrequency = 440.0 * pow(2.0, (Double(midiNote) - 69.0) / 12.0)
        isNoteOn = true
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.isNoteOn = false
        }
    }
}
