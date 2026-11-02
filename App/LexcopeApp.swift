import SwiftUI

@main
struct LexcopeApp: App {
    @StateObject private var model = AppModel()
    @StateObject private var speech = SpeechPlayer()
    @Environment(\.scenePhase) private var scenePhase
    private let timer = Timer.publish(every: 20, on: .main, in: .common).autoconnect()

    var body: some Scene {
        WindowGroup {
            Group {
                if let state = model.state {
                    NavigationStack {
                        if state.activeDeckIDs.isEmpty {
                            VStack(spacing: 24) {
                                Text("Lexcope").font(.largeTitle)
                                Text("选择词集，开始记忆").foregroundStyle(.secondary)
                                ForEach(state.decks) { deck in
                                    Button(deck.title) { model.toggleDeck(deck.id) }.buttonStyle(.bordered)
                                }
                            }.padding(24)
                        } else { StudyView() }
                    }
                } else {
                    ContentUnavailableView {
                        Label("无法打开学习记录", systemImage: "externaldrive.badge.exclamationmark")
                    } description: {
                        Text(model.errorMessage ?? "请重试。原始记录已保留。")
                    } actions: {
                        Button("重新载入") { model.load() }.buttonStyle(.borderedProminent)
                    }
                }
            }
            .environmentObject(model).environmentObject(speech).tint(Theme.accent)
            .alert("操作未完成", isPresented: Binding(get: { model.state != nil && model.errorMessage != nil },
                                                   set: { if !$0 { model.errorMessage = nil } })) {
                Button("知道了", role: .cancel) { model.errorMessage = nil }
            } message: { Text(model.errorMessage ?? "") }
            .alert("发音暂不可用", isPresented: Binding(get: { speech.errorMessage != nil },
                                                   set: { if !$0 { speech.errorMessage = nil } })) {
                Button("知道了", role: .cancel) { speech.errorMessage = nil }
            } message: { Text(speech.errorMessage ?? "") }
            .onReceive(timer) { _ in if scenePhase == .active { model.refresh() } }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { model.refresh() } else { speech.stop() }
            }
        }
    }
}
