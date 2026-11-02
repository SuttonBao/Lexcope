import AVFoundation
import Combine
import Foundation
#if os(iOS)
import UIKit
#endif

@MainActor
final class SpeechPlayer: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    @Published var errorMessage: String?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            guard let self, !self.synthesizer.isSpeaking else { return }
            self.releaseAudioSession()
        }
    }

    func speak(_ text: String, language: String) {
        synthesizer.stopSpeaking(at: .immediate)
        guard let voice = AVSpeechSynthesisVoice(language: language) else {
            errorMessage = "设备上没有可用的英语语音。请在系统设置的辅助功能中下载英语朗读声音。"
            return
        }
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { errorMessage = "无法播放读音：\(error.localizedDescription)"; return }
        #endif
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.85
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        releaseAudioSession()
    }

    private func releaseAudioSession() {
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        #endif
    }

    static func feedback() {
        #if os(iOS)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }
}
