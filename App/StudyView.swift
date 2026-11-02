import SwiftUI
import LexcopeCore

struct StudyView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var speech: SpeechPlayer
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var offset: CGSize = .zero
    @State private var detailWord: Word?
    @State private var preferredID: String?
    @State private var showHelp = false
    @State private var showButtons = false
    @State private var sessionCount = 0
    @State private var lastFeedback: String?
    @AppStorage("hasSeenStudyHelp") private var hasSeenHelp = false

    private var word: Word? {
        let ids = model.queue.wordIDs
        let id = preferredID.flatMap { ids.contains($0) ? $0 : nil } ?? ids.first
        return id.flatMap { model.state?.words[$0] }
    }

    var body: some View {
        VStack(spacing: 16) {
            if let word {
                HStack {
                    Text("待复习 \(model.queue.due.count)")
                    Spacer()
                    Text("新词 \(model.queue.new.count)")
                }.font(.subheadline).foregroundStyle(.secondary)
                card(word)
                    .id(word.id)
                if let lastFeedback {
                    Text(lastFeedback).font(.footnote).foregroundStyle(.secondary)
                        .accessibilityAddTraits(.updatesFrequently)
                }
                if showButtons {
                    HStack(spacing: 12) {
                        ratingButton(.unknown, symbol: "arrow.left", color: .red, word: word)
                        ratingButton(.fuzzy, symbol: "arrow.down", color: Theme.fuzzy, word: word)
                        ratingButton(.known, symbol: "arrow.right", color: Theme.accent, word: word)
                    }
                } else {
                    Text("轻点看详情 · 左右及向下滑动评分")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            } else {
                finished
            }
        }
        .padding(24).frame(maxWidth: 680).frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.canvas)
        .navigationTitle("专注记忆").inlineTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button { undo() } label: { Label("撤销", systemImage: "arrow.uturn.backward") }
                    .disabled(model.undoReceipt == nil).accessibilityIdentifier("undo-rating")
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("操作说明", systemImage: "hand.draw") { showHelp = true }
                    Toggle("显示评分按钮", isOn: $showButtons)
                } label: { Label("学习选项", systemImage: "ellipsis.circle") }
            }
        }
        .sheet(item: $detailWord) { WordDetailView(word: $0) }
        .sheet(isPresented: $showHelp, onDismiss: { hasSeenHelp = true }) { help }
        .onAppear {
            model.refresh()
            if !hasSeenHelp { showHelp = true }
        }
        .onDisappear { speech.stop() }
    }

    private func card(_ word: Word) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32).fill(Theme.paper)
                .onTapGesture { detailWord = word }
                .accessibilityHidden(true)
            VStack(spacing: 24) {
                Button { detailWord = word } label: {
                    Text(word.term).font(.system(.largeTitle, design: .serif).weight(.medium))
                        .multilineTextAlignment(.center).foregroundStyle(.primary)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("study-word")
                .accessibilityLabel(word.term)
                .accessibilityHint("轻点查看释义和例句")
                Button { speech.speak(word.term, language: model.state?.settings.voiceLanguage ?? "en-GB") } label: {
                    Text(word.ipa.isEmpty ? "音标未提供 · 点击听读音" : word.ipa)
                        .font(.title3).foregroundStyle(.secondary).padding(12)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("study-pronunciation")
                .accessibilityLabel("播放 \(word.term) 的英语发音")
            }.padding(24)
            if let direction = SwipeDirection.classify(x: offset.width, y: offset.height, threshold: 35) {
                Text(direction.rating.title).font(.headline)
                    .foregroundStyle(direction == .right ? Theme.accent : direction == .left ? .red : Theme.fuzzy)
                    .padding(16).background(Theme.paper, in: Capsule())
                    .frame(maxHeight: .infinity, alignment: .top).padding(.top, 24)
                    .allowsHitTesting(false)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("study-card")
        .frame(minHeight: 240, maxHeight: .infinity)
        .offset(offset)
        .rotationEffect(.degrees(reduceMotion ? 0 : Double(offset.width / 30)))
        .simultaneousGesture(
            DragGesture(minimumDistance: 24)
                .onChanged { offset = $0.translation }
                .onEnded { value in
                    let direction = SwipeDirection.classify(x: value.translation.width, y: value.translation.height)
                    withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.85)) { offset = .zero }
                    if let direction { rate(word, direction.rating) }
                }
        )
        .accessibilityAction(named: "认识") { rate(word, .known) }
        .accessibilityAction(named: "不认识") { rate(word, .unknown) }
        .accessibilityAction(named: "模糊") { rate(word, .fuzzy) }
    }

    private func ratingButton(_ rating: Rating, symbol: String, color: Color, word: Word) -> some View {
        Button { rate(word, rating) } label: {
            VStack(spacing: 8) { Image(systemName: symbol); Text(rating.title).font(.subheadline) }
                .frame(maxWidth: .infinity).padding(.vertical, 12)
        }.buttonStyle(.bordered).tint(color)
    }

    private func rate(_ word: Word, _ rating: Rating) {
        guard detailWord == nil, !showHelp else { return }
        speech.stop()
        if model.rate(word, rating) {
            preferredID = nil
            sessionCount += 1
            SpeechPlayer.feedback()
            if let dueAt = model.state?.progress[word.id]?.dueAt {
                lastFeedback = "\(rating.title) · 下次 \(dueAt.formatted(date: .abbreviated, time: .shortened))"
            }
        }
    }
    private func undo() {
        if let id = model.undo() {
            preferredID = id
            sessionCount = max(0, sessionCount - 1)
            lastFeedback = "已撤销最近一次评分"
        }
    }

    private var finished: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.circle").font(.system(size: 56, weight: .light)).foregroundStyle(Theme.accent)
            Text("这一轮完成了").font(.title.weight(.semibold))
            Text("本轮完成 \(sessionCount) 次回忆").foregroundStyle(.secondary)
            if let next = model.queue.nextReviewAt {
                Text("下次复习：\(next.formatted(date: .abbreviated, time: .shortened))")
                    .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            Text("短时重学到期后会自动进入队列，也可以稍后回来。")
                .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Spacer()
            Button("返回今日") { dismiss() }.buttonStyle(PrimaryButtonStyle())
        }
    }

    private var help: some View {
        NavigationStack {
            List {
                Section("让注意力留在回忆上") {
                    Label("轻点单词或卡片空白处：查看详情", systemImage: "hand.tap")
                    Label("轻点音标：播放英语读音", systemImage: "speaker.wave.2")
                }
                Section("按你的真实熟悉度评分") {
                    Label("右滑：认识，安排下一轮复习", systemImage: "arrow.right")
                    Label("左滑：不认识，5 分钟后重学", systemImage: "arrow.left")
                    Label("下滑：模糊，10 分钟后重学", systemImage: "arrow.down")
                }
                Section {
                    Text("误划可以撤销。右上角菜单可显示评分按钮；VoiceOver 也提供三种评分操作。")
                    Text("认识的词按 1、2、4、7、15、30 天的阶梯复习。这是受遗忘曲线启发的学习规则。")
                }
            }
            .navigationTitle("如何使用").inlineTitle()
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("开始记忆") { showHelp = false }.accessibilityIdentifier("dismiss-study-help") } }
        }
    }
}
