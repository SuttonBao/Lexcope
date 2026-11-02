import SwiftUI
import LexcopeCore

struct WordDetailView: View {
    let word: Word
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var speech: SpeechPlayer
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(word.term).font(.largeTitle.weight(.semibold)).textSelection(.enabled)
                        Button { play() } label: {
                            Label(word.ipa.isEmpty ? "音标未提供 · 听读音" : word.ipa, systemImage: "speaker.wave.2")
                                .font(.title3).padding(.vertical, 8)
                        }
                        .accessibilityLabel("播放 \(word.term) 的英语发音")
                        Text(word.meaning).font(.title3).textSelection(.enabled)
                    }
                    detail("英英解释", text: word.definition)
                    VStack(alignment: .leading, spacing: 12) {
                        sectionTitle("例句")
                        if word.examples.isEmpty { missing }
                        ForEach(Array(word.examples.enumerated()), id: \.offset) { _, example in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(example.english).textSelection(.enabled)
                                if !example.chinese.isEmpty { Text(example.chinese).foregroundStyle(.secondary) }
                            }.frame(maxWidth: .infinity, alignment: .leading).panel()
                        }
                    }
                    detail("词源与构词", text: word.etymology ?? "")
                    listDetail("常见搭配", values: word.collocations)
                    listDetail("同族词", values: word.family)
                    VStack(alignment: .leading, spacing: 8) {
                        sectionTitle("内容来源")
                        Text(word.source).font(.footnote).foregroundStyle(.secondary)
                    }
                }.padding(24).frame(maxWidth: 680, alignment: .leading).frame(maxWidth: .infinity)
            }
            .background(Theme.canvas)
            .navigationTitle("单词详情").inlineTitle()
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { dismiss() } } }
        }
    }

    private func play() { speech.speak(word.term, language: model.state?.settings.voiceLanguage ?? "en-GB") }
    private var missing: some View { Text("尚未提供此项内容").font(.subheadline).foregroundStyle(.secondary) }
    private func sectionTitle(_ text: String) -> some View { Text(text).font(.headline) }
    private func detail(_ title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(title)
            if text.isEmpty { missing } else { Text(text).textSelection(.enabled).lineSpacing(4) }
        }
    }
    private func listDetail(_ title: String, values: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(title)
            if values.isEmpty { missing }
            ForEach(Array(values.enumerated()), id: \.offset) { _, text in Text(text).textSelection(.enabled) }
        }
    }
}
